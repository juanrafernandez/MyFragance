# 🎁 Preguntas del Sistema de Recomendaciones de Regalo

Este directorio contiene todas las preguntas en formato JSON para el sistema de recomendaciones de regalo de PerfBeta.

## 📋 Estructura de Preguntas

### Preguntas Principales (main)
1. `main_01_knowledge_level.json` - ¿Qué tan bien conoces a la persona?
2. `main_02_gender.json` - ¿Para quién es el perfume?
3. `main_03b_reference_type.json` - ¿Qué tipo de referencia tienes? (condicional)

### Flow A - Bajo Conocimiento (5 preguntas)
- `flowA_01_personality.json` - Personalidad/estilo
- `flowA_02_occasion.json` - Ocasión de uso
- `flowA_03_age_range.json` - Rango de edad
- `flowA_04_intensity.json` - Intensidad preferida
- `flowA_05_season.json` - Temporada de uso

### Flow B1 - Por Marcas (1 pregunta)
- `flowB1_01_brands.json` - Marcas favoritas (selección múltiple)

### Flow B2 - Por Perfume Específico (1 pregunta)
- `flowB2_01_perfume_search.json` - Búsqueda de perfume (entrada de texto)

### Flow B3 - Por Aromas (1 pregunta)
- `flowB3_01_aromas.json` - Familias olfativas preferidas (selección múltiple)

### Flow B4 - Sin Referencias (2 preguntas)
- `flowB4_01_lifestyle.json` - Estilo de vida
- `flowB4_02_preferences.json` - Preferencias generales

**Total: 13 preguntas**

---

## 🚀 Subir Preguntas a Firebase

### Paso 1: Obtener Credenciales de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/project/perfbeta)
2. Haz clic en el ícono de engranaje ⚙️ → **Project Settings**
3. Ve a la pestaña **Service Accounts**
4. Haz clic en **Generate new private key**
5. Se descargará un archivo JSON (ej: `perfbeta-firebase-adminsdk-xxxxx.json`)
6. **IMPORTANTE**: NO compartas este archivo ni lo subas a Git

### Paso 2: Configurar Credenciales

Opción A: Variable de entorno (recomendado)
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/ruta/completa/al/archivo-credenciales.json"
```

Opción B: Copiar archivo al directorio del proyecto
```bash
cp ~/Downloads/perfbeta-firebase-adminsdk-xxxxx.json ./firebase-credentials.json
# Asegúrate de que está en .gitignore
echo "firebase-credentials.json" >> .gitignore
```

### Paso 3: Ejecutar Script de Subida

```bash
# Desde el directorio raíz del proyecto
python3 upload_gift_questions.py
```

### Salida Esperada

```
============================================================
🎁 SUBIENDO PREGUNTAS DE REGALO A FIREBASE
============================================================

📁 Encontrados 13 archivos de preguntas

🔥 Inicializando Firebase...
✅ Firebase inicializado correctamente

📤 Subiendo: main_01_knowledge_level.json
   ✅ ID: main_01_knowledge_level
   📝 Pregunta: ¿Qué tan bien conoces los gustos de esta persona?

... (más preguntas) ...

============================================================
📊 RESUMEN
============================================================
✅ Preguntas subidas exitosamente: 13
🔗 Colección: gift_questions
📍 Total documentos: 13

📋 ESTRUCTURA POR FLUJO:

  • Preguntas Principales: 3 preguntas
  • Flow A (Bajo Conocimiento): 5 preguntas
  • Flow B1 (Por Marcas): 1 preguntas
  • Flow B2 (Por Perfume): 1 preguntas
  • Flow B3 (Por Aromas): 1 preguntas
  • Flow B4 (Sin Referencias): 2 preguntas

🎉 ¡Listo! Puedes verificar en Firebase Console:
   https://console.firebase.google.com/project/perfbeta/firestore
============================================================
```

---

## 🔍 Verificar en Firebase Console

1. Ve a [Firestore Database](https://console.firebase.google.com/project/perfbeta/firestore)
2. Busca la colección **`gift_questions`**
3. Deberías ver 13 documentos con IDs:
   - main_01_knowledge_level
   - main_02_gender
   - main_03b_reference_type
   - flowA_01_personality
   - flowA_02_occasion
   - flowA_03_age_range
   - flowA_04_intensity
   - flowA_05_season
   - flowB1_01_brands
   - flowB2_01_perfume_search
   - flowB3_01_aromas
   - flowB4_01_lifestyle
   - flowB4_02_preferences

---

## 🔧 Troubleshooting

### Error: "No module named 'firebase_admin'"
```bash
pip3 install firebase-admin
```

### Error: "Could not automatically determine credentials"
- Asegúrate de haber configurado `GOOGLE_APPLICATION_CREDENTIALS`
- Verifica que el archivo de credenciales existe y es válido

### Error: "Permission denied"
- Verifica que la cuenta de servicio tiene permisos de escritura en Firestore
- En Firebase Console → Firestore → Rules, asegúrate de que el admin tiene acceso

---

## 📝 Estructura de Documento

Cada pregunta sigue este esquema:

```json
{
  "id": "unique_question_id",
  "category": "question_category",
  "flowType": "main|A|B1|B2|B3|B4",
  "order": 1,
  "question": "Texto de la pregunta",
  "description": "Descripción adicional",
  "isConditional": false,
  "conditionalRules": {
    "category": "expected_value"
  },
  "options": [
    {
      "id": "option_id",
      "text": "Texto visible",
      "description": "Descripción de la opción",
      "value": "valor_interno",
      "imageUrl": null
    }
  ],
  "uiConfig": {
    "displayType": "vertical_cards|grid|text_field",
    "isMultipleSelection": false,
    "isTextInput": false,
    "minSelection": 1,
    "maxSelection": 1
  }
}
```

---

## 🎯 Siguiente Paso

Una vez subidas las preguntas, la app las cargará automáticamente desde Firebase cuando el usuario acceda al flujo de recomendaciones de regalo.

**Ubicación en la app**: TestTab → "Buscar un Regalo" 🎁
