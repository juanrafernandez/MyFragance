import Foundation

// MARK: - Unified Recommendation Engine
/**
 # UnifiedRecommendationEngine

 Motor unificado de cálculo de perfiles olfativos y recomendaciones de perfumes.
 Reemplaza tanto a OlfactiveProfileHelper como a GiftScoringEngine.

 ## 🎯 Responsabilidades

 1. **Cálculo de Perfiles**: Procesa respuestas del test y genera UnifiedProfile
 2. **Scoring de Perfumes**: Calcula match entre perfumes y perfiles
 3. **Recomendaciones**: Genera listas rankeadas de perfumes recomendados

 ## 📊 Sistema de Familias Olfativas

 El perfil calcula scores para cada familia olfativa (0-100). Los scores provienen de:

 - **Respuestas con `option.families`** (weight > 0): Contribuyen directamente
 - **Perfumes de referencia** (autocomplete): Se analizan y sus familias suman puntos
 - **Familias a evitar** (metadata): Se penalizan con -80% DESPUÉS del cálculo base

 ### Reglas de Cálculo:

 1. **Solo weight > 0 contribuye**: Preguntas con weight = 0 solo aportan metadata
 2. **Notas NO suman a familias**: Se guardan para bonus directo en recomendaciones
 3. **Perfumes SÍ suman a familias**: Se analizan y extraen familias/subfamilias
 4. **Familias a evitar penalizan**: Reducen score al 20% (penalización 80%)

 ## 🧩 Sistema de Metadata (Extensible)

 El sistema captura metadata de las respuestas en `UnifiedProfileMetadata`:

 - `preferredNotes` - Notas favoritas (autocomplete)
 - `referencePerfumes` - Perfumes de referencia (autocomplete)
 - `avoidFamilies` - Familias a evitar
 - `intensityPreference, durationPreference, projectionPreference` - Performance
 - `concentrationPreference` - EDT, EDP, Parfum, etc.
 - `preferredSeasons, preferredOccasions` - Contexto
 - `personalityTraits` - Rasgos de personalidad
 - `structurePreference, phasePreference` - Estructura (Flow C)
 - `discoveryMode` - Apertura a nuevos perfumes

 ### ✅ Metadata que SE USA actualmente:

 **En recomendaciones** (`calculatePerfumeScore`):
 - ✓ `preferredNotes` - Bonus 20% si coinciden con el perfume
 - ✓ `avoidFamilies` - Penalización brutal (reduce a 30%)
 - ✓ `preferredSeasons` - Match de contexto (10% peso)
 - ✓ `preferredOccasions` - Match de contexto (10% peso)
 - ✓ `intensityPreference` - Suma 10 pts si coincide
 - ✓ `durationPreference` - Suma 10 pts si coincide

 **En cálculo de familias** (`calculateProfile`):
 - ✓ `referencePerfumes` - Analiza y suma scores de familias/subfamilias
 - ✓ `avoidFamilies` - Penaliza familias no deseadas (-80%)

 ### ⏳ Metadata GUARDADA pero NO USADA (preparada para futuro):

 - `personalityTraits` - Se guarda en perfil pero no se compara en scoring
 - `structurePreference` - Se guarda pero no se evalúa
 - `phasePreference` - Se guarda pero no se evalúa
 - `concentrationPreference` - Se guarda pero no se evalúa
 - `discoveryMode` - Se guarda pero no se aplica

 ## 🔧 Cómo Extender para Nueva Metadata

 ### Paso 1: Asegurar que se capture en `extractMetadata()`

 ```swift
 private func extractMetadata(from optionMeta: OptionMetadata, into metadata: inout UnifiedProfileMetadata) {
     // Ya existe - solo agregar campos nuevos si es necesario
     if let nuevoParametro = optionMeta.nuevoParametro {
         metadata.nuevoParametro = nuevoParametro
     }
 }
 ```

 ### Paso 2: Usar en cálculo de familias (opcional)

 Si el nuevo parámetro debe influir en las familias, agregar lógica en `calculateProfile()`:

 ```swift
 // Ejemplo: Mapear ocasiones a familias
 if let occasions = metadata.preferredOccasions {
     for occasion in occasions {
         let familyBonus = mapOccasionToFamilies(occasion)  // Crear función helper
         for (family, bonus) in familyBonus {
             familyScores[family, default: 0.0] += bonus
         }
     }
 }
 ```

 ### Paso 3: Usar en scoring de perfumes

 Agregar lógica en `calculatePerfumeScore()`:

 ```swift
 // Ejemplo: Bonus por concentración preferida
 if let preferredConcentration = profile.metadata.concentrationPreference {
     if perfume.concentration == preferredConcentration {
         score += 5.0 * weights.concentrationWeight
     }
 }
 ```

 ## 🔍 Detección FLEXIBLE de Tipos de Pregunta

 El sistema usa dos niveles de detección:

 1. **Primario**: `question.dataSource` (recomendado, configurado en Firebase)
 2. **Fallback**: Pattern matching en `question.key` (backup)

 Ejemplo:
 ```swift
 let isNotesQuestion = question.dataSource == "notes_database" ||
                      (question.questionType == "autocomplete_multiple" && question.key.contains("notes"))
 ```

 Esto permite flexibilidad: las preguntas pueden cambiar de key pero mientras tengan
 `dataSource` correcto, se detectarán bien.

 ## 📝 Logs de Debug

 El sistema incluye logs exhaustivos (#if DEBUG) para trazabilidad completa:

 - Procesamiento de cada pregunta con weight y families
 - Detección de notas/perfumes con dataSource y questionType
 - Análisis de perfumes de referencia con familias extraídas
 - Penalizaciones aplicadas
 - Scores finales normalizados

 ## 🎯 Uso

 ```swift
 // 1. Configurar con PerfumeService (se hace en PerfBetaApp.init)
 await UnifiedRecommendationEngine.shared.configure(perfumeService: perfumeService)

 // 2. Calcular perfil
 let profile = await UnifiedRecommendationEngine.shared.calculateProfile(
     from: answers,
     profileName: "Mi Perfil",
     profileType: .personal
 )

 // 3. Obtener recomendaciones
 let recommendations = await UnifiedRecommendationEngine.shared.getRecommendations(
     for: profile,
     from: allPerfumes,
     limit: 20
 )
 ```
 */
actor UnifiedRecommendationEngine {

    static let shared = UnifiedRecommendationEngine()

    // MARK: - Dependencies
    private var perfumeService: PerfumeServiceProtocol?

    private init() {}

    /// Configura el servicio de perfumes para análisis de referencias
    func configure(perfumeService: PerfumeServiceProtocol) {
        self.perfumeService = perfumeService
    }

    // MARK: - Weight Profiles
    /// Pesos contextuales según tipo de perfil y nivel de experiencia
    private struct WeightProfile {
        let families: Double
        let notes: Double
        let context: Double
        let popularity: Double
        let price: Double
        let occasion: Double
        let season: Double

        /// Obtiene pesos ajustados según el tipo de perfil y nivel de experiencia
        static func getWeights(profileType: ProfileType, experienceLevel: ExperienceLevel) -> WeightProfile {
            if profileType == .personal {
                switch experienceLevel {
                case .beginner:
                    // Principiantes: Mayor peso a familias y popularidad, sin notas
                    return WeightProfile(
                        families: 0.70,      // 70% peso en familias (simplificado)
                        notes: 0.00,         // 0% - No entienden de notas específicas
                        context: 0.15,       // 15% peso en contexto
                        popularity: 0.10,    // 10% peso en popularidad (guía)
                        price: 0.05,         // 5% peso en precio
                        occasion: 0.075,     // Incluido en context
                        season: 0.075        // Incluido en context
                    )
                case .intermediate:
                    // Intermedios: Balance entre familias y notas
                    return WeightProfile(
                        families: 0.60,      // 60% peso en familias
                        notes: 0.15,         // 15% peso en notas (comienzan a valorar)
                        context: 0.15,       // 15% peso en contexto
                        popularity: 0.05,    // 5% peso en popularidad
                        price: 0.05,         // 5% peso en precio
                        occasion: 0.075,     // Incluido en context
                        season: 0.075        // Incluido en context
                    )
                case .expert:
                    // Expertos: Mayor peso en notas específicas
                    return WeightProfile(
                        families: 0.50,      // 50% peso en familias (conocen bien)
                        notes: 0.25,         // 25% peso en notas (muy importantes)
                        context: 0.15,       // 15% peso en contexto
                        popularity: 0.05,    // 5% peso en popularidad (menos relevante)
                        price: 0.05,         // 5% peso en precio
                        occasion: 0.075,     // Incluido en context
                        season: 0.075        // Incluido en context
                    )
                }
            } else {
                // Gift: Pesos fijos (no depende de experiencia del receptor)
                return WeightProfile(
                    families: 0.40,      // 40% peso en familias
                    notes: 0.10,         // 10% peso en notas
                    context: 0.10,       // 10% peso en contexto general
                    popularity: 0.20,    // 20% peso en popularidad (importante para regalo)
                    price: 0.10,         // 10% peso en precio
                    occasion: 0.15,      // 15% peso en ocasión (muy relevante)
                    season: 0.05         // 5% peso en temporada
                )
            }
        }
    }

    // MARK: - Calculate Profile
    /// Calcula un perfil unificado a partir de respuestas
    func calculateProfile(
        from answers: [String: (question: Question, option: Option)],
        profileName: String,
        profileType: ProfileType = .personal
    ) async -> UnifiedProfile {

        #if DEBUG
        print("\n")
        print("═══════════════════════════════════════════════════════════════════")
        print("🧮 [PROFILE_CALC] INICIANDO CÁLCULO DE PERFIL")
        print("═══════════════════════════════════════════════════════════════════")
        print("🧮 [PROFILE_CALC] Nombre del perfil: \(profileName)")
        print("🧮 [PROFILE_CALC] Tipo: \(profileType.rawValue)")
        print("🧮 [PROFILE_CALC] Total de respuestas: \(answers.count)")
        print("")
        #endif

        var familyScores: [String: Double] = [:]
        var metadata = UnifiedProfileMetadata()
        var genderPreference: String = "unisex"

        // Extraer nivel de experiencia según el tipo de preguntas
        let experienceLevel = determineExperienceLevel(from: answers)

        // Extraer género si existe (weight = 0, solo metadata)
        if let genderAnswer = answers.values.first(where: { $0.question.key.contains("gender") }) {
            // Priorizar gender_type de la metadata, si no existe usar value
            if let genderType = genderAnswer.option.metadata?.genderType {
                genderPreference = genderType
                #if DEBUG
                print("🧮 [PROFILE_CALC] Género extraído de metadata.gender_type: \(genderType)")
                #endif
            } else {
                genderPreference = genderAnswer.option.value
                #if DEBUG
                print("🧮 [PROFILE_CALC] Género extraído de option.value: \(genderAnswer.option.value)")
                #endif
            }
        }

        // REGLA 1: Solo preguntas con weight > 0 contribuyen a family_scores
        for (questionKey, (question, option)) in answers {
            // Usar weight de Firebase, o fallback basado en el tipo de pregunta
            let weight = question.weight ?? getDefaultWeight(for: questionKey)

            #if DEBUG
            print("🧮 [PROFILE_CALC] ─────────────────────────────────────────────")
            print("🧮 [PROFILE_CALC] Pregunta: \(questionKey)")
            print("🧮 [PROFILE_CALC]   ├─ Weight: \(weight) \(question.weight == nil ? "(fallback)" : "(Firebase)")")
            print("🧮 [PROFILE_CALC]   ├─ Respuesta: \(option.label)")
            print("🧮 [PROFILE_CALC]   ├─ Valor: \(option.value)")
            print("🧮 [PROFILE_CALC]   ├─ Tipo: \(question.questionType ?? "nil")")
            print("🧮 [PROFILE_CALC]   ├─ DataSource: \(question.dataSource ?? "nil")")
            print("🧮 [PROFILE_CALC]   └─ Familias en opción: \(option.families)")
            #endif

            if weight > 0 {
                // Acumular scores de familias con peso de la pregunta
                for (family, points) in option.families {
                    let contribution = Double(points * weight)
                    familyScores[family, default: 0.0] += contribution
                    #if DEBUG
                    print("🧮 [PROFILE_CALC]      ✓ \(family): +\(String(format: "%.1f", contribution)) pts (puntos:\(points) × weight:\(weight))")
                    #endif
                }
            } else {
                #if DEBUG
                print("🧮 [PROFILE_CALC]      ⚠️ Weight = 0, no contribuye a familias (solo metadata)")
                #endif
            }

            // Extraer metadata siempre (independiente del weight)
            if let optionMeta = option.metadata {
                #if DEBUG
                print("🧮 [PROFILE_CALC]      📦 Metadata encontrada en opción:")
                if let occasions = optionMeta.occasion {
                    print("🧮 [PROFILE_CALC]         • occasions: \(occasions)")
                }
                if let personality = optionMeta.personality {
                    print("🧮 [PROFILE_CALC]         • personality: \(personality)")
                }
                if let season = optionMeta.season {
                    print("🧮 [PROFILE_CALC]         • season: \(season)")
                }
                if let intensity = optionMeta.intensity {
                    print("🧮 [PROFILE_CALC]         • intensity: \(intensity)")
                }
                if let projection = optionMeta.projection {
                    print("🧮 [PROFILE_CALC]         • projection: \(projection)")
                }
                if let duration = optionMeta.duration {
                    print("🧮 [PROFILE_CALC]         • duration: \(duration)")
                }
                if let avoidFamilies = optionMeta.avoidFamilies {
                    print("🧮 [PROFILE_CALC]         • avoidFamilies: \(avoidFamilies)")
                }
                #endif

                extractMetadata(from: optionMeta, into: &metadata)
            } else {
                #if DEBUG
                print("🧮 [PROFILE_CALC]      ⚠️ Sin metadata en esta opción")
                #endif
            }

            // REGLA 2: Las notas preferidas NO suman a familias
            // Se guardan en metadata para bonus directo en recomendaciones
            // Detección FLEXIBLE: usa dataSource primero, fallback a key pattern
            let isNotesQuestion = question.dataSource == "notes_database" ||
                                 (question.questionType == "autocomplete_multiple" && question.key.contains("notes"))

            if isNotesQuestion {
                let selectedNotes = option.value.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                metadata.preferredNotes = (metadata.preferredNotes ?? []) + selectedNotes

                #if DEBUG
                print("🧮 [PROFILE_CALC]      📝 Notas preferidas agregadas: \(selectedNotes.joined(separator: ", "))")
                print("🧮 [PROFILE_CALC]         (NO suman a familias - se usan como bonus directo)")
                #endif
            }

            // REGLA 3: Los perfumes de referencia SÍ suman a familias
            // Detección FLEXIBLE: usa dataSource primero, fallback a key pattern
            let isPerfumeQuestion = question.dataSource == "perfume_database" ||
                                   (question.questionType == "autocomplete_multiple" && (question.key.contains("reference") || question.key.contains("perfume")))

            if isPerfumeQuestion {
                let selectedPerfumes = option.value.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                metadata.referencePerfumes = (metadata.referencePerfumes ?? []) + selectedPerfumes

                #if DEBUG
                print("🧮 [PROFILE_CALC]      🎯 Perfumes de referencia agregados: \(selectedPerfumes.joined(separator: ", "))")
                print("🧮 [PROFILE_CALC]         Analizando familias de estos perfumes...")
                #endif

                // Analizar familias de estos perfumes y sumar scores
                let perfumeScores = await analyzeReferencePerfumes(selectedPerfumes)
                for (family, score) in perfumeScores {
                    familyScores[family, default: 0.0] += score
                    #if DEBUG
                    print("🧮 [PROFILE_CALC]         ✓ \(family): +\(String(format: "%.1f", score)) pts (de perfumes de referencia)")
                    #endif
                }
            }
        }

        // REGLA 5: Penalizar familias a evitar (antes de normalizar)
        // Esto reduce SIGNIFICATIVAMENTE el score de familias no deseadas
        if let avoidFamilies = metadata.avoidFamilies, !avoidFamilies.isEmpty {
            #if DEBUG
            print("")
            print("🧮 [PROFILE_CALC] ═══════════════════════════════════════════════")
            print("🧮 [PROFILE_CALC] PENALIZACIONES A FAMILIAS A EVITAR:")
            #endif

            for avoidFamily in avoidFamilies {
                // Buscar la familia en los scores (case insensitive)
                let normalizedAvoidFamily = avoidFamily.lowercased()

                for (family, currentScore) in familyScores {
                    if family.lowercased() == normalizedAvoidFamily {
                        let originalScore = currentScore
                        familyScores[family] = currentScore * 0.2  // Reducir al 20% (penalización del 80%)

                        #if DEBUG
                        print("🧮 [PROFILE_CALC]   🚫 \(family): \(String(format: "%.1f", originalScore)) → \(String(format: "%.1f", familyScores[family]!)) (-80%)")
                        #endif
                    }
                }
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
        print("")
        print("═══════════════════════════════════════════════════════════════════")
        print("🧮 [PROFILE_CALC] ✅ PERFIL CALCULADO EXITOSAMENTE")
        print("═══════════════════════════════════════════════════════════════════")
        print("🧮 [PROFILE_CALC] Familia Principal: \(primaryFamily) (score: \(String(format: "%.1f", normalizedScores[primaryFamily] ?? 0)))")
        print("🧮 [PROFILE_CALC] Subfamilias: \(subfamilies.isEmpty ? "ninguna" : subfamilies.joined(separator: ", "))")
        print("🧮 [PROFILE_CALC] Género: \(genderPreference)")
        print("🧮 [PROFILE_CALC] Nivel de experiencia: \(experienceLevel.rawValue)")
        print("🧮 [PROFILE_CALC]")
        print("🧮 [PROFILE_CALC] Scores de todas las familias (normalizados 0-100):")
        for (family, score) in normalizedScores.sorted(by: { $0.value > $1.value }) {
            print("🧮 [PROFILE_CALC]   • \(family): \(String(format: "%.1f", score))")
        }
        print("🧮 [PROFILE_CALC]")
        print("🧮 [PROFILE_CALC] Metadata recopilada:")
        if let notes = metadata.preferredNotes, !notes.isEmpty {
            print("🧮 [PROFILE_CALC]   📝 Notas preferidas: \(notes.joined(separator: ", "))")
        }
        if let perfumes = metadata.referencePerfumes, !perfumes.isEmpty {
            print("🧮 [PROFILE_CALC]   🎯 Perfumes de referencia: \(perfumes.joined(separator: ", "))")
        }
        if let occasions = metadata.preferredOccasions, !occasions.isEmpty {
            print("🧮 [PROFILE_CALC]   🕐 Ocasiones: \(occasions.joined(separator: ", "))")
        }
        if let seasons = metadata.preferredSeasons, !seasons.isEmpty {
            print("🧮 [PROFILE_CALC]   🌡️ Temporadas: \(seasons.joined(separator: ", "))")
        }
        if let intensity = metadata.intensityPreference {
            print("🧮 [PROFILE_CALC]   💪 Intensidad preferida: \(intensity)")
        }
        if let duration = metadata.durationPreference {
            print("🧮 [PROFILE_CALC]   ⏱️ Duración preferida: \(duration)")
        }
        if let projection = metadata.projectionPreference {
            print("🧮 [PROFILE_CALC]   📡 Proyección preferida: \(projection)")
        }
        if let personality = metadata.personalityTraits, !personality.isEmpty {
            print("🧮 [PROFILE_CALC]   🎭 Rasgos de personalidad: \(personality.joined(separator: ", "))")
        }
        if let avoidFamilies = metadata.avoidFamilies, !avoidFamilies.isEmpty {
            print("🧮 [PROFILE_CALC]   🚫 Familias a evitar: \(avoidFamilies.joined(separator: ", "))")
        }
        print("🧮 [PROFILE_CALC]")
        print("🧮 [PROFILE_CALC] Métricas de calidad:")
        print("🧮 [PROFILE_CALC]   ✓ Confianza: \(String(format: "%.2f", confidence))")
        print("🧮 [PROFILE_CALC]   ✓ Completitud: \(String(format: "%.2f", completeness)) (\(answers.count) preguntas respondidas)")
        print("🧮 [PROFILE_CALC]   ✓ Preguntas/Respuestas guardadas: \(questionsAndAnswers.count)")
        print("═══════════════════════════════════════════════════════════════════")
        print("")
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

        // ✅ Usar pesos dinámicos según experienceLevel
        let weights = WeightProfile.getWeights(profileType: profile.profileType, experienceLevel: profile.experienceLevel)
        var score: Double = 0.0

        #if DEBUG
        let enableDetailedScoring = true  // Cambiar a true para ver scoring de CADA perfume (muy verbose)
        if enableDetailedScoring {
            print("")
            print("💯 [SCORING] ══════════════════════════════════════════════════")
            print("💯 [SCORING] Evaluando: \(perfume.name) (\(perfume.brand))")
            print("💯 [SCORING] Familia: \(perfume.family)")
        }
        #endif

        // ✅ FILTRO 1: intensity_max (Profile B)
        // Si el perfume excede la intensidad máxima permitida, descalificar
        if let intensityMax = profile.metadata.intensityMax {
            if !matchesIntensityLimit(perfume: perfume, maxIntensity: intensityMax) {
                #if DEBUG
                if enableDetailedScoring {
                    print("💯 [SCORING]   ❌ DESCALIFICADO por intensity_max (perfume:\(perfume.intensity) > límite:\(intensityMax))")
                }
                #endif
                return 0.0
            }
        }

        // ✅ FILTRO 2: must_contain_notes (Profile B)
        // Si el perfume NO contiene TODAS las notas requeridas, descalificar o penalizar fuertemente
        if let mustContainNotes = profile.metadata.mustContainNotes, !mustContainNotes.isEmpty {
            if !containsAllRequiredNotes(perfume: perfume, requiredNotes: mustContainNotes) {
                #if DEBUG
                if enableDetailedScoring {
                    print("💯 [SCORING]   ❌ DESCALIFICADO por must_contain_notes (no contiene todas las notas requeridas: \(mustContainNotes.joined(separator: ", ")))")
                }
                #endif
                return 0.0
            }
        }

        // 1. Familias (usa family_scores) - Peso principal
        let familyScore = calculateFamilyMatch(perfume: perfume, profile: profile)
        let familyContribution = familyScore * weights.families
        score += familyContribution

        #if DEBUG
        if enableDetailedScoring {
            print("💯 [SCORING]   1️⃣ Match de familias: \(String(format: "%.1f", familyScore)) × \(String(format: "%.2f", weights.families)) = \(String(format: "%.1f", familyContribution))")
        }
        #endif

        // 2. Notas (bonus directo si coinciden)
        var noteContribution: Double = 0.0
        if let preferredNotes = profile.metadata.preferredNotes, !preferredNotes.isEmpty {
            let noteBonus = calculateNoteBonus(perfume: perfume, preferredNotes: preferredNotes)
            noteContribution = noteBonus * weights.notes
            score += noteContribution

            #if DEBUG
            if enableDetailedScoring && noteBonus > 0 {
                print("💯 [SCORING]   2️⃣ Bonus de notas: \(String(format: "%.1f", noteBonus)) × \(String(format: "%.2f", weights.notes)) = \(String(format: "%.1f", noteContribution))")
            }
            #endif
        }

        // ✅ 2b. Bonus específico para heartNotes (Profile B)
        var heartNotesContribution: Double = 0.0
        if let heartNotesBonus = profile.metadata.heartNotesBonus, !heartNotesBonus.isEmpty {
            let bonus = calculateHeartNotesBonus(perfume: perfume, bonusNotes: heartNotesBonus)
            heartNotesContribution = bonus * weights.notes
            score += heartNotesContribution

            #if DEBUG
            if enableDetailedScoring && bonus > 0 {
                print("💯 [SCORING]   2b️⃣ Bonus heartNotes: \(String(format: "%.1f", bonus)) × \(String(format: "%.2f", weights.notes)) = \(String(format: "%.1f", heartNotesContribution))")
            }
            #endif
        }

        // ✅ 2c. Bonus específico para baseNotes (Profile B)
        var baseNotesContribution: Double = 0.0
        if let baseNotesBonus = profile.metadata.baseNotesBonus, !baseNotesBonus.isEmpty {
            let bonus = calculateBaseNotesBonus(perfume: perfume, bonusNotes: baseNotesBonus)
            baseNotesContribution = bonus * weights.notes
            score += baseNotesContribution

            #if DEBUG
            if enableDetailedScoring && bonus > 0 {
                print("💯 [SCORING]   2c️⃣ Bonus baseNotes: \(String(format: "%.1f", bonus)) × \(String(format: "%.2f", weights.notes)) = \(String(format: "%.1f", baseNotesContribution))")
            }
            #endif
        }

        // 3. Contexto (ocasión + temporada)
        let contextScore = calculateContextMatch(perfume: perfume, metadata: profile.metadata)
        let contextContribution = contextScore * weights.context
        score += contextContribution

        #if DEBUG
        if enableDetailedScoring && contextScore > 0 {
            print("💯 [SCORING]   3️⃣ Match de contexto: \(String(format: "%.1f", contextScore)) × \(String(format: "%.2f", weights.context)) = \(String(format: "%.1f", contextContribution))")
        }
        #endif

        // 4. Popularidad
        var popularityContribution: Double = 0.0
        if let popularity = perfume.popularity {
            popularityContribution = (popularity / 10.0) * weights.popularity * 100
            score += popularityContribution

            #if DEBUG
            if enableDetailedScoring {
                print("💯 [SCORING]   4️⃣ Popularidad: \(popularity)/10 × \(String(format: "%.2f", weights.popularity)) = \(String(format: "%.1f", popularityContribution))")
            }
            #endif
        }

        // 5. Precio (favorece precios accesibles para regalo)
        var priceContribution: Double = 0.0
        if profile.profileType == .gift {
            if let price = perfume.price, (price == "low" || price == "medium") {
                priceContribution = weights.price * 100
                score += priceContribution

                #if DEBUG
                if enableDetailedScoring {
                    print("💯 [SCORING]   5️⃣ Bonus precio accesible (\(price)): \(String(format: "%.1f", priceContribution))")
                }
                #endif
            }
        }

        #if DEBUG
        if enableDetailedScoring {
            print("💯 [SCORING]   Subtotal ANTES de penalizaciones: \(String(format: "%.1f", score))")
        }
        #endif

        // PENALIZACIONES (se aplican DESPUÉS del cálculo base)
        // Familias a evitar
        if let avoidFamilies = profile.metadata.avoidFamilies,
           avoidFamilies.contains(perfume.family.lowercased()) {
            let beforePenalty = score
            score *= 0.3  // Reducir al 30%

            #if DEBUG
            if enableDetailedScoring {
                print("💯 [SCORING]   ⚠️ PENALIZACIÓN familia a evitar: \(String(format: "%.1f", beforePenalty)) → \(String(format: "%.1f", score)) (-70%)")
            }
            #endif
        }

        // Filtro de género (OBLIGATORIO para gift)
        if profile.profileType == .gift {
            if !matchesGender(perfume: perfume, preference: profile.genderPreference) {
                #if DEBUG
                if enableDetailedScoring {
                    print("💯 [SCORING]   ❌ DESCALIFICADO por género (perfume:\(perfume.gender) ≠ preferencia:\(profile.genderPreference))")
                }
                #endif
                return 0.0  // Descalificado completamente
            }
        }

        let finalScore = min(score, 100.0)

        #if DEBUG
        if enableDetailedScoring {
            print("💯 [SCORING]   ✅ Score FINAL: \(String(format: "%.1f", finalScore))")
            print("💯 [SCORING] ══════════════════════════════════════════════════")
        }
        #endif

        return finalScore
    }

    // MARK: - Get Recommendations
    /// Obtiene recomendaciones de perfumes para un perfil con diversidad de familias
    func getRecommendations(
        for profile: UnifiedProfile,
        from perfumes: [Perfume],
        limit: Int = 10
    ) async -> [RecommendedPerfume] {

        #if DEBUG
        print("")
        print("═══════════════════════════════════════════════════════════════════")
        print("🎯 [RECOMMEND] GENERANDO RECOMENDACIONES")
        print("═══════════════════════════════════════════════════════════════════")
        print("🎯 [RECOMMEND] Perfil: \(profile.name)")
        print("🎯 [RECOMMEND] Tipo: \(profile.profileType.rawValue)")
        print("🎯 [RECOMMEND] Familia principal: \(profile.primaryFamily)")
        print("🎯 [RECOMMEND] Subfamilias: \(profile.subfamilies.isEmpty ? "ninguna" : profile.subfamilies.joined(separator: ", "))")
        print("🎯 [RECOMMEND] Total de perfumes a evaluar: \(perfumes.count)")
        print("🎯 [RECOMMEND] Límite de resultados: \(limit)")
        print("")
        #endif

        // Calcular scores para todos los perfumes
        var scoredPerfumes: [(perfume: Perfume, score: Double)] = []
        for perfume in perfumes {
            let score = await calculatePerfumeScore(perfume: perfume, profile: profile)
            if score > 0 {
                scoredPerfumes.append((perfume, score))
            }
        }

        #if DEBUG
        print("🎯 [RECOMMEND] Perfumes con score > 0: \(scoredPerfumes.count)/\(perfumes.count)")
        print("🎯 [RECOMMEND] Perfumes descartados: \(perfumes.count - scoredPerfumes.count)")
        print("")
        #endif

        // ✅ DIVERSIDAD: Separar por familias para distribución 60/25/15
        let primaryFamily = profile.primaryFamily
        let subfamily1 = profile.subfamilies.first
        let subfamily2 = profile.subfamilies.count > 1 ? profile.subfamilies[1] : nil

        // Familia principal (ordenada por score)
        let primaryMatches = scoredPerfumes
            .filter { $0.perfume.family.lowercased() == primaryFamily.lowercased() }
            .sorted { $0.score > $1.score }

        // Subfamilia 1
        let subfamily1Matches = subfamily1 != nil ?
            scoredPerfumes
                .filter { $0.perfume.family.lowercased() == subfamily1!.lowercased() }
                .sorted { $0.score > $1.score } : []

        // Subfamilia 2
        let subfamily2Matches = subfamily2 != nil ?
            scoredPerfumes
                .filter { $0.perfume.family.lowercased() == subfamily2!.lowercased() }
                .sorted { $0.score > $1.score } : []

        #if DEBUG
        print("🎯 [RECOMMEND] ═══ DISTRIBUCIÓN POR FAMILIAS ═══")
        print("🎯 [RECOMMEND] Familia principal (\(primaryFamily)): \(primaryMatches.count) perfumes disponibles")
        if let sf1 = subfamily1 {
            print("🎯 [RECOMMEND] Subfamilia 1 (\(sf1)): \(subfamily1Matches.count) perfumes disponibles")
        }
        if let sf2 = subfamily2 {
            print("🎯 [RECOMMEND] Subfamilia 2 (\(sf2)): \(subfamily2Matches.count) perfumes disponibles")
        }
        print("")
        #endif

        var recommendations: [(perfume: Perfume, score: Double)] = []

        // 60% de familia principal
        let primaryCount = Int(Double(limit) * 0.60)
        recommendations.append(contentsOf: primaryMatches.prefix(primaryCount))

        // 25% de subfamilia 1
        let subfamily1Count = Int(Double(limit) * 0.25)
        if !subfamily1Matches.isEmpty {
            recommendations.append(contentsOf: subfamily1Matches.prefix(subfamily1Count))
        }

        // 15% de subfamilia 2
        let subfamily2Count = Int(Double(limit) * 0.15)
        if !subfamily2Matches.isEmpty {
            recommendations.append(contentsOf: subfamily2Matches.prefix(subfamily2Count))
        }

        #if DEBUG
        print("🎯 [RECOMMEND] Distribución objetivo:")
        print("🎯 [RECOMMEND]   • Familia principal: \(primaryCount) perfumes (60%)")
        print("🎯 [RECOMMEND]   • Subfamilia 1: \(subfamily1Count) perfumes (25%)")
        print("🎯 [RECOMMEND]   • Subfamilia 2: \(subfamily2Count) perfumes (15%)")
        print("🎯 [RECOMMEND] Recolectados hasta ahora: \(recommendations.count)/\(limit)")
        print("")
        #endif

        // Si no llegamos al límite, completar con los mejores restantes
        if recommendations.count < limit {
            let usedIds = Set(recommendations.map { $0.perfume.id ?? "" })
            let remaining = scoredPerfumes
                .filter { !usedIds.contains($0.perfume.id ?? "") }
                .sorted { $0.score > $1.score }
                .prefix(limit - recommendations.count)
            recommendations.append(contentsOf: remaining)

            #if DEBUG
            print("🎯 [RECOMMEND] Completando con \(remaining.count) perfumes adicionales")
            #endif
        }

        // Reordenar todo por score final (mantener calidad)
        recommendations.sort { $0.score > $1.score }
        let finalRecommendations = Array(recommendations.prefix(limit))

        #if DEBUG
        print("")
        print("🎯 [RECOMMEND] ═══ TOP \(finalRecommendations.count) RECOMENDACIONES FINALES ═══")

        // Contar familias únicas en las recomendaciones
        let familyCounts = Dictionary(grouping: finalRecommendations, by: { $0.perfume.family })
        print("🎯 [RECOMMEND] Diversidad de familias:")
        for (family, items) in familyCounts.sorted(by: { $0.value.count > $1.value.count }) {
            let percentage = Double(items.count) / Double(finalRecommendations.count) * 100.0
            print("🎯 [RECOMMEND]   • \(family): \(items.count) perfumes (\(String(format: "%.0f", percentage))%)")
        }
        print("")

        for (index, (perfume, score)) in finalRecommendations.enumerated() {
            print("🎯 [RECOMMEND]   \(index + 1). \(perfume.name) - \(perfume.brand)")
            print("🎯 [RECOMMEND]      Score: \(String(format: "%.1f", score))% | Familia: \(perfume.family)")
        }
        print("═══════════════════════════════════════════════════════════════════")
        print("")
        #endif

        return finalRecommendations.map { perfume, score in
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

        // ✅ NEW: intensity_max (Profile B)
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

        // ✅ NEW: must_contain_notes (Profile B)
        if let mustContainNotes = optionMeta.mustContainNotes {
            metadata.mustContainNotes = (metadata.mustContainNotes ?? []) + mustContainNotes
        }

        // ✅ NEW: heartNotes_bonus (Profile B)
        if let heartNotesBonus = optionMeta.heartNotesBonus {
            metadata.heartNotesBonus = (metadata.heartNotesBonus ?? []) + heartNotesBonus
        }

        // ✅ NEW: baseNotes_bonus (Profile B)
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

    /// Calcula bonus por notas específicas (escala 0-100)
    private func calculateNoteBonus(perfume: Perfume, preferredNotes: [String]) -> Double {
        let allNotes = (perfume.topNotes ?? []) + (perfume.heartNotes ?? []) + (perfume.baseNotes ?? [])

        let matches = preferredNotes.filter { note in
            allNotes.contains(where: { $0.lowercased() == note.lowercased() })
        }.count

        // ✅ Escala de bonus (0.0 - 100.0) para ser proporcional
        switch matches {
        case 0:
            return 0.0
        case 1:
            return 40.0   // 1 nota coincidente
        case 2:
            return 70.0   // 2 notas coincidentes
        default:  // 3+
            return 100.0  // 3+ notas coincidentes (match perfecto)
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

        // "any" o "all" (Sin distinción de género) coincide con todo
        if preferredGender == "any" || preferredGender == "all" {
            return true
        }

        // Unisex coincide con todo
        if perfumeGender == "unisex" || preferredGender == "unisex" {
            return true
        }

        // Mapeo de variantes (ampliado para soportar gender_type)
        let maleVariants = ["hombre", "masculino", "male", "man", "men", "masculine"]
        let femaleVariants = ["mujer", "femenino", "female", "woman", "women", "feminine"]

        let isMalePreference = maleVariants.contains(preferredGender)
        let isFemalePreference = femaleVariants.contains(preferredGender)
        let isMalePerfume = maleVariants.contains(perfumeGender)
        let isFemalePerfume = femaleVariants.contains(perfumeGender)

        return (isMalePreference && isMalePerfume) || (isFemalePreference && isFemalePerfume)
    }

    // MARK: - Reference Perfume Analysis
    /// Analiza perfumes de referencia y extrae scores de familias
    /// Los perfumes de referencia aportan puntos a sus familias/subfamilias
    private func analyzeReferencePerfumes(_ perfumeKeys: [String]) async -> [String: Double] {
        guard let perfumeService = perfumeService else {
            #if DEBUG
            print("  ⚠️ PerfumeService no configurado, no se pueden analizar perfumes de referencia")
            #endif
            return [:]
        }

        var scores: [String: Double] = [:]

        #if DEBUG
        print("  🔍 Analizando \(perfumeKeys.count) perfumes de referencia...")
        #endif

        for perfumeKey in perfumeKeys {
            do {
                // Buscar perfume por key
                guard let perfume = try await perfumeService.fetchPerfume(byKey: perfumeKey) else {
                    #if DEBUG
                    print("    ⚠️ Perfume no encontrado: \(perfumeKey)")
                    #endif
                    continue
                }

                #if DEBUG
                print("    ✓ \(perfume.name) - Familia: \(perfume.family)")
                #endif

                // Familia principal: 30 puntos
                scores[perfume.family, default: 0.0] += 30.0

                // Subfamilias: 10 puntos cada una (max 3)
                for subfamily in perfume.subfamilies.prefix(3) {
                    scores[subfamily, default: 0.0] += 10.0

                    #if DEBUG
                    print("      → Subfamilia: \(subfamily)")
                    #endif
                }

            } catch {
                #if DEBUG
                print("    ❌ Error al buscar perfume \(perfumeKey): \(error)")
                #endif
            }
        }

        #if DEBUG
        if !scores.isEmpty {
            print("  ✅ Scores extraídos de perfumes de referencia:")
            for (family, score) in scores.sorted(by: { $0.value > $1.value }) {
                print("     \(family): \(score) pts")
            }
        }
        #endif

        return scores
    }

    // MARK: - Profile B Filters & Bonus (NEW)

    /// Verifica si el perfume cumple con el límite de intensidad máxima (Profile B)
    /// - Parameters:
    ///   - perfume: El perfume a evaluar
    ///   - maxIntensity: Intensidad máxima permitida ("medium", "high", etc.)
    /// - Returns: true si cumple, false si excede el límite
    private func matchesIntensityLimit(perfume: Perfume, maxIntensity: String) -> Bool {
        // Mapeo de intensidades a valores numéricos
        let intensityLevels: [String: Int] = [
            "low": 1,
            "medium": 2,
            "high": 3,
            "very_high": 4,
            "very high": 4,
            "veryhigh": 4
        ]

        let perfumeIntensity = perfume.intensity.lowercased().trimmingCharacters(in: .whitespaces)
        let maxIntensityNormalized = maxIntensity.lowercased().trimmingCharacters(in: .whitespaces)

        guard let perfumeLevel = intensityLevels[perfumeIntensity],
              let maxLevel = intensityLevels[maxIntensityNormalized] else {
            // Si no podemos mapear, aceptamos por defecto (mejor no filtrar que filtrar incorrectamente)
            return true
        }

        return perfumeLevel <= maxLevel
    }

    /// Verifica si el perfume contiene TODAS las notas requeridas (Profile B - must_contain_notes)
    /// - Parameters:
    ///   - perfume: El perfume a evaluar
    ///   - requiredNotes: Notas que DEBEN estar presentes
    /// - Returns: true si contiene todas las notas, false si falta alguna
    private func containsAllRequiredNotes(perfume: Perfume, requiredNotes: [String]) -> Bool {
        // Reunir todas las notas del perfume
        let allNotes = (perfume.topNotes ?? []) + (perfume.heartNotes ?? []) + (perfume.baseNotes ?? [])
        let allNotesLower = allNotes.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        // Verificar que TODAS las notas requeridas estén presentes
        for requiredNote in requiredNotes {
            let noteLower = requiredNote.lowercased().trimmingCharacters(in: .whitespaces)
            if !allNotesLower.contains(noteLower) {
                return false  // Falta una nota requerida
            }
        }

        return true  // Todas las notas están presentes
    }

    /// Calcula bonus por notas específicas en heartNotes (Profile B)
    /// - Parameters:
    ///   - perfume: El perfume a evaluar
    ///   - bonusNotes: Notas que dan bonus si están en heartNotes
    /// - Returns: Puntos de bonus (escala 0-100)
    private func calculateHeartNotesBonus(perfume: Perfume, bonusNotes: [String]) -> Double {
        guard let heartNotes = perfume.heartNotes, !heartNotes.isEmpty else {
            return 0.0
        }

        let heartNotesLower = heartNotes.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        let matches = bonusNotes.filter { note in
            let noteLower = note.lowercased().trimmingCharacters(in: .whitespaces)
            return heartNotesLower.contains(noteLower)
        }.count

        // Sistema de bonus progresivo (similar a calculateNoteBonus)
        switch matches {
        case 0:
            return 0.0
        case 1:
            return 30.0   // 1 nota en heartNotes
        case 2:
            return 60.0   // 2 notas en heartNotes
        default:  // 3+
            return 100.0  // 3+ notas en heartNotes (bonus máximo)
        }
    }

    /// Calcula bonus por notas específicas en baseNotes (Profile B)
    /// - Parameters:
    ///   - perfume: El perfume a evaluar
    ///   - bonusNotes: Notas que dan bonus si están en baseNotes
    /// - Returns: Puntos de bonus (escala 0-100)
    private func calculateBaseNotesBonus(perfume: Perfume, bonusNotes: [String]) -> Double {
        guard let baseNotes = perfume.baseNotes, !baseNotes.isEmpty else {
            return 0.0
        }

        let baseNotesLower = baseNotes.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        let matches = bonusNotes.filter { note in
            let noteLower = note.lowercased().trimmingCharacters(in: .whitespaces)
            return baseNotesLower.contains(noteLower)
        }.count

        // Sistema de bonus progresivo (similar a calculateNoteBonus)
        switch matches {
        case 0:
            return 0.0
        case 1:
            return 30.0   // 1 nota en baseNotes
        case 2:
            return 60.0   // 2 notas en baseNotes
        default:  // 3+
            return 100.0  // 3+ notas en baseNotes (bonus máximo)
        }
    }
}
