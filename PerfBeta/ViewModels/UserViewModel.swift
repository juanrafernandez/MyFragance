import Combine
import SwiftUI

@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: User? // Información general del usuario
    @Published var wishlistPerfumes: [WishlistItem] = [] // Lista de WishlistItem en la wishlist (MODIFICADO a WishlistItem)
    @Published var triedPerfumes: [TriedPerfumeRecord] = [] // Lista de registros de perfumes probados
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?

    let userService: UserServiceProtocol

    init(userService: UserServiceProtocol = DependencyContainer.shared.userService) {
        self.userService = userService
    }

    func loadUserData(userId: String) async {
        isLoading = true
        do {
            user = try await userService.fetchUser(by: userId)
        } catch {
            handleError("Error al cargar datos del usuario: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func loadWishlist(userId: String) async {
        isLoading = true
        do {
            wishlistPerfumes = try await userService.fetchWishlist(for: userId) // Cargar WishlistItem directamente
        } catch {
            handleError("Error al cargar la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func loadTriedPerfumes(userId: String) async {
        isLoading = true
        do {
            triedPerfumes = try await userService.fetchTriedPerfumes(for: userId)
        } catch {
            handleError("Error al cargar perfumes probados: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MODIFIED addToWishlist to directly create and add WishlistItem
    func addToWishlist(userId: String, wishlistItem: WishlistItem) async {
        isLoading = true
        do {
            try await userService.addToWishlist(userId: userId, wishlistItem: wishlistItem) // Pass WishlistItem to userService
            // Optionally, reload wishlist to reflect changes
            await loadWishlist(userId: userId)
        } catch {
            handleError("Error al añadir a la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }


    func addTriedPerfume(userId: String, perfumeId: String, perfumeKey: String, brandId: String, projection: String, duration: String, price: String, rating: Double, impressions: String, occasions: [String]?, seasons: [String]?, personalities: [String]?) async {
        isLoading = true
        do {
            try await userService.addTriedPerfume(userId: userId, perfumeId: perfumeId, perfumeKey: perfumeKey, brandId: brandId, projection: projection, duration: duration, price: price, rating: rating, impressions: impressions, occasions: occasions, seasons: seasons, personalities: personalities)
            // Optionally, reload tried perfumes to reflect changes
            await loadTriedPerfumes(userId: userId)
        } catch {
            handleError("Error al añadir perfume probado: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Actualizar Perfume Probado Existente (No Changes)
    func updateTriedPerfume(
        userId: String,
        recordId: String,
        perfumeId: String,
        perfumeKey: String,
        brandId: String,
        projection: String,
        duration: String,
        price: String,
        rating: Double,
        impressions: String,
        occasions: [String]?,
        seasons: [String]?,
        personalities: [String]?
    ) async {
        isLoading = true
        errorMessage = nil // Clear any previous errors
        do {
            // Assuming TriedPerfumeRecord initializer is:
            // init(id: String?, userId: String, perfumeId: String, brandId: String, projection: String, duration: String, price: String, rating: Double?, impressions: String?, createdAt: Date?, updatedAt: Date?)

            let record = TriedPerfumeRecord(
                id: recordId, // Pass recordId to update existing record
                userId: userId, // Correct position for userId
                perfumeId: perfumeId,
                perfumeKey: perfumeKey,
                brandId: brandId,
                projection: projection,
                duration: duration,
                price: price,
                rating: rating,
                impressions: impressions,
                occasions: occasions,
                seasons: seasons,
                personalities: personalities,
                createdAt: Date(), // Provide a default Date() for createdAt - or adjust based on your model
                updatedAt: Date()  // Provide a default Date() for updatedAt - or adjust based on your model
            )
            let success = try await userService.updateTriedPerfumeRecord(record: record)
            if success {
                print("Perfume probado actualizado exitosamente con ID: \(recordId)")
                await loadTriedPerfumes(userId: userId) // Recargar la lista actualizada
            } else {
                errorMessage = IdentifiableString(value: "Error al actualizar el perfume probado.")
            }
        } catch {
            errorMessage = IdentifiableString(value: "Error al actualizar el perfume probado: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }

    func deleteTriedPerfume(userId: String, recordId: String) async -> Bool {
        do {
            try await userService.deleteTriedPerfumeRecord(recordId: recordId) // Assuming you have a userService method for deletion
            return true // Deletion successful
        } catch {
            print("Error deleting tried perfume record: \(error)")
            return false // Deletion failed
        }
    }

    // NEW: removeFromWishlist function to use WishlistItem (No Changes)
    func removeFromWishlist(userId: String, wishlistItem: WishlistItem) async {
        isLoading = true
        do {
            try await userService.removeFromWishlist(userId: userId, wishlistItem: wishlistItem) // Pass WishlistItem
            // Optionally, reload wishlist
            await loadWishlist(userId: userId)
        } catch {
            handleError("Error al eliminar de la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
