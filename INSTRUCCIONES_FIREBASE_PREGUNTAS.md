# Instrucciones para Subir Preguntas de Evaluación a Firebase

## 📋 Resumen

He creado **7 preguntas de evaluación** listas para subir a Firestore:

### Tipo "mi_opinion" (4 preguntas esenciales):
1. **Duración** - ¿Cuánto tiempo duró el perfume? (4 opciones)
2. **Proyección** - ¿Cuál fue la proyección? (4 opciones)
3. **Precio** - ¿Cómo valoras la relación calidad-precio? (4 opciones)
4. **Impresiones y Rating** - Comparte tus impresiones y califica (campo libre)

### Tipo "evaluacion_completa" (7 preguntas - incluye las 4 anteriores más):
5. **Ocasiones** - ¿En qué ocasiones usarías este perfume? (11 opciones - multiselección)
6. **Personalidades** - ¿Qué personalidades refleja? (10 opciones - multiselección)
7. **Estaciones** - ¿En qué estaciones usarías este perfume? (4 opciones - multiselección)

## 🚀 Pasos para Subir a Firebase Console

### Opción 1: Subida Individual (Recomendado para testing)

1. **Abre Firebase Console:**
   - Ve a https://console.firebase.google.com
   - Selecciona tu proyecto: `perfbeta`

2. **Navega a Firestore Database:**
   - En el menú lateral: `Firestore Database` → `Data`

3. **Accede a la colección `questions_es`:**
   - Si no existe, créala haciendo clic en "Start collection"
   - Nombre: `questions_es`

4. **Añade cada pregunta como documento:**
   - Haz clic en "Add document"
   - **Document ID:** Usa el campo `id` del JSON (ej: `eval_duration_001`)
   - **Copia los campos** del JSON correspondiente

### Formato de Campos para Firebase Console:

**Para la pregunta de Duración (ejemplo):**
```
Document ID: eval_duration_001

Campos:
┌─────────────────┬─────────────────────┬──────────┐
│ Field           │ Type                │ Value    │
├─────────────────┼─────────────────────┼──────────┤
│ id              │ string              │ eval_duration_001 │
│ key             │ string              │ eval_duration │
│ questionType    │ string              │ mi_opinion │
│ order           │ number              │ 1 │
│ category        │ string              │ evaluation │
│ text            │ string              │ ¿Cuánto tiempo duró el perfume en tu piel? │
│ stepType        │ string              │ duration │
│ options         │ array               │ [copiar array de opciones] │
└─────────────────┴─────────────────────┴──────────┘
```

**Para el campo `options` (array):**
- Haz clic en el icono "+" junto a `options`
- Selecciona tipo: **array**
- Dentro del array, añade objetos (maps) para cada opción:
  - Cada opción es un **map** con campos:
    - `id` (string)
    - `label` (string)
    - `value` (string)
    - `description` (string)
    - `image_asset` (string)
    - `families` (map) - vacío `{}`

### Opción 2: Importación Masiva con Firebase CLI (Más rápido)

**Requisitos previos:**
- Instalar Firebase CLI: `npm install -g firebase-tools`
- Autenticarte: `firebase login`

**Pasos:**

1. **Inicializa Firebase en tu proyecto:**
```bash
cd /Users/juanrafernandez/Documents/GitHub/MyFragance
firebase init firestore
```

2. **Usa el archivo JSON que creé:**
   - Archivo: `firebase_evaluation_questions_es.json`

3. **Importa las preguntas:**
```bash
# Instala firestore-import (si no lo tienes)
npm install -g node-firestore-import-export

# Importa los datos
firestore-import --accountCredentials serviceAccountKey.json --backupFile firebase_evaluation_questions_es.json --nodePath "questions_es"
```

### Opción 3: Script Python (Alternativa)

Puedo crear un script Python si prefieres automatizar la subida. Solo dime y te lo preparo.

## ✅ Verificación

Después de subir las preguntas, verifica en Firebase Console que:

1. **Collection `questions_es` existe**
2. **7 documentos creados:**
   - `eval_duration_001`
   - `eval_projection_002`
   - `eval_price_003`
   - `eval_impressions_004`
   - `eval_occasions_005`
   - `eval_personalities_006`
   - `eval_seasons_007`

3. **Campos correctos en cada documento:**
   - Todos tienen `questionType` y `order`
   - `questionType` = `"mi_opinion"` para las primeras 4
   - `questionType` = `"evaluacion_completa"` para las 3 últimas

## 📝 Notas Importantes

- **No requiere índice compuesto** porque el código ordena en memoria
- Las preguntas usan el mismo formato que las de perfil olfativo
- `multiSelect: true` indica preguntas de selección múltiple (Ocasiones, Personalidades, Estaciones)
- La pregunta de Impresiones no tiene opciones (es campo libre + rating)

## 🔄 Próximos Pasos

Después de subir las preguntas, te ayudaré a:
1. Adaptar el código para cargar estas preguntas desde Firebase
2. Actualizar el flujo "Mi Opinión" para usar las preguntas dinámicas
3. Probar el flujo completo

---

**Archivo JSON:** `/Users/juanrafernandez/Documents/GitHub/MyFragance/firebase_evaluation_questions_es.json`
