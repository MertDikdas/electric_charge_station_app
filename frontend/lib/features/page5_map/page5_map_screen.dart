import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/charger.dart';
import '../../data/models/reservation.dart';
import '../../data/models/station.dart';
import '../../data/models/vehicle.dart';
import '../../data/repositories/station_repository.dart';
import '../../data/services/location_service.dart';
import '../../data/services/reservation_service.dart';
import '../../data/services/vehicle_service.dart';
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
  static const Color _mapActionButtonColor = Color(0xFF0B1F4D);

  static const CameraPosition _fallbackCameraPosition = CameraPosition(
    target: LatLng(38.4237, 27.1428),
    zoom: 14,
  );

  final _locationService = LocationService();
  final _mapCameraService = MapCameraService();
  final _markerBuilder = StationMarkerBuilder();
  final _reservationService = ReservationService();
  final _stationRepository = StationRepository();
  final _vehicleService = VehicleService();

  GoogleMapController? _mapController;
  LatLng? _pendingCameraTarget;
  CameraPosition _initialCameraPosition = _fallbackCameraPosition;
  List<Station> _allStations = const [];
  List<Vehicle> _vehicles = const [];
  Vehicle? _selectedVehicle;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isLoadingVehicles = false;
  bool _isLocationPermissionGranted = false;
  String? _errorMessage;
  bool _isRefreshingMarkers = false;

  @override
  void initState() {
    super.initState();
    _initializeMapPage();
    _loadVehicles();
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
      print("-----------------------------------------");

      final position = LatLng(38.4237, 27.1428);
      final hasUserLocation = locationResult.isGranted && position != null;
      final target = hasUserLocation
          ? LatLng(position.latitude, position.longitude)
          : _fallbackCameraPosition.target;

      if (!mounted) return;
      setState(() {
        _isLocationPermissionGranted = hasUserLocation;
        _initialCameraPosition = CameraPosition(target: target, zoom: 14);
      });

      if (!hasUserLocation) {
        _showLocationPermissionSnackBar(locationResult.message);
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

  Future<void> _loadNearbyStationsFromMapBounds() async {
    final controller = _mapController;

    if (controller == null) return;

    final bounds = await controller.getVisibleRegion();
    final stations;
    if (_selectedVehicle == null) {
      stations = await _stationRepository.fetchNearbyStationsByArea(
        northLatitude: bounds.northeast.latitude,
        southLatitude: bounds.southwest.latitude,
        eastLongitude: bounds.northeast.longitude,
        westLongitude: bounds.southwest.longitude,
      );
    } else {
      stations = await _stationRepository.fetchNearbyStationsByAreaByVehicle(
        northLatitude: bounds.northeast.latitude,
        southLatitude: bounds.southwest.latitude,
        eastLongitude: bounds.northeast.longitude,
        westLongitude: bounds.southwest.longitude,
        vehicleId: _selectedVehicle!.id,
      );
    }

    if (!mounted) return;

    setState(() {
      _allStations = stations;
      _markers = _markerBuilder.buildMarkers(
        stations: stations,
        onMarkerTap: _showStationDetails,
      );
    });
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

    final LatLngBounds bounds;
    try {
      bounds = await _mapCameraService.getVisibleBounds(controller);
    } catch (_) {
      return;
    }

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

      // A light initial filter keeps the first frame from rendering every station
      // before Google Maps reports its exact visible bounds.
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

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
    });

    try {
      final vehicles = await _vehicleService.getMyVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _selectedVehicle ??= vehicles.isEmpty ? null : vehicles.first;
      });
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Araclar yuklenemedi: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVehicles = false;
        });
      }
    }
  }

  Future<void> _showVehiclePicker() async {
    if (_isLoadingVehicles) return;
    if (_vehicles.isEmpty) {
      await _loadVehicles();
    }
    if (!mounted) return;

    if (_vehicles.isEmpty) {
      _showSnackBar('Rezervasyon icin once profilinizden arac ekleyin.');
      return;
    }

    final selected = await showModalBottomSheet<Vehicle>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Text('Arac sec', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final vehicle in _vehicles)
                ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(
                    vehicle.model.isEmpty ? vehicle.plate : vehicle.model,
                  ),
                  subtitle: Text(
                    [
                      vehicle.plate,
                      vehicle.connectorType,
                      vehicle.currentType,
                    ].where((value) => value.trim().isNotEmpty).join(' | '),
                  ),
                  trailing: _selectedVehicle?.id == vehicle.id
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop(vehicle);
                  },
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _selectedVehicle = selected;
    });
    _showSnackBar('${selected.model} rezervasyon araci olarak secildi.');
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
                    const SizedBox(height: 12),
                    _SelectedVehicleTile(
                      vehicle: _selectedVehicle,
                      onSelectPressed: () {
                        Navigator.of(context).pop();
                        _showVehiclePicker();
                      },
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
                                  trailing: FilledButton(
                                    onPressed: _canReserveCharger(charger)
                                        ? () {
                                            Navigator.of(context).pop();
                                            _createReservation(charger);
                                          }
                                        : null,
                                    child: const Text('Reserve'),
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

  bool _canReserveCharger(Charger charger) {
    final vehicle = _selectedVehicle;
    if (vehicle == null) return false;

    final isCompatible =
        vehicle.connectorType == charger.connectorType &&
        vehicle.currentType == charger.currentType;
    final isAvailable = charger.status.toLowerCase().contains('available');

    return isCompatible && isAvailable;
  }

  Future<void> _createReservation(Charger charger) async {
    final vehicle = _selectedVehicle;
    if (vehicle == null) {
      _showSnackBar('Rezervasyon icin once bir arac secin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final slot = _nextReservationSlot();
      await _reservationService.createReservation(
        ReservationInput(
          vehicleId: vehicle.id,
          chargerId: charger.id,
          date: _formatDate(slot.start),
          startTime: _formatTime(slot.start),
          endTime: _formatTime(slot.end),
        ),
      );

      if (!mounted) return;
      _showSnackBar('${vehicle.model} icin rezervasyon olusturuldu.');
      await _reloadStations();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
      _showSnackBar('Rezervasyon olusturulamadi: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  _ReservationSlot _nextReservationSlot() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, now.hour + 1);
    return _ReservationSlot(
      start: start,
      end: start.add(const Duration(hours: 1)),
    );
  }

  String _formatDate(DateTime dateTime) {
    return [
      dateTime.year.toString().padLeft(4, '0'),
      dateTime.month.toString().padLeft(2, '0'),
      dateTime.day.toString().padLeft(2, '0'),
    ].join('-');
  }

  String _formatTime(DateTime dateTime) {
    return [
      dateTime.hour.toString().padLeft(2, '0'),
      dateTime.minute.toString().padLeft(2, '0'),
      '00',
    ].join(':');
  }

  String _formatPrice(double pricePerKwh) {
    if (pricePerKwh <= 0) return 'Price unavailable';
    return '${pricePerKwh.toStringAsFixed(2)} / kWh';
  }

  void _showLocationPermissionSnackBar(String? message) {
    _showSnackBar(
      message ?? 'Location permission is required for nearby stations.',
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
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
            onCameraIdle: _loadNearbyStationsFromMapBounds,
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
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _VehiclePickerButton(
                  backgroundColor: _mapActionButtonColor,
                  foregroundColor: Colors.white,
                  isLoading: _isLoadingVehicles,
                  selectedVehicle: _selectedVehicle,
                  onPressed: _showVehiclePicker,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _StartChargingFab(
        backgroundColor: _mapActionButtonColor,
        foregroundColor: Colors.white,
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

class _ReservationSlot {
  const _ReservationSlot({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _SelectedVehicleTile extends StatelessWidget {
  const _SelectedVehicleTile({
    required this.vehicle,
    required this.onSelectPressed,
  });

  final Vehicle? vehicle;
  final VoidCallback onSelectPressed;

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = vehicle;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        leading: const Icon(Icons.directions_car),
        title: Text(
          selectedVehicle == null
              ? 'Arac secilmedi'
              : selectedVehicle.model.isEmpty
              ? selectedVehicle.plate
              : selectedVehicle.model,
        ),
        subtitle: Text(
          selectedVehicle == null
              ? 'Rezervasyon icin bir arac secin.'
              : [
                  selectedVehicle.plate,
                  selectedVehicle.connectorType,
                  selectedVehicle.currentType,
                ].where((value) => value.trim().isNotEmpty).join(' | '),
        ),
        trailing: TextButton(
          onPressed: onSelectPressed,
          child: const Text('Sec'),
        ),
      ),
    );
  }
}

class _VehiclePickerButton extends StatelessWidget {
  const _VehiclePickerButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isLoading,
    required this.selectedVehicle,
    required this.onPressed,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final Vehicle? selectedVehicle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selectedVehicle == null
          ? 'Arac sec'
          : '${selectedVehicle!.model} secili',
      child: FloatingActionButton(
        heroTag: 'vehicle-picker',
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.directions_car),
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
