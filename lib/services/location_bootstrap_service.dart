import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationBootstrapService {
  static const String _cityKey = 'kutoot_city_name';
  static const String _initializedKey = 'kutoot_location_initialized';
  static const String _defaultCity = 'MUMBAI';

  static Future<String> getCachedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityKey) ?? _defaultCity;
  }

  static Future<String> ensureFirstLaunchLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyInitialized = prefs.getBool(_initializedKey) ?? false;
    if (alreadyInitialized) {
      return prefs.getString(_cityKey) ?? _defaultCity;
    }

    final city = await _fetchCityOrFallback();
    await prefs.setString(_cityKey, city);
    await prefs.setBool(_initializedKey, true);
    return city;
  }

  static Future<String> _fetchCityOrFallback() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _defaultCity;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _defaultCity;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return _defaultCity;
      final locality = placemarks.first.locality?.trim();
      if (locality == null || locality.isEmpty) return _defaultCity;
      return locality.toUpperCase();
    } catch (_) {
      return _defaultCity;
    }
  }
}
