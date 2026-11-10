import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

class SyncResult {
  final bool success;
  final String message;
  final List<ClientModel>? clients;
  final List<PaymentModel>? payments;
  final List<ExpenseModel>? expenses;
  final List<ServiceDayModel>? serviceDays;
  final List<NurseTransactionModel>? nurseTransactions;
  final List<PartnerLoanModel>? partnerLoans;
  final List<PartnerSettlementModel>? partnerSettlements;
  final List<UserModel>? users;
  final List<CaregiverModel>? caregivers;
  final List<ChatMessageModel>? chatMessages;
  final List<AppNotificationModel>? notifications;
  final List<String>? deletedIds;
  final Map<String, double>? openingBalances;

  SyncResult({
    required this.success,
    required this.message,
    this.clients,
    this.payments,
    this.expenses,
    this.serviceDays,
    this.nurseTransactions,
    this.partnerLoans,
    this.partnerSettlements,
    this.users,
    this.caregivers,
    this.chatMessages,
    this.notifications,
    this.deletedIds,
    this.openingBalances,
  });
}

class CloudSyncService {
  /// Primary 24/7 Cloud Database on Google Firebase (works even if PC is off)
  static const String defaultFirebaseEndpoint =
      'https://elite-grand-8a6c3-default-rtdb.firebaseio.com/elite_grand.json';

  String? cloudEndpoint;
  SyncStatus status = SyncStatus.idle;
  DateTime? lastSyncTime;
  Timer? _periodicTimer;

  CloudSyncService({this.cloudEndpoint});

  String get effectiveEndpoint {
    if (cloudEndpoint != null && cloudEndpoint!.trim().isNotEmpty) {
      return cloudEndpoint!.trim();
    }
    // If running on local developer/office machine, can connect to localhost
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
          return 'http://localhost:8080/api/data';
        }
      } catch (_) {}
    }
    // Default to the 24/7 Firebase Cloud Database
    return defaultFirebaseEndpoint;
  }

  // Start background auto sync every 3 seconds for real-time multi-device sync
  void startAutoSync(Future<void> Function() onSyncTriggered) {
    _periodicTimer?.cancel();
    onSyncTriggered();
    _periodicTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await onSyncTriggered();
    });
  }

  void stopAutoSync() {
    _periodicTimer?.cancel();
  }

  // Push all local data to Cloud with deletedIds, openingBalances and notifications
  Future<bool> pushData({
    required List<ClientModel> clients,
    required List<PaymentModel> payments,
    required List<ExpenseModel> expenses,
    List<ServiceDayModel> serviceDays = const [],
    List<NurseTransactionModel> nurseTransactions = const [],
    List<PartnerLoanModel> partnerLoans = const [],
    List<PartnerSettlementModel> partnerSettlements = const [],
    required List<UserModel> users,
    List<CaregiverModel> caregivers = const [],
    List<ChatMessageModel> chatMessages = const [],
    List<AppNotificationModel> notifications = const [],
    List<String> deletedIds = const [],
    Map<String, double>? openingBalances,
  }) async {
    final endpoint = effectiveEndpoint;

    try {
      status = SyncStatus.syncing;
      final payload = {
        'lastUpdated': DateTime.now().toIso8601String(),
        'deletedIds': deletedIds,
        'openingBalances':
            openingBalances ?? {'bank': 0.0, 'wallet': 0.0, 'cash': 0.0},
        'clients': clients.map((c) => c.toMap()).toList(),
        'payments': payments.map((p) => p.toMap()).toList(),
        'expenses': expenses.map((e) => e.toMap()).toList(),
        'serviceDays': serviceDays.map((d) => d.toMap()).toList(),
        'nurseTransactions': nurseTransactions.map((t) => t.toMap()).toList(),
        'partnerLoans': partnerLoans.map((l) => l.toMap()).toList(),
        'partnerSettlements': partnerSettlements.map((s) => s.toMap()).toList(),
        'users': users.map((u) => u.toMap()).toList(),
        'caregivers': caregivers.map((c) => c.toMap()).toList(),
        'chatMessages': chatMessages.take(300).map((m) => m.toMap()).toList(),
        'notifications': notifications.take(150).map((n) => n.toMap()).toList(),
      };

      final uri = Uri.parse(endpoint);
      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        status = SyncStatus.success;
        lastSyncTime = DateTime.now();
        return true;
      } else {
        status = SyncStatus.error;
        return false;
      }
    } catch (e) {
      status = SyncStatus.offline;
      return false;
    }
  }

  // Pull latest data from Cloud
  Future<SyncResult> pullData() async {
    final endpoint = effectiveEndpoint;

    try {
      status = SyncStatus.syncing;
      final uri = Uri.parse(endpoint);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty || response.body == 'null') {
          status = SyncStatus.success;
          return SyncResult(success: true, message: 'قاعدة البيانات فارغة');
        }

        final Map<String, dynamic> data = jsonDecode(response.body);

        List<String>? remoteDeletedIds;
        if (data['deletedIds'] is List) {
          remoteDeletedIds = (data['deletedIds'] as List)
              .map((e) => e.toString())
              .toList();
        }

        Map<String, double>? remoteOpeningBalances;
        if (data['openingBalances'] is Map) {
          final ob = data['openingBalances'] as Map;
          remoteOpeningBalances = {
            'bank': (ob['bank'] as num?)?.toDouble() ?? 0.0,
            'wallet': (ob['wallet'] as num?)?.toDouble() ?? 0.0,
            'cash': (ob['cash'] as num?)?.toDouble() ?? 0.0,
          };
        }

        List<ClientModel>? remoteClients;
        if (data['clients'] is List) {
          remoteClients = (data['clients'] as List)
              .map((e) => ClientModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }

        List<PaymentModel>? remotePayments;
        if (data['payments'] is List) {
          remotePayments = (data['payments'] as List)
              .map((e) => PaymentModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }

        List<ExpenseModel>? remoteExpenses;
        if (data['expenses'] is List) {
          remoteExpenses = (data['expenses'] as List)
              .map((e) => ExpenseModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }

        List<ServiceDayModel>? remoteServiceDays;
        if (data['serviceDays'] is List) {
          remoteServiceDays = (data['serviceDays'] as List)
              .map((e) => ServiceDayModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }

        List<NurseTransactionModel>? remoteNurseTransactions;
        if (data['nurseTransactions'] is List) {
          remoteNurseTransactions = (data['nurseTransactions'] as List)
              .map((e) => NurseTransactionModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }

        List<PartnerLoanModel>? remotePartnerLoans;
        if (data['partnerLoans'] is List) {
          remotePartnerLoans = (data['partnerLoans'] as List)
              .map((e) => PartnerLoanModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }

        List<PartnerSettlementModel>? remotePartnerSettlements;
        if (data['partnerSettlements'] is List) {
          remotePartnerSettlements = (data['partnerSettlements'] as List)
              .map((e) => PartnerSettlementModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }

        List<UserModel>? remoteUsers;
        if (data['users'] is List) {
          remoteUsers = (data['users'] as List)
              .map((e) => UserModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }

        List<CaregiverModel>? remoteCaregivers;
        if (data['caregivers'] is List) {
          remoteCaregivers = (data['caregivers'] as List)
              .map((c) => CaregiverModel.fromMap(Map<String, dynamic>.from(c)))
              .toList();
        }

        List<ChatMessageModel>? remoteChatMessages;
        if (data['chatMessages'] is List) {
          remoteChatMessages = (data['chatMessages'] as List)
              .map((m) => ChatMessageModel.fromMap(Map<String, dynamic>.from(m)))
              .toList();
        }

        List<AppNotificationModel>? remoteNotifications;
        if (data['notifications'] is List) {
          remoteNotifications = (data['notifications'] as List)
              .map((n) => AppNotificationModel.fromMap(Map<String, dynamic>.from(n)))
              .toList();
        }

        status = SyncStatus.success;
        lastSyncTime = DateTime.now();

        return SyncResult(
          success: true,
          message: 'تمت المزامنة اللحظية بنجاح 24/7',
          clients: remoteClients,
          payments: remotePayments,
          expenses: remoteExpenses,
          serviceDays: remoteServiceDays,
          nurseTransactions: remoteNurseTransactions,
          partnerLoans: remotePartnerLoans,
          partnerSettlements: remotePartnerSettlements,
          users: remoteUsers,
          caregivers: remoteCaregivers,
          chatMessages: remoteChatMessages,
          notifications: remoteNotifications,
          deletedIds: remoteDeletedIds,
          openingBalances: remoteOpeningBalances,
        );
      } else {
        status = SyncStatus.error;
        return SyncResult(
          success: false,
          message: 'فشل الاتصال: رمز ${response.statusCode}',
        );
      }
    } catch (e) {
      status = SyncStatus.offline;
      return SyncResult(
        success: false,
        message: 'وضع عدم الاتصال: $e',
      );
    }
  }
}
