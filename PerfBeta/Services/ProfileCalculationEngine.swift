import Foundation

/// Motor de cálculo de perfiles olfativos
/// Responsable de extraer y calcular puntuaciones de familias, metadata y preferencias
/// Sigue SRP: solo se encarga de cálculos, no de navegación ni UI
final class ProfileCalculationEngine {

    // MARK: - Singleton
    static let shared = ProfileCalculationEngine()

    private init() {}

    // MARK: - Family Score Calculation

    /// Extrae las familias olfativas con sus puntuaciones de las respuestas
    /// - Parameters:
    ///   - responses: Diccionario de respuestas [questionId: response]
    ///   - questions: Lista de preguntas para buscar las opciones
    /// - Returns: Diccionario de familias con sus puntuaciones acumuladas
    func extractFamilyScores(
        from responses: [String: UnifiedResponse],
        questions: [UnifiedQuestion]
    ) -> [String: Double] {
        var familyScores: [String: Double] = [:]

        for (questionId, response) in responses {
            guard let question = questions.first(where: { $0.id == questionId }) else { continue }

            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else { continue }

                for (family, score) in option.families {
                    familyScores[family, default: 0] += Double(score)
                }
            }
        }

        #if DEBUG
        print("📊 [ProfileCalculationEngine] Family scores extracted:")
        for (family, score) in familyScores.sorted(by: { $0.value > $1.value }) {
            print("   \(family): \(score)")
        }
        #endif

        return familyScores
    }

    /// Normaliza las puntuaciones de familias a un rango de 0-100
    func normalizeFamilyScores(_ scores: [String: Double]) -> [String: Double] {
        guard let maxScore = scores.values.max(), maxScore > 0 else {
            return scores
        }

        let factor = 100.0 / maxScore
        return scores.mapValues { $0 * factor }
    }

    // MARK: - Metadata Extraction

    /// Extrae metadata unificado de las respuestas
    func extractMetadata(
        from responses: [String: UnifiedResponse],
        questions: [UnifiedQuestion]
    ) -> UnifiedProfileMetadata {
        var metadata = UnifiedProfileMetadata()

        var allPersonalities: [String] = []
        var allOccasions: [String] = []
        var allSeasons: [String] = []
        var allAvoidFamilies: [String] = []
        var allMustContainNotes: [String] = []
        var allHeartNotesBonus: [String] = []
        var allBaseNotesBonus: [String] = []

        var lastIntensity: String?
        var lastIntensityMax: String?
        var lastDuration: String?
        var lastProjection: String?
        var lastDiscoveryMode: String?
        var lastStructurePreference: String?
        var lastPhasePreference: String?

        for (questionId, response) in responses {
            guard let question = questions.first(where: { $0.id == questionId }) else { continue }

            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else { continue }
                guard let optionMetadata = option.metadata else { continue }

                // Acumular listas
                if let personalities = optionMetadata.personality {
                    allPersonalities.append(contentsOf: personalities)
                }
                if let occasions = optionMetadata.occasion {
                    allOccasions.append(contentsOf: occasions)
                }
                if let seasons = optionMetadata.season {
                    allSeasons.append(contentsOf: seasons)
                }
                if let avoidFamilies = optionMetadata.avoidFamilies {
                    allAvoidFamilies.append(contentsOf: avoidFamilies)
                }
                if let mustContain = optionMetadata.mustContainNotes {
                    allMustContainNotes.append(contentsOf: mustContain)
                }
                if let heartBonus = optionMetadata.heartNotesBonus {
                    allHeartNotesBonus.append(contentsOf: heartBonus)
                }
                if let baseBonus = optionMetadata.baseNotesBonus {
                    allBaseNotesBonus.append(contentsOf: baseBonus)
                }

                // Últimos valores ganan
                if let intensity = optionMetadata.intensity {
                    lastIntensity = intensity
                }
                if let intensityMax = optionMetadata.intensityMax {
                    lastIntensityMax = intensityMax
                }
                if let duration = optionMetadata.duration {
                    lastDuration = duration
                }
                if let projection = optionMetadata.projection {
                    lastProjection = projection
                }
                if let discoveryMode = optionMetadata.discoveryMode {
                    lastDiscoveryMode = discoveryMode
                }
                if let structure = optionMetadata.phasePreference {
                    lastStructurePreference = structure
                }
                if let phase = optionMetadata.phasePreference {
                    lastPhasePreference = phase
                }
            }
        }

        // Asignar a metadata (eliminando duplicados en arrays)
        metadata.personalityTraits = Array(Set(allPersonalities))
        metadata.preferredOccasions = Array(Set(allOccasions))
        metadata.preferredSeasons = Array(Set(allSeasons))
        metadata.avoidFamilies = allAvoidFamilies.isEmpty ? nil : Array(Set(allAvoidFamilies))
        metadata.mustContainNotes = allMustContainNotes.isEmpty ? nil : Array(Set(allMustContainNotes))
        metadata.heartNotesBonus = allHeartNotesBonus.isEmpty ? nil : Array(Set(allHeartNotesBonus))
        metadata.baseNotesBonus = allBaseNotesBonus.isEmpty ? nil : Array(Set(allBaseNotesBonus))

        metadata.intensityPreference = lastIntensity
        metadata.intensityMax = lastIntensityMax
        metadata.durationPreference = lastDuration
        metadata.projectionPreference = lastProjection
        metadata.discoveryMode = lastDiscoveryMode
        metadata.structurePreference = lastStructurePreference
        metadata.phasePreference = lastPhasePreference

        return metadata
    }

    // MARK: - Gender Preference

    /// Extrae el género preferido de las respuestas
    func extractGenderPreference(
        from responses: [String: UnifiedResponse],
        questions: [UnifiedQuestion]
    ) -> String {
        for (questionId, response) in responses {
            guard let question = questions.first(where: { $0.id == questionId }) else { continue }

            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else { continue }
                guard let optionMetadata = option.metadata else { continue }

                if let genderType = optionMetadata.genderType {
                    switch genderType {
                    case "masculine": return "male"
                    case "feminine": return "female"
                    case "unisex": return "unisex"
                    case "all": return "any"
                    default: return genderType
                    }
                }
            }
        }

        return "unisex"
    }

    // MARK: - Profile Generation

    /// Genera un UnifiedProfile completo desde las respuestas
    func generateProfile(
        name: String,
        profileType: ProfileType,
        responses: [String: UnifiedResponse],
        questions: [UnifiedQuestion],
        currentFlow: String?
    ) -> UnifiedProfile {
        let familyScores = extractFamilyScores(from: responses, questions: questions)
        let metadata = extractMetadata(from: responses, questions: questions)
        let genderPreference = extractGenderPreference(from: responses, questions: questions)

        // Determinar familia principal
        let primaryFamily = familyScores.max(by: { $0.value < $1.value })?.key ?? "unknown"

        // Subfamilias (top 3 excluyendo la principal)
        let subfamilies = familyScores
            .filter { $0.key != primaryFamily }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }

        // Normalizar scores
        let normalizedScores = normalizeFamilyScores(familyScores)

        // Calcular confianza
        let answerCompleteness = Double(responses.count) / Double(max(questions.count, 1))
        let confidenceScore = min(answerCompleteness * 1.2, 1.0)

        // Determinar nivel de experiencia
        let experienceLevel = determineExperienceLevel(from: currentFlow)

        let profile = UnifiedProfile(
            name: name,
            profileType: profileType,
            experienceLevel: experienceLevel,
            primaryFamily: primaryFamily,
            subfamilies: Array(subfamilies),
            familyScores: normalizedScores,
            genderPreference: genderPreference,
            metadata: metadata,
            confidenceScore: confidenceScore,
            answerCompleteness: answerCompleteness,
            orderIndex: 0
        )

        #if DEBUG
        print("✅ [ProfileCalculationEngine] Generated profile:")
        print("   Name: \(profile.name)")
        print("   Type: \(profile.profileType.rawValue)")
        print("   Primary Family: \(profile.primaryFamily)")
        print("   Confidence: \(String(format: "%.2f", profile.confidenceScore))")
        #endif

        return profile
    }

    // MARK: - Private Helpers

    private func determineExperienceLevel(from flow: String?) -> ExperienceLevel {
        guard let flow = flow else { return .beginner }

        if flow.contains("_A") || flow == "flow_A" {
            return .beginner
        } else if flow.contains("_B") || flow == "flow_B" {
            return .intermediate
        } else if flow.contains("_C") || flow == "flow_C" {
            return .expert
        }

        return .beginner
    }
}
