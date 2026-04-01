import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OfferDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? offer;

  const OfferDetailScreen({super.key, this.offer});

  @override
  Widget build(BuildContext context) {
    final title =
        offer?['name'] ?? offer?['title'] ?? 'Artisan Latte + Pastry Combo';
    final price = offer?['price'] ?? 249;
    final originalPrice = offer?['original_price'] ?? 349;
    final stamps = offer?['stamps'] ?? 2;
    final description = offer?['description'] ??
        'Enjoy a delicious artisan latte paired with a fresh pastry. Perfect for your morning break or afternoon treat.';
    final terms = offer?['terms'] ??
        [
          'Valid at participating locations only',
          'One offer per customer',
          'Cannot be combined with other offers'
        ];
    final location = offer?['location'] ?? 'The Blue Bean';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.primary.withOpacity(0.3),
                child: const Center(
                    child: Icon(Icons.coffee_rounded,
                        size: 80, color: Colors.white54)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Get $stamps Stamps',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('₹$price',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary)),
                      const SizedBox(width: 12),
                      Text('₹$originalPrice',
                          style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(description,
                      style: const TextStyle(
                          height: 1.5, color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  const Text('Terms & Conditions',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(terms is List ? terms as List : [terms.toString()])
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)),
                                Expanded(
                                    child: Text(t.toString(),
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14))),
                              ],
                            ),
                          )),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(location,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deal claimed!'))),
                    child: const Text('Claim Deal'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
