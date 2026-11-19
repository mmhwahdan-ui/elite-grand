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

  // نظام الخدمة الأسبوعي ودورة التقفيل
  final String serviceScheduleType; // 'all_week' (طوال الأسبوع - 7 أيام), 'custom_days' (أيام محددة: 4 أو 5 أيام)
  final int daysPerWeek; // 4, 5, 6, 7
  final List<int> activeWeekdays; // أرقام أيام الأسبوع (6=السبت, 7=الأحد, 1=الإثنين, 2=الثلاثاء, 3=الأربعاء, 4=الخميس, 5=الجمعة)
  final String settlementFrequency; // 'weekly' (تقفيل أسبوعي كل خميس), 'monthly' (تقفيل شهري)

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
    this.serviceScheduleType = 'all_week',
    this.daysPerWeek = 7,
    this.activeWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.settlementFrequency = 'weekly',
  });

  // Calculate served days (based on determined duration or elapsed days if open-ended, respecting 4 or 5 days/week schedules)
  int get servedDays {
    if (startDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);

    DateTime endLimit;
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (end.isBefore(start)) return 1;
      endLimit = end;
    } else {
      if (today.isBefore(start)) return 1;
      endLimit = today;
    }

    // إذا كان العميل يتبع جدول أيام مخصص (مثل 4 أو 5 أيام أسبوعياً)
    if (serviceScheduleType == 'custom_days') {
      if (activeWeekdays.isNotEmpty) {
        int count = 0;
        DateTime cur = start;
        while (!cur.isAfter(endLimit)) {
          if (activeWeekdays.contains(cur.weekday)) {
            count++;
          }
          cur = cur.add(const Duration(days: 1));
        }
        return count > 0 ? count : 1;
      } else if (daysPerWeek > 0 && daysPerWeek < 7) {
        final totalCalendarDays = endLimit.difference(start).inDays + 1;
        final fullWeeks = totalCalendarDays ~/ 7;
        final remainingDays = totalCalendarDays % 7;
        final extraDays = remainingDays > daysPerWeek ? daysPerWeek : remainingDays;
        final res = (fullWeeks * daysPerWeek) + extraDays;
        return res > 0 ? res : 1;
      }
    }

    return endLimit.difference(start).inDays + 1;
  }

  // Total planned / contracted days if an end date was specified
  int? get totalContractDays {
    if (startDate == null || endDate == null) return null;
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    if (end.isBefore(start)) return 0;

    if (serviceScheduleType == 'custom_days') {
      if (activeWeekdays.isNotEmpty) {
        int count = 0;
        DateTime cur = start;
        while (!cur.isAfter(end)) {
          if (activeWeekdays.contains(cur.weekday)) {
            count++;
          }
          cur = cur.add(const Duration(days: 1));
        }
        return count;
      } else if (daysPerWeek > 0 && daysPerWeek < 7) {
        final totalCalendarDays = end.difference(start).inDays + 1;
        final fullWeeks = totalCalendarDays ~/ 7;
        final remainingDays = totalCalendarDays % 7;
        final extraDays = remainingDays > daysPerWeek ? daysPerWeek : remainingDays;
        return (fullWeeks * daysPerWeek) + extraDays;
      }
    }

    return end.difference(start).inDays + 1;
  }

  // Remaining days until planned end date
  int? get remainingContractDays {
    if (startDate == null || endDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    if (end.isBefore(today)) return 0;

    if (serviceScheduleType == 'custom_days') {
      if (activeWeekdays.isNotEmpty) {
        int count = 0;
        DateTime cur = today.add(const Duration(days: 1));
        while (!cur.isAfter(end)) {
          if (activeWeekdays.contains(cur.weekday)) {
            count++;
          }
          cur = cur.add(const Duration(days: 1));
        }
        return count;
      } else if (daysPerWeek > 0 && daysPerWeek < 7) {
        final totalCalendarDays = end.difference(today).inDays;
        final fullWeeks = totalCalendarDays ~/ 7;
        final remainingDays = totalCalendarDays % 7;
        final extraDays = remainingDays > daysPerWeek ? daysPerWeek : remainingDays;
        return (fullWeeks * daysPerWeek) + extraDays;
      }
    }

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

  // Weekly accrued cost for client
  double get weeklyClientCost => (daysPerWeek > 0 ? daysPerWeek : 7) * dailyPrice;

  // Weekly nurse cost
  double get weeklyNurseCost => (daysPerWeek > 0 ? daysPerWeek : 7) * nurseDailyPrice;

  // Weekly company profit
  double get weeklyCompanyProfit => weeklyClientCost - weeklyNurseCost;

  // Total gross profit from price difference for this case so far
  double get companyGrossProfit {
    if (startDate == null) return 0.0;
    return servedDays * (dailyPrice - nurseDailyPrice);
  }

  // وصف جدول الخدمة بالعربية
  String get scheduleDescriptionArabic {
    if (serviceScheduleType == 'all_week' || daysPerWeek == 7) {
      return 'طوال الأسبوع (7 أيام)';
    }

    final dayLabels = <String>[];
    if (activeWeekdays.contains(6)) dayLabels.add('السبت');
    if (activeWeekdays.contains(7)) dayLabels.add('الأحد');
    if (activeWeekdays.contains(1)) dayLabels.add('الإثنين');
    if (activeWeekdays.contains(2)) dayLabels.add('الثلاثاء');
    if (activeWeekdays.contains(3)) dayLabels.add('الأربعاء');
    if (activeWeekdays.contains(4)) dayLabels.add('الخميس');
    if (activeWeekdays.contains(5)) dayLabels.add('الجمعة');

    if (dayLabels.isNotEmpty) {
      return '$daysPerWeek أيام أسبوعياً (${dayLabels.join('، ')})';
    }
    return '$daysPerWeek أيام أسبوعياً';
  }

  String get settlementFrequencyArabic {
    return settlementFrequency == 'monthly' ? 'تقفيل شهري' : 'تقفيل أسبوعي (كل خميس)';
  }

  bool get isWeeklySettlement => settlementFrequency == 'weekly';
  bool get isMonthlySettlement => settlementFrequency == 'monthly';

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
    String? serviceScheduleType,
    int? daysPerWeek,
    List<int>? activeWeekdays,
    String? settlementFrequency,
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
      serviceScheduleType: serviceScheduleType ?? this.serviceScheduleType,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      settlementFrequency: settlementFrequency ?? this.settlementFrequency,
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
      'serviceScheduleType': serviceScheduleType,
      'daysPerWeek': daysPerWeek,
      'activeWeekdays': activeWeekdays,
      'settlementFrequency': settlementFrequency,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    List<int> parsedWeekdays = const [1, 2, 3, 4, 5, 6, 7];
    if (map['activeWeekdays'] is List) {
      parsedWeekdays = (map['activeWeekdays'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }

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
      serviceScheduleType: map['serviceScheduleType'] ?? 'all_week',
      daysPerWeek: (map['daysPerWeek'] as num?)?.toInt() ?? 7,
      activeWeekdays: parsedWeekdays,
      settlementFrequency: map['settlementFrequency'] ?? 'weekly',
    );
  }
}
