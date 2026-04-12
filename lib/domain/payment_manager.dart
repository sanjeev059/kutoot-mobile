import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../data/payment_repository.dart';
import 'payment_models.dart';
import 'razorpay_handler.dart';
import 'upi_handler.dart';

/// Domain facade: [PaymentRepository] + [UpiHandler] + [RazorpayHandler].
///
/// Typical bill pay: create order via [PaymentRepository.payWithoutCoupon],
/// parse [RazorpayOrderContext], then either:
/// - [openRazorpayUpiIntent] for PhonePe/GPay/Paytm (Razorpay SDK intent), or
/// - [openRazorpayHosted] for cards / netbanking / UPI ID in Razorpay UI.
///
/// Optional: if backend sets `use_direct_upi` + `merchant_upi_vpa`, [tryDirectUpiOrRazorpay]
/// opens raw `upi://pay` first, then falls back to Razorpay UPI intent.
class PaymentManager {
  PaymentManager(this.repository);

  final PaymentRepository repository;

  Future<void> openRazorpayHosted({
    required Razorpay flutterPlugin,
    required RazorpayOrderContext ctx,
    String description = 'Bill Payment',
    String themeColor = '#E23744',
    String? prefillContact10,
    String? prefillEmail,
  }) =>
      RazorpayHandler.openFullCheckout(
        flutterPlugin: flutterPlugin,
        ctx: ctx,
        description: description,
        themeColor: themeColor,
        prefillContact10: prefillContact10,
        prefillEmail: prefillEmail,
      );

  Future<void> openRazorpayUpiIntent({
    required Razorpay flutterPlugin,
    required RazorpayOrderContext ctx,
    required String upiAppPackage,
    String description = 'Bill Payment',
    String themeColor = '#E23744',
    String? prefillContact10,
    String? prefillEmail,
  }) =>
      RazorpayHandler.openUpiIntentCheckout(
        flutterPlugin: flutterPlugin,
        ctx: ctx,
        upiAppPackage: upiAppPackage,
        description: description,
        themeColor: themeColor,
        prefillContact10: prefillContact10,
        prefillEmail: prefillEmail,
      );

  /// Direct NPCI intent when API allows; otherwise Razorpay UPI intent.
  Future<void> tryDirectUpiOrRazorpay({
    required Razorpay flutterPlugin,
    required RazorpayOrderContext ctx,
    required String upiAppPackage,
    required double amountRupees,
    String description = 'Bill Payment',
    String themeColor = '#E23744',
    String? prefillContact10,
    String? prefillEmail,
  }) async {
    if (UpiHandler.shouldUseDirectIntent(ctx)) {
      final ok = await UpiHandler.launchDirectUpiIntent(
        ctx: ctx,
        upiAppPackage: upiAppPackage,
        amountRupees: amountRupees,
      );
      if (ok) return;
    }
    await openRazorpayUpiIntent(
      flutterPlugin: flutterPlugin,
      ctx: ctx,
      upiAppPackage: upiAppPackage,
      description: description,
      themeColor: themeColor,
      prefillContact10: prefillContact10,
      prefillEmail: prefillEmail,
    );
  }
}
