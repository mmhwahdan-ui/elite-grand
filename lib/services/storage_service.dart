import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/payment_model.dart';
import '../models/expense_model.dart';
import '../models/service_day_model.dart';
import '../models/nurse_transaction_model.dart';
import '../models/partner_loan_model.dart';
import '../models/partner_settlement_model.dart';
import '../models/app_notification_model.dart';
import '../models/caregiver_model.dart';
import '../models/chat_message_model.dart';
import '../models/case_offer_model.dart';
import '../models/management_instruction_model.dart';

class StorageService {
  static const String _keyUsers = 'eg_users_data';
  static const String _keyClients = 'eg_clients_data';
  static const String _keyPayments = 'eg_payments_data';
  static const String _keyExpenses = 'eg_expenses_data';
  static const String _keyCurrentUser = 'eg_current_user_id';
  static const String _keyCloudEndpoint = 'eg_cloud_endpoint';
  static const String _keySmsGatewayEndpoint = 'eg_sms_gateway_endpoint';
  static const String _keyLastSync = 'eg_last_sync_time';
  static const String _keyDeletedIds = 'eg_deleted_ids';
  static const String _keyOpeningBalances = 'eg_opening_balances';
  static const String _keyServiceDays = 'eg_service_days_data';
  static const String _keyNurseTransactions = 'eg_nurse_transactions_data';
  static const String _keyPartnerLoans = 'eg_partner_loans_data';
  static const String _keyPartnerSettlements = 'eg_partner_settlements_data';
  static const String _keyNotifications = 'eg_notifications_data';
  static const String _keyCaregivers = 'eg_caregivers_data';
  static const String _keyChatMessages = 'eg_chat_messages_data';
  static const String _keyCaseOffers = 'eg_case_offers_data';
  static const String _keyManagementInstructions = 'eg_management_instructions_data';
  static const String _keyLastThursdayAlertDate = 'eg_last_thursday_alert_date';
  static const String _keyPendingOfflineSync = 'eg_pending_offline_sync';
  static const String _keyCompanyName = 'eg_company_name';
  static const String _keyCompanySubtitle = 'eg_company_subtitle';
  static const String _keyCompanyLogoUrl = 'eg_company_logo_url';

  final SharedPreferences prefs;

  StorageService(this.prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Opening Balances (Bank & Wallet & Cash)
  Map<String, double> loadOpeningBalances() {
    final jsonStr = prefs.getString(_keyOpeningBalances);
    if (jsonStr == null || jsonStr.isEmpty) {
      return {'bank': 0.0, 'wallet': 0.0, 'cash': 0.0};
    }
    try {
      final Map decoded = jsonDecode(jsonStr);
      return {
        'bank': (decoded['bank'] as num?)?.toDouble() ?? 0.0,
        'wallet': (decoded['wallet'] as num?)?.toDouble() ?? 0.0,
        'cash': (decoded['cash'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (_) {
      return {'bank': 0.0, 'wallet': 0.0, 'cash': 0.0};
    }
  }

  Future<void> saveOpeningBalances(Map<String, double> balances) async {
    await prefs.setString(_keyOpeningBalances, jsonEncode(balances));
  }

  // Company Branding & Customization
  String loadCompanyName() {
    return prefs.getString(_keyCompanyName) ?? 'إيليت هوم كير';
  }

  String loadCompanySubtitle() {
    return prefs.getString(_keyCompanySubtitle) ?? 'تمريض منزلي ورعاية صحية متكاملة';
  }

  String? loadCompanyLogoUrl() {
    return prefs.getString(_keyCompanyLogoUrl);
  }

  Future<void> saveCompanyInfo(String name, String subtitle, String? logoUrl) async {
    await prefs.setString(_keyCompanyName, name);
    await prefs.setString(_keyCompanySubtitle, subtitle);
    if (logoUrl != null && logoUrl.isNotEmpty) {
      await prefs.setString(_keyCompanyLogoUrl, logoUrl);
    } else {
      await prefs.remove(_keyCompanyLogoUrl);
    }
  }

  // Deleted IDs for distributed sync tombstones
  List<String> loadDeletedIds() {
    return prefs.getStringList(_keyDeletedIds) ?? [];
  }

  Future<void> saveDeletedIds(List<String> ids) async {
    await prefs.setStringList(_keyDeletedIds, ids);
  }

  // Current User
  String? getCurrentUserId() {
    return prefs.getString(_keyCurrentUser);
  }

  Future<void> setCurrentUserId(String? userId) async {
    if (userId == null) {
      await prefs.remove(_keyCurrentUser);
    } else {
      await prefs.setString(_keyCurrentUser, userId);
    }
  }

  // Cloud endpoint
  String? getCloudEndpoint() {
    return prefs.getString(_keyCloudEndpoint);
  }

  Future<void> setCloudEndpoint(String endpoint) async {
    await prefs.setString(_keyCloudEndpoint, endpoint);
  }

  // SMS Gateway endpoint
  String? getSmsGatewayEndpoint() {
    return prefs.getString(_keySmsGatewayEndpoint);
  }

  Future<void> setSmsGatewayEndpoint(String? endpoint) async {
    if (endpoint == null || endpoint.trim().isEmpty) {
      await prefs.remove(_keySmsGatewayEndpoint);
    } else {
      await prefs.setString(_keySmsGatewayEndpoint, endpoint.trim());
    }
  }

  // Last Sync Time
  DateTime? getLastSyncTime() {
    final str = prefs.getString(_keyLastSync);
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await prefs.setString(_keyLastSync, time.toIso8601String());
  }

  // Users
  List<UserModel> loadUsers() {
    final jsonStr = prefs.getString(_keyUsers);
    if (jsonStr == null || jsonStr.isEmpty) {
      return UserModel.getDefaultUsers();
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => UserModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return UserModel.getDefaultUsers();
    }
  }

  Future<void> saveUsers(List<UserModel> users) async {
    final data = users.map((u) => u.toMap()).toList();
    await prefs.setString(_keyUsers, jsonEncode(data));
  }

  // Clients
  List<ClientModel> loadClients() {
    final jsonStr = prefs.getString(_keyClients);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => ClientModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveClients(List<ClientModel> clients) async {
    final data = clients.map((c) => c.toMap()).toList();
    await prefs.setString(_keyClients, jsonEncode(data));
  }

  // Payments
  List<PaymentModel> loadPayments() {
    final jsonStr = prefs.getString(_keyPayments);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => PaymentModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePayments(List<PaymentModel> payments) async {
    final data = payments.map((p) => p.toMap()).toList();
    await prefs.setString(_keyPayments, jsonEncode(data));
  }

  // Expenses
  List<ExpenseModel> loadExpenses() {
    final jsonStr = prefs.getString(_keyExpenses);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => ExpenseModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExpenses(List<ExpenseModel> expenses) async {
    final data = expenses.map((e) => e.toMap()).toList();
    await prefs.setString(_keyExpenses, jsonEncode(data));
  }

  // Service Days (أيام الخدمة والشفتات)
  List<ServiceDayModel> loadServiceDays() {
    final jsonStr = prefs.getString(_keyServiceDays);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => ServiceDayModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveServiceDays(List<ServiceDayModel> list) async {
    final data = list.map((d) => d.toMap()).toList();
    await prefs.setString(_keyServiceDays, jsonEncode(data));
  }

  // Nurse Transactions (معاملات وسلف وصرف التمريض)
  List<NurseTransactionModel> loadNurseTransactions() {
    final jsonStr = prefs.getString(_keyNurseTransactions);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => NurseTransactionModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNurseTransactions(List<NurseTransactionModel> list) async {
    final data = list.map((t) => t.toMap()).toList();
    await prefs.setString(_keyNurseTransactions, jsonEncode(data));
  }

  // Partner Loans (سلف الشركاء)
  List<PartnerLoanModel> loadPartnerLoans() {
    final jsonStr = prefs.getString(_keyPartnerLoans);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => PartnerLoanModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePartnerLoans(List<PartnerLoanModel> list) async {
    final data = list.map((l) => l.toMap()).toList();
    await prefs.setString(_keyPartnerLoans, jsonEncode(data));
  }

  // Partner Settlements (تصفية حساب الشركاء يوم 23)
  List<PartnerSettlementModel> loadPartnerSettlements() {
    final jsonStr = prefs.getString(_keyPartnerSettlements);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => PartnerSettlementModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePartnerSettlements(List<PartnerSettlementModel> list) async {
    final data = list.map((s) => s.toMap()).toList();
    await prefs.setString(_keyPartnerSettlements, jsonEncode(data));
  }

  // Notifications & Activity Logs (الإشعارات وسجل العمليات)
  List<AppNotificationModel> loadNotifications() {
    final jsonStr = prefs.getString(_keyNotifications);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((n) => AppNotificationModel.fromMap(Map<String, dynamic>.from(n))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotifications(List<AppNotificationModel> list) async {
    final data = list.take(150).map((n) => n.toMap()).toList();
    await prefs.setString(_keyNotifications, jsonEncode(data));
  }

  // Caregivers (قاعدة بيانات وسجل الكوادر التمريضية)
  List<CaregiverModel> loadCaregivers() {
    final jsonStr = prefs.getString(_keyCaregivers);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((c) => CaregiverModel.fromMap(Map<String, dynamic>.from(c))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCaregivers(List<CaregiverModel> list) async {
    final data = list.map((c) => c.toMap()).toList();
    await prefs.setString(_keyCaregivers, jsonEncode(data));
  }

  // Chat Messages (شات ورسائل الفريق الداخلي للشركة)
  List<ChatMessageModel> loadChatMessages() {
    final jsonStr = prefs.getString(_keyChatMessages);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((m) => ChatMessageModel.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveChatMessages(List<ChatMessageModel> list) async {
    final data = list.take(300).map((m) => m.toMap()).toList();
    await prefs.setString(_keyChatMessages, jsonEncode(data));
  }

  // Case Offers & Bulletins (جروب عرض الحالات والفرص الجديدة للتمريض)
  List<CaseOfferModel> loadCaseOffers() {
    final jsonStr = prefs.getString(_keyCaseOffers);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((o) => CaseOfferModel.fromMap(Map<String, dynamic>.from(o))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCaseOffers(List<CaseOfferModel> list) async {
    final data = list.map((o) => o.toMap()).toList();
    await prefs.setString(_keyCaseOffers, jsonEncode(data));
  }

  // Management Instructions (لوحة تعليمات وتوجيهات الإدارة لمقدمي الخدمة)
  List<ManagementInstructionModel> loadManagementInstructions() {
    final jsonStr = prefs.getString(_keyManagementInstructions);
    if (jsonStr == null || jsonStr.isEmpty) {
      return _defaultManagementInstructions();
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      final list = decoded
          .map((item) => ManagementInstructionModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      if (list.isEmpty) {
        return _defaultManagementInstructions();
      }
      return list;
    } catch (_) {
      return _defaultManagementInstructions();
    }
  }

  Future<void> saveManagementInstructions(List<ManagementInstructionModel> list) async {
    final data = list.map((i) => i.toMap()).toList();
    await prefs.setString(_keyManagementInstructions, jsonEncode(data));
  }

  static List<ManagementInstructionModel> _defaultManagementInstructions() {
    return [
      ManagementInstructionModel(
        id: 'inst_1',
        title: 'الالتزام التام بمواعيد الوردية والزي الطبي الرسمي',
        content: '• الحضور في الموعد المحدد بالضبط لمقر الحالة دون أي تأخير.\n'
            '• الالتزام بارتداء الزي التمريضي النظيف والأنيق طوال فترة التواجد مع المريض.\n'
            '• تسجيل إثبات الحضور الجغرافي (GPS) فور الوصول للحالة والانصراف عند انتهاء الوردية مباشرة.',
        authorName: 'أ/ وهدان',
        authorRole: 'المدير العام',
        priority: 'urgent',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ManagementInstructionModel(
        id: 'inst_2',
        title: 'السرية التامة ومنع مناقشة أي تعاملات مالية مع العملاء',
        content: '• يحظر منعاً باتاً التحدث مع المريض أو ذويه في أي حسابات، أسعار، أو أرباح خاصة بالشركة.\n'
            '• في حال سؤال أهل المريض عن سداد المستحقات أو تجديد فترات الخدمة، يجب توجيههم للتواصل مباشرة مع إدارة الشركة.\n'
            '• الحفاظ على خصوصية وأسرار المريض الطبية والشخصية أمانة مهنية ملزمة.',
        authorName: 'أ/ وهدان',
        authorRole: 'المدير العام',
        priority: 'urgent',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ManagementInstructionModel(
        id: 'inst_3',
        title: 'حظر الاتفاقات المباشرة خارج نطاق الشركة',
        content: '• أي اتفاق مباشر يتم بين مقدم الخدمة والعميل خارج مظلة الشركة يعتبر إخلالاً جسيماً بالأمانة والتعاقد ويعرض صاحبه للحظر الفوري والمساءلة القانونية.\n'
            '• الشركة هي الضامن الوحيد لحقوق ومستحقات الممرض وسلامته المهنية.',
        authorName: 'أ/ زيزو',
        authorRole: 'مدير الحسابات والمالية',
        priority: 'urgent',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ManagementInstructionModel(
        id: 'inst_4',
        title: 'بروتوكول الطوارئ وتبليغ الإدارة والمتابعة',
        content: '• في حالة حدوث أي طارئ صحي أو تغير مفاجئ في علامات المريض الحيوية، يتم إبلاغ الإدارة الطبية وأ/ شيماء فوراً عبر الشات المباشر أو هاتفياً.\n'
            '• تدوين أي أدوية وملاحظات علاجية بدقة في سجل الوردية.',
        authorName: 'أ/ شيماء',
        authorRole: 'مديرة المتابعة والتشغيل',
        priority: 'important',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  String? loadLastThursdayAlertDate() {
    return prefs.getString(_keyLastThursdayAlertDate);
  }

  Future<void> saveLastThursdayAlertDate(String dateStr) async {
    await prefs.setString(_keyLastThursdayAlertDate, dateStr);
  }

  bool loadPendingOfflineSync() {
    return prefs.getBool(_keyPendingOfflineSync) ?? false;
  }

  Future<void> savePendingOfflineSync(bool value) async {
    await prefs.setBool(_keyPendingOfflineSync, value);
  }
}
