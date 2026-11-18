import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'location_service.dart';

Future<GeoLocationResult?> getPlatformLocation() async {
  final completer = Completer<GeoLocationResult?>();
  int? watchId;
  Timer? timeoutTimer;
  GeoLocationResult? bestResult;

  void finish(GeoLocationResult? res) {
    if (timeoutTimer != null && timeoutTimer!.isActive) {
      timeoutTimer!.cancel();
    }
    if (watchId != null) {
      try {
        web.window.navigator.geolocation.clearWatch(watchId!);
      } catch (_) {}
      watchId = null;
    }
    if (!completer.isCompleted) {
      completer.complete(res);
    }
  }

  // مهلة أمان قصوى 7 ثوانٍ لجمع أفضل عينة من أقمار الـ GPS
  timeoutTimer = Timer(const Duration(milliseconds: 7000), () {
    if (bestResult != null) {
      finish(bestResult);
    } else {
      _fallbackSingleShot(completer);
    }
  });

  try {
    // تفعيل watchPosition لاستقبال تدفق الإشارات واختيار أدق نقطة فور قفل الأقمار الصناعية (Satellite Lock)
    watchId = web.window.navigator.geolocation.watchPosition(
      (web.GeolocationPosition pos) {
        final lat = pos.coords.latitude;
        final lng = pos.coords.longitude;
        final acc = pos.coords.accuracy;

        final current = GeoLocationResult(
          latitude: lat,
          longitude: lng,
          accuracy: acc,
          timestamp: DateTime.now(),
        );

        // الاحتفاظ بالعينة ذات نطاق الخطأ الأقل (أعلى دقة بالأمتار)
        if (bestResult == null || (acc > 0 && acc < (bestResult!.accuracy ?? 999999))) {
          bestResult = current;
        }

        // إذا تم قفل الأقمار بدقة عالية ممتازة (أقل من أو يساوي 25 متر)، نكتفي فوراً وننهي الطلب
        if (acc > 0 && acc <= 25.0) {
          finish(bestResult);
        }
      }.toJS,
      (web.GeolocationPositionError err) {
        if (bestResult != null) {
          finish(bestResult);
        } else {
          final msg = err.message.isNotEmpty
              ? err.message
              : 'تعذر تحديد الموقع الجغرافي، يرجى تفعيل الـ GPS في هاتفك';
          finish(GeoLocationResult.error(msg));
        }
      }.toJS,
      web.PositionOptions(
        enableHighAccuracy: true,
        timeout: 6500,
        maximumAge: 0, // منع استخدام أي بيانات مسبقة قديمة لبرج الاتصال
      ),
    );
  } catch (e) {
    _fallbackSingleShot(completer);
  }

  return completer.future;
}

void _fallbackSingleShot(Completer<GeoLocationResult?> completer) {
  try {
    web.window.navigator.geolocation.getCurrentPosition(
      (web.GeolocationPosition pos) {
        final lat = pos.coords.latitude;
        final lng = pos.coords.longitude;
        final acc = pos.coords.accuracy;
        if (!completer.isCompleted) {
          completer.complete(GeoLocationResult(
            latitude: lat,
            longitude: lng,
            accuracy: acc,
            timestamp: DateTime.now(),
          ));
        }
      }.toJS,
      (web.GeolocationPositionError err) {
        final msg = err.message.isNotEmpty
            ? err.message
            : 'تعذر تحديد الموقع الجغرافي، يرجى تفعيل الـ GPS في هاتفك';
        if (!completer.isCompleted) {
          completer.complete(GeoLocationResult.error(msg));
        }
      }.toJS,
      web.PositionOptions(
        enableHighAccuracy: true,
        timeout: 8000,
        maximumAge: 0,
      ),
    );
  } catch (e) {
    if (!completer.isCompleted) {
      completer.complete(GeoLocationResult.error('خطأ في طلب الموقع: $e'));
    }
  }
}

void openPlatformMap(String url) {
  try {
    web.window.open(url, '_blank');
  } catch (_) {}
}
