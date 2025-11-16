# Nuevas Preguntas de Perfil Olfativo

## 📋 Resumen del Cambio

Se han reemplazado las **7 preguntas originales** del test olfativo por **6 nuevas preguntas** con lenguaje más accesible y cotidiano.

## ✨ Nuevas Preguntas

### 1. Nivel de Experiencia (profile_00_classification)
**Pregunta:** "¿Cuál es tu experiencia con perfumes?"

**Opciones:**
- Estoy empezando
- Tengo experiencia
- Soy entusiasta

Esta pregunta inicial ayuda a contextualizar las respuestas posteriores.

### 2. Aromas Cotidianos (profile_A1_simple_preference)
**Pregunta:** "¿Qué aroma cotidiano te resulta más agradable?"

**Opciones:**
- El café por la mañana
- Ropa recién lavada
- Un ramo de flores
- Pastelería horneándose
- Brisa del mar
- Bosque después de la lluvia

Usa referencias del día a día en lugar de términos técnicos como "woody" o "aquatic".

### 3. Momento de Uso (profile_A2_time_preference)
**Pregunta:** "¿Cuándo te gusta más usar perfume?"

**Opciones:**
- Al salir de la ducha matutina
- Para ir al trabajo o estudios
- Para salir por la noche
- Los fines de semana

### 4. Sensación Deseada (profile_A3_desired_feeling)
**Pregunta:** "¿Cómo quieres sentirte con tu perfume?"

**Opciones:**
- Fresco y limpio
- Elegante y sofisticado
- Dulce y acogedor
- Misterioso y seductor
- Natural y relajado

### 5. Intensidad Preferida (profile_A4_intensity_simple)
**Pregunta:** "¿Qué tan notable quieres que sea tu perfume?"

**Opciones:**
- Muy sutil (solo yo puedo percibirlo)
- Suave presencia (se nota cuando alguien se acerca)
- Presencia moderada (en mi espacio personal)
- Presencia notable (dejo una estela agradable)

### 6. Temporada Favorita (profile_A5_season_basic)
**Pregunta:** "¿En qué época del año disfrutas más los perfumes?"

**Opciones:**
- Primavera
- Verano
- Otoño
- Invierno
- Me adapto a cada temporada

## 🔄 Cambios Realizados en Firebase

### Preguntas Eliminadas (IDs 1-7):
- ❌ "¿Qué tipo de perfume prefieres?" (Género Olfativo)
- ❌ "¿En qué momento usarías este perfume?" (Contexto de Uso)
- ❌ "¿Qué palabra te describe mejor?" (Personalidad)
- ❌ "¿Qué aroma prefieres en tu entorno?" (Preferencias Sensoriales)
- ❌ "¿Qué tan perceptible quieres que sea tu perfume?" (Intensidad)
- ❌ "¿Cuánto tiempo esperas que dure el perfume?" (Duración)
- ❌ "¿Cuál es tu estación del año preferida?" (Temporada)

### Preguntas Añadidas:
- ✅ profile_00_classification
- ✅ profile_A1_simple_preference
- ✅ profile_A2_time_preference
- ✅ profile_A3_desired_feeling
- ✅ profile_A4_intensity_simple
- ✅ profile_A5_season_basic

## 🎨 Assets de Imágenes

Los assets de imágenes se mapearon a assets existentes:

```
Nivel de Experiencia:
- beginner → personality_relaxed
- intermediate → personality_confident
- expert → personality_elegant

Aromas Cotidianos:
- coffee → family_gourmand
- clean_laundry → family_aquatic
- flowers → family_floral
- bakery → family_gourmand
- ocean → family_aquatic
- forest → family_woody

Momento de Uso:
- morning → occasion_sports
- work → occasion_office
- night → occasion_nights
- weekend → occasion_social_events

Sensación Deseada:
- fresh_clean → family_aquatic
- elegant → personality_elegant
- sweet_cozy → family_gourmand
- mysterious → personality_romantic
- natural → green

Intensidad:
- very_low/low → intensity_low
- medium → intensity_medium
- high → intensity_high

Temporadas:
- Usan los assets season_* existentes
```

## 🔧 Scripts Utilizados

1. **add_new_profile_questions.py** - Sube las 6 nuevas preguntas a Firebase
2. **remove_old_profile_questions.py** - Elimina las 7 preguntas antiguas
3. **update_question_assets.py** - Actualiza los image_assets para usar assets existentes
4. **export_all_questions.py** - Exporta todas las preguntas de Firebase (utilidad)
5. **export_olfactive_questions.py** - Exporta solo preguntas de perfil olfativo (utilidad)

## 📂 Archivos de Referencia

- **new_profile_questions.json** - Las 6 nuevas preguntas (formato final)
- **olfactive_profile_questions.json** - Las 7 preguntas originales (backup/referencia)
- **all_questions.json** - Snapshot de todas las preguntas en Firebase

## ✅ Estado Actual

- ✅ Preguntas antiguas eliminadas de Firebase
- ✅ Nuevas preguntas subidas a Firebase
- ✅ Assets de imágenes actualizados
- ✅ La app carga automáticamente las nuevas preguntas
- ✅ No se requieren cambios en el código Swift (TestView/TestViewModel)

## 🚀 Próximos Pasos (Opcional)

1. **Crear assets específicos** para las nuevas preguntas en el futuro:
   - Diseños para experience_beginner/intermediate/expert
   - Iconos para scent_coffee, scent_ocean, etc.
   - Iconos para time_morning, feeling_fresh, etc.

2. **Ajustar el algoritmo de cálculo** del perfil si es necesario, basándose en el nuevo sistema de puntuación de familias.

3. **Actualizar textos de ayuda/tooltips** si existen en la UI del test.

## 📊 Sistema de Puntuación

Las nuevas preguntas mantienen el mismo sistema de puntuación por familias olfativas:

```json
"families": {
  "woody": 3,
  "spicy": 2,
  "gourmand": 1
}
```

Los números representan la intensidad de la asociación (1-4) con cada familia olfativa.

---

**Fecha de implementación:** 2025-01-16
**Versión de caché:** No aplica (QuestionsService carga directamente desde Firestore)
