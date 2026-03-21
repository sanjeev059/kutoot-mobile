import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import 'stamp_history_screen.dart';

class StampsScreen extends StatefulWidget {
  const StampsScreen({super.key});

  @override
  State<StampsScreen> createState() => _StampsScreenState();
}

class _StampsScreenState extends State<StampsScreen> {
  final _api = KutootApi();
  late final Razorpay _razorpay;
  List<Map<String, dynamic>> _stamps = [];
  List<Map<String, dynamic>> _campaigns = [];
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;
  String? _error;
  bool _reserving = false;
  int? _pendingStampId;
  int? _pendingPlanId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _load();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getStamps();
      final campaignsRes = await _api.getAvailableCampaigns().catchError((_) => null);
      final plansRes = await _api.getSubscriptionPlans().catchError((_) => null);
      final data = res.data;
      if (data is Map && data['data'] != null) {
        final d = data['data'];
        if (d is List) {
          _stamps = d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _stamps = [];
        }
      } else if (data is List) {
        _stamps = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }

      if (campaignsRes != null && campaignsRes.data is Map) {
        final d = (campaignsRes.data as Map)['data'];
        _campaigns = d is List ? d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      }

      if (plansRes != null && plansRes.data is Map) {
        final d = (plansRes.data as Map)['data'];
        _plans = d is List ? d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
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
        title: const Text('My Stamps', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StampHistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _reserving ? null : _openReserveSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _stamps.isEmpty
                  ? const Center(child: Text('No stamps yet. Join a campaign to earn stamps.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stamps.length,
                        itemBuilder: (context, i) {
                          final s = _stamps[i];
                          final campaign = s['campaign'] is Map ? s['campaign'] as Map : <String, dynamic>{};
                          final name = campaign['reward_name'] ?? campaign['name'] ?? campaign['code'] ?? 'Stamp';
                          final code = s['code']?.toString() ?? '-';
                          final status = s['status']?.toString() ?? 'active';
                          final isReserved = s['is_reserved'] == true;
                          final isEditable = s['is_editable'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.star_rounded, color: AppTheme.primary, size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                            const SizedBox(height: 2),
                                            Text('Code: $code', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _stampTag(label: status),
                                      if (isReserved) _stampTag(label: 'Reserved', color: Colors.orange),
                                      if (isEditable) _stampTag(label: 'Editable', color: Colors.blue),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Future<void> _openReserveSheet() async {
    if (_campaigns.isEmpty || _plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaigns or plans are not available right now')),
      );
      return;
    }

    int? selectedCampaignId = _campaigns.first['id'] is int ? _campaigns.first['id'] as int : int.tryParse('${_campaigns.first['id']}');
    int? selectedPlanId = _plans.first['id'] is int ? _plans.first['id'] as int : int.tryParse('${_plans.first['id']}');

    final result = await showModalBottomSheet<(int?, int?)>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) => Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reserve Stamp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedCampaignId,
                  decoration: const InputDecoration(labelText: 'Campaign'),
                  items: _campaigns
                      .map((c) => DropdownMenuItem<int>(
                            value: c['id'] is int ? c['id'] as int : int.tryParse('${c['id']}'),
                            child: Text(c['name']?.toString() ?? c['reward_name']?.toString() ?? c['code']?.toString() ?? 'Campaign'),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => selectedCampaignId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedPlanId,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: _plans
                      .map((p) => DropdownMenuItem<int>(
                            value: p['id'] is int ? p['id'] as int : int.tryParse('${p['id']}'),
                            child: Text('${p['name'] ?? 'Plan'} (₹${p['price'] ?? p['amount'] ?? 0})'),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => selectedPlanId = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, (selectedCampaignId, selectedPlanId)),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null || result.$1 == null || result.$2 == null) return;
    await _startReservation(result.$1!, result.$2!);
  }

  Future<void> _startReservation(int campaignId, int planId) async {
    if (_reserving) return;
    setState(() => _reserving = true);
    try {
      final reserveRes = await _api.reserveStamp(campaignId);
      final reserveData = reserveRes.data is Map ? reserveRes.data as Map : {};
      final stamp = reserveData['data'] is Map ? reserveData['data'] as Map : {};
      final stampId = stamp['id'] is int ? stamp['id'] as int : int.tryParse('${stamp['id']}');
      if (stampId == null) throw Exception('Invalid reservation response');

      _pendingStampId = stampId;
      _pendingPlanId = planId;
      final orderRes = await _api.createStampReservationOrder(stampId, planId);
      final body = orderRes.data is Map ? orderRes.data as Map : {};
      final order = body['order'] is Map ? body['order'] as Map : {};
      final key = order['key']?.toString();
      final orderId = order['id']?.toString();
      final amount = order['amount'] is int ? order['amount'] as int : int.tryParse('${order['amount']}') ?? 0;

      if (key == null || key.isEmpty || orderId == null || orderId.isEmpty || amount <= 0) {
        throw Exception('Invalid payment order for reservation');
      }

      _razorpay.open({
        'key': key,
        'amount': amount,
        'currency': order['currency'] ?? 'INR',
        'name': order['merchant_name'] ?? 'Kutoot',
        'description': 'Stamp Reservation',
        'order_id': orderId,
        'theme': {'color': '#FF6B35'},
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reserving = false;
        _pendingStampId = null;
        _pendingPlanId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation failed: $e')),
      );
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final stampId = _pendingStampId;
    final planId = _pendingPlanId;
    if (stampId == null || planId == null) return;

    try {
      final confirmRes = await _api.confirmStampReservation(stampId, {
        'plan_id': planId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
      });
      if (!mounted) return;
      final data = confirmRes.data is Map ? confirmRes.data as Map : {};
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message']?.toString() ?? 'Stamp confirmed successfully')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment done but confirmation failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reserving = false;
          _pendingStampId = null;
          _pendingPlanId = null;
        });
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _reserving = false;
      _pendingStampId = null;
      _pendingPlanId = null;
    });
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

  Widget _stampTag({required String label, Color color = AppTheme.primary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
