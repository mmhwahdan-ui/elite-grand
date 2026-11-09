class PartnerLoanModel {
  final String id;
  /// 'wahdan' | 'shimaa' | 'zezo'
  final String partnerUsername;
  final String partnerName;
  final double totalAmount;
  final DateTime date;
  /// 'single' (دفعة واحدة من التصفية القادمة) | 'installments' (مقسمة على عدة أشهر)
  final String repaymentType;
  final int installmentMonths;
  final double monthlyDeduction;
  final double paidAmount;
  /// 'cash' | 'wallet' | 'bank'
  final String paymentChannel;
  final String notes;
  final String recordedBy;
  final DateTime createdAt;

  PartnerLoanModel({
    required this.id,
    required this.partnerUsername,
    required this.partnerName,
    required this.totalAmount,
    required this.date,
    this.repaymentType = 'single',
    this.installmentMonths = 1,
    double? monthlyDeduction,
    this.paidAmount = 0.0,
    this.paymentChannel = 'cash',
    this.notes = '',
    this.recordedBy = 'wahdan',
    DateTime? createdAt,
  })  : monthlyDeduction = monthlyDeduction ??
            (installmentMonths > 0 ? (totalAmount / installmentMonths) : totalAmount),
        createdAt = createdAt ?? DateTime.now();

  double get remainingAmount =>
      (totalAmount - paidAmount).clamp(0.0, double.infinity);

  bool get isFullyPaid => remainingAmount <= 0.01;

  String get repaymentTypeArabic {
    if (repaymentType == 'single' || installmentMonths <= 1) {
      return 'دفعة واحدة من التصفية';
    }
    return 'مقسمة على $installmentMonths أشهر (${monthlyDeduction.toStringAsFixed(0)} ج.م/شهر)';
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
      'partnerUsername': partnerUsername,
      'partnerName': partnerName,
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'repaymentType': repaymentType,
      'installmentMonths': installmentMonths,
      'monthlyDeduction': monthlyDeduction,
      'paidAmount': paidAmount,
      'paymentChannel': paymentChannel,
      'notes': notes,
      'recordedBy': recordedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PartnerLoanModel.fromMap(Map<String, dynamic> map) {
    final total = (map['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final months = (map['installmentMonths'] as num?)?.toInt() ?? 1;
    final deduction = (map['monthlyDeduction'] as num?)?.toDouble() ??
        (months > 0 ? (total / months) : total);

    return PartnerLoanModel(
      id: map['id'] ?? '',
      partnerUsername: map['partnerUsername'] ?? 'wahdan',
      partnerName: map['partnerName'] ?? '',
      totalAmount: total,
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      repaymentType: map['repaymentType'] ?? 'single',
      installmentMonths: months,
      monthlyDeduction: deduction,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      paymentChannel: map['paymentChannel'] ?? 'cash',
      notes: map['notes'] ?? '',
      recordedBy: map['recordedBy'] ?? 'wahdan',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PartnerLoanModel copyWith({
    double? paidAmount,
  }) {
    return PartnerLoanModel(
      id: id,
      partnerUsername: partnerUsername,
      partnerName: partnerName,
      totalAmount: totalAmount,
      date: date,
      repaymentType: repaymentType,
      installmentMonths: installmentMonths,
      monthlyDeduction: monthlyDeduction,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentChannel: paymentChannel,
      notes: notes,
      recordedBy: recordedBy,
      createdAt: createdAt,
    );
  }
}
