import 'package:flutter/material.dart';

import '../../data/models/company.dart';
import '../../data/services/company_member_service.dart';
import '../../data/services/user_service.dart';
import 'company_members_screen.dart';
import 'company_stations_screen.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({super.key, required this.company});

  final Company company;

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  final _memberService = CompanyMemberService();
  final _userService = UserService();
  final _managerEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isAddingManager = false;

  @override
  void dispose() {
    _managerEmailController.dispose();
    super.dispose();
  }

  Future<void> _showAddManagerDialog() async {
    _managerEmailController.clear();

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isAddingManager,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              setDialogState(() => _isAddingManager = true);

              try {
                final email = _managerEmailController.text.trim();
                final users = await _userService.getUsers();
                final matchingUsers = users.where(
                  (user) => user.mail.toLowerCase() == email.toLowerCase(),
                );

                if (matchingUsers.isEmpty) {
                  throw Exception('User with this email was not found.');
                }

                await _memberService.addMember(
                  companyId: widget.company.id,
                  userId: matchingUsers.first.id,
                  role: 'STATION_MANAGER',
                );

                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Manager added.')),
                );
              } catch (error) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
                setDialogState(() => _isAddingManager = false);
              }
            }

            return AlertDialog(
              title: const Text('Add Manager'),
              content: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _managerEmailController,
                  decoration: const InputDecoration(labelText: 'User email'),
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Email is required.';
                    }
                    if (!email.contains('@')) {
                      return 'Enter a valid email.';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isAddingManager
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _isAddingManager ? null : submit,
                  child: _isAddingManager
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() => _isAddingManager = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;

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
          Card(
            child: ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Add Manager'),
              subtitle: const Text('Add a station manager by email'),
              trailing: const Icon(Icons.add),
              onTap: _showAddManagerDialog,
            ),
          ),
        ],
      ),
    );
  }
}
