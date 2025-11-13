# 🧪 Guía de Ejecución de Tests - PerfBeta

**Última actualización:** Noviembre 13, 2025

---

## ⚠️ Problema: Tests Fallan en iPhone Físico

Si ves este error al ejecutar tests en tu iPhone físico:
```
Error loading ... code signature invalid in ... PerfBetaTests.xctest/PerfBetaTests
```

**Causa:** Los tests unitarios están diseñados para ejecutarse en **simulador**, no en dispositivo físico. Este es el comportamiento estándar de Xcode para tests unitarios.

---

## ✅ SOLUCIÓN RÁPIDA (RECOMENDADA)

### Paso 1: Cambiar a Simulador en Xcode

1. **Abre tu proyecto** en Xcode
2. **En la barra superior**, junto al botón ▶️ Play, verás el dispositivo actual:
   ```
   [PerfBeta >] [iPhone de Juanra]
   ```
3. **Haz clic** en "iPhone de Juanra"
4. **Selecciona un simulador** de la lista:
   - ✅ iPhone 16 (iOS 18.6) - RECOMENDADO
   - ✅ iPhone 17 Pro (iOS 26.0+)
   - ✅ Cualquier iPhone con iOS 17.2+

### Paso 2: Ejecutar Tests

**Opción A - Todos los tests:**
- Presiona `Cmd + U` en Xcode

**Opción B - Tests específicos:**
1. Abre el navegador de tests (ícono 💎 en la barra lateral izquierda)
2. Encuentra `PerfBetaTests`
3. Haz clic en el diamante ◊ junto a:
   - `CacheManagerTests` (16 tests)
   - `MetadataIndexManagerTests` (8 tests)

**Opción C - Un solo test:**
- Abre `PerfBetaTests.swift`
- Haz clic en el diamante ◊ junto a cualquier función `func test...`

---

## 🖥️ Ejecutar desde Línea de Comandos

### Tests Completos (24 tests)
```bash
xcodebuild test \
  -scheme PerfBeta \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:PerfBetaTests
```

### Solo CacheManager (16 tests)
```bash
xcodebuild test \
  -scheme PerfBeta \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:PerfBetaTests/CacheManagerTests
```

### Solo MetadataIndexManager (8 tests)
```bash
xcodebuild test \
  -scheme PerfBeta \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:PerfBetaTests/MetadataIndexManagerTests
```

### Simuladores Disponibles
Para ver todos los simuladores:
```bash
xcrun simctl list devices available
```

---

## 📱 Ejecutar Tests en Dispositivo Físico (NO RECOMENDADO)

Si **realmente necesitas** ejecutar en dispositivo físico, sigue estos pasos:

### 1. Configurar Signing en Xcode

1. **Selecciona el proyecto** "PerfBeta" en el navegador
2. **Selecciona el target** "PerfBetaTests" (NO PerfBeta)
3. Ve a la pestaña **"Signing & Capabilities"**
4. Asegúrate de que:
   - ✅ **"Automatically manage signing"** está activado
   - ✅ **Team** está seleccionado (tu cuenta de desarrollador)
   - ✅ **Bundle Identifier** es: `com.testjr.perfBeta.PerfBetaTests`

### 2. Verificar que el Target de Tests tiene Signing

```
Target: PerfBetaTests
├── Signing & Capabilities
│   ├── Automatically manage signing: ✅ ON
│   ├── Team: [Tu equipo de desarrollo]
│   └── Provisioning Profile: [Auto-generado]
└── Bundle Identifier: com.testjr.perfBeta.PerfBetaTests
```

### 3. Limpiar y Reconstruir

```bash
# Limpiar build folder
Cmd + Shift + K (en Xcode)

# O desde terminal:
xcodebuild clean -scheme PerfBeta
```

### 4. Ejecutar Tests

- Conecta tu iPhone
- Selecciona "iPhone de Juanra" como destino
- Presiona `Cmd + U`

---

## 🐛 Troubleshooting

### Problema: "No simulators available"
**Solución:**
```bash
# Abrir Simulator.app
open -a Simulator

# O instalar un runtime de iOS
xcodebuild -downloadPlatform iOS
```

### Problema: "Test bundle could not be loaded"
**Solución:**
1. Limpiar build: `Cmd + Shift + K`
2. Cerrar Xcode
3. Eliminar DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. Reabrir Xcode y reconstruir: `Cmd + B`

### Problema: Tests pasan desde terminal pero fallan en Xcode
**Solución:**
1. En Xcode, ve a `Product → Scheme → Edit Scheme`
2. Selecciona **"Test"** en la barra lateral
3. En **"Info"**, asegúrate de que:
   - ✅ `PerfBetaTests` está marcado
   - ✅ Todos los test classes están visibles
4. Haz clic en **"Close"**

---

## 📊 Resultados Esperados

Cuando los tests se ejecutan correctamente, deberías ver:

```
Test Suite 'All tests' started
Test Suite 'PerfBetaTests.xctest' started
Test Suite 'CacheManagerTests' started
Test Case 'CacheManagerTests.testSaveAndLoadSimpleModel()' passed (0.001 seconds)
Test Case 'CacheManagerTests.testSaveAndLoadComplexModel()' passed (0.010 seconds)
...
Test Suite 'CacheManagerTests' passed
    Executed 16 tests, with 0 failures (0 unexpected)

Test Suite 'MetadataIndexManagerTests' started
Test Case 'MetadataIndexManagerTests.testCacheClearingAffectsMetadataIndex()' passed (0.014 seconds)
...
Test Suite 'MetadataIndexManagerTests' passed
    Executed 8 tests, with 0 failures (0 unexpected)

** TEST SUCCEEDED **
Total: 24 tests, 0 failures
```

---

## ⚡ Tests Implementados

### CacheManagerTests (16 tests)
- ✅ Save/Load operations (5 tests)
- ✅ Timestamp management (3 tests)
- ✅ Cache clearing (3 tests)
- ✅ Size calculation (1 test)
- ✅ Performance benchmarks (2 tests)
- ✅ Edge cases (2 tests)

### MetadataIndexManagerTests (8 tests)
- ✅ Cache integration (3 tests)
- ✅ Model serialization (2 tests)
- ✅ Performance testing (1 test - 5000 items)
- ✅ Edge cases (2 tests)

---

## 📝 Notas Importantes

1. **Tests unitarios se ejecutan mejor en simulador**
   - Más rápidos
   - No requieren signing
   - Comportamiento consistente

2. **Tests de integración con Firebase**
   - Los tests actuales NO requieren Firebase activo
   - Tests de integración están documentados pero comentados
   - Requieren configuración de Firebase Test Environment

3. **Performance**
   - Los tests deberían completarse en < 2 segundos
   - Si tardan más, podría haber un problema de caché o red

4. **Cobertura**
   - 100% de CacheManager (todas las funciones críticas)
   - 100% de MetadataIndexManager (sin Firebase)
   - Tests de Firebase están documentados para implementación futura

---

## 🚀 Verificación Rápida

Ejecuta este comando para verificar que todo funciona:

```bash
xcodebuild test \
  -scheme PerfBeta \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:PerfBetaTests/CacheManagerTests/testSaveAndLoadSimpleModel
```

Si ves `** TEST SUCCEEDED **`, todo está funcionando correctamente ✅

---

## 📞 Soporte

Si los tests siguen fallando después de seguir esta guía:

1. Verifica que tienes Xcode 15+ instalado
2. Verifica que los simuladores de iOS 17.2+ están instalados
3. Revisa los logs completos para errores específicos
4. Limpia DerivedData y recompila

---

**Última revisión:** Noviembre 13, 2025
**Versión de Tests:** 1.0
**iOS Mínimo:** 17.2
**Xcode Requerido:** 15.0+
