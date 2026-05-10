import 'package:flutter/material.dart';

import '../../data/api/token_storage.dart';
import '../../data/models/reservation.dart';
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
  var _selectedReservationView = _ReservationView.upcoming;

  late final Future<List<Reservation>> _reservationsFuture =
      _loadReservations();

  Future<List<Reservation>> _loadReservations() async {
    final userId = await _tokenStorage.readUserId();
    if (userId == null || userId == 0) return [];
    return _userService.getUserReservations(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Rezervasyonlarim'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CreateReservationPanel(
              onMapPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Reservation>>(
              future: _reservationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageCard(
                    icon: Icons.error_outline,
                    title: 'Rezervasyonlar yuklenemedi',
                    subtitle: snapshot.error.toString(),
                  );
                }

                final reservations = snapshot.data ?? [];
                final upcomingCount = reservations
                    .where((reservation) => _isUpcoming(reservation))
                    .length;
                final pastCount = reservations.length - upcomingCount;
                final visibleReservations = _filteredReservations(reservations);

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
                        title: 'Rezervasyon bulunamadi',
                        subtitle: 'Bu bolumde gosterilecek rezervasyon yok.',
                      )
                    else
                      ...visibleReservations.map(
                        (reservation) => _ReservationCard(
                          reservation: reservation,
                          startsAt: _reservationStartsAt(reservation),
                          isPast: !_isUpcoming(reservation),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isUpcoming(Reservation reservation) {
    final endsAt = _reservationEndsAt(reservation);
    return endsAt == null || !endsAt.isBefore(DateTime.now());
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
                label: 'Gelecek',
                count: upcomingCount,
                isSelected: selectedView == _ReservationView.upcoming,
                onTap: () => onChanged(_ReservationView.upcoming),
              ),
            ),
            Expanded(
              child: _ReservationSwitchItem(
                icon: Icons.history,
                label: 'Gecmis',
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
    required this.startsAt,
    required this.isPast,
  });

  final Reservation reservation;
  final DateTime? startsAt;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = isPast ? colorScheme.outline : colorScheme.primary;
    final statusText = reservation.status.isEmpty
        ? 'PENDING'
        : reservation.status.toUpperCase();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Charger #${reservation.chargerId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _StatusBadge(text: statusText, isPast: isPast),
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
                    ],
                  ),
                ],
              ),
            ),
          ],
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
                        'Rezervasyon Olustur',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Haritadan istasyon secerek uygun sarj noktasina hizlica rezervasyon yap.',
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
                _InfoPill(icon: Icons.ev_station, text: 'Istasyon'),
                _InfoPill(icon: Icons.directions_car_outlined, text: 'Arac'),
                _InfoPill(icon: Icons.schedule, text: 'Zaman'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onMapPressed,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Haritadan Sec'),
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
