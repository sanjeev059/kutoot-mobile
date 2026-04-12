import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../api/kutoot_api.dart';
import '../../providers/auth_provider.dart';
import '../../services/razorpay_native_android.dart';
import '../../services/razorpay_order_checkout.dart';
import '../../theme/app_theme.dart';
import '../../widgets/zomato_payment_bottom_sheet.dart';
import '../payment/upi_app_select_screen.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _api = KutootApi();
  List<Map<String, dynamic>> _coupons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getCoupons();
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        final payload = data['data'] as Map;
        final plan = payload['plan_coupons'] is List
            ? payload['plan_coupons'] as List
            : <dynamic>[];
        final store = payload['store_coupons'] is List
            ? payload['store_coupons'] as List
            : <dynamic>[];
        final other = payload['other_coupons'] is List
            ? payload['other_coupons'] as List
            : <dynamic>[];

        List<Map<String, dynamic>> cast(List<dynamic> source, String segment) {
          return source
              .whereType<Map>()
              .map((e) => <String, dynamic>{
                    ...Map<String, dynamic>.from(e),
                    'segment_label': segment
                  })
              .toList();
        }

        _coupons = [
          ...cast(store, 'Store'),
          ...cast(plan, 'Plan'),
          ...cast(other, 'Other')
        ];
      } else if (data is Map && data['data'] is List) {
        _coupons = (data['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (data is List) {
        _coupons = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Coupons',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _coupons.isEmpty
                  ? const Center(child: Text('No coupons yet'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _coupons.length,
                        itemBuilder: (context, i) {
                          final c = _coupons[i];
                          return _CouponCard(
                            coupon: c,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CouponDetailScreen(
                                    couponId: c['id'] is int
                                        ? c['id'] as int
                                        : int.tryParse('${c['id']}') ?? 0,
                                    coupon: c),
                              ),
                            ).then((_) => _load()),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final VoidCallback onTap;

  const _CouponCard({required this.coupon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = coupon['name'] ?? coupon['title'] ?? 'Coupon';
    final desc = coupon['description'] ?? '';
    final status = coupon['status'] ?? '';
    final segment = coupon['segment_label']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_offer_rounded,
              color: AppTheme.primary, size: 28),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: desc.isNotEmpty
            ? Text(desc.toString(),
                maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (segment != null && segment.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(segment,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue)),
              ),
            if (status.toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status.toString(),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class CouponDetailScreen extends StatefulWidget {
  final int couponId;
  final Map coupon;

  const CouponDetailScreen(
      {super.key, required this.couponId, required this.coupon});

  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends State<CouponDetailScreen> {
  final _api = KutootApi();
  late final Razorpay _razorpay;
  final _amountController = TextEditingController(text: '100');
  Map<String, dynamic>? _coupon;
  bool _loading = true;
  String? _error;
  bool _paying = false;
  int? _pendingTransactionId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _coupon = Map<String, dynamic>.from(widget.coupon);
    _load();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _api.getCoupon(widget.couponId);
      if (res.data is Map && mounted) {
        final raw = res.data as Map;
        final mapped = raw['data'] is Map ? raw['data'] as Map : raw;
        setState(() {
          _coupon = Map<String, dynamic>.from(mapped);
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _startRedeemPayment() async {
    if (_paying) return;
    final c = _coupon ?? {};
    final couponId =
        c['id'] is int ? c['id'] as int : int.tryParse('${c['id']}');
    final merchant =
        c['merchant_location'] is Map ? c['merchant_location'] as Map : null;
    final merchantLocationId = merchant?['id'] is int
        ? merchant!['id'] as int
        : int.tryParse('${merchant?['id']}');
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (couponId == null || merchantLocationId == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Coupon payment needs valid amount and merchant location')),
      );
      return;
    }

    setState(() => _paying = true);
    try {
      final res = await _api.redeemCoupon(couponId, {
        'amount': amount,
        'merchant_location_id': merchantLocationId,
      });
      final body = res.data is Map ? res.data as Map : {};
      final result = body['data'] is Map ? body['data'] as Map : body;

      if (result['zero_amount'] == true) {
        if (!mounted) return;
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message']?.toString() ??
                  'Coupon redeemed successfully')),
        );
        await _load();
        return;
      }

      final order = result['order'] is Map ? result['order'] as Map : {};
      final key = order['key']?.toString();
      final orderId = order['id']?.toString();
      final orderAmount = order['amount'] is int
          ? order['amount'] as int
          : int.tryParse('${order['amount']}') ?? 0;
      _pendingTransactionId = result['transaction_id'] is int
          ? result['transaction_id'] as int
          : null;

      if (key == null ||
          key.isEmpty ||
          orderId == null ||
          orderId.isEmpty ||
          orderAmount <= 0) {
        throw Exception('Invalid payment order returned by server');
      }

      if (!mounted) return;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final choice = await showZomatoPaymentBottomSheet(
          context,
          amountInRupees: orderAmount / 100.0,
        );
        if (!mounted) return;
        if (choice == null) {
          setState(() => _paying = false);
          return;
        }
        if (choice == kutootRazorpayFullCheckout) {
          await _openCouponRazorpay(
            key: key,
            orderId: orderId,
            orderAmountPaise: orderAmount,
            order: Map<dynamic, dynamic>.from(order),
          );
        } else {
          await _openCouponRazorpayUpiIntent(
            key: key,
            orderId: orderId,
            orderAmountPaise: orderAmount,
            order: Map<dynamic, dynamic>.from(order),
            upiAppPackage: choice,
          );
        }
      } else {
        await _openCouponRazorpay(
          key: key,
          orderId: orderId,
          orderAmountPaise: orderAmount,
          order: Map<dynamic, dynamic>.from(order),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment init failed: $e')),
      );
    }
  }

  Future<void> _openCouponRazorpay({
    required String key,
    required String orderId,
    required int orderAmountPaise,
    required Map<dynamic, dynamic> order,
  }) async {
    if (!mounted) return;
    setState(() => _paying = true);
    final user = context.read<AuthProvider>().user;
    var contact10 = resolveRazorpayContactFromUser(
      user != null ? Map<String, dynamic>.from(user) : null,
    );
    contact10 ??= await AuthProvider.loadLastLoginMobileDigits();
    final email = user?['email']?.toString();

    final options = buildRazorpayOrderCheckoutOptions(
      key: key,
      orderId: orderId,
      orderAmountPaise: orderAmountPaise,
      order: order,
      description: 'Coupon Payment',
      themeColor: '#AE1E3F',
      prefillContact10: contact10,
      prefillEmail: email,
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await RazorpayNativeAndroid.open(options);
      } catch (e) {
        if (!mounted) return;
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payment: $e')),
        );
      }
    } else {
      _razorpay.open(options);
    }
  }

  Future<void> _openCouponRazorpayUpiIntent({
    required String key,
    required String orderId,
    required int orderAmountPaise,
    required Map<dynamic, dynamic> order,
    required String upiAppPackage,
  }) async {
    if (!mounted) return;
    setState(() => _paying = true);
    final user = context.read<AuthProvider>().user;
    var contact10 = resolveRazorpayContactFromUser(
      user != null ? Map<String, dynamic>.from(user) : null,
    );
    contact10 ??= await AuthProvider.loadLastLoginMobileDigits();
    final email = user?['email']?.toString();

    final options = buildRazorpayUpiIntentOnlyOptions(
      key: key,
      orderId: orderId,
      orderAmountPaise: orderAmountPaise,
      order: order,
      description: 'Coupon Payment',
      themeColor: '#AE1E3F',
      prefillContact10: contact10,
      prefillEmail: email,
      upiAppPackage: upiAppPackage,
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await RazorpayNativeAndroid.open(options);
      } catch (e) {
        if (!mounted) return;
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payment: $e')),
        );
      }
    } else {
      _razorpay.open(options);
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verifyRes = await _api.verifyPayment({
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });
      if (!mounted) return;
      final data = verifyRes.data is Map ? verifyRes.data as Map : {};
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(data['message']?.toString() ??
                'Payment verified successfully')),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Payment received. Verification pending for #${_pendingTransactionId ?? '-'}')),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _paying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'Payment failed')),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('External wallet selected: ${response.walletName ?? '-'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _coupon ?? {};
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Coupon',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'] ?? c['title'] ?? 'Coupon',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            if ((c['description'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(c['description'].toString(),
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary)),
                            ],
                            if ((c['value'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text('Value: ${c['value']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                            if ((c['code'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Code: ${c['code']}',
                                  style:
                                      const TextStyle(fontFamily: 'monospace')),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Bill Amount',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Enter bill amount',
                          prefixText: '₹ ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _paying ? null : _startRedeemPayment,
                          child: _paying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Redeem & Pay'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'To redeem, show this coupon at the store or use the redeem flow.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
    );
  }
}
