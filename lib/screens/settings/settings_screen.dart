import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../terms/terms_screen.dart';
import '../auth/logout_confirmation_dialog.dart';
import '../auth/delete_account_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('Settings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionTitle('Notifications'),
              _SettingsTile(
                title: 'Push Notifications',
                trailing: Switch(
                  value: settings.pushNotifications,
                  onChanged: (v) => settings.setPushNotifications(v),
                  activeColor: AppTheme.primary,
                ),
              ),
              _SettingsTile(
                title: 'Email Notifications',
                trailing: Switch(
                  value: settings.emailNotifications,
                  onChanged: (v) => settings.setEmailNotifications(v),
                  activeColor: AppTheme.primary,
                ),
              ),
              _SettingsTile(
                title: 'SMS Notifications',
                trailing: Switch(
                  value: settings.smsNotifications,
                  onChanged: (v) => settings.setSmsNotifications(v),
                  activeColor: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Security'),
              _SettingsTile(title: 'Change Password', onTap: () => _showComingSoon(context)),
              _SettingsTile(
                title: 'Biometric Login',
                trailing: Switch(
                  value: settings.biometricLogin,
                  onChanged: (v) => settings.setBiometricLogin(v),
                  activeColor: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Preferences'),
              _SettingsTile(title: 'Language', subtitle: 'English', onTap: () => _showComingSoon(context)),
              _SettingsTile(
                title: 'Dark Mode',
                trailing: Switch(
                  value: settings.darkMode,
                  onChanged: (v) => settings.setDarkMode(v),
                  activeColor: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('About'),
              _SettingsTile(title: 'Privacy Policy', onTap: () => _showComingSoon(context)),
              _SettingsTile(
                title: 'Terms of Service',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Account'),
              _SettingsTile(
                title: 'Delete Account',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await showLogoutConfirmation(context);
                    if (confirm == true && context.mounted) context.read<AuthProvider>().logout();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Log Out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: onSurface)),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 13)) : null,
        trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.7)) : null),
        onTap: onTap,
      ),
    );
  }
}
