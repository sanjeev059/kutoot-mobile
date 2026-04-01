import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../auth/signup_screen.dart';

class LocationPermissionScreen extends StatelessWidget {
  final VoidCallback? onAllow;
  final VoidCallback? onSkip;

  const LocationPermissionScreen({super.key, this.onAllow, this.onSkip});

  void _goToSignUp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.location_on_rounded,
                    size: 64, color: AppTheme.primary),
              ),
              const SizedBox(height: 40),
              const Text(
                'Enable Location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We need your location to find nearby deals and rewards.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onAllow?.call();
                    _goToSignUp(context);
                  },
                  child: const Text('Allow Location'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  onSkip?.call();
                  _goToSignUp(context);
                },
                child: Text('Skip for now',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
