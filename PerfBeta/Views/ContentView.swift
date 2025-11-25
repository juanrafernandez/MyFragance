import SwiftUI

// MARK: - App Data Loading View

/// Vista de carga con progreso - Muestra feedback durante la carga inicial
struct AppDataLoadingView: View, Equatable {
    let progress: StartupProgress

    init(progress: StartupProgress = .initial) {
        self.progress = progress
    }

    var body: some View {
        ZStack {
            GradientView(preset: .champan)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animación de botella con partículas
                PerfumeFragranceAnimation()
                    .frame(width: 120, height: 120)

                Text(progress.message)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(Color("textoPrincipal"))
                    .animation(.easeInOut, value: progress.message)

                // Barra de progreso
                if progress.progress > 0 && progress.progress < 1 {
                    ProgressView(value: progress.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color("champan")))
                        .frame(width: 200)
                }
            }
        }
    }

    static func == (lhs: AppDataLoadingView, rhs: AppDataLoadingView) -> Bool {
        return lhs.progress.progress == rhs.progress.progress &&
               lhs.progress.message == rhs.progress.message
    }
}

// MARK: - App Loading State

/// Estados posibles de la aplicación durante el inicio
/// Centralizado y claro para debugging
enum AppLoadingState: Equatable {
    /// Verificando si hay sesión activa
    case checkingAuth

    /// No hay sesión activa - mostrar login
    case unauthenticated

    /// Mostrando onboarding (primera vez o nueva versión)
    case showingOnboarding(OnboardingType)

    /// Usuario autenticado - cargando datos necesarios
    case loadingData

    /// Datos cargados - app lista para usar
    case ready

    var debugDescription: String {
        switch self {
        case .checkingAuth: return "checkingAuth"
        case .unauthenticated: return "unauthenticated"
        case .showingOnboarding(let type): return "showingOnboarding(\(type))"
        case .loadingData: return "loadingData"
        case .ready: return "ready"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    // MARK: - Environment
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var testViewModel: TestViewModel

    // MARK: - Startup Service
    @StateObject private var startupService = AppStartupService.shared

    // MARK: - State
    @State private var appState: AppLoadingState = .checkingAuth
    @State private var startupProgress: StartupProgress = .initial
    @State private var hasInitiatedStartup = false

    // MARK: - Body
    var body: some View {
        ZStack {
            switch appState {
            case .checkingAuth:
                initialLoadingView

            case .unauthenticated:
                NavigationStack {
                    LoginView()
                }.tint(.black)

            case .showingOnboarding(let type):
                OnboardingView(
                    type: type,
                    onComplete: { onOnboardingComplete() }
                )
                .transition(.opacity)

            case .loadingData:
                AppDataLoadingView(progress: startupProgress)
                    .id("loadingView")

            case .ready:
                NavigationStack {
                    MainTabView()
                }.tint(.black)
            }
        }
        .onChange(of: authViewModel.isCheckingInitialAuth) { _, isChecking in
            handleAuthCheckChange(isChecking: isChecking)
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            handleAuthStateChange(wasAuthenticated: oldValue, isAuthenticated: newValue)
        }
        .onAppear {
            initializeAppState()
        }
    }

    // MARK: - Initial Loading View
    private var initialLoadingView: some View {
        ZStack {
            GradientLinearView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
        }
    }

    // MARK: - State Management

    /// Inicializa el estado de la app al aparecer
    private func initializeAppState() {
        #if DEBUG
        print("🚀 [ContentView] Initializing app state")
        print("   - isCheckingInitialAuth: \(authViewModel.isCheckingInitialAuth)")
        print("   - isAuthenticated: \(authViewModel.isAuthenticated)")
        #endif

        updateAppState()

        // Si ya está autenticado, verificar onboarding e iniciar carga
        if authViewModel.isAuthenticated && !authViewModel.isCheckingInitialAuth {
            checkOnboardingAndStartLoad()
        }
    }

    /// Maneja cambios en el estado de verificación de auth
    private func handleAuthCheckChange(isChecking: Bool) {
        #if DEBUG
        print("🔄 [ContentView] Auth check changed: \(isChecking)")
        #endif

        updateAppState()

        if !isChecking && authViewModel.isAuthenticated {
            checkOnboardingAndStartLoad()
        }
    }

    /// Maneja cambios en el estado de autenticación
    private func handleAuthStateChange(wasAuthenticated: Bool, isAuthenticated: Bool) {
        #if DEBUG
        print("🔄 [ContentView] Auth state changed: \(wasAuthenticated) → \(isAuthenticated)")
        #endif

        updateAppState()

        // Usuario acaba de hacer login
        if isAuthenticated && !wasAuthenticated {
            hasInitiatedStartup = false // Reset para permitir nueva carga
            checkOnboardingAndStartLoad()
        }

        // Usuario hizo logout
        if !isAuthenticated && wasAuthenticated {
            handleLogout()
        }
    }

    /// Actualiza el estado de la app basado en auth
    private func updateAppState() {
        // No cambiar si estamos en onboarding
        if case .showingOnboarding = appState { return }

        if authViewModel.isCheckingInitialAuth {
            appState = .checkingAuth
        } else if !authViewModel.isAuthenticated {
            appState = .unauthenticated
        }
        // Si está autenticado, el estado lo maneja initiateStartup()
    }

    /// Verifica onboarding y luego inicia la carga
    private func checkOnboardingAndStartLoad() {
        // Verificar onboarding primero
        if OnboardingManager.shared.shouldShowOnboarding() {
            let type = OnboardingManager.shared.getType()
            appState = .showingOnboarding(type)
            // Datos se cargan en background mientras el usuario ve onboarding
        }

        initiateStartup()
    }

    /// Cuando el usuario completa el onboarding
    private func onOnboardingComplete() {
        withAnimation(.easeOut(duration: 0.3)) {
            // Si startup terminó → ready, sino → loadingData
            if startupService.isLoading {
                appState = .loadingData
            } else {
                appState = .ready
            }
        }
    }

    /// Maneja el logout del usuario
    private func handleLogout() {
        #if DEBUG
        print("🚪 [ContentView] Handling logout")
        #endif

        hasInitiatedStartup = false
        startupProgress = .initial

        // Limpiar caché del usuario
        if let userId = authViewModel.currentUser?.id {
            Task {
                await startupService.clearUserCache(userId: userId)
            }
        }
    }

    // MARK: - Startup Flow

    /// Inicia el proceso de carga usando AppStartupService
    private func initiateStartup() {
        guard !hasInitiatedStartup else {
            #if DEBUG
            print("⚠️ [ContentView] Startup already initiated, skipping")
            #endif
            return
        }

        guard let userId = authViewModel.currentUser?.id else {
            #if DEBUG
            print("⚠️ [ContentView] No user ID found, cannot start")
            #endif
            return
        }

        hasInitiatedStartup = true

        #if DEBUG
        print("🚀 [ContentView] Initiating startup for user: \(userId)")
        #endif

        Task {
            // 1. Determinar estrategia
            let strategy = await startupService.determineStrategy(for: userId)

            #if DEBUG
            print("🚀 [ContentView] Strategy: \(strategy)")
            #endif

            // 2. Actualizar UI basado en estrategia
            await MainActor.run {
                if case .showingOnboarding = appState {
                    // Mantener onboarding, carga en background
                } else if strategy.canShowMainTabImmediately {
                    appState = .ready
                } else {
                    appState = .loadingData
                }
            }

            // 3. Ejecutar startup
            do {
                try await startupService.executeStartup(
                    userId: userId,
                    strategy: strategy
                ) { progress in
                    Task { @MainActor in
                        self.startupProgress = progress
                    }
                }

                // 4. Cargar datos de ViewModels (compatibilidad con sistema actual)
                await loadViewModelData(userId: userId)

                // 5. Marcar como listo
                await MainActor.run {
                    if case .showingOnboarding = appState {
                        // Mantener onboarding hasta que complete
                    } else {
                        appState = .ready
                    }
                }

                #if DEBUG
                print("✅ [ContentView] Startup complete - app ready")
                #endif

            } catch {
                #if DEBUG
                print("❌ [ContentView] Startup failed: \(error)")
                #endif

                await MainActor.run {
                    // En caso de error, intentar mostrar MainTabView de todas formas
                    // Los ViewModels manejarán estados de error individualmente
                    appState = .ready
                }
            }
        }
    }

    /// Carga datos en los ViewModels existentes
    /// Mantiene compatibilidad con el sistema actual mientras usamos AppStartupService
    private func loadViewModelData(userId: String) async {
        #if DEBUG
        print("📦 [ContentView] Loading ViewModel data...")
        #endif

        // Cargar datos del usuario
        await userViewModel.loadInitialUserData(
            userId: userId,
            perfumeViewModel: perfumeViewModel
        )

        // Cargar datos compartidos de la app
        await userViewModel.loadSharedAppData(
            perfumeViewModel: perfumeViewModel,
            brandViewModel: brandViewModel,
            familyViewModel: familiaOlfativaViewModel,
            testViewModel: testViewModel
        )

        #if DEBUG
        print("✅ [ContentView] ViewModel data loaded")
        #endif
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthViewModel(authService: DependencyContainer.shared.authService))
        .environmentObject(UserViewModel(
            userService: DependencyContainer.shared.userService,
            authViewModel: AuthViewModel(authService: DependencyContainer.shared.authService)
        ))
        .environmentObject(PerfumeViewModel())
        .environmentObject(BrandViewModel())
        .environmentObject(FamilyViewModel())
        .environmentObject(TestViewModel())
}
