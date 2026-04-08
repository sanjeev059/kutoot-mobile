import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../api/kutoot_api.dart';
import '../../utils/image_utils.dart';
import '../../providers/auth_provider.dart';
import '../qr/qr_scan_screen.dart';
import '../campaigns/campaigns_screen.dart';
import '../campaigns/campaign_detail_screen.dart';
import '../stores/store_profile_screen.dart';
import '../stamps/stamps_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _api = KutootApi();
  List<dynamic> _banners = [];
  List<dynamic> _campaigns = [];
  List<dynamic> _categories = [];
  List<dynamic> _merchants = [];
  int _stampProgress = 0;
  int _stampTotal = 10;
  String? _stampCampaignName;
  bool _loading = true;
  bool _hasLoadedOnce = false;
  int _selectedCategoryIndex = 0;
  bool _loadingMerchants = false;
  final TextEditingController _searchCtrl = TextEditingController();

  static const _fallbackCategories = [
    ('Food', Icons.restaurant_rounded),
    ('Fashion', Icons.checkroom_rounded),
    ('Coffee', Icons.coffee_rounded),
    ('Retail', Icons.shopping_bag_rounded),
    ('Beauty', Icons.spa_rounded),
    ('More', Icons.grid_view_rounded),
  ];

  static const _fallbackMerchants = [
    ('The Coffee Bean', 4.7, '0.3 km', '1 per ₹200', 'Coffee'),
    ('Urban Grill', 4.5, '0.8 km', '1 per ₹500', 'Restaurant'),
    ('Urban Threads', 4.8, '1.2 km', '1 per ₹1000', 'Fashion'),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> get _merchantsForDisplay {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _merchants;
    return _merchants.where((m) {
      final map = m is Map ? m : {};
      final merchant = map['merchant'] is Map ? map['merchant'] as Map : {};
      final hay =
          '${map['branch_name'] ?? ''} ${merchant['name'] ?? ''}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  List<dynamic> get _campaignSearchHits {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.length < 2) return [];
    return _campaigns.where((c) {
      final map = c is Map ? c : {};
      final name =
          '${map['reward_name'] ?? map['name'] ?? ''}'.toLowerCase();
      return name.contains(q);
    }).take(6).toList();
  }

  static IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('restaurant'))
      return Icons.restaurant_rounded;
    if (n.contains('fashion') || n.contains('cloth'))
      return Icons.checkroom_rounded;
    if (n.contains('coffee') || n.contains('cafe')) return Icons.coffee_rounded;
    if (n.contains('retail') || n.contains('shop'))
      return Icons.shopping_bag_rounded;
    if (n.contains('beauty') || n.contains('salon') || n.contains('spa'))
      return Icons.spa_rounded;
    return Icons.grid_view_rounded;
  }

  Future<void> _fetchMerchantsForCategoryIndex(int index) async {
    if (!mounted) return;
    setState(() {
      _selectedCategoryIndex = index;
      _loadingMerchants = true;
    });
    List<dynamic> merchants = [];
    try {
      if (_categories.isEmpty) {
        if (mounted) {
          setState(() {
            _merchants = [];
            _loadingMerchants = false;
          });
        }
        return;
      }
      final safe = index.clamp(0, _categories.length - 1);
      final cat = _categories[safe];
      final catId = cat is Map
          ? (cat['id'] is int
              ? cat['id'] as int
              : int.tryParse(cat['id']?.toString() ?? ''))
          : null;
      if (catId != null) {
        final storesRes =
            await _api.getStoresByCategory(catId, params: {'per_page': 10});
        if (storesRes.data is Map &&
            (storesRes.data as Map)['data'] != null) {
          merchants = (storesRes.data as Map)['data'] is List
              ? (storesRes.data as Map)['data'] as List
              : [];
        }
      } else if (_categories.isEmpty) {
        final storesRes =
            await _api.getStores(params: {'per_page': 15});
        if (storesRes.data is Map &&
            (storesRes.data as Map)['data'] != null) {
          merchants = (storesRes.data as Map)['data'] is List
              ? (storesRes.data as Map)['data'] as List
              : [];
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _merchants = merchants;
      _loadingMerchants = false;
    });
  }

  List<Widget> _buildTopFilterChips() {
    if (_categories.isEmpty) {
      return _fallbackCategories.asMap().entries.map((e) {
        final i = e.key;
        final c = e.value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            avatar: Icon(c.$2, size: 20, color: AppTheme.primary),
            label: Text(c.$1),
            selected: _selectedCategoryIndex == i,
            onSelected: (sel) {
              if (sel) _fetchMerchantsForCategoryIndex(i);
            },
            selectedColor: AppTheme.primary.withOpacity(0.15),
            backgroundColor: AppTheme.background,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          ),
        );
      }).toList();
    }
    return _categories.asMap().entries.map((e) {
      final i = e.key;
      final c = e.value is Map ? e.value as Map : {};
      final imgUrl = ImageUtils.fromCategory(c);
      final name = c['name']?.toString() ?? 'More';
      final icon = _categoryIcon(name);
      final avatar = imgUrl != null && imgUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: imgUrl,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Icon(icon, size: 20, color: AppTheme.primary),
                errorWidget: (_, __, ___) =>
                    Icon(icon, size: 20, color: AppTheme.primary),
              ),
            )
          : Icon(icon, size: 20, color: AppTheme.primary);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          avatar: avatar,
          label: Text(name),
          selected: _selectedCategoryIndex == i,
          onSelected: (sel) {
            if (sel) _fetchMerchantsForCategoryIndex(i);
          },
          selectedColor: AppTheme.primary.withOpacity(0.15),
          backgroundColor: AppTheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
      );
    }).toList();
  }

  Widget _buildCategoryMerchantsPreview(BuildContext context) {
    if (_loadingMerchants) {
      return ListView(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _shimmerStoreCard(),
          ),
        ),
      );
    }
    if (_categories.isEmpty) {
      return ListView(
        children: _fallbackMerchants
            .map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StoreListCard(
                  name: m.$1,
                  rating: m.$2,
                  distance: m.$3,
                  stamps: m.$4,
                  imageUrl: null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreProfileScreen(
                        store: {'name': m.$1, 'category': m.$5},
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    }
    final list = _merchantsForDisplay;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No stores in this category yet',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final m = list[i];
        final map = m is Map ? m : {};
        final name = map['branch_name'] ??
            map['merchant']?['name'] ??
            'Store';
        final merchant = map['merchant'] is Map ? map['merchant'] as Map : {};
        final category = merchant['name'] ?? 'Store';
        final rating = (map['star_rating'] ?? 4.5) is num
            ? (map['star_rating'] as num).toDouble()
            : 4.5;
        final imgUrl = ImageUtils.fromStore(map);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _StoreListCard(
            name: name is String ? name : name.toString(),
            rating: rating,
            distance: 'Nearby',
            stamps: 'Earn stamps',
            imageUrl: imgUrl?.isNotEmpty == true ? imgUrl : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreProfileScreen(store: {
                  'name': name,
                  'category': category,
                  'store': map,
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        _api.getFeaturedBanners().catchError((_) => null),
        _api.getMarketingBanners().catchError((_) => null),
        _api.getStoreBanners().catchError((_) => null),
        _api.getCampaigns(params: {'per_page': 8}).catchError((_) => null),
        _api.getStoreCategories().catchError((_) => null),
        auth.isLoggedIn
            ? _api.getDashboard().catchError((_) => null)
            : Future.value(null),
      ]);

      List<dynamic> banners = [];
      for (int i = 0; i < 3 && banners.isEmpty; i++) {
        if (results[i] != null && results[i]?.data is Map) {
          final d = (results[i]!.data as Map)['data'];
          banners = d is List ? d : [];
        }
      }

      List<dynamic> campaigns = [];
      if (results[3] != null && results[3]?.data is Map) {
        final d = (results[3]!.data as Map)['data'];
        campaigns = d is List ? d : [];
      }

      List<dynamic> categories = [];
      if (results[4] != null && results[4]?.data is Map) {
        final d = (results[4]!.data as Map)['data'];
        categories = d is List ? d : [];
      } else if (results[4] != null && results[4]?.data is List) {
        categories = results[4]!.data as List;
      }

      int stampProgress = 0;
      int stampTotal = 10;
      String? stampCampaignName;
      if (results[5] != null && results[5]?.data is Map) {
        final data = (results[5]!.data as Map)['data'];
        if (data is Map) {
          final stats = data['stats'];
          final primary = data['primary_campaign'];
          stampProgress = (stats is Map && stats['stamps_count'] != null)
              ? (stats['stamps_count'] is int
                  ? stats['stamps_count']
                  : int.tryParse(stats['stamps_count'].toString()) ?? 0)
              : 0;
          if (primary is Map && primary['id'] != null) {
            stampCampaignName = primary['reward_name']?.toString();
            try {
              final campRes = await _api.getCampaign(primary['id'] is int
                  ? primary['id']
                  : int.tryParse(primary['id'].toString()) ?? 0);
              if (campRes.data is Map && (campRes.data as Map)['data'] is Map) {
                final camp = (campRes.data as Map)['data'] as Map;
                final stDyn =
                    camp['stamp_target'] ?? camp['stamp_slots'] ?? 10;
                stampTotal = stDyn is int
                    ? stDyn
                    : (int.tryParse(stDyn.toString()) ?? 10);
              }
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        setState(() {
          _banners = banners;
          _campaigns = campaigns;
          _categories = categories;
          _stampProgress = stampProgress;
          _stampTotal = stampTotal > 0 ? stampTotal : 10;
          _stampCampaignName = stampCampaignName;
          _loading = false;
          _hasLoadedOnce = true;
        });
        await _fetchMerchantsForCategoryIndex(0);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search stores, deals, or campaigns',
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    if (_searchCtrl.text.trim().length >= 2) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Matching campaigns',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: _campaignSearchHits.isEmpty
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'No campaign name matches',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _campaignSearchHits.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, i) {
                                  final c = _campaignSearchHits[i];
                                  final map = c is Map ? c : {};
                                  final id = map['id'] is int
                                      ? map['id'] as int
                                      : int.tryParse(
                                          '${map['id']}',
                                        );
                                  final label =
                                      map['reward_name']?.toString() ??
                                          map['name']?.toString() ??
                                          'Campaign';
                                  return ActionChip(
                                    label: Text(label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    onPressed: id == null
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CampaignDetailScreen(
                                                        campaignId: id),
                                              ),
                                            );
                                          },
                                  );
                                },
                              ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _buildTopFilterChips(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Stores in this category',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: _buildCategoryMerchantsPreview(context),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading && _banners.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 170,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    children: List.generate(2, (_) => _shimmerBanner()),
                  ),
                ),
              )
            else if (_banners.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _banners.length,
                    itemBuilder: (context, i) {
                      final b = _banners[i] is Map ? _banners[i] as Map : {};
                      var url = ImageUtils.fromBanner(b);
                      if ((url == null || url.isEmpty) && b['store'] != null)
                        url = ImageUtils.fromStore(b['store']);
                      return Container(
                        width: 320,
                        margin: const EdgeInsets.only(right: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: url != null && url.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _shimmerBanner(),
                                  errorWidget: (_, __, ___) =>
                                      _bannerPlaceholder(),
                                )
                              : _bannerPlaceholder(),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  height: 180,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary,
                        AppTheme.primaryDark,
                        Color(0xFFD94A1F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 10)),
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(Icons.auto_awesome,
                              size: 120,
                              color: Colors.white.withOpacity(0.15))),
                      Positioned(
                          left: -30,
                          bottom: -30,
                          child: Icon(Icons.loyalty_rounded,
                              size: 100, color: Colors.white.withOpacity(0.1))),
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.campaign_rounded,
                                size: 56, color: Colors.white),
                            SizedBox(height: 10),
                            Text('Featured Campaigns',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Pull to refresh for latest offers',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary.withOpacity(0.08),
                      AppTheme.primary.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.15), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _QuickAction(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Scan',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const QrScanScreen()))),
                    _QuickAction(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Rewards',
                        onTap: () {}),
                    _QuickAction(
                      icon: Icons.store_rounded,
                      label: 'Stores',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CampaignsScreen(
                            cityName: 'MUMBAI',
                            initialTabIndex: 0,
                          ),
                        ),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.campaign_rounded,
                      label: 'Deals',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CampaignsScreen(
                            cityName: 'MUMBAI',
                            initialTabIndex: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.isEmpty
                      ? _fallbackCategories
                          .asMap()
                          .entries
                          .map(
                            (e) => _CategoryChip(
                              icon: e.value.$2,
                              label: e.value.$1,
                              selected: _selectedCategoryIndex == e.key,
                              onSelected: () =>
                                  setState(() => _selectedCategoryIndex = e.key),
                            ),
                          )
                          .toList()
                      : _categories.asMap().entries.map((e) {
                          final i = e.key;
                          final m = e.value is Map ? e.value as Map : {};
                          return _CategoryChip(
                            icon:
                                _categoryIcon(m['name']?.toString() ?? ''),
                            label: m['name']?.toString() ?? 'More',
                            selected: _selectedCategoryIndex == i,
                            onSelected: () =>
                                _fetchMerchantsForCategoryIndex(i),
                          );
                        }).toList(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Top Deals Near You',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CampaignsScreen(
                                cityName: 'MUMBAI',
                                initialTabIndex: 0,
                              ),
                            ),
                          ),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: _loading && _campaigns.isEmpty
                          ? ListView(
                              scrollDirection: Axis.horizontal,
                              children: List.generate(3, (_) => _shimmerDeal()))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  _campaigns.isEmpty ? 3 : _campaigns.length,
                              itemBuilder: (context, i) {
                                if (_campaigns.isEmpty) {
                                  return _DealChip(
                                    name: 'Deal ${i + 1}',
                                    imageUrl: null,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CampaignsScreen(
                                          cityName: 'MUMBAI',
                                          initialTabIndex: 1,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final c = _campaigns[i] is Map
                                    ? _campaigns[i] as Map
                                    : {};
                                final id = c['id'];
                                final name =
                                    c['reward_name'] ?? c['name'] ?? 'Deal';
                                final imgUrl = ImageUtils.fromMap(
                                    Map<String, dynamic>.from(c));
                                return _DealChip(
                                  name: name,
                                  imageUrl: imgUrl != null && imgUrl.isNotEmpty
                                      ? imgUrl
                                      : null,
                                  onTap: id != null
                                      ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  CampaignDetailScreen(
                                                      campaignId: id is int
                                                          ? id
                                                          : int.tryParse(id
                                                                  .toString()) ??
                                                              0)))
                                      : () {},
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          final auth = context.read<AuthProvider>();
                          if (!auth.isLoggedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Log in to view your stamp collection'),
                              ),
                            );
                            return;
                          }
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const StampsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                AppTheme.primary.withOpacity(0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6)),
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color:
                                            AppTheme.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.loyalty_rounded,
                                        color: AppTheme.primary, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Stamp Program',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                        if (_stampCampaignName != null)
                                          Text(_stampCampaignName!,
                                              style: TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppTheme.textSecondary
                                        .withOpacity(0.7),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _stampTotal > 0
                                      ? (_stampProgress / _stampTotal)
                                          .clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 12,
                                  backgroundColor: AppTheme.background,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppTheme.primary),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                  '$_stampProgress / $_stampTotal stamps earned',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const QrScanScreen())),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
    );
  }

  Widget _bannerPlaceholder() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withOpacity(0.2),
              AppTheme.primary.withOpacity(0.08)
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign_rounded,
                  size: 56, color: AppTheme.primary.withOpacity(0.8)),
              const SizedBox(height: 8),
              Text('Campaign',
                  style: TextStyle(
                      color: AppTheme.primary.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _shimmerBanner() => Container(
        width: 320,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
          ],
        ),
        child: Shimmer.fromColors(
          baseColor: AppTheme.background,
          highlightColor: Colors.white,
          child: Container(color: Colors.white, height: 170),
        ),
      );

  Widget _shimmerDeal() => Container(
        width: 170,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
          ],
        ),
        child: Shimmer.fromColors(
          baseColor: AppTheme.background,
          highlightColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: 110,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)))),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _shimmerStoreCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
          ],
        ),
        child: Shimmer.fromColors(
          baseColor: AppTheme.background,
          highlightColor: Colors.white,
          child: Row(
            children: [
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 16, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _StoreListCard extends StatelessWidget {
  final String name;
  final double rating;
  final String distance;
  final String stamps;
  final String? imageUrl;
  final VoidCallback onTap;

  const _StoreListCard(
      {required this.name,
      required this.rating,
      required this.distance,
      required this.stamps,
      this.imageUrl,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primary.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _storeImagePlaceholder(),
                        errorWidget: (_, __, ___) => _storeImagePlaceholder(),
                      )
                    : _storeImagePlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: Colors.amber.shade700),
                        Text(' ${rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(' • $distance',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(stamps,
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeImagePlaceholder() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withOpacity(0.2),
              AppTheme.primary.withOpacity(0.08)
            ],
          ),
        ),
        child:
            const Icon(Icons.store_rounded, color: AppTheme.primary, size: 36),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon, size: 20, color: AppTheme.primary),
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        if (v) onSelected();
      },
      selectedColor: AppTheme.primary.withOpacity(0.2),
    );
  }
}

class _DealChip extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  const _DealChip({required this.name, this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 170,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primary.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        width: 170,
                        height: 110,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _dealImagePlaceholder(170, 110),
                        errorWidget: (_, __, ___) =>
                            _dealImagePlaceholder(170, 110),
                      )
                    : _dealImagePlaceholder(170, 110),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dealImagePlaceholder(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withOpacity(0.2),
              AppTheme.primary.withOpacity(0.06)
            ],
          ),
        ),
        child: Center(
            child: Icon(Icons.local_offer_rounded,
                color: AppTheme.primary.withOpacity(0.8), size: 44)),
      );
}
