//
//  AppBadge.swift
//  PerfBeta
//
//  Componente de badge/tag unificado con estilos predefinidos
//  para indicadores, etiquetas y estados.
//

import SwiftUI

// MARK: - AppBadge

struct AppBadge: View {

    // MARK: - Properties

    let text: String
    var style: BadgeStyle = .neutral
    var size: BadgeSize = .medium
    var icon: String? = nil

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.spacing4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
            }

            Text(text)
                .font(font)
                .lineLimit(1)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .foregroundColor(foregroundColor)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: hasBorder ? 1 : 0)
        )
    }

    // MARK: - Computed Properties

    private var font: Font {
        switch size {
        case .small:
            return AppTypography.overline
        case .medium:
            return AppTypography.labelSmall
        case .large:
            return AppTypography.labelMedium
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return AppSpacing.spacing4
        case .medium: return AppSpacing.spacing8
        case .large: return AppSpacing.spacing12
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return AppSpacing.spacing2
        case .medium: return AppSpacing.spacing4
        case .large: return AppSpacing.spacing8
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return AppCornerRadius.small / 2
        case .medium: return AppCornerRadius.small
        case .large: return AppCornerRadius.medium
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .neutral:
            return AppColor.textSecondary
        case .accent:
            return AppColor.textOnAccent
        case .success:
            return AppColor.feedbackSuccess
        case .warning:
            return AppColor.feedbackWarning
        case .error:
            return AppColor.feedbackError
        case .info:
            return AppColor.feedbackInfo
        case .outline:
            return AppColor.textPrimary
        case .gold:
            return AppColor.accentGoldDark
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .neutral:
            return AppColor.backgroundSecondary
        case .accent:
            return AppColor.brandAccent
        case .success:
            return AppColor.feedbackSuccessBackground
        case .warning:
            return AppColor.badgeWarning.opacity(0.15)
        case .error:
            return AppColor.feedbackErrorBackground
        case .info:
            return AppColor.badgeInfo.opacity(0.15)
        case .outline:
            return Color.clear
        case .gold:
            return AppColor.brandAccent.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch style {
        case .outline:
            return AppColor.borderPrimary
        case .gold:
            return AppColor.brandAccent.opacity(0.3)
        default:
            return Color.clear
        }
    }

    private var hasBorder: Bool {
        style == .outline || style == .gold
    }

    // MARK: - Badge Style

    enum BadgeStyle {
        case neutral    // Gris neutro
        case accent     // Color de marca (dorado)
        case success    // Verde
        case warning    // Amarillo/Ambar
        case error      // Rojo
        case info       // Azul
        case outline    // Solo borde
        case gold       // Dorado sutil
    }

    // MARK: - Badge Size

    enum BadgeSize {
        case small
        case medium
        case large
    }
}

// MARK: - Convenience Initializers

extension AppBadge {

    /// Badge de familia olfativa
    static func family(_ name: String) -> AppBadge {
        AppBadge(text: name, style: .gold, size: .medium)
    }

    /// Badge de genero
    static func gender(_ gender: String) -> AppBadge {
        AppBadge(text: gender, style: .neutral, size: .small, icon: "person.fill")
    }

    /// Badge de nuevo
    static func new() -> AppBadge {
        AppBadge(text: "NUEVO", style: .accent, size: .small, icon: "sparkles")
    }

    /// Badge de favorito
    static func favorite() -> AppBadge {
        AppBadge(text: "Favorito", style: .gold, size: .small, icon: "heart.fill")
    }

    /// Badge de intensidad
    static func intensity(_ level: String) -> AppBadge {
        AppBadge(text: level, style: .outline, size: .small)
    }

    /// Badge de match percentage
    static func match(_ percentage: Int) -> AppBadge {
        let style: BadgeStyle = percentage >= 80 ? .success : percentage >= 60 ? .gold : .neutral
        return AppBadge(text: "\(percentage)% Match", style: style, size: .medium, icon: "checkmark.circle.fill")
    }
}

// MARK: - Preview

#Preview("AppBadge Styles") {
    VStack(spacing: 16) {
        Text("Estilos").font(.headline)

        HStack(spacing: 8) {
            AppBadge(text: "Neutral", style: .neutral)
            AppBadge(text: "Accent", style: .accent)
            AppBadge(text: "Success", style: .success)
        }

        HStack(spacing: 8) {
            AppBadge(text: "Warning", style: .warning)
            AppBadge(text: "Error", style: .error)
            AppBadge(text: "Info", style: .info)
        }

        HStack(spacing: 8) {
            AppBadge(text: "Outline", style: .outline)
            AppBadge(text: "Gold", style: .gold)
        }

        Divider()

        Text("Tamanos").font(.headline)

        HStack(spacing: 8) {
            AppBadge(text: "Small", style: .accent, size: .small)
            AppBadge(text: "Medium", style: .accent, size: .medium)
            AppBadge(text: "Large", style: .accent, size: .large)
        }

        Divider()

        Text("Con iconos").font(.headline)

        HStack(spacing: 8) {
            AppBadge(text: "Email", style: .info, icon: "envelope.fill")
            AppBadge(text: "Verified", style: .success, icon: "checkmark.seal.fill")
        }

        Divider()

        Text("Presets").font(.headline)

        HStack(spacing: 8) {
            AppBadge.new()
            AppBadge.favorite()
            AppBadge.match(85)
        }

        HStack(spacing: 8) {
            AppBadge.family("Amaderado")
            AppBadge.gender("Unisex")
            AppBadge.intensity("Intensa")
        }
    }
    .padding()
}
