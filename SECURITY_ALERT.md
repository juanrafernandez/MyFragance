# 🚨 ALERTA DE SEGURIDAD CRÍTICA - ACCIÓN INMEDIATA REQUERIDA

**Fecha:** 20 de Octubre, 2025
**Severidad:** CRÍTICA
**Estado:** REQUIERE ACCIÓN INMEDIATA

---

## ⚠️ CREDENCIALES EXPUESTAS DETECTADAS

### 1. Cloudinary API Credentials (HARDCODED)

**Archivo:** `PerfBeta/Services/CloudinaryService.swift:8`

```swift
let config = CLDConfiguration(
    cloudName: "dx8zzuvad",
    apiKey: "233682717388671",
    apiSecret: "AWjHmvlXTbRlkx13QurretmUk_I"  // ⚠️ SECRET EXPUESTO
)
```

**Impacto:**
- ❌ API Secret de Cloudinary expuesto en código fuente
- ❌ Cualquiera con acceso al código puede usar tu cuenta de Cloudinary
- ❌ Riesgo de uso no autorizado de recursos
- ❌ Posible facturación no autorizada

**Estado:** Commiteado en git desde el inicio del proyecto

---

### 2. Firebase Configuration (GoogleService-Info.plist)

**Archivo:** `PerfBeta/GoogleService-Info.plist`

**Contenido expuesto:**
```
API_KEY: AIzaSyBiQGJI5I3LBZa_miw_KSej161SVTLjXjQ
PROJECT_ID: perfbeta
CLIENT_ID: 296354839132-2loobc3aavrm8qlflv8tu5t4f0qve0ba.apps.googleusercontent.com
```

**Impacto:**
- ⚠️ API Key de Firebase expuesta
- ⚠️ Aunque el API Key de Firebase es "público", debe protegerse
- ⚠️ Sin Security Rules estrictas, datos pueden estar expuestos

**Estado:** Commiteado en git desde noviembre 2024

---

## ✅ ACCIONES COMPLETADAS

1. ✅ `.gitignore` creado con protección para:
   - `GoogleService-Info.plist`
   - Archivos de configuración sensibles
   - Variables de entorno
   - Archivos de backup y temporales

---

## 🔴 ACCIONES REQUERIDAS INMEDIATAMENTE

### CRÍTICO - Cloudinary

#### Opción A: Rotar Credenciales (RECOMENDADO)
1. **Ir a Cloudinary Dashboard:**
   - https://cloudinary.com/console
   - Settings → Security → API Keys

2. **Regenerar API Secret:**
   - Click en "Reset API Secret"
   - Guardar nuevo secret

3. **Actualizar código (ver solución abajo)**

#### Opción B: Restringir API Key
1. En Cloudinary Dashboard → Settings → Security
2. Habilitar "Signed uploads only"
3. Configurar allowed domains/IP addresses

---

### ALTO - Firebase

#### 1. Verificar Firebase Security Rules
```bash
# Conectar a Firebase Console
# https://console.firebase.google.com/project/perfbeta
```

**Firestore Rules que DEBES tener:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users: solo el propio usuario puede leer/escribir
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Perfumes: lectura pública, escritura solo admin
    match /perfumes/{perfumeId} {
      allow read: if true;
      allow write: if request.auth != null &&
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rol == "admin";
    }

    // Olfactive Profiles: solo el usuario
    match /olfactive_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Tried Perfumes: solo el usuario
    match /tried_perfumes/{userId}/records/{recordId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Wishlist: solo el usuario
    match /wishlist/{userId}/items/{itemId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Reference data: lectura pública, escritura admin
    match /{document=**} {
      allow read: if true;
      allow write: if request.auth != null &&
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rol == "admin";
    }
  }
}
```

#### 2. Eliminar GoogleService-Info.plist del historial de Git

⚠️ **SOLO SI EL REPO ES PÚBLICO O SERÁ PÚBLICO:**

```bash
# ADVERTENCIA: Esto reescribe el historial de Git
# Hacer backup antes de ejecutar

# Opción 1: Usando git-filter-repo (recomendado)
# Instalar: brew install git-filter-repo
git filter-repo --path PerfBeta/GoogleService-Info.plist --invert-paths

# Opción 2: Usando BFG Repo Cleaner
# Descargar de: https://rtyley.github.io/bfg-repo-cleaner/
java -jar bfg.jar --delete-files GoogleService-Info.plist
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# Después de cualquier opción:
git push --force --all
```

⚠️ **NOTA:** Si otros desarrolladores han clonado el repo, deben re-clonar.

---

## ✅ SOLUCIÓN RECOMENDADA: Usar Variables de Entorno

### Paso 1: Crear archivo de configuración seguro

**Crear:** `PerfBeta/Config/Secrets.swift` (este archivo NO se commitea)

```swift
// Secrets.swift - NO COMMITEAR A GIT
import Foundation

enum Secrets {
    static let cloudinaryCloudName = "dx8zzuvad"
    static let cloudinaryAPIKey = "233682717388671"
    static let cloudinaryAPISecret = "AWjHmvlXTbRlkx13QurretmUk_I"  // CAMBIAR DESPUÉS DE ROTAR
}
```

### Paso 2: Crear template público

**Crear:** `PerfBeta/Config/Secrets.swift.template`

```swift
// Secrets.swift.template
// Copia este archivo como Secrets.swift y completa los valores
import Foundation

enum Secrets {
    static let cloudinaryCloudName = "YOUR_CLOUD_NAME"
    static let cloudinaryAPIKey = "YOUR_API_KEY"
    static let cloudinaryAPISecret = "YOUR_API_SECRET"
}
```

### Paso 3: Actualizar CloudinaryService

```swift
// CloudinaryService.swift
import Cloudinary
import UIKit

class CloudinaryService {
    private let cloudinary: CLDCloudinary

    init() {
        let config = CLDConfiguration(
            cloudName: Secrets.cloudinaryCloudName,
            apiKey: Secrets.cloudinaryAPIKey,
            apiSecret: Secrets.cloudinaryAPISecret
        )
        self.cloudinary = CLDCloudinary(configuration: config)
    }

    // ... resto del código
}
```

### Paso 4: Actualizar .gitignore

Ya completado ✅ - incluye:
```
**/Config/Secrets.swift
**/Config/APIKeys.swift
```

### Paso 5: Actualizar README con instrucciones

Ver README.md (próximo paso)

---

## 📋 MEJOR PRÁCTICA: Usar Xcode Configuration Files

### Alternativa más robusta (para futuro):

1. Crear `Config.xcconfig`:
```
CLOUDINARY_CLOUD_NAME = dx8zzuvad
CLOUDINARY_API_KEY = 233682717388671
CLOUDINARY_API_SECRET = AWjHmvlXTbRlkx13QurretmUk_I
```

2. Agregar a .gitignore:
```
*.xcconfig
!Config.template.xcconfig
```

3. Leer en código:
```swift
let cloudName = Bundle.main.object(forInfoDictionaryKey: "CLOUDINARY_CLOUD_NAME") as? String
```

---

## 🔍 VERIFICACIÓN POST-REMEDIACIÓN

- [ ] Cloudinary API Secret rotado
- [ ] `Secrets.swift` creado y funcional
- [ ] `CloudinaryService.swift` actualizado
- [ ] Firebase Security Rules verificadas y actualizadas
- [ ] `.gitignore` aplicado correctamente
- [ ] `GoogleService-Info.plist` eliminado del historial (si repo público)
- [ ] Nuevo commit sin credenciales
- [ ] README actualizado con instrucciones de configuración
- [ ] Team notificado (si aplica)

---

## 📞 CONTACTO DE EMERGENCIA

Si detectas uso no autorizado:

**Cloudinary:**
- Dashboard: https://cloudinary.com/console
- Support: https://support.cloudinary.com

**Firebase:**
- Console: https://console.firebase.google.com/project/perfbeta
- Support: https://firebase.google.com/support

**Google Cloud (si aplica):**
- Console: https://console.cloud.google.com
- Revocar credenciales comprometidas inmediatamente

---

## 📚 RECURSOS

- [OWASP: Hardcoded Secrets](https://owasp.org/www-community/vulnerabilities/Use_of_hard-coded_password)
- [Firebase Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Git: Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

---

**Prioridad:** 🔴 CRÍTICA - Atender dentro de 24 horas
**Próximos pasos:** Ver sección "ACCIONES REQUERIDAS INMEDIATAMENTE"
