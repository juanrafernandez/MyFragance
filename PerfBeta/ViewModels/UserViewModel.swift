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

    // MARK: - First Launch Detection (PASO 1)

    /// Detecta si es la primera vez que se carga data (sin caché)
    private var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: "hasLoadedDataBefore")
    }

    /// Marca que ya se ha cargado data al menos una vez
    private func markAsLoaded() {
        UserDefaults.standard.set(true, forKey: "hasLoadedDataBefore")
        print("✅ [UserViewModel] Marked as loaded (hasLoadedDataBefore = true)")
    }

    // MARK: - Initialization (PASO 2)
    /// NO auto-carga datos - MainTabView.onAppear inicia la carga
    /// Solo observa logout para limpiar datos
    init(
        userService: UserServiceProtocol,
        authViewModel: AuthViewModel,
        perfumeService: PerfumeServiceProtocol = DependencyContainer.shared.perfumeService
    ) {
        self.userService = userService
        self.authViewModel = authViewModel
        self.perfumeService = perfumeService

        // ✅ PASO 2: NO auto-cargar datos aquí
        // La carga la iniciará MainTabView.onAppear
        if authViewModel.currentUser == nil {
            print("👤 [UserViewModel] No user at init, disabling loading states")
            // No hay usuario - deshabilitar loading inmediatamente
            Task { @MainActor in
                self.isLoading = false
                self.isLoadingTriedPerfumes = false
                self.isLoadingWishlist = false
            }
        } else {
            print("👤 [UserViewModel] User detected at init, waiting for MainTabView to start loading")
        }

        // Observer SOLO para logout (para limpiar datos)
        authViewModel.$currentUser
            .sink { [weak self] currentUser in
                guard let self = self else { return }

                // Solo actuar en logout (usuario pasa a nil)
                if currentUser == nil {
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

    // MARK: - Data Loading (PASO 3)

    /// Carga inicial de datos del usuario con estrategia inteligente
    /// - Primera carga (sin caché): LoadingScreen visible → descarga TODO → marca como cargado
    /// - Cargas posteriores (con caché): Caché instantáneo → background sync transparente
    /// Llamado por MainTabView.onAppear cuando el usuario está autenticado
    func loadInitialUserData(userId: String) async {
        // Prevent duplicate loads
        guard !hasLoadedInitialData else {
            print("⚠️ [UserViewModel] Already loading/loaded, skipping duplicate call")
            return
        }

        // Mark as started IMMEDIATELY (before Task)
        hasLoadedInitialData = true

        errorMessage = nil
        isOffline = false

        // ✅ PASO 3: Estrategia inteligente basada en primera carga
        if isFirstLaunch {
            print("🆕 [UserViewModel] FIRST LAUNCH - Loading all data from Firestore...")
            await loadAllDataSequentially(userId: userId)
        } else {
            print("🔄 [UserViewModel] SUBSEQUENT LAUNCH - Cache-first loading...")
            await loadDataCacheFirst(userId: userId)
        }
    }

    // MARK: - Loading Strategies (PASO 4)

    /// Estrategia 1: Primera carga (sin caché)
    /// Descarga TODO desde Firestore secuencialmente, mantiene LoadingScreen visible
    private func loadAllDataSequentially(userId: String) async {
        let startTime = Date()
        print("⏳ [Strategy 1] Downloading all data from Firestore (no cache)...")

        do {
            // Download all data in parallel from Firestore
            async let userTask = userService.fetchUser(by: userId)
            async let wishlistTask = userService.fetchWishlist(for: userId)
            async let triedTask = userService.fetchTriedPerfumes(for: userId)

            let (fetchedUser, fetchedWishlist, fetchedTried) = try await (
                userTask,
                wishlistTask,
                triedTask
            )

            // Update UI after ALL data is downloaded
            let duration = Date().timeIntervalSince(startTime)
            self.user = fetchedUser
            self.wishlistPerfumes = fetchedWishlist
            self.triedPerfumes = fetchedTried
            self.isLoading = false
            self.isLoadingTriedPerfumes = false
            self.isLoadingWishlist = false

            // ✅ Mark as loaded for future launches
            markAsLoaded()

            print("✅ [Strategy 1] First load completed in \(String(format: "%.3f", duration))s: \(fetchedTried.count) tried, \(fetchedWishlist.count) wishlist")

        } catch {
            // Handle error - stop loading screen
            let duration = Date().timeIntervalSince(startTime)
            self.isLoading = false
            self.isLoadingTriedPerfumes = false
            self.isLoadingWishlist = false

            print("❌ [Strategy 1] First load failed in \(String(format: "%.3f", duration))s: \(error.localizedDescription)")

            // Detect network errors
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("offline") || errorString.contains("internet") || errorString.contains("network") {
                self.isOffline = true
                print("📴 [Strategy 1] Offline mode")
            } else {
                handleError("Error al cargar datos: \(error.localizedDescription)")
            }
        }
    }

    /// Estrategia 2: Cargas posteriores (con caché)
    /// Carga desde caché instantáneamente → background sync transparente
    private func loadDataCacheFirst(userId: String) async {
        let startTime = Date()
        print("⚡ [Strategy 2] Loading from cache (instant)...")

        do {
            // Load from cache in parallel (instant if cached)
            async let userTask = userService.fetchUser(by: userId)
            async let wishlistTask = userService.fetchWishlist(for: userId)
            async let triedTask = userService.fetchTriedPerfumes(for: userId)

            let (fetchedUser, fetchedWishlist, fetchedTried) = try await (
                userTask,
                wishlistTask,
                triedTask
            )

            // ⚡ Update UI IMMEDIATELY (instant from cache)
            let duration = Date().timeIntervalSince(startTime)
            self.user = fetchedUser
            self.wishlistPerfumes = fetchedWishlist
            self.triedPerfumes = fetchedTried
            self.isLoading = false  // ← Hide LoadingScreen instantly
            self.isLoadingTriedPerfumes = false
            self.isLoadingWishlist = false

            print("✅ [Strategy 2] Cache loaded in \(String(format: "%.3f", duration))s: \(fetchedTried.count) tried, \(fetchedWishlist.count) wishlist")

            // 🔄 Background sync (non-blocking)
            Task.detached(priority: .background) { [weak self] in
                await self?.backgroundSync(userId: userId)
            }

        } catch {
            // Cache load failed - stop loading
            let duration = Date().timeIntervalSince(startTime)
            self.isLoading = false
            self.isLoadingTriedPerfumes = false
            self.isLoadingWishlist = false

            print("⚠️ [Strategy 2] Cache load failed in \(String(format: "%.3f", duration))s (keeping data): \(error.localizedDescription)")

            // Detect offline
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("offline") || errorString.contains("internet") || errorString.contains("network") {
                self.isOffline = true
                print("📴 [Strategy 2] Offline mode")
            } else {
                handleError("Error al cargar datos: \(error.localizedDescription)")
            }
        }
    }

    /// Background sync - actualiza datos en segundo plano de forma transparente
    private func backgroundSync(userId: String) async {
        print("🔄 [Background Sync] Starting transparent sync...")

        // Update sync indicators (non-blocking UI)
        await MainActor.run {
            self.isSyncingUser = true
            self.isSyncingTriedPerfumes = true
            self.isSyncingWishlist = true
        }

        defer {
            Task { @MainActor in
                self.isSyncingUser = false
                self.isSyncingTriedPerfumes = false
                self.isSyncingWishlist = false
            }
        }

        // Background sync happens in UserService (cache-first architecture)
        // UserService already handles background sync with Task.detached
        // No need to re-fetch here - just log
        print("✅ [Background Sync] Sync completed (handled by UserService)")
    }

    // MARK: - Cleanup (PASO 6)

    /// Limpiar datos del usuario (logout o error crítico)
    /// - Parameters:
    ///   - keepError: Mantener mensaje de error visible
    ///   - resetFirstLaunch: Resetear flag de primera carga (forzar Strategy 1 en próximo login)
    private func clearUserData(keepError: Bool = false, resetFirstLaunch: Bool = false) {
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

        // ✅ PASO 6: Opcionalmente resetear primera carga
        if resetFirstLaunch {
            UserDefaults.standard.set(false, forKey: "hasLoadedDataBefore")
            print("🧹 [UserViewModel] User data cleared, flags reset, FIRST LAUNCH RESET")
        } else {
            print("🧹 [UserViewModel] User data cleared, flags reset")
        }
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
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Usuario no autenticado.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.updateTriedPerfume(userId: userId, triedPerfume)
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
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Usuario no autenticado.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.updateWishlistItem(userId: userId, item)
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
