class PaymentModel {
  final String id;
  final String clientId;
  final String clientName;
  final double amount;
  final DateTime paymentDate;
  final String paymentChannel; // 'wallet' (محفظة إلكترونية), 'bank' (حساب بنكي), 'cash' (خزينة نقدية)
  final String paymentMethod; // legacy fallback / display
  final String notes;
  final String receivedBy;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.amount,
    required this.paymentDate,
    this.paymentChannel = 'wallet',
    this.paymentMethod = 'transfer',
    this.notes = '',
    required this.receivedBy,
    required this.createdAt,
  });

  String get channelArabic {
    switch (paymentChannel) {
      case 'wallet':
        return 'محفظة إلكترونية (فودافون كاش / إنستاباي)';
      case 'bank':
        return 'الحساب البنكي (تحويل / إيداع)';
      case 'cash':
      default:
        return 'الخزينة النقدية (كاش)';
    }
  }

  String get channelShortArabic {
    switch (paymentChannel) {
      case 'wallet':
        return '📱 محفظة إلكترونية';
      case 'bank':
        return '🏦 بنك';
      case 'cash':
      default:
        return '💵 كاش';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentChannel': paymentChannel,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'receivedBy': receivedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    String channel = map['paymentChannel'] ?? '';
    if (channel.isEmpty) {
      final method = map['paymentMethod'] ?? 'cash';
      if (method == 'transfer') {
        channel = 'wallet';
      } else {
        channel = 'cash';
      }
    }

    return PaymentModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate']) ?? DateTime.now()
          : DateTime.now(),
      paymentChannel: channel,
      paymentMethod: map['paymentMethod'] ?? 'transfer',
      notes: map['notes'] ?? '',
      receivedBy: map['receivedBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
