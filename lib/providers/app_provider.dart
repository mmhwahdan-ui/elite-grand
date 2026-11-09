import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/payment_model.dart';
import '../models/expense_model.dart';
import '../models/service_day_model.dart';
import '../models/nurse_transaction_model.dart';
import '../models/partner_loan_model.dart';
import '../models/partner_settlement_model.dart';
import '../services/storage_service.dart';
import '../services/cloud_sync_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService storageService;
  late final CloudSyncService cloudSyncService;
  final Uuid _uuid = const Uuid();

  UserModel? _currentUser;
  List<UserModel> _users = [];
  List<ClientModel> _clients = [];
  List<PaymentModel> _payments = [];
  List<ExpenseModel> _expenses = [];
  List<ServiceDayModel> _serviceDays = [];
  List<NurseTransactionModel> _nurseTransactions = [];
  List<PartnerLoanModel> _partnerLoans = [];
  List<PartnerSettlementModel> _partnerSettlements = [];
  List<String> _deletedIds = [];
  Map<String, double> _openingBalances = {'bank': 0.0, 'wallet': 0.0, 'cash': 0.0};

  bool _isLoading = false;
  String? _statusMessage;

  AppProvider({required this.storageService}) {
    cloudSyncService = CloudSyncService(
      cloudEndpoint: storageService.getCloudEndpoint(),
    );
    _initData();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => List.unmodifiable(_users);
  List<ClientModel> get clients => List.unmodifiable(_clients);
  List<PaymentModel> get payments => List.unmodifiable(_payments);
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);
  List<ServiceDayModel> get serviceDays => List.unmodifiable(_serviceDays);
  List<NurseTransactionModel> get nurseTransactions => List.unmodifiable(_nurseTransactions);
  List<PartnerLoanModel> get partnerLoans => List.unmodifiable(_partnerLoans);
  List<PartnerSettlementModel> get partnerSettlements => List.unmodifiable(_partnerSettlements);
  List<String> get deletedIds => List.unmodifiable(_deletedIds);
  Map<String, double> get openingBalances => Map.unmodifiable(_openingBalances);
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;
  SyncStatus get syncStatus => cloudSyncService.status;
  DateTime? get lastSyncTime => cloudSyncService.lastSyncTime;

  // Opening Balances Getters
  double get bankOpeningBalance => _openingBalances['bank'] ?? 0.0;
  double get walletOpeningBalance => _openingBalances['wallet'] ?? 0.0;
  double get cashOpeningBalance => _openingBalances['cash'] ?? 0.0;

  // Channel Collections (الوارد والتحصيلات حسب القناة)
  double get bankCollections =>
      _payments.where((p) => p.paymentChannel == 'bank').fold(0.0, (s, p) => s + p.amount);

  double get walletCollections =>
      _payments.where((p) => p.paymentChannel == 'wallet').fold(0.0, (s, p) => s + p.amount);

  double get cashCollections =>
      _payments.where((p) => p.paymentChannel == 'cash').fold(0.0, (s, p) => s + p.amount);

  // Channel Expenses (المنصرف والمصروفات حسب القناة)
  double get bankExpenses =>
      _expenses.where((e) => e.paymentChannel == 'bank').fold(0.0, (s, e) => s + e.amount);

  double get walletExpenses =>
      _expenses.where((e) => e.paymentChannel == 'wallet').fold(0.0, (s, e) => s + e.amount);

  double get cashExpenses =>
      _expenses.where((e) => e.paymentChannel == 'cash').fold(0.0, (s, e) => s + e.amount);

  // Current Running Channel Balances (الأرصدة الحالية الفعلية)
  double get currentBankBalance => bankOpeningBalance + bankCollections - bankExpenses;
  double get currentWalletBalance => walletOpeningBalance + walletCollections - walletExpenses;
  double get currentCashBalance => cashOpeningBalance + cashCollections - cashExpenses;

  // Total Available Treasury Balance (إجمالي السيولة المتاحة)
  double get totalTreasuryBalance => currentBankBalance + currentWalletBalance + currentCashBalance;

  // Role checks for convenience
  bool get isManager => _currentUser?.roleType == 'manager' || _currentUser?.username == 'wahdan';
  bool get isAccountant => _currentUser?.roleType == 'accountant' || _currentUser?.username == 'zezo';
  bool get isFollowup => _currentUser?.roleType == 'followup' || _currentUser?.username == 'shimaa';

  // Permission checks
  bool get canAddClient => isManager || (_currentUser?.permissions.canAddClient ?? false);
  bool get canEditClient => isManager || (_currentUser?.permissions.canEditClient ?? false);
  bool get canSetPrice => isManager || (_currentUser?.permissions.canSetPrice ?? false);
  bool get canStartService => isManager || (_currentUser?.permissions.canStartService ?? false);
  bool get canEndService => isManager || (_currentUser?.permissions.canEndService ?? false);
  bool get canRecordPayment => isManager || (_currentUser?.permissions.canRecordPayment ?? false);
  bool get canRecordExpense => isManager || (_currentUser?.permissions.canRecordExpense ?? false);
  bool get canViewFinancialReports => isManager || (_currentUser?.permissions.canViewFinancialReports ?? false);
  bool get canManagePermissions => isManager || (_currentUser?.permissions.canManagePermissions ?? false);
  bool get canEditAnyData => isManager || (_currentUser?.permissions.canEditAnyData ?? false);

  // Filtered Client Lists
  List<ClientModel> get activeClients =>
      _clients.where((c) => c.status == 'active').toList();

  List<ClientModel> get pendingPricingClients =>
      _clients.where((c) => c.status == 'pending_pricing').toList();

  List<ClientModel> get readyToStartClients =>
      _clients.where((c) => c.status == 'ready_to_start').toList();

  List<ClientModel> get stoppedClients =>
      _clients.where((c) => c.status == 'stopped_by_accountant').toList();

  List<ClientModel> get completedClients =>
      _clients.where((c) => c.status == 'completed').toList();

  // Financial Calculations & Service Days Calculations for a single client
  double getClientTotalPaid(String clientId) {
    return _payments
        .where((p) => p.clientId == clientId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// قائمة أيام الخدمة المسجلة لحالة معينة مرتبة من الأحدث للأقدم
  List<ServiceDayModel> getClientServiceDays(String clientId) {
    final list = _serviceDays.where((d) => d.clientId == clientId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// حساب عدد أيام الخدمة الفعلية للعميل (إذا تم تسجيل أيام منفصلة نعتمدها، وإلا الحساب بالتقويم)
  int getClientServedDaysCount(ClientModel client) {
    final loggedDays = _serviceDays.where((d) => d.clientId == client.id);
    if (loggedDays.isNotEmpty) {
      return loggedDays.length;
    }
    return client.servedDays;
  }

  /// إجمالي المستحق على العميل للخدمة (إيرادات العميل الفعلية)
  double getClientAccruedCost(ClientModel client) {
    final loggedDays = _serviceDays.where((d) => d.clientId == client.id);
    if (loggedDays.isNotEmpty) {
      return loggedDays.fold(0.0, (sum, d) => sum + d.clientPrice);
    }
    return client.totalServiceCost;
  }

  /// إجمالي مستحقات التمريض لهذه الحالة
  double getClientNurseCost(ClientModel client) {
    final loggedDays = _serviceDays.where((d) => d.clientId == client.id);
    if (loggedDays.isNotEmpty) {
      return loggedDays.fold(0.0, (sum, d) => sum + d.nursePrice);
    }
    return client.totalNurseCost;
  }

  /// إجمالي ربح ومكسب الشركة من فروق الأسعار لهذه الحالة
  double getClientCompanyProfit(ClientModel client) {
    return getClientAccruedCost(client) - getClientNurseCost(client);
  }

  /// تفصيل عدد الأيام لكل ممرض عمل مع هذا العميل
  Map<String, int> getNurseDaysBreakdownForClient(String clientId) {
    final map = <String, int>{};
    final days = _serviceDays.where((d) => d.clientId == clientId);
    for (var d in days) {
      final name = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  /// تفصيل المستحقات المالية لكل ممرض عمل مع هذا العميل
  Map<String, double> getNurseCostBreakdownForClient(String clientId) {
    final map = <String, double>{};
    final days = _serviceDays.where((d) => d.clientId == clientId);
    for (var d in days) {
      final name = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      map[name] = (map[name] ?? 0) + d.nursePrice;
    }
    return map;
  }

  /// إجمالي أيام عمل كل ممرض على مستوى جميع الحالات
  Map<String, int> get allNursesDaysCount {
    final map = <String, int>{};
    for (var d in _serviceDays) {
      final name = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  /// إجمالي مستحقات كل ممرض المالية على مستوى جميع الحالات
  Map<String, double> get allNursesAccruedDues {
    final map = <String, double>{};
    for (var d in _serviceDays) {
      final name = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      map[name] = (map[name] ?? 0) + d.nursePrice;
    }
    return map;
  }

  /// قائمة جميع أيام الخدمة مجمعة حسب الممرض
  Map<String, List<ServiceDayModel>> get allNursesServiceDays {
    final map = <String, List<ServiceDayModel>>{};
    for (var d in _serviceDays) {
      final name = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      map.putIfAbsent(name, () => []).add(d);
    }
    return map;
  }

  /// Balance with opening balance included:
  /// (Opening Balance) + (Total Paid) - (Total Accrued Cost)
  /// If Negative (< 0): Company dues from client (مستحق على العميل / مديونية)
  /// If Positive (> 0): Client credit with company (مستحق للعميل / رصيد دائن مسبق)
  /// If Zero (= 0): Settled (خالص)
  double getClientBalance(ClientModel client) {
    final paid = getClientTotalPaid(client.id);
    final cost = getClientAccruedCost(client);
    return client.openingBalance + paid - cost;
  }

  // Aggregate Company Financials
  double get totalAccruedRevenues {
    return _clients.fold(0.0, (sum, c) => sum + getClientAccruedCost(c));
  }

  /// إجمالي مستحقات التمريض لجميع الحالات
  double get totalNurseAccruedCosts {
    return _clients.fold(0.0, (sum, c) => sum + getClientNurseCost(c));
  }

  /// إجمالي أرباح ومكاسب الشركة من فروق الأسعار بين اتفاق العميل واتفاق الممرض
  double get totalCompanyGrossProfit {
    return totalAccruedRevenues - totalNurseAccruedCosts;
  }

  double get totalPaymentsCollected {
    return _payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  double get totalExpenses {
    return _expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Net Profit based on accrued billing
  double get netAccruedProfit => totalAccruedRevenues - totalExpenses;

  /// Net Cash Flow based on actual collected payments
  double get netCashFlow => totalPaymentsCollected - totalExpenses;

  /// Sum of company debts owed by clients (where balance < 0)
  double get totalClientDebtsOwedToCompany {
    double total = 0.0;
    for (var c in _clients) {
      final bal = getClientBalance(c);
      if (bal < 0) {
        total += bal.abs();
      }
    }
    return total;
  }

  /// Sum of client advance balances (where balance > 0)
  double get totalClientAdvancesHeldByCompany {
    double total = 0.0;
    for (var c in _clients) {
      final bal = getClientBalance(c);
      if (bal > 0) {
        total += bal;
      }
    }
    return total;
  }

  // Initialization
  void _initData() {
    _users = storageService.loadUsers();
    _deletedIds = storageService.loadDeletedIds();
    _openingBalances = storageService.loadOpeningBalances();
    final deletedSet = _deletedIds.toSet();

    _clients = storageService.loadClients().where((c) => !deletedSet.contains(c.id)).toList();
    _payments = storageService.loadPayments().where((p) => !deletedSet.contains(p.id) && !deletedSet.contains(p.clientId)).toList();
    _expenses = storageService.loadExpenses().where((e) => !deletedSet.contains(e.id)).toList();
    _serviceDays = storageService.loadServiceDays().where((d) => !deletedSet.contains(d.id) && !deletedSet.contains(d.clientId)).toList();
    _nurseTransactions = storageService.loadNurseTransactions().where((t) => !deletedSet.contains(t.id)).toList();
    _partnerLoans = storageService.loadPartnerLoans().where((l) => !deletedSet.contains(l.id)).toList();
    _partnerSettlements = storageService.loadPartnerSettlements().where((s) => !deletedSet.contains(s.id)).toList();

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
        serviceDays: _serviceDays,
        users: _users,
        deletedIds: _deletedIds,
        openingBalances: _openingBalances,
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
  }

  // --- Opening Balances Management (Wahdan & Zezo) ---
  Future<void> updateOpeningBalances({
    required double bank,
    required double wallet,
    required double cash,
  }) async {
    _openingBalances = {
      'bank': bank,
      'wallet': wallet,
      'cash': cash,
    };
    await storageService.saveOpeningBalances(_openingBalances);
    await _persistAndSync();
    notifyListeners();
  }

  // --- Client Actions ---

  /// تسجيل عميل جديد أو حالي مع بيان الرصيد الافتتاحي ويومية الممرض
  Future<void> addClient({
    required String name,
    required String phone,
    required String address,
    required String healthCondition,
    String? nurseAssigned,
    String notes = '',
    bool isExistingClient = false,
    double openingBalance = 0.0,
    double dailyPrice = 0.0,
    double nurseDailyPrice = 0.0,
    String serviceType = 'hours12',
  }) async {
    final hasPricing = dailyPrice > 0;
    final newClient = ClientModel(
      id: 'cli_${_uuid.v4().substring(0, 8)}',
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim(),
      healthCondition: healthCondition.trim(),
      nurseAssigned: nurseAssigned?.trim(),
      notes: notes.trim(),
      isExistingClient: isExistingClient,
      openingBalance: openingBalance,
      dailyPrice: dailyPrice,
      nurseDailyPrice: nurseDailyPrice,
      serviceType: serviceType,
      status: hasPricing ? 'ready_to_start' : 'pending_pricing',
      createdBy: _currentUser?.username ?? 'shimaa',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _clients.insert(0, newClient);
    await _persistAndSync();
  }

  /// تعديل بيانات العميل الأساسية
  Future<void> editClient(ClientModel updated) async {
    final index = _clients.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _clients[index] = updated.copyWith(
        updatedAt: DateTime.now(),
      );
      await _persistAndSync();
    }
  }

  /// 2. زيزو (أو المدير): تحديد سعر الخدمة اليومي للعميل ويومية الممرض ونوع الوردية
  Future<void> setClientPricing({
    required String clientId,
    required double dailyPrice,
    required double nurseDailyPrice,
    required String serviceType, // 'hours12' or 'hours24'
  }) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      final current = _clients[index];
      final newStatus = current.startDate != null ? 'active' : 'ready_to_start';
      
      _clients[index] = current.copyWith(
        dailyPrice: dailyPrice,
        nurseDailyPrice: nurseDailyPrice,
        serviceType: serviceType,
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await _persistAndSync();
    }
  }

  /// 3. شيماء (أو المدير): تسجيل بدء الخدمة في التطبيق
  Future<void> startClientService({
    required String clientId,
    DateTime? startDate,
  }) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      final current = _clients[index];
      _clients[index] = current.copyWith(
        startDate: startDate ?? DateTime.now(),
        status: 'active',
        updatedAt: DateTime.now(),
      );
      await _persistAndSync();
    }
  }

  /// 4. زيزو (أو المدير): إنهاء الخدمة لتعثر العميل في السداد أو انتهاء الرعاية
  Future<void> stopClientService({
    required String clientId,
    required String reason,
    required bool isDueToPaymentDefault,
    DateTime? endDate,
  }) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      final current = _clients[index];
      _clients[index] = current.copyWith(
        endDate: endDate ?? DateTime.now(),
        status: isDueToPaymentDefault ? 'stopped_by_accountant' : 'completed',
        terminationReason: reason,
        updatedAt: DateTime.now(),
      );
      await _persistAndSync();
    }
  }

  Future<void> endClientService({
    required String clientId,
    required String reason,
    required bool isDueToPaymentDefault,
    DateTime? endDate,
  }) async {
    await stopClientService(
      clientId: clientId,
      reason: reason,
      isDueToPaymentDefault: isDueToPaymentDefault,
      endDate: endDate,
    );
  }

  /// حذف عميل نهائياً مع تتبع الحذف بسجل Tombstones
  Future<void> deleteClient(String clientId) async {
    if (!canEditAnyData) return;

    if (!_deletedIds.contains(clientId)) {
      _deletedIds.add(clientId);
    }

    final relatedPayments = _payments.where((p) => p.clientId == clientId).map((p) => p.id).toList();
    for (final pid in relatedPayments) {
      if (!_deletedIds.contains(pid)) {
        _deletedIds.add(pid);
      }
    }

    final relatedDays = _serviceDays.where((d) => d.clientId == clientId).map((d) => d.id).toList();
    for (final did in relatedDays) {
      if (!_deletedIds.contains(did)) {
        _deletedIds.add(did);
      }
    }

    _clients.removeWhere((c) => c.id == clientId);
    _payments.removeWhere((p) => p.clientId == clientId);
    _serviceDays.removeWhere((d) => d.clientId == clientId);

    await storageService.saveDeletedIds(_deletedIds);
    await _persistAndSync();
  }

  // --- Service Days Actions (أيام الخدمة والشفتات للعميل والممرض) ---

  /// تسجيل يوم خدمة فردي
  Future<void> recordServiceDay({
    required String clientId,
    required DateTime date,
    required String nurseName,
    String shiftType = 'hours12',
    required double clientPrice,
    required double nursePrice,
    String notes = '',
  }) async {
    final client = _clients.firstWhere((c) => c.id == clientId);
    final day = ServiceDayModel(
      id: 'day_${_uuid.v4().substring(0, 8)}',
      clientId: clientId,
      clientName: client.name,
      date: date,
      nurseName: nurseName.trim().isEmpty ? (client.nurseAssigned ?? 'ممرض') : nurseName.trim(),
      shiftType: shiftType,
      clientPrice: clientPrice,
      nursePrice: nursePrice,
      notes: notes.trim(),
      recordedBy: _currentUser?.username ?? 'wahdan',
      createdAt: DateTime.now(),
    );

    _serviceDays.insert(0, day);
    await _persistAndSync();
  }

  /// تسجيل حزمة أيام خدمة دفعة واحدة (مثلاً 4 أيام أو 5 أيام في الأسبوع مع ممرض معين)
  Future<void> recordBatchServiceDays({
    required String clientId,
    required List<DateTime> dates,
    required String nurseName,
    String shiftType = 'hours12',
    required double clientPrice,
    required double nursePrice,
    String notes = '',
  }) async {
    final client = _clients.firstWhere((c) => c.id == clientId);
    for (final date in dates) {
      final day = ServiceDayModel(
        id: 'day_${_uuid.v4().substring(0, 8)}',
        clientId: clientId,
        clientName: client.name,
        date: date,
        nurseName: nurseName.trim().isEmpty ? (client.nurseAssigned ?? 'ممرض') : nurseName.trim(),
        shiftType: shiftType,
        clientPrice: clientPrice,
        nursePrice: nursePrice,
        notes: notes.trim(),
        recordedBy: _currentUser?.username ?? 'wahdan',
        createdAt: DateTime.now(),
      );
      _serviceDays.insert(0, day);
    }
    await _persistAndSync();
  }

  /// حذف يوم خدمة محدد
  Future<void> deleteServiceDay(String dayId) async {
    if (!_deletedIds.contains(dayId)) {
      _deletedIds.add(dayId);
    }
    _serviceDays.removeWhere((d) => d.id == dayId);
    await storageService.saveDeletedIds(_deletedIds);
    await _persistAndSync();
  }

  // --- Payment Actions ---

  /// تسجيل دفعة نقدية أو تحويل من العميل مع تحديد مكان التحصيل (محفظة أم بنك أم كاش)
  Future<void> recordPayment({
    required String clientId,
    required double amount,
    required DateTime paymentDate,
    String paymentChannel = 'wallet', // 'wallet' (محفظة), 'bank' (بنك), 'cash' (كاش)
    String notes = '',
  }) async {
    final client = _clients.firstWhere((c) => c.id == clientId);
    final newPayment = PaymentModel(
      id: 'pay_${_uuid.v4().substring(0, 8)}',
      clientId: clientId,
      clientName: client.name,
      amount: amount,
      paymentDate: paymentDate,
      paymentChannel: paymentChannel,
      paymentMethod: paymentChannel == 'cash' ? 'cash' : 'transfer',
      notes: notes.trim(),
      receivedBy: _currentUser?.username ?? 'zezo',
      createdAt: DateTime.now(),
    );

    _payments.insert(0, newPayment);
    await _persistAndSync();
  }

  Future<void> deletePayment(String paymentId) async {
    if (!canEditAnyData) return;
    if (!_deletedIds.contains(paymentId)) {
      _deletedIds.add(paymentId);
    }
    _payments.removeWhere((p) => p.id == paymentId);
    await storageService.saveDeletedIds(_deletedIds);
    await _persistAndSync();
  }

  // --- Expense Actions ---

  /// تسجيل مصروف للشركة مع تحديد وسيلة الصرف (محفظة أم بنك أم كاش)
  Future<void> recordExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime expenseDate,
    String paymentChannel = 'cash', // 'cash', 'wallet', 'bank'
    String notes = '',
    String? relatedClientId,
  }) async {
    final newExpense = ExpenseModel(
      id: 'exp_${_uuid.v4().substring(0, 8)}',
      title: title.trim(),
      category: category,
      amount: amount,
      expenseDate: expenseDate,
      paymentChannel: paymentChannel,
      notes: notes.trim(),
      recordedBy: _currentUser?.username ?? 'zezo',
      relatedClientId: relatedClientId,
      createdAt: DateTime.now(),
    );

    _expenses.insert(0, newExpense);
    await _persistAndSync();
  }

  Future<void> deleteExpense(String expenseId) async {
    if (!canEditAnyData) return;
    if (!_deletedIds.contains(expenseId)) {
      _deletedIds.add(expenseId);
    }
    _expenses.removeWhere((e) => e.id == expenseId);
    await storageService.saveDeletedIds(_deletedIds);
    await _persistAndSync();
  }

  // --- User & Permissions Management (wahdan only) ---

  Future<void> updateUserPermissions(String userId, UserPermissions newPermissions) async {
    if (!canManagePermissions) return;
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(permissions: newPermissions);
      if (_currentUser?.id == userId) {
        _currentUser = _users[index];
      }
      await storageService.saveUsers(_users);
      await cloudSyncService.pushData(
        clients: _clients,
        payments: _payments,
        expenses: _expenses,
        serviceDays: _serviceDays,
        users: _users,
        deletedIds: _deletedIds,
        openingBalances: _openingBalances,
      );
      notifyListeners();
    }
  }

  Future<void> updateUserDetails({
    required String userId,
    required String displayName,
    required String roleTitle,
  }) async {
    if (!canManagePermissions) return;
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index].displayName = displayName.trim();
      _users[index].roleTitle = roleTitle.trim();
      if (_currentUser?.id == userId) {
        _currentUser = _users[index];
      }
      await storageService.saveUsers(_users);
      await cloudSyncService.pushData(
        clients: _clients,
        payments: _payments,
        expenses: _expenses,
        serviceDays: _serviceDays,
        users: _users,
        deletedIds: _deletedIds,
        openingBalances: _openingBalances,
      );
      notifyListeners();
    }
  }

  // --- Cloud Sync Actions ---

  Future<void> setCloudEndpoint(String endpoint) async {
    cloudSyncService.cloudEndpoint = endpoint.trim();
    await storageService.setCloudEndpoint(endpoint.trim());
    notifyListeners();
    await syncWithCloud();
  }

  Future<void> syncWithCloud({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _statusMessage = 'جاري المزامنة مع السحابة...';
      notifyListeners();
    }

    try {
      // 1. Pull remote data first
      final result = await cloudSyncService.pullData();
      if (result.success) {
        bool hasNewDeletions = false;
        if (result.deletedIds != null && result.deletedIds!.isNotEmpty) {
          for (final did in result.deletedIds!) {
            if (!_deletedIds.contains(did)) {
              _deletedIds.add(did);
              hasNewDeletions = true;
            }
          }
          if (hasNewDeletions) {
            await storageService.saveDeletedIds(_deletedIds);
          }
        }

        final deletedSet = _deletedIds.toSet();

        if (result.openingBalances != null) {
          _openingBalances = result.openingBalances!;
          await storageService.saveOpeningBalances(_openingBalances);
        }

        if (result.clients != null) {
          _clients = result.clients!.where((c) => !deletedSet.contains(c.id)).toList();
          await storageService.saveClients(_clients);
        }
        if (result.payments != null) {
          _payments = result.payments!.where((p) => !deletedSet.contains(p.id) && !deletedSet.contains(p.clientId)).toList();
          await storageService.savePayments(_payments);
        }
        if (result.expenses != null) {
          _expenses = result.expenses!.where((e) => !deletedSet.contains(e.id)).toList();
          await storageService.saveExpenses(_expenses);
        }
        if (result.serviceDays != null) {
          _serviceDays = result.serviceDays!.where((d) => !deletedSet.contains(d.id) && !deletedSet.contains(d.clientId)).toList();
          await storageService.saveServiceDays(_serviceDays);
        }
        if (result.nurseTransactions != null) {
          _nurseTransactions = result.nurseTransactions!.where((t) => !deletedSet.contains(t.id)).toList();
          await storageService.saveNurseTransactions(_nurseTransactions);
        }
        if (result.partnerLoans != null) {
          _partnerLoans = result.partnerLoans!.where((l) => !deletedSet.contains(l.id)).toList();
          await storageService.savePartnerLoans(_partnerLoans);
        }
        if (result.partnerSettlements != null) {
          _partnerSettlements = result.partnerSettlements!.where((s) => !deletedSet.contains(s.id)).toList();
          await storageService.savePartnerSettlements(_partnerSettlements);
        }
        if (result.users != null && result.users!.isNotEmpty) {
          _users = result.users!;
          await storageService.saveUsers(_users);
          if (_currentUser != null) {
            _currentUser = _users.firstWhere(
              (u) => u.id == _currentUser!.id,
              orElse: () => _currentUser!,
            );
          }
        }
        _statusMessage = 'تمت المزامنة بنجاح';
      } else {
        // If pull was empty or newly initialized endpoint, push local data up
        await cloudSyncService.pushData(
          clients: _clients,
          payments: _payments,
          expenses: _expenses,
          serviceDays: _serviceDays,
          nurseTransactions: _nurseTransactions,
          partnerLoans: _partnerLoans,
          partnerSettlements: _partnerSettlements,
          users: _users,
          deletedIds: _deletedIds,
          openingBalances: _openingBalances,
        );
        _statusMessage = result.message;
      }
    } catch (e) {
      _statusMessage = 'خطأ في المزامنة: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persistAndSync() async {
    await storageService.saveClients(_clients);
    await storageService.savePayments(_payments);
    await storageService.saveExpenses(_expenses);
    await storageService.saveServiceDays(_serviceDays);
    await storageService.saveNurseTransactions(_nurseTransactions);
    await storageService.savePartnerLoans(_partnerLoans);
    await storageService.savePartnerSettlements(_partnerSettlements);
    await storageService.saveOpeningBalances(_openingBalances);
    notifyListeners();

    // Push changes asynchronously
    cloudSyncService.pushData(
      clients: _clients,
      payments: _payments,
      expenses: _expenses,
      serviceDays: _serviceDays,
      nurseTransactions: _nurseTransactions,
      partnerLoans: _partnerLoans,
      partnerSettlements: _partnerSettlements,
      users: _users,
      deletedIds: _deletedIds,
      openingBalances: _openingBalances,
    );
  }

  // ==========================================
  // --- Nurse Accounts & Advances (حسابات وسلف التمريض) ---
  // ==========================================

  /// قائمة بأسماء كافة الممرضين والممرضات المسجلين في النظام
  List<String> get allNurseNames {
    final set = <String>{};
    for (var d in _serviceDays) {
      final n = d.nurseName.trim();
      if (n.isNotEmpty && n != 'ممرض غير محدد') set.add(n);
    }
    for (var c in _clients) {
      final n = (c.nurseAssigned ?? '').trim();
      if (n.isNotEmpty && n != 'غير محدد') set.add(n);
    }
    for (var t in _nurseTransactions) {
      final n = t.nurseName.trim();
      if (n.isNotEmpty) set.add(n);
    }
    final list = set.toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// كشف ورديات ممرض معين مرتبة من الأحدث للأقدم
  List<ServiceDayModel> getNurseShifts(String nurseName) {
    final list = _serviceDays.where((d) => d.nurseName.trim() == nurseName.trim()).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// عدد أيام العمل المنفذة لهذا الممرض
  int getNurseDaysCount(String nurseName) {
    return _serviceDays.where((d) => d.nurseName.trim() == nurseName.trim()).length;
  }

  /// إجمالي مستحقات الممرض من واقع أسعار الأيام والورديات
  double getNurseTotalEarned(String nurseName) {
    return _serviceDays
        .where((d) => d.nurseName.trim() == nurseName.trim())
        .fold(0.0, (sum, d) => sum + d.nursePrice);
  }

  /// كشف المعاملات المالية والسلف والمدفوعات الخاصة بالممرض
  List<NurseTransactionModel> getNurseTransactions(String nurseName) {
    final list = _nurseTransactions.where((t) => t.nurseName.trim() == nurseName.trim()).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// إجمالي السلف التي أخذها الممرض
  double getNurseTotalAdvances(String nurseName) {
    return _nurseTransactions
        .where((t) => t.nurseName.trim() == nurseName.trim() && t.type == 'advance')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// إجمالي صرف المستحقات / الأجور التي استلمها الممرض
  double getNurseTotalPayouts(String nurseName) {
    return _nurseTransactions
        .where((t) => t.nurseName.trim() == nurseName.trim() && t.type == 'payout')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// إجمالي ما استلمه الممرض (سلف + مستحقات منصرفة)
  double getNurseTotalReceived(String nurseName) {
    return getNurseTotalAdvances(nurseName) + getNurseTotalPayouts(nurseName);
  }

  /// باقي المستحق للممرض (المتبقي له طرف الشركة)
  /// إذا كان موجباً: مستحق للممرض طرف الشركة.
  /// إذا كان سالباً: الممرض أخذ سلف أكثر من مستحقاته وعليه للشركة!
  double getNurseRemainingBalance(String nurseName) {
    return getNurseTotalEarned(nurseName) - getNurseTotalReceived(nurseName);
  }

  /// تسجيل سلفة أو دفعة مستحقات للممرض
  Future<void> recordNurseTransaction({
    required String nurseName,
    required double amount,
    required DateTime date,
    required String type, // 'advance' (سلفة) | 'payout' (صرف مستحقات)
    String paymentChannel = 'cash',
    String notes = '',
  }) async {
    final transId = 'ntr_${_uuid.v4().substring(0, 8)}';
    final newTrans = NurseTransactionModel(
      id: transId,
      nurseName: nurseName.trim(),
      amount: amount,
      date: date,
      type: type,
      paymentChannel: paymentChannel,
      notes: notes.trim(),
      recordedBy: _currentUser?.username ?? 'wahdan',
      createdAt: DateTime.now(),
    );

    _nurseTransactions.insert(0, newTrans);

    // Record as company expense to maintain accurate treasury cash flow
    final expenseTitle = type == 'advance'
        ? 'سلفة تمريض: ${nurseName.trim()}'
        : 'صرف مستحقات تمريض: ${nurseName.trim()}';

    final newExpense = ExpenseModel(
      id: 'exp_${transId.substring(4)}',
      title: expenseTitle,
      category: type == 'advance' ? 'nurse_advance' : 'nurse_dues',
      amount: amount,
      expenseDate: date,
      paymentChannel: paymentChannel,
      notes: notes.trim(),
      recordedBy: _currentUser?.username ?? 'wahdan',
      createdAt: DateTime.now(),
    );

    _expenses.insert(0, newExpense);
    await _persistAndSync();
  }

  Future<void> deleteNurseTransaction(String id) async {
    if (!canEditAnyData) return;
    if (!_deletedIds.contains(id)) {
      _deletedIds.add(id);
    }
    final expId = 'exp_${id.substring(4)}';
    if (!_deletedIds.contains(expId)) {
      _deletedIds.add(expId);
    }
    _nurseTransactions.removeWhere((t) => t.id == id);
    _expenses.removeWhere((e) => e.id == expId);
    await storageService.saveDeletedIds(_deletedIds);
    await _persistAndSync();
  }

  // ==========================================
  // --- Partner Profit Settlements & Loans (تصفية أرباح الشركاء وسلف الشركاء) ---
  // ==========================================

  /// الشركاء ونسبهم الرسمية المتفق عليها
  static const List<Map<String, dynamic>> partnerConfigs = [
    {
      'username': 'wahdan',
      'displayName': 'أ/ وهدان (المدير العام)',
      'percentage': 0.40,
    },
    {
      'username': 'shimaa',
      'displayName': 'أ/ شيماء (المتابعة والتشغيل)',
      'percentage': 0.40,
    },
    {
      'username': 'zezo',
      'displayName': 'أ/ زيزو (الحسابات والمالية)',
      'percentage': 0.20,
    },
  ];

  /// إجمالي سلف شريك محدد المتبقية
  double getPartnerActiveLoansTotal(String username) {
    return _partnerLoans
        .where((l) => l.partnerUsername == username && !l.isFullyPaid)
        .fold(0.0, (sum, l) => sum + l.remainingAmount);
  }

  /// قائمة سلف شريك محدد مرتبة من الأحدث للأقدم
  List<PartnerLoanModel> getPartnerLoansList(String username) {
    final list = _partnerLoans.where((l) => l.partnerUsername == username).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// القسط الشهري المستحق استقطاعه من أرباح الشريك في التصفية الحالية
  double getPartnerMonthlyLoanDeduction(String username) {
    double totalDeduction = 0.0;
    final activeLoans = _partnerLoans.where((l) => l.partnerUsername == username && !l.isFullyPaid);
    for (var loan in activeLoans) {
      if (loan.repaymentType == 'single') {
        totalDeduction += loan.remainingAmount;
      } else {
        totalDeduction += loan.monthlyDeduction.clamp(0.0, loan.remainingAmount);
      }
    }
    return totalDeduction;
  }

  /// تسجيل سلفة جديدة لأحد الشركاء
  Future<void> recordPartnerLoan({
    required String partnerUsername,
    required String partnerName,
    required double totalAmount,
    required DateTime date,
    String repaymentType = 'single', // 'single' or 'installments'
    int installmentMonths = 1,
    String paymentChannel = 'cash',
    String notes = '',
  }) async {
    final loanId = 'loan_${_uuid.v4().substring(0, 8)}';
    final months = repaymentType == 'single' ? 1 : (installmentMonths > 0 ? installmentMonths : 1);
    final monthlyDeduction = totalAmount / months;

    final newLoan = PartnerLoanModel(
      id: loanId,
      partnerUsername: partnerUsername,
      partnerName: partnerName,
      totalAmount: totalAmount,
      date: date,
      repaymentType: repaymentType,
      installmentMonths: months,
      monthlyDeduction: monthlyDeduction,
      paidAmount: 0.0,
      paymentChannel: paymentChannel,
      notes: notes.trim(),
      recordedBy: _currentUser?.username ?? 'wahdan',
      createdAt: DateTime.now(),
    );

    _partnerLoans.insert(0, newLoan);

    // Outflow from treasury
    final newExpense = ExpenseModel(
      id: 'exp_${loanId.substring(5)}',
      title: 'سلفة شريك: $partnerName',
      category: 'partner_loan',
      amount: totalAmount,
      expenseDate: date,
      paymentChannel: paymentChannel,
      notes: notes.trim(),
      recordedBy: _currentUser?.username ?? 'wahdan',
      createdAt: DateTime.now(),
    );

    _expenses.insert(0, newExpense);
    await _persistAndSync();
  }

  /// حذف سلفة شريك
  Future<void> deletePartnerLoan(String loanId) async {
    if (!canEditAnyData) return;
    if (!_deletedIds.contains(loanId)) {
      _deletedIds.add(loanId);
    }
    final expId = 'exp_${loanId.substring(5)}';
    if (!_deletedIds.contains(expId)) {
      _deletedIds.add(expId);
    }
    _partnerLoans.removeWhere((l) => l.id == loanId);
    _expenses.removeWhere((e) => e.id == expId);
    await storageService.saveDeletedIds(_deletedIds);
    await _persistAndSync();
  }

  /// حساب أرباح دورة 23 الشهرية وقواعد التوزيع
  Map<String, dynamic> calculateCycle23Settlement({
    required DateTime settlementDate,
    double? customNetProfit,
  }) {
    // Start date is 23rd of previous month
    final previousMonth = settlementDate.month == 1 ? 12 : settlementDate.month - 1;
    final previousYear = settlementDate.month == 1 ? settlementDate.year - 1 : settlementDate.year;
    final startDate = DateTime(previousYear, previousMonth, 23);
    final endDate = DateTime(settlementDate.year, settlementDate.month, 22, 23, 59, 59);

    double profit;
    if (customNetProfit != null) {
      profit = customNetProfit;
    } else {
      // Calculate profit from service days during period
      final periodDays = _serviceDays.where((d) =>
          d.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          d.date.isBefore(endDate.add(const Duration(seconds: 1))));

      double grossProfit = periodDays.fold(0.0, (s, d) => s + d.companyDayProfit);

      // Period expenses (excluding partner payouts/loans to avoid recursion)
      final periodExpenses = _expenses.where((e) =>
          e.category != 'partner_loan' &&
          e.category != 'partner_settlement' &&
          e.expenseDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          e.expenseDate.isBefore(endDate.add(const Duration(seconds: 1))));

      double totalExpenses = periodExpenses.fold(0.0, (s, e) => s + e.amount);

      profit = (grossProfit - totalExpenses);
      if (profit <= 0) {
        // Fallback to overall net accrued profit if period days not separately logged
        profit = netAccruedProfit > 0 ? netAccruedProfit : 0.0;
      }
    }

    // 1. Base percentages: Wahdan 40%, Shimaa 40%, Zezo 20%
    final wahdanBase = profit * 0.40;
    final shimaaBase = profit * 0.40;
    final zezoBase = profit * 0.20;

    // 2. Minimum guarantee for Shimaa: 6,000 EGP
    // إذا كان أرباح shimaa أقل من 6000 جنيه تحصل على 6000 جنيه
    // ويخصم الفرق مصاريف إدارية من أرباح باقي الشركاء كلاً حسب نسبته
    // (نسبة وهدان 40% ونسبة زيزو 20%، أي نسبة 2 إلى 1: وهدان يتحمل ثلثي الفرق وزيزو يتحمل الثلث)
    double shimaaSubsidy = 0.0;
    double wahdanAdminDeduction = 0.0;
    double zezoAdminDeduction = 0.0;
    double shimaaFinal = shimaaBase;
    double wahdanFinal = wahdanBase;
    double zezoFinal = zezoBase;

    if (profit > 0 && shimaaBase < 6000.0) {
      shimaaSubsidy = 6000.0 - shimaaBase;
      shimaaFinal = 6000.0;
      // Deducted from Wahdan (40/60) and Zezo (20/60)
      wahdanAdminDeduction = shimaaSubsidy * (40.0 / 60.0);
      zezoAdminDeduction = shimaaSubsidy * (20.0 / 60.0);
      wahdanFinal = (wahdanBase - wahdanAdminDeduction).clamp(0.0, double.infinity);
      zezoFinal = (zezoBase - zezoAdminDeduction).clamp(0.0, double.infinity);
    }

    // 3. Partner Loans deduction
    final wahdanLoan = getPartnerMonthlyLoanDeduction('wahdan').clamp(0.0, wahdanFinal);
    final shimaaLoan = getPartnerMonthlyLoanDeduction('shimaa').clamp(0.0, shimaaFinal);
    final zezoLoan = getPartnerMonthlyLoanDeduction('zezo').clamp(0.0, zezoFinal);

    final wahdanNet = (wahdanFinal - wahdanLoan).clamp(0.0, double.infinity);
    final shimaaNet = (shimaaFinal - shimaaLoan).clamp(0.0, double.infinity);
    final zezoNet = (zezoFinal - zezoLoan).clamp(0.0, double.infinity);

    final totalDisbursed = wahdanNet + shimaaNet + zezoNet;
    final treasuryBefore = totalTreasuryBalance;
    final remainingTreasury = treasuryBefore - totalDisbursed;

    return {
      'startDate': startDate,
      'endDate': endDate,
      'profit': profit,
      'wahdanBase': wahdanBase,
      'wahdanAdminDeduction': wahdanAdminDeduction,
      'wahdanFinal': wahdanFinal,
      'wahdanLoan': wahdanLoan,
      'wahdanNet': wahdanNet,
      'shimaaBase': shimaaBase,
      'shimaaSubsidy': shimaaSubsidy,
      'shimaaFinal': shimaaFinal,
      'shimaaLoan': shimaaLoan,
      'shimaaNet': shimaaNet,
      'zezoBase': zezoBase,
      'zezoAdminDeduction': zezoAdminDeduction,
      'zezoFinal': zezoFinal,
      'zezoLoan': zezoLoan,
      'zezoNet': zezoNet,
      'totalDisbursed': totalDisbursed,
      'treasuryBefore': treasuryBefore,
      'remainingTreasury': remainingTreasury,
    };
  }

  /// تنفيذ وصرف تصفية أرباح دورة 23 وتحديث الخزينة وسداد أقساط السلف
  Future<void> executePartnerSettlement({
    required DateTime settlementDate,
    required double customNetProfit,
    String paymentChannel = 'cash',
    String notes = '',
  }) async {
    final calc = calculateCycle23Settlement(
      settlementDate: settlementDate,
      customNetProfit: customNetProfit,
    );

    final settlementId = 'settle_${_uuid.v4().substring(0, 8)}';
    final cycleTitle = 'تصفية دورة 23 ${_getMonthName(settlementDate.month)} ${settlementDate.year}';

    final settlement = PartnerSettlementModel(
      id: settlementId,
      cycleTitle: cycleTitle,
      settlementDate: settlementDate,
      startDate: calc['startDate'] as DateTime,
      endDate: calc['endDate'] as DateTime,
      companyNetProfit: calc['profit'] as double,
      wahdanBaseProfit: calc['wahdanBase'] as double,
      wahdanAdminDeduction: calc['wahdanAdminDeduction'] as double,
      wahdanLoanDeduction: calc['wahdanLoan'] as double,
      wahdanNetPayout: calc['wahdanNet'] as double,
      shimaaBaseProfit: calc['shimaaBase'] as double,
      shimaaAdminSubsidy: calc['shimaaSubsidy'] as double,
      shimaaLoanDeduction: calc['shimaaLoan'] as double,
      shimaaNetPayout: calc['shimaaNet'] as double,
      zezoBaseProfit: calc['zezoBase'] as double,
      zezoAdminDeduction: calc['zezoAdminDeduction'] as double,
      zezoLoanDeduction: calc['zezoLoan'] as double,
      zezoNetPayout: calc['zezoNet'] as double,
      totalDisbursed: calc['totalDisbursed'] as double,
      treasuryBeforePayout: calc['treasuryBefore'] as double,
      remainingTreasuryCash: calc['remainingTreasury'] as double,
      isDisbursed: true,
      notes: notes.trim(),
      recordedBy: _currentUser?.username ?? 'wahdan',
      createdAt: DateTime.now(),
    );

    _partnerSettlements.insert(0, settlement);

    // Apply loan repayments to active loans
    _applyLoanRepayment('wahdan', calc['wahdanLoan'] as double);
    _applyLoanRepayment('shimaa', calc['shimaaLoan'] as double);
    _applyLoanRepayment('zezo', calc['zezoLoan'] as double);

    // Record expense for disbursed profits
    if (settlement.totalDisbursed > 0) {
      final newExpense = ExpenseModel(
        id: 'exp_${settlementId.substring(7)}',
        title: 'صرف أرباح الشركاء ($cycleTitle)',
        category: 'partner_settlement',
        amount: settlement.totalDisbursed,
        expenseDate: settlementDate,
        paymentChannel: paymentChannel,
        notes: 'وهدان: ${settlement.wahdanNetPayout.toStringAsFixed(0)} ج.م | شيماء: ${settlement.shimaaNetPayout.toStringAsFixed(0)} ج.م | زيزو: ${settlement.zezoNetPayout.toStringAsFixed(0)} ج.م',
        recordedBy: _currentUser?.username ?? 'wahdan',
        createdAt: DateTime.now(),
      );
      _expenses.insert(0, newExpense);
    }

    await _persistAndSync();
  }

  void _applyLoanRepayment(String username, double amountToDeduct) {
    if (amountToDeduct <= 0) return;
    double remainingToDeduct = amountToDeduct;
    for (int i = 0; i < _partnerLoans.length; i++) {
      if (_partnerLoans[i].partnerUsername == username && !_partnerLoans[i].isFullyPaid) {
        final currentLoan = _partnerLoans[i];
        final canDeduct = currentLoan.remainingAmount;
        final deduction = remainingToDeduct > canDeduct ? canDeduct : remainingToDeduct;
        _partnerLoans[i] = currentLoan.copyWith(
          paidAmount: currentLoan.paidAmount + deduction,
        );
        remainingToDeduct -= deduction;
        if (remainingToDeduct <= 0) break;
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
