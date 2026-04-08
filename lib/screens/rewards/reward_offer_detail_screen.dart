import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Coupon / instant-offer detail (from Rewards hub list).
class RewardOfferDetailScreen extends StatelessWidget {
  final String brandName;
  final String categoryLabel;
  final String title;
  final String subtitle;
  final String code;
  final Color accentColor;

  const RewardOfferDetailScreen({
    super.key,
    required this.brandName,
    required this.categoryLabel,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFF8F5);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF221A14)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Offer details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF221A14),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                categoryLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              brandName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF221A14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.1,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.4,
                color: const Color(0xFF594042),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'YOUR CODE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFF594042),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFFF5E5DB),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied $code',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          code,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF221A14),
                          ),
                        ),
                      ),
                      const Icon(Icons.copy_rounded, color: Color(0xFFAE1E3F)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Code $code copied',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAE1E3F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'Copy code',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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
