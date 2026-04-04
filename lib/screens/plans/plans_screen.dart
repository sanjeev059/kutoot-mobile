import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_data_service.dart';
import '../../theme/app_theme.dart';
import '../payment/plan_payment_flow_screen.dart';
import '../home/kinetic_home_screens.dart';
import '../profile/profile_hub_screen.dart';
import '../qr/qr_scan_screen.dart';

class PlansScreen extends StatefulWidget {
  final String cityName;
  const PlansScreen({super.key, required this.cityName});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _selectedIndex = 0;
  List<_PlanData> _plans = _fallbackPlans;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _fetchPlans());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    try {
      final apiPlans = await ApiDataService.fetchPlans();
      if (apiPlans.isNotEmpty && mounted) {
        final parsed = apiPlans.map<_PlanData>((p) {
          final name = p['name']?.toString() ?? 'Plan';
          final price = p['price']?.toString() ?? '0';
          final isDefault = p['is_default'] == true;
          return _PlanData(
            id: p['id'] is int
                ? p['id'] as int
                : int.tryParse(p['id']?.toString() ?? '0') ?? 0,
            name: name,
            tier: isDefault ? 'FREE TIER' : 'MEMBERSHIP',
            price: price,
            validity: p['validity']?.toString() ?? 'Forever',
            maxBills: '${p['max_discounted_bills'] ?? 0} Trans.',
            maxRedeem: '₹${p['max_redeemable_amount'] ?? 0}',
            earnRate: '${p['stamps_per_transaction'] ?? 1} / bill',
            bonus: '${p['stamps_on_purchase'] ?? 0} Stamps',
            icon: _iconForPlan(name),
            badges: _badgesForPlan(name),
            deals: _dealsFromPlan(p),
            gradient: _gradientForPlan(name),
          );
        }).toList();
        if (parsed.isNotEmpty) {
          setState(() => _plans = parsed);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  static IconData _iconForPlan(String name) {
    switch (name.toLowerCase()) {
      case 'basic':
        return Icons.card_membership;
      case 'pro':
        return Icons.workspace_premium;
      case 'vip':
        return Icons.diamond_outlined;
      case 'elite':
        return Icons.emoji_events_outlined;
      default:
        return Icons.person_outline;
    }
  }

  static List<String> _badgesForPlan(String name) {
    switch (name.toLowerCase()) {
      case 'basic':
        return ['Best Value'];
      case 'pro':
        return ['Popular'];
      case 'vip':
        return ['Priority'];
      case 'elite':
        return ['Premium', 'Exclusive'];
      default:
        return [];
    }
  }

  static List<Color> _gradientForPlan(String name) {
    switch (name.toLowerCase()) {
      case 'basic':
        return [const Color(0xFF8A002B), const Color(0xFF4A0018)];
      case 'pro':
        return [const Color(0xFFA04100), const Color(0xFF612500)];
      case 'vip':
        return [const Color(0xFFEA6B1E), const Color(0xFF9A3A00)];
      case 'elite':
        return [const Color(0xFF221A14), const Color(0xFF3B322B)];
      default:
        return [const Color(0xFF9E9E9E), const Color(0xFF616161)];
    }
  }

  static List<String> _dealsFromPlan(Map<String, dynamic> p) {
    final cats = p['coupon_categories'];
    if (cats is List && cats.isNotEmpty) {
      return cats
          .map<String>(
              (c) => c is Map ? (c['name']?.toString() ?? '') : c.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    switch ((p['name'] ?? '').toString().toLowerCase()) {
      case 'basic':
        return ['Merchant', 'Platform'];
      case 'pro':
        return ['Merchant', 'Platform', 'Bank'];
      case 'vip':
        return ['Merchant', 'Platform', 'Bank', 'Flash Deals'];
      case 'elite':
        return ['Merchant', 'Platform', 'Bank', 'Exclusive', 'Concierge'];
      default:
        return ['Basic Merchant'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeArea(
        child: Column(
          children: [
            _PlansTopBar(cityName: widget.cityName),
            const SizedBox(height: 8),
            const Text(
              'Choose a plan that suits your shopping.',
              style: TextStyle(
                color: Color(0x99594042),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchPlans,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.86),
                        onPageChanged: (index) =>
                            setState(() => _selectedIndex = index),
                        itemCount: _plans.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: _PlanCard(
                            plan: _plans[i],
                            selected: _selectedIndex == i,
                            onSelect: () {
                              setState(() => _selectedIndex = i);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlanPaymentScreen(
                                    planId: _plans[i].id,
                                    planName: _plans[i].name,
                                    amount: _plans[i].price,
                                    cityName: widget.cityName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScanScreen()),
        ),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.36),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
        ),
      ),
      bottomNavigationBar: _PlansBottomNav(cityName: widget.cityName),
    );
  }
}

class _PlansTopBar extends StatelessWidget {
  final String cityName;
  const _PlansTopBar({required this.cityName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withOpacity(0.92),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Image.asset(
                'assets/images/k_logo.png',
                height: 48,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: AppTheme.secondary.withOpacity(0.20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 15, color: AppTheme.secondary),
                    const SizedBox(width: 2),
                    Text(
                      '$cityName ▾',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.close, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _PlanData plan;
  final bool selected;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: plan.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(plan.icon, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  if (plan.badges.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: plan.badges
                          .map(
                            (b) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                b,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plan.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                plan.tier,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${plan.price}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                plan.validity,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _MiniMetric(
                          label: 'MAX BILLS', value: plan.maxBills)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _MiniMetric(
                          label: 'MAX REDEEM', value: plan.maxRedeem)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _MiniMetric(
                          label: 'EARN RATE', value: plan.earnRate)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _MiniMetric(label: 'BONUS', value: plan.bonus)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'ELIGIBLE DROPS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 9,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: plan.deals
                    .map(
                      (d) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.11),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Text(
                    'SELECT ${plan.name.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 8,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansBottomNav extends StatelessWidget {
  final String cityName;
  const _PlansBottomNav({required this.cityName});
  @override
  Widget build(BuildContext context) {
    final items = ['HOME', 'DROPS', 'PLANS', 'PROFILE'];
    final icons = [
      Icons.home_rounded,
      Icons.local_offer_rounded,
      Icons.confirmation_num_rounded,
      Icons.person_rounded,
    ];
    return Container(
      height: 84,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == 2;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (i == 0) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => LoggedInHomeScreen(cityName: cityName),
                    ),
                    (route) => false,
                  );
                } else if (i == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileHubScreen(
                        cityName: cityName,
                        planLabel: 'UPGRADE',
                      ),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[i],
                    color: active ? AppTheme.primary : const Color(0xFF9A9A9A),
                    size: 25,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                      color:
                          active ? AppTheme.primary : const Color(0xFF9A9A9A),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PlanData {
  final int id;
  final String name;
  final String tier;
  final String price;
  final String validity;
  final String maxBills;
  final String maxRedeem;
  final String earnRate;
  final String bonus;
  final IconData icon;
  final List<String> badges;
  final List<String> deals;
  final List<Color> gradient;

  const _PlanData({
    this.id = 0,
    required this.name,
    required this.tier,
    required this.price,
    required this.validity,
    required this.maxBills,
    required this.maxRedeem,
    required this.earnRate,
    required this.bonus,
    required this.icon,
    required this.badges,
    required this.deals,
    required this.gradient,
  });
}

const List<_PlanData> _fallbackPlans = [
  _PlanData(
    name: 'Free',
    tier: 'FREE TIER',
    price: '0',
    validity: 'Forever',
    maxBills: '5 Trans.',
    maxRedeem: '₹500',
    earnRate: '1 / ₹2000',
    bonus: '0 Stamps',
    icon: Icons.person_outline,
    badges: [],
    deals: ['Basic Merchant'],
    gradient: [Color(0xFF9E9E9E), Color(0xFF616161)],
  ),
  _PlanData(
    name: 'Basic',
    tier: 'TIER I MEMBERSHIP',
    price: '149',
    validity: '/ 1 day',
    maxBills: '20 Trans.',
    maxRedeem: '₹2200',
    earnRate: '1 / ₹1000',
    bonus: '5 Stamps',
    icon: Icons.card_membership,
    badges: ['Best Value'],
    deals: ['Merchant', 'Platform'],
    gradient: [Color(0xFF8A002B), Color(0xFF4A0018)],
  ),
  _PlanData(
    name: 'Pro',
    tier: 'TIER II MEMBERSHIP',
    price: '399',
    validity: '/ 7 days',
    maxBills: '60 Trans.',
    maxRedeem: '₹7000',
    earnRate: '1 / ₹700',
    bonus: '12 Stamps',
    icon: Icons.workspace_premium,
    badges: ['Popular'],
    deals: ['Merchant', 'Platform', 'Bank'],
    gradient: [Color(0xFFA04100), Color(0xFF612500)],
  ),
  _PlanData(
    name: 'VIP',
    tier: 'TIER III MEMBERSHIP',
    price: '799',
    validity: '/ 15 days',
    maxBills: '120 Trans.',
    maxRedeem: '₹15000',
    earnRate: '1 / ₹500',
    bonus: '25 Stamps',
    icon: Icons.diamond_outlined,
    badges: ['Priority'],
    deals: ['Merchant', 'Platform', 'Bank', 'Flash Deals'],
    gradient: [Color(0xFFEA6B1E), Color(0xFF9A3A00)],
  ),
  _PlanData(
    name: 'Elite',
    tier: 'TIER IV MEMBERSHIP',
    price: '1499',
    validity: '/ 30 days',
    maxBills: 'Unlimited',
    maxRedeem: '₹50000',
    earnRate: '1 / ₹300',
    bonus: '50 Stamps',
    icon: Icons.emoji_events_outlined,
    badges: ['Premium', 'Exclusive'],
    deals: ['Merchant', 'Platform', 'Bank', 'Exclusive', 'Concierge'],
    gradient: [Color(0xFF221A14), Color(0xFF3B322B)],
  ),
];
