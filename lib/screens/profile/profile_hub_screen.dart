import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../api/kutoot_api.dart';
import '../../providers/auth_provider.dart';
import '../../services/campaign_entry_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../widgets/kutoot_bottom_nav.dart';
import '../auth/delete_account_screen.dart';
import '../auth/logout_confirm_screen.dart';
import '../support/contact_support_screen.dart';
import '../support/my_tickets_screen.dart';
import '../support/support_faq_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../stamps/stamps_screen.dart';

class ProfileHubScreen extends StatefulWidget {
  final String cityName;

  const ProfileHubScreen({
    super.key,
    required this.cityName,
  });

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

/// Stitch export `code.html` — profile / warm surface palette.
class _StitchProfile {
  static const Color primary = Color(0xFFAE1E3F);
  static const Color surface = Color(0xFFFFF8F5);
  static const Color onSurface = Color(0xFF221A14);
  static const Color onSurfaceVariant = Color(0xFF594042);
  static const Color outlineVariant = Color(0xFFE1BEC0);
  static const Color outline = Color(0xFF8D7072);
  static const Color tertiary = Color(0xFF725C00);
  static const Color secondary = Color(0xFFA04100);
  static const Color secondaryContainer = Color(0xFFFF7A2E);
  static const Color tertiaryContainer = Color(0xFFCDA700);
  static const Color onTertiaryContainer = Color(0xFF4D3E00);
  static const Color surfaceContainerLow = Color(0xFFFFF1E8);
  static const Color surfaceContainerHigh = Color(0xFFF5E5DB);
  static const Color error = Color(0xFFBA1A1A);

  static TextStyle jakarta(TextStyle base) =>
      GoogleFonts.plusJakartaSans(textStyle: base);
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  final _api = KutootApi();
  List<Map<String, dynamic>> _campaignEntries = [];
  Map<String, dynamic>? _subscription;
  bool _pushNotifications = true;
  String? _lastPhoneDigits;

  @override
  void initState() {
    super.initState();
    AuthProvider.loadLastLoginMobileDigits().then((d) {
      if (mounted) setState(() => _lastPhoneDigits = d);
    });
    _loadCampaignEntries();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final res = await _api.getCurrentSubscription();
      final body = res.data;
      Map<String, dynamic>? data;
      if (body is Map) {
        final d = body['data'];
        if (d is Map) {
          data = Map<String, dynamic>.from(d);
        } else if (body['plan'] is Map || body['subscription'] is Map) {
          data = Map<String, dynamic>.from(
            (body['subscription'] ?? body) as Map,
          );
        }
      }
      if (mounted) setState(() => _subscription = data);
    } catch (_) {
      if (mounted) setState(() => _subscription = null);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTransactionMaps() async {
    try {
      final res = await _api.getTransactions();
      final raw = res.data;
      List items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadCampaignEntries() async {
    List<Map<String, dynamic>> items = [];
    try {
      final response = await _api.getProfileCampaignEntries();
      final body = response.data;
      if (body is Map && body['data'] is List) {
        items = (body['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      items = await CampaignEntryService.getEntries();
    }

    if (items.isEmpty) {
      items = await CampaignEntryService.getEntries();
    }
    if (!mounted) return;
    setState(() => _campaignEntries = items);
  }

  String _subscriptionPlanTitle() {
    final s = _subscription;
    if (s == null) return 'Free';
    final plan = s['plan'];
    if (plan is Map) {
      final n = plan['name']?.toString() ?? plan['title']?.toString();
      if (n != null && n.isNotEmpty) return n;
    }
    final n = s['plan_name']?.toString() ?? s['name']?.toString();
    if (n != null && n.isNotEmpty) return n;
    return 'Premium Plan';
  }

  String _subscriptionExpirySubtitle() {
    final s = _subscription;
    if (s == null) {
      return 'Upgrade for more benefits';
    }
    final exp = s['expires_at'] ?? s['ends_at'] ?? s['valid_until'];
    if (exp == null) return 'Active subscription';
    final str = exp.toString();
    final datePart = str.split('T').first;
    return 'Active until $datePart';
  }

  bool _userShowsVipBadge(Map<String, dynamic>? u) {
    if (u == null) return false;
    final plan = _subscriptionPlanTitle().toUpperCase();
    if (plan.contains('VIP') || plan.contains('ELITE')) return true;
    final roles = u['roles'];
    if (roles is List) {
      for (final r in roles) {
        final name = r is Map
            ? r['name']?.toString().toUpperCase()
            : r.toString().toUpperCase();
        if (name != null &&
            (name.contains('VIP') || name.contains('ELITE'))) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _StitchProfile.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56 + topInset),
        child: _StitchProfileAppBar(
          topInset: topInset,
          cityName: widget.cityName,
          onUpgrade: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => StampsScreen(cityName: widget.cityName),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12 + 56 + topInset, 16, 100),
        children: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final u = auth.user;
              final rawName = u?['name']?.toString().trim() ?? '';
              final name = rawName.isNotEmpty ? rawName : 'Member';
              var rawPhone = u?['mobile']?.toString().trim() ??
                  u?['phone']?.toString().trim() ??
                  '';
              if (rawPhone.isEmpty &&
                  _lastPhoneDigits != null &&
                  _lastPhoneDigits!.length == 10) {
                rawPhone = _lastPhoneDigits!;
              }
              var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
              if (digits.startsWith('91') && digits.length == 12) {
                digits = digits.substring(2);
              }
              final phone = digits.length == 10
                  ? '+91 $digits'
                  : (rawPhone.isEmpty
                      ? 'Add your number'
                      : (rawPhone.startsWith('+')
                          ? rawPhone
                          : '+91 $rawPhone'));
              final email = u?['email']?.toString().trim() ?? '';
              final avatarUrl = ImageUtils.resolve(u?['profile_picture_url']);
              final showVip = _userShowsVipBadge(u);

              return _StitchProfileHeader(
                name: name,
                phone: phone,
                email: email,
                avatarUrl: avatarUrl,
                showVipBadge: showVip,
                onEditProfile: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileEditScreen(),
                  ),
                ),
              );
            },
          ),
          if (context.watch<AuthProvider>().user != null) ...[
            Builder(
              builder: (context) {
                final u = context.watch<AuthProvider>().user;
                final rawName = u?['name']?.toString().trim() ?? '';
                final incomplete = rawName.isEmpty ||
                    rawName.startsWith('User ') ||
                    (u?['mobile']?.toString().trim().isEmpty ?? true);
                if (!incomplete) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _StitchProfile.secondaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon:
                          const Icon(Icons.person_outline_rounded, size: 22),
                      label: Text(
                        'Complete your profile',
                        style: _StitchProfile.jakarta(
                          const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
          _StitchWelcomeCouponCard(
            onCopied: () {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: const Text('Code WELCOME50 copied'),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _StitchOutlineCtaTile(
            icon: Icons.receipt_long_rounded,
            title: 'Transaction History',
            subtitle: 'View recent spends & savings',
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => _TransactionHistoryPage(
                  load: _fetchTransactionMaps,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StitchSubscriptionCard(
            planTitle: _subscriptionPlanTitle(),
            expiryLine: _subscriptionExpirySubtitle(),
            onUpgrade: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => StampsScreen(cityName: widget.cityName),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Stamps',
                  style: _StitchProfile.jakarta(
                    const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _StitchProfile.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => StampsScreen(cityName: widget.cityName),
                  ),
                ),
                child: Text(
                  'View All',
                  style: _StitchProfile.jakarta(
                    const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _StitchProfile.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_campaignEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _StitchProfile.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _StitchProfile.primary.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                'No stamp campaigns yet. Pay at partner stores to earn stamps.',
                style: _StitchProfile.jakarta(
                  const TextStyle(
                    color: _StitchProfile.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _StitchProfile.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _StitchProfile.primary.withValues(alpha: 0.08),
                ),
              ),
              child: SizedBox(
                height: 288,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _campaignEntries.length,
                  itemBuilder: (_, i) {
                    return _CampaignEntryCard(entry: _campaignEntries[i]);
                  },
                ),
              ),
            ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SETTINGS & NOTIFICATIONS',
              style: _StitchProfile.jakarta(
                TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: _StitchProfile.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          _StitchNotificationsCard(
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SUPPORT & HELP',
              style: _StitchProfile.jakarta(
                TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: _StitchProfile.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          _StitchSupportCard(
            onFaq: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SupportFaqScreen(),
              ),
            ),
            onTickets: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const MyTicketsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _StitchNeedAssistanceCard(
            onGetSupport: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ContactSupportScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: _StitchProfile.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LogoutConfirmScreen(cityName: widget.cityName),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        color: _StitchProfile.onSurface),
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: _StitchProfile.jakarta(
                        const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _StitchProfile.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
            ),
            icon: Icon(Icons.delete_forever_outlined,
                color: _StitchProfile.error.withValues(alpha: 0.7)),
            label: Text(
              'DELETE ACCOUNT',
              style: _StitchProfile.jakarta(
                TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: _StitchProfile.error.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: KutootBottomNav(
        activeIndex: 2,
        cityName: widget.cityName,
        isLoggedIn: true,
      ),
    );
  }
}

// ─── Stitch `code.html` widgets ───────────────────────────────────────────

class _StitchProfileAppBar extends StatelessWidget {
  final double topInset;
  final String cityName;
  final VoidCallback onUpgrade;

  const _StitchProfileAppBar({
    required this.topInset,
    required this.cityName,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: EdgeInsets.only(top: topInset, left: 20, right: 20),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF612500).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF612500).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 16, color: _StitchProfile.secondaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      '$cityName ▾',
                      style: _StitchProfile.jakarta(
                        const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: _StitchProfile.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Image.asset(
                    AppTheme.logoAsset,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              TextButton(
                onPressed: onUpgrade,
                style: TextButton.styleFrom(
                  backgroundColor: _StitchProfile.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'UPGRADE',
                  style: _StitchProfile.jakarta(
                    const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StitchProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String avatarUrl;
  final bool showVipBadge;
  final VoidCallback onEditProfile;

  const _StitchProfileHeader({
    required this.name,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    required this.showVipBadge,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: _StitchProfile.surfaceContainerHigh,
                            child: const Icon(Icons.person,
                                color: _StitchProfile.primary, size: 44),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: _StitchProfile.surfaceContainerHigh,
                            child: const Icon(Icons.person,
                                color: _StitchProfile.primary, size: 44),
                          ),
                        )
                      : Container(
                          color: _StitchProfile.surfaceContainerHigh,
                          child: const Icon(Icons.person,
                              color: _StitchProfile.primary, size: 44),
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _StitchProfile.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: _StitchProfile.jakarta(
                          const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: _StitchProfile.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (showVipBadge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _StitchProfile.tertiaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'VIP',
                          style: _StitchProfile.jakarta(
                            const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: _StitchProfile.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: _StitchProfile.jakarta(
                    const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _StitchProfile.onSurfaceVariant,
                    ),
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: _StitchProfile.jakarta(
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _StitchProfile.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(
                    'Edit Profile',
                    style: _StitchProfile.jakarta(
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _StitchProfile.primary,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _StitchProfile.primary,
                    side: const BorderSide(color: _StitchProfile.outline),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StitchWelcomeCouponCard extends StatelessWidget {
  final VoidCallback onCopied;

  const _StitchWelcomeCouponCard({required this.onCopied});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(const ClipboardData(text: 'WELCOME50'));
          onCopied();
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _StitchProfile.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _StitchProfile.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPECIAL OFFER',
                          style: _StitchProfile.jakarta(
                            TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.2,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '50% OFF',
                          style: _StitchProfile.jakarta(
                            const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              height: 1.05,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'First Redemption',
                          style: _StitchProfile.jakarta(
                            TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _StitchProfile.primary.withValues(alpha: 0.22),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'WELCOME50',
                          style: _StitchProfile.jakarta(
                            const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: _StitchProfile.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'TAP TO COPY',
                        style: _StitchProfile.jakarta(
                          TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: -10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: _StitchProfile.surface,
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
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: _StitchProfile.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -24,
              right: -24,
              child: IgnorePointer(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StitchOutlineCtaTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StitchOutlineCtaTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _StitchProfile.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _StitchProfile.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _StitchProfile.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _StitchProfile.jakarta(
                        const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _StitchProfile.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: _StitchProfile.jakarta(
                        const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _StitchProfile.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: _StitchProfile.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _StitchSubscriptionCard extends StatelessWidget {
  final String planTitle;
  final String expiryLine;
  final VoidCallback onUpgrade;

  const _StitchSubscriptionCard({
    required this.planTitle,
    required this.expiryLine,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _StitchProfile.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _StitchProfile.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.card_membership_rounded,
                    color: _StitchProfile.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planTitle,
                      style: _StitchProfile.jakarta(
                        const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _StitchProfile.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      expiryLine.startsWith('Upgrade')
                          ? expiryLine
                          : expiryLine.toUpperCase(),
                      style: _StitchProfile.jakarta(
                        const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: _StitchProfile.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: _StitchProfile.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: _StitchProfile.primary.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'UPGRADE NOW',
                style: _StitchProfile.jakarta(
                  const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StitchNotificationsCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _StitchNotificationsCard({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _StitchProfile.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: _StitchProfile.primary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB2B8).withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_active_rounded,
              color: _StitchProfile.primary, size: 20),
        ),
        title: Text(
          'Push Notifications',
          style: _StitchProfile.jakarta(
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _StitchProfile.onSurface,
            ),
          ),
        ),
        subtitle: Text(
          'Alerts for order updates',
          style: _StitchProfile.jakarta(
            const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _StitchProfile.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _StitchSupportCard extends StatelessWidget {
  final VoidCallback onFaq;
  final VoidCallback onTickets;

  const _StitchSupportCard({
    required this.onFaq,
    required this.onTickets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _StitchProfile.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFaq,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDC206).withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.help_rounded,
                          color: _StitchProfile.tertiary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Read FAQs',
                        style: _StitchProfile.jakarta(
                          const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _StitchProfile.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: _StitchProfile.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
          Divider(
              height: 1,
              color: _StitchProfile.outlineVariant.withValues(alpha: 0.35)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTickets,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _StitchProfile.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_edu_rounded,
                          color: _StitchProfile.onSurface, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ticket History',
                        style: _StitchProfile.jakarta(
                          const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _StitchProfile.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: _StitchProfile.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StitchNeedAssistanceCard extends StatelessWidget {
  final VoidCallback onGetSupport;

  const _StitchNeedAssistanceCard({required this.onGetSupport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _StitchProfile.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Assistance?',
            style: _StitchProfile.jakarta(
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: _StitchProfile.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Questions about stamps or payments?',
            style: _StitchProfile.jakarta(
              const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _StitchProfile.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGetSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _StitchProfile.primary,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: _StitchProfile.primary.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Get Support',
                style: _StitchProfile.jakarta(
                  const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionHistoryPage extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() load;

  const _TransactionHistoryPage({required this.load});

  @override
  State<_TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<_TransactionHistoryPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final items = await widget.load();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _StitchProfile.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        title: Text(
          'Transaction History',
          style: _StitchProfile.jakarta(
            const TextStyle(
              fontWeight: FontWeight.w800,
              color: _StitchProfile.onSurface,
            ),
          ),
        ),
        foregroundColor: _StitchProfile.onSurface,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _reload,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.35,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No transactions yet. Your payment history will appear here.',
                            textAlign: TextAlign.center,
                            style: _StitchProfile.jakarta(
                              const TextStyle(
                                color: _StitchProfile.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: _items
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _TransactionTile(txn: t),
                              ))
                          .toList(),
                    ),
            ),
    );
  }
}

class _CampaignEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _CampaignEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final name = entry['campaign_name']?.toString() ?? 'Campaign';
    final store = entry['store_name']?.toString() ?? 'Store';
    final stamps = _readInt(entry['stamps_earned']) ?? 0;
    final target = (_readInt(entry['stamp_target']) ?? 10).clamp(1, 99);
    final progress =
        _progressPercent(stamps, target, entry['progress_percent']);
    final priceText = _priceLabel(entry);
    final imageUrl = ImageUtils.resolve(entry['image_url']);
    final tag =
        (entry['tag']?.toString().toUpperCase().trim().isNotEmpty ?? false)
            ? entry['tag'].toString().toUpperCase()
            : 'ENTERED';
    final activeBars = ((progress / 10).round()).clamp(1, 10);

    return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 288,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5E5DB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1BEC0)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackImage(),
                      )
                    : _fallbackImage(),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.84),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: tag == 'ENTERED'
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 18,
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _StitchProfile.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (priceText.isNotEmpty)
                      Text(
                        priceText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROGRESS',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w800,
                                fontSize: 8,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '$progress%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '$stamps Stamps Earned',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(10, (index) {
                        final isActive = index < activeBars;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: index == 9 ? 0 : 2),
                            height: 3,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _StitchProfile.primary
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  static Widget _fallbackImage() {
    return Container(
      color: const Color(0xFFFBECE1),
      child: const Center(
        child: Icon(Icons.emoji_events_rounded,
            color: Color(0xFFCDA700), size: 42),
      ),
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static int _progressPercent(int stamps, int target, dynamic progressValue) {
    final parsed = _readInt(progressValue);
    if (parsed != null) return parsed.clamp(0, 100);
    return ((stamps / target) * 100).round().clamp(0, 100);
  }

  static String _priceLabel(Map<String, dynamic> entry) {
    final value = entry['campaign_reward_cost'] ?? entry['bill_amount'];
    if (value == null) return '';
    final n =
        value is num ? value.toDouble() : double.tryParse(value.toString());
    if (n == null || n <= 0) return '';
    final text = n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
    return '₹$text';
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _TransactionTile({required this.txn});

  static String _normPaymentStatus(dynamic raw) {
    if (raw == null) return 'pending';
    if (raw is String) return raw.toLowerCase();
    if (raw is Map) {
      final v = raw['value'] ?? raw['name'];
      if (v != null) return v.toString().toLowerCase();
    }
    return raw.toString().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final amount =
        txn['total_amount']?.toString() ?? txn['amount']?.toString() ?? '0';
    final statusRaw = txn['payment_status'];
    final status = _normPaymentStatus(statusRaw);
    final type = txn['type']?.toString() ?? '';
    final date = txn['created_at']?.toString().split('T').first ?? '';
    final ml = txn['merchant_location'] is Map
        ? txn['merchant_location'] as Map
        : null;
    final storeName = ml?['branch_name']?.toString() ?? '';
    final isPaid = status == 'paid' || status == 'completed';
    final stampsRaw = txn['stamps'];
    final stampCount =
        stampsRaw is List ? stampsRaw.length : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFE1BEC0).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isPaid ? const Color(0xFF2E7D32) : AppTheme.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              type.contains('plan')
                  ? Icons.card_membership
                  : Icons.receipt_long,
              color: isPaid ? const Color(0xFF2E7D32) : AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName.isNotEmpty
                      ? storeName
                      : (type.contains('plan') ? 'Plan Purchase' : 'Payment'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(date,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
                if (isPaid && stampCount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.stars,
                          size: 12, color: AppTheme.tertiary.withValues(alpha: 0.9)),
                      const SizedBox(width: 4),
                      Text(
                        '$stampCount stamp${stampCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppTheme.tertiary.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹$amount',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isPaid
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFEA6B1E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
