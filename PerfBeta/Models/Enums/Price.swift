import Foundation

enum Price: String, CaseIterable, Identifiable, SelectableOption {
    case veryCheap = "€"
    case cheap = "€€"
    case moderate = "€€€"
    case expensive = "€€€€"

    var id: Price { self }

    /// Nombre traducido del nivel de precio
    var displayName: String {
        NSLocalizedString("price.\(rawValue).name", comment: "Display name for price: \(rawValue)")
    }

    /// Descripción traducida del nivel de precio
    var description: String {
        NSLocalizedString("price.\(rawValue).description", comment: "Description for price: \(rawValue)")
    }
    
    var imageName: String {
        switch self {
        case .veryCheap:
            return "price_veryCheap"
        case .cheap:
            return "price_cheap"
        case .moderate:
            return "price_moderate"
        case .expensive:
            return "price_expensive"
        }
    }
}
