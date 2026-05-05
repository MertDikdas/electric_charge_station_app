import 'package:flutter/material.dart';

import '../../widgets/app_app_bar.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Rezervasyonlarım'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Rezervasyon Oluştur', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.ev_station),
                title: Text('İstasyon'),
                subtitle: Text('Haritadan bir istasyon seçin.'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.directions_car),
                title: Text('Araç'),
                subtitle: Text('Araçlarınızdan birini seçin.'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Zaman'),
                subtitle: Text('Tarih ve saat seçin.'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.event_available),
              label: const Text('Rezervasyon Oluştur'),
            ),
            const SizedBox(height: 28),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text('Rezervasyonlarım', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.receipt_long),
                title: Text('Henüz rezervasyon yok'),
                subtitle: Text(
                  'Oluşturduğunuz rezervasyonlar burada görünecek.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
