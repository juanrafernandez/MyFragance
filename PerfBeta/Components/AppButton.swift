import SwiftUI

// MARK: - AppButton Style Enum
enum AppButtonStyle {
    case primary
    case secondary
    case tertiary
    case accent
    case destructive

    var backgroundColor: Color {
        switch self {
        case .primary:
            return AppColor.interactivePrimary
        case .secondary:
            return AppColor.interactiveSecondary
        case .tertiary:
            return .clear
        case .accent:
            return AppColor.brandAccent
        case .destructive:
            return AppColor.feedbackError
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary:
            return AppColor.textInverse
        case .secondary:
            return AppColor.textPrimary
        case .tertiary:
            return AppColor.brandAccent
        case .accent:
            return AppColor.textOnAccent
        case .destructive:
            return .white
        }
    }

    var borderColor: Color? {
        switch self {
        case .primary, .accent, .destructive:
            return nil
        case .secondary:
            return AppColor.borderPrimary
        case .tertiary:
            return nil
        }
    }

    var shadow: AppShadow? {
        switch self {
        case .primary, .accent:
            return AppShadow.small
        case .secondary, .tertiary, .destructive:
            return nil
        }
    }
}

// MARK: - AppButton Size Enum
enum AppButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small:
            return 36
        case .medium:
            return 44
        case .large:
            return 52
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small:
            return AppSpacing.spacing12
        case .medium:
            return AppSpacing.spacing16
        case .large:
            return AppSpacing.spacing20
        }
    }

    var font: Font {
        switch self {
        case .small:
            return AppTypography.labelSmall
        case .medium:
            return AppTypography.labelMedium
        case .large:
            return AppTypography.labelLarge
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 20
        }
    }
}

// MARK: - AppButton Component
struct AppButton: View {
    // Required parameters
    let title: String
    let action: () -> Void

    // Customization parameters
    var style: AppButtonStyle = .primary
    var size: AppButtonSize = .medium
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var isFullWidth: Bool = false
    var icon: String? = nil
    var iconPosition: IconPosition = .leading

    enum IconPosition {
        case leading
        case trailing
    }

    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                action()
            }
        }) {
            HStack(spacing: AppSpacing.spacing8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(size == .small ? 0.8 : 1.0)
                } else {
                    if let icon = icon, iconPosition == .leading {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize))
                    }

                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)

                    if let icon = icon, iconPosition == .trailing {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize))
                    }
                }
            }
            .foregroundColor(isDisabled ? AppColor.textDisabled : style.foregroundColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(isDisabled ? AppColor.interactiveDisabled : style.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(style.borderColor ?? .clear, lineWidth: 1)
            )
            .if(style.shadow != nil && !isDisabled) { view in
                view.shadow(style.shadow!)
            }
            .opacity(isDisabled ? 0.6 : 1.0)
            .animation(AppTransition.standard, value: isLoading)
            .animation(AppTransition.standard, value: isDisabled)
        }
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - View Extension for Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview Provider
struct AppButton_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: AppSpacing.spacing24) {
                // MARK: - Styles Section
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Button Styles")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(AppColor.textPrimary)

                    VStack(spacing: AppSpacing.spacing12) {
                        AppButton(title: "Primary Button", action: {}, style: .primary)
                        AppButton(title: "Secondary Button", action: {}, style: .secondary)
                        AppButton(title: "Tertiary Button", action: {}, style: .tertiary)
                        AppButton(title: "Accent Button", action: {}, style: .accent)
                        AppButton(title: "Destructive Button", action: {}, style: .destructive)
                    }
                }

                Divider()

                // MARK: - Sizes Section
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Button Sizes")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(AppColor.textPrimary)

                    VStack(spacing: AppSpacing.spacing12) {
                        AppButton(title: "Small Button", action: {}, size: .small)
                        AppButton(title: "Medium Button", action: {}, size: .medium)
                        AppButton(title: "Large Button", action: {}, size: .large)
                    }
                }

                Divider()

                // MARK: - States Section
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Button States")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(AppColor.textPrimary)

                    VStack(spacing: AppSpacing.spacing12) {
                        AppButton(title: "Normal State", action: {})
                        AppButton(title: "Loading State", action: {}, isLoading: true)
                        AppButton(title: "Disabled State", action: {}, isDisabled: true)
                    }
                }

                Divider()

                // MARK: - With Icons Section
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Buttons with Icons")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(AppColor.textPrimary)

                    VStack(spacing: AppSpacing.spacing12) {
                        AppButton(title: "Leading Icon", action: {}, icon: "arrow.right", iconPosition: .leading)
                        AppButton(title: "Trailing Icon", action: {}, icon: "arrow.right", iconPosition: .trailing)
                        AppButton(title: "Heart Icon", action: {}, style: .accent, icon: "heart.fill")
                        AppButton(title: "Delete", action: {}, style: .destructive, icon: "trash")
                    }
                }

                Divider()

                // MARK: - Full Width Section
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Full Width Buttons")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(AppColor.textPrimary)

                    VStack(spacing: AppSpacing.spacing12) {
                        AppButton(title: "Full Width Primary", action: {}, style: .primary, isFullWidth: true)
                        AppButton(title: "Full Width Secondary", action: {}, style: .secondary, isFullWidth: true)
                        AppButton(title: "Full Width with Icon", action: {}, style: .accent, isFullWidth: true, icon: "checkmark.circle.fill")
                    }
                }

                Divider()

                // MARK: - Size Combinations Section
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Size & Style Combinations")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(AppColor.textPrimary)

                    VStack(spacing: AppSpacing.spacing12) {
                        AppButton(title: "Small Primary", action: {}, style: .primary, size: .small)
                        AppButton(title: "Medium Secondary", action: {}, style: .secondary, size: .medium)
                        AppButton(title: "Large Accent", action: {}, style: .accent, size: .large)
                    }
                }

                Divider()

                // MARK: - Real Use Cases Section
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Real Use Cases")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(AppColor.textPrimary)

                    VStack(spacing: AppSpacing.spacing12) {
                        // Login button
                        AppButton(
                            title: "Iniciar Sesión",
                            action: {},
                            style: .primary,
                            size: .large,
                            isFullWidth: true
                        )

                        // Google login
                        AppButton(
                            title: "Continuar con Google",
                            action: {},
                            style: .secondary,
                            size: .large,
                            isFullWidth: true,
                            icon: "g.circle.fill"
                        )

                        // Save profile
                        AppButton(
                            title: "Guardar Perfil",
                            action: {},
                            style: .accent,
                            size: .medium,
                            icon: "checkmark"
                        )

                        // Delete account
                        AppButton(
                            title: "Eliminar Cuenta",
                            action: {},
                            style: .destructive,
                            size: .medium,
                            icon: "trash",
                            iconPosition: .leading
                        )

                        // Loading state example
                        AppButton(
                            title: "Guardando...",
                            action: {},
                            style: .primary,
                            size: .large,
                            isLoading: true,
                            isFullWidth: true
                        )
                    }
                }
            }
            .padding(AppSpacing.spacing20)
        }
        .background(AppColor.backgroundPrimary)
        .previewDisplayName("AppButton Showcase")
        .previewLayout(.sizeThatFits)
    }
}
