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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final member = members[index];

                return Card(
                  child: ListTile(
                    leading: Icon(
                      member.role.toUpperCase() == 'STATION_MANAGER'
                          ? Icons.manage_accounts_outlined
                          : Icons.badge_outlined,
                    ),
                    title: Text(
                      member.name == null || member.name!.isEmpty
                          ? 'User #${member.userId}'
                          : member.name!,
                    ),
                    subtitle: Text(
                      [
                        if (member.email != null && member.email!.isNotEmpty)
                          member.email!,
                        member.role,
                        member.isActive ? 'Active' : 'Inactive',
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
