import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  final _api = KutootApi();
  List<Map<String, dynamic>> _campaignEntries = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _pushNotifications = true;
  String? _lastPhoneDigits;

  @override
  void initState() {
    super.initState();
    AuthProvider.loadLastLoginMobileDigits().then((d) {
      if (mounted) setState(() => _lastPhoneDigits = d);
    });
    _loadCampaignEntries();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final res = await _api.getTransactions();
      final raw = res.data;
      List items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }
      if (items.isNotEmpty && mounted) {
        setState(() {
          _transactions = items
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        title: const Text(
          'Account',
          style: TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
        ),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                      ? 'Add your number in Edit profile'
                      : (rawPhone.startsWith('+')
                          ? rawPhone
                          : '+91 $rawPhone'));
              final avatarUrl = ImageUtils.resolve(u?['profile_picture_url']);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileEditScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE1BEC0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5E5DB),
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Icon(
                                      Icons.person,
                                      color: AppTheme.primary,
                                      size: 42),
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: AppTheme.primary,
                                      size: 42),
                                )
                              : const Icon(Icons.person,
                                  color: AppTheme.primary, size: 42),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to edit profile',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary.withValues(alpha: 0.85),
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
                              builder: (_) => const ProfileEditScreen()),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A2E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(Icons.person_outline_rounded, size: 22),
                      label: const Text(
                        'Complete your profile',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.confirmation_number_rounded,
            title: 'Stamp collection',
            subtitle: 'Your stamp tickets, search & QR scan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => StampsScreen(cityName: widget.cityName),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.help_outline_rounded,
            title: 'Support & Help',
            subtitle: 'FAQ, ticket history and support requests',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
            ),
          ),
          const SizedBox(height: 10),
          // Push Notifications
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1BEC0)),
            ),
            child: SwitchListTile(
              value: _pushNotifications,
              onChanged: (v) => setState(() => _pushNotifications = v),
              activeColor: AppTheme.primary,
              secondary: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppTheme.primary),
              ),
              title: const Text('Push Notifications',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Deals, stamps & order updates'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Transaction History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (_transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE1BEC0)),
              ),
              child: const Text(
                'No transactions yet. Your payment and reward history will appear here.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ..._transactions.take(5).map((t) => _TransactionTile(txn: t)),
          const SizedBox(height: 14),
          const Text(
            'My Stamp Campaigns',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (_campaignEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE1BEC0)),
              ),
              child: const Text(
                'No campaigns yet. Make a stamped purchase and your campaign entries will appear here.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _campaignEntries.length,
                itemBuilder: (_, i) {
                  final e = _campaignEntries[i];
                  return _CampaignEntryCard(entry: e);
                },
              ),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LogoutConfirmScreen(cityName: widget.cityName),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Delete Account'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBA1A1A),
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
          width: 220,
          margin: const EdgeInsets.only(right: 10),
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
                          color: const Color(0xFFAE1E3F),
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
                        Text(
                          '$progress%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$stamps / $target stamps',
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
                                  ? const Color(0xFFAE1E3F)
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1BEC0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final amount =
        txn['total_amount']?.toString() ?? txn['amount']?.toString() ?? '0';
    final status = txn['payment_status']?.toString() ?? 'pending';
    final type = txn['type']?.toString() ?? '';
    final date = txn['created_at']?.toString().split('T').first ?? '';
    final ml = txn['merchant_location'] is Map
        ? txn['merchant_location'] as Map
        : null;
    final storeName = ml?['branch_name']?.toString() ?? '';
    final isPaid = status == 'paid' || status == 'completed';

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
