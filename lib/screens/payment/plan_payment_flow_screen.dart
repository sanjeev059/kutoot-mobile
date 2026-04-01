import 'package:flutter/material.dart';
import '../../services/subscription_plan_service.dart';
import '../../theme/app_theme.dart';
import '../home/kinetic_home_screens.dart';

class PlanPaymentScreen extends StatelessWidget {
  final String planName;
  final String amount;
  final String cityName;

  const PlanPaymentScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F9),
        foregroundColor: AppTheme.primary,
        title: const Text('Payment'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1BEC0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$planName Membership',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Amount: ₹$amount',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E5DB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.credit_card, color: AppTheme.textPrimary),
                          SizedBox(width: 10),
                          Text(
                            'Card •••• 4242',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'UPI Options',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _UpiOption(
                        label: 'Google Pay',
                        icon: Icons.account_balance_wallet),
                    _UpiOption(label: 'PhonePe', icon: Icons.phone_android),
                    _UpiOption(label: 'Paytm', icon: Icons.payment),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await SubscriptionPlanService.setCurrentPlanName(planName);
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PaymentSuccessScreen(
                          planName: planName,
                          amount: amount,
                          cityName: cityName,
                        ),
                      ),
                    );
                  },
                  child: Text('Pay ₹$amount'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PaymentFailureScreen(
                          planName: planName,
                          amount: amount,
                          cityName: cityName,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    foregroundColor: AppTheme.primary,
                  ),
                  child: const Text('Simulate Failure'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final String planName;
  final String amount;
  final String cityName;

  const PaymentSuccessScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F9),
        foregroundColor: AppTheme.primary,
        title: const Text('Payment Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer]),
              ),
              child: const Icon(Icons.check, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Successful',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '₹$amount paid for $planName plan.',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => LoggedInHomeScreen(cityName: cityName),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentFailureScreen extends StatelessWidget {
  final String planName;
  final String amount;
  final String cityName;

  const PaymentFailureScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F9),
        foregroundColor: AppTheme.primary,
        title: const Text('Payment Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer]),
              ),
              child: const Icon(Icons.close, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Declined',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction for ₹$amount failed. Please retry or use another method.',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PlanPaymentScreen(
                        planName: planName,
                        amount: amount,
                        cityName: cityName,
                      ),
                    ),
                  );
                },
                child: const Text('Retry Payment'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpiOption extends StatelessWidget {
  final String label;
  final IconData icon;
  const _UpiOption({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E5DB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textPrimary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
