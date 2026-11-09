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

class StorageService {
  static const String _keyUsers = 'eg_users_data';
  static const String _keyClients = 'eg_clients_data';
  static const String _keyPayments = 'eg_payments_data';
  static const String _keyExpenses = 'eg_expenses_data';
  static const String _keyCurrentUser = 'eg_current_user_id';
  static const String _keyCloudEndpoint = 'eg_cloud_endpoint';
  static const String _keyLastSync = 'eg_last_sync_time';
  static const String _keyDeletedIds = 'eg_deleted_ids';
  static const String _keyOpeningBalances = 'eg_opening_balances';
  static const String _keyServiceDays = 'eg_service_days_data';
  static const String _keyNurseTransactions = 'eg_nurse_transactions_data';
  static const String _keyPartnerLoans = 'eg_partner_loans_data';
  static const String _keyPartnerSettlements = 'eg_partner_settlements_data';

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
      final defaultUsers = UserModel.getDefaultUsers();
      saveUsers(defaultUsers);
      return defaultUsers;
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => UserModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return UserModel.getDefaultUsers();
    }
  }

  Future<void> saveUsers(List<UserModel> users) async {
    final list = users.map((u) => u.toMap()).toList();
    await prefs.setString(_keyUsers, jsonEncode(list));
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
    final list = clients.map((c) => c.toMap()).toList();
    await prefs.setString(_keyClients, jsonEncode(list));
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
    final list = payments.map((p) => p.toMap()).toList();
    await prefs.setString(_keyPayments, jsonEncode(list));
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
    final list = expenses.map((e) => e.toMap()).toList();
    await prefs.setString(_keyExpenses, jsonEncode(list));
  }

  // Service Days (أيام الخدمة والشفتات المتغيرة)
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

  Future<void> saveServiceDays(List<ServiceDayModel> serviceDays) async {
    final list = serviceDays.map((d) => d.toMap()).toList();
    await prefs.setString(_keyServiceDays, jsonEncode(list));
  }

  // Nurse Transactions (سلف ومدفوعات التمريض)
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
}
