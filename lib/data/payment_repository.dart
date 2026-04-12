import 'package:dio/dio.dart';

import '../api/kutoot_api.dart';
import '../domain/payment_models.dart';

/// Data layer: create/verify payments via backend (Razorpay Orders on Kutoot API).
class PaymentRepository {
  PaymentRepository(this._api);

  final KutootApi _api;

  Future<Response<dynamic>> payWithoutCoupon(Map<String, dynamic> data) =>
      _api.payWithoutCoupon(data);

  Future<Response<dynamic>> verifyPayment(Map<String, dynamic> data) =>
      _api.verifyPayment(data);

  /// Parses `pay-without-coupon` JSON when a Razorpay order is returned.
  static RazorpayOrderContext? parseRazorpayOrderFromPayResponse(dynamic data) {
    final body = data is Map ? data : {};
    final result = body['data'] is Map ? body['data'] as Map : body;
    final order = result['order'] is Map ? result['order'] as Map : {};
    final key = order['key']?.toString();
    final orderId = order['id']?.toString();
    final orderAmount = order['amount'] is int
        ? order['amount'] as int
        : int.tryParse('${order['amount']}') ?? 0;
    if (key == null ||
        key.isEmpty ||
        orderId == null ||
        orderId.isEmpty ||
        orderAmount <= 0) {
      return null;
    }
    return RazorpayOrderContext(
      key: key,
      orderId: orderId,
      amountPaise: orderAmount,
      order: order,
    );
  }
}
