import Foundation

struct OlfactiveProfileHelper {
    
    /// Genera un OlfactiveProfile a partir de un diccionario de respuestas.
    /// - Parameter answers: Diccionario donde la clave es el *question key* y el valor es la opción seleccionada.
    /// - Returns: Un perfil olfativo generado.
    static func generateProfile(from answers: [String: Option]) -> OlfactiveProfile {
        var familyScores: [String: Int] = [:]
        
        let intensityKey = "intensity"
        let durationKey = "duration"
        
        let intensityOption = answers[intensityKey]
        let durationOption = answers[durationKey]
        
        for (questionKey, option) in answers where questionKey != intensityKey && questionKey != durationKey {
            for (family, score) in option.families {
                familyScores[family, default: 0] += score
            }
        }
        
        let families = familyScores.map { FamilyPuntuation(family: $0.key, puntuation: $0.value) }
            .sorted { $0.puntuation > $1.puntuation }
        
        let intensityValue = intensityOption?.value ?? "Media"
        let durationValue = durationOption?.value ?? "Media"
        
        let questionAnswers: [QuestionAnswer] = answers.compactMap { (questionKey, option) in
            let questionUUID = UUID(uuidString: questionKey) ?? UUID()
            let answerUUID = UUID(uuidString: option.id) ?? UUID()
            return QuestionAnswer(questionId: questionUUID, answerId: answerUUID)
        }
        
        return OlfactiveProfile(
            name: "Perfil generado",
            gender: "Unisex",
            families: families,
            intensity: intensityValue,
            duration: durationValue,
            descriptionProfile: "Descripción del perfil generado",
            icon: nil,
            questionsAndAnswers: questionAnswers
        )
    }
    
    static func suggestPerfumes(perfil: OlfactiveProfile, baseDeDatos: [Perfume], page: Int = 0, limit: Int = 10) -> [Perfume] {
        // Ordenar las familias del perfil por puntuación de mayor a menor
        let familiasPerfil = perfil.families.sorted { $0.puntuation > $1.puntuation }

        // Crear un mapa de puntuaciones basado en las familias del perfil
        let puntuacionFamilias: [String: Int] = familiasPerfil.enumerated().reduce(into: [:]) { dict, enumerado in
            let (index, family) = enumerado
            dict[family.family] = familiasPerfil.count - index  // Asignar mayor puntuación a familias prioritarias
        }

        // Calcular la puntuación de cada perfume y filtrar los relevantes
        let perfumesFiltrados = baseDeDatos.map { perfume -> (perfume: Perfume, score: Int) in
            var score = 0

            // Comprobar si la familia principal del perfume coincide con alguna familia del perfil
            if let puntuacionFamiliaPrincipal = puntuacionFamilias[perfume.family] {
                score += puntuacionFamiliaPrincipal * 3  // La familia principal tiene un peso fuerte
            }

            // Comprobar cuántas subfamilias del perfume coinciden con las familias secundarias del perfil
            let puntuacionSubfamilias = perfume.subfamilies.reduce(0) { subtotal, subfamilia in
                subtotal + (puntuacionFamilias[subfamilia] ?? 0)
            }
            score += puntuacionSubfamilias

            // Comprobar coincidencias de intensidad y duración
            if perfume.intensity.lowercased() == perfil.intensity.lowercased() {
                score += 2  // Puntuación adicional si coincide la intensidad
            }
            if perfume.duration.lowercased() == perfil.duration.lowercased() {
                score += 2  // Puntuación adicional si coincide la duración
            }

            // Comprobar coincidencia de género
            if perfume.gender.lowercased() == perfil.gender.lowercased() || perfil.gender.lowercased() == "unisex" {
                score += 1
            }

            return (perfume: perfume, score: score)
        }
        .filter { $0.score > 0 }  // Filtrar perfumes que no tienen puntuación
        .sorted { $0.score > $1.score }  // Ordenar por puntuación descendente

        // Implementar la paginación
        let startIndex = page * limit
        let endIndex = min(startIndex + limit, perfumesFiltrados.count)
        return perfumesFiltrados[startIndex..<endIndex].map { $0.perfume }
    }
}
