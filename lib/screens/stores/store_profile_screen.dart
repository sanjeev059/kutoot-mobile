import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../brand/brand_loyalty_screen.dart';

class StoreProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? store;

  const StoreProfileScreen({super.key, this.store});

  @override
  Widget build(BuildContext context) {
    final name = store?['name'] ?? store?['branch_name'] ?? store?['store_name'] ?? 'Urban Threads';
    final merchant = store?['merchant'] is Map ? store!['merchant'] as Map : null;
    final category = store?['category'] ?? merchant?['name'] ?? 'Fashion & Apparel';
    final r = store?['star_rating'] ?? store?['rating'] ?? 4.8;
    final rating = r is num ? r.toDouble() : 4.8;
    final imageUrl = ImageUtils.fromStore(store);
    final stampRule = store?['stamp_rule'] ?? 'Get 1 stamp for every ₹1000 spent.';

    final deals = [
      ('20% OFF', 'On your first purchase'),
      ('FLAT ₹500', 'On orders above ₹2000'),
    ];

    final bankOffers = ['HDFC Bank', 'ICICI Bank'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _headerPlaceholder(),
                      errorWidget: (_, __, ___) => _headerPlaceholder(),
                    )
                  : _headerPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(category, style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 20, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text('$rating', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STAMP LOYALTY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(stampRule, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Deals & Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...deals.map((d) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(d.$2, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        ElevatedButton(onPressed: () {}, child: const Text('Use Offer')),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  const Text('Bank Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: bankOffers.length,
                      itemBuilder: (context, i) => Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_rounded, color: AppTheme.primary),
                            const SizedBox(height: 8),
                            Text(bankOffers[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BrandLoyaltyScreen(brand: {'name': name, 'about': 'Premium store offering great rewards.'}))),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('View Brand Loyalty'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showComingSoon(context),
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Navigate to Store'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerPlaceholder() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)]),
        ),
        child: const Center(child: Icon(Icons.store_rounded, size: 80, color: Colors.white38)),
      );

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }
}
