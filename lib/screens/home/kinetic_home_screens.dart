import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_data_service.dart';
import '../../services/subscription_plan_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../campaigns/campaigns_screen.dart';
import '../plans/plans_screen.dart';
import '../profile/profile_hub_screen.dart';
import '../rewards/rewards_deals_screen.dart';
import '../qr/qr_scan_screen.dart';
import '../stores/store_profile_screen.dart';

String _storeDisplayTag(Map<String, dynamic> store) {
  if (store['is_new'] == true) return 'NEW';
  if (store['is_trending'] == true) return 'TRENDING';
  if (store['is_hot_deal'] == true) return 'HOT DEAL';
  final d = store['discount'];
  if (d != null) {
    final num? n = d is num ? d : num.tryParse(d.toString());
    if (n != null && n > 0) return 'LIMITED TIME';
  }
  final badge = store['badge']?.toString() ?? '';
  if (badge.isNotEmpty) return badge;
  return '';
}

Color _storeTagBackgroundColor(String tag) {
  switch (tag) {
    case 'HOT DEAL':
      return const Color(0xFFE53935);
    case 'NEW':
      return const Color(0xFF43A047);
    case 'TRENDING':
      return const Color(0xFFFF6D00);
    case 'LIMITED TIME':
      return const Color(0xFFFFA000);
    default:
      return AppTheme.tertiaryContainer;
  }
}

Color _storeTagForegroundColor(String tag) {
  switch (tag) {
    case 'HOT DEAL':
    case 'NEW':
    case 'TRENDING':
    case 'LIMITED TIME':
      return Colors.white;
    default:
      return AppTheme.textPrimary;
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  GUEST HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════
class GuestHomeScreen extends StatefulWidget {
  final String cityName;
  const GuestHomeScreen({super.key, required this.cityName});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int _activeCategory = 0;
  String _searchQuery = '';
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _categories = [];
  List<String> _bannerUrls = [];
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _fetchData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final results = await Future.wait([
      ApiDataService.fetchStores(),
      ApiDataService.fetchCategories(),
      ApiDataService.fetchBannerUrls(),
      ApiDataService.fetchCampaigns(status: 'active'),
    ]);
    if (!mounted) return;
    setState(() {
      _stores = results[0] as List<Map<String, dynamic>>;
      _categories = results[1] as List<Map<String, dynamic>>;
      _bannerUrls = results[2] as List<String>;
      _campaigns = results[3] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  Future<void> _onCategoryTap(int idx) async {
    setState(() => _activeCategory = idx);
    final catId =
        idx > 0 && idx < _categories.length ? _categories[idx]['id'] : null;
    final stores = await ApiDataService.fetchStores(
        categoryId: catId is int ? catId : null);
    if (!mounted) return;
    setState(() => _stores = stores);
  }

  List<Map<String, dynamic>> get _filteredStores {
    if (_searchQuery.isEmpty) return _stores;
    return _stores.where((s) {
      return (s['name']?.toString() ?? '')
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_circle_outlined, size: 16),
                      SizedBox(width: 4),
                      Text('GUEST • LOGIN',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              rightLabel: 'GO PRO',
              onRightTap: _goPro,
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _HomeBody(
                      cityName: widget.cityName,
                      isGuest: true,
                      activeCategory: _activeCategory,
                      categories: _categories,
                      onCategoryTap: _onCategoryTap,
                      stores: _filteredStores,
                      bannerUrls: _bannerUrls,
                      campaigns: _campaigns,
                      onSearchChanged: (q) => setState(() => _searchQuery = q),
                      onRefresh: _fetchData,
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
                          builder: (_) =>
                              AllStoresScreen(cityName: widget.cityName),
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
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  LOGGED-IN HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════
class LoggedInHomeScreen extends StatefulWidget {
  final String cityName;
  const LoggedInHomeScreen({super.key, required this.cityName});

  @override
  State<LoggedInHomeScreen> createState() => _LoggedInHomeScreenState();
}

class _LoggedInHomeScreenState extends State<LoggedInHomeScreen> {
  int _activeCategory = 0;
  String _searchQuery = '';
  String _upgradeLabel = 'UPGRADE';
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _categories = [];
  List<String> _bannerUrls = [];
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPlanLabel();
    _fetchData();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _fetchData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPlanLabel() async {
    final plan = await SubscriptionPlanService.getCurrentPlanName();
    if (!mounted) return;
    setState(() => _upgradeLabel = plan ?? 'UPGRADE');
  }

  Future<void> _fetchData() async {
    final results = await Future.wait([
      ApiDataService.fetchStores(),
      ApiDataService.fetchCategories(),
      ApiDataService.fetchBannerUrls(),
      ApiDataService.fetchCampaigns(status: 'active'),
    ]);
    if (!mounted) return;
    setState(() {
      _stores = results[0] as List<Map<String, dynamic>>;
      _categories = results[1] as List<Map<String, dynamic>>;
      _bannerUrls = results[2] as List<String>;
      _campaigns = results[3] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  Future<void> _onCategoryTap(int idx) async {
    setState(() => _activeCategory = idx);
    final catId =
        idx > 0 && idx < _categories.length ? _categories[idx]['id'] : null;
    final stores = await ApiDataService.fetchStores(
        categoryId: catId is int ? catId : null);
    if (!mounted) return;
    setState(() => _stores = stores);
  }

  List<Map<String, dynamic>> get _filteredStores {
    if (_searchQuery.isEmpty) return _stores;
    return _stores.where((s) {
      return (s['name']?.toString() ?? '')
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              left: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Location settings coming soon')),
                  );
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
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
              ),
              rightLabel: _upgradeLabel,
              onRightTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PlansScreen(cityName: widget.cityName)),
                );
                _loadPlanLabel();
              },
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _HomeBody(
                      cityName: widget.cityName,
                      isGuest: false,
                      activeCategory: _activeCategory,
                      categories: _categories,
                      onCategoryTap: _onCategoryTap,
                      stores: _filteredStores,
                      bannerUrls: _bannerUrls,
                      campaigns: _campaigns,
                      onSearchChanged: (q) => setState(() => _searchQuery = q),
                      onRefresh: _fetchData,
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
                          builder: (_) =>
                              AllStoresScreen(cityName: widget.cityName),
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

// ═══════════════════════════════════════════════════════════════════════
//  ALL STORES SCREEN
// ═══════════════════════════════════════════════════════════════════════
class AllStoresScreen extends StatefulWidget {
  final String cityName;
  const AllStoresScreen({super.key, required this.cityName});

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen> {
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _categories = [];
  int _activeCategory = 0;
  String _searchQuery = '';
  String _sortBy = 'trending';
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _fetchData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final results = await Future.wait([
      ApiDataService.fetchStores(),
      ApiDataService.fetchCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _stores = results[0];
      _categories = results[1];
      _loading = false;
    });
  }

  Future<void> _onCategoryTap(int idx) async {
    setState(() => _activeCategory = idx);
    final catId =
        idx > 0 && idx < _categories.length ? _categories[idx]['id'] : null;
    final stores = await ApiDataService.fetchStores(
        categoryId: catId is int ? catId : null);
    if (!mounted) return;
    setState(() => _stores = stores);
  }

  List<Map<String, dynamic>> get _filteredStores {
    if (_searchQuery.isEmpty) return _stores;
    return _stores.where((s) {
      return (s['name']?.toString() ?? '')
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _applySort(List<Map<String, dynamic>> list) {
    double rating(Map<String, dynamic> s) {
      final r = s['rating'];
      if (r is num) return r.toDouble();
      return double.tryParse(r?.toString() ?? '') ?? 0;
    }

    double discount(Map<String, dynamic> s) {
      final d = s['discount'];
      if (d is num) return d.toDouble();
      return double.tryParse(d?.toString() ?? '') ?? 0;
    }

    double distKm(Map<String, dynamic> s) {
      final t = s['distance']?.toString() ?? '';
      final m = RegExp(r'([\d.]+)').firstMatch(t);
      if (m == null) return double.maxFinite;
      final v = double.tryParse(m.group(1) ?? '') ?? double.maxFinite;
      final low = t.toLowerCase();
      if (low.contains('km')) return v;
      if (low.contains('m') && !low.contains('km')) return v / 1000.0;
      return v;
    }

    switch (_sortBy) {
      case 'nearest':
        list.sort((a, b) => distKm(a).compareTo(distKm(b)));
        break;
      case 'best_value':
        list.sort((a, b) => discount(b).compareTo(discount(a)));
        break;
      case 'popular':
        list.sort((a, b) => rating(b).compareTo(rating(a)));
        break;
      default:
        list.sort((a, b) {
          final tb = b['is_trending'] == true ? 1 : 0;
          final ta = a['is_trending'] == true ? 1 : 0;
          if (tb != ta) return tb.compareTo(ta);
          return rating(b).compareTo(rating(a));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = List<Map<String, dynamic>>.from(_filteredStores);
    _applySort(filtered);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              left: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  const SizedBox(width: 4),
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
                ],
              ),
              rightLabel: 'UPGRADE',
              onRightTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PlansScreen(cityName: widget.cityName)),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        children: [
                          _SearchBar(
                            hint: 'Search stores, brands, or items...',
                            onChanged: (q) => setState(() => _searchQuery = q),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(_categories.length, (i) {
                                final selected = _activeCategory == i;
                                final catName =
                                    _categories[i]['name']?.toString() ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => _onCategoryTap(i),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppTheme.secondary
                                            : const Color(0xFFE5E5E5),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        i == 0 ? 'All' : catName,
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
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _SortChip(label: 'Trending', value: 'trending', selected: _sortBy == 'trending', onTap: () => setState(() => _sortBy = 'trending')),
                                const SizedBox(width: 8),
                                _SortChip(label: 'Nearest', value: 'nearest', selected: _sortBy == 'nearest', onTap: () => setState(() => _sortBy = 'nearest')),
                                const SizedBox(width: 8),
                                _SortChip(label: 'Best Value', value: 'best_value', selected: _sortBy == 'best_value', onTap: () => setState(() => _sortBy = 'best_value')),
                                const SizedBox(width: 8),
                                _SortChip(label: 'Popular', value: 'popular', selected: _sortBy == 'popular', onTap: () => setState(() => _sortBy = 'popular')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(
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
                                '${filtered.length} STORES FOUND',
                                style: const TextStyle(
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
                            itemCount: filtered.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.62,
                            ),
                            itemBuilder: (_, i) =>
                                _StoreCardLarge(store: filtered[i]),
                          ),
                        ],
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
        planLabel: 'UPGRADE',
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  HOME BODY (shared between Guest & Logged-in)
// ═══════════════════════════════════════════════════════════════════════
class _HomeBody extends StatelessWidget {
  final String cityName;
  final bool isGuest;
  final int activeCategory;
  final List<Map<String, dynamic>> categories;
  final ValueChanged<int> onCategoryTap;
  final List<Map<String, dynamic>> stores;
  final List<String> bannerUrls;
  final List<Map<String, dynamic>> campaigns;
  final VoidCallback onOpenLive;
  final VoidCallback onOpenAnnouncements;
  final VoidCallback onSeeAll;
  final ValueChanged<String>? onSearchChanged;
  final Future<void> Function()? onRefresh;

  const _HomeBody({
    required this.cityName,
    required this.isGuest,
    required this.activeCategory,
    required this.categories,
    required this.onCategoryTap,
    required this.stores,
    required this.bannerUrls,
    required this.campaigns,
    required this.onOpenLive,
    required this.onOpenAnnouncements,
    required this.onSeeAll,
    this.onSearchChanged,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        children: [
          _SearchBar(
              hint: 'Search for brands or products...',
              onChanged: onSearchChanged),
          const SizedBox(height: 16),
          _CampaignCarousel(
            campaigns: campaigns,
            bannerUrls: bannerUrls,
            onOpenLive: onOpenLive,
          ),
          const SizedBox(height: 16),
          const Text(
            'TOP OFFERS TODAY',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              color: Color(0xFF9A9A9A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _TopOfferCard(
                  title: '50% OFF First Order',
                  tagLabel: 'NEW',
                  tagColor: Color(0xFF43A047),
                  gradientBegin: AppTheme.primary,
                  gradientEnd: AppTheme.secondary,
                ),
                SizedBox(width: 12),
                _TopOfferCard(
                  title: 'Free Delivery Weekend',
                  tagLabel: 'LIMITED',
                  tagColor: Color(0xFFFFA000),
                  gradientBegin: AppTheme.secondary,
                  gradientEnd: AppTheme.tertiaryContainer,
                ),
                SizedBox(width: 12),
                _TopOfferCard(
                  title: '2X Stamps on Payments',
                  tagLabel: 'HOT',
                  tagColor: Color(0xFFE53935),
                  gradientBegin: AppTheme.primary,
                  gradientEnd: AppTheme.tertiaryContainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'EXPLORE CATEGORIES',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              color: Color(0xFF9A9A9A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final selected = activeCategory == i;
                final catName = categories[i]['name']?.toString() ?? 'ALL';
                return Padding(
                  padding: EdgeInsets.only(
                      right: i == categories.length - 1 ? 0 : 12),
                  child: _CategoryBubble(
                    label: catName,
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF1E8), Color(0xFFFFF8F5)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1BEC0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.near_me,
                      color: AppTheme.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NEAR YOU RIGHT NOW',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppTheme.secondary)),
                      const SizedBox(height: 2),
                      Text(
                          '3 stores with active drops within 1 km',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.secondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE0B2), Color(0xFFFFF8E1)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.access_time_filled,
                      color: Color(0xFFFF6D00), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HAPPY HOURS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '4 PM – 7 PM exclusive discounts active!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8A002B).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF8A002B).withOpacity(0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Color(0xFFE53935), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("YOU'RE MISSING OUT",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: Color(0xFFE53935))),
                      const SizedBox(height: 2),
                      Text(
                          '12 people unlocked drops today  •  5 left',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
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
            child: stores.isEmpty
                ? const Center(
                    child: Text('No stores found',
                        style: TextStyle(color: Color(0xFF9A9A9A))))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stores.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(
                          right: i == stores.length - 1 ? 0 : 12),
                      child: _StoreCardCompact(store: stores[i]),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1BEC0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.savings_outlined,
                      color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Savings So Far',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹0 saved',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Keep shopping to unlock more savings!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _CampaignCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> campaigns;
  final List<String> bannerUrls;
  final VoidCallback onOpenLive;

  const _CampaignCarousel({
    required this.campaigns,
    required this.bannerUrls,
    required this.onOpenLive,
  });

  @override
  State<_CampaignCarousel> createState() => _CampaignCarouselState();
}

class _CampaignCarouselState extends State<_CampaignCarousel> {
  late final PageController _controller;
  Timer? _autoSlide;
  int _currentPage = 0;

  List<Map<String, dynamic>> get _items {
    if (widget.campaigns.isNotEmpty) return widget.campaigns;
    return _fallbackCampaigns;
  }

  static final _fallbackCampaigns = <Map<String, dynamic>>[
    {
      'title': 'LUXURY VILLA',
      'image': '',
      'is_active': true,
      'gradient': [const Color(0xFF1A237E), const Color(0xFF0D47A1)],
    },
    {
      'title': 'BMW M4 COMPETITION',
      'image': '',
      'is_active': true,
      'gradient': [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
    },
    {
      'title': 'IPHONE PRO MAX',
      'image': '',
      'is_active': true,
      'gradient': [const Color(0xFF4A148C), const Color(0xFF6A1B9A)],
    },
    {
      'title': '1KG GOLD BAR',
      'image': '',
      'is_active': true,
      'gradient': [const Color(0xFFE65100), const Color(0xFFF57C00)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlide?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlide?.cancel();
    _autoSlide = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _items.isEmpty) return;
      final next = (_currentPage + 1) % _items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty && widget.bannerUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    if (items.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Image.network(widget.bannerUrls[0],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.primary.withOpacity(0.1))),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) {
              final c = items[i];
              final title = c['title']?.toString() ?? 'Campaign';
              final image = c['image']?.toString() ?? '';
              final isActive = c['is_active'] == true;
              final gradientColors = c['gradient'] is List
                  ? (c['gradient'] as List).cast<Color>()
                  : <Color>[AppTheme.primary, AppTheme.primaryDark];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: widget.onOpenLive,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (image.isNotEmpty)
                          Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: gradientColors,
                                ),
                              ),
                              child: Center(
                                child: Image.asset(AppTheme.logoAsset,
                                    height: 60,
                                    fit: BoxFit.contain,
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: gradientColors,
                              ),
                            ),
                            child: Center(
                              child: Image.asset(AppTheme.logoAsset,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.3, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.78),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF43A047)
                                  : const Color(0xFF757575),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isActive)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  isActive ? 'LIVE' : 'COMING SOON',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Image.asset(
                            AppTheme.logoAsset,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title.toUpperCase(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Shop. Dream. Win.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : const Color(0xFFD5C8BE),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TopOfferCard extends StatelessWidget {
  final String title;
  final String tagLabel;
  final Color tagColor;
  final Color gradientBegin;
  final Color gradientEnd;

  const _TopOfferCard({
    required this.title,
    required this.tagLabel,
    required this.tagColor,
    required this.gradientBegin,
    required this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientBegin, gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: gradientBegin.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                tagLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final Widget left;
  final String rightLabel;
  final VoidCallback onRightTap;

  const _HomeTopBar(
      {required this.left, required this.rightLabel, required this.onRightTap});

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
              child: Image.asset('assets/images/k_logo.png',
                  height: 48, fit: BoxFit.contain),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rightLabel == 'GO PRO')
                const Text('FREE MEMBER',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8)),
              if (rightLabel == 'GO PRO') const SizedBox(height: 2),
              InkWell(
                onTap: onRightTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  const _SearchBar({required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.search, color: Color(0x551C1C1C), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                  color: Color(0x551C1C1C),
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _FlowEntryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FlowEntryCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.primary.withOpacity(0.12),
        highlightColor: AppTheme.primary.withOpacity(0.06),
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
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
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

  const _CategoryBubble(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  IconData get _icon {
    switch (label) {
      case 'FASHION':
        return Icons.checkroom;
      case 'ELECTRONICS':
        return Icons.devices_other;
      case 'HOME':
        return Icons.chair;
      case 'BEAUTY':
        return Icons.spa;
      default:
        return Icons.grid_view;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        label == 'ALL' || label == 'HOME' ? AppTheme.primary : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: AppTheme.primary.withOpacity(0.12),
      highlightColor: AppTheme.primary.withOpacity(0.06),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected ? color : color.withOpacity(0.80),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Icon(_icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? AppTheme.primary : AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _StoreCardCompact extends StatelessWidget {
  final Map<String, dynamic> store;
  const _StoreCardCompact({required this.store});

  @override
  Widget build(BuildContext context) {
    final name = store['name']?.toString() ?? 'Store';
    final image = store['image']?.toString() ?? '';
    final tag = _storeDisplayTag(store);
    final tagBg = _storeTagBackgroundColor(tag);
    final tagFg = _storeTagForegroundColor(tag);
    final rating = store['rating']?.toString() ?? '4.5';
    final distance = store['distance']?.toString() ?? '';

    return SizedBox(
      width: 155,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoreProfileScreen(store: store)),
        ),
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primary.withOpacity(0.1),
                        child: const Icon(Icons.store,
                            size: 48, color: AppTheme.primary),
                      )),
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
              if (tag.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(tag,
                        style: TextStyle(
                            color: tagFg,
                            fontWeight: FontWeight.w800,
                            fontSize: 10)),
                  ),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
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
                          ' $rating${distance.isNotEmpty ? "  • $distance" : ""}',
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
  final Map<String, dynamic> store;
  const _StoreCardLarge({required this.store});

  @override
  Widget build(BuildContext context) {
    final name = store['name']?.toString() ?? 'Store';
    final image = store['image']?.toString() ?? '';
    final tag = _storeDisplayTag(store);
    final tagBg = _storeTagBackgroundColor(tag);
    final tagFg = _storeTagForegroundColor(tag);
    final rating = store['rating']?.toString() ?? '4.5';
    final distance = store['distance']?.toString() ?? '';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoreProfileScreen(store: store)),
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
                    Image.network(image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.primary.withOpacity(0.1),
                              child: const Icon(Icons.store,
                                  size: 48, color: AppTheme.primary),
                            )),
                    if (tag.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(tag,
                              style: TextStyle(
                                  color: tagFg,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9)),
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
                            Text(' $rating',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 11)),
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
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            if (distance.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('📍 $distance AWAY',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0x99594042),
                        fontWeight: FontWeight.w700)),
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
                              offset: const Offset(0, 4))
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('PAY BILL',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.6)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(18)),
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withOpacity(0.36),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        type: MaterialType.circle,
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
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
            ),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 27),
          ),
        ),
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  final int activeIndex;
  final String cityName;
  final bool isLoggedIn;
  final String planLabel;
  const _HomeBottomNav(
      {required this.activeIndex,
      required this.cityName,
      required this.isLoggedIn,
      required this.planLabel});

  @override
  Widget build(BuildContext context) {
    final items = ['HOME', 'DROPS', 'PLANS', 'PROFILE'];
    final icons = [
      Icons.home_rounded,
      Icons.local_offer_rounded,
      Icons.confirmation_num_rounded,
      Icons.person_rounded
    ];
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomPad > 0 ? bottomPad : 8),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: SizedBox(
        height: 64,
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
                                    builder: (_) =>
                                        PlansScreen(cityName: cityName))),
                          ),
                        ));
                  } else if (i == 2) {
                    if (isLoggedIn) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PlansScreen(cityName: cityName)));
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()));
                    }
                  } else if (i == 3) {
                    if (isLoggedIn) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileHubScreen(
                                cityName: cityName, planLabel: planLabel),
                          ));
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()));
                    }
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icons[i],
                        color:
                            active ? AppTheme.primary : const Color(0xFF9A9A9A),
                        size: 25),
                    const SizedBox(height: 2),
                    Text(items[i],
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w900 : FontWeight.w700,
                            color: active
                                ? AppTheme.primary
                                : const Color(0xFF9A9A9A))),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFE1BEC0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.check, size: 14, color: AppTheme.primary),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
