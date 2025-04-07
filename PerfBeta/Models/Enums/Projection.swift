import Foundation

enum Projection: String, CaseIterable, Identifiable, SelectableOption {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case explosive = "explosive"

    var id: Projection { self }

    /// Nombre traducido del nivel de proyección
    var displayName: String {
        NSLocalizedString("projection.\(rawValue).name", comment: "Display name for projection: \(rawValue)")
    }

    /// Descripción traducida del nivel de proyección
    var description: String {
        NSLocalizedString("projection.\(rawValue).description", comment: "Description for projection: \(rawValue)")
    }

    /// Valor predeterminado
    static var defaultValue: Projection {
        .moderate // "moderada" como valor predeterminado
    }
    
    var imageName: String {
        switch self {
        case .low:
            return "projection_low"
        case .moderate:
            return "projection_moderate"
        case .high:
            return "projection_high"
        case .explosive:
            return "projection_explosive"
        }
    }
}
