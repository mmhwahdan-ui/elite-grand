class NurseTransactionModel {
  final String id;
  final String nurseName;
  final double amount;
  final DateTime date;
  /// 'advance' (سلفة) | 'payout' (صرف أجر / مستحقات)
  final String type;
  /// 'cash' (خزينة نقدية) | 'wallet' (فودافون كاش / إنستاباي) | 'bank' (حساب بنكي)
  final String paymentChannel;
  final String notes;
  final String recordedBy;
  final DateTime createdAt;

  NurseTransactionModel({
    required this.id,
    required this.nurseName,
    required this.amount,
    required this.date,
    required this.type,
    this.paymentChannel = 'cash',
    this.notes = '',
    this.recordedBy = 'wahdan',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeArabic {
    switch (type) {
      case 'advance':
        return 'سلفة';
      case 'payout':
        return 'صرف مستحقات / أجر';
      default:
        return 'دفعة';
    }
  }

  String get channelArabic {
    switch (paymentChannel) {
      case 'wallet':
        return 'محفظة إلكترونية';
      case 'bank':
        return 'حساب بنكي';
      case 'cash':
      default:
        return 'خزينة نقدية (كاش)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nurseName': nurseName,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'paymentChannel': paymentChannel,
      'notes': notes,
      'recordedBy': recordedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NurseTransactionModel.fromMap(Map<String, dynamic> map) {
    return NurseTransactionModel(
      id: map['id'] ?? '',
      nurseName: map['nurseName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      type: map['type'] ?? 'advance',
      paymentChannel: map['paymentChannel'] ?? 'cash',
      notes: map['notes'] ?? '',
      recordedBy: map['recordedBy'] ?? 'wahdan',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
