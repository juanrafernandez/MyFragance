import Foundation

struct Notes: Identifiable, Codable, Equatable {
    var id: String? // `id` es opcional para manejar el JSON sin ID
    var key: String // Nuevo campo agregado
    var name: String
    var origin: String?
    var descriptionNote: String?
    var imageURL: String?
    var createdAt: Date?
    var updatedAt: Date?

    init(id: String? = nil, key: String, name: String, origin: String, descriptionNote: String, imageURL: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.key = key
        self.name = name
        self.origin = origin
        self.descriptionNote = descriptionNote
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
