import SwiftUI

/// Fila individual para Settings - Componente reutilizable
/// Siguiendo diseño de iOS Settings con soporte para diferentes tipos de contenido
struct SettingsRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let value: String?
    let showChevron: Bool
    let action: (() -> Void)?

    init(
        icon: String,
        iconColor: Color = AppColor.iconPrimary,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        showChevron: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.showChevron = showChevron
        self.action = action
    }

    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: AppSpacing.spacing12) {
                // Icon Container
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }

                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColor.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColor.textTertiary)
                    }
                }

                Spacer()

                // Value or Chevron
                HStack(spacing: 6) {
                    if let value = value {
                        Text(value)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColor.textSecondary)
                    }

                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.textTertiary)
                    }
                }
            }
            .padding(.vertical, AppSpacing.spacing12)
            .padding(.horizontal, AppSpacing.spacing16)
            .background(AppColor.surfaceCard)
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(SettingsRowButtonStyle())
        .disabled(action == nil)
    }
}

/// Button Style para Settings Row con feedback visual sutil
struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppTransition.fast, value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GradientView(preset: .champan)
            .ignoresSafeArea()

        VStack(spacing: 12) {
            SettingsRowView(
                icon: "person.fill",
                iconColor: .blue,
                title: "Editar Perfil",
                subtitle: "Nombre, email y foto",
                action: {}
            )

            SettingsRowView(
                icon: "lock.fill",
                iconColor: .orange,
                title: "Cambiar Contraseña",
                action: {}
            )

            SettingsRowView(
                icon: "info.circle.fill",
                iconColor: .gray,
                title: "Versión",
                value: "1.0.0",
                showChevron: false,
                action: nil
            )

            SettingsRowView(
                icon: "trash.fill",
                iconColor: .red,
                title: "Limpiar Caché",
                subtitle: "Libera espacio en tu dispositivo",
                value: "2.3 MB",
                action: {}
            )
        }
        .padding()
    }
}
