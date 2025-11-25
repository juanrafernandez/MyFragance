import Foundation

// MARK: - Profile Calculation Helpers
/// Funciones auxiliares para el cálculo de perfiles olfativos
struct ProfileCalculationHelpers {

    // MARK: - Experience Level Detection

    /// Determina el nivel de experiencia según las preguntas respondidas
    static func determineExperienceLevel(from answers: [String: (question: Question, option: Option)]) -> ExperienceLevel {
        let questionIds = answers.keys

        if questionIds.contains(where: { $0.contains("profile_C") }) {
            return .expert
        } else if questionIds.contains(where: { $0.contains("profile_B") }) {
            return .intermediate
        } else {
            return .beginner
        }
    }

    // MARK: - Default Weight

    /// Obtiene weight por defecto basándose en el tipo de pregunta
    static func getDefaultWeight(for questionKey: String) -> Int {
        if questionKey.contains("gender") ||
           questionKey.contains("intensity") ||
           questionKey.contains("concentration") {
            return 0
        }

        if questionKey.contains("preference") ||
           questionKey.contains("simple_preference") ||
           questionKey.contains("mixed_preference") ||
           questionKey.contains("structure") {
            return 3
        }

        if questionKey.contains("feeling") ||
           questionKey.contains("personality") ||
           questionKey.contains("discovery") {
            return 2
        }

        if questionKey.contains("time") ||
           questionKey.contains("season") ||
           questionKey.contains("occasion") ||
           questionKey.contains("balance") {
            return 1
        }

        return 1
    }

    // MARK: - Family Score Normalization

    /// Normaliza scores de familias a escala 0-100
    static func normalizeFamilyScores(_ scores: [String: Double]) -> [String: Double] {
        guard let maxScore = scores.values.max(), maxScore > 0 else {
            return scores
        }

        let normalizationFactor = 100.0 / maxScore
        return scores.mapValues { $0 * normalizationFactor }
    }

    // MARK: - Primary Families Determination

    /// Determina familia principal y subfamilias
    static func determinePrimaryFamilies(from scores: [String: Double]) -> (primary: String, subfamilies: [String]) {
        let sorted = scores.sorted { $0.value > $1.value }

        guard let primary = sorted.first?.key else {
            return ("unknown", [])
        }

        let subfamilies = sorted.dropFirst().prefix(3).map { $0.key }
        return (primary, Array(subfamilies))
    }

    // MARK: - Confidence Calculation

    /// Calcula confianza del perfil (0.0 - 1.0)
    static func calculateConfidence(scores: [String: Double], completeness: Double) -> Double {
        let sorted = scores.sorted { $0.value > $1.value }
        let clarity: Double
        if sorted.count >= 2 {
            let diff = sorted[0].value - sorted[1].value
            clarity = min(diff / 50.0, 1.0)
        } else {
            clarity = 1.0
        }

        return (clarity * 0.6) + (completeness * 0.4)
    }

    // MARK: - Completeness Calculation

    /// Calcula completitud de respuestas (0.0 - 1.0)
    static func calculateCompleteness(answers: [String: (question: Question, option: Option)], experienceLevel: ExperienceLevel) -> Double {
        let expectedQuestions: Double
        switch experienceLevel {
        case .beginner: expectedQuestions = 6.0
        case .intermediate: expectedQuestions = 7.0
        case .expert: expectedQuestions = 8.0
        }

        return min(Double(answers.count) / expectedQuestions, 1.0)
    }

    // MARK: - Metadata Extraction

    /// Extrae metadata de una opción y la agrega al metadata del perfil
    static func extractMetadata(from optionMeta: OptionMetadata, into metadata: inout UnifiedProfileMetadata) {
        if let occasion = optionMeta.occasion {
            metadata.preferredOccasions = (metadata.preferredOccasions ?? []) + occasion
        }

        if let season = optionMeta.season {
            metadata.preferredSeasons = (metadata.preferredSeasons ?? []) + season
        }

        if let personality = optionMeta.personality {
            metadata.personalityTraits = (metadata.personalityTraits ?? []) + personality
        }

        if let intensity = optionMeta.intensity {
            metadata.intensityPreference = intensity
        }

        if let intensityMax = optionMeta.intensityMax {
            metadata.intensityMax = intensityMax
        }

        if let duration = optionMeta.duration {
            metadata.durationPreference = duration
        }

        if let projection = optionMeta.projection {
            metadata.projectionPreference = projection
        }

        if let avoidFamilies = optionMeta.avoidFamilies {
            metadata.avoidFamilies = (metadata.avoidFamilies ?? []) + avoidFamilies
        }

        if let mustContainNotes = optionMeta.mustContainNotes {
            metadata.mustContainNotes = (metadata.mustContainNotes ?? []) + mustContainNotes
        }

        if let heartNotesBonus = optionMeta.heartNotesBonus {
            metadata.heartNotesBonus = (metadata.heartNotesBonus ?? []) + heartNotesBonus
        }

        if let baseNotesBonus = optionMeta.baseNotesBonus {
            metadata.baseNotesBonus = (metadata.baseNotesBonus ?? []) + baseNotesBonus
        }

        if let phasePreference = optionMeta.phasePreference {
            metadata.phasePreference = phasePreference
        }

        if let discoveryMode = optionMeta.discoveryMode {
            metadata.discoveryMode = discoveryMode
        }
    }
}
