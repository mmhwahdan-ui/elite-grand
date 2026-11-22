class CaregiverModel {
  final String id;
  final String code; // كود مقدم الخدمة (e.g. CG-001)
  final String name; // الاسم
  final String nationalId; // الرقم القومي (14 رقم)
  final String phone; // رقم التليفون
  final String qualification; // المؤهل
  final String address; // العنوان التفصيلي
  final String residenceArea; // مكان السكن / المنطقة / المحافظة
  final double? weight; // الوزن بالكيلوجرام
  final double? height; // الطول بالسنتيمتر
  final String shiftPreference; // 'hours12' | 'hours24' | 'both'
  final double dailyPrice; // سعره / اليومية الافتراضية
  final double rating; // التقييم من 1 إلى 5
  final bool isBlocked; // حظره بسبب مشاكل
  final String? blockReason; // نوع المشكلة / سبب الحظر
  final bool hasWorkedWithUs; // إذا كان قد اشتغل مع شركتنا من قبل
  final List<String> pastClients; // أسماء العملاء الذين اشتغل معهم
  final bool isCurrentlyWorking; // شغال معانا الآن
  final String? currentClientName; // اسم الحالة التي يعمل فيها حالياً
  final double openingBalance; // رصيد سابق: (+) مستحق للممرض عن خدمة قديمة لم يحصلها / (-) سلف أو مديونية على الممرض
  final String? notes; // ملاحظات إضافية
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // wahdan / shimaa
  final bool hasLoginAccount; // هل لديه حساب دخول للنظام
  final String? loginUsername; // اسم المستخدم للدخول
  final String? loginPassword; // كلمة المرور للدخول
  final DateTime? lastSmsSentAt; // تاريخ ووقت آخر إرسال لرسالة SMS
  final double? lastLatitude; // آخر خط عرض للموقع الجغرافي
  final double? lastLongitude; // آخر خط طول للموقع الجغرافي
  final double? lastLocationAccuracy; // دقة تحديد الموقع بالأمتار
  final DateTime? lastLocationUpdate; // وقت آخر تحديث للموقع
  final String? lastLocationSource; // مصدر رصد الموقع (nurse_phone | shift_checkin | shift_checkout | admin_manual)

  CaregiverModel({
    required this.id,
    required this.code,
    required this.name,
    this.nationalId = '',
    this.phone = '',
    this.qualification = '',
    this.address = '',
    this.residenceArea = '',
    this.weight,
    this.height,
    this.shiftPreference = 'both',
    this.dailyPrice = 0.0,
    this.rating = 5.0,
    this.isBlocked = false,
    this.blockReason,
    this.hasWorkedWithUs = false,
    this.pastClients = const [],
    this.isCurrentlyWorking = false,
    this.currentClientName,
    this.openingBalance = 0.0,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy = 'shimaa',
    this.hasLoginAccount = false,
    this.loginUsername,
    this.loginPassword,
    this.lastSmsSentAt,
    this.lastLatitude,
    this.lastLongitude,
    this.lastLocationAccuracy,
    this.lastLocationUpdate,
    this.lastLocationSource,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get hasLocation => lastLatitude != null && lastLongitude != null;
  String? get locationMapsUrl => hasLocation ? 'https://www.google.com/maps?q=$lastLatitude,$lastLongitude' : null;

  bool get hasVerifiedNurseLocation =>
      hasLocation && (lastLocationSource == 'nurse_phone' || lastLocationSource == 'shift_checkin' || lastLocationSource == 'shift_checkout');

  String get locationSourceArabic {
    switch (lastLocationSource) {
      case 'shift_checkin':
        return 'إثبات حضور وردية من هاتف الممرض 📱';
      case 'shift_checkout':
        return 'إثبات انصراف وردية من هاتف الممرض 🏁';
      case 'nurse_phone':
        return 'تحديث مباشر من هاتف الممرض 📲';
      case 'admin_manual':
        return 'تعيين يدوي من الإدارة 🏢';
      default:
        return 'إثبات حضور وردية 📍';
    }
  }

  String get shiftPreferenceArabic {
    switch (shiftPreference) {
      case 'hours12':
        return '12 ساعة فقط';
      case 'hours24':
        return '24 ساعة (إقامة)';
      case 'both':
      default:
        return 'متاح للاثنين (12 و 24 ساعة)';
    }
  }

  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      final heightInMeters = height! / 100.0;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  CaregiverModel copyWith({
    String? id,
    String? code,
    String? name,
    String? nationalId,
    String? phone,
    String? qualification,
    String? address,
    String? residenceArea,
    double? weight,
    double? height,
    String? shiftPreference,
    double? dailyPrice,
    double? rating,
    bool? isBlocked,
    String? blockReason,
    bool? hasWorkedWithUs,
    List<String>? pastClients,
    bool? isCurrentlyWorking,
    String? currentClientName,
    bool clearCurrentClient = false,
    double? openingBalance,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? hasLoginAccount,
    String? loginUsername,
    String? loginPassword,
    DateTime? lastSmsSentAt,
    double? lastLatitude,
    double? lastLongitude,
    double? lastLocationAccuracy,
    DateTime? lastLocationUpdate,
    String? lastLocationSource,
  }) {
    return CaregiverModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      nationalId: nationalId ?? this.nationalId,
      phone: phone ?? this.phone,
      qualification: qualification ?? this.qualification,
      address: address ?? this.address,
      residenceArea: residenceArea ?? this.residenceArea,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      shiftPreference: shiftPreference ?? this.shiftPreference,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      rating: rating ?? this.rating,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: blockReason ?? this.blockReason,
      hasWorkedWithUs: hasWorkedWithUs ?? this.hasWorkedWithUs,
      pastClients: pastClients ?? this.pastClients,
      isCurrentlyWorking: isCurrentlyWorking ?? this.isCurrentlyWorking,
      currentClientName: clearCurrentClient ? null : (currentClientName ?? this.currentClientName),
      openingBalance: openingBalance ?? this.openingBalance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
      hasLoginAccount: hasLoginAccount ?? this.hasLoginAccount,
      loginUsername: loginUsername ?? this.loginUsername,
      loginPassword: loginPassword ?? this.loginPassword,
      lastSmsSentAt: lastSmsSentAt ?? this.lastSmsSentAt,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastLocationAccuracy: lastLocationAccuracy ?? this.lastLocationAccuracy,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      lastLocationSource: lastLocationSource ?? this.lastLocationSource,
    );
  }

  CaregiverModel clearLocation() {
    return CaregiverModel(
      id: id,
      code: code,
      name: name,
      nationalId: nationalId,
      phone: phone,
      qualification: qualification,
      address: address,
      residenceArea: residenceArea,
      weight: weight,
      height: height,
      shiftPreference: shiftPreference,
      dailyPrice: dailyPrice,
      rating: rating,
      isBlocked: isBlocked,
      blockReason: blockReason,
      hasWorkedWithUs: hasWorkedWithUs,
      pastClients: pastClients,
      isCurrentlyWorking: isCurrentlyWorking,
      currentClientName: currentClientName,
      openingBalance: openingBalance,
      notes: notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      hasLoginAccount: hasLoginAccount,
      loginUsername: loginUsername,
      loginPassword: loginPassword,
      lastSmsSentAt: lastSmsSentAt,
      lastLatitude: null,
      lastLongitude: null,
      lastLocationAccuracy: null,
      lastLocationUpdate: null,
      lastLocationSource: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'nationalId': nationalId,
      'phone': phone,
      'qualification': qualification,
      'address': address,
      'residenceArea': residenceArea,
      'weight': weight,
      'height': height,
      'shiftPreference': shiftPreference,
      'dailyPrice': dailyPrice,
      'rating': rating,
      'isBlocked': isBlocked,
      'blockReason': blockReason,
      'hasWorkedWithUs': hasWorkedWithUs,
      'pastClients': pastClients,
      'isCurrentlyWorking': isCurrentlyWorking,
      'currentClientName': currentClientName,
      'openingBalance': openingBalance,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'hasLoginAccount': hasLoginAccount,
      'loginUsername': loginUsername,
      'loginPassword': loginPassword,
      'lastSmsSentAt': lastSmsSentAt?.toIso8601String(),
      if (lastLatitude != null) 'lastLatitude': lastLatitude,
      if (lastLongitude != null) 'lastLongitude': lastLongitude,
      if (lastLocationAccuracy != null) 'lastLocationAccuracy': lastLocationAccuracy,
      if (lastLocationUpdate != null) 'lastLocationUpdate': lastLocationUpdate!.toIso8601String(),
      if (lastLocationSource != null) 'lastLocationSource': lastLocationSource,
    };
  }

  factory CaregiverModel.fromMap(Map<String, dynamic> map) {
    return CaregiverModel(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      nationalId: map['nationalId'] ?? '',
      phone: map['phone'] ?? '',
      qualification: map['qualification'] ?? '',
      address: map['address'] ?? '',
      residenceArea: map['residenceArea'] ?? '',
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      shiftPreference: map['shiftPreference'] ?? 'both',
      dailyPrice: (map['dailyPrice'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      isBlocked: map['isBlocked'] ?? false,
      blockReason: map['blockReason'],
      hasWorkedWithUs: map['hasWorkedWithUs'] ?? false,
      pastClients: (map['pastClients'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isCurrentlyWorking: map['isCurrentlyWorking'] ?? false,
      currentClientName: map['currentClientName'],
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      createdBy: map['createdBy'] ?? 'shimaa',
      hasLoginAccount: map['hasLoginAccount'] ?? false,
      loginUsername: map['loginUsername'],
      loginPassword: map['loginPassword'],
      lastSmsSentAt: map['lastSmsSentAt'] != null ? DateTime.tryParse(map['lastSmsSentAt']) : null,
      lastLatitude: (map['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (map['lastLongitude'] as num?)?.toDouble(),
      lastLocationAccuracy: (map['lastLocationAccuracy'] as num?)?.toDouble(),
      lastLocationUpdate: map['lastLocationUpdate'] != null ? DateTime.tryParse(map['lastLocationUpdate']) : null,
      lastLocationSource: map['lastLocationSource'],
    );
  }
}
