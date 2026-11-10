class ClientModel {
  final String id;
  String name;
  String phone;
  String address;
  String healthCondition;
  String serviceType; // 'hours8', 'hours10', 'hours12', 'hours24', 'custom'
  double dailyPrice; // سعر اليوم المتفق عليه مع العميل
  double nurseDailyPrice; // يومية الممرض المتفق عليها
  bool isExistingClient; // هل عميل جديد (false) أم عميل حالي (true)
  double openingBalance; // رصيد سابق: بالموجب (+) مستحق للعميل / بالسالب (-) مديونية على العميل
  DateTime? startDate;
  DateTime? endDate;
  String status; // 'pending_pricing', 'ready_to_start', 'active', 'stopped_by_accountant', 'completed'
  String? terminationReason;
  String? nurseAssigned;
  String notes;
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.healthCondition,
    this.serviceType = 'hours12',
    this.dailyPrice = 0.0,
    this.nurseDailyPrice = 0.0,
    this.isExistingClient = false,
    this.openingBalance = 0.0,
    this.startDate,
    this.endDate,
    this.status = 'pending_pricing',
    this.terminationReason,
    this.nurseAssigned,
    this.notes = '',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate served days (based on determined duration or elapsed days if open-ended)
  int get servedDays {
    if (startDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);

    if (endDate != null) {
      // If duration is determined (سواء عميل حالي أو جديد), calculate based on the determined duration!
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (end.isBefore(start)) return 1;
      return end.difference(start).inDays + 1;
    } else {
      // If duration is open-ended, calculate from start date up to today
      if (today.isBefore(start)) return 1;
      return today.difference(start).inDays + 1;
    }
  }

  // Total planned / contracted days if an end date was specified
  int? get totalContractDays {
    if (startDate == null || endDate == null) return null;
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    if (end.isBefore(start)) return 0;
    return end.difference(start).inDays + 1;
  }

  // Remaining days until planned end date
  int? get remainingContractDays {
    if (startDate == null || endDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    if (end.isBefore(today)) return 0;
    return end.difference(today).inDays;
  }

  // Is duration open-ended (continuous)
  bool get isOpenEnded => endDate == null;

  // Calculate total accrued service cost billed to client
  double get totalServiceCost {
    if (dailyPrice <= 0 || startDate == null) return 0.0;
    return servedDays * dailyPrice;
  }

  // Calculate total accrued nurse cost for this case
  double get totalNurseCost {
    if (nurseDailyPrice <= 0 || startDate == null) return 0.0;
    return servedDays * nurseDailyPrice;
  }

  // Daily gross profit difference between client and nurse
  double get dailyCompanyProfit => dailyPrice - nurseDailyPrice;

  // Total gross profit from price difference for this case so far
  double get companyGrossProfit {
    if (startDate == null) return 0.0;
    return servedDays * (dailyPrice - nurseDailyPrice);
  }

  String get serviceTypeArabic {
    switch (serviceType) {
      case 'hours24':
        return 'إقامة كاملة (24 ساعة)';
      case 'hours12':
        return 'وردية يومية (12 ساعة)';
      case 'hours10':
        return 'وردية (10 ساعات)';
      case 'hours8':
        return 'وردية (8 ساعات)';
      case 'custom':
        return 'ساعات مخصصة';
      default:
        return 'وردية يومية (12 ساعة)';
    }
  }

  String get statusArabic {
    switch (status) {
      case 'pending_pricing':
        return 'بانتظار تسعير الحسابات';
      case 'ready_to_start':
        return 'تم التسعير - بانتظار بدء الخدمة';
      case 'active':
        return 'الخدمة جارية (نشطة)';
      case 'stopped_by_accountant':
        return 'متوقفة (تعثر سداد)';
      case 'completed':
        return 'منتهية (مكتملة)';
      default:
        return status;
    }
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? healthCondition,
    String? serviceType,
    double? dailyPrice,
    double? nurseDailyPrice,
    bool? isExistingClient,
    double? openingBalance,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    String? status,
    String? terminationReason,
    String? nurseAssigned,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      healthCondition: healthCondition ?? this.healthCondition,
      serviceType: serviceType ?? this.serviceType,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      nurseDailyPrice: nurseDailyPrice ?? this.nurseDailyPrice,
      isExistingClient: isExistingClient ?? this.isExistingClient,
      openingBalance: openingBalance ?? this.openingBalance,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      status: status ?? this.status,
      terminationReason: terminationReason ?? this.terminationReason,
      nurseAssigned: nurseAssigned ?? this.nurseAssigned,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'healthCondition': healthCondition,
      'serviceType': serviceType,
      'dailyPrice': dailyPrice,
      'nurseDailyPrice': nurseDailyPrice,
      'isExistingClient': isExistingClient,
      'openingBalance': openingBalance,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'terminationReason': terminationReason,
      'nurseAssigned': nurseAssigned,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      healthCondition: map['healthCondition'] ?? '',
      serviceType: map['serviceType'] ?? 'hours12',
      dailyPrice: (map['dailyPrice'] as num?)?.toDouble() ?? 0.0,
      nurseDailyPrice: (map['nurseDailyPrice'] as num?)?.toDouble() ?? 0.0,
      isExistingClient: map['isExistingClient'] ?? false,
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'])
          : null,
      endDate:
          map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
      status: map['status'] ?? 'pending_pricing',
      terminationReason: map['terminationReason'],
      nurseAssigned: map['nurseAssigned'],
      notes: map['notes'] ?? '',
      createdBy: map['createdBy'] ?? 'shimaa',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
