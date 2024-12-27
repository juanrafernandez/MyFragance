import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                MainTabView() // Navega directamente si está autenticado
            } else {
                LoginOptionsView() // Muestra la pantalla de inicio de sesión
            }
        }.tint(.black)
    }
}
