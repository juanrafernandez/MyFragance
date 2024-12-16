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
            TestView()
                .tabItem {
                    Image(systemName: "drop.fill")
                    Text("Test")
                }
                .tag(2)

            // Perfil de Usuario
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Perfil")
                }
                .tag(3)
        }
        .accentColor(Color("Gold")) // Aplica el color dorado desde Assets
    }
}
