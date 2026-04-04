import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/kinetic_home_screens.dart';
import '../screens/plans/plans_screen.dart';
import '../screens/profile/profile_hub_screen.dart';
import '../screens/rewards/rewards_deals_screen.dart';

class KutootBottomNav extends StatelessWidget {
  final int activeIndex;
  final String cityName;
  final bool isLoggedIn;
  final String planLabel;

  const KutootBottomNav({
    super.key,
    required this.activeIndex,
    required this.cityName,
    required this.isLoggedIn,
    required this.planLabel,
  });

  void _navigate(BuildContext context, int i) {
    if (i == activeIndex) return;

    Widget screen;
    switch (i) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => isLoggedIn
                ? LoggedInHomeScreen(cityName: cityName)
                : GuestHomeScreen(cityName: cityName),
          ),
          (r) => false,
        );
        return;
      case 1:
        screen = RewardsDealsScreen(
          cityName: cityName,
          upgradeLabel: planLabel,
        );
        break;
      case 2:
        if (!isLoggedIn) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          return;
        }
        screen = PlansScreen(cityName: cityName);
        break;
      case 3:
        if (!isLoggedIn) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          return;
        }
        screen = ProfileHubScreen(cityName: cityName, planLabel: planLabel);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 150),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const items = ['HOME', 'DROPS', 'PLANS', 'PROFILE'];
    const icons = [
      Icons.home_rounded,
      Icons.local_offer_rounded,
      Icons.confirmation_num_rounded,
      Icons.person_rounded,
    ];
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final barBg = dark
        ? const Color(0xFF1C1C1C).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.96);
    final barBorder = dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    const accentGreen = Color(0xFF1DB954);

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad > 0 ? bottomPad : 8),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: barBorder),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = activeIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => _navigate(context, i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform:
                          Matrix4.translationValues(0, active ? -4 : 0, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: active
                          ? BoxDecoration(
                              color: dark
                                  ? accentGreen.withValues(alpha: 0.2)
                                  : const Color(0xFFE6F54D)
                                      .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                            )
                          : null,
                      child: Icon(icons[i],
                          color: active
                              ? (dark ? accentGreen : AppTheme.primary)
                              : (dark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF9A9A9A)),
                          size: 24),
                    ),
                    const SizedBox(height: 1),
                    Text(items[i],
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                active ? FontWeight.w900 : FontWeight.w700,
                            color: active
                                ? (dark ? accentGreen : AppTheme.primary)
                                : (dark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF9A9A9A)))),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
