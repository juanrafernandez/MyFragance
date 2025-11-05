import Foundation
import FirebaseFirestore

protocol QuestionsServiceProtocol {
    func fetchQuestions() async throws -> [Question]
    func listenToQuestionsChanges(completion: @escaping (Result<[Question], Error>) -> Void)
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
    func fetchQuestions() async throws -> [Question] {
        let collectionPath = "questions_\(language)"
        let snapshot = try await db.collection(collectionPath).getDocuments()

        return snapshot.documents.compactMap { questionParser.parseQuestion(from: $0) }
    }
        
    func listenToQuestionsChanges(completion: @escaping (Result<[Question], Error>) -> Void) {
        let collectionPath = "questions_\(language)"
        let collectionRef = db.collection(collectionPath)

        collectionRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success([])) // Sin documentos, lista vacía
                return
            }

            let questions = documents.compactMap { self?.questionParser.parseQuestion(from: $0) }
            completion(.success(questions))
        }
    }
}
