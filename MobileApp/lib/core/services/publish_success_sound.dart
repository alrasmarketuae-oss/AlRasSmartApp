import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays after create/edit ad succeeds and the backend response is received.
class PublishSuccessSound {
  PublishSuccessSound._();

  static final PublishSuccessSound instance = PublishSuccessSound._();

  static const assetPath = 'sounds/publish_success.mpeg';

  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  Future<void> playOnce() async {
    if (_playing) return;
    _playing = true;
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('PublishSuccessSound play failed: $e');
    } finally {
      _playing = false;
    }
  }
}
