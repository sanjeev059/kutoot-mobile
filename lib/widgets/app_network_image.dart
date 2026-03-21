import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Displays a network image with placeholder and error fallback to icon.
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackColor;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_rounded,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = fallbackColor ?? AppTheme.primary;
    final placeholder = Container(
      color: color.withOpacity(0.1),
      child: Icon(fallbackIcon, color: color, size: (width ?? height ?? 48) * 0.5),
    );
    final errorWidget = Container(
      color: color.withOpacity(0.15),
      child: Icon(fallbackIcon, color: color, size: (width ?? height ?? 48) * 0.5),
    );

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _wrap(placeholder);
    }

    final child = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => errorWidget,
    );

    return _wrap(child);
  }

  Widget _wrap(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }
}
