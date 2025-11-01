import Foundation
import FirebaseFirestore

protocol QuestionsServiceProtocol {
    func fetchQuestions() async throws -> [Question]
    func listenToQuestionsChanges(completion: @escaping (Result<[Question], Error>) -> Void)
}

class QuestionsService: QuestionsServiceProtocol {
    private let db: Firestore
    private let language: String

    init(firestore: Firestore = Firestore.firestore(), language: String = AppState.shared.language) {
        self.db = firestore
        self.language = language
    }

    // MARK: - Obtener Preguntas
    func fetchQuestions() async throws -> [Question] {
        let collectionPath = "questions_\(language)"
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
        
    func listenToQuestionsChanges(completion: @escaping (Result<[Question], Error>) -> Void) {
        let collectionPath = "questions_\(language)"
        let collectionRef = db.collection(collectionPath)

        collectionRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success([])) // Sin documentos, lista vacía
                return
            }

            // Use same manual parsing as fetchQuestions() to ensure consistency
            let questions = documents.compactMap { document -> Question? in
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
                    let id = optionDict["id"] as? String ?? UUID().uuidString

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
            completion(.success(questions))
        }
    }
}
