import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native [upi://pay] resolver list (Android). Empty on non-Android.
class UpiInstalledApp {
  const UpiInstalledApp({required this.packageName, required this.label});
  final String packageName;
  final String label;
}

class UpiAppsAndroid {
  static const _ch = MethodChannel('com.kutoot.app/upi_apps');

  static Future<List<UpiInstalledApp>> listInstalled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const [];
    }
    try {
      final raw = await _ch.invokeMethod<List<dynamic>>('listInstalledUpiApps');
      if (raw == null) return const [];
      return raw
          .whereType<Map>()
          .map((e) => UpiInstalledApp(
                packageName: e['packageName']?.toString() ?? '',
                label: e['label']?.toString() ?? '',
              ))
          .where((e) => e.packageName.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
