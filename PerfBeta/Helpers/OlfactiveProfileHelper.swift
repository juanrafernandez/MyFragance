import Foundation

struct OlfactiveProfileHelper {
    
    /// Genera un OlfactiveProfile a partir de un diccionario de respuestas.
    /// - Parameter answers: Diccionario donde la clave es el *question key* y el valor es la opción seleccionada.
    /// - Returns: Un perfil olfativo generado.
    static func generateProfile(from answers: [String: Option]) -> OlfactiveProfile {
        var familyScores: [String: Int] = [:]
        
        let intensityKey = "intensity"
        let durationKey = "duration"
        let genderKey = "olfactive_gender"
        
        let intensityOption = answers[intensityKey]
        let durationOption = answers[durationKey]
        let genderOption = answers[genderKey]
        
        for (questionKey, option) in answers where questionKey != intensityKey && questionKey != durationKey {
            for (family, score) in option.families {
                familyScores[family, default: 0] += score
            }
        }
        
        let families = familyScores.map { FamilyPuntuation(family: $0.key, puntuation: $0.value) }
            .sorted { $0.puntuation > $1.puntuation }
        
        let intensityValue = intensityOption?.value ?? "Media"
        let durationValue = durationOption?.value ?? "Media"
        let genderValue = genderOption?.value ?? "Unisex"
        
        let questionAnswers: [QuestionAnswer] = answers.compactMap { (questionKey, option) in
            //let questionUUID = UUID(uuidString: questionKey) ?? UUID()
            //let answerUUID = UUID(uuidString: option.id) ?? UUID()
            return QuestionAnswer(questionId: questionKey, answerId: option.id)
        }
        
        return OlfactiveProfile(
            name: "Perfil generado",
            gender: genderValue,
            families: families,
            intensity: intensityValue,
            duration: durationValue,
            descriptionProfile: "Descripción del perfil generado",
            icon: nil,
            questionsAndAnswers: questionAnswers,
            orderIndex: -1
        )
    }
    
    static func suggestPerfumes(perfil: OlfactiveProfile, baseDeDatos: [Perfume], allFamilies: [Family], page: Int = 0, limit: Int = 10) async throws -> [RecommendedPerfume] {
        // Ordenar las familias del perfil por puntuación de mayor a menor y quedarse con las 3 primeras
        let familiasPerfil = Array(perfil.families.sorted { $0.puntuation > $1.puntuation }.prefix(3))

        // Filtrar perfumes por género
        let perfumesFiltradosPorGenero = baseDeDatos.filter { perfume in
            perfume.gender.lowercased() == perfil.gender.lowercased() || perfil.gender.lowercased() == "unisex" || perfume.gender.lowercased() == "unisex"
        }

        // Calcular la puntuación de cada perfume de manera asíncrona
        var perfumesFiltrados = [(perfume: Perfume, score: Double)]()

        try await withThrowingTaskGroup(of: (perfume: Perfume, score: Double).self) { group in
            for perfume in perfumesFiltradosPorGenero {
                group.addTask {
                    await calculateScore(for: perfume, using: familiasPerfil, perfil: perfil)
                }
            }

            for try await result in group {
                perfumesFiltrados.append(result)
            }
        }

        // Filtrar y ordenar los perfumes
        let filteredAndSortedPerfumes = perfumesFiltrados
            .filter { $0.score > 0 }  // Filtrar perfumes que no tienen puntuación
            .sorted { $0.score > $1.score }  // Ordenar por puntuación descendente

        let recommendedPerfumes = filteredAndSortedPerfumes.map { (perfume, score) in
            return RecommendedPerfume(perfumeId: perfume.id ?? "", matchPercentage: score)
        }
        
        // Calcular el porcentaje de afinidad
//        let maxScore = filteredAndSortedPerfumes.first?.score ?? 1.0
//        let recommendedPerfumes = filteredAndSortedPerfumes.map { (perfume, score) in
//            let matchPercentage = (score / maxScore) * 100
//            return RecommendedPerfume(perfumeId: perfume.id ?? "", matchPercentage: matchPercentage)
//        }

        // Implementar la paginación
        let startIndex = page * limit
        let endIndex = min(startIndex + limit, recommendedPerfumes.count)
        return Array(recommendedPerfumes[startIndex..<endIndex])
    }

    private static func calculateScore(for perfume: Perfume, using familiasPerfil: [FamilyPuntuation], perfil: OlfactiveProfile) async -> (perfume: Perfume, score: Double) {
        var score: Double = 0.0
        
        // 1. Puntuación por familia principal (40 puntos)
        if let mainFamily = familiasPerfil.first, perfume.family == mainFamily.family {
            score += 40.0
        }
        
        // 2. Puntuación por subfamilias (40 puntos distribuidos proporcionalmente)
        let secondaryFamilies = familiasPerfil.dropFirst()
        // Asegúrate de que secondaryFamilies no esté vacío antes de calcular el peso total
        if !secondaryFamilies.isEmpty {
            let totalSecondaryWeight = secondaryFamilies.reduce(0) { $0 + $1.puntuation }
            
            // Solo calcular si hay peso en subfamilias para evitar división por cero
            if totalSecondaryWeight > 0 {
                var subFamilyScoreContribution: Double = 0.0 // Puntuación acumulada solo de subfamilias
                for subfamilia in perfume.subfamilies {
                    if let matchingFamily = secondaryFamilies.first(where: { $0.family == subfamilia }) {
                        // Puntuación proporcional al peso de esta subfamilia en el perfil
                        let subfamilyProportion = Double(matchingFamily.puntuation) / Double(totalSecondaryWeight)
                        subFamilyScoreContribution += subfamilyProportion * 40.0
                    }
                }
                // Limitar el aporte de subfamilias a 40 puntos y añadirlo al score total
                score += min(subFamilyScoreContribution, 40.0)
            }
        } // Fin del bloque if !secondaryFamilies.isEmpty
        
        // 3. Puntuación por intensidad y duración (20 puntos)
        // Usar caseInsensitiveCompare para comparación de strings más robusta
        if perfume.intensity.caseInsensitiveCompare(perfil.intensity) == .orderedSame {
            score += 10.0
        }
        if perfume.duration.caseInsensitiveCompare(perfil.duration) == .orderedSame {
            score += 10.0
        }
        
        // Asegurar que el score no pase de 100 antes de redondear
        let finalScore = min(score, 100.0)
        
        // Redondear el score final a un decimal
        let roundedScore = round(finalScore * 10.0) / 10.0
        
        return (perfume: perfume, score: roundedScore)
    }
}
