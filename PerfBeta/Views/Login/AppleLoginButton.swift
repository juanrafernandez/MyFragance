import AuthenticationServices
import FirebaseAuth
import SwiftUI
import CryptoKit

struct AppleLoginButton: View {
    var onSuccess: () -> Void // Callback para manejar el éxito
    @State private var currentNonce: String?

    var body: some View {
        SignInWithAppleButton(.signIn, onRequest: configureRequest, onCompletion: handleAuthorization)
            .frame(height: 50)
            .cornerRadius(8)
    }

    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    private func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
                print("Error: Credencial inválida")
                return
            }

            guard let idTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                print("Error: No se pudo obtener el idToken")
                return
            }

            guard let rawNonce = currentNonce else {
                print("Error: No se encontró el rawNonce")
                return
            }

            let credential = OAuthProvider.credential(
                providerID: AuthProviderID.apple,
                idToken: idToken,
                rawNonce: rawNonce,
                accessToken: nil
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error al autenticar con Firebase: \(error.localizedDescription)")
                } else {
                    print("Inicio de sesión exitoso con Apple")
                    onSuccess() // Notifica el éxito
                }
            }

        case .failure(let error):
            print("Error al autorizar con Apple: \(error.localizedDescription)")
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode == errSecSuccess {
                    return random
                } else {
                    fatalError("Error generando números aleatorios")
                }
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
