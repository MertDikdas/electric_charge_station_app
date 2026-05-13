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
  final _nameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late Future<List<Company>> _companiesFuture;
  bool _isSavingCompany = false;

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
  void dispose() {
    _nameController.dispose();
    _taxNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _reloadCompanies() {
    setState(() {
      _companiesFuture = _companyService.getCompanies();
    });
  }

  Future<void> _showCreateCompanyDialog() async {
    _nameController.clear();
    _taxNumberController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isSavingCompany,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              setDialogState(() => _isSavingCompany = true);

              try {
                await _companyService.createCompany(
                  name: _nameController.text.trim(),
                  taxNumber: _optionalText(_taxNumberController),
                  phone: _optionalText(_phoneController),
                  email: _optionalText(_emailController),
                  address: _optionalText(_addressController),
                );

                if (!mounted) return;
                setDialogState(() => _isSavingCompany = false);
                navigator.pop();
                _reloadCompanies();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Company created.')),
                );
              } catch (error) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
                setDialogState(() => _isSavingCompany = false);
              }
            }

            return AlertDialog(
              title: const Text('Add Company'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _taxNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Tax number',
                        ),
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSavingCompany
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _isSavingCompany ? null : submit,
                  child: _isSavingCompany
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleCompanyStatus(Company company) async {
    try {
      await _companyService.updateCompanyStatus(company.id, !company.isActive);
      if (!mounted) return;
      _reloadCompanies();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            company.isActive ? 'Company deactivated.' : 'Company activated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteCompany(Company company) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Company'),
          content: Text('Deactivate ${company.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _companyService.deleteCompany(company.id);
      if (!mounted) return;
      _reloadCompanies();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Company deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companies')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCompanyDialog,
        child: const Icon(Icons.add),
      ),
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
              separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'status') {
                          _toggleCompanyStatus(company);
                        } else if (value == 'delete') {
                          _deleteCompany(company);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'status',
                          child: Text(
                            company.isActive ? 'Deactivate' : 'Activate',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
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
