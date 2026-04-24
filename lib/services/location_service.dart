// lib/services/location_service.dart
// LOCAL RESOURCE 4: GPS / Geolocation
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double lat;
  final double lng;
  const LocationResult({required this.lat, required this.lng});
}

class LocationService {
  static Future<LocationResult?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return LocationResult(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) return null;
      return LocationResult(lat: last.latitude, lng: last.longitude);
    }
  }

  static String formatCoords(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°';
}
