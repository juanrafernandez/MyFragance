import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Pantalla Inicio
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Inicio")
                }
                .tag(0)

            // Pantalla Explorar
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explorar")
                }
                .tag(1)

            // Test Olfativo
            TestOlfativoView()
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
        .accentColor(Color("Gold")) // Aplica el color dorado desde Assets
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(named: "grisClaro") // Fondo del TabBar
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
