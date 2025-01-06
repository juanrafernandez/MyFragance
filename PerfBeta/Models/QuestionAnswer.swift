import SwiftData
import Foundation

@Model
struct QuestionAnswer: Identifiable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var questionId: String
    var answerId: String

    // Inicializador para Firestore
    init?(from data: [String: Any]) {
        guard
            let questionId = data["questionId"] as? String,
            let answerId = data["answerId"] as? String
        else {
            return nil
        }
        self.id = data["id"] as? String ?? UUID().uuidString
        self.questionId = questionId
        self.answerId = answerId
    }

    // Inicializador manual para instancias locales
    init(id: String = UUID().uuidString, questionId: String, answerId: String) {
        self.id = id
        self.questionId = questionId
        self.answerId = answerId
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "questionId": questionId,
            "answerId": answerId
        ]
    }
}
