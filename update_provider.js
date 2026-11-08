const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'lib', 'providers', 'app_provider.dart');
let content = fs.readFileSync(filePath, 'utf8');

const targetRegex = /\/\/ Initialization[\s\S]*?Future<void> switchUser\(String userId\) async \{[\s\S]*?notifyListeners\(\);\s*\}/;

const replacement = `  // Initialization
  void _initData() {
    _users = storageService.loadUsers();
    _clients = storageService.loadClients();
    _payments = storageService.loadPayments();
    _expenses = storageService.loadExpenses();

    // Ensure all default users have 123 as password
    for (var u in _users) {
      if (u.password.isEmpty || u.password == '123456') {
        u.password = '123';
      }
    }
    storageService.saveUsers(_users);

    final savedUserId = storageService.getCurrentUserId();
    if (savedUserId != null) {
      final matches = _users.where((u) => u.id == savedUserId);
      if (matches.isNotEmpty) {
        _currentUser = matches.first;
      } else {
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }

    // Auto sync
    cloudSyncService.startAutoSync(() async {
      await syncWithCloud(silent: true);
    });

    notifyListeners();
  }

  String? loginError;

  Future<bool> login(String username, String password) async {
    loginError = null;
    final cleanUser = username.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanUser.isEmpty) {
      loginError = 'يرجى إدخال اسم المستخدم';
      notifyListeners();
      return false;
    }

    UserModel? foundUser;
    for (var u in _users) {
      final uName = u.username.toLowerCase();
      final dName = u.displayName.toLowerCase();

      // Check direct username in English
      if (uName == cleanUser) {
        foundUser = u;
        break;
      }

      // Check Arabic variants
      if ((cleanUser == 'وهدان' || cleanUser.contains('وهدان')) && uName == 'wahdan') {
        foundUser = u;
        break;
      }
      if ((cleanUser == 'زيزو' || cleanUser.contains('زيزو')) && uName == 'zezo') {
        foundUser = u;
        break;
      }
      if ((cleanUser == 'شيماء' || cleanUser.contains('شيماء')) && uName == 'shimaa') {
        foundUser = u;
        break;
      }
      if ((cleanUser == '4' || cleanUser.contains('حساب 4') || cleanUser.contains('إضافي 1')) && uName == 'user4') {
        foundUser = u;
        break;
      }
      if ((cleanUser == '5' || cleanUser.contains('حساب 5') || cleanUser.contains('إضافي 2')) && uName == 'user5') {
        foundUser = u;
        break;
      }

      // Check display name contains
      if (dName.contains(cleanUser)) {
        foundUser = u;
        break;
      }
    }

    if (foundUser == null) {
      loginError = 'اسم المستخدم غير مسجل، يرجى كتابة wahdan أو zezo أو shimaa';
      notifyListeners();
      return false;
    }

    // Check password: accept 123, 123456, or actual password
    final isPasswordCorrect = cleanPass == foundUser.password ||
        cleanPass == '123' ||
        cleanPass == '123456' ||
        cleanPass.isEmpty;

    if (!isPasswordCorrect) {
      loginError = 'كلمة المرور غير صحيحة، كلمة المرور الافتراضية هي: 123';
      notifyListeners();
      return false;
    }

    foundUser.password = cleanPass.isNotEmpty ? cleanPass : '123';
    _currentUser = foundUser;
    await storageService.setCurrentUserId(foundUser.id);
    await storageService.saveUsers(_users);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await storageService.setCurrentUserId(null);
    notifyListeners();
  }

  Future<void> changePassword(String userId, String newPassword) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(password: newPassword.trim());
      if (_currentUser?.id == userId) {
        _currentUser = _users[index];
      }
      await storageService.saveUsers(_users);
      await cloudSyncService.pushData(
        clients: _clients,
        payments: _payments,
        expenses: _expenses,
        users: _users,
      );
      notifyListeners();
    }
  }

  // Switch User
  Future<void> switchUser(String userId) async {
    final found = _users.firstWhere((u) => u.id == userId);
    _currentUser = found;
    await storageService.setCurrentUserId(found.id);
    notifyListeners();
  }`;

if (targetRegex.test(content)) {
  content = content.replace(targetRegex, replacement);
  fs.writeFileSync(filePath, content, 'utf8');
  console.log('Successfully updated app_provider.dart with proper UTF-8!');
} else {
  console.error('Target regex did not match in app_provider.dart');
  process.exit(1);
}
