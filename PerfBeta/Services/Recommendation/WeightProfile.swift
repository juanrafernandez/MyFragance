import Foundation

// MARK: - Weight Profile
/// Pesos contextuales según tipo de perfil y nivel de experiencia
/// Utilizado por UnifiedRecommendationEngine para ajustar la importancia de cada factor
struct WeightProfile {
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
                    families: 0.70,
                    notes: 0.00,
                    context: 0.15,
                    popularity: 0.10,
                    price: 0.05,
                    occasion: 0.075,
                    season: 0.075
                )
            case .intermediate:
                // Intermedios: Balance entre familias y notas
                return WeightProfile(
                    families: 0.60,
                    notes: 0.15,
                    context: 0.15,
                    popularity: 0.05,
                    price: 0.05,
                    occasion: 0.075,
                    season: 0.075
                )
            case .expert:
                // Expertos: Mayor peso en notas específicas
                return WeightProfile(
                    families: 0.50,
                    notes: 0.25,
                    context: 0.15,
                    popularity: 0.05,
                    price: 0.05,
                    occasion: 0.075,
                    season: 0.075
                )
            }
        } else {
            // Gift: Pesos fijos (no depende de experiencia del receptor)
            return WeightProfile(
                families: 0.40,
                notes: 0.10,
                context: 0.10,
                popularity: 0.20,
                price: 0.10,
                occasion: 0.15,
                season: 0.05
            )
        }
    }
}
