import SwiftUI

/// Header de perfil de usuario en Settings
/// Muestra avatar, nombre, email y estadísticas clave
struct SettingsHeaderView: View {
    let userName: String
    let userEmail: String
    let triedCount: Int
    let wishlistCount: Int
    let profilesCount: Int
    let onEditProfile: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.spacing20) {
            // Avatar + Info
            HStack(spacing: AppSpacing.spacing16) {
                // Avatar Circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColor.brandAccent.opacity(0.3),
                                    AppColor.brandAccent.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Text(userName.prefix(1).uppercased())
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppColor.brandAccent)
                }

                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(AppTypography.titleLarge)
                        .foregroundColor(AppColor.textPrimary)

                    Text(userEmail)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColor.textSecondary)

                    // Edit Profile Button
                    Button(action: onEditProfile) {
                        HStack(spacing: 4) {
                            Text("Editar Perfil")
                                .font(AppTypography.labelSmall)
                                .foregroundColor(AppColor.brandAccent)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppColor.brandAccent)
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer()
            }

            // Stats Cards
            HStack(spacing: AppSpacing.spacing12) {
                StatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(triedCount)",
                    label: "Probados",
                    color: .green
                )

                StatCard(
                    icon: "heart.fill",
                    value: "\(wishlistCount)",
                    label: "Wishlist",
                    color: .pink
                )

                StatCard(
                    icon: "sparkles",
                    value: "\(profilesCount)",
                    label: "Perfiles",
                    color: AppColor.brandAccent
                )
            }
        }
        .padding(AppSpacing.spacing20)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(AppColor.surfaceCard)
                .shadow(.medium)
        )
    }
}

/// Tarjeta de estadística individual
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.spacing8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColor.textPrimary)

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.spacing12)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GradientView(preset: .champan)
            .ignoresSafeArea()

        SettingsHeaderView(
            userName: "Juan Fernández",
            userEmail: "juan@email.com",
            triedCount: 12,
            wishlistCount: 8,
            profilesCount: 3,
            onEditProfile: {}
        )
        .padding()
    }
}
