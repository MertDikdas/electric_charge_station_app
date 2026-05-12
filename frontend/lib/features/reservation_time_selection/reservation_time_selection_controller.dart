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
    this.selectedSlot,
    this.isLoadingSlots = false,
    this.isConfirming = false,
    this.errorMessage,
  });

  final DateTime selectedDate;
  final List<ReservationSlot> slots;
  final ReservationSlot? selectedSlot;
  final bool isLoadingSlots;
  final bool isConfirming;
  final String? errorMessage;

  ReservationTimeSelectionState copyWith({
    DateTime? selectedDate,
    List<ReservationSlot>? slots,
    ReservationSlot? selectedSlot,
    bool clearSelectedSlot = false,
    bool? isLoadingSlots,
    bool? isConfirming,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReservationTimeSelectionState(
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selectedSlot: clearSelectedSlot
          ? null
          : selectedSlot ?? this.selectedSlot,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
      isConfirming: isConfirming ?? this.isConfirming,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ReservationTimeSelectionController
    extends Stream<ReservationTimeSelectionState> {
  static const Duration reservationDuration = Duration(hours: 2);

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
      final selectedSlot = _state.selectedSlot;
      final stillAvailable =
          selectedSlot != null &&
          slots.any(
            (slot) =>
                slot.start == selectedSlot.start &&
                slot.end == selectedSlot.end &&
                slot.isAvailable,
          );

      _emit(
        _state.copyWith(
          slots: slots,
          selectedSlot: stillAvailable ? selectedSlot : null,
          clearSelectedSlot: !stillAvailable,
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
        clearSelectedSlot: true,
        clearError: true,
      ),
    );
  }

  void selectSlot(ReservationSlot slot) {
    if (!slot.isAvailable) return;
    _emit(_state.copyWith(selectedSlot: slot, clearError: true));
  }

  Future<void> confirmReservation() async {
    final slot = _state.selectedSlot;
    if (slot == null || _state.isConfirming) return;

    _emit(_state.copyWith(isConfirming: true, clearError: true));

    try {
      await _reservationService.createReservation(
        ReservationInput(
          stationId: station.id,
          vehicleId: vehicle.id,
          chargerId: charger.id,
          date: _formatDate(slot.start),
          startTime: _formatTime(slot.start),
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
      final end = start.add(reservationDuration);
      if (end.isAfter(closing)) break;

      final isPast = _isSameDate(selectedDate, now) && !start.isAfter(now);
      final isOccupied = occupiedRanges.any(
        (range) => start.isBefore(range.end) && end.isAfter(range.start),
      );
      slots.add(
        ReservationSlot(
          start: start,
          end: end,
          isOccupied: isOccupied,
          isPast: isPast,
        ),
      );
      start = start.add(const Duration(minutes: 15));
    }
    return slots;
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
    final message = error.toString().toLowerCase();
    if (message.contains('overlap') ||
        message.contains('conflict') ||
        message.contains('reserved') ||
        message.contains('occupied')) {
      return 'That slot was just reserved. Please choose another time.';
    }
    if (message.contains('past')) {
      return 'That time has already passed. Please choose another slot.';
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

  static String _formatTime(DateTime dateTime) {
    return [
      dateTime.hour.toString().padLeft(2, '0'),
      dateTime.minute.toString().padLeft(2, '0'),
      '00',
    ].join(':');
  }
}
