import Foundation

struct Question: Identifiable, Codable {
    var id: String
    var key: String
    var questionType: String
    var order: Int
    var category: String
    var text: String
    var stepType: String?        // NEW: Para identificar tipo de evaluación (duration, projection, price, etc.)
    var multiSelect: Bool?       // NEW: Indica si permite selección múltiple
    var options: [Option]
    var createdAt: Date?
    var updatedAt: Date?

    /// Helper computed property para acceder al tipo como enum
    var type: QuestionType? {
        QuestionType(rawValue: questionType)
    }

    init(
        id: String,
        key: String,
        questionType: String,
        order: Int,
        category: String,
        text: String,
        stepType: String? = nil,
        multiSelect: Bool? = nil,
        options: [Option],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.key = key
        self.questionType = questionType
        self.order = order
        self.category = category
        self.text = text
        self.stepType = stepType
        self.multiSelect = multiSelect
        self.options = options
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Option: Codable, Equatable {
    var id: String
    var label: String
    var value: String
    var description: String
    var image_asset: String
    var families: [String: Int]
    
    init(id: String, label: String, value: String, description: String, image_asset: String, families: [String : Int]) {
        self.id = id
        self.label = label
        self.value = value
        self.description = description
        self.image_asset = image_asset
        self.families = families
    }
}
