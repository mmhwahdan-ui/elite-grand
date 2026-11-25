import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
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
  final bool hasChanges;
  final String? lastUpdated;
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
  final List<CaseOfferModel>? caseOffers;
  final List<AppNotificationModel>? notifications;
  final List<ManagementInstructionModel>? managementInstructions;
  final List<String>? deletedIds;
  final Map<String, double>? openingBalances;

  SyncResult({
    required this.success,
    required this.message,
    this.hasChanges = true,
    this.lastUpdated,
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
    this.caseOffers,
    this.notifications,
    this.managementInstructions,
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
  String? _lastKnownRemoteTimestamp;
  bool _isAutoSyncRunning = false;
  bool _hasAttachedVisibilityListener = false;

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

  // Start background auto sync with smart 8s lightweight checking and tab visibility awareness
  void startAutoSync(Future<void> Function() onSyncTriggered) {
    _periodicTimer?.cancel();
    onSyncTriggered();

    if (kIsWeb && !_hasAttachedVisibilityListener) {
      _hasAttachedVisibilityListener = true;
      try {
        web.document.addEventListener('visibilitychange', (web.Event e) {
          if (!web.document.hidden) {
            onSyncTriggered();
          }
        }.toJS);
      } catch (_) {}
    }

    _periodicTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (_isAutoSyncRunning) return;
      if (kIsWeb) {
        try {
          if (web.document.hidden) {
            // Tab is hidden or phone screen is locked; skip background tick to conserve battery and CPU
            return;
          }
        } catch (_) {}
      }

      _isAutoSyncRunning = true;
      try {
        await onSyncTriggered();
      } finally {
        _isAutoSyncRunning = false;
      }
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
    List<CaseOfferModel> caseOffers = const [],
    List<AppNotificationModel> notifications = const [],
    List<ManagementInstructionModel> managementInstructions = const [],
    List<String> deletedIds = const [],
    Map<String, double>? openingBalances,
    bool isFinancialReset = false,
    bool resetServiceDays = false,
  }) async {
    final endpoint = effectiveEndpoint;

    try {
      status = SyncStatus.syncing;

      List<ClientModel> mergedClients = List.from(clients);
      List<CaregiverModel> mergedCaregivers = List.from(caregivers);
      List<UserModel> mergedUsers = List.from(users);

      // Fetch remote first to prevent an old device with partial data from wiping cloud records
      try {
        final uri = Uri.parse(endpoint);
        final checkRes = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 4));
        if (checkRes.statusCode >= 200 && checkRes.statusCode < 300 && checkRes.body.isNotEmpty && checkRes.body != 'null') {
          final Map<String, dynamic> remote = jsonDecode(checkRes.body);
          final delSet = deletedIds.toSet();
          if (remote['deletedIds'] is List) {
            delSet.addAll((remote['deletedIds'] as List).map((e) => e.toString()));
          }

          if (remote['caregivers'] is List) {
            final remoteCgs = (remote['caregivers'] as List)
                .map((e) => CaregiverModel.fromMap(Map<String, dynamic>.from(e)))
                .where((c) => !delSet.contains(c.id))
                .toList();
            final cgMap = {for (var c in remoteCgs) c.id: c};
            for (var c in caregivers) {
              if (!delSet.contains(c.id)) cgMap[c.id] = c;
            }
            mergedCaregivers = cgMap.values.toList();
          }

          if (remote['clients'] is List) {
            final remoteCls = (remote['clients'] as List)
                .map((e) => ClientModel.fromMap(Map<String, dynamic>.from(e)))
                .where((c) => !delSet.contains(c.id))
                .toList();
            final clMap = {for (var c in remoteCls) c.id: c};
            for (var c in clients) {
              if (!delSet.contains(c.id)) clMap[c.id] = c;
            }
            mergedClients = clMap.values.toList();
          }

          if (remote['users'] is List) {
            final remoteUsrs = (remote['users'] as List)
                .map((e) => UserModel.fromMap(Map<String, dynamic>.from(e)))
                .toList();
            final uMap = {for (var u in remoteUsrs) u.id: u};
            for (var u in users) {
              uMap[u.id] = u;
            }
            mergedUsers = uMap.values.toList();
          }
        }
      } catch (_) {}

      final nowIso = DateTime.now().toIso8601String();
      final payload = {
        'lastUpdated': nowIso,
        'isFinancialReset': isFinancialReset,
        'resetServiceDays': resetServiceDays,
        'deletedIds': deletedIds,
        'openingBalances':
            openingBalances ?? {'bank': 0.0, 'wallet': 0.0, 'cash': 0.0},
        'clients': mergedClients.map((c) => c.toMap()).toList(),
        'payments': payments.map((p) => p.toMap()).toList(),
        'expenses': expenses.map((e) => e.toMap()).toList(),
        'serviceDays': serviceDays.map((d) => d.toMap()).toList(),
        'nurseTransactions': nurseTransactions.map((t) => t.toMap()).toList(),
        'partnerLoans': partnerLoans.map((l) => l.toMap()).toList(),
        'partnerSettlements': partnerSettlements.map((s) => s.toMap()).toList(),
        'users': mergedUsers.map((u) => u.toMap()).toList(),
        'caregivers': mergedCaregivers.map((c) => c.toMap()).toList(),
        'chatMessages': chatMessages.take(300).map((m) => m.toMap()).toList(),
        'caseOffers': caseOffers.map((o) => o.toMap()).toList(),
        'notifications': notifications.take(150).map((n) => n.toMap()).toList(),
        'managementInstructions': managementInstructions.map((i) => i.toMap()).toList(),
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
        _lastKnownRemoteTimestamp = nowIso;
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

  // Pull latest data from Cloud with smart lightweight timestamp check
  Future<SyncResult> pullData({bool force = false}) async {
    final endpoint = effectiveEndpoint;

    try {
      // 1. Lightweight subkey check on Firebase (30 bytes instead of 150KB) to prevent UI frame drops
      if (!force && endpoint.contains('firebaseio.com')) {
        final tsUrl = endpoint.endsWith('.json')
            ? endpoint.replaceAll('.json', '/lastUpdated.json')
            : '$endpoint/lastUpdated.json';
        try {
          final tsRes = await http.get(
            Uri.parse(tsUrl),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 4));

          if (tsRes.statusCode >= 200 && tsRes.statusCode < 300 && tsRes.body.isNotEmpty && tsRes.body != 'null') {
            final remoteTs = tsRes.body.trim().replaceAll('"', '');
            if (_lastKnownRemoteTimestamp != null && _lastKnownRemoteTimestamp == remoteTs) {
              // Remote cloud data has NOT changed! No need to download 150KB or rebuild UI!
              status = SyncStatus.success;
              return SyncResult(
                success: true,
                hasChanges: false,
                lastUpdated: remoteTs,
                message: 'قاعدة البيانات السحابية محدثة (لا توجد تغييرات)',
              );
            }
          }
        } catch (_) {}
      }

      status = SyncStatus.syncing;
      final uri = Uri.parse(endpoint);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty || response.body == 'null') {
          status = SyncStatus.success;
          return SyncResult(success: true, hasChanges: false, message: 'قاعدة البيانات فارغة');
        }

        final Map<String, dynamic> data = jsonDecode(response.body);

        final remoteTs = data['lastUpdated']?.toString();
        if (remoteTs != null && remoteTs.isNotEmpty) {
          _lastKnownRemoteTimestamp = remoteTs;
        }

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
        } else if (data['payments'] == null) {
          remotePayments = [];
        }

        List<ExpenseModel>? remoteExpenses;
        if (data['expenses'] is List) {
          remoteExpenses = (data['expenses'] as List)
              .map((e) => ExpenseModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        } else if (data['expenses'] == null) {
          remoteExpenses = [];
        }

        List<ServiceDayModel>? remoteServiceDays;
        if (data['serviceDays'] is List) {
          remoteServiceDays = (data['serviceDays'] as List)
              .map((e) => ServiceDayModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        } else if (data['serviceDays'] == null && data['deletedIds'] is List) {
          remoteServiceDays = [];
        }

        List<NurseTransactionModel>? remoteNurseTransactions;
        if (data['nurseTransactions'] is List) {
          remoteNurseTransactions = (data['nurseTransactions'] as List)
              .map((e) => NurseTransactionModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        } else if (data['nurseTransactions'] == null) {
          remoteNurseTransactions = [];
        }

        List<PartnerLoanModel>? remotePartnerLoans;
        if (data['partnerLoans'] is List) {
          remotePartnerLoans = (data['partnerLoans'] as List)
              .map((e) => PartnerLoanModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        } else if (data['partnerLoans'] == null) {
          remotePartnerLoans = [];
        }

        List<PartnerSettlementModel>? remotePartnerSettlements;
        if (data['partnerSettlements'] is List) {
          remotePartnerSettlements = (data['partnerSettlements'] as List)
              .map((e) => PartnerSettlementModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        } else if (data['partnerSettlements'] == null) {
          remotePartnerSettlements = [];
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

        List<CaseOfferModel>? remoteCaseOffers;
        if (data['caseOffers'] is List) {
          remoteCaseOffers = (data['caseOffers'] as List)
              .map((o) => CaseOfferModel.fromMap(Map<String, dynamic>.from(o)))
              .toList();
        }

        List<AppNotificationModel>? remoteNotifications;
        if (data['notifications'] is List) {
          remoteNotifications = (data['notifications'] as List)
              .map((n) => AppNotificationModel.fromMap(Map<String, dynamic>.from(n)))
              .toList();
        }

        List<ManagementInstructionModel>? remoteInstructions;
        if (data['managementInstructions'] is List) {
          remoteInstructions = (data['managementInstructions'] as List)
              .map((i) => ManagementInstructionModel.fromMap(Map<String, dynamic>.from(i)))
              .toList();
        }

        status = SyncStatus.success;
        lastSyncTime = DateTime.now();

        return SyncResult(
          success: true,
          hasChanges: true,
          lastUpdated: remoteTs,
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
          caseOffers: remoteCaseOffers,
          notifications: remoteNotifications,
          managementInstructions: remoteInstructions,
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
