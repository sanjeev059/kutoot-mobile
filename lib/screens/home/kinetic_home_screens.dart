import 'package:flutter/material.dart';
import '../../services/subscription_plan_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../campaigns/campaigns_screen.dart';
import '../plans/plans_screen.dart';
import '../profile/profile_hub_screen.dart';
import '../rewards/rewards_deals_screen.dart';
import '../stores/store_profile_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  final String cityName;

  const GuestHomeScreen({super.key, required this.cityName});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int _activeCategory = 0;

  @override
  Widget build(BuildContext context) {
    final stores = _stores.where((s) {
      if (_activeCategory == 0) return true;
      return s.category == _categories[_activeCategory];
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              left: InkWell(
                onTap: _goPro,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.account_circle_outlined, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'GUEST • LOGIN',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              rightLabel: 'GO PRO',
              onRightTap: _goPro,
            ),
            Expanded(
              child: _HomeBody(
                cityName: widget.cityName,
                isGuest: true,
                activeCategory: _activeCategory,
                onCategoryTap: (idx) => setState(() => _activeCategory = idx),
                stores: stores,
                onOpenLive: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampaignsScreen(
                      cityName: widget.cityName,
                      upgradeLabel: 'GO PRO',
                      initialTabIndex: 0,
                      onUpgradeTap: _goPro,
                    ),
                  ),
                ),
                onOpenAnnouncements: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampaignsScreen(
                      cityName: widget.cityName,
                      upgradeLabel: 'GO PRO',
                      initialTabIndex: 1,
                      onUpgradeTap: _goPro,
                    ),
                  ),
                ),
                onSeeAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllStoresScreen(cityName: widget.cityName),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _QrFab(),
      bottomNavigationBar: _HomeBottomNav(
        activeIndex: 0,
        cityName: widget.cityName,
        isLoggedIn: false,
        planLabel: 'FREE',
      ),
    );
  }

  void _goPro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

class LoggedInHomeScreen extends StatefulWidget {
  final String cityName;
  const LoggedInHomeScreen({super.key, required this.cityName});

  @override
  State<LoggedInHomeScreen> createState() => _LoggedInHomeScreenState();
}

class _LoggedInHomeScreenState extends State<LoggedInHomeScreen> {
  int _activeCategory = 0;
  String _upgradeLabel = 'UPGRADE';

  @override
  void initState() {
    super.initState();
    _loadPlanLabel();
  }

  Future<void> _loadPlanLabel() async {
    final plan = await SubscriptionPlanService.getCurrentPlanName();
    if (!mounted) return;
    setState(() {
      _upgradeLabel = plan ?? 'UPGRADE';
    });
  }

  @override
  Widget build(BuildContext context) {
    final stores = _stores.where((s) {
      if (_activeCategory == 0) return true;
      return s.category == _categories[_activeCategory];
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              left: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: AppTheme.secondary.withOpacity(0.20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        size: 15, color: AppTheme.secondary),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.cityName} ▾',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              rightLabel: _upgradeLabel,
              onRightTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlansScreen(cityName: widget.cityName),
                  ),
                );
                _loadPlanLabel();
              },
            ),
            Expanded(
              child: _HomeBody(
                cityName: widget.cityName,
                isGuest: false,
                activeCategory: _activeCategory,
                onCategoryTap: (idx) => setState(() => _activeCategory = idx),
                stores: stores,
                onOpenLive: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampaignsScreen(
                      cityName: widget.cityName,
                      upgradeLabel: _upgradeLabel,
                      initialTabIndex: 0,
                      onUpgradeTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlansScreen(cityName: widget.cityName),
                        ),
                      ),
                    ),
                  ),
                ),
                onOpenAnnouncements: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampaignsScreen(
                      cityName: widget.cityName,
                      upgradeLabel: _upgradeLabel,
                      initialTabIndex: 1,
                      onUpgradeTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlansScreen(cityName: widget.cityName),
                        ),
                      ),
                    ),
                  ),
                ),
                onSeeAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllStoresScreen(cityName: widget.cityName),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _QrFab(),
      bottomNavigationBar: _HomeBottomNav(
        activeIndex: 0,
        cityName: widget.cityName,
        isLoggedIn: true,
        planLabel: _upgradeLabel,
      ),
    );
  }
}

class AllStoresScreen extends StatelessWidget {
  final String cityName;
  const AllStoresScreen({super.key, required this.cityName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              left: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: AppTheme.secondary.withOpacity(0.20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
              rightLabel: 'UPGRADE',
              onRightTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlansScreen(cityName: cityName),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  const _SearchBar(hint: 'Search stores, brands, or items...'),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_categories.length, (i) {
                        final selected = i == 0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.secondary
                                  : const Color(0xFFE5E5E5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              i == 0 ? 'All' : _categories[i],
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Nearby curated stores',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Text(
                        '24 STORES FOUND',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stores.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemBuilder: (_, i) => _StoreCardLarge(store: _stores[i]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _QrFab(),
      bottomNavigationBar: _HomeBottomNav(
        activeIndex: 0,
        cityName: cityName,
        isLoggedIn: true,
        planLabel: 'UPGRADE',
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final String cityName;
  final bool isGuest;
  final int activeCategory;
  final ValueChanged<int> onCategoryTap;
  final List<_StoreItem> stores;
  final VoidCallback onOpenLive;
  final VoidCallback onOpenAnnouncements;
  final VoidCallback onSeeAll;

  const _HomeBody({
    required this.cityName,
    required this.isGuest,
    required this.activeCategory,
    required this.onCategoryTap,
    required this.stores,
    required this.onOpenLive,
    required this.onOpenAnnouncements,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      children: [
        const _SearchBar(hint: 'Search for brands or products...'),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCPH9hMRCozh3NfthtmLUKM6o287QOpScFM7sZ1vv6CrYy63ww2DV_t4JFmMZL3kEB_Dr7EAmhF8l0bHvPpTNRConFTaAFvxbewYzw8DrCf9ffWdOoulpmTlPy8WaqZeujPiC199Y0uhnmERB14HOa29AbH4dc10mOmo9hZb1O3x0D15yazXmi2SqdtwfyAOFLbo1qKrDIlvtAUu1Ja6CBiCA4cOUDl8Z8bmpehyRtcECfYmHsUzADG8PeATdI0NO9eW2tJ3iFPaVDp',
                  fit: BoxFit.cover,
                ),
                Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppTheme.primary.withOpacity(0.85),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: const Text(
                    'Upto 70% Off',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'DISCOVER CATEGORIES',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: Color(0xFF9A9A9A),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 94,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final selected = activeCategory == i;
              return Padding(
                padding: EdgeInsets.only(
                    right: i == _categories.length - 1 ? 0 : 12),
                child: _CategoryBubble(
                  label: _categories[i],
                  selected: selected,
                  onTap: () => onCategoryTap(i),
                  color: i == 1
                      ? AppTheme.primary
                      : i == 2
                          ? AppTheme.secondary
                          : i == 3
                              ? AppTheme.tertiaryContainer
                              : const Color(0xFFF2DCE3),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FlowEntryCard(
                title: 'LIVE',
                subtitle: 'Campaigns',
                icon: Icons.bolt_rounded,
                onTap: onOpenLive,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FlowEntryCard(
                title: 'ANNOUNCED',
                subtitle: 'Campaigns',
                icon: Icons.campaign_rounded,
                onTap: onOpenAnnouncements,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Stores Nearby',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'SEE ALL  ▶',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(right: i == stores.length - 1 ? 0 : 12),
              child: _StoreCardCompact(store: stores[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final Widget left;
  final String rightLabel;
  final VoidCallback onRightTap;

  const _HomeTopBar({
    required this.left,
    required this.rightLabel,
    required this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withOpacity(0.92),
      child: Row(
        children: [
          left,
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/k_logo.png',
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
          ),
          InkWell(
            onTap: onRightTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.26),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                rightLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  const _SearchBar({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0x7A1C1C1C), size: 28),
          const SizedBox(width: 8),
          Text(
            hint,
            style: const TextStyle(
              color: Color(0x661C1C1C),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowEntryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FlowEntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1BEC0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _CategoryBubble extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryBubble({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        label == 'ALL' || label == 'HOME' ? AppTheme.primary : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: selected ? color : color.withOpacity(0.80),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              label == 'FASHION'
                  ? Icons.checkroom
                  : label == 'ELECTRONICS'
                      ? Icons.devices_other
                      : label == 'HOME'
                          ? Icons.chair
                          : Icons.grid_view,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              color: selected ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCardCompact extends StatelessWidget {
  final _StoreItem store;
  const _StoreCardCompact({required this.store});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreProfileScreen(store: store.toMap()),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(store.image, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.88),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    store.badge,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 10),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 13, color: AppTheme.tertiaryContainer),
                        Text(
                          ' ${store.rating}  • ${store.distance}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreCardLarge extends StatelessWidget {
  final _StoreItem store;
  const _StoreCardLarge({required this.store});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreProfileScreen(store: store.toMap()),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(store.image, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          store.badge,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 9),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppTheme.tertiaryContainer, size: 13),
                            Text(
                              ' ${store.rating}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Text(
                store.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '📍 ${store.distance} AWAY',
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0x99594042),
                    fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'PAY BILL',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.near_me, size: 18),
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

class _QrFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 27),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  final int activeIndex;
  final String cityName;
  final bool isLoggedIn;
  final String planLabel;
  const _HomeBottomNav({
    required this.activeIndex,
    required this.cityName,
    required this.isLoggedIn,
    required this.planLabel,
  });

  @override
  Widget build(BuildContext context) {
    final items = ['HOME', 'REWARDS', 'PLANS', 'ACCOUNT'];
    final icons = [
      Icons.home_rounded,
      Icons.sell_rounded,
      Icons.confirmation_num_rounded,
      Icons.person_rounded,
    ];
    return Container(
      height: 84,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = activeIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (i == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RewardsDealsScreen(
                        cityName: cityName,
                        upgradeLabel: planLabel,
                        onUpgradeTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlansScreen(cityName: cityName),
                          ),
                        ),
                      ),
                    ),
                  );
                  return;
                }
                if (i == 2) {
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlansScreen(cityName: cityName),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                  return;
                }
                if (i == 3) {
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileHubScreen(
                          cityName: cityName,
                          planLabel: planLabel,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
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

class _StoreItem {
  final int id;
  final String name;
  final String category;
  final String image;
  final String badge;
  final String rating;
  final String distance;

  const _StoreItem({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.badge,
    required this.rating,
    required this.distance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'image': image,
      'badge': badge,
      'rating': rating,
      'distance': distance,
      'is_demo_store': true,
      'source': 'home_static',
    };
  }
}

const List<String> _categories = [
  'ALL',
  'FASHION',
  'ELECTRONICS',
  'HOME',
  'BEAUTY'
];

const List<_StoreItem> _stores = [
  _StoreItem(
    id: 101,
    name: 'Westside',
    category: 'FASHION',
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuC-G-9JECKc4p-QWP2LcUZycO_1MrQk6lY9_tzqV_OEFbUimLGUT63ICHGRgaMnVslwyryofi3hAO-R_PRGPWK4Q_GiiQCbDdur4do_MaV-ddX7NbEBhi6FJsAlUBODWGe4sqAqfHqEfxPmRJ5EAJm3O8ZP_HdxZLrI0Pn5ZEQ--6yY-x24M9W9i6JHXwsM6vRmAvBsQx16-l50FCqp6twRNIWJUXcouZMYdxmFGrzM8RyNwWskC48v32ktcLOfzQGVNEbrRJosrZhm',
    badge: '15% OFF',
    rating: '4.5',
    distance: '1.2 km',
  ),
  _StoreItem(
    id: 102,
    name: 'Croma',
    category: 'ELECTRONICS',
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAUDHP3i51_AfeqtPe-dzEkR4HWCjgcnjEwU44IG3_sD8Ui2-XaLe-rPaAH9ILxU3uZAT1xMGXorP6yVustg6lFMyagLgupRbO37jsYuXgQL6h3efR8uk-JbZV4g02Wo3iHRmVt3CpCT6cw3Bqvz96k_r1QwOx56g2PHd9-QWwGYaT5Is4k-FXLC-MPnm_oDzcxkziZGl-mpJMjScJnoCOojnbN6ttS2Dr2dShDSEkn5-M83mBwDvg62ZKioLvJlGMBXpXN5HgzwQu1',
    badge: 'EXCLUSIVE',
    rating: '4.7',
    distance: '2.1 km',
  ),
  _StoreItem(
    id: 103,
    name: 'Reliance Digital',
    category: 'ELECTRONICS',
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAfYcqf6LF2jIg9uNMLSLCNPhurMGTqyKtihB8_sjbCaSIPNyvr9WWofdp35dY5nOb3MiQVQlHnZs6Ik7D9Q9jNQ5hBqV1_FOn72NufxfV59Hbz-mhRUAXoXzWA9h9_S10q3Dww2zro_DdIwC06-kSHQ1iaj0XFB5MTMWsSR7v_C4Jhkq0LR_jvEveNv7fOtvC6UR-aydqop_SqGEgUWCeGd5VAYOCoQ3dJdVf3Z3CsDI1xslffQtOfzBeXTgUJH1escO6PWZR8esI',
    badge: '10% OFF',
    rating: '4.4',
    distance: '1.9 km',
  ),
  _StoreItem(
    id: 104,
    name: 'Nykaa Luxe',
    category: 'BEAUTY',
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDMQ8epcMm-c6LllV8dXvZFaapPJd5hz-EmlGWv8ItN6OLpKPTc-reumCV6Pm3193580lp1cLKh5sGupU470ffI-laRJNFFKmlwvHPjYHUKoczHmhzeoN-aSM3D9MdEEsiYXOuyWwp6nGh724UIg2WzY7s57L1oE2mNwphs-OUJtUHSJiiVCVmS4dSrAPmmYgUe4_I-J8qPMuzg3ABGlTcVf5-5qoKv3wGHxqIl6v5qtU3kZJwJ6dazxfg0Min-Y7DqBfjznNvls_g',
    badge: 'FLAT ₹500',
    rating: '4.9',
    distance: '1.5 km',
  ),
  _StoreItem(
    id: 105,
    name: 'Home Centre',
    category: 'HOME',
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuC8S9lnC0l-6bxkdx4sx7b96JcGcAH0AEdqPCvAhm8wVZnTywYsMWEDbxn1oTDV61KZbQET06wsKc4_vIXehaIl25sMPEomuuorwsK-Y54fOrueEeCW9OSlY6HlksO416zUNzgU-26CgQU_vs6GNPDOH9HhZDcPQv9jy2JQ_5Z3LyNFdsfRTcTeFJ_hC1YwQhXSEIV0XswHW7aK2jtT6uthtP4LBn4ftAj84mvpswr8IsVka1BztAdvMcXfuHYQQEzL7ouq1ron7sw',
    badge: 'EXT 10% OFF',
    rating: '4.2',
    distance: '2.4 km',
  ),
];
