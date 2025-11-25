const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkAutocompleteQuestions() {
  const questionIds = ['gift_C1_brands', 'gift_D1_perfume_search'];

  for (const qid of questionIds) {
    const doc = await db.collection('questions_es').doc(qid).get();
    if (doc.exists) {
      const data = doc.data();
      console.log(`\n📄 ${qid}:`);
      console.log(`   dataSource: ${data.dataSource || '❌ FALTA'}`);
      console.log(`   questionType: ${data.questionType || '❌ FALTA'}`);
      console.log(`   minSelections: ${data.minSelections || '❌ FALTA'}`);
      console.log(`   maxSelections: ${data.maxSelections || '❌ FALTA'}`);
      console.log(`   placeholder: ${data.placeholder || '(none)'}`);
      console.log(`   options: ${data.options?.length || 0} opciones`);
    } else {
      console.log(`\n❌ ${qid} NO EXISTE`);
    }
  }

  process.exit(0);
}

checkAutocompleteQuestions();
