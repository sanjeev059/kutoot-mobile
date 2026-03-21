import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _api = KutootApi();
  List<dynamic> _coupons = [];
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
      final res = await _api.getCoupons();
      final data = res.data;
      if (data is Map && data['data'] != null) {
        _coupons = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        _coupons = data;
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
        title: const Text('My Coupons', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
              : _coupons.isEmpty
                  ? const Center(child: Text('No coupons yet'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _coupons.length,
                        itemBuilder: (context, i) {
                          final c = _coupons[i] is Map ? _coupons[i] as Map : {};
                          return _CouponCard(
                            coupon: c,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CouponDetailScreen(couponId: c['id'] ?? 0, coupon: c),
                              ),
                            ).then((_) => _load()),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Map coupon;
  final VoidCallback onTap;

  const _CouponCard({required this.coupon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = coupon['name'] ?? coupon['title'] ?? 'Coupon';
    final desc = coupon['description'] ?? coupon['value'] ?? '';
    final status = coupon['status'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_offer_rounded, color: AppTheme.primary, size: 28),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: desc.isNotEmpty ? Text(desc.toString(), maxLines: 2, overflow: TextOverflow.ellipsis) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class CouponDetailScreen extends StatefulWidget {
  final int couponId;
  final Map coupon;

  const CouponDetailScreen({super.key, required this.couponId, required this.coupon});

  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends State<CouponDetailScreen> {
  final _api = KutootApi();
  Map<String, dynamic>? _coupon;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _coupon = Map<String, dynamic>.from(widget.coupon);
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.getCoupon(widget.couponId);
      if (res.data is Map && mounted) {
        setState(() {
          _coupon = Map<String, dynamic>.from(res.data as Map);
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _coupon ?? {};
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Coupon', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'] ?? c['title'] ?? 'Coupon',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            if ((c['description'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(c['description'].toString(), style: const TextStyle(color: AppTheme.textSecondary)),
                            ],
                            if ((c['value'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text('Value: ${c['value']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                            if ((c['code'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Code: ${c['code']}', style: const TextStyle(fontFamily: 'monospace')),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'To redeem, show this coupon at the store or use the redeem flow.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
    );
  }
}
