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

    /// Tracks if we've ever had an authenticated user (to detect real logouts vs initial state)
    private var hasEverBeenAuthenticated = false

    // Dependencies
    private let userService: UserServiceProtocol
    private let authViewModel: AuthViewModel
    private let perfumeService: PerfumeServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - First Launch Detection (Cache-based with Timestamps)

    /// Detecta si es la primera vez que se carga la app (sin caché esencial)
    /// Verifica timestamps de cada tipo de dato en lugar de un flag binario
    private var isFirstLaunch: Bool {
        get async {
            // Verificar si existe timestamp para datos del usuario
            let userCacheKey = "user-\(authViewModel.currentUser?.id ?? "unknown")"
            let hasUserCache = await CacheManager.shared.getLastSyncTimestamp(for: userCacheKey) != nil

            // Verificar si existe timestamp para metadata de perfumes
            let hasMetadataCache = await CacheManager.shared.getLastSyncTimestamp(for: "perfume_metadata_index") != nil

            #if DEBUG
            print("🔍 [UserViewModel] Cache status - User: \(hasUserCache), Metadata: \(hasMetadataCache)")
            #endif

            // Es primera carga si NO hay ningún cache esencial
            let isFirst = !hasUserCache && !hasMetadataCache

            #if DEBUG
            if isFirst {
                print("🆕 [UserViewModel] First launch detected (no cache)")
            } else {
                print("⚡ [UserViewModel] Cached launch detected (has cache)")
            }
            #endif

            return isFirst
        }
    }

    /// Marca que la carga esencial se completó guardando timestamps
    private func markEssentialDataLoaded(userId: String) async {
        let userCacheKey = "user-\(userId)"
        await CacheManager.shared.saveLastSyncTimestamp(Date(), for: userCacheKey)

        #if DEBUG
        print("✅ [UserViewModel] Essential data timestamps saved for user \(userId)")
        #endif
    }

    /// Reinicia cache (para testing o después de logout)
    func resetEssentialDataFlag() async {
        if let userId = authViewModel.currentUser?.id {
            let userCacheKey = "user-\(userId)"
            await CacheManager.shared.clearCache(for: userCacheKey)

            #if DEBUG
            print("🔄 [UserViewModel] User cache cleared for \(userId)")
            #endif
        }
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
        // Usar un valor conservador: true por defecto
        // Será actualizado a false en loadInitialUserData si hay cache
        self.isLoading = true

        #if DEBUG
        print("🔧 [UserViewModel] Initialized (isLoading = true, will check cache later)")
        #endif

        // Observer SOLO para logout (para limpiar datos)
        // ✅ FIX: Rastrea si alguna vez hubo un usuario autenticado
        // Solo reacciona a LOGOUT REAL (transición de autenticado → no autenticado)
        authViewModel.$currentUser
            .sink { [weak self] currentUser in
                guard let self = self else { return }

                if let _ = currentUser {
                    // Usuario autenticado - marcar flag
                    self.hasEverBeenAuthenticated = true
                } else {
                    // Usuario nil - solo limpiar si es un logout REAL
                    if self.hasEverBeenAuthenticated {
                        #if DEBUG
                        print("👤 [UserViewModel] User logged out, clearing data")
                        #endif
                        self.clearUserData()
                        self.hasEverBeenAuthenticated = false // Reset flag
                        Task { @MainActor in
                            self.isLoading = false
                            self.isLoadingTriedPerfumes = false
                            self.isLoadingWishlist = false
                        }
                    } else {
                        #if DEBUG
                        print("🔧 [UserViewModel] Initial state (no user yet), skipping clearUserData")
                        #endif
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Main Loading Entry Point

    /// Punto de entrada único para carga de datos
    /// Decide estrategia según si es primera vez o tiene caché
    /// - Parameters:
    ///   - userId: User ID
    ///   - perfumeViewModel: ViewModel de perfumes para pre-cargar perfumes de biblioteca
    func loadInitialUserData(userId: String, perfumeViewModel: PerfumeViewModel? = nil) async {
        guard !hasLoadedInitialData else {
            #if DEBUG
            print("⚠️ [UserViewModel] Already loading/loaded, skipping")
            #endif
            return
        }

        hasLoadedInitialData = true

        // Verificar si es primera carga (usa timestamps de cache)
        let isFirst = await isFirstLaunch

        if isFirst {
            // ═══════════════════════════════════════════════════
            // PRIMERA CARGA: Descargar esencial + secundario
            // ═══════════════════════════════════════════════════
            #if DEBUG
            print("🆕 [UserViewModel] FIRST LAUNCH - Downloading all essential data")
            #endif

            await loadEssentialData(userId: userId)

            // ✅ Pre-cargar perfumes de biblioteca (previene race condition)
            if let perfumeViewModel = perfumeViewModel {
                await preloadLibraryPerfumes(perfumeViewModel: perfumeViewModel)
            }

            // Secundario en background (no bloquea)
            Task.detached(priority: .background) { [weak self] in
                await self?.loadSecondaryData()
            }

        } else {
            // ═══════════════════════════════════════════════════
            // CACHE-FIRST: Carga instantánea desde caché
            // Actualizar isLoading a false para mostrar TabView inmediatamente
            // ═══════════════════════════════════════════════════
            #if DEBUG
            print("⚡ [UserViewModel] CACHE-FIRST - Loading from cache")
            #endif

            await MainActor.run {
                self.isLoading = false
            }

            await loadFromCache(userId: userId)

            // ✅ Pre-cargar perfumes de biblioteca (previene race condition)
            if let perfumeViewModel = perfumeViewModel {
                await preloadLibraryPerfumes(perfumeViewModel: perfumeViewModel)
            }

            // ✅ Background sync con throttling: solo si cache es viejo (>5 min)
            // Evita re-cacheo innecesario si acabamos de cargar datos frescos
            Task.detached(priority: .background) { [weak self] in
                // Esperar 2 segundos para dar tiempo a que la UI se establezca
                try? await Task.sleep(nanoseconds: 2_000_000_000)

                // Solo sync si los datos del cache son viejos
                let cacheAge = await self?.getCacheAge(userId: userId) ?? 999999
                if cacheAge > 300 { // > 5 minutos
                    #if DEBUG
                    print("🔄 [Background Sync] Cache age: \(Int(cacheAge))s, syncing...")
                    #endif
                    await self?.syncInBackground(userId: userId)
                } else {
                    #if DEBUG
                    print("✅ [Background Sync] Skipped (cache fresh: \(Int(cacheAge))s old)")
                    #endif
                }
            }
        }
    }

    // MARK: - Library Perfumes Pre-loading

    /// Pre-carga perfumes de biblioteca (wishlist + tried) para prevenir race condition
    /// donde las vistas intentan acceder a perfumes antes de que se carguen
    private func preloadLibraryPerfumes(perfumeViewModel: PerfumeViewModel) async {
        let wishlistKeys = wishlistPerfumes.map { $0.perfumeId }
        let triedKeys = triedPerfumes.map { $0.perfumeId }
        let allLibraryKeys = Array(Set(wishlistKeys + triedKeys))

        guard !allLibraryKeys.isEmpty else {
            #if DEBUG
            print("ℹ️ [UserViewModel] No library perfumes to pre-load")
            #endif
            return
        }

        #if DEBUG
        print("📥 [UserViewModel] Pre-loading \(allLibraryKeys.count) library perfumes...")
        #endif

        await perfumeViewModel.loadPerfumesByKeys(allLibraryKeys)

        #if DEBUG
        print("✅ [UserViewModel] Library perfumes loaded: \(perfumeViewModel.perfumeIndex.count) in index")
        #endif
    }

    // MARK: - Essential Data (Blocks LoadingScreen)

    /// Carga datos ESENCIALES para que todos los tabs funcionen
    /// LoadingScreen visible hasta que esto complete
    /// NOTA: isLoading ya está en true desde init() en primera carga
    private func loadEssentialData(userId: String) async {
        #if DEBUG
        print("🔄 [UserViewModel] Loading ESSENTIAL data (blocks UI)...")
        #endif

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

                #if DEBUG
                print("✅ [UserViewModel] User data loaded: \(tried.count) tried, \(wishlist.count) wishlist")
                #endif
            }

            // Marcar como completado guardando timestamp
            await markEssentialDataLoaded(userId: userId)

            await MainActor.run {
                self.isLoading = false
                #if DEBUG
                print("✅ [UserViewModel] ESSENTIAL data complete - UI unblocked")
                #endif
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
                    #if DEBUG
                    print("📴 [UserViewModel] Network error detected - offline mode")
                    #endif
                } else {
                    #if DEBUG
                    print("⚠️ [UserViewModel] Non-network error (not marking as offline): \(error.localizedDescription)")
                    #endif
                }

                self.isLoading = false
                #if DEBUG
                print("❌ [UserViewModel] ESSENTIAL data failed: \(error)")
                #endif
            }
        }
    }

    // MARK: - Cache-First Loading

    /// Carga datos de caché (instantáneo < 0.2s)
    private func loadFromCache(userId: String) async {
        #if DEBUG
        print("⚡ [UserViewModel] Loading from cache (instant)...")
        #endif

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

                #if DEBUG
                print("⚡ [UserViewModel] Cache loaded: \(tried.count) tried, \(wishlist.count) wishlist")
                #endif
            }

        } catch {
            // Si caché falla, cargar de Firestore
            #if DEBUG
            print("⚠️ [UserViewModel] Cache failed, loading from Firestore...")
            #endif
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
        #if DEBUG
        print("🔄 [Background Sync] Starting transparent sync...")
        #endif

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

                    #if DEBUG
                    print("✅ [Background Sync] Changes detected and applied")
                    #endif
                } else {
                    #if DEBUG
                    print("✅ [Background Sync] No changes")
                    #endif
                }
            }

        } catch {
            #if DEBUG
            print("⚠️ [Background Sync] Failed (non-critical): \(error.localizedDescription)")
            #endif
            // No hacer nada, mantener caché
        }
    }

    // MARK: - Shared App Data Loading

    /// Carga datos compartidos necesarios para todos los tabs
    /// Debe llamarse desde MainTabView en paralelo con la carga de datos del usuario
    /// - Parameters:
    ///   - perfumeViewModel: ViewModel de perfumes (para metadata)
    ///   - brandViewModel: ViewModel de marcas
    ///   - familyViewModel: ViewModel de familias olfativas
    ///   - testViewModel: ViewModel de test (para preguntas)
    func loadSharedAppData(
        perfumeViewModel: PerfumeViewModel,
        brandViewModel: BrandViewModel,
        familyViewModel: FamilyViewModel,
        testViewModel: TestViewModel
    ) async {
        #if DEBUG
        print("🚀 [UserViewModel] Loading shared app data for all tabs...")
        #endif

        // Cargar todo en paralelo para máxima velocidad
        await withTaskGroup(of: Void.self) { group in
            // Metadata (para HomeTab recomendaciones + ExploreTab)
            group.addTask(priority: .userInitiated) {
                do {
                    await perfumeViewModel.loadMetadataIndex()
                    #if DEBUG
                    print("✅ [UserViewModel] Shared: Metadata loaded")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ [UserViewModel] Shared: Metadata failed - \(error.localizedDescription)")
                    #endif
                }
            }

            // Brands (para ExploreTab - mostrar nombres de marcas)
            group.addTask(priority: .userInitiated) {
                do {
                    await brandViewModel.loadInitialData()
                    #if DEBUG
                    print("✅ [UserViewModel] Shared: Brands loaded")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ [UserViewModel] Shared: Brands failed - \(error.localizedDescription)")
                    #endif
                }
            }

            // Families (para ExploreTab filtros)
            group.addTask(priority: .userInitiated) {
                do {
                    await familyViewModel.loadInitialData()
                    #if DEBUG
                    print("✅ [UserViewModel] Shared: Families loaded")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ [UserViewModel] Shared: Families failed - \(error.localizedDescription)")
                    #endif
                }
            }

            // Questions (para TestTab - solo onboarding de perfil)
            group.addTask(priority: .userInitiated) {
                do {
                    await testViewModel.loadInitialData()
                    #if DEBUG
                    print("✅ [UserViewModel] Shared: Questions loaded")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ [UserViewModel] Shared: Questions failed - \(error.localizedDescription)")
                    #endif
                }
            }

            // Esperar a que todas las tareas completen
            await group.waitForAll()
        }

        // ✅ CRÍTICO: Garantizar que perfumeIndex esté inicializado para FragranceLibraryTabView
        // Esto previene que la vista de biblioteca quede sin datos cuando metadata ya está cargado
        await perfumeViewModel.ensureIndexInitialized()

        #if DEBUG
        print("✅ [UserViewModel] All shared app data loaded")
        #endif
    }

    // MARK: - Secondary Data (Background, non-blocking)

    /// Carga datos SECUNDARIOS que no bloquean la UI
    /// Funcionalidades avanzadas que se usan menos frecuentemente
    private func loadSecondaryData() async {
        #if DEBUG
        print("🔄 [Secondary Data] Loading in background...")
        #endif

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

        #if DEBUG
        print("✅ [Secondary Data] Background loading complete")
        #endif
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
            Task {
                await resetEssentialDataFlag()
            }
            #if DEBUG
            print("🧹 [UserViewModel] User data cleared, flags reset, FIRST LAUNCH RESET")
            #endif
        } else {
            #if DEBUG
            print("🧹 [UserViewModel] User data cleared, flags reset")
            #endif
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
            #if DEBUG
            print("✅ [UserViewModel] Cargados \(triedPerfumes.count) perfumes probados")
            #endif
        } catch {
            // ❌ NO BORRAR DATOS - Mantener caché
            #if DEBUG
            print("⚠️ [UserViewModel] Error cargando tried perfumes (keeping cache): \(error.localizedDescription)")
            #endif

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
            #if DEBUG
            print("Perfume eliminado exitosamente.")
            #endif
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
            #if DEBUG
            print("✅ [UserViewModel] Cargados \(wishlistPerfumes.count) items en wishlist")
            #endif
        } catch {
            // ❌ NO BORRAR DATOS - Mantener caché
            #if DEBUG
            print("⚠️ [UserViewModel] Error cargando wishlist (keeping cache): \(error.localizedDescription)")
            #endif

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
         #if DEBUG
         print("🔴 UserViewModel Error: \(message)")
         #endif
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
            #if DEBUG
            print("⚠️ [UserViewModel] Cannot retry: No user")
            #endif
            return
        }

        #if DEBUG
        print("🔄 [UserViewModel] Retrying data load...")
        #endif

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
