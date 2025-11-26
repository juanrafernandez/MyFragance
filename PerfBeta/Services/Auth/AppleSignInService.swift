//
//  AppleSignInService.swift
//  PerfBeta
//
//  Servicio separado para manejar la autenticación con Apple
//  Sigue el principio SRP (Single Responsibility Principle)
//

import Foundation
import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth

// MARK: - Protocol

protocol AppleSignInServiceProtocol {
    func getCredential() async throws -> (credential: AuthCredential, userInfo: AppleUserInfo?)
}

// MARK: - User Info

struct AppleUserInfo {
    let name: String?
    let email: String?
}

// MARK: - Errors

enum AppleSignInServiceError: Error, LocalizedError {
    case invalidCredential
    case invalidToken
    case cancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Credencial de Apple inválida."
        case .invalidToken:
            return "No se pudo obtener el token de Apple."
        case .cancelled:
            return "Inicio de sesión con Apple cancelado."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Service

final class AppleSignInService: NSObject, AppleSignInServiceProtocol {

    // MARK: - Private Properties

    private var currentNonce: String?
    private var continuation: CheckedContinuation<(credential: AuthCredential, userInfo: AppleUserInfo?), Error>?

    // MARK: - Public Methods

    /// Obtiene las credenciales de autenticación de Apple
    /// - Returns: Tupla con AuthCredential de Firebase y la información del usuario (si está disponible)
    /// - Throws: AppleSignInServiceError si hay algún problema
    func getCredential() async throws -> (credential: AuthCredential, userInfo: AppleUserInfo?) {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let nonce = randomNonceString()
            currentNonce = nonce

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self

            // Retener referencia para evitar dealloc
            objc_setAssociatedObject(authorizationController, "appleSignInService", self, .OBJC_ASSOCIATION_RETAIN)

            authorizationController.performRequests()
        }
    }

    // MARK: - Private Methods

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode == errSecSuccess {
                    return random
                } else {
                    #if DEBUG
                    AppLogger.error("Nonce generation error: \(errorCode)", category: .auth)
                    #endif
                    return 0
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

    private func getRootWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        #if DEBUG
        AppLogger.debug("Apple Sign In completed successfully", category: .auth)
        #endif

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            #if DEBUG
            AppLogger.error("Failed to get ASAuthorizationAppleIDCredential", category: .auth)
            #endif
            continuation?.resume(throwing: AppleSignInServiceError.invalidCredential)
            continuation = nil
            return
        }

        guard let idTokenData = appleIDCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8) else {
            #if DEBUG
            AppLogger.error("Failed to get idToken from Apple", category: .auth)
            #endif
            continuation?.resume(throwing: AppleSignInServiceError.invalidToken)
            continuation = nil
            return
        }

        // Extraer nombre del usuario si está disponible
        var userName: String?
        if let fullNameComponents = appleIDCredential.fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .default
            let formattedName = formatter.string(from: fullNameComponents)
            if !formattedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                userName = formattedName
            }
        }

        let userInfo = AppleUserInfo(
            name: userName,
            email: appleIDCredential.email
        )

        guard let nonce = currentNonce else {
            #if DEBUG
            AppLogger.error("No nonce available for Apple Sign In", category: .auth)
            #endif
            continuation?.resume(throwing: AppleSignInServiceError.invalidCredential)
            continuation = nil
            return
        }

        // ⚠️ TODO: Update to new credential API when Firebase makes AuthProviderID public
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idToken,
            rawNonce: nonce
        )

        #if DEBUG
        AppLogger.info("Apple credential obtained successfully", category: .auth)
        #endif

        continuation?.resume(returning: (credential: credential, userInfo: userInfo))
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        #if DEBUG
        AppLogger.error("Apple Sign In error: \(error.localizedDescription)", category: .auth)
        #endif

        let nsError = error as NSError
        if nsError.code == ASAuthorizationError.canceled.rawValue {
            continuation?.resume(throwing: AppleSignInServiceError.cancelled)
        } else {
            continuation?.resume(throwing: AppleSignInServiceError.unknown(error))
        }
        continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return getRootWindow() ?? UIWindow()
    }
}
