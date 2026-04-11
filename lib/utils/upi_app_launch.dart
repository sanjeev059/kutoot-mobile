import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launch India UPI apps with a payee + amount (NPCI-style query params).
/// Falls back through several URI schemes so the right app opens when installed.
Future<bool> launchUpiForApp({
  required _UpiAppTarget app,
  required String payeeVpa,
  required String payeeName,
  required String amountRupees,
  String transactionNote = 'Kutoot bill',
  String? transactionRef,
}) async {
  if (payeeVpa.isEmpty) return false;
  final pn = Uri.encodeComponent(payeeName.isEmpty ? 'Merchant' : payeeName);
  final am = Uri.encodeComponent(amountRupees);
  final tn = Uri.encodeComponent(transactionNote);
  final tr = transactionRef != null && transactionRef.isNotEmpty
      ? '&tr=${Uri.encodeComponent(transactionRef)}'
      : '';
  final base =
      'pa=${Uri.encodeComponent(payeeVpa)}&pn=$pn&am=$am&cu=INR&tn=$tn$tr';

  final candidates = switch (app) {
    _UpiAppTarget.phonepe => [
        'phonepe://pay?$base',
        'upi://pay?$base',
      ],
    _UpiAppTarget.paytm => [
        'paytmmp://pay?$base',
        'upi://pay?$base',
      ],
    _UpiAppTarget.googlePay => [
        'tez://upi/pay?$base',
        'gpay://upi/pay?$base',
        'upi://pay?$base',
      ],
    _UpiAppTarget.bhim => [
        'bhim://pay?$base',
        'upi://pay?$base',
      ],
    _UpiAppTarget.any => ['upi://pay?$base'],
  };

  for (final raw in candidates) {
    final uri = Uri.tryParse(raw);
    if (uri == null) continue;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e, st) {
      debugPrint('launchUpiForApp $raw: $e\n$st');
    }
  }
  return false;
}

enum _UpiAppTarget { phonepe, paytm, googlePay, bhim, any }

Future<bool> launchPhonePeUpi({
  required String payeeVpa,
  required String payeeName,
  required String amountRupees,
  String? transactionRef,
}) =>
    launchUpiForApp(
      app: _UpiAppTarget.phonepe,
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amountRupees: amountRupees,
      transactionRef: transactionRef,
    );

Future<bool> launchPaytmUpi({
  required String payeeVpa,
  required String payeeName,
  required String amountRupees,
  String? transactionRef,
}) =>
    launchUpiForApp(
      app: _UpiAppTarget.paytm,
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amountRupees: amountRupees,
      transactionRef: transactionRef,
    );

Future<bool> launchGooglePayUpi({
  required String payeeVpa,
  required String payeeName,
  required String amountRupees,
  String? transactionRef,
}) =>
    launchUpiForApp(
      app: _UpiAppTarget.googlePay,
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amountRupees: amountRupees,
      transactionRef: transactionRef,
    );

Future<bool> launchBhimUpi({
  required String payeeVpa,
  required String payeeName,
  required String amountRupees,
  String? transactionRef,
}) =>
    launchUpiForApp(
      app: _UpiAppTarget.bhim,
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amountRupees: amountRupees,
      transactionRef: transactionRef,
    );

Future<bool> launchGenericUpiChooser({
  required String payeeVpa,
  required String payeeName,
  required String amountRupees,
  String? transactionRef,
}) =>
    launchUpiForApp(
      app: _UpiAppTarget.any,
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amountRupees: amountRupees,
      transactionRef: transactionRef,
    );
