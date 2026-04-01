import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider with ChangeNotifier {
  static const _keySeen = 'onboarding_seen';

  bool _hasSeen = false;
  bool _loading = true;

  bool get hasSeen => _hasSeen;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeen = prefs.getBool(_keySeen) ?? false;
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markSeen() async {
    _hasSeen = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySeen, true);
    } catch (_) {}
  }
}
