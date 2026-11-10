import 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart' as sound_impl;

class SoundService {
  static void playNotificationSound() {
    try {
      sound_impl.playNotificationAlert();
    } catch (_) {}
  }
}
