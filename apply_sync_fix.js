const fs = require('fs');
const path = require('path');

// 1. Update home_screen.dart
const homePath = path.join(__dirname, 'lib', 'screens', 'home_screen.dart');
let homeContent = fs.readFileSync(homePath, 'utf8');

const targetHome = '            const SizedBox(width: 8),\n\n            // User Profile / Switch Account';
const replacementHome = `            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              tooltip: 'تحديث فوري للبيانات من السحابة',
              onPressed: () async {
                await provider.syncWithCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث البيانات من السحابة فوراً', style: TextStyle(fontFamily: 'Cairo')),
                      duration: Duration(seconds: 1),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 4),

            // User Profile / Switch Account`;

if (homeContent.includes('// User Profile / Switch Account')) {
  homeContent = homeContent.replace(/\/\/\s*User Profile \/ Switch Account/, `IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              tooltip: 'تحديث فوري للبيانات من السحابة',
              onPressed: () async {
                await provider.syncWithCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث البيانات من السحابة فوراً', style: TextStyle(fontFamily: 'Cairo')),
                      duration: Duration(seconds: 1),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 4),

            // User Profile / Switch Account`);
  fs.writeFileSync(homePath, homeContent, 'utf8');
  console.log('home_screen.dart updated with sync button!');
}

// 2. Update app_provider.dart _persistAndSync
const providerPath = path.join(__dirname, 'lib', 'providers', 'app_provider.dart');
let provContent = fs.readFileSync(providerPath, 'utf8');

provContent = provContent.replace(
  /cloudSyncService\.pushData\([\s\S]*?\);/,
  `await cloudSyncService.pushData(
      clients: _clients,
      payments: _payments,
      expenses: _expenses,
      users: _users,
    );`
);
fs.writeFileSync(providerPath, provContent, 'utf8');
console.log('app_provider.dart updated with await pushData!');
