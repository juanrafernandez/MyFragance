import Foundation

struct Family: Identifiable, Codable, Equatable {
    var id: String?
    var key: String
    var name: String
    var familyDescription: String
    var keyNotes: [String]
    var associatedIngredients: [String]
    var averageIntensity: String
    var recommendedSeason: [String]
    var associatedPersonality: [String]
    var occasion: [String]
    var familyColor: String
    var createdAt: Date?
    var updatedAt: Date?

    init(
        id: String = UUID().uuidString,
        key: String,
        name: String,
        familyDescription: String,
        keyNotes: [String],
        associatedIngredients: [String],
        averageIntensity: String,
        recommendedSeason: [String],
        associatedPersonality: [String],
        occasion: [String],
        familyColor: String,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.key = key
        self.name = name
        self.familyDescription = familyDescription
        self.keyNotes = keyNotes
        self.associatedIngredients = associatedIngredients
        self.averageIntensity = averageIntensity
        self.recommendedSeason = recommendedSeason
        self.associatedPersonality = associatedPersonality
        self.occasion = occasion
        self.familyColor = familyColor
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Familia por defecto
    static var defaultFamily: Family {
        return Family(
            id: UUID().uuidString,
            key: "default",
            name: "Familia Desconocida",
            familyDescription: "Esta es una familia predeterminada utilizada cuando no se encuentra la familia real.",
            keyNotes: [],
            associatedIngredients: [],
            averageIntensity: "Media",
            recommendedSeason: [],
            associatedPersonality: [],
            occasion: [],
            familyColor: "#CCCCCC"
        )
    }
}
