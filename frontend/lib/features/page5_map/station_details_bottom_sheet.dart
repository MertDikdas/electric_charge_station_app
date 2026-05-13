import 'package:flutter/material.dart';

import '../../data/models/charger.dart';
import '../../data/models/station.dart';
import '../../data/models/vehicle.dart';
import 'route_details.dart';

class StationDetailsBottomSheet extends StatefulWidget {
  const StationDetailsBottomSheet({
    super.key,
    required this.station,
    required this.chargersFuture,
    required this.selectedVehicle,
    required this.distanceText,
    required this.initialRouteDetails,
    required this.onRoutePressed,
    required this.onReserveCharger,
    required this.onSelectCharger,
    required this.selectedChargerId,
    required this.onSelectVehiclePressed,
    required this.formatPrice,
    required this.canReserveCharger,
  });

  final Station station;
  final Future<List<Charger>> chargersFuture;
  final Vehicle? selectedVehicle;
  final String distanceText;
  final RouteDetails? initialRouteDetails;
  final Future<RouteDetails?> Function() onRoutePressed;
  final ValueChanged<Charger> onReserveCharger;
  final ValueChanged<Charger> onSelectCharger;
  final int? selectedChargerId;
  final VoidCallback onSelectVehiclePressed;
  final String Function(double pricePerKwh) formatPrice;
  final bool Function(Charger charger) canReserveCharger;

  @override
  State<StationDetailsBottomSheet> createState() =>
      _StationDetailsBottomSheetState();
}

class _StationDetailsBottomSheetState extends State<StationDetailsBottomSheet> {
  RouteDetails? _routeDetails;
  bool _isRouteLoading = false;
  int? _selectedChargerId;

  @override
  void initState() {
    super.initState();
    _routeDetails = widget.initialRouteDetails;
    _selectedChargerId = widget.selectedChargerId;
  }

  Future<void> _requestRoute() async {
    if (_isRouteLoading) return;

    setState(() {
      _isRouteLoading = true;
    });

    final details = await widget.onRoutePressed();

    if (!mounted) return;
    setState(() {
      _routeDetails = details ?? _routeDetails;
      _isRouteLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: FutureBuilder<List<Charger>>(
          future: widget.chargersFuture,
          builder: (context, snapshot) {
            final chargers = snapshot.data ?? const <Charger>[];
            final primaryCharger = _primaryCharger(chargers);
            final reserveCharger = chargers
                .where(widget.canReserveCharger)
                .firstOrNull;
            final durationText = _routeDetails?.durationText ?? 'Route needed';
            final distanceText =
                _routeDetails?.distanceText ?? widget.distanceText;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedChargerId == null && chargers.isNotEmpty)
                    Builder(
                      builder: (context) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted || _selectedChargerId != null) return;
                          final defaultCharger =
                              chargers
                                  .where(widget.canReserveCharger)
                                  .firstOrNull ??
                              chargers.first;
                          setState(() {
                            _selectedChargerId = defaultCharger.id;
                          });
                          widget.onSelectCharger(defaultCharger);
                        });
                        return const SizedBox.shrink();
                      },
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.ev_station,
                          color: colorScheme.onPrimaryContainer,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.station.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.station.address.isEmpty
                                  ? '${widget.station.latitude.toStringAsFixed(5)}, ${widget.station.longitude.toStringAsFixed(5)}'
                                  : widget.station.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _InfoGrid(
                    chargerText: _chargerInfo(primaryCharger),
                    availabilityText: _availabilityText(chargers, snapshot),
                    distanceText: distanceText,
                    durationText: durationText,
                  ),
                  const SizedBox(height: 14),
                  _SelectedVehiclePanel(
                    vehicle: widget.selectedVehicle,
                    onSelectPressed: widget.onSelectVehiclePressed,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isRouteLoading ? null : _requestRoute,
                          icon: _isRouteLoading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.route),
                          label: const Text('Route'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: reserveCharger == null
                              ? null
                              : () => widget.onReserveCharger(reserveCharger),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Reserve'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ChargerList(
                    chargers: chargers,
                    snapshot: snapshot,
                    canReserveCharger: widget.canReserveCharger,
                    onReserveCharger: widget.onReserveCharger,
                    onSelectCharger: (charger) {
                      setState(() {
                        _selectedChargerId = charger.id;
                      });
                      widget.onSelectCharger(charger);
                    },
                    selectedChargerId: _selectedChargerId,
                    formatPrice: widget.formatPrice,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Charger? _primaryCharger(List<Charger> chargers) {
    if (chargers.isEmpty) return null;

    final reservable = chargers.where(widget.canReserveCharger).firstOrNull;
    return reservable ?? chargers.first;
  }

  String _chargerInfo(Charger? charger) {
    if (charger == null) return 'No charger';
    return '${charger.connectorType} ${charger.currentType}'.trim();
  }

  String _availabilityText(
    List<Charger> chargers,
    AsyncSnapshot<List<Charger>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) return 'Loading';
    if (snapshot.hasError) return 'Unavailable';
    if (chargers.isEmpty) return 'No chargers';

    final available = chargers.where(widget.canReserveCharger).length;
    if (available > 0) return '$available available';

    return widget.station.status.isEmpty ? 'Occupied' : widget.station.status;
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.chargerText,
    required this.availabilityText,
    required this.distanceText,
    required this.durationText,
  });

  final String chargerText;
  final String availabilityText;
  final String distanceText;
  final String durationText;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.45,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _MetricTile(icon: Icons.power, label: 'Charger', value: chargerText),
        _MetricTile(
          icon: Icons.check_circle_outline,
          label: 'Status',
          value: availabilityText,
        ),
        _MetricTile(
          icon: Icons.near_me_outlined,
          label: 'Distance',
          value: distanceText,
        ),
        _MetricTile(
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: durationText,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedVehiclePanel extends StatelessWidget {
  const _SelectedVehiclePanel({
    required this.vehicle,
    required this.onSelectPressed,
  });

  final Vehicle? vehicle;
  final VoidCallback onSelectPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedVehicle = vehicle;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: const Icon(Icons.directions_car),
        title: Text(
          selectedVehicle == null
              ? 'No vehicle selected'
              : selectedVehicle.model.isEmpty
              ? selectedVehicle.plate
              : selectedVehicle.model,
        ),
        subtitle: Text(
          selectedVehicle == null
              ? 'Select a vehicle for reservation.'
              : [
                  selectedVehicle.plate,
                  selectedVehicle.connectorType,
                  selectedVehicle.currentType,
                ].where((value) => value.trim().isNotEmpty).join(' | '),
        ),
        trailing: TextButton(
          onPressed: onSelectPressed,
          child: const Text('Select'),
        ),
      ),
    );
  }
}

class _ChargerList extends StatelessWidget {
  const _ChargerList({
    required this.chargers,
    required this.snapshot,
    required this.canReserveCharger,
    required this.onReserveCharger,
    required this.onSelectCharger,
    required this.selectedChargerId,
    required this.formatPrice,
  });

  final List<Charger> chargers;
  final AsyncSnapshot<List<Charger>> snapshot;
  final bool Function(Charger charger) canReserveCharger;
  final ValueChanged<Charger> onReserveCharger;
  final ValueChanged<Charger> onSelectCharger;
  final int? selectedChargerId;
  final String Function(double pricePerKwh) formatPrice;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (snapshot.hasError) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.error_outline),
        title: const Text('Charger list could not be loaded'),
        subtitle: Text(snapshot.error.toString()),
      );
    }

    if (chargers.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.ev_station),
        title: Text('No chargers found'),
      );
    }

    return Column(
      children: chargers.map((charger) {
        final isSelected = charger.id == selectedChargerId;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.ev_station,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          title: Text('${charger.connectorType} - ${charger.currentType}'),
          subtitle: Text(
            [
              charger.status,
              '${charger.maxPower.toStringAsFixed(0)} kW',
              formatPrice(charger.pricePerKwh),
            ].join(' | '),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle, size: 20),
                ),
              FilledButton.tonal(
                onPressed: canReserveCharger(charger)
                    ? () => onReserveCharger(charger)
                    : null,
                child: const Text('Reserve'),
              ),
            ],
          ),
          onTap: () => onSelectCharger(charger),
        );
      }).toList(),
    );
  }
}
