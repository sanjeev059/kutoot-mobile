import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/location_bootstrap_service.dart';
import '../services/notification_service.dart';
import 'home/kinetic_home_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _logoAsset = 'assets/images/k_logo.png';
  static const String _wordmarkAsset =
      'assets/images/kutoot_spell_transparent.png';
  late final AnimationController _controller;
  late final AnimationController _logoController;
  late final AnimationController _wordmarkController;
  late final Animation<double> _logoScale;
  late final Animation<double> _wordmarkOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _wordmarkController,
        curve: Curves.easeIn,
      ),
    );

    _logoController.forward();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _wordmarkController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();

      // Run auth check and splash delay in parallel
      await Future.wait([
        auth.checkAuth(),
        Future<void>.delayed(const Duration(milliseconds: 3500)),
      ]);
      if (!mounted) return;

      // Step 1: Request APP permission (shows "Allow while using app" dialog)
      final permission =
          await LocationBootstrapService.requestAppPermission();
      if (!mounted) return;

      // Step 2: If permission granted, ensure GPS is turned on
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await LocationBootstrapService.ensureGpsEnabled();
        if (!mounted) return;
      } else if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        if (!mounted) return;
      }

      // Step 3: Fetch actual location (will use GPS if available, else fallback)
      final city =
          await LocationBootstrapService.ensureFirstLaunchLocation();
      if (!mounted) return;

      NotificationService().setCityName(city);

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
    _logoController.dispose();
    _wordmarkController.dispose();
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
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 168,
                          height: 168,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFFFD700)
                                    .withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.3),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Container(
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
                          child:
                              Image.asset(_logoAsset, fit: BoxFit.contain),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _wordmarkOpacity,
                  child: Image.asset(
                    _wordmarkAsset,
                    width: 116,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'THE FUTURE OF LOCAL COMMERCE',
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
