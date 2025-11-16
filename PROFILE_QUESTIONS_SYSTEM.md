# Sistema Completo de Preguntas de Perfil Olfativo

## 📊 Resumen General

**Total de preguntas:** 16
**Tipos de preguntas:**
- Selección simple: 13 preguntas
- Autocomplete múltiple: 3 preguntas

**Niveles de profundidad:**
- **Serie A (Básicas):** 6 preguntas - Para usuarios que están empezando
- **Serie B (Intermedias):** 5 preguntas - Para usuarios con experiencia
- **Serie C (Expertas):** 5 preguntas - Para entusiastas avanzados

---

## 🎯 Serie A - Preguntas Básicas (Orden 0-5)

### 0. Nivel de Experiencia (profile_00_classification)
**Categoría:** Nivel de Experiencia
**Tipo:** perfil_olfativo
**Pregunta:** "¿Cuál es tu experiencia con perfumes?"

**Opciones:**
1. Estoy empezando
2. Tengo experiencia
3. Soy entusiasta

---

### 1. Aromas Cotidianos (profile_A1_simple_preference)
**Categoría:** Aromas Cotidianos
**Tipo:** perfil_olfativo
**Pregunta:** "¿Qué aroma cotidiano te resulta más agradable?"

**Opciones:**
1. El café por la mañana
2. Ropa recién lavada
3. Un ramo de flores
4. Pastelería horneándose
5. Brisa del mar
6. Bosque después de la lluvia

---

### 2. Momento de Uso (profile_A2_time_preference)
**Categoría:** Momento de Uso
**Tipo:** perfil_olfativo
**Pregunta:** "¿Cuándo te gusta más usar perfume?"

**Opciones:**
1. Al salir de la ducha matutina
2. Para ir al trabajo o estudios
3. Para salir por la noche
4. Los fines de semana

---

### 3. Sensación Deseada (profile_A3_desired_feeling)
**Categoría:** Sensación Deseada
**Tipo:** perfil_olfativo
**Pregunta:** "¿Cómo quieres sentirte con tu perfume?"

**Opciones:**
1. Fresco y limpio
2. Elegante y sofisticado
3. Dulce y acogedor
4. Misterioso y seductor
5. Natural y relajado

---

### 4. Intensidad Preferida (profile_A4_intensity_simple)
**Categoría:** Intensidad Preferida
**Tipo:** perfil_olfativo
**Pregunta:** "¿Qué tan notable quieres que sea tu perfume?"

**Opciones:**
1. Muy sutil (solo yo puedo percibirlo)
2. Suave presencia (se nota cuando alguien se acerca)
3. Presencia moderada (en mi espacio personal)
4. Presencia notable (dejo una estela agradable)

---

### 5. Temporada Favorita (profile_A5_season_basic)
**Categoría:** Temporada Favorita
**Tipo:** perfil_olfativo
**Pregunta:** "¿En qué época del año disfrutas más los perfumes?"

**Opciones:**
1. Primavera
2. Verano
3. Otoño
4. Invierno
5. Me adapto a cada temporada

---

## 🎨 Serie B - Preguntas Intermedias (Orden 6-10)

### 6. Estilo de Fragancia (profile_B1_mixed_preference)
**Categoría:** Estilo de Fragancia
**Tipo:** perfil_olfativo
**Pregunta:** "¿Qué estilo de fragancia te atrae más?"

**Opciones con referencias:**
1. Frescos y limpios - Como Acqua di Giò, Light Blue, CK One
2. Florales elegantes - Como Chanel N°5, Miss Dior, Flowerbomb
3. Dulces y golosos - Como La Vie Est Belle, Black Opium, Angel
4. Amaderados sofisticados - Como Terre d'Hermès, Bleu de Chanel, Santal 33
5. Orientales intensos - Como Opium, Spicebomb, Tom Ford Black Orchid
6. Cítricos energizantes - Como Dior Homme Cologne, Versace Man Eau Fraîche

---

### 7. Personalidad (profile_B2_personality)
**Categoría:** Personalidad
**Tipo:** perfil_olfativo
**Pregunta:** "¿Cómo describirías tu estilo personal?"

**Opciones:**
1. Clásico y atemporal
2. Moderno y minimalista
3. Romántico y soñador
4. Audaz y llamativo
5. Deportivo y casual
6. Sofisticado y urbano

---

### 8. Notas Favoritas (profile_B3_preferred_notes)
**Categoría:** Notas Favoritas
**Tipo:** autocomplete_multiple
**Pregunta:** "¿Hay alguna nota específica que te encante?"

**Configuración:**
- Helper text: "Opcional: Busca hasta 3 notas que disfrutes especialmente"
- Placeholder: "Busca: vainilla, jazmín, sándalo, bergamota..."
- Data source: notes_database
- Max selections: 3
- Min selections: 0
- Skip option: "No conozco notas específicas"

---

### 9. Ocasión Principal (profile_B4_occasion)
**Categoría:** Ocasión Principal
**Tipo:** perfil_olfativo
**Pregunta:** "¿Para qué ocasión buscas principalmente un perfume?"

**Opciones:**
1. Trabajo diario
2. Citas románticas
3. Eventos sociales
4. Actividades al aire libre
5. Uso versátil
6. Ocasiones especiales

---

### 10. Apertura al Descubrimiento (profile_B5_discovery)
**Categoría:** Apertura al Descubrimiento
**Tipo:** perfil_olfativo
**Pregunta:** "¿Qué tan aventurero eres con las fragancias?"

**Opciones:**
1. Prefiero lo seguro
2. Abierto con límites
3. Me encanta explorar
4. Quiero sorprenderme

---

## 🎓 Serie C - Preguntas Expertas (Orden 11-15)

### 11. Estructura Olfativa (profile_C1_structure)
**Categoría:** Estructura Olfativa
**Tipo:** perfil_olfativo
**Pregunta:** "¿Qué tipo de estructura olfativa prefieres?"

**Opciones con perfumes de referencia:**
1. Lineal/Monolítica - Molecule 01, Santal 33, Not a Perfume
2. Pirámide clásica - Chanel N°5, Shalimar, Mitsouko
3. Salida explosiva - Aventus, BR540, Erba Pura
4. Base dominante - Oud Wood, Black Afgano, Interlude Man
5. Radial/Caleidoscópica - Jubilation XXV, Portrait of a Lady, Amber Absolute
6. Metamórfica - Kouros, Secretions Magnifiques, Bat

---

### 12. Concentración (profile_C2_concentration)
**Categoría:** Concentración
**Tipo:** perfil_olfativo
**Pregunta:** "¿Qué concentración prefieres para tu uso habitual?"

**Opciones con detalles técnicos:**
1. Eau Fraîche/Cologne (1-3%) - Duración 1-2h - 4711, Roger & Gallet
2. EDT (5-15%) - Duración 3-5h - Mayoría de freshies
3. EDP (15-20%) - Duración 5-8h - Estándar moderno
4. Parfum/Extrait (20-40%) - Duración 8h+ - Roja, Clive Christian
5. Aceites/Attars - Sin alcohol, duración excepcional
6. Depende del perfume - Cada fragancia tiene su concentración óptima

---

### 13. Referencias Personales (profile_C3_reference_perfumes)
**Categoría:** Referencias Personales
**Tipo:** autocomplete_multiple
**Pregunta:** "¿Cuáles son tus perfumes de referencia absolutos?"

**Configuración:**
- Helper text: "Busca hasta 5 perfumes que definan tu estilo olfativo"
- Placeholder: "Busca: Aventus, Baccarat Rouge 540, Oud Wood..."
- Data source: perfume_database
- Max selections: 5
- Min selections: 1

---

### 14. Preferencias Estacionales (profile_C4_seasonal_preference)
**Categoría:** Preferencias Estacionales
**Tipo:** perfil_olfativo
**Pregunta:** "¿Cómo adaptas tus fragancias según la temporada?"

**Opciones:**
1. Siempre frescos, todo el año
2. Frescos en verano, cálidos en invierno
3. Intensos todo el año
4. Por temperatura real, no calendario
5. Por ocasión, ignoro la estación

---

### 15. Balance de Notas (profile_C5_note_balance)
**Categoría:** Balance de Notas
**Tipo:** perfil_olfativo
**Pregunta:** "¿Qué balance de notas prefieres en la evolución del perfume?"

**Opciones:**
1. Salida protagonista - Cítricos o frutas dominan
2. Corazón dominante - Florales o especiadas son las estrellas
3. Base persistente - Maderas, resinas y notas de fondo
4. Equilibrio perfecto - Transición suave entre fases
5. Sin fases, todo junto - Todas las notas desde el inicio

---

## 🎨 Mapeo de Image Assets

### Assets de Familias
- `family_aquatic` - Acuáticos/Frescos
- `family_floral` - Florales
- `family_gourmand` - Golosos/Dulces
- `family_woody` - Amaderados
- `family_oriental` - Orientales
- `family_citrus` - Cítricos
- `green` - Verdes

### Assets de Personalidad
- `personality_relaxed` - Relajado/Casual
- `personality_confident` - Confiado/Moderno
- `personality_elegant` - Elegante/Clásico
- `personality_romantic` - Romántico
- `personality_adventurous` - Aventurero/Audaz

### Assets de Ocasión
- `occasion_sports` - Deportivo/Aire libre
- `occasion_office` - Trabajo/Oficina
- `occasion_nights` - Noches/Salidas
- `occasion_social_events` - Eventos sociales
- `occasion_dates` - Citas románticas
- `occasion_daily` - Uso diario
- `occasion_formal` - Ocasiones especiales

### Assets de Intensidad
- `intensity_low` - Baja intensidad
- `intensity_medium` - Intensidad media
- `intensity_high` - Alta intensidad

### Assets de Duración
- `duration_very_long` - Duración muy larga

### Assets de Estación
- `season_spring` - Primavera
- `season_summer` - Verano
- `season_autumn` - Otoño
- `season_winter` - Invierno
- `season_all` - Todas las estaciones

---

## 📈 Sistema de Scoring de Familias

Cada opción de respuesta tiene un objeto `families` que asigna puntos a diferentes familias olfativas:

```json
"families": {
  "woody": 4,      // Peso máximo
  "oriental": 3,   // Peso alto
  "spicy": 2,      // Peso medio
  "citrus": 1      // Peso bajo
}
```

**Escala de puntuación:**
- **4 puntos:** Asociación muy fuerte con la familia
- **3 puntos:** Asociación fuerte
- **2 puntos:** Asociación moderada
- **1 punto:** Asociación leve

---

## 🔄 Flujo de Uso

### Para Usuarios Principiantes (Serie A):
1. Responder las 6 preguntas básicas
2. Lenguaje cotidiano y accesible
3. Sin referencias técnicas
4. Tiempo estimado: 2-3 minutos

### Para Usuarios con Experiencia (Serie A + B):
1. Responder Serie A (6 preguntas)
2. Responder Serie B (5 preguntas)
3. Incluye referencias a perfumes conocidos
4. Opción de buscar notas específicas
5. Tiempo estimado: 4-6 minutos

### Para Entusiastas Avanzados (Serie A + B + C):
1. Responder Serie A (6 preguntas)
2. Responder Serie B (5 preguntas)
3. Responder Serie C (5 preguntas)
4. Terminología técnica de perfumería
5. Referencias a perfumes nicho y de culto
6. Búsqueda de perfumes de referencia personales
7. Tiempo estimado: 7-10 minutos

---

## 🚀 Implementación Técnica

### Firebase Collection: `questions_es`

**Campos comunes:**
```json
{
  "id": "profile_X#_name",
  "key": "unique_key",
  "questionType": "perfil_olfativo" | "autocomplete_multiple",
  "order": 0-15,
  "category": "Nombre de la Categoría",
  "text": "Texto de la pregunta",
  "options": [...],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Campos para autocomplete:**
```json
{
  "helper_text": "Texto de ayuda",
  "placeholder": "Texto del placeholder",
  "data_source": "notes_database" | "perfume_database",
  "max_selections": 3 | 5,
  "min_selections": 0 | 1,
  "skip_option": {
    "label": "Texto del skip",
    "value": "skip"
  }
}
```

### Carga en Cliente (Swift)

El `QuestionsService` carga automáticamente todas las preguntas ordenadas:

```swift
let questions = try await questionsService.fetchQuestions(type: .perfilOlfativo)
// Retorna las 16 preguntas ordenadas por campo 'order'
```

---

## 📝 Scripts de Gestión

### Añadir Preguntas
- `add_new_profile_questions.py` - Serie A (básicas)
- `add_intermediate_questions.py` - Serie B (intermedias)
- `add_expert_questions.py` - Serie C (expertas)

### Utilidades
- `verify_all_questions.py` - Verificar todas las preguntas en Firebase
- `export_all_questions.py` - Exportar todas las preguntas a JSON
- `export_olfactive_questions.py` - Exportar solo preguntas de perfil olfativo
- `update_question_assets.py` - Actualizar assets de imágenes

### Limpieza
- `remove_old_profile_questions.py` - Eliminar preguntas antiguas (IDs 1-7)

---

## 🎯 Próximos Pasos (Opcional)

### 1. UI Dinámica según Nivel
- Mostrar Serie A a todos los usuarios
- Mostrar Serie B solo si responden "Tengo experiencia" o "Soy entusiasta"
- Mostrar Serie C solo si responden "Soy entusiasta"

### 2. Implementar Autocomplete
- Crear componente de búsqueda para notas
- Crear componente de búsqueda para perfumes
- Integrar con bases de datos de notas y perfumes

### 3. Assets Personalizados
- Diseñar iconos específicos para estructura olfativa
- Diseñar iconos para concentración
- Diseñar iconos para balance de notas

### 4. Algoritmo de Scoring Mejorado
- Ponderar más las respuestas de Serie C
- Implementar scoring diferenciado por nivel de experiencia
- Ajustar recomendaciones según profundidad del perfil

---

**Fecha de última actualización:** 2025-01-16
**Versión del sistema:** 2.0 (3 niveles de profundidad)
**Total de preguntas:** 16 (6 + 5 + 5)
