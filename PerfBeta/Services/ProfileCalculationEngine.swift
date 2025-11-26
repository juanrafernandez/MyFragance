import Foundation

/// Motor de cálculo de perfiles olfativos
/// UNIFICADO: Delega todos los cálculos a UnifiedRecommendationEngine para tener una sola fuente de verdad
/// Mantiene la API existente para compatibilidad con UnifiedQuestionFlowViewModel
final class ProfileCalculationEngine {

    // MARK: - Singleton
    static let shared = ProfileCalculationEngine()

    private init() {}

    // MARK: - Profile Generation (Delegated to UnifiedRecommendationEngine)

    /// Genera un UnifiedProfile completo desde las respuestas
    /// Delega a UnifiedRecommendationEngine para cálculos consistentes
    func generateProfile(
        name: String,
        profileType: ProfileType,
        responses: [String: UnifiedResponse],
        questions: [UnifiedQuestion],
        currentFlow: String?
    ) async -> UnifiedProfile {
        // Convertir UnifiedQuestion/UnifiedResponse a Question/Option format
        let convertedAnswers = convertToLegacyFormat(responses: responses, questions: questions)

        #if DEBUG
        print("")
        print("═══════════════════════════════════════════════════════════════════")
        print("🔄 [ProfileCalculationEngine] Delegando a UnifiedRecommendationEngine")
        print("═══════════════════════════════════════════════════════════════════")
        print("🔄 [ProfileCalculationEngine] Respuestas convertidas: \(convertedAnswers.count)")
        #endif

        // Delegar el cálculo a UnifiedRecommendationEngine
        let profile = await UnifiedRecommendationEngine.shared.calculateProfile(
            from: convertedAnswers,
            profileName: name,
            profileType: profileType
        )

        #if DEBUG
        print("🔄 [ProfileCalculationEngine] ✅ Perfil generado via UnifiedRecommendationEngine")
        print("═══════════════════════════════════════════════════════════════════")
        print("")
        #endif

        return profile
    }

    /// Versión síncrona que usa Task para compatibilidad
    /// DEPRECATED: Usar la versión async cuando sea posible
    func generateProfile(
        name: String,
        profileType: ProfileType,
        responses: [String: UnifiedResponse],
        questions: [UnifiedQuestion],
        currentFlow: String?
    ) -> UnifiedProfile {
        // Fallback síncrono para compatibilidad
        // Usa la implementación local simple para casos donde no podemos usar async
        return generateProfileSync(
            name: name,
            profileType: profileType,
            responses: responses,
            questions: questions,
            currentFlow: currentFlow
        )
    }

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

        #if DEBUG
        print("📊 [ProfileCalculationEngine] Extracting family scores from \(responses.count) responses")
        #endif

        for (questionId, response) in responses {
            guard let question = questions.first(where: { $0.id == questionId }) else {
                #if DEBUG
                print("   ⚠️ Question not found: \(questionId)")
                #endif
                continue
            }

            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else {
                    #if DEBUG
                    print("   ⚠️ Option not found: \(optionId) in question \(questionId)")
                    #endif
                    continue
                }

                // Obtener weight de la pregunta (por defecto 1)
                let weight = getQuestionWeight(question)

                #if DEBUG
                if option.families.isEmpty {
                    print("   ⚠️ Empty families for option '\(option.label)' in question '\(question.text.prefix(30))...'")
                } else {
                    print("   ✅ Option '\(option.label)' has families: \(option.families)")
                }
                #endif

                for (family, score) in option.families {
                    familyScores[family, default: 0] += Double(score) * Double(weight)
                }
            }
        }

        // Aplicar penalización por familias a evitar (consistente con UnifiedRecommendationEngine)
        let avoidFamilies = extractAvoidFamilies(from: responses, questions: questions)
        if !avoidFamilies.isEmpty {
            #if DEBUG
            print("📊 [ProfileCalculationEngine] Aplicando penalizaciones a familias a evitar...")
            #endif

            for avoidFamily in avoidFamilies {
                let normalizedAvoidFamily = avoidFamily.lowercased()
                for (family, currentScore) in familyScores {
                    if family.lowercased() == normalizedAvoidFamily {
                        let originalScore = currentScore
                        familyScores[family] = currentScore * 0.2  // Reducir al 20%
                        #if DEBUG
                        print("📊 [ProfileCalculationEngine]   🚫 \(family): \(String(format: "%.1f", originalScore)) → \(String(format: "%.1f", familyScores[family]!)) (-80%)")
                        #endif
                    }
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
        var allPreferredNotes: [String] = []

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

            // Capturar notas de autocomplete
            if question.isAutocompleteNotes, let textInput = response.textInput {
                let notes = textInput.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                allPreferredNotes.append(contentsOf: notes)
            }
        }

        // Asignar a metadata (eliminando duplicados en arrays)
        metadata.personalityTraits = allPersonalities.isEmpty ? nil : Array(Set(allPersonalities))
        metadata.preferredOccasions = allOccasions.isEmpty ? nil : Array(Set(allOccasions))
        metadata.preferredSeasons = allSeasons.isEmpty ? nil : Array(Set(allSeasons))
        metadata.avoidFamilies = allAvoidFamilies.isEmpty ? nil : Array(Set(allAvoidFamilies))
        metadata.mustContainNotes = allMustContainNotes.isEmpty ? nil : Array(Set(allMustContainNotes))
        metadata.heartNotesBonus = allHeartNotesBonus.isEmpty ? nil : Array(Set(allHeartNotesBonus))
        metadata.baseNotesBonus = allBaseNotesBonus.isEmpty ? nil : Array(Set(allBaseNotesBonus))
        metadata.preferredNotes = allPreferredNotes.isEmpty ? nil : Array(Set(allPreferredNotes))

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

    // MARK: - Private Helpers

    /// Extrae familias a evitar de las respuestas
    private func extractAvoidFamilies(
        from responses: [String: UnifiedResponse],
        questions: [UnifiedQuestion]
    ) -> [String] {
        var avoidFamilies: [String] = []

        for (questionId, response) in responses {
            guard let question = questions.first(where: { $0.id == questionId }) else { continue }

            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else { continue }
                guard let optionMetadata = option.metadata else { continue }

                if let families = optionMetadata.avoidFamilies {
                    avoidFamilies.append(contentsOf: families)
                }
            }
        }

        return Array(Set(avoidFamilies))
    }

    /// Obtiene el peso de una pregunta basándose en su tipo
    private func getQuestionWeight(_ question: UnifiedQuestion) -> Int {
        // Preguntas de metadata (weight = 0)
        if question.questionType == "routing" ||
           question.id.contains("gender") ||
           question.id.contains("intensity") && question.id.contains("preference") {
            return 0
        }

        // Preguntas clave de preferencias (weight = 3)
        if question.id.contains("preference") ||
           question.id.contains("simple_preference") ||
           question.id.contains("mixed_preference") ||
           question.id.contains("structure") {
            return 3
        }

        // Preguntas de sentimientos/emociones (weight = 2)
        if question.id.contains("feeling") ||
           question.id.contains("personality") ||
           question.id.contains("discovery") {
            return 2
        }

        // Preguntas contextuales (weight = 1)
        if question.id.contains("time") ||
           question.id.contains("season") ||
           question.id.contains("occasion") ||
           question.id.contains("balance") {
            return 1
        }

        return 1
    }

    private func determineExperienceLevel(from flow: String?) -> ExperienceLevel {
        guard let flow = flow else { return .beginner }

        if flow.contains("_A") || flow == "flow_A" || flow.contains("profile_A") {
            return .beginner
        } else if flow.contains("_B") || flow == "flow_B" || flow.contains("profile_B") {
            return .intermediate
        } else if flow.contains("_C") || flow == "flow_C" || flow.contains("profile_C") {
            return .expert
        }

        return .beginner
    }

    // MARK: - Sync Profile Generation (Fallback)

    /// Versión síncrona del generador de perfiles (para compatibilidad)
    private func generateProfileSync(
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

        // Crear questionsAndAnswers para guardar el historial
        let questionsAndAnswers = responses.map { (questionId, response) -> QuestionAnswer in
            QuestionAnswer(
                questionId: questionId,
                answerId: response.selectedOptionIds.first ?? ""
            )
        }

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
            orderIndex: 0,
            questionsAndAnswers: questionsAndAnswers
        )

        #if DEBUG
        print("")
        print("═══════════════════════════════════════════════════════════════════")
        print("✅ [ProfileCalculationEngine] Generated profile (sync):")
        print("═══════════════════════════════════════════════════════════════════")
        print("   Name: \(profile.name)")
        print("   Type: \(profile.profileType.rawValue)")
        print("   Primary Family: \(profile.primaryFamily)")
        print("   Subfamilies: \(profile.subfamilies.joined(separator: ", "))")
        print("   Confidence: \(String(format: "%.2f", profile.confidenceScore))")
        print("")
        print("   Family Scores (normalized 0-100):")
        for (family, score) in normalizedScores.sorted(by: { $0.value > $1.value }) {
            print("     • \(family): \(String(format: "%.1f", score))")
        }
        print("═══════════════════════════════════════════════════════════════════")
        print("")
        #endif

        return profile
    }

    // MARK: - Format Conversion

    /// Convierte UnifiedQuestion/UnifiedResponse a formato Question/Option
    /// Necesario para delegar a UnifiedRecommendationEngine
    private func convertToLegacyFormat(
        responses: [String: UnifiedResponse],
        questions: [UnifiedQuestion]
    ) -> [String: (question: Question, option: Option)] {
        var result: [String: (question: Question, option: Option)] = [:]

        for (questionId, response) in responses {
            guard let unifiedQuestion = questions.first(where: { $0.id == questionId }) else { continue }
            guard let selectedOptionId = response.selectedOptionIds.first else { continue }
            guard let unifiedOption = unifiedQuestion.options.first(where: { $0.id == selectedOptionId }) else { continue }

            // Convertir UnifiedQuestion a Question
            let question = Question(
                id: unifiedQuestion.id,
                key: unifiedQuestion.id,
                questionType: unifiedQuestion.questionType,
                order: unifiedQuestion.order,
                category: unifiedQuestion.category,
                text: unifiedQuestion.text,
                subtitle: unifiedQuestion.subtitle,
                multiSelect: unifiedQuestion.allowsMultipleSelection,
                minSelections: unifiedQuestion.minSelection,
                maxSelections: unifiedQuestion.maxSelection,
                weight: unifiedQuestion.weight,
                dataSource: unifiedQuestion.dataSource,
                isConditional: unifiedQuestion.isConditional,
                conditionalRules: unifiedQuestion.conditionalRules,
                options: unifiedQuestion.options.map { opt in
                    Option(
                        id: opt.id,
                        label: opt.label,
                        value: opt.value,
                        description: opt.description ?? "",
                        image_asset: "",
                        families: opt.families,
                        metadata: opt.metadata,
                        nextFlow: opt.route
                    )
                }
            )

            // Convertir UnifiedOption a Option
            let option = Option(
                id: unifiedOption.id,
                label: unifiedOption.label,
                value: unifiedOption.value,
                description: unifiedOption.description ?? "",
                image_asset: "",
                families: unifiedOption.families,
                metadata: unifiedOption.metadata,
                nextFlow: unifiedOption.route
            )

            result[questionId] = (question: question, option: option)
        }

        return result
    }
}
