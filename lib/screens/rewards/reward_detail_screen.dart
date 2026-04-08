import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../qr/qr_scan_screen.dart';

/// Campaign / exclusive reward detail — layout aligned with Figma `kutoot_reward_details_consistent_nav`.
class RewardDetailScreen extends StatefulWidget {
  final int campaignId;
  final String? cityName;

  const RewardDetailScreen({
    super.key,
    required this.campaignId,
    this.cityName,
  });

  @override
  State<RewardDetailScreen> createState() => _RewardDetailScreenState();
}

class _RewardDetailScreenState extends State<RewardDetailScreen> {
  final _api = KutootApi();
  Map<String, dynamic>? _campaign;
  Map<String, dynamic>? _bounty;
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
      final res = await _api.getCampaign(widget.campaignId);
      final data = KutootApi.unwrapSuccessData(res.data);
      if (data == null) throw Exception('Invalid response');
      Map<String, dynamic>? bounty;
      try {
        final b = await _api.getCampaignBounty(widget.campaignId);
        bounty = KutootApi.unwrapSuccessData(b.data);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _campaign = data;
          _bounty = bounty;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<String> _galleryUrls() {
    final c = _campaign;
    if (c == null) return [];
    final urls = <String>[];
    final main = ImageUtils.fromMap(c);
    if (main != null) urls.add(main);
    final media = c['media'];
    if (media is List) {
      for (final m in media) {
        if (m is Map) {
          final u = ImageUtils.resolve(m['url'] ?? m['thumb'] ?? m['preview']);
          if (u.isNotEmpty && !urls.contains(u)) urls.add(u);
        }
      }
    }
    return urls;
  }

  String _title() =>
      _campaign?['reward_name']?.toString() ??
      _campaign?['name']?.toString() ??
      'Reward';

  String _valueLabel() {
    final c = _campaign;
    if (c == null) return '—';
    final v = c['prize_value_display'] ??
        c['reward_value'] ??
        c['prize_amount'] ??
        c['estimated_value'];
    if (v != null && v.toString().isNotEmpty) {
      final s = v.toString();
      if (s.contains('₹')) return s;
      final n = num.tryParse(s);
      if (n != null) return '₹${_formatIndian(n)}';
      return s;
    }
    return 'Exclusive reward';
  }

  String _formatIndian(num n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)} L';
    if (n >= 1000) return n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return n.toStringAsFixed(0);
  }

  String _announcementDate() {
    final c = _campaign;
    if (c == null) return 'TBA';
    final d = c['winner_announcement_at'] ??
        c['draw_date'] ??
        c['end_date'] ??
        c['announcement_date'];
    if (d == null) return 'TBA';
    try {
      final dt = DateTime.tryParse(d.toString());
      if (dt != null) {
        const months = [
          'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
          'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
        ];
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}
    return d.toString();
  }

  int _bountyPercent() {
    final c = _campaign;
    if (c == null) return 0;
    final issued =
        int.tryParse(c['issued_stamps_cache']?.toString() ?? '0') ?? 0;
    final target = int.tryParse(c['stamp_target']?.toString() ?? '100') ?? 100;
    if (target <= 0) return 0;
    return ((issued / target) * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFF8F5);
    const primary = Color(0xFFAE1E3F);
    const secondary = Color(0xFFEA6B1E);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const QrScanScreen()),
          ),
          backgroundColor: primary,
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: Colors.white.withValues(alpha: 0.92),
                      elevation: 0,
                      leadingWidth: 44,
                      titleSpacing: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF221A14)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: SizedBox(
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: Image.asset(
                                AppTheme.logoAsset,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (widget.cityName != null &&
                                widget.cityName!.trim().isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: secondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: secondary.withValues(alpha: 0.22),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_rounded,
                                            size: 12, color: secondary),
                                        const SizedBox(width: 3),
                                        ConstrainedBox(
                                          constraints:
                                              const BoxConstraints(maxWidth: 72),
                                          child: Text(
                                            widget.cityName!.trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: secondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _GalleryRow(urls: _galleryUrls()),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A2E),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'EXCLUSIVE CAMPAIGN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: const Color(0xFF612500),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _title(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: -0.5,
                                color: const Color(0xFF221A14),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    right: -24,
                                    top: -24,
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TOTAL REWARD VALUE',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2,
                                          color: Colors.white.withValues(
                                              alpha: 0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _valueLabel(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E5DB)
                                    .withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFE1BEC0)
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_rounded,
                                      size: 18, color: primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'WINNER ANNOUNCEMENT',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                        color: const Color(0xFF594042),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _announcementDate(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            _PartnersStrip(campaign: _campaign),
                            const SizedBox(height: 22),
                            _BountyMeterCard(
                              percent: _bountyPercent(),
                              bountyHint: _bounty?['description']?.toString(),
                            ),
                            const SizedBox(height: 16),
                            const _RewardInfoCards(),
                            const SizedBox(height: 22),
                            Text(
                              'ABOUT THIS REWARD',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: const Color(0xFF594042),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              (_campaign?['description']?.toString() ?? '')
                                      .isNotEmpty
                                  ? _campaign!['description'].toString()
                                  : 'Complete Kutoot activities and earn stamps toward this campaign. '
                                      'Terms apply; see campaign rules in the app and on kutoot.com.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                height: 1.5,
                                color: const Color(0xFF594042),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// Short guidance tiles (Figma-style info cards below bounty).
class _RewardInfoCards extends StatelessWidget {
  const _RewardInfoCards();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String body) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE1BEC0).withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFAE1E3F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFAE1E3F), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF221A14),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.35,
                      color: const Color(0xFF594042),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        tile(
          Icons.qr_code_scanner_rounded,
          'Pay in the app',
          'Pay at partner stores through Kutoot and show your QR — that’s how stamps are recorded.',
        ),
        const SizedBox(height: 10),
        tile(
          Icons.stacked_line_chart_rounded,
          'Bounty meter',
          'Shows how close this campaign is to its community goal. Your personal stamps still count toward qualifying.',
        ),
        const SizedBox(height: 10),
        tile(
          Icons.calendar_month_rounded,
          'Winner timeline',
          'Watch the announcement date above. Rules and eligibility may vary by campaign.',
        ),
      ],
    );
  }
}

class _GalleryRow extends StatelessWidget {
  final List<String> urls;

  const _GalleryRow({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: ColoredBox(
            color: const Color(0xFFAE1E3F).withValues(alpha: 0.15),
            child: const Center(
              child: Icon(Icons.card_giftcard_rounded,
                  size: 56, color: Color(0xFFAE1E3F)),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: MediaQuery.of(context).size.width * 10 / 16,
      child: PageView.builder(
        itemCount: urls.length,
        padEnds: false,
        controller: PageController(viewportFraction: 0.92),
        itemBuilder: (_, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: urls[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFFF5E5DB),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFF5E5DB),
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${i + 1}/${urls.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PartnersStrip extends StatelessWidget {
  final Map<String, dynamic>? campaign;

  const _PartnersStrip({this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFFE1BEC0).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'OFFICIAL CAMPAIGN PARTNERS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: const Color(0xFF221A14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE1BEC0).withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _partnerPlaceholder('Partner'),
                _partnerPlaceholder('Partner'),
                _partnerPlaceholder('Partner'),
                Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEBE0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE1BEC0).withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Text(
                    '+ MORE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF594042).withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This reward is made possible by our valued partners',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF594042).withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _partnerPlaceholder(String label) {
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFE1BEC0).withValues(alpha: 0.4)),
      ),
      child: Icon(Icons.storefront_rounded,
          color: const Color(0xFF594042).withValues(alpha: 0.35)),
    );
  }
}

class _BountyMeterCard extends StatelessWidget {
  final int percent;
  final String? bountyHint;

  const _BountyMeterCard({required this.percent, this.bountyHint});

  @override
  Widget build(BuildContext context) {
    const secondary = Color(0xFFEA6B1E);
    final filled = (percent / 100 * 10).ceil().clamp(0, 10);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFE1BEC0).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bounty meter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF221A14),
                ),
              ),
              Text(
                '$percent%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(10, (i) {
              final active = i < filled;
              return Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(right: i < 9 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: active
                        ? secondary
                        : secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            bountyHint ??
                '${100 - percent}% to go toward full bounty capacity for the final draw.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              height: 1.35,
              color: const Color(0xFF594042),
            ),
          ),
        ],
      ),
    );
  }
}
