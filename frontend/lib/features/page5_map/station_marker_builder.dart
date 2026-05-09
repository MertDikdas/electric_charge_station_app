import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/station.dart';
import '../../data/models/vehicle.dart';

class StationMarkerBuilder {
  Set<Marker> buildMarkers({
    required Iterable<Station> stations,
    required ValueChanged<Station> onMarkerTap,
    Vehicle? selectedVehicle,
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
              _markerHueForStation(
                station: station,
                selectedVehicle: selectedVehicle,
              ),
            ),
            infoWindow: InfoWindow(
              title: 'Station #${station.id}',
              snippet: _availabilityLabel(
                station: station,
                selectedVehicle: selectedVehicle,
              ),
            ),
            onTap: () => onMarkerTap(station),
          ),
        )
        .toSet();
  }

  double _markerHueForStation({
    required Station station,
    Vehicle? selectedVehicle,
  }) {
    if (_isStationUnavailableButVisible(station.status)) {
      debugPrint(
        'Station ${station.id} marker orange: station ${station.status}',
      );
      return BitmapDescriptor.hueOrange;
    }

    if (!_isStationAvailable(station.status)) {
      return BitmapDescriptor.hueRed;
    }

    final compatibleChargers = _compatibleChargers(
      station: station,
      selectedVehicle: selectedVehicle,
    );

    if (compatibleChargers.isEmpty) {
      return BitmapDescriptor.hueRed;
    }

    final allCompatibleChargersUnavailable = compatibleChargers.every(
      (charger) => _isChargerUnavailableButVisible(charger.status),
    );

    if (allCompatibleChargersUnavailable) {
      debugPrint(
        'Station ${station.id} marker orange: all compatible chargers unavailable',
      );
      return BitmapDescriptor.hueOrange;
    }

    final hasAvailableCompatibleCharger = compatibleChargers.any(
      (charger) => _isChargerAvailable(charger),
    );

    return hasAvailableCompatibleCharger
        ? BitmapDescriptor.hueGreen
        : BitmapDescriptor.hueRed;
  }

  String _availabilityLabel({
    required Station station,
    Vehicle? selectedVehicle,
  }) {
    if (_isStationUnavailableButVisible(station.status)) {
      return 'Station is ${station.status}';
    }

    if (!_isStationAvailable(station.status)) {
      return 'Station is unavailable';
    }

    final compatibleChargers = _compatibleChargers(
      station: station,
      selectedVehicle: selectedVehicle,
    );

    if (compatibleChargers.isEmpty) {
      return selectedVehicle == null
          ? 'No charger found'
          : 'No compatible charger';
    }

    final allCompatibleChargersUnavailable = compatibleChargers.every(
      (charger) => _isChargerUnavailableButVisible(charger.status),
    );

    if (allCompatibleChargersUnavailable) {
      return 'Compatible chargers are under maintenance';
    }

    final availableCount = compatibleChargers
        .where((charger) => _isChargerAvailable(charger))
        .length;

    final totalCount = compatibleChargers.length;

    if (availableCount > 0) {
      return '$availableCount/$totalCount compatible charger available';
    }

    return 'Compatible chargers are occupied or reserved';
  }

  List<dynamic> _compatibleChargers({
    required Station station,
    Vehicle? selectedVehicle,
  }) {
    final chargers = station.chargers ?? [];

    if (selectedVehicle == null) {
      return chargers;
    }

    return chargers.where((charger) {
      return charger.connectorType == selectedVehicle.connectorType &&
          charger.currentType == selectedVehicle.currentType;
    }).toList();
  }

  bool _isStationAvailable(String status) {
    final normalized = status.toUpperCase().trim();

    return normalized == 'AVAILABLE' ||
        normalized == 'ACTIVE' ||
        normalized == 'OPEN';
  }

  bool _isStationUnavailableButVisible(String status) {
    final normalized = status.toUpperCase().trim();

    return normalized == 'MAINTENANCE' ||
        normalized == 'CLOSED' ||
        normalized == 'OUT_OF_SERVICE';
  }

  bool _isChargerUnavailableButVisible(String status) {
    final normalized = status.toUpperCase().trim();

    return normalized == 'MAINTENANCE' ||
        normalized == 'OUT_OF_SERVICE' ||
        normalized == 'INACTIVE' ||
        normalized == 'OFFLINE';
  }

  bool _isChargerAvailable(dynamic charger) {
    final chargerStatus = charger.status.toString().toUpperCase().trim();

    final isStatusAvailable =
        chargerStatus == 'AVAILABLE' ||
        chargerStatus == 'FREE' ||
        chargerStatus == 'ACTIVE';

    if (!isStatusAvailable) {
      return false;
    }

    return charger.isReservedNow != true;
  }
}
