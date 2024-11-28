import FirebaseAuth
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false // Controla si el usuario está autenticado

    init() {
        checkAuthentication()
    }

    // Verificar si hay un usuario autenticado
    func checkAuthentication() {
        if Auth.auth().currentUser != nil {
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }

    // Cerrar sesión
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}
