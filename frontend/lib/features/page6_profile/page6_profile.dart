import 'package:flutter/material.dart';

import '../../widgets/app_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Profil'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Profil Bilgileri', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Ad Soyad'),
                subtitle: Text('—'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.mail_outline),
                title: Text('E-posta'),
                subtitle: Text('—'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.phone_outlined),
                title: Text('Telefon'),
                subtitle: Text('—'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Vehicle', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car_outlined),
                title: const Text('Araçlarım'),
                subtitle: const Text('Araç ekle / düzenle'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const VehicleScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Vehicle'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Add Vehicle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Vehicle Name',
                prefixIcon: Icon(Icons.directions_car),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Plate Number',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Connector Type',
                prefixIcon: Icon(Icons.power),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            ),
            const SizedBox(height: 24),
            Text('My Vehicles', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.directions_car_filled),
                title: Text('No vehicle added yet'),
                subtitle: Text('Your vehicles will appear here.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
