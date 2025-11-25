/**
 * Script para migrar gift questions a la estructura unificada de profile questions
 *
 * CAMBIOS:
 * - question → text
 * - description → helperText
 * - options[].text → options[].label
 * - options[].imageUrl → options[].image_asset
 * - Agregar families: {} a opciones si no existe
 *
 * USO:
 * 1. Instalar Firebase Admin: npm install firebase-admin
 * 2. Descargar service account key de Firebase Console
 * 3. Ejecutar: node migrate_gift_questions.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Necesitas descargar esto de Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateGiftQuestions() {
  console.log('🚀 Iniciando migración de gift questions...\n');

  try {
    // Obtener todas las gift questions
    const questionsRef = db.collection('questions_es');
    const snapshot = await questionsRef
      .where(admin.firestore.FieldPath.documentId(), '>=', 'gift_')
      .where(admin.firestore.FieldPath.documentId(), '<', 'gift_\uf8ff')
      .get();

    console.log(`📦 Encontradas ${snapshot.size} gift questions\n`);

    let migratedCount = 0;
    let errorCount = 0;

    // Procesar cada documento
    for (const doc of snapshot.docs) {
      const docId = doc.id;
      const data = doc.data();

      console.log(`\n📄 Procesando: ${docId}`);

      try {
        const updates = {};
        let hasChanges = false;

        // 1. Migrar "question" → "text"
        if (data.question !== undefined) {
          updates.text = data.question;
          updates.question = admin.firestore.FieldValue.delete();
          hasChanges = true;
          console.log(`   ✓ question → text`);
        }

        // 2. Migrar "description" → "helperText"
        if (data.description !== undefined) {
          updates.helperText = data.description;
          updates.description = admin.firestore.FieldValue.delete();
          hasChanges = true;
          console.log(`   ✓ description → helperText`);
        }

        // 3. Migrar opciones
        if (data.options && Array.isArray(data.options)) {
          const migratedOptions = data.options.map((option, index) => {
            const newOption = { ...option };
            let optionChanged = false;

            // text → label
            if (option.text !== undefined) {
              newOption.label = option.text;
              delete newOption.text;
              optionChanged = true;
            }

            // imageUrl → image_asset
            if (option.imageUrl !== undefined) {
              newOption.image_asset = option.imageUrl;
              delete newOption.imageUrl;
              optionChanged = true;
            }

            // Agregar families si no existe
            if (!option.families) {
              newOption.families = {};
              optionChanged = true;
            }

            if (optionChanged) {
              console.log(`   ✓ Opción ${index + 1}: ${optionChanged ? 'migrada' : 'sin cambios'}`);
            }

            return newOption;
          });

          updates.options = migratedOptions;
          hasChanges = true;
          console.log(`   ✓ ${data.options.length} opciones procesadas`);
        }

        // 4. Actualizar updatedAt
        updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

        // Aplicar cambios
        if (hasChanges) {
          await questionsRef.doc(docId).update(updates);
          migratedCount++;
          console.log(`   ✅ Migrado exitosamente`);
        } else {
          console.log(`   ⏭️  Sin cambios necesarios`);
        }

      } catch (error) {
        errorCount++;
        console.error(`   ❌ Error en ${docId}:`, error.message);
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log(`✅ Migración completada!`);
    console.log(`   Documentos migrados: ${migratedCount}`);
    console.log(`   Errores: ${errorCount}`);
    console.log(`   Total procesados: ${snapshot.size}`);
    console.log('='.repeat(60));

  } catch (error) {
    console.error('❌ Error fatal:', error);
  } finally {
    process.exit(0);
  }
}

// Ejecutar migración
migrateGiftQuestions();
