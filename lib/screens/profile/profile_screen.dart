import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../providers/auth_provider.dart';
import '../auth/logout_confirmation_dialog.dart';
import 'profile_edit_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../wallet/wallet_screen.dart';
import '../transactions/transactions_screen.dart';
import '../payment/payment_methods_screen.dart';
import '../notifications/notifications_screen.dart';
import '../support/contact_support_screen.dart';
import '../settings/settings_screen.dart';
import '../coupons/coupons_screen.dart';
import '../stamps/stamps_screen.dart';
import '../stamps/stamp_history_screen.dart';
import '../refer/refer_earn_screen.dart';
import '../terms/terms_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?['name'] ?? 'Alex Rivers';
    final email = user?['email'] ?? user?['mobile'] ?? '';
    final avatarUrl = user != null ? ImageUtils.resolve(user['profile_picture_url']) : null;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('Profile', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                hasAvatar
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _avatarFallback(name),
                          errorWidget: (_, __, ___) => _avatarFallback(name),
                        ),
                      )
                    : _avatarFallback(name),
                const SizedBox(height: 12),
                Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (email.isNotEmpty)
                  Text(email, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _StatChip(label: 'Life Rewards', value: '24'),
                    SizedBox(width: 28),
                    _StatChip(label: 'Total Coupons', value: '5'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileTile(icon: Icons.edit, title: 'Edit Profile', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()))),
          _ProfileTile(icon: Icons.card_membership, title: 'Subscription', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()))),
          _ProfileTile(icon: Icons.account_balance_wallet, title: 'e-Gift Balance', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
          _ProfileTile(icon: Icons.receipt_long, title: 'Transaction History', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()))),
          _ProfileTile(icon: Icons.bookmark, title: 'Saved Items', onTap: () => _showComingSoon(context)),
          _ProfileTile(icon: Icons.credit_card, title: 'Payment Methods', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
          _ProfileTile(icon: Icons.notifications, title: 'Notifications', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          _ProfileTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactSupportScreen()))),
          _ProfileTile(icon: Icons.local_offer, title: 'My Coupons', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsScreen()))),
          _ProfileTile(icon: Icons.star, title: 'My Stamps', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StampsScreen()))),
          _ProfileTile(icon: Icons.history, title: 'Stamp History', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StampHistoryScreen()))),
          _ProfileTile(icon: Icons.card_giftcard, title: 'Refer & Earn', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferEarnScreen()))),
          _ProfileTile(icon: Icons.description, title: 'Terms of Service', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()))),
          _ProfileTile(icon: Icons.settings, title: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          const SizedBox(height: 10),
          _ProfileTile(
            icon: Icons.logout,
            title: 'Logout',
            isDestructive: true,
            onTap: () async {
              final confirm = await showLogoutConfirmation(context);
              if (confirm == true && context.mounted) {
                context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppTheme.primary.withOpacity(0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 36, color: AppTheme.primary),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileTile({required this.icon, required this.title, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final iconColor = isDestructive ? Colors.red : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDestructive ? Border.all(color: Colors.red.withOpacity(0.2), width: 1.3) : null,
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : onSurface)),
        trailing: Icon(Icons.chevron_right_rounded, color: isDestructive ? Colors.red.withOpacity(0.7) : onSurface.withOpacity(0.65)),
        onTap: onTap,
      ),
    );
  }
}
