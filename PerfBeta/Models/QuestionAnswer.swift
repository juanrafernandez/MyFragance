import Foundation

struct QuestionAnswer: Identifiable, Codable, Hashable {
    var id: UUID
    var questionId: UUID
    var answerId: UUID

    // Inicializador para instancias locales
    init(id: UUID = UUID(), questionId: UUID, answerId: UUID) {
        self.id = id
        self.questionId = questionId
        self.answerId = answerId
    }

    // Inicializador para Firestore
    init?(from data: [String: Any]) {
        guard
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString),
            let questionIdString = data["questionId"] as? String,
            let questionId = UUID(uuidString: questionIdString),
            let answerIdString = data["answerId"] as? String,
            let answerId = UUID(uuidString: answerIdString)
        else {
            return nil
        }
        self.init(id: id, questionId: questionId, answerId: answerId)
    }

    // Convertir a diccionario para Firebase
    func toDictionary() -> [String: Any] {
        [
            "id": id.uuidString,
            "questionId": questionId.uuidString,
            "answerId": answerId.uuidString
        ]
    }
}
