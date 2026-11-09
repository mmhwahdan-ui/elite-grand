class PartnerSettlementModel {
  final String id;
  final String cycleTitle;
  final DateTime settlementDate;
  final DateTime startDate;
  final DateTime endDate;
  final double companyNetProfit;

  // Wahdan (40%)
  final double wahdanBaseProfit;
  final double wahdanAdminDeduction;
  final double wahdanLoanDeduction;
  final double wahdanNetPayout;

  // Shimaa (40% with minimum guarantee of 6,000 EGP)
  final double shimaaBaseProfit;
  final double shimaaAdminSubsidy;
  final double shimaaLoanDeduction;
  final double shimaaNetPayout;

  // Zezo (20%)
  final double zezoBaseProfit;
  final double zezoAdminDeduction;
  final double zezoLoanDeduction;
  final double zezoNetPayout;

  // Treasury impact
  final double totalDisbursed;
  final double treasuryBeforePayout;
  final double remainingTreasuryCash;
  final bool isDisbursed;
  final String notes;
  final String recordedBy;
  final DateTime createdAt;

  PartnerSettlementModel({
    required this.id,
    required this.cycleTitle,
    required this.settlementDate,
    required this.startDate,
    required this.endDate,
    required this.companyNetProfit,
    required this.wahdanBaseProfit,
    required this.wahdanAdminDeduction,
    required this.wahdanLoanDeduction,
    required this.wahdanNetPayout,
    required this.shimaaBaseProfit,
    required this.shimaaAdminSubsidy,
    required this.shimaaLoanDeduction,
    required this.shimaaNetPayout,
    required this.zezoBaseProfit,
    required this.zezoAdminDeduction,
    required this.zezoLoanDeduction,
    required this.zezoNetPayout,
    required this.totalDisbursed,
    required this.treasuryBeforePayout,
    required this.remainingTreasuryCash,
    this.isDisbursed = false,
    this.notes = '',
    this.recordedBy = 'wahdan',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycleTitle': cycleTitle,
      'settlementDate': settlementDate.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'companyNetProfit': companyNetProfit,
      'wahdanBaseProfit': wahdanBaseProfit,
      'wahdanAdminDeduction': wahdanAdminDeduction,
      'wahdanLoanDeduction': wahdanLoanDeduction,
      'wahdanNetPayout': wahdanNetPayout,
      'shimaaBaseProfit': shimaaBaseProfit,
      'shimaaAdminSubsidy': shimaaAdminSubsidy,
      'shimaaLoanDeduction': shimaaLoanDeduction,
      'shimaaNetPayout': shimaaNetPayout,
      'zezoBaseProfit': zezoBaseProfit,
      'zezoAdminDeduction': zezoAdminDeduction,
      'zezoLoanDeduction': zezoLoanDeduction,
      'zezoNetPayout': zezoNetPayout,
      'totalDisbursed': totalDisbursed,
      'treasuryBeforePayout': treasuryBeforePayout,
      'remainingTreasuryCash': remainingTreasuryCash,
      'isDisbursed': isDisbursed,
      'notes': notes,
      'recordedBy': recordedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PartnerSettlementModel.fromMap(Map<String, dynamic> map) {
    return PartnerSettlementModel(
      id: map['id'] ?? '',
      cycleTitle: map['cycleTitle'] ?? '',
      settlementDate: map['settlementDate'] != null
          ? DateTime.tryParse(map['settlementDate']) ?? DateTime.now()
          : DateTime.now(),
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate']) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate']) ?? DateTime.now()
          : DateTime.now(),
      companyNetProfit: (map['companyNetProfit'] as num?)?.toDouble() ?? 0.0,
      wahdanBaseProfit: (map['wahdanBaseProfit'] as num?)?.toDouble() ?? 0.0,
      wahdanAdminDeduction: (map['wahdanAdminDeduction'] as num?)?.toDouble() ?? 0.0,
      wahdanLoanDeduction: (map['wahdanLoanDeduction'] as num?)?.toDouble() ?? 0.0,
      wahdanNetPayout: (map['wahdanNetPayout'] as num?)?.toDouble() ?? 0.0,
      shimaaBaseProfit: (map['shimaaBaseProfit'] as num?)?.toDouble() ?? 0.0,
      shimaaAdminSubsidy: (map['shimaaAdminSubsidy'] as num?)?.toDouble() ?? 0.0,
      shimaaLoanDeduction: (map['shimaaLoanDeduction'] as num?)?.toDouble() ?? 0.0,
      shimaaNetPayout: (map['shimaaNetPayout'] as num?)?.toDouble() ?? 0.0,
      zezoBaseProfit: (map['zezoBaseProfit'] as num?)?.toDouble() ?? 0.0,
      zezoAdminDeduction: (map['zezoAdminDeduction'] as num?)?.toDouble() ?? 0.0,
      zezoLoanDeduction: (map['zezoLoanDeduction'] as num?)?.toDouble() ?? 0.0,
      zezoNetPayout: (map['zezoNetPayout'] as num?)?.toDouble() ?? 0.0,
      totalDisbursed: (map['totalDisbursed'] as num?)?.toDouble() ?? 0.0,
      treasuryBeforePayout: (map['treasuryBeforePayout'] as num?)?.toDouble() ?? 0.0,
      remainingTreasuryCash: (map['remainingTreasuryCash'] as num?)?.toDouble() ?? 0.0,
      isDisbursed: map['isDisbursed'] ?? false,
      notes: map['notes'] ?? '',
      recordedBy: map['recordedBy'] ?? 'wahdan',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
