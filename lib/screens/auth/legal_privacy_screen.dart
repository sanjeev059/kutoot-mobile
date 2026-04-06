import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'legal_terms_screen.dart';

class LegalPrivacyScreen extends StatelessWidget {
  const LegalPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 56,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE1BEC0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEGAL NOTICE',
                          style: TextStyle(
                            color: AppTheme.accentWarm,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.7,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F2F9),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child:
                          const Icon(Icons.close, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x14E1BEC0)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                children: [
                  const Text(
                    'At The Culinary Curator, we handle your data with transparency and care. This policy explains how and why we collect account and usage data.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _BlockTitle(
                      icon: Icons.storage_rounded,
                      color: AppTheme.primary,
                      title: 'Data Collection'),
                  const SizedBox(height: 12),
                  const _InfoCard(
                    label: 'IDENTITY',
                    title: 'Profile Details',
                    body:
                        'We collect name, mobile number and preferences to personalize your experience.',
                    leftBorderColor: AppTheme.primary,
                  ),
                  const SizedBox(height: 10),
                  const _InfoCard(
                    label: 'BEHAVIOR',
                    title: 'App Activity',
                    body:
                        'Interactions and feature usage help us improve discovery and offer relevance.',
                    leftBorderColor: AppTheme.accentWarm,
                  ),
                  const SizedBox(height: 20),
                  _BlockTitle(
                      icon: Icons.verified_user_rounded,
                      color: AppTheme.accentWarm,
                      title: 'Your Rights'),
                  const SizedBox(height: 10),
                  const _RightRow(
                      icon: Icons.visibility_rounded,
                      title: 'Right to Access',
                      body:
                          'Request a copy of your stored information at any time.'),
                  const _RightRow(
                      icon: Icons.edit_rounded,
                      title: 'Right to Rectification',
                      body:
                          'Update or correct your personal information when needed.'),
                  const _RightRow(
                      icon: Icons.delete_outline_rounded,
                      title: 'Right to Erasure',
                      body:
                          'Request deletion of your account and related data.'),
                  const SizedBox(height: 22),
                  _BlockTitle(
                      icon: Icons.lock_rounded,
                      color: AppTheme.tertiary,
                      title: 'Data Security'),
                  const SizedBox(height: 10),
                  const Text(
                    'Sensitive data is encrypted in transit and protected in secure infrastructure with routine audits.',
                    style:
                        TextStyle(color: AppTheme.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _ChipLabel('AES-256 ENCRYPTION'),
                      _ChipLabel('GDPR COMPLIANT'),
                      _ChipLabel('2FA READY'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0x14E1BEC0))),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const LegalTermsScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.textPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text('I Understand'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Last Updated: October 2023',
                    style: TextStyle(
                      color: Color(0x99594042),
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  const _BlockTitle(
      {required this.icon, required this.color, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String title;
  final String body;
  final Color leftBorderColor;
  const _InfoCard({
    required this.label,
    required this.title,
    required this.body,
    required this.leftBorderColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2F9),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: leftBorderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: leftBorderColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class _RightRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _RightRow(
      {required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E5DB),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(icon, size: 20, color: AppTheme.accentWarm),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String text;
  const _ChipLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E5DB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
