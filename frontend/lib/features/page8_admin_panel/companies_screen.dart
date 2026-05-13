import 'package:flutter/material.dart';

import '../../data/models/company.dart';
import '../../data/services/company_service.dart';
import 'company_detail_screen.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final _companyService = CompanyService();

  late Future<List<Company>> _companiesFuture;

  @override
  void initState() {
    super.initState();
    _companiesFuture = _companyService.getCompanies();
  }

  Future<void> _refreshCompanies() async {
    setState(() {
      _companiesFuture = _companyService.getCompanies();
    });

    await _companiesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companies')),
      body: RefreshIndicator(
        onRefresh: _refreshCompanies,
        child: FutureBuilder<List<Company>>(
          future: _companiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Companies could not be loaded.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final companies = snapshot.data ?? [];

            if (companies.isEmpty) {
              return ListView(
                padding: EdgeInsets.all(16),
                children: [Center(child: Text('No companies found.'))],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: companies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final company = companies[index];

                return Card(
                  child: ListTile(
                    leading: Icon(
                      company.isActive
                          ? Icons.business_outlined
                          : Icons.business_center_outlined,
                    ),
                    title: Text(company.name),
                    subtitle: Text(
                      [
                        if (company.email != null && company.email!.isNotEmpty)
                          company.email!,
                        if (company.phone != null && company.phone!.isNotEmpty)
                          company.phone!,
                        company.isActive ? 'Active' : 'Inactive',
                      ].join(' • '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CompanyDetailScreen(company: company),
                        ),
                      );
                    },
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
