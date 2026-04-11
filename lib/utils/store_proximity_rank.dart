import 'dart:math' as math;

/// Ranks stores for "Recommended for you" using live GPS when available.
/// Stores you are physically near (walking distance) surface first — heuristic
/// "AI-style" personalization without a backend model.
const double _hereNowMeters = 120;
const double _unknownDistanceM = 1e12;

double? _readCoord(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v is num) return v.toDouble();
    final d = double.tryParse(v?.toString() ?? '');
    if (d != null) return d;
  }
  return null;
}

double? distanceMetersToStore(
  Map<String, dynamic> store,
  double userLat,
  double userLng,
) {
  final lat = _readCoord(store, ['latitude', 'lat']);
  final lng = _readCoord(store, ['longitude', 'lng', 'long']);
  if (lat == null || lng == null) return null;
  return haversineMeters(userLat, userLng, lat, lng);
}

double haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const r = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _rad(double d) => d * math.pi / 180.0;

/// Parses API labels like "1.2 km", "800 m", "500m away".
double? parseDistanceKmFromLabel(String? raw) {
  if (raw == null) return null;
  final t = raw.trim().toLowerCase().replaceAll(',', '');
  if (t.isEmpty) return null;

  final kmMatch = RegExp(r'([\d.]+)\s*km').firstMatch(t);
  if (kmMatch != null) {
    return double.tryParse(kmMatch.group(1) ?? '');
  }

  final mMatch = RegExp(r'([\d.]+)\s*m(?:\s|$|away|\.|,)', caseSensitive: false)
      .firstMatch(t);
  if (mMatch != null) {
    final meters = double.tryParse(mMatch.group(1) ?? '');
    if (meters != null) return meters / 1000.0;
  }

  final bare = RegExp(r'^([\d.]+)\s*$').firstMatch(t);
  if (bare != null) {
    return double.tryParse(bare.group(1) ?? '');
  }

  return null;
}

/// Returns new list (copies of maps) sorted closest-first; tags [proximity_here_now], [proximity_meters].
List<Map<String, dynamic>> rankStoresForRecommendation(
  List<Map<String, dynamic>> stores, {
  double? userLat,
  double? userLng,
}) {
  if (stores.isEmpty) return stores;

  final enriched = stores.map((s) => Map<String, dynamic>.from(s)).toList();

  for (final s in enriched) {
    s.remove('proximity_here_now');
    s.remove('proximity_meters');
  }

  final ulat = userLat;
  final ulng = userLng;

  double metricFor(Map<String, dynamic> s) {
    if (ulat != null && ulng != null) {
      final m = distanceMetersToStore(s, ulat, ulng);
      if (m != null) return m;
    }
    final km = parseDistanceKmFromLabel(s['distance']?.toString());
    if (km != null) return km * 1000.0;
    return _unknownDistanceM;
  }

  if (ulat != null && ulng != null) {
    for (final s in enriched) {
      final m = distanceMetersToStore(s, ulat, ulng);
      if (m != null) {
        s['proximity_meters'] = m;
        if (m <= _hereNowMeters) {
          s['proximity_here_now'] = true;
        }
      }
    }
  }

  enriched.sort((a, b) {
    final ma = metricFor(a);
    final mb = metricFor(b);
    final ca = a['proximity_here_now'] == true;
    final cb = b['proximity_here_now'] == true;
    if (ca != cb) return cb ? 1 : -1;
    return ma.compareTo(mb);
  });

  return enriched;
}
