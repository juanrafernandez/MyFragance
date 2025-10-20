# PerfBeta - UI Component Library & Design System

**Fecha:** Octubre 20, 2025
**Versión:** 2.0 (Post-UX Audit)
**Estado:** 📋 Documentación de sistema existente + propuestas de mejora

---

## 📖 Propósito de Este Documento

Este documento cataloga **TODOS los componentes UI** de PerfBeta, identifica inconsistencias, y propone un design system unificado para:
- ✅ Mantener consistencia visual a través de la app
- ✅ Acelerar desarrollo con componentes reutilizables
- ✅ Facilitar onboarding de nuevos desarrolladores
- ✅ Preparar para escala (dark mode, temas, localization)

---

## 🎨 Principios del Design System

### 1. Accessibility First
- WCAG 2.1 AA compliance mínimo
- Dynamic Type support en todos los textos
- VoiceOver labels en todos los elementos interactivos
- Contrast ratio ≥ 4.5:1 para texto normal

### 2. Platform Native
- Seguir iOS Human Interface Guidelines
- Usar SwiftUI idioms y patterns
- Respetar system settings (Reduce Motion, Dark Mode)

### 3. Scalable & Maintainable
- Componentes atómicos reutilizables
- Design tokens para valores hardcoded
- Temas soportados desde arquitectura

### 4. Performance Optimized
- Lazy loading donde aplique
- Image caching (Kingfisher)
- Minimize re-renders con @State management

---

## 🏗️ Arquitectura del Design System

```
Design System
├── Foundation (Tokens)
│   ├── Colors
│   ├── Typography
│   ├── Spacing
│   ├── Border Radius
│   └── Shadows
│
├── Components (Atoms)
│   ├── Buttons
│   ├── Text Fields
│   ├── Cards
│   ├── Chips
│   └── Icons
│
├── Patterns (Molecules)
│   ├── Search Bar
│   ├── Filter Accordion
│   ├── Perfume Card
│   ├── Rating Stars
│   └── Progress Bar
│
└── Layouts (Organisms)
    ├── Tab Navigation
    ├── Modal Headers
    ├── Empty States
    └── Error Views
```

---

## 🎨 Foundation: Design Tokens

### Colors

#### Estado Actual (⚠️ Inconsistente)

**Assets existentes:**
```swift
// En Assets.xcassets
Color("textoPrincipal")        // Negro/gris oscuro
Color("textSecondaryNew")      // Gris medio
Color("primaryButton")         // Azul principal

// Hardcoded en código (❌ malo):
Color(hex: "#F6AD55")          // Naranja (progress bars)
Color(hex: "#F3E9E5")          // Beige (backgrounds)
Color.blue                     // Sistema (usado inconsistentemente)
Color.gray                     // Sistema (usado en muchos lugares)
```

**Problemas:**
- ❌ Hex codes hardcoded en 15+ archivos
- ❌ No hay palette central documentado
- ❌ Dark mode no funciona con Color(hex:)
- ❌ Naming inconsistente ("primaryButton" vs "textSecondaryNew")

#### Propuesta: Unified Color System

```swift
// File: PerfBeta/DesignSystem/Colors.swift
import SwiftUI

/// Sistema de colores unificado con soporte para light/dark mode
extension Color {

    // MARK: - Brand Colors
    static let brandPrimary = Color("BrandPrimary")     // Azul principal (#007AFF)
    static let brandSecondary = Color("BrandSecondary") // Naranja accent (#F6AD55)
    static let brandTertiary = Color("BrandTertiary")   // Verde success (#34C759)

    // MARK: - Semantic Colors (Adaptan a context)
    static let textPrimary = Color("TextPrimary")       // Negro/Blanco según mode
    static let textSecondary = Color("TextSecondary")   // Gris medio/Gris claro
    static let textTertiary = Color("TextTertiary")     // Gris claro/Gris oscuro

    static let backgroundPrimary = Color("BackgroundPrimary")   // Blanco/Negro
    static let backgroundSecondary = Color("BackgroundSecondary") // Gris claro/Gris oscuro
    static let backgroundTertiary = Color("BackgroundTertiary")  // Beige/Gris más oscuro

    // MARK: - Functional Colors
    static let success = Color("Success")     // Verde (#34C759)
    static let warning = Color("Warning")     // Naranja (#FF9500)
    static let error = Color("Error")         // Rojo (#FF3B30)
    static let info = Color("Info")           // Azul (#007AFF)

    // MARK: - Interactive Elements
    static let buttonPrimary = Color("ButtonPrimary")
    static let buttonSecondary = Color("ButtonSecondary")
    static let buttonDisabled = Color("ButtonDisabled")

    static let inputBackground = Color("InputBackground")
    static let inputBorder = Color("InputBorder")
    static let inputBorderFocused = Color("InputBorderFocused")

    // MARK: - Gradients (Presets existentes)
    struct Gradients {
        static let champan = LinearGradient(
            colors: [Color(hex: "#F3E9E5"), Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
        static let rosado = LinearGradient(
            colors: [Color(hex: "#FFE4E1"), Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
        // ... otros 6 presets existentes
    }
}

// MARK: - Hex Initializer (mantener compatibilidad)
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
        scanner.currentIndex = hex.hasPrefix("#") ? hex.index(after: hex.startIndex) : hex.startIndex

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

**Implementación en Assets.xcassets:**
```
Assets.xcassets/
├── Colors/
│   ├── BrandPrimary.colorset/
│   │   └── Contents.json (Light: #007AFF, Dark: #0A84FF)
│   ├── TextPrimary.colorset/
│   │   └── Contents.json (Light: #000000, Dark: #FFFFFF)
│   ├── BackgroundPrimary.colorset/
│   │   └── Contents.json (Light: #FFFFFF, Dark: #000000)
│   └── ... (resto de colores)
```

**Migración:**
```swift
// ❌ Antes (hardcoded):
Text("Hola").foregroundColor(Color(hex: "#000000"))
VStack {}.background(Color.white)

// ✅ Después (semantic):
Text("Hola").foregroundColor(.textPrimary)
VStack {}.background(.backgroundPrimary)
```

---

### Typography

#### Estado Actual (⚠️ Muy Inconsistente)

**Estilos usados:**
```swift
// SwiftUI text styles (✅ bueno - Dynamic Type):
.font(.title)
.font(.title2)
.font(.headline)
.font(.body)
.font(.subheadline)
.font(.caption)

// Hardcoded (❌ malo - no escala):
.font(.system(size: 18, weight: .light))  // Usado en 10+ lugares
.font(.system(size: 14, weight: .thin))
.font(.system(size: 32))                  // Rating stars
.font(.system(size: 50))                  // Icons grandes
```

**Problemas:**
- ❌ Tamaños hardcoded no respetan Dynamic Type del usuario
- ❌ No hay convención clara para cuándo usar qué estilo
- ❌ Weights inconsistentes (.light, .thin, .semibold, .bold)

#### Propuesta: Typography Scale

```swift
// File: PerfBeta/DesignSystem/Typography.swift
import SwiftUI

/// Sistema tipográfico unificado con Dynamic Type support
extension Font {

    // MARK: - Display (Títulos grandes, onboarding, hero sections)
    static let displayLarge = Font.system(.largeTitle, design: .default, weight: .bold)
    static let displayMedium = Font.system(.title, design: .default, weight: .bold)
    static let displaySmall = Font.system(.title2, design: .default, weight: .semibold)

    // MARK: - Headings (Secciones, headers)
    static let heading1 = Font.system(.title2, design: .default, weight: .bold)
    static let heading2 = Font.system(.title3, design: .default, weight: .semibold)
    static let heading3 = Font.system(.headline, design: .default, weight: .semibold)

    // MARK: - Body (Texto principal)
    static let bodyLarge = Font.system(.body, design: .default, weight: .regular)
    static let bodyRegular = Font.system(.callout, design: .default, weight: .regular)
    static let bodySmall = Font.system(.subheadline, design: .default, weight: .regular)

    // MARK: - Label (Metadatos, hints, captions)
    static let labelLarge = Font.system(.subheadline, design: .default, weight: .medium)
    static let labelRegular = Font.system(.footnote, design: .default, weight: .medium)
    static let labelSmall = Font.system(.caption, design: .default, weight: .medium)

    // MARK: - Special (Casos específicos)
    static let buttonLarge = Font.system(.body, design: .default, weight: .semibold)
    static let buttonRegular = Font.system(.callout, design: .default, weight: .semibold)
    static let inputText = Font.system(.body, design: .default, weight: .regular)
}

// MARK: - Text Modifier Extensions
extension View {
    func textStyle(_ style: TextStyle) -> some View {
        modifier(TextStyleModifier(style: style))
    }
}

enum TextStyle {
    case displayLarge, displayMedium, displaySmall
    case heading1, heading2, heading3
    case bodyLarge, bodyRegular, bodySmall
    case labelLarge, labelRegular, labelSmall
    case buttonLarge, buttonRegular

    var font: Font {
        switch self {
        case .displayLarge: return .displayLarge
        case .displayMedium: return .displayMedium
        case .displaySmall: return .displaySmall
        case .heading1: return .heading1
        case .heading2: return .heading2
        case .heading3: return .heading3
        case .bodyLarge: return .bodyLarge
        case .bodyRegular: return .bodyRegular
        case .bodySmall: return .bodySmall
        case .labelLarge: return .labelLarge
        case .labelRegular: return .labelRegular
        case .labelSmall: return .labelSmall
        case .buttonLarge: return .buttonLarge
        case .buttonRegular: return .buttonRegular
        }
    }

    var color: Color {
        switch self {
        case .displayLarge, .displayMedium, .displaySmall,
             .heading1, .heading2, .heading3,
             .bodyLarge, .bodyRegular, .bodySmall:
            return .textPrimary
        case .labelLarge, .labelRegular, .labelSmall:
            return .textSecondary
        case .buttonLarge, .buttonRegular:
            return .white
        }
    }
}

struct TextStyleModifier: ViewModifier {
    let style: TextStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(style.color)
    }
}
```

**Uso:**
```swift
// ❌ Antes:
Text("Título").font(.system(size: 18, weight: .light)).foregroundColor(.black)

// ✅ Después:
Text("Título").textStyle(.heading2)

// Con override de color si necesario:
Text("Error").textStyle(.bodyRegular).foregroundColor(.error)
```

**Guía de uso:**
- **Display:** Hero sections, onboarding, splash
- **Heading:** Títulos de secciones, tab titles
- **Body:** Texto principal, descripciones de perfumes
- **Label:** Metadatos (año, perfumista), hints, captions

---

### Spacing

#### Estado Actual (❌ Sin Sistema)

**Valores encontrados en código:**
```swift
.padding(8)
.padding(10)
.padding(12)
.padding(16)
.padding(20)
.padding(25)  // ⚠️ No sigue escala
.padding(30)
.padding(40)
.padding(.horizontal, 30)
.padding(.vertical, 10)
```

**Problemas:**
- ❌ No hay escala consistente
- ❌ Valores arbitrarios (25, 35)
- ❌ Difícil mantener consistencia visual

#### Propuesta: Spacing Scale (Sistema 8pt)

```swift
// File: PerfBeta/DesignSystem/Spacing.swift
import SwiftUI

/// Sistema de espaciado basado en escala de 8pt
enum Spacing {
    /// 4pt - Espaciado mínimo (entre íconos y texto)
    static let xxs: CGFloat = 4

    /// 8pt - Espaciado pequeño (entre elementos inline)
    static let xs: CGFloat = 8

    /// 12pt - Espaciado compacto (padding interno de botones)
    static let sm: CGFloat = 12

    /// 16pt - Espaciado estándar (padding general)
    static let md: CGFloat = 16

    /// 24pt - Espaciado amplio (separar secciones)
    static let lg: CGFloat = 24

    /// 32pt - Espaciado grande (headers, títulos)
    static let xl: CGFloat = 32

    /// 48pt - Espaciado muy grande (onboarding, empty states)
    static let xxl: CGFloat = 48

    /// 64pt - Espaciado máximo (splash, hero sections)
    static let xxxl: CGFloat = 64
}

// MARK: - View Extensions
extension View {
    // Padding shortcuts
    func padding(_ size: Spacing) -> some View {
        padding(size.rawValue)
    }

    func padding(_ edges: Edge.Set, _ size: Spacing) -> some View {
        padding(edges, size.rawValue)
    }

    // Spacing shortcuts
    func spacing(_ size: Spacing) -> some View {
        // Para VStack, HStack
        self
    }
}

// Hacer Spacing conforme a ExpressibleByIntegerLiteral para sintaxis limpia
extension Spacing: ExpressibleByFloatLiteral {
    init(floatLiteral value: FloatLiteralType) {
        self = .md // Default
    }

    var rawValue: CGFloat {
        switch self {
        case .xxs: return Self.xxs
        case .xs: return Self.xs
        case .sm: return Self.sm
        case .md: return Self.md
        case .lg: return Self.lg
        case .xl: return Self.xl
        case .xxl: return Self.xxl
        case .xxxl: return Self.xxxl
        }
    }
}
```

**Uso:**
```swift
// ❌ Antes:
VStack(spacing: 20) {
    Text("Título").padding(25)
    Text("Subtítulo").padding(.horizontal, 30)
}

// ✅ Después:
VStack(spacing: Spacing.lg) {
    Text("Título").padding(Spacing.lg)
    Text("Subtítulo").padding(.horizontal, Spacing.xl)
}
```

**Mapping de valores actuales:**
```
4pt  → xxs (casi no usado)
8pt  → xs
12pt → sm
16pt → md
20pt → lg (antes 20 → ahora 24, mejora consistencia)
25pt → lg (unificar a 24)
30pt → xl (antes 30 → ahora 32)
40pt → xl (unificar a 32) o xxl (si necesita destacar)
```

---

### Border Radius

#### Estado Actual (⚠️ Inconsistente)

```swift
.cornerRadius(8)   // Usado en ~60% casos
.cornerRadius(12)  // Usado en ~30% casos
.cornerRadius(16)  // Usado en chips
.cornerRadius(35)  // Solo en LoginView header curve
```

#### Propuesta: Radius System

```swift
// File: PerfBeta/DesignSystem/Radius.swift
import SwiftUI

enum CornerRadius {
    /// 4pt - Elementos muy pequeños (badges)
    static let xs: CGFloat = 4

    /// 8pt - Botones pequeños, inputs
    static let sm: CGFloat = 8

    /// 12pt - Botones estándar, cards
    static let md: CGFloat = 12

    /// 16pt - Cards grandes, modals
    static let lg: CGFloat = 16

    /// 24pt - Elementos hero, destacados
    static let xl: CGFloat = 24

    /// Full radius (pill shape)
    static let full: CGFloat = 9999
}

extension View {
    func cornerRadius(_ radius: CornerRadius) -> some View {
        self.cornerRadius(radius.rawValue)
    }
}
```

**Uso:**
```swift
// ❌ Antes:
Button("Login") {}.cornerRadius(12)
RoundedRectangle(cornerRadius: 8)

// ✅ Después:
Button("Login") {}.cornerRadius(.md)
RoundedRectangle(cornerRadius: CornerRadius.sm)
```

---

### Shadows

#### Estado Actual (❌ Muy Básico)

```swift
.shadow(radius: 5)     // Usado en 80% casos (muy genérico)
.shadow(radius: 8)     // Algunos casos
.shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2) // Solo en OptionButton
```

#### Propuesta: Shadow System

```swift
// File: PerfBeta/DesignSystem/Shadows.swift
import SwiftUI

enum ShadowStyle {
    case none
    case xs   // Subtle, hover effect
    case sm   // Default cards
    case md   // Elevated cards
    case lg   // Modals, overlays
    case xl   // Hero elements

    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .xs: return 2
        case .sm: return 4
        case .md: return 8
        case .lg: return 16
        case .xl: return 24
        }
    }

    var offset: CGSize {
        switch self {
        case .none: return .zero
        case .xs: return CGSize(width: 0, height: 1)
        case .sm: return CGSize(width: 0, height: 2)
        case .md: return CGSize(width: 0, height: 4)
        case .lg: return CGSize(width: 0, height: 8)
        case .xl: return CGSize(width: 0, height: 12)
        }
    }

    var opacity: Double {
        0.15 // Consistente para todas
    }
}

extension View {
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(
            color: Color.black.opacity(style.opacity),
            radius: style.radius,
            x: style.offset.width,
            y: style.offset.height
        )
    }
}
```

---

## 🧩 Components (Atoms)

### Buttons

#### Inventory Actual

**1. PrimaryButtonStyle** (✅ Existe)
```swift
// File: PerfBeta/Views/Login/LoginView.swift (inline)
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
```

**2. MinimalButtonStyle** (✅ Existe)
```swift
// File: PerfBeta/Views/SettingsTab/SettingsView.swift
struct MinimalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
```

**3. System buttons** (❌ Sin estilo unificado)
- Chevrons de navegación
- X de cerrar
- Íconos de tabs
- Share buttons

#### Propuesta: Unified Button System

```swift
// File: PerfBeta/DesignSystem/Components/PBButton.swift
import SwiftUI

/// Sistema de botones unificado
struct PBButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: ButtonSize
    let action: () -> Void

    enum ButtonStyle {
        case primary    // Filled, color primario
        case secondary  // Outline, color primario
        case tertiary   // Text only, sin background
        case destructive // Filled, color rojo
        case success    // Filled, color verde
    }

    enum ButtonSize {
        case small   // Padding compacto, font pequeño
        case medium  // Default
        case large   // Padding amplio, font grande
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(fontForSize)
            }
            .frame(maxWidth: style == .tertiary ? nil : .infinity)
            .padding(paddingForSize)
            .background(backgroundForStyle)
            .foregroundColor(foregroundForStyle)
            .overlay(overlayForStyle)
            .cornerRadius(.md)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Style Helpers
    private var fontForSize: Font {
        switch size {
        case .small: return .buttonRegular
        case .medium: return .buttonLarge
        case .large: return .buttonLarge
        }
    }

    private var paddingForSize: EdgeInsets {
        switch size {
        case .small: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .medium: return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        }
    }

    private var backgroundForStyle: Color {
        switch style {
        case .primary: return .brandPrimary
        case .secondary: return .clear
        case .tertiary: return .clear
        case .destructive: return .error
        case .success: return .success
        }
    }

    private var foregroundForStyle: Color {
        switch style {
        case .primary, .destructive, .success: return .white
        case .secondary: return .brandPrimary
        case .tertiary: return .brandPrimary
        }
    }

    @ViewBuilder
    private var overlayForStyle: some View {
        if style == .secondary {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.brandPrimary, lineWidth: 2)
        }
    }
}

// MARK: - Scale Button Style (Animación de press)
struct ScaleButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

**Uso:**
```swift
// Primary button (default)
PBButton("Iniciar Sesión", icon: "arrow.right") {
    login()
}

// Secondary button
PBButton("Cancelar", style: .secondary, size: .small) {
    dismiss()
}

// Destructive
PBButton("Eliminar", icon: "trash", style: .destructive) {
    delete()
}

// Tertiary (text only)
PBButton("Saltar", style: .tertiary) {
    skip()
}
```

---

## 📊 Resumen de Prioridades de Implementación

### Phase 1: Foundation (Semana 1-2)
1. ✅ Crear `DesignSystem/` folder structure
2. ✅ Implementar `Colors.swift` con Assets
3. ✅ Implementar `Typography.swift`
4. ✅ Implementar `Spacing.swift`
5. ✅ Implementar `Radius.swift` y `Shadows.swift`
6. ✅ Migrar 3-5 vistas como PoC

### Phase 2: Components (Semana 3-4)
7. ✅ Implementar `PBButton` unificado
8. ✅ Implementar `PBTextField` unificado
9. ✅ Implementar `PBCard` unificado (perfume cards)
10. ✅ Implementar `LoadingView` y `ErrorView` (ya propuestos)

### Phase 3: Migration (Semana 5-8)
11. ✅ Migrar TODAS las vistas a design system
12. ✅ Eliminar código legacy (hardcoded values)
13. ✅ Testing de regresión visual
14. ✅ Documentar patterns en este documento

### Phase 4: Advanced (Post-MVP)
15. ✅ Dark mode full support
16. ✅ Theming system (multiple gradients)
17. ✅ Accessibility audit completo
18. ✅ Animation library

---

## 📚 Recursos y Referencias

### Inspiration
- **Apple Human Interface Guidelines:** https://developer.apple.com/design/human-interface-guidelines/
- **Material Design 3:** https://m3.material.io/
- **Fluent 2 (Microsoft):** https://fluent2.microsoft.design/

### SwiftUI Design Systems
- **Orbit (Kiwi.com):** https://orbit.kiwi/design-tokens/
- **Primer (GitHub):** https://primer.style/design/
- **Polaris (Shopify):** https://polaris.shopify.com/

### Tools
- **Figma:** Para diseñar componentes antes de implementar
- **SF Symbols:** Iconografía iOS oficial
- **Color Contrast Analyzer:** Para WCAG compliance

---

**Documentos relacionados:**
- UX_AUDIT_REPORT.md - Problemas de inconsistencia identificados
- UX_RECOMMENDATIONS.md - Componentes propuestos (LoadingView, ErrorView)
- USER_FLOWS_IMPROVED.md - Uso de componentes en flujos

*Documento generado por: Claude Code*
*Fecha: Octubre 20, 2025*
*Versión: Living Document - se actualizará con nuevos componentes*
