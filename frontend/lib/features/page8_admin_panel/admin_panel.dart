import 'package:flutter/material.dart';

import 'admin_statistics_screen.dart';
import 'companies_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Companies'),
              subtitle: const Text('View and manage companies'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CompaniesScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.query_stats_outlined),
              title: const Text('Statistics'),
              subtitle: const Text('View platform statistics'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminStatisticsScreen(),
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
