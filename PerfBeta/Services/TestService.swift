import Foundation
import FirebaseFirestore
import Combine

protocol TestServiceProtocol {
    func fetchQuestions() async throws -> [Question]
    func listenToQuestionsChanges() -> AnyPublisher<[Question], Error>
}

class TestService: TestServiceProtocol {
    private let db: Firestore
    private let languageProvider: LanguageProvider
    private var listener: ListenerRegistration?
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
