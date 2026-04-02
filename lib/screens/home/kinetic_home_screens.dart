import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../api/kutoot_api.dart';
import '../../providers/auth_provider.dart';
import '../../services/subscription_plan_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../auth/login_screen.dart';
import '../campaigns/campaigns_screen.dart';
import '../plans/plans_screen.dart';
import '../profile/profile_hub_screen.dart';
import '../rewards/rewards_deals_screen.dart';
import '../stores/store_profile_screen.dart';

// ─── Guest Home ──────────────────────────────────────────────────

class GuestHomeScreen extends StatefulWidget {
  final String cityName;
  const GuestHomeScreen({super.key, required this.cityName});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
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

// ─── Logged-in Home ──────────────────────────────────────────────

class LoggedInHomeScreen extends StatefulWidget {
  final String cityName;
  const LoggedInHomeScreen({super.key, required this.cityName});

  @override
  State<LoggedInHomeScreen> createState() => _LoggedInHomeScreenState();
}

class _LoggedInHomeScreenState extends State<LoggedInHomeScreen> {
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

// ─── All Stores Screen ───────────────────────────────────────────

class AllStoresScreen extends StatefulWidget {
  final String cityName;
  const AllStoresScreen({super.key, required this.cityName});

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen> {
  final _api = KutootApi();
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _categories = [];
  int _activeCategory = 0;
  bool _loading = true;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getStoreCategories().catchError((_) => null),
        _api.getStores(params: {'per_page': 50}).catchError((_) => null),
      ]);
      final cats = _extractList(results[0]?.data);
      final stores = _extractList(results[1]?.data);
      if (mounted) {
        setState(() {
          _categories = [
            {'id': 0, 'name': 'ALL'},
            ...cats.map(_toMap),
          ];
          _stores = stores.map(_toMap).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search(String query) async {
    _searchDebounce?.cancel();
    _searchQuery = query;
    if (query.isEmpty) {
      _loadData();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final catId = _activeCategory > 0
            ? _categories[_activeCategory]['id']
            : null;
        final params = <String, dynamic>{
          'search': query,
          'per_page': 50,
        };
        if (catId != null && catId != 0) params['category_id'] = catId;
        final res = await _api.getStores(params: params);
        final stores = _extractList(res.data);
        if (mounted) {
          setState(() {
            _stores = stores.map(_toMap).toList();
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  void _filterByCategory(int idx) {
    setState(() => _activeCategory = idx);
    if (_searchQuery.isNotEmpty) {
      _search(_searchQuery);
      return;
    }
    if (idx == 0) {
      _loadData();
      return;
    }
    final catId = _categories[idx]['id'];
    setState(() => _loading = true);
    _api
        .getStores(params: {'category_id': catId, 'per_page': 50})
        .then((res) {
      if (mounted) {
        setState(() {
          _stores = _extractList(res.data).map(_toMap).toList();
          _loading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

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
              rightLabel: 'UPGRADE',
              onRightTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlansScreen(cityName: widget.cityName),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  _InteractiveSearchBar(
                    hint: 'Search stores, brands, or items...',
                    onChanged: _search,
                  ),
                  const SizedBox(height: 10),
                  if (_categories.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            List.generate(_categories.length, (i) {
                          final selected = _activeCategory == i;
                          final name =
                              _categories[i]['name']?.toString() ?? 'ALL';
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _filterByCategory(i),
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
                                  name.toUpperCase(),
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
                        '${_stores.length} STORES FOUND',
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
                  if (_loading)
                    _buildGridSkeletons()
                  else if (_stores.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No stores found',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
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
                      itemBuilder: (_, i) =>
                          _StoreCardLargeApi(store: _stores[i]),
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
        cityName: widget.cityName,
        isLoggedIn: true,
        planLabel: 'UPGRADE',
      ),
    );
  }

  Widget _buildGridSkeletons() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (_, __) => const _SkeletonBox(height: 250, borderRadius: 16),
      );
}

// ─── Home Body (API-connected) ───────────────────────────────────

class _HomeBody extends StatefulWidget {
  final String cityName;
  final bool isGuest;
  final VoidCallback onOpenLive;
  final VoidCallback onOpenAnnouncements;
  final VoidCallback onSeeAll;

  const _HomeBody({
    required this.cityName,
    required this.isGuest,
    required this.onOpenLive,
    required this.onOpenAnnouncements,
    required this.onSeeAll,
  });

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final _api = KutootApi();
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _searchResults = [];
  int _activeCategory = 0;
  bool _loading = true;
  bool _searching = false;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
      // Fire all requests in parallel for speed
      final results = await Future.wait([
        isLoggedIn
            ? _api.getBanners().catchError((_) => null)
            : Future.value(null),
        _api.getStoreCategories().catchError((_) => null),
        isLoggedIn
            ? _api.getStores(params: {'per_page': 10}).catchError((_) => null)
            : Future.value(null),
      ]);

      // Banners: {data: {featured: [], marketing: [], store: []}}
      List<Map<String, dynamic>> banners = [];
      if (results[0] != null) {
        final wrapper = results[0]?.data;
        if (wrapper is Map) {
          final data = wrapper['data'];
          if (data is Map) {
            for (final key in ['featured', 'marketing', 'store']) {
              final list = data[key];
              if (list is List) {
                banners.addAll(list
                    .whereType<Map>()
                    .map((m) => Map<String, dynamic>.from(m)));
              }
            }
          }
        }
      }

      // Categories
      List<dynamic> cats = _extractList(results[1]?.data);

      // Stores
      List<dynamic> stores = _extractList(results[2]?.data);

      if (mounted) {
        setState(() {
          _banners = banners;
          _categories = cats.map(_toMap).toList();
          _stores = stores.map(_toMap).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchQuery = query;
    if (query.isEmpty) {
      setState(() {
        _searching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || _searchQuery != query) return;
      try {
        final res = await _api
            .getStores(params: {'search': query, 'per_page': 15});
        final stores = _extractList(res.data);
        if (mounted && _searchQuery == query) {
          setState(() {
            _searchResults = stores.map(_toMap).toList();
            _searching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _onCategoryTap(int idx) {
    setState(() => _activeCategory = idx);
    if (idx == 0) {
      _loadAll();
      return;
    }
    final catId = _categories[idx - 1]['id']; // offset by 1 for ALL
    setState(() => _loading = true);
    _api
        .getStores(params: {'category_id': catId, 'per_page': 10})
        .then((res) {
      final stores = _extractList(res.data);
      if (mounted) {
        setState(() {
          _stores = stores.map(_toMap).toList();
          _loading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (n.contains('fashion') || n.contains('cloth')) return Icons.checkroom;
    if (n.contains('electronic') || n.contains('tech')) {
      return Icons.devices_other;
    }
    if (n.contains('home') || n.contains('furniture')) return Icons.chair;
    if (n.contains('beauty') || n.contains('salon') || n.contains('spa')) {
      return Icons.spa_rounded;
    }
    if (n.contains('coffee') || n.contains('cafe')) {
      return Icons.coffee_rounded;
    }
    if (n.contains('retail') || n.contains('shop')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.grid_view;
  }

  Color _categoryColor(int i) {
    const colors = [
      AppTheme.primary,
      AppTheme.secondary,
      Color(0xFF6C63FF),
      Color(0xFFF2DCE3),
      Color(0xFF2DBDB5),
      Color(0xFFF4A261),
    ];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults = _searchQuery.isNotEmpty;

    // ALL + API categories
    final allCategories = <Map<String, dynamic>>[
      {'id': 0, 'name': 'ALL'},
      ..._categories,
    ];

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        children: [
          _InteractiveSearchBar(
            hint: 'Search for brands or products...',
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),

          // ── Search results ──
          if (showSearchResults) ...[
            if (_searching)
              ..._buildSearchSkeletons()
            else if (_searchResults.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('No stores found',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              )
            else ...[
              Text(
                '${_searchResults.length} results',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ..._searchResults.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StoreListTile(store: s),
                  )),
            ],
          ] else ...[
            // ── Banner carousel ──
            if (_banners.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 170,
                  child: PageView.builder(
                    itemCount: _banners.length,
                    itemBuilder: (_, i) {
                      final b = _banners[i];
                      final imgUrl = ImageUtils.fromBanner(b);
                      final title = b['title']?.toString() ?? '';
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imgUrl != null && imgUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: imgUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                  color:
                                      AppTheme.primary.withOpacity(0.1)),
                              errorWidget: (_, __, ___) =>
                                  _bannerPlaceholder(title),
                            )
                          else
                            _bannerPlaceholder(title),
                          if (title.isNotEmpty)
                            Container(
                              alignment: Alignment.bottomLeft,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppTheme.primary.withOpacity(0.85),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              )
            else if (_loading)
              _SkeletonBox(height: 170, borderRadius: 22)
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 170,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text('Welcome to Kutoot!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20)),
                  ),
                ),
              ),

            const SizedBox(height: 18),

            // ── Categories ──
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
              child: _categories.isEmpty && _loading
                  ? _buildCategorySkeletons()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allCategories.length,
                      itemBuilder: (_, i) {
                        final selected = _activeCategory == i;
                        final name =
                            allCategories[i]['name']?.toString() ?? 'ALL';
                        return Padding(
                          padding: EdgeInsets.only(
                              right: i == allCategories.length - 1
                                  ? 0
                                  : 12),
                          child: _CategoryBubble(
                            label: name.toUpperCase(),
                            selected: selected,
                            onTap: () => _onCategoryTap(i),
                            color: _categoryColor(i),
                            icon: _categoryIcon(name),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // ── Campaign entry cards ──
            Row(
              children: [
                Expanded(
                  child: _FlowEntryCard(
                    title: 'LIVE',
                    subtitle: 'Campaigns',
                    icon: Icons.bolt_rounded,
                    onTap: widget.onOpenLive,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FlowEntryCard(
                    title: 'ANNOUNCED',
                    subtitle: 'Campaigns',
                    icon: Icons.campaign_rounded,
                    onTap: widget.onOpenAnnouncements,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Stores Nearby ──
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
                  onPressed: widget.onSeeAll,
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
              child: _loading && _stores.isEmpty
                  ? _buildStoreSkeletons()
                  : _stores.isEmpty
                      ? const Center(
                          child: Text('No stores found',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _stores.length,
                          itemBuilder: (_, i) => Padding(
                            padding: EdgeInsets.only(
                                right:
                                    i == _stores.length - 1 ? 0 : 12),
                            child: _StoreCardCompactApi(
                                store: _stores[i]),
                          ),
                        ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bannerPlaceholder(String title) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withOpacity(0.6),
              AppTheme.primary,
            ],
          ),
        ),
        child: Center(
          child: Text(
            title.isNotEmpty ? title : 'Kutoot',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20),
          ),
        ),
      );

  List<Widget> _buildSearchSkeletons() => List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _SkeletonBox(height: 76, borderRadius: 16),
        ),
      );

  Widget _buildCategorySkeletons() => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Column(
            children: [
              _SkeletonBox(width: 62, height: 62, borderRadius: 18),
              SizedBox(height: 8),
              _SkeletonBox(width: 50, height: 10, borderRadius: 5),
            ],
          ),
        ),
      );

  Widget _buildStoreSkeletons() => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(right: 12),
          child: _SkeletonBox(width: 155, height: 220, borderRadius: 18),
        ),
      );
}

// ─── Skeleton Shimmer Widget ─────────────────────────────────────

class _SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  const _SkeletonBox({
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFEEECEC),
                Color(0xFFF5F3F3),
                Color(0xFFEEECEC),
              ],
              stops: [
                (_ctrl.value - 0.3).clamp(0.0, 1.0),
                _ctrl.value,
                (_ctrl.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────

List<dynamic> _extractList(dynamic data) {
  if (data is Map) {
    final d = data['data'];
    if (d is List) return d;
    if (d is Map && d['data'] is List) return d['data'] as List;
  }
  if (data is List) return data;
  return [];
}

Map<String, dynamic> _toMap(dynamic item) {
  if (item is Map<String, dynamic>) return item;
  if (item is Map) return Map<String, dynamic>.from(item);
  return {};
}

String _storeName(Map<String, dynamic> s) {
  return s['store_name']?.toString() ??
      s['branch_name']?.toString() ??
      (s['merchant'] is Map
          ? (s['merchant'] as Map)['name']?.toString()
          : null) ??
      s['name']?.toString() ??
      'Store';
}

String _storeCategory(Map<String, dynamic> s) {
  final cat = s['merchant_category'] ?? s['category'];
  if (cat is Map) return cat['name']?.toString() ?? '';
  return s['category']?.toString() ?? '';
}

String _storeRating(Map<String, dynamic> s) {
  final r = s['star_rating'] ?? s['rating'];
  if (r is num) return r.toStringAsFixed(1);
  if (r is String) return r;
  return '4.5';
}

String? _storeImage(Map<String, dynamic> s) {
  return ImageUtils.fromStore(s);
}

// ─── UI Components ───────────────────────────────────────────────

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
    );
  }
}

class _InteractiveSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _InteractiveSearchBar(
      {required this.hint, required this.onChanged});

  @override
  State<_InteractiveSearchBar> createState() =>
      _InteractiveSearchBarState();
}

class _InteractiveSearchBarState extends State<_InteractiveSearchBar> {
  final _controller = TextEditingController();
  bool _focused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      onFocusChange: (focused) {
        setState(() => _focused = focused);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _focused
              ? theme.colorScheme.surfaceContainerLowest
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focused
                ? theme.colorScheme.primary.withOpacity(0.25)
                : theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: _focused
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (v) {
                  widget.onChanged(v);
                  setState(() {});
                },
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
                child: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
          ],
        ),
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
  final IconData icon;

  const _CategoryBubble({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon = Icons.grid_view,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        color.computeLuminance() > 0.5 ? AppTheme.primary : Colors.white;
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
            child: Icon(icon, color: iconColor, size: 28),
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

class _StoreCardCompactApi extends StatelessWidget {
  final Map<String, dynamic> store;
  const _StoreCardCompactApi({required this.store});

  @override
  Widget build(BuildContext context) {
    final name = _storeName(store);
    final rating = _storeRating(store);
    final imgUrl = _storeImage(store);
    final category = _storeCategory(store);
    final badge = store['badge']?.toString() ?? category;

    return SizedBox(
      width: 155,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreProfileScreen(store: store),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imgUrl != null && imgUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imgUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      color: AppTheme.primary.withOpacity(0.1)),
                  errorWidget: (_, __, ___) =>
                      _storePlaceholder(name),
                )
              else
                _storePlaceholder(name),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.88),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              if (badge.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badge.length > 15
                          ? badge.substring(0, 15)
                          : badge,
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
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 13,
                            color: AppTheme.tertiaryContainer),
                        Text(
                          ' $rating',
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

  static Widget _storePlaceholder(String name) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withOpacity(0.3),
              AppTheme.primary.withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: Icon(Icons.store_rounded,
              color: Colors.white.withOpacity(0.7), size: 40),
        ),
      );
}

class _StoreCardLargeApi extends StatelessWidget {
  final Map<String, dynamic> store;
  const _StoreCardLargeApi({required this.store});

  @override
  Widget build(BuildContext context) {
    final name = _storeName(store);
    final rating = _storeRating(store);
    final imgUrl = _storeImage(store);
    final badge = _storeCategory(store);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreProfileScreen(store: store),
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
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imgUrl != null && imgUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppTheme.primary.withOpacity(0.08)),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.primary.withOpacity(0.08),
                          child: const Icon(Icons.store_rounded,
                              size: 40, color: AppTheme.primary),
                        ),
                      )
                    else
                      Container(
                        color: AppTheme.primary.withOpacity(0.08),
                        child: const Icon(Icons.store_rounded,
                            size: 40, color: AppTheme.primary),
                      ),
                    if (badge.isNotEmpty)
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
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                color: AppTheme.tertiaryContainer,
                                size: 13),
                            Text(
                              ' $rating',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11),
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
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '📍 ${store['address'] ?? 'Nearby'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

class _StoreListTile extends StatelessWidget {
  final Map<String, dynamic> store;
  const _StoreListTile({required this.store});

  @override
  Widget build(BuildContext context) {
    final name = _storeName(store);
    final rating = _storeRating(store);
    final imgUrl = _storeImage(store);
    final category = _storeCategory(store);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StoreProfileScreen(store: store)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: imgUrl != null && imgUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppTheme.primary.withOpacity(0.1)),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.store_rounded,
                              color: AppTheme.primary),
                        ),
                      )
                    : Container(
                        color: AppTheme.primary.withOpacity(0.1),
                        child: const Icon(Icons.store_rounded,
                            color: AppTheme.primary),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  if (category.isNotEmpty)
                    Text(category,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star,
                    size: 14, color: AppTheme.tertiaryContainer),
                const SizedBox(width: 2),
                Text(rating,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey),
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
      child:
          const Icon(Icons.qr_code_scanner, color: Colors.white, size: 27),
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
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      height: 68 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.05)),
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
                            builder: (_) =>
                                PlansScreen(cityName: cityName),
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
                        builder: (_) =>
                            PlansScreen(cityName: cityName),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
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
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                  }
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[i],
                    color: active
                        ? AppTheme.primary
                        : const Color(0xFF9A9A9A),
                    size: 25,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.w900 : FontWeight.w700,
                      color: active
                          ? AppTheme.primary
                          : const Color(0xFF9A9A9A),
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
