import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const _keyPush = 'settings_push';
  static const _keyEmail = 'settings_email';
  static const _keySms = 'settings_sms';
  static const _keyBiometric = 'settings_biometric';
  static const _keyDark = 'settings_dark';

  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _biometricLogin = false;
  bool _darkMode = false;

  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get smsNotifications => _smsNotifications;
  bool get biometricLogin => _biometricLogin;
  bool get darkMode => _darkMode;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pushNotifications = prefs.getBool(_keyPush) ?? true;
      _emailNotifications = prefs.getBool(_keyEmail) ?? true;
      _smsNotifications = prefs.getBool(_keySms) ?? false;
      _biometricLogin = prefs.getBool(_keyBiometric) ?? false;
      _darkMode = prefs.getBool(_keyDark) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setPushNotifications(bool v) async {
    _pushNotifications = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_keyPush, v);
  }

  Future<void> setEmailNotifications(bool v) async {
    _emailNotifications = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_keyEmail, v);
  }

  Future<void> setSmsNotifications(bool v) async {
    _smsNotifications = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_keySms, v);
  }

  Future<void> setBiometricLogin(bool v) async {
    _biometricLogin = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_keyBiometric, v);
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_keyDark, v);
  }
}
