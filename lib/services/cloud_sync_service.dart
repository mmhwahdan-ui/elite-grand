import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/payment_model.dart';
import '../models/expense_model.dart';
import '../models/service_day_model.dart';

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
  final List<UserModel>? users;
  final List<String>? deletedIds;
  final Map<String, double>? openingBalances;

  SyncResult({
    required this.success,
    required this.message,
    this.clients,
    this.payments,
    this.expenses,
    this.serviceDays,
    this.users,
    this.deletedIds,
    this.openingBalances,
  });
}

class CloudSyncService {
  static const String tunnelDiscoveryUrl =
      'https://raw.githubusercontent.com/mmhwahdan-ui/elite-grand/main/tunnel.json';

  String? cloudEndpoint;
  SyncStatus status = SyncStatus.idle;
  DateTime? lastSyncTime;
  Timer? _periodicTimer;
  bool _isResolving = false;

  CloudSyncService({this.cloudEndpoint}) {
    resolveDynamicEndpoint();
  }

  /// Automatically discovers the active tunnel URL published by the Windows launcher
  Future<void> resolveDynamicEndpoint() async {
    if (_isResolving) return;
    _isResolving = true;
    try {
      if (kIsWeb) {
        try {
          final origin = Uri.base.origin;
          if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
            cloudEndpoint = 'http://localhost:8080/api/data';
            return;
          }
        } catch (_) {}
      }

      final uri = Uri.parse(
          '$tunnelDiscoveryUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map && data['url'] != null) {
          final rawUrl =
              data['url'].toString().trim().replaceAll(RegExp(r'/+$'), '');
          if (rawUrl.startsWith('http')) {
            cloudEndpoint = '$rawUrl/api/data';
          }
        }
      }
    } catch (_) {
      // Keep existing endpoint on error
    } finally {
      _isResolving = false;
    }
  }

  String get effectiveEndpoint {
    if (cloudEndpoint != null && cloudEndpoint!.trim().isNotEmpty) {
      return cloudEndpoint!.trim();
    }
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty &&
            origin != 'null' &&
            !origin.contains('github.io')) {
          return '$origin/api/data';
        }
      } catch (_) {}
    }
    return 'https://relax-deck-speed-temporary.trycloudflare.com/api/data';
  }

  // Start background auto sync every 4 seconds
  void startAutoSync(Future<void> Function() onSyncTriggered) {
    _periodicTimer?.cancel();
    resolveDynamicEndpoint().then((_) {
      onSyncTriggered();
    });
    _periodicTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await onSyncTriggered();
    });
  }

  void stopAutoSync() {
    _periodicTimer?.cancel();
  }

  // Push all local data to Cloud with deletedIds and openingBalances
  Future<bool> pushData({
    required List<ClientModel> clients,
    required List<PaymentModel> payments,
    required List<ExpenseModel> expenses,
    List<ServiceDayModel> serviceDays = const [],
    required List<UserModel> users,
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
        'users': users.map((u) => u.toMap()).toList(),
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
        resolveDynamicEndpoint();
        return false;
      }
    } catch (e) {
      status = SyncStatus.offline;
      resolveDynamicEndpoint();
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

        List<UserModel>? remoteUsers;
        if (data['users'] is List) {
          remoteUsers = (data['users'] as List)
              .map((e) => UserModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }

        status = SyncStatus.success;
        lastSyncTime = DateTime.now();

        return SyncResult(
          success: true,
          message: 'تمت المزامنة اللحظية بنجاح',
          clients: remoteClients,
          payments: remotePayments,
          expenses: remoteExpenses,
          serviceDays: remoteServiceDays,
          users: remoteUsers,
          deletedIds: remoteDeletedIds,
          openingBalances: remoteOpeningBalances,
        );
      } else {
        status = SyncStatus.error;
        resolveDynamicEndpoint();
        return SyncResult(
          success: false,
          message: 'فشل الاتصال: رمز ${response.statusCode}',
        );
      }
    } catch (e) {
      status = SyncStatus.offline;
      resolveDynamicEndpoint();
      return SyncResult(
        success: false,
        message: 'وضع عدم الاتصال: $e',
      );
    }
  }
}
