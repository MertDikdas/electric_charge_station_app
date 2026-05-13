import 'package:flutter/material.dart';

import '../../data/models/company.dart';
import 'company_members_screen.dart';
import 'company_stations_screen.dart';

class CompanyDetailScreen extends StatelessWidget {
  const CompanyDetailScreen({super.key, required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(company.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.ev_station_outlined),
              title: const Text('Stations'),
              subtitle: const Text('View company stations'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompanyStationsScreen(company: company),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Members'),
              subtitle: const Text('View company managers and operators'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompanyMembersScreen(company: company),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
