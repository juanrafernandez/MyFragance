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

            // Si ya está autenticado al iniciar (autologin), cargar datos
            if authViewModel.isAuthenticated && !authViewModel.isCheckingInitialAuth {
                loadAppData()
            }
        }
    }

    // MARK: - State Management

    /// Actualiza el estado de la app basado en el estado de autenticación
    private func updateAppState() {
        if authViewModel.isCheckingInitialAuth {
            appState = .checkingAuth
        } else if !authViewModel.isAuthenticated {
            appState = .unauthenticated
        } else if appState == .ready {
            // Ya terminamos de cargar, mantener ready
            return
        } else if authViewModel.isAuthenticated {
            // Usuario autenticado - ir directamente a loadingData
            // Esto evita el "flash" de unauthenticated
            if appState != .loadingData {
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
            #endif

            // ✅ DETECTAR CACHÉ: Decidir si mostrar loading screen o skeleton
            let hasCache = await userViewModel.hasCachedData(userId: userId)

            if hasCache {
                // ✅ HAY CACHÉ: Ir directo a MainTabView (HomeTab mostrará skeleton)
                #if DEBUG
                print("⚡ [ContentView] Cache detected - showing MainTabView with skeleton")
                #endif

                await MainActor.run {
                    appState = .ready // HomeTab automáticamente muestra skeleton mientras carga
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
            } else {
                // ❌ NO HAY CACHÉ: Mostrar loading screen completa (primera carga)
                #if DEBUG
                print("🆕 [ContentView] No cache - showing full loading screen")
                #endif

                await MainActor.run {
                    appState = .loadingData // Muestra AppDataLoadingView
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
                    appState = .ready
                }
            }
        }
    }
}
