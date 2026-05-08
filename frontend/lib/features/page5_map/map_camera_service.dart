import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapCameraService {
  Future<LatLngBounds> getVisibleBounds(GoogleMapController controller) {
    return controller.getVisibleRegion();
  }

  List<T> filterInsideBounds<T>({
    required Iterable<T> items,
    required LatLngBounds bounds,
    required double? Function(T item) latitudeOf,
    required double? Function(T item) longitudeOf,
  }) {
    return items.where((item) {
      final latitude = latitudeOf(item);
      final longitude = longitudeOf(item);
      if (latitude == null || longitude == null) return false;
      return contains(bounds, LatLng(latitude, longitude));
    }).toList(growable: false);
  }

  bool contains(LatLngBounds bounds, LatLng point) {
    final isInsideLatitude =
        point.latitude >= bounds.southwest.latitude &&
        point.latitude <= bounds.northeast.latitude;

    final crossesDateLine =
        bounds.southwest.longitude > bounds.northeast.longitude;
    final isInsideLongitude = crossesDateLine
        ? point.longitude >= bounds.southwest.longitude ||
              point.longitude <= bounds.northeast.longitude
        : point.longitude >= bounds.southwest.longitude &&
              point.longitude <= bounds.northeast.longitude;

    return isInsideLatitude && isInsideLongitude;
  }
}
