import SwiftUI

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

    var body: some View {
        ZStack {
            switch appState {
            case .checkingAuth:
                initialLoadingView

            case .unauthenticated:
                NavigationStack {
                    LoginView()
                }.tint(.black)

            case .loadingData:
                appDataLoadingView

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

    // MARK: - App Data Loading View (Cache Download)
    /// Vista de carga de datos con animación de botella y partículas
    /// Se muestra mientras se descarga la caché necesaria
    private var appDataLoadingView: some View {
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

    // MARK: - Load App Data
    /// Carga TODOS los datos críticos antes de mostrar MainTabView
    private func loadAppData() {
        guard let userId = authViewModel.currentUser?.id else {
            #if DEBUG
            print("⚠️ [ContentView] No user ID found, skipping data load")
            #endif
            return
        }

        appState = .loadingData

        Task {
            #if DEBUG
            print("🚀 [ContentView] Starting app data load for user: \(userId)")
            #endif

            // Cargar datos del usuario + perfumes de biblioteca
            await userViewModel.loadInitialUserData(
                userId: userId,
                perfumeViewModel: perfumeViewModel
            )

            // Cargar datos compartidos necesarios para todos los tabs
            await userViewModel.loadSharedAppData(
                perfumeViewModel: perfumeViewModel,
                brandViewModel: brandViewModel,
                familyViewModel: familiaOlfativaViewModel,
                testViewModel: testViewModel
            )

            #if DEBUG
            print("✅ [ContentView] App data load completed")
            #endif

            // Cuando termine, permitir mostrar MainTabView
            await MainActor.run {
                appState = .ready
            }
        }
    }
}
