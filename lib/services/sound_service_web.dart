import 'dart:js_interop';

@JS('playEliteGrandAlertSound')
external void _playEliteGrandAlertSound();

void playNotificationAlert() {
  try {
    _playEliteGrandAlertSound();
  } catch (_) {
    // Fallback if not ready
  }
}
