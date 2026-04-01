import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import 'reward_details_screen.dart';

class RedeemRewardsScreen extends StatefulWidget {
  const RedeemRewardsScreen({super.key});

  @override
  State<RedeemRewardsScreen> createState() => _RedeemRewardsScreenState();
}

class _RedeemRewardsScreenState extends State<RedeemRewardsScreen> {
  int _categoryIndex = 0;
  final _categories = ['All', 'Beverage', 'Food', 'Retail'];

  final _featuredRewards = [
    {
      'name': 'Signature Roast Latte',
      'points': 250,
      'provider': 'Robert Premium Roasters',
      'image': null
    },
    {
      'name': 'Artisan Pastry',
      'points': 150,
      'provider': 'The Coffee Artisan',
      'image': null
    },
  ];

  final _retailDiscounts = [
    {
      'name': '20% Off Next Purchase',
      'points': 100,
      'provider': 'Urban Threads'
    },
    {'name': 'Flat ₹500 Off', 'points': 300, 'provider': 'Elite Fashion Hub'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Redeem Rewards',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search rewards...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_categories[i]),
                    selected: _categoryIndex == i,
                    onSelected: (_) => setState(() => _categoryIndex = i),
                    selectedColor: AppTheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Featured Rewards',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._featuredRewards.map((r) => _RewardTile(
                  name: (r['name'] ?? '').toString(),
                  points: r['points'] is int
                      ? r['points'] as int
                      : int.tryParse(r['points']?.toString() ?? '0') ?? 0,
                  provider: (r['provider'] ?? '').toString(),
                  imageUrl: ImageUtils.fromMap(
                      r is Map ? Map<String, dynamic>.from(r) : null),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RewardDetailsScreen(reward: r))),
                )),
            const SizedBox(height: 24),
            const Text('Retail Discounts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._retailDiscounts.map((r) => _RewardTile(
                  name: (r['name'] ?? '').toString(),
                  points: r['points'] is int
                      ? r['points'] as int
                      : int.tryParse(r['points']?.toString() ?? '0') ?? 0,
                  provider: (r['provider'] ?? '').toString(),
                  imageUrl: ImageUtils.fromMap(
                      r is Map ? Map<String, dynamic>.from(r) : null),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RewardDetailsScreen(reward: r))),
                )),
          ],
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final String name;
  final int points;
  final String provider;
  final String? imageUrl;
  final VoidCallback onTap;

  const _RewardTile(
      {required this.name,
      required this.points,
      required this.provider,
      this.imageUrl,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      color: AppTheme.primary.withOpacity(0.15),
                      child: const Icon(Icons.card_giftcard_rounded,
                          color: AppTheme.primary, size: 28)),
                  errorWidget: (_, __, ___) => Container(
                      color: AppTheme.primary.withOpacity(0.15),
                      child: const Icon(Icons.card_giftcard_rounded,
                          color: AppTheme.primary, size: 28)),
                )
              : Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: AppTheme.primary, size: 28),
                ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(provider,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$points Stars',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const Text('Redeem',
                style: TextStyle(fontSize: 12, color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }
}
