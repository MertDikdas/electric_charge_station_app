import 'package:flutter/material.dart';

import '../../data/models/company.dart';
import '../../data/models/company_member.dart';
import '../../data/services/company_member_service.dart';

class CompanyMembersScreen extends StatefulWidget {
  const CompanyMembersScreen({super.key, required this.company});

  final Company company;

  @override
  State<CompanyMembersScreen> createState() => _CompanyMembersScreenState();
}

class _CompanyMembersScreenState extends State<CompanyMembersScreen> {
  final _memberService = CompanyMemberService();

  late Future<List<CompanyMember>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _memberService.getMembersByCompany(widget.company.id);
  }

  Future<void> _refreshMembers() async {
    setState(() {
      _membersFuture = _memberService.getMembersByCompany(widget.company.id);
    });

    await _membersFuture;
  }

  String _memberDisplayName(CompanyMember member) {
    final name = member.name?.trim();
    final email = member.email?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'User #${member.userId}';
  }

  String _formatRole(String role) {
    switch (role.toUpperCase()) {
      case 'STATION_MANAGER':
        return 'Station Manager';
      case 'STATION_OPERATOR':
        return 'Station Operator';
      case 'ADMIN':
        return 'Admin';
      default:
        return role
            .split('_')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  String _formatBalance(double balance) {
    return balance.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.company.name} Members')),
      body: RefreshIndicator(
        onRefresh: _refreshMembers,
        child: FutureBuilder<List<CompanyMember>>(
          future: _membersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Members could not be loaded.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final members = snapshot.data ?? [];

            if (members.isEmpty) {
              return ListView(
                padding: EdgeInsets.all(16),
                children: [Center(child: Text('No members found.'))],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final member = members[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),

                    leading: CircleAvatar(
                      child: Icon(
                        member.role.toUpperCase() == 'STATION_MANAGER'
                            ? Icons.manage_accounts_outlined
                            : Icons.badge_outlined,
                      ),
                    ),

                    title: Text(
                      _memberDisplayName(member),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (member.email != null && member.email!.isNotEmpty)
                            Text(member.email!),

                          const SizedBox(height: 6),

                          Text('User ID: ${member.userId}'),

                          if (member.userRole != null &&
                              member.userRole!.isNotEmpty)
                            Text('User role: ${_formatRole(member.userRole!)}'),

                          if (member.userBalance != null)
                            Text(
                              'Balance: ${_formatBalance(member.userBalance!)}',
                            ),

                          const SizedBox(height: 6),

                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(
                                label: Text(_formatRole(member.role)),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              Chip(
                                label: Text(
                                  member.isActive ? 'Active' : 'Inactive',
                                ),
                                backgroundColor: member.isActive
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.red.withValues(alpha: 0.12),
                                labelStyle: TextStyle(
                                  color: member.isActive
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              if (member.userIsActive != null)
                                Chip(
                                  label: Text(
                                    member.userIsActive!
                                        ? 'User Active'
                                        : 'User Inactive',
                                  ),
                                  backgroundColor: member.userIsActive!
                                      ? Colors.blue.withValues(alpha: 0.12)
                                      : Colors.orange.withValues(alpha: 0.12),
                                  labelStyle: TextStyle(
                                    color: member.userIsActive!
                                        ? Colors.blue
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    trailing: const Icon(Icons.chevron_right),
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
