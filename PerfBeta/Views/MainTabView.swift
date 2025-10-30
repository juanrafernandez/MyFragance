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

            // ⚡ Load only essential data at launch
            // Other data loads lazily when tabs are accessed
            loadEssentialData()
        }
        .onDisappear {
            PerformanceLogger.logViewDisappear("MainTabView")
        }
        .onChange(of: selectedTab) { newTab in
            PerformanceLogger.logViewModelLoad("MainTabView", action: "tabChanged(to: \(newTab))")
        }
    }

    // MARK: - Data Loading

    /// Loads only essential data needed for HomeTab
    /// Other data loads on-demand when user navigates to those tabs
    private func loadEssentialData() {
        print("🚀 [MainTabView] Loading essential data only...")

        // Metadata index is required for perfume recommendations
        Task.detached(priority: .userInitiated) { [weak perfumeViewModel] in
            do {
                await perfumeViewModel?.loadMetadataIndex()
                print("✅ [MainTabView] Essential: Metadata loaded")
            } catch {
                print("❌ [MainTabView] Essential: Metadata failed - \(error.localizedDescription)")
            }
        }
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
