import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                MainTabView() // Navega directamente si está autenticado
            } else {
                //LoginView_NewDesign()
                LoginView() // Muestra la pantalla de inicio de sesión
            }
        }.tint(.black)
    }
}
