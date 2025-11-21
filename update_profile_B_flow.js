#!/usr/bin/env node

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const profileBQuestions = [
  {
    id: "profile_B1_gender",
    key: "gender",
    questionType: "routing",
    order: 1,
    category: "Género",
    text: "¿Para quién es el perfume?",
    weight: 0,
    required: true,
    showDescriptions: true,
    options: [
      { id: "1", label: "Hombre", value: "male", description: "Fragancias masculinas", image_asset: "gender_male", families: {}, metadata: { gender_type: "masculine" } },
      { id: "2", label: "Mujer", value: "female", description: "Fragancias femeninas", image_asset: "gender_female", families: {}, metadata: { gender_type: "feminine" } },
      { id: "3", label: "Unisex", value: "unisex", description: "Fragancias unisex", image_asset: "gender_unisex", families: {}, metadata: { gender_type: "unisex" } },
      { id: "4", label: "Sin distinción de género", value: "any", description: "Todos los géneros", image_asset: "gender_any", families: {}, metadata: { gender_type: "all" } }
    ]
  },
  {
    id: "profile_B2_mixed_preference",
    key: "mixed_preference",
    questionType: "single_choice",
    order: 2,
    category: "Estilo de Fragancia",
    text: "¿Qué estilo de fragancia te atrae más?",
    weight: 3,
    options: [
      { id: "1", label: "Frescos y Cristalinos", value: "fresh_clean", description: "Cítricos, flores blancas, sensación de ducha", families: { citrus: 5, aquatic: 4, floral: 2 }, metadata: { must_contain_notes: ["bergamota", "almizcle", "neroli"] } },
      { id: "2", label: "Florales Románticos", value: "elegant_floral", description: "Rosas, Peonías, Jazmín", families: { floral: 6, fruity: 3, green: 2 }, metadata: { heartNotes_bonus: ["rosa", "peonia", "jazmin"] } },
      { id: "3", label: "Dulces y Envolventes", value: "sweet_gourmand", description: "Vainilla, Haba Tonka, Almendras", families: { oriental: 5, gourmand: 5 }, metadata: { baseNotes_bonus: ["vainilla", "haba_tonka", "almendra_amarga"] } },
      { id: "4", label: "Amaderados con Carácter", value: "woody_sophisticated", description: "Cedro, Vetiver, Sándalo", families: { woody: 6, spicy: 3, green: 2 }, metadata: { baseNotes_bonus: ["cedro", "vetiver", "sandalo"] } },
      { id: "5", label: "Intensos y Misteriosos", value: "intense_oriental", description: "Oud, Incienso, Cuero, Especias", families: { oriental: 6, woody: 4 }, metadata: { baseNotes_bonus: ["oud", "cuero", "incienso", "ambar"] } }
    ]
  },
  {
    id: "profile_B3_personality",
    key: "personality_intermediate",
    questionType: "single_choice",
    order: 3,
    category: "Personalidad",
    text: "¿Cómo describirías tu estilo personal?",
    weight: 1,
    options: [
      { id: "1", label: "Clásico y atemporal", value: "classic", description: "Prefiero la elegancia tradicional", image_asset: "personality_classic", families: { floral: 4, woody: 4, citrus: 2 }, metadata: { personality: ["elegant"] } },
      { id: "2", label: "Moderno y minimalista", value: "modern_minimal", description: "Me gusta lo simple y contemporáneo", image_asset: "personality_minimal", families: { aquatic: 4, woody: 3, green: 3 }, metadata: { personality: ["confident", "relaxed"] } },
      { id: "3", label: "Romántico y soñador", value: "romantic", description: "Disfruto lo poético y emotivo", image_asset: "personality_romantic", families: { floral: 5, fruity: 3, gourmand: 2 }, metadata: { personality: ["romantic", "passionate"] } },
      { id: "4", label: "Audaz y llamativo", value: "bold", description: "Me gusta destacar", image_asset: "personality_bold", families: { oriental: 5, spicy: 4, gourmand: 1 }, metadata: { personality: ["adventurous", "confident"] } },
      { id: "5", label: "Natural y relajado", value: "natural", description: "Busco la sencillez y autenticidad", image_asset: "personality_natural", families: { green: 5, citrus: 3, aquatic: 2 }, metadata: { personality: ["relaxed"] } },
      { id: "6", label: "Creativo y único", value: "creative", description: "Me gusta lo diferente y artístico", image_asset: "personality_creative", families: { spicy: 4, oriental: 3, woody: 3 }, metadata: { personality: ["creative", "mysterious"] } }
    ]
  },
  {
    id: "profile_B4_preferred_notes",
    key: "preferred_notes_search",
    questionType: "autocomplete_notes",
    order: 4,
    category: "Notas Favoritas",
    text: "¿Hay alguna nota específica que te encante?",
    helperText: "Opcional: Busca hasta 3 notas que disfrutes especialmente",
    placeholder: "Busca: vainilla, jazmín, sándalo, bergamota...",
    dataSource: "notes_database",
    maxSelections: 3,
    minSelections: 0,
    weight: 0,
    skipOption: { label: "No conozco notas específicas", value: "skip" },
    options: []
  },
  {
    id: "profile_B5_occasion",
    key: "occasion_intermediate",
    questionType: "single_choice",
    order: 5,
    category: "Ocasión",
    text: "¿Para qué ocasión buscas principalmente un perfume?",
    weight: 2,
    options: [
      { id: "1", label: "Uso Diario / Oficina", value: "daily_work", description: "Algo apropiado para la oficina", image_asset: "occasion_work", families: { citrus: 3, floral: 3, woody: 2, green: 2 }, metadata: { occasion: ["office", "daily_use"], intensity_max: "medium" } },
      { id: "2", label: "Citas románticas", value: "romantic_dates", description: "Seductor y memorable", image_asset: "occasion_date", families: { oriental: 4, gourmand: 3, floral: 3 }, metadata: { occasion: ["dates", "nights"] } },
      { id: "3", label: "Eventos sociales", value: "social_events", description: "Fiestas, cenas, reuniones", image_asset: "occasion_social", families: { woody: 3, spicy: 3, fruity: 2, floral: 2 }, metadata: { occasion: ["social_events", "parties"] } },
      { id: "4", label: "Deportes y aire libre", value: "outdoor", description: "Actividades físicas", image_asset: "occasion_outdoor", families: { aquatic: 5, citrus: 4, green: 1 }, metadata: { occasion: ["sports", "nature_walks"] } },
      { id: "5", label: "Uso versátil", value: "versatile", description: "Para cualquier momento", image_asset: "occasion_versatile", families: { woody: 3, citrus: 2, floral: 2, aquatic: 2, fruity: 1 }, metadata: { occasion: ["daily_use", "social_events"] } }
    ]
  },
  {
    id: "profile_B6_intensity_duration",
    key: "intensity_duration",
    questionType: "single_choice",
    order: 6,
    category: "Rendimiento",
    text: "¿Qué prefieres en cuanto a duración e intensidad?",
    weight: 2,
    options: [
      { id: "1", label: "Ligero pero duradero", value: "light_lasting", description: "Sutil presencia todo el día", image_asset: "performance_light_long", families: { woody: 4, green: 3, aquatic: 3 }, metadata: { intensity: "low", duration: "long", projection: "low" } },
      { id: "2", label: "Intenso aunque dure menos", value: "intense_short", description: "Impacto fuerte inicial", image_asset: "performance_intense_short", families: { citrus: 5, spicy: 3, fruity: 2 }, metadata: { intensity: "high", duration: "short", projection: "high" } },
      { id: "3", label: "Equilibrado en todo", value: "balanced", description: "Moderado en intensidad y duración", image_asset: "performance_balanced", families: { floral: 4, woody: 3, fruity: 3 }, metadata: { intensity: "medium", duration: "moderate", projection: "moderate" } },
      { id: "4", label: "Máximo rendimiento", value: "maximum", description: "Intenso Y duradero", image_asset: "performance_maximum", families: { oriental: 5, gourmand: 3, spicy: 2 }, metadata: { intensity: "very_high", duration: "very_long", projection: "explosive" } }
    ]
  },
  {
    id: "profile_B7_discovery",
    key: "discovery_openness",
    questionType: "single_choice",
    order: 7,
    category: "Exploración",
    text: "¿Qué tan aventurero eres con las fragancias?",
    weight: 1,
    options: [
      { id: "1", label: "Prefiero lo conocido y seguro", value: "safe", description: "Me quedo con marcas y estilos que conozco", image_asset: "discovery_safe", families: { floral: 3, citrus: 3, woody: 2, aquatic: 2 }, metadata: { discovery_mode: "safe" } },
      { id: "2", label: "Exploro dentro de mi zona de confort", value: "moderate", description: "Pruebo variaciones de lo que me gusta", image_asset: "discovery_moderate", families: { woody: 3, fruity: 3, gourmand: 2, spicy: 2 }, metadata: { discovery_mode: "moderate" } },
      { id: "3", label: "Me encanta descubrir cosas nuevas", value: "adventurous", description: "Busco activamente fragancias únicas", image_asset: "discovery_adventurous", families: { oriental: 4, spicy: 3, green: 3 }, metadata: { discovery_mode: "adventurous" } }
    ]
  }
];

async function updateProfileBFlow() {
  console.log('\n🔄 Actualizando Profile B Flow (7 preguntas)...\n');

  let updated = 0;
  for (const question of profileBQuestions) {
    try {
      await db.collection('questions_es').doc(question.id).set({
        ...question,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log(`✅ ${question.id} actualizada`);
      updated++;
    } catch (error) {
      console.error(`❌ Error al actualizar ${question.id}:`, error.message);
    }
  }

  console.log(`\n✨ Actualizadas ${updated}/${profileBQuestions.length} preguntas del Profile B Flow\n`);
  await admin.app().delete();
}

updateProfileBFlow().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
