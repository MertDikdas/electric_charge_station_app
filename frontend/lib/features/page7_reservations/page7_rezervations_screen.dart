import 'package:flutter/material.dart';

import '../../core/app_snackbar.dart';
import '../../data/api/token_storage.dart';
import '../../data/models/charger.dart';
import '../../data/models/reservation.dart';
import '../../data/services/charger_service.dart';
import '../../data/services/reservation_service.dart';
import '../../data/services/user_service.dart';
import '../../widgets/app_app_bar.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _tokenStorage = TokenStorage();
  final _userService = UserService();
  final _reservationService = ReservationService();
  final _chargerService = ChargerService();
  final Map<int, Future<Charger>> _chargerFutures = {};
  final Set<int> _cancellingReservationIds = {};
  List<Reservation> _reservations = const [];
  var _selectedReservationView = _ReservationView.upcoming;
  bool _isLoading = true;
  bool _didCancelReservation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshReservations();
  }

  Future<List<Reservation>> _loadReservations() async {
    final userId = await _tokenStorage.readUserId();
    if (userId == null || userId == 0) return [];
    return _userService.getUserReservations(userId);
  }

  Future<void> _refreshReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reservations = await _loadReservations();
      if (!mounted) return;
      setState(() {
        _reservations = reservations;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmCancelReservation(Reservation reservation) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Reservation'),
          content: const Text(
            'Are you sure you want to cancel this reservation?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Reservation'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Confirm Cancel'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      await _cancelReservation(reservation);
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    setState(() {
      _cancellingReservationIds.add(reservation.id);
    });

    try {
      await _reservationService.updateReservationStatus(
        reservation.id,
        'CANCELLED',
      );
      if (!mounted) return;
      _didCancelReservation = true;
      AppSnackBar.showSuccess(context, 'Reservation cancelled successfully.');
      await _refreshReservations();
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, _friendlyCancelError(error));
    } finally {
      if (mounted) {
        setState(() {
          _cancellingReservationIds.remove(reservation.id);
        });
      }
    }
  }

  String _friendlyCancelError(Object error) {
    final message = error.toString();
    if (message.toLowerCase().contains('not found')) {
      return 'Reservation could not be found.';
    }
    if (message.toLowerCase().contains('cancel')) {
      return 'Reservation is already cancelled or cannot be cancelled.';
    }
    return 'Reservation could not be cancelled. Please try again.';
  }

  // Deprecated: Use AppSnackBar service instead
  void _showSnackBar(String message) {
    // This method is kept for backward compatibility but should not be used
    AppSnackBar.showInfo(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_didCancelReservation);
      },
      child: Scaffold(
        appBar: const AppAppBar(title: 'My Reservations'),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshReservations,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CreateReservationPanel(
                  onMapPressed: () {
                    Navigator.of(context).pop(_didCancelReservation);
                  },
                ),
                const SizedBox(height: 16),
                _buildReservationContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReservationContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return _MessageCard(
        icon: Icons.error_outline,
        title: 'Reservations could not be loaded',
        subtitle: errorMessage,
      );
    }

    final upcomingCount = _reservations
        .where((reservation) => _isUpcoming(reservation))
        .length;
    final pastCount = _reservations.length - upcomingCount;
    final visibleReservations = _filteredReservations(_reservations);

    return Column(
      children: [
        _ReservationViewSwitch(
          selectedView: _selectedReservationView,
          upcomingCount: upcomingCount,
          pastCount: pastCount,
          onChanged: (view) {
            setState(() {
              _selectedReservationView = view;
            });
          },
        ),
        const SizedBox(height: 14),
        if (visibleReservations.isEmpty)
          const _MessageCard(
            icon: Icons.receipt_long,
            title: 'No reservations found',
            subtitle: 'There are no reservations to show here.',
          )
        else
          ...visibleReservations.map(
            (reservation) => _ReservationCard(
              reservation: reservation,
              chargerFuture: _chargerFutureFor(reservation.chargerId),
              startsAt: _reservationStartsAt(reservation),
              isPast: !_isUpcoming(reservation),
              isCancelling: _cancellingReservationIds.contains(reservation.id),
              canCancel: _canCancelReservation(reservation),
              onCancelPressed: () => _confirmCancelReservation(reservation),
            ),
          ),
      ],
    );
  }

  bool _isUpcoming(Reservation reservation) {
    final endsAt = _reservationEndsAt(reservation);
    return endsAt == null || !endsAt.isBefore(DateTime.now());
  }

  bool _canCancelReservation(Reservation reservation) {
    final status = reservation.status.toUpperCase().trim();
    return _isUpcoming(reservation) &&
        (status == 'ACTIVE' || status == 'PENDING' || status == 'CONFIRMED');
  }

  Future<Charger> _chargerFutureFor(int chargerId) {
    return _chargerFutures.putIfAbsent(
      chargerId,
      () => _chargerService.getCharger(chargerId),
    );
  }

  List<Reservation> _filteredReservations(List<Reservation> reservations) {
    final filtered = reservations.where((reservation) {
      final isUpcoming = _isUpcoming(reservation);

      return switch (_selectedReservationView) {
        _ReservationView.upcoming => isUpcoming,
        _ReservationView.past => !isUpcoming,
      };
    }).toList();

    filtered.sort((a, b) {
      final aDate = _reservationStartsAt(a);
      final bDate = _reservationStartsAt(b);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return switch (_selectedReservationView) {
        _ReservationView.upcoming => aDate.compareTo(bDate),
        _ReservationView.past => bDate.compareTo(aDate),
      };
    });

    return filtered;
  }

  DateTime? _reservationStartsAt(Reservation reservation) {
    return _parseReservationDateTime(reservation.date, reservation.startTime);
  }

  DateTime? _reservationEndsAt(Reservation reservation) {
    return _parseReservationDateTime(reservation.date, reservation.endTime);
  }

  DateTime? _parseReservationDateTime(String date, String time) {
    final normalizedTime = time.length == 5 ? '$time:00' : time;
    return DateTime.tryParse('${date}T$normalizedTime');
  }
}

enum _ReservationView { upcoming, past }

class _ReservationViewSwitch extends StatelessWidget {
  const _ReservationViewSwitch({
    required this.selectedView,
    required this.upcomingCount,
    required this.pastCount,
    required this.onChanged,
  });

  final _ReservationView selectedView;
  final int upcomingCount;
  final int pastCount;
  final ValueChanged<_ReservationView> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _ReservationSwitchItem(
                icon: Icons.bolt,
                label: 'Upcoming',
                count: upcomingCount,
                isSelected: selectedView == _ReservationView.upcoming,
                onTap: () => onChanged(_ReservationView.upcoming),
              ),
            ),
            Expanded(
              child: _ReservationSwitchItem(
                icon: Icons.history,
                label: 'Past',
                count: pastCount,
                isSelected: selectedView == _ReservationView.past,
                onTap: () => onChanged(_ReservationView.past),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationSwitchItem extends StatelessWidget {
  const _ReservationSwitchItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Material(
      color: isSelected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.onPrimary.withValues(alpha: 0.18)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.chargerFuture,
    required this.startsAt,
    required this.isPast,
    required this.isCancelling,
    required this.canCancel,
    required this.onCancelPressed,
  });

  final Reservation reservation;
  final Future<Charger> chargerFuture;
  final DateTime? startsAt;
  final bool isPast;
  final bool isCancelling;
  final bool canCancel;
  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCancelled = reservation.status.toUpperCase().trim() == 'CANCELLED';
    final accentColor = isCancelled || isPast
        ? colorScheme.outline
        : colorScheme.primary;
    final statusText = reservation.status.isEmpty
        ? 'PENDING'
        : reservation.status.toUpperCase();

    return Card(
      elevation: 0,
      color: isCancelled
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
          : colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<Charger>(
          future: chargerFuture,
          builder: (context, snapshot) {
            final charger = snapshot.data;

            return Opacity(
              opacity: isCancelled ? 0.68 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.ev_station, color: accentColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              charger == null
                                  ? 'Station loading'
                                  : 'Station #${charger.stationId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              charger == null
                                  ? 'Charger #${reservation.chargerId}'
                                  : [
                                          'Charger #${reservation.chargerId}',
                                          charger.connectorType,
                                          charger.currentType,
                                        ]
                                        .where((value) => value.isNotEmpty)
                                        .join(' | '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        text: statusText,
                        isPast: isPast || isCancelled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        icon: Icons.calendar_today_outlined,
                        text: _dateText(),
                      ),
                      _InfoPill(
                        icon: Icons.schedule,
                        text: '${reservation.startTime}-${reservation.endTime}',
                      ),
                      _InfoPill(
                        icon: Icons.directions_car_outlined,
                        text: 'Vehicle #${reservation.vehicleId}',
                      ),
                      if (charger != null)
                        _InfoPill(
                          icon: Icons.power,
                          text: '${charger.maxPower.toStringAsFixed(0)} kW',
                        ),
                    ],
                  ),
                  if (canCancel) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isCancelling ? null : onCancelPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                        ),
                        icon: isCancelling
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cancel_outlined),
                        label: Text(
                          isCancelling ? 'Cancelling...' : 'Cancel Reservation',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _dateText() {
    final date = startsAt;
    if (date == null) return reservation.date;

    return [
      date.day.toString().padLeft(2, '0'),
      date.month.toString().padLeft(2, '0'),
      date.year.toString(),
    ].join('.');
  }
}

class _CreateReservationPanel extends StatelessWidget {
  const _CreateReservationPanel({required this.onMapPressed});

  final VoidCallback onMapPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_location_alt_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Reservation',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a station on the map and quickly reserve an available charging point.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(icon: Icons.ev_station, text: 'Station'),
                _InfoPill(icon: Icons.directions_car_outlined, text: 'Vehicle'),
                _InfoPill(icon: Icons.schedule, text: 'Time'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onMapPressed,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Select on Map'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.isPast});

  final String text;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isPast ? colorScheme.outline : colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
