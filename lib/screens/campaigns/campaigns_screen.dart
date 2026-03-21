import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import 'campaign_detail_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final _api = KutootApi();
  List<dynamic> _campaigns = [];
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
      final res = await _api.getCampaigns();
      final data = res.data;
      if (data is Map && data['data'] != null) {
        _campaigns = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        _campaigns = data;
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
        title: const Text('Campaigns', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
              : _campaigns.isEmpty
                  ? const Center(child: Text('No campaigns yet'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _campaigns.length,
                        itemBuilder: (context, i) {
                          final c = _campaigns[i] is Map ? _campaigns[i] as Map : {};
                          final id = c['id'];
                          final name = c['reward_name'] ?? c['name'] ?? 'Campaign';
                          final desc = c['description'] ?? '';
                          final imageUrl = ImageUtils.fromMap(Map<String, dynamic>.from(c));
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
                            ),
                            child: ListTile(
                              onTap: id != null
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CampaignDetailScreen(campaignId: id is int ? id : int.tryParse(id.toString()) ?? 0),
                                        ),
                                      )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              leading: imageUrl != null && imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: AppTheme.primary.withOpacity(0.1), child: const Icon(Icons.card_giftcard_rounded, color: AppTheme.primary, size: 28)),
                                        errorWidget: (_, __, ___) => Container(color: AppTheme.primary.withOpacity(0.15), child: const Icon(Icons.card_giftcard_rounded, color: AppTheme.primary, size: 28)),
                                      ),
                                    )
                                  : Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.card_giftcard_rounded, color: AppTheme.primary, size: 28),
                                    ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: desc.isNotEmpty ? Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
