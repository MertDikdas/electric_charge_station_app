import 'package:flutter/material.dart';

import '../../widgets/app_app_bar.dart';

class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Reservation'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Create Reservation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.ev_station),
                title: Text('Station'),
                subtitle: Text('Select a station from the map.'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.directions_car),
                title: Text('Vehicle'),
                subtitle: Text('Select one of your vehicles.'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Time Slot'),
                subtitle: Text('Pick a date and charging time.'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.event_available),
              label: const Text('Create Reservation'),
            ),
          ],
        ),
      ),
    );
  }
}
