import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/notification.dart';
import '../../data/models/reservation.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/reservation_service.dart';

class InAppNotificationController extends ChangeNotifier {
  InAppNotificationController({
    NotificationService? notificationService,
    ReservationService? reservationService,
  }) : _notificationService = notificationService ?? NotificationService(),
       _reservationService = reservationService ?? ReservationService();

  final NotificationService _notificationService;
  final ReservationService _reservationService;
  final List<NotificationModel> _notifications = [];
  final Set<String> _shownNotificationKeys = {};
  final Set<String> _firedReminderKeys = {};

  Timer? _notificationPollTimer;
  Timer? _reservationReminderTimer;
  NotificationModel? _activeBannerNotification;
  Timer? _bannerDismissTimer;
  bool _isStarted = false;
  bool _isRefreshing = false;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  NotificationModel? get activeBannerNotification => _activeBannerNotification;

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;

    await refresh(showNewNotifications: false);
    await _checkReservationReminders();

    _notificationPollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => refresh(),
    );
    _reservationReminderTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkReservationReminders(),
    );
  }

  Future<void> refresh({bool showNewNotifications = true}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final latest = await _notificationService.getNotifications();
      _mergeNotifications(latest, showNewNotifications: showNewNotifications);
    } catch (_) {
      // Keep notification polling quiet so temporary backend/network issues do
      // not interrupt the active map or reservation flow.
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> markAsRead(NotificationModel notification) async {
    _replaceNotification(notification.copyWith(isRead: true));
    notifyListeners();

    if (notification.id <= 0) return;

    try {
      final updated = await _notificationService.markNotificationAsRead(
        notification.id,
      );
      _replaceNotification(updated);
      notifyListeners();
    } catch (_) {
      // Local read state is kept for this app session.
    }
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications
        .where((notification) => !notification.isRead)
        .toList(growable: false);

    for (final notification in unread) {
      _replaceNotification(notification.copyWith(isRead: true));
    }
    notifyListeners();

    for (final notification in unread) {
      if (notification.id <= 0) continue;
      try {
        final updated = await _notificationService.markNotificationAsRead(
          notification.id,
        );
        _replaceNotification(updated);
      } catch (_) {
        // Ignore individual failures; the local session remains read.
      }
    }
    notifyListeners();
  }

  void dismissBanner() {
    _bannerDismissTimer?.cancel();
    _activeBannerNotification = null;
    notifyListeners();
  }

  void _mergeNotifications(
    List<NotificationModel> latest, {
    required bool showNewNotifications,
  }) {
    for (final notification in latest) {
      if (notification.id > 0) {
        _notifications.removeWhere(
          (item) =>
              item.id < 0 && _isSimilarReservationReminder(item, notification),
        );
      }
      _replaceNotification(notification);

      final key = _notificationKey(notification);
      if (showNewNotifications &&
          !notification.isRead &&
          !_shownNotificationKeys.contains(key)) {
        _shownNotificationKeys.add(key);
        _showBanner(notification);
      } else {
        _shownNotificationKeys.add(key);
      }
    }

    _sortNotifications();
    notifyListeners();
  }

  void _replaceNotification(NotificationModel notification) {
    final index = _notifications.indexWhere(
      (item) => _notificationKey(item) == _notificationKey(notification),
    );
    if (index == -1) {
      _notifications.add(notification);
      return;
    }
    _notifications[index] = notification;
  }

  Future<void> _checkReservationReminders() async {
    try {
      final reservations = await _reservationService.getReservations();
      final now = DateTime.now();

      for (final reservation in reservations) {
        if (!_isActiveReservation(reservation)) continue;

        final startsAt = _reservationStartsAt(reservation);
        if (startsAt == null) continue;

        final reminderAt = startsAt.subtract(const Duration(minutes: 30));
        final reminderKey = 'reservation-${reservation.id}-30m';
        final shouldFire = !now.isBefore(reminderAt) && now.isBefore(startsAt);

        if (shouldFire &&
            !_firedReminderKeys.contains(reminderKey) &&
            !_hasReminderForReservation(reservation)) {
          _firedReminderKeys.add(reminderKey);
          _addLocalReminder(reservation);
        }
      }
    } catch (_) {
      // Reservation reminder checks are best-effort while the app is open.
    }
  }

  void _addLocalReminder(Reservation reservation) {
    final notification = NotificationModel(
      id: -reservation.id,
      userId: reservation.userId,
      title: 'Reservation reminder',
      message:
          'Your reservation at ${reservation.stationName.isEmpty ? 'your selected station' : reservation.stationName} starts in 30 minutes.',
      notificationType: 'INFO',
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    _replaceNotification(notification);
    _sortNotifications();
    _showBanner(notification);
    notifyListeners();
  }

  bool _isActiveReservation(Reservation reservation) {
    final status = reservation.status.toUpperCase().trim();
    return status == 'PENDING' || status == 'CONFIRMED';
  }

  bool _hasReminderForReservation(Reservation reservation) {
    return _notifications.any((notification) {
      final title = notification.title.toLowerCase();
      final message = notification.message.toLowerCase().replaceAll('#', '');
      return title.contains('reservation') &&
          message.contains('charger ${reservation.chargerId}');
    });
  }

  bool _isSimilarReservationReminder(
    NotificationModel first,
    NotificationModel second,
  ) {
    final firstTitle = first.title.toLowerCase();
    final secondTitle = second.title.toLowerCase();
    if (!firstTitle.contains('reservation') ||
        !secondTitle.contains('reservation')) {
      return false;
    }

    final firstMessage = first.message.toLowerCase().replaceAll('#', '');
    final secondMessage = second.message.toLowerCase().replaceAll('#', '');
    final chargerPattern = RegExp(r'charger\s+(\d+)');
    final firstCharger = chargerPattern.firstMatch(firstMessage)?.group(1);
    final secondCharger = chargerPattern.firstMatch(secondMessage)?.group(1);

    return firstCharger != null && firstCharger == secondCharger;
  }

  DateTime? _reservationStartsAt(Reservation reservation) {
    final startTime = reservation.startTime.length == 5
        ? '${reservation.startTime}:00'
        : reservation.startTime;
    return DateTime.tryParse('${reservation.date}T$startTime');
  }

  void _showBanner(NotificationModel notification) {
    _bannerDismissTimer?.cancel();
    _activeBannerNotification = notification;
    notifyListeners();

    _bannerDismissTimer = Timer(const Duration(seconds: 5), dismissBanner);
  }

  void _sortNotifications() {
    _notifications.sort((a, b) {
      final aTime = a.timestamp;
      final bTime = b.timestamp;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
  }

  String _notificationKey(NotificationModel notification) {
    if (notification.id > 0) return 'remote-${notification.id}';
    return [
      'local',
      notification.title,
      notification.message,
      notification.createdAt,
    ].join('|');
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    _reservationReminderTimer?.cancel();
    _bannerDismissTimer?.cancel();
    super.dispose();
  }
}

class InAppNotificationScope
    extends InheritedNotifier<InAppNotificationController> {
  const InAppNotificationScope({
    super.key,
    required InAppNotificationController controller,
    required super.child,
  }) : super(notifier: controller);

  static InAppNotificationController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InAppNotificationScope>();
    assert(scope != null, 'InAppNotificationScope was not found.');
    return scope!.notifier!;
  }
}
