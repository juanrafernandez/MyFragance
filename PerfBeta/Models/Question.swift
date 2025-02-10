import Foundation

struct Question: Identifiable, Codable {
    var id: String
    var key: String
    var category: String
    var text: String
    var options: [Option]
    var createdAt: Date?
    var updatedAt: Date?
    
    init(id: String, key: String, category: String, text: String, options: [Option], createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.key = key
        self.category = category
        self.text = text
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
