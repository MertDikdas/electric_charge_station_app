import 'package:geolocator/geolocator.dart';

enum LocationPermissionResult { granted, denied, serviceDisabled }

class LocationResult {
  const LocationResult({
    required this.permissionResult,
    this.position,
    this.message,
  });

  final LocationPermissionResult permissionResult;
  final Position? position;
  final String? message;

  bool get isGranted =>
      permissionResult == LocationPermissionResult.granted && position != null;
}

class LocationService {
  Future<LocationResult> requestCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        permissionResult: LocationPermissionResult.serviceDisabled,
        message: 'Location services are disabled.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const LocationResult(
        permissionResult: LocationPermissionResult.denied,
        message: 'Location permission is required for nearby stations.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LocationResult(
      permissionResult: LocationPermissionResult.granted,
      position: position,
    );
  }
}
