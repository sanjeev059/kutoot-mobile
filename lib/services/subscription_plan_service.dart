import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionPlanService {
  static const String _currentPlanKey = 'kutoot_current_plan_name';

  static Future<void> setCurrentPlanName(String planName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentPlanKey, planName.toUpperCase());
  }

  static Future<String?> getCurrentPlanName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentPlanKey);
  }

  static Future<void> clearCurrentPlanName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentPlanKey);
  }
}
