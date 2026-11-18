import 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart' as sound_impl;

class SoundService {
  static void playNotificationSound([String soundType = 'general']) {
    try {
      sound_impl.playNotificationAlert(soundType);
    } catch (_) {}
  }

  /// صوت عالي جداً للشات الداخلي للإدارة
  static void playAdminChatSound() => playNotificationSound('admin_chat');

  /// صوت عالي احتفالي لفرصة حالة تمريض جديدة
  static void playOpportunitySound() => playNotificationSound('opportunity');

  /// صوت عالي مميز لرسالة خاصة من الإدارة لمقدم الخدمة
  static void playAdminMessageSound() => playNotificationSound('admin_message');
}
