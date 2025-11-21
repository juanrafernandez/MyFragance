/**
 * Script to upload brand data to Firebase Firestore
 * Replaces all documents in brands_es collection
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadBrands() {
  try {
    console.log('📚 Starting brand data upload to Firebase...\n');

    // Read brands data
    const brandsDataPath = path.join(__dirname, 'brands_data.json');
    const brandsData = JSON.parse(fs.readFileSync(brandsDataPath, 'utf8'));

    console.log(`✅ Loaded ${brandsData.length} brands from brands_data.json\n`);

    // Get reference to brands_es collection
    const brandsCollection = db.collection('brands_es');

    // Step 1: Delete all existing documents
    console.log('🗑️  Deleting existing brands...');
    const existingBrands = await brandsCollection.get();
    const deletePromises = existingBrands.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
    console.log(`✅ Deleted ${existingBrands.size} existing brands\n`);

    // Step 2: Upload new brands
    console.log('📤 Uploading new brands...\n');

    let successCount = 0;
    let errorCount = 0;

    for (const brand of brandsData) {
      try {
        // Use brand.key as document ID
        const docRef = brandsCollection.doc(brand.key);

        // Prepare brand document
        const brandDoc = {
          key: brand.key,
          name: brand.name,
          origin: brand.origin,
          descriptionBrand: brand.descriptionBrand,
          perfumist: brand.perfumist || [],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Upload to Firestore
        await docRef.set(brandDoc);

        successCount++;
        console.log(`✅ [${successCount}/${brandsData.length}] Uploaded: ${brand.name} (${brand.key})`);

      } catch (error) {
        errorCount++;
        console.error(`❌ Error uploading ${brand.name}:`, error.message);
      }
    }

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 UPLOAD SUMMARY');
    console.log('='.repeat(60));
    console.log(`✅ Successful uploads: ${successCount}`);
    console.log(`❌ Failed uploads: ${errorCount}`);
    console.log(`📦 Total brands: ${brandsData.length}`);
    console.log('='.repeat(60));

    if (errorCount === 0) {
      console.log('\n🎉 All brands uploaded successfully!');
    } else {
      console.log(`\n⚠️  Upload completed with ${errorCount} errors`);
    }

    process.exit(0);

  } catch (error) {
    console.error('💥 Fatal error:', error);
    process.exit(1);
  }
}

// Run the upload
uploadBrands();
