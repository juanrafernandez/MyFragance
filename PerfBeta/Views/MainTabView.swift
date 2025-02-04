import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel

    var body: some View {
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
                .environmentObject(perfumeViewModel)
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
            FragranceLibraryView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Mi Perfumería")
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
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(named: "grisClaro")
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        .task {
            await brandViewModel.loadInitialData()
            await perfumeViewModel.loadInitialData()
            await familiaOlfativaViewModel.loadInitialData()
            await notesViewModel.loadInitialData()
            await testViewModel.loadInitialData()
            await olfactiveProfileViewModel.loadInitialData()
        }
    }
}
