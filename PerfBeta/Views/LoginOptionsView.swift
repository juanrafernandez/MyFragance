import SwiftUI

struct LoginOptionsView: View {
    @State private var isAuthenticated: Bool = false

    var body: some View {
        NavigationStack {
            if isAuthenticated {
                WelcomeView()
            } else {
                VStack {
                    LoginView(onSuccess: {
                        isAuthenticated = true
                    })
                    GoogleLoginButton {
                        isAuthenticated = true // Cambia el estado al iniciar sesión exitosamente
                    }
                    AppleLoginButton {
                        isAuthenticated = true // Cambia el estado al iniciar sesión exitosamente
                    }
                }
                .padding()
            }
        }.tint(.black)
    }
}
