import 'package:flutter/material.dart';

import '../services/payment_nudge_service.dart';
import '../theme/app_theme.dart';

/// Dismissible reminder to pay via Kutoot (shown when cooldown allows).
class PaymentNudgeBanner extends StatefulWidget {
  final VoidCallback onScanAndPay;

  const PaymentNudgeBanner({super.key, required this.onScanAndPay});

  @override
  State<PaymentNudgeBanner> createState() => _PaymentNudgeBannerState();
}

class _PaymentNudgeBannerState extends State<PaymentNudgeBanner> {
  bool? _visible;

  @override
  void initState() {
    super.initState();
    PaymentNudgeService.shouldShowBanner().then((v) {
      if (mounted) setState(() => _visible = v);
    });
  }

  Future<void> _dismiss() async {
    await PaymentNudgeService.dismissBannerForCooldown();
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_visible != true) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? [
                      AppTheme.primary.withValues(alpha: 0.35),
                      const Color(0xFF5C1A2E).withValues(alpha: 0.9),
                    ]
                  : [
                      const Color(0xFFFFF1E8),
                      const Color(0xFFFFE4D6),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.savings_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pay with Kutoot at the counter',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Save on fees, earn stamps, and stay in the daily reward draw — scan when you pay.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: context.kutootMutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.tonal(
                          onPressed: widget.onScanAndPay,
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          child: const Text(
                            'Scan & pay',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _dismiss,
                          child: Text(
                            'Later',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: context.kutootMutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: _dismiss,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
