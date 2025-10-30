import Combine
import SwiftUI

// TODO: Reimplement DataIntegrityChecker for new models (using perfumeId)

// MARK: - UserViewModel
/// Manages user data, tried perfumes, and wishlist with offline-first architecture
/// Loading states control LoadingScreen visibility in MainTabView
@MainActor
final class UserViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var user: User?
    @Published var wishlistPerfumes: [WishlistItem] = []
    @Published var triedPerfumes: [TriedPerfume] = []

    /// Controls LoadingScreen visibility in MainTabView
    @Published var isLoading: Bool = true  // Starts true, disabled if no user
    @Published var isLoadingTriedPerfumes: Bool = true
    @Published var isLoadingWishlist: Bool = true
    @Published var errorMessage: IdentifiableString?

    // ✅ OFFLINE-FIRST: Background sync states (non-blocking)
    @Published var isSyncingUser = false
    @Published var isSyncingTriedPerfumes = false
    @Published var isSyncingWishlist = false
    @Published var isOffline = false

    // MARK: - Private Properties

    /// Prevents duplicate loading calls (reset on logout)
    private var hasLoadedTriedPerfumes = false
    private var hasLoadedWishlist = false
    private var hasLoadedInitialData = false

    // Dependencies
    private let userService: UserServiceProtocol
    private let authViewModel: AuthViewModel
    private let perfumeService: PerfumeServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // *** CORREGIDO: Eliminado el valor por defecto ***
    // Ahora siempre requiere un servicio y el AuthViewModel
    init(
        userService: UserServiceProtocol,
        authViewModel: AuthViewModel,
        perfumeService: PerfumeServiceProtocol = DependencyContainer.shared.perfumeService
    ) {
        self.userService = userService
        self.authViewModel = authViewModel
        self.perfumeService = perfumeService

        // ✅ FIX: Chequear si hay usuario al iniciar el ViewModel
        if let currentUser = authViewModel.currentUser, !currentUser.id.isEmpty {
            print("👤 [UserViewModel] User detected at init, loading data...")
            Task {
                await self.loadInitialUserData(userId: currentUser.id)
            }
        } else {
            // No hay usuario - deshabilitar loading inmediatamente
            print("👤 [UserViewModel] No user at init, disabling loading states")
            Task { @MainActor in
                self.isLoading = false
                self.isLoadingTriedPerfumes = false
                self.isLoadingWishlist = false
            }
        }

        // Observer para cambios futuros de usuario (login/logout)
        authViewModel.$currentUser
            .dropFirst() // ✅ Ignorar el valor inicial (ya procesado arriba)
            .sink { [weak self] currentUser in
                guard let self = self else { return }

                if let user = currentUser, !user.id.isEmpty {
                    print("👤 [UserViewModel] User changed, loading data for: \(user.id)")
                    Task {
                        await self.loadInitialUserData(userId: user.id)
                    }
                } else {
                    print("👤 [UserViewModel] User logged out, clearing data")
                    self.clearUserData()
                    Task { @MainActor in
                        self.isLoading = false
                        self.isLoadingTriedPerfumes = false
                        self.isLoadingWishlist = false
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    /// Loads user, tried perfumes, and wishlist in parallel
    /// Called automatically when user logs in (via authViewModel observer)
    /// Uses offline-first strategy: cache → network → background sync
    private func loadInitialUserData(userId: String) async {
        // Prevent duplicate loads
        guard !hasLoadedInitialData else {
            print("⚠️ [UserViewModel] Already loading/loaded, skipping duplicate call")
            return
        }

        // Mark as started IMMEDIATELY (before Task)
        hasLoadedInitialData = true

        print("📱 [UserViewModel] Loading initial data (offline-first)")

        let hasAnyData = !triedPerfumes.isEmpty || !wishlistPerfumes.isEmpty || user != nil
        if !hasAnyData {
            print("⏳ [UserViewModel] First load - fetching data...")
        }

        errorMessage = nil
        isOffline = false

        let startTime = Date()

        do {
            // ⚡ CRÍTICO: async let ejecuta TODO en PARALELO
            // Si viene de caché → todas completan en ~0.02s
            async let userTask = userService.fetchUser(by: userId)
            async let wishlistTask = userService.fetchWishlist(for: userId)
            async let triedTask = userService.fetchTriedPerfumes(for: userId)

            // ⚡ OPTIMIZACIÓN: Esperar todas las tareas en paralelo (tuple)
            let (fetchedUser, fetchedWishlist, fetchedTried) = try await (
                userTask,
                wishlistTask,
                triedTask
            )

            // ⚡ Actualizar UI INMEDIATAMENTE (atómico con isLoading)
            let duration = Date().timeIntervalSince(startTime)
            self.user = fetchedUser
            self.wishlistPerfumes = fetchedWishlist
            self.triedPerfumes = fetchedTried
            self.isLoading = false  // ← TERMINA AQUÍ (instantáneo si es caché)
            self.isLoadingTriedPerfumes = false
            self.isLoadingWishlist = false

            print("✅ [UserViewModel] Initial data loaded in \(String(format: "%.3f", duration))s: \(fetchedTried.count) tried, \(fetchedWishlist.count) wishlist")

            // Background syncs corren SOLOS en UserService (Task.detached)
            // NO bloquean este método

        } catch {
            // ✅ Si falla, terminar loading igual
            let duration = Date().timeIntervalSince(startTime)
            self.isLoading = false
            self.isLoadingTriedPerfumes = false
            self.isLoadingWishlist = false

            print("⚠️ [UserViewModel] Load failed in \(String(format: "%.3f", duration))s (keeping cached data): \(error.localizedDescription)")

            // Detectar si es error de red
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("offline") || errorString.contains("internet") || errorString.contains("network") {
                self.isOffline = true
                print("📴 [UserViewModel] App is offline, using cached data")
            } else {
                // Otros errores (no de red) - mostrar mensaje
                handleError("Error al cargar datos: \(error.localizedDescription)")
            }

            // ❌ ELIMINADO: clearUserData(keepError: true)
            // Los datos en caché se mantienen SIEMPRE
        }
    }

    // Limpiar datos (llamado en logout o error de carga inicial)
    private func clearUserData(keepError: Bool = false) {
        user = nil
        wishlistPerfumes = []
        triedPerfumes = []

        // ✅ CRÍTICO: Resetear flags de carga para permitir reload después de login
        hasLoadedInitialData = false
        hasLoadedTriedPerfumes = false
        hasLoadedWishlist = false

        if !keepError {
             errorMessage = nil
             isOffline = false
        }

        print("🧹 [UserViewModel] User data cleared, flags reset")
    }

    // Las funciones loadUserData, loadTriedPerfumes, loadWishlist individuales
    // podrían eliminarse si loadInitialUserData hace todo, o mantenerse
    // si necesitas recargar secciones específicas. Si las mantienes,
    // asegúrate de que obtengan el userId del authViewModel.

    // ✅ OFFLINE-FIRST: Load tried perfumes
    func loadTriedPerfumes() async {
        guard let userId = authViewModel.currentUser?.id else { return }

        // Si ya hay datos, marcar como syncing en lugar de loading
        if !triedPerfumes.isEmpty {
            isSyncingTriedPerfumes = true
        } else {
            isLoadingTriedPerfumes = true
        }

        defer {
            isLoadingTriedPerfumes = false
            isSyncingTriedPerfumes = false
            hasLoadedTriedPerfumes = true
        }

        errorMessage = nil

        do {
            triedPerfumes = try await userService.fetchTriedPerfumes(for: userId)
            print("✅ [UserViewModel] Cargados \(triedPerfumes.count) perfumes probados")
        } catch {
            // ❌ NO BORRAR DATOS - Mantener caché
            print("⚠️ [UserViewModel] Error cargando tried perfumes (keeping cache): \(error.localizedDescription)")

            // Solo mostrar error si no hay datos en caché
            if triedPerfumes.isEmpty {
                handleError("Error al cargar perfumes probados: \(error.localizedDescription)")
            }
        }
    }

    // ✅ REFACTOR: Método simplificado con nueva API
    func addTriedPerfume(perfumeId: String, rating: Double, userProjection: String?, userDuration: String?, userPrice: String?, notes: String?, userSeasons: [String]?, userPersonalities: [String]?) async {
        guard let userId = authViewModel.currentUser?.id else {
             handleError("Usuario no autenticado.")
             return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.addTriedPerfume(
                userId: userId,
                perfumeId: perfumeId,
                rating: rating,
                userProjection: userProjection,
                userDuration: userDuration,
                userPrice: userPrice,
                notes: notes,
                userSeasons: userSeasons,
                userPersonalities: userPersonalities
            )
            await loadTriedPerfumes()
        } catch {
            handleError("Error al añadir perfume probado: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // ✅ REFACTOR: Actualizar perfume probado
    func updateTriedPerfume(_ triedPerfume: TriedPerfume) async {
        guard authViewModel.currentUser?.id == triedPerfume.userId else {
            handleError("Error de permisos o usuario incorrecto.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.updateTriedPerfume(triedPerfume)
            await loadTriedPerfumes()
        } catch {
            handleError("Error al actualizar el perfume probado: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // ✅ REFACTOR: Eliminar perfume probado
    func removeTriedPerfume(perfumeId: String) async {
        guard let userId = authViewModel.currentUser?.id else {
             handleError("Usuario no autenticado.")
             return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.removeTriedPerfume(userId: userId, perfumeId: perfumeId)
            // Optimista: eliminar de la lista local inmediatamente
            triedPerfumes.removeAll { $0.perfumeId == perfumeId }
            print("Perfume eliminado exitosamente.")
        } catch {
             handleError("Error al eliminar perfume probado: \(error.localizedDescription)")
        }
         isLoading = false
    }

    // --- WISH LIST (OFFLINE-FIRST) ---

    func loadWishlist() async {
        guard let userId = authViewModel.currentUser?.id else { return }

        // Si ya hay datos, marcar como syncing en lugar de loading
        if !wishlistPerfumes.isEmpty {
            isSyncingWishlist = true
        } else {
            isLoadingWishlist = true
        }

        defer {
            isLoadingWishlist = false
            isSyncingWishlist = false
            hasLoadedWishlist = true
        }

        errorMessage = nil

        do {
            wishlistPerfumes = try await userService.fetchWishlist(for: userId)
            print("✅ [UserViewModel] Cargados \(wishlistPerfumes.count) items en wishlist")
        } catch {
            // ❌ NO BORRAR DATOS - Mantener caché
            print("⚠️ [UserViewModel] Error cargando wishlist (keeping cache): \(error.localizedDescription)")

            // Solo mostrar error si no hay datos en caché
            if wishlistPerfumes.isEmpty {
                handleError("Error al cargar la wishlist: \(error.localizedDescription)")
            }
        }
    }

    // ✅ REFACTOR: Añadir a wishlist con nueva API
    func addToWishlist(perfumeId: String, notes: String? = nil, priority: Int? = nil) async {
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Usuario no autenticado.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.addToWishlist(userId: userId, perfumeId: perfumeId, notes: notes, priority: priority)
            await loadWishlist()
        } catch {
            handleError("Error al añadir a la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // ✅ REFACTOR: Eliminar de wishlist con nueva API
    func removeFromWishlist(perfumeId: String) async {
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Usuario no autenticado.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.removeFromWishlist(userId: userId, perfumeId: perfumeId)
            // Optimista: eliminar de la lista local
            wishlistPerfumes.removeAll { $0.perfumeId == perfumeId }
        } catch {
            handleError("Error al eliminar de la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // ✅ REFACTOR: Actualizar item de wishlist
    func updateWishlistItem(_ item: WishlistItem) async {
        isLoading = true
        errorMessage = nil
        do {
            try await userService.updateWishlistItem(item)
            await loadWishlist()
        } catch {
            handleError("Error al actualizar wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Computed Properties para UI

    /// Indica si se debe mostrar loading en tried perfumes
    var shouldShowTriedPerfumesLoading: Bool {
        return isLoadingTriedPerfumes || (triedPerfumes.isEmpty && !hasLoadedTriedPerfumes)
    }

    /// Indica si se debe mostrar loading en wishlist
    var shouldShowWishlistLoading: Bool {
        return isLoadingWishlist || (wishlistPerfumes.isEmpty && !hasLoadedWishlist)
    }

    // MARK: - Manual Loading State Control

    /// Marca manualmente el inicio de carga (para evitar EmptyState antes de cargar)
    func startLoadingIfNeeded() {
        if triedPerfumes.isEmpty && !hasLoadedTriedPerfumes {
            isLoadingTriedPerfumes = true
        }
        if wishlistPerfumes.isEmpty && !hasLoadedWishlist {
            isLoadingWishlist = true
        }
    }

    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
         print("🔴 UserViewModel Error: \(message)")
    }

    // MARK: - Retry Logic

    /// Permite reintentar la carga de datos después de un error o timeout
    func retryLoadData() {
        guard let userId = authViewModel.currentUser?.id else {
            print("⚠️ [UserViewModel] Cannot retry: No user")
            return
        }

        print("🔄 [UserViewModel] Retrying data load...")

        // Reset flag para permitir retry
        hasLoadedInitialData = false

        // Restablecer estados de loading
        Task { @MainActor in
            self.isLoading = true
            self.isLoadingTriedPerfumes = true
            self.isLoadingWishlist = true
        }

        // Reintentar carga
        Task {
            await loadInitialUserData(userId: userId)
        }
    }

    // TODO: Implementar data integrity check con nuevos modelos (perfumeId en lugar de perfumeKey)
}
