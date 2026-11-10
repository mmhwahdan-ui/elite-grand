import 'package:intl/intl.dart' hide TextDirection;
import '../models/app_notification_model.dart';
import '../models/period_financial_summary.dart';
import '../services/sound_service.dart';
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
import '../models/caregiver_model.dart';
import '../models/chat_message_model.dart';
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
  List<CaregiverModel> _caregivers = [];
  List<ChatMessageModel> _chatMessages = [];
  final Set<String> _knownChatMessageIds = {};
  int _unreadChatCount = 0;
  List<String> _deletedIds = [];
  Map<String, double> _openingBalances = {'bank': 0.0, 'wallet': 0.0, 'cash': 0.0};

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  List<AppNotificationModel> _notifications = [];
  final Set<String> _knownNotificationIds = {};
  int _unreadNotificationCount = 0;
  bool _soundAlertsEnabled = true;

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
  List<CaregiverModel> get caregivers => List.unmodifiable(_caregivers);
  List<ChatMessageModel> get chatMessages => List.unmodifiable(_chatMessages);
  int get unreadChatCount => _unreadChatCount;
  List<String> get deletedIds => List.unmodifiable(_deletedIds);
  Map<String, double> get openingBalances => Map.unmodifiable(_openingBalances);
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;
  SyncStatus get syncStatus => cloudSyncService.status;
  DateTime? get lastSyncTime => cloudSyncService.lastSyncTime;

  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationCount => _unreadNotificationCount;
  bool get soundAlertsEnabled => _soundAlertsEnabled;

  void toggleSoundAlerts(bool val) {
    _soundAlertsEnabled = val;
    notifyListeners();
  }

  void markNotificationsAsRead() {
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  void clearNotifications() async {
    _notifications.clear();
    await storageService.saveNotifications(_notifications);
    notifyListeners();
  }

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
  bool get canViewFinancialReports =>
      isManager ||
      isFollowup ||
      isAccountant ||
      _currentUser?.username == 'wahdan' ||
      _currentUser?.username == 'shimaa' ||
      _currentUser?.username == 'zezo' ||
      (_currentUser?.permissions.canViewFinancialReports ?? false);
  bool get canManagePermissions => isManager || (_currentUser?.permissions.canManagePermissions ?? false);
  bool get canEditAnyData => isManager || (_currentUser?.permissions.canEditAnyData ?? false);

  /// صلاحية ملء وتعديل قاعدة بيانات مقدمي الخدمة (حصرياً لمديرة المتابعة shimaa والمدير wahdan)
  bool get canManageCaregivers =>
      _currentUser?.username == 'wahdan' ||
      _currentUser?.username == 'shimaa' ||
      isManager ||
      isFollowup ||
      (_currentUser?.permissions.canEditAnyData ?? false);

  /// هل الحساب الحالي للاطلاع فقط على قاعدة بيانات مقدمي الخدمة (مثل أ/ زيزو)
  bool get isCaregiverViewerOnly => _currentUser?.username == 'zezo' || (!canManageCaregivers);

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

  // --- Periodic Net Profit Calculations (Daily, Weekly, Monthly Cycle 23) ---

  /// حساب ملخص مالي دقيق لأي فترة زمنية محددة
  PeriodFinancialSummary getFinancialSummaryForRange({
    required DateTime startDate,
    required DateTime endDate,
    required String periodType,
    required String periodTitle,
    int? daysRemaining,
  }) {
    final sDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final eDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    double revenues = 0.0;
    double nurseCosts = 0.0;
    int shiftsCount = 0;
    final Set<String> activeClientIds = {};

    final sDay = DateTime(sDate.year, sDate.month, sDate.day);
    final eDay = DateTime(eDate.year, eDate.month, eDate.day);
    final totalDaysInRange = eDay.difference(sDay).inDays + 1;

    // حساب الإيرادات وتكلفة التمريض يوماً بيوم خلال الفترة
    for (int i = 0; i < totalDaysInRange; i++) {
      final currentDay = sDay.add(Duration(days: i));

      // 1. فحص الورديات المسجلة فعلياً في جدول _serviceDays لهذا اليوم
      final daysLoggedForCurrentDay = _serviceDays.where((d) {
        final dDate = DateTime(d.date.year, d.date.month, d.date.day);
        return dDate.isAtSameMomentAs(currentDay);
      }).toList();

      final Set<String> clientsHandledToday = {};

      for (final loggedDay in daysLoggedForCurrentDay) {
        revenues += loggedDay.clientPrice;
        nurseCosts += loggedDay.nursePrice;
        shiftsCount++;
        activeClientIds.add(loggedDay.clientId);
        clientsHandledToday.add(loggedDay.clientId);
      }

      // 2. فحص الحالات النشطة التي لم تُسجل ورديتها يدوياً لهذا اليوم بعد واحتساب يومية تعاقدها
      for (final client in _clients) {
        if (clientsHandledToday.contains(client.id)) continue;
        if (client.startDate == null || client.dailyPrice <= 0) continue;

        final cStart = DateTime(client.startDate!.year, client.startDate!.month, client.startDate!.day);
        final DateTime cEnd;
        if (client.endDate != null) {
          cEnd = DateTime(client.endDate!.year, client.endDate!.month, client.endDate!.day);
        } else {
          final now = DateTime.now();
          cEnd = DateTime(now.year, now.month, now.day);
        }

        if (!currentDay.isBefore(cStart) && !currentDay.isAfter(cEnd)) {
          if (client.status == 'active' || client.status == 'completed') {
            revenues += client.dailyPrice;
            nurseCosts += client.nurseDailyPrice;
            shiftsCount++;
            activeClientIds.add(client.id);
          }
        }
      }
    }

    final grossProfit = revenues - nurseCosts;

    // 3. حساب المصروفات التشغيلية خلال الفترة (مع استثناء سلف الشركاء وتصفية الأرباح)
    double expenses = 0.0;
    for (final exp in _expenses) {
      if (exp.category == 'partner_loan' || exp.category == 'partner_settlement') continue;
      final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
      if (!expDate.isBefore(DateTime(sDate.year, sDate.month, sDate.day)) &&
          !expDate.isAfter(DateTime(eDate.year, eDate.month, eDate.day))) {
        expenses += exp.amount;
      }
    }

    final netProfit = grossProfit - expenses;

    // 4. حساب أنصبة الشركاء للدورة
    double wahdanShare = 0.0;
    double shimaaShare = 0.0;
    double zezoShare = 0.0;

    if (netProfit > 0) {
      final wahdanBase = netProfit * 0.40;
      final shimaaBase = netProfit * 0.40;
      final zezoBase = netProfit * 0.20;

      if (shimaaBase < 6000.0) {
        final subsidy = 6000.0 - shimaaBase;
        shimaaShare = 6000.0;
        final wahdanDed = subsidy * (40.0 / 60.0);
        final zezoDed = subsidy * (20.0 / 60.0);
        wahdanShare = (wahdanBase - wahdanDed).clamp(0.0, double.infinity);
        zezoShare = (zezoBase - zezoDed).clamp(0.0, double.infinity);
      } else {
        wahdanShare = wahdanBase;
        shimaaShare = shimaaBase;
        zezoShare = zezoBase;
      }
    }

    return PeriodFinancialSummary(
      periodType: periodType,
      periodTitle: periodTitle,
      startDate: sDate,
      endDate: eDate,
      revenues: revenues,
      nurseCosts: nurseCosts,
      grossProfit: grossProfit,
      expenses: expenses,
      netProfit: netProfit,
      shiftsCount: shiftsCount,
      activeClientsCount: activeClientIds.length,
      daysRemainingUntil23: daysRemaining,
      wahdanShare: wahdanShare,
      shimaaShare: shimaaShare,
      zezoShare: zezoShare,
    );
  }

  /// صافي الربح اليومي (ليوم محدد أو اليوم الحالي)
  PeriodFinancialSummary getDailyNetProfitSummary([DateTime? targetDate]) {
    final date = targetDate ?? DateTime.now();
    final sDate = DateTime(date.year, date.month, date.day);
    final eDate = DateTime(date.year, date.month, date.day);
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final title = isToday
        ? 'اليوم (${DateFormat('yyyy/MM/dd').format(date)})'
        : 'يوم ${DateFormat('yyyy/MM/dd').format(date)}';

    return getFinancialSummaryForRange(
      startDate: sDate,
      endDate: eDate,
      periodType: 'daily',
      periodTitle: title,
    );
  }

  /// صافي الربح الأسبوعي (آخر 7 أيام حتى تاريخ محدد أو اليوم)
  PeriodFinancialSummary getWeeklyNetProfitSummary([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final eDate = DateTime(ref.year, ref.month, ref.day);
    final sDate = eDate.subtract(const Duration(days: 6));
    final title = 'آخر 7 أيام (${DateFormat('MM/dd').format(sDate)} - ${DateFormat('MM/dd').format(eDate)})';

    return getFinancialSummaryForRange(
      startDate: sDate,
      endDate: eDate,
      periodType: 'weekly',
      periodTitle: title,
    );
  }

  /// صافي الربح الشهري وفق دورة يوم 23 من كل شهر
  /// الدورة تمتد من يوم 24 من الشهر السابق حتى يوم 23 من الشهر الحالي
  /// يمكن تمرير offsetCycles للتنقل للدورات السابقة (-1، -2) أو القادمة (+1)
  PeriodFinancialSummary getMonthlyNetProfitSummary({DateTime? referenceDate, int offsetCycles = 0}) {
    final ref = referenceDate ?? DateTime.now();

    // تحديد شهر وسنة نهاية الدورة
    int targetMonth = ref.month;
    int targetYear = ref.year;

    // إذا تجاوز اليوم تاريخ 23، فإننا نكون قد بدأنا في الدورة التالية التي تنتهي يوم 23 من الشهر القادم
    if (ref.day > 23) {
      if (targetMonth == 12) {
        targetMonth = 1;
        targetYear++;
      } else {
        targetMonth++;
      }
    }

    // تطبيق إزاحة الدورات (offsetCycles)
    if (offsetCycles != 0) {
      int totalMonths = (targetYear * 12 + (targetMonth - 1)) + offsetCycles;
      targetYear = totalMonths ~/ 12;
      targetMonth = (totalMonths % 12) + 1;
    }

    // تاريخ نهاية الدورة هو يوم 23 من الشهر المستهدف
    final cycleEnd = DateTime(targetYear, targetMonth, 23);

    // تاريخ بداية الدورة هو يوم 24 من الشهر السابق
    final prevMonth = targetMonth == 1 ? 12 : targetMonth - 1;
    final prevYear = targetMonth == 1 ? targetYear - 1 : targetYear;
    final cycleStart = DateTime(prevYear, prevMonth, 24);

    // حساب الأيام المتبقية حتى يوم 23
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int daysRemaining = 0;
    if (cycleEnd.isAfter(today) || cycleEnd.isAtSameMomentAs(today)) {
      daysRemaining = cycleEnd.difference(today).inDays;
    }

    final cycleTitle = 'دورة 23 ${_getMonthName(targetMonth)} $targetYear (${DateFormat('MM/dd').format(cycleStart)} - ${DateFormat('MM/dd').format(cycleEnd)})';

    return getFinancialSummaryForRange(
      startDate: cycleStart,
      endDate: cycleEnd,
      periodType: 'monthly_23',
      periodTitle: cycleTitle,
      daysRemaining: daysRemaining,
    );
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
    _caregivers = storageService.loadCaregivers().where((c) => !deletedSet.contains(c.id)).toList();
    _chatMessages = storageService.loadChatMessages();
    for (final m in _chatMessages) {
      _knownChatMessageIds.add(m.id);
    }
    _notifications = storageService.loadNotifications();
    for (final n in _notifications) {
      _knownNotificationIds.add(n.id);
    }

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
      await _logAction(
        title: 'تعديل صلاحيات مستخدم',
        description: 'تم تعديل صلاحيات المستخدم: ${_users[index].displayName}',
        actionType: 'user_permissions',
      );
      await cloudSyncService.pushData(
        clients: _clients,
        payments: _payments,
        expenses: _expenses,
        serviceDays: _serviceDays,
        users: _users,
        notifications: _notifications,
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
    await _logAction(
      title: 'تعديل الأرصدة الافتتاحية',
      description: 'تم تحديث أرصدة الخزينة (بنك: ${bank.toStringAsFixed(0)} ج.م | محفظة: ${wallet.toStringAsFixed(0)} ج.م | كاش: ${cash.toStringAsFixed(0)} ج.م)',
      actionType: 'balances',
    );
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
    await _logAction(
      title: isExistingClient ? 'تسجيل عميل حالي' : 'إضافة عميل جديد',
      description: 'تم تسجيل العميل: ${name.trim()} (السعر اليومي: ${dailyPrice.toStringAsFixed(0)} ج.م - يومية التمريض: ${nurseDailyPrice.toStringAsFixed(0)} ج.م)',
      actionType: 'add_client',
      metadata: {'clientName': name, 'dailyPrice': dailyPrice},
    );
    await _persistAndSync();
  }

  /// تعديل بيانات العميل الأساسية
  Future<void> editClient(ClientModel updated) async {
    final index = _clients.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _clients[index] = updated.copyWith(
        updatedAt: DateTime.now(),
      );
      await _logAction(
        title: 'تعديل بيانات عميل',
        description: 'تم تعديل بيانات العميل: ${updated.name}',
        actionType: 'edit_client',
        metadata: {'clientId': updated.id, 'clientName': updated.name},
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
      await _logAction(
        title: 'تحديد أسعار الخدمة للعميل',
        description: 'تم تحديد سعر العميل: ${current.name} (يومي: ${dailyPrice.toStringAsFixed(0)} ج.م - تمريض: ${nurseDailyPrice.toStringAsFixed(0)} ج.م)',
        actionType: 'pricing',
        metadata: {'clientId': clientId, 'clientName': current.name},
      );
      await _persistAndSync();
    }
  }

  /// 3. شيماء (أو المدير): تسجيل بدء الخدمة في التطبيق
  Future<void> startClientService({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
    bool isOpenEnded = false,
    String? nurseAssigned,
  }) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      final current = _clients[index];
      final start = startDate ?? DateTime.now();
      final end = isOpenEnded ? null : endDate;
      final nurse = nurseAssigned ?? current.nurseAssigned;

      _clients[index] = current.copyWith(
        startDate: start,
        endDate: end,
        clearEndDate: isOpenEnded,
        nurseAssigned: nurse,
        status: 'active',
        updatedAt: DateTime.now(),
      );

      // Auto-generate service days if duration is determined and nurse assigned
      if (!isOpenEnded && end != null && nurse != null && nurse.trim().isNotEmpty) {
        final startNorm = DateTime(start.year, start.month, start.day);
        final endNorm = DateTime(end.year, end.month, end.day);
        final int days = endNorm.difference(startNorm).inDays + 1;
        if (days > 0) {
          final List<DateTime> dates = [];
          for (int i = 0; i < days; i++) {
            dates.add(startNorm.add(Duration(days: i)));
          }
          await recordBatchServiceDays(
            clientId: clientId,
            dates: dates,
            nurseName: nurse,
            shiftType: current.serviceType,
            clientPrice: current.dailyPrice,
            nursePrice: current.nurseDailyPrice,
            notes: 'تسجيل آلي للمدة المحددة للتعاقد ($days يوم)',
          );
        }
      }

      final durStr = isOpenEnded
          ? 'مدة مفتوحة'
          : 'من ${DateFormat('yyyy/MM/dd').format(start)} إلى ${end != null ? DateFormat('yyyy/MM/dd').format(end) : ''}';
      await _logAction(
        title: 'بدء خدمة عميل',
        description: 'تم بدء الخدمة للعميل: ${current.name} (${durStr}) - التمريض: ${nurse ?? "غير محدد"}',
        actionType: 'start_service',
        metadata: {'clientId': clientId, 'clientName': current.name},
      );
      await _persistAndSync();
    }
  }

  /// تمديد أو تعديل مدة الخدمة أو فتح المدة للعميل (عند طلب العميل مد الخدمة أو فتحها)
  Future<void> extendOrUpdateServiceDuration({
    required String clientId,
    DateTime? newStartDate,
    DateTime? newEndDate,
    bool makeOpenEnded = false,
    String? note,
  }) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      final current = _clients[index];
      String updatedNotes = current.notes;
      if (note != null && note.trim().isNotEmpty) {
        final stamp = DateFormat('yyyy/MM/dd').format(DateTime.now());
        updatedNotes = updatedNotes.isEmpty
            ? '[$stamp] $note'
            : '$updatedNotes\n[$stamp] $note';
      }

      _clients[index] = current.copyWith(
        startDate: newStartDate ?? current.startDate,
        endDate: makeOpenEnded ? null : (newEndDate ?? current.endDate),
        clearEndDate: makeOpenEnded,
        notes: updatedNotes,
        updatedAt: DateTime.now(),
      );
      final newEndStr = makeOpenEnded
          ? 'مدة مفتوحة'
          : (newEndDate != null ? DateFormat('yyyy/MM/dd').format(newEndDate) : '');
      await _logAction(
        title: 'تمديد / تعديل مدة الخدمة',
        description: 'تم تعديل/تمديد مدة خدمة العميل: ${current.name} (${newEndStr})',
        actionType: 'extend_service',
        metadata: {'clientId': clientId, 'clientName': current.name},
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
      await _logAction(
        title: 'إنهاء خدمة عميل',
        description: 'تم إنهاء خدمة العميل: ${current.name} (السبب: ${reason.trim()})',
        actionType: 'end_service',
        metadata: {'clientId': clientId, 'clientName': current.name},
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

    String deletedClientName = 'عميل';
    for (final c in _clients) {
      if (c.id == clientId) {
        deletedClientName = c.name;
        break;
      }
    }
    _clients.removeWhere((c) => c.id == clientId);
    _payments.removeWhere((p) => p.clientId == clientId);
    _serviceDays.removeWhere((d) => d.clientId == clientId);

    await _logAction(
      title: 'حذف عميل',
      description: 'تم حذف العميل: $deletedClientName من النظام',
      actionType: 'delete_client',
    );
    await storageService.saveDeletedIds(_deletedIds);
    await _persistAndSync();
  }

  // --- Service Days Actions (أيام الخدمة والشفتات للعميل والممرض) ---

  /// تعديل وردية مسجلة / تبديل ممرض أو تعديل أوقات وساعات العمل
  Future<void> updateServiceDay(ServiceDayModel updatedDay) async {
    final index = _serviceDays.indexWhere((d) => d.id == updatedDay.id);
    if (index != -1) {
      _serviceDays[index] = updatedDay;
      final timeStr = updatedDay.timeRangeDisplay.isNotEmpty ? ' (${updatedDay.timeRangeDisplay})' : '';
      await _logAction(
        title: 'تعديل وردية / تبديل ممرض',
        description: 'تم تعديل وردية العميل: ${updatedDay.clientName} - الممرض: ${updatedDay.nurseName} - ${updatedDay.shiftTypeArabic}$timeStr',
        actionType: 'service_days',
        metadata: {'clientId': updatedDay.clientId, 'nurseName': updatedDay.nurseName},
      );
      await _persistAndSync();
    }
  }

  /// تسجيل يوم خدمة فردي
  Future<void> recordServiceDay({
    required String clientId,
    required DateTime date,
    required String nurseName,
    String shiftType = 'hours12',
    required double clientPrice,
    required double nursePrice,
    String notes = '',
    String? startTime,
    String? endTime,
    double? hoursCount,
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
      startTime: startTime,
      endTime: endTime,
      hoursCount: hoursCount,
    );

    _serviceDays.insert(0, day);
    final timeStr = day.timeRangeDisplay.isNotEmpty ? ' (${day.timeRangeDisplay})' : '';
    await _logAction(
      title: 'تسجيل يوم خدمة',
      description: 'تم تسجيل يوم خدمة (${DateFormat('yyyy/MM/dd').format(date)}) للعميل: ${client.name} - التمريض: ${day.nurseName} - ${day.shiftTypeArabic}$timeStr',
      actionType: 'service_days',
      metadata: {'clientId': clientId, 'clientName': client.name, 'nurseName': day.nurseName},
    );
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
    String? startTime,
    String? endTime,
    double? hoursCount,
  }) async {
    final client = _clients.firstWhere((c) => c.id == clientId);
    for (final date in dates) {
      final existingIndex = _serviceDays.indexWhere(
        (d) => d.clientId == clientId &&
               d.date.year == date.year &&
               d.date.month == date.month &&
               d.date.day == date.day &&
               (d.nurseName.trim() == nurseName.trim() || d.shiftType == shiftType)
      );

      final day = ServiceDayModel(
        id: existingIndex != -1 ? _serviceDays[existingIndex].id : 'day_${_uuid.v4().substring(0, 8)}',
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
        startTime: startTime,
        endTime: endTime,
        hoursCount: hoursCount,
      );

      if (existingIndex != -1) {
        _serviceDays[existingIndex] = day;
      } else {
        _serviceDays.insert(0, day);
      }
    }
    final timeStr = (startTime != null && endTime != null) ? ' (من $startTime إلى $endTime)' : '';
    await _logAction(
      title: 'تسجيل أيام الخدمة',
      description: 'تم تسجيل ${dates.length} يوم خدمة للعميل: ${client.name} - التمريض: ${nurseName.trim()} ($shiftType)$timeStr',
      actionType: 'service_days',
      metadata: {'clientId': clientId, 'clientName': client.name, 'daysCount': dates.length},
    );
    await _persistAndSync();
  }

  /// حذف يوم خدمة محدد
  Future<void> deleteServiceDay(String dayId) async {
    String targetClient = 'عميل';
    String targetNurse = '';
    for (final d in _serviceDays) {
      if (d.id == dayId) {
        targetClient = d.clientName;
        targetNurse = d.nurseName;
        break;
      }
    }
    if (!_deletedIds.contains(dayId)) {
      _deletedIds.add(dayId);
    }
    _serviceDays.removeWhere((d) => d.id == dayId);
    await _logAction(
      title: 'حذف يوم خدمة',
      description: 'تم حذف يوم خدمة للعميل: $targetClient (التمريض: $targetNurse)',
      actionType: 'service_days',
    );
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
    await _logAction(
      title: 'تسجيل تحصيل نقدية',
      description: 'تم تحصيل مبلغ ${amount.toStringAsFixed(0)} ج.م من العميل: ${client.name} (${_getChannelArabic(paymentChannel)})',
      actionType: 'payment',
      metadata: {'clientId': clientId, 'clientName': client.name, 'amount': amount},
    );
    await _persistAndSync();
  }

  Future<void> deletePayment(String paymentId) async {
    if (!canEditAnyData) return;
    String targetClient = 'عميل';
    double targetAmount = 0.0;
    for (final p in _payments) {
      if (p.id == paymentId) {
        targetClient = p.clientName;
        targetAmount = p.amount;
        break;
      }
    }
    if (!_deletedIds.contains(paymentId)) {
      _deletedIds.add(paymentId);
    }
    _payments.removeWhere((p) => p.id == paymentId);
    await _logAction(
      title: 'حذف دفعة نقدية',
      description: 'تم حذف دفعة بقيمة ${targetAmount.toStringAsFixed(0)} ج.م للعميل: $targetClient',
      actionType: 'delete_payment',
    );
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
    await _logAction(
      title: 'تسجيل مصروف جديد',
      description: 'تم تسجيل مصروف: ${title.trim()} بقيمة ${amount.toStringAsFixed(0)} ج.م (${_getChannelArabic(paymentChannel)})',
      actionType: 'expense',
      metadata: {'amount': amount, 'title': title},
    );
    await _persistAndSync();
  }

  Future<void> deleteExpense(String expenseId) async {
    if (!canEditAnyData) return;
    String targetTitle = 'مصروف';
    double targetAmount = 0.0;
    for (final e in _expenses) {
      if (e.id == expenseId) {
        targetTitle = e.title;
        targetAmount = e.amount;
        break;
      }
    }
    if (!_deletedIds.contains(expenseId)) {
      _deletedIds.add(expenseId);
    }
    _expenses.removeWhere((e) => e.id == expenseId);
    await _logAction(
      title: 'حذف مصروف',
      description: 'تم حذف مصروف: $targetTitle بقيمة ${targetAmount.toStringAsFixed(0)} ج.م',
      actionType: 'delete_expense',
    );
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
      await _logAction(
        title: 'تعديل صلاحيات مستخدم',
        description: 'تم تعديل صلاحيات المستخدم: ${_users[index].displayName}',
        actionType: 'user_permissions',
      );
      await cloudSyncService.pushData(
        clients: _clients,
        payments: _payments,
        expenses: _expenses,
        serviceDays: _serviceDays,
        users: _users,
        notifications: _notifications,
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
      await _logAction(
        title: 'تعديل بيانات مستخدم',
        description: 'تم تعديل بيانات المستخدم: ${displayName.trim()} (${roleTitle.trim()})',
        actionType: 'user_permissions',
      );
      await cloudSyncService.pushData(
        clients: _clients,
        payments: _payments,
        expenses: _expenses,
        serviceDays: _serviceDays,
        users: _users,
        notifications: _notifications,
        deletedIds: _deletedIds,
        openingBalances: _openingBalances,
      );
      notifyListeners();
    }
  }

  // --- Real-time Audible Notifications & Activity Logging ---

  void _triggerRemoteNotificationAlert(AppNotificationModel notif) {
    if (_soundAlertsEnabled) {
      SoundService.playNotificationSound();
    }

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0A2540),
          elevation: 10,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00D09C), width: 1.5),
          ),
          duration: const Duration(seconds: 6),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D09C).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFF00D09C),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notif.userName,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00D09C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notif.description,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Color(0xFFE2E8F0),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _logAction({
    required String title,
    required String description,
    required String actionType,
    Map<String, dynamic>? metadata,
  }) async {
    final notif = AppNotificationModel(
      id: 'ntf_${_uuid.v4().substring(0, 8)}',
      title: title,
      description: description,
      actionType: actionType,
      userId: _currentUser?.id ?? 'usr_anonymous',
      userName: _currentUser?.displayName ?? _currentUser?.username ?? 'مستخدم',
      userRole: _currentUser?.roleTitle ?? '',
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _notifications.insert(0, notif);
    if (_notifications.length > 150) {
      _notifications = _notifications.sublist(0, 150);
    }
    _knownNotificationIds.add(notif.id);
    await storageService.saveNotifications(_notifications);
  }

  String _getChannelArabic(String channel) {
    switch (channel) {
      case 'wallet': return 'المحفظة الإلكترونية';
      case 'bank': return 'الحساب البنكي';
      case 'cash': return 'الخزينة كاش';
      default: return channel;
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
        if (result.caregivers != null) {
          _caregivers = result.caregivers!.where((c) => !deletedSet.contains(c.id)).toList();
          await storageService.saveCaregivers(_caregivers);
        }
        if (result.chatMessages != null && result.chatMessages!.isNotEmpty) {
          final incoming = result.chatMessages!;
          bool hasNewIncomingChatMessage = false;
          ChatMessageModel? latestNewMsg;

          for (final msg in incoming) {
            if (!_knownChatMessageIds.contains(msg.id)) {
              _knownChatMessageIds.add(msg.id);
              final isFromOtherUser = _currentUser == null ||
                  (msg.senderId != _currentUser!.id &&
                   msg.senderUsername.trim() != _currentUser!.username.trim());
              final isForMe = msg.recipientId == 'all' ||
                  msg.recipientId == _currentUser?.id ||
                  msg.recipientId == _currentUser?.username;

              if (isFromOtherUser && isForMe) {
                hasNewIncomingChatMessage = true;
                _unreadChatCount++;
                latestNewMsg ??= msg;
              }
            }
          }

          final Map<String, ChatMessageModel> msgMap = {
            for (var m in _chatMessages) m.id: m,
          };
          for (var m in incoming) {
            msgMap[m.id] = m;
          }
          _chatMessages = msgMap.values.toList();
          _chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          if (_chatMessages.length > 300) {
            _chatMessages = _chatMessages.sublist(_chatMessages.length - 300);
          }
          await storageService.saveChatMessages(_chatMessages);

          if (hasNewIncomingChatMessage && latestNewMsg != null) {
            _triggerChatMessageAlert(latestNewMsg);
          }
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
        if (result.notifications != null && result.notifications!.isNotEmpty) {
          final now = DateTime.now();
          final List<AppNotificationModel> incoming = result.notifications!;
          incoming.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          bool hasFreshRemoteEvent = false;
          AppNotificationModel? freshestNotification;

          for (final notif in incoming) {
            if (!_knownNotificationIds.contains(notif.id)) {
              _knownNotificationIds.add(notif.id);

              final isFromOtherUser = _currentUser == null ||
                  (notif.userId != _currentUser!.id &&
                   notif.userName.trim() != _currentUser!.displayName.trim() &&
                   notif.userName.trim() != _currentUser!.username.trim());

              final isRecent = now.difference(notif.timestamp).inSeconds.abs() <= 60;

              if (isFromOtherUser && isRecent) {
                hasFreshRemoteEvent = true;
                _unreadNotificationCount++;
                freshestNotification ??= notif;
              }
            }
          }

          final Map<String, AppNotificationModel> notifMap = {
            for (var n in _notifications) n.id: n,
          };
          for (var n in incoming) {
            notifMap[n.id] = n;
          }
          _notifications = notifMap.values.toList();
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          if (_notifications.length > 150) {
            _notifications = _notifications.sublist(0, 150);
          }
          await storageService.saveNotifications(_notifications);

          if (hasFreshRemoteEvent && freshestNotification != null) {
            _triggerRemoteNotificationAlert(freshestNotification);
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
          caregivers: _caregivers,
          chatMessages: _chatMessages,
          notifications: _notifications,
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
    await storageService.saveCaregivers(_caregivers);
    await storageService.saveChatMessages(_chatMessages);
    await storageService.saveOpeningBalances(_openingBalances);
    await storageService.saveNotifications(_notifications);
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
      caregivers: _caregivers,
      chatMessages: _chatMessages,
      notifications: _notifications,
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
    for (var c in _caregivers) {
      final n = c.name.trim();
      if (n.isNotEmpty) set.add(n);
    }
    final list = set.toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// كشف ورديات ممرض معين مرتبة من الأحدث للأقدم
  List<ServiceDayModel> getNurseShifts(String nurseName) {
    final n = nurseName.trim();
    final list = _serviceDays.where((d) => d.nurseName.trim() == n).toList();

    // If client is assigned to this nurse but has no logged days, construct shifts from determined duration
    for (var c in _clients) {
      if ((c.nurseAssigned ?? '').trim() == n) {
        final clientLogged = _serviceDays.where((d) => d.clientId == c.id);
        if (clientLogged.isEmpty && c.startDate != null) {
          final int days = getClientServedDaysCount(c);
          final startNorm = DateTime(c.startDate!.year, c.startDate!.month, c.startDate!.day);
          for (int i = 0; i < days; i++) {
            list.add(ServiceDayModel(
              id: 'calc_${c.id}_$i',
              clientId: c.id,
              clientName: c.name,
              date: startNorm.add(Duration(days: i)),
              nurseName: n,
              shiftType: c.serviceType,
              clientPrice: c.dailyPrice,
              nursePrice: c.nurseDailyPrice,
              notes: 'حساب طبقاً للمدة المحددة بالتعاقد',
              recordedBy: c.createdBy,
              createdAt: c.createdAt,
            ));
          }
        }
      }
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// عدد أيام العمل المنفذة لهذا الممرض (سواء مسجلة في الشفتات أو من واقع المدة المحددة للعميل)
  int getNurseDaysCount(String nurseName) {
    final n = nurseName.trim();
    int count = _serviceDays.where((d) => d.nurseName.trim() == n).length;
    for (var c in _clients) {
      if ((c.nurseAssigned ?? '').trim() == n) {
        final clientLogged = _serviceDays.where((d) => d.clientId == c.id);
        if (clientLogged.isEmpty) {
          count += getClientServedDaysCount(c);
        }
      }
    }
    return count;
  }

  /// إجمالي مستحقات الممرض من واقع أسعار الأيام والورديات والمدة المحددة للعملاء
  double getNurseTotalEarned(String nurseName) {
    final n = nurseName.trim();
    double earned = _serviceDays
        .where((d) => d.nurseName.trim() == n)
        .fold(0.0, (sum, d) => sum + d.nursePrice);

    for (var c in _clients) {
      if ((c.nurseAssigned ?? '').trim() == n) {
        final clientLogged = _serviceDays.where((d) => d.clientId == c.id);
        if (clientLogged.isEmpty) {
          earned += getClientNurseCost(c);
        }
      }
    }
    return earned;
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
    final actTitle = type == 'advance' ? 'تسجيل سلفة تمريض' : 'صرف مستحقات تمريض';
    await _logAction(
      title: actTitle,
      description: 'تم ${actTitle} للممرض: ${nurseName.trim()} بمبلغ ${amount.toStringAsFixed(0)} ج.م (${_getChannelArabic(paymentChannel)})',
      actionType: type == 'advance' ? 'nurse_advance' : 'nurse_payout',
      metadata: {'nurseName': nurseName, 'amount': amount},
    );
    await _persistAndSync();
  }

  Future<void> deleteNurseTransaction(String id) async {
    if (!canEditAnyData) return;
    String targetNurse = 'ممرض';
    double targetAmount = 0.0;
    for (final t in _nurseTransactions) {
      if (t.id == id) {
        targetNurse = t.nurseName;
        targetAmount = t.amount;
        break;
      }
    }
    if (!_deletedIds.contains(id)) {
      _deletedIds.add(id);
    }
    final expId = 'exp_${id.substring(4)}';
    if (!_deletedIds.contains(expId)) {
      _deletedIds.add(expId);
    }
    _nurseTransactions.removeWhere((t) => t.id == id);
    _expenses.removeWhere((e) => e.id == expId);
    await _logAction(
      title: 'حذف معاملة تمريض',
      description: 'تم حذف معاملة للممرض: $targetNurse بقيمة ${targetAmount.toStringAsFixed(0)} ج.م',
      actionType: 'nurse_trans',
    );
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
    await _logAction(
      title: 'تسجيل سلفة شريك',
      description: 'تم تسجيل سلفة للشريك: $partnerName بمبلغ ${totalAmount.toStringAsFixed(0)} ج.م (${_getChannelArabic(paymentChannel)})',
      actionType: 'partner_loan',
      metadata: {'partnerName': partnerName, 'amount': totalAmount},
    );
    await _persistAndSync();
  }

  /// حذف سلفة شريك
  Future<void> deletePartnerLoan(String loanId) async {
    if (!canEditAnyData) return;
    String targetPartner = 'شريك';
    double targetAmount = 0.0;
    for (final l in _partnerLoans) {
      if (l.id == loanId) {
        targetPartner = l.partnerName;
        targetAmount = l.totalAmount;
        break;
      }
    }
    if (!_deletedIds.contains(loanId)) {
      _deletedIds.add(loanId);
    }
    final expId = 'exp_${loanId.substring(5)}';
    if (!_deletedIds.contains(expId)) {
      _deletedIds.add(expId);
    }
    _partnerLoans.removeWhere((l) => l.id == loanId);
    _expenses.removeWhere((e) => e.id == expId);
    await _logAction(
      title: 'حذف سلفة شريك',
      description: 'تم حذف سلفة الشريك: $targetPartner بقيمة ${targetAmount.toStringAsFixed(0)} ج.م',
      actionType: 'partner_loan',
    );
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

    await _logAction(
      title: 'اعتماد تصفية أرباح الشركاء',
      description: 'تم اعتماد وصرف $cycleTitle - إجمالي المنصرف: ${settlement.totalDisbursed.toStringAsFixed(0)} ج.م (متبقي الخزينة: ${settlement.remainingTreasuryCash.toStringAsFixed(0)} ج.م)',
      actionType: 'partner_settlement',
    );
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

  // ==========================================
  // --- Real-time Chat Alert & Methods (شات وتواصل أفراد الشركة) ---
  // ==========================================

  void _triggerChatMessageAlert(ChatMessageModel msg) {
    if (_soundAlertsEnabled) {
      SoundService.playNotificationSound();
    }

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F172A),
          elevation: 10,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
          ),
          duration: const Duration(seconds: 4),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            msg.isGroupMessage ? 'رسالة في شات الفريق' : 'رسالة خاصة جديدة',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'من: ${msg.senderDisplayName}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        msg.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// جلب رسائل شات الفريق العام
  List<ChatMessageModel> get groupChatMessages {
    return _chatMessages.where((m) => m.isGroupMessage).toList();
  }

  /// جلب الرسائل الخاصة مع مستخدم معين
  List<ChatMessageModel> getDirectMessagesWith(String otherUserId, [String? otherUsername]) {
    final myId = _currentUser?.id ?? '';
    final myUser = _currentUser?.username ?? '';
    return _chatMessages.where((m) {
      if (m.isGroupMessage) return false;
      final sentByMeToOther = (m.senderId == myId || m.senderUsername == myUser) &&
          (m.recipientId == otherUserId || (otherUsername != null && m.recipientId == otherUsername));
      final sentByOtherToMe = (m.senderId == otherUserId || (otherUsername != null && m.senderUsername == otherUsername)) &&
          (m.recipientId == myId || m.recipientId == myUser);
      return sentByMeToOther || sentByOtherToMe;
    }).toList();
  }

  /// إرسال رسالة جديدة
  Future<void> sendChatMessage({
    required String text,
    String recipientId = 'all',
    String recipientName = 'الجميع',
    String? tag,
    String? relatedClientName,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final newMsg = ChatMessageModel(
      id: 'msg_${_uuid.v4().substring(0, 8)}',
      senderId: _currentUser?.id ?? 'usr_guest',
      senderUsername: _currentUser?.username ?? 'user',
      senderDisplayName: _currentUser?.displayName ?? 'مستخدم',
      senderRole: _currentUser?.roleTitle ?? '',
      recipientId: recipientId,
      recipientName: recipientName,
      text: cleanText,
      tag: tag,
      relatedClientName: relatedClientName,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _knownChatMessageIds.add(newMsg.id);
    _chatMessages.add(newMsg);
    if (_chatMessages.length > 300) {
      _chatMessages = _chatMessages.sublist(_chatMessages.length - 300);
    }

    await storageService.saveChatMessages(_chatMessages);
    notifyListeners();

    // Push to cloud instantly
    cloudSyncService.pushData(
      clients: _clients,
      payments: _payments,
      expenses: _expenses,
      serviceDays: _serviceDays,
      nurseTransactions: _nurseTransactions,
      partnerLoans: _partnerLoans,
      partnerSettlements: _partnerSettlements,
      users: _users,
      caregivers: _caregivers,
      chatMessages: _chatMessages,
      notifications: _notifications,
      deletedIds: _deletedIds,
      openingBalances: _openingBalances,
    );
  }

  /// تحديد الرسائل كمقروءة
  void markChatAsRead([String? recipientId]) {
    _unreadChatCount = 0;
    notifyListeners();
  }

  // ==========================================
  // --- Caregivers & Staff Database (قاعدة بيانات وسجل مقدمي الخدمة) ---

  /// توليد كود تلقائي لمقدم الخدمة (e.g. CG-001, CG-002...)
  String generateNextCaregiverCode() {
    int maxNum = 0;
    for (var c in _caregivers) {
      final digits = c.code.replaceAll(RegExp(r'[^0-9]'), '');
      final n = int.tryParse(digits);
      if (n != null && n > maxNum) {
        maxNum = n;
      }
    }
    final nextNum = maxNum + 1;
    return 'CG-${nextNum.toString().padLeft(3, '0')}';
  }

  /// البحث عن مقدم خدمة بالاسم
  CaregiverModel? findCaregiverByName(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.isEmpty) return null;
    try {
      return _caregivers.firstWhere(
        (c) => c.name.trim().toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// البحث عن مقدم خدمة بالكود
  CaregiverModel? findCaregiverByCode(String code) {
    final clean = code.trim().toLowerCase();
    if (clean.isEmpty) return null;
    try {
      return _caregivers.firstWhere(
        (c) => c.code.trim().toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// الحالة الحالية التي يعمل بها مقدم الخدمة الآن
  String? getCaregiverCurrentCase(String caregiverName) {
    final clean = caregiverName.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // 1. أولاً نبحث في العملاء النشطين (active)
    for (var client in _clients) {
      if (client.status == 'active' &&
          (client.nurseAssigned ?? '').trim().toLowerCase() == clean) {
        return client.name;
      }
    }

    // 2. التحقق من الورديات المسجلة خلال آخر 3 أيام لعملاء نشطين
    for (var client in activeClients) {
      final shifts = getClientServiceDays(client.id);
      if (shifts.isNotEmpty) {
        final recentShift = shifts.first;
        if (recentShift.nurseName.trim().toLowerCase() == clean &&
            DateTime.now().difference(recentShift.date).inDays.abs() <= 3) {
          return client.name;
        }
      }
    }

    // 3. التحقق من السجل المحفوظ في ملف مقدم الخدمة
    final registered = findCaregiverByName(caregiverName);
    if (registered != null &&
        registered.isCurrentlyWorking &&
        registered.currentClientName != null &&
        registered.currentClientName!.trim().isNotEmpty) {
      return registered.currentClientName!.trim();
    }

    return null;
  }

  /// جلب قائمة بكافة العملاء الذين اشتغل معهم مقدم الخدمة
  List<String> getCaregiverPastClients(String caregiverName) {
    final set = <String>{};
    final clean = caregiverName.trim().toLowerCase();
    if (clean.isEmpty) return [];

    // من الورديات المسجلة فعلياً في النظام
    for (var d in _serviceDays) {
      if (d.nurseName.trim().toLowerCase() == clean) {
        try {
          final client = _clients.firstWhere((c) => c.id == d.clientId);
          if (client.name.trim().isNotEmpty) {
            set.add(client.name.trim());
          }
        } catch (_) {}
      }
    }

    // من ملف مقدم الخدمة المحفوظ
    final registered = findCaregiverByName(caregiverName);
    if (registered != null) {
      for (var p in registered.pastClients) {
        if (p.trim().isNotEmpty) set.add(p.trim());
      }
    }

    final list = set.toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// إضافة مقدم خدمة جديد إلى قاعدة البيانات
  Future<void> addCaregiver(CaregiverModel caregiver) async {
    _caregivers.add(caregiver);
    await _logAction(
      title: 'إضافة مقدم خدمة بقاعدة البيانات',
      description: '${_currentUser?.displayName ?? 'المستخدم'} قام بإضافة: ${caregiver.name} (كود: ${caregiver.code}) - السعر: ${caregiver.dailyPrice.toStringAsFixed(0)} ج',
      actionType: 'add_caregiver',
      metadata: {'caregiverId': caregiver.id, 'name': caregiver.name},
    );
    await _persistAndSync();
  }

  /// تعديل بيانات مقدم خدمة
  Future<void> updateCaregiver(CaregiverModel caregiver) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiver.id);
    if (idx != -1) {
      _caregivers[idx] = caregiver;
      await _logAction(
        title: 'تعديل ملف مقدم خدمة',
        description: '${_currentUser?.displayName ?? 'المستخدم'} قام بتعديل بيانات: ${caregiver.name} (كود: ${caregiver.code})',
        actionType: 'edit_caregiver',
        metadata: {'caregiverId': caregiver.id, 'name': caregiver.name},
      );
      await _persistAndSync();
    }
  }

  /// حظر أو فك حظر مقدم خدمة بسبب مشاكل
  Future<void> toggleCaregiverBlock(
    String caregiverId, {
    required bool isBlocked,
    String? reason,
  }) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId);
    if (idx != -1) {
      final old = _caregivers[idx];
      _caregivers[idx] = old.copyWith(
        isBlocked: isBlocked,
        blockReason: isBlocked ? reason : null,
      );
      await _logAction(
        title: isBlocked ? 'حظر مقدم خدمة لمشاكل' : 'إلغاء حظر مقدم خدمة',
        description: isBlocked
            ? '${_currentUser?.displayName ?? 'المستخدم'} قام بحظر: ${old.name} - السبب: ${reason ?? "غير محدد"}'
            : '${_currentUser?.displayName ?? 'المستخدم'} قام بإلغاء حظر: ${old.name}',
        actionType: isBlocked ? 'block_caregiver' : 'unblock_caregiver',
        metadata: {'caregiverId': old.id, 'name': old.name, 'reason': reason},
      );
      await _persistAndSync();
    }
  }

  /// حذف مقدم خدمة
  Future<void> deleteCaregiver(String caregiverId) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId);
    if (idx != -1) {
      final removed = _caregivers[idx];
      _caregivers.removeAt(idx);
      _deletedIds.add(caregiverId);
      await storageService.saveDeletedIds(_deletedIds);
      await _logAction(
        title: 'حذف مقدم خدمة',
        description: '${_currentUser?.displayName ?? 'المستخدم'} قام بحذف: ${removed.name} (كود: ${removed.code})',
        actionType: 'delete_caregiver',
        metadata: {'caregiverId': caregiverId, 'name': removed.name},
      );
      await _persistAndSync();
    }
  }
}
