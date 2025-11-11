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
        let _ = {
            #if DEBUG
            print("🔄 [ContentView] Body re-rendered. State: \(appState)")
            #endif
        }()

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

            // ✅ Verificar si debe mostrar onboarding (solo si ya autenticado)
            if authViewModel.isAuthenticated && OnboardingManager.shared.shouldShowOnboarding() {
                let type = OnboardingManager.shared.getType()
                appState = .showingOnboarding(type)

                #if DEBUG
                print("🎯 [ContentView] Showing onboarding: \(type)")
                #endif
            }

            // Si ya está autenticado al iniciar (autologin), cargar datos EN BACKGROUND
            if authViewModel.isAuthenticated && !authViewModel.isCheckingInitialAuth {
                loadAppData()
            }
        }
    }

    // MARK: - State Management

    /// Actualiza el estado de la app basado en el estado de autenticación
    private func updateAppState() {
        #if DEBUG
        print("🔄 [ContentView] updateAppState() called - current state: \(appState)")
        print("   - isCheckingInitialAuth: \(authViewModel.isCheckingInitialAuth)")
        print("   - isAuthenticated: \(authViewModel.isAuthenticated)")
        #endif

        // ✅ No cambiar estado si estamos mostrando onboarding
        if case .showingOnboarding = appState {
            #if DEBUG
            print("   → Showing onboarding, skipping state update")
            #endif
            return
        }

        if authViewModel.isCheckingInitialAuth {
            appState = .checkingAuth
            #if DEBUG
            print("   → Set state to: .checkingAuth")
            #endif
        } else if !authViewModel.isAuthenticated {
            appState = .unauthenticated
            #if DEBUG
            print("   → Set state to: .unauthenticated")
            #endif
        } else if appState == .ready {
            // Ya terminamos de cargar, mantener ready
            #if DEBUG
            print("   → State already .ready, no change")
            #endif
            return
        } else if authViewModel.isAuthenticated {
            // ✅ Usuario autenticado - NO setear loadingData aquí
            // loadAppData() detectará caché y decidirá si mostrar loading o skeleton
            #if DEBUG
            print("   → User authenticated, keeping state \(appState) - loadAppData() will decide")
            #endif
        }
    }

    /// Cuando el usuario completa o salta el onboarding
    private func onOnboardingComplete() {
        #if DEBUG
        print("🎯 [ContentView] Onboarding completed - isDataReady: \(isDataReady)")
        #endif

        // Decidir a qué estado ir después del onboarding
        if isDataReady {
            // Ya terminó de cargar - ir directo a MainTabView
            #if DEBUG
            print("   → Data already loaded, going to .ready")
            #endif
            withAnimation(.easeOut(duration: 0.3)) {
                appState = .ready
            }
        } else {
            // Aún está cargando - mostrar loading screen
            #if DEBUG
            print("   → Data still loading, going to .loadingData")
            #endif
            withAnimation(.easeOut(duration: 0.3)) {
                appState = .loadingData
            }
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
    /// Carga TODOS los datos críticos antes de mostrar MainTabView
    /// ✅ SMART LOADING: Si hay caché, va directo a MainTabView (HomeTab muestra skeleton)
    /// ✅ Protegido contra llamadas duplicadas con hasLoadedData flag
    private func loadAppData() {
        // ✅ GUARD: Evitar cargas duplicadas
        guard !hasLoadedData else {
            #if DEBUG
            print("⚠️ [ContentView] Data already loaded or loading, skipping")
            #endif
            return
        }

        guard let userId = authViewModel.currentUser?.id else {
            #if DEBUG
            print("⚠️ [ContentView] No user ID found, skipping data load")
            #endif
            return
        }

        // ✅ Marcar como cargando para prevenir llamadas concurrentes
        hasLoadedData = true

        Task {
            #if DEBUG
            print("🚀 [ContentView] Starting app data load for user: \(userId)")
            print("   - Current appState: \(appState)")
            #endif

            // ✅ DETECTAR CACHÉ: Decidir si mostrar loading screen o skeleton
            let hasCache = await userViewModel.hasCachedData(userId: userId)

            #if DEBUG
            print("📊 [ContentView] Cache detection result: \(hasCache)")
            #endif

            if hasCache {
                // ✅ HAY CACHÉ: Ir directo a MainTabView (HomeTab mostrará skeleton)
                #if DEBUG
                print("⚡ [ContentView] Cache detected - showing MainTabView with skeleton")
                print("   - Transitioning from \(appState) to .ready")
                #endif

                await MainActor.run {
                    // Solo cambiar a .ready si NO estamos en onboarding
                    if case .showingOnboarding = appState {
                        #if DEBUG
                        print("   → Showing onboarding, marking data as ready but keeping state")
                        #endif
                    } else {
                        appState = .ready // HomeTab automáticamente muestra skeleton mientras carga
                        #if DEBUG
                        print("✅ [ContentView] State changed to .ready")
                        #endif
                    }
                }

                // Cargar datos en background (rápido ~0.1s desde caché)
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

                #if DEBUG
                print("✅ [ContentView] App data loaded from cache")
                #endif

                // Marcar datos como listos
                await MainActor.run {
                    isDataReady = true
                }
            } else {
                // ❌ NO HAY CACHÉ: Mostrar loading screen completa (primera carga)
                #if DEBUG
                print("🆕 [ContentView] No cache - showing full loading screen")
                print("   - Transitioning from \(appState) to .loadingData")
                #endif

                await MainActor.run {
                    // Solo cambiar a .loadingData si NO estamos en onboarding
                    if case .showingOnboarding = appState {
                        #if DEBUG
                        print("   → Showing onboarding, keeping state")
                        #endif
                    } else {
                        appState = .loadingData // Muestra AppDataLoadingView
                        #if DEBUG
                        print("✅ [ContentView] State changed to .loadingData")
                        #endif
                    }
                }

                // Descargar todos los datos (lento ~2-5s desde Firestore)
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

                #if DEBUG
                print("✅ [ContentView] App data downloaded from Firestore")
                #endif

                // Cuando termine, permitir mostrar MainTabView
                await MainActor.run {
                    isDataReady = true
                    // Solo cambiar a .ready si NO estamos en onboarding
                    if case .showingOnboarding = appState {
                        #if DEBUG
                        print("   → Showing onboarding, data ready but keeping state")
                        #endif
                    } else {
                        appState = .ready
                    }
                }
            }
        }
    }
}
