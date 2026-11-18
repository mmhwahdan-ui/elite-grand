import 'package:flutter/services.dart';

void playNotificationAlert([String soundType = 'general']) {
  SystemSound.play(SystemSoundType.alert);
}
