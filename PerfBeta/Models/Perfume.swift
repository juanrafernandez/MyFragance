import Foundation

struct Perfume: Identifiable, Codable, Equatable {
    var id: String // Assigned from document ID after decoding
    var name: String
    var brand: String // Brand slug: "dior", "chanel"
    var brandName: String? // Display name: "Dior", "Chanel" (NEW - from flat structure)
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
    var popularity: Double? // Optional - some perfumes don't have this field in Firestore
    var year: Int? // Optional - some perfumes don't have this field in Firestore
    var perfumist: String?
    var imageURL: String?
    var description: String
    var gender: String
    var price: String?
    var searchTerms: [String]? // NEW - for efficient search in flat structure
    var createdAt: Date?
    var updatedAt: Date?

    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, name, brand, brandName, key, family, subfamilies
        case topNotes, heartNotes, baseNotes
        case projection, intensity, duration
        case recommendedSeason, associatedPersonalities, occasion
        case popularity, year, perfumist, imageURL, description, gender, price
        case searchTerms, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // ID is optional during decoding - will be set from document ID
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""

        self.name = try container.decode(String.self, forKey: .name)
        self.brand = try container.decode(String.self, forKey: .brand)
        self.brandName = try container.decodeIfPresent(String.self, forKey: .brandName)
        self.key = try container.decode(String.self, forKey: .key)
        self.family = try container.decode(String.self, forKey: .family)
        self.subfamilies = try container.decode([String].self, forKey: .subfamilies)
        self.topNotes = try container.decodeIfPresent([String].self, forKey: .topNotes)
        self.heartNotes = try container.decodeIfPresent([String].self, forKey: .heartNotes)
        self.baseNotes = try container.decodeIfPresent([String].self, forKey: .baseNotes)
        self.projection = try container.decode(String.self, forKey: .projection)
        self.intensity = try container.decode(String.self, forKey: .intensity)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.recommendedSeason = try container.decode([String].self, forKey: .recommendedSeason)
        self.associatedPersonalities = try container.decode([String].self, forKey: .associatedPersonalities)
        self.occasion = try container.decode([String].self, forKey: .occasion)
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity)
        self.year = try container.decodeIfPresent(Int.self, forKey: .year)
        self.perfumist = try container.decodeIfPresent(String.self, forKey: .perfumist)
        self.imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        self.description = try container.decode(String.self, forKey: .description)
        self.gender = try container.decode(String.self, forKey: .gender)
        self.price = try container.decodeIfPresent(String.self, forKey: .price)
        self.searchTerms = try container.decodeIfPresent([String].self, forKey: .searchTerms)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(brand, forKey: .brand)
        try container.encodeIfPresent(brandName, forKey: .brandName)
        try container.encode(key, forKey: .key)
        try container.encode(family, forKey: .family)
        try container.encode(subfamilies, forKey: .subfamilies)
        try container.encodeIfPresent(topNotes, forKey: .topNotes)
        try container.encodeIfPresent(heartNotes, forKey: .heartNotes)
        try container.encodeIfPresent(baseNotes, forKey: .baseNotes)
        try container.encode(projection, forKey: .projection)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(duration, forKey: .duration)
        try container.encode(recommendedSeason, forKey: .recommendedSeason)
        try container.encode(associatedPersonalities, forKey: .associatedPersonalities)
        try container.encode(occasion, forKey: .occasion)
        try container.encodeIfPresent(popularity, forKey: .popularity)
        try container.encodeIfPresent(year, forKey: .year)
        try container.encodeIfPresent(perfumist, forKey: .perfumist)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(description, forKey: .description)
        try container.encode(gender, forKey: .gender)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(searchTerms, forKey: .searchTerms)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    init(
        id: String? = nil,
        name: String,
        brand: String,
        brandName: String? = nil,
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
        popularity: Double? = nil,
        year: Int? = nil,
        perfumist: String? = nil,
        imageURL: String,
        description: String,
        gender: String,
        price: String? = nil,
        searchTerms: [String]? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.name = name
        self.brand = brand
        self.brandName = brandName
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
        self.searchTerms = searchTerms
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
