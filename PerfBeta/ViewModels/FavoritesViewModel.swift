import Combine
import SwiftUI

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var wishlist: [Perfume] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?

    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol = DependencyContainer.shared.userService) {
        self.userService = userService
    }

    func loadWishlist(userId: String) async {
        isLoading = true
        do {
            wishlist = try await userService.fetchWishlist(for: userId)
        } catch {
            handleError("Error al cargar la lista de deseos: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }
}
