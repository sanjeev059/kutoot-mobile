import 'package:flutter/material.dart';
import '../../services/location_bootstrap_service.dart';
import '../home/kinetic_home_screens.dart';
import '../../theme/app_theme.dart';

class LegalTermsScreen extends StatelessWidget {
  const LegalTermsScreen({super.key});

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
                          'LEGAL FRAMEWORK',
                          style: TextStyle(
                            color: AppTheme.accentWarm,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.7,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Terms & Conditions',
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
                    onPressed: () => Navigator.pop(context),
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
                children: const [
                  _SectionHeader(
                    icon: Icons.verified_rounded,
                    color: AppTheme.primary,
                    title: 'Acceptance of Terms',
                  ),
                  SizedBox(height: 10),
                  Text(
                    'By using Kutoot, you agree to platform rules and periodic updates made to keep the service secure and reliable.',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        height: 1.45),
                  ),
                  SizedBox(height: 18),
                  _TermsCard(
                    icon: Icons.person_pin_circle_outlined,
                    iconColor: AppTheme.accentWarm,
                    title: 'User Responsibilities',
                    body:
                        'Provide accurate information and maintain confidentiality of your account.',
                  ),
                  SizedBox(height: 10),
                  _TermsCard(
                    icon: Icons.shield_outlined,
                    iconColor: AppTheme.tertiary,
                    title: 'Data Privacy',
                    body:
                        'We protect your personal and transaction data using secure storage and transport.',
                  ),
                  SizedBox(height: 20),
                  _SectionHeader(
                    icon: Icons.block_rounded,
                    color: Color(0xFFBA1A1A),
                    title: 'Prohibited Activities',
                  ),
                  SizedBox(height: 10),
                  _BulletText(
                      'Scraping or commercial reuse of content without permission.'),
                  _BulletText(
                      'Impersonating Kutoot staff or partner merchants.'),
                  _BulletText(
                      'Any malicious activity that affects app performance or integrity.'),
                  SizedBox(height: 20),
                  _DarkInfoCard(),
                  SizedBox(height: 14),
                  Text(
                    'Last Updated: October 24, 2024',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0x99594042),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
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
                      onPressed: () async {
                        final city =
                            await LocationBootstrapService.getCachedCity();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) =>
                                  LoggedInHomeScreen(cityName: city)),
                          (route) => false,
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  const _SectionHeader(
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

class _TermsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  const _TermsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
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

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppTheme.primary),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkInfoCard extends StatelessWidget {
  const _DarkInfoCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intellectual Property',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          SizedBox(height: 6),
          Text(
            'All reviews, curation copy, and creative assets are owned by Kutoot and may not be reproduced without permission.',
            style:
                TextStyle(color: Color(0xCCFEEEE3), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
