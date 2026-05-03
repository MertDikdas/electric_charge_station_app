import 'package:flutter/material.dart';

import '../../widgets/app_app_bar.dart';

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'My Reservations'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Card(
              child: ListTile(
                leading: Icon(Icons.receipt_long),
                title: Text('No reservations yet'),
                subtitle: Text('Created reservations will appear here.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
