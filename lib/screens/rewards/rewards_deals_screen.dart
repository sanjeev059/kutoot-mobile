import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../services/subscription_plan_service.dart';
import '../../theme/app_theme.dart';

class RewardsDealsScreen extends StatefulWidget {
  final String cityName;
  final String upgradeLabel;
  final VoidCallback? onUpgradeTap;
  final VoidCallback? onHomeTap;

  const RewardsDealsScreen({
    super.key,
    required this.cityName,
    this.upgradeLabel = 'UPGRADE',
    this.onUpgradeTap,
    this.onHomeTap,
  });

  @override
  State<RewardsDealsScreen> createState() => _RewardsDealsScreenState();
}

class _RewardsDealsScreenState extends State<RewardsDealsScreen> {
  final _api = KutootApi();
  String _filter = 'All';
  String? _currentPlan;
  String? _appliedCode;
  List<_RewardDeal> _apiDeals = [];
  bool _loaded = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPlan();
    _fetchDeals();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _fetchDeals());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    final plan = await SubscriptionPlanService.getCurrentPlanName();
    if (!mounted) return;
    setState(() => _currentPlan = plan);
  }

  Future<void> _fetchDeals() async {
    try {
      final res = await _api.getCoupons(params: {'per_page': 50});
      final raw = res.data;
      final deals = <_RewardDeal>[];

      void parseCoupons(dynamic list, String segment) {
        if (list is! List) return;
        for (final item in list) {
          final m = item is Map
              ? Map<String, dynamic>.from(item)
              : <String, dynamic>{};
          final code = m['code']?.toString() ?? '';
          final title = m['title']?.toString() ?? '';
          if (code.isEmpty && title.isEmpty) continue;

          final requiredPlan = m['required_plan'] is Map
              ? (m['required_plan'] as Map)['name']?.toString() ?? 'BASIC'
              : (m['is_eligible'] == true ? '' : 'BASIC');

          final catMap = m['category'] is Map
              ? Map<String, dynamic>.from(m['category'] as Map)
              : <String, dynamic>{};
          final catName = catMap['name']?.toString() ?? segment;

          final merchant = m['merchant_location'] is Map
              ? Map<String, dynamic>.from(m['merchant_location'] as Map)
              : <String, dynamic>{};
          final merchantInfo = merchant['merchant'] is Map
              ? Map<String, dynamic>.from(merchant['merchant'] as Map)
              : <String, dynamic>{};
          final brandName = merchantInfo['name']?.toString() ?? catName;

          final discountType = m['discount_type']?.toString() ?? 'fixed';
          final discountValue =
              num.tryParse(m['discount_value']?.toString() ?? '0') ?? 0;
          final dealTitle = discountType == 'percentage'
              ? '$discountValue% OFF'
              : '₹$discountValue OFF';

          deals.add(_RewardDeal(
            brandName: brandName,
            categoryLabel: catName.toUpperCase(),
            title: title.isNotEmpty ? title : dealTitle,
            subtitle: m['description']?.toString() ?? '',
            code: code,
            requiredPlan: requiredPlan.toUpperCase(),
            type: segment == 'bank'
                ? _DealType.bank
                : (segment == 'store' ? _DealType.store : _DealType.merchant),
            brandIcon:
                segment == 'bank' ? Icons.account_balance : Icons.storefront,
            brandColor:
                segment == 'bank' ? const Color(0xFF004B87) : AppTheme.primary,
          ));
        }
      }

      if (raw is Map && raw['data'] is Map) {
        final data = Map<String, dynamic>.from(raw['data'] as Map);
        parseCoupons(data['plan_coupons'], 'plan');
        parseCoupons(data['store_coupons'], 'store');
        parseCoupons(data['other_coupons'], 'other');
      } else if (raw is Map && raw['data'] is List) {
        parseCoupons(raw['data'], 'plan');
      }

      if (deals.isNotEmpty && mounted) {
        setState(() => _apiDeals = deals);
      }
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
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

  bool _canApply(String requiredPlan) =>
      _planRank(_currentPlan) >= _planRank(requiredPlan);

  List<_RewardDeal> get _allDealsSource =>
      _apiDeals.isNotEmpty ? _apiDeals : _fallbackDeals;

  List<_RewardDeal> get _filtered {
    final source = _allDealsSource;
    if (_filter == 'Merchant Deals') {
      return source.where((d) => d.type == _DealType.merchant).toList();
    }
    if (_filter == 'Bank Offers') {
      return source.where((d) => d.type == _DealType.bank).toList();
    }
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final deals = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search,
                      color: Colors.black.withValues(alpha: 0.3)),
                  const SizedBox(width: 10),
                  Text(
                    'Search brands, banks or items...',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', 'Merchant Deals', 'Bank Offers'].map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: active,
                    selectedColor: AppTheme.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color:
                          active ? AppTheme.primary : const Color(0xFFE1BEC0),
                    ),
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: deals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final d = deals[i];
                final canApply = _canApply(d.requiredPlan);
                final applied = _appliedCode == d.code;
                return _DealCard(
                  deal: d,
                  canApply: canApply,
                  applied: applied,
                  onApply: () {
                    setState(() => _appliedCode = d.code);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${d.code} applied successfully!')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: AppTheme.secondaryContainer.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppTheme.secondaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.cityName} ▾',
                    style: const TextStyle(
                      color: AppTheme.secondaryContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Image.asset(AppTheme.logoAsset,
                    height: 48, fit: BoxFit.contain),
              ),
            ),
            InkWell(
              onTap: widget.onUpgradeTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.upgradeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DealType { merchant, bank, store }

class _RewardDeal {
  final String brandName;
  final String categoryLabel;
  final String title;
  final String subtitle;
  final String code;
  final String requiredPlan;
  final _DealType type;
  final IconData brandIcon;
  final Color brandColor;

  const _RewardDeal({
    required this.brandName,
    required this.categoryLabel,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.requiredPlan,
    required this.type,
    required this.brandIcon,
    required this.brandColor,
  });
}

const _fallbackDeals = [
  _RewardDeal(
    brandName: 'Starbucks Reserve',
    categoryLabel: 'MERCHANT OFFER',
    title: '60% OFF',
    subtitle: 'Valid till 30 Nov • Up to ₹200',
    code: 'SBUX60',
    requiredPlan: 'BASIC',
    type: _DealType.merchant,
    brandIcon: Icons.coffee,
    brandColor: Color(0xFF00704A),
  ),
  _RewardDeal(
    brandName: 'HDFC Bank Cards',
    categoryLabel: 'BANK PRIVILEGE',
    title: '₹500 BACK',
    subtitle: 'Ends in 2 days • Min. ₹1,999',
    code: 'HDFC500',
    requiredPlan: 'PRO',
    type: _DealType.bank,
    brandIcon: Icons.account_balance,
    brandColor: Color(0xFF004B87),
  ),
  _RewardDeal(
    brandName: "Nature's Basket",
    categoryLabel: 'STORE REWARD',
    title: 'FREE SHIP',
    subtitle: 'Next 3 fresh orders • Member exclusive',
    code: 'NBSHIP',
    requiredPlan: 'BASIC',
    type: _DealType.store,
    brandIcon: Icons.eco,
    brandColor: Color(0xFF558B2F),
  ),
  _RewardDeal(
    brandName: 'Westside',
    categoryLabel: 'MERCHANT OFFER',
    title: '40% OFF',
    subtitle: 'All categories • Min ₹999',
    code: 'WEST40',
    requiredPlan: 'VIP',
    type: _DealType.merchant,
    brandIcon: Icons.storefront,
    brandColor: Color(0xFFAE1E3F),
  ),
  _RewardDeal(
    brandName: 'ICICI Platinum',
    categoryLabel: 'BANK PRIVILEGE',
    title: '₹750 BACK',
    subtitle: 'Credit card only • Min. ₹2,500',
    code: 'ICICI750',
    requiredPlan: 'ELITE',
    type: _DealType.bank,
    brandIcon: Icons.credit_card,
    brandColor: Color(0xFFF37021),
  ),
  _RewardDeal(
    brandName: 'Croma Electronics',
    categoryLabel: 'MERCHANT OFFER',
    title: '₹2000 OFF',
    subtitle: 'On Laptops & Mobiles above ₹25K',
    code: 'CROMA2K',
    requiredPlan: 'PRO',
    type: _DealType.merchant,
    brandIcon: Icons.devices,
    brandColor: Color(0xFF2E7D32),
  ),
];

class _DealCard extends StatelessWidget {
  final _RewardDeal deal;
  final bool canApply;
  final bool applied;
  final VoidCallback onApply;

  const _DealCard({
    required this.deal,
    required this.canApply,
    required this.applied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFE1BEC0).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: deal.brandColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(deal.brandIcon,
                              color: deal.brandColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deal.categoryLabel,
                                style: TextStyle(
                                  color: deal.brandColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                deal.brandName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      deal.title,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          deal.type == _DealType.bank
                              ? Icons.access_time
                              : Icons.calendar_today,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            deal.subtitle,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              color: const Color(0xFFE1BEC0).withValues(alpha: 0.3),
            ),
            SizedBox(
              width: 90,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (applied)
                    const Icon(Icons.check_circle,
                        color: Color(0xFF2E7D32), size: 32),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: applied ? null : (canApply ? onApply : null),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: applied
                            ? const Color(0xFF2E7D32)
                            : (canApply ? AppTheme.primary : Colors.grey),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        applied ? 'APPLIED' : (canApply ? 'APPLY' : 'LOCKED'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
