import Foundation
import Combine

// MARK: - App Startup Service Protocol
/// Protocolo para el servicio de inicio de la app
/// Permite testing y diferentes implementaciones
protocol AppStartupServiceProtocol {
    /// Determina la estrategia de inicio basándose en el estado del caché
    func determineStrategy(for userId: String) async -> StartupStrategy

    /// Ejecuta la carga de datos según la estrategia
    func executeStartup(
        userId: String,
        strategy: StartupStrategy,
        onProgress: @escaping (StartupProgress) -> Void
    ) async throws

    /// Ejecuta sync en background (para usuarios con caché)
    func syncInBackground(userId: String) async

    /// Limpia el caché del usuario (logout o reset)
    func clearUserCache(userId: String) async
}

// MARK: - App Startup Service
/// Servicio centralizado que coordina todo el proceso de inicio de la app
/// Single Responsibility: Solo maneja la lógica de startup, no UI
@MainActor
final class AppStartupService: ObservableObject, AppStartupServiceProtocol {

    // MARK: - Singleton
    static let shared = AppStartupService()

    // MARK: - Published State
    @Published private(set) var currentStrategy: StartupStrategy?
    @Published private(set) var progress: StartupProgress = .initial
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: StartupError?

    // MARK: - Dependencies
    private let cacheManager: CacheManager
    private let metadataIndexManager: MetadataIndexManager

    // MARK: - Configuration
    private let backgroundSyncThresholdSeconds: TimeInterval = 300 // 5 minutos

    // MARK: - Cache Keys (Centralizados)
    private struct CacheKeys {
        static func user(_ userId: String) -> String { "user-\(userId)" }
        static func triedPerfumes(_ userId: String) -> String { "tried_perfumes-\(userId)" }
        static func wishlist(_ userId: String) -> String { "wishlist-\(userId)" }
        static let metadataIndex = "perfume_metadata_index"
        static let families = "families_cache"
        static let brands = "brands_cache"
    }

    // MARK: - Init
    private init(
        cacheManager: CacheManager = .shared,
        metadataIndexManager: MetadataIndexManager = .shared
    ) {
        self.cacheManager = cacheManager
        self.metadataIndexManager = metadataIndexManager
    }

    // MARK: - Determine Strategy

    /// Analiza el estado del caché y determina la estrategia óptima de inicio
    func determineStrategy(for userId: String) async -> StartupStrategy {
        #if DEBUG
        print("🚀 [AppStartupService] Determining strategy for user: \(userId)")
        #endif

        // Verificar cada tipo de caché
        let availability = await checkCacheAvailability(for: userId)

        #if DEBUG
        print("🚀 [AppStartupService] Cache availability:")
        print("   - User data: \(availability.hasUserData)")
        print("   - Metadata index: \(availability.hasMetadataIndex)")
        print("   - Tried perfumes: \(availability.hasTriedPerfumes)")
        print("   - Wishlist: \(availability.hasWishlist)")
        #endif

        // Determinar estrategia basándose en disponibilidad
        let strategy: StartupStrategy

        if availability.isEmpty {
            strategy = .freshInstall
        } else if availability.isComplete {
            strategy = .fullCache
        } else {
            strategy = .partialCache(available: availability)
        }

        #if DEBUG
        print("🚀 [AppStartupService] Strategy determined: \(strategy)")
        #endif

        await MainActor.run {
            self.currentStrategy = strategy
        }

        return strategy
    }

    // MARK: - Execute Startup

    /// Ejecuta la carga de datos según la estrategia determinada
    func executeStartup(
        userId: String,
        strategy: StartupStrategy,
        onProgress: @escaping (StartupProgress) -> Void
    ) async throws {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }

        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }

        switch strategy {
        case .freshInstall:
            try await executeFreshInstall(userId: userId, onProgress: onProgress)

        case .fullCache:
            try await executeFullCacheLoad(userId: userId, onProgress: onProgress)

        case .partialCache(let availability):
            try await executePartialCacheLoad(
                userId: userId,
                availability: availability,
                onProgress: onProgress
            )

        case .error(let startupError):
            await MainActor.run {
                self.error = startupError
            }
            throw startupError
        }

        onProgress(.complete)
    }

    // MARK: - Fresh Install Flow

    /// Primera instalación: Descarga todo desde Firestore
    private func executeFreshInstall(
        userId: String,
        onProgress: @escaping (StartupProgress) -> Void
    ) async throws {
        #if DEBUG
        print("🆕 [AppStartupService] Executing FRESH INSTALL flow")
        #endif

        // Fase 1: Cargar metadata index (crítico para HomeTab)
        onProgress(StartupProgress(
            phase: .loadingMetadata,
            progress: 0.1,
            message: "Descargando catálogo de perfumes..."
        ))

        do {
            _ = try await metadataIndexManager.getMetadataIndex()
        } catch {
            #if DEBUG
            print("❌ [AppStartupService] Failed to load metadata: \(error)")
            #endif
            throw StartupError.firestoreError("Error cargando catálogo: \(error.localizedDescription)")
        }

        onProgress(StartupProgress(
            phase: .loadingMetadata,
            progress: 0.4,
            message: "Catálogo descargado"
        ))

        // Fase 2: Marcar que el usuario tiene caché (para próximos inicios)
        await cacheManager.saveLastSyncTimestamp(Date(), for: CacheKeys.user(userId))

        onProgress(StartupProgress(
            phase: .loadingUserData,
            progress: 0.6,
            message: "Preparando tu perfil..."
        ))

        // Fase 3: Datos secundarios se cargarán en background después
        onProgress(StartupProgress(
            phase: .complete,
            progress: 1.0,
            message: "¡Listo!"
        ))

        #if DEBUG
        print("✅ [AppStartupService] Fresh install complete")
        #endif
    }

    // MARK: - Full Cache Flow

    /// Usuario existente con caché completo: Carga desde disco
    private func executeFullCacheLoad(
        userId: String,
        onProgress: @escaping (StartupProgress) -> Void
    ) async throws {
        #if DEBUG
        print("⚡ [AppStartupService] Executing FULL CACHE flow (instant)")
        #endif

        onProgress(StartupProgress(
            phase: .loadingMetadata,
            progress: 0.3,
            message: "Cargando datos..."
        ))

        // Cargar metadata desde caché (instantáneo)
        do {
            _ = try await metadataIndexManager.getMetadataIndex()
        } catch {
            #if DEBUG
            print("⚠️ [AppStartupService] Metadata cache miss, downloading...")
            #endif
            // Si falla el caché, descargar (raro pero posible)
        }

        onProgress(StartupProgress(
            phase: .complete,
            progress: 1.0,
            message: "¡Listo!"
        ))

        // Programar sync en background
        Task.detached { [weak self] in
            await self?.syncInBackground(userId: userId)
        }

        #if DEBUG
        print("✅ [AppStartupService] Full cache load complete")
        #endif
    }

    // MARK: - Partial Cache Flow

    /// Caché parcial: Cargar lo disponible y descargar lo faltante
    private func executePartialCacheLoad(
        userId: String,
        availability: CacheAvailability,
        onProgress: @escaping (StartupProgress) -> Void
    ) async throws {
        #if DEBUG
        print("🔄 [AppStartupService] Executing PARTIAL CACHE flow")
        print("   - Missing user data: \(!availability.hasUserData)")
        print("   - Missing metadata: \(!availability.hasMetadataIndex)")
        #endif

        var currentProgress: Double = 0.0

        // Cargar metadata (desde caché o Firestore)
        onProgress(StartupProgress(
            phase: .loadingMetadata,
            progress: currentProgress,
            message: availability.hasMetadataIndex ? "Cargando catálogo..." : "Descargando catálogo..."
        ))

        do {
            _ = try await metadataIndexManager.getMetadataIndex()
            currentProgress = 0.5
        } catch {
            #if DEBUG
            print("❌ [AppStartupService] Failed to load metadata: \(error)")
            #endif
        }

        // Si falta user data, marcar para que se cree
        if !availability.hasUserData {
            await cacheManager.saveLastSyncTimestamp(Date(), for: CacheKeys.user(userId))
        }

        onProgress(StartupProgress(
            phase: .complete,
            progress: 1.0,
            message: "¡Listo!"
        ))

        #if DEBUG
        print("✅ [AppStartupService] Partial cache load complete")
        #endif
    }

    // MARK: - Background Sync

    /// Sincroniza datos en background sin bloquear UI
    func syncInBackground(userId: String) async {
        // Verificar si es necesario sincronizar
        let shouldSync = await shouldPerformBackgroundSync(userId: userId)

        guard shouldSync else {
            #if DEBUG
            print("⏭️ [AppStartupService] Background sync skipped (recent sync exists)")
            #endif
            return
        }

        #if DEBUG
        print("🔄 [AppStartupService] Starting background sync for user: \(userId)")
        #endif

        // Sync metadata incremental
        do {
            try await metadataIndexManager.syncIncrementalChanges()
            #if DEBUG
            print("✅ [AppStartupService] Metadata sync complete")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ [AppStartupService] Metadata sync failed: \(error)")
            #endif
        }

        // Actualizar timestamp de sync
        await cacheManager.saveLastSyncTimestamp(Date(), for: CacheKeys.user(userId))
    }

    // MARK: - Clear Cache

    /// Limpia el caché del usuario (para logout)
    func clearUserCache(userId: String) async {
        #if DEBUG
        print("🗑️ [AppStartupService] Clearing cache for user: \(userId)")
        #endif

        await cacheManager.clearCache(for: CacheKeys.user(userId))
        await cacheManager.clearCache(for: CacheKeys.triedPerfumes(userId))
        await cacheManager.clearCache(for: CacheKeys.wishlist(userId))

        await MainActor.run {
            self.currentStrategy = nil
            self.progress = .initial
        }

        #if DEBUG
        print("✅ [AppStartupService] User cache cleared")
        #endif
    }

    // MARK: - Private Helpers

    /// Verifica qué cachés están disponibles
    private func checkCacheAvailability(for userId: String) async -> CacheAvailability {
        async let hasUser = cacheManager.getLastSyncTimestamp(for: CacheKeys.user(userId)) != nil
        async let hasMetadata = cacheManager.getLastSyncTimestamp(for: CacheKeys.metadataIndex) != nil
        async let hasTried = cacheManager.getLastSyncTimestamp(for: CacheKeys.triedPerfumes(userId)) != nil
        async let hasWishlist = cacheManager.getLastSyncTimestamp(for: CacheKeys.wishlist(userId)) != nil
        async let hasFamilies = cacheManager.getLastSyncTimestamp(for: CacheKeys.families) != nil
        async let hasBrands = cacheManager.getLastSyncTimestamp(for: CacheKeys.brands) != nil

        return await CacheAvailability(
            hasUserData: hasUser,
            hasMetadataIndex: hasMetadata,
            hasTriedPerfumes: hasTried,
            hasWishlist: hasWishlist,
            hasFamilies: hasFamilies,
            hasBrands: hasBrands
        )
    }

    /// Determina si es necesario hacer sync en background
    private func shouldPerformBackgroundSync(userId: String) async -> Bool {
        guard let lastSync = await cacheManager.getLastSyncTimestamp(for: CacheKeys.user(userId)) else {
            return true // Sin sync previo, sincronizar
        }

        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync > backgroundSyncThresholdSeconds
    }
}

// MARK: - Convenience Extension
extension AppStartupService {
    /// Método conveniente que determina estrategia y ejecuta en un solo paso
    func startApp(
        userId: String,
        onProgress: @escaping (StartupProgress) -> Void
    ) async throws -> StartupStrategy {
        let strategy = await determineStrategy(for: userId)
        try await executeStartup(userId: userId, strategy: strategy, onProgress: onProgress)
        return strategy
    }
}
