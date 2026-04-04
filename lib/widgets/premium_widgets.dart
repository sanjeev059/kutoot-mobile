import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

// ─── Shimmer Loading Placeholders ────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E0DA),
      highlightColor:
          isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F0EC),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({super.key, this.width = double.infinity, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: width, height: height, radius: 6);
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: double.infinity, height: height, radius: 16),
          const SizedBox(height: 10),
          const ShimmerLine(width: 180),
          const SizedBox(height: 6),
          const ShimmerLine(width: 120, height: 12),
        ],
      ),
    );
  }
}

class ShimmerStoreCard extends StatelessWidget {
  const ShimmerStoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 160, height: 110, radius: 14),
          const SizedBox(height: 8),
          const ShimmerLine(width: 120, height: 13),
          const SizedBox(height: 4),
          ShimmerLine(width: 80, height: 11),
        ],
      ),
    );
  }
}

class ShimmerCategoryRow extends StatelessWidget {
  const ShimmerCategoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              const ShimmerBox(width: 52, height: 52, radius: 26),
              const SizedBox(height: 6),
              ShimmerLine(width: 40, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerListLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerListLoader({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => ShimmerCard(height: itemHeight),
      ),
    );
  }
}

// ─── Scale-on-Press (Bounce Tap) ─────────────────────────────────────────────

class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final bool enableHaptic;

  const BounceTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.enableHaptic = true,
  });

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (widget.enableHaptic) HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─── Glassmorphism Card ──────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 16,
    this.opacity = 0.15,
    this.borderRadius = 20,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── Premium Page Transitions ────────────────────────────────────────────────

class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  PremiumPageRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}

Route<T> premiumRoute<T>(Widget page) => PremiumPageRoute<T>(page: page);

// ─── Section Header ──────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (actionText != null)
            BounceTap(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    actionText!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppTheme.primary.withValues(alpha: 0.8)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButton;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.primary.withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Icon(icon,
                  size: 40, color: AppTheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 24),
              BounceTap(
                onTap: onButton,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    buttonText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Animated Counter ────────────────────────────────────────────────────────

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        v.toInt().toString(),
        style: style ??
            const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
      ),
    );
  }
}
