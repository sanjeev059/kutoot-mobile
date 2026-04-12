import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Return this from [UpiAppSelectScreen] to open full Razorpay (card / NB / wallet).
const String kutootRazorpayFullCheckout = '__kutoot_full__';

/// Pick a UPI PSP before Razorpay opens (intent flow). [packageName] is Android
/// package id; empty string = system UPI chooser.
class UpiAppSelectScreen extends StatefulWidget {
  const UpiAppSelectScreen({
    super.key,
    required this.amountInRupees,
  });

  final double amountInRupees;

  @override
  State<UpiAppSelectScreen> createState() => _UpiAppSelectScreenState();
}

class _UpiOption {
  const _UpiOption({required this.label, required this.package});
  final String label;

  /// Empty = any installed UPI app (intent chooser).
  final String package;
}

class _UpiAppSelectScreenState extends State<UpiAppSelectScreen> {
  static const _options = <_UpiOption>[
    _UpiOption(
      label: 'Google Pay',
      package: 'com.google.android.apps.nbu.paisa.user',
    ),
    _UpiOption(
      label: 'PhonePe',
      package: 'com.phonepe.app',
    ),
    _UpiOption(
      label: 'Paytm',
      package: 'net.one97.paytm',
    ),
    _UpiOption(
      label: 'BHIM UPI',
      package: 'in.org.npci.upiapp',
    ),
    _UpiOption(
      label: 'Any UPI app',
      package: '',
    ),
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final amt = widget.amountInRupees.toStringAsFixed(2);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'Pay with UPI',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Choose how you want to pay ₹$amt',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: List.generate(_options.length, (i) {
                final o = _options[i];
                return RadioListTile<int>(
                  value: i,
                  groupValue: _selected,
                  onChanged: (v) => setState(() => _selected = v ?? 0),
                  activeColor: AppTheme.primary,
                  title: Text(
                    o.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: o.package.isEmpty
                      ? const Text(
                          'Opens the system picker for installed UPI apps',
                          style: TextStyle(fontSize: 12),
                        )
                      : null,
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, kutootRazorpayFullCheckout),
            child: const Text(
              'Pay with card, netbanking or wallet instead',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context, _options[_selected].package);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Pay ₹$amt',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
