import 'dart:js_interop';

@JS('playEliteGrandAlertSound')
external void _playEliteGrandAlertSound([JSString? soundType]);

void playNotificationAlert([String soundType = 'general']) {
  try {
    _playEliteGrandAlertSound(soundType.toJS);
  } catch (_) {
    // Fallback if not ready
  }
}
