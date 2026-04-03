import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/location_bootstrap_service.dart';
import 'home/kinetic_home_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _logoAsset = 'assets/images/k_logo.png';
  static const String _wordmarkAsset =
      'assets/images/kutoot_spell_transparent.png';
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await Future.wait([
        auth.checkAuth(),
        Future<void>.delayed(const Duration(milliseconds: 3500)),
      ]);
      if (!mounted) return;

      final city = await LocationBootstrapService.ensureFirstLaunchLocation();
      if (!mounted) return;

      final Widget destination = auth.isLoggedIn
          ? LoggedInHomeScreen(cityName: city)
          : GuestHomeScreen(cityName: city);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF9F3EF),
                    Color(0xFFFFF8F5),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 7),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A3B322B),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Image.asset(_logoAsset, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 26),
                Image.asset(
                  _wordmarkAsset,
                  width: 116,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 22),
                const Text(
                  'THE CULINARY CURATOR',
                  style: TextStyle(
                    color: Color(0xFF2D2927),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.8,
                  ),
                ),
                const Spacer(flex: 7),
                const SizedBox(
                  width: 260,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 8, color: Color(0xFFC7A48B)),
                      SizedBox(width: 10),
                      Text(
                        'Fetching your location...',
                        style: TextStyle(
                          color: Color(0xFF4B423D),
                          fontSize: 33 / 3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 314,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      color: const Color(0xFFE5DDD6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final widthFactor =
                                0.22 + (0.18 * _controller.value);
                            return FractionallySizedBox(
                              widthFactor: widthFactor,
                              child: Container(color: const Color(0xFF8A002B)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
