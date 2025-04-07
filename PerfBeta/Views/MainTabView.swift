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
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if isLoadingData {
            ZStack {
                Color("grisClaro").edgesIgnoringSafeArea(.all)
                ProgressView("Cargando datos...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("Gold")))
                    .foregroundColor(Color("textoPrincipal"))
                    .font(.headline)
            }
            .task {
                await familiaOlfativaViewModel.loadInitialData()
                await brandViewModel.loadInitialData()
                await perfumeViewModel.loadInitialData()
                await notesViewModel.loadInitialData()
                await testViewModel.loadInitialData()
                await olfactiveProfileViewModel.loadInitialData()
                await userViewModel.loadUserData(userId: "1")
                
                isLoadingData = false
            }
        } else {
            TabView(selection: $selectedTab) {
                // Pantalla Inicio
                HomeTabView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Inicio")
                    }
                    .tag(0)

                // Pantalla Explorar
                ExploreTabView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Explorar")
                    }
                    .tag(1)

                // Test Olfativo
                TestOlfativoTabView()
                    .tabItem {
                        Image(systemName: "drop.fill")
                        Text("Test")
                    }
                    .tag(2)

                // Biblioteca de Fragancias
                FragranceLibraryTabView()
                    .tabItem {
                        Image(systemName: "books.vertical.fill")
                        Text("Mi Colección")
                    }
                    .tag(3)

                // Ajustes de la App
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
                tabBarAppearance.configureWithTransparentBackground() // Fondo transparente
                tabBarAppearance.backgroundColor = .clear // Eliminar el color de fondo
                UITabBar.appearance().standardAppearance = tabBarAppearance
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
}
