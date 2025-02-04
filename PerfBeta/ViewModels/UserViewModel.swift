import Combine
import SwiftUI

@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: User? // Información general del usuario
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?

    private let userService: UserServiceProtocol

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

    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }
}
