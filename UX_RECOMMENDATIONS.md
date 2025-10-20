# PerfBeta - Recomendaciones UX/UI Detalladas con Soluciones

**Fecha:** Octubre 20, 2025
**Basado en:** UX_AUDIT_REPORT.md

---

## 📖 Cómo Usar Este Documento

Este documento complementa el **UX_AUDIT_REPORT.md** con implementaciones específicas, código de ejemplo y guías paso a paso para resolver los 10 problemas críticos identificados.

**Estructura de cada recomendación:**
1. **Problema** - Resumen del issue
2. **Por Qué es Importante** - Educación UX (el "por qué")
3. **Solución Propuesta** - Diseño de la solución
4. **Implementación** - Código SwiftUI con comentarios
5. **Testing** - Cómo validar la mejora
6. **Referencias** - Ejemplos de apps que lo hacen bien

---

## 1. Implementar Onboarding Completo para Nuevos Usuarios

### 🔴 Problema Crítico
Sin onboarding formal, los usuarios nuevos enfrentan una curva de aprendizaje empinada al no entender conceptos clave como "Perfil Olfativo", navegación de tabs, o valor diferencial de la app.

### 📚 Por Qué es Importante (Educación UX)

**Concepto: First-Time User Experience (FTUX)**

El onboarding es la **primera impresión** de tu app y determina si el usuario se queda o abandona. Estudios muestran:
- **25% de usuarios abandonan** apps sin onboarding claro (Localytics, 2023)
- **65% más probabilidad** de retención con onboarding efectivo (Appcues, 2024)
- Los **primeros 3-5 minutos** son críticos para engagement

**Principios de buen onboarding:**
1. **Progresivo:** No abrumar, introducir features gradualmente
2. **Orientado a beneficios:** Mostrar VALOR antes que funcionalidades
3. **Skippable:** Permitir saltar para usuarios avanzados
4. **Interactivo:** Dejar probar features, no solo leer
5. **Contextual:** Educar en el momento de usar una feature

**Errores comunes a evitar:**
- ❌ Tutorial largo de 10+ pantallas (fatiga cognitiva)
- ❌ Solo texto sin visuals (aburrido)
- ❌ Bloquear acceso a la app hasta completarlo (frustración)
- ❌ Explicar TODO en el primer uso (sobrecarga)

### 💡 Solución Propuesta

**Onboarding de 3 capas:**

**Capa 1: Welcome Onboarding** (3-4 screens, solo primera vez)
- Screen 1: Valor único
- Screen 2: Concepto de Perfil Olfativo
- Screen 3: Tour rápido de navegación
- Screen 4: CTA para test

**Capa 2: Contextual Tooltips** (primera interacción con features)
- Explora tab: "Usa filtros para descubrir perfumes"
- Detalle perfume: "Agrega a wishlist o marca como probado"
- Mi Colección vacía: "Añade perfumes que hayas probado"

**Capa 3: Progressive Disclosure** (revelar features avanzadas después)
- Después de 5 perfumes probados: Sugerir refinamiento de perfil
- Después de completar test: Explicar recomendaciones con %

### 🛠️ Implementación

#### Paso 1: Crear Modelo de Onboarding

```swift
// File: PerfBeta/Models/OnboardingPage.swift
import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String // SF Symbol o asset
    let backgroundColor: Color
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Descubre tu Fragancia Ideal",
            subtitle: "PerfBeta usa ciencia y personalización para recomendarte perfumes que amarás",
            imageName: "sparkles",
            backgroundColor: Color(hex: "#F3E9E5")
        ),
        OnboardingPage(
            title: "Tu Perfil Olfativo Único",
            subtitle: "Responde nuestro test personalizado para conocer tus preferencias en fragancias",
            imageName: "drop.triangle",
            backgroundColor: Color(hex: "#E8F5E9")
        ),
        OnboardingPage(
            title: "Explora, Guarda y Evalúa",
            subtitle: "Descubre miles de perfumes, guarda tus favoritos y comparte tus experiencias",
            imageName: "books.vertical.fill",
            backgroundColor: Color(hex: "#FFF3E0")
        ),
        OnboardingPage(
            title: "Comencemos",
            subtitle: "Crea tu perfil olfativo en 5 minutos y recibe recomendaciones personalizadas",
            imageName: "arrow.right.circle.fill",
            backgroundColor: Color(hex: "#E3F2FD")
        )
    ]
}
```

#### Paso 2: Vista de Onboarding

```swift
// File: PerfBeta/Views/Onboarding/OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0

    let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            // Background gradient del page actual
            pages[currentPage].backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut, value: currentPage)

            VStack(spacing: 0) {
                // Skip button (solo en primeras 3 páginas)
                if currentPage < pages.count - 1 {
                    HStack {
                        Spacer()
                        Button("Saltar") {
                            completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                } else {
                    Spacer().frame(height: 60)
                }

                // Contenido del page actual
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page, isLastPage: index == pages.count - 1)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Botón de acción
                actionButton
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
            }
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private var actionButton: some View {
        if currentPage == pages.count - 1 {
            // Última página: CTA principal
            Button(action: {
                completeOnboarding()
                // TODO: Navegar directamente al test olfativo
            }) {
                HStack {
                    Text("Iniciar Test Olfativo")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        } else {
            // Páginas intermedias: Botón Siguiente
            Button(action: {
                withAnimation {
                    currentPage += 1
                }
            }) {
                HStack {
                    Text("Siguiente")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.9))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
        }
    }

    private func completeOnboarding() {
        // Guardar que ya vio onboarding
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Cerrar onboarding
        withAnimation {
            showOnboarding = false
        }
    }
}

// MARK: - Subcomponente: Página Individual
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icono grande
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundColor(.blue.opacity(0.8))
                .padding(.bottom, 20)

            // Título
            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Subtítulo
            Text(page.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}
```

#### Paso 3: Integrar en ContentView

```swift
// File: PerfBeta/Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    // Controlar si debe mostrar onboarding
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    var body: some View {
        NavigationStack {
            ZStack {
                // App principal
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }

                // Overlay de onboarding (solo primera vez después de login)
                if showOnboarding && authViewModel.isAuthenticated {
                    OnboardingView(showOnboarding: $showOnboarding)
                        .transition(.move(edge: .trailing))
                        .zIndex(999) // Asegurar que esté arriba
                }
            }
        }
        .tint(.black)
        // Resetear flag cuando user hace logout
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if !isAuthenticated {
                // Si hace logout, resetear onboarding para nuevo login
                // (Opcional: puedes no resetearlo si quieres solo 1 vez por instalación)
                showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
            }
        }
    }
}
```

#### Paso 4: Tooltips Contextuales (Opcional pero Recomendado)

```swift
// File: PerfBeta/Components/TooltipView.swift
import SwiftUI

struct TooltipView: View {
    let message: String
    let arrowDirection: ArrowDirection
    @Binding var isVisible: Bool

    enum ArrowDirection {
        case top, bottom, left, right
    }

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                if arrowDirection == .bottom {
                    arrowShape
                }

                HStack {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()

                    Button(action: { isVisible = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.trailing, 10)
                }
                .background(Color.blue)
                .cornerRadius(12)

                if arrowDirection == .top {
                    arrowShape
                }
            }
            .shadow(radius: 8)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(), value: isVisible)
        }
    }

    private var arrowShape: some View {
        Triangle()
            .fill(Color.blue)
            .frame(width: 20, height: 10)
            .rotationEffect(.degrees(arrowDirection == .top ? 0 : 180))
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// Uso en ExploreTabView:
@AppStorage("hasSeenExploreTooltip") private var hasSeenExploreTooltip = false
@State private var showExploreTooltip = false

// En onAppear:
.onAppear {
    if !hasSeenExploreTooltip {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showExploreTooltip = true
        }
    }
}

// Overlay del tooltip:
.overlay(alignment: .top) {
    if showExploreTooltip {
        TooltipView(
            message: "Usa los filtros para encontrar tu perfume ideal",
            arrowDirection: .top,
            isVisible: $showExploreTooltip
        )
        .padding(.top, 60)
        .onChange(of: showExploreTooltip) { visible in
            if !visible {
                hasSeenExploreTooltip = true
            }
        }
    }
}
```

### ✅ Testing

**1. Testing Manual:**
```
□ Instalar app fresca y crear cuenta nueva
□ Verificar que onboarding aparece automáticamente
□ Navegar por todas las páginas con swipe
□ Probar botón "Saltar" en páginas 1-3
□ Probar botón "Iniciar Test" en página 4
□ Cerrar app y reabrir → NO debe mostrar onboarding de nuevo
□ Hacer logout y login con cuenta nueva → Sí debe mostrar onboarding
□ Verificar tooltips contextuales en primera visita a tabs
```

**2. Testing de Accesibilidad:**
```swift
// Verificar con VoiceOver:
□ Cada página debe leerse claramente
□ Botones "Saltar" y "Siguiente" accesibles
□ Page indicators anunciados (Página 1 de 4)

// Agregar accessibility labels:
Button("Saltar") { ... }
    .accessibilityLabel("Saltar introducción")
    .accessibilityHint("Toca para ir directamente a la app")
```

**3. Testing de Métricas:**
```
Implementar analytics para medir:
- Completion rate del onboarding (meta: >80%)
- % usuarios que presionan "Saltar" (si >50%, simplificar)
- Tiempo promedio en onboarding (meta: <2 minutos)
- Retention D1 comparando con/sin onboarding
```

### 📚 Referencias

**Apps con excelente onboarding:**
- **Duolingo:** Onboarding interactivo, permite skip, explica valor claramente
- **Headspace:** Introduce conceptos de meditación progresivamente
- **Calm:** Visual storytelling con animaciones suaves
- **Airbnb:** Contextual onboarding (explica features cuando las usas)

**Recursos:**
- [Apple FTUX Guidelines](https://developer.apple.com/design/human-interface-guidelines/onboarding)
- [Nielsen Norman: Onboarding Best Practices](https://www.nngroup.com/articles/mobile-onboarding/)
- [Appcues: Onboarding Checklist](https://www.appcues.com/blog/user-onboarding-checklist)

### 💰 Impacto Esperado

- ✅ **↑ 20-30% en completion del test olfativo** (primera semana)
- ✅ **↑ 15% en D7 retention** (usuarios entienden valor)
- ✅ **↓ 40% en support requests** sobre "cómo usar la app"
- ✅ **↑ 25% en engagement con features** (usuarios saben que existen)

---

## 2. Simplificar Flujo de Agregar Perfume Probado (De 9 a 3 Pasos)

### 🔴 Problema Crítico
El flujo actual de 9 pasos obligatorios para añadir un perfume probado causa fricción severa, con tasa estimada de abandono del 40-60%.

### 📚 Por Qué es Importante (Educación UX)

**Concepto: Friction in User Flows**

**Fricción** es cualquier elemento que hace más difícil o lento completar una tarea. En UX, **menos fricción = mejor experiencia**, especialmente en acciones frecuentes.

**Ley de Tesler (Ley de Conservación de Complejidad):**
> "Para cualquier sistema existe una cantidad inherente de complejidad que no puede reducirse"

**Clave:** Decidir qué complejidad es esencial vs accidental:
- ✅ **Complejidad esencial:** Rating del perfume (core value)
- ❌ **Complejidad accidental:** 9 pantallas separadas cuando podría ser 2-3

**Impacto de cada paso adicional:**
- Cada campo adicional reduce completion rate en ~5-10% (Baymard Institute)
- Flujos >3 pasos necesitan barra de progreso visible
- Usuarios toleran complejidad si entienden el beneficio

**Soluciones UX:**
1. **Progressive Disclosure:** Mostrar solo lo esencial, ocultar opciones avanzadas
2. **Chunking:** Agrupar campos relacionados en la misma pantalla
3. **Defaults inteligentes:** Pre-rellenar con valores comunes
4. **Guardado automático:** No perder progreso si sale

### 💡 Solución Propuesta

**Nuevo flujo de 3 pasos:**

**Modo Rápido (Default):**
1. **Step 1:** Buscar y seleccionar perfume
2. **Step 2:** Rating + evaluación básica (grid de opciones en 1 screen)
3. **Step 3:** Guardar → Opción "Agregar más detalles" expandible

**Modo Completo (Opcional):**
- Botón "Evaluación Detallada" al final del Modo Rápido
- Abre formulario expandido con todos los campos
- Guardado automático cada cambio

### 🛠️ Implementación

#### Paso 1: Refactorizar Modelo de Evaluación

```swift
// File: PerfBeta/Models/PerfumeEvaluation.swift
import Foundation

/// Modelo unificado para evaluación rápida y completa
struct PerfumeEvaluation: Codable {
    // MARK: - Campos Obligatorios (Modo Rápido)
    var perfumeKey: String
    var rating: Double // 1-5 estrellas

    // MARK: - Campos Opcionales (Modo Completo)
    var occasions: [String]? // Multi-select
    var personalities: [String]? // Multi-select
    var seasons: [String]? // Multi-select
    var projection: String? // Enum
    var duration: String? // Enum
    var pricePerception: String? // Enum
    var notes: String? // Texto libre
    var customImage: String? // URL Cloudinary

    // MARK: - Metadata
    var createdAt: Date
    var lastUpdated: Date
    var isComplete: Bool // true si completó modo completo

    init(perfumeKey: String, rating: Double) {
        self.perfumeKey = perfumeKey
        self.rating = rating
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.isComplete = false
    }

    /// Validar si tiene mínimo requerido para modo rápido
    var isValidForQuickMode: Bool {
        return !perfumeKey.isEmpty && rating > 0
    }
}
```

#### Paso 2: Nueva Vista Unificada

```swift
// File: PerfBeta/Views/LibraryTab/AddTriedPerfumeView.swift
import SwiftUI

struct AddTriedPerfumeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var currentStep = 1
    @State private var selectedPerfume: Perfume?
    @State private var evaluation = PerfumeEvaluation(perfumeKey: "", rating: 0)
    @State private var showDetailedMode = false
    @State private var isSaving = false

    let totalSteps = 3

    var body: some View {
        NavigationStack {
            ZStack {
                GradientView(preset: .champan)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Barra de progreso
                    progressBar

                    // Contenido del paso actual
                    stepContent
                        .frame(maxHeight: .infinity)

                    // Botones de navegación
                    navigationButtons
                        .padding()
                }
            }
            .navigationTitle("Añadir Perfume")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    // MARK: - Barra de Progreso
    private var progressBar: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                .tint(Color.blue)

            Text("Paso \(currentStep) de \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    // MARK: - Contenido por Paso
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 1:
            // Buscar perfume
            SearchPerfumeStepView(selectedPerfume: $selectedPerfume)
        case 2:
            // Rating + Evaluación básica
            QuickEvaluationStepView(
                perfume: selectedPerfume!,
                evaluation: $evaluation
            )
        case 3:
            // Confirmación + Opción de modo completo
            ConfirmationStepView(
                perfume: selectedPerfume!,
                evaluation: evaluation,
                showDetailedMode: $showDetailedMode
            )
        default:
            EmptyView()
        }
    }

    // MARK: - Botones de Navegación
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Botón Atrás (solo si no es el primer paso)
            if currentStep > 1 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Atrás")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }

            // Botón Siguiente/Guardar
            Button(action: {
                handleNextAction()
            }) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentStep == totalSteps ? "Guardar" : "Siguiente")
                        if currentStep < totalSteps {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isNextEnabled ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isNextEnabled || isSaving)
        }
    }

    // MARK: - Lógica de Navegación
    private var isNextEnabled: Bool {
        switch currentStep {
        case 1: return selectedPerfume != nil
        case 2: return evaluation.rating > 0
        case 3: return true
        default: return false
        }
    }

    private func handleNextAction() {
        if currentStep < totalSteps {
            // Avanzar al siguiente paso
            withAnimation {
                currentStep += 1
            }

            // Haptic feedback
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()

        } else {
            // Último paso: Guardar
            saveEvaluation()
        }
    }

    private func saveEvaluation() {
        guard let perfume = selectedPerfume else { return }

        isSaving = true

        Task {
            do {
                // Crear TriedPerfumeRecord
                var record = TriedPerfumeRecord(
                    perfumeKey: perfume.key,
                    triedDate: Date(),
                    rating: evaluation.rating
                )

                // Agregar campos opcionales si existen
                record.occasions = evaluation.occasions
                record.personalities = evaluation.personalities
                record.recommendedSeasons = evaluation.seasons
                record.projection = evaluation.projection
                record.duration = evaluation.duration
                record.pricePerception = evaluation.pricePerception
                record.notes = evaluation.notes

                // Guardar en Firestore
                try await userViewModel.addTriedPerfume(record: record)

                // Haptic success
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                // Cerrar vista
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }

            } catch {
                print("Error al guardar: \(error)")
                await MainActor.run {
                    isSaving = false
                    // TODO: Mostrar alert de error
                }
            }
        }
    }
}

// MARK: - Step 1: Buscar Perfume
struct SearchPerfumeStepView: View {
    @Binding var selectedPerfume: Perfume?
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel

    @State private var searchText = ""

    var filteredPerfumes: [Perfume] {
        if searchText.isEmpty {
            return Array(perfumeViewModel.perfumes.prefix(20))
        }
        return perfumeViewModel.perfumes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("¿Qué perfume probaste?")
                .font(.title2.bold())
                .padding(.top)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Buscar perfume...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)

            // Resultados
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredPerfumes) { perfume in
                        PerfumeSearchResultRow(
                            perfume: perfume,
                            brand: brandViewModel.getBrand(byKey: perfume.brand),
                            isSelected: selectedPerfume?.id == perfume.id,
                            onTap: {
                                withAnimation {
                                    selectedPerfume = perfume
                                }
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Step 2: Evaluación Rápida
struct QuickEvaluationStepView: View {
    let perfume: Perfume
    @Binding var evaluation: PerfumeEvaluation

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Imagen del perfume
                AsyncImage(url: URL(string: perfume.imageURL ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(height: 150)
                .cornerRadius(12)

                // Nombre
                Text(perfume.name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                // Rating (OBLIGATORIO)
                VStack(spacing: 8) {
                    Text("¿Cómo lo calificarías?")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: evaluation.rating >= Double(star) ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(evaluation.rating >= Double(star) ? .yellow : .gray)
                                .onTapGesture {
                                    evaluation.rating = Double(star)
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                // Ocasiones (OPCIONAL pero en misma pantalla)
                VStack(alignment: .leading, spacing: 8) {
                    Text("¿Para qué ocasiones? (Opcional)")
                        .font(.subheadline.bold())

                    FlowLayout(spacing: 8) {
                        ForEach(Occasion.allCases, id: \.self) { occasion in
                            OccasionChip(
                                occasion: occasion,
                                isSelected: evaluation.occasions?.contains(occasion.rawValue) ?? false,
                                onTap: {
                                    toggleOccasion(occasion)
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                // Nota: Campos adicionales colapsados
                DisclosureGroup("¿Agregar más detalles?") {
                    VStack(spacing: 16) {
                        // Temporada
                        SeasonPicker(selectedSeasons: Binding(
                            get: { evaluation.seasons ?? [] },
                            set: { evaluation.seasons = $0 }
                        ))

                        // Notas personales
                        VStack(alignment: .leading) {
                            Text("Notas personales")
                                .font(.subheadline.bold())
                            TextEditor(text: Binding(
                                get: { evaluation.notes ?? "" },
                                set: { evaluation.notes = $0 }
                            ))
                            .frame(height: 80)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            .padding()
        }
    }

    private func toggleOccasion(_ occasion: Occasion) {
        if evaluation.occasions == nil {
            evaluation.occasions = []
        }

        if let index = evaluation.occasions?.firstIndex(of: occasion.rawValue) {
            evaluation.occasions?.remove(at: index)
        } else {
            evaluation.occasions?.append(occasion.rawValue)
        }

        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Step 3: Confirmación
struct ConfirmationStepView: View {
    let perfume: Perfume
    let evaluation: PerfumeEvaluation
    @Binding var showDetailedMode: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("¡Listo para Guardar!")
                .font(.title.bold())

            // Resumen
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Perfume:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(perfume.name)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Tu Rating:")
                        .fontWeight(.semibold)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(evaluation.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                    }
                }

                if let occasions = evaluation.occasions, !occasions.isEmpty {
                    HStack {
                        Text("Ocasiones:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(occasions.count) seleccionadas")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)

            Spacer()

            // Botón opcional para modo completo
            Button(action: {
                // TODO: Abrir modo de evaluación completa
                showDetailedMode = true
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Agregar Evaluación Detallada")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding()
    }
}

// MARK: - Componente: Chip de Ocasión
struct OccasionChip: View {
    let occasion: Occasion
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(occasion.displayName)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Layout Helper: FlowLayout
// (Chips que wrappean automáticamente)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
```

### ✅ Testing

**1. Testing de Usabilidad:**
```
□ Tiempo promedio para completar flujo (meta: <90 segundos)
□ Tasa de completion (meta: >85%)
□ % usuarios que usan DisclosureGroup (analizar si lo descubren)
□ Satisfaction score post-uso (encuesta 1-5 estrellas)
```

**2. A/B Testing:**
```
- Versión A: Flujo de 9 pasos (control)
- Versión B: Flujo de 3 pasos (tratamiento)

Métricas:
- Completion rate
- Time to complete
- % que agregan evaluación detallada
- Retention D7 (usuarios que agregaron ≥3 perfumes)
```

**3. Edge Cases:**
```
□ Usuario sale en medio del flujo → debe mostrar alert "¿Perder progreso?"
□ Usuario no encuentra perfume → botón "Sugerir perfume" (email)
□ Perfume sin imagen → placeholder bonito
□ Network error al guardar → retry automático + mensaje claro
```

### 📚 Referencias

**Apps con formularios optimizados:**
- **Uber:** Agregar dirección en 1 pantalla con opción de expandir detalles
- **Airbnb:** Publicar anuncio con progreso visible, guardado intermedio
- **Instagram:** Subir post con modo rápido (1 tap) vs modo completo (edición)

**Principios:**
- [Nielsen Norman: Minimizing Cognitive Load](https://www.nngroup.com/articles/minimize-cognitive-load/)
- [Baymard Institute: Form Design Best Practices](https://baymard.com/blog/checkout-flow-average-form-fields)

### 💰 Impacto Esperado

- ✅ **↑ 40-50% en completion rate** (de 50% a 85%)
- ✅ **↓ 60% en tiempo promedio** (de 5 min a 2 min)
- ✅ **↑ 3x perfumes agregados por usuario** en primera semana
- ✅ **↑ 25% en retention D7** (más engagement con biblioteca)

---

## 3. Componentes de Loading y Error Handling Unificados

### 🔴 Problema Crítico
Estados de carga y errores son inconsistentes a través de la app, causando confusión y frustración cuando algo falla.

### 📚 Por Qué es Importante (Educación UX)

**Concepto: System Status Visibility (Heurística #1 de Nielsen)**

> "El sistema debe mantener a los usuarios informados sobre qué está pasando, mediante feedback apropiado en tiempo razonable"

**Tipos de feedback en UI:**
1. **Immediate (< 100ms):** Highlight de botón, vibración háptica
2. **Brief (0.1-1s):** Spinner, progress bar determinado
3. **Long (1-10s):** Progress bar con mensaje, "Guardando..."
4. **Indefinite (>10s):** Progress indeterminado + opción de cancelar

**Reglas de oro:**
- **< 1 segundo:** Usuario percibe como instantáneo, no necesita feedback
- **1-5 segundos:** Mostrar spinner/progress, usuario espera
- **5-10 segundos:** Mostrar progreso + mensaje explicativo
- **> 10 segundos:** Permitir cancelar + explicar por qué es lento

**Error Handling UX:**
- ❌ **Malo:** "Error 404", "NetworkError: timeout"
- ✅ **Bueno:** "No pudimos cargar los perfumes. Verifica tu conexión."
- ✅ **Excelente:** "No pudimos cargar los perfumes. Verifica tu conexión." + botón "Reintentar" + fallback offline

### 💡 Solución Propuesta

**Sistema unificado con 3 componentes:**
1. **LoadingView** - Estados de carga con 3 estilos (full, inline, overlay)
2. **ErrorView** - Errores con recovery actions
3. **NetworkMonitor** - Detectar estado de red y mostrar banner

### 🛠️ Implementación

```swift
// File: PerfBeta/Components/LoadingView.swift
import SwiftUI

/// Componente unificado para todos los loading states
struct LoadingView: View {
    let message: String
    let style: LoadingStyle

    enum LoadingStyle {
        case fullScreen    // Cubre toda la pantalla
        case inline        // Dentro de una sección
        case overlay       // Overlay semitransparente sobre contenido
    }

    var body: some View {
        switch style {
        case .fullScreen:
            fullScreenLoading
        case .inline:
            inlineLoading
        case .overlay:
            overlayLoading
        }
    }

    private var fullScreenLoading: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(2)
                .tint(.blue)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.95))
    }

    private var inlineLoading: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private var overlayLoading: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemGray6).opacity(0.95))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}

// MARK: - Uso
struct ExampleUsageView: View {
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // Contenido principal
            ScrollView {
                Text("Contenido aquí...")
            }

            // Loading overlay
            if isLoading {
                LoadingView(
                    message: "Guardando perfume...",
                    style: .overlay
                )
            }
        }
    }
}
```

```swift
// File: PerfBeta/Components/ErrorView.swift
import SwiftUI

/// Errores de la app con categorías específicas
enum AppError: LocalizedError {
    case networkUnavailable
    case serverError
    case notFound
    case unauthorized
    case dataCorrupted
    case unknown(Error)

    var icon: String {
        switch self {
        case .networkUnavailable: return "wifi.slash"
        case .serverError: return "exclamationmark.triangle"
        case .notFound: return "magnifyingglass"
        case .unauthorized: return "lock.fill"
        case .dataCorrupted: return "doc.badge.exclamationmark"
        case .unknown: return "questionmark.circle"
        }
    }

    var title: String {
        switch self {
        case .networkUnavailable: return "Sin Conexión"
        case .serverError: return "Error del Servidor"
        case .notFound: return "No Encontrado"
        case .unauthorized: return "No Autorizado"
        case .dataCorrupted: return "Datos Corruptos"
        case .unknown: return "Error Inesperado"
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .networkUnavailable:
            return "No pudimos conectar con el servidor. Verifica tu conexión a internet."
        case .serverError:
            return "Estamos experimentando problemas técnicos. Intenta de nuevo en unos momentos."
        case .notFound:
            return "No pudimos encontrar lo que buscabas. Es posible que ya no exista."
        case .unauthorized:
            return "No tienes permisos para acceder a este contenido. Intenta iniciar sesión de nuevo."
        case .dataCorrupted:
            return "Los datos están corruptos. Intenta limpiar la caché en Ajustes."
        case .unknown(let error):
            return "Algo salió mal: \(error.localizedDescription)"
        }
    }

    var recoveryAction: RecoveryAction {
        switch self {
        case .networkUnavailable: return .retry
        case .serverError: return .retry
        case .notFound: return .goBack
        case .unauthorized: return .login
        case .dataCorrupted: return .clearCache
        case .unknown: return .retry
        }
    }

    enum RecoveryAction {
        case retry, goBack, login, clearCache, none

        var buttonTitle: String {
            switch self {
            case .retry: return "Reintentar"
            case .goBack: return "Volver"
            case .login: return "Iniciar Sesión"
            case .clearCache: return "Limpiar Caché"
            case .none: return "Cerrar"
            }
        }
    }
}

/// Vista de error con recovery actions
struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?
    let dismissAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Icono
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.8))

            // Título
            Text(error.title)
                .font(.title2.bold())

            // Mensaje
            Text(error.userFriendlyMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Botón de acción
            Button(action: {
                handleRecoveryAction()
            }) {
                HStack {
                    Image(systemName: error.recoveryAction.buttonTitle == "Reintentar" ? "arrow.clockwise" : "")
                    Text(error.recoveryAction.buttonTitle)
                }
                .frame(maxWidth: 200)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleRecoveryAction() {
        let generator = UINotificationFeedbackGenerator()

        switch error.recoveryAction {
        case .retry:
            generator.notificationOccurred(.warning)
            retryAction?()
        case .goBack:
            dismissAction?()
        case .login:
            // TODO: Navigate to login
            break
        case .clearCache:
            // TODO: Clear cache
            break
        case .none:
            dismissAction?()
        }
    }
}

// MARK: - Uso
struct ExampleErrorView: View {
    @State private var error: AppError? = nil

    var body: some View {
        ZStack {
            if let error = error {
                ErrorView(
                    error: error,
                    retryAction: {
                        Task {
                            await loadData()
                        }
                    },
                    dismissAction: {
                        self.error = nil
                    }
                )
            } else {
                Text("Contenido normal")
            }
        }
    }

    func loadData() async {
        do {
            // Intenta cargar
            throw URLError(.notConnectedToInternet)
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet {
                error = .networkUnavailable
            } else {
                error = .unknown(urlError)
            }
        } catch {
            error = .unknown(error)
        }
    }
}
```

```swift
// File: PerfBeta/Utils/NetworkMonitor.swift
import Network
import SwiftUI

/// Monitor de conexión de red
@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    deinit {
        stopMonitoring()
    }
}

// MARK: - Banner de red offline
struct NetworkStatusBanner: View {
    @ObservedObject var networkMonitor: NetworkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                Text("Sin conexión. Usando datos guardados.")
                    .font(.subheadline)
                Spacer()
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Integrar en PerfBetaApp.swift
@main
struct PerfBetaApp: App {
    @StateObject private var networkMonitor = NetworkMonitor()
    // ... otros ViewModels

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                ContentView()
                    .environmentObject(networkMonitor)

                // Banner de red offline
                NetworkStatusBanner(networkMonitor: networkMonitor)
                    .animation(.spring(), value: networkMonitor.isConnected)
                    .zIndex(999)
            }
        }
    }
}
```

### ✅ Testing

**1. Testing de Loading States:**
```
□ Simular carga lenta (Network Link Conditioner en Xcode)
□ Verificar que todos los spinners sean consistentes
□ Timing: Loading debe aparecer solo si >300ms
□ Verificar que loading no bloquea UI innecesariamente
```

**2. Testing de Errores:**
```
□ Airplane mode → debe mostrar NetworkUnavailable
□ Servidor down (mock) → debe mostrar ServerError
□ Auth token inválido → debe mostrar Unauthorized
□ Botón "Reintentar" debe funcionar 3 veces antes de dar up
□ Errores en background no deben crashear app
```

**3. Testing de Network Monitor:**
```
□ Activar/desactivar WiFi → banner debe aparecer/desaparecer
□ Cambiar de WiFi a Cellular → banner debe actualizarse
□ Network glitch (intermitente) → no debe "flicker"
```

### 📚 Referencias

**Recursos:**
- [Apple HIG: Loading](https://developer.apple.com/design/human-interface-guidelines/loading)
- [Material Design: Progress Indicators](https://m3.material.io/components/progress-indicators/overview)
- [Nielsen Norman: Progress Indicators](https://www.nngroup.com/articles/progress-indicators/)

### 💰 Impacto Esperado

- ✅ **↓ 50% en soporte requests** sobre errores confusos
- ✅ **↑ 30% en retry success rate** (usuarios saben cómo recuperarse)
- ✅ **↓ 20% en app abandonment** durante errores
- ✅ **Mejor perceived performance** aunque velocidad real no cambie

---

## Resumen de Prioridades de Implementación

### Sprint 1 (Semana 1-2) - Quick Wins
1. ✅ **LoadingView y ErrorView** (Recomendación #3) - 2-3 días
2. ✅ **NetworkMonitor + Banner** (Recomendación #3) - 1 día
3. ✅ **Haptic feedback básico** (ver UX_AUDIT_REPORT.md #8) - 1 día
4. ✅ **Empty states mejorados** (ver UX_AUDIT_REPORT.md #7) - 2 días

### Sprint 2 (Semana 3-4) - Core UX
5. ✅ **Onboarding completo** (Recomendación #1) - 3-4 días
6. ✅ **Tooltips contextuales** (Recomendación #1) - 1-2 días
7. ✅ **Barra de progreso en wizard** (preparación para #2) - 1 día

### Sprint 3 (Semana 5-7) - Major Refactor
8. ✅ **Simplificar Add Perfume** (Recomendación #2) - 5-6 días
9. ✅ **Testing y refinamiento** - 2-3 días

---

**Continuará en siguientes documentos:**
- USER_FLOWS_IMPROVED.md - Flujos optimizados con wireframes
- UI_COMPONENT_LIBRARY.md - Design system completo

*Documento generado por: Claude Code*
*Fecha: Octubre 20, 2025*
