import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';

const String _kLogoAsset = 'assets/images/k_logo.png';

class CampaignsScreen extends StatefulWidget {
  final String cityName;
  final int initialTabIndex;
  final String? upgradeLabel;
  final VoidCallback? onUpgradeTap;

  const CampaignsScreen({
    super.key,
    required this.cityName,
    this.initialTabIndex = 0,
    this.upgradeLabel,
    this.onUpgradeTap,
  });

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final _api = KutootApi();
  late int _activeTab;
  List<_CampaignData> _liveCampaigns = _fallbackLive;
  List<_CampaignData> _announcedCampaigns = _fallbackAnnounced;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
    _fetchCampaigns();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _fetchCampaigns());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCampaigns() async {
    try {
      final res = await _api.getCampaigns(params: {'per_page': 50});
      final raw = res.data;
      List items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }
      if (items.isNotEmpty && mounted) {
        final live = <_CampaignData>[];
        final announced = <_CampaignData>[];
        for (final item in items) {
          final m = item is Map
              ? Map<String, dynamic>.from(item)
              : <String, dynamic>{};
          final status = m['status']?.toString() ?? 'active';
          final isActive = m['is_active'] == true;
          final title = m['reward_name']?.toString() ??
              m['code']?.toString() ??
              'Campaign';
          final issuedStamps =
              int.tryParse(m['issued_stamps_cache']?.toString() ?? '0') ?? 0;
          final stampTarget =
              int.tryParse(m['stamp_target']?.toString() ?? '100') ?? 100;
          final progress = stampTarget > 0
              ? ((issuedStamps / stampTarget) * 100).round().clamp(0, 100)
              : 0;
          final c = _CampaignData(
            id: m['id'] is int
                ? m['id'] as int
                : int.tryParse(m['id']?.toString() ?? ''),
            title: title.toUpperCase(),
            stamps: issuedStamps,
            progress: progress,
            live: isActive && status == 'active',
          );
          if (c.live) {
            live.add(c);
          } else {
            announced.add(c);
          }
        }
        setState(() {
          if (live.isNotEmpty) _liveCampaigns = live;
          if (announced.isNotEmpty) _announcedCampaigns = announced;
        });
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = _activeTab == 0 ? _liveCampaigns : _announcedCampaigns;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeArea(
        child: Column(
          children: [
            _CampaignHeader(
              cityName: widget.cityName,
              rightLabel: widget.upgradeLabel,
              onRightTap: widget.onUpgradeTap,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchCampaigns,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E5DB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'LIVE',
                              selected: _activeTab == 0,
                              onTap: () => setState(() => _activeTab = 0),
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              label: 'ANNOUNCED',
                              selected: _activeTab == 1,
                              onTap: () => setState(() => _activeTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...campaigns.map(
                      (c) => _CampaignTicket(
                        campaign: c,
                        onEnterTap: () => _onEnterCampaign(c),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onEnterCampaign(_CampaignData campaign) async {
    final id = campaign.id;
    if (id == null) {
      _showInfo(
        'Entry noted. Keep completing Kutoot activities to unlock this reward.',
      );
      return;
    }
    try {
      final response = await _api.participateInCampaign(id);
      final body = response.data;
      String msg = 'You\'re in this Kutoot campaign.';
      if (body is Map && body['message'] != null) {
        msg = body['message'].toString();
      }
      final title = campaign.title.trim();
      if (title.isNotEmpty) {
        msg = '$msg — $title';
      }
      if (!mounted) return;
      _showInfo(msg);
    } catch (_) {
      if (!mounted) return;
      _showInfo(
        'You can join this campaign by app engagement tasks. Please try again shortly.',
      );
    }
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CampaignHeader extends StatelessWidget {
  final String cityName;
  final String? rightLabel;
  final VoidCallback? onRightTap;

  const _CampaignHeader({
    required this.cityName,
    this.rightLabel,
    this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.92),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentWarm.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: AppTheme.accentWarm.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    size: 15, color: AppTheme.accentWarm),
                const SizedBox(width: 2),
                Text(
                  '$cityName ▾',
                  style: const TextStyle(
                    color: AppTheme.accentWarm,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                _kLogoAsset,
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (rightLabel != null &&
              rightLabel!.isNotEmpty &&
              onRightTap != null)
            InkWell(
              onTap: onRightTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  rightLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _CampaignTicket extends StatelessWidget {
  final _CampaignData campaign;
  final VoidCallback onEnterTap;
  const _CampaignTicket({
    required this.campaign,
    required this.onEnterTap,
  });

  @override
  Widget build(BuildContext context) {
    final filledBars = (campaign.progress / 10).round().clamp(0, 10);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 174,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: const Color(0xFFE1BEC0).withValues(alpha: 0.7),
                  width: 1.4,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  _kLogoAsset,
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 4),
                Text(
                  'KUTOOT',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.black.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          campaign.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: campaign.live
                              ? const Color(0xFFEA6B1E)
                              : const Color(0xFF594042),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          campaign.live ? 'LIVE CAMPAIGN' : 'ANNOUNCED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Your Engagement',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.accentWarm,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${campaign.stamps} Stamps',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (campaign.live) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Progress Meter',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.primaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${campaign.progress}% Progress',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(10, (index) {
                        final active = index < filledBars;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 2),
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.primaryContainer
                                  : const Color(0xFFF5E5DB),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onEnterTap,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      child: const Text('ENTER VIA APP TASKS'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignData {
  final int? id;
  final String title;
  final int stamps;
  final int progress;
  final bool live;

  const _CampaignData({
    this.id,
    required this.title,
    required this.stamps,
    required this.progress,
    required this.live,
  });
}

const List<_CampaignData> _fallbackLive = [
  _CampaignData(
      id: 1, title: 'LUXURY VILLA', stamps: 12, progress: 82, live: true),
  _CampaignData(
      id: 2, title: 'BMW M4 COMPETITION', stamps: 5, progress: 45, live: true),
  _CampaignData(
      id: 3, title: '1KG GOLD BAR', stamps: 1, progress: 94, live: true),
];

const List<_CampaignData> _fallbackAnnounced = [
  _CampaignData(
      id: 4, title: 'MALDIVES TRIP', stamps: 0, progress: 0, live: false),
  _CampaignData(
      id: 5, title: 'IPHONE PRO MAX', stamps: 0, progress: 0, live: false),
  _CampaignData(
      id: 6,
      title: 'PREMIUM HOME MAKEOVER',
      stamps: 0,
      progress: 0,
      live: false),
];
