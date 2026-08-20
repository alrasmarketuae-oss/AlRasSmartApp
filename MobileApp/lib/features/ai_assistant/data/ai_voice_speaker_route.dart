import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Forces loudspeaker output so the call is audible without holding the phone
/// to the ear (iOS playAndRecord otherwise routes to the receiver).
class AiVoiceSpeakerRoute {
  AiVoiceSpeakerRoute._();

  static AudioContext get context => AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioMode: AndroidAudioMode.normal,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: const {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.allowBluetoothA2DP,
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      );

  static Future<void> apply() async {
    try {
      await AudioPlayer.global.setAudioContext(context);
    } catch (e) {
      debugPrint('Voice speaker route failed: $e');
    }
  }
}
