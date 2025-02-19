import Foundation

struct OlfactiveProfile: Identifiable, Codable, Equatable, Hashable {
    var id: String?
    var name: String
    var gender: String
    var families: [FamilyPuntuation]
    var intensity: String
    var duration: String
    var descriptionProfile: String?
    var icon: String?
    var questionsAndAnswers: [QuestionAnswer]?

    // NUEVO: Lista de perfumes recomendados
    var recommendedPerfumes: [RecommendedPerfume]?

    // Inicializador principal
    init(
        id: String? = nil,
        name: String,
        gender: String,
        families: [FamilyPuntuation],
        intensity: String,
        duration: String,
        descriptionProfile: String? = nil,
        icon: String? = nil,
        questionsAndAnswers: [QuestionAnswer]? = nil,
        recommendedPerfumes: [RecommendedPerfume]? = nil
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.families = families
        self.intensity = intensity
        self.duration = duration
        self.descriptionProfile = descriptionProfile
        self.icon = icon
        self.questionsAndAnswers = questionsAndAnswers
        self.recommendedPerfumes = recommendedPerfumes
    }

    // Propiedad computada para descripción compacta
    var compactDescription: String {
        descriptionProfile ?? "Descripción no disponible"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    static func == (lhs: OlfactiveProfile, rhs: OlfactiveProfile) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

struct FamilyPuntuation: Codable, Equatable, Hashable {
    var family: String
    var puntuation: Int
}

// NUEVO: Estructura para representar un perfume recomendado
struct RecommendedPerfume: Codable, Equatable, Hashable {
    var perfumeId: String // ID del perfume
    var matchPercentage: Double // Porcentaje de coincidencia con el perfil
}
