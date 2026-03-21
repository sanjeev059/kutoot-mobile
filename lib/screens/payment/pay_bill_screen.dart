import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';

class PayBillScreen extends StatefulWidget {
  final Map<String, dynamic> merchantLocation;

  const PayBillScreen({super.key, required this.merchantLocation});

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  final _api = KutootApi();
  final _amountController = TextEditingController();
  late final Razorpay _razorpay;

  bool _loadingCampaigns = true;
  bool _paying = false;
  List<Map<String, dynamic>> _campaigns = [];
  int? _selectedCampaignId;
  int? _transactionId;

  @override
  void initState() {
    super.initState();
    _amountController.text = '200';
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadCampaigns();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    try {
      final res = await _api.getAvailableCampaigns();
      if (!mounted) return;
      final data = res.data;
      List<Map<String, dynamic>> items = [];
      if (data is Map && data['data'] is List) {
        items = (data['data'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      setState(() {
        _campaigns = items;
        if (items.any((c) => c['is_primary'] == true)) {
          _selectedCampaignId = items.firstWhere((c) => c['is_primary'] == true)['id'] as int?;
        }
        _loadingCampaigns = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCampaigns = false);
    }
  }

  Future<void> _startPayment() async {
    if (_paying) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final merchantId = widget.merchantLocation['id'] is int
        ? widget.merchantLocation['id'] as int
        : int.tryParse('${widget.merchantLocation['id']}');

    if (merchantId == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid bill amount')),
      );
      return;
    }

    setState(() => _paying = true);
    try {
      final payload = <String, dynamic>{
        'amount': amount,
        'merchant_location_id': merchantId,
      };
      if (_selectedCampaignId != null) payload['campaign_id'] = _selectedCampaignId;

      final res = await _api.payWithoutCoupon(payload);
      final body = res.data is Map ? res.data as Map : {};
      final result = body['data'] is Map ? body['data'] as Map : body;
      _transactionId = result['transaction_id'] is int ? result['transaction_id'] as int : null;

      if (result['zero_amount'] == true) {
        if (!mounted) return;
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Payment successful')),
        );
        Navigator.pop(context, true);
        return;
      }

      final order = result['order'] is Map ? result['order'] as Map : {};
      final key = order['key']?.toString();
      final orderId = order['id']?.toString();
      final orderAmount = order['amount'] is int ? order['amount'] as int : int.tryParse('${order['amount']}') ?? 0;

      if (key == null || key.isEmpty || orderId == null || orderId.isEmpty || orderAmount <= 0) {
        throw Exception('Invalid payment order response');
      }

      _razorpay.open({
        'key': key,
        'amount': orderAmount,
        'currency': order['currency'] ?? 'INR',
        'name': order['merchant_name'] ?? 'Kutoot',
        'description': 'Bill Payment',
        'order_id': orderId,
        'theme': {'color': '#FF6B35'},
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start payment: $e')),
      );
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verifyPayload = <String, dynamic>{
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      };
      if (_selectedCampaignId != null) verifyPayload['campaign_id'] = _selectedCampaignId;
      await _api.verifyPayment(verifyPayload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment verified successfully')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment received. Verification pending for #${_transactionId ?? '-'}')),
      );
      Navigator.pop(context, true);
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
      SnackBar(content: Text('External wallet: ${response.walletName ?? '-'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.merchantLocation['branch_name']?.toString() ??
        widget.merchantLocation['name']?.toString() ??
        'Store';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pay Bill'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(branch, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Pay without coupon', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 20),
          const Text('Bill Amount', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: '₹ ',
              hintText: 'Enter bill amount',
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingCampaigns)
            const LinearProgressIndicator(color: AppTheme.primary)
          else if (_campaigns.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _selectedCampaignId,
              decoration: const InputDecoration(labelText: 'Stamp Campaign (optional)'),
              items: _campaigns
                  .map((c) => DropdownMenuItem<int>(
                        value: c['id'] is int ? c['id'] as int : int.tryParse('${c['id']}'),
                        child: Text(c['name']?.toString() ?? c['code']?.toString() ?? 'Campaign'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCampaignId = v),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _paying ? null : _startPayment,
              child: _paying
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Pay Now'),
            ),
          ),
        ],
      ),
    );
  }
}
