import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../auth/login_screen.dart';
import '../location/location_permission_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _api = KutootApi();
  int _currentPage = 0;
  bool _loading = true;

  List<_OnboardingPage> _pages = [];

  static const _fallbackPages = [
    _OnboardingPage(title: 'Welcome to Kutoot', subtitle: 'Discover deals, earn stamps and win rewards.', icon: Icons.people_rounded, buttonText: 'Get Started', showSkip: false),
    _OnboardingPage(title: 'Pay In Store', subtitle: 'Scan QR and get instant discounts.', icon: Icons.qr_code_scanner_rounded, buttonText: 'Continue', showSkip: true),
    _OnboardingPage(title: 'Earn Stamps and Win Rewards', subtitle: 'Collect stamps at your favorite stores and unlock rewards.', icon: Icons.card_giftcard_rounded, buttonText: 'Next', showSkip: true),
    _OnboardingPage(title: 'Discover Nearby Stores', subtitle: 'Find local shops and support your community.', icon: Icons.store_rounded, buttonText: 'Next', showSkip: true),
  ];

  static const _iconMap = <String, IconData>{
    'people': Icons.people_rounded,
    'qr_code': Icons.qr_code_scanner_rounded,
    'gift': Icons.card_giftcard_rounded,
    'store': Icons.store_rounded,
    'star': Icons.star_rounded,
    'location': Icons.location_on_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadOnboarding();
  }

  Future<void> _loadOnboarding() async {
    try {
      final res = await _api.getOnboarding();
      if (mounted && res.data is Map) {
        final d = (res.data as Map)['data'];
        if (d is List && d.isNotEmpty) {
          setState(() {
            _pages = d.asMap().entries.map((e) {
              final p = e.value is Map ? e.value as Map : {};
              return _OnboardingPage(
                title: (p['title'] ?? '').toString(),
                subtitle: (p['description'] ?? p['subtitle'] ?? '').toString(),
                icon: _iconMap[p['icon']] ?? Icons.info_rounded,
                imageUrl: (p['image'] ?? p['image_url'] ?? '').toString(),
                buttonText: e.key == 0 ? 'Get Started' : 'Next',
                showSkip: e.key > 0,
              );
            }).toList();
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _pages = _fallbackPages.toList();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<OnboardingProvider>().markSeen();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LocationPermissionScreen(),
        ),
      );
    }
  }

  void _onSkip() {
    context.read<OnboardingProvider>().markSeen();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPermissionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (_pages[_currentPage].showSkip)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _onSkip,
                  child: Text('Skip', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (p.imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(p.imageUrl, width: 200, height: 200, fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(24)),
                                child: Icon(p.icon, size: 64, color: AppTheme.primary),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(p.icon, size: 64, color: AppTheme.primary),
                          ),
                        const SizedBox(height: 40),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppTheme.primary : AppTheme.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _onNext,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: Text(_pages[_currentPage].buttonText),
                    ),
                  ),
                  if (_currentPage == 2) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text('Already have an account? Sign In'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final String imageUrl;
  final String buttonText;
  final bool showSkip;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imageUrl = '',
    required this.buttonText,
    required this.showSkip,
  });
}
