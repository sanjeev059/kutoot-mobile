import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

void _logRazorpayOptionsForDebug(Map<String, dynamic> options) {
  if (!kDebugMode) return;
  final flow = options['_[flow]'];
  final pkg = options['upi_app_package_name'];
  final method = options['method'];
  final oid = options['order_id'];
  final key = options['key']?.toString() ?? '';
  final keyMasked =
      key.length <= 8 ? '***' : '${key.substring(0, 8)}…';
  debugPrint(
    '[RazorpayNative] flow=$flow order_id=$oid key=$keyMasked '
    'method=$method upi_pkg=$pkg webview_intent=${options['webview_intent']}',
  );
}

/// Opens Razorpay via [Checkout.open] on the host [FlutterActivity] (Android only).
/// Improves UPI **intent** vs the plugin’s CheckoutActivity/WebView collect flow.
class RazorpayNativeAndroid {
  static const _ch = MethodChannel('com.kutoot.app/razorpay_native');

  static void bind({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    required void Function(ExternalWalletResponse) onExternalWallet,
  }) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSuccess':
          final m = Map<String, dynamic>.from(call.arguments as Map);
          onSuccess(
            PaymentSuccessResponse(
              m['razorpay_payment_id']?.toString(),
              m['razorpay_order_id']?.toString(),
              m['razorpay_signature']?.toString(),
              m,
            ),
          );
          break;
        case 'onError':
          final m = Map<String, dynamic>.from(call.arguments as Map);
          final c = m['code'];
          onError(
            PaymentFailureResponse(
              c is int ? c : int.tryParse('$c') ?? 100,
              m['message']?.toString(),
              null,
            ),
          );
          break;
        case 'onExternalWallet':
          final m = Map<String, dynamic>.from(call.arguments as Map);
          onExternalWallet(ExternalWalletResponse(m['walletName']?.toString()));
          break;
      }
    });
  }

  static void unbind() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _ch.setMethodCallHandler(null);
  }

  static Future<void> open(Map<String, dynamic> options) async {
    _logRazorpayOptionsForDebug(options);
    // Shows in logcat as `flutter` tag: `adb logcat -s flutter` (release/profile too).
    print('[RazorpayNative] invoking native Checkout.open');
    try {
      await _ch.invokeMethod<void>('open', {'options': options});
    } on PlatformException catch (e, st) {
      debugPrint(
        '[RazorpayNative] PlatformException ${e.code} ${e.message} '
        'details=${e.details}',
      );
      debugPrint('$st');
      rethrow;
    }
  }
}
