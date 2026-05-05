import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../page6_profile/page6_profile.dart';
import '../page7_reservations/page7_rezervations_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(38.4237, 27.1428),
    zoom: 14,
  );

  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  static const Set<Marker> _markers = <Marker>{};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _StartChargingFab(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        onPressed: () {},
      ),
      bottomNavigationBar: _MapBottomAppBar(
        onReservationsPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ReservationsScreen(),
            ),
          );
        },
        onProfilePressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ProfileScreen(),
            ),
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
            Icon(
              icon,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
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
            child: const Icon(Icons.qr_code_2, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            'Start',
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
