const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixAutocompleteQuestions() {
  console.log('🔧 Arreglando preguntas de autocomplete...\n');

  const fixes = [
    {
      id: 'gift_C1_brands',
      updates: {
        dataSource: 'brands_database',
        minSelections: 1,
        maxSelections: 3,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }
    },
    {
      id: 'gift_D1_perfume_search',
      updates: {
        dataSource: 'perfumes_database',
        minSelections: 1,
        maxSelections: 3,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }
    }
  ];

  for (const fix of fixes) {
    console.log(`📝 Actualizando ${fix.id}...`);
    await db.collection('questions_es').doc(fix.id).update(fix.updates);
    console.log(`   ✅ dataSource: ${fix.updates.dataSource}`);
    console.log(`   ✅ minSelections: ${fix.updates.minSelections}`);
    console.log(`   ✅ maxSelections: ${fix.updates.maxSelections}\n`);
  }

  console.log('✅ Autocomplete questions arregladas!');
  process.exit(0);
}

fixAutocompleteQuestions();
