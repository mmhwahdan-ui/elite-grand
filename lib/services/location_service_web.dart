import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'location_service.dart';

Future<GeoLocationResult?> getPlatformLocation() async {
  final completer = Completer<GeoLocationResult?>();

  try {
    web.window.navigator.geolocation.getCurrentPosition(
      (web.GeolocationPosition pos) {
        final lat = pos.coords.latitude;
        final lng = pos.coords.longitude;
        final acc = pos.coords.accuracy;
        completer.complete(GeoLocationResult(
          latitude: lat,
          longitude: lng,
          accuracy: acc,
          timestamp: DateTime.now(),
        ));
      }.toJS,
      (web.GeolocationPositionError err) {
        final msg = err.message.isNotEmpty
            ? err.message
            : 'تعذر تحديد الموقع الجغرافي، يرجى تفعيل الـ GPS في متصفحك';
        completer.complete(GeoLocationResult.error(msg));
      }.toJS,
      web.PositionOptions(
        enableHighAccuracy: true,
        timeout: 12000,
        maximumAge: 30000,
      ),
    );
  } catch (e) {
    completer.complete(GeoLocationResult.error('خطأ في طلب الموقع: $e'));
  }

  return completer.future;
}

void openPlatformMap(String url) {
  try {
    web.window.open(url, '_blank');
  } catch (_) {}
}
