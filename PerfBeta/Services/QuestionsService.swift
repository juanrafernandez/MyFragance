import Foundation
import FirebaseFirestore

// MARK: - Question Category
/// Categorías de preguntas disponibles en Firestore
enum QuestionCategory: String {
    case profile = "category_profile"
    case gift = "category_gift"
    case evaluation = "evaluation"
}

// MARK: - Questions Service Protocol
protocol QuestionsServiceProtocol {
    func fetchQuestions(type: QuestionType) async throws -> [Question]
    func listenToQuestionsChanges(type: QuestionType, completion: @escaping (Result<[Question], Error>) -> Void)

    // MARK: - Unified Question Flow
    func fetchAllProfileQuestions() async throws -> [Question]
    func fetchAllGiftQuestions() async throws -> [Question]

    // MARK: - Cached Question Loading (for Gift flow)
    func loadQuestions(category: QuestionCategory) async throws -> [Question]
    func getQuestionsForFlow(_ flowType: String, category: QuestionCategory) async throws -> [Question]
    func getQuestion(byId id: String, category: QuestionCategory) async throws -> Question?
    func refreshQuestions(category: QuestionCategory) async throws -> [Question]
}

// MARK: - Questions Service Errors
enum QuestionsServiceError: LocalizedError {
    case noQuestionsFound
    case questionNotFound(String)
    case invalidCategory(String)

    var errorDescription: String? {
        switch self {
        case .noQuestionsFound:
            return "No se encontraron preguntas en Firebase"
        case .questionNotFound(let id):
            return "Pregunta no encontrada: \(id)"
        case .invalidCategory(let category):
            return "Categoría inválida: \(category)"
        }
    }
}

// MARK: - Questions Service
class QuestionsService: QuestionsServiceProtocol {

    // MARK: - Singleton for cached access
    static let shared = QuestionsService()

    private let db: Firestore
    private let languageProvider: LanguageProvider
    private let questionParser: QuestionParserProtocol
    private let cacheManager = CacheManager.shared

    // Cache keys por categoría
    private func cacheKey(for category: QuestionCategory) -> String {
        "questions_\(category.rawValue)_v1"
    }

    private func cacheVersionKey(for category: QuestionCategory) -> String {
        "questions_\(category.rawValue)_version_v1"
    }

    // Versión actual del cache (incrementar para forzar recarga)
    private let currentCacheVersion = 1

    // Cache en memoria por categoría
    private var memoryCaches: [QuestionCategory: [Question]] = [:]

    init(
        firestore: Firestore = Firestore.firestore(),
        languageProvider: LanguageProvider = AppState.shared,
        questionParser: QuestionParserProtocol = QuestionParser()
    ) {
        self.db = firestore
        self.languageProvider = languageProvider
        self.questionParser = questionParser
    }

    /// Computed property to access current language
    private var language: String {
        languageProvider.language
    }

    // MARK: - Legacy Methods (for QuestionsViewModel compatibility)

    func fetchQuestions(type: QuestionType = .perfilOlfativo) async throws -> [Question] {
        let collectionPath = "questions_\(language)"
        let snapshot = try await db.collection(collectionPath)
            .whereField("questionType", isEqualTo: type.rawValue)
            .getDocuments()

        let questions = snapshot.documents.compactMap { questionParser.parseQuestion(from: $0) }
        return questions.sorted { $0.order < $1.order }
    }

    func listenToQuestionsChanges(type: QuestionType = .perfilOlfativo, completion: @escaping (Result<[Question], Error>) -> Void) {
        let collectionPath = "questions_\(language)"
        let collectionRef = db.collection(collectionPath)
            .whereField("questionType", isEqualTo: type.rawValue)

        collectionRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }

            let questions = documents.compactMap { self?.questionParser.parseQuestion(from: $0) }
            let sortedQuestions = questions.sorted { $0.order < $1.order }
            completion(.success(sortedQuestions))
        }
    }

    // MARK: - Unified Question Flow Methods

    func fetchAllProfileQuestions() async throws -> [Question] {
        return try await loadQuestions(category: .profile)
    }

    func fetchAllGiftQuestions() async throws -> [Question] {
        return try await loadQuestions(category: .gift)
    }

    // MARK: - Cached Question Loading

    /// Cargar preguntas con sistema de caché (primero memoria, luego disco, luego Firebase)
    func loadQuestions(category: QuestionCategory) async throws -> [Question] {
        // 1. Check memoria
        if let cached = memoryCaches[category] {
            #if DEBUG
            print("✅ [QuestionsService] Questions loaded from memory cache (\(category.rawValue)): \(cached.count)")
            #endif
            return cached
        }

        // 2. Check versión del cache
        let versionKey = cacheVersionKey(for: category)
        var cachedVersion = UserDefaults.standard.integer(forKey: versionKey)

        if cachedVersion != currentCacheVersion {
            #if DEBUG
            print("🔄 [QuestionsService] Cache version mismatch for \(category.rawValue) (cached: \(cachedVersion), current: \(currentCacheVersion)) - invalidating...")
            #endif

            await cacheManager.clearCache(for: cacheKey(for: category))
            memoryCaches[category] = nil
            UserDefaults.standard.set(currentCacheVersion, forKey: versionKey)
            cachedVersion = currentCacheVersion

            return try await downloadQuestions(category: category)
        }

        // 3. Check disco
        let key = cacheKey(for: category)
        if let cachedQuestions = await cacheManager.load([Question].self, for: key) {
            #if DEBUG
            print("✅ [QuestionsService] Questions loaded from disk cache (\(category.rawValue)): \(cachedQuestions.count)")
            #endif
            memoryCaches[category] = cachedQuestions

            // Background sync
            Task {
                try? await self.syncQuestionsInBackground(category: category)
            }

            return cachedQuestions
        }

        // 4. Download desde Firebase
        #if DEBUG
        print("📥 [QuestionsService] No cache found for \(category.rawValue) - fetching from Firebase...")
        #endif

        return try await downloadQuestions(category: category)
    }

    /// Obtener preguntas de un flujo específico
    func getQuestionsForFlow(_ flowType: String, category: QuestionCategory) async throws -> [Question] {
        let allQuestions = try await loadQuestions(category: category)

        let filtered = allQuestions
            .filter { $0.flow == flowType }
            .sorted { $0.order < $1.order }

        #if DEBUG
        print("🔍 [QuestionsService] Questions for flow '\(flowType)' (\(category.rawValue)): \(filtered.count)")
        #endif

        return filtered
    }

    /// Obtener pregunta específica por ID
    func getQuestion(byId id: String, category: QuestionCategory) async throws -> Question? {
        let allQuestions = try await loadQuestions(category: category)
        return allQuestions.first { $0.id == id }
    }

    /// Forzar actualización desde Firebase
    func refreshQuestions(category: QuestionCategory) async throws -> [Question] {
        #if DEBUG
        print("🔄 [QuestionsService] Force refresh from Firebase for \(category.rawValue)")
        #endif

        memoryCaches[category] = nil
        return try await downloadQuestions(category: category)
    }

    // MARK: - Private Methods

    private func downloadQuestions(category: QuestionCategory) async throws -> [Question] {
        let collectionPath = "questions_\(language)"

        let snapshot = try await db.collection(collectionPath)
            .whereField("category", isEqualTo: category.rawValue)
            .getDocuments()

        #if DEBUG
        print("📥 [QuestionsService] Firestore returned \(snapshot.documents.count) documents for \(category.rawValue)")
        #endif

        var questions: [Question] = []
        for doc in snapshot.documents {
            do {
                let question = try doc.data(as: Question.self)
                questions.append(question)
            } catch {
                // Fallback al parser si falla el decode directo
                if let parsed = questionParser.parseQuestion(from: doc) {
                    questions.append(parsed)
                } else {
                    #if DEBUG
                    print("❌ [QuestionsService] Failed to decode question '\(doc.documentID)': \(error)")
                    #endif
                }
            }
        }

        guard !questions.isEmpty else {
            throw QuestionsServiceError.noQuestionsFound
        }

        questions.sort { $0.order < $1.order }

        #if DEBUG
        print("✅ [QuestionsService] Downloaded \(questions.count) questions for \(category.rawValue)")

        // Mostrar resumen por flujo
        let flowTypes = Set(questions.compactMap { $0.flow })
        for flowType in flowTypes.sorted() {
            let flowQuestions = questions.filter { $0.flow == flowType }
            print("   \(flowType): \(flowQuestions.count) questions")
        }
        #endif

        // Guardar en cache
        await saveToCache(questions, category: category)

        // Guardar en memoria
        memoryCaches[category] = questions

        return questions
    }

    private func syncQuestionsInBackground(category: QuestionCategory) async throws {
        let key = cacheKey(for: category)
        let lastSync = await cacheManager.getLastSyncTimestamp(for: key) ?? Date.distantPast
        let collectionPath = "questions_\(language)"

        let snapshot = try await db.collection(collectionPath)
            .whereField("category", isEqualTo: category.rawValue)
            .whereField("updatedAt", isGreaterThan: Timestamp(date: lastSync))
            .getDocuments()

        guard !snapshot.documents.isEmpty else {
            #if DEBUG
            print("✅ [QuestionsService] No updates needed for \(category.rawValue)")
            #endif
            return
        }

        #if DEBUG
        print("🔄 [QuestionsService] Found \(snapshot.documents.count) updated questions for \(category.rawValue)")
        #endif

        _ = try await downloadQuestions(category: category)
    }

    private func saveToCache(_ questions: [Question], category: QuestionCategory) async {
        let key = cacheKey(for: category)
        do {
            try await cacheManager.save(questions, for: key)
            await cacheManager.saveLastSyncTimestamp(Date(), for: key)

            #if DEBUG
            print("💾 [QuestionsService] Questions saved to cache (\(category.rawValue)): \(questions.count)")
            #endif
        } catch {
            #if DEBUG
            print("❌ [QuestionsService] Failed to save to cache: \(error.localizedDescription)")
            #endif
        }
    }
}
