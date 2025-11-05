# Refactorización del Sistema de Onboarding

## 📋 Resumen

Se ha refactorizado el sistema de onboarding para hacerlo **reutilizable y configurable**, permitiendo diferentes flujos con distintos números de preguntas según el contexto de uso.

## ✅ Problema Resuelto

**Problema original:**
- El onboarding tenía **7 pasos fijos** (hardcodeados del paso 3 al 9)
- Cuando se usaba desde "Mi Opinión", mostraba 7 preguntas aunque solo se querían 4
- La barra de progreso siempre mostraba "X / 7" sin importar cuántas preguntas realmente había
- No era reutilizable para otros contextos (perfil olfativo, etc.)

**Solución implementada:**
- Sistema de configuración dinámica con `OnboardingConfiguration`
- Soporte para múltiples contextos predefinidos
- Barra de progreso que se adapta automáticamente al número de pasos
- Arquitectura extensible para futuros casos de uso

---

## 🏗️ Arquitectura de la Solución

### 1. **OnboardingConfiguration.swift** (NUEVO)

Archivo ubicado en: `PerfBeta/Models/OnboardingConfiguration.swift`

#### Componentes principales:

**a) `OnboardingStepType` (enum)**
Define todos los tipos de pasos disponibles:

```swift
enum OnboardingStepType: String, CaseIterable {
    case duration              // Duración
    case projection            // Proyección
    case price                 // Precio
    case occasions             // Ocasión
    case personalities         // Personalidad
    case seasons               // Estación
    case impressionsAndRating  // Impresiones y Valoración
}
```

Cada paso tiene:
- `legacyStepNumber`: Número del paso en el sistema anterior (3-9)
- `navigationTitle`: Título que aparece en la barra de navegación

**b) `OnboardingContext` (enum)**
Define los contextos de uso predefinidos:

```swift
enum OnboardingContext {
    case triedPerfumeOpinion   // "Mi Opinión" - 4 preguntas
    case fullEvaluation        // Evaluación completa - 7 preguntas
    case olfactiveProfile      // Para perfil olfativo (futuro)
}
```

Cada contexto tiene su propio array de pasos:

- **`.triedPerfumeOpinion`** (4 preguntas):
  1. Duración
  2. Proyección
  3. Precio
  4. Impresiones y Valoración

- **`.fullEvaluation`** (7 preguntas):
  1. Duración
  2. Proyección
  3. Precio
  4. Ocasión
  5. Personalidad
  6. Estación
  7. Impresiones y Valoración

**c) `OnboardingConfiguration` (struct)**
Estructura de configuración con métodos útiles:

```swift
struct OnboardingConfiguration {
    let context: OnboardingContext
    let steps: [OnboardingStepType]

    // Inicializa con un contexto predefinido
    init(context: OnboardingContext)

    // Inicializa con pasos personalizados
    init(customSteps: [OnboardingStepType])

    var totalSteps: Int
    func shouldShow(stepType: OnboardingStepType) -> Bool
    func stepIndex(for stepType: OnboardingStepType) -> Int?
    func nextStep(after currentStep: OnboardingStepType) -> OnboardingStepType?
    func isLastStep(_ stepType: OnboardingStepType) -> Bool
}
```

### 2. **AddPerfumeOnboardingView** (REFACTORIZADO)

#### Cambios principales:

**Antes:**
```swift
init(
    isAddingPerfume: Binding<Bool>,
    triedPerfumeRecord: TriedPerfumeRecord?,
    initialStep: Int,  // ❌ Número hardcodeado (siempre 3)
    selectedPerfumeForEvaluation: Perfume?
)

let stepCount = 7  // ❌ Hardcodeado
@State private var onboardingStep: Int  // ❌ Números mágicos
```

**Después:**
```swift
init(
    isAddingPerfume: Binding<Bool>,
    triedPerfumeRecord: TriedPerfumeRecord?,
    selectedPerfumeForEvaluation: Perfume?,
    configuration: OnboardingConfiguration  // ✅ Configuración dinámica
)

@State private var currentStepIndex: Int = 0  // ✅ Índice basado en array

private var currentStep: OnboardingStepType {
    configuration.steps[currentStepIndex]
}

private var isLastStep: Bool {
    currentStepIndex == configuration.steps.count - 1
}
```

#### Nueva barra de progreso:
```swift
// ANTES
ProgressView(value: Double(onboardingStep - initialStepsCount), total: Double(stepCount))
Text("\(onboardingStep - initialStepsCount) / \(stepCount)")  // Siempre "X / 7"

// DESPUÉS
ProgressView(value: Double(currentStepIndex + 1), total: Double(configuration.totalSteps))
Text("\(currentStepIndex + 1) / \(configuration.totalSteps)")  // Dinámico: "X / 4" o "X / 7"
```

#### Nuevo sistema de vistas de pasos:
```swift
@ViewBuilder
private func stepView(for stepType: OnboardingStepType) -> some View {
    switch stepType {
    case .duration:
        AddPerfumeStep3View(duration: $duration, onNext: { goToNextStep() })
    case .projection:
        AddPerfumeStep4View(projection: $projection, onNext: { goToNextStep() })
    // ... etc
    }
}

private func goToNextStep() {
    if currentStepIndex < configuration.steps.count - 1 {
        currentStepIndex += 1
    }
}
```

### 3. **Step Views** (ACTUALIZADOS)

Todos los Step views (3, 4, 5, 6, 7, 8) fueron actualizados:

**Antes:**
```swift
struct AddPerfumeStep3View: View {
    @Binding var duration: Duration?
    @Binding var onboardingStep: Int  // ❌ Binding a variable de control

    var body: some View {
        // ...
        GenericOptionButtonView<Duration>(...) {
            duration = durationCase
            onboardingStep = 4  // ❌ Número hardcodeado
        }
    }
}
```

**Después:**
```swift
struct AddPerfumeStep3View: View {
    @Binding var duration: Duration?
    let onNext: () -> Void  // ✅ Closure para avanzar

    var body: some View {
        // ...
        GenericOptionButtonView<Duration>(...) {
            duration = durationCase
            onNext()  // ✅ Delega la navegación al padre
        }
    }
}
```

---

## 🎯 Uso del Nuevo Sistema

### Ejemplo 1: "Mi Opinión" (4 preguntas)

**Archivo:** `AddPerfumeDetailView.swift`

```swift
.navigationDestination(isPresented: $showingEvaluationOnboarding) {
    AddPerfumeOnboardingView(
        isAddingPerfume: $isAddingPerfume,
        triedPerfumeRecord: nil,
        selectedPerfumeForEvaluation: perfume,
        configuration: OnboardingConfiguration(context: .triedPerfumeOpinion)  // ✅ 4 preguntas
    )
}
```

**Resultado:** El usuario responde solo 4 preguntas y la barra muestra "1/4", "2/4", "3/4", "4/4".

### Ejemplo 2: Evaluación completa (7 preguntas)

**Archivo:** `AddPerfumeInitialStepsView.swift`

```swift
AddPerfumeOnboardingView(
    isAddingPerfume: $isAddingPerfume,
    triedPerfumeRecord: nil,
    selectedPerfumeForEvaluation: selectedPerfume,
    configuration: OnboardingConfiguration(context: .fullEvaluation)  // ✅ 7 preguntas
)
```

**Resultado:** El usuario responde las 7 preguntas completas.

### Ejemplo 3: Onboarding personalizado (futuro)

```swift
// Crear configuración personalizada con solo 3 preguntas específicas
let customConfig = OnboardingConfiguration(customSteps: [
    .duration,
    .projection,
    .impressionsAndRating
])

AddPerfumeOnboardingView(
    isAddingPerfume: $isAddingPerfume,
    triedPerfumeRecord: nil,
    selectedPerfumeForEvaluation: perfume,
    configuration: customConfig
)
```

---

## 📁 Archivos Modificados

### Nuevos archivos:
- ✅ `PerfBeta/Models/OnboardingConfiguration.swift` (configuración del sistema)

### Archivos refactorizados:
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeOnboardingView.swift`
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeStep3View.swift`
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeStep4View.swift`
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeStep5View.swift`
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeStep6View.swift`
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeStep7View.swift`
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeStep8View.swift`

### Archivos actualizados (llamadas al onboarding):
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeDetailView.swift`
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeInitialStepsView.swift`
- ✅ `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/AddPerfumeStep2View.swift`

---

## 🚀 Beneficios de la Refactorización

1. **✅ Flexibilidad:** Diferentes contextos con diferentes números de preguntas
2. **✅ Reutilización:** Un solo componente para múltiples casos de uso
3. **✅ Mantenibilidad:** Cambios centralizados en `OnboardingConfiguration`
4. **✅ Escalabilidad:** Fácil agregar nuevos contextos o pasos
5. **✅ UX mejorada:** Barra de progreso precisa según el flujo actual
6. **✅ Código limpio:** Eliminados números mágicos y lógica hardcodeada

---

## 🔮 Extensibilidad Futura

### Agregar un nuevo contexto:

```swift
// En OnboardingConfiguration.swift

enum OnboardingContext {
    // ... existing cases
    case quickReview  // Nuevo: Reseña rápida con solo 2 preguntas
}

extension OnboardingContext {
    var steps: [OnboardingStepType] {
        switch self {
        // ... existing cases
        case .quickReview:
            return [.rating, .impressionsAndRating]  // Solo 2 preguntas
        }
    }
}
```

### Agregar un nuevo tipo de paso:

```swift
// 1. Agregar a OnboardingStepType
enum OnboardingStepType: String, CaseIterable {
    // ... existing cases
    case favoriteNotes  // Nuevo: Preguntar por notas favoritas
}

// 2. Crear la vista del paso
struct AddPerfumeStepFavoriteNotesView: View { ... }

// 3. Agregar al switch en AddPerfumeOnboardingView
@ViewBuilder
private func stepView(for stepType: OnboardingStepType) -> some View {
    switch stepType {
    // ... existing cases
    case .favoriteNotes:
        AddPerfumeStepFavoriteNotesView(...)
    }
}
```

---

## 🧪 Testing

Flujos a probar en Xcode:

### Test 1: "Mi Opinión" desde PerfumeDetailView
1. Navegar a la vista de detalle de un perfume
2. Pulsar botón "Mi Opinión"
3. **Verificar:** Barra de progreso muestra "1 / 4"
4. Responder las 4 preguntas (Duración, Proyección, Precio, Impresiones)
5. **Verificar:** Llega a pantalla final con botón "Guardar"
6. Guardar y verificar que vuelve a FragranceLibraryTabView

### Test 2: Evaluación completa desde AddPerfumeInitialStepsView
1. Navegar al flujo de añadir perfume
2. Seleccionar un perfume
3. **Verificar:** Barra de progreso muestra "1 / 7"
4. Responder las 7 preguntas
5. **Verificar:** Llega a pantalla final con botón "Guardar"

### Test 3: Navegación hacia atrás
1. Iniciar cualquier onboarding
2. Avanzar 2-3 pasos
3. Pulsar botón "atrás" (arrow.backward)
4. **Verificar:** Retrocede correctamente y la barra de progreso se actualiza

---

## 📊 Comparativa Antes/Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| Número de preguntas | 7 fijas | Configurable (4, 7, o custom) |
| Barra de progreso | Siempre "X / 7" | Dinámica según contexto |
| Reutilización | No reutilizable | Totalmente reutilizable |
| Mantenibilidad | Difícil (números mágicos) | Fácil (configuración central) |
| Extensibilidad | Requiere duplicar código | Solo agregar a enum |
| Navegación | Números hardcodeados (3→4→5...) | Basada en array de pasos |

---

## ⚠️ Breaking Changes

### API Changes:

**AddPerfumeOnboardingView:**
```swift
// ANTES (deprecated)
AddPerfumeOnboardingView(
    isAddingPerfume: $isAddingPerfume,
    triedPerfumeRecord: nil,
    initialStep: 3,  // ❌ Ya no se usa
    selectedPerfumeForEvaluation: perfume
)

// DESPUÉS (required)
AddPerfumeOnboardingView(
    isAddingPerfume: $isAddingPerfume,
    triedPerfumeRecord: nil,
    selectedPerfumeForEvaluation: perfume,
    configuration: OnboardingConfiguration(context: .triedPerfumeOpinion)  // ✅ Requerido
)
```

**Step Views (3-8):**
```swift
// ANTES
AddPerfumeStep3View(duration: $duration, onboardingStep: $onboardingStep)

// DESPUÉS
AddPerfumeStep3View(duration: $duration, onNext: { goToNextStep() })
```

---

## 📝 Notas Adicionales

- El Step9View (Impresiones y Valoración) no requiere `onNext` porque es siempre el último paso
- La propiedad `isLastStep` en `AddPerfumeOnboardingView` controla cuándo mostrar el botón "Guardar"
- El sistema soporta edición de perfumes probados (cuando `triedPerfumeRecord` no es nil)
- Se mantiene compatibilidad con el sistema de guardado existente en `saveTriedPerfume()`

---

**Autor:** Claude Code
**Fecha:** 2025-11-05
**Versión:** 1.0
