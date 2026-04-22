import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  StreamSubscription<Position>? _positionSubscription;

  /// Get current location with automatic permission request
  Future<Position?> getCurrentLocation({bool requestPermission = true}) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        if (requestPermission) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            return null;
          }
        } else {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get location permission status details
  Future<Map<String, dynamic>> getLocationStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    return {
      'serviceEnabled': serviceEnabled,
      'permission': permission.toString(),
      'hasPermission':
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always,
      'isDenied': permission == LocationPermission.denied,
      'isDeniedForever': permission == LocationPermission.deniedForever,
    };
  }

  /// Open app settings for location permission
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Watch position updates
  Stream<Position>? watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) {
    try {
      _positionSubscription?.cancel();

      final stream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      );

      // Return broadcast stream so multiple listeners can subscribe
      return stream.asBroadcastStream();
    } catch (e) {
      return null;
    }
  }

  /// Check location permission status
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Calculate distance between two coordinates (in meters)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Reverse geocode coordinates into address and district details.
  Future<Map<String, String?>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return {'address': null, 'district': null};
      }

      final place = placemarks.first;
      final addressParts = <String>[
        if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
        if ((place.subLocality ?? '').trim().isNotEmpty)
          place.subLocality!.trim(),
        if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
        if ((place.country ?? '').trim().isNotEmpty) place.country!.trim(),
      ];

      final district =
          (place.subAdministrativeArea ?? '').trim().isNotEmpty
              ? place.subAdministrativeArea!.trim()
              : (place.administrativeArea ?? '').trim().isNotEmpty
              ? place.administrativeArea!.trim()
              : (place.locality ?? '').trim().isNotEmpty
              ? place.locality!.trim()
              : null;

      return {
        'address': addressParts.isEmpty ? null : addressParts.join(', '),
        'district': district,
      };
    } catch (_) {
      return {'address': null, 'district': null};
    }
  }

  /// Dispose resources
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
