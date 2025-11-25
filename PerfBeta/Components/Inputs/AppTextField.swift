//
//  AppTextField.swift
//  PerfBeta
//
//  Componente de campo de texto unificado con soporte para:
//  - Iconos leading/trailing
//  - Estados: normal, focus, error, disabled
//  - Campos seguros (password)
//  - Validación visual
//

import SwiftUI

// MARK: - AppTextField

struct AppTextField: View {

    // MARK: - Properties

    let placeholder: String
    @Binding var text: String

    var icon: String? = nil
    var iconPosition: IconPosition = .leading
    var isSecure: Bool = false
    var isDisabled: Bool = false
    var errorMessage: String? = nil
    var helpText: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrectionDisabled: Bool = false

    // MARK: - State

    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false

    // MARK: - Computed Properties

    private var hasError: Bool {
        errorMessage != nil
    }

    private var borderColor: Color {
        if hasError {
            return AppColor.feedbackError
        } else if isFocused {
            return AppColor.borderFocus
        } else {
            return AppColor.borderPrimary
        }
    }

    private var backgroundColor: Color {
        if isDisabled {
            return AppColor.backgroundSecondary
        } else {
            return AppColor.surfacePrimary
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing4) {
            // Input Field
            HStack(spacing: AppSpacing.spacing12) {
                // Leading icon
                if let icon = icon, iconPosition == .leading {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(hasError ? AppColor.feedbackError : AppColor.iconSecondary)
                        .frame(width: 20)
                }

                // Text Field
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(AppTypography.bodyLarge)
                .foregroundColor(isDisabled ? AppColor.textDisabled : AppColor.textPrimary)
                .focused($isFocused)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
                .disabled(isDisabled)

                // Trailing icon or password toggle
                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 16))
                            .foregroundColor(AppColor.iconSecondary)
                    }
                    .buttonStyle(.plain)
                } else if let icon = icon, iconPosition == .trailing {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(hasError ? AppColor.feedbackError : AppColor.iconSecondary)
                        .frame(width: 20)
                }
            }
            .padding(.horizontal, AppSpacing.spacing16)
            .padding(.vertical, AppSpacing.spacing12)
            .background(backgroundColor)
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(borderColor, lineWidth: isFocused || hasError ? 2 : 1)
            )

            // Error or Help text
            if let errorMessage = errorMessage {
                HStack(spacing: AppSpacing.spacing4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(AppTypography.caption)
                }
                .foregroundColor(AppColor.feedbackError)
            } else if let helpText = helpText {
                Text(helpText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.textTertiary)
            }
        }
    }

    // MARK: - Icon Position

    enum IconPosition {
        case leading
        case trailing
    }
}

// MARK: - Convenience Initializers

extension AppTextField {

    /// Campo de email
    static func email(
        placeholder: String = "Email",
        text: Binding<String>,
        errorMessage: String? = nil
    ) -> AppTextField {
        AppTextField(
            placeholder: placeholder,
            text: text,
            icon: "envelope",
            iconPosition: .leading,
            errorMessage: errorMessage,
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            autocapitalization: .never,
            autocorrectionDisabled: true
        )
    }

    /// Campo de password
    static func password(
        placeholder: String = "Contrasena",
        text: Binding<String>,
        errorMessage: String? = nil
    ) -> AppTextField {
        AppTextField(
            placeholder: placeholder,
            text: text,
            icon: "lock",
            iconPosition: .leading,
            isSecure: true,
            errorMessage: errorMessage,
            textContentType: .password,
            autocapitalization: .never,
            autocorrectionDisabled: true
        )
    }

    /// Campo de busqueda
    static func search(
        placeholder: String = "Buscar...",
        text: Binding<String>
    ) -> AppTextField {
        AppTextField(
            placeholder: placeholder,
            text: text,
            icon: "magnifyingglass",
            iconPosition: .leading,
            keyboardType: .default,
            autocapitalization: .never
        )
    }
}

// MARK: - Preview

#Preview("AppTextField States") {
    VStack(spacing: 20) {
        AppTextField(
            placeholder: "Normal field",
            text: .constant("")
        )

        AppTextField(
            placeholder: "With icon",
            text: .constant("Hello"),
            icon: "person"
        )

        AppTextField.email(
            text: .constant("test@example.com")
        )

        AppTextField.password(
            text: .constant("password123")
        )

        AppTextField(
            placeholder: "With error",
            text: .constant("Invalid"),
            icon: "envelope",
            errorMessage: "Email invalido"
        )

        AppTextField(
            placeholder: "Disabled",
            text: .constant("Cannot edit"),
            isDisabled: true
        )

        AppTextField(
            placeholder: "With help text",
            text: .constant(""),
            helpText: "Introduce tu nombre completo"
        )
    }
    .padding()
}
