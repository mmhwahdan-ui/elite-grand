class ExpenseModel {
  final String id;
  final String title;
  final String category; // 'nurse_salary', 'transportation', 'medical_supplies', 'advances', 'admin', 'other'
  final double amount;
  final DateTime expenseDate;
  final String paymentChannel; // 'wallet' (محفظة), 'bank' (بنك), 'cash' (كاش)
  final String notes;
  final String recordedBy;
  final String? relatedClientId;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.paymentChannel = 'cash',
    this.notes = '',
    required this.recordedBy,
    this.relatedClientId,
    required this.createdAt,
  });

  String get categoryArabic {
    switch (category) {
      case 'nurse_salary':
        return 'رواتب تمريض';
      case 'transportation':
        return 'انتقالات ومواصلات';
      case 'medical_supplies':
        return 'مستلزمات وأدوات طبية';
      case 'advances':
        return 'سلف وعُهد تمريض';
      case 'admin':
        return 'مصاريف إدارية ومقر';
      default:
        return 'مصروفات أخرى';
    }
  }

  String get channelArabic {
    switch (paymentChannel) {
      case 'wallet':
        return 'محفظة إلكترونية';
      case 'bank':
        return 'الحساب البنكي';
      case 'cash':
      default:
        return 'الخزينة النقدية (كاش)';
    }
  }

  String get channelShortArabic {
    switch (paymentChannel) {
      case 'wallet':
        return '📱 محفظة';
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
      'title': title,
      'category': category,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'paymentChannel': paymentChannel,
      'notes': notes,
      'recordedBy': recordedBy,
      'relatedClientId': relatedClientId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: map['expenseDate'] != null
          ? DateTime.tryParse(map['expenseDate']) ?? DateTime.now()
          : DateTime.now(),
      paymentChannel: map['paymentChannel'] ?? 'cash',
      notes: map['notes'] ?? '',
      recordedBy: map['recordedBy'] ?? '',
      relatedClientId: map['relatedClientId'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
