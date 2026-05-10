import 'package:flutter/material.dart';

import '../../data/models/notification.dart';
import 'in_app_notification_controller.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = InAppNotificationScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final notifications = controller.notifications;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: controller.unreadCount == 0
                          ? null
                          : controller.markAllAsRead,
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: notifications.isEmpty
                      ? const _EmptyNotificationState()
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return _NotificationTile(
                              notification: notification,
                              onTap: () {
                                controller.markAsRead(notification);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NotificationBanner extends StatelessWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = InAppNotificationScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final notification = controller.activeBannerNotification;

        return IgnorePointer(
          ignoring: notification == null,
          child: AnimatedSlide(
            offset: notification == null ? const Offset(0, -1.2) : Offset.zero,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: notification == null ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: notification == null
                        ? const SizedBox.shrink()
                        : _NotificationBannerCard(
                            notification: notification,
                            onClose: controller.dismissBanner,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationBannerCard extends StatelessWidget {
  const _NotificationBannerCard({
    required this.notification,
    required this.onClose,
  });

  final NotificationModel notification;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 10,
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _NotificationIcon(type: notification.notificationType),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: notification.isRead
          ? colorScheme.surfaceContainerLow
          : colorScheme.primaryContainer.withValues(alpha: 0.45),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        leading: _NotificationIcon(type: notification.notificationType),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              notification.message,
              _formatTimestamp(notification.timestamp),
            ].where((value) => value.isNotEmpty).join('\n'),
          ),
        ),
        trailing: notification.isRead
            ? null
            : Icon(Icons.circle, size: 10, color: colorScheme.primary),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = type.toUpperCase();
    final icon = switch (normalized) {
      'WARNING' => Icons.warning_amber,
      'ERROR' => Icons.error_outline,
      'SUCCESS' => Icons.check_circle_outline,
      _ => Icons.notifications_outlined,
    };
    final color = switch (normalized) {
      'WARNING' => Colors.orange,
      'ERROR' => colorScheme.error,
      'SUCCESS' => Colors.green,
      _ => colorScheme.primary,
    };

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.notifications_none),
        title: Text('No notifications yet'),
        subtitle: Text('Reservation reminders and station alerts appear here.'),
      ),
    );
  }
}

String _formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) return '';

  final local = timestamp.toLocal();
  final date = [
    local.day.toString().padLeft(2, '0'),
    local.month.toString().padLeft(2, '0'),
    local.year.toString(),
  ].join('.');
  final time = [
    local.hour.toString().padLeft(2, '0'),
    local.minute.toString().padLeft(2, '0'),
  ].join(':');

  return '$date $time';
}
