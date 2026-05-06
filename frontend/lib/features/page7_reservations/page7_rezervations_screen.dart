import 'package:flutter/material.dart';

import '../../data/api/token_storage.dart';
import '../../data/models/reservation.dart';
import '../../data/services/user_service.dart';
import '../../widgets/app_app_bar.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _tokenStorage = TokenStorage();
  final _userService = UserService();

  late final Future<List<Reservation>> _reservationsFuture =
      _loadReservations();

  Future<List<Reservation>> _loadReservations() async {
    final userId = await _tokenStorage.readUserId();
    if (userId == null || userId == 0) return [];
    return _userService.getUserReservations(userId);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Rezervasyonlarim'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Rezervasyon Olustur', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.ev_station),
                title: Text('Istasyon'),
                subtitle: Text('Haritadan bir istasyon secin.'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.directions_car),
                title: Text('Arac'),
                subtitle: Text('Araclarinizdan birini secin.'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Zaman'),
                subtitle: Text('Tarih ve saat secin.'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.event_available),
              label: const Text('Rezervasyon Olustur'),
            ),
            const SizedBox(height: 28),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text('Rezervasyonlarim', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            FutureBuilder<List<Reservation>>(
              future: _reservationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageCard(
                    icon: Icons.error_outline,
                    title: 'Rezervasyonlar yuklenemedi',
                    subtitle: snapshot.error.toString(),
                  );
                }

                final reservations = snapshot.data ?? [];
                if (reservations.isEmpty) {
                  return const _MessageCard(
                    icon: Icons.receipt_long,
                    title: 'Henuz rezervasyon yok',
                    subtitle: 'Olusturdugunuz rezervasyonlar burada gorunecek.',
                  );
                }

                return Column(
                  children: reservations
                      .map(
                        (reservation) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.receipt_long),
                            title: Text(
                              'Charger #${reservation.chargerId} - ${reservation.status}',
                            ),
                            subtitle: Text(
                              '${reservation.date} ${reservation.startTime}-${reservation.endTime}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
