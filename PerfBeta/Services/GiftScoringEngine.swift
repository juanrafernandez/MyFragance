import Foundation

// MARK: - Gift Scoring Engine

/// Motor de scoring para recomendaciones de regalo
/// Analiza las respuestas del usuario y calcula scores para cada perfume
actor GiftScoringEngine {

    static let shared = GiftScoringEngine()

    private init() {}

    // MARK: - Public Methods

    /// Calcular recomendaciones basadas en las respuestas del usuario
    func calculateRecommendations(
        responses: GiftResponsesCollection,
        allPerfumes: [PerfumeMetadata],
        flowType: GiftFlowType?,
        limit: Int = 10
    ) async -> [GiftRecommendation] {

        #if DEBUG
        print("🎯 [ScoringEngine] Starting calculation for flow: \(flowType?.rawValue ?? "unknown")")
        print("   Available perfumes: \(allPerfumes.count)")
        #endif

        // Determinar qué estrategia de scoring usar según el flujo
        let scoredPerfumes: [(perfume: PerfumeMetadata, score: Double, matchFactors: [MatchFactor])]

        switch flowType {
        case .flowA:
            scoredPerfumes = await scoreFlowA(responses: responses, perfumes: allPerfumes)
        case .flowB1:
            scoredPerfumes = await scoreFlowB1(responses: responses, perfumes: allPerfumes)
        case .flowB2:
            scoredPerfumes = await scoreFlowB2(responses: responses, perfumes: allPerfumes)
        case .flowB3:
            scoredPerfumes = await scoreFlowB3(responses: responses, perfumes: allPerfumes)
        case .flowB4:
            scoredPerfumes = await scoreFlowB4(responses: responses, perfumes: allPerfumes)
        default:
            // Fallback: scoring genérico
            scoredPerfumes = await scoreGeneric(responses: responses, perfumes: allPerfumes)
        }

        #if DEBUG
        print("✅ [ScoringEngine] Scored \(scoredPerfumes.count) perfumes")
        let genderFilter = responses.perfumeType ?? "unknown"
        let genderFilteredCount = scoredPerfumes.filter { perfume in
            matchesGender(perfume: perfume.perfume, type: genderFilter)
        }.count
        print("   Gender requested: '\(genderFilter)'")
        print("   Perfumes after gender filter: \(genderFilteredCount)/\(scoredPerfumes.count)")
        #endif

        // ✅ Ordenar por score con aleatorización para scores similares
        // Esto da más variedad en las recomendaciones
        let topPerfumes = scoredPerfumes
            .sorted { item1, item2 in
                // Si los scores están muy cerca (diferencia < 5), aleatorizar
                if abs(item1.score - item2.score) < 5 {
                    return Bool.random()
                }
                return item1.score > item2.score
            }
            .prefix(limit)

        // Convertir a GiftRecommendation
        let recommendations = topPerfumes.map { item in
            GiftRecommendation(
                perfumeKey: item.perfume.key,
                score: item.score,
                reason: generateReason(for: item.perfume, matchFactors: item.matchFactors),
                matchFactors: item.matchFactors,
                confidence: calculateConfidence(score: item.score)
            )
        }

        #if DEBUG
        print("🎁 [ScoringEngine] Generated \(recommendations.count) recommendations")
        if let top = recommendations.first {
            print("   Top recommendation: \(top.perfumeKey) (score: \(String(format: "%.1f", top.score)))")
        }
        #endif

        return Array(recommendations)
    }

    // MARK: - Flow A: Conocimiento Bajo

    /// Scoring para usuarios con bajo conocimiento del receptor
    /// Se basa en: género, personalidad, ocasión, edad, intensidad, temporada
    private func scoreFlowA(
        responses: GiftResponsesCollection,
        perfumes: [PerfumeMetadata]
    ) async -> [(perfume: PerfumeMetadata, score: Double, matchFactors: [MatchFactor])] {

        // Extraer respuestas clave
        let perfumeType = responses.perfumeType // "hombre", "mujer", "unisex"
        let personality = responses.personalityStyle
        let occasion = responses.occasion
        let ageRange = responses.ageRange
        let intensity = responses.intensityPreference
        let season = responses.seasonPreference

        #if DEBUG
        print("🔍 [FlowA] Starting scoring with:")
        print("   Requested gender: '\(perfumeType ?? "none")'")
        print("   Personality: '\(personality ?? "none")'")
        print("   Total perfumes to evaluate: \(perfumes.count)")
        #endif

        var scored: [(PerfumeMetadata, Double, [MatchFactor])] = []
        var skippedByGender = 0
        var matchedByGender = 0

        for perfume in perfumes {
            var score: Double = 0
            var factors: [MatchFactor] = []

            // 1. Filtro de género (obligatorio, 0 o 30 puntos)
            if let type = perfumeType {
                if matchesGender(perfume: perfume, type: type) {
                    score += 30
                    matchedByGender += 1
                    factors.append(MatchFactor(
                        factor: "Género",
                        description: "Perfume \(perfume.gender)",
                        weight: 0.3
                    ))
                } else {
                    skippedByGender += 1
                    continue // Skip si no coincide el género
                }
            }

            // 2. Familia olfativa basada en personalidad (25 puntos)
            if let pers = personality {
                if matchesPersonality(perfume: perfume, personality: pers) {
                    score += 25
                    factors.append(MatchFactor(
                        factor: "Personalidad",
                        description: "Acorde con \(pers)",
                        weight: 0.25
                    ))
                }
            }

            // 3. Precio (20 puntos) - favorece precios accesibles
            if let price = perfume.price, (price == "low" || price == "medium") {
                score += 20
                factors.append(MatchFactor(
                    factor: "Precio",
                    description: "Excelente relación calidad-precio",
                    weight: 0.2
                ))
            }

            // 4. Popularidad (15 puntos)
            if let popularity = perfume.popularity, popularity >= 7 {
                score += 15
                factors.append(MatchFactor(
                    factor: "Popularidad",
                    description: "Alta valoración (\(String(format: "%.1f", popularity))/10)",
                    weight: 0.15
                ))
            }

            // 5. Modernidad (10 puntos) - perfumes recientes
            if let year = perfume.year, year >= Calendar.current.component(.year, from: Date()) - 5 {
                score += 10
                factors.append(MatchFactor(
                    factor: "Modernidad",
                    description: "Lanzamiento reciente (\(year))",
                    weight: 0.1
                ))
            }

            scored.append((perfume, score, factors))
        }

        #if DEBUG
        print("✅ [FlowA] Scoring complete:")
        print("   Matched by gender: \(matchedByGender)")
        print("   Skipped by gender: \(skippedByGender)")
        print("   Total scored perfumes: \(scored.count)")
        if let top = scored.sorted(by: { $0.1 > $1.1 }).first {
            print("   Top perfume: \(top.0.name) (\(top.0.gender)) - Score: \(String(format: "%.1f", top.1))")
        }
        #endif

        return scored
    }

    // MARK: - Flow B1: Por Marcas

    /// Scoring para usuarios que conocen las marcas favoritas
    private func scoreFlowB1(
        responses: GiftResponsesCollection,
        perfumes: [PerfumeMetadata]
    ) async -> [(perfume: PerfumeMetadata, score: Double, matchFactors: [MatchFactor])] {

        guard let selectedBrands = responses.selectedBrands, !selectedBrands.isEmpty else {
            return await scoreGeneric(responses: responses, perfumes: perfumes)
        }

        var scored: [(PerfumeMetadata, Double, [MatchFactor])] = []

        for perfume in perfumes {
            var score: Double = 0
            var factors: [MatchFactor] = []

            // Filtro principal: marca seleccionada (50 puntos)
            if selectedBrands.contains(where: { $0.lowercased() == perfume.brand.lowercased() }) {
                score += 50
                factors.append(MatchFactor(
                    factor: "Marca Favorita",
                    description: perfume.brand,
                    weight: 0.5
                ))
            } else {
                continue // Skip si no es una marca seleccionada
            }

            // Popularidad dentro de la marca (30 puntos)
            if let popularity = perfume.popularity {
                score += popularity * 3
                if popularity > 7 {
                    factors.append(MatchFactor(
                        factor: "Popularidad",
                        description: "Muy popular (\(String(format: "%.1f", popularity))/10)",
                        weight: 0.3
                    ))
                }
            }

            // Precio accesible (20 puntos)
            if let price = perfume.price, (price == "low" || price == "medium") {
                score += 20
                factors.append(MatchFactor(
                    factor: "Precio",
                    description: "Precio accesible",
                    weight: 0.2
                ))
            }

            scored.append((perfume, score, factors))
        }

        return scored
    }

    // MARK: - Flow B2: Por Perfume Conocido

    /// Scoring basado en similitud a un perfume de referencia
    private func scoreFlowB2(
        responses: GiftResponsesCollection,
        perfumes: [PerfumeMetadata]
    ) async -> [(perfume: PerfumeMetadata, score: Double, matchFactors: [MatchFactor])] {

        // TODO: Implementar búsqueda de perfume de referencia y similitud
        // Por ahora, usar scoring por familia
        return await scoreFlowB3(responses: responses, perfumes: perfumes)
    }

    // MARK: - Flow B3: Por Aromas

    /// Scoring basado en familias olfativas preferidas
    private func scoreFlowB3(
        responses: GiftResponsesCollection,
        perfumes: [PerfumeMetadata]
    ) async -> [(perfume: PerfumeMetadata, score: Double, matchFactors: [MatchFactor])] {

        guard let selectedAromas = responses.selectedAromas, !selectedAromas.isEmpty else {
            return await scoreGeneric(responses: responses, perfumes: perfumes)
        }

        var scored: [(PerfumeMetadata, Double, [MatchFactor])] = []

        for perfume in perfumes {
            var score: Double = 0
            var factors: [MatchFactor] = []

            // Coincidencia con familias seleccionadas (40 puntos)
            if selectedAromas.contains(where: { $0.lowercased() == perfume.family.lowercased() }) {
                score += 40
                factors.append(MatchFactor(
                    factor: "Familia Olfativa",
                    description: perfume.family,
                    weight: 0.4
                ))
            }

            // Subfamilias (30 puntos)
            if let subfamilies = perfume.subfamilies {
                let matchingSubfamilies = subfamilies.filter { subfamily in
                    selectedAromas.contains(where: { $0.lowercased() == subfamily.lowercased() })
                }
                if !matchingSubfamilies.isEmpty {
                    score += Double(matchingSubfamilies.count) * 10
                    factors.append(MatchFactor(
                        factor: "Subfamilias",
                        description: matchingSubfamilies.joined(separator: ", "),
                        weight: 0.3
                    ))
                }
            }

            // Popularidad (20 puntos)
            if let popularity = perfume.popularity {
                score += popularity * 2
            }

            // Precio accesible (10 puntos)
            if let price = perfume.price, (price == "low" || price == "medium") {
                score += 10
                factors.append(MatchFactor(
                    factor: "Precio",
                    description: "Precio accesible",
                    weight: 0.1
                ))
            }

            scored.append((perfume, score, factors))
        }

        return scored
    }

    // MARK: - Flow B4: Sin Referencias

    /// Scoring basado en estilo de vida
    private func scoreFlowB4(
        responses: GiftResponsesCollection,
        perfumes: [PerfumeMetadata]
    ) async -> [(perfume: PerfumeMetadata, score: Double, matchFactors: [MatchFactor])] {

        // Similar a Flow A pero con más peso en ocasión y personalidad
        return await scoreFlowA(responses: responses, perfumes: perfumes)
    }

    // MARK: - Scoring Genérico (Fallback)

    /// Scoring genérico cuando no hay suficiente información
    private func scoreGeneric(
        responses: GiftResponsesCollection,
        perfumes: [PerfumeMetadata]
    ) async -> [(perfume: PerfumeMetadata, score: Double, matchFactors: [MatchFactor])] {

        var scored: [(PerfumeMetadata, Double, [MatchFactor])] = []

        for perfume in perfumes {
            var score: Double = 0
            var factors: [MatchFactor] = []

            // Popularidad base (50% del score)
            if let popularity = perfume.popularity {
                score += popularity * 5
                factors.append(MatchFactor(
                    factor: "Popularidad",
                    description: "Puntuación \(String(format: "%.1f", popularity))/10",
                    weight: 0.5
                ))
            }

            // Precio accesible (+20 puntos si es bajo/medio)
            if let price = perfume.price, (price == "low" || price == "medium") {
                score += 20
                factors.append(MatchFactor(
                    factor: "Precio",
                    description: "Excelente relación calidad-precio",
                    weight: 0.2
                ))
            }

            // Múltiples subfamilias = más versátil (+15 puntos)
            if let subfamilies = perfume.subfamilies, subfamilies.count >= 2 {
                score += 15
                factors.append(MatchFactor(
                    factor: "Versatilidad",
                    description: "Perfume versátil con múltiples facetas",
                    weight: 0.15
                ))
            }

            // Reciente (+15 puntos si es de últimos 5 años)
            if let year = perfume.year, year >= Calendar.current.component(.year, from: Date()) - 5 {
                score += 15
                factors.append(MatchFactor(
                    factor: "Modernidad",
                    description: "Lanzamiento reciente (\(year))",
                    weight: 0.15
                ))
            }

            scored.append((perfume, score, factors))
        }

        return scored
    }

    // MARK: - Helper Methods

    private func matchesGender(perfume: PerfumeMetadata, type: String) -> Bool {
        let perfumeGender = perfume.gender.lowercased().trimmingCharacters(in: .whitespaces)
        let requestedType = type.lowercased().trimmingCharacters(in: .whitespaces)

        // Unisex coincide con todo
        if perfumeGender == "unisex" {
            return true
        }

        // ✅ Mapeo completo de género (soporta inglés y español)
        let maleVariants = ["hombre", "masculino", "male", "man", "men"]
        let femaleVariants = ["mujer", "femenino", "female", "woman", "women"]

        let isMaleRequest = maleVariants.contains(requestedType)
        let isFemaleRequest = femaleVariants.contains(requestedType)
        let isMalePerfume = maleVariants.contains(perfumeGender)
        let isFemalePerfume = femaleVariants.contains(perfumeGender)

        // Coincidencia exacta de género
        if (isMaleRequest && isMalePerfume) || (isFemaleRequest && isFemalePerfume) {
            return true
        }

        #if DEBUG
        // Log para debugging de filtrado
        if !((isMaleRequest && isMalePerfume) || (isFemaleRequest && isFemalePerfume)) {
            // No coincide - esto se usará para debugging
        }
        #endif

        return false
    }

    private func matchesPersonality(perfume: PerfumeMetadata, personality: String) -> Bool {
        // Mapeo de personalidades a familias olfativas
        let personalityToFamily: [String: [String]] = [
            "elegante": ["woody", "oriental"],
            "deportivo": ["fresh", "aquatic"],
            "romantico": ["floral", "gourmand"],
            "sofisticado": ["oriental", "woody"],
            "juvenil": ["fresh", "citrus"],
            "clasico": ["woody", "floral"]
        ]

        guard let families = personalityToFamily[personality.lowercased()] else {
            return false
        }

        return families.contains(where: { $0.lowercased() == perfume.family.lowercased() })
    }

    private func generateReason(for perfume: PerfumeMetadata, matchFactors: [MatchFactor]) -> String {
        if matchFactors.isEmpty {
            return "Perfume muy popular y versátil"
        }

        let topFactor = matchFactors.first!
        return "Perfecto por \(topFactor.factor.lowercased()): \(topFactor.description)"
    }

    private func calculateConfidence(score: Double) -> String {
        switch score {
        case 70...:
            return "high"
        case 40..<70:
            return "medium"
        default:
            return "low"
        }
    }
}
