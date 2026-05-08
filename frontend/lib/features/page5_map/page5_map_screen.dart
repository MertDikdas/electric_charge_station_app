import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/charger.dart';
import '../../data/models/station.dart';
import '../../data/repositories/station_repository.dart';
import '../../data/services/location_service.dart';
import '../page6_profile/page6_profile.dart';
import '../page7_reservations/page7_rezervations_screen.dart';
import 'map_camera_service.dart';
import 'station_marker_builder.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _fallbackCameraPosition = CameraPosition(
    target: LatLng(38.4237, 27.1428),
    zoom: 14,
  );

  final _locationService = LocationService();
  final _mapCameraService = MapCameraService();
  final _markerBuilder = StationMarkerBuilder();
  final _stationRepository = StationRepository();

  GoogleMapController? _mapController;
  LatLng? _pendingCameraTarget;
  CameraPosition _initialCameraPosition = _fallbackCameraPosition;
  List<Station> _allStations = const [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isLocationPermissionGranted = false;
  String? _errorMessage;
  bool _isRefreshingMarkers = false;

  @override
  void initState() {
    super.initState();
    _initializeMapPage();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMapPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locationResult = await _locationService.requestCurrentLocation();
      final stations = await _stationRepository.fetchStations();
      print("-----------------------------------------");

      final position = locationResult.position;
      print(position?.latitude);
      print(position?.longitude);
      final hasUserLocation = locationResult.isGranted && position != null;
      final target = hasUserLocation
          ? LatLng(position.latitude, position.longitude)
          : _fallbackCameraPosition.target;

      if (!mounted) return;
      setState(() {
        _allStations = stations;
        _isLocationPermissionGranted = hasUserLocation;
        _initialCameraPosition = CameraPosition(target: target, zoom: 14);
      });

      if (!hasUserLocation) {
        _showSnackBar(
          locationResult.message ??
              'Location permission is required for nearby stations.',
        );
      }

      await _moveCameraAndRefreshMarkers(target);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _moveCameraAndRefreshMarkers(LatLng target) async {
    final controller = _mapController;
    if (controller == null) {
      _pendingCameraTarget = target;
      _refreshMarkersForFallbackViewport(target);
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 14)),
    );
    await _refreshVisibleMarkers();
  }

  Future<void> _refreshVisibleMarkers() async {
    final controller = _mapController;
    if (controller == null || _allStations.isEmpty) return;

    final bounds = await _mapCameraService.getVisibleBounds(controller);
    final visibleStations = _mapCameraService.filterInsideBounds<Station>(
      items: _allStations,
      bounds: bounds,
      latitudeOf: (station) => station.latitude,
      longitudeOf: (station) => station.longitude,
    );

    if (!mounted) return;
    setState(() {
      _markers = _markerBuilder.buildMarkers(
        stations: visibleStations,
        onMarkerTap: _showStationDetails,
      );
    });
  }

  void _refreshMarkersForFallbackViewport(LatLng center) {
    final nearbyStations = _allStations.where((station) {
      final latitude = station.latitude;
      final longitude = station.longitude;
      if (latitude == null || longitude == null) return false;

      // Keeps the first frame light until Google Maps reports exact bounds.
      return (latitude - center.latitude).abs() <= 0.08 &&
          (longitude - center.longitude).abs() <= 0.08;
    });

    setState(() {
      _markers = _markerBuilder.buildMarkers(
        stations: nearbyStations,
        onMarkerTap: _showStationDetails,
      );
    });
  }

  Future<void> _reloadStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stations = await _stationRepository.fetchStations();
      if (!mounted) return;
      setState(() {
        _allStations = stations;
      });
      await _refreshVisibleMarkers();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadStations() => _initializeMapPage();

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatPrice(double value) => '${value.toStringAsFixed(2)} TL/kWh';

  Future<void> _moveCameraAndRefreshMarkers(LatLng target) async {
    final controller = _mapController;
    if (controller == null) {
      _pendingCameraTarget = target;
      return;
    }

    await controller.animateCamera(CameraUpdate.newLatLng(target));
  }

  Future<void> _refreshVisibleMarkers() async {
    if (_isRefreshingMarkers) return;

    final controller = _mapController;
    if (controller == null) return;

    _isRefreshingMarkers = true;

    try {
      final bounds = await _mapCameraService.getVisibleBounds(controller);

      final visibleStations = _mapCameraService.filterInsideBounds<Station>(
        items: _allStations,
        bounds: bounds,
        latitudeOf: (station) => station.latitude,
        longitudeOf: (station) => station.longitude,
      );

      final newMarkers = _markerBuilder.buildMarkers(
        stations: visibleStations,
        onMarkerTap: _showStationDetails,
      );

      if (!mounted) return;

      setState(() {
        _markers = newMarkers;
      });
    } finally {
      _isRefreshingMarkers = false;
    }
  }

  Future<void> _showStationDetails(Station station) async {
    final chargersFuture = _stationRepository.fetchStationChargers(station.id);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: FutureBuilder<List<Charger>>(
              future: chargersFuture,
              builder: (context, snapshot) {
                final chargers = snapshot.data ?? [];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Station #${station.id}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      station.address.isEmpty
                          ? '${station.latitude.toStringAsFixed(5)}, ${station.longitude.toStringAsFixed(5)}'
                          : station.address,
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else if (snapshot.hasError)
                      ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: const Text('Charger listesi yuklenemedi'),
                        subtitle: Text(snapshot.error.toString()),
                      )
                    else if (chargers.isEmpty)
                      const ListTile(
                        leading: Icon(Icons.ev_station),
                        title: Text('Charger bulunamadi'),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: chargers
                              .map(
                                (charger) => ListTile(
                                  leading: const Icon(Icons.ev_station),
                                  title: Text(
                                    '${charger.connectorType} - ${charger.currentType}',
                                  ),
                                  subtitle: Text(
                                    [
                                      charger.status,
                                      '${charger.maxPower.toStringAsFixed(0)} kW',
                                      _formatPrice(charger.pricePerKwh),
                                    ].join(' | '),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatPrice(double pricePerKwh) {
    if (pricePerKwh <= 0) return 'Price unavailable';
    return '${pricePerKwh.toStringAsFixed(2)} / kWh';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            myLocationEnabled: _isLocationPermissionGranted,
            myLocationButtonEnabled: _isLocationPermissionGranted,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;

              final pendingTarget = _pendingCameraTarget;
              if (pendingTarget != null) {
                _pendingCameraTarget = null;
                _moveCameraAndRefreshMarkers(pendingTarget);
              } else {
                _refreshVisibleMarkers();
              }
            },
            onCameraIdle: _refreshVisibleMarkers,
          ),
          if (_isLoading)
            const SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ),
          if (_errorMessage != null && !_isLoading)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _StartChargingFab(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        onPressed: _reloadStations,
      ),
      bottomNavigationBar: _MapBottomAppBar(
        onReservationsPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ReservationsScreen()),
          );
        },
        onProfilePressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          );
        },
      ),
    );
  }
}

class _MapBottomAppBar extends StatelessWidget {
  const _MapBottomAppBar({
    required this.onReservationsPressed,
    required this.onProfilePressed,
  });

  final VoidCallback onReservationsPressed;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: BottomAppBar(
        color: colorScheme.surfaceContainerLow,
        elevation: 10,
        surfaceTintColor: Colors.transparent,
        height: 100,
        notchMargin: 12,
        shape: const AutomaticNotchedShape(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          CircleBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.bookmark_outline,
                  label: 'Reservations',
                  onTap: onReservationsPressed,
                ),
              ),
              const SizedBox(width: 88),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: onProfilePressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkResponse(
      radius: 32,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartChargingFab extends StatelessWidget {
  const _StartChargingFab({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.large(
            onPressed: onPressed,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 10,
            child: const Icon(Icons.refresh, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            'Refresh',
            style: textTheme.labelMedium?.copyWith(
              color: backgroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
