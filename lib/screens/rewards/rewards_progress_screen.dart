import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RewardsProgressScreen extends StatelessWidget {
  const RewardsProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandName = 'Robert Rewards';
    const earned = 3;
    const total = 5;

    final activities = [
      ('The Daily Grind', 'Oct 26', '+2 stars'),
      ('Boulangerie Patisserie', 'Oct 25', '+12 stars'),
      ('The Coffee Artisan', 'Oct 24', '+3 stars'),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Rewards Progress', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$brandName Progress', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(total, (i) => Icon(
                      i < earned ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 40,
                      color: i < earned ? AppTheme.primary : Colors.grey.shade300,
                    )),
                  ),
                  const SizedBox(height: 12),
                  Text('$earned / $total stars', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('How to Earn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Make purchases at participating stores'),
                  SizedBox(height: 8),
                  Text('• Earn 1 star for every ₹100 spent'),
                  SizedBox(height: 8),
                  Text('• Complete 5 stars to unlock a free reward'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...activities.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  Icon(Icons.store_rounded, color: AppTheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(a.$2, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(a.$3, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
