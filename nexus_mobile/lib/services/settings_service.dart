import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  Future<void> saveTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', dark);
  }

  Future<bool> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? true;
  }
}
