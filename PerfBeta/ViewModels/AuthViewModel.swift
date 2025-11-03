import Foundation
import SwiftUI
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isCheckingInitialAuth: Bool = true // ✅ NUEVO: Loading inicial de la app
    @Published var isLoadingGoogleLogin: Bool = false
    @Published var isLoadingAppleLogin: Bool = false
    @Published var isLoadingGoogleRegister: Bool = false
    @Published var isLoadingAppleRegister: Bool = false
    @Published var isLoadingEmailLogin: Bool = false
    @Published var isLoadingEmailRegister: Bool = false
    @Published var errorMessage: String? = nil
    @Published private(set) var currentUser: User? = nil

    private let authService: AuthServiceProtocol
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var appleContinuation: CheckedContinuation<AuthCredential, Error>?
    private var appleNameInfo: [String: Any]? = nil
    private var hasReceivedInitialAuthState = false // ✅ NUEVO: Para detectar primera actualización

    enum SocialProvider { case google, apple }

    init(authService: AuthServiceProtocol) {
        self.authService = authService
        self.currentUser = authService.getCurrentAuthUser()
        self.isAuthenticated = (self.currentUser != nil)
        print("AuthViewModel Initialized. Current User: \(currentUser?.id ?? "None"). IsAuthenticated: \(isAuthenticated)")
        startListeningToAuthState()

        // ✅ NUEVO: Si no hay listener activo o no hay usuario, completar verificación inmediatamente
        // Esto maneja el caso donde Firebase ya tiene su estado listo
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay para dar tiempo al listener
            if !hasReceivedInitialAuthState {
                print("AuthViewModel: No initial auth state received, completing check")
                isCheckingInitialAuth = false
            }
        }
    }

    private func startListeningToAuthState() {
        if authStateListenerHandle != nil { return }
        print("AuthViewModel: Setting up auth state listener via service...")
        authStateListenerHandle = authService.addAuthStateListener { [weak self] (auth, firebaseUser) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("AuthViewModel Listener: Received update.")
                let wasAuthenticated = self.isAuthenticated
                let currentAppUser = self.authService.getCurrentAuthUser()

                self.currentUser = currentAppUser
                let nowAuthenticated = currentAppUser != nil

                if wasAuthenticated != nowAuthenticated {
                    self.isAuthenticated = nowAuthenticated
                    if nowAuthenticated {
                        print("AuthViewModel Listener: State changed to AUTHENTICATED (User: \(currentAppUser?.id ?? "N/A")). Stopping indicators.")
                        self.stopAllLoadingIndicators()
                    } else {
                        print("AuthViewModel Listener: State changed to UNAUTHENTICATED.")
                    }
                } else {
                     print("AuthViewModel Listener: State unchanged (Authenticated: \(nowAuthenticated), User: \(currentAppUser?.id ?? "N/A")).")
                }

                // ✅ NUEVO: Después de la primera actualización, completar verificación inicial
                if !self.hasReceivedInitialAuthState {
                    self.hasReceivedInitialAuthState = true
                    self.isCheckingInitialAuth = false
                    print("AuthViewModel: Initial auth check complete. isAuthenticated: \(self.isAuthenticated)")
                }
            }
        }
        if authStateListenerHandle == nil {
             print("🔴 AuthViewModel: Failed to get listener handle from authService.")
        }
    }

    deinit {
        print("AuthViewModel: Deinit - Removing Auth State Listener.")
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signInWithEmailPassword(email: String, password: String) async throws {
        isLoadingEmailLogin = true
        errorMessage = nil
        defer { isLoadingEmailLogin = false }
        do {
            try await authService.signInWithEmail(email: email, password: password)
        } catch {
            self.errorMessage = mapAuthErrorToMessage(error)
            throw error
        }
    }

    func registerUserWithEmail(email: String, password: String, name: String) async -> Bool {
        isLoadingEmailRegister = true
        errorMessage = nil
        var registrationAttemptSucceeded = false
        defer { isLoadingEmailRegister = false }
        do {
            try await authService.registerUser(email: email, password: password, nombre: name, rol: "usuario")
            registrationAttemptSucceeded = true
        } catch {
            self.errorMessage = mapAuthErrorToMessage(error)
        }
        return registrationAttemptSucceeded
    }

    func signInWithGoogle() {
        handleSocialAuth(provider: .google, isLoginAttempt: true)
    }

    func signInWithApple() {
        handleSocialAuth(provider: .apple, isLoginAttempt: true)
    }

    func registerWithGoogle() {
        handleSocialAuth(provider: .google, isLoginAttempt: false)
    }

    func registerWithApple() {
        handleSocialAuth(provider: .apple, isLoginAttempt: false)
    }

    private func handleSocialAuth(provider: SocialProvider, isLoginAttempt: Bool) {
        let providerNameString = provider == .google ? "Google" : "Apple"

        // --- Determinar y activar el estado de carga correcto ---
        var shouldSetLoading = false
        switch (provider, isLoginAttempt) {
        case (.google, true):
            if !isLoadingGoogleLogin && !isLoadingAppleLogin && !isLoadingAppleRegister && !isLoadingGoogleRegister {
                isLoadingGoogleLogin = true
                shouldSetLoading = true
            }
        case (.google, false):
             if !isLoadingGoogleRegister && !isLoadingAppleLogin && !isLoadingAppleRegister && !isLoadingGoogleLogin {
                isLoadingGoogleRegister = true
                shouldSetLoading = true
            }
        case (.apple, true):
             if !isLoadingAppleLogin && !isLoadingGoogleLogin && !isLoadingGoogleRegister && !isLoadingAppleRegister {
                isLoadingAppleLogin = true
                shouldSetLoading = true
            }
        case (.apple, false):
             if !isLoadingAppleRegister && !isLoadingGoogleLogin && !isLoadingGoogleRegister && !isLoadingAppleLogin {
                isLoadingAppleRegister = true
                shouldSetLoading = true
            }
        }

        guard shouldSetLoading else {
            print("AuthViewModel: handleSocialAuth cancelado, otra operación en progreso.")
            return
        }
        // --- Fin determinar y activar estado de carga ---

        errorMessage = nil

        Task {
            do {
                let (credential, providerInfo) = try await getCredentialAndInfo(for: provider)
                self.authenticateWithFirebase(
                    credential: credential,
                    provider: providerNameString,
                    providerInfo: providerInfo,
                    isLoginAttempt: isLoginAttempt
                )
            } catch {
                 print("Error obteniendo credencial para \(providerNameString): \(error)")
                 if let nsError = error as NSError?,
                   (nsError.code == GIDSignInError.canceled.rawValue || nsError.code == ASAuthorizationError.canceled.rawValue) {
                      print("\(providerNameString) Sign In cancelado.")
                      self.errorMessage = nil
                 } else {
                      self.errorMessage = "Error al iniciar con \(providerNameString)."
                 }
                 // --- Resetear el estado de carga correcto en caso de error al obtener credencial ---
                 await MainActor.run {
                     switch (provider, isLoginAttempt) {
                     case (.google, true): self.isLoadingGoogleLogin = false
                     case (.google, false): self.isLoadingGoogleRegister = false
                     case (.apple, true): self.isLoadingAppleLogin = false
                     case (.apple, false): self.isLoadingAppleRegister = false
                     }
                 }
                 // --- Fin resetear estado ---
            }
        }
    }

    private func getCredentialAndInfo(for provider: SocialProvider) async throws -> (AuthCredential, [String: Any]?) {
        switch provider {
        case .google:
            let credential = try await getGoogleCredential()
            return (credential, nil)
        case .apple:
            let credential = try await getAppleCredential()
            let info = self.appleNameInfo
            self.appleNameInfo = nil
            return (credential, info)
        }
    }

    private func getGoogleCredential() async throws -> AuthCredential {
         guard let presentingViewController = getRootViewController() else {
             throw NSError(domain: "AuthViewModelError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la ventana para Google Sign In."])
         }
         return try await withCheckedThrowingContinuation { continuation in
             GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
                 if let error = error {
                     continuation.resume(throwing: error)
                     return
                 }
                 guard let result = signInResult, let idToken = result.user.idToken?.tokenString else {
                     continuation.resume(throwing: NSError(domain: "AuthViewModelError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Resultado o token de Google inválido."]))
                     return
                 }
                 let accessToken = result.user.accessToken.tokenString
                 let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                 continuation.resume(returning: credential)
             }
         }
     }

    private func getAppleCredential() async throws -> AuthCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.appleContinuation = continuation

            let nonce = randomNonceString()
            currentNonce = nonce
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            let coordinator = AppleSignInCoordinatorBridge(viewModel: self, nonce: nonce)
            authorizationController.delegate = coordinator
            authorizationController.presentationContextProvider = coordinator
            objc_setAssociatedObject(authorizationController, "coordinator", coordinator, .OBJC_ASSOCIATION_RETAIN)
            authorizationController.performRequests()
        }
    }

    func completeAppleSignIn(credential: AuthCredential, info: [String: Any]?) {
        self.appleNameInfo = info
        appleContinuation?.resume(returning: credential)
        appleContinuation = nil
    }

    func failAppleSignIn(error: Error) {
        appleContinuation?.resume(throwing: error)
        appleContinuation = nil
    }

    private func authenticateWithFirebase(credential: AuthCredential, provider: String, providerInfo: [String: Any]?, isLoginAttempt: Bool) {
        // --- Closure auxiliar para resetear el estado de carga correcto ---
        let resetLoadingState = { [weak self] in
            guard let self = self else { return }
            Task {
                await MainActor.run {
                     switch (provider, isLoginAttempt) {
                     case ("Google", true): self.isLoadingGoogleLogin = false
                     case ("Google", false): self.isLoadingGoogleRegister = false
                     case ("Apple", true): self.isLoadingAppleLogin = false
                     case ("Apple", false): self.isLoadingAppleRegister = false
                     default: break
                     }
                }
            }
        }
        // --- Fin closure auxiliar ---

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                print("Error Firebase Auth con \(provider): \(error.localizedDescription)")
                self.errorMessage = self.mapFirebaseErrorToMessage(error)
                resetLoadingState()
                return
            }

            print("✅ Autenticación con Firebase vía \(provider) exitosa para \(authResult?.user.uid ?? "N/A")")
            guard let firebaseUser = authResult?.user else {
                print("Error: AuthResult exitoso pero no se encontró firebaseUser.")
                self.errorMessage = "Error inesperado post-autenticación."
                try? Auth.auth().signOut()
                resetLoadingState()
                return
            }

            Task {
                do {
                    try await self.authService.checkAndCreateUserProfileIfNeeded(
                        firebaseUser: firebaseUser,
                        providedName: providerInfo?["name"] as? String,
                        isLoginAttempt: isLoginAttempt
                    )
                    print("AuthViewModel: Profile check/create successful for \(firebaseUser.uid). Intent was login: \(isLoginAttempt)")
                    resetLoadingState()

                } catch let authServiceError as AuthServiceError {
                     print("❌ Error during checkAndCreateUserProfileIfNeeded for \(firebaseUser.uid): \(authServiceError)")
                     if case .userNotFound = authServiceError, isLoginAttempt {
                         self.errorMessage = "Cuenta no encontrada. Por favor, regístrate primero."
                         try? Auth.auth().signOut()
                     } else if case .coreError(let underlying) = authServiceError,
                               let nsError = underlying as NSError?, nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue, !isLoginAttempt {
                          self.errorMessage = "Esta cuenta social ya está registrada. Por favor, inicia sesión."
                          try? Auth.auth().signOut()
                     }
                     else {
                         self.errorMessage = self.mapAuthErrorToMessage(authServiceError)
                         try? Auth.auth().signOut()
                     }
                     resetLoadingState()

                } catch {
                    print("❌ Generic Error during checkAndCreateUserProfileIfNeeded for \(firebaseUser.uid): \(error)")
                    self.errorMessage = "Ocurrió un error al verificar tu perfil."
                    try? Auth.auth().signOut()
                    resetLoadingState()
                }
            }
        }
    }

    private func getRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode == errSecSuccess { return random }
                else { print("Nonce Error: \(errorCode)"); return 0 }
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
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("❌ Error signing out via ViewModel: \(error.localizedDescription)")
            errorMessage = "No se pudo cerrar sesión. Inténtalo de nuevo."
        }
    }

    private func stopAllLoadingIndicators() {
        isLoadingEmailLogin = false
        isLoadingEmailRegister = false
        isLoadingGoogleLogin = false
        isLoadingGoogleRegister = false
        isLoadingAppleLogin = false
        isLoadingAppleRegister = false
    }

    private func mapAuthErrorToMessage(_ error: Error) -> String {
        if let authError = error as? AuthServiceError {
             switch authError {
             case .userNotFound: return "Cuenta no encontrada. Regístrate primero."
             case .dataSaveError(let underlyingError): return "Error guardando datos: \(underlyingError.localizedDescription)"
             case .coreError(let underlyingError):
                 if let nsError = underlyingError as NSError?, nsError.domain == AuthErrorDomain {
                     switch nsError.code {
                     case AuthErrorCode.emailAlreadyInUse.rawValue: return "El correo electrónico ya está en uso o la cuenta ya existe."
                     case AuthErrorCode.weakPassword.rawValue: return "La contraseña es demasiado débil."
                     case AuthErrorCode.invalidEmail.rawValue: return "El formato del correo electrónico no es válido."
                     case AuthErrorCode.wrongPassword.rawValue: return "La contraseña es incorrecta."
                     case AuthErrorCode.userNotFound.rawValue: return "No se encontró un usuario con ese correo electrónico."
                     case AuthErrorCode.accountExistsWithDifferentCredential.rawValue: return "Ya existe una cuenta con este email usando otro método."
                     default: return "Error de autenticación (#\(nsError.code))"
                     }
                 }
                 return "Error: \(underlyingError.localizedDescription)"
             case .unknownError: return "Ocurrió un error desconocido."
             }
         }
        return error.localizedDescription
    }

     private func mapFirebaseErrorToMessage(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain {
             switch nsError.code {
             case AuthErrorCode.accountExistsWithDifferentCredential.rawValue:
                  return "Ya existe una cuenta con este email usando otro método de inicio de sesión."
             default:
                  return "Error de Firebase Auth (#\(nsError.code))"
             }
        }
        return error.localizedDescription
    }
}


class AppleSignInCoordinatorBridge: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    weak var viewModel: AuthViewModel?
    let rawNonce: String

    init(viewModel: AuthViewModel, nonce: String) {
        self.viewModel = viewModel
        self.rawNonce = nonce
        super.init()
         print("AppleSignInCoordinatorBridge Initialized")
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
         print("AppleSignInCoordinatorBridge: Providing presentation anchor")
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
         print("AppleSignInCoordinatorBridge: didCompleteWithAuthorization")
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
             print("AppleSignInCoordinatorBridge: Error - Failed to get ASAuthorizationAppleIDCredential")
            viewModel?.failAppleSignIn(error: NSError(domain: "AuthViewModelError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Credencial de Apple inválida."]))
            return
        }

        guard let idTokenData = appleIDCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8) else {
              print("AppleSignInCoordinatorBridge: Error - Failed to get idToken")
            viewModel?.failAppleSignIn(error: NSError(domain: "AuthViewModelError", code: 4, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener el token de Apple."]))
            return
        }
        print("AppleSignInCoordinatorBridge: idToken obtained")

        var providerName: String? = nil
        if let fullNameComponents = appleIDCredential.fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .default
            providerName = formatter.string(from: fullNameComponents)
            if providerName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                providerName = nil
            }
             print("AppleSignInCoordinatorBridge: Name obtained: \(providerName ?? "None")")
        } else {
             print("AppleSignInCoordinatorBridge: fullNameComponents not provided by Apple.")
        }

        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idToken,
                                                  rawNonce: rawNonce)
        print("AppleSignInCoordinatorBridge: Firebase credential created")

        let providerInfo = providerName != nil ? ["name": providerName!] : nil

        viewModel?.completeAppleSignIn(credential: credential, info: providerInfo)
         print("AppleSignInCoordinatorBridge: Called viewModel.completeAppleSignIn")
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
         print("AppleSignInCoordinatorBridge: didCompleteWithError: \(error.localizedDescription)")
        viewModel?.failAppleSignIn(error: error)
         print("AppleSignInCoordinatorBridge: Called viewModel.failAppleSignIn")
    }
}
