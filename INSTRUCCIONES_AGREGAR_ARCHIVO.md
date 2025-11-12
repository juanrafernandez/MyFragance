# Instrucciones: Agregar Archivos de Evaluación al Proyecto

## ⚠️ Problema

Existen 3 archivos nuevos en el sistema de archivos que no están incluidos en el target de Xcode:
1. ❌ `EvaluationQuestionsViewModel.swift`
2. ❌ `EvaluationQuestionView.swift`
3. ❌ `FirestoreOptionButtonView.swift`

Error actual: `cannot find 'EvaluationQuestionView' in scope`

## ✅ Solución (3 minutos)

### Opción 1: Agregar manualmente desde Xcode (RECOMENDADO)

1. **Abre el proyecto en Xcode**
   ```bash
   open PerfBeta.xcodeproj
   ```

2. **Agregar EvaluationQuestionsViewModel:**
   - En el navegador de archivos (izquierda): `PerfBeta` → `ViewModels`
   - Clic derecho en `ViewModels` → **"Add Files to PerfBeta..."**
   - Selecciona: `PerfBeta/ViewModels/EvaluationQuestionsViewModel.swift`
   - ✅ Marca: **"Add to targets: PerfBeta"**
   - Clic en **"Add"**

3. **Agregar EvaluationQuestionView:**
   - Navega a: `PerfBeta` → `Views` → `LibraryTab` → `TriedPerfumesSteps`
   - Clic derecho en `TriedPerfumesSteps` → **"Add Files to PerfBeta..."**
   - Selecciona: `EvaluationQuestionView.swift`
   - ✅ Marca: **"Add to targets: PerfBeta"**
   - Clic en **"Add"**

4. **Agregar FirestoreOptionButtonView:**
   - En la misma carpeta `TriedPerfumesSteps`
   - Clic derecho → **"Add Files to PerfBeta..."**
   - Selecciona: `FirestoreOptionButtonView.swift`
   - ✅ Marca: **"Add to targets: PerfBeta"**
   - Clic en **"Add"**

5. **Limpia y compila:**
   - Menú: `Product` → `Clean Build Folder` (⇧⌘K)
   - Menú: `Product` → `Build` (⌘B)

### Opción 2: Re-crear el archivo desde Xcode

1. **Elimina el archivo actual:**
   ```bash
   rm PerfBeta/ViewModels/EvaluationQuestionsViewModel.swift
   ```

2. **En Xcode:**
   - Clic derecho en `ViewModels` → **"New File..."**
   - Selecciona: **"Swift File"**
   - Nombre: `EvaluationQuestionsViewModel`
   - Asegúrate de marcar: ✅ **"PerfBeta" target**

3. **Copia el contenido del archivo:**
   ```bash
   cat > PerfBeta/ViewModels/EvaluationQuestionsViewModel.swift << 'EOF'
   [contenido del archivo actualizado con caché]
   EOF
   ```

## 📝 Archivos Que Deben Agregarse

### 1. **EvaluationQuestionsViewModel.swift**
- **Ubicación**: `PerfBeta/ViewModels/`
- **Función**: ViewModel para cargar preguntas desde Firestore con caché
- **Usado por**: `AddPerfumeOnboardingView.swift` línea 10

### 2. **EvaluationQuestionView.swift**
- **Ubicación**: `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/`
- **Función**: Vista genérica para mostrar preguntas de Firestore
- **Usado por**: `AddPerfumeOnboardingView.swift` línea 207

### 3. **FirestoreOptionButtonView.swift**
- **Ubicación**: `PerfBeta/Views/LibraryTab/TriedPerfumesSteps/`
- **Función**: Botón para opciones de Firestore (duration, projection, price)
- **Usado por**: `EvaluationQuestionView.swift`

## 🔍 Verificación

Después de agregar los 3 archivos, el proyecto debería compilar sin errores.

### Errores actuales:
```
error: cannot find 'EvaluationQuestionView' in scope
error: cannot find 'FirestoreOptionButtonView' in scope
```

Una vez agregados correctamente, estos errores desaparecerán.
