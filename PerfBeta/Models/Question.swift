import SwiftData
import Foundation

@Model
struct Question: Identifiable {
    @Attribute(.unique) var id: String
    var category: String
    var text: String
    var options: [Option] = []

    // Inicializador para Firestore
    init?(from data: [String: Any]) {
        guard
            let id = data["id"] as? String,
            let category = data["category"] as? String,
            let text = data["text"] as? String,
            let optionsArray = data["options"] as? [[String: Any]]
        else {
            return nil
        }

        self.id = id
        self.category = category
        self.text = text
        self.options = optionsArray.compactMap { Option(data: $0) }
    }

    // Inicializador para SwiftData o manual
    init(id: String = UUID().uuidString, category: String, text: String, options: [Option] = []) {
        self.id = id
        self.category = category
        self.text = text
        self.options = options
    }
}
