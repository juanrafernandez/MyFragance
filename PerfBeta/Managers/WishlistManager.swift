import SwiftUI

class WishlistManager: ObservableObject {
    @Published var wishlist: [Perfume] = [] // Lista de perfumes en la lista de deseos

    func addToWishlist(_ perfume: Perfume) {
        if !wishlist.contains(where: { $0.id == perfume.id }) {
            wishlist.append(perfume)
        }
    }

    func removeFromWishlist(_ perfume: Perfume) {
        wishlist.removeAll(where: { $0.id == perfume.id })
    }

    func isInWishlist(_ perfume: Perfume) -> Bool {
        wishlist.contains(where: { $0.id == perfume.id })
    }
}
