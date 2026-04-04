import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationBootstrapService {
  static const String _cityKey = 'kutoot_city_name';
  static const String _defaultCity = 'MUMBAI';

  static Future<String> getCachedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityKey) ?? _defaultCity;
  }

  /// Request app-level location permission (shows the system dialog).
  /// Returns the resulting permission status.
  static Future<LocationPermission> requestAppPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Ensures GPS service is on. Returns true if enabled, false otherwise.
  /// When [promptUser] is true and GPS is off, opens device location settings.
  static Future<bool> ensureGpsEnabled({bool promptUser = true}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled && promptUser) {
      await Geolocator.openLocationSettings();
      // Re-check after user returns from settings
      return Geolocator.isLocationServiceEnabled();
    }
    return enabled;
  }

  /// Fetches the real city and caches it. Falls back to cached/default.
  static Future<String> ensureFirstLaunchLocation() async {
    final city = await _fetchCityOrFallback();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, city);
    return city;
  }

  /// Refresh city from GPS and return the new city name.
  static Future<String> refreshLocation() async {
    final city = await _fetchCityOrFallback();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, city);
    return city;
  }

  static Future<String> _fetchCityOrFallback() async {
    try {
      // Step 1: Check if we have permission (don't re-request here; splash does it)
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return await _cachedOrDefault();
      }

      // Step 2: Check if GPS service is on
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await _cachedOrDefault();
      }

      // Step 3: Get the actual position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return await _cachedOrDefault();
      final locality = placemarks.first.locality?.trim();
      if (locality == null || locality.isEmpty) return await _cachedOrDefault();
      return locality.toUpperCase();
    } catch (_) {
      return await _cachedOrDefault();
    }
  }

  static Future<String> _cachedOrDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityKey) ?? _defaultCity;
  }
}
