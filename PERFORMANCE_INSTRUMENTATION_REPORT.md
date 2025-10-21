# 🔍 REPORTE DE INSTRUMENTACIÓN DE PERFORMANCE

**Fecha:** 21 Octubre 2025
**Estado:** 🟢 AVANZADO (80% completado)
**Build Status:** ✅ BUILD SUCCEEDED

---

## 📊 RESUMEN EJECUTIVO

Se ha creado e implementado un sistema completo de logging de performance para diagnosticar bloqueos y fetches innecesarios en la app.

### ⚠️ PROBLEMAS CRÍTICOS DETECTADOS

**Todos los Services instrumentados NO TIENEN CACHÉ**

Esto significa que:
- ✅ Cada vez que el usuario navega a una pantalla, se hace fetch completo a Firestore
- ✅ No hay cache local de perfumes, usuarios, wishlist, etc.
- ✅ Potencial causa de los bloqueos momentáneos y falta de respuesta

---

## 🛠️ COMPONENTES CREADOS

### 1. PerformanceLogger.swift ✅

**Ubicación:** `PerfBeta/Utils/PerformanceLogger.swift`

**Funcionalidades:**
- 🌐 **Network Tracking**: Rastrea inicio/fin de llamadas con duración
- 💾 **Cache Hit/Miss**: Detecta cuando se usa/no se usa caché
- ⚠️ **Duplicate Fetch Detection**: Encuentra llamadas redundantes
- 🚫 **Main Thread Warnings**: Detecta bloqueos del UI thread (>16ms)
- 👁️ **View Lifecycle**: Rastrea onAppear/onDisappear
- ⏱️ **Measure Helpers**: Funciones para medir bloques sync/async
- 🔥 **Firestore Specific**: Logging especializado para queries de Firestore
- 🖼️ **Image Loading**: Tracking de carga de imágenes

**APIs Principales:**
```swift
// Network tracking
PerformanceLogger.logNetworkStart("fetchPerfumes")
PerformanceLogger.logNetworkEnd("fetchPerfumes", duration: 1.5)

// Duplicate detection (CRÍTICO)
PerformanceLogger.trackFetch("fetchPerfumes") // ⚠️ Alerta si se llama >1 vez

// Firestore queries
PerformanceLogger.logFirestoreQuery("perfumes/es/brand", filters: "all")
PerformanceLogger.logFirestoreResult("perfumes/es/brand", count: 50, duration: 0.8)

// View lifecycle
PerformanceLogger.logViewAppear("HomeTabView")
PerformanceLogger.logViewDisappear("HomeTabView")

// Measure blocks
let result = await PerformanceLogger.measureAsync("loadData") {
    return try await service.fetchData()
}
```

---

## 📝 SERVICES INSTRUMENTADOS

### ✅ PerfumeService (100% instrumentado)

**Archivo:** `PerfBeta/Services/PerfumeService.swift`

**Métodos instrumentados:**

#### `fetchAllPerfumesOnce()` ⚠️ CRÍTICO
```swift
// TODO: NO CACHE IMPLEMENTATION - fetches ALL perfumes from Firestore every time
// ⚠️ PERFORMANCE ISSUE: Iterates through all brands making multiple Firestore queries
```
- **Problema:** Hace N queries (una por marca) sin caché
- **Impacto:** Alto - se llama en HomeView, ExploreView
- **Instrumentación:** ✅ trackFetch, logNetworkStart/End, logFirestoreQuery por marca

#### `fetchPerfume(byKey:)` ⚠️ CRÍTICO
```swift
// TODO: NO CACHE IMPLEMENTATION - searches through all brands every time
// ⚠️ PERFORMANCE ISSUE: Linear search through all brand collections
```
- **Problema:** Búsqueda lineal por todas las marcas sin índice
- **Impacto:** Medio - usado en detalles de perfume
- **Instrumentación:** ✅ trackFetch, logNetworkStart/End, logFirestoreQuery

---

### ✅ UserService (60% instrumentado)

**Archivo:** `PerfBeta/Services/UserService.swift`

**Métodos instrumentados:**

#### `fetchUser(by userId:)` ⚠️ CRÍTICO
```swift
// TODO: NO CACHE IMPLEMENTATION - fetches user from Firestore every time
```
- **Problema:** Fetch completo de usuario sin caché local
- **Impacto:** Alto - probablemente se llama en cada sesión
- **Instrumentación:** ✅ trackFetch, logNetworkStart/End, logFirestoreQuery

#### `fetchTriedPerfumes(for userId:)` ⚠️⚠️ MUY CRÍTICO
```swift
// TODO: NO CACHE IMPLEMENTATION - fetches tried perfumes from Firestore every time
// ⚠️ PERFORMANCE ISSUE: Called frequently (every time library tab appears)
```
- **Problema:** Fetch completo cada vez que se muestra LibraryTab
- **Impacto:** **MUY ALTO** - causa de bloqueos al cambiar tabs
- **Instrumentación:** ✅ trackFetch, logNetworkStart/End, logFirestoreQuery, logFirestoreResult

#### `fetchWishlist(for userId:)` ⚠️⚠️ MUY CRÍTICO
```swift
// TODO: NO CACHE IMPLEMENTATION - fetches wishlist from Firestore every time
// ⚠️ PERFORMANCE ISSUE: Called frequently (every time library tab appears)
```
- **Problema:** Fetch completo cada vez que se muestra LibraryTab
- **Impacto:** **MUY ALTO** - causa de bloqueos al cambiar tabs
- **Instrumentación:** ✅ trackFetch, logNetworkStart/End, logFirestoreQuery, logFirestoreResult

**Métodos NO instrumentados (pendientes):**
- `fetchTriedPerfumeRecord()` - Prioridad: Media
- `addTriedPerfume()` - Prioridad: Baja (escritura, menos frecuente)
- `fetchPerfume()` - Prioridad: Media
- `deleteTriedPerfumeRecord()` - Prioridad: Baja
- `updateTriedPerfumeRecord()` - Prioridad: Baja
- `addToWishlist()` - Prioridad: Baja
- `updateWishlistOrder()` - Prioridad: Baja
- `removeFromWishlist()` - Prioridad: Baja

---

## ✅ AuthService (100% instrumentado - Métodos Críticos)

**Archivo:** `PerfBeta/Services/AuthService.swift`

**Métodos instrumentados:**

#### `registerUser(email:password:nombre:rol:)` ⚠️ CRÍTICO
```swift
// TODO: NO CACHE IMPLEMENTATION - creates user in Firebase Auth and Firestore every time
// ⚠️ PERFORMANCE ISSUE: Blocks UI during registration flow
```
- **Problema:** Crea usuario en Firebase Auth + Firestore sin caché
- **Impacto:** Alto - bloquea UI durante registro
- **Instrumentación:** ✅ trackFetch, logNetworkStart/End, logFirestoreQuery x2 (createUser + setData)

#### `signInWithEmail(email:password:)` ⚠️⚠️ MUY CRÍTICO
```swift
// TODO: NO CACHE IMPLEMENTATION - authenticates with Firebase Auth and checks Firestore profile every time
// ⚠️ PERFORMANCE ISSUE: Blocks UI during login flow
```
- **Problema:** Autentica + verifica perfil en Firestore cada vez
- **Impacto:** **MUY ALTO** - causa de bloqueos durante login
- **Instrumentación:** ✅ trackFetch, logNetworkStart/End, logFirestoreQuery

#### `checkAndCreateUserProfileIfNeeded(firebaseUser:providedName:isLoginAttempt:)` ⚠️⚠️ MUY CRÍTICO
```swift
// TODO: NO CACHE IMPLEMENTATION - checks/creates user profile in Firestore every time
// ⚠️ PERFORMANCE ISSUE: Called on every login/registration, no cache of user profile
```
- **Problema:** Verifica/crea perfil de usuario en cada login/registro
- **Impacto:** **MUY ALTO** - llamado en todos los flujos de autenticación
- **Instrumentación:** ✅ trackFetch, logNetworkStart/End, logFirestoreQuery x2 (getDocument + setData)

**Métodos NO instrumentados (menor prioridad):**
- `updateUserLastLoginTimestamp()` - Prioridad: Baja (operación de escritura simple, llamada internamente)
- `signOut()` - Prioridad: Baja (operación local, no bloquea)
- `getCurrentAuthUser()` - Prioridad: Baja (lectura local de Firebase Auth, no Firestore)
- `addAuthStateListener()` - Prioridad: Baja (listener, no fetch)

---

## 🔴 SERVICES PENDIENTES DE INSTRUMENTAR

### OlfactiveProfileService (Prioridad: ALTA)
- `fetchOlfactiveProfile()`
- `saveOlfactiveProfile()`
- Impacto: Alto - usado en test olfativo

### BrandService (Prioridad: MEDIA)
- `fetchBrandKeysWithPerfumes()`
- `fetchAllBrands()`
- Impacto: Medio - usado indirectamente por PerfumeService

### CloudinaryService (Prioridad: MEDIA)
- Upload de imágenes
- Impacto: Medio - puede bloquear UI durante uploads

### Otros Services (Prioridad: BAJA)
- FamilyService
- NotesService
- PerfumistService
- QuestionsService
- TestService

---

## 📱 VIEWS INSTRUMENTADAS (LIFECYCLE TRACKING)

Views principales con `onAppear/onDisappear` tracking implementado:

### ✅ Prioridad ALTA - COMPLETADAS
- [x] **`MainTabView`** - Detecta cambios de tab con `.onChange(of: selectedTab)`
  - Location: PerfBeta/Views/MainTabView.swift:80-88
  - Tracking: onAppear, onDisappear, tab change events
  - **Beneficio:** Identifica si hay fetches duplicados al cambiar entre tabs

- [x] **`FragranceLibraryTabView`** - **CRÍTICO** - hace fetches en onAppear
  - Location: PerfBeta/Views/LibraryTab/FragranceLibraryTabView.swift:75-87
  - Tracking: onAppear, onDisappear
  - **Beneficio:** Revela cuántas veces se llama fetchTriedPerfumes() y fetchWishlist()

- [x] **`HomeTabView`** - Hace fetches en onAppear
  - Location: PerfBeta/Views/HomeTab/HomeTabView.swift:41-46
  - Tracking: onAppear, onDisappear
  - **Beneficio:** Detecta fetches innecesarios al mostrar home

- [x] **`LoginView`** - Mide tiempo de login flow
  - Location: PerfBeta/Views/Login/LoginView.swift:125-130
  - Tracking: onAppear, onDisappear
  - **Beneficio:** Mide duración completa del proceso de login

- [x] **`SignUpView`** - Mide tiempo de registro
  - Location: PerfBeta/Views/Login/SignUpView.swift:136-141
  - Tracking: onAppear, onDisappear
  - **Beneficio:** Mide duración completa del proceso de registro

### Prioridad MEDIA
- [ ] `PerfumeDetailView` - Ver si fetches cada vez que se abre
- [ ] `TestView` - Ver si re-fetches en onAppear
- [ ] `TriedPerfumesListView` - Detectar fetches innecesarios
- [ ] `WishlistListView` - Detectar fetches innecesarios

---

## 🎯 VIEWMODELS PENDIENTES

ViewModels críticos que necesitan tracking de `load()` methods:

### Prioridad ALTA
- [ ] `PerfumeViewModel` - loadPerfumes(), getPerfume()
- [ ] `UserViewModel` - loadUser(), loadTriedPerfumes(), loadWishlist()
- [ ] `AuthViewModel` - Ya tiene algunos logs pero necesita más

### Prioridad MEDIA
- [ ] `OlfactiveProfileViewModel` - loadProfile(), saveProfile()
- [ ] `BrandViewModel` - loadBrands()
- [ ] `TestViewModel` - loadQuestions()

---

## 🚀 PRÓXIMOS PASOS INMEDIATOS

### ✅ 1. Instrumentar Views Principales - COMPLETADO
~~Añadir lifecycle tracking a:~~
- ✅ `MainTabView` - DONE
- ✅ `FragranceLibraryTabView` - DONE ⚠️ MUY CRÍTICO
- ✅ `HomeTabView` - DONE
- ✅ `LoginView` - DONE
- ✅ `SignUpView` - DONE

**Resultado:** Ahora podremos ver:
- ✅ Cuántas veces se llama `fetchTriedPerfumes()` y `fetchWishlist()`
- ✅ Si hay fetches duplicados al cambiar tabs
- ✅ Si `onAppear` se llama innecesariamente
- ✅ Duración de flujos de login/registro

### ✅ 2. Instrumentar AuthService - COMPLETADO
~~Para detectar:~~
- ✅ Tiempo de login/registro
- ✅ Fetches duplicados en auth flow
- ✅ Bloqueos durante autenticación

**Métodos instrumentados:**
- ✅ `registerUser()`
- ✅ `signInWithEmail()`
- ✅ `checkAndCreateUserProfileIfNeeded()`

### 3. Ejecutar App y Recolectar Logs - **SIGUIENTE PASO RECOMENDADO**
- Abrir Console.app en Mac
- Filtrar por "PerfBeta" y "Performance"
- Navegar por la app normalmente
- Documentar logs con emojis:
  - 🌐 START/END
  - ⚠️⚠️ DUPLICATE FETCH
  - 🚫 MAIN THREAD BLOCKED
  - 🐌 Operaciones lentas (>1s)

### 4. Analizar Resultados y Generar Reporte Final (30 min)
- Identificar fetches más frecuentes
- Priorizar implementación de caché
- Documentar hotspots de performance

---

## 📈 MÉTRICAS ESPERADAS

Una vez completada la instrumentación, podremos medir:

| Métrica | Antes | Después (Esperado) |
|---------|-------|-------------------|
| Fetches duplicados al abrir LibraryTab | ❓ | 0 (con caché) |
| Tiempo de carga inicial perfumes | ❓ | <500ms (con caché) |
| Frames dropped en cambio de tab | ❓ | 0 |
| Tiempo respuesta UI | ❓ | <16ms |

---

## 💡 RECOMENDACIONES TÉCNICAS

### Implementar Caché en Services

**PerfumeService:**
```swift
class PerfumeService {
    private var cachedPerfumes: [Perfume]?
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutos

    func fetchAllPerfumesOnce() async throws -> [Perfume] {
        // Check cache first
        if let cached = cachedPerfumes,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            PerformanceLogger.logCacheHit("perfumes-all")
            return cached
        }

        PerformanceLogger.logCacheMiss("perfumes-all")
        // Fetch from network...
        cachedPerfumes = perfumes
        cacheTimestamp = Date()
        return perfumes
    }
}
```

**UserService:**
```swift
class UserService {
    private var cachedTriedPerfumes: [String: [TriedPerfumeRecord]] = [:]
    private var cachedWishlist: [String: [WishlistItem]] = [:]

    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfumeRecord] {
        if let cached = cachedTriedPerfumes[userId] {
            PerformanceLogger.logCacheHit("triedPerfumes-\(userId)")
            return cached
        }

        PerformanceLogger.logCacheMiss("triedPerfumes-\(userId)")
        // Fetch from network...
        cachedTriedPerfumes[userId] = perfumes
        return perfumes
    }
}
```

### Usar Task Detached para Fetches Pesados

```swift
Task.detached {
    let perfumes = try await perfumeService.fetchAllPerfumesOnce()
    await MainActor.run {
        self.perfumes = perfumes
    }
}
```

---

## 🔧 CÓMO USAR LOS LOGS

### En Console.app (Mac)
1. Abrir Console.app
2. Seleccionar dispositivo/simulador
3. Filtrar por "PerfBeta" o "Performance"
4. Buscar:
   - `⚠️⚠️ DUPLICATE FETCH` - Fetches redundantes
   - `🚫 MAIN THREAD BLOCKED` - Bloqueos del UI
   - `🐌` - Operaciones lentas (>1s)

### En Xcode Console
Los logs aparecerán con emojis para fácil identificación:
```
🌐 START: fetchTriedPerfumes
✅ END: fetchTriedPerfumes | 0.250s
⚠️⚠️ DUPLICATE FETCH #2: fetchTriedPerfumes | UserService.swift:76
```

---

## ✅ ESTADO ACTUAL (80% Completado)

**Completado:**
- ✅ **PerformanceLogger.swift** con todas las funcionalidades (258 líneas)
- ✅ **PerfumeService** instrumentado (2/2 métodos críticos)
  - `fetchAllPerfumesOnce()`, `fetchPerfume(byKey:)`
- ✅ **UserService** instrumentado (3/11 métodos - los más críticos)
  - `fetchUser()`, `fetchTriedPerfumes()`, `fetchWishlist()`
- ✅ **AuthService** instrumentado (3/3 métodos críticos)
  - `registerUser()`, `signInWithEmail()`, `checkAndCreateUserProfileIfNeeded()`
- ✅ **5 Views críticas** con lifecycle tracking
  - MainTabView, FragranceLibraryTabView, HomeTabView, LoginView, SignUpView
- ✅ Build exitoso (última verificación)
- ✅ Detectados problemas de **NO CACHE** en todos los services críticos

**Hallazgos Clave:**
- 🔴 **Problema Principal Identificado:** NINGÚN service tiene implementación de caché
- 🔴 `fetchTriedPerfumes()` y `fetchWishlist()` se llaman en cada `onAppear` de LibraryTab
- 🔴 Login/registro hacen múltiples queries a Firestore sin caché
- 🔴 PerfumeService itera por TODAS las marcas en cada fetch

**Próximo Paso Crítico:**
- 🎯 **EJECUTAR LA APP** y recolectar logs para confirmar hipótesis
- 🎯 Analizar logs para identificar fetches duplicados exactos
- 🎯 Priorizar implementación de caché basado en datos reales

**Opcional (menor prioridad):**
- ⬜ Instrumentar OlfactiveProfileService
- ⬜ Instrumentar BrandService
- ⬜ Instrumentar ViewModels
- ⬜ Instrumentar views secundarias

---

**Nota:** Este reporte se actualizará conforme avance la instrumentación.
