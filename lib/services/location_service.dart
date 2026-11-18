import 'dart:math';
import 'location_service_stub.dart'
    if (dart.library.js_interop) 'location_service_web.dart' as platform;

class GeoLocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final bool isSuccess;
  final String? errorMessage;

  GeoLocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    DateTime? timestamp,
    this.isSuccess = true,
    this.errorMessage,
  }) : timestamp = timestamp ?? DateTime.now();

  factory GeoLocationResult.error(String msg) {
    return GeoLocationResult(
      latitude: 0.0,
      longitude: 0.0,
      isSuccess: false,
      errorMessage: msg,
    );
  }

  /// هل دقة التحديد ممتازة (GPS أقمار صناعية <= 35 متر)
  bool get isHighPrecision => isSuccess && (accuracy != null && accuracy! <= 35.0);

  /// هل دقة التحديد مقبولة (واي فاي / A-GPS)
  bool get isModeratePrecision => isSuccess && (accuracy != null && accuracy! > 35.0 && accuracy! <= 100.0);

  /// هل دقة التحديد تقريبية / ضعيفة (برج اتصال أو شبكة هاتف)
  bool get isCoarsePrecision => isSuccess && (accuracy == null || accuracy! > 100.0);

  /// وصف الدقة بالعربية
  String get accuracyDescriptionArabic {
    if (!isSuccess) return errorMessage ?? 'فشل تحديد الموقع';
    if (accuracy == null) return 'تم تحديد الموقع (دقة غير محددة)';
    final acc = accuracy!.toStringAsFixed(0);
    if (accuracy! <= 30) return '🎯 دقة ممتازة (GPS أقمار صناعية: ±$acc متر)';
    if (accuracy! <= 80) return '🟢 دقة جيدة (±$acc متر)';
    return '⚠️ دقة تقريبية (±$acc متر - شبكة محمول/داخل مبنى)';
  }

  String get googleMapsUrl => 'https://www.google.com/maps?q=$latitude,$longitude';

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'isSuccess': isSuccess,
    };
  }

  factory GeoLocationResult.fromMap(Map<String, dynamic> map) {
    return GeoLocationResult(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      isSuccess: map['isSuccess'] ?? true,
    );
  }
}

class LocationService {
  /// جلب الموقع الجغرافي الحالي (GPS) بدقة عالية مع تنقية متعددة للعينات
  static Future<GeoLocationResult?> getCurrentLocation() async {
    return await platform.getPlatformLocation();
  }

  /// فتح إحداثيات الموقع على خرائط Google Maps
  static void openCoordinatesOnMap(double lat, double lng) {
    final url = 'https://www.google.com/maps?q=$lat,$lng';
    openMapUrl(url);
  }

  /// فتح رابط الخريطة في تبويب مستقل
  static void openMapUrl(String url) {
    platform.openPlatformMap(url);
  }

  /// حساب المسافة بين نقطتين بالأمتار (Haversine Formula)
  static double calculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }
}
