import 'package:flutter/material.dart';

import '../../core/app_snackbar.dart';
import '../../data/models/charger.dart';
import '../../data/models/station.dart';
import '../../data/models/vehicle.dart';
import '../../widgets/app_app_bar.dart';
import '../page7_reservations/page7_rezervations_screen.dart';
import 'reservation_time_selection_controller.dart';

class ReservationTimeSelectionScreen extends StatefulWidget {
  const ReservationTimeSelectionScreen({
    super.key,
    required this.station,
    required this.charger,
    required this.vehicle,
  });

  final Station station;
  final Charger charger;
  final Vehicle vehicle;

  @override
  State<ReservationTimeSelectionScreen> createState() =>
      _ReservationTimeSelectionScreenState();
}

class _ReservationTimeSelectionScreenState
    extends State<ReservationTimeSelectionScreen> {
  late final ReservationTimeSelectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReservationTimeSelectionController(
      station: widget.station,
      charger: widget.charger,
      vehicle: widget.vehicle,
    );
    _controller.loadSlots();
    _controller.startAutoRefresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate(ReservationTimeSelectionState state) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day + 30),
    );
    if (selectedDate == null) return;
    _controller.selectDate(selectedDate);
    await _controller.loadSlots();
  }

  Future<void> _confirmReservation() async {
    try {
      await _controller.confirmReservation();
      await _controller.loadSlots();
      if (!mounted) return;

      AppSnackBar.showSuccess(context, 'Reservation confirmed successfully.');

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle_outline),
            title: const Text('Reservation confirmed'),
            content: const Text('Your selected charging slot is now reserved.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('View Reservations'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ReservationsScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      final message =
          _controller.state.errorMessage ??
          'Reservation could not be confirmed. Please try again.';
      AppSnackBar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReservationTimeSelectionState>(
      stream: _controller,
      initialData: _controller.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _controller.state;

        return Scaffold(
          appBar: const AppAppBar(title: 'Select Reservation Time'),
          bottomNavigationBar: _ConfirmBar(
            canConfirm: state.selectedSlot != null && !state.isConfirming,
            isConfirming: state.isConfirming,
            onPressed: _confirmReservation,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _controller.loadSlots,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
                children: [
                  _ReservationSummary(
                    station: widget.station,
                    charger: widget.charger,
                    vehicle: widget.vehicle,
                    selectedSlot: state.selectedSlot,
                  ),
                  const SizedBox(height: 16),
                  _DateSelector(
                    date: state.selectedDate,
                    onPressed: () => _pickDate(state),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Available Slots',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (state.isLoadingSlots && state.slots.isEmpty)
                    const _SlotSkeletonGrid()
                  else if (state.errorMessage != null && state.slots.isEmpty)
                    _EmptySlotsState(
                      icon: Icons.wifi_off_outlined,
                      title: 'Slots could not be loaded',
                      subtitle: state.errorMessage!,
                    )
                  else
                    _SlotGrid(
                      slots: state.slots,
                      selectedSlot: state.selectedSlot,
                      onSlotPressed: _controller.selectSlot,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReservationSummary extends StatelessWidget {
  const _ReservationSummary({
    required this.station,
    required this.charger,
    required this.vehicle,
    this.selectedSlot,
  });

  final Station station;
  final Charger charger;
  final Vehicle vehicle;
  final ReservationSlot? selectedSlot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
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
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.ev_station,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Station #${station.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        station.address.isEmpty
                            ? '${station.latitude.toStringAsFixed(5)}, ${station.longitude.toStringAsFixed(5)}'
                            : station.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SummaryRow(
              icon: Icons.power,
              label: 'Charger',
              value: [
                charger.connectorType,
                charger.currentType,
                '${charger.maxPower.toStringAsFixed(0)} kW',
              ].where((value) => value.trim().isNotEmpty).join(' | '),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.directions_car,
              label: 'Vehicle',
              value: [
                vehicle.model.isEmpty ? vehicle.plate : vehicle.model,
                vehicle.plate,
              ].where((value) => value.trim().isNotEmpty).join(' | '),
            ),
            if (selectedSlot != null) ...[
              const SizedBox(height: 8),
              _SummaryRow(
                icon: Icons.schedule,
                label: 'Start time',
                value: _formatTime(selectedSlot!.start),
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                icon: Icons.av_timer,
                label: 'End time',
                value: _formatTime(selectedSlot!.end),
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                icon: Icons.timelapse,
                label: 'Duration',
                value: _formatDuration(
                  selectedSlot!.end.difference(selectedSlot!.start),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return [
      dateTime.hour.toString().padLeft(2, '0'),
      dateTime.minute.toString().padLeft(2, '0'),
    ].join(':');
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '$hours hours';
    }
    return '$hours h $minutes min';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onPressed});

  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        leading: const Icon(Icons.calendar_month_outlined),
        title: const Text('Selected Date'),
        subtitle: Text(_formatReadableDate(date)),
        trailing: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(Icons.edit_calendar_outlined),
          label: const Text('Change'),
        ),
      ),
    );
  }

  String _formatReadableDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.onSlotPressed,
  });

  final List<ReservationSlot> slots;
  final ReservationSlot? selectedSlot;
  final ValueChanged<ReservationSlot> onSlotPressed;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const _EmptySlotsState(
        icon: Icons.event_busy_outlined,
        title: 'No available slots',
        subtitle: 'Try a different day or refresh in a moment.',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];
        return ReservationSlotTile(
          slot: slot,
          isSelected: selectedSlot?.start == slot.start,
          onPressed: () => onSlotPressed(slot),
        );
      },
    );
  }
}

class ReservationSlotTile extends StatelessWidget {
  const ReservationSlotTile({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.onPressed,
  });

  final ReservationSlot slot;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabled = !slot.isAvailable;
    final background = disabled
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
        : isSelected
        ? colorScheme.primary
        : colorScheme.surfaceContainerLow;
    final foreground = disabled
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
        : isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: disabled ? null : onPressed,
        child: Center(
          child: Text(
            _formatTime(slot.start),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return [
      dateTime.hour.toString().padLeft(2, '0'),
      dateTime.minute.toString().padLeft(2, '0'),
    ].join(':');
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.canConfirm,
    required this.isConfirming,
    required this.onPressed,
  });

  final bool canConfirm;
  final bool isConfirming;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: FilledButton.icon(
            onPressed: canConfirm ? onPressed : null,
            icon: isConfirming
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(isConfirming ? 'Confirming...' : 'Confirm Reservation'),
          ),
        ),
      ),
    );
  }
}

class _SlotSkeletonGrid extends StatelessWidget {
  const _SlotSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
      ),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.35, end: 0.75),
          duration: Duration(milliseconds: 650 + (index % 4) * 80),
          curve: Curves.easeInOut,
          builder: (context, opacity, child) {
            return Opacity(opacity: opacity, child: child);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}

class _EmptySlotsState extends StatelessWidget {
  const _EmptySlotsState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 56, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
