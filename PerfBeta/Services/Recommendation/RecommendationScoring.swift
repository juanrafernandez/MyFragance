import Foundation

// MARK: - Recommendation Scoring
/// Funciones de cálculo de scores para el motor de recomendaciones
struct RecommendationScoring {

    // MARK: - Family Match

    /// Calcula match de familias olfativas (escala 0-100)
    static func calculateFamilyMatch(perfume: Perfume, profile: UnifiedProfile) -> Double {
        var score: Double = 0.0

        // Familia principal: 40 puntos
        if let primaryScore = profile.familyScores[perfume.family] {
            score += (primaryScore / 100.0) * 40.0
        }

        // Subfamilias: 40 puntos distribuidos
        for subfamily in perfume.subfamilies {
            if let subfamilyScore = profile.familyScores[subfamily] {
                score += (subfamilyScore / 100.0) * 10.0
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

    // MARK: - Note Bonus

    /// Calcula bonus por notas específicas (escala 0-100)
    static func calculateNoteBonus(perfume: Perfume, preferredNotes: [String]) -> Double {
        let allNotes = (perfume.topNotes ?? []) + (perfume.heartNotes ?? []) + (perfume.baseNotes ?? [])

        let matches = preferredNotes.filter { note in
            allNotes.contains(where: { $0.lowercased() == note.lowercased() })
        }.count

        switch matches {
        case 0: return 0.0
        case 1: return 40.0
        case 2: return 70.0
        default: return 100.0
        }
    }

    // MARK: - Heart Notes Bonus (Profile B)

    /// Calcula bonus por notas en heartNotes (escala 0-100)
    static func calculateHeartNotesBonus(perfume: Perfume, bonusNotes: [String]) -> Double {
        guard let heartNotes = perfume.heartNotes, !heartNotes.isEmpty else {
            return 0.0
        }

        let heartNotesLower = heartNotes.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        let matches = bonusNotes.filter { note in
            heartNotesLower.contains(note.lowercased().trimmingCharacters(in: .whitespaces))
        }.count

        switch matches {
        case 0: return 0.0
        case 1: return 30.0
        case 2: return 60.0
        default: return 100.0
        }
    }

    // MARK: - Base Notes Bonus (Profile B)

    /// Calcula bonus por notas en baseNotes (escala 0-100)
    static func calculateBaseNotesBonus(perfume: Perfume, bonusNotes: [String]) -> Double {
        guard let baseNotes = perfume.baseNotes, !baseNotes.isEmpty else {
            return 0.0
        }

        let baseNotesLower = baseNotes.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        let matches = bonusNotes.filter { note in
            baseNotesLower.contains(note.lowercased().trimmingCharacters(in: .whitespaces))
        }.count

        switch matches {
        case 0: return 0.0
        case 1: return 30.0
        case 2: return 60.0
        default: return 100.0
        }
    }

    // MARK: - Context Match

    /// Calcula match de contexto (ocasión + temporada) - escala 0-100
    static func calculateContextMatch(perfume: Perfume, metadata: UnifiedProfileMetadata) -> Double {
        var score: Double = 0.0
        var checks: Double = 0.0

        if let preferredOccasions = metadata.preferredOccasions {
            checks += 1
            let matchingOccasions = perfume.occasion.filter { occasion in
                preferredOccasions.contains(where: { $0.lowercased() == occasion.lowercased() })
            }
            if !matchingOccasions.isEmpty {
                score += 1.0
            }
        }

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
}
