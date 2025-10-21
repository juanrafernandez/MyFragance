# 🎨 PERFBETA - PROPUESTA DE DISEÑO VISUAL

**Basado en:** DESIGN_AUDIT.md
**Objetivo:** Sistema de diseño premium, consistente y escalable
**Inspiración:** Fragrantica (lujo), Sephora (clean), Airbnb (sistema robusto)

---

## 📋 RESUMEN EJECUTIVO

Esta propuesta transforma PerfBeta de una app genérica a una experiencia premium que refleja la sofisticación de los perfumes de lujo.

**Cambios Clave:**
1. ✨ Paleta Elegante (Negro + Dorado + Beige)
2. 📝 Typography Scale Completa
3. 📏 Spacing System 8pt
4. 🎯 Component Library Unificado
5. 💎 Visual Polish Premium

---

## 🎨 PROPUESTA 1: COLOR PALETTE PREMIUM

### Filosofía

**De:** Púrpura juvenil + Dorado inconsistente
**A:** Negro elegante + Dorado sofisticado + Beige cálido

**Inspiración:** Perfumes de nicho (Le Labo, Byredo, Diptyque) usan negro/oro/beige

---

### Paleta Propuesta

```swift
// PerfBeta/Utils/DesignTokens.swift (NUEVO ARCHIVO)

import SwiftUI

// MARK: - Color Tokens
enum AppColor {

    // MARK: - Brand Colors (Identidad)
    static let brandPrimary = Color("brandPrimary")        // Negro elegante #1A1A1A
    static let brandAccent = Color("brandAccent")          // Dorado champagne #C4A962
    static let brandAccentLight = Color("brandAccentLight") // Dorado claro #D4B97A

    // MARK: - Semantic Colors (Función)

    // Backgrounds
    static let backgroundPrimary = Color("backgroundPrimary")     // Blanco #FFFFFF
    static let backgroundSecondary = Color("backgroundSecondary") // Beige muy claro #F5F5F0
    static let backgroundTertiary = Color("backgroundTertiary")   // Beige claro #EEEEE8
    static let backgroundElevated = Color("backgroundElevated")   // Blanco con sombra

    // Surfaces (Cards, Modals)
    static let surfacePrimary = Color("surfacePrimary")           // Blanco #FFFFFF
    static let surfaceSecondary = Color("surfaceSecondary")       // Beige #F9F9F5
    static let surfaceOverlay = Color("surfaceOverlay")           // Negro 0.4 alpha

    // Text
    static let textPrimary = Color("textPrimary")                 // Negro #1A1A1A
    static let textSecondary = Color("textSecondary")             // Gris oscuro #4A4A4A
    static let textTertiary = Color("textTertiary")               // Gris medio #8A8A8A
    static let textDisabled = Color("textDisabled")               // Gris claro #CACACA
    static let textInverse = Color("textInverse")                 // Blanco #FFFFFF

    // Interactive (Botones, Links)
    static let interactivePrimary = Color("interactivePrimary")   // Negro #1A1A1A
    static let interactiveSecondary = Color("interactiveSecondary") // Dorado #C4A962
    static let interactiveTertiary = Color("interactiveTertiary") // Gris oscuro #4A4A4A

    // States
    static let stateHover = Color("stateHover")                   // Negro 0.08 alpha
    static let statePressed = Color("statePressed")               // Negro 0.12 alpha
    static let stateDisabled = Color("stateDisabled")             // Gris muy claro #F0F0F0
    static let stateFocus = Color("stateFocus")                   // Dorado #C4A962

    // Feedback
    static let feedbackSuccess = Color("feedbackSuccess")         // Verde oliva #6B8E23
    static let feedbackWarning = Color("feedbackWarning")         // Ambar #D4A962
    static let feedbackError = Color("feedbackError")             // Rojo oscuro #8B0000
    static let feedbackInfo = Color("feedbackInfo")               // Azul grisáceo #5A7A8C

    // Borders
    static let borderPrimary = Color("borderPrimary")             // Gris claro #E0E0E0
    static let borderSecondary = Color("borderSecondary")         // Beige #EEEEE8
    static let borderFocus = Color("borderFocus")                 // Dorado #C4A962

    // Icons
    static let iconPrimary = Color("iconPrimary")                 // Negro #1A1A1A
    static let iconSecondary = Color("iconSecondary")             // Gris #8A8A8A
    static let iconTertiary = Color("iconTertiary")               // Gris claro #CACACA
    static let iconAccent = Color("iconAccent")                   // Dorado #C4A962

    // Ratings & Badges
    static let ratingFill = Color("ratingFill")                   // Dorado #C4A962
    static let badgeSuccess = Color("badgeSuccess")               // Verde #6B8E23
    static let badgeWarning = Color("badgeWarning")               // Ambar #D4A962
    static let badgeInfo = Color("badgeInfo")                     // Azul gris #5A7A8C
}

extension Color {
    // MARK: - Opacities (Consistentes)
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
```

---

### Implementación en Assets.xcassets

**Crear estos ColorSets:**

1. **brandPrimary** → #1A1A1A (Any), #F5F5F0 (Dark)
2. **brandAccent** → #C4A962 (Any/Dark)
3. **backgroundPrimary** → #FFFFFF (Any), #1A1A1A (Dark)
4. **backgroundSecondary** → #F5F5F0 (Any), #2C2C2C (Dark)
5. **textPrimary** → #1A1A1A (Any), #F5F5F0 (Dark)
6. **textSecondary** → #4A4A4A (Any), #CACACA (Dark)
7. ... (todos los colores listados arriba)

**⚠️ IMPORTANTE:** Definir **TODOS** los colores en Assets para Dark Mode automático

---

### Migración del Código Existente

```swift
// ❌ ANTES (Código actual)
.foregroundColor(.gray)
.foregroundColor(Color("textoSecundario"))
.background(Color.white)
Color(red: 0.8, green: 0.6, blue: 0.8) // Púrpura hardcoded

// ✅ DESPUÉS (Con DesignTokens)
.foregroundColor(AppColor.textSecondary)
.foregroundColor(AppColor.textSecondary)
.background(AppColor.backgroundPrimary)
AppColor.backgroundSecondary // Ya no hay hardcoded RGB
```

---

### **🚨 CAMBIO CRÍTICO: Eliminar Sistema de Temas Personalizables**

**Problema identificado:** La app actualmente permite al usuario elegir entre 3 degradados (Champán, Lila, Verde) en Ajustes → "Personalización del Degradado".

**Impacto negativo:**
- ❌ Cada usuario ve una app diferente → NO HAY identidad de marca
- ❌ Screenshots de marketing inconsistentes
- ❌ Imposible crear coherencia visual
- ❌ Percepción de falta de profesionalismo

**✅ SOLUCIÓN: Definir UN SOLO degradado premium como parte de la marca PerfBeta**

---

### Gradiente de Marca Único (Nuevo)

**Eliminar completamente:**
```swift
// ❌ ELIMINAR PerfBeta/Utils/GradientPreset.swift
enum GradientPreset {
    case champan
    case lila      // ← Eliminar opción purple
    case verde     // ← Eliminar opción verde
}

// ❌ ELIMINAR de SettingsView.swift (líneas 87-96)
SectionCard(title: "Personalización del Degradado", content: {
    Picker("", selection: $selectedGradientPreset) { ... }
})
```

**✅ REEMPLAZAR con degradado único de marca:**

```swift
// PerfBeta/Utils/DesignTokens.swift

enum AppGradient {
    // DEGRADADO DE MARCA (único, no modificable)
    // Opción recomendada: Champán refinado
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

    // Locations para controlar la distribución del degradado
    static let brandGradientLocations: [CGFloat] = [0.0, 0.25, 0.55, 0.85]

    // ALTERNATIVA: Degradado dramático (Negro a Dorado)
    static let brandGradientDramatic = LinearGradient(
        colors: [
            Color(hex: "1A1A1A"),  // Negro
            Color(hex: "2C2C2C"),  // Gris oscuro
            Color(hex: "C4A962"),  // Champán
            Color(hex: "FFFFFF")   // Blanco
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Overlay oscuro para imágenes (sin cambios)
    static let imageOverlay = LinearGradient(
        colors: [
            Color.black.opacity(0.4),
            Color.black.opacity(0.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Badge gradient dorado (sin cambios)
    static let badgeGold = LinearGradient(
        colors: [
            AppColor.brandAccent,
            AppColor.brandAccentLight
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// Extension para crear Color desde Hex
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

---

### Componente de Degradado Actualizado

```swift
// PerfBeta/Components/GradientBackgroundView.swift (ACTUALIZAR)

import SwiftUI

// MARK: - GradientBackgroundView Simplificado
struct GradientBackgroundView: View {
    var body: some View {
        // ✅ Degradado único de marca (sin opciones de personalización)
        AppGradient.brandGradient
            .ignoresSafeArea()
    }
}

// Ya no necesita recibir `preset: GradientPreset`
// Ya no hay GradientView con UIViewRepresentable

// Uso simple:
// GradientBackgroundView()  // Sin parámetros
```

---

### Migración de Vistas Existentes

```swift
// ❌ ANTES (LoginView.swift:15)
@AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

ZStack {
    GradientView(preset: selectedGradientPreset)
        .edgesIgnoringSafeArea(.all)
    // Content...
}

// ✅ DESPUÉS
ZStack {
    GradientBackgroundView()  // Sin parámetros, siempre el mismo
    // Content...
}
```

```swift
// ❌ ANTES (SettingsView.swift:6)
@AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

// ✅ DESPUÉS
// ELIMINAR @AppStorage de selectedGradientPreset
// ELIMINAR sección "Personalización del Degradado" de la UI
```

---

### Decisión de Diseño Recomendada

**Opción A (RECOMENDADA): Degradado Champán Refinado**
- **Colores:** `#8B7355` → `#C4A962` → `#E8DCC8` → `#FFFFFF`
- **Feel:** Cálido, sofisticado, perfumería clásica
- **Referencias:** Chanel, Dior, Tom Ford
- **Ventaja:** Mantiene el espíritu del color "champán" actual pero elevado

**Opción B: Degradado Dramático Negro-Dorado**
- **Colores:** `#1A1A1A` → `#2C2C2C` → `#C4A962` → `#FFFFFF`
- **Feel:** Nocturno, luxury, bold
- **Referencias:** YSL, Viktor&Rolf
- **Ventaja:** Máximo contraste y dramatismo

**Opción C (Minimalista): Sin degradado**
- **Fondos sólidos:** Blanco `#FFFFFF` + Beige `#F5F5F0`
- **Accent:** Dorado `#C4A962` solo en detalles
- **Feel:** Clean, moderno, Sephora-style
- **Ventaja:** Máxima simplicidad y elegancia

**Mi recomendación: Opción A** (degradado champán refinado)
- Evoluciona el diseño actual sin romper bruscamente
- Mantiene personalidad cálida y acogedora
- Se diferencia de competidores (Fragrantica = negro puro, Sephora = blanco puro)

---

## 📝 PROPUESTA 2: TYPOGRAPHY SYSTEM

### Filosofía

**De:** 4 estilos genéricos no usados
**A:** 10 estilos semánticos con Dynamic Type

**Inspiración:** Apple Human Interface Guidelines + Fragrantica

---

### Escala Tipográfica

```swift
// PerfBeta/Utils/DesignTokens.swift

// MARK: - Typography Tokens
enum AppTypography {

    // MARK: - Display (Para screens de bienvenida, onboarding)
    static let displayLarge = Font.custom("PlayfairDisplay-Regular", size: 57)
        .weight(.regular)
    static let displayMedium = Font.custom("PlayfairDisplay-Regular", size: 45)
        .weight(.regular)
    static let displaySmall = Font.custom("PlayfairDisplay-Regular", size: 36)
        .weight(.regular)

    // MARK: - Headlines (Títulos de secciones)
    static let headlineLarge = Font.system(size: 32, weight: .light, design: .default)
    static let headlineMedium = Font.system(size: 28, weight: .regular, design: .default)
    static let headlineSmall = Font.system(size: 24, weight: .regular, design: .default)

    // MARK: - Titles (Títulos de cards, items)
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let titleMedium = Font.system(size: 18, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 16, weight: .semibold, design: .default)

    // MARK: - Body (Contenido principal)
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Label (Botones, tabs, labels)
    static let labelLarge = Font.system(size: 16, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 14, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)

    // MARK: - Caption (Texto secundario, metadatos)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionEmphasis = Font.system(size: 12, weight: .medium, design: .default)

    // MARK: - Overline (Labels, categorías pequeñas)
    static let overline = Font.system(size: 10, weight: .semibold, design: .default)
        .uppercaseSmallCaps() // "RECOMENDADOS PARA TI"
}

// MARK: - Text Modifiers (Para aplicar estilos completos)
extension Text {
    // Display
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

    // Headlines
    func headlineLarge() -> some View {
        self.font(AppTypography.headlineLarge)
            .foregroundColor(AppColor.textPrimary)
            .lineSpacing(2)
    }

    func headlineMedium() -> some View {
        self.font(AppTypography.headlineMedium)
            .foregroundColor(AppColor.textPrimary)
    }

    // Titles
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

    // Body
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

    // Labels
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

    // Caption
    func caption() -> some View {
        self.font(AppTypography.caption)
            .foregroundColor(AppColor.textTertiary)
    }

    func captionEmphasis() -> some View {
        self.font(AppTypography.captionEmphasis)
            .foregroundColor(AppColor.textSecondary)
    }

    // Overline
    func overline() -> some View {
        self.font(AppTypography.overline)
            .foregroundColor(AppColor.textTertiary)
            .kerning(0.5) // Letter spacing para mayúsculas
    }
}
```

---

### Uso en Código

```swift
// ❌ ANTES
Text("Perfume Name")
    .font(.system(size: 30, weight: .light))
    .foregroundColor(Color("textoPrincipal"))

// ✅ DESPUÉS
Text("Perfume Name")
    .headlineMedium()
```

```swift
// ❌ ANTES
Text("By Givenchy")
    .font(.system(size: 24, weight: .light))
    .foregroundColor(Color("textoSecundario"))

// ✅ DESPUÉS
Text("By Givenchy")
    .titleMedium()
```

```swift
// ❌ ANTES
Text("RECOMENDADOS PARA TI")
    .font(.system(size: 12, weight: .light))

// ✅ DESPUÉS
Text("Recomendados para ti")
    .overline()
```

---

### Tipografía Premium (Opcional)

**Añadir fuente Serif para perfumes:**

1. Descargar **Playfair Display** (Google Fonts, gratis)
2. Añadir a proyecto (PerfBeta/Resources/Fonts/)
3. Actualizar Info.plist:
   ```xml
   <key>UIAppFonts</key>
   <array>
       <string>PlayfairDisplay-Regular.ttf</string>
       <string>PlayfairDisplay-Medium.ttf</string>
       <string>PlayfairDisplay-Bold.ttf</string>
   </array>
   ```

4. Usar en nombres de perfumes:
   ```swift
   Text(perfume.name)
       .font(.custom("PlayfairDisplay-Regular", size: 24))
       .foregroundColor(AppColor.textPrimary)
   ```

**Resultado:** Nombres de perfumes más elegantes y premium

---

## 📏 PROPUESTA 3: SPACING SYSTEM

### Filosofía

**De:** Valores arbitrarios (3, 4, 5, 6, 8, 10, 12, 15, 20, 25, 30...)
**A:** Sistema 8pt riguroso

**Inspiración:** Material Design, iOS HIG, Figma

---

### Escala de Spacing

```swift
// PerfBeta/Utils/DesignTokens.swift

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

    // Predefined shadows
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
}

// MARK: - View Extension para aplicar shadows
extension View {
    func shadow(_ shadow: AppShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
```

---

### Uso en Código

```swift
// ❌ ANTES
.padding(25)
.cornerRadius(10)
.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

// ✅ DESPUÉS
.padding(AppSpacing.spacing24)
.cornerRadius(AppCornerRadius.medium)
.shadow(AppShadow.small)
```

```swift
// ❌ ANTES
VStack(spacing: 15) {
    // Content
}
.padding(.horizontal, 30)
.padding(.vertical, 20)

// ✅ DESPUÉS
VStack(spacing: AppSpacing.spacing16) {
    // Content
}
.padding(.horizontal, AppSpacing.spacing24)
.padding(.vertical, AppSpacing.spacing20)
```

---

## 🎯 PROPUESTA 4: COMPONENT LIBRARY

### 4.1 Botones Rediseñados

```swift
// PerfBeta/Components/AppButton.swift (NUEVO ARCHIVO)

import SwiftUI

// MARK: - Button Style Enum
enum AppButtonStyle {
    case primary      // Negro sólido, texto blanco
    case secondary    // Borde negro, fondo transparente
    case tertiary     // Solo texto, sin fondo
    case accent       // Dorado sólido, texto negro
    case destructive  // Rojo, texto blanco
}

enum AppButtonSize {
    case small   // Height 40
    case medium  // Height 48
    case large   // Height 56
}

// MARK: - AppButton Component
struct AppButton: View {
    let title: String
    let style: AppButtonStyle
    let size: AppButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: AppButtonStyle = .primary,
        size: AppButtonSize = .large,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else {
                    Text(title)
                        .font(font)
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(AppCornerRadius.medium)
            .shadow(shadow)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    // MARK: - Computed Properties

    private var height: CGFloat {
        switch size {
        case .small: return 40
        case .medium: return 48
        case .large: return 56
        }
    }

    private var font: Font {
        switch size {
        case .small: return AppTypography.labelSmall
        case .medium: return AppTypography.labelMedium
        case .large: return AppTypography.labelLarge
        }
    }

    private var backgroundColor: Color {
        if isDisabled { return AppColor.stateDisabled }

        switch style {
        case .primary: return AppColor.interactivePrimary
        case .secondary: return .clear
        case .tertiary: return .clear
        case .accent: return AppColor.interactiveSecondary
        case .destructive: return AppColor.feedbackError
        }
    }

    private var textColor: Color {
        if isDisabled { return AppColor.textDisabled }

        switch style {
        case .primary: return AppColor.textInverse
        case .secondary: return AppColor.textPrimary
        case .tertiary: return AppColor.textPrimary
        case .accent: return AppColor.textPrimary
        case .destructive: return AppColor.textInverse
        }
    }

    private var borderColor: Color {
        if isDisabled { return .clear }

        switch style {
        case .primary: return .clear
        case .secondary: return AppColor.borderPrimary
        case .tertiary: return .clear
        case .accent: return .clear
        case .destructive: return .clear
        }
    }

    private var borderWidth: CGFloat {
        style == .secondary ? 1.5 : 0
    }

    private var shadow: AppShadow {
        if isDisabled { return .none }

        switch style {
        case .primary, .accent, .destructive: return .small
        case .secondary, .tertiary: return .none
        }
    }
}

// MARK: - Preview
struct AppButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppSpacing.spacing16) {
            AppButton("Primary Button", style: .primary) {}
            AppButton("Secondary Button", style: .secondary) {}
            AppButton("Tertiary Button", style: .tertiary) {}
            AppButton("Accent Button", style: .accent) {}
            AppButton("Loading", style: .primary, isLoading: true) {}
            AppButton("Disabled", style: .primary, isDisabled: true) {}
        }
        .padding()
    }
}
```

---

### Uso en Código

```swift
// ❌ ANTES (LoginView.swift:47)
Button(action: performLogin) {
    if authViewModel.isLoadingEmailLogin {
        ProgressView().tint(.white)
    } else {
        Text("Login")
    }
}
.buttonStyle(PrimaryButtonStyle())
.disabled(authViewModel.isLoadingEmailLogin || email.isEmpty || password.isEmpty)

// ✅ DESPUÉS
AppButton(
    "Login",
    style: .primary,
    isLoading: authViewModel.isLoadingEmailLogin,
    isDisabled: email.isEmpty || password.isEmpty
) {
    performLogin()
}
.padding(.horizontal, AppSpacing.spacing24)
```

---

### 4.2 Perfume Card Unificado

```swift
// PerfBeta/Components/PerfumeCard.swift (REEMPLAZA PerfumeCardView, PerfumeCarouselItem)

import SwiftUI
import Kingfisher

// MARK: - Perfume Card Variants
enum PerfumeCardVariant {
    case standard     // Card normal con toda la info
    case compact      // Card pequeño para carousel
    case minimal      // Solo imagen y nombre
}

// MARK: - Perfume Card Badge Type
enum PerfumeCardBadgeType {
    case none
    case matchPercentage(Int)  // "81%"
    case rating(Double)         // "8.3"
    case userRating(Double)     // Heart icon + rating
}

// MARK: - Perfume Card Component
struct PerfumeCard: View {
    let perfume: Perfume
    let brandName: String
    let familyName: String
    let variant: PerfumeCardVariant
    let badge: PerfumeCardBadgeType
    let onTap: () -> Void

    init(
        perfume: Perfume,
        brandViewModel: BrandViewModel,
        familyViewModel: FamilyViewModel,
        variant: PerfumeCardVariant = .standard,
        badge: PerfumeCardBadgeType = .rating(0),
        onTap: @escaping () -> Void = {}
    ) {
        self.perfume = perfume
        self.brandName = brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand
        self.familyName = familyViewModel.familias.first { $0.key == perfume.family }?.name ?? perfume.family
        self.variant = variant
        self.badge = badge
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .center, spacing: cardSpacing) {
                    // Imagen
                    KFImage(perfume.imageURL.flatMap { URL(string: $0) })
                        .placeholder { placeholderImage }
                        .resizable()
                        .scaledToFit()
                        .frame(height: imageHeight)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .cornerRadius(AppCornerRadius.small)

                    // Info
                    if variant != .minimal {
                        infoSection
                    }
                }
                .frame(width: cardWidth)
                .padding(cardPadding)
                .background(AppColor.surfacePrimary)
                .cornerRadius(AppCornerRadius.medium)
                .shadow(AppShadow.small)

                // Badge
                if case .none = badge {} else {
                    badgeView
                        .offset(x: -AppSpacing.spacing8, y: AppSpacing.spacing8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var infoSection: some View {
        VStack(spacing: AppSpacing.spacing4) {
            Text(brandName)
                .labelSmall()
                .lineLimit(1)

            Text(perfume.name)
                .titleSmall()
                .lineLimit(variant == .compact ? 1 : 2)

            if variant == .standard {
                Text(familyName.capitalized)
                    .caption()
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var badgeView: some View {
        Group {
            switch badge {
            case .none:
                EmptyView()
            case .matchPercentage(let percentage):
                HStack(spacing: AppSpacing.spacing2) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                    Text("\(percentage)%")
                        .font(AppTypography.captionEmphasis)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, AppSpacing.spacing8)
                .padding(.vertical, AppSpacing.spacing4)
                .background(AppColor.feedbackSuccess)
                .cornerRadius(AppCornerRadius.small)

            case .rating(let rating):
                HStack(spacing: AppSpacing.spacing2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(AppColor.ratingFill)
                    Text(String(format: "%.1f", rating))
                        .font(AppTypography.captionEmphasis)
                        .foregroundColor(AppColor.textPrimary)
                }
                .padding(.horizontal, AppSpacing.spacing8)
                .padding(.vertical, AppSpacing.spacing4)
                .background(AppColor.backgroundPrimary.opacity(0.9))
                .cornerRadius(AppCornerRadius.small)
                .shadow(AppShadow.small)

            case .userRating(let rating):
                HStack(spacing: AppSpacing.spacing2) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                    Text(String(format: "%.1f", rating))
                        .font(AppTypography.captionEmphasis)
                        .foregroundColor(AppColor.textPrimary)
                }
                .padding(.horizontal, AppSpacing.spacing8)
                .padding(.vertical, AppSpacing.spacing4)
                .background(AppColor.backgroundPrimary.opacity(0.9))
                .cornerRadius(AppCornerRadius.small)
                .shadow(AppShadow.small)
            }
        }
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .foregroundColor(AppColor.iconTertiary)
            .frame(height: imageHeight)
            .background(AppColor.backgroundTertiary)
            .cornerRadius(AppCornerRadius.small)
    }

    // MARK: - Computed Properties

    private var cardWidth: CGFloat {
        switch variant {
        case .standard: return 160
        case .compact: return 120
        case .minimal: return 100
        }
    }

    private var imageHeight: CGFloat {
        switch variant {
        case .standard: return 120
        case .compact: return 90
        case .minimal: return 80
        }
    }

    private var cardPadding: CGFloat {
        switch variant {
        case .standard: return AppSpacing.spacing12
        case .compact: return AppSpacing.spacing8
        case .minimal: return AppSpacing.spacing8
        }
    }

    private var cardSpacing: CGFloat {
        switch variant {
        case .standard: return AppSpacing.spacing8
        case .compact: return AppSpacing.spacing4
        case .minimal: return AppSpacing.spacing4
        }
    }
}
```

---

### Uso en Código

```swift
// ❌ ANTES (3 componentes diferentes)
// PerfumeCardView
// PerfumeCarouselItem
// TestPerfumeCardView

// ✅ DESPUÉS (UN componente con variants)

// Home carousel:
PerfumeCard(
    perfume: perfume,
    brandViewModel: brandViewModel,
    familyViewModel: familyViewModel,
    variant: .compact,
    badge: .matchPercentage(81)
) {
    selectedPerfume = perfume
}

// Explorar grid:
PerfumeCard(
    perfume: perfume,
    brandViewModel: brandViewModel,
    familyViewModel: familyViewModel,
    variant: .standard,
    badge: .rating(perfume.popularity ?? 0)
) {
    selectedPerfume = perfume
}

// Mi Colección:
PerfumeCard(
    perfume: perfume,
    brandViewModel: brandViewModel,
    familyViewModel: familyViewModel,
    variant: .standard,
    badge: .userRating(triedPerfume.rating ?? 0)
) {
    showDetail = true
}
```

---

### 4.3 Text Field Mejorado

```swift
// PerfBeta/Components/AppTextField.swift

import SwiftUI

enum AppTextFieldStyle {
    case filled     // Fondo gris claro
    case outlined   // Borde, fondo transparente
}

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    let style: AppTextFieldStyle
    let leadingIcon: String?
    let isSecure: Bool
    let keyboardType: UIKeyboardType

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        style: AppTextFieldStyle = .filled,
        leadingIcon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.style = style
        self.leadingIcon = leadingIcon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }

    var body: some View {
        HStack(spacing: AppSpacing.spacing12) {
            if let icon = leadingIcon {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(AppTypography.bodyMedium)
            .foregroundColor(AppColor.textPrimary)
            .keyboardType(keyboardType)
            .focused($isFocused)
        }
        .padding(AppSpacing.spacing16)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .cornerRadius(AppCornerRadius.medium)
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        switch style {
        case .filled: return AppColor.backgroundTertiary
        case .outlined: return .clear
        }
    }

    private var borderColor: Color {
        if isFocused {
            return AppColor.borderFocus
        }
        switch style {
        case .filled: return .clear
        case .outlined: return AppColor.borderPrimary
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .filled: return 0
        case .outlined: return isFocused ? 2 : 1
        }
    }

    private var iconColor: Color {
        isFocused ? AppColor.iconAccent : AppColor.iconSecondary
    }
}
```

---

## 💎 PROPUESTA 5: VISUAL POLISH

### 5.1 Shadows Consistentes

**Eliminar:**
```swift
// ❌ Shadows inconsistentes
.shadow(radius: 5)
.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
.shadow(radius: 1)
```

**Usar:**
```swift
// ✅ Shadows estandarizados
.shadow(AppShadow.small)   // Cards
.shadow(AppShadow.medium)  // Modals
.shadow(AppShadow.elevated) // Nav bars, tab bars
```

---

### 5.2 Transitions Suaves

```swift
// PerfBeta/Utils/AppTransitions.swift

enum AppTransition {
    static let standard: Animation = .easeInOut(duration: 0.3)
    static let quick: Animation = .easeInOut(duration: 0.2)
    static let slow: Animation = .easeInOut(duration: 0.5)
    static let spring: Animation = .spring(response: 0.3, dampingFraction: 0.7)
    static let springBouncy: Animation = .spring(response: 0.4, dampingFraction: 0.6)
}

// Uso:
.animation(AppTransition.spring, value: isExpanded)
```

---

### 5.3 Loading States

```swift
// PerfBeta/Components/AppLoadingView.swift

struct AppLoadingView: View {
    let style: LoadingStyle

    enum LoadingStyle {
        case fullscreen
        case inline
        case overlay
    }

    var body: some View {
        switch style {
        case .fullscreen:
            ZStack {
                AppColor.backgroundPrimary.ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColor.brandAccent))
                    .scaleEffect(1.2)
            }

        case .inline:
            HStack(spacing: AppSpacing.spacing12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColor.brandAccent))
                Text("Cargando...")
                    .bodyMedium()
            }
            .padding()

        case .overlay:
            ZStack {
                AppColor.surfaceOverlay.ignoresSafeArea()
                VStack(spacing: AppSpacing.spacing16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColor.brandAccent))
                        .scaleEffect(1.5)
                    Text("Cargando...")
                        .bodyMedium()
                        .foregroundColor(AppColor.textInverse)
                }
                .padding(AppSpacing.spacing32)
                .background(AppColor.surfacePrimary)
                .cornerRadius(AppCornerRadius.large)
                .shadow(AppShadow.elevated)
            }
        }
    }
}
```

---

### 5.4 Empty States Mejorados

```swift
// PerfBeta/Components/AppEmptyState.swift

struct AppEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: AppSpacing.spacing24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(AppColor.iconTertiary)

            VStack(spacing: AppSpacing.spacing8) {
                Text(title)
                    .titleLarge()

                Text(message)
                    .bodyMedium()
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                AppButton(actionTitle, style: .primary, size: .medium) {
                    action()
                }
                .frame(maxWidth: 280)
            }
        }
        .padding(AppSpacing.spacing32)
        .frame(maxWidth: .infinity)
    }
}

// Uso:
AppEmptyState(
    icon: "heart",
    title: "Tu colección está vacía",
    message: "Comienza añadiendo tus perfumes favoritos para recibir recomendaciones personalizadas",
    actionTitle: "Añadir Perfume"
) {
    isAddingPerfume = true
}
```

---

## 🎨 PROPUESTA 6: PANTALLAS ESPECÍFICAS

### 6.1 Login / SignUp Rediseñado

**Cambios:**
- ❌ Eliminar gradiente púrpura fuerte
- ✅ Fondo blanco/beige clean
- ✅ Card con sombra sutil
- ✅ Botones con nuevo estilo

```swift
// LoginView.swift - REDISEÑADO

var body: some View {
    ZStack {
        // ✅ Fondo simple
        AppColor.backgroundSecondary.ignoresSafeArea()

        ScrollView {
            VStack(spacing: AppSpacing.spacing32) {
                Spacer().frame(height: AppSpacing.spacing64)

                // Logo o icon
                Image("app_logo") // Crear logo elegante
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                // Título
                VStack(spacing: AppSpacing.spacing8) {
                    Text("Bienvenido")
                        .headlineLarge()
                    Text("Descubre tu fragancia ideal")
                        .bodyLarge()
                        .foregroundColor(AppColor.textSecondary)
                }

                // Card con inputs
                VStack(spacing: AppSpacing.spacing16) {
                    AppTextField(
                        "Email",
                        text: $email,
                        style: .filled,
                        leadingIcon: "envelope",
                        keyboardType: .emailAddress
                    )

                    AppTextField(
                        "Contraseña",
                        text: $password,
                        style: .filled,
                        leadingIcon: "lock",
                        isSecure: true
                    )

                    HStack {
                        Spacer()
                        Button("¿Olvidaste tu contraseña?") {
                            // Action
                        }
                        .labelSmall()
                        .foregroundColor(AppColor.brandAccent)
                    }

                    AppButton(
                        "Iniciar Sesión",
                        style: .primary,
                        isLoading: authViewModel.isLoadingEmailLogin,
                        isDisabled: email.isEmpty || password.isEmpty
                    ) {
                        performLogin()
                    }

                    // Divider
                    HStack(spacing: AppSpacing.spacing12) {
                        Rectangle()
                            .fill(AppColor.borderPrimary)
                            .frame(height: 1)
                        Text("o continúa con")
                            .caption()
                        Rectangle()
                            .fill(AppColor.borderPrimary)
                            .frame(height: 1)
                    }
                    .padding(.vertical, AppSpacing.spacing8)

                    // Social buttons
                    HStack(spacing: AppSpacing.spacing16) {
                        SocialButton(icon: "icon_google") {
                            authViewModel.signInWithGoogle()
                        }
                        SocialButton(icon: "icon_apple") {
                            authViewModel.signInWithApple()
                        }
                    }
                }
                .padding(AppSpacing.spacing24)
                .background(AppColor.surfacePrimary)
                .cornerRadius(AppCornerRadius.large)
                .shadow(AppShadow.medium)
                .padding(.horizontal, AppSpacing.spacing24)

                // Footer
                HStack(spacing: AppSpacing.spacing4) {
                    Text("¿No tienes cuenta?")
                        .bodyMedium()
                        .foregroundColor(AppColor.textSecondary)
                    NavigationLink("Regístrate", destination: SignUpView())
                        .labelMedium()
                        .foregroundColor(AppColor.brandAccent)
                }

                Spacer().frame(height: AppSpacing.spacing32)
            }
        }

        // Error overlay
        if let error = authViewModel.errorMessage {
            ErrorView(error: error) {
                authViewModel.errorMessage = nil
            }
        }
    }
}
```

---

### 6.2 Home Tab Rediseñado

**Cambios:**
- ❌ Reducir gradiente o eliminar
- ✅ Más whitespace
- ✅ Secciones mejor separadas
- ✅ Typography mejorada

```swift
// HomeTabView.swift - REDISEÑADO

var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.spacing32) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
                Text("Hola, \(userName)")
                    .headlineMedium()
                Text("Explora perfumes perfectos para ti")
                    .bodyMedium()
                    .foregroundColor(AppColor.textSecondary)
            }
            .padding(.horizontal, AppSpacing.spacing24)
            .padding(.top, AppSpacing.spacing24)

            // Recomendaciones
            VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
                HStack {
                    Text("Recomendados para ti")
                        .overline()
                    Spacer()
                    Button("Ver todos") {}
                        .labelSmall()
                        .foregroundColor(AppColor.brandAccent)
                }
                .padding(.horizontal, AppSpacing.spacing24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.spacing16) {
                        ForEach(recommendedPerfumes) { perfume in
                            PerfumeCard(
                                perfume: perfume,
                                brandViewModel: brandViewModel,
                                familyViewModel: familyViewModel,
                                variant: .compact,
                                badge: .matchPercentage(perfume.matchScore)
                            ) {
                                selectedPerfume = perfume
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.spacing24)
                }
            }

            // ¿Sabías que?
            DidYouKnowCard(fact: currentFact)
                .padding(.horizontal, AppSpacing.spacing24)

            // Más secciones...
        }
    }
    .background(AppColor.backgroundPrimary)
}
```

---

## 📊 RESUMEN DE MEJORAS

| Aspecto | Antes | Después | Impacto |
|---------|-------|---------|---------|
| **Color Palette** | Púrpura inconsistente, hardcoded | Negro+Dorado semántico | ⭐️⭐️⭐️⭐️⭐️ |
| **Typography** | 4 estilos no usados | 10 estilos semánticos | ⭐️⭐️⭐️⭐️⭐️ |
| **Spacing** | Valores arbitrarios | Sistema 8pt riguroso | ⭐️⭐️⭐️⭐️ |
| **Components** | 3+ versiones duplicadas | 1 componente con variants | ⭐️⭐️⭐️⭐️ |
| **Polish** | Sombras inconsistentes | Sistema de elevación | ⭐️⭐️⭐️⭐️ |
| **Visual Identity** | Genérica, infantil | Premium, elegante | ⭐️⭐️⭐️⭐️⭐️ |

---

## 🎯 PRÓXIMOS PASOS

1. ✅ Revisar esta propuesta
2. ➡️ Decidir: ¿Opción A (Negro+Dorado) u Opción B (Púrpura refinado)?
3. ➡️ Implementar según DESIGN_ROADMAP.md (sprints priorizados)
4. ➡️ Crear Assets.xcassets con todos los colores
5. ➡️ Crear DesignTokens.swift
6. ➡️ Refactorizar Views progresivamente

---

**Propuesta creada por:** Claude Code
**Fecha:** 21 de Octubre de 2025
**Versión:** 1.0
