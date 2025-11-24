import Foundation
import FirebaseFirestore

protocol QuestionsServiceProtocol {
    func fetchQuestions(type: QuestionType) async throws -> [Question]
    func listenToQuestionsChanges(type: QuestionType, completion: @escaping (Result<[Question], Error>) -> Void)

    // MARK: - Unified Question Flow
    /// Carga TODAS las preguntas que empiezan con "profile_" para el flujo personal
    func fetchAllProfileQuestions() async throws -> [Question]

    /// Carga TODAS las preguntas que empiezan con "gift_" para el flujo de regalo
    func fetchAllGiftQuestions() async throws -> [Question]
}

class QuestionsService: QuestionsServiceProtocol {
    private let db: Firestore
    private let languageProvider: LanguageProvider
    private let questionParser: QuestionParserProtocol

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

    // MARK: - Obtener Preguntas
    func fetchQuestions(type: QuestionType = .perfilOlfativo) async throws -> [Question] {
        let collectionPath = "questions_\(language)"
        let snapshot = try await db.collection(collectionPath)
            .whereField("questionType", isEqualTo: type.rawValue)
            .getDocuments()

        // Ordenar en memoria en lugar de en Firestore (evita necesidad de índice compuesto)
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
                completion(.success([])) // Sin documentos, lista vacía
                return
            }

            // Ordenar en memoria en lugar de en Firestore (evita necesidad de índice compuesto)
            let questions = documents.compactMap { self?.questionParser.parseQuestion(from: $0) }
            let sortedQuestions = questions.sorted { $0.order < $1.order }
            completion(.success(sortedQuestions))
        }
    }

    // MARK: - Unified Question Flow Methods

    /// Carga TODAS las preguntas que empiezan con "profile_"
    func fetchAllProfileQuestions() async throws -> [Question] {
        return try await fetchQuestionsWithPrefix("profile_")
    }

    /// Carga TODAS las preguntas que empiezan con "gift_"
    func fetchAllGiftQuestions() async throws -> [Question] {
        return try await fetchQuestionsWithPrefix("gift_")
    }

    /// Helper privado para cargar preguntas por prefijo
    private func fetchQuestionsWithPrefix(_ prefix: String) async throws -> [Question] {
        let collectionPath = "questions_\(language)"

        #if DEBUG
        print("📥 [QuestionsService] Cargando preguntas con prefijo '\(prefix)' desde '\(collectionPath)'")
        #endif

        // Firestore no soporta "startsWith" directamente, pero podemos usar range queries
        // Para IDs que empiezan con "profile_", queremos >= "profile_" y < "profile_~"
        let startAt = prefix
        let endBefore = prefix + "\u{F8FF}"  // Carácter Unicode alto para terminar el rango

        let snapshot = try await db.collection(collectionPath)
            .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: startAt)
            .whereField(FieldPath.documentID(), isLessThan: endBefore)
            .getDocuments()

        let questions = snapshot.documents.compactMap { questionParser.parseQuestion(from: $0) }
        let sortedQuestions = questions.sorted { $0.order < $1.order }

        #if DEBUG
        print("✅ [QuestionsService] Cargadas \(sortedQuestions.count) preguntas con prefijo '\(prefix)'")
        #endif

        return sortedQuestions
    }
}
