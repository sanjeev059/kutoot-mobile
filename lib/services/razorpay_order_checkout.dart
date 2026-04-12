import 'package:flutter/foundation.dart';

/// Normalizes to 10-digit Indian mobile for Razorpay [prefill.contact] (no +91).
String? normalizeRazorpayContact10(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  var d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length == 12 && d.startsWith('91')) d = d.substring(2);
  if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
  if (d.length == 10) return d;
  return null;
}

/// Picks the first valid 10-digit Indian mobile from typical `/me` user fields.
String? resolveRazorpayContactFromUser(Map<String, dynamic>? user) {
  if (user == null) return null;
  for (final key in [
    'mobile',
    'phone',
    'phone_number',
    'contact',
    'phoneNumber',
  ]) {
    final n = normalizeRazorpayContact10(user[key]?.toString());
    if (n != null) return n;
  }
  return null;
}

/// Razorpay **order** checkout (Orders API + `order_id`).
///
/// [prefillContact10] — skips the “Contact details” step when valid.
/// On Android, [webview_intent] enables UPI **intent** in the hosted checkout (do not
/// set [method.upi] to a nested map — that hides the UPI row; booleans only if needed).
Map<String, dynamic> buildRazorpayOrderCheckoutOptions({
  required String key,
  required String orderId,
  required int orderAmountPaise,
  required Map<dynamic, dynamic> order,
  String merchantName = 'Kutoot',
  String description = 'Payment',
  String themeColor = '#AE1E3F',
  String? prefillContact10,
  String? prefillEmail,
}) {
  final options = <String, dynamic>{
    'key': key,
    'amount': orderAmountPaise.toString(),
    'currency': order['currency'] ?? 'INR',
    'name': order['merchant_name'] ?? merchantName,
    'description': description,
    'order_id': orderId,
    'theme.color': themeColor,
  };

  final contact = normalizeRazorpayContact10(prefillContact10);
  if (contact != null) {
    final prefill = <String, dynamic>{'contact': contact};
    if (prefillEmail != null && prefillEmail.trim().isNotEmpty) {
      prefill['email'] = prefillEmail.trim();
    }
    options['prefill'] = prefill;
    options['prefill.contact'] = contact;
    if (prefillEmail != null && prefillEmail.trim().isNotEmpty) {
      options['prefill.email'] = prefillEmail.trim();
    }
    final ro = <String, dynamic>{'contact': true};
    if (prefillEmail != null && prefillEmail.trim().isNotEmpty) {
      ro['email'] = true;
    }
    options['readonly'] = ro;
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    options['webview_intent'] = true;
  }

  return options;
}

/// UPI **intent-only** checkout (after user picked an app in-app). Opens the PSP
/// or system chooser instead of UPI Collect (@VPA). Non-Android falls back to
/// [buildRazorpayOrderCheckoutOptions].
///
/// [upiAppPackage] — Android package id, or `''` for system UPI chooser.
Map<String, dynamic> buildRazorpayUpiIntentOnlyOptions({
  required String key,
  required String orderId,
  required int orderAmountPaise,
  required Map<dynamic, dynamic> order,
  String merchantName = 'Kutoot',
  String description = 'Payment',
  String themeColor = '#AE1E3F',
  String? prefillContact10,
  String? prefillEmail,
  required String upiAppPackage,
}) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return buildRazorpayOrderCheckoutOptions(
      key: key,
      orderId: orderId,
      orderAmountPaise: orderAmountPaise,
      order: order,
      merchantName: merchantName,
      description: description,
      themeColor: themeColor,
      prefillContact10: prefillContact10,
      prefillEmail: prefillEmail,
    );
  }

  final options = buildRazorpayOrderCheckoutOptions(
    key: key,
    orderId: orderId,
    orderAmountPaise: orderAmountPaise,
    order: order,
    merchantName: merchantName,
    description: description,
    themeColor: themeColor,
    prefillContact10: prefillContact10,
    prefillEmail: prefillEmail,
  );

  // Native Checkout.open (not an embedded WebView): `true` is for hosted WebView UPI intent docs; `false` often helps direct PSP launch.
  options['webview_intent'] = false;
  options['_[flow]'] = 'intent';
  options['display_logo'] = false;
  if (upiAppPackage.isNotEmpty) {
    options['upi_app_package_name'] = upiAppPackage;
  }

  // Razorpay Android docs: `method` = JSONObject with upi: true + upi_app_package_name.
  final locked = normalizeRazorpayContact10(prefillContact10);
  options['method'] = <String, dynamic>{'upi': true};

  // Without `readonly`, Razorpay often re-prompts for mobile before UPI intent.
  // With a valid prefill + readonly.contact, the logged-in number is used and locked.
  if (locked != null) {
    options['readonly'] = <String, dynamic>{
      'contact': true,
      if (prefillEmail != null && prefillEmail.trim().isNotEmpty) 'email': true,
    };
  } else {
    options.remove('readonly');
  }

  return options;
}
