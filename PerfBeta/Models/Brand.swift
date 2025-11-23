import Foundation

struct Brand: Identifiable, Codable, Equatable {
    var id: String?
    var key: String
    var name: String
    var imageURL: String?
    var origin: String
    var descriptionBrand: String
    var perfumist: [String]?
    var createdAt: Date?
    var updatedAt: Date?

    init(id: String = UUID().uuidString,
         key: String,
         name: String,
         imageURL: String,
         origin: String,
         descriptionBrand: String,
         perfumist: [String],
         createdAt: Date? = nil,
         updatedAt: Date? = nil) {
        self.id = id
        self.key = key
        self.name = name
        self.imageURL = imageURL
        self.origin = origin
        self.descriptionBrand = descriptionBrand
        self.perfumist = perfumist
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
