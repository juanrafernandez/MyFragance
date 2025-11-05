import Foundation
import FirebaseFirestore

protocol QuestionsServiceProtocol {
    func fetchQuestions() async throws -> [Question]
    func listenToQuestionsChanges(completion: @escaping (Result<[Question], Error>) -> Void)
}

class QuestionsService: QuestionsServiceProtocol {
    private let db: Firestore
    private let language: String
    private let questionParser: QuestionParserProtocol

    init(
        firestore: Firestore = Firestore.firestore(),
        language: String = AppState.shared.language,
        questionParser: QuestionParserProtocol = QuestionParser()
    ) {
        self.db = firestore
        self.language = language
        self.questionParser = questionParser
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
