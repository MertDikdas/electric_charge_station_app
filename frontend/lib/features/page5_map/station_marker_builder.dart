import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/station.dart';

class StationMarkerBuilder {
  Set<Marker> buildMarkers({
    required Iterable<Station> stations,
    required ValueChanged<Station> onMarkerTap,
  }) {
    return stations
        .where(
          (station) => station.latitude != null && station.longitude != null,
        )
        .map(
          (station) => Marker(
            markerId: MarkerId('station-${station.id}'),
            position: LatLng(station.latitude!, station.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _markerHueForStatus(station.status),
            ),
            infoWindow: InfoWindow(
              title: station.company.isEmpty
                  ? 'Station #${station.id}'
                  : station.company,
              snippet: _availabilityLabel(station.status),
            ),
            onTap: () => onMarkerTap(station),
          ),
        )
        .toSet();
  }

  double _markerHueForStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('available') ||
        normalized.contains('free') ||
        normalized.contains('active')) {
      return BitmapDescriptor.hueGreen;
    }
    if (normalized.contains('occupied') ||
        normalized.contains('busy') ||
        normalized.contains('reserved') ||
        normalized.contains('in_use')) {
      return BitmapDescriptor.hueOrange;
    }
    if (normalized.contains('offline') ||
        normalized.contains('inactive') ||
        normalized.contains('out')) {
      return BitmapDescriptor.hueRed;
    }
    return BitmapDescriptor.hueRed;
  }

  String _availabilityLabel(String status) {
    return status.trim().isEmpty ? 'Unknown availability' : status;
  }
}
