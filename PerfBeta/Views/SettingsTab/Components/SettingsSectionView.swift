import SwiftUI

/// Sección de Settings con título y contenido
/// Agrupa filas relacionadas con un encabezado opcional
struct SettingsSectionView<Content: View>: View {
    let title: String?
    let footer: String?
    let content: Content

    init(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
            // Section Title
            if let title = title {
                Text(title)
                    .font(AppTypography.captionEmphasis)
                    .foregroundColor(AppColor.textSecondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .padding(.horizontal, AppSpacing.spacing4)
                    .padding(.bottom, AppSpacing.spacing4)
            }

            // Section Content
            VStack(spacing: AppSpacing.spacing8) {
                content
            }

            // Section Footer
            if let footer = footer {
                Text(footer)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.textTertiary)
                    .padding(.horizontal, AppSpacing.spacing4)
                    .padding(.top, AppSpacing.spacing4)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GradientView(preset: .champan)
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: AppSpacing.spacing24) {
                SettingsSectionView(
                    title: "Mi Cuenta",
                    footer: "Gestiona tu información personal y seguridad"
                ) {
                    SettingsRowView(
                        icon: "person.fill",
                        iconColor: .blue,
                        title: "Editar Perfil",
                        action: {}
                    )

                    SettingsRowView(
                        icon: "lock.fill",
                        iconColor: .orange,
                        title: "Cambiar Contraseña",
                        action: {}
                    )

                    SettingsRowView(
                        icon: "arrow.right.square.fill",
                        iconColor: .red,
                        title: "Cerrar Sesión",
                        action: {}
                    )
                }

                SettingsSectionView(title: "Información") {
                    SettingsRowView(
                        icon: "info.circle.fill",
                        iconColor: .gray,
                        title: "Versión",
                        value: "1.0.0",
                        showChevron: false,
                        action: nil
                    )
                }
            }
            .padding()
        }
    }
}
