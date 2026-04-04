import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'contact_support_screen.dart';
import '../home/kinetic_home_screens.dart';
import '../../services/location_bootstrap_service.dart';

class TicketSubmittedScreen extends StatelessWidget {
  const TicketSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Ticket Submitted!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('We\'ll get back to you soon.',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ContactSupportScreen())),
                  child: const Text('Back to Support'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final city =
                        await LocationBootstrapService.getCachedCity();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LoggedInHomeScreen(cityName: city),
                      ),
                      (r) => false,
                    );
                  },
                  child: const Text('Go to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
