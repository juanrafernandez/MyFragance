import Foundation

struct Perfumist: Identifiable, Codable, Equatable {
    var id: String // Hacerlo no opcional
    var name: String
    var imageUrl: String?
    var country: String
    var year: Int
    var createdAt: Date?
    var updatedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        imageUrl: String? = nil,
        country: String,
        year: Int,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.country = country
        self.year = year
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
