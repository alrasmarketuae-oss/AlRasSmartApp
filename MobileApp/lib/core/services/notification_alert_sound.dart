import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the same alert ding used by the admin web dashboard.
class NotificationAlertSound {
  NotificationAlertSound._();

  static final NotificationAlertSound instance = NotificationAlertSound._();

  static const assetPath = 'sounds/notification_ding.mp3';

  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  Future<void> playOnce() async {
    if (_playing) return;
    _playing = true;
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('NotificationAlertSound play failed: $e');
    } finally {
      _playing = false;
    }
  }
}
