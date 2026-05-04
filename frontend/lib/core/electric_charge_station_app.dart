import 'package:flutter/material.dart';

import '../features/auth/page1_login_screen.dart';
import 'app_theme.dart';

class ElectricChargeStationApp extends StatelessWidget {
  const ElectricChargeStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Electric Charge Station',
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
