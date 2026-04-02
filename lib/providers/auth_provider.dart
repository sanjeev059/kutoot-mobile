import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/kutoot_api.dart';

class AuthProvider with ChangeNotifier {
  final _api = KutootApi();

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
      final res = await _api.getUser();
      final wrapper = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
      _user = wrapper != null && wrapper['data'] is Map
          ? Map<String, dynamic>.from(wrapper['data'] as Map)
          : null;
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      _hasChecked = true;
      notifyListeners();
    }
  }

  /// Returns (success, debugOtp). Backend may return debug_otp in the response on non-production.
  Future<(bool, String?)> sendOtp(String identifier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.sendOtp(identifier);
      final wrapper = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
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
      final res = await _api.verifyOtp(identifier, otp);
      final wrapper = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
      final data = wrapper != null && wrapper['data'] is Map
          ? Map<String, dynamic>.from(wrapper['data'] as Map)
          : wrapper;
      if (data != null && data['token'] != null) {
        await _api.setToken(data['token'] as String);
        _user = data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Invalid or expired OTP';
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
          return list is List && list.isNotEmpty ? list.first.toString() : 'Invalid phone or email';
        }
      }
      if (status == 422) return 'Invalid phone or email';
      if (status != null && status >= 500) return 'Server error. Please try again later.';
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Cannot reach server. Check your connection or try again.';
      }
      if (e.type == DioExceptionType.unknown && e.error?.toString().contains('CORS') == true) {
        return 'Connection blocked. If using web, try running on a device/emulator.';
      }
    }
    return 'Failed to send OTP. Please try again.';
  }
}
