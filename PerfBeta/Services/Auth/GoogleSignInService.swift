//
//  GoogleSignInService.swift
//  PerfBeta
//
//  Servicio separado para manejar la autenticación con Google
//  Sigue el principio SRP (Single Responsibility Principle)
//

import Foundation
import UIKit
import GoogleSignIn
import FirebaseAuth

// MARK: - Protocol

protocol GoogleSignInServiceProtocol {
    func getCredential() async throws -> AuthCredential
}

// MARK: - Errors

enum GoogleSignInServiceError: Error, LocalizedError {
    case noRootViewController
    case invalidResult
    case cancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "No se pudo obtener la ventana para Google Sign In."
        case .invalidResult:
            return "Resultado o token de Google inválido."
        case .cancelled:
            return "Inicio de sesión con Google cancelado."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Service

final class GoogleSignInService: GoogleSignInServiceProtocol {

    // MARK: - Public Methods

    /// Obtiene las credenciales de autenticación de Google
    /// - Returns: AuthCredential de Firebase para autenticar con Google
    /// - Throws: GoogleSignInServiceError si hay algún problema
    func getCredential() async throws -> AuthCredential {
        guard let presentingViewController = getRootViewController() else {
            throw GoogleSignInServiceError.noRootViewController
        }

        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code == GIDSignInError.canceled.rawValue {
                        continuation.resume(throwing: GoogleSignInServiceError.cancelled)
                    } else {
                        continuation.resume(throwing: GoogleSignInServiceError.unknown(error))
                    }
                    return
                }

                guard let result = signInResult,
                      let idToken = result.user.idToken?.tokenString else {
                    continuation.resume(throwing: GoogleSignInServiceError.invalidResult)
                    return
                }

                let accessToken = result.user.accessToken.tokenString
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

                #if DEBUG
                AppLogger.info("Google credential obtained successfully", category: .auth)
                #endif

                continuation.resume(returning: credential)
            }
        }
    }

    // MARK: - Private Methods

    private func getRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}
