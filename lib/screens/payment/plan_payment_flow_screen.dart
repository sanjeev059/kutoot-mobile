import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../api/kutoot_api.dart';
import '../../services/subscription_plan_service.dart';
import '../../theme/app_theme.dart';
import '../home/kinetic_home_screens.dart';

class PlanPaymentScreen extends StatefulWidget {
  final int planId;
  final String planName;
  final String amount;
  final String cityName;

  const PlanPaymentScreen({
    super.key,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.cityName,
  });

  @override
  State<PlanPaymentScreen> createState() => _PlanPaymentScreenState();
}

class _PlanPaymentScreenState extends State<PlanPaymentScreen> {
  final _api = KutootApi();
  late final Razorpay _razorpay;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _startPayment() async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await _api.recordSubscriptionConsent(widget.planId);

      final res = await _api.upgradeSubscription(widget.planId);
      final payload = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};

      final needsPayment = payload['requires_payment'] == true;

      if (!mounted) return;

      if (needsPayment) {
        final order = payload['order'] is Map
            ? payload['order'] as Map
            : <String, dynamic>{};
        final amountPaise = order['amount'] is int
            ? order['amount'] as int
            : int.tryParse('${order['amount']}') ?? 0;

        if (order['id'] != null && order['key'] != null && amountPaise > 0) {
          _razorpay.open({
            'key': order['key'],
            'amount': amountPaise,
            'currency': order['currency'] ?? 'INR',
            'name': order['merchant_name'] ?? 'Kutoot',
            'description': '${widget.planName} Membership',
            'order_id': order['id'],
            'theme': {'color': '#FF6B35'},
          });
        } else {
          setState(() {
            _processing = false;
            _error = 'Payment order incomplete — contact support.';
          });
        }
      } else {
        await SubscriptionPlanService.setCurrentPlanName(widget.planName);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              planName: widget.planName,
              amount: widget.amount,
              cityName: widget.cityName,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String msg = 'Something went wrong. Please try again.';
      if (e.toString().contains('DioException')) {
        msg = 'Network error — check your connection.';
      }
      setState(() {
        _processing = false;
        _error = msg;
      });
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await _api.verifySubscriptionPayment({
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
        'plan_id': widget.planId,
        'campaign_selections': <Map<String, dynamic>>[],
      });

      await SubscriptionPlanService.setCurrentPlanName(widget.planName);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            planName: widget.planName,
            amount: widget.amount,
            cityName: widget.cityName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentFailureScreen(
            planName: widget.planName,
            amount: widget.amount,
            cityName: widget.cityName,
            planId: widget.planId,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentFailureScreen(
          planName: widget.planName,
          amount: widget.amount,
          cityName: widget.cityName,
          planId: widget.planId,
          errorMessage: response.message,
        ),
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'External wallet selected: ${response.walletName ?? '-'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F9),
        foregroundColor: AppTheme.primary,
        title: const Text('Payment'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1BEC0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.planName} Membership',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Amount: \u20B9${widget.amount}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E5DB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.security, color: AppTheme.textPrimary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Powered by Razorpay — 100% Secure',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'UPI, Cards, NetBanking & Wallets accepted',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processing ? null : _startPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _processing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Processing…',
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700)),
                          ],
                        )
                      : Text('Pay \u20B9${widget.amount}',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _processing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final String planName;
  final String amount;
  final String cityName;

  const PaymentSuccessScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F9),
        foregroundColor: AppTheme.primary,
        title: const Text('Payment Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer]),
              ),
              child: const Icon(Icons.check, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Successful',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '\u20B9$amount paid for $planName plan.',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          LoggedInHomeScreen(cityName: cityName),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Back to Home'),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class PaymentFailureScreen extends StatelessWidget {
  final String planName;
  final String amount;
  final String cityName;
  final int planId;
  final String? errorMessage;

  const PaymentFailureScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.cityName,
    required this.planId,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F9),
        foregroundColor: AppTheme.primary,
        title: const Text('Payment Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer]),
              ),
              child: const Icon(Icons.close, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Declined',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ??
                  'Transaction for \u20B9$amount failed. Please retry or use another method.',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PlanPaymentScreen(
                        planId: planId,
                        planName: planName,
                        amount: amount,
                        cityName: cityName,
                      ),
                    ),
                  );
                },
                child: const Text('Retry Payment'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
