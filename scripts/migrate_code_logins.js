const fs = require('fs');

const raw = fs.readFileSync('data.json', 'utf8');
const data = JSON.parse(raw);

// Backup
fs.writeFileSync('data_backup_before_code_login.json', raw, 'utf8');

console.log('--- STARTING DATABASE MIGRATION ---');

// Caregiver mapping and cleanup
// 1. Identify canonical caregivers:
// CG-001: شيماء حسن الحاكم (cg_1794991670881)
// CG-002: زينب محمد عبد الحميد احمد خير الله (cg_1795011214381) - Client: احمد وصفي
// CG-003: هايدي عبد الهادي محمد بكري (cg_1795020786803)
// CG-004: محمود احمد عبد القادر شمس الدين (cg_1795353804644) - Client: كريم الحسيني
// CG-005: رشا سيد سيد محمد (cg_1795029639463)
// CG-006: امال علي فتحي (cg_1795030078696)
// CG-007: اميره محمد موسى السنوسي (cg_amira_haifa) - Client: هيفاء, openingBalance: 5350
// CG-008: فاطمه الزهراء علي علي علي محمد (cg_1795354115693)
// CG-009: سحر حمدي ابراهيم اسماعيل (cg_1795354569582) - Client: منال, openingBalance: 700
// CG-010: صابرين شعبان علي محمد (cg_1795355314367) - Client: ياسر اسماعيل, openingBalance: 3500
// CG-011: شيماء ايمن محمد سعيد الامير (cg_1795021381593) - Client: ابتسام, openingBalance: 1535
// CG-012: مديحه محمد داود رفاعي (cg_1795356509845) - Client: اميره
// CG-013: مني (cg_1795031375004) - Phone: 01096551478
// CG-014: سميه جمال عبد الحليم سعد ابراهيم (cg_1795350613716) - Client: ناديه, openingBalance: 800, password: 506472
// CG-015: نهى احمد شوقي محمود مرسي (cg_1795359157114) - Client: عمرو

// Remove redundant duplicates:
const idsToRemove = [
  'cg_1795349076610', // محمود placeholder
  'cg_1795349162271', // صابرين placeholder
  'cg_1795349228075', // سحر placeholder
  'cg_1795349281347', // شيماء 1 placeholder
  'cg_1795349422716', // هدى placeholder
  'cg_1795349580302', // نهى placeholder
  'cg_1795356164762', // duplicate Amira
  'cg_1795356214379', // duplicate Amira
  'cg_1795358610668'  // duplicate Somaya (merged into cg_1795350613716)
];

data.caregivers = data.caregivers.filter(c => !idsToRemove.includes(c.id));

// Define the canonical caregivers map:
const canonicalMap = {
  'cg_1794991670881': { code: 'CG-001', name: 'شيماء حسن الحاكم', phone: '01033408925', pass: '123456' },
  'cg_1795011214381': { code: 'CG-002', name: 'زينب محمد عبد الحميد احمد خير الله', phone: '01014703959', client: 'احمد وصفي', pass: '123456' },
  'cg_1795020786803': { code: 'CG-003', name: 'هايدي عبد الهادي محمد بكري', phone: '01019399875', pass: '123456' },
  'cg_1795353804644': { code: 'CG-004', name: 'محمود احمد عبد القادر شمس الدين', phone: '01008747542', client: 'كريم الحسيني', pass: '123456' },
  'cg_1795029639463': { code: 'CG-005', name: 'رشا سيد سيد محمد', phone: '01007794327', pass: '123456' },
  'cg_1795030078696': { code: 'CG-006', name: 'امال علي فتحي', phone: '01040103657', pass: '123456' },
  'cg_amira_haifa':   { code: 'CG-007', name: 'اميره محمد موسى السنوسي', phone: '01102539520', client: 'هيفاء', openingBalance: 5350, pass: '123456' },
  'cg_1795354115693': { code: 'CG-008', name: 'فاطمه الزهراء علي علي علي محمد', phone: '01029894341', pass: '123456' },
  'cg_1795354569582': { code: 'CG-009', name: 'سحر حمدي ابراهيم اسماعيل', phone: '01556423624', client: 'منال', openingBalance: 700, pass: '123456' },
  'cg_1795355314367': { code: 'CG-010', name: 'صابرين شعبان علي محمد', phone: '01127128968', client: 'ياسر اسماعيل', openingBalance: 3500, pass: '123456' },
  'cg_1795021381593': { code: 'CG-011', name: 'شيماء ايمن محمد سعيد الامير', phone: '01068561497', client: 'ابتسام', openingBalance: 1535, pass: '654321' },
  'cg_1795356509845': { code: 'CG-012', name: 'مديحه محمد داود رفاعي', phone: '01154466528', client: 'اميره', pass: '123456' },
  'cg_1795350613716': { code: 'CG-014', name: 'سميه جمال عبد الحليم سعد ابراهيم', phone: '01044142641', client: 'ناديه', openingBalance: 800, pass: '506472' },
  'cg_1795359157114': { code: 'CG-015', name: 'نهى احمد شوقي محمود مرسي', phone: '01117116203', client: 'عمرو', pass: '123456' },
};

// Update Caregivers
for (const cg of data.caregivers) {
  const cInfo = canonicalMap[cg.id];
  if (cInfo) {
    cg.code = cInfo.code;
    cg.name = cInfo.name;
    cg.phone = cInfo.phone;
    if (cInfo.client !== undefined) cg.currentClientName = cInfo.client;
    if (cInfo.openingBalance !== undefined) cg.openingBalance = cInfo.openingBalance;
    cg.hasLoginAccount = true;
    cg.loginUsername = cInfo.code;
    cg.loginPassword = cInfo.pass;
    cg.isCurrentlyWorking = Boolean(cg.currentClientName);
  }
}

// Make sure Mona exists as CG-013 if needed
let monaCg = data.caregivers.find(c => c.name.includes('مني') || c.id === 'cg_1795031375004');
if (!monaCg) {
  data.caregivers.push({
    id: 'cg_1795031375004',
    code: 'CG-013',
    name: 'مني',
    phone: '01096551478',
    qualification: 'تمريض منزلي',
    residenceArea: 'القاهرة',
    rating: 5,
    dailyPrice: 400,
    shiftPreference: 'both',
    isBlocked: false,
    hasWorkedWithUs: false,
    hasLoginAccount: true,
    isCurrentlyWorking: false,
    currentClientName: null,
    openingBalance: 0,
    loginUsername: 'CG-013',
    loginPassword: '123456',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    createdBy: 'wahdan'
  });
} else {
  monaCg.code = 'CG-013';
  monaCg.hasLoginAccount = true;
  monaCg.loginUsername = 'CG-013';
  monaCg.loginPassword = '123456';
}

// Update Clients to point to exact canonical nurse names:
for (const cl of data.clients) {
  if (cl.name.includes('ناديه')) {
    cl.nurseAssigned = 'سميه جمال عبد الحليم سعد ابراهيم';
  } else if (cl.name.includes('هيفاء')) {
    cl.nurseAssigned = 'اميره محمد موسى السنوسي';
  } else if (cl.name.includes('كريم الحسيني')) {
    cl.nurseAssigned = 'محمود احمد عبد القادر شمس الدين';
  } else if (cl.name.includes('ياسر اسماعيل')) {
    cl.nurseAssigned = 'صابرين شعبان علي محمد';
  } else if (cl.name.includes('منال')) {
    cl.nurseAssigned = 'سحر حمدي ابراهيم اسماعيل';
  } else if (cl.name.includes('ابتسام')) {
    cl.nurseAssigned = 'شيماء ايمن محمد سعيد الامير';
  } else if (cl.name.includes('اميره')) {
    cl.nurseAssigned = 'مديحه محمد داود رفاعي';
  } else if (cl.name.includes('عمرو')) {
    cl.nurseAssigned = 'نهى احمد شوقي محمود مرسي';
  } else if (cl.name.includes('احمد وصفي')) {
    cl.nurseAssigned = 'زينب محمد عبد الحميد احمد خير الله';
  }
}

// Update Users:
// Keep admin users untouched:
const adminUsers = data.users.filter(u => u.roleType !== 'nurse');

// Rebuild nurse users cleanly from canonical caregivers:
const nurseUsers = [];
for (const cg of data.caregivers) {
  nurseUsers.push({
    id: 'usr_cg_' + cg.id,
    username: cg.code, // EXACT CODE (CG-001, CG-014, etc.)
    password: cg.loginPassword || '123456',
    displayName: cg.name,
    phone: cg.phone,
    roleTitle: 'طاقم تمريض / مقدم خدمة',
    roleType: 'nurse',
    caregiverId: cg.id,
    permissions: {
      canAddClient: false,
      canEditClient: false,
      canStartService: false,
      canEndService: false,
      canSetPrice: false,
      canRecordPayment: false,
      canRecordExpense: false,
      canViewFinancialReports: false,
      canManagePermissions: false,
      canEditAnyData: false
    }
  });
}

data.users = [...adminUsers, ...nurseUsers];

fs.writeFileSync('data.json', JSON.stringify(data, null, 2), 'utf8');

console.log('--- MIGRATION COMPLETED SUCCESSFULLY ---');
console.log('Caregivers count:', data.caregivers.length);
console.log('Users count:', data.users.length);

console.log('\n--- VERIFYING NURSE USERS ---');
nurseUsers.forEach(u => {
  console.log(`User: ${u.username.padEnd(8)} | Pass: ${u.password.padEnd(8)} | Name: ${u.displayName} | Phone: ${u.phone}`);
});
