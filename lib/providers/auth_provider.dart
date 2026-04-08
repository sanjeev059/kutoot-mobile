import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/kutoot_api.dart';
import '../services/device_service.dart';

class AuthProvider with ChangeNotifier {
  static const _prefsLastMobileKey = 'last_login_mobile_digits';

  final _api = KutootApi();
  final _device = DeviceService();

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _hasChecked = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get hasChecked => _hasChecked;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> checkAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _api.readAuthToken();
      if (token == null || token.isEmpty) {
        final restored = await _tryRestoreDeviceSession();
        if (!restored) {
          _user = null;
        }
      } else {
        try {
          final res = await _api.getUser();
          final wrapper = res.data is Map
              ? Map<String, dynamic>.from(res.data as Map)
              : null;
          _user = wrapper != null && wrapper['data'] is Map
              ? Map<String, dynamic>.from(wrapper['data'] as Map)
              : wrapper;
        } catch (e) {
          _user = null;
          if (e is DioException && e.response?.statusCode == 401) {
            final restored = await _tryRestoreDeviceSession();
            if (!restored) {
              _user = null;
            }
          }
        }
      }
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      _hasChecked = true;
      notifyListeners();
    }
  }

  /// Server recognizes this device (FCM row or users.device_id) → new token without OTP.
  Future<bool> _tryRestoreDeviceSession() async {
    try {
      await _device.getDeviceFingerprint();
      final res = await _api.restoreSession();
      final wrapper =
          res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
      final data = wrapper != null && wrapper['data'] is Map
          ? Map<String, dynamic>.from(wrapper['data'] as Map)
          : wrapper;
      if (data != null && data['token'] != null) {
        await _api.setToken(data['token'] as String);
        _user = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : null;
        await _persistLastMobileFromUser();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('restoreSession: $e');
      }
    }
    return false;
  }

  static Future<String?> loadLastLoginMobileDigits() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_prefsLastMobileKey);
    if (v == null || v.length != 10) return null;
    return v;
  }

  Future<void> _persistLastMobileFromUser() async {
    final m = _user?['mobile']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
    if (m.length == 10) {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefsLastMobileKey, m);
    } else if (m.length == 12 && m.startsWith('91')) {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefsLastMobileKey, m.substring(2));
    }
  }

  Future<(bool, String?)> sendOtp(String identifier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deviceId = await _device.getDeviceFingerprint();
      final res = await _api.sendOtp(identifier, deviceId: deviceId);
      final wrapper =
          res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
      final data = wrapper != null && wrapper['data'] is Map
          ? Map<String, dynamic>.from(wrapper['data'] as Map)
          : wrapper;
      final debugOtp = data?['debug_otp']?.toString();
      _isLoading = false;
      notifyListeners();
      return (true, debugOtp);
    } catch (e) {
      _error = _parseOtpError(e);
      _isLoading = false;
      notifyListeners();
      return (false, null);
    }
  }

  Future<bool> verifyOtp(String identifier, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deviceId = await _device.getDeviceFingerprint();
      final res = await _api.verifyOtp(identifier, otp,
          deviceId: deviceId, deviceModel: _device.deviceModel);
      final wrapper =
          res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
      final data = wrapper != null && wrapper['data'] is Map
          ? Map<String, dynamic>.from(wrapper['data'] as Map)
          : wrapper;
      if (data != null && data['token'] != null) {
        await _api.setToken(data['token'] as String);
        _user = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : null;
        _enrichPhoneFromIdentifier(identifier);
        await _persistLastMobileFromUser();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = _parseVerifyError(e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _api.clearAuth();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Merge fields into the cached user (e.g. after profile update API).
  void mergeUserFields(Map<String, dynamic> patch) {
    if (_user == null) {
      _user = Map<String, dynamic>.from(patch);
    } else {
      _user = {..._user!, ...patch};
    }
    notifyListeners();
  }

  void _enrichPhoneFromIdentifier(String identifier) {
    if (_user == null) return;
    final mobile = _user!['mobile']?.toString().trim() ?? '';
    final phone = _user!['phone']?.toString().trim() ?? '';
    if (mobile.isNotEmpty || phone.isNotEmpty) return;
    final raw = identifier.trim().replaceAll(RegExp(r'\s'), '');
    if (raw.isEmpty || raw.contains('@')) return;
    if (RegExp(r'^\+?\d{7,15}$').hasMatch(raw)) {
      _user!['mobile'] = raw;
    }
  }

  static String _parseVerifyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'] as String;
      }
      if (e.response?.statusCode == 403) {
        return 'This device is already linked to another account.';
      }
    }
    return 'Invalid or expired OTP';
  }

  static String _parseOtpError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'] as String;
      }
      if (data is Map && data['errors'] != null) {
        final errs = data['errors'];
        if (errs is Map && errs['identifier'] != null) {
          final list = errs['identifier'];
          return list is List && list.isNotEmpty
              ? list.first.toString()
              : 'Invalid phone or email';
        }
      }
      if (status == 422) return 'Invalid phone or email';
      if (status != null && status >= 500) {
        return 'Server error. Please try again later.';
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Cannot reach server. Check your connection or try again.';
      }
    }
    return 'Failed to send OTP. Please try again.';
  }
}
