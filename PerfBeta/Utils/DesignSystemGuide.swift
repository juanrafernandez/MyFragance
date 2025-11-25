//
//  DesignSystemGuide.swift
//  PerfBeta
//
//  Guia de uso del Design System
//  Este archivo contiene previews y documentacion de todos los tokens y componentes
//

import SwiftUI

// MARK: - Design System Overview

/*
 # PerfBeta Design System

 ## Estructura

 El Design System se compone de:

 1. **Tokens** (DesignTokens.swift)
    - AppColor: Colores semanticos
    - AppTypography: Escala tipografica
    - AppSpacing: Sistema de 8pt grid
    - AppCornerRadius: Radios de esquinas
    - AppShadow: Sombras y elevaciones
    - AppTransition: Animaciones
    - AppIconSize: Tamanos de iconos
    - AppIcon: Catalogo de SF Symbols

 2. **Componentes** (Components/)
    - AppButton: Botones con 5 estilos
    - AppTextField: Campos de texto
    - AppBadge: Badges y tags
    - PerfumeCard: Cards de perfumes
    - LoadingView: Indicadores de carga
    - EmptyStateView: Estados vacios

 ## Uso Rapido

 ### Colores
 ```swift
 Text("Titulo")
     .foregroundColor(AppColor.textPrimary)

 Rectangle()
     .fill(AppColor.brandAccent)
 ```

 ### Tipografia
 ```swift
 Text("Display Large")
     .displayLarge()

 Text("Body")
     .font(AppTypography.bodyMedium)
 ```

 ### Espaciado
 ```swift
 VStack(spacing: AppSpacing.spacing16) { }

 .padding(.horizontal, AppSpacing.screenHorizontal)
 ```

 ### Iconos
 ```swift
 Image(systemName: AppIcon.favorite)
     .font(.system(size: AppIconSize.medium))
 ```

 ### Botones
 ```swift
 AppButton(
     title: "Continuar",
     action: { },
     style: .primary,
     size: .large
 )
 ```

 ### Text Fields
 ```swift
 AppTextField.email(text: $email)
 AppTextField.password(text: $password)
 ```

 ### Badges
 ```swift
 AppBadge.family("Amaderado")
 AppBadge.match(85)
 ```
 */

// MARK: - Color Palette Preview

struct ColorPalettePreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.spacing24) {

                // Brand
                Section("Brand") {
                    ColorRow("brandPrimary", AppColor.brandPrimary)
                    ColorRow("brandAccent", AppColor.brandAccent)
                    ColorRow("brandAccentLight", AppColor.brandAccentLight)
                }

                // Text
                Section("Text") {
                    ColorRow("textPrimary", AppColor.textPrimary)
                    ColorRow("textSecondary", AppColor.textSecondary)
                    ColorRow("textTertiary", AppColor.textTertiary)
                    ColorRow("textDisabled", AppColor.textDisabled)
                }

                // Background
                Section("Background") {
                    ColorRow("backgroundPrimary", AppColor.backgroundPrimary)
                    ColorRow("backgroundSecondary", AppColor.backgroundSecondary)
                    ColorRow("backgroundTertiary", AppColor.backgroundTertiary)
                }

                // Feedback
                Section("Feedback") {
                    ColorRow("feedbackSuccess", AppColor.feedbackSuccess)
                    ColorRow("feedbackError", AppColor.feedbackError)
                    ColorRow("feedbackWarning", AppColor.feedbackWarning)
                    ColorRow("feedbackInfo", AppColor.feedbackInfo)
                }

                // Accent Gold
                Section("Accent Gold") {
                    ColorRow("accentGold", AppColor.accentGold)
                    ColorRow("accentGoldLight", AppColor.accentGoldLight)
                    ColorRow("accentGoldDark", AppColor.accentGoldDark)
                }
            }
            .padding()
        }
        .navigationTitle("Color Palette")
    }

    @ViewBuilder
    private func Section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
            Text(title)
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColor.textPrimary)
            content()
        }
    }

    private func ColorRow(_ name: String, _ color: Color) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .stroke(AppColor.borderPrimary, lineWidth: 1)
                )

            Text(name)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColor.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Typography Preview

struct TypographyPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                Text("Display Large").displayLarge()
                Text("Display Medium").displayMedium()
                Text("Display Small").displaySmall()

                Divider()

                Text("Headline Large").headlineLarge()
                Text("Headline Medium").headlineMedium()
                Text("Headline Small").headlineSmall()

                Divider()

                Text("Title Large").titleLarge()
                Text("Title Medium").titleMedium()
                Text("Title Small").titleSmall()

                Divider()

                Text("Body Large - Lorem ipsum dolor sit amet").bodyLarge()
                Text("Body Medium - Lorem ipsum dolor sit amet").bodyMedium()
                Text("Body Small - Lorem ipsum dolor sit amet").bodySmall()

                Divider()

                Text("Label Large").labelLarge()
                Text("Label Medium").labelMedium()
                Text("Label Small").labelSmall()

                Divider()

                Text("Caption text").caption()
                Text("Caption Emphasis").captionEmphasis()
                Text("OVERLINE").overline()
            }
            .padding()
        }
        .navigationTitle("Typography")
    }
}

// MARK: - Spacing Preview

struct SpacingPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                SpacingRow("spacing2", AppSpacing.spacing2)
                SpacingRow("spacing4", AppSpacing.spacing4)
                SpacingRow("spacing8", AppSpacing.spacing8)
                SpacingRow("spacing12", AppSpacing.spacing12)
                SpacingRow("spacing16", AppSpacing.spacing16)
                SpacingRow("spacing20", AppSpacing.spacing20)
                SpacingRow("spacing24", AppSpacing.spacing24)
                SpacingRow("spacing32", AppSpacing.spacing32)
                SpacingRow("spacing40", AppSpacing.spacing40)
                SpacingRow("spacing48", AppSpacing.spacing48)
                SpacingRow("spacing64", AppSpacing.spacing64)
            }
            .padding()
        }
        .navigationTitle("Spacing")
    }

    private func SpacingRow(_ name: String, _ value: CGFloat) -> some View {
        HStack {
            Text(name)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColor.textPrimary)
                .frame(width: 100, alignment: .leading)

            Rectangle()
                .fill(AppColor.brandAccent)
                .frame(width: value, height: 24)

            Text("\(Int(value))pt")
                .font(AppTypography.caption)
                .foregroundColor(AppColor.textSecondary)
        }
    }
}

// MARK: - Component Catalog Preview

struct ComponentCatalogPreview: View {
    @State private var textFieldValue = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.spacing32) {

                // Buttons
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Buttons").titleLarge()

                    AppButton(title: "Primary", action: {}, style: .primary)
                    AppButton(title: "Secondary", action: {}, style: .secondary)
                    AppButton(title: "Tertiary", action: {}, style: .tertiary)
                    AppButton(title: "Accent", action: {}, style: .accent)
                    AppButton(title: "Destructive", action: {}, style: .destructive)
                }

                Divider()

                // Text Fields
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Text Fields").titleLarge()

                    AppTextField(placeholder: "Default field", text: $textFieldValue)
                    AppTextField.email(text: .constant("test@example.com"))
                    AppTextField.password(text: .constant("password"))
                    AppTextField.search(text: .constant(""))
                }

                Divider()

                // Badges
                VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                    Text("Badges").titleLarge()

                    HStack(spacing: AppSpacing.spacing8) {
                        AppBadge(text: "Neutral", style: .neutral)
                        AppBadge(text: "Accent", style: .accent)
                        AppBadge(text: "Success", style: .success)
                    }

                    HStack(spacing: AppSpacing.spacing8) {
                        AppBadge.new()
                        AppBadge.favorite()
                        AppBadge.match(85)
                    }

                    HStack(spacing: AppSpacing.spacing8) {
                        AppBadge.family("Amaderado")
                        AppBadge.gender("Unisex")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Components")
    }
}

// MARK: - Previews

#Preview("Color Palette") {
    NavigationStack {
        ColorPalettePreview()
    }
}

#Preview("Typography") {
    NavigationStack {
        TypographyPreview()
    }
}

#Preview("Spacing") {
    NavigationStack {
        SpacingPreview()
    }
}

#Preview("Components") {
    NavigationStack {
        ComponentCatalogPreview()
    }
}
