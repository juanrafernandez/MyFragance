import Foundation

// MARK: - Startup Strategy
/// Define los posibles estados de inicio de la app
/// Usado por AppStartupService para determinar qué datos cargar y cómo
enum StartupStrategy: Equatable {
    /// Primera instalación: Sin caché, requiere descarga completa
    /// UI: Mostrar loading screen con animación
    case freshInstall

    /// Caché parcial: Algunos datos disponibles, otros no
    /// UI: Mostrar MainTabView con skeletons en secciones sin datos
    case partialCache(available: CacheAvailability)

    /// Caché completa: Todos los datos esenciales disponibles
    /// UI: Mostrar MainTabView inmediatamente
    case fullCache

    /// Error durante la verificación de caché
    /// UI: Mostrar error con opción de reintentar
    case error(StartupError)

    var requiresLoadingScreen: Bool {
        switch self {
        case .freshInstall:
            return true
        case .partialCache, .fullCache, .error:
            return false
        }
    }

    var canShowMainTabImmediately: Bool {
        switch self {
        case .fullCache, .partialCache:
            return true
        case .freshInstall, .error:
            return false
        }
    }
}

// MARK: - Cache Availability
/// Detalle de qué cachés están disponibles
struct CacheAvailability: Equatable {
    let hasUserData: Bool
    let hasMetadataIndex: Bool
    let hasTriedPerfumes: Bool
    let hasWishlist: Bool
    let hasFamilies: Bool
    let hasBrands: Bool

    var isComplete: Bool {
        hasUserData && hasMetadataIndex
    }

    var isEmpty: Bool {
        !hasUserData && !hasMetadataIndex && !hasTriedPerfumes && !hasWishlist
    }

    static let none = CacheAvailability(
        hasUserData: false,
        hasMetadataIndex: false,
        hasTriedPerfumes: false,
        hasWishlist: false,
        hasFamilies: false,
        hasBrands: false
    )

    static let full = CacheAvailability(
        hasUserData: true,
        hasMetadataIndex: true,
        hasTriedPerfumes: true,
        hasWishlist: true,
        hasFamilies: true,
        hasBrands: true
    )
}

// MARK: - Startup Error
/// Errores específicos del proceso de inicio
enum StartupError: Error, Equatable {
    case noUserId
    case cacheCorrupted
    case networkUnavailable
    case firestoreError(String)
    case timeout
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .noUserId:
            return "No se encontró el ID de usuario"
        case .cacheCorrupted:
            return "Los datos en caché están corruptos"
        case .networkUnavailable:
            return "Sin conexión a internet"
        case .firestoreError(let message):
            return "Error de base de datos: \(message)"
        case .timeout:
            return "La carga tardó demasiado tiempo"
        case .unknown(let message):
            return message
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .timeout:
            return true
        case .noUserId, .cacheCorrupted, .firestoreError, .unknown:
            return false
        }
    }
}

// MARK: - Startup Progress
/// Progreso de la carga inicial para feedback de UI
struct StartupProgress {
    let phase: StartupPhase
    let progress: Double // 0.0 - 1.0
    let message: String

    enum StartupPhase {
        case detectingCache
        case loadingUserData
        case loadingMetadata
        case loadingLibrary
        case syncingBackground
        case complete
    }

    static let initial = StartupProgress(
        phase: .detectingCache,
        progress: 0.0,
        message: "Preparando..."
    )

    static let complete = StartupProgress(
        phase: .complete,
        progress: 1.0,
        message: "¡Listo!"
    )
}
