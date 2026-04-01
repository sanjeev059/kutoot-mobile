import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

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
    return MaterialApp(
      title: 'KUTOOT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
