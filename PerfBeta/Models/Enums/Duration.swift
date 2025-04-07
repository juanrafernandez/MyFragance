import Foundation

enum Duration: String, CaseIterable, Identifiable, SelectableOption {
    case short = "short"
    case moderate = "moderate"
    case long = "long"
    case veryLong = "very_long"

    var id: Duration { self }

    /// Nombre localizable de la duración
    var displayName: String {
        NSLocalizedString("duracion.\(rawValue).name", comment: "Nombre de la duración: \(rawValue)")
    }

    /// Descripción localizable de la duración
    var description: String {
        NSLocalizedString("duracion.\(rawValue).description", comment: "Descripción de la duración: \(rawValue)")
    }

    static var defaultValue: Duration {
      .moderate
    }

    var displayNameForDuration: String {
        return displayName
    }
    
    var imageName: String {
        switch self {
        case .short:
            return "duration_short"
        case .moderate:
            return "duration_moderate"
        case .long:
            return "duration_long"
        case .veryLong:
            return "duration_very_long"
        }
    }
}
