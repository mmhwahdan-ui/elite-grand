const fs = require('fs');
const data = JSON.parse(fs.readFileSync('data.json', 'utf8'));

console.log('=== CAREGIVERS LIST ===');
data.caregivers.forEach((c, idx) => {
  console.log(idx + ': id=' + c.id + ', code=' + c.code + ', name=' + c.name + ', phone=' + c.phone + ', client=' + c.currentClientName + ', hasLogin=' + c.hasLoginAccount + ', loginUser=' + c.loginUsername + ', loginPass=' + c.loginPassword);
});

console.log('\n=== USERS LIST ===');
data.users.forEach((u, idx) => {
  console.log(idx + ': id=' + u.id + ', username=' + u.username + ', role=' + u.roleType + ', displayName=' + u.displayName + ', phone=' + u.phone + ', cgId=' + u.caregiverId + ', pass=' + u.password);
});
