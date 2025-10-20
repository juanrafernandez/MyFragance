import SwiftUI

/// Componente unificado para mostrar errores con recovery actions
/// Convierte errores técnicos en mensajes user-friendly con acciones claras
struct ErrorView: View {
    // MARK: - Properties
    let error: AppError
    let retryAction: (() -> Void)?
    let dismissAction: (() -> Void)?

    // MARK: - Initializers
    init(
        error: AppError,
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.error = error
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }

    /// Convenience initializer desde Error genérico
    init(
        from error: Error,
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.error = AppError.from(error)
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 24) {
            // Icono del error
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundStyle(error.color)
                .symbolEffect(.bounce, value: error)

            // Título y mensaje
            VStack(spacing: 12) {
                Text(error.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(error.userFriendlyMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            // Botones de acción
            actionButtons
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Botón principal (retry/login/etc)
            if let action = primaryAction {
                Button(action: {
                    performAction(action)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: action.icon)
                        Text(action.title)
                    }
                    .frame(maxWidth: 280)
                    .padding()
                    .background(action.style.backgroundColor)
                    .foregroundColor(action.style.foregroundColor)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Botón secundario (dismiss/cancel)
            if dismissAction != nil {
                Button("Cerrar") {
                    dismissAction?()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers
    private var primaryAction: RecoveryAction? {
        switch error.recoveryType {
        case .retry:
            return retryAction != nil ? RecoveryAction(
                title: "Reintentar",
                icon: "arrow.clockwise",
                style: .primary,
                action: retryAction!
            ) : nil

        case .login:
            // TODO: Integrar con AuthViewModel cuando se implemente
            return nil

        case .goBack:
            return dismissAction != nil ? RecoveryAction(
                title: "Volver",
                icon: "arrow.left",
                style: .secondary,
                action: dismissAction!
            ) : nil

        case .clearCache:
            return RecoveryAction(
                title: "Limpiar Caché",
                icon: "trash",
                style: .secondary,
                action: { /* TODO: Integrar con AppDelegate */ }
            )

        case .none:
            return nil
        }
    }

    private func performAction(_ action: RecoveryAction) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        // Ejecutar acción
        action.action()
    }
}

// MARK: - Recovery Action
private struct RecoveryAction {
    let title: String
    let icon: String
    let style: ButtonStyleType
    let action: () -> Void

    enum ButtonStyleType {
        case primary, secondary

        var backgroundColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return Color(.systemGray5)
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .primary
            }
        }
    }
}

// MARK: - AppError Definition
/// Errores categorizados de la aplicación con mensajes user-friendly
enum AppError: Error, Identifiable, Equatable {
    case networkUnavailable
    case serverError
    case notFound
    case unauthorized
    case dataCorrupted
    case firebaseError(String)
    case cloudinaryError(String)
    case unknown(Error)

    // MARK: - Equatable
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }

    var id: String {
        switch self {
        case .networkUnavailable: return "network"
        case .serverError: return "server"
        case .notFound: return "notFound"
        case .unauthorized: return "unauthorized"
        case .dataCorrupted: return "dataCorrupted"
        case .firebaseError(let msg): return "firebase_\(msg)"
        case .cloudinaryError(let msg): return "cloudinary_\(msg)"
        case .unknown(let error): return "unknown_\(error.localizedDescription)"
        }
    }

    /// Icono SF Symbol apropiado para cada tipo de error
    var icon: String {
        switch self {
        case .networkUnavailable:
            return "wifi.slash"
        case .serverError:
            return "exclamationmark.triangle.fill"
        case .notFound:
            return "magnifyingglass"
        case .unauthorized:
            return "lock.fill"
        case .dataCorrupted:
            return "doc.badge.exclamationmark"
        case .firebaseError:
            return "flame.fill"
        case .cloudinaryError:
            return "photo.badge.exclamationmark"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    /// Color apropiado para el icono
    var color: Color {
        switch self {
        case .networkUnavailable:
            return .orange
        case .serverError, .dataCorrupted, .firebaseError, .cloudinaryError:
            return .red
        case .notFound:
            return .gray
        case .unauthorized:
            return .yellow
        case .unknown:
            return .purple
        }
    }

    /// Título breve del error
    var title: String {
        switch self {
        case .networkUnavailable:
            return "Sin Conexión"
        case .serverError:
            return "Error del Servidor"
        case .notFound:
            return "No Encontrado"
        case .unauthorized:
            return "No Autorizado"
        case .dataCorrupted:
            return "Datos Corruptos"
        case .firebaseError:
            return "Error de Firebase"
        case .cloudinaryError:
            return "Error de Imagen"
        case .unknown:
            return "Error Inesperado"
        }
    }

    /// Mensaje detallado y comprensible para el usuario
    var userFriendlyMessage: String {
        switch self {
        case .networkUnavailable:
            return "No pudimos conectar con el servidor. Verifica tu conexión a internet e intenta de nuevo."

        case .serverError:
            return "Estamos experimentando problemas técnicos. Por favor, intenta de nuevo en unos momentos."

        case .notFound:
            return "No pudimos encontrar lo que buscabas. Es posible que ya no exista o haya sido eliminado."

        case .unauthorized:
            return "No tienes permisos para acceder a este contenido. Intenta iniciar sesión de nuevo."

        case .dataCorrupted:
            return "Los datos están corruptos o incompletos. Intenta limpiar la caché en Ajustes o reinstalar la app."

        case .firebaseError(let message):
            return "Error al comunicarse con el servidor: \(translateFirebaseError(message))"

        case .cloudinaryError(let message):
            return "Error al procesar la imagen: \(message)"

        case .unknown(let error):
            return "Ocurrió un error inesperado. Si el problema persiste, contáctanos.\n\nDetalles técnicos: \(error.localizedDescription)"
        }
    }

    /// Tipo de recuperación sugerida
    var recoveryType: RecoveryType {
        switch self {
        case .networkUnavailable, .serverError:
            return .retry
        case .notFound:
            return .goBack
        case .unauthorized:
            return .login
        case .dataCorrupted:
            return .clearCache
        case .firebaseError, .cloudinaryError:
            return .retry
        case .unknown:
            return .retry
        }
    }

    enum RecoveryType {
        case retry, login, goBack, clearCache, none
    }

    // MARK: - Helpers

    /// Convierte Error genérico a AppError
    static func from(_ error: Error) -> AppError {
        // Firebase errors
        if let nsError = error as NSError?, nsError.domain.contains("Firebase") {
            return .firebaseError(nsError.localizedDescription)
        }

        // Network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                return .networkUnavailable
            default:
                return .serverError
            }
        }

        // Ya es AppError
        if let appError = error as? AppError {
            return appError
        }

        // Unknown
        return .unknown(error)
    }

    /// Traduce mensajes técnicos de Firebase a español
    private func translateFirebaseError(_ message: String) -> String {
        let lowercased = message.lowercased()

        if lowercased.contains("network") || lowercased.contains("connection") {
            return "problema de conexión"
        } else if lowercased.contains("permission") || lowercased.contains("denied") {
            return "permisos insuficientes"
        } else if lowercased.contains("not found") {
            return "documento no encontrado"
        } else if lowercased.contains("timeout") {
            return "tiempo de espera agotado"
        } else {
            return message
        }
    }
}

// MARK: - Scale Button Style
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extension para uso conveniente
extension View {
    /// Muestra ErrorView cuando hay un error
    /// - Parameters:
    ///   - error: Binding al error opcional
    ///   - retryAction: Acción de retry
    func errorOverlay(
        error: Binding<AppError?>,
        retryAction: @escaping () -> Void
    ) -> some View {
        ZStack {
            self

            if let appError = error.wrappedValue {
                ErrorView(
                    error: appError,
                    retryAction: retryAction,
                    dismissAction: {
                        error.wrappedValue = nil
                    }
                )
                .background(Color(.systemBackground))
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Previews
#Preview("Network Error") {
    ErrorView(
        error: .networkUnavailable,
        retryAction: {
            print("Retry tapped")
        },
        dismissAction: {
            print("Dismiss tapped")
        }
    )
}

#Preview("Server Error") {
    ErrorView(
        error: .serverError,
        retryAction: {
            print("Retry tapped")
        }
    )
}

#Preview("Not Found") {
    ErrorView(
        error: .notFound,
        dismissAction: {
            print("Go back")
        }
    )
}

#Preview("Unauthorized") {
    ErrorView(
        error: .unauthorized,
        retryAction: {
            print("Login again")
        }
    )
}

#Preview("Data Corrupted") {
    ErrorView(
        error: .dataCorrupted,
        retryAction: {
            print("Clear cache")
        }
    )
}

#Preview("Firebase Error") {
    ErrorView(
        error: .firebaseError("Permission denied: User does not have access"),
        retryAction: {
            print("Retry")
        }
    )
}

#Preview("Unknown Error") {
    let unknownError = NSError(
        domain: "com.perfbeta",
        code: 999,
        userInfo: [NSLocalizedDescriptionKey: "Something went wrong internally"]
    )

    return ErrorView(
        error: .unknown(unknownError),
        retryAction: {
            print("Retry")
        }
    )
}

#Preview("Interactive Demo") {
    struct ErrorDemo: View {
        @State private var currentError: AppError? = nil

        let errors: [AppError] = [
            .networkUnavailable,
            .serverError,
            .notFound,
            .unauthorized,
            .dataCorrupted
        ]

        var body: some View {
            VStack(spacing: 16) {
                Text("Tap para ver diferentes errores:")
                    .font(.headline)

                ForEach(errors, id: \.id) { error in
                    Button(error.title) {
                        currentError = error
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .errorOverlay(error: $currentError) {
                print("Retry action for: \(currentError?.title ?? "unknown")")
                // Simular retry exitoso después de 1 segundo
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    currentError = nil
                }
            }
        }
    }

    return ErrorDemo()
}
