import Foundation

struct QuestionAnswer: Identifiable, Codable, Hashable {
    var id: UUID
    var questionId: String
    var answerId: String

    // Inicializador para instancias locales
    init(id: UUID = UUID(), questionId: String, answerId: String) {
        self.id = id
        self.questionId = questionId
        self.answerId = answerId
    }

    // Inicializador para Firestore
    init?(from data: [String: Any]) {
        guard
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString),
            let questionId = data["questionId"] as? String,
            let answerId = data["answerId"] as? String
        else {
            return nil
        }
        self.init(id: id, questionId: questionId, answerId: answerId)
    }

    // Convertir a diccionario para Firebase
    func toDictionary() -> [String: Any] {
        [
            "id": id.uuidString,
            "questionId": questionId,
            "answerId": answerId
        ]
    }
}
