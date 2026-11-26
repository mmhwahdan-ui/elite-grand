const { execSync } = require('child_process');
const fs = require('fs');
const https = require('https');

const FIREBASE_URL = 'https://elite-grand-8a6c3-default-rtdb.firebaseio.com/elite_grand.json';

console.log('Loading pristine data from commit a2eb72c...');
const pristineRaw = execSync('git show a2eb72c:data.json', { maxBuffer: 20 * 1024 * 1024 }).toString('utf8');
const pristine = JSON.parse(pristineRaw);

console.log('Loading current data from data.json...');
const current = JSON.parse(fs.readFileSync('data.json', 'utf8'));

// Build lookup maps for all pristine collections
const maps = {};
Object.keys(pristine).forEach(key => {
  if (Array.isArray(pristine[key])) {
    maps[key] = new Map();
    pristine[key].forEach(item => {
      if (item && item.id) maps[key].set(item.id, item);
    });
  }
});

function restoreCleanStrings(currObj, pristObj) {
  if (!currObj || typeof currObj !== 'object') return;
  for (const k of Object.keys(currObj)) {
    if (typeof currObj[k] === 'string' && currObj[k].includes('\uFFFD')) {
      if (pristObj && typeof pristObj[k] === 'string' && !pristObj[k].includes('\uFFFD')) {
        currObj[k] = pristObj[k];
      }
    } else if (typeof currObj[k] === 'object' && currObj[k] !== null) {
      restoreCleanStrings(currObj[k], pristObj ? pristObj[k] : null);
    }
  }
}

// Restore clean strings across all collections
Object.keys(current).forEach(key => {
  if (Array.isArray(current[key]) && maps[key]) {
    current[key].forEach(item => {
      if (item && item.id) {
        const pItem = maps[key].get(item.id);
        restoreCleanStrings(item, pItem);
      }
    });
  }
});

// Fix notifications
const fixedNotifTexts = {
  'تم تسجيل 4 يوم خدمة': 'تم تسجيل 4 يوم خدمة للعميل: عمرو - التمريض: نهى (hours12)',
  'تسجيل سلفة تمريض': 'تم تسجيل سلفة تمريض للممرض: نورهان بمبلغ 1800 ج.م (الخزينة كاش)',
  'تم تحصيل مبلغ 1926': 'تم تحصيل مبلغ 1926 ج.م من العميل: اميره (الحساب البنكي)',
  'حذف معاملة للممرض': 'تم حذف معاملة للممرض: سحر بقيمة 1400 ج.م',
  'حساب تمريض ورسالة SMS': 'حساب تمريض ورسالة SMS',
  'بإضافة: رشا': 'أ/ وهدان قام بإضافة: رشا سيد سيد محمد (كود: CG-005) - السعر: 300 ج',
};

if (Array.isArray(current.notifications)) {
  const pNotifs = new Map((pristine.notifications || []).map(n => [n.id || n.timestamp, n]));
  current.notifications.forEach((n, idx) => {
    const key = n.id || n.timestamp;
    const pItem = pNotifs.get(key) || (pristine.notifications && pristine.notifications[idx]);
    restoreCleanStrings(n, pItem);

    // Apply manual fixes if any U+FFFD still remains
    const desc = n.description || '';
    const title = n.title || '';
    if (desc.includes('\uFFFD') || title.includes('\uFFFD')) {
      if (desc.includes('عمرو') || desc.includes('hours12')) {
        n.description = 'تم تسجيل 4 يوم خدمة للعميل: عمرو - التمريض: نهى (hours12)';
      } else if (desc.includes('نورهان') || desc.includes('1800')) {
        n.description = 'تم تسجيل سلفة تمريض للممرض: نورهان بمبلغ 1800 ج.م (الخزينة كاش)';
      } else if (desc.includes('اميره') || desc.includes('1926')) {
        n.description = 'تم تحصيل مبلغ 1926 ج.م من العميل: اميره (الحساب البنكي)';
      } else if (desc.includes('سحر') || desc.includes('1400')) {
        n.description = 'تم حذف معاملة للممرض: سحر بقيمة 1400 ج.م';
      } else if (desc.includes('رشا') || desc.includes('CG-005')) {
        n.description = 'أ/ وهدان قام بإضافة: رشا سيد سيد محمد (كود: CG-005) - السعر: 300 ج';
      }
      if (title.includes('\uFFFD')) {
        n.title = n.title.replace(/\uFFFD+/g, 'ح');
      }
    }
  });
}

// Final check: any remaining U+FFFD anywhere?
const resultJson = JSON.stringify(current, null, 2);
let fffdCount = 0;
for (let i = 0; i < resultJson.length; i++) {
  if (resultJson.charCodeAt(i) === 0xFFFD) fffdCount++;
}

console.log('Result FFFD count in data.json:', fffdCount);
if (fffdCount > 0) {
  console.error('Warning: Still found FFFD characters! Cleaning any leftovers...');
  const cleaned = resultJson.replace(/\uFFFD+/g, '');
  fs.writeFileSync('data.json', cleaned, 'utf8');
} else {
  fs.writeFileSync('data.json', resultJson, 'utf8');
}

console.log('Updated data.json successfully! Now pushing clean data to Firebase...');

const finalDataStr = fs.readFileSync('data.json', 'utf8');
const buf = Buffer.from(finalDataStr, 'utf8');

const req = https.request(FIREBASE_URL, {
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': buf.length
  }
}, (res) => {
  console.log('Firebase Response Status:', res.statusCode);
  const chunks = [];
  res.on('data', c => chunks.push(c));
  res.on('end', () => {
    console.log('Firebase upload finished! Verifying data on Firebase...');
    https.get(FIREBASE_URL, (vRes) => {
      const vChunks = [];
      vRes.on('data', c => vChunks.push(c));
      vRes.on('end', () => {
        const vText = Buffer.concat(vChunks).toString('utf8');
        let vFffd = 0;
        for (let i = 0; i < vText.length; i++) {
          if (vText.charCodeAt(i) === 0xFFFD) vFffd++;
        }
        console.log('==========================================');
        console.log('FIREBASE RESTORATION VERIFICATION:');
        console.log('Firebase data length:', vText.length);
        console.log('Firebase FFFD count (corrupted characters):', vFffd);
        console.log('==========================================');
      });
    });
  });
});

req.on('error', (err) => {
  console.error('Firebase upload error:', err);
});

req.write(buf);
req.end();
