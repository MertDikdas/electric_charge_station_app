import 'package:flutter/material.dart';

import '../features/page5_map/page5_map_screen.dart';
import '../features/notifications/in_app_notification_controller.dart';
import '../features/notifications/notification_panel.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late final InAppNotificationController _notificationController =
      InAppNotificationController();

  @override
  void initState() {
    super.initState();
    _notificationController.start();
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppNotificationScope(
      controller: _notificationController,
      child: const Stack(children: [MapScreen(), NotificationBanner()]),
    );
  }
}
