import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import 'stamp_history_screen.dart';

class StampsScreen extends StatefulWidget {
  const StampsScreen({super.key});

  @override
  State<StampsScreen> createState() => _StampsScreenState();
}

class _StampsScreenState extends State<StampsScreen> {
  final _api = KutootApi();
  List<dynamic> _stamps = [];
  bool _loading = true;
  String? _error;

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
      final res = await _api.getStamps();
      final data = res.data;
      if (data is Map && data['data'] != null) {
        _stamps = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        _stamps = data;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Stamps', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StampHistoryScreen())),
          ),
        ],
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
              : _stamps.isEmpty
                  ? const Center(child: Text('No stamps yet. Join a campaign to earn stamps.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stamps.length,
                        itemBuilder: (context, i) {
                          final s = _stamps[i] is Map ? _stamps[i] as Map : {};
                          final campaign = s['campaign'] is Map ? s['campaign'] as Map : {};
                          final name = campaign['name'] ?? s['campaign_name'] ?? 'Stamp';
                          final progress = s['progress'] ?? s['current_count'] ?? 0;
                          final total = s['total'] ?? s['required_count'] ?? campaign['stamps_required'] ?? 1;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.star_rounded, color: AppTheme.primary, size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: total > 0 ? (progress as num) / total : 0,
                                      minHeight: 8,
                                      backgroundColor: AppTheme.background,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('$progress / $total stamps', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
