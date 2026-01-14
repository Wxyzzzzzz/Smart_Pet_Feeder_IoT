// Quick test to check your Firestore structure
// Run this in browser console when your app is open

// Test 1: Check if sensor_history collection exists
const db = firebase.firestore();
db.collection('feeders').doc('feeder_001').collection('sensor_history')
  .get()
  .then(snapshot => {
    console.log('sensor_history documents:', snapshot.size);
    snapshot.forEach(doc => {
      console.log('Document ID:', doc.id);
      console.log('Data:', doc.data());
    });
  });

// Test 2: Check the main feeder_001 document
db.collection('feeders').doc('feeder_001')
  .get()
  .then(doc => {
    console.log('feeder_001 document exists:', doc.exists);
    console.log('feeder_001 data:', doc.data());
  });

// Test 3: List all subcollections
db.collection('feeders').doc('feeder_001')
  .listCollections()
  .then(collections => {
    console.log('Subcollections:', collections.map(col => col.id));
  });
