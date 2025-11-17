import Foundation

// MARK: - Unified Recommendation Engine
/// Motor unificado de cálculo de perfiles y recomendaciones
/// Reemplaza tanto a OlfactiveProfileHelper como a GiftScoringEngine
actor UnifiedRecommendationEngine {

    static let shared = UnifiedRecommendationEngine()

    private init() {}

    // MARK: - Weight Profiles
    /// Pesos contextuales según tipo de perfil
    private struct WeightProfile {
        let families: Double
        let notes: Double
        let context: Double
        let popularity: Double
        let price: Double
        let occasion: Double
        let season: Double

        static let personal = WeightProfile(
            families: 0.60,      // 60% peso en familias olfativas
            notes: 0.20,         // 20% peso en notas específicas
            context: 0.10,       // 10% peso en contexto (ocasión/temporada)
            popularity: 0.05,    // 5% peso en popularidad
            price: 0.05,         // 5% peso en precio
            occasion: 0.05,      // Incluido en context
            season: 0.05         // Incluido en context
        )

        static let gift = WeightProfile(
            families: 0.40,      // 40% peso en familias
            notes: 0.10,         // 10% peso en notas
            context: 0.10,       // 10% peso en contexto general
            popularity: 0.20,    // 20% peso en popularidad (más importante para regalo)
            price: 0.10,         // 10% peso en precio
            occasion: 0.15,      // 15% peso en ocasión
            season: 0.05         // 5% peso en temporada
        )
    }

    // MARK: - Calculate Profile
    /// Calcula un perfil unificado a partir de respuestas
    func calculateProfile(
        from answers: [String: (question: Question, option: Option)],
        profileName: String,
        profileType: ProfileType = .personal
    ) async -> UnifiedProfile {

        #if DEBUG
        print("🧮 [UnifiedEngine] Calculating profile from \(answers.count) answers")
        #endif

        var familyScores: [String: Double] = [:]
        var metadata = UnifiedProfileMetadata()
        var genderPreference: String = "unisex"

        // Extraer nivel de experiencia según el tipo de preguntas
        let experienceLevel = determineExperienceLevel(from: answers)

        // Extraer género si existe (weight = 0, solo metadata)
        if let genderAnswer = answers.values.first(where: { $0.question.key.contains("gender") }) {
            genderPreference = genderAnswer.option.value
        }

        // REGLA 1: Solo preguntas con weight > 0 contribuyen a family_scores
        for (questionKey, (question, option)) in answers {
            // Usar weight de Firebase, o fallback basado en el tipo de pregunta
            let weight = question.weight ?? getDefaultWeight(for: questionKey)

            #if DEBUG
            print("  🔍 Procesando \(questionKey):")
            print("     - weight: \(weight) \(question.weight == nil ? "(fallback)" : "(Firebase)")")
            print("     - families en option: \(option.families)")
            print("     - option.label: \(option.label)")
            #endif

            if weight > 0 {
                // Acumular scores de familias con peso de la pregunta
                for (family, points) in option.families {
                    let contribution = Double(points * weight)
                    familyScores[family, default: 0.0] += contribution
                    #if DEBUG
                    print("  ➕ \(family): +\(contribution) pts (from \(questionKey), weight:\(weight))")
                    #endif
                }
            } else {
                #if DEBUG
                print("  ⚠️ Pregunta \(questionKey) tiene weight = 0, no contribuye a familias")
                #endif
            }

            // REGLA 4: weight = 0 significa solo metadata
            if weight == 0, let optionMeta = option.metadata {
                extractMetadata(from: optionMeta, into: &metadata)
            }

            // Extraer metadata siempre (independiente del weight)
            if let optionMeta = option.metadata {
                extractMetadata(from: optionMeta, into: &metadata)
            }

            // REGLA 2: Las notas preferidas NO suman a familias
            // Se guardan en metadata para bonus directo
            if question.dataSource == "notes_database" ||
               (question.key.contains("notes") && question.questionType == "autocomplete_multiple") {
                // Extraer notas preferidas del value (pueden ser múltiples separadas por coma)
                let selectedNotes = option.value.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                metadata.preferredNotes = (metadata.preferredNotes ?? []) + selectedNotes

                #if DEBUG
                print("  📝 Notas preferidas agregadas: \(selectedNotes.joined(separator: ", "))")
                #endif
            }

            // REGLA 3: Los perfumes de referencia SÍ suman a familias
            if question.dataSource == "perfume_database" ||
               (question.key.contains("reference") && question.questionType == "autocomplete_multiple") {
                // Extraer perfumes de referencia del value
                let selectedPerfumes = option.value.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                metadata.referencePerfumes = (metadata.referencePerfumes ?? []) + selectedPerfumes

                #if DEBUG
                print("  🎯 Perfumes de referencia agregados: \(selectedPerfumes.joined(separator: ", "))")
                print("  ⚠️ TODO: Analizar familias de estos perfumes y sumar scores")
                #endif

                // TODO: Analizar perfumes de referencia y sumar scores
                // let scores = await analyzeReferencePerfumes(selectedPerfumes)
                // for (family, score) in scores {
                //     familyScores[family, default: 0.0] += score
                // }
            }
        }

        // Normalizar scores a escala 0-100
        let normalizedScores = normalizeFamilyScores(familyScores)

        // Determinar familia principal y subfamilias
        let (primaryFamily, subfamilies) = determinePrimaryFamilies(from: normalizedScores)

        // Calcular confianza y completitud
        let completeness = calculateCompleteness(answers: answers, experienceLevel: experienceLevel)
        let confidence = calculateConfidence(scores: normalizedScores, completeness: completeness)

        // Guardar preguntas y respuestas para referencia futura
        let questionsAndAnswers = answers.map { (key, value) in
            QuestionAnswer(
                questionId: value.question.id,
                answerId: value.option.id
            )
        }

        #if DEBUG
        print("✅ [UnifiedEngine] Profile calculated:")
        print("   Primary: \(primaryFamily) (score: \(String(format: "%.1f", normalizedScores[primaryFamily] ?? 0)))")
        print("   Subfamilies: \(subfamilies.joined(separator: ", "))")
        print("   Confidence: \(String(format: "%.2f", confidence))")
        print("   Completeness: \(String(format: "%.2f", completeness)) (\(answers.count) questions answered)")
        print("   Questions/Answers saved: \(questionsAndAnswers.count)")
        #endif

        return UnifiedProfile(
            name: profileName,
            profileType: profileType,
            createdDate: Date(),
            experienceLevel: experienceLevel,
            primaryFamily: primaryFamily,
            subfamilies: subfamilies,
            familyScores: normalizedScores,
            genderPreference: genderPreference,
            metadata: metadata,
            confidenceScore: confidence,
            answerCompleteness: completeness,
            questionsAndAnswers: questionsAndAnswers
        )
    }

    // MARK: - Calculate Perfume Match Score
    /// Calcula el score de match entre un perfume y un perfil
    func calculatePerfumeScore(
        perfume: Perfume,
        profile: UnifiedProfile
    ) async -> Double {

        let weights = profile.profileType == .personal ? WeightProfile.personal : WeightProfile.gift
        var score: Double = 0.0

        // 1. Familias (usa family_scores) - Peso principal
        score += calculateFamilyMatch(perfume: perfume, profile: profile) * weights.families

        // 2. Notas (bonus directo si coinciden)
        if let preferredNotes = profile.metadata.preferredNotes, !preferredNotes.isEmpty {
            let noteBonus = calculateNoteBonus(perfume: perfume, preferredNotes: preferredNotes)
            score += noteBonus * weights.notes
        }

        // 3. Contexto (ocasión + temporada)
        score += calculateContextMatch(perfume: perfume, metadata: profile.metadata) * weights.context

        // 4. Popularidad
        if let popularity = perfume.popularity {
            score += (popularity / 10.0) * weights.popularity * 100
        }

        // 5. Precio (favorece precios accesibles para regalo)
        if profile.profileType == .gift {
            if let price = perfume.price, (price == "low" || price == "medium") {
                score += weights.price * 100
            }
        }

        // PENALIZACIONES (se aplican DESPUÉS del cálculo base)
        // Familias a evitar
        if let avoidFamilies = profile.metadata.avoidFamilies,
           avoidFamilies.contains(perfume.family.lowercased()) {
            score *= 0.3  // Reducir al 30%
        }

        // Filtro de género (OBLIGATORIO para gift)
        if profile.profileType == .gift {
            if !matchesGender(perfume: perfume, preference: profile.genderPreference) {
                return 0.0  // Descalificado completamente
            }
        }

        return min(score, 100.0)  // Cap at 100
    }

    // MARK: - Get Recommendations
    /// Obtiene recomendaciones de perfumes para un perfil
    func getRecommendations(
        for profile: UnifiedProfile,
        from perfumes: [Perfume],
        limit: Int = 10
    ) async -> [RecommendedPerfume] {

        #if DEBUG
        print("🎯 [UnifiedEngine] Getting recommendations for profile: \(profile.name)")
        print("   Profile type: \(profile.profileType.rawValue)")
        print("   Evaluating \(perfumes.count) perfumes")
        #endif

        var scoredPerfumes: [(perfume: Perfume, score: Double)] = []

        for perfume in perfumes {
            let score = await calculatePerfumeScore(perfume: perfume, profile: profile)
            if score > 0 {
                scoredPerfumes.append((perfume, score))
            }
        }

        #if DEBUG
        print("   Scored perfumes: \(scoredPerfumes.count)")
        #endif

        // Ordenar con aleatorización para scores similares (variedad)
        let sorted = scoredPerfumes.sorted { item1, item2 in
            if abs(item1.score - item2.score) < 5 {
                return Bool.random()  // Aleatorizar si diferencia < 5 puntos
            }
            return item1.score > item2.score
        }

        let topPerfumes = Array(sorted.prefix(limit))

        #if DEBUG
        if let top = topPerfumes.first {
            print("   Top recommendation: \(top.perfume.name) (score: \(String(format: "%.1f", top.score)))")
        }
        #endif

        return topPerfumes.map { perfume, score in
            RecommendedPerfume(
                perfumeId: perfume.id ?? "",
                matchPercentage: score
            )
        }
    }

    // MARK: - Helper Methods

    /// Determina el nivel de experiencia según las preguntas respondidas
    private func determineExperienceLevel(from answers: [String: (question: Question, option: Option)]) -> ExperienceLevel {
        // Detectar por los IDs de preguntas
        let questionIds = answers.keys

        if questionIds.contains(where: { $0.contains("profile_C") }) {
            return .expert
        } else if questionIds.contains(where: { $0.contains("profile_B") }) {
            return .intermediate
        } else {
            return .beginner
        }
    }

    /// Extrae metadata de una opción y la agrega al metadata del perfil
    private func extractMetadata(from optionMeta: OptionMetadata, into metadata: inout UnifiedProfileMetadata) {
        if let gender = optionMeta.gender {
            // El gender se usa como filter principal, no como metadata adicional
        }

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

        if let duration = optionMeta.duration {
            metadata.durationPreference = duration
        }

        if let projection = optionMeta.projection {
            metadata.projectionPreference = projection
        }

        if let avoidFamilies = optionMeta.avoidFamilies {
            metadata.avoidFamilies = (metadata.avoidFamilies ?? []) + avoidFamilies
        }

        if let phasePreference = optionMeta.phasePreference {
            metadata.phasePreference = phasePreference
        }

        if let discoveryMode = optionMeta.discoveryMode {
            metadata.discoveryMode = discoveryMode
        }
    }

    /// Normaliza scores de familias a escala 0-100
    private func normalizeFamilyScores(_ scores: [String: Double]) -> [String: Double] {
        guard let maxScore = scores.values.max(), maxScore > 0 else {
            return scores
        }

        let normalizationFactor = 100.0 / maxScore
        return scores.mapValues { $0 * normalizationFactor }
    }

    /// Determina familia principal y subfamilias
    private func determinePrimaryFamilies(from scores: [String: Double]) -> (primary: String, subfamilies: [String]) {
        let sorted = scores.sorted { $0.value > $1.value }

        guard let primary = sorted.first?.key else {
            return ("unknown", [])
        }

        let subfamilies = sorted.dropFirst().prefix(3).map { $0.key }
        return (primary, Array(subfamilies))
    }

    /// Calcula confianza del perfil (0.0 - 1.0)
    private func calculateConfidence(scores: [String: Double], completeness: Double) -> Double {
        // Factores de confianza:
        // 1. Diferencia entre familia principal y segunda (claridad)
        let sorted = scores.sorted { $0.value > $1.value }
        let clarity: Double
        if sorted.count >= 2 {
            let diff = sorted[0].value - sorted[1].value
            clarity = min(diff / 50.0, 1.0)  // Normalizar a 0-1
        } else {
            clarity = 1.0
        }

        // 2. Completitud (ya calculada externamente basándose en el flujo)

        // Promedio ponderado
        return (clarity * 0.6) + (completeness * 0.4)
    }

    /// Obtiene weight por defecto basándose en el tipo de pregunta
    /// Fallback temporal mientras se actualiza Firebase
    private func getDefaultWeight(for questionKey: String) -> Int {
        // Preguntas de metadata (weight = 0)
        if questionKey.contains("gender") ||
           questionKey.contains("intensity") ||
           questionKey.contains("concentration") {
            return 0
        }

        // Preguntas clave de preferencias (weight = 3)
        if questionKey.contains("preference") ||
           questionKey.contains("simple_preference") ||
           questionKey.contains("mixed_preference") ||
           questionKey.contains("structure") {
            return 3
        }

        // Preguntas de sentimientos/emociones (weight = 2)
        if questionKey.contains("feeling") ||
           questionKey.contains("personality") ||
           questionKey.contains("discovery") {
            return 2
        }

        // Preguntas contextuales (weight = 1)
        if questionKey.contains("time") ||
           questionKey.contains("season") ||
           questionKey.contains("occasion") ||
           questionKey.contains("balance") {
            return 1
        }

        // Por defecto: contribuye mínimamente
        return 1
    }

    /// Calcula completitud de respuestas (0.0 - 1.0)
    private func calculateCompleteness(answers: [String: (question: Question, option: Option)], experienceLevel: ExperienceLevel) -> Double {
        // Número de preguntas esperadas por flujo
        let expectedQuestions: Double
        switch experienceLevel {
        case .beginner:     // Flujo A
            expectedQuestions = 6.0
        case .intermediate: // Flujo B
            expectedQuestions = 7.0
        case .expert:       // Flujo C
            expectedQuestions = 8.0
        }

        // Calcular porcentaje de completitud
        return min(Double(answers.count) / expectedQuestions, 1.0)
    }

    /// Calcula match de familias olfativas
    private func calculateFamilyMatch(perfume: Perfume, profile: UnifiedProfile) -> Double {
        var score: Double = 0.0

        // Familia principal: 40 puntos
        if let primaryScore = profile.familyScores[perfume.family] {
            score += (primaryScore / 100.0) * 40.0
        }

        // Subfamilias: 40 puntos distribuidos
        for subfamily in perfume.subfamilies {
            if let subfamilyScore = profile.familyScores[subfamily] {
                score += (subfamilyScore / 100.0) * 10.0  // Max 40 puntos total
            }
        }

        // Intensidad: 10 puntos
        if let preferredIntensity = profile.metadata.intensityPreference,
           perfume.intensity.lowercased() == preferredIntensity.lowercased() {
            score += 10.0
        }

        // Duración: 10 puntos
        if let preferredDuration = profile.metadata.durationPreference,
           perfume.duration.lowercased() == preferredDuration.lowercased() {
            score += 10.0
        }

        return min(score, 100.0)
    }

    /// Calcula bonus por notas específicas
    private func calculateNoteBonus(perfume: Perfume, preferredNotes: [String]) -> Double {
        let allNotes = (perfume.topNotes ?? []) + (perfume.heartNotes ?? []) + (perfume.baseNotes ?? [])

        let matches = preferredNotes.filter { note in
            allNotes.contains(where: { $0.lowercased() == note.lowercased() })
        }.count

        // Escala de bonus (0.0 - 1.0)
        switch matches {
        case 0:
            return 0.0
        case 1:
            return 0.5
        case 2:
            return 0.8
        default:  // 3+
            return 1.0
        }
    }

    /// Calcula match de contexto (ocasión + temporada)
    private func calculateContextMatch(perfume: Perfume, metadata: UnifiedProfileMetadata) -> Double {
        var score: Double = 0.0
        var checks: Double = 0.0

        // Ocasiones
        if let preferredOccasions = metadata.preferredOccasions {
            checks += 1
            let matchingOccasions = perfume.occasion.filter { occasion in
                preferredOccasions.contains(where: { $0.lowercased() == occasion.lowercased() })
            }
            if !matchingOccasions.isEmpty {
                score += 1.0
            }
        }

        // Temporadas
        if let preferredSeasons = metadata.preferredSeasons {
            checks += 1
            let matchingSeasons = perfume.recommendedSeason.filter { season in
                preferredSeasons.contains(where: { $0.lowercased() == season.lowercased() })
            }
            if !matchingSeasons.isEmpty {
                score += 1.0
            }
        }

        return checks > 0 ? (score / checks) * 100.0 : 0.0
    }

    /// Verifica si el perfume coincide con la preferencia de género
    private func matchesGender(perfume: Perfume, preference: String) -> Bool {
        let perfumeGender = perfume.gender.lowercased().trimmingCharacters(in: .whitespaces)
        let preferredGender = preference.lowercased().trimmingCharacters(in: .whitespaces)

        // Unisex coincide con todo
        if perfumeGender == "unisex" || preferredGender == "unisex" {
            return true
        }

        // Mapeo de variantes
        let maleVariants = ["hombre", "masculino", "male", "man", "men"]
        let femaleVariants = ["mujer", "femenino", "female", "woman", "women"]

        let isMalePreference = maleVariants.contains(preferredGender)
        let isFemalePreference = femaleVariants.contains(preferredGender)
        let isMalePerfume = maleVariants.contains(perfumeGender)
        let isFemalePerfume = femaleVariants.contains(perfumeGender)

        return (isMalePreference && isMalePerfume) || (isFemalePreference && isFemalePerfume)
    }

    // MARK: - Reference Perfume Analysis (TODO: Implementar)
    /// Analiza perfumes de referencia y extrae scores de familias
    private func analyzeReferencePerfumes(_ perfumeKeys: [String]) async -> [String: Double] {
        // TODO: Implementar análisis de perfumes de referencia
        // 1. Buscar perfumes en la base de datos
        // 2. Extraer familias y subfamilias
        // 3. Calcular pesos distribuidos
        return [:]
    }
}
