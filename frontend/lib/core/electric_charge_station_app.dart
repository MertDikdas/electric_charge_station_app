import 'package:flutter/material.dart';

import '../features/page2_3_4_sign_up/page2_signup_phone_page.dart';
import '../features/page1_login/page1_login_screen.dart';
import 'main_navigation_shell.dart';
import 'app_theme.dart';

class ElectricChargeStationApp extends StatelessWidget {
  const ElectricChargeStationApp({super.key, this.initialRoute = '/'});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Electric Charge Station',
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: {
        '/': (_) => const LoginScreen(),
        '/signup-phone': (_) => const SignupPhonePage(),
        '/home': (_) => const MainNavigationShell(),
      },
    );
  }
}
