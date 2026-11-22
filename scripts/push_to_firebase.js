const https = require('https');
const fs = require('fs');

const FIREBASE_URL = 'https://elite-grand-8a6c3-default-rtdb.firebaseio.com/elite_grand.json';
const data = JSON.parse(fs.readFileSync('data.json', 'utf8'));

// Clean up Heidy: Heidy is NOT assigned to Nadia. Nadia is with Somaya!
const heidy = data.caregivers.find(c => c.name.includes('هايدي'));
if (heidy) {
  heidy.currentClientName = null;
  heidy.isCurrentlyWorking = false;
  console.log('Cleared Heidy currentClientName. Heidy is now free.');
}

const somaya = data.caregivers.find(c => c.name.includes('سميه'));
if (somaya) {
  somaya.currentClientName = 'ناديه';
  somaya.isCurrentlyWorking = true;
  console.log('Confirmed Somaya is with Nadia.');
}

const nadia = data.clients.find(c => c.name.includes('ناديه'));
if (nadia) {
  nadia.nurseAssigned = 'سميه جمال عبد الحليم سعد ابراهيم';
  console.log('Confirmed Nadia nurseAssigned is Somaya.');
}

// Update lastUpdated
data.lastUpdated = new Date().toISOString();

const jsonStr = JSON.stringify(data, null, 2);
fs.writeFileSync('data.json', jsonStr, 'utf8');

console.log('Pushing clean data.json to Firebase Cloud Database (24/7)...');

const req = https.request(FIREBASE_URL, {
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(jsonStr)
  }
}, res => {
  console.log('Firebase Response Status:', res.statusCode);
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    if (res.statusCode === 200) {
      console.log('SUCCESS! Firebase 24/7 Cloud Database is now 100% in sync with data.json!');
    } else {
      console.log('Failed:', body);
    }
  });
});

req.on('error', err => {
  console.error('Network error pushing to Firebase:', err.message);
});

req.write(jsonStr);
req.end();
