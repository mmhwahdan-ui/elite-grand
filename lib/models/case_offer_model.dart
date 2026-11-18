class CaseApplicantModel {
  final String caregiverId;
  final String caregiverName;
  final String caregiverCode;
  final String phone;
  final String nurseUserId;
  final DateTime appliedAt;
  final String notes;
  final String status; // 'applied', 'contacted', 'approved', 'rejected'

  CaseApplicantModel({
    required this.caregiverId,
    required this.caregiverName,
    this.caregiverCode = '',
    this.phone = '',
    this.nurseUserId = '',
    DateTime? appliedAt,
    this.notes = '',
    this.status = 'applied',
  }) : appliedAt = appliedAt ?? DateTime.now();

  CaseApplicantModel copyWith({
    String? caregiverId,
    String? caregiverName,
    String? caregiverCode,
    String? phone,
    String? nurseUserId,
    DateTime? appliedAt,
    String? notes,
    String? status,
  }) {
    return CaseApplicantModel(
      caregiverId: caregiverId ?? this.caregiverId,
      caregiverName: caregiverName ?? this.caregiverName,
      caregiverCode: caregiverCode ?? this.caregiverCode,
      phone: phone ?? this.phone,
      nurseUserId: nurseUserId ?? this.nurseUserId,
      appliedAt: appliedAt ?? this.appliedAt,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'caregiverCode': caregiverCode,
      'phone': phone,
      'nurseUserId': nurseUserId,
      'appliedAt': appliedAt.toIso8601String(),
      'notes': notes,
      'status': status,
    };
  }

  factory CaseApplicantModel.fromMap(Map<String, dynamic> map) {
    return CaseApplicantModel(
      caregiverId: map['caregiverId']?.toString() ?? '',
      caregiverName: map['caregiverName']?.toString() ?? '',
      caregiverCode: map['caregiverCode']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      nurseUserId: map['nurseUserId']?.toString() ?? '',
      appliedAt: map['appliedAt'] != null
          ? DateTime.tryParse(map['appliedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes']?.toString() ?? '',
      status: map['status']?.toString() ?? 'applied',
    );
  }
}

class CaseOfferModel {
  final String id;
  final String code; // e.g. CASE-001
  final String title; // عنوان الحالة (مثال: رعاية مسن - المعادي)
  final String patientDescription; // تفاصيل ووصف الحالة المرضية
  final String city; // المحافظة أو المدينة (مثل: القاهرة)
  final String area; // الحي أو المنطقة (مثل: المعادي، التجمع)
  final String shiftType; // 'hours12', 'hours24', 'hours8', 'hours10', 'custom'
  final double nurseDailyPrice; // سعر التمريض / اليومية المحددة لمقدم الخدمة
  final String genderPreference; // 'any', 'male', 'female'
  final String requirements; // متطلبات إضافية (قسطرة، أنبوبة تغذية، غير مدخن...)
  final String clientName; // اسم العميل (كامل للإدارة، مختصر للتمريض)
  final String clientPhone; // هاتف العميل (خاص بالإدارة فقط - مخفي تماماً عن التمريض)
  final double clientDailyPrice; // سعر العميل المتفق عليه (خاص بالإدارة فقط - مخفي تماماً عن التمريض)
  final String status; // 'open', 'under_review', 'assigned', 'closed'
  final String postedByUserId; // معرف ناشر الحالة (شيماء أو وهدان)
  final String postedByUserName; // اسم ناشر الحالة
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<CaseApplicantModel> applicants;
  final String? assignedCaregiverId;
  final String? assignedCaregiverName;
  final DateTime? assignedAt;
  final String? notes;

  CaseOfferModel({
    required this.id,
    required this.code,
    required this.title,
    required this.patientDescription,
    required this.city,
    required this.area,
    this.shiftType = 'hours12',
    required this.nurseDailyPrice,
    this.genderPreference = 'any',
    this.requirements = '',
    this.clientName = '',
    this.clientPhone = '',
    this.clientDailyPrice = 0.0,
    this.status = 'open',
    this.postedByUserId = 'usr_shimaa',
    this.postedByUserName = 'أ/ شيماء',
    DateTime? createdAt,
    this.updatedAt,
    this.applicants = const [],
    this.assignedCaregiverId,
    this.assignedCaregiverName,
    this.assignedAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOpen => status == 'open';
  bool get isAssigned => status == 'assigned';
  bool get isUnderReview => status == 'under_review';
  String get cityRegion => area.isNotEmpty ? '$city - $area' : city;

  String get shiftTypeArabic {
    switch (shiftType) {
      case 'hours12':
        return 'وردية 12 ساعة';
      case 'hours24':
        return 'إقامة كاملة 24 ساعة';
      case 'hours8':
        return 'وردية 8 ساعات';
      case 'hours10':
        return 'وردية 10 ساعات';
      case 'custom':
        return 'ساعات مخصصة';
      default:
        return 'وردية 12 ساعة';
    }
  }

  String get statusArabic {
    switch (status) {
      case 'open':
        return 'متاح للتقديم 📢';
      case 'under_review':
        return 'قيد الاتفاق والمراجعة ⏳';
      case 'assigned':
        return 'تم التسكين والإتمام بنجاح ✅';
      case 'closed':
        return 'مغلق 🔒';
      default:
        return 'متاح للتقديم';
    }
  }

  String get genderPreferenceArabic {
    switch (genderPreference) {
      case 'male':
        return 'ممرض (ذكر)';
      case 'female':
        return 'ممرضة (أنثى)';
      default:
        return 'غير محدد (متاح للجميع)';
    }
  }

  CaseOfferModel copyWith({
    String? id,
    String? code,
    String? title,
    String? patientDescription,
    String? city,
    String? area,
    String? shiftType,
    double? nurseDailyPrice,
    String? genderPreference,
    String? requirements,
    String? clientName,
    String? clientPhone,
    double? clientDailyPrice,
    String? status,
    String? postedByUserId,
    String? postedByUserName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CaseApplicantModel>? applicants,
    String? assignedCaregiverId,
    String? assignedCaregiverName,
    DateTime? assignedAt,
    String? notes,
  }) {
    return CaseOfferModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      patientDescription: patientDescription ?? this.patientDescription,
      city: city ?? this.city,
      area: area ?? this.area,
      shiftType: shiftType ?? this.shiftType,
      nurseDailyPrice: nurseDailyPrice ?? this.nurseDailyPrice,
      genderPreference: genderPreference ?? this.genderPreference,
      requirements: requirements ?? this.requirements,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientDailyPrice: clientDailyPrice ?? this.clientDailyPrice,
      status: status ?? this.status,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedByUserName: postedByUserName ?? this.postedByUserName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      applicants: applicants ?? this.applicants,
      assignedCaregiverId: assignedCaregiverId ?? this.assignedCaregiverId,
      assignedCaregiverName: assignedCaregiverName ?? this.assignedCaregiverName,
      assignedAt: assignedAt ?? this.assignedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'patientDescription': patientDescription,
      'city': city,
      'area': area,
      'shiftType': shiftType,
      'nurseDailyPrice': nurseDailyPrice,
      'genderPreference': genderPreference,
      'requirements': requirements,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientDailyPrice': clientDailyPrice,
      'status': status,
      'postedByUserId': postedByUserId,
      'postedByUserName': postedByUserName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'applicants': applicants.map((a) => a.toMap()).toList(),
      'assignedCaregiverId': assignedCaregiverId,
      'assignedCaregiverName': assignedCaregiverName,
      'assignedAt': assignedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory CaseOfferModel.fromMap(Map<String, dynamic> map) {
    List<CaseApplicantModel> applicantsList = [];
    if (map['applicants'] is List) {
      applicantsList = (map['applicants'] as List)
          .map((a) => CaseApplicantModel.fromMap(Map<String, dynamic>.from(a)))
          .toList();
    }

    return CaseOfferModel(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      patientDescription: map['patientDescription']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      shiftType: map['shiftType']?.toString() ?? 'hours12',
      nurseDailyPrice: (map['nurseDailyPrice'] as num?)?.toDouble() ?? 0.0,
      genderPreference: map['genderPreference']?.toString() ?? 'any',
      requirements: map['requirements']?.toString() ?? '',
      clientName: map['clientName']?.toString() ?? '',
      clientPhone: map['clientPhone']?.toString() ?? '',
      clientDailyPrice: (map['clientDailyPrice'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'open',
      postedByUserId: map['postedByUserId']?.toString() ?? 'usr_shimaa',
      postedByUserName: map['postedByUserName']?.toString() ?? 'أ/ شيماء',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
      applicants: applicantsList,
      assignedCaregiverId: map['assignedCaregiverId']?.toString(),
      assignedCaregiverName: map['assignedCaregiverName']?.toString(),
      assignedAt: map['assignedAt'] != null
          ? DateTime.tryParse(map['assignedAt'].toString())
          : null,
      notes: map['notes']?.toString(),
    );
  }
}
