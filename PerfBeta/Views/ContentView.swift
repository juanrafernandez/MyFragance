import SwiftUI

// MARK: - App Data Loading View

/// Vista estática de carga - NO se recrea en cada render del ContentView
/// Esto evita que la animación se resetee cada vez que un @EnvironmentObject publica cambios
struct AppDataLoadingView: View, Equatable {
    var body: some View {
        ZStack {
            GradientView(preset: .champan)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animación de botella con partículas
                PerfumeFragranceAnimation()
                    .frame(width: 120, height: 120)

                Text("Preparando tu experiencia...")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(Color("textoPrincipal"))

                Text("Cargando tus perfumes y preferencias")
                    .font(.caption)
                    .foregroundColor(Color("textoSecundario"))
            }
        }
    }

    // ✅ Equatable: Como la vista es estática (sin @State), siempre es igual
    static func == (lhs: AppDataLoadingView, rhs: AppDataLoadingView) -> Bool {
        return true // Siempre igual, no re-renderizar
    }
}

// MARK: - App State

/// Estados posibles de la aplicación durante el inicio
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
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var testViewModel: TestViewModel

    @State private var appState: AppLoadingState = .checkingAuth
    @State private var hasLoadedData = false // ✅ Flag para evitar cargas duplicadas
    @State private var isDataReady = false // ✅ Flag para saber si la carga completa terminó

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
                // ✅ Onboarding pantalla completa (carga de datos en background)
                OnboardingView(
                    type: type,
                    onComplete: {
                        onOnboardingComplete()
                    }
                )
                .transition(AnyTransition.opacity)

            case .loadingData:
                AppDataLoadingView()
                    .id("loadingView") // ✅ ID estable para evitar recreación

            case .ready:
                NavigationStack {
                    MainTabView()
                }.tint(.black)
            }
        }
        .onChange(of: authViewModel.isCheckingInitialAuth) { _, isChecking in
            updateAppState()

            // Cuando termina el check inicial y el usuario está autenticado, cargar datos
            if !isChecking && authViewModel.isAuthenticated {
                loadAppData()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            updateAppState()

            // Cuando el usuario hace login, cargar datos
            if newValue && !oldValue {
                loadAppData()
            }
        }
        .onAppear {
            updateAppState()

            // Verificar si debe mostrar onboarding (solo si ya autenticado)
            if authViewModel.isAuthenticated && OnboardingManager.shared.shouldShowOnboarding() {
                let type = OnboardingManager.shared.getType()
                appState = .showingOnboarding(type)
            }

            // Si ya está autenticado al iniciar (autologin), cargar datos en background
            if authViewModel.isAuthenticated && !authViewModel.isCheckingInitialAuth {
                loadAppData()
            }
        }
    }

    // MARK: - State Management

    /// Actualiza el estado de la app basado en el estado de autenticación
    private func updateAppState() {
        // No cambiar estado si estamos mostrando onboarding
        if case .showingOnboarding = appState {
            return
        }

        if authViewModel.isCheckingInitialAuth {
            appState = .checkingAuth
        } else if !authViewModel.isAuthenticated {
            appState = .unauthenticated
        } else if appState == .ready {
            // Ya terminamos de cargar, mantener ready
            return
        }
        // Usuario autenticado - loadAppData() decidirá el próximo estado
    }

    /// Cuando el usuario completa o salta el onboarding
    private func onOnboardingComplete() {
        withAnimation(.easeOut(duration: 0.3)) {
            // Si datos listos → MainTabView, sino → loading screen
            appState = isDataReady ? .ready : .loadingData
        }
    }

    // MARK: - Initial Loading View (Check Auth)
    /// Vista de loading inicial durante verificación de autenticación
    /// Spinner simple con fondo champán
    private var initialLoadingView: some View {
        ZStack {
            GradientLinearView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
        }
    }

    // MARK: - Load App Data
    /// Carga datos críticos antes de mostrar MainTabView
    /// Smart loading: Si hay caché, va directo a MainTabView (HomeTab muestra skeleton)
    private func loadAppData() {
        guard !hasLoadedData else {
            #if DEBUG
            print("⚠️ [ContentView] Data already loaded, skipping")
            #endif
            return
        }

        guard let userId = authViewModel.currentUser?.id else {
            #if DEBUG
            print("⚠️ [ContentView] No user ID found")
            #endif
            return
        }

        hasLoadedData = true

        Task {
            let hasCache = await userViewModel.hasCachedData(userId: userId)

            if hasCache {
                // Con caché: ir directo a MainTabView (HomeTab muestra skeleton)
                await MainActor.run {
                    if case .showingOnboarding = appState {
                        // Mantenemos onboarding, datos se cargan en background
                    } else {
                        appState = .ready
                    }
                }

                // Cargar datos desde caché (~0.1s)
                await userViewModel.loadInitialUserData(
                    userId: userId,
                    perfumeViewModel: perfumeViewModel
                )

                await userViewModel.loadSharedAppData(
                    perfumeViewModel: perfumeViewModel,
                    brandViewModel: brandViewModel,
                    familyViewModel: familiaOlfativaViewModel,
                    testViewModel: testViewModel
                )

                await MainActor.run {
                    isDataReady = true
                }
            } else {
                // Sin caché: mostrar loading screen (primera carga)
                await MainActor.run {
                    if case .showingOnboarding = appState {
                        // Mantenemos onboarding, datos se cargan en background
                    } else {
                        appState = .loadingData
                    }
                }

                // Descargar desde Firestore (~2-5s)
                await userViewModel.loadInitialUserData(
                    userId: userId,
                    perfumeViewModel: perfumeViewModel
                )

                await userViewModel.loadSharedAppData(
                    perfumeViewModel: perfumeViewModel,
                    brandViewModel: brandViewModel,
                    familyViewModel: familiaOlfativaViewModel,
                    testViewModel: testViewModel
                )

                await MainActor.run {
                    isDataReady = true
                    if case .showingOnboarding = appState {
                        // Mantenemos onboarding hasta que usuario lo complete
                    } else {
                        appState = .ready
                    }
                }
            }
        }
    }
}
