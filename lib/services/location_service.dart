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
  /// جلب الموقع الجغرافي الحالي (GPS) بدقة عالية
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
}
