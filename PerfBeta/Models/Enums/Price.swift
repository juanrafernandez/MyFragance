import Foundation

enum Price: String, CaseIterable, Identifiable {
    case veryCheap = "€"
    case cheap = "€€"
    case moderate = "€€€"
    case expensive = "€€€€"

    var id: String { rawValue }

    /// Nombre traducido del nivel de precio
    var displayName: String {
        NSLocalizedString("price.\(rawValue).name", comment: "Display name for price: \(rawValue)")
    }

    /// Descripción traducida del nivel de precio
    var description: String {
        NSLocalizedString("price.\(rawValue).description", comment: "Description for price: \(rawValue)")
    }
}
