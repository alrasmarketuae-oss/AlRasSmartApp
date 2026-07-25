import 'package:shared_preferences/shared_preferences.dart';

class CachHelper {
  static SharedPreferences? sharedPreferences;

  static init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (value is String) return await sharedPreferences!.setString(key, value);
    if (value is bool) return await sharedPreferences!.setBool(key, value);
    if (value is int) return await sharedPreferences!.setInt(key, value);
    return await sharedPreferences!.setDouble(key, value);
  }

  static getData(String key) {
    print('Data:$key:');
    return sharedPreferences!.get(key);
  }

  static Future<bool> removeData(String key) async {
    return await sharedPreferences!.remove(key);
  }

  static Future<bool> removeAllData() async {
    return await sharedPreferences!.clear();
  }

  static const String languageCode = 'languageCode';

  Future<void> setLanguage(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageCode, code);
  }

  Future<String> getLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(languageCode) ?? 'en';
  }
}
