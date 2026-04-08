import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/api_data_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/campaign_preview_sheet.dart';
import '../../widgets/premium_widgets.dart';
import '../auth/login_screen.dart';
import '../campaigns/campaigns_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/kutoot_bottom_nav.dart';
import '../qr/qr_scan_screen.dart';
import '../stores/store_profile_screen.dart';
import '../payment/pay_bill_screen.dart';
import '../../utils/maps_launch.dart';

void _openPayBill(BuildContext context, Map<String, dynamic> store) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PayBillScreen(merchantLocation: store),
    ),
  );
}

Future<void> _openStoreDirections(
    BuildContext context, Map<String, dynamic> store) async {
  final ok = await openStoreInMaps(store);
  if (!context.mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Could not open Maps. Install Google Maps or try again.'),
      ),
    );
  }
}

void _showHappyHoursSheet(BuildContext context, String cityName) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Happy hours & campaigns',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            'These are time-limited reward campaigns. After you join, you earn stamps by paying at partner stores in the Kutoot app and showing your QR — there is no separate “task app” to install.',
            style: TextStyle(
              height: 1.45,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CampaignsScreen(
                      cityName: cityName,
                      initialTabIndex: 1,
                    ),
                  ),
                );
              },
              child: const Text('View announced campaigns'),
            ),
          ),
        ],
      ),
    ),
  );
}

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
  if (badge.isNotEmpty) {
    return badge.replaceAll('EXT 10% OFF', '10% OFFER');
  }
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

IconData _iconForCategoryName(String rawName) {
  final n = rawName.trim().toLowerCase();
  if (n.isEmpty || n == 'all') {
    return Icons.grid_view_rounded;
  }
  if (n.contains('food') || n.contains('restaurant')) {
    return Icons.restaurant_rounded;
  }
  if (n.contains('shopping') || n.contains('retail')) {
    return Icons.shopping_bag_rounded;
  }
  if (n.contains('health') || n.contains('wellness') || n.contains('beauty')) {
    return Icons.spa_rounded;
  }
  if (n.contains('electronics') || n.contains('tech')) {
    return Icons.devices_rounded;
  }
  if (n.contains('entertainment')) {
    return Icons.movie_rounded;
  }
  if (n.contains('service')) {
    return Icons.build_rounded;
  }
  return Icons.storefront_rounded;
}

bool _storeMatchesSearch(Map<String, dynamic> s, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  String hay(dynamic v) => (v?.toString() ?? '').toLowerCase();
  return hay(s['name']).contains(q) ||
      hay(s['branch_name']).contains(q) ||
      hay(s['city']).contains(q) ||
      hay(s['address']).contains(q);
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
    if (_searchQuery.trim().isEmpty) return _stores;
    return _stores.where((s) => _storeMatchesSearch(s, _searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kutootPageBg,
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              left: InkWell(
                onTap: _openLogin,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.kutootCardSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_circle_outlined,
                          size: 11, color: context.kutootOnSurface),
                      const SizedBox(width: 2),
                      Text('LOGIN',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 7.5,
                              height: 1.05,
                              letterSpacing: 0.2,
                              color: context.kutootOnSurface)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const _HomeShimmer()
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
                            initialTabIndex: 0,
                          ),
                        ),
                      ),
                      onOpenAnnouncements: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CampaignsScreen(
                            cityName: widget.cityName,
                            initialTabIndex: 1,
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
      bottomNavigationBar: KutootBottomNav(
        activeIndex: 0,
        cityName: widget.cityName,
        isLoggedIn: false,
      ),
    );
  }

  void _openLogin() {
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
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _categories = [];
  List<String> _bannerUrls = [];
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;
  Timer? _refreshTimer;
  final _notifService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _fetchData());
    _notifService.startPolling();
    _notifService.addListener(_onNotifUpdate);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notifService.removeListener(_onNotifUpdate);
    super.dispose();
  }

  void _onNotifUpdate() {
    if (mounted) setState(() => _unreadCount = _notifService.unreadCount);
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
    if (_searchQuery.trim().isEmpty) return _stores;
    return _stores.where((s) => _storeMatchesSearch(s, _searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.kutootPageBg,
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
                    color: dark
                        ? const Color(0xFF2C2C2E)
                        : AppTheme.secondary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.secondary.withOpacity(0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on,
                          size: 15,
                          color: dark
                              ? const Color(0xFFFF7A2E)
                              : AppTheme.secondary),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.cityName} ▾',
                        style: TextStyle(
                          color: dark
                              ? const Color(0xFFFFE0D5)
                              : AppTheme.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              notificationCount: _unreadCount,
              onNotificationTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen()),
              ),
            ),
            Expanded(
              child: _loading
                  ? const _HomeShimmer()
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
                            initialTabIndex: 0,
                          ),
                        ),
                      ),
                      onOpenAnnouncements: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CampaignsScreen(
                            cityName: widget.cityName,
                            initialTabIndex: 1,
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
      bottomNavigationBar: KutootBottomNav(
        activeIndex: 0,
        cityName: widget.cityName,
        isLoggedIn: true,
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
    if (_searchQuery.trim().isEmpty) return _stores;
    return _stores.where((s) => _storeMatchesSearch(s, _searchQuery)).toList();
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.kutootPageBg,
      body: SafeArea(
        child: Column(
          children: [
            _HomeTopBar(
              left: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: context.kutootOnSurface),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF2C2C2E)
                          : AppTheme.secondary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppTheme.secondary.withOpacity(0.20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on,
                            size: 15,
                            color: dark
                                ? const Color(0xFFFF7A2E)
                                : AppTheme.secondary),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.cityName} ▾',
                          style: TextStyle(
                            color: dark
                                ? const Color(0xFFFFE0D5)
                                : AppTheme.secondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const _HomeShimmer()
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        children: [
                          _SearchBar(
                            hint: 'Search stores, areas, or branches...',
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
                                final dark = Theme.of(context).brightness ==
                                    Brightness.dark;
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
                                            : (dark
                                                ? const Color(0xFF3A3A3C)
                                                : const Color(0xFFE5E5E5)),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        i == 0 ? 'All' : catName,
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : (dark
                                                  ? context.kutootOnSurface
                                                  : AppTheme.textPrimary),
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
                              Expanded(
                                child: Text(
                                  'Nearby curated stores',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: context.kutootOnSurface,
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
      bottomNavigationBar: KutootBottomNav(
        activeIndex: 0,
        cityName: widget.cityName,
        isLoggedIn: true,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
        children: [
          _SearchBar(
              hint: 'Search stores, areas, or branches...',
              onChanged: onSearchChanged),
          const SizedBox(height: 12),
          Text(
            'EXPLORE CATEGORIES',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              color: context.kutootMutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Stores Nearby',
                  style: TextStyle(
                    color: context.kutootOnSurface,
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
            height: 258,
            child: stores.isEmpty
                ? Center(
                    child: Text('No stores found',
                        style: TextStyle(color: context.kutootMutedText)))
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
          const SizedBox(height: 18),
          _CampaignCarousel(
            campaigns: campaigns,
            bannerUrls: bannerUrls,
            onOpenLive: onOpenLive,
            onCampaignTap: (c) => showCampaignPreview(context, c),
          ),
          const SizedBox(height: 16),
          Text(
            'TOP OFFERS TODAY',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              color: context.kutootMutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TopOfferCard(
                  title: '50% OFF First Order',
                  tagLabel: 'NEW',
                  tagColor: Color(0xFF43A047),
                  gradientBegin: AppTheme.primary,
                  gradientEnd: AppTheme.secondary,
                  imageUrl: null,
                ),
                const SizedBox(width: 12),
                _TopOfferCard(
                  title: 'Free Delivery Weekend',
                  tagLabel: 'LIMITED',
                  tagColor: Color(0xFFFFA000),
                  gradientBegin: AppTheme.secondary,
                  gradientEnd: AppTheme.tertiaryContainer,
                  imageUrl: null,
                ),
                const SizedBox(width: 12),
                _TopOfferCard(
                  title: '2X Stamps on Payments',
                  tagLabel: 'HOT',
                  tagColor: Color(0xFFE53935),
                  gradientBegin: AppTheme.primary,
                  gradientEnd: AppTheme.tertiaryContainer,
                  imageUrl: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllStoresScreen(cityName: cityName),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: dark
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFFF1E8), Color(0xFFFFF8F5)],
                        ),
                  color: dark ? const Color(0xFF1C1C1E) : null,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE1BEC0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            AppTheme.secondary.withOpacity(dark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.near_me,
                          color: dark
                              ? AppTheme.secondaryContainer
                              : AppTheme.secondary,
                          size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEAR YOU RIGHT NOW',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: dark
                                      ? AppTheme.secondaryContainer
                                      : AppTheme.secondary)),
                          const SizedBox(height: 2),
                          Text(
                            stores.isEmpty
                                ? 'Browse stores in $cityName'
                                : '${stores.length} stores • tap to open list',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: dark
                                    ? context.kutootMutedText
                                    : AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: dark
                            ? context.kutootMutedText
                            : AppTheme.secondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showHappyHoursSheet(context, cityName),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: dark
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFFE0B2), Color(0xFFFFF8E1)],
                        ),
                  color: dark ? const Color(0xFF2C2419) : null,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dark
                        ? const Color(0xFFFF8F00).withValues(alpha: 0.35)
                        : const Color(0xFFFFCC80),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6D00)
                            .withOpacity(dark ? 0.25 : 0.15),
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
                          Text(
                            'HAPPY HOURS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: dark
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to learn how it works • view campaigns',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? const Color(0xFFE0E0E0)
                                  : const Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF2A1518)
                  : AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: dark
                      ? AppTheme.primary.withValues(alpha: 0.45)
                      : AppTheme.primary.withOpacity(0.12)),
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
                          '12 people unlocked rewards today  •  5 left',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? context.kutootMutedText
                                  : AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.kutootCardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE1BEC0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(dark ? 0.22 : 0.12),
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
                      Text(
                        'Your Savings So Far',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.kutootOnSurface,
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
                          color: dark
                              ? context.kutootMutedText
                              : AppTheme.textSecondary,
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
  final Function(Map<String, dynamic>)? onCampaignTap;

  const _CampaignCarousel({
    required this.campaigns,
    required this.bannerUrls,
    required this.onOpenLive,
    this.onCampaignTap,
  });

  @override
  State<_CampaignCarousel> createState() => _CampaignCarouselState();
}

class _CampaignCarouselState extends State<_CampaignCarousel> {
  late final PageController _controller;
  Timer? _autoSlide;
  Timer? _zoomPulseTimer;
  int _currentPage = 0;
  bool _zoomed = false;

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
    _zoomPulseTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _zoomed = !_zoomed);
    });
  }

  @override
  void dispose() {
    _autoSlide?.cancel();
    _zoomPulseTimer?.cancel();
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

    return SizedBox(
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
                child: BounceTap(
                  onTap: () {
                    if (widget.onCampaignTap != null) {
                      widget.onCampaignTap!(c);
                    } else {
                      widget.onOpenLive();
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        AnimatedScale(
                          scale: _zoomed ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeInOut,
                          alignment: Alignment.center,
                          child: image.isNotEmpty
                              ? Image.network(
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
                              : Container(
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
                          child: Builder(
                            builder: (ctx) {
                              final d = Theme.of(ctx).brightness ==
                                  Brightness.dark;
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: d
                                      ? Colors.black.withValues(alpha: 0.45)
                                      : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Image.asset(
                                  AppTheme.logoAsset,
                                  height: 24,
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
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
        );
  }
}

class _TopOfferCard extends StatelessWidget {
  final String title;
  final String tagLabel;
  final Color tagColor;
  final Color gradientBegin;
  final Color gradientEnd;
  final String? imageUrl;

  const _TopOfferCard({
    required this.title,
    required this.tagLabel,
    required this.tagColor,
    required this.gradientBegin,
    required this.gradientEnd,
    this.imageUrl,
  });

  bool get _hasImage =>
      imageUrl != null && imageUrl!.trim().isNotEmpty;

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.local_offer_rounded,
          color: Colors.white.withOpacity(0.5),
          size: 36,
        ),
      ),
    );
  }

  Widget _imageErrorFallback() {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 216,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasImage)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!.trim(),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _imagePlaceholder(),
                  errorWidget: (_, __, ___) => _imageErrorFallback(),
                ),
              ),
            if (_hasImage)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final Widget left;
  final String? rightLabel;
  final VoidCallback? onRightTap;
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  const _HomeTopBar(
      {required this.left,
      this.rightLabel,
      this.onRightTap,
      this.notificationCount = 0,
      this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: dark
            ? context.kutootTopBarBg
            : Colors.white.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(color: context.kutootHairlineBorder),
        ),
      ),
      child: Row(
        children: [
          left,
          Expanded(
            child: Center(
              child: Container(
                padding: dark ? const EdgeInsets.all(5) : EdgeInsets.zero,
                decoration: dark
                    ? BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      )
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: dark
                            ? AppTheme.primary.withValues(alpha: 0.35)
                            : const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: dark ? 14 : 20,
                        spreadRadius: dark ? 0 : 2,
                      ),
                    ],
                  ),
                  child: Image.asset('assets/images/k_logo.png',
                      height: dark ? 40 : 48, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          if (onNotificationTap != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 26,
                        color: context.kutootOnSurface.withOpacity(0.7)),
                    if (notificationCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 18, minHeight: 18),
                          child: Text(
                            notificationCount > 9
                                ? '9+'
                                : '$notificationCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (rightLabel != null &&
              rightLabel!.isNotEmpty &&
              onRightTap != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onRightTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                      rightLabel!,
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

class _SearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  const _SearchBar({required this.hint, this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hintC =
        dark ? const Color(0xFF8E8E93) : const Color(0x551C1C1C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.kutootSearchFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: hintC, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: widget.hint,
                hintStyle: TextStyle(
                    color: hintC,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.kutootOnSurface),
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

  const _FlowEntryCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
            color: context.kutootCardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE1BEC0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(dark ? 0.22 : 0.12),
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
                      style: TextStyle(
                          color: dark
                              ? context.kutootOnSurface
                              : AppTheme.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final icon = _iconForCategoryName(label);
    final lower = label.trim().toLowerCase();
    final iconColor =
        lower == 'all' || lower == 'home' ? AppTheme.primary : Colors.white;
    final labelColor = selected
        ? AppTheme.primary
        : (dark ? context.kutootMutedText : AppTheme.textPrimary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: AppTheme.primary.withOpacity(0.12),
      highlightColor: AppTheme.primary.withOpacity(0.06),
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? color : color.withOpacity(0.80),
                borderRadius: BorderRadius.circular(14),
                border: selected
                    ? Border.all(
                        color:
                            dark ? AppTheme.primaryContainer : const Color(0xFFFFD700),
                        width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(dark ? 0.35 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                height: 1.15,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: labelColor,
              ),
            ),
          ],
        ),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openPayBill(context, store),
                              borderRadius: BorderRadius.circular(999),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 7),
                                  child: Center(
                                    child: Text(
                                      'Pay Bill',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.white.withOpacity(0.92),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openStoreDirections(context, store),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.directions,
                                size: 18,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
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
          color: context.kutootCardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withOpacity(0.05),
          ),
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
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.kutootOnSurface)),
            ),
            if (distance.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('📍 $distance AWAY',
                    style: TextStyle(
                        fontSize: 10,
                        color: dark
                            ? context.kutootMutedText
                            : const Color(0x99594042),
                        fontWeight: FontWeight.w700)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openPayBill(context, store),
                        borderRadius: BorderRadius.circular(999),
                        child: Ink(
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
                          child: const Center(
                            child: Text('Pay Bill',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 0.6)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: dark
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openStoreDirections(context, store),
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(Icons.directions,
                            size: 18,
                            color: dark
                                ? context.kutootOnSurface
                                : AppTheme.textPrimary),
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

// _HomeBottomNav removed - now using shared KutootBottomNav

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(dark ? 0.22 : 0.1)
              : (dark ? const Color(0xFF3A3A3C) : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : (dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE1BEC0)),
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
                color: selected
                    ? AppTheme.primary
                    : (dark ? context.kutootMutedText : AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  HOME SHIMMER PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      children: const [
        ShimmerBox(width: double.infinity, height: 48, radius: 14),
        SizedBox(height: 16),
        ShimmerBox(width: double.infinity, height: 200, radius: 22),
        SizedBox(height: 20),
        ShimmerCategoryRow(),
        SizedBox(height: 20),
        ShimmerLine(width: 140),
        SizedBox(height: 12),
        _ShimmerStoreRow(),
        SizedBox(height: 24),
        ShimmerLine(width: 160),
        SizedBox(height: 12),
        _ShimmerStoreRow(),
      ],
    );
  }
}

class _ShimmerStoreRow extends StatelessWidget {
  const _ShimmerStoreRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => const ShimmerStoreCard(),
      ),
    );
  }
}
