import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteDetails {
  const RouteDetails({
    required this.points,
    required this.distanceText,
    required this.durationText,
  });

  final List<LatLng> points;
  final String distanceText;
  final String durationText;
}
