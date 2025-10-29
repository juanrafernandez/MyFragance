import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var userViewModel: UserViewModel // ✅ Necesario para isLoading
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel


    var body: some View {
        Group {
            // ✅ FIX: Pantalla completa de loading que REEMPLAZA el TabView
            if userViewModel.isLoading {
                LoadingScreen()
            } else {
                TabView(selection: $selectedTab) {
                    HomeTabView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Inicio")
                        }
                        .tag(0)

                    ExploreTabView()
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Explorar")
                        }
                        .tag(1)

                    TestOlfativoTabView()
                        .tabItem {
                            Image(systemName: "drop.fill")
                            Text("Test")
                        }
                        .tag(2)

                    FragranceLibraryTabView()
                        .tabItem {
                            Image(systemName: "books.vertical.fill")
                            Text("Mi Colección")
                        }
                        .tag(3)

                    SettingsViewNew()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Ajustes")
                        }
                        .tag(4)
                }
                .accentColor(Color("Gold"))
                .onAppear {
                     let tabBarAppearance = UITabBarAppearance()
                     tabBarAppearance.configureWithTransparentBackground()
                     tabBarAppearance.backgroundColor = .clear
                     UITabBar.appearance().standardAppearance = tabBarAppearance
                     UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }
            }
        }
        .onAppear {
            PerformanceLogger.logViewAppear("MainTabView")

            // ⚡ CRÍTICO: Lanzar cargas en background SIN esperar
            // userViewModel.isLoading controla la pantalla de loading
            loadAllDataInBackground()
        }
        .onDisappear {
            PerformanceLogger.logViewDisappear("MainTabView")
        }
        .onChange(of: selectedTab) { newTab in
            PerformanceLogger.logViewModelLoad("MainTabView", action: "tabChanged(to: \(newTab))")
        }
    }

    // ⚡ CRÍTICO: Cargar TODO en background SIN bloquear UI
    private func loadAllDataInBackground() {
        print("🚀 [MainTabView] UI shown immediately, loading in background...")

        // ⚡ Lanzar TODAS las cargas en background independiente
        // NO esperar a NADA - la UI ya está visible

        Task.detached(priority: .userInitiated) { [weak perfumeViewModel] in
            await perfumeViewModel?.loadMetadataIndex()
            print("✅ [MainTabView] Background: Metadata loaded")
        }

        Task.detached(priority: .userInitiated) { [weak brandViewModel] in
            await brandViewModel?.loadInitialData()
            print("✅ [MainTabView] Background: Brands loaded")
        }

        Task.detached(priority: .background) { [weak familiaOlfativaViewModel] in
            await familiaOlfativaViewModel?.loadInitialData()
            print("✅ [MainTabView] Background: Families loaded")
        }

        Task.detached(priority: .background) { [weak notesViewModel] in
            await notesViewModel?.loadInitialData()
            print("✅ [MainTabView] Background: Notes loaded")
        }

        Task.detached(priority: .background) { [weak testViewModel] in
            await testViewModel?.loadInitialData()
            print("✅ [MainTabView] Background: Questions loaded")
        }

        // ⚡ UI es completamente funcional AHORA
        // Background tasks completan cuando puedan (usuario no lo nota)
    }
}

// MARK: - Loading Screen
/// ✅ Pantalla completa de loading que REEMPLAZA el TabView durante la carga inicial
struct LoadingScreen: View {
    var body: some View {
        ZStack {
            // Fondo con gradiente
            GradientView(preset: .champan)
                .ignoresSafeArea()

            // Contenido centrado
            VStack(spacing: 24) {
                // Icono opcional (puedes usar tu logo o emoji)
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(Color("Gold"))

                // Spinner
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color("Gold"))

                // Texto
                Text("Cargando tus perfumes...")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(Color("textoPrincipal"))
            }
        }
    }
}
