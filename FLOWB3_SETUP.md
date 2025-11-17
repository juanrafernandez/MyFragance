# Añadir Preguntas del Flujo B3

Este documento explica cómo añadir las 4 nuevas preguntas del flujo B3 al sistema de recomendación de regalos.

## 📋 Preguntas a añadir

Las siguientes 4 preguntas se añadirán al flujo B3:

1. **flowB3_02_intensity** - ¿Cómo le gustan los perfumes? (intensidad y proyección)
2. **flowB3_03_moment** - ¿Cuándo usa principalmente perfume? (momento de uso)
3. **flowB3_04_personal_style** - ¿Cuál es su estilo personal? (personalidad)
4. **flowB3_05_budget** - ¿Cuál es tu presupuesto aproximado? (rango de precio)

## 🚀 Método 1: Desde la App (Recomendado)

**⚠️ IMPORTANTE: Ejecutar solo una vez**

1. Compila y ejecuta la app en modo DEBUG
2. Navega a la pestaña **Ajustes** (Settings)
3. Desplázate hasta la sección **🐛 DEBUG** (solo visible en DEBUG builds)
4. Pulsa el botón **"Añadir Preguntas B3"**
5. Espera a que aparezca el mensaje de confirmación
6. Las preguntas se habrán añadido a Firebase y el cache se habrá invalidado automáticamente

### Verificación:
- Revisa la consola para ver los logs de confirmación:
  ```
  📝 Añadiendo pregunta: flowB3_02_intensity
  ✅ Pregunta flowB3_02_intensity añadida correctamente
  ...
  ✨ Todas las preguntas B3 añadidas correctamente
  ```

## 📄 Método 2: Manual desde Firebase Console

Si prefieres añadir las preguntas manualmente:

1. Ve a Firebase Console → Firestore Database
2. Navega a la colección `questions_es`
3. Importa el archivo `flowB3_questions.json` (ubicado en la raíz del proyecto)
4. O crea manualmente los 4 documentos usando los IDs:
   - `flowB3_02_intensity`
   - `flowB3_03_moment`
   - `flowB3_04_personal_style`
   - `flowB3_05_budget`

### Campos requeridos para cada pregunta:
```json
{
  "id": "flowB3_02_intensity",
  "order": 2,
  "flowType": "B3",
  "category": "intensity",
  "question": "¿Cómo le gustan los perfumes?",
  "description": "Define la intensidad y proyección preferida",
  "isConditional": true,
  "conditionalRules": {
    "previousQuestion": "flowB3_01_aroma_types"
  },
  "options": [...],
  "uiConfig": {...},
  "createdAt": <Timestamp>,
  "updatedAt": <Timestamp>
}
```

## 🔄 Después de añadir las preguntas

1. **Invalidar cache:**
   - Si usaste el botón en la app, el cache ya se invalidó automáticamente
   - Si lo hiciste manualmente, ve a Ajustes → Datos → "Limpiar caché local"

2. **Verificar en la app:**
   - Navega a la pestaña de Regalos
   - Inicia un nuevo flujo de recomendación
   - Selecciona "Bajo conocimiento" → "Por tipo de aromas" (flowB3)
   - Deberías ver las nuevas preguntas en secuencia

## 📊 Estructura del Flujo B3

```
flowB3_01_aroma_types (ya existe)
  ↓
flowB3_02_intensity (NUEVA)
  ↓
flowB3_03_moment (NUEVA)
  ↓
flowB3_04_personal_style (NUEVA)
  ↓
flowB3_05_budget (NUEVA)
  ↓
Resultados
```

## 🔍 Troubleshooting

### Las preguntas no aparecen en el flujo
- Verifica que las preguntas se crearon correctamente en Firebase Console
- Limpia el cache desde Ajustes → Datos → "Limpiar caché local"
- Cierra y vuelve a abrir la app
- Verifica los logs en consola: `[GiftQuestionService] Downloaded X questions from Firebase`

### Error al ejecutar desde la app
- Asegúrate de estar ejecutando en modo DEBUG
- Verifica que tienes conexión a Firebase
- Revisa los logs de error en la consola
- Si ya ejecutaste la función una vez, es normal que dé error (las preguntas ya existen)

### Preguntas duplicadas
- Si añadiste las preguntas manualmente Y desde la app, tendrás duplicados
- Elimina las duplicadas desde Firebase Console
- Limpia el cache

## 🗑️ Eliminar la función temporal (después de usar)

Una vez hayas añadido las preguntas exitosamente, puedes:

1. Comentar o eliminar la sección DEBUG de `SettingsView.swift` (líneas 105-135)
2. Comentar o eliminar la función `addFlowB3Questions()` de `GiftQuestionService.swift` (líneas 124-417)
3. La función solo está disponible en DEBUG, así que no aparecerá en builds RELEASE

## ✅ Verificación Final

Después de añadir las preguntas, verifica que:

- [ ] Las 4 preguntas aparecen en Firebase Console → `questions_es`
- [ ] Cada pregunta tiene `flowType: "B3"`
- [ ] El orden es correcto (2, 3, 4, 5)
- [ ] Las preguntas condicionales apuntan a la pregunta anterior correcta
- [ ] El flujo funciona en la app sin errores
- [ ] El cache se ha invalidado y las preguntas se cargan correctamente

---

**Fecha de creación:** 15 de Noviembre de 2025
**Versión:** 1.0
