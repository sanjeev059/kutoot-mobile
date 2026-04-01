import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';

class StampHistoryScreen extends StatefulWidget {
  const StampHistoryScreen({super.key});

  @override
  State<StampHistoryScreen> createState() => _StampHistoryScreenState();
}

class _StampHistoryScreenState extends State<StampHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _api = KutootApi();
  late TabController _tabController;
  List<dynamic> _stamps = [];
  int _totalBalance = 24;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getStamps();
      final data = res.data;
      if (data is Map && data['data'] != null) {
        _stamps = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        _stamps = data;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Stamp History',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Earned'),
            Tab(text: 'Redeemed'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.primary,
                AppTheme.primary.withOpacity(0.8)
              ]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3), blurRadius: 16)
              ],
            ),
            child: Column(
              children: [
                const Text('TOTAL BALANCE',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$_totalBalance Stamps',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _stamps.isEmpty
                    ? _buildPlaceholderList()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _StampList(items: _stamps),
                          _StampList(
                              items: _stamps
                                  .where((s) =>
                                      (s is Map
                                          ? s['type'] ?? 'earned'
                                          : 'earned') ==
                                      'earned')
                                  .toList()),
                          _StampList(
                              items: _stamps
                                  .where((s) =>
                                      (s is Map ? s['type'] ?? '' : '') ==
                                      'redeemed')
                                  .toList()),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderList() {
    final items = [
      ('The Daily Grind', 'Oct 26, 2023', '₹450', 2),
      ('Boulangerie Patisserie', 'Oct 25, 2023', '₹1,200', 12),
      ('The Coffee Artisan', 'Oct 24, 2023', '₹350', 3),
    ];
    return TabBarView(
      controller: _tabController,
      children: [
        _StampList(placeholderItems: items),
        _StampList(placeholderItems: items),
        _StampList(placeholderItems: []),
      ],
    );
  }
}

class _StampList extends StatelessWidget {
  final List<dynamic>? items;
  final List<(String, String, String, int)>? placeholderItems;

  const _StampList({this.items, this.placeholderItems});

  @override
  Widget build(BuildContext context) {
    if (placeholderItems != null && placeholderItems!.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: placeholderItems!.length,
        itemBuilder: (context, i) {
          final p = placeholderItems![i];
          return _StampActivityTile(
              storeName: p.$1, date: p.$2, amount: p.$3, stamps: p.$4);
        },
      );
    }
    if (items == null || items!.isEmpty) {
      return const Center(child: Text('No activity yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items!.length,
      itemBuilder: (context, i) {
        final s = items![i] is Map ? items![i] as Map : {};
        final campaign = s['campaign'] is Map ? s['campaign'] as Map : {};
        final name = campaign['name'] ?? s['campaign_name'] ?? 'Store';
        final date = s['created_at'] ?? s['date'] ?? '';
        final progress = s['progress'] ?? s['current_count'] ?? 0;
        return _StampActivityTile(
            storeName: name,
            date: date.toString(),
            amount: '',
            stamps: progress is int ? progress : 0);
      },
    );
  }
}

class _StampActivityTile extends StatelessWidget {
  final String storeName;
  final String date;
  final String amount;
  final int stamps;

  const _StampActivityTile(
      {required this.storeName,
      required this.date,
      required this.amount,
      required this.stamps});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(storeName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(date,
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                if (amount.isNotEmpty)
                  Text(amount,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('+$stamps',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
