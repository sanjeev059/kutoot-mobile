import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../payment/pay_bill_screen.dart';
import '../../utils/maps_launch.dart';

class StoreProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? store;

  const StoreProfileScreen({super.key, this.store});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  String? _appliedCode;
  List<_StoreCoupon>? _apiCoupons;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _fetchCoupons());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCoupons() async {
    final storeId = widget.store?['id'];
    if (storeId == null) return;
    final intId = storeId is int ? storeId : int.tryParse(storeId.toString());
    if (intId == null) return;

    final result = await ApiDataService.fetchCoupons(merchantLocationId: intId);
    final allCoupons = <_StoreCoupon>[];

    void parseCoupons(List<Map<String, dynamic>> list) {
      for (final m in list) {
        final code = m['code']?.toString() ?? '';
        final title = m['title']?.toString() ?? '';
        if (code.isEmpty && title.isEmpty) continue;

        final discountType = m['discount_type']?.toString() ?? 'fixed';
        final discountValue =
            num.tryParse(m['discount_value']?.toString() ?? '0') ?? 0;
        final dealTitle = discountType == 'percentage'
            ? '$discountValue% OFF'
            : '₹$discountValue OFF';

        final requiredPlan = m['required_plan'] is Map
            ? (m['required_plan'] as Map)['name']?.toString() ?? ''
            : (m['is_eligible'] == true ? '' : 'BASIC');

        final catMap = m['category'] is Map
            ? Map<String, dynamic>.from(m['category'] as Map)
            : <String, dynamic>{};
        final badge = catMap['name']?.toString().toUpperCase() ??
            m['segment']?.toString().toUpperCase() ??
            '';

        allCoupons.add(_StoreCoupon(
          title: title.isNotEmpty ? title : dealTitle,
          subtitle: m['description']?.toString() ?? '',
          code: code,
          badge: badge,
          requiredPlan: requiredPlan.toUpperCase(),
        ));
      }
    }

    parseCoupons(result['plan_coupons'] as List<Map<String, dynamic>>);
    parseCoupons(result['store_coupons'] as List<Map<String, dynamic>>);
    parseCoupons(result['other_coupons'] as List<Map<String, dynamic>>);

    if (allCoupons.isNotEmpty && mounted) {
      setState(() => _apiCoupons = allCoupons);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final name = store?['name'] ??
        store?['branch_name'] ??
        store?['store_name'] ??
        'Westside';
    final merchant =
        store?['merchant'] is Map ? store!['merchant'] as Map : null;
    final category =
        store?['category'] ?? merchant?['name'] ?? 'Premium Lifestyle';
    final r = store?['star_rating'] ?? store?['rating'] ?? 4.8;
    final rating = r is num ? r.toDouble() : 4.8;
    final imageUrl = ImageUtils.fromStore(store);
    final coupons = _apiCoupons ?? _buildStoreCoupons();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 390,
                  width: double.infinity,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _headerPlaceholder(),
                          errorWidget: (_, __, ___) => _headerPlaceholder(),
                        )
                      : _headerPlaceholder(),
                ),
                Container(
                  height: 390,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.45),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 42,
                  left: 12,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: 52,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            '323 CUSTOMERS TRANSACTED TODAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.84),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE080),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, size: 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$category • MG Road, Bangalore',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.near_me,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${store?['distance'] ?? '1.2 km'} away',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.schedule,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            const Text(
                              '11:00 AM - 10:00 PM',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await openStoreInMaps(store ?? {});
                        if (!context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Could not open Maps. Try installing Google Maps.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PayBillScreen(
                            merchantLocation: store ?? {},
                            initialCouponCode: _appliedCode,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.payments),
                      label: const Text('Pay Bill'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EXCLUSIVE REWARDS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Curated Rewards',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _AllCouponsScreen(
                          storeName: name,
                          coupons: coupons,
                          onApply: (coupon) {
                            _applyCoupon(coupon);
                          },
                        ),
                      ),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap a coupon to apply at checkout.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 370,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: coupons.length,
                itemBuilder: (_, i) {
                  final coupon = coupons[i];
                  final canApply = true;
                  final applied = _appliedCode == coupon.code;
                  return _CouponCard(
                    coupon: coupon,
                    canApply: canApply,
                    applied: applied,
                    onApply: () => _applyCoupon(coupon),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _headerPlaceholder() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
          ),
        ),
        child: const Center(
            child: Icon(Icons.store_rounded, size: 80, color: Colors.white38)),
      );

  void _applyCoupon(_StoreCoupon coupon) {
    setState(() => _appliedCode = coupon.code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${coupon.code} applied successfully')),
    );
  }
}

class _StoreCoupon {
  final String title;
  final String subtitle;
  final String code;
  final String badge;
  final String requiredPlan;

  const _StoreCoupon({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.badge,
    required this.requiredPlan,
  });
}

List<_StoreCoupon> _buildStoreCoupons() {
  return const [
    _StoreCoupon(
      title: '60% OFF',
      subtitle: 'Premium apparel collections',
      code: 'WST60',
      badge: 'MERCHANT SPECIAL',
      requiredPlan: 'ELITE',
    ),
    _StoreCoupon(
      title: '₹500 CB',
      subtitle: 'Spends above ₹3,000 only',
      code: 'CASHBACK500',
      badge: 'FLASH DEAL',
      requiredPlan: 'PRO',
    ),
    _StoreCoupon(
      title: '15% OFF',
      subtitle: 'HDFC card users exclusive',
      code: 'AUTO APPLIED',
      badge: 'BANK OFFER',
      requiredPlan: 'BASIC',
    ),
    _StoreCoupon(
      title: 'BOGO',
      subtitle: 'On latest select footwear',
      code: 'WESTBOGO',
      badge: 'NEW USER',
      requiredPlan: 'VIP',
    ),
  ];
}

class _AllCouponsScreen extends StatefulWidget {
  final String storeName;
  final List<_StoreCoupon> coupons;
  final void Function(_StoreCoupon) onApply;

  const _AllCouponsScreen({
    required this.storeName,
    required this.coupons,
    required this.onApply,
  });

  @override
  State<_AllCouponsScreen> createState() => _AllCouponsScreenState();
}

class _AllCouponsScreenState extends State<_AllCouponsScreen> {
  String _filter = 'All';
  String? _appliedCode;

  List<_StoreCoupon> get _filtered {
    List<_StoreCoupon> base;
    if (_filter == 'Merchant Deals') {
      base = widget.coupons
          .where(
              (c) => c.badge.contains('MERCHANT') || c.badge.contains('FLASH'))
          .toList();
    } else if (_filter == 'Bank Offers') {
      base = widget.coupons.where((c) => c.badge.contains('BANK')).toList();
    } else {
      base = List.of(widget.coupons);
    }
    if (_appliedCode != null) {
      base.sort((a, b) {
        final aApplied = a.code == _appliedCode ? 0 : 1;
        final bApplied = b.code == _appliedCode ? 0 : 1;
        return aApplied.compareTo(bApplied);
      });
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final coupons = _filtered;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${widget.storeName} Deals',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: Colors.black.withValues(alpha: 0.3)),
                    const SizedBox(width: 10),
                    Text(
                      'Search stores, banks or items...',
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
                itemCount: coupons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final c = coupons[i];
                  final canApply = true;
                  final applied = _appliedCode == c.code;
                  return _CouponListCard(
                    coupon: c,
                    canApply: canApply,
                    applied: applied,
                    onApply: () {
                      setState(() => _appliedCode = c.code);
                      widget.onApply(c);
                    },
                    onLocked: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This offer is available to use.'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponListCard extends StatelessWidget {
  final _StoreCoupon coupon;
  final bool canApply;
  final bool applied;
  final VoidCallback onApply;
  final VoidCallback? onLocked;

  const _CouponListCard({
    required this.coupon,
    required this.canApply,
    required this.applied,
    required this.onApply,
    this.onLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFE1BEC0).withValues(alpha: 0.5)),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        coupon.badge,
                        style: TextStyle(
                          color: _badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _brandName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      coupon.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            coupon.subtitle,
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
              color: const Color(0xFFE1BEC0).withValues(alpha: 0.4),
            ),
            GestureDetector(
              onTap: applied ? null : (canApply ? onApply : onLocked),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 90,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (applied)
                      const Icon(Icons.check_circle,
                          color: Color(0xFF2E7D32), size: 30)
                    else if (!canApply)
                      Icon(Icons.lock, color: Colors.grey.shade400, size: 30),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _badgeColor {
    if (coupon.badge.contains('MERCHANT') || coupon.badge.contains('FLASH')) {
      return AppTheme.primary;
    }
    if (coupon.badge.contains('BANK')) return const Color(0xFF1565C0);
    return AppTheme.secondary;
  }

  String get _brandName {
    if (coupon.badge.contains('MERCHANT')) return 'Starbucks Reserve';
    if (coupon.badge.contains('BANK')) return 'HDFC Bank Cards';
    if (coupon.badge.contains('FLASH')) return 'Flash Deal';
    return "Nature's Basket";
  }
}

class _CouponCard extends StatelessWidget {
  final _StoreCoupon coupon;
  final bool canApply;
  final bool applied;
  final VoidCallback onApply;

  const _CouponCard({
    required this.coupon,
    required this.canApply,
    required this.applied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1BEC0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                coupon.badge,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              coupon.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              coupon.subtitle,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Text(
              'Requires ${coupon.requiredPlan} plan+',
              style: TextStyle(
                color: canApply
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFBA1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1E8),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (coupon.badge.contains('BANK'))
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.verified,
                              size: 14, color: Color(0xFF2E7D32)),
                        ),
                      Expanded(
                        child: Text(
                          'Code: ${coupon.code}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: applied ? null : onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canApply ? AppTheme.primary : Colors.grey,
                    disabledBackgroundColor:
                        applied ? const Color(0xFF2E7D32) : Colors.grey,
                    minimumSize: const Size(96, 38),
                  ),
                  child: Text(
                      applied ? 'APPLIED' : (canApply ? 'APPLY' : 'LOCKED')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
