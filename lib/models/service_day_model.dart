class ServiceDayModel {
  final String id;
  final String clientId;
  final String clientName;
  final DateTime date;
  final String nurseName; // الممرض الذي نفذ الخدمة في هذا اليوم
  final String shiftType; // 'hours8', 'hours10', 'hours12', 'hours24', 'custom'
  final double clientPrice; // سعر هذا اليوم المحسوب على العميل
  final double nursePrice; // يومية الممرض المستحقة في هذا اليوم
  final String notes;
  final String recordedBy;
  final DateTime createdAt;
  final String? startTime; // وقت استلام الخدمة (مثلاً 08:00 ص)
  final String? endTime; // وقت إنهاء الخدمة والتسليم (مثلاً 08:00 م)
  final double? hoursCount; // عدد ساعات العمل الفعلي (مثلاً 12 أو 24 أو 8)

  ServiceDayModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.date,
    required this.nurseName,
    this.shiftType = 'hours12',
    required this.clientPrice,
    required this.nursePrice,
    this.notes = '',
    required this.recordedBy,
    required this.createdAt,
    this.startTime,
    this.endTime,
    this.hoursCount,
  });

  // Gross profit for this specific day
  double get companyDayProfit => clientPrice - nursePrice;

  String get shiftTypeArabic {
    switch (shiftType) {
      case 'hours24':
        return 'إقامة 24 ساعة';
      case 'hours12':
        return 'وردية 12 ساعة';
      case 'hours10':
        return 'وردية 10 ساعات';
      case 'hours8':
        return 'وردية 8 ساعات';
      case 'custom':
        return hoursCount != null ? 'وردية ${hoursCount!.toStringAsFixed(0)} ساعة' : 'ساعات مخصصة';
      default:
        return 'وردية 12 ساعة';
    }
  }

  String get timeRangeDisplay {
    final hasStart = startTime != null && startTime!.trim().isNotEmpty;
    final hasEnd = endTime != null && endTime!.trim().isNotEmpty;
    if (hasStart && hasEnd) {
      return 'من $startTime إلى $endTime';
    } else if (hasStart) {
      return 'استلام: $startTime';
    } else if (hasEnd) {
      return 'إنهاء: $endTime';
    }
    return '';
  }

  ServiceDayModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    DateTime? date,
    String? nurseName,
    String? shiftType,
    double? clientPrice,
    double? nursePrice,
    String? notes,
    String? recordedBy,
    DateTime? createdAt,
    String? startTime,
    String? endTime,
    double? hoursCount,
  }) {
    return ServiceDayModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      nurseName: nurseName ?? this.nurseName,
      shiftType: shiftType ?? this.shiftType,
      clientPrice: clientPrice ?? this.clientPrice,
      nursePrice: nursePrice ?? this.nursePrice,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hoursCount: hoursCount ?? this.hoursCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'date': date.toIso8601String(),
      'nurseName': nurseName,
      'shiftType': shiftType,
      'clientPrice': clientPrice,
      'nursePrice': nursePrice,
      'notes': notes,
      'recordedBy': recordedBy,
      'createdAt': createdAt.toIso8601String(),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (hoursCount != null) 'hoursCount': hoursCount,
    };
  }

  factory ServiceDayModel.fromMap(Map<String, dynamic> map) {
    return ServiceDayModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      nurseName: map['nurseName'] ?? 'ممرض غير محدد',
      shiftType: map['shiftType'] ?? 'hours12',
      clientPrice: (map['clientPrice'] as num?)?.toDouble() ?? 0.0,
      nursePrice: (map['nursePrice'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      recordedBy: map['recordedBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      startTime: map['startTime'],
      endTime: map['endTime'],
      hoursCount: (map['hoursCount'] as num?)?.toDouble(),
    );
  }
}
