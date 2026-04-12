import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/razorpay_native_android.dart';
import '../services/razorpay_order_checkout.dart';
import 'payment_models.dart';

/// Razorpay Standard checkout: hosted (cards / NB / UPI ID) or UPI app intent.
class RazorpayHandler {
  RazorpayHandler._();

  static Future<void> openFullCheckout({
    required Razorpay flutterPlugin,
    required RazorpayOrderContext ctx,
    String description = 'Payment',
    String themeColor = '#E23744',
    String? prefillContact10,
    String? prefillEmail,
  }) async {
    final options = buildRazorpayOrderCheckoutOptions(
      key: ctx.key,
      orderId: ctx.orderId,
      orderAmountPaise: ctx.amountPaise,
      order: ctx.order,
      description: description,
      themeColor: themeColor,
      prefillContact10: prefillContact10,
      prefillEmail: prefillEmail,
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await RazorpayNativeAndroid.open(options);
    } else {
      flutterPlugin.open(options);
    }
  }

  static Future<void> openUpiIntentCheckout({
    required Razorpay flutterPlugin,
    required RazorpayOrderContext ctx,
    required String upiAppPackage,
    String description = 'Payment',
    String themeColor = '#E23744',
    String? prefillContact10,
    String? prefillEmail,
  }) async {
    final options = buildRazorpayUpiIntentOnlyOptions(
      key: ctx.key,
      orderId: ctx.orderId,
      orderAmountPaise: ctx.amountPaise,
      order: ctx.order,
      description: description,
      themeColor: themeColor,
      prefillContact10: prefillContact10,
      prefillEmail: prefillEmail,
      upiAppPackage: upiAppPackage,
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await RazorpayNativeAndroid.open(options);
    } else {
      flutterPlugin.open(options);
    }
  }
}
