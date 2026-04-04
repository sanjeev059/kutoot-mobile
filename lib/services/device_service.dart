import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._();
  factory DeviceService() => _instance;
  DeviceService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
  );

  String? _deviceId;
  String? _deviceModel;

  String? get deviceId => _deviceId;
  String? get deviceModel => _deviceModel;

  /// Returns a unique, persistent device fingerprint.
  /// Uses Android ID (survives app reinstalls, unique per device).
  /// Falls back to a stored UUID if Android ID is unavailable.
  Future<String> getDeviceFingerprint() async {
    if (_deviceId != null) return _deviceId!;

    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;

      // Android ID: unique per device + app signing key combo,
      // persists across installs
      _deviceId = android.id;
      _deviceModel =
          '${android.manufacturer} ${android.model} (Android ${android.version.release})';

      if (_deviceId != null && _deviceId!.isNotEmpty) {
        await _storage.write(key: 'device_fingerprint', value: _deviceId);
        return _deviceId!;
      }
    } catch (e) {
      debugPrint('Failed to get Android device info: $e');
    }

    // Fallback: read from storage or generate new
    _deviceId = await _storage.read(key: 'device_fingerprint');
    if (_deviceId == null || _deviceId!.isEmpty) {
      _deviceId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      await _storage.write(key: 'device_fingerprint', value: _deviceId);
    }
    return _deviceId!;
  }

  Future<Map<String, String>> getDeviceHeaders() async {
    final fp = await getDeviceFingerprint();
    return {
      'X-Device-Id': fp,
      if (_deviceModel != null) 'X-Device-Model': _deviceModel!,
    };
  }
}
