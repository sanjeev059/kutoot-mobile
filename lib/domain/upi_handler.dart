import '../utils/upi_app_launch.dart';
import 'payment_models.dart';

/// Handles `upi://pay` style intents (Google Pay / PhonePe / Paytm / BHIM).
///
/// **Bill pay via Razorpay Orders:** use [RazorpayHandler] UPI intent — the SDK
/// completes payment and returns `payment_id` for verify.
///
/// Use [launchDirectUpiIntent] only when the backend adds `merchant_upi_vpa`
/// (and you have a verify/polling path), e.g. `use_direct_upi: true` on the order.
class UpiHandler {
  UpiHandler._();

  static bool shouldUseDirectIntent(RazorpayOrderContext ctx) {
    final o = ctx.order;
    if (o['use_direct_upi'] != true) return false;
    final vpa = o['merchant_upi_vpa']?.toString() ?? o['vpa']?.toString();
    return vpa != null && vpa.isNotEmpty;
  }

  /// Returns `true` if a UPI URI was launched (user left the app).
  static Future<bool> launchDirectUpiIntent({
    required RazorpayOrderContext ctx,
    required String upiAppPackage,
    required double amountRupees,
    String payeeName = 'Merchant',
    String? transactionRef,
  }) async {
    final vpa = ctx.order['merchant_upi_vpa']?.toString() ??
        ctx.order['vpa']?.toString();
    if (vpa == null || vpa.isEmpty) return false;
    final amountStr = amountRupees.toStringAsFixed(2);
    final tr = transactionRef ?? ctx.orderId;
    return launchUpiForAndroidPackage(
      packageName: upiAppPackage.isEmpty ? 'any' : upiAppPackage,
      payeeVpa: vpa,
      payeeName: ctx.order['merchant_name']?.toString() ?? payeeName,
      amountRupees: amountStr,
      transactionRef: tr,
    );
  }
}
