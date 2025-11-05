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
    @Published var isLoading: Bool
    // ✅ FIX: Empezar en false, solo true cuando realmente está cargando
    // Evita mostrar "Cargando..." cuando los datos ya están en caché
    @Published var isLoadingTriedPerfumes: Bool = false
    @Published var isLoadingWishlist: Bool = false
    @Published var errorMessage: IdentifiableString?

    // ✅ OFFLINE-FIRST: Background sync states (non-blocking)
    @Published var isSyncingUser = false
    @Published var isSyncingTriedPerfumes = false
    @Published var isSyncingWishlist = false
    @Published var isOffline = false

    // MARK: - Private Properties

    /// Prevents duplicate loading calls (reset on logout)
    @Published internal(set) var hasLoadedTriedPerfumes = false
    @Published internal(set) var hasLoadedWishlist = false
    private var hasLoadedInitialData = false

    // Dependencies
    private let userService: UserServiceProtocol
    private let authViewModel: AuthViewModel
    private let perfumeService: PerfumeServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - First Launch Detection

    /// Detecta si es la primera vez que se carga la app (sin caché esencial)
    private var isFirstLaunch: Bool {
        // Si UserDefaults dice que nunca se completó carga esencial
        !UserDefaults.standard.bool(forKey: "hasCompletedEssentialDownload")
    }

    /// Marca que la carga esencial se completó
    private func markEssentialDataLoaded() {
        UserDefaults.standard.set(true, forKey: "hasCompletedEssentialDownload")
        print("✅ [UserViewModel] Essential data marked as complete")
    }

    /// Reinicia flag (para testing o después de logout)
    func resetEssentialDataFlag() {
        UserDefaults.standard.set(false, forKey: "hasCompletedEssentialDownload")
        print("🔄 [UserViewModel] Essential data flag reset")
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

        // ✅ Inicializar isLoading basado en si hay caché
        // Si NO hay caché (primera carga) → true (mostrar LoadingScreen inmediatamente)
        // Si hay caché (segunda+ carga) → false (mostrar TabView con datos instantáneamente)
        let hasCache = UserDefaults.standard.bool(forKey: "hasCompletedEssentialDownload")
        self.isLoading = !hasCache

        if hasCache {
            print("🔧 [UserViewModel] Initialized with cache (isLoading = false)")
        } else {
            print("🔧 [UserViewModel] Initialized without cache (isLoading = true, will show LoadingScreen)")
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

    // MARK: - Main Loading Entry Point

    /// Punto de entrada único para carga de datos
    /// Decide estrategia según si es primera vez o tiene caché
    func loadInitialUserData(userId: String) async {
        guard !hasLoadedInitialData else {
            print("⚠️ [UserViewModel] Already loading/loaded, skipping")
            return
        }

        hasLoadedInitialData = true

        if isFirstLaunch {
            // ═══════════════════════════════════════════════════
            // PRIMERA CARGA: Descargar esencial + secundario
            // ═══════════════════════════════════════════════════
            print("🆕 [UserViewModel] FIRST LAUNCH - Downloading all essential data")

            await loadEssentialData(userId: userId)

            // Secundario en background (no bloquea)
            Task.detached(priority: .background) { [weak self] in
                await self?.loadSecondaryData()
            }

        } else {
            // ═══════════════════════════════════════════════════
            // CACHE-FIRST: Carga instantánea desde caché
            // isLoading ya está en false (desde init) → TabView visible inmediatamente
            // ═══════════════════════════════════════════════════
            print("⚡ [UserViewModel] CACHE-FIRST - Loading from cache (isLoading already false)")

            await loadFromCache(userId: userId)

            // ✅ Background sync con throttling: solo si cache es viejo (>5 min)
            // Evita re-cacheo innecesario si acabamos de cargar datos frescos
            Task.detached(priority: .background) { [weak self] in
                // Esperar 2 segundos para dar tiempo a que la UI se establezca
                try? await Task.sleep(nanoseconds: 2_000_000_000)

                // Solo sync si los datos del cache son viejos
                let cacheAge = await self?.getCacheAge(userId: userId) ?? 999999
                if cacheAge > 300 { // > 5 minutos
                    print("🔄 [Background Sync] Cache age: \(Int(cacheAge))s, syncing...")
                    await self?.syncInBackground(userId: userId)
                } else {
                    print("✅ [Background Sync] Skipped (cache fresh: \(Int(cacheAge))s old)")
                }
            }
        }
    }

    // MARK: - Essential Data (Blocks LoadingScreen)

    /// Carga datos ESENCIALES para que todos los tabs funcionen
    /// LoadingScreen visible hasta que esto complete
    /// NOTA: isLoading ya está en true desde init() en primera carga
    private func loadEssentialData(userId: String) async {
        print("🔄 [UserViewModel] Loading ESSENTIAL data (blocks UI)...")

        // Asegurar que isLoading = true (puede ya estarlo desde init)
        await MainActor.run {
            self.isLoading = true
        }

        do {
            // ═══════════════════════════════════════════════════
            // Descargar TODO en PARALELO con async let
            // ═══════════════════════════════════════════════════

            async let userData = userService.fetchUser(by: userId)
            async let triedData = userService.fetchTriedPerfumes(for: userId)
            async let wishlistData = userService.fetchWishlist(for: userId)

            // NOTA: Estos se cargan en sus propios ViewModels pero desde aquí
            // les damos la señal de que descarguen (no esperan lazy loading)

            // Esperar a que TODO complete
            let (user, tried, wishlist) = try await (
                userData,
                triedData,
                wishlistData
            )

            await MainActor.run {
                self.user = user
                self.triedPerfumes = tried
                self.wishlistPerfumes = wishlist

                // ✅ FIX: Actualizar flags de loading
                self.isLoadingTriedPerfumes = false
                self.isLoadingWishlist = false
                self.hasLoadedTriedPerfumes = true
                self.hasLoadedWishlist = true

                print("✅ [UserViewModel] User data loaded: \(tried.count) tried, \(wishlist.count) wishlist")
            }

            // Marcar como completado
            markEssentialDataLoaded()

            await MainActor.run {
                self.isLoading = false
                print("✅ [UserViewModel] ESSENTIAL data complete - UI unblocked")
            }

        } catch {
            await MainActor.run {
                self.errorMessage = IdentifiableString(value: "Error loading essential data: \(error.localizedDescription)")

                // ✅ FIX: Solo marcar offline si ES un error de red
                let errorString = error.localizedDescription.lowercased()
                if errorString.contains("offline") ||
                   errorString.contains("internet") ||
                   errorString.contains("network") ||
                   errorString.contains("connection") {
                    self.isOffline = true
                    print("📴 [UserViewModel] Network error detected - offline mode")
                } else {
                    print("⚠️ [UserViewModel] Non-network error (not marking as offline): \(error.localizedDescription)")
                }

                self.isLoading = false
                print("❌ [UserViewModel] ESSENTIAL data failed: \(error)")
            }
        }
    }

    // MARK: - Cache-First Loading

    /// Carga datos de caché (instantáneo < 0.2s)
    private func loadFromCache(userId: String) async {
        print("⚡ [UserViewModel] Loading from cache (instant)...")

        // Ya NO necesitamos esto (se hace en loadInitialUserData)
        // isLoading = false se setea SÍNCRONAMENTE antes de llamar a este método

        do {
            // Cargar de caché en paralelo
            async let userData = userService.fetchUser(by: userId)
            async let triedData = userService.fetchTriedPerfumes(for: userId)
            async let wishlistData = userService.fetchWishlist(for: userId)

            let (user, tried, wishlist) = try await (
                userData,
                triedData,
                wishlistData
            )

            await MainActor.run {
                self.user = user
                self.triedPerfumes = tried
                self.wishlistPerfumes = wishlist

                // ✅ FIX: Actualizar flags de loading después de cargar desde caché
                self.isLoadingTriedPerfumes = false
                self.isLoadingWishlist = false
                self.hasLoadedTriedPerfumes = true
                self.hasLoadedWishlist = true

                print("⚡ [UserViewModel] Cache loaded: \(tried.count) tried, \(wishlist.count) wishlist")
            }

        } catch {
            // Si caché falla, cargar de Firestore
            print("⚠️ [UserViewModel] Cache failed, loading from Firestore...")
            await loadEssentialData(userId: userId)
        }
    }

    // MARK: - Background Sync

    /// Obtiene la edad del cache en segundos
    private func getCacheAge(userId: String) async -> TimeInterval {
        let cacheKey = "user-\(userId)"
        if let timestamp = await CacheManager.shared.getLastSyncTimestamp(for: cacheKey) {
            return Date().timeIntervalSince(timestamp)
        }
        return 999999 // Cache muy viejo o no existe
    }

    /// Sync en background: verifica si hay cambios y actualiza
    private func syncInBackground(userId: String) async {
        print("🔄 [Background Sync] Starting transparent sync...")

        do {
            // Fetch desde Firestore (forzar download, no caché)
            async let userData = userService.fetchUser(by: userId)
            async let triedData = userService.fetchTriedPerfumes(for: userId)
            async let wishlistData = userService.fetchWishlist(for: userId)

            let (user, tried, wishlist) = try await (
                userData,
                triedData,
                wishlistData
            )

            // Actualizar si hay cambios
            await MainActor.run {
                let hasChanges =
                    self.triedPerfumes.count != tried.count ||
                    self.wishlistPerfumes.count != wishlist.count

                if hasChanges {
                    self.user = user
                    self.triedPerfumes = tried
                    self.wishlistPerfumes = wishlist

                    print("✅ [Background Sync] Changes detected and applied")
                } else {
                    print("✅ [Background Sync] No changes")
                }
            }

        } catch {
            print("⚠️ [Background Sync] Failed (non-critical): \(error.localizedDescription)")
            // No hacer nada, mantener caché
        }
    }

    // MARK: - Secondary Data (Background, non-blocking)

    /// Carga datos SECUNDARIOS que no bloquean la UI
    /// Funcionalidades avanzadas que se usan menos frecuentemente
    private func loadSecondaryData() async {
        print("🔄 [Secondary Data] Loading in background...")

        // Notes (para búsquedas avanzadas futuras)
        // NOTA: Este método es para datos secundarios, actualmente no hay
        // pero dejamos la estructura para futuras expansiones

        // Questions adicionales (gift finder, etc.) - FUTURO
        // do {
        //     try await questionService.fetchAdditionalQuestions()
        //     print("✅ [Secondary] Additional questions loaded")
        // } catch {
        //     print("⚠️ [Secondary] Questions failed (non-critical)")
        // }

        print("✅ [Secondary Data] Background loading complete")
    }

    // MARK: - Cleanup

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

        // OPCIONAL: Resetear flag de primera carga
        // (Si quieres forzar re-descarga después de logout)
        if resetFirstLaunch {
            resetEssentialDataFlag()
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
        // ✅ FIX: NO activar isLoading para operaciones individuales
        // isLoading solo se usa para carga inicial de datos del usuario
        // Esto evita mostrar el LoadingScreen completo en MainTabView
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
    // MARK: - Sorting Helpers

    /// Ordena perfumes probados según criterio:
    /// 1. Primero los que tienen rating > 0 (de mayor a menor rating)
    /// 2. Luego los que tienen rating = 0 (por orden alfabético de nombre)
    ///
    /// - Parameters:
    ///   - perfumes: Array de TriedPerfume a ordenar
    ///   - getPerfumeName: Closure que convierte perfumeId en nombre del perfume
    /// - Returns: Array ordenado
    func sortTriedPerfumes(_ perfumes: [TriedPerfume], getPerfumeName: (String) -> String?) -> [TriedPerfume] {
        return perfumes.sorted { lhs, rhs in
            let lhsRating = lhs.rating
            let rhsRating = rhs.rating

            // Ambos tienen rating > 0: ordenar por rating descendente
            if lhsRating > 0 && rhsRating > 0 {
                return lhsRating > rhsRating
            }

            // Solo lhs tiene rating > 0: va primero
            if lhsRating > 0 && rhsRating == 0 {
                return true
            }

            // Solo rhs tiene rating > 0: va primero
            if lhsRating == 0 && rhsRating > 0 {
                return false
            }

            // Ambos tienen rating = 0: ordenar alfabéticamente por nombre
            let lhsName = getPerfumeName(lhs.perfumeId) ?? ""
            let rhsName = getPerfumeName(rhs.perfumeId) ?? ""
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        }
    }

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
