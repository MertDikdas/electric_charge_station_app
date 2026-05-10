import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/charger.dart';
import '../../data/models/reservation.dart';
import '../../data/models/station.dart';
import '../../data/models/vehicle.dart';
import '../../data/models/charging_session.dart';
import '../../data/repositories/station_repository.dart';
import '../../data/services/location_service.dart';
import '../../data/services/reservation_service.dart';
import '../../data/services/vehicle_service.dart';
import '../../data/services/charging_session_service.dart';
import '../page6_profile/page6_profile.dart';
import '../page7_reservations/page7_rezervations_screen.dart';
import '../notifications/in_app_notification_controller.dart';
import '../notifications/notification_panel.dart';
import 'map_camera_service.dart';
import 'route_details.dart';
import 'route_service.dart';
import 'station_details_bottom_sheet.dart';
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
  final _chargingSessionService = ChargingSessionService();
  final _locationService = LocationService();
  final _mapCameraService = MapCameraService();
  final _markerBuilder = StationMarkerBuilder();
  final _reservationService = ReservationService();
  final _routeService = RouteService();
  final _stationRepository = StationRepository();
  final _vehicleService = VehicleService();

  StreamSubscription<Position>? _positionSubscription;
  String? _mapStyle;
  GoogleMapController? _mapController;
  LatLng? _pendingCameraTarget;
  CameraPosition _initialCameraPosition = _fallbackCameraPosition;
  LatLng? _currentUserLocation;
  Marker? _userLocationMarker;
  DateTime? _lastCameraFollowAt;
  int? _selectedStationId;
  RouteDetails? _activeRouteDetails;
  int? _activeRouteStationId;
  List<Station> _allStations = const [];
  List<Vehicle> _vehicles = const [];
  Vehicle? _selectedVehicle;
  Set<Marker> _stationMarkers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _isLoadingVehicles = false;
  bool _isLocationPermissionGranted = false;
  bool _isRouteLoading = false;
  bool _isNavigationModeEnabled = false;
  String? _errorMessage;
  ChargingSession? _activeChargingSession;
  bool _isSessionLoading = false;
  List<ChargingSession> _sessionHistory = const [];

  Set<Marker> get _mapMarkers => {..._stationMarkers, ?_userLocationMarker};

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initializeMapPage();
    _loadVehicles();
    _loadActiveChargingSession();
    _loadSessionHistory();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadSessionHistory() async {
    try {
      final sessions = await _chargingSessionService.getSessions();

      if (!mounted) return;

      setState(() {
        _sessionHistory = sessions;
      });
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Session history yuklenemedi: $error');
    }
  }

  Future<void> _showSessionHistorySheet() async {
    await _loadSessionHistory();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _SessionHistorySheetContent(sessions: _sessionHistory),
          ),
        );
      },
    );
  }

  Future<void> _loadActiveChargingSession() async {
    try {
      final session = await _chargingSessionService.getActiveSession();

      if (!mounted) return;

      setState(() {
        _activeChargingSession = session;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _activeChargingSession = null;
      });
    }
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_styles/map.json');

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeMapPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locationResult = await _locationService.requestCurrentLocation();
      final position = locationResult.position;
      final hasUserLocation = locationResult.isGranted && position != null;
      final target = hasUserLocation
          ? LatLng(position.latitude, position.longitude)
          : _fallbackCameraPosition.target;

      if (!mounted) return;
      setState(() {
        _isLocationPermissionGranted = hasUserLocation;
        _currentUserLocation = hasUserLocation ? target : null;
        _initialCameraPosition = CameraPosition(target: target, zoom: 14);
        if (position != null) {
          _userLocationMarker = _buildUserMarker(position);
        }
      });

      if (!hasUserLocation) {
        _showLocationPermissionSnackBar(locationResult.message);
      } else {
        await _startLiveLocationTracking();
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

    final List<Station> stations;

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

    final markers = await _markerBuilder.buildMarkers(
      stations: stations,
      selectedVehicle: _selectedVehicle,
      selectedStationId: _selectedStationId,
      onMarkerTap: _showStationDetails,
    );

    if (!mounted) return;

    setState(() {
      _allStations = stations;
      _stationMarkers = markers;
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

    final markers = await _markerBuilder.buildMarkers(
      stations: visibleStations,
      selectedVehicle: _selectedVehicle,
      selectedStationId: _selectedStationId,
      onMarkerTap: _showStationDetails,
    );

    if (!mounted) return;

    setState(() {
      _stationMarkers = markers;
    });
  }

  Future<void> _refreshMarkersForFallbackViewport(LatLng center) async {
    final nearbyStations = _allStations.where((station) {
      final latitude = station.latitude;
      final longitude = station.longitude;

      return (latitude - center.latitude).abs() <= 0.08 &&
          (longitude - center.longitude).abs() <= 0.08;
    });

    final markers = await _markerBuilder.buildMarkers(
      stations: nearbyStations,
      selectedVehicle: _selectedVehicle,
      selectedStationId: _selectedStationId,
      onMarkerTap: _showStationDetails,
    );

    if (!mounted) return;

    setState(() {
      _stationMarkers = markers;
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
    await _refreshVisibleMarkers();
  }

  Future<void> _showStationDetails(Station station) async {
    final bottomSheetColor = Theme.of(context).colorScheme.surface;

    setState(() {
      _selectedStationId = station.id;
    });
    await _refreshVisibleMarkers();

    if (!mounted) return;
    final chargersFuture = _stationRepository.fetchStationChargers(station.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StationDetailsBottomSheet(
          station: station,
          chargersFuture: chargersFuture,
          selectedVehicle: _selectedVehicle,
          distanceText: _distanceFromUserText(station),
          initialRouteDetails: _activeRouteStationId == station.id
              ? _activeRouteDetails
              : null,
          onRoutePressed: () => _drawRouteToStation(station),
          onReserveCharger: (charger) {
            Navigator.of(context).pop();
            _createReservation(charger);
          },
          onSelectVehiclePressed: () {
            Navigator.of(context).pop();
            _showVehiclePicker();
          },
          formatPrice: _formatPrice,
          canReserveCharger: _canReserveCharger,
        );
      },
    );
  }

  Future<RouteDetails?> _drawRouteToStation(Station station) async {
    if (_isRouteLoading) return _activeRouteDetails;

    final controller = _mapController;
    if (controller == null) {
      _showSnackBar('Map is still loading. Please try again.');
      return null;
    }

    setState(() {
      _isRouteLoading = true;
      _errorMessage = null;
    });

    try {
      final origin = await _resolveRouteOrigin();
      final destination = LatLng(station.latitude, station.longitude);
      final details = await _routeService.fetchDrivingRoute(
        origin: origin,
        destination: destination,
      );

      if (!mounted) return null;

      final routePoints = [origin, ...details.points, destination];
      final routeDetails = RouteDetails(
        points: routePoints,
        distanceText: details.distanceText,
        durationText: details.durationText,
      );

      setState(() {
        _selectedStationId = station.id;
        _activeRouteStationId = station.id;
        _activeRouteDetails = routeDetails;
        _isNavigationModeEnabled = true;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('active-route'),
            points: routePoints,
            color: Colors.blue,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
      });

      await _fitCameraToRoute(routePoints);
      await _refreshVisibleMarkers();
      await _startLiveLocationTracking(followCamera: true);
      return routeDetails;
    } catch (error) {
      if (!mounted) return null;
      _showSnackBar('Route could not be created: $error');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isRouteLoading = false;
        });
      }
    }
  }

  Future<LatLng> _resolveRouteOrigin() async {
    final locationResult = await _locationService.requestCurrentLocation();
    final position = locationResult.position;
    if (locationResult.isGranted && position != null) {
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _isLocationPermissionGranted = true;
        _currentUserLocation = location;
      });
      return location;
    }

    _showLocationPermissionSnackBar(locationResult.message);
    return _currentUserLocation ?? _fallbackCameraPosition.target;
  }

  Future<void> _centerOnCurrentLocation() async {
    final location = _currentUserLocation;
    if (location == null) {
      await _startLiveLocationTracking(followCamera: true);
      return;
    }

    await _animateCameraToUser(location, zoom: 17, force: true);
  }

  Future<void> _toggleNavigationMode() async {
    final enabled = !_isNavigationModeEnabled;
    setState(() {
      _isNavigationModeEnabled = enabled;
    });

    if (enabled) {
      await _startLiveLocationTracking(followCamera: true);
      final location = _currentUserLocation;
      if (location != null) {
        await _animateCameraToUser(location, zoom: 17, force: true);
      }
      return;
    }

    _showSnackBar('Navigation follow disabled.');
  }

  Future<void> _cancelNavigation() async {
    setState(() {
      _isNavigationModeEnabled = false;
      _selectedStationId = null;
      _activeRouteDetails = null;
      _activeRouteStationId = null;
      _polylines = {};
      _lastCameraFollowAt = null;
    });

    await _refreshVisibleMarkers();
    _showSnackBar('Navigation cancelled');
  }

  Future<void> _startLiveLocationTracking({bool followCamera = false}) async {
    final locationResult = await _locationService.requestCurrentLocation();
    final position = locationResult.position;

    if (!locationResult.isGranted || position == null) {
      if (!mounted) return;
      setState(() {
        _isLocationPermissionGranted = false;
        _isNavigationModeEnabled = false;
      });
      _showLocationPermissionSnackBar(locationResult.message);
      return;
    }

    _updateUserPosition(position, animateCamera: followCamera);

    await _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 6,
          ),
        ).listen(
          (position) {
            _updateUserPosition(
              position,
              animateCamera: _isNavigationModeEnabled,
            );
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _isNavigationModeEnabled = false;
            });
            _showSnackBar('Live location could not be updated: $error');
          },
        );
  }

  void _updateUserPosition(Position position, {required bool animateCamera}) {
    if (!mounted) return;

    final location = LatLng(position.latitude, position.longitude);
    setState(() {
      _isLocationPermissionGranted = true;
      _currentUserLocation = location;
      _userLocationMarker = _buildUserMarker(position);
    });

    if (animateCamera) {
      _animateCameraToUser(location, bearing: position.heading);
    }
  }

  Marker _buildUserMarker(Position position) {
    final heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : 0.0;

    return Marker(
      markerId: const MarkerId('live-user-location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      anchor: const Offset(0.5, 0.5),
      flat: true,
      rotation: heading,
      zIndexInt: 10,
      infoWindow: const InfoWindow(title: 'You'),
    );
  }

  Future<void> _animateCameraToUser(
    LatLng location, {
    double? bearing,
    double zoom = 17,
    bool force = false,
  }) async {
    final controller = _mapController;
    if (controller == null) return;

    final now = DateTime.now();
    final lastFollowAt = _lastCameraFollowAt;
    if (!force &&
        lastFollowAt != null &&
        now.difference(lastFollowAt) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastCameraFollowAt = now;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: zoom,
          tilt: _isNavigationModeEnabled ? 45 : 0,
          bearing: bearing != null && bearing.isFinite && bearing >= 0
              ? bearing
              : 0,
        ),
      ),
    );
  }

  Future<void> _fitCameraToRoute(List<LatLng> routePoints) async {
    final controller = _mapController;
    if (controller == null || routePoints.isEmpty) return;

    final bounds = _boundsForLatLngs(routePoints);
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }

  LatLngBounds _boundsForLatLngs(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  String _distanceFromUserText(Station station) {
    final origin = _currentUserLocation;
    if (origin == null) return 'Location needed';

    final meters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      station.latitude,
      station.longitude,
    );

    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
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

  Future<void> _openNotificationPanel() async {
    final controller = InAppNotificationScope.of(context);
    await controller.refresh(showNewNotifications: false);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => InAppNotificationScope(
        controller: controller,
        child: const FractionallySizedBox(
          heightFactor: 0.78,
          child: NotificationPanel(),
        ),
      ),
    );
  }

  Future<void> _toggleChargingSession() async {
    if (_isSessionLoading) return;

    setState(() {
      _isSessionLoading = true;
      _errorMessage = null;
    });

    try {
      if (_activeChargingSession == null) {
        final session = await _chargingSessionService.startSession();

        if (!mounted) return;
        setState(() {
          _activeChargingSession = session;
        });

        _showSnackBar('Charging session started.');
        await _loadSessionHistory();
      } else {
        await _chargingSessionService.finishSession(
          sessionId: _activeChargingSession!.id,
        );

        if (!mounted) return;
        setState(() {
          _activeChargingSession = null;
        });

        _showSnackBar('Charging session finished.');
        await _loadSessionHistory();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSessionLoading = false;
        });
      }
    }
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
            markers: _mapMarkers,
            polylines: _polylines,
            style: _mapStyle,
            myLocationEnabled: _isLocationPermissionGranted,
            myLocationButtonEnabled: _isLocationPermissionGranted,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) async {
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
          if (_isRouteLoading)
            const SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 84),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Creating route...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _NotificationBellButton(
                  onPressed: _openNotificationPanel,
                ),
              ),
            ),
          ),
          if (_isNavigationModeEnabled)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: FilledButton.icon(
                    onPressed: _cancelNavigation,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      elevation: 8,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Cancel Navigation'),
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
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 122),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'navigation-toggle',
                      backgroundColor: _isNavigationModeEnabled
                          ? colorScheme.primary
                          : colorScheme.surface,
                      foregroundColor: _isNavigationModeEnabled
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                      onPressed: _toggleNavigationMode,
                      child: Icon(
                        _isNavigationModeEnabled
                            ? Icons.navigation
                            : Icons.navigation_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'current-location',
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.primary,
                      onPressed: _centerOnCurrentLocation,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 122),
                child: _SessionHistoryChip(
                  sessionCount: _sessionHistory.length,
                  onPressed: _showSessionHistorySheet,
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
        isLoading: _isSessionLoading,
        isSessionActive: _activeChargingSession != null,
        onPressed: _toggleChargingSession,
      ),
      bottomNavigationBar: _MapBottomAppBar(
        onReservationsPressed: () {
          Navigator.of(context)
              .push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => const ReservationsScreen(),
                ),
              )
              .then((shouldRefreshStations) {
                if (shouldRefreshStations == true && mounted) {
                  _reloadStations();
                }
              });
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

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final controller = InAppNotificationScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final unreadCount = controller.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton.small(
              heroTag: 'notifications',
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.primary,
              onPressed: onPressed,
              child: const Icon(Icons.notifications_outlined),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onError,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReservationSlot {
  const _ReservationSlot({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
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
    required this.isLoading,
    required this.isSessionActive,
    required this.onPressed,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final bool isSessionActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: FloatingActionButton.extended(
        heroTag: 'charging-session',
        onPressed: isLoading ? null : onPressed,
        backgroundColor: isSessionActive ? Colors.red : backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 10,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isSessionActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
        label: Text(
          isSessionActive ? 'Finish Session' : 'Start Session',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }
}

class _SessionHistoryChip extends StatelessWidget {
  const _SessionHistoryChip({
    required this.sessionCount,
    required this.onPressed,
  });

  final int sessionCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Icon(Icons.history, size: 18, color: colorScheme.primary),
        ),
      ),
    );
  }
}

class _MiniSessionHistoryItem extends StatelessWidget {
  const _MiniSessionHistoryItem({required this.session});

  final ChargingSession session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.ev_station, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Session #${session.id}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            session.endTime ?? session.status.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryTile extends StatelessWidget {
  const _SessionHistoryTile({required this.session});

  final ChargingSession session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(Icons.ev_station, color: colorScheme.primary),
        title: Text(
          'Session #${session.id}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            'Start: ${session.startTime ?? '-'}',
            'End: ${session.endTime ?? '-'}',
            if (session.totalCost != null)
              'Cost: ${session.totalCost!.toStringAsFixed(2)} TL',
          ].join('\n'),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _SessionHistorySheetContent extends StatelessWidget {
  const _SessionHistorySheetContent({required this.sessions});

  final List<ChargingSession> sessions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session History',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            const Expanded(
              child: Center(child: Text('No completed sessions yet.')),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _SessionHistoryTile(session: sessions[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}
