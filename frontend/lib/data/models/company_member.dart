import 'user.dart';

class CompanyMember {
  const CompanyMember({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    required this.isActive,
    this.name,
    this.surname,
    this.email,
    this.userRole,
    this.userBalance,
    this.userIsActive,
  });

  final int id;
  final int companyId;
  final int userId;
  final String role;
  final bool isActive;
  final String? name;
  final String? surname;
  final String? email;
  final String? userRole;
  final double? userBalance;
  final bool? userIsActive;

  factory CompanyMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userObject = user is Map<String, dynamic> ? user : null;
    final name = userObject?['name']?.toString();
    final surname = userObject?['surname']?.toString();

    return CompanyMember(
      id: _asInt(json['id']),
      companyId: _asInt(json['company_id'] ?? json['companyId']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      role: (json['role'] ?? '').toString(),
      isActive: json['is_active'] != false,
      name: userObject != null
          ? '${name ?? ''} ${surname ?? ''}'.trim()
          : json['name']?.toString(),
      surname: userObject != null ? surname : json['surname']?.toString(),
      email: userObject != null
          ? (userObject['email'] ?? userObject['mail'])?.toString()
          : (json['email'] ?? json['mail'])?.toString(),
      userRole: userObject != null
          ? userObject['role']?.toString()
          : json['user_role']?.toString(),
      userBalance: _asDouble(
        userObject != null
            ? userObject['balance']
            : json['balance'] ?? json['userBalance'],
      ),
      userIsActive: userObject != null
          ? userObject['is_active'] != false
          : json['user_is_active'] == null
          ? null
          : json['user_is_active'] != false,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class CompanyEmployee {
  const CompanyEmployee({required this.member, required this.user});

  final CompanyMember member;
  final AppUser user;

  factory CompanyEmployee.fromJson(Map<String, dynamic> json) {
    return CompanyEmployee(
      member: CompanyMember.fromJson(
        Map<String, dynamic>.from((json['member'] as Map?) ?? const {}),
      ),
      user: AppUser.fromJson(
        Map<String, dynamic>.from((json['user'] as Map?) ?? const {}),
      ),
    );
  }
}
