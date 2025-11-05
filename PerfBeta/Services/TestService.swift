import Foundation
import FirebaseFirestore
import Combine

protocol TestServiceProtocol {
    func fetchQuestions() async throws -> [Question]
    func listenToQuestionsChanges() -> AnyPublisher<[Question], Error>
}

class TestService: TestServiceProtocol {
    private let db: Firestore
    private let language: String
    private var listener: ListenerRegistration?
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
    
    // MARK: - Obtener Preguntas desde Firestore
    func fetchQuestions() async throws -> [Question] {
        let collectionPath = "questions_\(language)"
        let snapshot = try await db.collection(collectionPath).getDocuments()

        return snapshot.documents.compactMap { questionParser.parseQuestion(from: $0) }
    }
    
    // MARK: - Escuchar Cambios en Tiempo Real
    func listenToQuestionsChanges() -> AnyPublisher<[Question], Error> {
        let subject = PassthroughSubject<[Question], Error>()

        let collectionPath = "questions_\(language)"
        let collectionRef = db.collection(collectionPath)

        listener = collectionRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }

            let questions = documents.compactMap { self?.questionParser.parseQuestion(from: $0) }
            subject.send(questions)
        }

        // Asegúrate de cancelar la escucha cuando el publisher termine
        return subject.handleEvents(receiveCancel: { [weak self] in
            self?.listener?.remove()
        }).eraseToAnyPublisher()
    }
}
