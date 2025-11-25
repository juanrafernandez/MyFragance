import Foundation

/// Protocolo que define las propiedades necesarias para filtrar y ordenar perfumes
protocol FilterablePerfumeItem: Identifiable {
    var id: String { get }
    var perfume: Perfume { get }
    var personalRating: Double? { get }
}

// MARK: - Display Items

/// Item de visualización para perfumes probados
struct TriedPerfumeDisplayItem: Identifiable, FilterablePerfumeItem {
    let id: String
    let record: TriedPerfume
    let perfume: Perfume

    var personalRating: Double? {
        return record.rating
    }
}

/// Item de visualización para wishlist
struct WishlistItemDisplayData: Identifiable, FilterablePerfumeItem {
    let id: String
    let wishlistItem: WishlistItem
    let perfume: Perfume

    var personalRating: Double? {
        return nil
    }
}

// MARK: - Perfume Conformance

extension Perfume: FilterablePerfumeItem {
    var perfume: Perfume { self }
    var personalRating: Double? { nil }
}
