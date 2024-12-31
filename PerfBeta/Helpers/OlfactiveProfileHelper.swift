import Foundation

import Foundation

struct OlfactiveProfileHelper {
    /// Calcula el perfil principal y el complementario basado en las respuestas ponderadas.
    static func calculateProfile(from answers: [String: Option]) -> (profile: String, complementaryProfile: String) {
        var familyScores: [String: Int] = [:]
        
        // Iterar sobre las respuestas y acumular puntuaciones para cada familia
        for option in answers.values {
            if let familias = option.familiasAsociadas {
                for (familia, score) in familias {
                    familyScores[familia, default: 0] += score
                }
            }
        }
        
        // Ordenar las familias por puntuación de mayor a menor
        let sortedFamilies = familyScores.sorted { $0.value > $1.value }
        
        // Obtener el perfil principal y complementario
        let profile = sortedFamilies.first?.key ?? "Desconocido"
        let complementaryProfile = sortedFamilies.dropFirst().first?.key ?? "Desconocido"
        
        return (profile, complementaryProfile)
    }

    /// Sugiere perfumes basados en el perfil principal y complementario del usuario.
    static func suggestPerfumes(
        for profileResult: (profile: String, complementaryProfile: String),
        families: [FamiliaOlfativa]
    ) -> [(perfume: Perfume, matchPercentage: Int)] {
        // Obtener notas clave de las familias olfativas
        let dominantNotes = families
            .first(where: { $0.id == profileResult.profile })?.notasClave ?? []
        let complementaryNotes = families
            .first(where: { $0.id == profileResult.complementaryProfile })?.notasClave ?? []

        // Calcular los perfumes sugeridos con puntuación
        return MockPerfumes.perfumes.map { perfume in
            var score = 0

            // Puntos por familia principal
            if perfume.familia == profileResult.profile {
                score += 10
            }

            // Puntos por familia complementaria
            if perfume.familia == profileResult.complementaryProfile {
                score += 5
            }

            // Puntos por notas clave
            for note in perfume.notas {
                if dominantNotes.contains(note) {
                    score += 3
                } else if complementaryNotes.contains(note) {
                    score += 1
                }
            }

            // Puntos por popularidad (opcional)
            score += Int(perfume.popularidad / 2) // Ejemplo: Escala popularidad a 0-5 puntos

            // Calcular porcentaje de coincidencia
            let maxScore = 10 + 5 + (dominantNotes.count * 3) + (complementaryNotes.count * 1) + 5
            let matchPercentage = Int((Double(score) / Double(maxScore)) * 100)

            return (perfume: perfume, matchPercentage: matchPercentage)
        }
        .sorted { $0.matchPercentage > $1.matchPercentage } // Ordenar por coincidencia
    }
}
