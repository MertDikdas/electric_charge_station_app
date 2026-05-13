import 'package:flutter/material.dart';

class AdminPanelShell extends StatelessWidget {
  const AdminPanelShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.admin_panel_settings_outlined),
                title: Text('Admin Panel'),
                subtitle: Text('Admin workspace route is ready.'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
