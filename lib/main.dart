import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In release, log but don't crash - helps diagnose production issues
      debugPrint('FlutterError: ${details.exception}');
    }
  };
  runZonedGuarded(() {
    runApp(const KutootApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

class KutootApp extends StatelessWidget {
  const KutootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Kutoot',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppRouter(),
          );
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OnboardingProvider>(
      builder: (context, auth, onboarding, _) {
        if (!auth.hasChecked) {
          return const SplashScreen();
        }
        if (auth.isLoggedIn) {
          return const HomeScreen();
        }
        if (onboarding.loading) {
          return const SplashScreen();
        }
        if (!onboarding.hasSeen) {
          return const OnboardingScreen();
        }
        return const SignUpScreen();
      },
    );
  }
}
