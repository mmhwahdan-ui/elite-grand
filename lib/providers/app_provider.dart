import 'package:intl/intl.dart' hide TextDirection;
import '../models/app_notification_model.dart';
import '../models/period_financial_summary.dart';
import '../services/sound_service.dart';
import '../services/sms_service.dart';
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
import '../models/case_offer_model.dart';
import '../models/management_instruction_model.dart';
import '../models/settlement_report_model.dart';
import '../services/storage_service.dart';
import '../services/cloud_sync_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService storageService;
  late final CloudSyncService cloudSyncService;
  final Uuid _uuid = const Uuid();

  UserModel? _currentUser;
  UserModel? _impersonatorAdminUser;
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
  List<CaseOfferModel> _caseOffers = [];
  final Set<String> _knownCaseOfferIds = {};
  List<ManagementInstructionModel> _managementInstructions = [];
  final Set<String> _knownInstructionIds = {};
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
  UserModel? get impersonatorAdminUser => _impersonatorAdminUser;
  bool get isImpersonating => _impersonatorAdminUser != null;
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
  List<CaseOfferModel> get caseOffers => List.unmodifiable(_caseOffers);
  List<CaseOfferModel> get openCaseOffers => _caseOffers.where((o) => o.isOpen).toList();
  int get openCaseOffersCount => openCaseOffers.length;
  List<ManagementInstructionModel> get managementInstructions => List.unmodifiable(_managementInstructions);
  List<ManagementInstructionModel> get activeManagementInstructions => _managementInstructions.where((i) => i.isActive).toList();
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

  bool _hasDismissedThursdayBanner = false;

  bool get isTodayThursday => DateTime.now().weekday == DateTime.thursday;

  bool get showThursdayBanner => isTodayThursday && !_hasDismissedThursdayBanner && (isAdmin || isManager || isFollowup || isAccountant);

  void dismissThursdayBanner() {
    _hasDismissedThursdayBanner = true;
    notifyListeners();
  }

  /// فحص وإطلاق تنبيه صوتي وإشعار للإدارة يوم الخميس لتقفيل الحساب الأسبوعي
  Future<void> checkThursdayWeeklySettlementAlert({bool forcePlaySound = false}) async {
    final now = DateTime.now();
    final isThursday = now.weekday == DateTime.thursday;
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    final lastAlert = storageService.loadLastThursdayAlertDate();
    final shouldAlertToday = isThursday && (lastAlert != todayStr);

    if (shouldAlertToday || forcePlaySound) {
      if (_soundAlertsEnabled) {
        SoundService.playWeeklySettlementSound();
      }

      if (shouldAlertToday) {
        await storageService.saveLastThursdayAlertDate(todayStr);

        final notifId = 'ntf_thu_$todayStr';
        if (!_notifications.any((n) => n.id == notifId)) {
          final notif = AppNotificationModel(
            id: notifId,
            title: '🔔 تنبيه تقفيل الحساب الأسبوعي (يوم الخميس)',
            description: 'اليوم موعد انتهاء دورة الخدمة الأسبوعية وتقفيل حسابات الورديات ومستحقات مقدمي الخدمة والعملاء.',
            actionType: 'weekly_settlement',
            userId: _currentUser?.id ?? 'sys_settlement',
            userName: 'النظام الآلي للشركة',
            userRole: 'التنبيهات الإدارية',
            timestamp: now,
          );
          _notifications.insert(0, notif);
          _unreadNotificationCount++;
          await storageService.saveNotifications(_notifications);
        }
      }
      notifyListeners();
    }
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
  bool get isAdmin => isManager || isFollowup || isAccountant || canManageCaregivers;

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
      final raw = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      final name = getCanonicalNurseName(raw);
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  /// تفصيل المستحقات المالية لكل ممرض عمل مع هذا العميل
  Map<String, double> getNurseCostBreakdownForClient(String clientId) {
    final map = <String, double>{};
    final days = _serviceDays.where((d) => d.clientId == clientId);
    for (var d in days) {
      final raw = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      final name = getCanonicalNurseName(raw);
      map[name] = (map[name] ?? 0) + d.nursePrice;
    }
    return map;
  }

  /// إجمالي أيام عمل كل ممرض على مستوى جميع الحالات
  Map<String, int> get allNursesDaysCount {
    final map = <String, int>{};
    for (var d in _serviceDays) {
      final raw = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      final name = getCanonicalNurseName(raw);
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  /// إجمالي مستحقات كل ممرض المالية على مستوى جميع الحالات
  Map<String, double> get allNursesAccruedDues {
    final map = <String, double>{};
    for (var d in _serviceDays) {
      final raw = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      final name = getCanonicalNurseName(raw);
      map[name] = (map[name] ?? 0) + d.nursePrice;
    }
    return map;
  }

  /// قائمة جميع أيام الخدمة مجمعة حسب الممرض
  Map<String, List<ServiceDayModel>> get allNursesServiceDays {
    final map = <String, List<ServiceDayModel>>{};
    for (var d in _serviceDays) {
      final raw = d.nurseName.trim().isEmpty ? 'ممرض غير محدد' : d.nurseName.trim();
      final name = getCanonicalNurseName(raw);
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
      final currentDay = DateTime(sDay.year, sDay.month, sDay.day + i);

      // 1. فحص الورديات المسجلة فعلياً في جدول _serviceDays لهذا اليوم باليوم والشهر والسنة
      final daysLoggedForCurrentDay = _serviceDays.where((d) {
        final dLocal = d.date.toLocal();
        return dLocal.year == currentDay.year &&
            dLocal.month == currentDay.month &&
            dLocal.day == currentDay.day;
      }).toList();

      final Set<String> clientsHandledToday = {};

      for (final loggedDay in daysLoggedForCurrentDay) {
        revenues += loggedDay.clientPrice;
        nurseCosts += loggedDay.nursePrice;
        shiftsCount++;
        activeClientIds.add(loggedDay.clientId);
        clientsHandledToday.add(loggedDay.clientId);
      }

      // 2. فحص الحالات النشطة التي تعمل في هذا اليوم ولم تُسجل ورديتها يدوياً بعد واحتساب يوميتها التعاقدية
      for (final client in _clients) {
        if (clientsHandledToday.contains(client.id)) continue;
        if (client.startDate == null || client.dailyPrice <= 0) continue;

        final cStart = client.startDate!.toLocal();
        final cStartDay = DateTime(cStart.year, cStart.month, cStart.day);
        final DateTime cEndDay;
        if (client.endDate != null) {
          final cEnd = client.endDate!.toLocal();
          cEndDay = DateTime(cEnd.year, cEnd.month, cEnd.day);
        } else {
          final now = DateTime.now();
          cEndDay = DateTime(now.year, now.month, now.day);
        }

        final curDayNorm = DateTime(currentDay.year, currentDay.month, currentDay.day);
        if (!curDayNorm.isBefore(cStartDay) && !curDayNorm.isAfter(cEndDay)) {
          if (client.status == 'active' ||
              client.status == 'ready_to_start' ||
              client.status == 'completed') {
            revenues += client.dailyPrice;
            nurseCosts += client.nurseDailyPrice;
            shiftsCount++;
            activeClientIds.add(client.id);
          }
        }
      }
    }

    final grossProfit = revenues - nurseCosts;

    // 3. حساب المصروفات التشغيلية الحقيقية خلال الفترة
    // نستثني سلف الشركاء وتوزيع الأرباح، ونستثني صرف مستحقات وسلف التمريض
    // لأن أجور التمريض محسوبة بالفعل ومخصومة ضمن (nurseCosts)، واحتساب صرفها هنا يؤدي لخصم التمريض مرتين!
    double expenses = 0.0;
    for (final exp in _expenses) {
      final cat = exp.category.toLowerCase().trim();
      if (cat == 'partner_loan' ||
          cat == 'partner_settlement' ||
          cat == 'nurse_dues' ||
          cat == 'nurse_advance' ||
          cat == 'nurse_salary' ||
          cat == 'advances') {
        continue;
      }

      final expLocal = exp.expenseDate.toLocal();
      final expDay = DateTime(expLocal.year, expLocal.month, expLocal.day);
      if (!expDay.isBefore(sDay) && !expDay.isAfter(eDay)) {
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
    _caseOffers = storageService.loadCaseOffers();
    for (final o in _caseOffers) {
      _knownCaseOfferIds.add(o.id);
    }
    _notifications = storageService.loadNotifications();
    for (final n in _notifications) {
      _knownNotificationIds.add(n.id);
    }
    _managementInstructions = storageService.loadManagementInstructions();
    for (final i in _managementInstructions) {
      _knownInstructionIds.add(i.id);
    }

    // تنظيف أي إحداثيات موقع قديمة التُقطت بالخطأ من أجهزة الإدارة أثناء المعاينة والتجارب
    for (var i = 0; i < _caregivers.length; i++) {
      if (_caregivers[i].lastLatitude != null && _caregivers[i].lastLocationSource == null) {
        final hasRealShiftGps = _serviceDays.any((d) =>
            isNurseNameMatch(d.nurseName, _caregivers[i].name) &&
            d.checkInLatitude != null &&
            d.checkInLatitude == _caregivers[i].lastLatitude);
        if (!hasRealShiftGps) {
          _caregivers[i] = _caregivers[i].clearLocation();
        }
      }
    }

    // مزامنة إحداثيات الـ GPS لمقدمي الخدمة من آخر وردية تم تسجيلها جغرافياً من هاتف الممرض
    for (var i = 0; i < _caregivers.length; i++) {
      if (_caregivers[i].lastLatitude == null) {
        final withLoc = _serviceDays.where((d) => isNurseNameMatch(d.nurseName, _caregivers[i].name) && d.checkInLatitude != null).toList();
        if (withLoc.isNotEmpty) {
          final latest = withLoc.first;
          _caregivers[i] = _caregivers[i].copyWith(
            lastLatitude: latest.checkInLatitude,
            lastLongitude: latest.checkInLongitude,
            lastLocationAccuracy: latest.checkInAccuracy,
            lastLocationUpdate: latest.checkInAt ?? latest.createdAt,
            lastLocationSource: 'shift_checkin',
          );
        }
      }
    }
    storageService.saveCaregivers(_caregivers);

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

    if (_currentUser != null && (isAdmin || isManager || isFollowup || isAccountant)) {
      checkThursdayWeeklySettlementAlert();
    }

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

    // Check nurse accounts by phone or caregiver code if not found yet
    if (foundUser == null) {
      final cleanDigits = cleanUser.replaceAll(RegExp(r'[^0-9]'), '');
      for (var u in _users) {
        if (u.roleType == 'nurse') {
          final phoneDigits = (u.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
          if (cleanDigits.isNotEmpty && phoneDigits.isNotEmpty && (phoneDigits == cleanDigits || phoneDigits.endsWith(cleanDigits) || cleanDigits.endsWith(phoneDigits))) {
            foundUser = u;
            break;
          }
          if (u.caregiverId != null) {
            final cgMatch = _caregivers.where((c) => c.id == u.caregiverId).toList();
            if (cgMatch.isNotEmpty && cgMatch.first.code.toLowerCase() == cleanUser) {
              foundUser = u;
              break;
            }
          }
        }
      }
    }

    if (foundUser == null) {
      loginError = 'اسم المستخدم أو رقم الهاتف غير مسجل بالنظام';
      notifyListeners();
      return false;
    }

    // Check password: match actual password, or if still default '123' accept 123/123456
    final isDefault = foundUser.password.trim() == '123' || foundUser.password.trim().isEmpty;
    final isPasswordCorrect = cleanPass == foundUser.password.trim() ||
        (isDefault && (cleanPass == '123' || cleanPass == '123456'));

    if (!isPasswordCorrect) {
      loginError = isDefault
          ? 'كلمة المرور غير صحيحة، كلمة المرور الافتراضية هي: 123'
          : 'كلمة المرور غير صحيحة، يرجى كتابة كلمة المرور المعتمدة لحسابك';
      notifyListeners();
      return false;
    }

    _currentUser = foundUser;
    await storageService.setCurrentUserId(foundUser.id);
    if (isAdmin || isManager || isFollowup || isAccountant) {
      checkThursdayWeeklySettlementAlert();
    }
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
        title: 'تغيير كلمة المرور',
        description: 'تم تحديث كلمة المرور للمستخدم: ${_users[index].displayName}',
        actionType: 'change_password',
        metadata: {'userId': userId, 'username': _users[index].username},
      );
      await _persistAndSync();
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

  /// دخول فوري كـ مقدم خدمة دون الحاجة لاسم مستخدم أو كلمة مرور (خاص بالإدارة لمراجعة ومعاينة الشاشة)
  Future<void> loginAsCaregiver(CaregiverModel caregiver) async {
    if (_impersonatorAdminUser == null && _currentUser != null && _currentUser!.roleType != 'nurse') {
      _impersonatorAdminUser = _currentUser;
    }

    UserModel? nurseUser = _users.where((u) =>
        u.roleType == 'nurse' &&
        (u.caregiverId == caregiver.id || isNurseNameMatch(u.displayName, caregiver.name))).firstOrNull;

    if (nurseUser == null) {
      final cleanPhone = caregiver.phone.trim();
      final username = caregiver.loginUsername?.trim().isNotEmpty == true
          ? caregiver.loginUsername!.trim()
          : (cleanPhone.isNotEmpty ? cleanPhone : 'nurse_${caregiver.code.toLowerCase()}');

      nurseUser = UserModel(
        id: 'u_${caregiver.id}',
        username: username,
        displayName: caregiver.name,
        roleTitle: 'طاقم تمريض / مقدم خدمة',
        roleType: 'nurse',
        password: caregiver.loginPassword ?? '123',
        phone: cleanPhone,
        caregiverId: caregiver.id,
        permissions: const UserPermissions(),
      );
      _users.add(nurseUser);
      await storageService.saveUsers(_users);
    }

    _currentUser = nurseUser;
    await storageService.setCurrentUserId(nurseUser.id);
    notifyListeners();
  }

  /// الخروج من وضع معاينة شاشة الممرض والعودة الفورية لحساب الإدارة
  Future<void> exitCaregiverImpersonation() async {
    if (_impersonatorAdminUser != null) {
      _currentUser = _impersonatorAdminUser;
      _impersonatorAdminUser = null;
      await storageService.setCurrentUserId(_currentUser?.id);
      notifyListeners();
    }
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

  /// تصفير النظام من الأرصدة المالية والبدء من جديد مع الحفاظ الكامل على العملاء ومقدمي الخدمة
  Future<void> resetSystemFinancials({
    required bool resetClientOpeningBalances,
    required bool resetServiceDays,
    String reason = 'تصفير الحسابات المالية وإعادة إدخال الأرصدة',
  }) async {
    if (!canManagePermissions && !canEditAnyData) {
      throw Exception('ليس لديك صلاحية تصفير حسابات النظام');
    }

    // 1. Collect all IDs being wiped to permanently tombstone them in _deletedIds
    final wipedIds = <String>[
      ..._payments.map((p) => p.id),
      ..._expenses.map((e) => e.id),
      ..._nurseTransactions.map((t) => t.id),
      ..._partnerLoans.map((l) => l.id),
      ..._partnerSettlements.map((s) => s.id),
      if (resetServiceDays) ..._serviceDays.map((d) => d.id),
    ];
    for (final wid in wipedIds) {
      if (!_deletedIds.contains(wid)) {
        _deletedIds.add(wid);
      }
    }
    await storageService.saveDeletedIds(_deletedIds);

    // 2. Clear financial transactions collections
    _payments.clear();
    _expenses.clear();
    _nurseTransactions.clear();
    _partnerLoans.clear();
    _partnerSettlements.clear();

    // 3. Reset treasury opening balances to zero
    _openingBalances = {'bank': 0.0, 'wallet': 0.0, 'cash': 0.0};
    await storageService.saveOpeningBalances(_openingBalances);

    // 4. Reset client opening balances if requested
    if (resetClientOpeningBalances) {
      final now = DateTime.now();
      for (int i = 0; i < _clients.length; i++) {
        final c = _clients[i];
        if (c.openingBalance != 0.0 || c.isExistingClient) {
          _clients[i] = c.copyWith(
            openingBalance: 0.0,
            isExistingClient: false,
            updatedAt: now,
          );
        }
      }
      await storageService.saveClients(_clients);
    }

    // 5. Reset service days if requested
    if (resetServiceDays) {
      _serviceDays.clear();
      await storageService.saveServiceDays(_serviceDays);
    }

    // 6. Save all cleared collections to local storage
    await storageService.savePayments(_payments);
    await storageService.saveExpenses(_expenses);
    await storageService.saveNurseTransactions(_nurseTransactions);
    await storageService.savePartnerLoans(_partnerLoans);
    await storageService.savePartnerSettlements(_partnerSettlements);

    // 7. Push immediately to Cloud and await confirmation
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
      caseOffers: _caseOffers,
      notifications: _notifications,
      managementInstructions: _managementInstructions,
      deletedIds: _deletedIds,
      openingBalances: _openingBalances,
      isFinancialReset: true,
      resetServiceDays: resetServiceDays,
    );

    // 8. Log security audit trail
    await _logAction(
      title: 'تصفير الحسابات المالية للنظام',
      description: 'تم تصفير كافة الأرصدة المالية والخزائن والمدفوعات والمصروفات وحسابات الشركاء والتمريض مع الحفاظ التام على كافة بيانات العملاء والتمريض والمستخدمين. ($reason)',
      actionType: 'financial_reset',
      metadata: {
        'resetClientOpeningBalances': resetClientOpeningBalances,
        'resetServiceDays': resetServiceDays,
        'clientsPreserved': _clients.length,
        'caregiversPreserved': _caregivers.length,
        'usersPreserved': _users.length,
        'wipedRecordsCount': wipedIds.length,
      },
    );

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
    String serviceScheduleType = 'all_week',
    int daysPerWeek = 7,
    List<int> activeWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    String settlementFrequency = 'weekly',
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
      serviceScheduleType: serviceScheduleType,
      daysPerWeek: daysPerWeek,
      activeWeekdays: activeWeekdays,
      settlementFrequency: settlementFrequency,
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
        final List<DateTime> dates = [];
        DateTime cur = startNorm;
        while (!cur.isAfter(endNorm)) {
          bool isActiveDay = true;
          if (current.serviceScheduleType == 'custom_days' && current.activeWeekdays.isNotEmpty) {
            isActiveDay = current.activeWeekdays.contains(cur.weekday);
          }
          if (isActiveDay) {
            dates.add(cur);
          }
          cur = cur.add(const Duration(days: 1));
        }
        if (dates.isNotEmpty) {
          await recordBatchServiceDays(
            clientId: clientId,
            dates: dates,
            nurseName: nurse,
            shiftType: current.serviceType,
            clientPrice: current.dailyPrice,
            nursePrice: current.nurseDailyPrice,
            notes: 'تسجيل آلي للمدة المحددة للتعاقد (${dates.length} يوم - ${current.scheduleDescriptionArabic})',
          );
        }
      }

      final durStr = isOpenEnded
          ? 'مدة مفتوحة'
          : 'من ${DateFormat('yyyy/MM/dd').format(start)} إلى ${end != null ? DateFormat('yyyy/MM/dd').format(end) : ''}';
      await _logAction(
        title: 'بدء خدمة عميل',
        description: 'تم بدء الخدمة للعميل: ${current.name} ($durStr) - التمريض: ${nurse ?? "غير محدد"}',
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
        description: 'تم تعديل/تمديد مدة خدمة العميل: ${current.name} ($newEndStr)',
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

  /// تبديل مقدم الخدمة لحالة عميل (متاح لـ أ/ وهدان و أ/ زيزو)
  /// يتيح تغيير الممرض المسند، وسعر اليومية الجديد، ونقل الورديات القادمة تلقائياً
  Future<void> swapClientCaregiver({
    required String clientId,
    required String newNurseName,
    required double newNurseDailyPrice,
    required DateTime effectiveDate,
    bool updateUpcomingShifts = true,
    String? reason,
  }) async {
    final clientIdx = _clients.indexWhere((c) => c.id == clientId);
    if (clientIdx == -1) return;
    final client = _clients[clientIdx];
    final oldNurseName = (client.nurseAssigned ?? '').trim().isEmpty ? 'غير محدد' : client.nurseAssigned!.trim();
    final effectiveNorm = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
    final cleanNewNurse = newNurseName.trim();

    // 1. تحديث بيانات العميل وملاحظات التبديل
    final swapAudit = '[تبديل ممرض ${DateFormat('yyyy/MM/dd').format(effectiveDate)}: من ($oldNurseName) إلى ($cleanNewNurse) بيومية ${newNurseDailyPrice.toStringAsFixed(0)} ج.م${reason != null && reason.trim().isNotEmpty ? " - السبب: ${reason.trim()}" : ""}]';
    _clients[clientIdx] = client.copyWith(
      nurseAssigned: cleanNewNurse,
      nurseDailyPrice: newNurseDailyPrice,
      notes: client.notes.isEmpty ? swapAudit : '${client.notes}\n$swapAudit',
      updatedAt: DateTime.now(),
    );

    int updatedShiftsCount = 0;
    // 2. تحديث الورديات المستقبلية من تاريخ السريان فصاعداً
    if (updateUpcomingShifts) {
      for (int i = 0; i < _serviceDays.length; i++) {
        final d = _serviceDays[i];
        if (d.clientId == clientId) {
          final dayNorm = DateTime(d.date.year, d.date.month, d.date.day);
          if (!dayNorm.isBefore(effectiveNorm)) {
            _serviceDays[i] = d.copyWith(
              nurseName: cleanNewNurse,
              nursePrice: newNurseDailyPrice,
              notes: d.notes.isNotEmpty ? '${d.notes} (تم التبديل من $oldNurseName)' : 'تم التبديل من $oldNurseName',
            );
            updatedShiftsCount++;
          }
        }
      }
    }

    // 3. تحديث حالات مقدمي الخدمة بقاعدة البيانات
    final oldCgIdx = _caregivers.indexWhere((c) => isNurseNameMatch(c.name, oldNurseName) || isNurseNameMatch(c.code, oldNurseName));
    if (oldCgIdx != -1) {
      final otherClients = _clients.where((c) => c.id != clientId && (c.status == 'active' || c.status == 'ready_to_start') && isNurseNameMatch(c.nurseAssigned, _caregivers[oldCgIdx].name));
      if (otherClients.isEmpty) {
        _caregivers[oldCgIdx] = _caregivers[oldCgIdx].copyWith(
          isCurrentlyWorking: false,
          currentClientName: null,
        );
      }
    }

    final newCgIdx = _caregivers.indexWhere((c) => isNurseNameMatch(c.name, cleanNewNurse) || isNurseNameMatch(c.code, cleanNewNurse));
    if (newCgIdx != -1) {
      _caregivers[newCgIdx] = _caregivers[newCgIdx].copyWith(
        isCurrentlyWorking: true,
        currentClientName: client.name,
      );
    }

    // 4. تسجيل الإشعار والعملية في سجل النظام
    await _logAction(
      title: 'تبديل مقدم خدمة للحالة',
      description: 'قام ${_currentUser?.displayName ?? "الإدارة"} بتبديل مقدم الخدمة للعميل: ${client.name} من ($oldNurseName) إلى ($cleanNewNurse) بيومية ${newNurseDailyPrice.toStringAsFixed(0)} ج.م (تاريخ السريان: ${DateFormat('yyyy/MM/dd').format(effectiveDate)} - تم تحديث $updatedShiftsCount وردية)',
      actionType: 'swap_caregiver',
      metadata: {
        'clientId': clientId,
        'clientName': client.name,
        'oldNurse': oldNurseName,
        'newNurse': cleanNewNurse,
        'effectiveDate': effectiveDate.toIso8601String(),
        'updatedShifts': updatedShiftsCount,
      },
    );

    await storageService.saveCaregivers(_caregivers);
    await _persistAndSync();
    notifyListeners();
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
    } else {
      // إذا كانت الوردية محسوبة آلياً من مدة التعاقد (calc_)، يتم تحويلها إلى يوم خدمة مسجل فعلياً
      final concreteDay = updatedDay.copyWith(
        id: updatedDay.id.startsWith('calc_') ? 'day_${_uuid.v4().substring(0, 8)}' : updatedDay.id,
      );
      _serviceDays.insert(0, concreteDay);
    }
    final timeStr = updatedDay.timeRangeDisplay.isNotEmpty ? ' (${updatedDay.timeRangeDisplay})' : '';
    await _logAction(
      title: 'تعديل وردية / تبديل ممرض',
      description: 'تم تعديل وردية العميل: ${updatedDay.clientName} - الممرض: ${updatedDay.nurseName} - ${updatedDay.shiftTypeArabic}$timeStr',
      actionType: 'service_days',
      metadata: {'clientId': updatedDay.clientId, 'nurseName': updatedDay.nurseName},
    );
    await _persistAndSync();
    notifyListeners();
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
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkInAccuracy,
    DateTime? checkInAt,
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
      checkInLatitude: checkInLatitude,
      checkInLongitude: checkInLongitude,
      checkInAccuracy: checkInAccuracy,
      checkInAt: checkInAt,
    );

    _serviceDays.insert(0, day);
    final timeStr = day.timeRangeDisplay.isNotEmpty ? ' (${day.timeRangeDisplay})' : '';
    final gpsStr = day.hasGpsCheckIn ? ' [موقع جغرافي مثبت 📍]' : '';
    await _logAction(
      title: 'تسجيل يوم خدمة',
      description: 'تم تسجيل يوم خدمة (${DateFormat('yyyy/MM/dd').format(date)}) للعميل: ${client.name} - التمريض: ${day.nurseName} - ${day.shiftTypeArabic}$timeStr$gpsStr',
      actionType: 'service_days',
      metadata: {'clientId': clientId, 'clientName': client.name, 'nurseName': day.nurseName},
    );
    await _persistAndSync();
  }

  /// إثبات انصراف وتسليم الوردية للممرض مع إحداثيات GPS
  Future<void> recordNurseCheckOut({
    String? serviceDayId,
    String? shiftId,
    String? endTime,
    double? checkOutLatitude,
    double? checkOutLongitude,
    DateTime? checkOutAt,
    double? hoursCount,
    String? notes,
  }) async {
    final targetId = serviceDayId ?? shiftId ?? '';
    final effectiveEndTime = endTime ?? DateFormat('hh:mm a').format(DateTime.now());
    final idx = _serviceDays.indexWhere((d) => d.id == targetId);
    if (idx != -1) {
      final old = _serviceDays[idx];
      _serviceDays[idx] = old.copyWith(
        endTime: effectiveEndTime,
        hoursCount: hoursCount ?? old.hoursCount,
        checkOutLatitude: checkOutLatitude,
        checkOutLongitude: checkOutLongitude,
        checkOutAt: checkOutAt ?? DateTime.now(),
        notes: notes != null && notes.trim().isNotEmpty
            ? '${old.notes.isNotEmpty ? "${old.notes} • " : ""}$notes'
            : old.notes,
      );
      if (checkOutLatitude != null && checkOutLongitude != null) {
        final cgIdx = _caregivers.indexWhere((c) => isNurseNameMatch(c.name, old.nurseName));
        if (cgIdx != -1) {
          _caregivers[cgIdx] = _caregivers[cgIdx].copyWith(
            lastLatitude: checkOutLatitude,
            lastLongitude: checkOutLongitude,
            lastLocationUpdate: checkOutAt ?? DateTime.now(),
            lastLocationSource: 'shift_checkout',
          );
          await storageService.saveCaregivers(_caregivers);
        }
      }
      final gpsStr = checkOutLatitude != null ? ' [موقع جغرافي مثبت 📍]' : '';
      await _logAction(
        title: 'إثبات انصراف وردية (GPS)',
        description: 'الممرض: ${old.nurseName} قام بتسليم وانصراف الوردية للعميل: ${old.clientName} (وقت الإنهاء: $effectiveEndTime)$gpsStr',
        actionType: 'service_days',
        metadata: {'clientId': old.clientId, 'nurseName': old.nurseName},
      );
      await _persistAndSync();
      notifyListeners();
    }
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

  /// تفعيل الخدمة الأسبوعي لحالة عميل بأيام محددة مسبقاً وتأكيد أسعار العميل ومقدم الخدمة
  Future<int> activateWeeklyClientService({
    required String clientId,
    required List<DateTime> selectedDates,
    required double clientPrice,
    required double nursePrice,
    required String nurseName,
    String? shiftType,
    String notes = '',
  }) async {
    final clientIndex = _clients.indexWhere((c) => c.id == clientId);
    if (clientIndex == -1 || selectedDates.isEmpty) return 0;
    final client = _clients[clientIndex];

    int createdCount = 0;
    for (final date in selectedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final existingIndex = _serviceDays.indexWhere((d) =>
          d.clientId == clientId &&
          d.date.year == normalizedDate.year &&
          d.date.month == normalizedDate.month &&
          d.date.day == normalizedDate.day);

      final dayModel = ServiceDayModel(
        id: existingIndex != -1 ? _serviceDays[existingIndex].id : 'day_${_uuid.v4().substring(0, 8)}',
        clientId: clientId,
        clientName: client.name,
        date: normalizedDate,
        nurseName: nurseName.trim().isEmpty ? (client.nurseAssigned ?? 'ممرض') : nurseName.trim(),
        shiftType: shiftType ?? client.serviceType,
        clientPrice: clientPrice,
        nursePrice: nursePrice,
        notes: notes.trim().isNotEmpty ? notes.trim() : 'تفعيل خدمة أسبوعي',
        recordedBy: _currentUser?.username ?? 'wahdan',
        createdAt: DateTime.now(),
      );

      if (existingIndex != -1) {
        _serviceDays[existingIndex] = dayModel;
      } else {
        _serviceDays.insert(0, dayModel);
        createdCount++;
      }
    }

    // Ensure client status is active and nurse is assigned with confirmed rates
    final updatedClient = client.copyWith(
      status: 'active',
      nurseAssigned: nurseName.trim().isNotEmpty ? nurseName.trim() : client.nurseAssigned,
      dailyPrice: clientPrice,
      nurseDailyPrice: nursePrice,
      startDate: client.startDate ?? selectedDates.first,
    );
    _clients[clientIndex] = updatedClient;

    await storageService.saveClients(_clients);
    await storageService.saveServiceDays(_serviceDays);

    await _logAction(
      title: 'تفعيل الخدمة الأسبوعي للعميل',
      description: 'تم تفعيل ${selectedDates.length} ورديات أسبوعية للعميل ${client.name} مع التمريض: $nurseName (سعر العميل: $clientPrice ج.م | يومية التمريض: $nursePrice ج.م)',
      actionType: 'activate_weekly_service',
      metadata: {
        'clientId': clientId,
        'clientName': client.name,
        'datesCount': selectedDates.length,
        'newShiftsCount': createdCount,
        'nurseName': nurseName,
      },
    );

    await _persistAndSync();
    notifyListeners();
    return selectedDates.length;
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
        if (result.caseOffers != null) {
          final incomingOffers = result.caseOffers!.where((o) => !deletedSet.contains(o.id)).toList();
          bool hasNewOpenOffer = false;
          CaseOfferModel? latestNewOffer;

          for (final o in incomingOffers) {
            if (!_knownCaseOfferIds.contains(o.id)) {
              _knownCaseOfferIds.add(o.id);
              if (o.isOpen) {
                hasNewOpenOffer = true;
                latestNewOffer = o;
              }
            }
          }

          _caseOffers = incomingOffers;
          await storageService.saveCaseOffers(_caseOffers);

          // إشعار بصوت عالي لمقدمي الخدمة في حالة وجود فرصة جديدة
          if (hasNewOpenOffer && latestNewOffer != null && _currentUser?.roleType == 'nurse') {
            _triggerNewCaseOfferAlert(latestNewOffer);
          }
        }
        if (result.managementInstructions != null && result.managementInstructions!.isNotEmpty) {
          _managementInstructions = result.managementInstructions!;
          await storageService.saveManagementInstructions(_managementInstructions);
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
              final isForMe = msg.recipientId == _currentUser?.id ||
                  msg.recipientId == _currentUser?.username ||
                  (msg.threadId != null && _currentUser != null && msg.threadId == 'thread_${_currentUser!.id}') ||
                  (_currentUser?.roleType != 'nurse' && msg.recipientId == 'all') ||
                  (_currentUser?.roleType == 'nurse' && msg.recipientId == 'cases_group');

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
          caseOffers: _caseOffers,
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
    await storageService.saveCaseOffers(_caseOffers);
    await storageService.saveOpeningBalances(_openingBalances);
    await storageService.saveNotifications(_notifications);
    await storageService.saveManagementInstructions(_managementInstructions);
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
      caseOffers: _caseOffers,
      notifications: _notifications,
      managementInstructions: _managementInstructions,
      deletedIds: _deletedIds,
      openingBalances: _openingBalances,
    );
  }

  // ==========================================
  // --- Nurse Accounts & Advances (حسابات وسلف التمريض) ---
  // ==========================================

  /// تنظيف وتوحيد النصوص العربية للبحث والمطابقة الذكية
  static String _normalizeArabic(String text) {
    var s = text.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\u064B-\u0652]'), ''); // تشكيل
    s = s.replaceAll(RegExp(r'[إأآا]'), 'ا'); // همزات الألف
    s = s.replaceAll('ة', 'ه'); // تاء مربوطة
    s = s.replaceAll('ى', 'ي'); // ألف مقصورة وياء
    s = s.replaceAll(RegExp(r'\s+'), ' '); // مسافات زائدة
    return s.trim();
  }

  /// مطابقة ذكية بين أسماء وأكواد الممرضين
  /// تضمن ربط الاسم المختصر (مثل: "زينب") بالاسم الرباعي (مثل: "زينب محمد عبد الحميد احمد خير الله") أو الكود (مثل: CG-002)
  bool isNurseNameMatch(String? a, String? b) {
    if (a == null || b == null) return false;
    final s1 = _normalizeArabic(a);
    final s2 = _normalizeArabic(b);
    if (s1.isEmpty || s2.isEmpty) return false;
    if (s1 == s2) return true;

    // 1. فحص سجلات مقدمي الخدمة المسجلين بقاعدة البيانات
    for (var c in _caregivers) {
      final cName = _normalizeArabic(c.name);
      final cCode = _normalizeArabic(c.code);
      final cUser = _normalizeArabic(c.loginUsername ?? '');

      final m1 = (s1 == cCode || s1 == cName || (cUser.isNotEmpty && s1 == cUser));
      final m2 = (s2 == cCode || s2 == cName || (cUser.isNotEmpty && s2 == cUser));
      if (m1 && m2) return true;

      if (m1 || m2) {
        final other = m1 ? s2 : s1;
        if (cName.contains(other) || (other.length >= 3 && cName.startsWith(other))) {
          return true;
        }
      }
    }

    // 2. فحص حسابات المستخدمين التمريض
    for (var u in _users.where((u) => u.isNurse)) {
      final uName = _normalizeArabic(u.displayName);
      final uUser = _normalizeArabic(u.username);
      final m1 = (s1 == uName || s1 == uUser);
      final m2 = (s2 == uName || s2 == uUser);
      if (m1 && m2) return true;
      if (m1 || m2) {
        final other = m1 ? s2 : s1;
        if (uName.contains(other) || (other.length >= 3 && uName.startsWith(other))) {
          return true;
        }
      }
    }

    // 3. تطابق احتواء مباشر للكلمات المركبة (أكبر من حرفين)
    if (s1.length >= 3 && s2.length >= 3) {
      if (s1.contains(s2) || s2.contains(s1)) return true;
    }

    // 4. تطابق الاسم الأول إذا كان أحدهما اسماً مفرداً (مثل: "زينب")
    final w1 = s1.split(' ');
    final w2 = s2.split(' ');
    if (w1.isNotEmpty && w2.isNotEmpty) {
      if (w1.first == w2.first && w1.first.length >= 3) {
        if (w1.length == 1 || w2.length == 1) return true;
      }
    }

    return false;
  }

  /// جلب الاسم الرسمي المعتمد للممرض المسجل بقاعدة البيانات
  String getCanonicalNurseName(String rawName) {
    final clean = rawName.trim();
    if (clean.isEmpty || clean == 'ممرض غير محدد' || clean == 'غير محدد') return clean;
    for (var c in _caregivers) {
      if (isNurseNameMatch(clean, c.name) || isNurseNameMatch(clean, c.code)) {
        return c.name;
      }
    }
    for (var u in _users.where((u) => u.isNurse)) {
      if (isNurseNameMatch(clean, u.displayName) || isNurseNameMatch(clean, u.username)) {
        return u.displayName;
      }
    }
    return clean;
  }

  /// قائمة بأسماء كافة الممرضين والممرضات المسجلين في النظام
  List<String> get allNurseNames {
    final set = <String>{};
    for (var c in _caregivers) {
      final n = c.name.trim();
      if (n.isNotEmpty) set.add(n);
    }
    for (var d in _serviceDays) {
      final n = d.nurseName.trim();
      if (n.isNotEmpty && n != 'ممرض غير محدد') {
        set.add(getCanonicalNurseName(n));
      }
    }
    for (var c in _clients) {
      final n = (c.nurseAssigned ?? '').trim();
      if (n.isNotEmpty && n != 'غير محدد') {
        set.add(getCanonicalNurseName(n));
      }
    }
    for (var t in _nurseTransactions) {
      final n = t.nurseName.trim();
      if (n.isNotEmpty) {
        set.add(getCanonicalNurseName(n));
      }
    }
    final list = set.toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// كشف ورديات ممرض معين مرتبة من الأحدث للأقدم
  List<ServiceDayModel> getNurseShifts(String nurseName) {
    final list = _serviceDays.where((d) => isNurseNameMatch(d.nurseName, nurseName)).toList();

    // If client is assigned to this nurse but has no logged days, construct shifts from determined duration
    for (var c in _clients) {
      if (isNurseNameMatch(c.nurseAssigned, nurseName)) {
        final clientLogged = _serviceDays.where((d) => d.clientId == c.id);
        if (clientLogged.isEmpty && c.startDate != null) {
          final startNorm = DateTime(c.startDate!.year, c.startDate!.month, c.startDate!.day);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final endLimit = c.endDate != null ? DateTime(c.endDate!.year, c.endDate!.month, c.endDate!.day) : today;

          DateTime cur = startNorm;
          int i = 0;
          while (!cur.isAfter(endLimit)) {
            bool isActiveDay = true;
            if (c.serviceScheduleType == 'custom_days' && c.activeWeekdays.isNotEmpty) {
              isActiveDay = c.activeWeekdays.contains(cur.weekday);
            }
            if (isActiveDay) {
              list.add(ServiceDayModel(
                id: 'calc_${c.id}_$i',
                clientId: c.id,
                clientName: c.name,
                date: cur,
                nurseName: c.nurseAssigned ?? nurseName,
                shiftType: c.serviceType,
                clientPrice: c.dailyPrice,
                nursePrice: c.nurseDailyPrice,
                notes: 'حساب طبقاً للمدة وجدول الخدمة الأسبوعي (${c.scheduleDescriptionArabic})',
                recordedBy: c.createdBy,
                createdAt: c.createdAt,
              ));
              i++;
            }
            cur = cur.add(const Duration(days: 1));
          }
        }
      }
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// عدد أيام العمل المنفذة لهذا الممرض (سواء مسجلة في الشفتات أو من واقع المدة المحددة للعميل)
  int getNurseDaysCount(String nurseName) {
    int count = _serviceDays.where((d) => isNurseNameMatch(d.nurseName, nurseName)).length;
    for (var c in _clients) {
      if (isNurseNameMatch(c.nurseAssigned, nurseName)) {
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
    double earned = _serviceDays
        .where((d) => isNurseNameMatch(d.nurseName, nurseName))
        .fold(0.0, (sum, d) => sum + d.nursePrice);

    for (var c in _clients) {
      if (isNurseNameMatch(c.nurseAssigned, nurseName)) {
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
    final list = _nurseTransactions.where((t) => isNurseNameMatch(t.nurseName, nurseName)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// إجمالي السلف التي أخذها الممرض
  double getNurseTotalAdvances(String nurseName) {
    return _nurseTransactions
        .where((t) => isNurseNameMatch(t.nurseName, nurseName) && t.type == 'advance')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// إجمالي صرف المستحقات / الأجور التي استلمها الممرض
  double getNurseTotalPayouts(String nurseName) {
    return _nurseTransactions
        .where((t) => isNurseNameMatch(t.nurseName, nurseName) && t.type == 'payout')
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

  /// تقرير كشف تقفيل الحسابات الأسبوعي أو الشهري لمقدمي الخدمة والعملاء
  WeeklyMonthlySettlementReport getSettlementReportData({
    required DateTime startDate,
    required DateTime endDate,
    String periodType = 'weekly',
    String? customTitle,
  }) {
    final startNorm = DateTime(startDate.year, startDate.month, startDate.day);
    final endNorm = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final dateFormat = DateFormat('yyyy/MM/dd');
    final title = customTitle ??
        (periodType == 'weekly'
            ? 'كشف التقفيل الأسبوعي لمقدمي الخدمة والعملاء (المنتهي بالخميس ${dateFormat.format(endDate)})'
            : 'كشف التقفيل الشهري لمقدمي الخدمة والعملاء (${dateFormat.format(startNorm)} - ${dateFormat.format(endDate)})');

    // 1. أطقم التمريض
    final List<CaregiverSettlementItem> caregiverItems = [];
    final allNurses = allNurseNames;

    for (var nurse in allNurses) {
      final allShifts = getNurseShifts(nurse);
      final periodShifts = allShifts.where((s) {
        final d = DateTime(s.date.year, s.date.month, s.date.day);
        return !d.isBefore(startNorm) && !d.isAfter(endNorm);
      }).toList();

      final allTrans = getNurseTransactions(nurse);
      final periodTrans = allTrans.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return !d.isBefore(startNorm) && !d.isAfter(endNorm);
      }).toList();

      final earned = periodShifts.fold(0.0, (sum, s) => sum + s.nursePrice);
      final advances = periodTrans.where((t) => t.type == 'advance').fold(0.0, (sum, t) => sum + t.amount);
      final payouts = periodTrans.where((t) => t.type == 'payout').fold(0.0, (sum, t) => sum + t.amount);
      final periodNetDue = earned - advances - payouts;
      final allTimeRem = getNurseRemainingBalance(nurse);

      final clientNames = periodShifts.map((s) => s.clientName).toSet().toList();
      final cg = findCaregiverByName(nurse);

      if (periodShifts.isNotEmpty || advances > 0 || payouts > 0 || allTimeRem.abs() > 0.01) {
        caregiverItems.add(CaregiverSettlementItem(
          nurseName: nurse,
          nurseCode: cg?.code,
          nursePhone: cg?.phone,
          clientNames: clientNames,
          shiftsCount: periodShifts.length,
          dailyRate: periodShifts.isNotEmpty ? periodShifts.first.nursePrice : (cg?.dailyPrice ?? 0.0),
          totalEarned: earned,
          advances: advances,
          payouts: payouts,
          periodNetDue: periodNetDue,
          allTimeRemaining: allTimeRem,
          shifts: periodShifts,
        ));
      }
    }

    // 2. العملاء والحالات
    final List<ClientSettlementItem> clientItems = [];

    for (var client in _clients) {
      final allLoggedDays = getClientServiceDays(client.id);
      final periodLoggedDays = allLoggedDays.where((d) {
        final dt = DateTime(d.date.year, d.date.month, d.date.day);
        return !dt.isBefore(startNorm) && !dt.isAfter(endNorm);
      }).toList();

      int daysInPeriod = 0;
      double periodAccrued = 0.0;

      if (periodLoggedDays.isNotEmpty) {
        daysInPeriod = periodLoggedDays.length;
        periodAccrued = periodLoggedDays.fold(0.0, (sum, d) => sum + d.clientPrice);
      } else if (client.startDate != null) {
        final cStart = DateTime(client.startDate!.year, client.startDate!.month, client.startDate!.day);
        final now = DateTime.now();
        final cEnd = client.endDate != null ? DateTime(client.endDate!.year, client.endDate!.month, client.endDate!.day) : DateTime(now.year, now.month, now.day);

        final effectiveStart = cStart.isAfter(startNorm) ? cStart : startNorm;
        final effectiveEnd = cEnd.isBefore(endNorm) ? cEnd : endNorm;

        if (!effectiveStart.isAfter(effectiveEnd)) {
          DateTime cur = effectiveStart;
          while (!cur.isAfter(effectiveEnd)) {
            bool isActiveDay = true;
            if (client.serviceScheduleType == 'custom_days' && client.activeWeekdays.isNotEmpty) {
              isActiveDay = client.activeWeekdays.contains(cur.weekday);
            }
            if (isActiveDay) {
              daysInPeriod++;
            }
            cur = cur.add(const Duration(days: 1));
          }
          periodAccrued = daysInPeriod * client.dailyPrice;
        }
      }

      final periodPayments = _payments.where((p) {
        final d = DateTime(p.paymentDate.year, p.paymentDate.month, p.paymentDate.day);
        return p.clientId == client.id && !d.isBefore(startNorm) && !d.isAfter(endNorm);
      }).fold(0.0, (sum, p) => sum + p.amount);

      final periodRemaining = periodAccrued - periodPayments;
      final allTimeBalance = getClientBalance(client);

      if (daysInPeriod > 0 || periodPayments > 0 || client.status == 'active' || allTimeBalance.abs() > 0.01) {
        clientItems.add(ClientSettlementItem(
          client: client,
          daysServedInPeriod: daysInPeriod,
          dailyPrice: client.dailyPrice,
          periodAccruedCost: periodAccrued,
          periodCollected: periodPayments,
          periodRemaining: periodRemaining,
          allTimeBalance: allTimeBalance,
        ));
      }
    }

    return WeeklyMonthlySettlementReport(
      startDate: startNorm,
      endDate: endNorm,
      periodType: periodType,
      title: title,
      caregivers: caregiverItems,
      clients: clientItems,
    );
  }

  /// تسجيل سلفة أو دفعة مستحقات للممرض مع ربط العميل المسجل في النظام تلقائياً
  Future<void> recordNurseTransaction({
    required String nurseName,
    required double amount,
    required DateTime date,
    required String type, // 'advance' (سلفة) | 'payout' (صرف مستحقات)
    String paymentChannel = 'bank', // الخزنة التلقائية الحساب البنكي
    String notes = '',
    String? clientId,
    String? clientName,
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
      clientId: clientId,
      clientName: clientName,
      createdAt: DateTime.now(),
    );

    _nurseTransactions.insert(0, newTrans);

    // Record as company expense to maintain accurate treasury cash flow
    final clientPart = (clientName != null && clientName.trim().isNotEmpty) ? ' (العميل: ${clientName.trim()})' : '';
    final expenseTitle = type == 'advance'
        ? 'سلفة تمريض: ${nurseName.trim()}$clientPart'
        : 'صرف مستحقات تمريض: ${nurseName.trim()}$clientPart';

    final expNotes = [
      if (notes.trim().isNotEmpty) notes.trim(),
      if (clientName != null && clientName.trim().isNotEmpty) 'العميل: ${clientName.trim()}',
    ].join(' | ');

    final newExpense = ExpenseModel(
      id: 'exp_${transId.substring(4)}',
      title: expenseTitle,
      category: type == 'advance' ? 'nurse_advance' : 'nurse_dues',
      amount: amount,
      expenseDate: date,
      paymentChannel: paymentChannel,
      notes: expNotes,
      recordedBy: _currentUser?.username ?? 'wahdan',
      relatedClientId: clientId,
      createdAt: DateTime.now(),
    );

    _expenses.insert(0, newExpense);
    final actTitle = type == 'advance' ? 'تسجيل سلفة تمريض' : 'صرف مستحقات تمريض';
    await _logAction(
      title: actTitle,
      description: 'تم $actTitle للممرض: ${nurseName.trim()} بمبلغ ${amount.toStringAsFixed(0)} ج.م (${_getChannelArabic(paymentChannel)})$clientPart',
      actionType: type == 'advance' ? 'nurse_advance' : 'nurse_payout',
      metadata: {'nurseName': nurseName, 'amount': amount, 'clientId': clientId, 'clientName': clientName},
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
    double grossProfit = 0.0;
    double totalExpenses = 0.0;

    if (customNetProfit != null) {
      profit = customNetProfit;
    } else {
      // 1. Calculate profit strictly from executed service days during the period
      final periodDays = _serviceDays.where((d) =>
          d.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          d.date.isBefore(endDate.add(const Duration(seconds: 1)))).toList();

      grossProfit = periodDays.fold(0.0, (s, d) => s + d.companyDayProfit);

      // If active clients have dates in this cycle not individually logged in _serviceDays, calculate from executed duration
      for (var c in _clients) {
        final clientLogged = periodDays.where((d) => d.clientId == c.id);
        if (clientLogged.isEmpty && c.startDate != null) {
          final cStart = DateTime(c.startDate!.year, c.startDate!.month, c.startDate!.day);
          final cEnd = c.endDate != null ? DateTime(c.endDate!.year, c.endDate!.month, c.endDate!.day) : DateTime.now();
          final effectiveStart = cStart.isAfter(startDate) ? cStart : startDate;
          final effectiveEnd = cEnd.isBefore(endDate) ? cEnd : endDate;
          if (!effectiveStart.isAfter(effectiveEnd)) {
            final days = effectiveEnd.difference(effectiveStart).inDays + 1;
            for (int i = 0; i < days; i++) {
              final cur = effectiveStart.add(Duration(days: i));
              if (c.isActiveOnWeekday(cur.weekday)) {
                grossProfit += (c.dailyPrice - c.nurseDailyPrice);
              }
            }
          }
        }
      }

      // 2. Period operating expenses (excluding partner payouts/loans)
      final periodExpenses = _expenses.where((e) =>
          e.category != 'partner_loan' &&
          e.category != 'partner_settlement' &&
          e.expenseDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          e.expenseDate.isBefore(endDate.add(const Duration(seconds: 1))));

      totalExpenses = periodExpenses.fold(0.0, (s, e) => s + e.amount);

      // Distributable profit strictly decoupled from client collection debt
      profit = (grossProfit - totalExpenses);
      if (profit < 0) {
        profit = 0.0;
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
      'grossProfit': grossProfit,
      'totalExpenses': totalExpenses,
      'totalClientDebts': totalClientDebtsOwedToCompany,
      'totalClientAdvances': totalClientAdvancesHeldByCompany,
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
    String paymentChannel = 'bank', // الخزنة التلقائية الحساب البنكي
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
    final isNurse = _currentUser?.roleType == 'nurse';

    if (_soundAlertsEnabled) {
      if (isNurse) {
        // صوت عالي مميز لرسالة الإدارة لمقدم الخدمة
        SoundService.playAdminMessageSound();
      } else {
        // صوت عالي مخصص للشات الداخلي لحسابات الإدارة
        SoundService.playAdminChatSound();
      }
    }

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isNurse ? const Color(0xFF0F172A) : const Color(0xFF1E1B4B),
          elevation: 10,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isNurse ? const Color(0xFF10B981) : const Color(0xFF818CF8),
              width: 1.5,
            ),
          ),
          duration: const Duration(seconds: 5),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isNurse ? const Color(0xFF10B981) : const Color(0xFF818CF8)).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isNurse ? Icons.lock_outline_rounded : Icons.mark_chat_unread_rounded,
                    color: isNurse ? const Color(0xFF34D399) : const Color(0xFFA5B4FC),
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
                            isNurse
                                ? '✉️ رسالة خاصة جديدة من الإدارة'
                                : (msg.isGroupMessage ? '💬 رسالة في شات الإدارة الداخلي' : '💬 رسالة خاصة جديدة'),
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
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isNurse ? const Color(0xFF34D399) : const Color(0xFFA5B4FC),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // لا تظهر محتويات الرسالة في الإشعار إلا في حالة فتحها (حماية الخصوصية)
                      Text(
                        isNurse
                            ? '🔒 محتوى الرسالة محمي بالخصوصية • اضغط هنا لفتح المحادثة وقراءتها'
                            : 'اضغط لفتح الشات الداخلي وقراءة الرسالة 💬',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: isNurse ? Colors.amber.shade200 : const Color(0xFFCBD5E1),
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

  /// إشعار بصوت عالي لمقدمي الخدمة عند نزول فرصة حالة جديدة
  void _triggerNewCaseOfferAlert(CaseOfferModel offer) {
    if (_soundAlertsEnabled) {
      // صوت عالي احتفالي لفرصة حالة تمريض جديدة
      SoundService.playOpportunitySound();
    }

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF064E3B),
          elevation: 10,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF34D399), width: 1.5),
          ),
          duration: const Duration(seconds: 6),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📢 فرصة وحالة تمريض جديدة متاحة لدى الشركة!',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'حالة: ${offer.title} (${offer.code}) • يومية: ${offer.nurseDailyPrice.toStringAsFixed(0)} ج • ${offer.cityRegion}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Color(0xFFA7F3D0),
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

  /// جلب رسائل جروب عرض الحالات والفرص الجديدة
  List<ChatMessageModel> get casesGroupMessages {
    return _chatMessages.where((m) => m.isCasesGroupMessage).toList();
  }

  /// جلب الرسائل الخاصة مع مستخدم معين
  List<ChatMessageModel> getDirectMessagesWith(String otherUserId, [String? otherUsername]) {
    final myId = _currentUser?.id ?? '';
    final myUser = _currentUser?.username ?? '';
    return _chatMessages.where((m) {
      if (m.isGroupMessage || m.isCasesGroupMessage) return false;
      final sentByMeToOther = (m.senderId == myId || m.senderUsername == myUser) &&
          (m.recipientId == otherUserId || (otherUsername != null && m.recipientId == otherUsername));
      final sentByOtherToMe = (m.senderId == otherUserId || (otherUsername != null && m.senderUsername == otherUsername)) &&
          (m.recipientId == myId || m.recipientId == myUser);
      return sentByMeToOther || sentByOtherToMe;
    }).toList();
  }

  /// جلب كامل سجل محادثة الممرض مع الإدارة (أ/ شيماء وأ/ وهدان)
  List<ChatMessageModel> getNurseDirectMessages(String nurseUserId) {
    return _chatMessages.where((m) {
      if (m.isGroupMessage || m.isCasesGroupMessage) return false;
      if (m.threadId == 'thread_$nurseUserId') return true;
      final involvedWithNurse = m.senderId == nurseUserId || m.recipientId == nurseUserId;
      if (!involvedWithNurse) return false;
      final involvedWithManagement = m.senderId == 'usr_shimaa' ||
          m.recipientId == 'usr_shimaa' ||
          m.senderId == 'usr_wahdan' ||
          m.recipientId == 'usr_wahdan' ||
          m.senderUsername == 'shimaa' ||
          m.recipientId == 'shimaa' ||
          m.senderUsername == 'wahdan' ||
          m.recipientId == 'wahdan' ||
          m.senderRole.contains('مدير') ||
          m.senderRole.contains('متابعة');
      return involvedWithManagement;
    }).toList();
  }

  /// جلب قائمة بكافة غرف المحادثات الخاصة مع التمريض (لـ أ/ شيماء ولـ أ/ وهدان المدير العام)
  List<Map<String, dynamic>> getAllNurseChatThreads() {
    final Map<String, Map<String, dynamic>> threads = {};

    for (var u in _users.where((u) => u.isNurse)) {
      final cg = _caregivers.where((c) => c.id == u.caregiverId || c.phone.trim() == u.phone?.trim() || c.name.trim() == u.displayName.trim()).firstOrNull;
      threads[u.id] = {
        'nurseUserId': u.id,
        'nurseName': u.displayName,
        'nursePhone': u.phone ?? cg?.phone ?? u.username,
        'caregiverCode': cg?.code ?? '',
        'caregiverId': cg?.id ?? '',
        'lastMessage': '',
        'lastMessageTime': DateTime.fromMillisecondsSinceEpoch(0),
        'unreadCount': 0,
      };
    }

    for (var c in _caregivers) {
      final user = _users.where((u) => u.caregiverId == c.id || u.phone?.trim() == c.phone.trim()).firstOrNull;
      final uid = user?.id ?? 'usr_cg_${c.id}';
      if (!threads.containsKey(uid)) {
        threads[uid] = {
          'nurseUserId': uid,
          'nurseName': c.name,
          'nursePhone': c.phone,
          'caregiverCode': c.code,
          'caregiverId': c.id,
          'lastMessage': '',
          'lastMessageTime': c.createdAt,
          'unreadCount': 0,
        };
      }
    }

    for (var m in _chatMessages) {
      if (m.isGroupMessage || m.isCasesGroupMessage) continue;
      String? nurseId;
      if (threads.containsKey(m.senderId)) {
        nurseId = m.senderId;
      } else if (threads.containsKey(m.recipientId)) {
        nurseId = m.recipientId;
      } else if (m.threadId != null && m.threadId!.startsWith('thread_')) {
        nurseId = m.threadId!.replaceFirst('thread_', '');
      }

      if (nurseId != null && threads.containsKey(nurseId)) {
        final t = threads[nurseId]!;
        final curTime = t['lastMessageTime'] as DateTime;
        if (m.timestamp.isAfter(curTime)) {
          t['lastMessage'] = m.text;
          t['lastMessageTime'] = m.timestamp;
        }
      }
    }

    final list = threads.values.toList();
    list.sort((a, b) => (b['lastMessageTime'] as DateTime).compareTo(a['lastMessageTime'] as DateTime));
    return list;
  }

  /// إرسال رسالة جديدة
  Future<void> sendChatMessage({
    required String text,
    String recipientId = 'all',
    String recipientName = 'الجميع',
    String? tag,
    String? relatedClientName,
    String? caseOfferId,
    String? threadId,
    bool isSupervisorAction = false,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final isWahdan = _currentUser?.username == 'wahdan' || _currentUser?.roleType == 'manager';

    final newMsg = ChatMessageModel(
      id: 'msg_${_uuid.v4().substring(0, 8)}',
      senderId: _currentUser?.id ?? 'usr_guest',
      senderUsername: _currentUser?.username ?? 'user',
      senderDisplayName: isWahdan && isSupervisorAction
          ? 'أ/ وهدان (المدير العام) 🛡️'
          : (_currentUser?.displayName ?? 'مستخدم'),
      senderRole: _currentUser?.roleTitle ?? '',
      recipientId: recipientId,
      recipientName: recipientName,
      text: cleanText,
      tag: tag,
      relatedClientName: relatedClientName,
      caseOfferId: caseOfferId,
      threadId: threadId,
      isSupervisorAction: isSupervisorAction || (isWahdan && recipientId != 'all' && recipientId != 'cases_group'),
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
      caseOffers: _caseOffers,
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
  // --- جروب الحالات والفرص الجديدة لمقدمي الخدمة والتمريض ---
  // ==========================================

  /// توليد كود تلقائي للحالة المعروضة (e.g. CASE-001, CASE-002...)
  String generateNextCaseOfferCode() {
    int maxNum = 0;
    for (var o in _caseOffers) {
      final digits = o.code.replaceAll(RegExp(r'[^0-9]'), '');
      final n = int.tryParse(digits);
      if (n != null && n > maxNum) {
        maxNum = n;
      }
    }
    final nextNum = maxNum + 1;
    return 'CASE-${nextNum.toString().padLeft(3, '0')}';
  }

  /// نشر حالة جديدة في جروب الفرص بواسطة أ/ شيماء أو الإدارة
  Future<void> addCaseOffer({
    required String title,
    required String patientDescription,
    required String city,
    required String area,
    String shiftType = 'hours12',
    required double nurseDailyPrice,
    String genderPreference = 'any',
    String requirements = '',
    String clientName = '',
    String clientPhone = '',
    double clientDailyPrice = 0.0,
    String? notes,
  }) async {
    final nextCode = generateNextCaseOfferCode();
    final newOffer = CaseOfferModel(
      id: 'case_${_uuid.v4().substring(0, 8)}',
      code: nextCode,
      title: title.trim(),
      patientDescription: patientDescription.trim(),
      city: city.trim(),
      area: area.trim(),
      shiftType: shiftType,
      nurseDailyPrice: nurseDailyPrice,
      genderPreference: genderPreference,
      requirements: requirements.trim(),
      clientName: clientName.trim(),
      clientPhone: clientPhone.trim(),
      clientDailyPrice: clientDailyPrice,
      status: 'open',
      postedByUserId: _currentUser?.id ?? 'usr_shimaa',
      postedByUserName: _currentUser?.displayName ?? 'أ/ شيماء',
      createdAt: DateTime.now(),
      notes: notes?.trim(),
    );

    _knownCaseOfferIds.add(newOffer.id);
    _caseOffers.insert(0, newOffer);

    // بث رسالة إعلان تلقائية في جروب الحالات المتاح للتمريض
    final announcementText = '📢 فرصة وحالة تمريض جديدة متاحة:\n'
        '• الحالة: ${newOffer.title} ($nextCode)\n'
        '• المنطقة: ${newOffer.city} - ${newOffer.area}\n'
        '• نوع الوردية: ${newOffer.shiftTypeArabic}\n'
        '• سعر التمريض اليومي: ${newOffer.nurseDailyPrice.toStringAsFixed(0)} ج.م\n'
        '• وصف الحالة: ${newOffer.patientDescription}\n'
        '👉 لمن يناسبه السعر والقدرة على التنفيذ، اضغط تقديم أو راسل أ/ شيماء على الخاص 💬';

    final announceMsg = ChatMessageModel(
      id: 'msg_${_uuid.v4().substring(0, 8)}',
      senderId: _currentUser?.id ?? 'usr_shimaa',
      senderUsername: _currentUser?.username ?? 'shimaa',
      senderDisplayName: _currentUser?.displayName ?? 'أ/ شيماء',
      senderRole: _currentUser?.roleTitle ?? 'مديرة المتابعة والتشغيل',
      recipientId: 'cases_group',
      recipientName: 'جروب الحالات والفرص',
      text: announcementText,
      tag: 'case_offer',
      caseOfferId: newOffer.id,
      timestamp: DateTime.now(),
    );
    _knownChatMessageIds.add(announceMsg.id);
    _chatMessages.add(announceMsg);

    await _logAction(
      title: 'نشر حالة جديدة في جروب الفرص',
      description: '${_currentUser?.displayName ?? "الإدارة"} قامت بنشر حالة: ${newOffer.title} ($nextCode) بسعر تمريض: ${newOffer.nurseDailyPrice.toStringAsFixed(0)} ج',
      actionType: 'case_offer_post',
      metadata: {'caseOfferId': newOffer.id, 'title': newOffer.title},
    );

    await _persistAndSync();
  }

  /// تعديل بيانات حالة معروضة
  Future<void> updateCaseOffer(CaseOfferModel updated) async {
    final idx = _caseOffers.indexWhere((o) => o.id == updated.id);
    if (idx != -1) {
      _caseOffers[idx] = updated.copyWith(updatedAt: DateTime.now());
      await _logAction(
        title: 'تعديل حالة في جروب الفرص',
        description: 'تم تعديل بيانات الحالة: ${updated.title} (${updated.code})',
        actionType: 'case_offer_edit',
        metadata: {'caseOfferId': updated.id},
      );
      await _persistAndSync();
    }
  }

  /// حذف حالة معروضة
  Future<void> deleteCaseOffer(String id) async {
    final removed = _caseOffers.where((o) => o.id == id).firstOrNull;
    if (removed != null) {
      _caseOffers.removeWhere((o) => o.id == id);
      _deletedIds.add(id);
      await _logAction(
        title: 'حذف حالة من جروب الفرص',
        description: 'تم حذف الحالة: ${removed.title} (${removed.code})',
        actionType: 'case_offer_delete',
        metadata: {'caseOfferId': id},
      );
      await _persistAndSync();
    }
  }

  /// تقديم مقدم الخدمة على الحالة وإرسال رسالة خاصة فورية لـ أ/ شيماء
  Future<void> applyForCaseOffer({
    required String caseOfferId,
    required String notes,
  }) async {
    final idx = _caseOffers.indexWhere((o) => o.id == caseOfferId);
    if (idx == -1) throw 'الحالة المعروضة غير موجودة أو تم حذفها';

    final offer = _caseOffers[idx];
    final cg = currentNurseCaregiver;
    final nurseUser = _currentUser;
    final nurseName = cg?.name ?? nurseUser?.displayName ?? 'مقدم خدمة';
    final nurseId = cg?.id ?? nurseUser?.caregiverId ?? nurseUser?.id ?? 'cg_temp';
    final nursePhone = cg?.phone ?? nurseUser?.phone ?? nurseUser?.username ?? '';
    final nurseUserId = nurseUser?.id ?? 'usr_cg_$nurseId';

    if (offer.applicants.any((a) => a.caregiverId == nurseId || a.nurseUserId == nurseUserId)) {
      throw 'لقد تقدمت بالفعل لهذه الحالة من قبل';
    }

    final newApplicant = CaseApplicantModel(
      caregiverId: nurseId,
      caregiverName: nurseName,
      caregiverCode: cg?.code ?? '',
      phone: nursePhone,
      nurseUserId: nurseUserId,
      appliedAt: DateTime.now(),
      notes: notes.trim(),
      status: 'applied',
    );

    final updatedApplicants = List<CaseApplicantModel>.from(offer.applicants)..add(newApplicant);
    _caseOffers[idx] = offer.copyWith(
      applicants: updatedApplicants,
      status: offer.status == 'open' ? 'open' : offer.status,
      updatedAt: DateTime.now(),
    );

    // إرسال رسالة شات خاص تلقائية ومباشرة لـ أ/ شيماء
    final directMessageText = 'السلام عليكم أ/ شيماء، أنا موافق وجاهز لتنفيذ حالة: [${offer.title} - ${offer.area}] بسعر ${offer.nurseDailyPrice.toStringAsFixed(0)} ج.م/يوم.'
        '${notes.trim().isNotEmpty ? '\nملاحظاتي: ${notes.trim()}' : ''}';

    final privateMsg = ChatMessageModel(
      id: 'msg_${_uuid.v4().substring(0, 8)}',
      senderId: nurseUserId,
      senderUsername: nurseUser?.username ?? nursePhone,
      senderDisplayName: nurseName,
      senderRole: 'طاقم تمريض / مقدم خدمة',
      recipientId: 'usr_shimaa',
      recipientName: 'أ/ شيماء',
      text: directMessageText,
      tag: 'case_offer',
      caseOfferId: offer.id,
      threadId: 'thread_$nurseUserId',
      timestamp: DateTime.now(),
    );
    _knownChatMessageIds.add(privateMsg.id);
    _chatMessages.add(privateMsg);

    await _logAction(
      title: 'طلب تنفيذ حالة (شات خاص)',
      description: 'الممرض $nurseName تقدم لتنفيذ حالة: ${offer.title} (${offer.code}) وراسل أ/ شيماء على الخاص',
      actionType: 'case_applicant',
      metadata: {'caseOfferId': offer.id, 'caregiverName': nurseName, 'caregiverId': nurseId},
    );

    await _persistAndSync();
  }

  /// إتمام الحالة هاتفياً بواسطة أ/ زيزو وتسكين الممرض المختار وتحويلها لعميل نشط
  Future<void> finalizeCaseWithZezo({
    required String caseOfferId,
    required String selectedCaregiverId,
    required double clientDailyPrice,
    required double nurseDailyPrice,
    DateTime? startDate,
    String? agreementNotes,
  }) async {
    final idx = _caseOffers.indexWhere((o) => o.id == caseOfferId);
    if (idx == -1) throw 'الحالة غير موجودة';

    final offer = _caseOffers[idx];
    CaregiverModel? selectedCaregiver = _caregivers.where((c) => c.id == selectedCaregiverId).firstOrNull;
    if (selectedCaregiver == null) {
      final app = offer.applicants.where((a) => a.caregiverId == selectedCaregiverId || a.nurseUserId == selectedCaregiverId).firstOrNull;
      if (app != null) {
        selectedCaregiver = findCaregiverByName(app.caregiverName);
      }
    }
    final caregiverName = selectedCaregiver?.name ?? 'مقدم الخدمة';

    final effectiveClientPrice = clientDailyPrice > 0 ? clientDailyPrice : offer.clientDailyPrice;
    final effectiveNursePrice = nurseDailyPrice > 0 ? nurseDailyPrice : (selectedCaregiver?.dailyPrice ?? offer.nurseDailyPrice);
    final effectiveStartDate = startDate ?? DateTime.now();

    // 1. إنشاء العميل الجديد في قاعدة العملاء
    final newClient = ClientModel(
      id: 'cli_${_uuid.v4().substring(0, 8)}',
      name: offer.clientName.trim().isNotEmpty ? offer.clientName.trim() : offer.title,
      phone: offer.clientPhone.trim(),
      address: '${offer.city} - ${offer.area}'.trim(),
      healthCondition: offer.patientDescription,
      serviceType: offer.shiftType,
      dailyPrice: effectiveClientPrice,
      nurseDailyPrice: effectiveNursePrice,
      nurseAssigned: caregiverName,
      startDate: effectiveStartDate,
      status: 'active',
      notes: 'تم إتمام الحالة تليفونياً بواسطة أ/ زيزو وتسكين الممرض: $caregiverName. ${agreementNotes ?? ''}'.trim(),
      createdBy: _currentUser?.username ?? 'zezo',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _clients.insert(0, newClient);

    // 2. تحديث حالة الممرض في قاعدة مقدمي الخدمة
    if (selectedCaregiver != null) {
      final cgIdx = _caregivers.indexWhere((c) => c.id == selectedCaregiver!.id);
      if (cgIdx != -1) {
        final past = List<String>.from(_caregivers[cgIdx].pastClients);
        if (!past.contains(newClient.name)) past.add(newClient.name);
        _caregivers[cgIdx] = _caregivers[cgIdx].copyWith(
          isCurrentlyWorking: true,
          currentClientName: newClient.name,
          pastClients: past,
          hasWorkedWithUs: true,
          updatedAt: DateTime.now(),
        );
      }
    }

    // 3. تحديث حالة عرض الحالة إلى تم التسكين والإتمام
    final updatedApplicants = offer.applicants.map((a) {
      if (a.caregiverId == selectedCaregiverId || a.nurseUserId == selectedCaregiverId || a.caregiverName == caregiverName) {
        return a.copyWith(status: 'approved');
      }
      return a.copyWith(status: 'contacted');
    }).toList();

    _caseOffers[idx] = offer.copyWith(
      status: 'assigned',
      assignedCaregiverId: selectedCaregiver?.id ?? selectedCaregiverId,
      assignedCaregiverName: caregiverName,
      assignedAt: DateTime.now(),
      clientDailyPrice: effectiveClientPrice,
      nurseDailyPrice: effectiveNursePrice,
      applicants: updatedApplicants,
      updatedAt: DateTime.now(),
    );

    // 4. إرسال رسالة شات تهنئة وتأكيد للممرض في شاته الخاص
    final applicantUser = _users.where((u) => u.caregiverId == selectedCaregiver?.id || u.displayName.trim() == caregiverName.trim() || u.id == selectedCaregiverId).firstOrNull;
    final nurseTargetId = applicantUser?.id ?? 'usr_cg_${selectedCaregiver?.id ?? selectedCaregiverId}';

    final confirmChatMsg = ChatMessageModel(
      id: 'msg_${_uuid.v4().substring(0, 8)}',
      senderId: _currentUser?.id ?? 'usr_zezo',
      senderUsername: _currentUser?.username ?? 'zezo',
      senderDisplayName: 'أ/ زيزو (مدير الحسابات والمالية)',
      senderRole: 'مدير الحسابات والمالية',
      recipientId: nurseTargetId,
      recipientName: caregiverName,
      text: '🎉 مبروك يا $caregiverName! تم إتمام الاتفاق تليفونياً مع العميل وتسكينك رسمياً لحالة: ${newClient.name} (${newClient.address}) بسعر يومية ${effectiveNursePrice.toStringAsFixed(0)} ج.م. يمكنك الآن متابعة تفاصيل الحالة وبدء تسجيل حضور الوردية من بوابتك.',
      tag: 'case_offer',
      caseOfferId: offer.id,
      threadId: 'thread_$nurseTargetId',
      timestamp: DateTime.now(),
    );
    _knownChatMessageIds.add(confirmChatMsg.id);
    _chatMessages.add(confirmChatMsg);

    await _logAction(
      title: 'إتمام حالة وتسكين ممرض',
      description: 'أ/ زيزو قام بإتمام الاتفاق هاتفياً مع عميل حالة: ${newClient.name} وتسكين الممرض: $caregiverName بنجاح',
      actionType: 'finalize_case',
      metadata: {'clientId': newClient.id, 'clientName': newClient.name, 'nurseName': caregiverName},
    );

    await _persistAndSync();
  }

  // ==========================================
  // --- Management Instructions (لوحة تعليمات وتوجيهات الإدارة لمقدمي الخدمة) ---
  // ==========================================

  /// إضافة لائحة تعليمات وتوجيهات جديدة من الإدارة
  Future<void> addManagementInstruction({
    required String title,
    required String content,
    String priority = 'important',
  }) async {
    final author = _currentUser?.displayName ?? 'الإدارة';
    final role = _currentUser?.roleTitle ?? 'المدير العام';
    final newInst = ManagementInstructionModel(
      id: 'inst_${_uuid.v4().substring(0, 8)}',
      title: title.trim(),
      content: content.trim(),
      authorName: author,
      authorRole: role,
      priority: priority,
      createdAt: DateTime.now(),
    );

    _knownInstructionIds.add(newInst.id);
    _managementInstructions.insert(0, newInst);
    await storageService.saveManagementInstructions(_managementInstructions);

    await _logAction(
      title: 'إصدار لائحة تعليمات إدارية',
      description: '$author قام بنشر لائحة تعليمات جديدة: $title',
      actionType: 'instruction_publish',
      metadata: {'instructionId': newInst.id, 'title': title},
    );

    await _persistAndSync();
  }

  /// تعديل لائحة تعليمات
  Future<void> updateManagementInstruction(ManagementInstructionModel updated) async {
    final idx = _managementInstructions.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      _managementInstructions[idx] = updated.copyWith(updatedAt: DateTime.now());
      await storageService.saveManagementInstructions(_managementInstructions);
      await _persistAndSync();
    }
  }

  /// تفعيل أو تعطيل لائحة تعليمات
  Future<void> toggleManagementInstructionActive(String id, bool isActive) async {
    final idx = _managementInstructions.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _managementInstructions[idx] = _managementInstructions[idx].copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      await storageService.saveManagementInstructions(_managementInstructions);
      await _persistAndSync();
    }
  }

  /// حذف لائحة تعليمات
  Future<void> deleteManagementInstruction(String id) async {
    final removed = _managementInstructions.where((i) => i.id == id).firstOrNull;
    if (removed != null) {
      _managementInstructions.removeWhere((i) => i.id == id);
      _deletedIds.add(id);
      await storageService.saveDeletedIds(_deletedIds);
      await storageService.saveManagementInstructions(_managementInstructions);
      await _logAction(
        title: 'حذف لائحة تعليمات',
        description: '${_currentUser?.displayName ?? "الإدارة"} قام بحذف لائحة: ${removed.title}',
        actionType: 'instruction_delete',
        metadata: {'instructionId': id},
      );
      await _persistAndSync();
    }
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

  /// البحث عن مقدم خدمة بالاسم (مع دعم البحث الذكي والتطابق الجزئي والكود)
  CaregiverModel? findCaregiverByName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return null;
    try {
      return _caregivers.firstWhere(
        (c) => isNurseNameMatch(c.name, clean) || isNurseNameMatch(c.code, clean),
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
        (c) => c.code.trim().toLowerCase() == clean || isNurseNameMatch(c.name, clean),
      );
    } catch (_) {
      return null;
    }
  }

  /// الحالة الحالية التي يعمل بها مقدم الخدمة الآن
  String? getCaregiverCurrentCase(String caregiverName) {
    final clean = caregiverName.trim();
    if (clean.isEmpty) return null;

    // 1. أولاً نبحث في العملاء النشطين (active أو ready_to_start)
    for (var client in _clients) {
      if ((client.status == 'active' || client.status == 'ready_to_start') &&
          isNurseNameMatch(client.nurseAssigned, clean)) {
        return client.name;
      }
    }

    // 2. التحقق من الورديات المسجلة خلال آخر 3 أيام لعملاء نشطين
    for (var client in activeClients) {
      final shifts = getClientServiceDays(client.id);
      if (shifts.isNotEmpty) {
        final recentShift = shifts.first;
        if (isNurseNameMatch(recentShift.nurseName, clean) &&
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
    final clean = caregiverName.trim();
    if (clean.isEmpty) return [];

    // من الورديات المسجلة فعلياً في النظام
    for (var d in _serviceDays) {
      if (isNurseNameMatch(d.nurseName, clean)) {
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

  /// تحديث الموقع الجغرافي الحي لمقدم الخدمة (يُستدعى تلقائياً عند فتح البوابة وبشكل دوري)
  Future<void> updateCaregiverLiveLocation({
    required String caregiverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    String source = 'nurse_phone',
  }) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId);
    if (idx != -1) {
      _caregivers[idx] = _caregivers[idx].copyWith(
        lastLatitude: latitude,
        lastLongitude: longitude,
        lastLocationAccuracy: accuracy,
        lastLocationUpdate: DateTime.now(),
        lastLocationSource: source,
      );
      await storageService.saveCaregivers(_caregivers);
      notifyListeners();
    }
  }

  /// مسح جميع إحداثيات المواقع القديمة التي قد تكون سُجلت من أجهزة الإدارة لجميع الممرضين
  Future<void> clearAllUnverifiedCaregiverLocations() async {
    bool changed = false;
    for (var i = 0; i < _caregivers.length; i++) {
      if (_caregivers[i].hasLocation && _caregivers[i].lastLocationSource != 'shift_checkin' && _caregivers[i].lastLocationSource != 'shift_checkout') {
        _caregivers[i] = _caregivers[i].clearLocation();
        changed = true;
      }
    }
    if (changed) {
      await storageService.saveCaregivers(_caregivers);
      notifyListeners();
    }
  }

  /// مسح وإلغاء إحداثيات الـ GPS لمقدم الخدمة (لحذف أي إحداثيات تم تسجيلها بالخطأ أو من كمبيوتر الإدارة)
  Future<void> clearCaregiverLocation(String caregiverId) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId);
    if (idx != -1) {
      _caregivers[idx] = _caregivers[idx].clearLocation();
      await storageService.saveCaregivers(_caregivers);
      notifyListeners();
    }
  }

  /// تعيين موقع جغرافي يدوياً لمقدم الخدمة (من قبل الإدارة)
  Future<void> setCaregiverManualLocation({
    required String caregiverId,
    required double latitude,
    required double longitude,
    double accuracy = 10.0,
  }) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId);
    if (idx != -1) {
      _caregivers[idx] = _caregivers[idx].copyWith(
        lastLatitude: latitude,
        lastLongitude: longitude,
        lastLocationAccuracy: accuracy,
        lastLocationUpdate: DateTime.now(),
      );
      await storageService.saveCaregivers(_caregivers);
      notifyListeners();
    }
  }

  // ==========================================
  // إمكانات وبوابة التمريض ورسائل الـ SMS
  // ==========================================

  /// هل المستخدم الحالي هو ممرض / مقدم خدمة
  bool get isNurse => _currentUser?.roleType == 'nurse';

  /// سجل الممرض المرتبط بالمستخدم الحالي
  CaregiverModel? get currentNurseCaregiver {
    if (!isNurse || _currentUser == null) return null;
    if (_currentUser!.caregiverId != null) {
      final cg = _caregivers.where((c) => c.id == _currentUser!.caregiverId).toList();
      if (cg.isNotEmpty) return cg.first;
    }
    final byName = _caregivers.where((c) => isNurseNameMatch(c.name, _currentUser!.displayName)).toList();
    if (byName.isNotEmpty) return byName.first;

    // Fallback ديناميكي لضمان عمل البوابة بسلاسة حتى لو لم يتم تحميل قائمة الكوادر بعد
    return CaregiverModel(
      id: _currentUser!.caregiverId ?? 'cg_${_currentUser!.id}',
      code: _currentUser!.username.toUpperCase(),
      name: _currentUser!.displayName,
      phone: _currentUser!.phone ?? '',
      dailyPrice: 700.0,
      hasLoginAccount: true,
      loginUsername: _currentUser!.username,
      isCurrentlyWorking: true,
    );
  }

  /// الحالة النشطة المكلف بها الممرض حالياً
  ClientModel? get currentNurseActiveClient {
    final cg = currentNurseCaregiver;
    if (cg == null) return null;
    final assigned = _clients.where((c) {
      final isAssigned = isNurseNameMatch(c.nurseAssigned, cg.name) ||
          isNurseNameMatch(c.nurseAssigned, cg.code);
      final isActive = c.status == 'active' || c.status == 'ready_to_start';
      return isAssigned && isActive;
    }).toList();
    if (assigned.isNotEmpty) return assigned.first;
    return null;
  }

  /// جميع الحالات المسندة للممرض الحالي (الحالية والسابقة)
  List<ClientModel> get currentNurseAllAssignedClients {
    final cg = currentNurseCaregiver;
    if (cg == null) return [];
    return _clients.where((c) {
      return isNurseNameMatch(c.nurseAssigned, cg.name) ||
          isNurseNameMatch(c.nurseAssigned, cg.code);
    }).toList();
  }

  /// كشف ورديات الممرض الحالي
  List<ServiceDayModel> get currentNurseShifts {
    final cg = currentNurseCaregiver;
    if (cg == null) return [];
    return getNurseShifts(cg.name);
  }

  /// كشف سلف ومعاملات الممرض الحالي
  List<NurseTransactionModel> get currentNurseTransactions {
    final cg = currentNurseCaregiver;
    if (cg == null) return [];
    return getNurseTransactions(cg.name);
  }

  /// إجمالي المستحقات المكتسبة للممرض الحالي
  double get currentNurseTotalEarned {
    final cg = currentNurseCaregiver;
    if (cg == null) return 0.0;
    return getNurseTotalEarned(cg.name);
  }

  /// إجمالي السلف التي استلمها الممرض الحالي
  double get currentNurseTotalAdvances {
    final cg = currentNurseCaregiver;
    if (cg == null) return 0.0;
    return getNurseTotalAdvances(cg.name);
  }

  /// إجمالي المبالغ المنصرفة للممرض الحالي
  double get currentNurseTotalPayouts {
    final cg = currentNurseCaregiver;
    if (cg == null) return 0.0;
    return getNurseTotalPayouts(cg.name);
  }

  /// الرصيد الصافي المتبقي للممرض الحالي طرف الشركة
  double get currentNurseRemainingBalance {
    final cg = currentNurseCaregiver;
    if (cg == null) return 0.0;
    return getNurseRemainingBalance(cg.name);
  }

  /// إعدادات بوابة SMS
  String? get smsGatewayEndpoint => storageService.getSmsGatewayEndpoint();
  Future<void> setSmsGatewayEndpoint(String? endpoint) async {
    await storageService.setSmsGatewayEndpoint(endpoint);
    notifyListeners();
  }

  /// البحث عن حساب المستخدم المرتبط بمقدم خدمة معين
  UserModel? getNurseUserForCaregiver(String caregiverId) {
    final users = _users.where((u) => u.caregiverId == caregiverId).toList();
    return users.isNotEmpty ? users.first : null;
  }

  /// إنشاء أو تحديث حساب دخول للممرض مع إرسال SMS
  Future<bool> createOrUpdateNurseAccount({
    required CaregiverModel caregiver,
    required String username,
    required String password,
    bool sendSms = true,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      return false;
    }

    // فحص ما إذا كان اسم المستخدم مستخدم لشخص آخر
    final existingUserIndex = _users.indexWhere(
      (u) => u.username.toLowerCase() == cleanUsername.toLowerCase() && u.caregiverId != caregiver.id,
    );
    if (existingUserIndex != -1) {
      throw 'اسم المستخدم مستخدم بالفعل لحساب آخر، يرجى اختيار اسم مستخدم مختلف.';
    }

    // العثور على حساب الممرض أو إنشائه
    final userIdx = _users.indexWhere(
      (u) => u.caregiverId == caregiver.id || u.username.toLowerCase() == cleanUsername.toLowerCase(),
    );

    if (userIdx != -1) {
      _users[userIdx] = _users[userIdx].copyWith(
        username: cleanUsername,
        password: cleanPassword,
        displayName: caregiver.name,
        roleTitle: 'طاقم تمريض / مقدم خدمة',
        roleType: 'nurse',
        caregiverId: caregiver.id,
        phone: caregiver.phone,
      );
    } else {
      final newUserId = 'usr_cg_${caregiver.id}';
      final newUser = UserModel(
        id: newUserId,
        username: cleanUsername,
        password: cleanPassword,
        displayName: caregiver.name,
        roleTitle: 'طاقم تمريض / مقدم خدمة',
        roleType: 'nurse',
        caregiverId: caregiver.id,
        phone: caregiver.phone,
        permissions: const UserPermissions(),
      );
      _users.add(newUser);
    }

    // تحديث ملف مقدم الخدمة
    final cgIdx = _caregivers.indexWhere((c) => c.id == caregiver.id);
    if (cgIdx != -1) {
      _caregivers[cgIdx] = _caregivers[cgIdx].copyWith(
        hasLoginAccount: true,
        loginUsername: cleanUsername,
        loginPassword: cleanPassword,
        lastSmsSentAt: sendSms ? DateTime.now() : _caregivers[cgIdx].lastSmsSentAt,
      );
    }

    await storageService.saveUsers(_users);
    await storageService.saveCaregivers(_caregivers);

    // إرسال SMS تلقائي للممرض
    if (sendSms && caregiver.phone.trim().isNotEmpty) {
      await SmsService.sendNurseCredentials(
        phone: caregiver.phone.trim(),
        nurseName: caregiver.name,
        username: cleanUsername,
        password: cleanPassword,
        customGatewayUrl: storageService.getSmsGatewayEndpoint(),
      );
    }

    await _logAction(
      title: 'حساب تمريض ورسالة SMS',
      description: 'تم تفعيل حساب النظام للممرض: ${caregiver.name} (اسم المستخدم: $cleanUsername) ${sendSms ? "وإرسال رسالة SMS" : ""}',
      actionType: 'nurse_account',
    );

    SoundService.playNotificationSound();
    await _persistAndSync();
    notifyListeners();
    return true;
  }

  /// إعادة إرسال رسالة SMS ببيانات الدخول للممرض
  Future<SmsResult> resendNurseCredentialsSms(CaregiverModel caregiver) async {
    final username = caregiver.loginUsername ?? caregiver.phone;
    final password = caregiver.loginPassword ?? '123';

    final result = await SmsService.sendNurseCredentials(
      phone: caregiver.phone.trim(),
      nurseName: caregiver.name,
      username: username,
      password: password,
      customGatewayUrl: storageService.getSmsGatewayEndpoint(),
    );

    final cgIdx = _caregivers.indexWhere((c) => c.id == caregiver.id);
    if (cgIdx != -1) {
      _caregivers[cgIdx] = _caregivers[cgIdx].copyWith(
        lastSmsSentAt: DateTime.now(),
      );
      await storageService.saveCaregivers(_caregivers);
    }

    await _logAction(
      title: 'إرسال SMS للممرض',
      description: 'تم إرسال رسالة SMS ببيانات الدخول للممرض: ${caregiver.name} على الهاتف: ${caregiver.phone}',
      actionType: 'nurse_sms',
    );

    SoundService.playNotificationSound();
    notifyListeners();
    return result;
  }

  /// تعطيل أو حذف حساب الممرض
  Future<void> deleteNurseAccount(String caregiverId) async {
    _users.removeWhere((u) => u.caregiverId == caregiverId);
    final cgIdx = _caregivers.indexWhere((c) => c.id == caregiverId);
    if (cgIdx != -1) {
      _caregivers[cgIdx] = _caregivers[cgIdx].copyWith(
        hasLoginAccount: false,
        loginUsername: null,
        loginPassword: null,
      );
    }
    await storageService.saveUsers(_users);
    await storageService.saveCaregivers(_caregivers);
    await _persistAndSync();
    notifyListeners();
  }

  /// تسجيل الممرض لحضور ورديته من خلال بوابته الخاصة
  Future<void> nurseRecordShiftAttendance({
    required String clientId,
    required DateTime date,
    required String shiftType,
    required String startTime,
    required String endTime,
    double? hoursCount,
    required String notes,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkInAccuracy,
    DateTime? checkInAt,
  }) async {
    final cg = currentNurseCaregiver;
    if (cg == null) throw 'لا يمكن التعرف على حساب الممرض الحالي';

    final client = _clients.firstWhere(
      (c) => c.id == clientId,
      orElse: () => throw 'الحالة غير مسجلة بالنظام',
    );

    // اليومية المستحقة للممرض
    final double nurseRate = client.nurseDailyPrice > 0 ? client.nurseDailyPrice : cg.dailyPrice;
    // سعر العميل يحفظ داخلياً للشركة ولا يظهر للممرض نهائياً
    final double clientRate = client.dailyPrice;

    await recordServiceDay(
      clientId: clientId,
      date: date,
      nurseName: cg.name,
      shiftType: shiftType,
      clientPrice: clientRate,
      nursePrice: nurseRate,
      notes: notes,
      startTime: startTime,
      endTime: endTime,
      hoursCount: hoursCount,
      checkInLatitude: checkInLatitude,
      checkInLongitude: checkInLongitude,
      checkInAccuracy: checkInAccuracy,
      checkInAt: checkInAt,
    );

    if (checkInLatitude != null && checkInLongitude != null) {
      await updateCaregiverLiveLocation(
        caregiverId: cg.id,
        latitude: checkInLatitude,
        longitude: checkInLongitude,
        accuracy: checkInAccuracy,
        source: 'shift_checkin',
      );
    }
  }
}
