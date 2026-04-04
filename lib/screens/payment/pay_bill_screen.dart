import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../api/kutoot_api.dart';
import '../../services/campaign_entry_service.dart';
import '../../services/subscription_plan_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';

class PayBillScreen extends StatefulWidget {
  final Map<String, dynamic> merchantLocation;
  final String? initialCouponCode;

  const PayBillScreen({
    super.key,
    required this.merchantLocation,
    this.initialCouponCode,
  });

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  final _api = KutootApi();
  final _amountController = TextEditingController(text: '200');
  final _dealsScrollController = ScrollController();
  late final Razorpay _razorpay;

  bool _loadingCampaigns = true;
  bool _paying = false;
  List<Map<String, dynamic>> _campaigns = [];
  int? _selectedCampaignId;
  int? _transactionId;
  String? _currentPlan;
  String? _selectedUpgradePlan;
  String? _selectedCouponCode;
  bool _addDonation = true;
  bool _includeUpgradeInBill = false;

  @override
  void initState() {
    super.initState();
    _selectedCouponCode = widget.initialCouponCode;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadPlan();
    _loadCampaigns();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    _dealsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    final plan = await SubscriptionPlanService.getCurrentPlanName();
    if (!mounted) return;
    setState(() => _currentPlan = plan);
  }

  Future<void> _loadCampaigns() async {
    try {
      final res = await _api.getAvailableCampaigns();
      final data = res.data;
      List<Map<String, dynamic>> items = [];
      if (data is Map && data['data'] is List) {
        items = (data['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _campaigns = items;
        if (items.any((c) => c['is_primary'] == true)) {
          final primary = items.firstWhere((c) => c['is_primary'] == true);
          _selectedCampaignId = primary['id'] as int?;
        } else if (items.isNotEmpty) {
          _selectedCampaignId = items.first['id'] as int?;
        }
        _loadingCampaigns = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCampaigns = false);
    }
  }

  int _planRank(String? plan) {
    switch ((plan ?? '').toUpperCase()) {
      case 'BASIC':
        return 1;
      case 'PRO':
        return 2;
      case 'VIP':
        return 3;
      case 'ELITE':
        return 4;
      default:
        return 0;
    }
  }

  int _planFee(String? plan) {
    switch ((plan ?? '').toUpperCase()) {
      case 'BASIC':
        return 149;
      case 'PRO':
        return 399;
      case 'VIP':
        return 799;
      case 'ELITE':
        return 1499;
      default:
        return 0;
    }
  }

  String _effectivePlan() {
    if (_includeUpgradeInBill && (_selectedUpgradePlan ?? '').isNotEmpty) {
      return _selectedUpgradePlan!;
    }
    return _currentPlan ?? 'FREE';
  }

  int _platformFee(double amount) {
    final effectivePlanRank = _planRank(_effectivePlan());
    if (effectivePlanRank > 0) return 10;
    if (amount >= 1000) return 20;
    return 30;
  }

  List<_CouponOption> _couponOptions() {
    return const [
      _CouponOption(
          code: 'WST60',
          label: '60% OFF',
          type: _DiscountType.percent,
          value: 60,
          minPlan: 'ELITE'),
      _CouponOption(
          code: 'CASHBACK500',
          label: '₹500 BACK',
          type: _DiscountType.flat,
          value: 500,
          minPlan: 'PRO'),
      _CouponOption(
          code: 'AUTO15',
          label: '15% OFF',
          type: _DiscountType.percent,
          value: 15,
          minPlan: 'BASIC'),
      _CouponOption(
          code: 'WESTBOGO',
          label: 'BOGO',
          type: _DiscountType.flat,
          value: 300,
          minPlan: 'VIP'),
    ];
  }

  _CouponOption? _selectedCoupon() {
    if ((_selectedCouponCode ?? '').isEmpty) return null;
    for (final c in _couponOptions()) {
      if (c.code == _selectedCouponCode) return c;
    }
    return null;
  }

  bool _canUseCoupon(_CouponOption coupon) {
    return _planRank(_effectivePlan()) >= _planRank(coupon.minPlan);
  }

  _BillBreakdown _calculateBreakdown() {
    final amount = _readAmount();
    final subtotal = amount.clamp(0, double.infinity).toDouble();
    final selectedPlanFee =
        _includeUpgradeInBill ? _planFee(_selectedUpgradePlan) : 0;
    final platformFee = _platformFee(subtotal);
    const storeHandling = 3;
    final donation = _addDonation ? 3 : 0;
    final coupon = _selectedCoupon();
    int couponDiscount = 0;
    if (coupon != null && _canUseCoupon(coupon)) {
      if (coupon.type == _DiscountType.percent) {
        couponDiscount = ((subtotal * coupon.value) / 100).round();
      } else {
        couponDiscount = coupon.value.round();
      }
      // Protect business cuts first: discount cannot eat fees or plan.
      final maxAllowed = subtotal.round();
      if (couponDiscount > maxAllowed) {
        couponDiscount = maxAllowed;
      }
    }

    final gross =
        subtotal + selectedPlanFee + platformFee + storeHandling + donation;
    final payable =
        (gross - couponDiscount).clamp(0, double.infinity).toDouble();
    return _BillBreakdown(
      baseBill: subtotal,
      planUpgradeFee: selectedPlanFee.toDouble(),
      platformFee: platformFee.toDouble(),
      storeHandlingFee: storeHandling.toDouble(),
      donation: donation.toDouble(),
      couponDiscount: couponDiscount.toDouble(),
      payable: payable,
    );
  }

  Future<void> _startPayment() async {
    if (_paying) return;
    final breakdown = _calculateBreakdown();
    final amount = breakdown.payable;

    if (_includeUpgradeInBill && (_selectedUpgradePlan ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a plan upgrade to continue')),
      );
      return;
    }

    final merchantId = _readInt(widget.merchantLocation['id']) ??
        _readInt(widget.merchantLocation['merchant_location_id']) ??
        _readInt(widget.merchantLocation['location_id']);

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid bill amount')),
      );
      return;
    }
    if (merchantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Store information is missing. Re-open this store and try again.')),
      );
      return;
    }

    // Demo/static stores are local showcase cards; avoid backend failures.
    if (_isDemoStore()) {
      setState(() => _paying = true);
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      setState(() => _paying = false);
      if (_includeUpgradeInBill && (_selectedUpgradePlan ?? '').isNotEmpty) {
        await SubscriptionPlanService.setCurrentPlanName(_selectedUpgradePlan!);
        if (!mounted) return;
      }
      final selectedCampaign = _campaigns.where((c) {
        final id = c['id'] is int ? c['id'] as int : int.tryParse('${c['id']}');
        return id == _selectedCampaignId;
      }).toList();
      final campaignName = selectedCampaign.isNotEmpty
          ? (selectedCampaign.first['name']?.toString() ?? 'campaign')
          : 'campaign';
      await _recordCampaignEntry(
        campaignId: _selectedCampaignId,
        campaignName: campaignName,
        breakdown: breakdown,
        campaignData:
            selectedCampaign.isNotEmpty ? selectedCampaign.first : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment successful (demo). You earned stamps and got entry in $campaignName.',
          ),
        ),
      );
      await _showRatingDialog();
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    setState(() => _paying = true);
    try {
      final payload = <String, dynamic>{
        'amount': amount,
        'bill_amount': breakdown.baseBill,
        'coupon_code': _selectedCouponCode,
        'coupon_discount': breakdown.couponDiscount,
        'plan_name': _effectivePlan(),
        'plan_upgrade_fee': breakdown.planUpgradeFee,
        'platform_fee': breakdown.platformFee,
        'store_handling_fee': breakdown.storeHandlingFee,
        'donation_fee': breakdown.donation,
        'merchant_location_id': merchantId,
      };
      if (_selectedCampaignId != null) {
        payload['campaign_id'] = _selectedCampaignId;
      }

      final res = await _api.payWithoutCoupon(payload);
      final body = res.data is Map ? res.data as Map : {};
      final result = body['data'] is Map ? body['data'] as Map : body;
      _transactionId = result['transaction_id'] is int
          ? result['transaction_id'] as int
          : null;

      if (result['zero_amount'] == true) {
        if (!mounted) return;
        final selectedCampaign = _campaigns.where((c) {
          final id =
              c['id'] is int ? c['id'] as int : int.tryParse('${c['id']}');
          return id == _selectedCampaignId;
        }).toList();
        final campaignName = selectedCampaign.isNotEmpty
            ? (selectedCampaign.first['name']?.toString() ?? 'campaign')
            : 'campaign';
        await _recordCampaignEntry(
          campaignId: _selectedCampaignId,
          campaignName: campaignName,
          breakdown: breakdown,
          campaignData:
              selectedCampaign.isNotEmpty ? selectedCampaign.first : null,
        );
        if (!mounted) return;
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result['message']?.toString() ?? 'Payment successful')),
        );
        Navigator.pop(context, true);
        return;
      }

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
        throw Exception('Invalid payment order response');
      }

      _razorpay.open({
        'key': key,
        'amount': orderAmount,
        'currency': order['currency'] ?? 'INR',
        'name': order['merchant_name'] ?? 'Kutoot',
        'description': 'Bill Payment',
        'order_id': orderId,
        'theme': {'color': '#8A002B'},
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      String message = 'Could not start payment. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          message = e.message!;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
      if (_selectedCampaignId != null) {
        verifyPayload['campaign_id'] = _selectedCampaignId;
      }

      await _api.verifyPayment(verifyPayload);
      if (!mounted) return;
      final selectedCampaign = _campaigns.where((c) {
        final id = c['id'] is int ? c['id'] as int : int.tryParse('${c['id']}');
        return id == _selectedCampaignId;
      }).toList();
      final campaignName = selectedCampaign.isNotEmpty
          ? (selectedCampaign.first['name']?.toString() ?? 'campaign')
          : 'campaign';
      await _recordCampaignEntry(
        campaignId: _selectedCampaignId,
        campaignName: campaignName,
        breakdown: _calculateBreakdown(),
        campaignData:
            selectedCampaign.isNotEmpty ? selectedCampaign.first : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment successful. You earned stamps and got entry in $campaignName.',
          ),
        ),
      );
      if (_includeUpgradeInBill && (_selectedUpgradePlan ?? '').isNotEmpty) {
        await SubscriptionPlanService.setCurrentPlanName(_selectedUpgradePlan!);
        if (!mounted) return;
      }
      if (!mounted) return;
      await _showRatingDialog();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Payment received. Verification pending for #${_transactionId ?? '-'}')),
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

  Future<void> _showRatingDialog() async {
    int rating = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'How was your experience?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.merchantLocation['name']?.toString() ??
                    widget.merchantLocation['branch_name']?.toString() ??
                    'Store',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: i < rating ? const Color(0xFFFFA000) : const Color(0xFFBDBDBD),
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    rating > 0 ? 'Submit' : 'Skip',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.merchantLocation['branch_name']?.toString() ??
        widget.merchantLocation['name']?.toString() ??
        'Westside, Forum Mall';
    final breakdown = _calculateBreakdown();
    final stampsEarned = ((breakdown.baseBill / 400).floor() +
            (_selectedCoupon() != null ? 1 : 0))
        .clamp(1, 99);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(title: const Text('Pay Bill')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.storefront, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const Text('Luxury Fashion & Lifestyle',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENTER BILL AMOUNT',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('₹',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800,
                              color: AppTheme.primary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: AppTheme.surfaceContainerHighest,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x33CDA700),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x4DCDA700)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars,
                          color: AppTheme.tertiary, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'You will earn $stampsEarned stamps from this visit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vibrant Drops',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              GestureDetector(
                onTap: () {
                  _dealsScrollController.animateTo(
                    _dealsScrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                child: const Text('See All Drops',
                    style: TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.builder(
              controller: _dealsScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _couponOptions().length,
              itemBuilder: (_, i) {
                final c = _couponOptions()[i];
                final selected = _selectedCouponCode == c.code;
                final eligible = _canUseCoupon(c);
                return _DealCard(
                  coupon: c,
                  selected: selected,
                  eligible: eligible,
                  onTap: () {
                    if (selected) {
                      setState(() => _selectedCouponCode = null);
                    } else if (eligible) {
                      setState(() => _selectedCouponCode = c.code);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'This coupon requires ${c.minPlan} plan or above.'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          if (_selectedCoupon() != null && !_canUseCoupon(_selectedCoupon()!))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Selected coupon requires higher plan.',
                style: TextStyle(
                    color: Color(0xFFBA1A1A), fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 14),
          Text('Apply to Reward',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
          const SizedBox(height: 10),
          SizedBox(
            height: 260,
            child: _loadingCampaigns
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _campaigns.isEmpty
                    ? _buildFallbackCampaigns()
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _campaigns.length,
                        itemBuilder: (_, i) {
                          final c = _campaigns[i];
                          final id = c['id'] is int
                              ? c['id'] as int
                              : int.tryParse('${c['id']}');
                          return _CampaignRewardCard(
                            title: c['name']?.toString() ?? 'Campaign',
                            imageUrl: ImageUtils.fromBanner(c),
                            selected: id == _selectedCampaignId,
                            onTap: () =>
                                setState(() => _selectedCampaignId = id),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1BEC0)),
            ),
            child: Column(
              children: [
                _line('Bill amount', breakdown.baseBill),
                _line('Plan upgrade', breakdown.planUpgradeFee),
                _line('Platform fee', breakdown.platformFee),
                _line('Store handling', breakdown.storeHandlingFee),
                _line('Donation', breakdown.donation),
                _line('Coupon discount', -breakdown.couponDiscount),
                const Divider(height: 18),
                _line('Total payable', breakdown.payable, highlight: true),
                if (breakdown.couponDiscount > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'You saved ₹${breakdown.couponDiscount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          CheckboxListTile(
            value: _addDonation,
            onChanged: (v) => setState(() => _addDonation = v ?? true),
            title: const Text('₹3 donation to Blind Eye Trust'),
            subtitle: const Text(
                'Pre-selected. Untick if you do not want to donate.'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _includeUpgradeInBill,
            onChanged: (v) => setState(() => _includeUpgradeInBill = v),
            title: const Text('Add plan upgrade in this bill'),
            subtitle: Text('Current plan: ${_currentPlan ?? 'FREE'}'),
            contentPadding: EdgeInsets.zero,
          ),
          if (_includeUpgradeInBill)
            Wrap(
              spacing: 8,
              children: const [
                _PlanChoice(plan: 'BASIC', fee: 149),
                _PlanChoice(plan: 'PRO', fee: 399),
                _PlanChoice(plan: 'VIP', fee: 799),
                _PlanChoice(plan: 'ELITE', fee: 1499),
              ].map((p) {
                final selected = _selectedUpgradePlan == p.plan;
                return ChoiceChip(
                  selected: selected,
                  label: Text('${p.plan} • ₹${p.fee}'),
                  onSelected: (_) =>
                      setState(() => _selectedUpgradePlan = p.plan),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _paying ? null : _startPayment,
              child: _paying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Pay Now ₹${breakdown.payable.toStringAsFixed(0)}'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _line(String label, double amount, {bool highlight = false}) {
    final isDiscount = amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: highlight
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : EdgeInsets.zero,
        decoration: highlight
            ? BoxDecoration(
                color: const Color(0xFFFFF1E8),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            if (isDiscount)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
              ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
                  fontSize: highlight ? 18 : 14,
                  color: isDiscount ? const Color(0xFF2E7D32) : null,
                ),
              ),
            ),
            Text(
              '${amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
              style: TextStyle(
                color: isDiscount
                    ? const Color(0xFF2E7D32)
                    : (highlight ? AppTheme.primary : null),
                fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
                fontSize: highlight ? 18 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _readAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  bool _isDemoStore() {
    final flag = widget.merchantLocation['is_demo_store'];
    return flag == true || widget.merchantLocation['source'] == 'home_static';
  }

  Widget _buildFallbackCampaigns() {
    final fallback = <Map<String, dynamic>>[
      {
        'id': 9001,
        'name': 'Luxury Villa\nWeekend Getaway',
        'stamp_target': 200,
        'stamps_collected': 150,
        'is_primary': true,
        'banner_url':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAViL5wtuWs2XUgzI4O6zkKPKt8Imy5oleiUYdueL4mMKiKPML7w6hS8_kNqfURwhNMABYvUoCGa7QNLJZNXI9s4Rg4YGX15YwOn5T3FVaP8zoGUwoprqjWl7HD59a3gIPfVuj9JxXXLbwRe6-rm2BubGIctQoMbRC4Ai7N6ismUpy2zSupL5hceWWp0vNEsgc6eg3hu3hBzTuOy02MRrP9GpgQWMAHdj4TNG0hBNYCmy6rgeNpdnylV4QW-yCQ2Fm1k50lZPIhkhw',
      },
      {
        'id': 9002,
        'name': 'Artisan Coffee\nTasting Box',
        'stamp_target': 50,
        'stamps_collected': 45,
        'banner_url':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAlHzPWKsSZSl1BjWkxh9VFIU0l_W_GpA99Z4_6iTqMKhAAXpXesh7qrCeTXmMVWBLcVP-haFW1_uMaxHQXvpqdjt4U7oj-ohP_GdL3vg8KD1qQOYjAZyJV8eR66cJEXtu_2aMxYQFls8tvcIa7vNErKPh2LNST5MBmfyn5lqLG5ficsXFAMvwRAraH9MiP0tJQQIJ3XTeqTkrgbAI7cKBqEUHEMpYtacReWmmKTNR1EeRhiTsEfMkuGMsZ31eSGxOrigovmqNQ2eQ',
      },
    ];
    if (_selectedCampaignId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCampaignId = 9001);
      });
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: fallback.length,
      itemBuilder: (_, i) {
        final c = fallback[i];
        final id = c['id'] as int;
        return _CampaignRewardCard(
          title: c['name'] as String,
          imageUrl: c['banner_url'] as String,
          selected: id == _selectedCampaignId,
          onTap: () => setState(() => _selectedCampaignId = id),
        );
      },
    );
  }

  int _stampsEarnedFromBill(double billAmount) {
    return (billAmount / 400).floor().clamp(1, 99);
  }

  Future<void> _recordCampaignEntry({
    required int? campaignId,
    required String campaignName,
    required _BillBreakdown breakdown,
    Map<String, dynamic>? campaignData,
  }) async {
    await CampaignEntryService.addEntry(
      campaignId: campaignId,
      campaignName: campaignName,
      stampsEarned: _stampsEarnedFromBill(breakdown.baseBill),
      storeName: widget.merchantLocation['name']?.toString() ??
          widget.merchantLocation['branch_name']?.toString() ??
          'Store',
      billAmount: breakdown.baseBill,
      imageUrl: ImageUtils.fromBanner(campaignData),
      stampTarget: _readInt(campaignData?['stamp_target']) ?? 10,
      progressPercent: null,
      tag: campaignData?['is_primary'] == true ? 'PRIMARY' : 'ENTERED',
    );
  }
}

class _DealCard extends StatelessWidget {
  final _CouponOption coupon;
  final bool selected;
  final bool eligible;
  final VoidCallback onTap;

  const _DealCard({
    required this.coupon,
    required this.selected,
    required this.eligible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppTheme.primary : Colors.white;
    final fg = selected ? Colors.white : AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 238,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1BEC0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(coupon.code,
                style: TextStyle(
                    color: selected ? Colors.white70 : AppTheme.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            const Spacer(),
            Text(
              coupon.label,
              style: TextStyle(
                color: fg,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${coupon.minPlan}+',
                  style: TextStyle(
                    color: selected ? Colors.white70 : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : AppTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    selected ? 'APPLIED' : (eligible ? 'APPLY' : 'LOCKED'),
                    style: TextStyle(
                      color: selected ? AppTheme.primary : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignRewardCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _CampaignRewardCard({
    required this.title,
    this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.secondary
                : AppTheme.outlineVariant.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.secondary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.surfaceContainerHighest,
                        child: const Icon(Icons.card_giftcard,
                            size: 40, color: AppTheme.primary),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surfaceContainerHighest,
                      child: const Icon(Icons.card_giftcard,
                          size: 40, color: AppTheme.primary),
                    ),
                  if (selected)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_circle,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  if (selected)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SELECTED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanChoice {
  final String plan;
  final int fee;
  const _PlanChoice({required this.plan, required this.fee});
}

enum _DiscountType { flat, percent }

class _CouponOption {
  final String code;
  final String label;
  final _DiscountType type;
  final double value;
  final String minPlan;

  const _CouponOption({
    required this.code,
    required this.label,
    required this.type,
    required this.value,
    required this.minPlan,
  });
}

class _BillBreakdown {
  final double baseBill;
  final double planUpgradeFee;
  final double platformFee;
  final double storeHandlingFee;
  final double donation;
  final double couponDiscount;
  final double payable;

  const _BillBreakdown({
    required this.baseBill,
    required this.planUpgradeFee,
    required this.platformFee,
    required this.storeHandlingFee,
    required this.donation,
    required this.couponDiscount,
    required this.payable,
  });
}
