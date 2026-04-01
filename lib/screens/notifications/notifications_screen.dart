import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Notifications',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'System'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotificationList(items: _personalNotifications),
          _NotificationList(items: _systemNotifications),
        ],
      ),
    );
  }

  static final _personalNotifications = [
    _NotificationItem(
      icon: Icons.star_rounded,
      title: 'You earned 5 stamps!',
      body: 'Great progress at The Coffee Artisan. Keep it up!',
      time: '2 min ago',
    ),
    _NotificationItem(
      icon: Icons.local_offer_rounded,
      title: 'New coupon available',
      body: '20% off your next purchase at Burger King',
      time: '1 hour ago',
    ),
    _NotificationItem(
      icon: Icons.card_giftcard_rounded,
      title: 'Campaign reward unlocked',
      body: 'You\'ve completed the stamp program. Claim your reward!',
      time: 'Yesterday',
    ),
  ];

  static final _systemNotifications = [
    _NotificationItem(
      icon: Icons.info_outline_rounded,
      title: 'App update available',
      body: 'Version 1.1.0 is ready with new features',
      time: '3 hours ago',
    ),
    _NotificationItem(
      icon: Icons.verified_user_rounded,
      title: 'Security reminder',
      body: 'Your account is secure. No action needed.',
      time: '1 day ago',
    ),
  ];
}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String body;
  final String time;

  _NotificationItem(
      {required this.icon,
      required this.title,
      required this.body,
      required this.time});
}

class _NotificationList extends StatelessWidget {
  final List<_NotificationItem> items;

  const _NotificationList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No notifications'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
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
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: AppTheme.primary),
            ),
            title: Text(item.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item.body,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text(item.time,
                    style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.8),
                        fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
