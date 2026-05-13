import 'user.dart';

class CompanyMember {
  const CompanyMember({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    required this.isActive,
  });

  final int id;
  final int companyId;
  final int userId;
  final String role;
  final bool isActive;

  bool get isManager => role == 'COMPANY_MANAGER' || role == 'STATION_MANAGER';

  factory CompanyMember.fromJson(Map<String, dynamic> json) {
    return CompanyMember(
      id: _asInt(json['id']),
      companyId: _asInt(json['company_id'] ?? json['companyId']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      role: (json['role'] ?? '').toString(),
      isActive: json['is_active'] ?? json['isActive'] ?? false,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CompanyEmployee {
  const CompanyEmployee({required this.member, required this.user});

  final CompanyMember member;
  final AppUser user;

  factory CompanyEmployee.fromJson(Map<String, dynamic> json) {
    return CompanyEmployee(
      member: CompanyMember.fromJson(json['member'] as Map<String, dynamic>),
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
