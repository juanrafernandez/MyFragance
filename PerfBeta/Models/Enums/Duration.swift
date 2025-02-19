import Foundation

enum Duration: String, CaseIterable, Identifiable {
    case short = "short"
    case moderate = "moderate"
    case long = "long"
    case veryLong = "very_long"

    var id: String { rawValue }

    /// Nombre localizable de la duración
    var displayName: String {
        NSLocalizedString("duracion.\(rawValue).name", comment: "Nombre de la duración: \(rawValue)")
    }

    /// Descripción localizable de la duración
    var description: String {
        NSLocalizedString("duracion.\(rawValue).description", comment: "Descripción de la duración: \(rawValue)")
    }

    static var defaultValue: Duration {
      .moderate // Por ejemplo, seleccionamos "moderada" como predeterminado
    }

    var displayNameForDuration: String {
        return displayName // To keep consistency with the previous approach, although it's redundant now.
    }
}
