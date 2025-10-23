import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isLoadingData = true

    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var userViewModel: UserViewModel // Sigue siendo necesario para las pestañas
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel


    var body: some View {
        Group {
            if isLoadingData {
                ZStack {
                    Color("grisClaro").edgesIgnoringSafeArea(.all)
                    ProgressView("Cargando datos...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("Gold")))
                        .foregroundColor(Color("textoPrincipal"))
                        .font(.headline)
                }
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

                    SettingsView()
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
        .task {
            if isLoadingData {
                await loadAllInitialData()
            }
        }
        .onAppear {
            PerformanceLogger.logViewAppear("MainTabView")
        }
        .onDisappear {
            PerformanceLogger.logViewDisappear("MainTabView")
        }
        .onChange(of: selectedTab) { newTab in
            PerformanceLogger.logViewModelLoad("MainTabView", action: "tabChanged(to: \(newTab))")
        }
    }

    private func loadAllInitialData() async {

        let familiaVM = self.familiaOlfativaViewModel
        let brandVM = self.brandViewModel
        let perfumeVM = self.perfumeViewModel
        let notesVM = self.notesViewModel
        let testVM = self.testViewModel
        // No necesitamos capturar userVM ni olfactiveVM aquí para la carga inicial

        await familiaVM.loadInitialData()
        await brandVM.loadInitialData()

        // ✅ OPTIMIZACIÓN: Cargar solo metadata index (ligero) en vez de todos los perfumes completos
        await perfumeVM.loadMetadataIndex()

        await notesVM.loadInitialData()
        await testVM.loadInitialData()

        // Ya no se llaman los métodos de carga de UserViewModel ni OlfactiveProfileViewModel aquí

        isLoadingData = false
    }
}
