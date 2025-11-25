import Foundation

// MARK: - Question Processor
/**
 # Procesador de Preguntas

 Procesa las respuestas del usuario según la estrategia de cada pregunta.
 Diseñado para ser flexible y soportar nuevos tipos de preguntas sin modificar el código.

 ## Responsabilidades
 1. Determinar la estrategia de procesamiento de cada pregunta
 2. Calcular contribuciones a familias según la estrategia
 3. Extraer metadata de las opciones seleccionadas
 4. Manejar casos especiales (perfumes de referencia, notas, marcas)

 ## Uso
 ```swift
 let processor = QuestionProcessor(perfumeService: perfumeService)
 let result = await processor.processAnswers(answers)
 // result contiene: familyScores, metadata, filters
 ```
 */
actor QuestionProcessor {

    // MARK: - Dependencies
    private let perfumeService: PerfumeServiceProtocol?

    // MARK: - Configuration
    /// Puntos base para perfumes de referencia
    private let perfumeReferenceBasePoints: Double = 10.0

    /// Factor de normalización para múltiples perfumes de referencia
    private let multiPerfumeNormalizationFactor: Double = 0.7

    // MARK: - Init
    init(perfumeService: PerfumeServiceProtocol? = nil) {
        self.perfumeService = perfumeService
    }

    // MARK: - Process All Answers
    /// Procesa todas las respuestas y retorna el resultado consolidado
    func processAnswers(
        _ answers: [String: (question: Question, option: Option)],
        referencePerfumeData: [String: PerfumeReferenceData] = [:]
    ) async -> QuestionProcessingResult {

        var result = QuestionProcessingResult()
        var totalWeight: Int = 0
        var perfumeReferenceContributions: [String: Double] = [:]

        #if DEBUG
        print("\n")
        print("═══════════════════════════════════════════════════════════════════")
        print("🔄 [QuestionProcessor] PROCESANDO \(answers.count) RESPUESTAS")
        print("═══════════════════════════════════════════════════════════════════")
        #endif

        // Primera pasada: procesar todas las preguntas excepto inherit_from_reference
        for (questionKey, (question, option)) in answers {
            let strategy = QuestionProcessingStrategy.determine(from: question)
            let weight = question.weight ?? 0

            #if DEBUG
            print("\n🔄 [QuestionProcessor] ─────────────────────────────────────────")
            print("🔄 [QuestionProcessor] Pregunta: \(questionKey)")
            print("🔄 [QuestionProcessor]   Estrategia: \(strategy.rawValue)")
            print("🔄 [QuestionProcessor]   Weight: \(weight)")
            print("🔄 [QuestionProcessor]   Opción: \(option.label)")
            #endif

            switch strategy {
            case .standard:
                let contributions = processStandardQuestion(
                    question: question,
                    option: option,
                    weight: weight
                )
                mergeContributions(contributions, into: &result.familyContributions)
                totalWeight += weight

            case .perfumeDatabase:
                let (contributions, perfumes) = await processPerfumeDatabaseQuestion(
                    question: question,
                    option: option,
                    weight: weight
                )
                // Guardar contribuciones de perfumes por separado para normalización
                mergeContributions(contributions, into: &perfumeReferenceContributions)
                result.referencePerfumeIds.append(contentsOf: perfumes)
                totalWeight += weight

            case .notesDatabase:
                processNotesDatabaseQuestion(option: option, into: &result.metadata)

            case .brandsDatabase:
                processBrandsDatabaseQuestion(option: option, into: &result.filters)

            case .routing:
                #if DEBUG
                print("🔄 [QuestionProcessor]   → Routing, sin contribución")
                #endif

            case .metadataOnly:
                #if DEBUG
                print("🔄 [QuestionProcessor]   → Solo metadata, sin contribución a familias")
                #endif
            }

            // Siempre extraer metadata de la opción
            extractOptionMetadata(from: option, into: &result.metadata)

            // Detectar valores especiales en families
            if let specialValue = SpecialFamilyValue.detect(in: option.families) {
                await processSpecialFamilyValue(
                    specialValue: specialValue,
                    option: option,
                    referencePerfumeData: referencePerfumeData,
                    into: &result
                )
            }
        }

        // Normalizar contribuciones de perfumes de referencia
        // Los perfumes de referencia deben ser importantes pero no dominar completamente
        if !perfumeReferenceContributions.isEmpty {
            let normalizedPerfumeContributions = normalizePerfumeContributions(
                perfumeReferenceContributions,
                perfumeCount: result.referencePerfumeIds.count
            )
            mergeContributions(normalizedPerfumeContributions, into: &result.familyContributions)

            #if DEBUG
            print("\n🔄 [QuestionProcessor] Contribuciones de perfumes de referencia normalizadas:")
            for (family, score) in normalizedPerfumeContributions.sorted(by: { $0.value > $1.value }) {
                print("🔄 [QuestionProcessor]   \(family): \(String(format: "%.2f", score))")
            }
            #endif
        }

        #if DEBUG
        print("\n═══════════════════════════════════════════════════════════════════")
        print("🔄 [QuestionProcessor] RESULTADO FINAL")
        print("═══════════════════════════════════════════════════════════════════")
        print("🔄 [QuestionProcessor] Familias con scores:")
        for (family, score) in result.familyContributions.sorted(by: { $0.value > $1.value }) {
            print("🔄 [QuestionProcessor]   \(family): \(String(format: "%.2f", score))")
        }
        if result.filters.hasActiveFilters {
            print("🔄 [QuestionProcessor] Filtros activos:")
            if !result.filters.allowedBrands.isEmpty {
                print("🔄 [QuestionProcessor]   Marcas: \(result.filters.allowedBrands.joined(separator: ", "))")
            }
        }
        print("═══════════════════════════════════════════════════════════════════\n")
        #endif

        return result
    }

    // MARK: - Strategy: Standard
    /// Procesa pregunta estándar con families directas
    private func processStandardQuestion(
        question: Question,
        option: Option,
        weight: Int
    ) -> [String: Double] {

        guard weight > 0 else { return [:] }

        var contributions: [String: Double] = [:]

        for (family, points) in option.families {
            // Ignorar valores especiales
            guard SpecialFamilyValue(rawValue: family) == nil else { continue }

            let contribution = Double(points * weight)
            contributions[family, default: 0.0] += contribution

            #if DEBUG
            print("🔄 [QuestionProcessor]   ✓ \(family): +\(String(format: "%.1f", contribution)) (puntos:\(points) × weight:\(weight))")
            #endif
        }

        return contributions
    }

    // MARK: - Strategy: Perfume Database
    /// Procesa pregunta de perfumes de referencia
    private func processPerfumeDatabaseQuestion(
        question: Question,
        option: Option,
        weight: Int
    ) async -> (contributions: [String: Double], perfumeIds: [String]) {

        guard let perfumeService = perfumeService else {
            #if DEBUG
            print("🔄 [QuestionProcessor]   ⚠️ PerfumeService no disponible")
            #endif
            return ([:], [])
        }

        // Extraer IDs/keys de perfumes del valor de la opción
        let perfumeKeys = option.value
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }

        guard !perfumeKeys.isEmpty else { return ([:], []) }

        #if DEBUG
        print("🔄 [QuestionProcessor]   Analizando \(perfumeKeys.count) perfumes de referencia...")
        #endif

        var contributions: [String: Double] = [:]
        var validPerfumeIds: [String] = []

        for perfumeKey in perfumeKeys {
            do {
                guard let perfume = try await perfumeService.fetchPerfume(byKey: perfumeKey) else {
                    #if DEBUG
                    print("🔄 [QuestionProcessor]     ⚠️ Perfume no encontrado: \(perfumeKey)")
                    #endif
                    continue
                }

                validPerfumeIds.append(perfume.id ?? perfumeKey)

                // Familia principal: puntos base × weight
                let mainFamilyPoints = perfumeReferenceBasePoints * Double(weight)
                contributions[perfume.family, default: 0.0] += mainFamilyPoints

                #if DEBUG
                print("🔄 [QuestionProcessor]     ✓ \(perfume.name) - Familia: \(perfume.family) (+\(String(format: "%.1f", mainFamilyPoints)))")
                #endif

                // Subfamilias: puntos proporcionales decrecientes
                for (index, subfamily) in perfume.subfamilies.prefix(3).enumerated() {
                    let subfamilyFactor = 0.5 - (Double(index) * 0.15) // 50%, 35%, 20%
                    let subfamilyPoints = perfumeReferenceBasePoints * Double(weight) * subfamilyFactor
                    contributions[subfamily, default: 0.0] += subfamilyPoints

                    #if DEBUG
                    print("🔄 [QuestionProcessor]       → Subfamilia: \(subfamily) (+\(String(format: "%.1f", subfamilyPoints)))")
                    #endif
                }

            } catch {
                #if DEBUG
                print("🔄 [QuestionProcessor]     ❌ Error buscando perfume \(perfumeKey): \(error)")
                #endif
            }
        }

        return (contributions, validPerfumeIds)
    }

    // MARK: - Strategy: Notes Database
    /// Procesa pregunta de notas preferidas (solo metadata, no suma familias)
    private func processNotesDatabaseQuestion(
        option: Option,
        into metadata: inout ExtractedMetadata
    ) {
        let notes = option.value
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }

        metadata.preferredNotes.append(contentsOf: notes)

        #if DEBUG
        print("🔄 [QuestionProcessor]   📝 Notas guardadas para bonus: \(notes.joined(separator: ", "))")
        print("🔄 [QuestionProcessor]      (NO suman a familias, se usan como bonus directo en scoring)")
        #endif
    }

    // MARK: - Strategy: Brands Database
    /// Procesa pregunta de marcas preferidas (filtro obligatorio)
    private func processBrandsDatabaseQuestion(
        option: Option,
        into filters: inout ProfileFilters
    ) {
        let brands = option.value
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }

        filters.allowedBrands.append(contentsOf: brands)

        #if DEBUG
        print("🔄 [QuestionProcessor]   🏷️ Marcas como FILTRO OBLIGATORIO: \(brands.joined(separator: ", "))")
        print("🔄 [QuestionProcessor]      (Solo se recomendarán perfumes de estas marcas)")
        #endif
    }

    // MARK: - Special Family Values
    /// Procesa valores especiales en option.families
    private func processSpecialFamilyValue(
        specialValue: SpecialFamilyValue,
        option: Option,
        referencePerfumeData: [String: PerfumeReferenceData],
        into result: inout QuestionProcessingResult
    ) async {

        switch specialValue {
        case .inheritFromReference:
            // Obtener factor de herencia (valor numérico del campo)
            let factor = Double(option.families[specialValue.rawValue] ?? 1)

            #if DEBUG
            print("🔄 [QuestionProcessor]   🔗 inherit_from_reference detectado (factor: \(factor))")
            #endif

            // Usar perfumes de referencia ya procesados
            if !result.referencePerfumeIds.isEmpty {
                #if DEBUG
                print("🔄 [QuestionProcessor]      Heredando de \(result.referencePerfumeIds.count) perfumes de referencia")
                #endif
                // Las contribuciones ya fueron procesadas en perfumeDatabase
                // Este flag indica que el scoring debe priorizar similitud
            } else if let perfumeService = perfumeService {
                // Intentar buscar perfume del valor de la opción
                if let perfume = try? await perfumeService.fetchPerfume(byKey: option.value) {
                    let refData = PerfumeReferenceData(
                        perfumeId: perfume.id ?? "",
                        perfumeKey: perfume.key,
                        name: perfume.name,
                        brand: perfume.brand,
                        family: perfume.family,
                        subfamilies: perfume.subfamilies,
                        intensity: perfume.intensity,
                        price: perfume.price,
                        gender: perfume.gender
                    )
                    let contributions = refData.toFamilyContributions(factor: factor)
                    mergeContributions(contributions, into: &result.familyContributions)
                    result.referencePerfumeIds.append(perfume.id ?? option.value)
                }
            }

        case .complementReference:
            #if DEBUG
            print("🔄 [QuestionProcessor]   🔄 complement_reference detectado")
            print("🔄 [QuestionProcessor]      (Buscar perfumes que complementen, no dupliquen)")
            #endif
            // Este flag se usará en el scoring para penalizar perfumes muy similares
            // y favorecer perfumes complementarios
        }
    }

    // MARK: - Extract Option Metadata
    /// Extrae metadata de una opción
    private func extractOptionMetadata(from option: Option, into metadata: inout ExtractedMetadata) {
        guard let optionMeta = option.metadata else { return }

        // Género
        if let gender = optionMeta.genderType ?? optionMeta.gender {
            metadata.gender = gender
        }

        // Contexto
        if let occasions = optionMeta.occasion {
            metadata.preferredOccasions.append(contentsOf: occasions)
        }
        if let seasons = optionMeta.season {
            metadata.preferredSeasons.append(contentsOf: seasons)
        }
        if let personalities = optionMeta.personality {
            metadata.personalityTraits.append(contentsOf: personalities)
        }

        // Performance
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

        // Exclusiones
        if let avoidFamilies = optionMeta.avoidFamilies {
            metadata.avoidFamilies.append(contentsOf: avoidFamilies)
        }

        // Notas específicas (Profile B)
        if let mustContain = optionMeta.mustContainNotes {
            metadata.mustContainNotes.append(contentsOf: mustContain)
        }
        if let heartBonus = optionMeta.heartNotesBonus {
            metadata.heartNotesBonus.append(contentsOf: heartBonus)
        }
        if let baseBonus = optionMeta.baseNotesBonus {
            metadata.baseNotesBonus.append(contentsOf: baseBonus)
        }

        // Preferencias de estructura (Profile C)
        if let phase = optionMeta.phasePreference {
            metadata.phasePreference = phase
        }
        if let discovery = optionMeta.discoveryMode {
            metadata.discoveryMode = discovery
        }
    }

    // MARK: - Helper Methods

    /// Merge contribuciones de familias
    private func mergeContributions(
        _ contributions: [String: Double],
        into target: inout [String: Double]
    ) {
        for (family, score) in contributions {
            target[family, default: 0.0] += score
        }
    }

    /// Normaliza contribuciones de múltiples perfumes de referencia
    private func normalizePerfumeContributions(
        _ contributions: [String: Double],
        perfumeCount: Int
    ) -> [String: Double] {

        guard perfumeCount > 0 else { return contributions }

        // Si hay múltiples perfumes, normalizar para evitar que dominen
        // pero mantener su importancia relativa
        let normalizationFactor: Double
        if perfumeCount == 1 {
            normalizationFactor = 1.0
        } else if perfumeCount == 2 {
            normalizationFactor = multiPerfumeNormalizationFactor // 0.7
        } else {
            // 3+ perfumes: reducir más para que otras respuestas tengan peso
            normalizationFactor = multiPerfumeNormalizationFactor * 0.8 // 0.56
        }

        return contributions.mapValues { $0 * normalizationFactor }
    }
}
