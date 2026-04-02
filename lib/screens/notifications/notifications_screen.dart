import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = KutootApi();
  List<dynamic> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getNotifications().then<dynamic>((r) => r).catchError((_) => null),
        _api.getUnreadNotificationCount().then<dynamic>((r) => r).catchError((_) => null),
      ]);
      if (mounted) {
        if (results[0] != null && results[0]!.data is Map) {
          final d = (results[0]!.data as Map)['data'];
          _notifications = d is List ? d : [];
        }
        if (results[1] != null && results[1]!.data is Map) {
          final d = (results[1]!.data as Map)['data'];
          _unreadCount = d is Map ? (d['count'] ?? d['unread_count'] ?? 0) : (d is int ? d : 0);
        }
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(dynamic id) async {
    try {
      final nid = id is int ? id : int.tryParse(id.toString()) ?? 0;
      await _api.markNotificationRead(nid);
      _load();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      _load();
    } catch (_) {}
  }

  List<dynamic> get _personalNotifications =>
      _notifications.where((n) {
        final type = (n is Map ? n['type'] ?? '' : '').toString().toLowerCase();
        return type != 'system';
      }).toList();

  List<dynamic> get _systemNotifications =>
      _notifications.where((n) {
        final type = (n is Map ? n['type'] ?? '' : '').toString().toLowerCase();
        return type == 'system';
      }).toList();

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
        title: Row(
          children: [
            const Text('Notifications', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        foregroundColor: AppTheme.textPrimary,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
            ),
        ],
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NotificationList(items: _personalNotifications, onTap: _markRead),
                  _NotificationList(items: _systemNotifications, onTap: _markRead),
                ],
              ),
            ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<dynamic> items;
  final void Function(dynamic id) onTap;

  const _NotificationList({required this.items, required this.onTap});

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'promo': return Icons.local_offer_rounded;
      case 'system': return Icons.info_outline_rounded;
      case 'reward': return Icons.card_giftcard_rounded;
      default: return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No notifications'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i] is Map ? items[i] as Map : {};
        final title = item['title'] ?? '';
        final body = item['body'] ?? item['message'] ?? '';
        final type = (item['type'] ?? '').toString();
        final time = item['created_at'] ?? '';
        final isRead = item['read_at'] != null;
        return GestureDetector(
          onTap: () => onTap(item['id']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isRead ? Colors.white : AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
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
                child: Icon(_iconForType(type), color: AppTheme.primary),
              ),
              title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(time, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
