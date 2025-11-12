import Foundation
import FirebaseFirestore
import Combine

protocol TestServiceProtocol {
    func fetchQuestions(type: QuestionType) async throws -> [Question]
    func listenToQuestionsChanges(type: QuestionType) -> AnyPublisher<[Question], Error>
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
    func fetchQuestions(type: QuestionType = .perfilOlfativo) async throws -> [Question] {
        let collectionPath = "questions_\(language)"
        let snapshot = try await db.collection(collectionPath)
            .whereField("questionType", isEqualTo: type.rawValue)
            .getDocuments()

        // Ordenar en memoria en lugar de en Firestore (evita necesidad de índice compuesto)
        let questions = snapshot.documents.compactMap { questionParser.parseQuestion(from: $0) }
        return questions.sorted { $0.order < $1.order }
    }

    // MARK: - Escuchar Cambios en Tiempo Real
    func listenToQuestionsChanges(type: QuestionType = .perfilOlfativo) -> AnyPublisher<[Question], Error> {
        let subject = PassthroughSubject<[Question], Error>()

        let collectionPath = "questions_\(language)"
        let collectionRef = db.collection(collectionPath)
            .whereField("questionType", isEqualTo: type.rawValue)

        listener = collectionRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }

            // Ordenar en memoria en lugar de en Firestore (evita necesidad de índice compuesto)
            let questions = documents.compactMap { self?.questionParser.parseQuestion(from: $0) }
            let sortedQuestions = questions.sorted { $0.order < $1.order }
            subject.send(sortedQuestions)
        }

        // Asegúrate de cancelar la escucha cuando el publisher termine
        return subject.handleEvents(receiveCancel: { [weak self] in
            self?.listener?.remove()
        }).eraseToAnyPublisher()
    }
}
