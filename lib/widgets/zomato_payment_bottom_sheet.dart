import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/payment/upi_app_select_screen.dart';
import '../services/upi_apps_android.dart';
import '../theme/app_theme.dart';

/// Zomato-style payment picker: detected UPI apps + Razorpay fallbacks.
///
/// Returns:
/// - Android package name for Razorpay UPI intent
/// - `''` = system chooser / any UPI app
/// - [kutootRazorpayFullCheckout] for hosted checkout (cards, NB, wallet, UPI ID)
/// - `null` if dismissed
Future<String?> showZomatoPaymentBottomSheet(
  BuildContext context, {
  required double amountInRupees,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ZomatoPaymentSheetBody(amountInRupees: amountInRupees),
  );
}

class _ZomatoPaymentSheetBody extends StatefulWidget {
  const _ZomatoPaymentSheetBody({required this.amountInRupees});
  final double amountInRupees;

  @override
  State<_ZomatoPaymentSheetBody> createState() => _ZomatoPaymentSheetBodyState();
}

class _ZomatoPaymentSheetBodyState extends State<_ZomatoPaymentSheetBody> {
  List<UpiInstalledApp> _apps = const [];
  bool _loading = true;
  String? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await UpiAppsAndroid.listInstalled();
    if (!mounted) return;
    const priority = [
      'com.phonepe.app',
      'com.google.android.apps.nbu.paisa.user',
      'net.one97.paytm',
      'in.org.npci.upiapp',
    ];
    list.sort((a, b) {
      final ia = priority.indexOf(a.packageName);
      final ib = priority.indexOf(b.packageName);
      if (ia == -1 && ib == -1) return 0;
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    });
    if (!mounted) return;
    setState(() {
      _apps = list;
      _loading = false;
      if (_apps.isNotEmpty) {
        _selectedPackage = _apps.first.packageName;
      }
    });
  }

  IconData _iconForPackage(String pkg) {
    if (pkg.contains('nbu.paisa')) return Icons.account_balance_wallet;
    if (pkg.contains('phonepe')) return Icons.payments;
    if (pkg.contains('paytm')) return Icons.payment;
    if (pkg.contains('npci') || pkg.contains('bhim')) return Icons.smartphone;
    return Icons.touch_app;
  }

  @override
  Widget build(BuildContext context) {
    final amt = widget.amountInRupees.toStringAsFixed(0);
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Payment options',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pay ₹$amt securely',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _loading
                ? const Padding(
                    key: ValueKey('loading'),
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                : Column(
                    key: const ValueKey('content'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'RECOMMENDED',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_apps.isEmpty)
                        Text(
                          'No UPI apps detected. Use Razorpay below or install Google Pay / PhonePe.',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        )
                      else
                        ...List.generate(_apps.length, (i) {
                          final a = _apps[i];
                          final sel = _selectedPackage == a.packageName;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Material(
                              color: sel
                                  ? cs.primaryContainer.withValues(alpha: 0.35)
                                  : cs.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(
                                    () => _selectedPackage = a.packageName),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(_iconForPackage(a.packageName),
                                          color: AppTheme.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              a.packageName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        sel
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: sel
                                            ? AppTheme.primary
                                            : cs.outline,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 12),
                      Text(
                        'OTHER OPTIONS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _OtherTile(
                        icon: Icons.apps,
                        title: 'Any UPI app',
                        subtitle: 'System chooser',
                        onTap: () => Navigator.pop(context, ''),
                      ),
                      _OtherTile(
                        icon: Icons.alternate_email,
                        title: 'UPI ID / number',
                        subtitle: 'Pay with VPA in Razorpay',
                        onTap: () => Navigator.pop(
                            context, kutootRazorpayFullCheckout),
                      ),
                      _OtherTile(
                        icon: Icons.credit_card,
                        title: 'Cards, net banking & wallets',
                        subtitle: 'Razorpay secure checkout',
                        onTap: () => Navigator.pop(
                            context, kutootRazorpayFullCheckout),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          if (!_loading && _apps.isNotEmpty)
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _selectedPackage ?? ''),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Continue with selected app',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          if (!_loading && _apps.isEmpty && !kIsWeb) ...[
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, kutootRazorpayFullCheckout),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Open Razorpay checkout',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OtherTile extends StatelessWidget {
  const _OtherTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
