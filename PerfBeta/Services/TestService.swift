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
    
    init(firestore: Firestore = Firestore.firestore(), language: String = AppState.shared.language) {
        self.db = firestore
        self.language = language
    }
    
    // MARK: - Obtener Preguntas desde Firestore
    func fetchQuestions() async throws -> [Question] {
        let collectionPath = "questions/\(language)/test"
        let snapshot = try await db.collection(collectionPath).getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            
            guard let category = data["category"] as? String,
                  let text = data["text"] as? String,
                  let key = data["key"] as? String else {
                return nil
            }
            
            // Mapear opciones correctamente
            let optionsArray = data["options"] as? [[String: Any]] ?? []
            let options = optionsArray.compactMap { optionDict -> Option? in
                // Maneja el campo 'id' como opcional si no siempre está presente
                let id = optionDict["id"] as? String ?? UUID().uuidString // Genera un ID si no está presente
                
                guard let label = optionDict["label"] as? String,
                      let value = optionDict["value"] as? String,
                      let description = optionDict["description"] as? String,
                      let imageAsset = optionDict["image_asset"] as? String,
                      let families = optionDict["families"] as? [String: Int] else {
                    return nil
                }
                
                return Option(
                    id: id,
                    label: label,
                    value: value,
                    description: description,
                    image_asset: imageAsset,
                    families: families
                )
            }
            
            return Question(
                id: data["id"] as? String ?? document.documentID,
                key: key,
                category: category,
                text: text,
                options: options,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
            )
        }
    }
    
    // MARK: - Escuchar Cambios en Tiempo Real
    func listenToQuestionsChanges() -> AnyPublisher<[Question], Error> {
        let subject = PassthroughSubject<[Question], Error>()
        
        let collectionPath = "questions/\(language)/\(AppState.shared.levelSelected)"
        let collectionRef = db.collection(collectionPath)
        
        listener = collectionRef.addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }
            
            let questions = documents.compactMap { try? $0.data(as: Question.self) }
            subject.send(questions)
        }
        
        // Asegúrate de cancelar la escucha cuando el publisher termine
        return subject.handleEvents(receiveCancel: { [weak self] in
            self?.listener?.remove()
        }).eraseToAnyPublisher()
    }
}
