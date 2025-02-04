import Foundation

enum Duration: String, CaseIterable, Identifiable {
    case corta = "corta"
    case moderada = "moderada"
    case larga = "larga"
    case muyLarga = "muy_larga"

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
            .moderada // Por ejemplo, seleccionamos "moderada" como predeterminado
        }
}
