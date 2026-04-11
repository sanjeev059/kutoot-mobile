import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../qr/qr_scan_screen.dart';
import 'stamp_history_screen.dart';

/// Stamp collection — UI aligned with `Stamps-collection/code.html` (no upgrade CTA).
class StampsScreen extends StatefulWidget {
  /// Shown in header chip when provided (e.g. from Rewards / Profile).
  final String? cityName;

  const StampsScreen({super.key, this.cityName});

  @override
  State<StampsScreen> createState() => _StampsScreenState();
}

class _StampsScreenState extends State<StampsScreen> {
  static const Color _surface = Color(0xFFFFF8F5);
  static const Color _primaryMaroon = Color(0xFF8A002B);
  static const Color _primaryContainer = Color(0xFFAE1E3F);
  static const Color _secondary = Color(0xFFEA6B1E);
  static const Color _secondaryContainer = Color(0xFFFF7A2E);
  static const Color _inputFill = Color(0xFFF5E5DB);
  static const Color _onSurface = Color(0xFF221A14);
  static const Color _chipIdle = Color(0xFFEFE0D5);

  final _api = KutootApi();
  late final Razorpay _razorpay;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _stamps = [];
  List<Map<String, dynamic>> _campaigns = [];
  List<Map<String, dynamic>> _plans = [];
  List<String> _filterLabels = ['ALL'];
  int _filterIndex = 0;
  bool _loading = true;
  String? _error;
  bool _reserving = false;
  int? _pendingStampId;
  int? _pendingPlanId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getStamps();
      Response<dynamic>? campaignsRes;
      try {
        campaignsRes = await _api.getAvailableCampaigns();
      } catch (_) {}
      Response<dynamic>? plansRes;
      try {
        plansRes = await _api.getSubscriptionPlans();
      } catch (_) {}
      final data = res.data;
      if (data is Map && data['data'] != null) {
        final d = data['data'];
        if (d is List) {
          _stamps = d
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          _stamps = [];
        }
      } else if (data is List) {
        _stamps = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (campaignsRes != null && campaignsRes.data is Map) {
        final d = (campaignsRes.data as Map)['data'];
        _campaigns = d is List
            ? d
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      }

      if (plansRes != null && plansRes.data is Map) {
        final d = (plansRes.data as Map)['data'];
        _plans = d is List
            ? d
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      }

      _rebuildFilters();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _rebuildFilters() {
    final words = <String>{};
    for (final s in _stamps) {
      final t = _titleFromStamp(s).toUpperCase();
      for (final w in t.split(RegExp(r'[^A-Z0-9]+'))) {
        if (w.length >= 3) words.add(w);
      }
    }
    final sorted = words.toList()..sort();
    _filterLabels = ['ALL', ...sorted.take(8)];
    _filterIndex = 0;
  }

  String _titleFromStamp(Map<String, dynamic> s) {
    final campaign =
        s['campaign'] is Map ? s['campaign'] as Map : <String, dynamic>{};
    final v = campaign['reward_name'] ??
        campaign['name'] ??
        campaign['code'] ??
        s['name'] ??
        'Stamp';
    return v.toString();
  }

  String _codeFromStamp(Map<String, dynamic> s) {
    final c = s['code']?.toString();
    if (c != null && c.isNotEmpty && c != '-') return c;
    return 'KTO-${s['id'] ?? '----'}';
  }

  String? _imageFromStamp(Map<String, dynamic> s) {
    final campaign =
        s['campaign'] is Map ? s['campaign'] as Map : <String, dynamic>{};
    return ImageUtils.resolve(
      campaign['image_url'] ??
          campaign['thumbnail_url'] ??
          campaign['banner_url'] ??
          campaign['hero_image_url'],
    );
  }

  List<Map<String, dynamic>> get _filteredStamps {
    final q = _searchController.text.trim().toLowerCase();
    final label =
        _filterIndex > 0 && _filterIndex < _filterLabels.length
            ? _filterLabels[_filterIndex]
            : null;

    return _stamps.where((s) {
      final title = _titleFromStamp(s).toLowerCase();
      final code = _codeFromStamp(s).toLowerCase();
      if (q.isNotEmpty && !title.contains(q) && !code.contains(q)) {
        return false;
      }
      if (label != null && label != 'ALL') {
        if (!title.contains(label.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final city = widget.cityName?.trim();

    return Scaffold(
      backgroundColor: _surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: _primaryContainer,
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: _primaryContainer.withValues(alpha: 0.45),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const QrScanScreen()),
            ),
            child: Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context, canPop: canPop, city: city),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primaryMaroon))
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
                      : RefreshIndicator(
                          color: _primaryMaroon,
                          onRefresh: _load,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(22, 8, 22, 12),
                                sliver: SliverToBoxAdapter(
                                  child: _searchField(),
                                ),
                              ),
                              if (_filterLabels.length > 1)
                                SliverToBoxAdapter(child: _filterChips()),
                              if (_filteredStamps.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Text(
                                        _stamps.isEmpty
                                            ? 'No stamps yet. Scan a store QR or join a campaign to collect stamps.'
                                            : 'No stamps match your search or filter.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          color: _onSurface.withValues(alpha: 0.65),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                      22, 0, 22, 100),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, i) {
                                        final s = _filteredStamps[i];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _StampTicketCard(
                                            title: _titleFromStamp(s),
                                            code: _codeFromStamp(s),
                                            imageUrl: _imageFromStamp(s),
                                          ),
                                        );
                                      },
                                      childCount: _filteredStamps.length,
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

  Widget _buildTopBar(BuildContext context,
      {required bool canPop, String? city}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: _onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          if (city != null && city.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _secondary.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 15, color: _secondary),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 88),
                    child: Text(
                      '$city ▾',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (city != null && city.isNotEmpty) const SizedBox(width: 6),
          Expanded(
            child: Center(
              child: Image.asset(
                AppTheme.logoAsset,
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded, color: _primaryMaroon),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => const StampHistoryScreen()),
            ),
          ),
          if (_campaigns.isNotEmpty && _plans.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: _onSurface),
              onSelected: (v) {
                if (v == 'reserve') _openReserveSheet();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'reserve',
                  child: Text('Reserve stamp (plan)'),
                ),
              ],
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        color: _onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Search unique stamp code…',
        hintStyle: GoogleFonts.plusJakartaSans(
          color: _onSurface.withValues(alpha: 0.38),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: _primaryMaroon.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final active = i == _filterIndex;
          final label = _filterLabels[i];
          return FilterChip(
            label: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: active ? Colors.white : _onSurface,
              ),
            ),
            selected: active,
            onSelected: (_) => setState(() => _filterIndex = i),
            backgroundColor: _chipIdle,
            selectedColor: _secondaryContainer,
            checkmarkColor: Colors.white,
            showCheckmark: false,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openReserveSheet() async {
    if (_campaigns.isEmpty || _plans.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaigns or plans are not available right now'),
        ),
      );
      return;
    }

    int? selectedCampaignId = _campaigns.first['id'] is int
        ? _campaigns.first['id'] as int
        : int.tryParse('${_campaigns.first['id']}');
    int? selectedPlanId = _plans.first['id'] is int
        ? _plans.first['id'] as int
        : int.tryParse('${_plans.first['id']}');

    final result = await showModalBottomSheet<(int?, int?)>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) => Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserve stamp',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedCampaignId,
                  decoration: const InputDecoration(labelText: 'Campaign'),
                  items: _campaigns
                      .map((c) => DropdownMenuItem<int>(
                            value: c['id'] is int
                                ? c['id'] as int
                                : int.tryParse('${c['id']}'),
                            child: Text(c['name']?.toString() ??
                                c['reward_name']?.toString() ??
                                c['code']?.toString() ??
                                'Campaign'),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => selectedCampaignId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedPlanId,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: _plans
                      .map((p) => DropdownMenuItem<int>(
                            value: p['id'] is int
                                ? p['id'] as int
                                : int.tryParse('${p['id']}'),
                            child: Text(
                                '${p['name'] ?? 'Plan'} (₹${p['price'] ?? p['amount'] ?? 0})'),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => selectedPlanId = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                        context, (selectedCampaignId, selectedPlanId)),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null || result.$1 == null || result.$2 == null) return;
    await _startReservation(result.$1!, result.$2!);
  }

  Future<void> _startReservation(int campaignId, int planId) async {
    if (_reserving) return;
    setState(() => _reserving = true);
    try {
      final reserveRes = await _api.reserveStamp(campaignId);
      final reserveData = reserveRes.data is Map ? reserveRes.data as Map : {};
      final stamp =
          reserveData['data'] is Map ? reserveData['data'] as Map : {};
      final stampId = stamp['id'] is int
          ? stamp['id'] as int
          : int.tryParse('${stamp['id']}');
      if (stampId == null) throw Exception('Invalid reservation response');

      _pendingStampId = stampId;
      _pendingPlanId = planId;
      final orderRes = await _api.createStampReservationOrder(stampId, planId);
      final body = orderRes.data is Map ? orderRes.data as Map : {};
      final order = body['order'] is Map ? body['order'] as Map : {};
      final key = order['key']?.toString();
      final orderId = order['id']?.toString();
      final amount = order['amount'] is int
          ? order['amount'] as int
          : int.tryParse('${order['amount']}') ?? 0;

      if (key == null ||
          key.isEmpty ||
          orderId == null ||
          orderId.isEmpty ||
          amount <= 0) {
        throw Exception('Invalid payment order for reservation');
      }

      _razorpay.open({
        'key': key,
        'amount': amount.toString(),
        'currency': order['currency'] ?? 'INR',
        'name': order['merchant_name'] ?? 'Kutoot',
        'description': 'Stamp Reservation',
        'order_id': orderId,
        'theme.color': '#AE1E3F',
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reserving = false;
        _pendingStampId = null;
        _pendingPlanId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation failed: $e')),
      );
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final stampId = _pendingStampId;
    final planId = _pendingPlanId;
    if (stampId == null || planId == null) return;

    try {
      final confirmRes = await _api.confirmStampReservation(stampId, {
        'plan_id': planId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
      });
      if (!mounted) return;
      final data = confirmRes.data is Map ? confirmRes.data as Map : {};
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message']?.toString() ?? 'Stamp confirmed successfully',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment done but confirmation failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reserving = false;
          _pendingStampId = null;
          _pendingPlanId = null;
        });
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _reserving = false;
      _pendingStampId = null;
      _pendingPlanId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'Payment failed')),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName ?? '-'}')),
    );
  }
}

class _StampTicketCard extends StatelessWidget {
  final String title;
  final String code;
  final String? imageUrl;

  const _StampTicketCard({
    required this.title,
    required this.code,
    this.imageUrl,
  });

  static const Color _surface = Color(0xFFFFF8F5);
  static const Color _primaryContainer = Color(0xFFAE1E3F);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 102,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Opacity(
                  opacity: 0.28,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: _surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: _surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 58,
              top: -10,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 58,
              bottom: -10,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 72,
              top: 10,
              bottom: 10,
              child: CustomPaint(
                painter: _DottedLinePainter(color: _outlineForTicket),
                size: const Size(2, 82),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AppTheme.logoAsset,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'KUTOOT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 5.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: _primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: 0.2,
                            color: const Color(0xFF221A14),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _primaryContainer.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _primaryContainer.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            code,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _primaryContainer,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryContainer.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color get _outlineForTicket =>
      const Color(0xFFE1BEC0).withValues(alpha: 0.65);
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 4), paint);
      y += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
