import SwiftUI
import Combine

// MARK: - Launch Phase
/// Fases del flujo de inicio de la app
enum LaunchPhase: Equatable {
    /// Splash animado en pantalla
    case splash

    /// Onboarding (primera vez o novedades)
    case onboarding(OnboardingType)

    /// Pantalla de carga de datos (solo si splash ya terminó y datos no están listos)
    case loading

    /// App lista para usar
    case ready

    var debugDescription: String {
        switch self {
        case .splash: return "splash"
        case .onboarding(let type): return "onboarding(\(type))"
        case .loading: return "loading"
        case .ready: return "ready"
        }
    }
}

// MARK: - App Launch Coordinator
/// Coordina el flujo de inicio: Splash → Onboarding? → Loading? → Ready
/// Gestiona la carga de datos en paralelo con el splash
@MainActor
class AppLaunchCoordinator: ObservableObject {
    // MARK: - Published State
    @Published private(set) var currentPhase: LaunchPhase = .splash
    @Published private(set) var isDataLoaded = false
    @Published private(set) var loadingProgress: StartupProgress = .initial

    // MARK: - Private State
    private var splashAnimationComplete = false
    private var onboardingRequired: OnboardingType?
    private var hasStartedDataLoad = false

    // MARK: - Dependencies
    private let onboardingManager = OnboardingManager.shared

    // MARK: - Singleton (para acceso global)
    static let shared = AppLaunchCoordinator()

    private init() {
        checkOnboardingRequirement()
    }

    // MARK: - Public Methods

    /// Llamar cuando el splash completa su animación
    func splashAnimationDidComplete() {
        #if DEBUG
        print("🎬 [LaunchCoordinator] Splash animation complete")
        #endif

        splashAnimationComplete = true
        evaluateNextPhase()
    }

    /// Llamar cuando la carga de datos inicial completa
    func dataLoadDidComplete() {
        #if DEBUG
        print("📦 [LaunchCoordinator] Data load complete")
        #endif

        isDataLoaded = true
        evaluateNextPhase()
    }

    /// Actualiza el progreso de carga
    func updateLoadingProgress(_ progress: StartupProgress) {
        loadingProgress = progress
    }

    /// Llamar cuando el usuario completa el onboarding
    func onboardingDidComplete() {
        #if DEBUG
        print("✅ [LaunchCoordinator] Onboarding complete")
        #endif

        onboardingManager.markCompleted()
        onboardingRequired = nil
        evaluateNextPhase()
    }

    /// Forzar mostrar onboarding (ej: desde Settings)
    func showOnboarding(type: OnboardingType = .whatsNew) {
        #if DEBUG
        print("📖 [LaunchCoordinator] Showing onboarding (forced): \(type)")
        #endif

        currentPhase = .onboarding(type)
    }

    /// Resetear el estado (útil para testing o logout)
    func reset() {
        #if DEBUG
        print("🔄 [LaunchCoordinator] Resetting state")
        #endif

        splashAnimationComplete = false
        isDataLoaded = false
        hasStartedDataLoad = false
        loadingProgress = .initial
        checkOnboardingRequirement()
        currentPhase = .splash
    }

    // MARK: - Private Methods

    /// Verifica si se necesita mostrar onboarding
    private func checkOnboardingRequirement() {
        if onboardingManager.shouldShowOnboarding() {
            onboardingRequired = onboardingManager.getType()
            #if DEBUG
            print("📋 [LaunchCoordinator] Onboarding required: \(onboardingRequired!)")
            #endif
        } else {
            onboardingRequired = nil
            #if DEBUG
            print("📋 [LaunchCoordinator] No onboarding required")
            #endif
        }
    }

    /// Evalúa y transiciona a la siguiente fase según el estado actual
    private func evaluateNextPhase() {
        #if DEBUG
        print("🔄 [LaunchCoordinator] Evaluating next phase...")
        print("   - splashComplete: \(splashAnimationComplete)")
        print("   - dataLoaded: \(isDataLoaded)")
        print("   - onboardingRequired: \(onboardingRequired?.debugDescription ?? "nil")")
        print("   - currentPhase: \(currentPhase.debugDescription)")
        #endif

        // Flujo de decisión:
        // 1. Si splash no ha terminado → quedarse en splash
        // 2. Si splash terminó y hay onboarding → mostrar onboarding
        // 3. Si splash terminó, no hay onboarding, pero datos no están listos → loading
        // 4. Si todo listo → ready

        guard splashAnimationComplete else {
            // Splash todavía en progreso
            return
        }

        // Splash completó, ¿necesitamos onboarding?
        if let type = onboardingRequired {
            transition(to: .onboarding(type))
            return
        }

        // No onboarding, ¿datos listos?
        if isDataLoaded {
            transition(to: .ready)
        } else {
            transition(to: .loading)
        }
    }

    /// Transiciona a una nueva fase
    private func transition(to newPhase: LaunchPhase) {
        guard newPhase != currentPhase else { return }

        #if DEBUG
        print("➡️ [LaunchCoordinator] Transitioning: \(currentPhase.debugDescription) → \(newPhase.debugDescription)")
        #endif

        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhase = newPhase
        }
    }
}

// MARK: - OnboardingType Extension
extension OnboardingType: CustomStringConvertible {
    var description: String {
        switch self {
        case .firstTime: return "firstTime"
        case .whatsNew: return "whatsNew"
        }
    }

    var debugDescription: String { description }
}
