import Foundation

enum Projection: String, CaseIterable, Identifiable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case explosive = "explosive"

    var id: String { rawValue }

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
}
