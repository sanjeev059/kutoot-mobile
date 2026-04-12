import 'package:dio/dio.dart';

/// Turns API / Dio errors into short copy for SnackBars (401 → sign-in hint).
String userFacingApiError(Object error) {
  if (error is DioException) {
    final code = error.response?.statusCode;
    if (code == 401) {
      return 'Please sign in with your mobile number to continue.';
    }
    final data = error.response?.data;
    if (data is Map) {
      final raw = data['message']?.toString().trim() ?? '';
      if (raw.isNotEmpty) {
        final lower = raw.toLowerCase();
        if (lower.contains('unauthenticated')) {
          return 'Please sign in with your mobile number to continue.';
        }
        if (raw != 'undefined') return raw;
      }
    }
    final m = error.message;
    if (m != null && m.isNotEmpty) return m;
  }
  return error.toString();
}
