# 🗺️ DESIGN ROADMAP - PerfBeta
**Hoja de ruta priorizada para implementar el nuevo sistema de diseño**

---

## 📊 RESUMEN EJECUTIVO

**Objetivo:** Transformar PerfBeta de 4.2/10 → 8.5/10 en diseño visual

**Esfuerzo total estimado:** 12-15 días de desarrollo

**Impacto esperado:**
- ✨ **Percepción de calidad:** +80% (de amateur a profesional)
- 🎨 **Consistencia visual:** +300% (de caótico a sistema unificado)
- ⚡ **Velocidad de desarrollo:** +50% (reutilización de componentes)
- ♿ **Accesibilidad:** +100% (soporte completo Dark Mode + Dynamic Type)

---

## 🎯 MATRIZ DE PRIORIZACIÓN (Impacto vs Esfuerzo)

```
Alto Impacto
    ▲
    │
    │  🟢 SPRINT 1          🟡 SPRINT 3
    │  - DesignTokens       - Refactor
    │  - AppButton            Home/Explore
    │  - Colors Assets      - Animations
    │
    │  🟢 SPRINT 2          🔴 SPRINT 4
    │  - PerfumeCard        - Advanced
    │  - Login/SignUp         Polish
    │  - AppTextField       - Edge cases
    │
    └──────────────────────────────────▶
    Bajo Esfuerzo              Alto Esfuerzo

🟢 Quick Wins (hacer YA)
🟡 Alto valor (siguiente)
🔴 Refinamiento (después)
```

---

## 📅 SPRINTS PRIORIZADOS

### 🚀 **SPRINT 1: FUNDACIÓN DEL SISTEMA**
**Duración:** 2 días
**Impacto:** 🔥🔥🔥🔥🔥 (Crítico - desbloquea todo lo demás)
**Esfuerzo:** ⚡⚡ (Bajo - mayormente crear archivos nuevos)

#### **OBJETIVO:**
Crear la infraestructura base del design system que usarán todos los componentes.

#### **TAREAS:**

##### ✅ **Tarea 1.0: [CRÍTICO] Eliminar Sistema de Temas Personalizable** (1 hora)

**Problema:** La app actualmente permite al usuario elegir entre 3 degradados (Champán, Lila, Verde) en Ajustes, destruyendo la identidad de marca.

**Archivos a modificar:**

1. **SettingsView.swift** (líneas 6 y 87-96)
   ```swift
   // ❌ ELIMINAR línea 6
   @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

   // ❌ ELIMINAR líneas 87-96 (sección completa)
   SectionCard(title: "Personalización del Degradado", content: {
       Picker("", selection: $selectedGradientPreset) {
           ForEach(GradientPreset.allCases, id: \.self) { preset in
               Text(preset.rawValue).tag(preset)
           }
       }
       .pickerStyle(SegmentedPickerStyle())
       .cornerRadius(8)
       .padding(.vertical, 4)
   })

   // ✅ SIN REEMPLAZAR (simplemente eliminar, queda solo 3 secciones: Cuenta, Datos, Soporte)
   ```

2. **GradientPreset.swift** (Archivo completo)
   ```swift
   // ❌ MARCAR PARA ELIMINAR (no borrar todavía, se reemplazará en Tarea 1.1)
   // Por ahora, comentar las opciones .lila y .verde

   enum GradientPreset: String, CaseIterable, Identifiable, Codable, Hashable {
       case champan = "Champán"
       // case lila = "Lila"      // ← COMENTAR
       // case verde = "Verde"    // ← COMENTAR
   }
   ```

3. **Todas las Views que usan GradientView(preset:)**

   **Buscar y reemplazar en estos archivos:**
   - LoginView.swift
   - SignUpView.swift
   - HomeTabView.swift
   - ExploreTabView.swift
   - FragranceLibraryTabView.swift
   - TestOlfativoTabView.swift
   - AllPerfumesView.swift
   - PerfumeDetailView.swift (si aplica)

   ```swift
   // ❌ ANTES
   @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

   ZStack {
       GradientView(preset: selectedGradientPreset)
           .edgesIgnoringSafeArea(.all)
       // Content...
   }

   // ✅ DESPUÉS (solución temporal hasta Tarea 1.1)
   // ELIMINAR @AppStorage

   ZStack {
       GradientView(preset: .champan)  // ← Forzar champán siempre
           .edgesIgnoringSafeArea(.all)
       // Content...
   }
   ```

**⚠️ IMPORTANTE:** Esto es una solución temporal. En Tarea 1.1 se creará el degradado único definitivo en DesignTokens.swift.

**Archivos afectados (estimados):**
- SettingsView.swift (2 cambios)
- GradientPreset.swift (2 líneas comentadas)
- ~8-10 Views (eliminar @AppStorage y forzar .champan)

**Comando útil para encontrar todos los usos:**
```bash
grep -r "GradientView" --include="*.swift" PerfBeta/
grep -r "@AppStorage.*GradientPreset" --include="*.swift" PerfBeta/
```

**Validación:**
- [ ] Build exitoso
- [ ] Ajustes ya no muestra selector de degradado
- [ ] Todas las pantallas usan degradado champán
- [ ] No hay warnings de @AppStorage no usado

**Impacto:**
- ✅ Identidad de marca única
- ✅ Screenshots consistentes
- ✅ Elimina confusión del usuario
- ✅ Prepara terreno para degradado refinado en Tarea 1.1

---

##### ✅ **Tarea 1.1: Crear DesignTokens.swift** (2 horas)
- **Archivo nuevo:** `PerfBeta/Utils/DesignTokens.swift`
- **Qué hacer:**
  ```swift
  // Copiar el código completo de DESIGN_PROPOSAL.md
  enum AppColor { /* 30+ colores semánticos */ }
  enum AppTypography { /* 10 estilos tipográficos */ }
  enum AppSpacing { /* Grid 8pt */ }
  enum AppCornerRadius { /* small, medium, large, full */ }
  struct AppShadow { /* elevation1, elevation2, elevation3 */ }
  extension Text { /* helpers .appDisplayLarge(), etc */ }
  ```
- **Impacto:** Desbloquea todos los componentes y pantallas
- **Validación:** Build exitoso sin errores

##### ✅ **Tarea 1.2: Crear ColorSets en Assets.xcassets** (3 horas)
- **Archivos a crear en:** `PerfBeta/Assets.xcassets/Colors/`
- **30 ColorSets nuevos:**

  **Brand Colors:**
  - `brandPrimary.colorset` → Light: #1A1A1A, Dark: #F5F5F0
  - `brandAccent.colorset` → Universal: #C4A962

  **Background Colors (8):**
  - `backgroundPrimary` → Light: #FFFFFF, Dark: #1A1A1A
  - `backgroundSecondary` → Light: #F5F5F0, Dark: #2A2A2A
  - `backgroundTertiary` → Light: #FAFAFA, Dark: #3A3A3A
  - `surfacePrimary`, `surfaceSecondary`, `surfaceElevated`, `surfaceCard`, `surfaceOverlay`

  **Text Colors (5):**
  - `textPrimary` → Light: #1A1A1A, Dark: #F5F5F0
  - `textSecondary` → Light: #4A4A4A, Dark: #B0B0B0
  - `textTertiary`, `textDisabled`, `textOnAccent`

  **Interactive Colors (9):**
  - `interactivePrimary`, `interactiveSecondary`, `interactiveHover`, `interactiveFocus`, `interactivePressed`, `interactiveDisabled`
  - `accentGold`, `accentGoldLight`, `accentGoldDark`

  **Feedback Colors (6):**
  - `feedbackSuccess`, `feedbackError`, `feedbackWarning`, `feedbackInfo`
  - `feedbackSuccessBackground`, `feedbackErrorBackground`

  **Border & Divider (2):**
  - `borderPrimary`, `dividerPrimary`

- **Cómo crear cada ColorSet:**
  1. Right-click en `Assets.xcassets` → New Color Set
  2. Nombre: exactamente como `AppColor` enum (`brandPrimary`, etc.)
  3. Configurar:
     - Appearances: Any, Light, Dark
     - Color Space: sRGB
     - Hex values según especificación

- **Impacto:** Dark Mode automático en toda la app
- **Validación:** Ver colores en preview SwiftUI

##### ✅ **Tarea 1.3: Crear AppButton component** (2 horas)
- **Archivo nuevo:** `PerfBeta/Components/AppButton.swift`
- **Qué hacer:** Copiar implementación completa de DESIGN_PROPOSAL.md
- **Features:**
  - 5 estilos (primary, secondary, tertiary, accent, destructive)
  - 3 tamaños (small, medium, large)
  - Estados: loading, disabled
  - Full width option
- **Impacto:** Reemplaza 8+ variantes de botones custom
- **Validación:** Preview en Xcode muestra todos los estilos

##### ✅ **Tarea 1.4: Migrar 5 botones de alta visibilidad** (1 hora)
**Archivos a modificar (quick wins):**

1. **LoginView.swift** (línea ~180)
   ```swift
   // ❌ ANTES
   Button(action: { viewModel.signIn() }) {
       Text("Iniciar Sesión")
           .font(.system(size: 18, weight: .semibold))
           .foregroundColor(.white)
   }
   .frame(height: 50)
   .background(Color(red: 0.8, green: 0.6, blue: 0.8))

   // ✅ DESPUÉS
   AppButton(
       title: "Iniciar Sesión",
       style: .primary,
       size: .large,
       isLoading: viewModel.isLoading,
       action: { viewModel.signIn() }
   )
   ```

2. **SignUpView.swift** (línea ~200)
   ```swift
   // Similar migration para botón "Crear Cuenta"
   AppButton(
       title: "Crear Cuenta",
       style: .primary,
       size: .large,
       isLoading: viewModel.isLoading,
       action: { viewModel.signUp() }
   )
   ```

3. **OlfactiveProfileViewModel.swift** (línea ~150)
   ```swift
   // Botón "Iniciar Test Olfativo"
   AppButton(
       title: "Iniciar Test Olfativo",
       style: .accent,
       size: .large,
       action: { showTest() }
   )
   ```

4. **AddPerfumeOnboardingView.swift** (línea ~80)
   ```swift
   // Botón "Añadir Perfume"
   AppButton(
       title: "Añadir Perfume",
       style: .primary,
       size: .medium,
       action: { addPerfume() }
   )
   ```

5. **SettingsView.swift** (línea ~120)
   ```swift
   // Botón "Cerrar Sesión"
   AppButton(
       title: "Cerrar Sesión",
       style: .destructive,
       size: .medium,
       action: { logout() }
   )
   ```

- **Impacto:** Cambio visual inmediato en pantallas clave
- **Validación:** Botones se ven consistentes y profesionales

#### **✅ CRITERIOS DE ÉXITO SPRINT 1:**
- [ ] ✅ **Sistema de temas eliminado** (Ajustes sin selector, todas las vistas usan degradado único)
- [ ] Build exitoso sin warnings
- [ ] DesignTokens.swift compilando (incluyendo AppGradient.brandGradient)
- [ ] 30 ColorSets creados con Light/Dark modes
- [ ] AppButton funcionando en 5 pantallas
- [ ] Preview en Xcode mostrando nuevos colores
- [ ] **Degradado único visible en Login/Home** (champán refinado o negro-dorado según decisión)

---

### 🎨 **SPRINT 2: COMPONENTES CORE**
**Duración:** 3-4 días
**Impacto:** 🔥🔥🔥🔥 (Alto - componentes más usados)
**Esfuerzo:** ⚡⚡⚡ (Medio - requiere refactor de código existente)

#### **OBJETIVO:**
Unificar los componentes más usados (tarjetas de perfume, text fields) y migrar Login/SignUp completos.

#### **TAREAS:**

##### ✅ **Tarea 2.1: Crear PerfumeCard unificado** (4 horas)
- **Archivo nuevo:** `PerfBeta/Components/PerfumeCard.swift`
- **Qué hacer:** Copiar implementación de DESIGN_PROPOSAL.md
- **Features:**
  - 3 variantes: `.standard`, `.compact`, `.minimal`
  - 3 tipos de badge: `.matchPercentage`, `.rating`, `.userRating`
  - Skeleton loading state
  - Lazy loading de imágenes con Kingfisher
- **Reemplaza estos archivos:**
  - `Views/HomeTab/PerfumeCarouselItem.swift` (línea 1-100)
  - `Views/PerfumeDetail/PerfumeCardView.swift` (línea 1-150)
  - `Views/TestTab/TestPerfumeCardView.swift` (línea 1-120)
  - `Views/Filter/FilterablePerfumeItem.swift` (línea 1-80)
- **Impacto:** Consistencia visual en toda la app + código reutilizable
- **Validación:** 4 pantallas usando el mismo componente

##### ✅ **Tarea 2.2: Migrar PerfumeCarouselItem → PerfumeCard** (2 horas)
**Archivos a modificar:**

1. **HomeTabView.swift** (línea ~200)
   ```swift
   // ❌ ANTES
   ScrollView(.horizontal) {
       LazyHStack(spacing: 16) {
           ForEach(perfumes) { perfume in
               PerfumeCarouselItem(perfume: perfume)
                   .frame(width: 280, height: 360)
           }
       }
   }

   // ✅ DESPUÉS
   ScrollView(.horizontal) {
       LazyHStack(spacing: AppSpacing.spacing16) {
           ForEach(perfumes) { perfume in
               PerfumeCard(
                   perfume: perfume,
                   variant: .standard,
                   badge: .matchPercentage(80)
               )
               .frame(width: 280)
           }
       }
   }
   ```

2. **SuggestionsView.swift** (línea ~150)
   ```swift
   // Mismo pattern para recomendaciones
   PerfumeCard(
       perfume: perfume,
       variant: .standard,
       badge: .matchPercentage(suggestion.matchPercentage)
   )
   ```

- **Impacto:** Home y Suggestions visualmente consistentes
- **Validación:** Tarjetas se ven idénticas en ambas pantallas

##### ✅ **Tarea 2.3: Crear AppTextField component** (3 horas)
- **Archivo nuevo:** `PerfBeta/Components/AppTextField.swift`
- **Qué hacer:** Copiar implementación de DESIGN_PROPOSAL.md
- **Features:**
  - 2 estilos: `.filled`, `.outlined`
  - Leading/trailing icons
  - Secure entry para passwords
  - Focus states con animación
  - Error states
- **Impacto:** Text fields profesionales con feedback visual
- **Validación:** Preview muestra todos los estados

##### ✅ **Tarea 2.4: Refactor COMPLETO de LoginView** (2 horas)
**Archivo:** `PerfBeta/Views/Login/LoginView.swift`

**Cambios completos:**

```swift
// ✅ NUEVO LoginView.swift (migración completa)
struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            // ❌ ELIMINAR: Gradiente purple
            // ✅ NUEVO: Background beige limpio
            AppColor.backgroundSecondary
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.spacing32) {
                Spacer()

                // Logo y título
                VStack(spacing: AppSpacing.spacing16) {
                    Image("Splash1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(
                            color: AppShadow.elevation2.color,
                            radius: AppShadow.elevation2.radius,
                            y: AppShadow.elevation2.y
                        )

                    Text("PerfBeta")
                        .font(AppTypography.displayMedium)
                        .foregroundColor(AppColor.textPrimary)

                    Text("Descubre tu fragancia perfecta")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColor.textSecondary)
                }

                // Form
                VStack(spacing: AppSpacing.spacing16) {
                    AppTextField(
                        text: $viewModel.email,
                        placeholder: "Correo electrónico",
                        style: .filled,
                        leadingIcon: "envelope.fill"
                    )

                    AppTextField(
                        text: $viewModel.password,
                        placeholder: "Contraseña",
                        style: .filled,
                        leadingIcon: "lock.fill",
                        isSecure: true
                    )

                    AppButton(
                        title: "Iniciar Sesión",
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.isLoading,
                        action: { viewModel.signIn() }
                    )

                    // Divider
                    HStack(spacing: AppSpacing.spacing12) {
                        Divider()
                            .frame(height: 1)
                            .background(AppColor.dividerPrimary)
                        Text("o")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColor.textTertiary)
                        Divider()
                            .frame(height: 1)
                            .background(AppColor.dividerPrimary)
                    }

                    AppButton(
                        title: "Continuar con Google",
                        style: .secondary,
                        size: .large,
                        leadingIcon: "google",
                        action: { viewModel.signInWithGoogle() }
                    )
                }
                .padding(.horizontal, AppSpacing.spacing24)

                // Footer
                Button {
                    showSignUp = true
                } label: {
                    HStack(spacing: AppSpacing.spacing4) {
                        Text("¿No tienes cuenta?")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColor.textSecondary)
                        Text("Regístrate")
                            .font(AppTypography.bodyMediumBold)
                            .foregroundColor(AppColor.accentGold)
                    }
                }

                Spacer()
            }
        }
    }
}
```

**Líneas a cambiar:**
- Eliminar todo el gradient code (líneas 30-50)
- Reemplazar todos los `Color(red:green:blue:)` con `AppColor.*`
- Reemplazar todos los `.font(.system(size:))` con `AppTypography.*`
- Reemplazar todos los números de spacing con `AppSpacing.*`
- Migrar botones a `AppButton`
- Migrar text fields a `AppTextField`

- **Impacto:** Primera impresión profesional de la app
- **Validación:** Login se ve elegante y premium

##### ✅ **Tarea 2.5: Refactor COMPLETO de SignUpView** (2 horas)
**Archivo:** `PerfBeta/Views/Login/SignUpView.swift`

**Cambios similares a LoginView:**
- Mismo background beige (`AppColor.backgroundSecondary`)
- Migrar 3 text fields (nombre, email, password) a `AppTextField`
- Migrar botón "Crear Cuenta" a `AppButton.primary`
- Usar `AppTypography.*` para todos los textos
- Usar `AppSpacing.*` para todo el layout

- **Impacto:** Onboarding consistente con Login
- **Validación:** Flujo Login → SignUp visualmente cohesivo

#### **✅ CRITERIOS DE ÉXITO SPRINT 2:**
- [ ] PerfumeCard funcionando en 4+ pantallas
- [ ] Login y SignUp 100% migrados al design system
- [ ] Zero colores hardcoded en Login/SignUp
- [ ] Zero tamaños de font inline en Login/SignUp
- [ ] Dark Mode funcionando perfectamente en Login/SignUp

---

### 🏠 **SPRINT 3: PANTALLAS PRINCIPALES**
**Duración:** 5-6 días
**Impacto:** 🔥🔥🔥🔥 (Alto - pantallas más usadas)
**Esfuerzo:** ⚡⚡⚡⚡ (Alto - muchos archivos y detalles)

#### **OBJETIVO:**
Refactorizar las 4 tabs principales (Home, Explorar, Test, Mi Colección) para usar el design system.

#### **TAREAS:**

##### ✅ **Tarea 3.1: Refactor HomeTabView** (1 día)
**Archivos a modificar:**
- `Views/HomeTab/HomeTabView.swift` (~400 líneas)
- `Views/HomeTab/RecommendedSection.swift` (~150 líneas)

**Cambios específicos:**

1. **Header "Descubre tu fragancia" (línea ~50)**
   ```swift
   // ❌ ANTES
   Text("Descubre tu fragancia ideal")
       .font(.system(size: 28, weight: .bold))
       .foregroundColor(.primary)

   // ✅ DESPUÉS
   Text("Descubre tu fragancia ideal")
       .font(AppTypography.headlineLarge)
       .foregroundColor(AppColor.textPrimary)
   ```

2. **Spacing del VStack principal (línea ~40)**
   ```swift
   // ❌ ANTES
   VStack(spacing: 20) { ... }

   // ✅ DESPUÉS
   VStack(spacing: AppSpacing.spacing20) { ... }
   ```

3. **Tarjetas de perfume (línea ~200)**
   ```swift
   // Ya hecho en Sprint 2.2, verificar que usa PerfumeCard
   ```

4. **Botón "Ver todos" (línea ~180)**
   ```swift
   // ❌ ANTES
   Button("Ver todos") { ... }
       .font(.system(size: 14, weight: .medium))
       .foregroundColor(.blue)

   // ✅ DESPUÉS
   Button("Ver todos") { ... }
       .font(AppTypography.labelLarge)
       .foregroundColor(AppColor.accentGold)
   ```

5. **Background color (línea ~30)**
   ```swift
   // ❌ ANTES
   .background(Color(UIColor.systemBackground))

   // ✅ DESPUÉS
   .background(AppColor.backgroundPrimary)
   ```

- **Impacto:** Home es la pantalla más vista, cambio muy visible
- **Validación:**
  - Zero inline fonts
  - Zero hardcoded colors
  - PerfumeCard usado en todos los carousels
  - Dark Mode sin bugs

##### ✅ **Tarea 3.2: Refactor ExploreTabView** (1 día)
**Archivos a modificar:**
- `Views/ExploreTab/ExploreTabView.swift` (~300 líneas)
- `Views/Filter/PerfumeFilterView.swift` (~500 líneas)

**Cambios específicos:**

1. **Search bar (línea ~60)**
   ```swift
   // ❌ ANTES
   TextField("Buscar perfume o marca", text: $searchText)
       .padding(12)
       .background(Color.gray.opacity(0.1))
       .cornerRadius(10)

   // ✅ DESPUÉS
   AppTextField(
       text: $searchText,
       placeholder: "Buscar perfume o marca",
       style: .filled,
       leadingIcon: "magnifyingglass"
   )
   ```

2. **Filter chips (línea ~100)**
   ```swift
   // ❌ ANTES
   Text(filter.name)
       .font(.system(size: 14))
       .padding(.horizontal, 16)
       .padding(.vertical, 8)
       .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
       .cornerRadius(20)

   // ✅ DESPUÉS
   Text(filter.name)
       .font(AppTypography.labelMedium)
       .padding(.horizontal, AppSpacing.spacing16)
       .padding(.vertical, AppSpacing.spacing8)
       .background(isSelected ? AppColor.accentGold : AppColor.surfaceSecondary)
       .cornerRadius(AppCornerRadius.full)
   ```

3. **Grid de perfumes (línea ~200)**
   ```swift
   // Usar PerfumeCard.compact en grid
   LazyVGrid(
       columns: [
           GridItem(.flexible(), spacing: AppSpacing.spacing16),
           GridItem(.flexible(), spacing: AppSpacing.spacing16)
       ],
       spacing: AppSpacing.spacing16
   ) {
       ForEach(perfumes) { perfume in
           PerfumeCard(
               perfume: perfume,
               variant: .compact,
               badge: .rating
           )
       }
   }
   ```

- **Impacto:** Explorar es la pantalla de búsqueda principal
- **Validación:**
  - Search bar profesional
  - Filter chips con accent gold
  - Grid consistente con Home

##### ✅ **Tarea 3.3: Refactor Test Olfativo (ProfileManagementView)** (1 día)
**Archivos a modificar:**
- `Views/TestTab/ProfileManagementView.swift` (~200 líneas)
- `Views/TestTab/TestSaveProfileView.swift` (~250 líneas)
- `Views/TestTab/SuggestionsView.swift` (~300 líneas)

**Cambios específicos:**

1. **TestSaveProfileView - Question cards (línea ~100)**
   ```swift
   // ❌ ANTES
   VStack(alignment: .leading, spacing: 12) {
       Text(question.text)
           .font(.system(size: 20, weight: .semibold))

       ForEach(question.options) { option in
           Button { selectOption(option) } label: {
               HStack {
                   Text(option.label)
                       .font(.system(size: 16))
                   Spacer()
                   if isSelected(option) {
                       Image(systemName: "checkmark.circle.fill")
                           .foregroundColor(.blue)
                   }
               }
               .padding(16)
               .background(Color.gray.opacity(0.1))
               .cornerRadius(12)
           }
       }
   }

   // ✅ DESPUÉS
   VStack(alignment: .leading, spacing: AppSpacing.spacing12) {
       Text(question.text)
           .font(AppTypography.titleLarge)
           .foregroundColor(AppColor.textPrimary)

       ForEach(question.options) { option in
           Button { selectOption(option) } label: {
               HStack {
                   Text(option.label)
                       .font(AppTypography.bodyLarge)
                       .foregroundColor(AppColor.textPrimary)
                   Spacer()
                   if isSelected(option) {
                       Image(systemName: "checkmark.circle.fill")
                           .foregroundColor(AppColor.accentGold)
                   }
               }
               .padding(AppSpacing.spacing16)
               .background(
                   isSelected(option)
                       ? AppColor.surfaceElevated
                       : AppColor.surfaceSecondary
               )
               .cornerRadius(AppCornerRadius.medium)
           }
       }
   }
   ```

2. **SuggestionsView - Results (línea ~150)**
   ```swift
   // Usar PerfumeCard con matchPercentage badge
   PerfumeCard(
       perfume: suggestion.perfume,
       variant: .standard,
       badge: .matchPercentage(suggestion.matchPercentage)
   )
   ```

3. **Botón "Guardar Perfil" (línea ~300)**
   ```swift
   // Ya migrado en Sprint 1.4
   AppButton(
       title: "Guardar Perfil",
       style: .accent,
       size: .large,
       action: { saveProfile() }
   )
   ```

- **Impacto:** Test es feature diferenciadora, debe verse premium
- **Validación:**
  - Question cards elegantes
  - Match percentage visible en resultados
  - Flujo completo sin colores hardcoded

##### ✅ **Tarea 3.4: Refactor Mi Colección** (1.5 días)
**Archivos a modificar:**
- `Views/LibraryTab/FragranceLibraryTabView.swift` (~400 líneas)
- `Views/LibraryTab/TriedPerfumesListView.swift` (~300 líneas)
- `Views/LibraryTab/WishlistListView.swift` (~250 líneas)

**Cambios específicos:**

1. **FragranceLibraryTabView - Tabs (línea ~50)**
   ```swift
   // ❌ ANTES
   Picker("", selection: $selectedTab) { ... }
       .pickerStyle(SegmentedPickerStyle())
       .padding()

   // ✅ DESPUÉS
   Picker("", selection: $selectedTab) { ... }
       .pickerStyle(SegmentedPickerStyle())
       .padding(AppSpacing.spacing16)
       .background(AppColor.backgroundPrimary)
   ```

2. **Empty state (línea ~200)**
   ```swift
   // ❌ ANTES
   VStack(spacing: 16) {
       Image(systemName: "tray")
           .font(.system(size: 60))
           .foregroundColor(.gray)
       Text("No has añadido perfumes")
           .font(.system(size: 18, weight: .medium))
       Text("Añade tus primeros perfumes")
           .font(.system(size: 14))
           .foregroundColor(.secondary)
   }

   // ✅ DESPUÉS (usar component de DESIGN_PROPOSAL.md)
   AppEmptyState(
       icon: "tray",
       title: "No has añadido perfumes",
       message: "Añade tus primeros perfumes a tu colección",
       action: AppEmptyState.Action(
           title: "Explorar Perfumes",
           action: { goToExplore() }
       )
   )
   ```

3. **List items (línea ~250)**
   ```swift
   // Usar PerfumeCard.minimal para listas
   ForEach(triedPerfumes) { record in
       PerfumeCard(
           perfume: record.perfume,
           variant: .minimal,
           badge: .userRating(record.userRating ?? 0)
       )
   }
   ```

4. **Botón "Añadir Perfume" (línea ~100)**
   ```swift
   AppButton(
       title: "Añadir Perfume",
       style: .accent,
       size: .medium,
       leadingIcon: "plus",
       action: { showAddPerfume() }
   )
   ```

- **Impacto:** Biblioteca personal es feature core
- **Validación:**
  - Empty states profesionales
  - List items consistentes
  - User ratings visibles

##### ✅ **Tarea 3.5: Refactor SettingsView** (0.5 días)
**Archivo:** `Views/SettingsTab/SettingsView.swift` (~200 líneas)

**Cambios específicos:**

1. **Settings rows (línea ~80)**
   ```swift
   // ❌ ANTES
   NavigationLink {
       ProfileView()
   } label: {
       HStack {
           Image(systemName: "person.circle")
           Text("Perfil")
               .font(.system(size: 16))
           Spacer()
           Image(systemName: "chevron.right")
               .foregroundColor(.gray)
       }
       .padding()
   }

   // ✅ DESPUÉS
   NavigationLink {
       ProfileView()
   } label: {
       HStack(spacing: AppSpacing.spacing12) {
           Image(systemName: "person.circle")
               .foregroundColor(AppColor.accentGold)
           Text("Perfil")
               .font(AppTypography.bodyLarge)
               .foregroundColor(AppColor.textPrimary)
           Spacer()
           Image(systemName: "chevron.right")
               .foregroundColor(AppColor.textTertiary)
       }
       .padding(AppSpacing.spacing16)
   }
   .background(AppColor.surfaceCard)
   .cornerRadius(AppCornerRadius.medium)
   ```

2. **Botón "Cerrar Sesión" (línea ~200)**
   ```swift
   // Ya migrado en Sprint 1.4
   AppButton(
       title: "Cerrar Sesión",
       style: .destructive,
       size: .medium,
       action: { logout() }
   )
   ```

- **Impacto:** Settings más profesional
- **Validación:** Navegación clara y elegante

#### **✅ CRITERIOS DE ÉXITO SPRINT 3:**
- [ ] 4 tabs principales 100% migradas
- [ ] Zero inline fonts en HomeTab, ExploreTab, TestTab, LibraryTab
- [ ] Zero hardcoded colors en las 4 tabs
- [ ] PerfumeCard usado en todas las listas/grids
- [ ] AppEmptyState usado en estados vacíos
- [ ] Dark Mode sin bugs en las 4 tabs

---

### ✨ **SPRINT 4: POLISH & ANIMACIONES**
**Duración:** 2-3 días
**Impacto:** 🔥🔥🔥 (Medio-Alto - detalles que hacen diferencia)
**Esfuerzo:** ⚡⚡⚡ (Medio - mayormente ajustes)

#### **OBJETIVO:**
Añadir transiciones, animaciones, loading states y toques finales de polish.

#### **TAREAS:**

##### ✅ **Tarea 4.1: Implementar AppTransition** (0.5 días)
**Archivo nuevo:** `PerfBeta/Utils/AppTransition.swift`

```swift
enum AppTransition {
    static let fast = Animation.easeInOut(duration: 0.2)
    static let medium = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
```

**Aplicar en:**
- Navigation transitions (todas las NavigationLink)
- Botones con hover/press states
- Sheet presentations
- Loading states

- **Impacto:** App se siente fluida y moderna
- **Validación:** Todas las transiciones suaves

##### ✅ **Tarea 4.2: Implementar AppLoadingView** (0.5 días)
**Archivo nuevo:** `PerfBeta/Components/AppLoadingView.swift`

**Copiar implementación de DESIGN_PROPOSAL.md**

**Usar en:**
- `PerfumeService.swift` cuando carga perfumes (línea ~100)
- `AuthViewModel.swift` cuando hace login (línea ~80)
- `OlfactiveProfileViewModel.swift` cuando calcula matches (línea ~150)

```swift
// Reemplazar ProgressView() genéricos con:
if isLoading {
    AppLoadingView(message: "Cargando perfumes...")
}
```

- **Impacto:** Loading states elegantes y con branding
- **Validación:** Spinner gold con mensaje claro

##### ✅ **Tarea 4.3: Añadir Haptic Feedback** (0.5 días)
**Archivos a modificar:**
- `Components/AppButton.swift` (línea ~50)
- `Views/HomeTab/PerfumeCard.swift` (línea ~80)

```swift
// En AppButton.swift
Button(action: {
    // ✅ AÑADIR haptic feedback
    let impactLight = UIImpactFeedbackGenerator(style: .light)
    impactLight.impactOccurred()

    action()
}) { ... }

// En PerfumeCard tap
.onTapGesture {
    let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    impactMedium.impactOccurred()

    navigateToPerfume()
}
```

- **Impacto:** Feedback táctil hace app más responsive
- **Validación:** Tap en botones y tarjetas da vibración sutil

##### ✅ **Tarea 4.4: Mejorar PerfumeDetailView** (1 día)
**Archivo:** `Views/PerfumeDetail/PerfumeDetailView.swift` (~600 líneas)

**Cambios específicos:**

1. **Hero image con parallax (línea ~80)**
   ```swift
   // ✅ AÑADIR parallax scroll effect
   GeometryReader { geometry in
       KFImage(perfume.imageURL.flatMap { URL(string: $0) })
           .resizable()
           .scaledToFill()
           .frame(height: 400)
           .offset(y: -geometry.frame(in: .global).minY * 0.5)
   }
   .frame(height: 400)
   ```

2. **Action buttons (línea ~200)**
   ```swift
   HStack(spacing: AppSpacing.spacing12) {
       AppButton(
           title: "Añadir a Biblioteca",
           style: .primary,
           size: .large,
           fullWidth: true,
           action: { addToLibrary() }
       )

       AppButton(
           title: "",
           style: .secondary,
           size: .large,
           leadingIcon: "heart\(isWishlisted ? ".fill" : "")",
           action: { toggleWishlist() }
       )
   }
   ```

3. **Notes section (línea ~300)**
   ```swift
   VStack(alignment: .leading, spacing: AppSpacing.spacing16) {
       Text("Notas Olfativas")
           .font(AppTypography.titleMedium)
           .foregroundColor(AppColor.textPrimary)

       // Top notes
       NotesPill(notes: perfume.topNotes, type: .top)

       // Heart notes
       NotesPill(notes: perfume.heartNotes, type: .heart)

       // Base notes
       NotesPill(notes: perfume.baseNotes, type: .base)
   }
   ```

- **Impacto:** Detail es donde usuario decide añadir perfume
- **Validación:**
  - Parallax funciona en scroll
  - Botones claros y accesibles
  - Notas organizadas visualmente

##### ✅ **Tarea 4.5: Mejorar onboarding images** (0.5 días)
**Archivos a modificar:**
- `Views/TestTab/TestSaveProfileView.swift` (línea ~50)

**Problema actual:** Imágenes de preguntas (alta.jpg, media.jpg, etc.) no tienen tratamiento visual.

**Solución:**
```swift
// ❌ ANTES
Image(question.imageName)
    .resizable()
    .scaledToFit()
    .frame(height: 200)

// ✅ DESPUÉS
ZStack(alignment: .bottomLeading) {
    Image(question.imageName)
        .resizable()
        .scaledToFill()
        .frame(height: 300)
        .clipped()
        .overlay(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .center
            )
        )

    // Label sobre la imagen
    Text(question.text)
        .font(AppTypography.headlineMedium)
        .foregroundColor(.white)
        .padding(AppSpacing.spacing20)
}
.cornerRadius(AppCornerRadius.large)
.shadow(
    color: AppShadow.elevation2.color,
    radius: AppShadow.elevation2.radius,
    y: AppShadow.elevation2.y
)
```

- **Impacto:** Onboarding más visual e inmersivo
- **Validación:** Imágenes con overlay y texto legible

#### **✅ CRITERIOS DE ÉXITO SPRINT 4:**
- [ ] Todas las transiciones son suaves
- [ ] Loading states branded en 3+ pantallas
- [ ] Haptic feedback en botones y tarjetas
- [ ] PerfumeDetailView con parallax y botones claros
- [ ] Onboarding images con tratamiento visual

---

## 📈 PROGRESO ESTIMADO POR SPRINT

```
Sprint 1 (Fundación)     ████████░░ 20% complete → 40%
Sprint 2 (Componentes)   ████████░░ 40% complete → 65%
Sprint 3 (Pantallas)     ████████░░ 65% complete → 90%
Sprint 4 (Polish)        ██████████ 90% complete → 100%
```

**Hitos de calidad de diseño:**
- **Antes:** 4.2/10
- **Después Sprint 1:** 5.5/10 (fundación sólida)
- **Después Sprint 2:** 7.0/10 (componentes core listos)
- **Después Sprint 3:** 8.5/10 (app completa rediseñada)
- **Después Sprint 4:** 9.0/10 (polish profesional)

---

## 🎯 ESTRATEGIA DE IMPLEMENTACIÓN

### **Enfoque Recomendado: "Bottom-Up"**

1. **Sprint 1 primero (SIEMPRE):** No se puede hacer nada sin DesignTokens.swift
2. **Sprint 2 segundo:** Componentes desbloquean Sprint 3
3. **Sprint 3 en paralelo:** Una persona puede hacer HomeTab mientras otra hace ExploreTab
4. **Sprint 4 al final:** Polish cuando todo lo demás esté listo

### **Si tienes solo 1 desarrollador:**
- Hacer sprints en orden secuencial
- Dentro de Sprint 3, priorizar: Home → Explorar → Mi Colección → Test → Settings

### **Si tienes 2+ desarrolladores:**
- Dev 1: Sprint 1 completo (bloquea a todos)
- Dev 2: Mientras tanto, preparar assets (imágenes, iconos)
- Después Sprint 1:
  - Dev 1: Sprint 2 (componentes)
  - Dev 2: Sprint 3.1 + 3.2 (Home + Explorar)
- Sprint 4: Ambos en paralelo (animaciones + polish)

---

## 🚨 RIESGOS Y MITIGACIONES

### **Riesgo 1: Merge conflicts en Assets.xcassets**
- **Mitigación:** Crear todos los 30 ColorSets en Sprint 1 de una vez
- **Plan B:** Usar Git LFS para Assets.xcassets

### **Riesgo 2: Regresiones visuales**
- **Mitigación:** Screenshots antes/después de cada sprint
- **Plan B:** Feature flags para habilitar nuevo design system gradualmente

### **Riesgo 3: Performance de PerfumeCard**
- **Mitigación:** Lazy loading ya implementado
- **Plan B:** Si lag, usar `.onAppear` threshold para cargar imágenes

### **Riesgo 4: Dark Mode bugs**
- **Mitigación:** Testear AMBOS modes después de cada tarea
- **Plan B:** Si problemas, deshabilitar Dark Mode temporalmente

---

## ✅ CHECKLIST FINAL (Post-Implementación)

### **Calidad de Código:**
- [ ] Zero inline fonts (todos usan `AppTypography.*`)
- [ ] Zero hardcoded colors (todos usan `AppColor.*`)
- [ ] Zero hardcoded spacing (todos usan `AppSpacing.*`)
- [ ] Zero warnings de compilación
- [ ] Código SwiftLint compliant (si se usa)

### **Funcionalidad:**
- [ ] Todas las pantallas funcionan sin crashes
- [ ] Botones responden correctamente
- [ ] Navegación fluye sin problemas
- [ ] Formularios validan inputs
- [ ] Loading states no bloquean UI

### **Accesibilidad:**
- [ ] Dark Mode funciona en todas las pantallas
- [ ] Dynamic Type soportado (textos escalan)
- [ ] VoiceOver labels en elementos interactivos
- [ ] Touch targets mínimo 44x44pt
- [ ] Contraste de color AA (4.5:1 mínimo)

### **Visual:**
- [ ] Consistencia de colores en todas las pantallas
- [ ] Consistencia de tipografía (mismos estilos)
- [ ] Spacing consistente (8pt grid visible)
- [ ] Sombras sutiles y profesionales
- [ ] Transiciones suaves

### **Performance:**
- [ ] App inicia en <2 segundos
- [ ] Scroll suave a 60fps
- [ ] Imágenes cargan con placeholders
- [ ] No memory leaks en Instruments
- [ ] Binary size <50MB

---

## 📊 MÉTRICAS DE ÉXITO

### **Métricas Cuantitativas:**
| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Inline fonts | ~150 | 0 | -100% |
| Hardcoded colors | ~200 | 0 | -100% |
| Component variants | 15+ | 5 | -66% |
| Líneas de código UI | ~8000 | ~5000 | -37% |
| Build warnings | ~10 | 0 | -100% |
| Dark Mode support | 30% | 100% | +70% |

### **Métricas Cualitativas:**
- **Consistencia Visual:** 3/10 → 9/10
- **Percepción de Calidad:** 4/10 → 9/10
- **Facilidad de Mantenimiento:** 5/10 → 9/10
- **Velocidad de Desarrollo:** 6/10 → 9/10

---

## 🎉 ENTREGA FINAL

### **Artefactos:**
1. ✅ `PerfBeta/Utils/DesignTokens.swift` (300+ líneas)
2. ✅ `PerfBeta/Assets.xcassets/Colors/` (30 ColorSets)
3. ✅ `PerfBeta/Components/AppButton.swift` (200 líneas)
4. ✅ `PerfBeta/Components/PerfumeCard.swift` (300 líneas)
5. ✅ `PerfBeta/Components/AppTextField.swift` (250 líneas)
6. ✅ `PerfBeta/Components/AppLoadingView.swift` (100 líneas)
7. ✅ `PerfBeta/Components/AppEmptyState.swift` (150 líneas)
8. ✅ `PerfBeta/Utils/AppTransition.swift` (50 líneas)
9. 📝 Documentación completa (DESIGN_AUDIT.md, DESIGN_PROPOSAL.md, DESIGN_ROADMAP.md)

### **Resultado Final:**
Una app iOS con **design system profesional**, consistencia visual del 95%+, soporte completo de Dark Mode, y fundación sólida para escalar el equipo.

---

**¿LISTO PARA EMPEZAR?**
Comienza por Sprint 1, Tarea 1.1: Crear `DesignTokens.swift` 🚀

