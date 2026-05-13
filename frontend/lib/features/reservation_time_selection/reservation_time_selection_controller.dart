import 'dart:async';

import '../../data/api/api_exception.dart';
import '../../data/models/charger.dart';
import '../../data/models/reservation.dart';
import '../../data/models/station.dart';
import '../../data/models/vehicle.dart';
import '../../data/services/reservation_service.dart';

class ReservationSlot {
  const ReservationSlot({
    required this.start,
    required this.end,
    required this.isOccupied,
    required this.isPast,
  });

  final DateTime start;
  final DateTime end;
  final bool isOccupied;
  final bool isPast;

  bool get isAvailable => !isOccupied && !isPast;
}

class ReservationTimeSelectionState {
  const ReservationTimeSelectionState({
    required this.selectedDate,
    this.slots = const [],
    this.selectedStart,
    this.selectedEnd,
    this.isLoadingSlots = false,
    this.isConfirming = false,
    this.errorMessage,
  });

  final DateTime selectedDate;
  final List<ReservationSlot> slots;
  final DateTime? selectedStart;
  final DateTime? selectedEnd;
  final bool isLoadingSlots;
  final bool isConfirming;
  final String? errorMessage;

  bool get hasValidRange => selectedStart != null && selectedEnd != null;

  Duration? get selectedDuration {
    final start = selectedStart;
    final end = selectedEnd;
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  ReservationTimeSelectionState copyWith({
    DateTime? selectedDate,
    List<ReservationSlot>? slots,
    DateTime? selectedStart,
    DateTime? selectedEnd,
    bool clearSelection = false,
    bool clearSelectedEnd = false,
    bool? isLoadingSlots,
    bool? isConfirming,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReservationTimeSelectionState(
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selectedStart: clearSelection
          ? null
          : selectedStart ?? this.selectedStart,
      selectedEnd: clearSelection || clearSelectedEnd
          ? null
          : selectedEnd ?? this.selectedEnd,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
      isConfirming: isConfirming ?? this.isConfirming,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ReservationTimeSelectionController
    extends Stream<ReservationTimeSelectionState> {
  static const Duration slotInterval = Duration(minutes: 15);
  static const Duration minReservationDuration = Duration(minutes: 15);
  static const Duration maxReservationDuration = Duration(hours: 2);

  ReservationTimeSelectionController({
    required this.station,
    required this.charger,
    required this.vehicle,
    ReservationService? reservationService,
    DateTime? initialDate,
    DateTime? openingTime,
    DateTime? closingTime,
  }) : _reservationService = reservationService ?? ReservationService(),
       _openingTime = openingTime,
       _closingTime = closingTime,
       _state = ReservationTimeSelectionState(
         selectedDate: _dateOnly(initialDate ?? DateTime.now()),
       );

  final Station station;
  final Charger charger;
  final Vehicle vehicle;
  final ReservationService _reservationService;
  final DateTime? _openingTime;
  final DateTime? _closingTime;
  final _stateController =
      StreamController<ReservationTimeSelectionState>.broadcast();

  ReservationTimeSelectionState _state;
  Timer? _autoRefreshTimer;

  ReservationTimeSelectionState get state => _state;

  @override
  StreamSubscription<ReservationTimeSelectionState> listen(
    void Function(ReservationTimeSelectionState event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stateController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future<void> loadSlots() async {
    _emit(_state.copyWith(isLoadingSlots: true, clearError: true));

    try {
      final reservations = await _reservationService.getChargerReservations(
        chargerId: charger.id,
        date: _state.selectedDate,
      );
      final slots = _generateSlots(
        selectedDate: _state.selectedDate,
        reservations: reservations,
      );
      final stillAvailable = _isRangeAvailable(
        slots,
        _state.selectedStart,
        _state.selectedEnd,
      );

      _emit(
        _state.copyWith(
          slots: slots,
          clearSelection: !stillAvailable,
          isLoadingSlots: false,
        ),
      );
    } catch (error) {
      _emit(
        _state.copyWith(
          isLoadingSlots: false,
          errorMessage: _friendlyLoadError(error),
        ),
      );
    }
  }

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => loadSlots(),
    );
  }

  void selectDate(DateTime date) {
    _emit(
      _state.copyWith(
        selectedDate: _dateOnly(date),
        clearSelection: true,
        clearError: true,
      ),
    );
  }

  void selectSlot(ReservationSlot slot) {
    final selectedStart = _state.selectedStart;
    if (selectedStart == null || _state.selectedEnd != null) {
      if (!slot.isAvailable) return;
      _emit(
        _state.copyWith(
          selectedStart: slot.start,
          clearSelectedEnd: true,
          clearError: true,
        ),
      );
      return;
    }

    if (slot.start.isBefore(selectedStart) || slot.start == selectedStart) {
      if (!slot.isAvailable) return;
      _emit(
        _state.copyWith(
          selectedStart: slot.start,
          clearSelectedEnd: true,
          clearError: true,
        ),
      );
      return;
    }

    if (!isValidEndSlot(slot)) return;
    _emit(_state.copyWith(selectedEnd: slot.start, clearError: true));
  }

  Future<void> confirmReservation() async {
    final start = _state.selectedStart;
    final end = _state.selectedEnd;
    if (start == null || end == null || _state.isConfirming) return;

    _emit(_state.copyWith(isConfirming: true, clearError: true));

    try {
      await _reservationService.createReservation(
        ReservationInput(
          stationId: station.id,
          vehicleId: vehicle.id,
          chargerId: charger.id,
          date: _formatDate(start),
          startTime: start.toIso8601String(),
          endTime: end.toIso8601String(),
        ),
      );
      _emit(_state.copyWith(isConfirming: false));
    } catch (error) {
      final errorMessage = _friendlyCreateError(error);
      _emit(_state.copyWith(isConfirming: false, errorMessage: errorMessage));
      await loadSlots();
      _emit(_state.copyWith(errorMessage: errorMessage));
      rethrow;
    }
  }

  List<ReservationSlot> _generateSlots({
    required DateTime selectedDate,
    required List<Reservation> reservations,
  }) {
    final opening =
        _atTime(selectedDate, _openingTime) ??
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final closing =
        _atTime(selectedDate, _closingTime) ??
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1);
    final now = DateTime.now();
    final occupiedRanges = reservations
        .where((reservation) => reservation.status.toUpperCase() != 'CANCELLED')
        .map(
          (reservation) => (
            start: _parseDateTime(reservation.date, reservation.startTime),
            end: _parseDateTime(reservation.date, reservation.endTime),
          ),
        )
        .where((range) => range.start != null && range.end != null)
        .map((range) => (start: range.start!, end: range.end!))
        .toList();

    final slots = <ReservationSlot>[];
    var start = opening;
    while (start.isBefore(closing)) {
      final end = start.add(slotInterval);
      final isPast = _isSameDate(selectedDate, now) && !start.isAfter(now);
      final isOccupied = occupiedRanges.any(
        (range) => start.isBefore(range.end) && end.isAfter(range.start),
      );
      slots.add(
        ReservationSlot(
          start: start,
          end: start.add(slotInterval),
          isOccupied: isOccupied,
          isPast: isPast,
        ),
      );
      start = start.add(slotInterval);
    }
    return slots;
  }

  bool isValidEndSlot(ReservationSlot slot) {
    final start = _state.selectedStart;
    if (start == null) return false;
    return _isRangeAvailable(_state.slots, start, slot.start);
  }

  bool isInsideSelectedRange(ReservationSlot slot) {
    final start = _state.selectedStart;
    final end = _state.selectedEnd;
    if (start == null || end == null) return false;
    return slot.start.isAfter(start) && slot.start.isBefore(end);
  }

  bool isSelectedStart(ReservationSlot slot) =>
      slot.start == _state.selectedStart;

  bool isSelectedEnd(ReservationSlot slot) => slot.start == _state.selectedEnd;

  bool isSelectable(ReservationSlot slot) {
    final start = _state.selectedStart;
    if (start == null || _state.selectedEnd != null) return slot.isAvailable;
    if (slot.start.isAfter(start)) return isValidEndSlot(slot);
    return slot.isAvailable;
  }

  bool _isRangeAvailable(
    List<ReservationSlot> slots,
    DateTime? start,
    DateTime? end,
  ) {
    if (start == null) return true;
    if (end == null) {
      return slots.any((slot) => slot.start == start && slot.isAvailable);
    }
    final duration = end.difference(start);
    if (duration < minReservationDuration ||
        duration > maxReservationDuration) {
      return false;
    }
    if (duration.inMinutes % slotInterval.inMinutes != 0) return false;
    final rangeSlots = slots.where(
      (slot) =>
          (slot.start == start || slot.start.isAfter(start)) &&
          slot.start.isBefore(end),
    );
    if (rangeSlots.length != duration.inMinutes ~/ slotInterval.inMinutes) {
      return false;
    }
    return rangeSlots.every((slot) => slot.isAvailable);
  }

  DateTime? _atTime(DateTime date, DateTime? time) {
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  DateTime? _parseDateTime(String date, String time) {
    final normalizedTime = time.length == 5 ? '$time:00' : time;
    return DateTime.tryParse('${date}T$normalizedTime');
  }

  String _friendlyLoadError(Object error) {
    final message = error.toString().toLowerCase();
    if ((error is ApiException && error.statusCode == null) ||
        message.contains('clientexception') ||
        message.contains('socketexception') ||
        message.contains('connection')) {
      return 'No internet connection. Pull down to try again.';
    }
    return 'Reservation slots could not be loaded. Please try again.';
  }

  String _friendlyCreateError(Object error) {
    final rawMessage = error.toString();
    final message = rawMessage.toLowerCase();
    if (message.contains('overlap') ||
        message.contains('conflict') ||
        message.contains('reserved') ||
        message.contains('occupied')) {
      return 'That slot was just reserved. Please choose another time.';
    }
    if (message.contains('one reservation per day')) {
      return 'You already have a reservation for this day.';
    }
    if (message.contains('exactly 2 hours')) {
      return 'Backend is still using the old 2-hour-only reservation rule. Restart the backend server.';
    }
    if (message.contains('duration')) {
      return rawMessage;
    }
    if (message.contains('charger is not available')) {
      return 'This charger is not available right now.';
    }
    if (message.contains('station is not available')) {
      return 'This station is not available right now.';
    }
    if (message.contains('past')) {
      return 'That time has already passed. Please choose another slot.';
    }
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return 'Reservation could not be confirmed. Please try again.';
  }

  void _emit(ReservationTimeSelectionState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void dispose() {
    _autoRefreshTimer?.cancel();
    _stateController.close();
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _formatDate(DateTime dateTime) {
    return [
      dateTime.year.toString().padLeft(4, '0'),
      dateTime.month.toString().padLeft(2, '0'),
      dateTime.day.toString().padLeft(2, '0'),
    ].join('-');
  }
}
