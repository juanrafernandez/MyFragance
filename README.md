# PerfBeta 🌸

Una aplicación iOS sofisticada para el descubrimiento, gestión y recomendación de perfumes. Combina perfiles olfativos personalizados, una biblioteca de fragancias, y características sociales para ayudar a los usuarios a descubrir y gestionar su viaje aromático.

![iOS](https://img.shields.io/badge/iOS-17.2+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-100%25-green.svg)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-yellow.svg)

---

## 📱 Características

### ✨ Funcionalidades Principales

- **Sistema de Autenticación Completo**
  - Email/Password
  - Google Sign-In
  - Apple Sign-In
  - Gestión de sesiones con Firebase Auth

- **Perfiles Olfativos Personalizados**
  - Cuestionario interactivo con elementos visuales
  - Múltiples perfiles por usuario
  - Modo regalo (crear perfiles para otros)
  - Recomendaciones personalizadas

- **Biblioteca de Perfumes (Mi Colección)**
  - Lista de perfumes probados con reviews
  - Wishlist con organización
  - Sistema de calificaciones (1-5 estrellas)
  - Notas personales e impresiones
  - Etiquetado por ocasiones, temporadas, personalidades

- **Exploración y Descubrimiento**
  - Feed personalizado
  - Carruseles de perfumes
  - Filtros avanzados (género, familia, intensidad, precio, etc.)
  - Vista detallada de perfumes (pirámide de notas, características)

- **Diseño Moderno**
  - SwiftUI 100%
  - Tema champagne/dorado elegante
  - Soporte de modo oscuro (pendiente)
  - Animaciones fluidas

---

## 🏗️ Arquitectura

- **Patrón:** MVVM (Model-View-ViewModel)
- **Diseño Orientado a Protocolos** - Todos los servicios implementan protocolos
- **Inyección de Dependencias** - `DependencyContainer` centralizado
- **Gestión de Estado** - `@StateObject`, `@EnvironmentObject`, `AppState`
- **Programación Reactiva** - Combine framework

### Stack Tecnológico

- **Swift 6.2**
- **SwiftUI** - Framework de UI declarativo
- **iOS 17.2+** - Target mínimo
- **Firebase**
  - Firebase Authentication (Email, Google, Apple)
  - Cloud Firestore (con persistencia offline)
  - Firebase Storage
- **Kingfisher** - Carga y cache de imágenes asíncronas
- **Cloudinary** - CDN de imágenes
- **GoogleSignIn SDK** - Autenticación con Google
- **AuthenticationServices** - Sign in with Apple

---

## 📋 Requisitos Previos

- macOS 13.0+ (Ventura o superior)
- Xcode 15.0+
- Swift 6.2+
- CocoaPods o Swift Package Manager
- Cuenta de Firebase (gratuita)
- Cuenta de Cloudinary (opcional, para subida de imágenes)
- Apple Developer Account (para testing en dispositivo físico y Sign in with Apple)

---

## 🚀 Instalación y Configuración

> ⚠️ **IMPORTANTE PARA NUEVOS DESARROLLADORES:**
> Este proyecto requiere configuración de secrets antes de compilar.
> Lee la sección "Configurar Secrets" cuidadosamente.

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/TU_USUARIO/PerfBeta.git
cd PerfBeta/PerfBeta
```

### Paso 2: Configurar Firebase

#### 2.1 Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Crea un nuevo proyecto o usa uno existente
3. Agrega una app iOS con Bundle ID: `com.testjr.perfBeta`

#### 2.2 Descargar GoogleService-Info.plist

1. En Firebase Console → Project Settings → Your apps → iOS app
2. Descarga `GoogleService-Info.plist`
3. **Colócalo en:** `PerfBeta/GoogleService-Info.plist`

⚠️ **IMPORTANTE:** Este archivo contiene API keys y NO debe commitearse a git público (ya está en .gitignore)

#### 2.3 Configurar Firebase Authentication

1. En Firebase Console → Authentication → Sign-in method
2. Habilitar los siguientes providers:
   - **Email/Password** ✅
   - **Google** ✅
     - Copiar el Web client ID (lo usarás después)
   - **Apple** ✅ (requiere Apple Developer Program)

#### 2.4 Configurar Firestore Database

1. En Firebase Console → Firestore Database
2. Crear base de datos en modo **Production**
3. Configurar **Security Rules** (ver `SECURITY_ALERT.md` para reglas recomendadas)

**Reglas básicas de seguridad:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /perfumes/{perfumeId} {
      allow read: if true;
      allow write: if request.auth != null;
    }

    // Agregar más reglas según necesites
  }
}
```

### Paso 3: ⚙️ Configurar Secrets (CRÍTICO - Cloudinary)

⚠️ **IMPORTANTE:** Este proyecto usa un sistema centralizado de secrets para proteger credenciales.

#### 3.1 Copiar Template de Secrets

El proyecto incluye un template para configurar secrets de forma segura:

```bash
# Navega al directorio del proyecto
cd PerfBeta

# Copia el template para crear tu archivo de secrets
cp Config/Secrets.swift.template Config/Secrets.swift
```

⚠️ **NUNCA commitees `Secrets.swift` a git** (ya está protegido por .gitignore)

#### 3.2 Obtener Credenciales de Cloudinary

Si vas a usar la funcionalidad de subida de imágenes:

1. **Crear cuenta en Cloudinary:**
   - Ve a [https://cloudinary.com](https://cloudinary.com)
   - Regístrate gratis (plan gratuito incluye 25GB storage)

2. **Obtener credenciales:**
   - Dashboard de Cloudinary → Account Details
   - Copia los siguientes valores:
     - **Cloud Name** (ej: `mycompany-cloud`)
     - **API Key** (ej: `123456789012345`)
     - **API Secret** (click "Reveal" para verlo)

#### 3.3 Configurar Secrets.swift

Abre `PerfBeta/Config/Secrets.swift` y reemplaza los placeholders:

```swift
enum Secrets {
    // ANTES (placeholder):
    static let cloudinaryCloudName = "YOUR_CLOUDINARY_CLOUD_NAME"

    // DESPUÉS (tu valor real):
    static let cloudinaryCloudName = "mycompany-cloud"  // ← TU VALOR AQUÍ

    // Repite para:
    static let cloudinaryAPIKey = "TU_API_KEY_REAL"
    static let cloudinaryAPISecret = "TU_API_SECRET_REAL"
}
```

⚠️ **CRÍTICO:** Si este proyecto ya existía con credenciales expuestas:
1. **ROTA** el API Secret en Cloudinary Dashboard → Settings → Security
2. Usa el **NUEVO** secret en tu `Secrets.swift`

#### 3.4 Verificar Configuración

El proyecto validará automáticamente al iniciar. Si hay errores, verás:

```
⚠️ Cloudinary configuration error: ...
⚠️ Please ensure Secrets.swift is properly configured
```

**Troubleshooting:**
- ❌ "Configuration Error": `Secrets.swift` no existe o tiene placeholders
- ✅ "CloudinaryService initialized": Configuración correcta

### Paso 4: Instalar Dependencias

#### Opción A: Swift Package Manager (Recomendado)

Las dependencias ya están configuradas en el proyecto. Xcode las descargará automáticamente al abrir el proyecto.

1. Abre `PerfBeta.xcodeproj` en Xcode
2. Espera a que Xcode resuelva los paquetes automáticamente
3. Si hay problemas: File → Packages → Resolve Package Versions

#### Opción B: CocoaPods (Si aplica)

Si el proyecto usa CocoaPods:

```bash
# Instalar CocoaPods si no lo tienes
sudo gem install cocoapods

# Instalar dependencias
pod install

# Abrir workspace (NO el .xcodeproj)
open PerfBeta.xcworkspace
```

### Paso 5: Configurar Esquema de Firma

1. Abre el proyecto en Xcode
2. Selecciona el target `PerfBeta`
3. Ve a "Signing & Capabilities"
4. Selecciona tu Team de desarrollo
5. Xcode generará automáticamente el Provisioning Profile

### Paso 6: Compilar y Ejecutar

```bash
# Opción 1: Desde Xcode
# Presiona Cmd+R o click en el botón Play

# Opción 2: Desde terminal
xcodebuild -scheme PerfBeta -configuration Debug
```

**Selecciona un simulador o dispositivo y ejecuta.**

---

## 📁 Estructura del Proyecto

```
PerfBeta/
├── App/                        # Punto de entrada de la app
│   ├── PerfBetaApp.swift      # Main app, configuración Firebase
│   └── LaunchScreen.storyboard
├── Models/                     # Modelos de datos
│   ├── Perfume.swift
│   ├── User.swift
│   ├── OlfactiveProfile.swift
│   ├── TriedPerfumeRecord.swift
│   └── Enums/                 # Enumeraciones (Gender, Season, etc.)
├── Services/                   # Capa de servicios (Firebase, API)
│   ├── AuthService.swift
│   ├── UserService.swift
│   ├── PerfumeService.swift
│   ├── OlfactiveProfileService.swift
│   └── CloudinaryService.swift
├── ViewModels/                 # ViewModels MVVM
│   ├── AuthViewModel.swift
│   ├── UserViewModel.swift
│   ├── PerfumeViewModel.swift
│   └── OlfactiveProfileViewModel.swift
├── Views/                      # Vistas SwiftUI
│   ├── Login/
│   ├── HomeTab/
│   ├── TestTab/
│   ├── LibraryTab/
│   ├── ExploreTab/
│   ├── PerfumeDetail/
│   └── SettingsTab/
├── Components/                 # Componentes reutilizables
│   ├── GradientBackgroundView.swift
│   ├── ItsukiSlider.swift
│   └── AccordionView.swift
├── Helpers/                    # Utilidades y helpers
│   ├── DependencyContainer.swift
│   ├── AppState.swift
│   └── OlfactiveProfileHelper.swift
├── Utils/                      # Utilidades generales
│   ├── GradientPreset.swift
│   ├── TextStyle.swift
│   └── ButtonsStyle.swift
├── Extensions/                 # Extensiones de Swift/SwiftUI
├── Resources/                  # Recursos (localizaciones)
│   └── Localizable.xcstrings
├── Assets.xcassets/           # Imágenes y colores
└── Config/ (crear manualmente)
    └── Secrets.swift          # ⚠️ NO COMMITEAR
```

---

## 🧪 Testing

### Ejecutar Tests

```bash
# Desde terminal
xcodebuild test -scheme PerfBeta -destination 'platform=iOS Simulator,name=iPhone 15'

# Desde Xcode
Cmd+U
```

### Estado Actual de Testing

⚠️ **Tests pendientes de implementación**

**TODO:**
- [ ] Unit tests para ViewModels
- [ ] Unit tests para Services
- [ ] UI tests para flujos críticos
- [ ] Integration tests con Firebase

---

## 🔐 Seguridad

⚠️ **LEE ESTO ANTES DE COMMITEAR CÓDIGO**

### Archivos Sensibles (NUNCA commitear)

- `PerfBeta/GoogleService-Info.plist` - Configuración Firebase
- `PerfBeta/Config/Secrets.swift` - API keys y secrets
- Cualquier archivo con credenciales

### .gitignore Configurado

Ya se incluyó un `.gitignore` completo que protege:
- Archivos de Firebase
- Secrets y configuraciones
- Archivos de Xcode user-specific
- Archivos de sistema macOS

### Mejores Prácticas

1. **Nunca hardcodear secrets en código**
   - ❌ Malo: `let apiKey = "abc123"`
   - ✅ Bueno: `let apiKey = Secrets.cloudinaryAPIKey`

2. **Verificar Security Rules de Firebase**
   - Revisar mensualmente
   - Seguir principio de mínimo privilegio
   - Documentar reglas

3. **Rotar credenciales periódicamente**
   - Especialmente si el repo fue público
   - Después de que un colaborador deje el proyecto

**Ver `SECURITY_ALERT.md` para más detalles sobre seguridad.**

---

## 🎨 Guía de Contribución

### Convenciones de Código

#### Swift Style

- Usar Swift 6.2 features
- Preferir `struct` sobre `class` para modelos
- Usar `async/await` para operaciones asíncronas
- Naming: camelCase para variables/funciones, PascalCase para tipos

#### SwiftUI

- Extraer vistas complejas en componentes separados
- Usar `@EnvironmentObject` para estado compartido
- Preferir `@StateObject` sobre `@ObservedObject`
- Mantener vistas bajo 300 líneas

#### Naming Conventions

- **Services:** `XxxService` + protocol `XxxServiceProtocol`
- **ViewModels:** `XxxViewModel` (siempre `@MainActor`)
- **Views:** `XxxView` (descriptivos)
- **Models:** Sustantivos (Perfume, User)

### Git Workflow

```bash
# Crear branch para feature
git checkout -b feature/nombre-feature

# Commits descriptivos
git commit -m "feat: agregar filtro por temporada"
git commit -m "fix: corregir crash en login con Google"

# Push y crear PR
git push origin feature/nombre-feature
```

### Convención de Commits

Usar [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - Nueva funcionalidad
- `fix:` - Corrección de bug
- `docs:` - Documentación
- `style:` - Formato, punto y coma, etc.
- `refactor:` - Refactorización
- `test:` - Agregar tests
- `chore:` - Mantenimiento

---

## 📚 Documentación Adicional

- **[CLAUDE.md](./CLAUDE.md)** - Documentación técnica completa para asistente AI
- **[TODO.md](./TODO.md)** - Roadmap, features pendientes, priorización
- **[SECURITY_ALERT.md](./SECURITY_ALERT.md)** - Alerta de seguridad y remediación

---

## 🐛 Problemas Conocidos

### Critical
- [ ] Credenciales de Cloudinary hardcodeadas en código (ver SECURITY_ALERT.md)

### Medium
- [ ] Algunos ViewModels muy grandes (AuthViewModel ~479 líneas)
- [ ] Funcionalidad de compartir parcialmente implementada

### Low
- [ ] Falta onboarding para usuarios nuevos
- [ ] ExploreTab necesita más contenido

**Ver [TODO.md](./TODO.md) para lista completa.**

---

## 🗺️ Roadmap

### Version 1.0 (MVP) - 90% Completo
- [x] Autenticación completa
- [x] Sistema de perfiles olfativos
- [x] Biblioteca de perfumes
- [x] Home feed y exploración
- [ ] Onboarding
- [ ] Polish UI/UX

### Version 1.1 (Post-Launch)
- [ ] Editar perfumes probados
- [ ] Búsqueda global
- [ ] Estadísticas de biblioteca
- [ ] Modo oscuro
- [ ] Tests unitarios (50%+ coverage)

### Version 2.0 (Futuro)
- [ ] Features sociales
- [ ] Recomendaciones con IA
- [ ] AR try-on
- [ ] Apple Watch app

**Ver [TODO.md](./TODO.md) para roadmap detallado.**

---

## 📊 Stack de Dependencias

### Firebase
```
Firebase/Auth
Firebase/Firestore
Firebase/Storage
```

### Third-Party
```
Kingfisher ~> 7.0
GoogleSignIn ~> 7.0
Cloudinary ~> 4.0 (pendiente verificar versión)
```

---

## 🤝 Colaboradores

- **Desarrollador Principal:** Juan Ramon Fernandez Calvo
- **Email:** juan-ramon.fernandez@prosegur.com

---

## 📄 Licencia

[Especificar licencia - MIT, Apache, Propietaria, etc.]

---

## 💬 Soporte

**¿Problemas de configuración?**

1. Verificar que `GoogleService-Info.plist` esté en el lugar correcto
2. Verificar que `Secrets.swift` exista y tenga las credenciales correctas
3. Limpiar build: `Cmd+Shift+K` en Xcode
4. Borrar DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`

**¿Errores de compilación?**

1. File → Packages → Reset Package Caches
2. File → Packages → Resolve Package Versions
3. Verificar que el target iOS sea 17.2+

**¿Problemas con Firebase?**

1. Verificar que el Bundle ID coincida: `com.testjr.perfBeta`
2. Verificar que `GoogleService-Info.plist` sea del proyecto correcto
3. Revisar Firebase Console para errores

---

## 📞 Contacto

Para preguntas o soporte:

- **Email:** juan-ramon.fernandez@prosegur.com
- **Firebase Console:** https://console.firebase.google.com/project/perfbeta

---

## ⭐ Agradecimientos

- Firebase por la infraestructura backend
- Kingfisher por la excelente librería de imágenes
- Cloudinary por el CDN de imágenes
- Comunidad de SwiftUI

---

**Última actualización:** Octubre 2025
**Versión:** 1.0 (Beta)
**Estado:** En desarrollo activo
