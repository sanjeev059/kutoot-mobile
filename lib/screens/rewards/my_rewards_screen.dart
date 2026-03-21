import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'reward_details_screen.dart';
import 'redemption_success_screen.dart';

class MyRewardsScreen extends StatefulWidget {
  const MyRewardsScreen({super.key});

  @override
  State<MyRewardsScreen> createState() => _MyRewardsScreenState();
}

class _MyRewardsScreenState extends State<MyRewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _activeRewards = [
    {'name': 'Signature Roast Latte', 'points': 250, 'provider': 'Robert Premium Roasters', 'code': 'KUT-001'},
    {'name': '20% Off', 'points': 100, 'provider': 'Urban Threads', 'code': 'KUT-002'},
  ];

  final _redeemedRewards = [
    {'name': 'Artisan Pastry', 'provider': 'The Coffee Artisan', 'used': 'Oct 20, 2024'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Rewards', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Redeemed')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveRewardsList(rewards: _activeRewards),
          _RedeemedRewardsList(rewards: _redeemedRewards),
        ],
      ),
    );
  }
}

class _ActiveRewardsList extends StatelessWidget {
  final List<Map<String, dynamic>> rewards;

  const _ActiveRewardsList({required this.rewards});

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const Center(child: Text('No active rewards'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: rewards.length,
      itemBuilder: (context, i) {
        final r = rewards[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded, color: AppTheme.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(r['provider'] ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RedemptionSuccessScreen(reward: r))),
                  child: const Text('Redeem'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RedeemedRewardsList extends StatelessWidget {
  final List<Map<String, dynamic>> rewards;

  const _RedeemedRewardsList({required this.rewards});

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const Center(child: Text('No redeemed rewards yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: rewards.length,
      itemBuilder: (context, i) {
        final r = rewards[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.grey),
            ),
            title: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Used ${r['used'] ?? ''}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: const Text('Used', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }
}
