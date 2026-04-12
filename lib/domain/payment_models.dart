/// Domain models for Zomato-style payment (order → sheet → Razorpay / UPI intent).
class RazorpayOrderContext {
  const RazorpayOrderContext({
    required this.key,
    required this.orderId,
    required this.amountPaise,
    required this.order,
  });

  final String key;
  final String orderId;
  final int amountPaise;
  final Map<dynamic, dynamic> order;
}
