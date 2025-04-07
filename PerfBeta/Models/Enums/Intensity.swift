import Foundation

enum Intensity: String, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
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
    
    var imageName: String {
        switch self {
        case .low:
            return "intensity_low"
        case .medium:
            return "intensity_medium"
        case .high:
            return "intensity_high"
        case .veryHigh:
            return "intensity_very_high"
        }
    }
}
