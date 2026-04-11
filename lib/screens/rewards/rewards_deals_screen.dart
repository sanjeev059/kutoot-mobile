import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../api/kutoot_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../widgets/kutoot_bottom_nav.dart';
import '../home/kinetic_home_screens.dart';
import '../qr/qr_scan_screen.dart';
import '../stamps/stamps_screen.dart';
import '../stores/store_profile_screen.dart';
import 'reward_detail_screen.dart';

/// Reward Hub: exclusive campaigns + instant coupon offers (Figma `kutoot_rewards_hub`).
class RewardsHubScreen extends StatefulWidget {
  final String cityName;

  const RewardsHubScreen({super.key, required this.cityName});

  @override
  State<RewardsHubScreen> createState() => _RewardsHubScreenState();
}

/// Alias for deep links and older imports — same UI as [RewardsHubScreen].
class RewardsDealsScreen extends StatelessWidget {
  final String cityName;

  const RewardsDealsScreen({super.key, required this.cityName});

  @override
  Widget build(BuildContext context) => RewardsHubScreen(cityName: cityName);
}

class _RewardsHubScreenState extends State<RewardsHubScreen> {
  final _api = KutootApi();
  List<Map<String, dynamic>> _campaigns = _fallbackCampaignMaps();
  List<_RewardDeal> _apiDeals = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_fetchCampaigns(), _fetchDeals()]);
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
        final next = <Map<String, dynamic>>[];
        for (final item in items) {
          if (item is Map) {
            next.add(Map<String, dynamic>.from(item));
          }
        }
        setState(() => _campaigns = next);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _fetchDeals() async {
    try {
      final res = await _api.getCoupons(params: {'per_page': 50});
      final raw = res.data;
      final deals = <_RewardDeal>[];

      void parseCoupons(dynamic list, String segment) {
        if (list is! List) return;
        for (final item in list) {
          final m = item is Map
              ? Map<String, dynamic>.from(item)
              : <String, dynamic>{};
          final code = m['code']?.toString() ?? '';
          final title = m['title']?.toString() ?? '';
          if (code.isEmpty && title.isEmpty) continue;

          final requiredPlan = m['required_plan'] is Map
              ? (m['required_plan'] as Map)['name']?.toString() ?? 'BASIC'
              : (m['is_eligible'] == true ? '' : 'BASIC');

          final catMap = m['category'] is Map
              ? Map<String, dynamic>.from(m['category'] as Map)
              : <String, dynamic>{};
          final catName = catMap['name']?.toString() ?? segment;

          final merchant = m['merchant_location'] is Map
              ? Map<String, dynamic>.from(m['merchant_location'] as Map)
              : <String, dynamic>{};
          final merchantInfo = merchant['merchant'] is Map
              ? Map<String, dynamic>.from(merchant['merchant'] as Map)
              : <String, dynamic>{};
          final brandName = merchantInfo['name']?.toString() ?? catName;
          int? merchantLocationId;
          final mlId = merchant['id'];
          if (mlId != null) {
            merchantLocationId =
                mlId is int ? mlId : int.tryParse(mlId.toString());
          }
          merchantLocationId ??=
              int.tryParse(m['merchant_location_id']?.toString() ?? '');

          final discountType = m['discount_type']?.toString() ?? 'fixed';
          final discountValue =
              num.tryParse(m['discount_value']?.toString() ?? '0') ?? 0;
          final dealTitle = discountType == 'percentage'
              ? '$discountValue% OFF'
              : '₹$discountValue OFF';

          deals.add(_RewardDeal(
            brandName: brandName,
            categoryLabel: catName.toUpperCase(),
            title: title.isNotEmpty ? title : dealTitle,
            subtitle: m['description']?.toString() ?? '',
            code: code,
            requiredPlan: requiredPlan.toUpperCase(),
            merchantLocationId: merchantLocationId,
            type: segment == 'bank'
                ? _DealType.bank
                : (segment == 'store' ? _DealType.store : _DealType.merchant),
            brandIcon:
                segment == 'bank' ? Icons.account_balance : Icons.storefront,
            brandColor:
                segment == 'bank' ? const Color(0xFF004B87) : AppTheme.primary,
          ));
        }
      }

      if (raw is Map && raw['data'] is Map) {
        final data = Map<String, dynamic>.from(raw['data'] as Map);
        parseCoupons(data['plan_coupons'], 'plan');
        parseCoupons(data['store_coupons'], 'store');
        parseCoupons(data['other_coupons'], 'other');
      } else if (raw is Map && raw['data'] is List) {
        parseCoupons(raw['data'], 'plan');
      }

      if (deals.isNotEmpty && mounted) {
        setState(() => _apiDeals = deals);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> get _campaignsSource =>
      _campaigns.isNotEmpty ? _campaigns : _fallbackCampaignMaps();

  List<_RewardDeal> get _allDealsSource =>
      _apiDeals.isNotEmpty ? _apiDeals : _fallbackDeals;

  void _openCampaign(Map<String, dynamic> m) {
    final id = m['id'] is int
        ? m['id'] as int
        : int.tryParse(m['id']?.toString() ?? '');
    if (id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward details are not available yet.')),
      );
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RewardDetailScreen(
          campaignId: id,
          cityName: widget.cityName,
        ),
      ),
    );
  }

  void _onBackOrHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    final auth = context.read<AuthProvider>();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => auth.isLoggedIn
            ? LoggedInHomeScreen(cityName: widget.cityName)
            : GuestHomeScreen(cityName: widget.cityName),
      ),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = _campaignsSource;
    final deals = _allDealsSource;
    const primaryMaroon = Color(0xFFAE1E3F);
    const secondaryOrange = Color(0xFFEA6B1E);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const QrScanScreen()),
          ),
          backgroundColor: primaryMaroon,
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        ),
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return KutootBottomNav(
            activeIndex: 1,
            cityName: widget.cityName,
            isLoggedIn: auth.isLoggedIn,
          );
        },
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: primaryMaroon,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (!auth.isLoggedIn) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _StampCollectionBanner(
                          cityName: widget.cityName,
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    StampsScreen(cityName: widget.cityName),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Text(
                    'Exclusive Campaigns',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: secondaryOrange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your Rewards Hub',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: const Color(0xFF221A14),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap a reward for full details, progress, and partners.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.35,
                      color: const Color(0xFF594042),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...campaigns.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _HubCampaignCard(
                        data: m,
                        onTap: () => _openCampaign(m),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Instant offers',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF221A14),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to open store',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF594042),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...deals.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DealCardCompact(
                        deal: d,
                        onOpen: () {
                          final id = d.merchantLocationId;
                          if (id != null && id > 0) {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => StoreProfileScreen(
                                  cityName: widget.cityName,
                                  store: {
                                    'id': id,
                                    'name': d.brandName,
                                    'branch_name': d.brandName,
                                  },
                                ),
                              ),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'This offer isn’t linked to a store listing yet. Try another offer or browse Stores.',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
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

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: _onBackOrHome,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.asset(
                    AppTheme.logoAsset,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.secondaryContainer.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: AppTheme.secondaryContainer),
                    const SizedBox(width: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 88),
                      child: Text(
                        '${widget.cityName} ▾',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.secondaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
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
}

class _HubCampaignCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _HubCampaignCard({required this.data, required this.onTap});

  int? get _id {
    final v = data['id'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  String get _title {
    final t = data['reward_name']?.toString() ??
        data['code']?.toString() ??
        'Reward';
    return t.toUpperCase();
  }

  int get _progress {
    final issued =
        int.tryParse(data['issued_stamps_cache']?.toString() ?? '0') ?? 0;
    final stampTarget =
        int.tryParse(data['stamp_target']?.toString() ?? '100') ?? 100;
    if (stampTarget <= 0) return 0;
    return ((issued / stampTarget) * 100).round().clamp(0, 100);
  }

  int get _filledSegments => (_progress / 10).round().clamp(0, 10);

  String get _valueLine {
    final v = data['prize_value_display'] ??
        data['reward_value'] ??
        data['prize_amount'] ??
        data['estimated_value'];
    if (v != null && v.toString().trim().isNotEmpty) {
      return 'Prize value · ${v.toString()}';
    }
    return 'Collect stamps to qualify';
  }

  String _drawDateLabel() {
    final raw = data['winner_announcement_at'] ??
        data['draw_date'] ??
        data['announcement_date'];
    if (raw == null) return 'Draw date TBA';
    try {
      final dt = DateTime.tryParse(raw.toString());
      if (dt != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return 'Draw ${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}
    return 'Draw $raw';
  }

  ({String label, Color bg, Color fg}) _badge() {
    final isPrimary = data['is_primary'] == true;
    final live = data['is_active'] == true &&
        (data['status']?.toString() ?? 'active') == 'active';
    if (isPrimary) {
      return (
        label: 'Primary',
        bg: const Color(0xFFEA6B1E),
        fg: Colors.white,
      );
    }
    if (live) {
      return (
        label: 'Eligible',
        bg: const Color(0xFF2E7D32),
        fg: Colors.white,
      );
    }
    return (
      label: 'Locked',
      bg: const Color(0xFF594042),
      fg: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge();
    final imageUrl = ImageUtils.fromMap(data);
    const maroon = Color(0xFFAE1E3F);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 240,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFF5E5DB),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: maroon,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFAE1E3F), Color(0xFFEA6B1E)],
                      ),
                    ),
                    child: const Icon(Icons.card_giftcard_rounded,
                        color: Colors.white54, size: 64),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        maroon,
                        maroon.withValues(alpha: 0.75),
                        const Color(0xFFEA6B1E),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.card_giftcard_rounded,
                        color: Colors.white38, size: 72),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    badge.label.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                      color: badge.fg,
                    ),
                  ),
                ),
              ),
              if (_id != null)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$_id',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF221A14),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 14, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _drawDateLabel(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _valueLine,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Bounty progress',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_progress%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(10, (index) {
                        final active = index < _filledSegments;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: index < 9 ? 3 : 0),
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _fallbackCampaignMaps() => [
      {
        'id': 1,
        'reward_name': 'Luxury Villa',
        'issued_stamps_cache': 82,
        'stamp_target': 100,
        'is_active': true,
        'status': 'active',
        'is_primary': false,
      },
      {
        'id': 2,
        'reward_name': 'BMW M4 Competition',
        'issued_stamps_cache': 45,
        'stamp_target': 100,
        'is_active': true,
        'status': 'active',
        'is_primary': true,
      },
      {
        'id': 3,
        'reward_name': 'Maldives Trip',
        'issued_stamps_cache': 0,
        'stamp_target': 100,
        'is_active': false,
        'status': 'announced',
        'is_primary': false,
      },
    ];

class _StampCollectionBanner extends StatelessWidget {
  final String cityName;
  final VoidCallback onTap;

  const _StampCollectionBanner({
    required this.cityName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFAE1E3F).withValues(alpha: 0.07),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFAE1E3F).withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFAE1E3F).withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A2E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    color: Color(0xFFAE1E3F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stamp collection',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View tickets, search codes & scan QR in $cityName',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _DealType { merchant, bank, store }

class _RewardDeal {
  final String brandName;
  final String categoryLabel;
  final String title;
  final String subtitle;
  final String code;
  final String requiredPlan;
  final int? merchantLocationId;
  final _DealType type;
  final IconData brandIcon;
  final Color brandColor;

  const _RewardDeal({
    required this.brandName,
    required this.categoryLabel,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.requiredPlan,
    this.merchantLocationId,
    required this.type,
    required this.brandIcon,
    required this.brandColor,
  });
}

const _fallbackDeals = [
  _RewardDeal(
    brandName: 'Starbucks Reserve',
    categoryLabel: 'MERCHANT OFFER',
    title: '60% OFF',
    subtitle: 'Valid till 30 Nov • Up to ₹200',
    code: 'SBUX60',
    requiredPlan: 'BASIC',
    merchantLocationId: null,
    type: _DealType.merchant,
    brandIcon: Icons.coffee,
    brandColor: Color(0xFF00704A),
  ),
  _RewardDeal(
    brandName: 'HDFC Bank Cards',
    categoryLabel: 'BANK PRIVILEGE',
    title: '₹500 BACK',
    subtitle: 'Ends in 2 days • Min. ₹1,999',
    code: 'HDFC500',
    requiredPlan: 'PRO',
    merchantLocationId: null,
    type: _DealType.bank,
    brandIcon: Icons.account_balance,
    brandColor: Color(0xFF004B87),
  ),
  _RewardDeal(
    brandName: "Nature's Basket",
    categoryLabel: 'STORE REWARD',
    title: 'FREE SHIP',
    subtitle: 'Next 3 fresh orders • Member exclusive',
    code: 'NBSHIP',
    requiredPlan: 'BASIC',
    merchantLocationId: null,
    type: _DealType.store,
    brandIcon: Icons.eco,
    brandColor: Color(0xFF558B2F),
  ),
];

class _DealCardCompact extends StatelessWidget {
  final _RewardDeal deal;
  final VoidCallback onOpen;

  const _DealCardCompact({
    required this.deal,
    required this.onOpen,
  });

  Color get _cardBackgroundColor {
    switch (deal.type) {
      case _DealType.merchant:
        return const Color(0xFFFFF3E8);
      case _DealType.bank:
        return const Color(0xFFE8F0FF);
      case _DealType.store:
        return const Color(0xFFE8FFE8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBackgroundColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: deal.brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(deal.brandIcon, color: deal.brandColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.categoryLabel,
                      style: TextStyle(
                        color: deal.brandColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      deal.brandName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        height: 1,
                      ),
                    ),
                    if (deal.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        deal.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
