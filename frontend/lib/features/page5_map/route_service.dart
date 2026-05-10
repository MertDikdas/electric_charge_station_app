import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../data/api/api_config.dart';
import 'route_details.dart';

class RouteService {
  RouteService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  final http.Client _httpClient;

  Future<RouteDetails> fetchDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (ApiConfig.googleMapsApiKey.isEmpty) {
      throw const RouteServiceException(
        'Google Maps API key is missing. Add MAPS_API_KEY to your Flutter run configuration.',
      );
    }

    final uri = Uri.parse(_directionsUrl).replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'key': ApiConfig.googleMapsApiKey,
      },
    );

    final response = await _httpClient.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RouteServiceException(
        'Directions service returned ${response.statusCode}.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (body['status'] ?? '').toString();
    if (status != 'OK') {
      final message = (body['error_message'] ?? body['status']).toString();
      throw RouteServiceException('Directions route failed: $message');
    }

    final routes = body['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw const RouteServiceException('No route was found for this station.');
    }

    final route = routes.first as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>? ?? const [];
    if (legs.isEmpty) {
      throw const RouteServiceException('Route details are empty.');
    }

    final leg = legs.first as Map<String, dynamic>;
    final encodedPolyline =
        ((route['overview_polyline'] as Map<String, dynamic>?)?['points'] ?? '')
            .toString();
    if (encodedPolyline.isEmpty) {
      throw const RouteServiceException('Route polyline is empty.');
    }

    final decodedPoints = PolylinePoints.decodePolyline(encodedPolyline);
    final routePoints = decodedPoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);

    if (routePoints.isEmpty) {
      throw const RouteServiceException('Route could not be decoded.');
    }

    return RouteDetails(
      points: routePoints,
      distanceText: _nestedText(leg, 'distance'),
      durationText: _nestedText(leg, 'duration'),
    );
  }

  String _nestedText(Map<String, dynamic> json, String key) {
    return ((json[key] as Map<String, dynamic>?)?['text'] ?? '').toString();
  }
}

class RouteServiceException implements Exception {
  const RouteServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
