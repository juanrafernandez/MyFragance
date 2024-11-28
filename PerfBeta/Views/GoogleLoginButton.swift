import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth

struct GoogleLoginButton: View {
    var onSuccess: () -> Void // Closure para manejar el éxito

    var body: some View {
        Button(action: signInWithGoogle) {
            HStack {
                Image(systemName: "globe") // Reemplázalo con un ícono de Google si tienes uno
                Text("Iniciar sesión con Google")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(8)
        }
    }

    func signInWithGoogle() {
        // Obtén el controlador de vista actual
        guard let presentingViewController = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("Error: No se encontró el rootViewController")
            return
        }

        // Inicia el proceso de autenticación con Google
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
            if let error = error {
                print("Error al iniciar sesión con Google: \(error.localizedDescription)")
                return
            }

            guard let signInResult = signInResult else {
                print("Error: No se pudo obtener el resultado de la autenticación")
                return
            }

            // Obtén el ID token y el access token
            guard let idToken = signInResult.user.idToken?.tokenString else {
                print("Error: No se pudo obtener el ID token del usuario")
                return
            }
            let accessToken = signInResult.user.accessToken.tokenString

            // Crea las credenciales para Firebase
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            // Autentica con Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error al autenticar con Firebase: \(error.localizedDescription)")
                } else {
                    print("Inicio de sesión exitoso: \(authResult?.user.email ?? "No Email")")
                    onSuccess() // Llama al closure en caso de éxito
                }
            }
        }
    }
}
