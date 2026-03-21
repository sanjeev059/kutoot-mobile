import '../config/env.dart';

/// Resolves image URLs from API responses to full URLs.
/// Handles relative paths and ensures http/https for network loading.
class ImageUtils {
  static String resolve(dynamic url) {
    if (url == null || url.toString().trim().isEmpty) return '';
    final s = url.toString().trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final base = Env.apiBaseUrl.replaceAll(RegExp(r'/api/v1$'), '');
    return s.startsWith('/') ? '$base$s' : '$base/$s';
  }

  /// Extract image URL from various API response shapes.
  static String? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final url = map['image_url'] ?? map['thumb_url'] ?? map['url'] ?? map['preview_url'];
    if (url != null) return resolve(url);
    final media = map['media'];
    if (media is List && media.isNotEmpty) {
      final m = media[0];
      if (m is Map) return resolve(m['url'] ?? m['thumb'] ?? m['preview']);
    }
    final sponsor = map['sponsor_image'];
    if (sponsor is Map) return resolve(sponsor['url'] ?? sponsor['thumb']);
    return null;
  }

  /// From banner/campaign/media object.
  static String? fromBanner(dynamic b) {
    if (b == null) return null;
    if (b is Map) {
      final url = b['image_url'] ?? b['thumb_url'] ?? b['url'] ?? b['preview_url'];
      if (url != null) return resolve(url);
      final media = b['media'];
      if (media is List && media.isNotEmpty && media[0] is Map) {
        final m = media[0] as Map;
        return resolve(m['url'] ?? m['thumb']);
      }
      return fromMap(b['sponsor_image'] is Map ? Map<String, dynamic>.from(b['sponsor_image'] as Map) : null);
    }
    return null;
  }

  /// From merchant/store location (media array or merchant.logo_url).
  static String? fromStore(dynamic store) {
    if (store == null) return null;
    if (store is! Map) return null;
    final media = store['media'];
    if (media is List && media.isNotEmpty && media[0] is Map) {
      final m = media[0] as Map;
      final url = m['url'] ?? m['thumb'];
      if (url != null) return resolve(url);
    }
    final merchant = store['merchant'];
    if (merchant is Map) {
      final logo = merchant['logo_url'];
      if (logo != null) return resolve(logo);
    }
    return null;
  }

  /// From category (image or icon).
  static String? fromCategory(dynamic cat) {
    if (cat == null) return null;
    if (cat is! Map) return null;
    final url = cat['image'] ?? cat['icon'];
    return url != null ? resolve(url) : null;
  }
}
