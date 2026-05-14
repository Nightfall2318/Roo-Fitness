import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _unitKey = 'unit';
  static const String _incrementKey = 'increment';

  static Future<String> getUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_unitKey) ?? 'KG';
  }

  static Future<void> setUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, unit);
  }

  static Future<double> getIncrement() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_incrementKey) ?? 2.5;
  }

  static Future<void> setIncrement(double increment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_incrementKey, increment);
  }
}
