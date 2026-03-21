import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _api = KutootApi();
  List<dynamic> _plans = [];
  Map<String, dynamic>? _current;
  bool _loading = true;
  String? _error;
  bool _upgrading = false;
  bool _yearly = false;

  final _defaultPlans = [
    {'name': 'Free', 'price': 0, 'monthly': 0, 'yearly': 0, 'recommended': false},
    {'name': 'Pro', 'price': 9.99, 'monthly': 9.99, 'yearly': 99.99, 'recommended': true},
    {'name': 'VIP', 'price': 19.99, 'monthly': 19.99, 'yearly': 199.99, 'recommended': false},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plansRes = await _api.getSubscriptionPlans();
      Map<String, dynamic>? current;
      try {
        final curRes = await _api.getCurrentSubscription();
        current = curRes.data is Map ? Map<String, dynamic>.from(curRes.data as Map) : null;
      } catch (_) {}
      final data = plansRes.data;
      List<dynamic> plans = [];
      if (data is Map && data['data'] != null) {
        plans = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        plans = data;
      }
      if (mounted) setState(() {
        _plans = plans;
        _current = current;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _upgrade(int planId) async {
    if (_upgrading) return;
    setState(() => _upgrading = true);
    try {
      await _api.upgradeSubscription(planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription upgrade initiated')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Subscription', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ToggleChip(label: 'Monthly', selected: !_yearly, onTap: () => setState(() => _yearly = false)),
                                _ToggleChip(label: 'Yearly', selected: _yearly, onTap: () => setState(() => _yearly = true)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_current != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.card_membership, color: AppTheme.primary, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Current: ${_current!['plan']?['name'] ?? _current!['plan_name'] ?? 'Active'}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const Text('Available Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...(_plans.isEmpty ? _defaultPlans : _plans).map((p) {
                          final plan = p is Map ? p as Map : {};
                          final id = plan['id'];
                          final name = plan['name'] ?? 'Plan';
                          final price = _yearly ? (plan['yearly'] ?? plan['price'] ?? plan['amount']) : (plan['monthly'] ?? plan['price'] ?? plan['amount']);
                          final desc = plan['description'] ?? '';
                          final recommended = plan['recommended'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      if (recommended) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                          child: const Text('Recommended', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (desc.toString().isNotEmpty) Text(desc.toString(), style: const TextStyle(color: AppTheme.textSecondary)),
                                  if (price != null) Text('₹$price', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                  const SizedBox(height: 12),
                                  if (id != null)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _upgrading ? null : () => _upgrade(id is int ? id : int.tryParse(id.toString()) ?? 0),
                                        child: _upgrading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Upgrade'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (_plans.isEmpty && _defaultPlans.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No plans available'))),
                        const SizedBox(height: 24),
                        const Text('Compare Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _ComparisonRow(feature: 'Reward Limit', free: '5/mo', pro: 'Unlimited', vip: 'Unlimited'),
                        _ComparisonRow(feature: 'Customization', free: '—', pro: '✓', vip: '✓'),
                        _ComparisonRow(feature: 'Exclusive Items', free: '—', pro: '—', vip: '✓'),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)] : null,
        ),
        child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String feature;
  final String free;
  final String pro;
  final String vip;

  const _ComparisonRow({required this.feature, required this.free, required this.pro, required this.vip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(feature, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(free, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary))),
          Expanded(child: Text(pro, textAlign: TextAlign.center)),
          Expanded(child: Text(vip, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
