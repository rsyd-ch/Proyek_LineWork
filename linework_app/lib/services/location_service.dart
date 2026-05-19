import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static Future<bool> requestPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  static String getAddressFromCoordinates(
      double latitude, double longitude) {
    return 'Lokasi: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
