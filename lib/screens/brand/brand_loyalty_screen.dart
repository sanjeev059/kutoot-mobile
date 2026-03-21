import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BrandLoyaltyScreen extends StatelessWidget {
  final Map<String, dynamic>? brand;

  const BrandLoyaltyScreen({super.key, this.brand});

  @override
  Widget build(BuildContext context) {
    final name = brand?['name'] ?? 'Elite Fashion Hub';
    final about = brand?['about'] ?? 'Premium fashion destination offering the latest trends in clothing, accessories, and lifestyle products.';
    final progress = brand?['progress'] ?? 4;
    final total = brand?['total'] ?? 10;

    final locations = [
      ('Downtown', '123 Main Street', true),
      ('Northside Mall', '456 Mall Drive', true),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Brand Loyalty', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About the Brand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(about, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('Follow Brand'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Brand Stamp Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(total, (i) => Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i < progress ? AppTheme.primary : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: i < progress ? const Icon(Icons.star_rounded, color: Colors.white, size: 16) : null,
                    )),
                  ),
                  const SizedBox(height: 12),
                  Text('$progress/$total STAMPS COLLECTED', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Store Locations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...locations.map((l) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: AppTheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(l.$2, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(l.$3 ? 'Open' : 'Closed', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
