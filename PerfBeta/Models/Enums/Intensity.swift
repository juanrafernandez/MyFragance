import Foundation

enum Intensity: String, CaseIterable, Identifiable {
    case veryLow = "very_low"
    case low = "low"
    case medium = "medium"
    case mediumHigh = "medium_high"
    case high = "high"
    case veryHigh = "very_high"

    var id: String { rawValue }

    /// Nombre traducido de la intensidad
    var displayName: String {
        NSLocalizedString("intensity.\(rawValue).name", comment: "Display name for intensity: \(rawValue)")
    }

    /// Descripción traducida de la intensidad
    var descriptionIntensity: String {
        NSLocalizedString("intensity.\(rawValue).description", comment: "Description for intensity: \(rawValue)")
    }
}
