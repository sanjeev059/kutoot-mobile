import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../api/kutoot_api.dart';
import '../../utils/image_utils.dart';
import '../campaigns/campaigns_screen.dart';
import '../campaigns/campaign_detail_screen.dart';
import '../coupons/coupons_screen.dart';
import '../stores/stores_screen.dart';
import '../stores/store_profile_screen.dart';
import '../offers/offer_detail_screen.dart';
import '../brand/brand_loyalty_screen.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final _api = KutootApi();
  List<dynamic> _featured = [];
  List<dynamic> _stores = [];
  int _filterIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getFeaturedBanners().catchError((_) => null),
        _api.getMerchantLocations().catchError((_) => null),
      ]);
      if (mounted) {
        if (results[0] != null &&
            results[0].data is Map &&
            (results[0].data as Map)['data'] != null) {
          _featured = (results[0].data as Map)['data'] is List
              ? (results[0].data as Map)['data'] as List
              : [];
        }
        if (results[1] != null &&
            results[1].data is Map &&
            (results[1].data as Map)['data'] != null) {
          _stores = (results[1].data as Map)['data'] is List
              ? (results[1].data as Map)['data'] as List
              : [];
        }
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Widget> _buildNearbyStoreCards() {
    if (_stores.isEmpty) {
      return _placeholderStores
          .map((s) => _StoreDealCard(
                name: s.$1,
                category: s.$2,
                rating: s.$3,
                imageUrl: null,
                onViewDeal: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => StoreProfileScreen(
                            store: {'name': s.$1, 'category': s.$2}))),
              ))
          .toList();
    }
    return _stores.take(5).map((s) {
      final store = s is Map ? s : {};
      final merchant =
          store['merchant'] is Map ? store['merchant'] as Map : null;
      return _StoreDealCard(
        name: store['branch_name'] ??
            store['name'] ??
            store['store_name'] ??
            'Store',
        category: merchant?['name'] ?? 'Store',
        rating: () {
          final r = store['star_rating'] ?? 4.5;
          return r is num ? (r as num).toDouble() : 4.5;
        }(),
        imageUrl: ImageUtils.fromStore(store),
        onViewDeal: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => StoreProfileScreen(store: Map.from(store)))),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.store_rounded, color: AppTheme.primary, size: 28),
            const SizedBox(width: 8),
            const Text('Kutoot',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('Deals'),
                        selected: _filterIndex == 0,
                        onSelected: (_) => setState(() => _filterIndex = 0),
                        selectedColor: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Offers'),
                        selected: _filterIndex == 1,
                        onSelected: (_) => setState(() => _filterIndex = 1),
                        selectedColor: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Nearby'),
                        selected: _filterIndex == 2,
                        onSelected: (_) => setState(() => _filterIndex = 2),
                        selectedColor: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Featured Deals',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.primary))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _featured.isEmpty ? 2 : _featured.length,
                        itemBuilder: (context, i) {
                          if (_featured.isEmpty) {
                            return _FeaturedCard(
                              title: 'Deal ${i + 1}',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => CampaignsScreen(
                                            cityName: '',
                                            upgradeLabel: 'GO PRO',
                                            onUpgradeTap: () {},
                                          ))),
                            );
                          }
                          final f =
                              _featured[i] is Map ? _featured[i] as Map : {};
                          return _FeaturedCard(
                            title: f['title'] ?? f['name'] ?? 'Deal',
                            imageUrl: ImageUtils.fromBanner(f),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => CampaignsScreen(
                                          cityName: '',
                                          upgradeLabel: 'GO PRO',
                                          onUpgradeTap: () {},
                                        ))),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nearby Stores',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StoresScreen())),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ..._buildNearbyStoreCards(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static final _placeholderStores = [
    ('The Coffee Artisan', 'Coffee & Bakery', 4.9),
    ('Burger King', 'Fast Food', 4.5),
    ('Starbucks', 'Coffee', 4.7),
  ];
}

class _FeaturedCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;

  const _FeaturedCard(
      {required this.title, this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(),
                          errorWidget: (_, __, ___) => _placeholder()),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7)
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                    ],
                  )
                : Container(
                    color: AppTheme.primary.withOpacity(0.2),
                    child: Center(
                        child: Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: AppTheme.primary.withOpacity(0.2),
      child: Center(
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold))));
}

class _StoreDealCard extends StatelessWidget {
  final String name;
  final String category;
  final double rating;
  final String? imageUrl;
  final VoidCallback onViewDeal;

  const _StoreDealCard(
      {required this.name,
      required this.category,
      required this.rating,
      this.imageUrl,
      required this.onViewDeal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewDeal,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              width: 80,
                              height: 80,
                              color: AppTheme.primary.withOpacity(0.15),
                              child: const Icon(Icons.store_rounded,
                                  color: AppTheme.primary, size: 40)),
                          errorWidget: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: AppTheme.primary.withOpacity(0.15),
                              child: const Icon(Icons.store_rounded,
                                  color: AppTheme.primary, size: 40)),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.store_rounded,
                              color: AppTheme.primary, size: 40),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(category,
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text('$rating',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onViewDeal,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10)),
                  child: const Text('View Deal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
