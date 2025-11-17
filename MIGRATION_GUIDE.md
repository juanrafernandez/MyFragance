# Guía de Migración: Sistema Unificado de Recomendaciones

## 📋 Resumen

Esta guía describe el proceso de migración del sistema dual actual (OlfactiveProfileHelper + GiftScoringEngine) al nuevo sistema unificado (UnifiedRecommendationEngine).

**Estado Actual:** ✅ Modelos y Engine implementados  
**Próximo Paso:** Integración gradual en ViewModels

---

## 🎯 Objetivo

Unificar ambos sistemas de recomendación en un solo motor que:
- Procese respuestas de CUALQUIER flujo (A/B/C personal, gift flows)
- Genere perfiles estandarizados (UnifiedProfile)
- Use el mismo algoritmo base ajustando pesos según contexto

---

## 📦 Componentes Implementados

### 1. ✅ Modelos Actualizados

#### Question.swift - Campos Nuevos
- `weight: Int?` - Peso de la pregunta (0-3) para el algoritmo
- `helperText, placeholder, dataSource` - Soporte para autocomplete
- `maxSelections, minSelections` - Límites para autocomplete
- `skipOption` - Opción de saltar pregunta

#### Option.swift - Metadata
- `metadata: OptionMetadata?` - Contexto adicional
- Soporta: gender, occasion, season, personality, intensity, duration, projection, avoidFamilies, phasePreference, discoveryMode

### 2. ✅ UnifiedProfile.swift
Modelo unificado con:
- Identificación (id, name, profileType, experienceLevel)
- Core olfativo (primaryFamily, subfamilies, familyScores)
- Metadata rica (preferredNotes, avoidFamilies, referencePerfumes, performance, context)
- Sistema de confianza (confidenceScore, answerCompleteness)
- **Compatibilidad legacy:** `toLegacyProfile()` y `fromLegacyProfile()`

### 3. ✅ UnifiedRecommendationEngine.swift
Engine que implementa:
- Cálculo de perfil desde respuestas
- Sistema de pesos contextuales (personal vs gift)
- Matching de perfumes con penalizaciones
- Todas las reglas críticas especificadas

---

## ⚠️ Reglas Críticas Implementadas

### ✅ REGLA 1: Solo weight > 0 contribuye a familias
```swift
if weight > 0 {
    for (family, points) in option.families {
        familyScores[family] += Double(points * weight)
    }
}
```

### ✅ REGLA 2: Notas preferidas NO modifican familias
Se guardan en metadata para bonus directo

### ✅ REGLA 3: Perfumes de referencia SÍ modifican familias
Se analizan y suman a familyScores

### ✅ REGLA 4: weight = 0 significa solo metadata
Solo extrae metadata, no modifica familyScores

### ✅ Pesos Contextuales
- **Personal:** 60% familias, 20% notas, 10% context, 5% popularity, 5% price
- **Regalo:** 40% familias, 20% popularidad, 15% occasion, 10% precio, 10% notas, 5% season

### ✅ Penalizaciones AL FINAL
Primero calcular score base, luego aplicar penalizaciones (avoid_families, gender filter)

### ✅ Normalización a 100
Familia con mayor puntaje = 100, las demás en proporción

---

## 🔄 Plan de Migración

### Fase 1: Preparación ✅ COMPLETADA
- [x] Actualizar modelos Question/Option
- [x] Crear UnifiedProfile
- [x] Crear UnifiedRecommendationEngine

### Fase 2: Integración (PRÓXIMO PASO)
1. Actualizar TestViewModel para usar UnifiedRecommendationEngine
2. Actualizar GiftViewModel para usar UnifiedRecommendationEngine
3. Mantener compatibilidad con sistema legacy

### Fase 3: Testing
1. Probar flujos A, B, C (personal)
2. Probar gift flows
3. Verificar recomendaciones
4. A/B testing con usuarios

### Fase 4: Deprecación
1. Marcar OlfactiveProfileHelper como deprecated
2. Marcar GiftScoringEngine como deprecated
3. Eliminar en siguiente versión mayor

---

## 📊 Archivos Creados

1. `/PerfBeta/Models/UnifiedProfile.swift` - Nuevo modelo de perfil
2. `/PerfBeta/Services/UnifiedRecommendationEngine.swift` - Motor unificado
3. `/PerfBeta/Models/Question.swift` - ACTUALIZADO con weight y metadata
4. `MIGRATION_GUIDE.md` - Esta guía

---

## 🚀 Próximos Pasos

1. **Integración en ViewModels:**
   - Adaptar TestViewModel para usar nuevo engine
   - Adaptar GiftViewModel para usar nuevo engine
   - Mantener compatibilidad con UI existente

2. **Testing Exhaustivo:**
   - Unit tests para UnifiedRecommendationEngine
   - Integration tests con Firebase
   - UI tests para flujos completos

3. **Optimizaciones:**
   - Implementar análisis de perfumes de referencia
   - Optimizar cálculo de scores
   - Añadir caching de resultados

---

**Última actualización:** 2025-01-16  
**Estado:** ✅ Fase 1 Completada - Ready for Integration
