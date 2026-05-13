import 'package:flutter/material.dart';

import '../../data/models/company.dart';
import '../../data/models/station.dart';
import '../../data/services/station_service.dart';

class CompanyStationsScreen extends StatefulWidget {
  const CompanyStationsScreen({super.key, required this.company});

  final Company company;

  @override
  State<CompanyStationsScreen> createState() => _CompanyStationsScreenState();
}

class _CompanyStationsScreenState extends State<CompanyStationsScreen> {
  final _stationService = StationService();

  late Future<List<Station>> _stationsFuture;

  @override
  void initState() {
    super.initState();
    _stationsFuture = _stationService.getStationsByCompany(widget.company.id);
  }

  Future<void> _refreshStations() async {
    setState(() {
      _stationsFuture = _stationService.getStationsByCompany(widget.company.id);
    });

    await _stationsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.company.name} Stations')),
      body: RefreshIndicator(
        onRefresh: _refreshStations,
        child: FutureBuilder<List<Station>>(
          future: _stationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Stations could not be loaded.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final stations = snapshot.data ?? [];

            if (stations.isEmpty) {
              return ListView(
                padding: EdgeInsets.all(16),
                children: [Center(child: Text('No stations found.'))],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final station = stations[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.ev_station_outlined),
                    title: Text(
                      station.name.isEmpty
                          ? 'Station #${station.id}'
                          : station.name,
                    ),
                    subtitle: Text(
                      [
                        if (station.address != null &&
                            station.address!.isNotEmpty)
                          station.address!,
                        station.status,
                      ].join(' • '),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
