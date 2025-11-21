import Foundation

// MARK: - Unified Profile
/// Nuevo modelo unificado de perfil que reemplaza OlfactiveProfile y GiftProfile
/// Compatible con flujos personales (A/B/C) y flujos de regalo
struct UnifiedProfile: Identifiable, Codable, Equatable, Hashable {

    // MARK: - Identificación
    var id: String?
    var name: String
    var profileType: ProfileType
    var createdDate: Date
    var experienceLevel: ExperienceLevel

    // MARK: - Core Olfativo (siempre presente)
    var primaryFamily: String
    var subfamilies: [String]
    var familyScores: [String: Double]  // Normalizado a 0-100

    // MARK: - Filtros Principales
    var genderPreference: String  // "male", "female", "unisex"

    // MARK: - Metadata de Preferencias
    var metadata: UnifiedProfileMetadata

    // MARK: - Sistema de Confianza
    var confidenceScore: Double      // 0.0 - 1.0
    var answerCompleteness: Double   // 0.0 - 1.0

    // MARK: - Perfumes Recomendados
    var recommendedPerfumes: [RecommendedPerfume]?

    // MARK: - Legacy (para compatibilidad con sistema anterior)
    var orderIndex: Int
    var descriptionProfile: String?
    var icon: String?
    var questionsAndAnswers: [QuestionAnswer]?

    init(
        id: String? = nil,
        name: String,
        profileType: ProfileType = .personal,
        createdDate: Date = Date(),
        experienceLevel: ExperienceLevel = .beginner,
        primaryFamily: String,
        subfamilies: [String] = [],
        familyScores: [String: Double] = [:],
        genderPreference: String = "unisex",
        metadata: UnifiedProfileMetadata = UnifiedProfileMetadata(),
        confidenceScore: Double = 0.0,
        answerCompleteness: Double = 0.0,
        recommendedPerfumes: [RecommendedPerfume]? = nil,
        orderIndex: Int = 0,
        descriptionProfile: String? = nil,
        icon: String? = nil,
        questionsAndAnswers: [QuestionAnswer]? = nil
    ) {
        self.id = id
        self.name = name
        self.profileType = profileType
        self.createdDate = createdDate
        self.experienceLevel = experienceLevel
        self.primaryFamily = primaryFamily
        self.subfamilies = subfamilies
        self.familyScores = familyScores
        self.genderPreference = genderPreference
        self.metadata = metadata
        self.confidenceScore = confidenceScore
        self.answerCompleteness = answerCompleteness
        self.recommendedPerfumes = recommendedPerfumes
        self.orderIndex = orderIndex
        self.descriptionProfile = descriptionProfile
        self.icon = icon
        self.questionsAndAnswers = questionsAndAnswers
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    static func == (lhs: UnifiedProfile, rhs: UnifiedProfile) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

// MARK: - Profile Type
enum ProfileType: String, Codable {
    case personal = "personal"
    case gift = "gift"
}

// MARK: - Experience Level
enum ExperienceLevel: String, Codable {
    case beginner = "beginner"       // Flujo A
    case intermediate = "intermediate" // Flujo B
    case expert = "expert"            // Flujo C
}

// MARK: - Profile Metadata
struct UnifiedProfileMetadata: Codable, Equatable {
    // Notas (opcionales)
    var preferredNotes: [String]?
    var avoidFamilies: [String]?

    // Referencias (opcional)
    var referencePerfumes: [String]?

    // Performance
    var intensityPreference: String?      // "low", "medium", "high", "very_high"
    var intensityMax: String?             // NEW (Profile B): Límite máximo de intensidad
    var durationPreference: String?       // "short", "moderate", "long", "very_long"
    var projectionPreference: String?     // "low", "moderate", "high", "explosive"
    var concentrationPreference: String?  // "edt", "edp", "parfum", "oil", "varies"

    // Notas específicas (Profile B - Intermediate)
    var mustContainNotes: [String]?       // NEW: Notas que DEBEN estar presentes
    var heartNotesBonus: [String]?        // NEW: Bonus si están en heartNotes
    var baseNotesBonus: [String]?         // NEW: Bonus si están en baseNotes

    // Contexto
    var preferredSeasons: [String]?       // ["autumn", "winter"]
    var preferredOccasions: [String]?     // ["office", "daily_use", "nights"]
    var personalityTraits: [String]?      // ["elegant", "confident", "mysterious"]

    // Estructura (solo flujo C)
    var structurePreference: String?      // "linear", "pyramid", "top_heavy", "base_forward", "radial"
    var phasePreference: String?          // "top", "heart", "base", "all"

    // Regalo específico (solo gift flows)
    var recipientInfo: UnifiedRecipientInfo?

    // Discovery
    var discoveryMode: String?            // "safe", "moderate", "adventurous"

    init(
        preferredNotes: [String]? = nil,
        avoidFamilies: [String]? = nil,
        referencePerfumes: [String]? = nil,
        intensityPreference: String? = nil,
        intensityMax: String? = nil,
        durationPreference: String? = nil,
        projectionPreference: String? = nil,
        concentrationPreference: String? = nil,
        mustContainNotes: [String]? = nil,
        heartNotesBonus: [String]? = nil,
        baseNotesBonus: [String]? = nil,
        preferredSeasons: [String]? = nil,
        preferredOccasions: [String]? = nil,
        personalityTraits: [String]? = nil,
        structurePreference: String? = nil,
        phasePreference: String? = nil,
        recipientInfo: UnifiedRecipientInfo? = nil,
        discoveryMode: String? = nil
    ) {
        self.preferredNotes = preferredNotes
        self.avoidFamilies = avoidFamilies
        self.referencePerfumes = referencePerfumes
        self.intensityPreference = intensityPreference
        self.intensityMax = intensityMax
        self.durationPreference = durationPreference
        self.projectionPreference = projectionPreference
        self.concentrationPreference = concentrationPreference
        self.mustContainNotes = mustContainNotes
        self.heartNotesBonus = heartNotesBonus
        self.baseNotesBonus = baseNotesBonus
        self.preferredSeasons = preferredSeasons
        self.preferredOccasions = preferredOccasions
        self.personalityTraits = personalityTraits
        self.structurePreference = structurePreference
        self.phasePreference = phasePreference
        self.recipientInfo = recipientInfo
        self.discoveryMode = discoveryMode
    }
}

// MARK: - Recipient Info (for gift profiles)
struct UnifiedRecipientInfo: Codable, Equatable {
    var ageRange: String?       // "young", "adult", "mature", "senior"
    var lifestyle: String?      // "professional", "creative", "active", "social"
    var relationship: String?   // "partner", "friend", "family", "colleague"

    init(
        ageRange: String? = nil,
        lifestyle: String? = nil,
        relationship: String? = nil
    ) {
        self.ageRange = ageRange
        self.lifestyle = lifestyle
        self.relationship = relationship
    }
}

// MARK: - Extensions for Legacy Compatibility

extension UnifiedProfile {
    /// Convierte UnifiedProfile a OlfactiveProfile (legacy)
    func toLegacyProfile() -> OlfactiveProfile {
        let families = familyScores.map { key, value in
            FamilyPuntuation(family: key, puntuation: Int(value))
        }.sorted { $0.puntuation > $1.puntuation }

        return OlfactiveProfile(
            id: id,
            name: name,
            gender: genderPreference,
            families: families,
            intensity: metadata.intensityPreference ?? "medium",
            duration: metadata.durationPreference ?? "moderate",
            descriptionProfile: descriptionProfile,
            icon: icon,
            questionsAndAnswers: questionsAndAnswers,
            experienceLevel: experienceLevel.rawValue,
            recommendedPerfumes: recommendedPerfumes,
            orderIndex: orderIndex
        )
    }

    /// Crea UnifiedProfile desde OlfactiveProfile (legacy)
    static func fromLegacyProfile(_ legacy: OlfactiveProfile) -> UnifiedProfile {
        var familyScores: [String: Double] = [:]
        for family in legacy.families {
            familyScores[family.family] = Double(family.puntuation)
        }

        // Normalizar scores a 100
        if let maxScore = familyScores.values.max(), maxScore > 0 {
            let normalizationFactor = 100.0 / maxScore
            familyScores = familyScores.mapValues { $0 * normalizationFactor }
        }

        let primaryFamily = legacy.families.first?.family ?? "unknown"
        let subfamilies = legacy.families.dropFirst().map { $0.family }

        var metadata = UnifiedProfileMetadata()
        metadata.intensityPreference = legacy.intensity.lowercased()
        metadata.durationPreference = legacy.duration.lowercased()

        return UnifiedProfile(
            id: legacy.id,
            name: legacy.name,
            profileType: .personal,
            createdDate: Date(),
            experienceLevel: .beginner,
            primaryFamily: primaryFamily,
            subfamilies: Array(subfamilies),
            familyScores: familyScores,
            genderPreference: legacy.gender.lowercased(),
            metadata: metadata,
            confidenceScore: 0.7,  // Default
            answerCompleteness: 1.0,
            recommendedPerfumes: legacy.recommendedPerfumes,
            orderIndex: legacy.orderIndex,
            descriptionProfile: legacy.descriptionProfile,
            icon: legacy.icon,
            questionsAndAnswers: legacy.questionsAndAnswers
        )
    }
}
