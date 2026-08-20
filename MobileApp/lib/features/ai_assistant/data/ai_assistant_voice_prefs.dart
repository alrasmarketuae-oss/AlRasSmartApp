import 'package:shared_preferences/shared_preferences.dart';

class AiAssistantVoicePrefs {
  static const genderKey = 'ai.assistant.voice.gender';

  static Future<bool> isMale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(genderKey) == 'male';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setMale(bool male) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(genderKey, male ? 'male' : 'female');
  }
}
