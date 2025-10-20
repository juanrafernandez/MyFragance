import Combine
import SwiftUI

@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var wishlistPerfumes: [WishlistItem] = []
    @Published var triedPerfumes: [TriedPerfumeRecord] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString? // Asume que tienes este tipo definido

    // Dependencias: El servicio y AuthViewModel (para obtener ID actual)
    private let userService: UserServiceProtocol
    private let authViewModel: AuthViewModel // Añadido como dependencia
    private var cancellables = Set<AnyCancellable>()

    // *** CORREGIDO: Eliminado el valor por defecto ***
    // Ahora siempre requiere un servicio y el AuthViewModel
    init(userService: UserServiceProtocol, authViewModel: AuthViewModel) {
        self.userService = userService
        self.authViewModel = authViewModel

        // Observar cambios en el usuario para cargar/limpiar datos
        authViewModel.$currentUser
            .sink { [weak self] currentUser in
                guard let self = self else { return }
                if let user = currentUser, !user.id.isEmpty {
                    // Cargar datos cuando hay usuario
                    // Llamamos a Task para no bloquear el Sink
                    Task {
                        await self.loadInitialUserData(userId: user.id)
                    }
                } else {
                    // Limpiar datos si no hay usuario
                    self.clearUserData()
                }
            }
            .store(in: &cancellables)
    }

    // Función combinada para cargar todo al inicio o cuando el usuario cambie
    private func loadInitialUserData(userId: String) async {
        guard !isLoading else { return } // Evitar cargas múltiples
        isLoading = true
        errorMessage = nil
        print("UserViewModel: Loading initial data for user \(userId)")
        do {
            // Cargar usuario, wishlist y tried en paralelo si es posible
            async let userFetch = userService.fetchUser(by: userId)
            async let wishlistFetch = userService.fetchWishlist(for: userId)
            async let triedFetch = userService.fetchTriedPerfumes(for: userId)

            // Esperar resultados
            self.user = try await userFetch
            self.wishlistPerfumes = try await wishlistFetch
            self.triedPerfumes = try await triedFetch

            print("UserViewModel: Initial data loaded successfully.")

        } catch {
            print("🔴 UserViewModel: Error loading initial user data: \(error)")
            handleError("Error al cargar datos iniciales: \(error.localizedDescription)")
            // Limpiar datos si la carga falla
            clearUserData(keepError: true)
        }
        isLoading = false
    }

    // Limpiar datos (llamado en logout o error de carga inicial)
    private func clearUserData(keepError: Bool = false) {
        user = nil
        wishlistPerfumes = []
        triedPerfumes = []
        if !keepError {
             errorMessage = nil
        }
        // No necesitamos cambiar isLoading aquí normalmente
        print("UserViewModel: User data cleared.")
    }

    // Las funciones loadUserData, loadTriedPerfumes, loadWishlist individuales
    // podrían eliminarse si loadInitialUserData hace todo, o mantenerse
    // si necesitas recargar secciones específicas. Si las mantienes,
    // asegúrate de que obtengan el userId del authViewModel.

    // Ejemplo de cómo se vería loadTriedPerfumes si se mantiene:
    func loadTriedPerfumes() async {
        guard let userId = authViewModel.currentUser?.id else { return } // Obtener ID actual
        isLoading = true
        errorMessage = nil
        do {
            triedPerfumes = try await userService.fetchTriedPerfumes(for: userId)
        } catch {
            handleError("Error al cargar perfumes probados: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // Ejemplo de addTriedPerfume obteniendo userId de authViewModel
    func addTriedPerfume(perfumeId: String, perfumeKey: String, brandId: String, projection: String, duration: String, price: String, rating: Double, impressions: String, occasions: [String]?, seasons: [String]?, personalities: [String]?) async {
        guard let userId = authViewModel.currentUser?.id else {
             handleError("Usuario no autenticado.")
             return
        }
        isLoading = true
        errorMessage = nil
        do {
            // Pasar el userId obtenido al servicio
            try await userService.addTriedPerfume(userId: userId, perfumeId: perfumeId, perfumeKey: perfumeKey, brandId: brandId, projection: projection, duration: duration, price: price, rating: rating, impressions: impressions, occasions: occasions, seasons: seasons, personalities: personalities)
            await loadTriedPerfumes() // Recargar usando el método que obtiene userId internamente
        } catch {
            handleError("Error al añadir perfume probado: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // Adapta las demás funciones (update, delete, wishlist) de forma similar
    // para obtener el userId desde self.authViewModel.currentUser?.id

    func updateTriedPerfume(record: TriedPerfumeRecord) async { // Simplificado, asume record ya tiene userId
        guard authViewModel.currentUser?.id == record.userId else {
            handleError("Error de permisos o usuario incorrecto.")
            return
        }
        guard let recordId = record.id else {
             handleError("ID de registro inválido para actualizar.")
             return
        }
        isLoading = true
        errorMessage = nil
        do {
            // El record ya tiene el userId correcto
            let success = try await userService.updateTriedPerfumeRecord(record: record)
            if success {
                print("Perfume probado actualizado exitosamente con ID: \(recordId)")
                await loadTriedPerfumes()
            } else {
                handleError("Error al actualizar el perfume probado.")
            }
        } catch {
            handleError("Error al actualizar el perfume probado: \(error.localizedDescription)")
        }
        isLoading = false
    }

     func deleteTriedPerfume(recordId: String) async {
        guard let userId = authViewModel.currentUser?.id else {
             handleError("Usuario no autenticado.")
             return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.deleteTriedPerfumeRecord(userId: userId, recordId: recordId)
            // Optimista: eliminar de la lista local inmediatamente
            triedPerfumes.removeAll { $0.id == recordId }
            // O recargar: await loadTriedPerfumes()
            print("Registro eliminado exitosamente.")
        } catch {
             handleError("Error al eliminar perfume probado: \(error.localizedDescription)")
        }
         isLoading = false
    }

    // --- WISH LIST ---

    func loadWishlist() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        do {
            wishlistPerfumes = try await userService.fetchWishlist(for: userId)
        } catch {
            handleError("Error al cargar la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func addToWishlist(wishlistItem: WishlistItem) async {
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Usuario no autenticado.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.addToWishlist(userId: userId, wishlistItem: wishlistItem)
            await loadWishlist()
        } catch {
            handleError("Error al añadir a la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func removeFromWishlist(wishlistItem: WishlistItem) async {
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Usuario no autenticado.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.removeFromWishlist(userId: userId, wishlistItem: wishlistItem)
            await loadWishlist()
        } catch {
            handleError("Error al eliminar de la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func updateWishlistOrder(orderedPerfumes: [WishlistItem]) async {
         guard let userId = authViewModel.currentUser?.id else {
             handleError("Usuario no autenticado.")
             return
         }
        // La UI se actualiza por el binding, solo persistimos
        isLoading = true
        errorMessage = nil
        let previousOrder = self.wishlistPerfumes // Guardar por si hay error
        self.wishlistPerfumes = orderedPerfumes // Actualización optimista (opcional)

        do {
            try await userService.updateWishlistOrder(userId: userId, orderedItems: orderedPerfumes)
            print("Orden de la Wishlist actualizado en el backend.")
             // Podríamos recargar aquí para asegurar consistencia: await loadWishlist()
        } catch {
            handleError("Error al actualizar el orden de la wishlist: \(error.localizedDescription)")
             self.wishlistPerfumes = previousOrder // Revertir UI si falla
        }
        isLoading = false
    }

    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
         print("🔴 UserViewModel Error: \(message)")
    }
}
