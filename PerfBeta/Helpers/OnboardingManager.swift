import Foundation

// MARK: - Onboarding Type

/// Tipo de onboarding a mostrar
enum OnboardingType {
    case firstTime    // Primera vez que abre la app
    case whatsNew     // Novedades de una nueva versión
}

// MARK: - Onboarding Manager

/// Gestiona el estado del onboarding y detecta cuándo debe mostrarse
class OnboardingManager {
    static let shared = OnboardingManager()

    private let lastOnboardingVersionKey = "lastOnboardingVersion"

    private init() {}

    /// Versión actual de la app
    var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Versiones que tienen onboarding (primera vez o novedades)
    private let versionsWithOnboarding = ["1.0"]  // ← Añadir "1.4.0", "2.0.0", etc.

    /// Determina si debe mostrar el onboarding
    /// - Returns: true si debe mostrar, false si no
    func shouldShowOnboarding() -> Bool {
        let lastVersion = UserDefaults.standard.string(forKey: lastOnboardingVersionKey)

        // Primera vez - nunca vio onboarding
        if lastVersion == nil {
            #if DEBUG
            print("🎯 [OnboardingManager] Primera vez - mostrar onboarding")
            #endif
            return true
        }

        // Nueva versión con novedades
        let shouldShow = versionsWithOnboarding.contains(currentAppVersion)
                         && lastVersion != currentAppVersion

        #if DEBUG
        print("🎯 [OnboardingManager] Check version - current: \(currentAppVersion), last: \(lastVersion ?? "nil"), shouldShow: \(shouldShow)")
        #endif

        return shouldShow
    }

    /// Obtiene el tipo de onboarding a mostrar
    func getType() -> OnboardingType {
        let lastVersion = UserDefaults.standard.string(forKey: lastOnboardingVersionKey)
        return lastVersion == nil ? .firstTime : .whatsNew
    }

    /// Marca el onboarding como completado para la versión actual
    func markCompleted() {
        UserDefaults.standard.set(currentAppVersion, forKey: lastOnboardingVersionKey)

        #if DEBUG
        print("✅ [OnboardingManager] Onboarding completado para versión: \(currentAppVersion)")
        #endif
    }

    /// Resetea el onboarding (útil para testing)
    func reset() {
        UserDefaults.standard.removeObject(forKey: lastOnboardingVersionKey)

        #if DEBUG
        print("🔄 [OnboardingManager] Onboarding reseteado")
        #endif
    }
}
