class ServiceDayModel {
  final String id;
  final String clientId;
  final String clientName;
  final DateTime date;
  final String nurseName; // الممرض الذي نفذ الخدمة في هذا اليوم
  final String shiftType; // 'hours12' (12 ساعة) or 'hours24' (24 ساعة)
  final double clientPrice; // سعر هذا اليوم المحسوب على العميل
  final double nursePrice; // يومية الممرض المستحقة في هذا اليوم
  final String notes;
  final String recordedBy;
  final DateTime createdAt;

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
  });

  // Gross profit for this specific day
  double get companyDayProfit => clientPrice - nursePrice;

  String get shiftTypeArabic {
    switch (shiftType) {
      case 'hours24':
        return 'إقامة 24 ساعة';
      case 'hours12':
      default:
        return 'وردية 12 ساعة';
    }
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
    );
  }
}
