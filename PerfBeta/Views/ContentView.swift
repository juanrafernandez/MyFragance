import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        // ✅ NUEVO: Mostrar loading inicial mientras se verifica autenticación
        // Usa el mismo fondo que LoginView para transición suave
        if authViewModel.isCheckingInitialAuth {
            initialLoadingView
        } else {
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

    // MARK: - Initial Loading View
    /// Vista de loading inicial con el mismo fondo que LoginView
    /// Sin texto para transición suave
    private var initialLoadingView: some View {
        ZStack {
            // Mismo fondo que LoginView
            GradientLinearView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            // Spinner simple centrado
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
        }
    }
}
