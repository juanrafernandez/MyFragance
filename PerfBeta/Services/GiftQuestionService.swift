import Foundation
import FirebaseFirestore

// MARK: - Gift Question Service Protocol
protocol GiftQuestionServiceProtocol {
    func loadQuestions() async throws -> [GiftQuestion]
    func getQuestionsForFlow(_ flowType: String) async throws -> [GiftQuestion]
    func getQuestion(byId id: String) async throws -> GiftQuestion?
    func refreshQuestions() async throws -> [GiftQuestion]
}

// MARK: - Gift Question Service
/// Servicio para cargar y cachear preguntas del flujo de regalo desde Firebase
actor GiftQuestionService: GiftQuestionServiceProtocol {

    static let shared = GiftQuestionService()

    private let db: Firestore
    private let cacheManager = CacheManager.shared
    private let cacheKey = "gift_questions_v2"  // ✅ Cambiada clave para forzar reload
    private let cacheVersionKey = "gift_questions_version_v2"  // ✅ Nueva clave de versión
    private let currentCacheVersion = 4  // ✅ Incrementado para fix flowB1_04_season (removido null filters)

    // Cache en memoria para acceso rápido
    private var questionsCache: [GiftQuestion]?

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    /// Cargar preguntas (primero intenta desde cache, luego Firebase)
    func loadQuestions() async throws -> [GiftQuestion] {
        // 1. Check memoria
        if let cached = questionsCache {
            #if DEBUG
            print("✅ [GiftQuestionService] Questions loaded from memory cache: \(cached.count)")
            #endif
            return cached
        }

        // 2. Check version del cache
        var cachedVersion = UserDefaults.standard.integer(forKey: cacheVersionKey)

        if cachedVersion != currentCacheVersion {
            #if DEBUG
            print("🔄 [GiftQuestionService] Cache version mismatch (cached: \(cachedVersion), current: \(currentCacheVersion)) - invalidating...")
            #endif

            // Invalidar cache antiguo
            await cacheManager.clearCache(for: cacheKey)
            questionsCache = nil

            // Actualizar versión
            UserDefaults.standard.set(currentCacheVersion, forKey: cacheVersionKey)
            cachedVersion = currentCacheVersion  // ✅ Actualizar variable local también

            #if DEBUG
            print("🔄 [GiftQuestionService] Cache invalidated, downloading fresh questions from Firebase...")
            #endif

            // Forzar descarga desde Firebase
            return try await downloadQuestions()
        }

        // 3. Check disco (solo si la versión es correcta)
        if let cachedQuestions = await cacheManager.load([GiftQuestion].self, for: cacheKey) {
            #if DEBUG
            print("✅ [GiftQuestionService] Questions loaded from disk cache: \(cachedQuestions.count)")
            for q in cachedQuestions.filter({ $0.flowType == "B1" }) {
                print("   - B1 Question: \(q.id) (order: \(q.order))")
            }
            #endif
            questionsCache = cachedQuestions

            // Background sync para actualizar si hay cambios
            Task {
                try? await self.syncQuestionsInBackground()
            }

            return cachedQuestions
        }

        // 4. Download desde Firebase
        #if DEBUG
        print("📥 [GiftQuestionService] No cache found - fetching from Firebase...")
        #endif

        return try await downloadQuestions()
    }

    /// Obtener preguntas de un flujo específico
    func getQuestionsForFlow(_ flowType: String) async throws -> [GiftQuestion] {
        let allQuestions = try await loadQuestions()

        let filtered = allQuestions
            .filter { $0.flowType == flowType }
            .sorted { $0.order < $1.order }

        #if DEBUG
        print("🔍 [GiftQuestionService] Questions for flow '\(flowType)': \(filtered.count)")
        #endif

        return filtered
    }

    /// Obtener pregunta específica por ID
    func getQuestion(byId id: String) async throws -> GiftQuestion? {
        let allQuestions = try await loadQuestions()
        return allQuestions.first { $0.id == id }
    }

    /// Forzar actualización desde Firebase
    func refreshQuestions() async throws -> [GiftQuestion] {
        #if DEBUG
        print("🔄 [GiftQuestionService] Force refresh from Firebase")
        #endif

        questionsCache = nil
        return try await downloadQuestions()
    }

    // MARK: - Private Methods

    private func downloadQuestions() async throws -> [GiftQuestion] {
        // Cargar desde questions_es filtrando por flowTypes de regalo
        let validFlowTypes = ["main", "A", "B1", "B2", "B3", "B4"]

        let snapshot = try await db.collection("questions_es")
            .whereField("flowType", in: validFlowTypes)
            .getDocuments()

        let questions = snapshot.documents.compactMap { doc -> GiftQuestion? in
            try? doc.data(as: GiftQuestion.self)
        }

        guard !questions.isEmpty else {
            throw GiftQuestionServiceError.noQuestionsFound
        }

        #if DEBUG
        print("✅ [GiftQuestionService] Downloaded \(questions.count) questions from Firebase (questions_es)")
        let b1Questions = questions.filter { $0.flowType == "B1" }.sorted { $0.order < $1.order }
        print("   B1 Questions: \(b1Questions.count)")
        for q in b1Questions {
            print("     - \(q.id) (order: \(q.order), conditional: \(q.isConditional))")
        }
        #endif

        // Guardar en cache
        await saveToCache(questions)

        // Guardar en memoria
        questionsCache = questions

        return questions
    }

    private func syncQuestionsInBackground() async throws {
        // Obtener última sincronización
        let lastSync = await cacheManager.getLastSyncTimestamp(for: cacheKey) ?? Date.distantPast

        // Consultar solo preguntas modificadas de regalo en questions_es
        let validFlowTypes = ["main", "A", "B1", "B2", "B3", "B4"]

        let snapshot = try await db.collection("questions_es")
            .whereField("flowType", in: validFlowTypes)
            .whereField("updatedAt", isGreaterThan: Timestamp(date: lastSync))
            .getDocuments()

        guard !snapshot.documents.isEmpty else {
            #if DEBUG
            print("✅ [GiftQuestionService] No updates needed")
            #endif
            return
        }

        #if DEBUG
        print("🔄 [GiftQuestionService] Found \(snapshot.documents.count) updated questions")
        #endif

        // Descargar todas las preguntas actualizadas
        let updatedQuestions = try await downloadQuestions()

        #if DEBUG
        print("✅ [GiftQuestionService] Background sync complete: \(updatedQuestions.count) questions")
        #endif
    }

    private func saveToCache(_ questions: [GiftQuestion]) async {
        do {
            try await cacheManager.save(questions, for: cacheKey)
            await cacheManager.saveLastSyncTimestamp(Date(), for: cacheKey)

            #if DEBUG
            print("💾 [GiftQuestionService] Questions saved to cache: \(questions.count)")
            #endif
        } catch {
            #if DEBUG
            print("❌ [GiftQuestionService] Failed to save to cache: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Gift Profile Service Protocol
protocol GiftProfileServiceProtocol {
    func saveProfile(_ profile: GiftProfile, userId: String) async throws
    func loadProfiles(userId: String) async throws -> [GiftProfile]
    func loadProfile(id: String, userId: String) async throws -> GiftProfile?
    func updateProfile(_ profile: GiftProfile, userId: String) async throws
    func deleteProfile(id: String, userId: String) async throws
}

// MARK: - Gift Profile Service
/// Servicio para gestionar perfiles de regalo guardados
actor GiftProfileService: GiftProfileServiceProtocol {

    static let shared = GiftProfileService()

    private let db: Firestore
    private let cacheManager = CacheManager.shared

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    func saveProfile(_ profile: GiftProfile, userId: String) async throws {
        let profileData = profile.toFirestore()

        try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(profile.id)
            .setData(profileData)

        #if DEBUG
        print("✅ [GiftProfileService] Profile saved: \(profile.id)")
        #endif

        // Invalidar cache de perfiles
        await invalidateProfilesCache(userId: userId)
    }

    func loadProfiles(userId: String) async throws -> [GiftProfile] {
        // Check cache primero
        let cacheKey = "gift_profiles_\(userId)"
        if let cached = await cacheManager.load([GiftProfile].self, for: cacheKey) {
            #if DEBUG
            print("✅ [GiftProfileService] Profiles loaded from cache: \(cached.count)")
            #endif
            return cached
        }

        // Download desde Firebase
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .order(by: "metadata.lastUsed", descending: true)
            .getDocuments()

        let profiles = snapshot.documents.compactMap { doc -> GiftProfile? in
            GiftProfile.fromFirestore(doc.data())
        }

        #if DEBUG
        print("✅ [GiftProfileService] Profiles loaded from Firebase: \(profiles.count)")
        #endif

        // Guardar en cache
        try? await cacheManager.save(profiles, for: cacheKey)

        return profiles
    }

    func loadProfile(id: String, userId: String) async throws -> GiftProfile? {
        let doc = try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(id)
            .getDocument()

        guard doc.exists, let data = doc.data() else {
            return nil
        }

        return GiftProfile.fromFirestore(data)
    }

    func updateProfile(_ profile: GiftProfile, userId: String) async throws {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()

        let profileData = updatedProfile.toFirestore()

        try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(profile.id)
            .updateData(profileData)

        #if DEBUG
        print("✅ [GiftProfileService] Profile updated: \(profile.id)")
        #endif

        await invalidateProfilesCache(userId: userId)
    }

    func deleteProfile(id: String, userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(id)
            .delete()

        #if DEBUG
        print("✅ [GiftProfileService] Profile deleted: \(id)")
        #endif

        await invalidateProfilesCache(userId: userId)
    }

    // MARK: - Private Methods

    private func invalidateProfilesCache(userId: String) async {
        let cacheKey = "gift_profiles_\(userId)"
        await cacheManager.clearCache(for: cacheKey)
        #if DEBUG
        print("🗑️ [GiftProfileService] Cache invalidated for user: \(userId)")
        #endif
    }
}

// MARK: - Errors
enum GiftQuestionServiceError: LocalizedError {
    case noQuestionsFound
    case questionNotFound(String)
    case invalidFlowType(String)

    var errorDescription: String? {
        switch self {
        case .noQuestionsFound:
            return "No se encontraron preguntas en Firebase"
        case .questionNotFound(let id):
            return "Pregunta no encontrada: \(id)"
        case .invalidFlowType(let flow):
            return "Tipo de flujo inválido: \(flow)"
        }
    }
}
