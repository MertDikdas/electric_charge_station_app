import 'package:flutter/material.dart';

import '../../data/models/company.dart';
import '../../data/models/charger.dart';
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

  String _formatStatus(String status) {
    return status
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatConnector(String value) {
    return value.replaceAll('_', ' ');
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  Widget _buildChargerRow(Charger charger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.power_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Charger #${charger.id} • ${_formatConnector(charger.connectorType)} • ${charger.currentType}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatNumber(charger.maxPower)} kW • ${_formatNumber(charger.pricePerKwh)} / kWh • ${_formatStatus(charger.status)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final station = stations[index];
                final chargers = station.chargers;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.ev_station_outlined),
                          title: Text(
                            station.name.isEmpty
                                ? 'Station #${station.id}'
                                : station.name,
                          ),
                          subtitle: Text(
                            [
                              if (station.address.isNotEmpty) station.address,
                              _formatStatus(station.status),
                              '${chargers.length} charger${chargers.length == 1 ? '' : 's'}',
                            ].join(' • '),
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: chargers.isEmpty
                              ? const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('No chargers found.'),
                                )
                              : Column(
                                  children: [
                                    for (final charger in chargers)
                                      _buildChargerRow(charger),
                                  ],
                                ),
                        ),
                      ],
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
