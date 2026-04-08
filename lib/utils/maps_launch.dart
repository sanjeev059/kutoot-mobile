import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps for a store map or search query.
Future<bool> openStoreInMaps(Map<String, dynamic> store) async {
  final lat = store['latitude'] ?? store['lat'];
  final lng = store['longitude'] ?? store['lng'] ?? store['long'];
  final la = lat is num
      ? lat.toDouble()
      : double.tryParse(lat?.toString() ?? '');
  final ln = lng is num
      ? lng.toDouble()
      : double.tryParse(lng?.toString() ?? '');
  Uri uri;
  if (la != null && ln != null) {
    uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${la.toStringAsFixed(6)},${ln.toStringAsFixed(6)}');
  } else {
    final parts = <String>[
      store['branch_name']?.toString() ?? '',
      store['name']?.toString() ?? '',
      store['address']?.toString() ?? '',
      store['city']?.toString() ?? '',
      store['area']?.toString() ?? '',
    ].where((s) => s.trim().isNotEmpty).join(', ');
    final q = Uri.encodeComponent(parts.isEmpty ? 'Store' : parts);
    uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
  }
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
