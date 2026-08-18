/// ChatGPT-style TTS tuning and natural voice selection for the AI assistant.
class AiAssistantTtsVoice {
  AiAssistantTtsVoice._();

  /// iOS default utterance rate is ~0.5; ChatGPT speaks at natural pace.
  static const double femaleSpeechRate = 0.51;
  static const double maleSpeechRate = 0.5;

  /// Neutral pitch — close to OpenAI voice mode (not cartoonish).
  static const double femalePitch = 1.02;
  static const double malePitch = 0.97;

  static const _femalePreferred = [
    'amira',
    'laila',
    'mariam',
    'zira',
    'samantha',
    'moira',
    'karen',
    'tessa',
    'serena',
    'zoe',
    'nova',
    'shimmer',
    'siri_female',
    'x-sfg',
    'x-gba',
    'x-iog',
    'x-tpf',
  ];

  static const _malePreferred = [
    'hamed',
    'hamid',
    'tarik',
    'majed',
    'maged',
    'daniel',
    'aaron',
    'fred',
    'alex',
    'gordon',
    'onyx',
    'echo',
    'x-sfm',
    'x-gbb',
    'x-iom',
    'x-iod',
  ];

  static const _femaleBlocked = [
    ' man',
    ' boy',
    ' masculine',
    'hamed',
    'hamid',
    'tarik',
    'majed',
    'maged',
    'daniel',
    'aaron',
    'fred',
    'alex',
    'gordon',
    'onyx',
    'echo',
    'x-iom',
    'x-iod',
    'x-gbb',
    'x-sfm',
  ];

  static const _maleBlocked = [
    'female',
    ' woman',
    ' girl',
    ' feminine',
    'amira',
    'laila',
    'mariam',
    'zira',
    'samantha',
    'moira',
    'karen',
    'tessa',
    'serena',
    'nova',
    'shimmer',
    'x-sfg',
    'x-gba',
    'x-iog',
    'x-tpf',
  ];

  static bool _isBlocked(String blob, {required bool isFemale}) {
    final blocked = isFemale ? _femaleBlocked : _maleBlocked;
    for (final hint in blocked) {
      if (blob.contains(hint)) return true;
    }
    // Match standalone "male" but not "female".
    if (isFemale && RegExp(r'(?<!fe)male').hasMatch(blob)) return true;
    return false;
  }

  static double speechRateFor({required bool isFemale}) =>
      isFemale ? femaleSpeechRate : maleSpeechRate;

  static double pitchFor({required bool isFemale}) =>
      isFemale ? femalePitch : malePitch;

  static String previewPhrase(String langCode) =>
      langCode == 'ar'
          ? 'مرحباً، أنا مساعدك في الراس الذكي.'
          : "Hi, I'm your Al Ras Smart assistant.";

  /// Picks the best on-device voice map for [isFemale] and [langCode].
  static Map<String, String>? pickVoicePayload({
    required List<dynamic> voices,
    required bool isFemale,
    required String langCode,
  }) {
    final preferred = isFemale ? _femalePreferred : _malePreferred;
    Map<String, String>? best;
    var bestScore = -999999;
    Map<String, String>? fallback;
    var fallbackScore = -999999;

    for (final raw in voices) {
      if (raw is! Map) continue;
      final payload = _voicePayload(raw);
      if (payload == null) continue;

      final blob = '${payload['name']} ${payload['locale']}'.toLowerCase();
      if (_isBlocked(blob, isFemale: isFemale)) continue;

      var score = 0;
      for (var i = 0; i < preferred.length; i++) {
        final hint = preferred[i];
        if (blob.contains(hint)) {
          score += 120 - i;
        }
      }

      if (blob.contains('enhanced') ||
          blob.contains('premium') ||
          blob.contains('neural') ||
          blob.contains('wavenet')) {
        score += 25;
      }
      if (blob.contains('compact') || blob.contains('eloquence')) {
        score += 8;
      }

      final locale = payload['locale']!.toLowerCase();
      final matchesLang = langCode == 'ar'
          ? locale.startsWith('ar')
          : locale.startsWith('en');

      if (matchesLang) {
        if (score > bestScore) {
          best = payload;
          bestScore = score;
        }
      } else if (score > fallbackScore) {
        fallback = payload;
        fallbackScore = score;
      }
    }

    return best ?? fallback;
  }

  static String signature(Map<String, String>? payload) {
    if (payload == null) return '';
    return '${payload['name']}|${payload['locale']}';
  }

  static Map<String, String>? _voicePayload(Map raw) {
    final name = raw['name']?.toString().trim();
    if (name == null || name.isEmpty) return null;
    final locale = raw['locale']?.toString().trim();
    return {
      'name': name,
      if (locale != null && locale.isNotEmpty) 'locale': locale,
    };
  }
}
