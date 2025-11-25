import Foundation

// MARK: - Recommendation Filters
/// Filtros y validaciones para el motor de recomendaciones
struct RecommendationFilters {

    // MARK: - Gender Matching

    /// Verifica si el perfume coincide con la preferencia de género
    static func matchesGender(perfume: Perfume, preference: String) -> Bool {
        let perfumeGender = perfume.gender.lowercased().trimmingCharacters(in: .whitespaces)
        let preferredGender = preference.lowercased().trimmingCharacters(in: .whitespaces)

        if preferredGender == "any" || preferredGender == "all" {
            return true
        }

        if perfumeGender == "unisex" || preferredGender == "unisex" {
            return true
        }

        let maleVariants = ["hombre", "masculino", "male", "man", "men", "masculine"]
        let femaleVariants = ["mujer", "femenino", "female", "woman", "women", "feminine"]

        let isMalePreference = maleVariants.contains(preferredGender)
        let isFemalePreference = femaleVariants.contains(preferredGender)
        let isMalePerfume = maleVariants.contains(perfumeGender)
        let isFemalePerfume = femaleVariants.contains(perfumeGender)

        return (isMalePreference && isMalePerfume) || (isFemalePreference && isFemalePerfume)
    }

    // MARK: - Intensity Matching (Profile B)

    /// Verifica si el perfume cumple con el límite de intensidad máxima
    static func matchesIntensityLimit(perfume: Perfume, maxIntensity: String) -> Bool {
        let intensityLevels: [String: Int] = [
            "low": 1, "medium": 2, "high": 3,
            "very_high": 4, "very high": 4, "veryhigh": 4
        ]

        let perfumeIntensity = perfume.intensity.lowercased().trimmingCharacters(in: .whitespaces)
        let maxIntensityNormalized = maxIntensity.lowercased().trimmingCharacters(in: .whitespaces)

        guard let perfumeLevel = intensityLevels[perfumeIntensity],
              let maxLevel = intensityLevels[maxIntensityNormalized] else {
            return true
        }

        return perfumeLevel <= maxLevel
    }

    // MARK: - Required Notes (Profile B)

    /// Verifica si el perfume contiene TODAS las notas requeridas
    static func containsAllRequiredNotes(perfume: Perfume, requiredNotes: [String]) -> Bool {
        let allNotes = (perfume.topNotes ?? []) + (perfume.heartNotes ?? []) + (perfume.baseNotes ?? [])
        let allNotesLower = allNotes.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        for requiredNote in requiredNotes {
            let noteLower = requiredNote.lowercased().trimmingCharacters(in: .whitespaces)
            if !allNotesLower.contains(noteLower) {
                return false
            }
        }

        return true
    }
}
