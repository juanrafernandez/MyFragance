import Foundation

struct Perfume: Identifiable, Codable, Equatable {
    var id: String?
    var name: String
    var brand: String
    var key: String
    var family: String
    var subfamilies: [String]
    var topNotes: [String]?
    var heartNotes: [String]?
    var baseNotes: [String]?
    var projection: String
    var intensity: String
    var duration: String
    var recommendedSeason: [String]
    var associatedPersonalities: [String]
    var occasion: [String]
    var popularity: Double
    var year: Int
    var perfumist: String?
    var imageURL: String?
    var description: String
    var gender: String
    var price: String?
    var createdAt: Date?
    var updatedAt: Date?

    init(
        id: String? = nil,
        name: String,
        brand: String,
        key: String,
        family: String,
        subfamilies: [String] = [],
        topNotes: [String] = [],
        heartNotes: [String] = [],
        baseNotes: [String] = [],
        projection: String,
        intensity: String,
        duration: String,
        recommendedSeason: [String] = [],
        associatedPersonalities: [String] = [],
        occasion: [String] = [],
        popularity: Double = -1,
        year: Int,
        perfumist: String,
        imageURL: String,
        description: String,
        gender: String,
        price: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.name = name
        self.brand = brand
        self.key = key
        self.family = family
        self.subfamilies = subfamilies
        self.topNotes = topNotes
        self.heartNotes = heartNotes
        self.baseNotes = baseNotes
        self.projection = projection
        self.intensity = intensity
        self.duration = duration
        self.recommendedSeason = recommendedSeason
        self.associatedPersonalities = associatedPersonalities
        self.occasion = occasion
        self.popularity = popularity
        self.year = year
        self.perfumist = perfumist
        self.imageURL = imageURL
        self.description = description
        self.gender = gender
        self.price = price
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Extensiones
extension Perfume {
    /// Convertir a diccionario para usar en Firebase
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "PerfumeRemote", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error converting to dictionary"])
        }
        return dictionary
    }
}
