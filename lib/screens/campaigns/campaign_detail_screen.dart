import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../stores/stores_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final _api = KutootApi();
  Map<String, dynamic>? _campaign;
  Map<String, dynamic>? _bounty;
  bool _loading = true;
  String? _error;
  bool _reserving = false;
  Duration _countdown = const Duration(hours: 6, minutes: 12, seconds: 45);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _countdown.inSeconds > 0) {
        setState(
            () => _countdown = Duration(seconds: _countdown.inSeconds - 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdownStr {
    final h = _countdown.inHours.toString().padLeft(2, '0');
    final m = (_countdown.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_countdown.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getCampaign(widget.campaignId);
      final data = res.data;
      Map<String, dynamic>? bounty;
      try {
        final bountyRes = await _api.getCampaignBounty(widget.campaignId);
        bounty = bountyRes.data is Map
            ? Map<String, dynamic>.from(bountyRes.data as Map)
            : null;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _campaign =
              data is Map ? Map<String, dynamic>.from(data as Map) : data;
          _bounty = bounty;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _reserveStamp() async {
    if (_reserving) return;
    setState(() => _reserving = true);
    try {
      await _api.reserveStamp(widget.campaignId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stamp reserved successfully')),
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
      if (mounted) setState(() => _reserving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Campaign',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _campaign == null
                  ? const Center(child: Text('Campaign not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ImageUtils.fromMap(_campaign) != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: ImageUtils.fromMap(_campaign)!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                      height: 200,
                                      color: AppTheme.primary.withOpacity(0.1),
                                      child: const Center(
                                          child: Icon(
                                              Icons.card_giftcard_rounded,
                                              size: 64,
                                              color: AppTheme.primary))),
                                  errorWidget: (_, __, ___) => Container(
                                      height: 200,
                                      color: AppTheme.primary.withOpacity(0.1),
                                      child: const Center(
                                          child: Icon(
                                              Icons.card_giftcard_rounded,
                                              size: 64,
                                              color: AppTheme.primary))),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            Text(
                              _campaign!['reward_name'] ??
                                  _campaign!['name'] ??
                                  'Campaign',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if ((_campaign!['description'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _campaign!['description'].toString(),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.timer_rounded,
                                      color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Text(_countdownStr,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if (_bounty != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.star_rounded,
                                        color: AppTheme.primary, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Bounty: ${_bounty!['description'] ?? _bounty!['amount'] ?? 'Available'}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _ExpandableSection(
                                title: 'How to Play',
                                content:
                                    '1. Visit a participating store\n2. Make a purchase and show your QR code\n3. Earn stamps for each visit\n4. Complete the card to win rewards!'),
                            const SizedBox(height: 12),
                            _ExpandableSection(
                                title: 'Rules',
                                content:
                                    '• One stamp per visit\n• Stamps cannot be transferred\n• Offer valid at participating locations only\n• Terms and conditions apply'),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Nearby Stores',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const StoresScreen())),
                                  child: const Text('See all'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _NearbyStoreChip(
                                      name: 'The Coffee Artisan', onTap: () {}),
                                  _NearbyStoreChip(
                                      name: 'Burger King', onTap: () {}),
                                  _NearbyStoreChip(
                                      name: 'Starbucks', onTap: () {}),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _reserving ? null : _reserveStamp,
                                child: _reserving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text('Reserve Stamp'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final String content;

  const _ExpandableSection({required this.title, required this.content});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.content,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, height: 1.5)),
            ),
        ],
      ),
    );
  }
}

class _NearbyStoreChip extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _NearbyStoreChip({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_rounded, color: AppTheme.primary, size: 28),
                const SizedBox(height: 8),
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
