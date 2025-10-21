//
//  DesignTokens.swift
//  PerfBeta
//
//  Design System - Tokens centralizados para colores, tipografía, spacing, etc.
//  Opción A: Degradado Champán Refinado
//

import SwiftUI

// MARK: - Color Tokens

enum AppColor {

    // MARK: - Brand Colors (Identidad)

    /// Negro elegante - Color primario de marca
    static let brandPrimary = Color("brandPrimary")

    /// Dorado champagne - Color de acento
    static let brandAccent = Color("brandAccent")

    /// Dorado claro - Variante clara del acento
    static let brandAccentLight = Color("brandAccentLight")

    // MARK: - Background Colors

    /// Fondo principal (blanco en light, negro en dark)
    static let backgroundPrimary = Color("backgroundPrimary")

    /// Fondo secundario (beige muy claro en light, gris oscuro en dark)
    static let backgroundSecondary = Color("backgroundSecondary")

    /// Fondo terciario (beige claro)
    static let backgroundTertiary = Color("backgroundTertiary")

    /// Fondo elevado (con sombra)
    static let backgroundElevated = Color("backgroundElevated")

    // MARK: - Surface Colors (Cards, Modals)

    /// Superficie primaria (cards principales)
    static let surfacePrimary = Color("surfacePrimary")

    /// Superficie secundaria (cards secundarias)
    static let surfaceSecondary = Color("surfaceSecondary")

    /// Superficie elevada (modals, popovers)
    static let surfaceElevated = Color("surfaceElevated")

    /// Superficie para cards
    static let surfaceCard = Color("surfaceCard")

    /// Overlay oscuro para modals
    static let surfaceOverlay = Color("surfaceOverlay")

    // MARK: - Text Colors

    /// Texto principal (negro en light, beige en dark)
    static let textPrimary = Color("textPrimary")

    /// Texto secundario (gris oscuro)
    static let textSecondary = Color("textSecondary")

    /// Texto terciario (gris medio)
    static let textTertiary = Color("textTertiary")

    /// Texto deshabilitado (gris claro)
    static let textDisabled = Color("textDisabled")

    /// Texto sobre fondos oscuros/botones primarios (blanco)
    static let textInverse = Color("textInverse")

    /// Texto sobre color de acento
    static let textOnAccent = Color("textOnAccent")

    // MARK: - Interactive Colors (Botones, Links)

    /// Color interactivo primario (botones principales)
    static let interactivePrimary = Color("interactivePrimary")

    /// Color interactivo secundario (botones secundarios)
    static let interactiveSecondary = Color("interactiveSecondary")

    /// Color interactivo terciario
    static let interactiveTertiary = Color("interactiveTertiary")

    /// Estado hover
    static let interactiveHover = Color("interactiveHover")

    /// Estado focus
    static let interactiveFocus = Color("interactiveFocus")

    /// Estado pressed
    static let interactivePressed = Color("interactivePressed")

    /// Estado disabled
    static let interactiveDisabled = Color("interactiveDisabled")

    // MARK: - Accent Colors (Gold variations)

    /// Acento dorado principal
    static let accentGold = Color("accentGold")

    /// Acento dorado claro
    static let accentGoldLight = Color("accentGoldLight")

    /// Acento dorado oscuro
    static let accentGoldDark = Color("accentGoldDark")

    // MARK: - Feedback Colors

    /// Color de éxito (verde oliva)
    static let feedbackSuccess = Color("feedbackSuccess")

    /// Color de error (rojo oscuro)
    static let feedbackError = Color("feedbackError")

    /// Color de advertencia (ámbar)
    static let feedbackWarning = Color("feedbackWarning")

    /// Color de información (azul grisáceo)
    static let feedbackInfo = Color("feedbackInfo")

    /// Fondo de éxito (verde muy claro)
    static let feedbackSuccessBackground = Color("feedbackSuccessBackground")

    /// Fondo de error (rojo muy claro)
    static let feedbackErrorBackground = Color("feedbackErrorBackground")

    // MARK: - Border & Divider Colors

    /// Borde primario (gris claro)
    static let borderPrimary = Color("borderPrimary")

    /// Borde secundario (beige)
    static let borderSecondary = Color("borderSecondary")

    /// Borde con focus (dorado)
    static let borderFocus = Color("borderFocus")

    /// Divisor (líneas separadoras)
    static let dividerPrimary = Color("dividerPrimary")

    // MARK: - Icon Colors

    /// Icono primario (negro)
    static let iconPrimary = Color("iconPrimary")

    /// Icono secundario (gris)
    static let iconSecondary = Color("iconSecondary")

    /// Icono terciario (gris claro)
    static let iconTertiary = Color("iconTertiary")

    /// Icono con acento (dorado)
    static let iconAccent = Color("iconAccent")

    // MARK: - Rating & Badge Colors

    /// Color de relleno para ratings (dorado)
    static let ratingFill = Color("ratingFill")

    /// Badge de éxito
    static let badgeSuccess = Color("badgeSuccess")

    /// Badge de advertencia
    static let badgeWarning = Color("badgeWarning")

    /// Badge de información
    static let badgeInfo = Color("badgeInfo")
}

// MARK: - Opacity Helpers

extension Color {
    /// Aplica una opacidad estandarizada
    func opacity(_ value: AppOpacity) -> Color {
        return self.opacity(value.rawValue)
    }
}

enum AppOpacity: Double {
    case subtle = 0.04      // Hover muy sutil
    case light = 0.08       // Hover light
    case medium = 0.12      // Pressed
    case strong = 0.16      // Disabled backgrounds
    case overlay = 0.40     // Modal overlays
    case semitransparent = 0.60
    case almostOpaque = 0.92
}

// MARK: - Gradient Tokens
// Note: Color(hex:) initializer is defined in UIColorExtension.swift

enum AppGradient {

    /// Degradado de marca único - Opción A: Champán Refinado
    /// Colores: Champán oscuro → Champán → Beige cálido → Blanco
    static let brandGradient = LinearGradient(
        colors: [
            Color(hex: "8B7355"),  // Champán oscuro/marrón cálido
            Color(hex: "C4A962"),  // Champán (color actual)
            Color(hex: "E8DCC8"),  // Beige cálido
            Color(hex: "FFFFFF")   // Blanco
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Locations para controlar la distribución del degradado
    static let brandGradientStops: [Gradient.Stop] = [
        .init(color: Color(hex: "8B7355"), location: 0.0),
        .init(color: Color(hex: "C4A962"), location: 0.25),
        .init(color: Color(hex: "E8DCC8"), location: 0.55),
        .init(color: Color(hex: "FFFFFF"), location: 0.85)
    ]

    /// Degradado sutil para headers (opcional)
    static let headerSubtle = LinearGradient(
        colors: [
            AppColor.backgroundSecondary,
            AppColor.backgroundPrimary
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Overlay oscuro para imágenes
    static let imageOverlay = LinearGradient(
        colors: [
            Color.black.opacity(0.6),
            Color.black.opacity(0.0)
        ],
        startPoint: .bottom,
        endPoint: .center
    )

    /// Badge gradient (dorado sutil)
    static let badgeGold = LinearGradient(
        colors: [
            AppColor.brandAccent,
            AppColor.brandAccentLight
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography Tokens

enum AppTypography {

    // MARK: - Display (Para screens de bienvenida, onboarding)

    /// Display Large - Para splash screens, headers principales
    static let displayLarge = Font.custom("PlayfairDisplay-Regular", size: 57)

    /// Display Medium - Para títulos grandes
    static let displayMedium = Font.custom("PlayfairDisplay-Regular", size: 45)

    /// Display Small - Para subtítulos grandes
    static let displaySmall = Font.custom("PlayfairDisplay-Regular", size: 36)

    // MARK: - Headlines (Títulos de secciones)

    /// Headline Large - Títulos de pantallas principales
    static let headlineLarge = Font.system(size: 32, weight: .light, design: .default)

    /// Headline Medium - Títulos de secciones
    static let headlineMedium = Font.system(size: 28, weight: .regular, design: .default)

    /// Headline Small - Subtítulos de secciones
    static let headlineSmall = Font.system(size: 24, weight: .regular, design: .default)

    // MARK: - Titles (Títulos de cards, items)

    /// Title Large - Títulos de cards grandes
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)

    /// Title Medium - Títulos de cards medianos
    static let titleMedium = Font.system(size: 18, weight: .semibold, design: .default)

    /// Title Small - Títulos de cards pequeños
    static let titleSmall = Font.system(size: 16, weight: .semibold, design: .default)

    // MARK: - Body (Contenido principal)

    /// Body Large - Texto principal grande
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)

    /// Body Medium - Texto principal mediano
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)

    /// Body Small - Texto principal pequeño
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    /// Body Medium Bold - Énfasis en texto
    static let bodyMediumBold = Font.system(size: 14, weight: .semibold, design: .default)

    // MARK: - Label (Botones, tabs, labels)

    /// Label Large - Botones grandes
    static let labelLarge = Font.system(size: 16, weight: .medium, design: .default)

    /// Label Medium - Botones medianos
    static let labelMedium = Font.system(size: 14, weight: .medium, design: .default)

    /// Label Small - Botones pequeños, tabs
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)

    // MARK: - Caption (Texto secundario, metadatos)

    /// Caption - Texto secundario, metadatos
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Caption Emphasis - Caption con énfasis
    static let captionEmphasis = Font.system(size: 12, weight: .medium, design: .default)

    // MARK: - Overline (Labels, categorías pequeñas)

    /// Overline - Labels pequeños en mayúsculas
    static let overline = Font.system(size: 10, weight: .semibold, design: .default)
}

// MARK: - Text Modifiers (Para aplicar estilos completos)

extension Text {

    // MARK: - Display

    func displayLarge() -> some View {
        self.font(AppTypography.displayLarge)
            .foregroundColor(AppColor.textPrimary)
            .lineSpacing(4)
    }

    func displayMedium() -> some View {
        self.font(AppTypography.displayMedium)
            .foregroundColor(AppColor.textPrimary)
            .lineSpacing(2)
    }

    func displaySmall() -> some View {
        self.font(AppTypography.displaySmall)
            .foregroundColor(AppColor.textPrimary)
    }

    // MARK: - Headlines

    func headlineLarge() -> some View {
        self.font(AppTypography.headlineLarge)
            .foregroundColor(AppColor.textPrimary)
            .lineSpacing(2)
    }

    func headlineMedium() -> some View {
        self.font(AppTypography.headlineMedium)
            .foregroundColor(AppColor.textPrimary)
    }

    func headlineSmall() -> some View {
        self.font(AppTypography.headlineSmall)
            .foregroundColor(AppColor.textPrimary)
    }

    // MARK: - Titles

    func titleLarge() -> some View {
        self.font(AppTypography.titleLarge)
            .foregroundColor(AppColor.textPrimary)
    }

    func titleMedium() -> some View {
        self.font(AppTypography.titleMedium)
            .foregroundColor(AppColor.textPrimary)
    }

    func titleSmall() -> some View {
        self.font(AppTypography.titleSmall)
            .foregroundColor(AppColor.textPrimary)
    }

    // MARK: - Body

    func bodyLarge() -> some View {
        self.font(AppTypography.bodyLarge)
            .foregroundColor(AppColor.textPrimary)
            .lineSpacing(4)
    }

    func bodyMedium() -> some View {
        self.font(AppTypography.bodyMedium)
            .foregroundColor(AppColor.textPrimary)
            .lineSpacing(2)
    }

    func bodySmall() -> some View {
        self.font(AppTypography.bodySmall)
            .foregroundColor(AppColor.textSecondary)
    }

    // MARK: - Labels

    func labelLarge() -> some View {
        self.font(AppTypography.labelLarge)
            .foregroundColor(AppColor.textPrimary)
    }

    func labelMedium() -> some View {
        self.font(AppTypography.labelMedium)
            .foregroundColor(AppColor.textPrimary)
    }

    func labelSmall() -> some View {
        self.font(AppTypography.labelSmall)
            .foregroundColor(AppColor.textSecondary)
    }

    // MARK: - Caption

    func caption() -> some View {
        self.font(AppTypography.caption)
            .foregroundColor(AppColor.textTertiary)
    }

    func captionEmphasis() -> some View {
        self.font(AppTypography.captionEmphasis)
            .foregroundColor(AppColor.textSecondary)
    }

    // MARK: - Overline

    func overline() -> some View {
        self.font(AppTypography.overline)
            .foregroundColor(AppColor.textTertiary)
            .kerning(0.5) // Letter spacing para mayúsculas
            .textCase(.uppercase)
    }
}

// MARK: - Spacing Tokens

enum AppSpacing {

    // Base 8pt grid
    static let spacing0: CGFloat = 0
    static let spacing2: CGFloat = 2    // Micro (line spacing)
    static let spacing4: CGFloat = 4    // XXS (badges, tags)
    static let spacing8: CGFloat = 8    // XS (padding denso)
    static let spacing12: CGFloat = 12  // S (padding normal)
    static let spacing16: CGFloat = 16  // M (padding cómodo)
    static let spacing20: CGFloat = 20  // L (secciones)
    static let spacing24: CGFloat = 24  // XL (espaciado generoso)
    static let spacing32: CGFloat = 32  // 2XL (separación secciones)
    static let spacing40: CGFloat = 40  // 3XL (mucho aire)
    static let spacing48: CGFloat = 48  // 4XL (headers)
    static let spacing64: CGFloat = 64  // 5XL (top padding screens)
}

// MARK: - Corner Radius Tokens

enum AppCornerRadius {
    static let none: CGFloat = 0
    static let small: CGFloat = 8    // Botones pequeños, badges
    static let medium: CGFloat = 12  // Cards, inputs
    static let large: CGFloat = 16   // Modals, bottom sheets
    static let extraLarge: CGFloat = 24 // Pantallas completas
    static let full: CGFloat = 9999  // Círculos (capsule)
}

// MARK: - Shadow Tokens

struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    // Predefined shadows (elevaciones)
    static let none = AppShadow(color: .clear, radius: 0, x: 0, y: 0)

    static let small = AppShadow(
        color: Color.black.opacity(0.08),
        radius: 4,
        x: 0,
        y: 2
    )

    static let medium = AppShadow(
        color: Color.black.opacity(0.12),
        radius: 8,
        x: 0,
        y: 4
    )

    static let large = AppShadow(
        color: Color.black.opacity(0.16),
        radius: 16,
        x: 0,
        y: 8
    )

    static let elevated = AppShadow(
        color: Color.black.opacity(0.20),
        radius: 24,
        x: 0,
        y: 12
    )

    // Alias para compatibilidad
    static let elevation1 = small
    static let elevation2 = medium
    static let elevation3 = large
}

// MARK: - View Extension para aplicar shadows

extension View {
    /// Aplica una sombra estandarizada
    func shadow(_ shadow: AppShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

// MARK: - Transition Tokens

enum AppTransition {
    static let fast: Animation = .easeInOut(duration: 0.2)
    static let standard: Animation = .easeInOut(duration: 0.3)
    static let slow: Animation = .easeInOut(duration: 0.5)
    static let spring: Animation = .spring(response: 0.3, dampingFraction: 0.7)
    static let springBouncy: Animation = .spring(response: 0.4, dampingFraction: 0.6)
}
