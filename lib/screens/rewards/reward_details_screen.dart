import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import 'redemption_success_screen.dart';

class RewardDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> reward;

  const RewardDetailsScreen({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    final name = reward['name'] ?? reward['reward_name'] ?? 'Reward';
    final imageUrl = ImageUtils.fromMap(
        reward is Map ? Map<String, dynamic>.from(reward) : null);
    final points = reward['points'] ?? 250;
    final provider = reward['provider'] ?? 'Partner';
    final description = reward['description'] ??
        'Enjoy this exclusive reward. Valid at participating locations.';
    final notes = reward['notes'] ??
        [
          'One redemption per customer',
          'Valid for 30 days',
          'Cannot be combined with other offers'
        ];
    final instructions = [
      'Visit a participating store',
      'Show your reward code at checkout',
      'Enjoy your reward!',
    ];

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
              background: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: AppTheme.primary.withOpacity(0.5),
                          child: const Center(
                              child: Icon(Icons.card_giftcard_rounded,
                                  size: 80, color: Colors.white54))),
                      errorWidget: (_, __, ___) => Container(
                          color: AppTheme.primary.withOpacity(0.5),
                          child: const Center(
                              child: Icon(Icons.card_giftcard_rounded,
                                  size: 80, color: Colors.white54))),
                    )
                  : Container(
                      color: AppTheme.primary.withOpacity(0.5),
                      child: const Center(
                          child: Icon(Icons.card_giftcard_rounded,
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
                  Text(name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(provider,
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('$points Stars',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Expires in 30 days',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(description,
                      style: const TextStyle(
                          height: 1.5, color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),
                  const Text('Notes & Conditions',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(notes is List ? notes as List : [notes.toString()])
                      .map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)),
                                Expanded(
                                    child: Text(n.toString(),
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14))),
                              ],
                            ),
                          )),
                  const SizedBox(height: 20),
                  const Text('How to Redeem',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...instructions.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle),
                              child: Center(
                                  child: Text('${e.key + 1}',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(e.value,
                                    style: const TextStyle(height: 1.4))),
                          ],
                        ),
                      )),
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
                    onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                RedemptionSuccessScreen(reward: reward))),
                    child: const Text('Redeem Reward'),
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
