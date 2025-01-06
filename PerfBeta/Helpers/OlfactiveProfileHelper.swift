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
    
    /// Genera un objeto `OlfactiveProfile` a partir de las respuestas proporcionadas.
//    static func generateProfile(
//        from answers: [String: Option]
//    ) -> OlfactiveProfile {
//        // Calcular la familia principal y complementaria
//        let profileResult = calculateProfile(from: answers)
//        let families = FamiliaOlfativaManager().familias
//        let questions = QuestionService().getAllQuestions()
//        let name = "Tu Perfil"
//        
//        
//        // Obtener la familia principal
//        let mainFamily = families.first(where: { $0.id == profileResult.profile }) ?? FamiliaOlfativa(
//            id: "desconocido",
//            nombre: "Desconocido",
//            descripcion: "No se pudo determinar una familia principal.",
//            notasClave: [],
//            ingredientesAsociados: [],
//            intensidadPromedio: "Desconocida",
//            estacionRecomendada: [],
//            personalidadAsociada: [],
//            color: "#000000"
//        )
//        
//        // Obtener las familias complementarias
//        let complementaryFamilies = families.filter { $0.id != profileResult.profile && profileResult.complementaryProfile.contains($0.id) }
//        
//        // Sugerir perfumes basados en las familias
//        let suggestedPerfumes = suggestPerfumes(for: profileResult, families: families).map { $0.perfume }
//        
//        // Generar preguntas y respuestas
//        let questionsAndAnswers = questions.map { question in
//            QuestionAnswer(
//                questionId: question.id,
//                answerId: answers[question.id]?.value ?? "unknown"
//            )
//        }
//        
//        // Crear y devolver el perfil
//        return OlfactiveProfile(
//            name: name,
//            perfumes: suggestedPerfumes,
//            familia: mainFamily,
//            complementaryFamilies: complementaryFamilies,
//            description: "Un perfil basado en tus respuestas.",
//            icon: "icon_default",
//            questionsAndAnswers: questionsAndAnswers
//        )
//    }
    
    static func generateProfile(from answers: [String: Option]) -> OlfactiveProfile {
        var familyScores: [String: Int] = [:]
        let name = "Tu Perfil"

        // Obtener todas las familias de FamiliaOlfativaManager
        let allFamilies = FamiliaOlfativaManager().familias

        // Obtener género
        var gender = "masculino"
        
        // Iterar sobre las respuestas y acumular puntuaciones para cada familia
        for option in answers.values {
            if let familias = option.familiasAsociadas {
                for (familia, score) in familias {
                    familyScores[familia, default: 0] += score
                }
            }

            if let genderSelected = option.label?.uppercased(),
               let genderEnum = Gender(rawValue: genderSelected) { // Intenta convertir a Gender
                gender = genderEnum.rawValue // Asigna el valor del Gender
            }

        }

        // Ordenar las familias por puntuación de mayor a menor
        let sortedFamilies = familyScores.sorted { $0.value > $1.value }

        // Obtener la familia principal
        guard let mainFamilyID = sortedFamilies.first?.key,
              let mainFamily = allFamilies.first(where: { $0.id == mainFamilyID }) else {
            fatalError("No se pudo determinar la familia principal.")
        }

        // Obtener las familias complementarias (máximo 2)
        let complementaryFamilyIDs = sortedFamilies.dropFirst().prefix(2).map { $0.key }
        let complementaryFamilies = allFamilies.filter { complementaryFamilyIDs.contains($0.id) }
        
        // Generar perfumes sugeridos
        let suggestedPerfumes = suggestPerfumes(
            profile: mainFamily.id,
            complementaryProfile: complementaryFamilyIDs.first ?? "Desconocido"
        ).map { $0.perfume }

        // Generar preguntas y respuestas
        let questionsAndAnswers = answers.map { questionID, option in
            QuestionAnswer(questionId: questionID, answerId: option.value)
        }

        // Crear y devolver el perfil
        return OlfactiveProfile(
            name: name,
            genero: gender,
            perfumes: suggestedPerfumes,
            familia: mainFamily,
            complementaryFamilies: complementaryFamilies,
            description: "Un perfil basado en tus respuestas.",
            icon: "icon_default",
            questionsAndAnswers: questionsAndAnswers
        )
    }
    
    /// Sugiere perfumes basados en el perfil principal y complementario del usuario.
    static func suggestPerfumes(
        profile: String,
        complementaryProfile: String
    ) -> [(perfume: Perfume, matchPercentage: Int)] {
        let families = FamiliaOlfativaManager().familias
        // Obtener notas clave de las familias olfativas
        let dominantNotes = families
            .first(where: { $0.id == profile })?.notasClave ?? []
        let complementaryNotes = families
            .first(where: { $0.id == complementaryProfile })?.notasClave ?? []

        // Calcular los perfumes sugeridos con puntuación
        return PerfumeManager().getAllPerfumes().map { perfume in
            var score = 0

            // Puntos por familia principal
            if perfume.familia == profile {
                score += 10
            }

            // Puntos por familia complementaria
            if perfume.familia == complementaryProfile {
                score += 5
            }

            // Puntos por notas clave
            for note in perfume.notasPrincipales {
                if dominantNotes.contains(note) {
                    score += 3
                } else if complementaryNotes.contains(note) {
                    score += 1
                }
            }

            // Puntos por popularidad (opcional)
            //score += Int(perfume.popularidad / 2) // Ejemplo: Escala popularidad a 0-5 puntos

            // Calcular porcentaje de coincidencia
            let maxScore = 10 + 5 + (dominantNotes.count * 3) + (complementaryNotes.count * 1) + 5
            let matchPercentage = Int((Double(score) / Double(maxScore)) * 100)

            return (perfume: perfume, matchPercentage: matchPercentage)
        }
        .sorted { $0.matchPercentage > $1.matchPercentage } // Ordenar por coincidencia
    }
}
