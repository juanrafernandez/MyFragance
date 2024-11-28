import Foundation

class QuizViewModel: ObservableObject {
    @Published var answers: [String] = []
    
    func calculateProfile() -> [String: Double] {
        // Simulación de lógica para calcular perfil
        var profile: [String: Double] = ["Cítricas": 0, "Florales": 0, "Amaderadas": 0, "Dulces": 0]

        for answer in answers {
            profile[answer, default: 0] += 1
        }

        // Normalizar los resultados
        let total = profile.values.reduce(0, +)
        for key in profile.keys {
            profile[key]! = (profile[key]! / total) * 100
        }

        return profile
    }
    
    func recommendPerfumes() -> [Perfume] {
        let profile = calculateProfile()
        return MockPerfumes.perfumes.sorted {
            let affinity1 = $0.notas.reduce(0) { $0 + (profile[$1] ?? 0) }
            let affinity2 = $1.notas.reduce(0) { $0 + (profile[$1] ?? 0) }
            return (affinity1 * 0.7 + $0.popularidad * 0.3) >
                   (affinity2 * 0.7 + $1.popularidad * 0.3)
        }
    }
}
