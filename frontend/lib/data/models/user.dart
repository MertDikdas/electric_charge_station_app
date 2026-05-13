class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.surname,
    required this.mail,
    required this.balance,
    this.role = 'USER',
    this.companyId,
    this.membershipRole,
  });

  final int id;
  final String name;
  final String surname;
  final String mail;
  final double balance;
  final String role;
  final int? companyId;
  final String? membershipRole;

  String get fullName =>
      [name, surname].where((part) => part.isNotEmpty).join(' ');

  String get effectiveRole {
    if (companyId != null && (membershipRole?.isNotEmpty ?? false)) {
      return membershipRole!;
    }
    return role;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      surname: (json['surname'] ?? '').toString(),
      mail: (json['mail'] ?? json['email'] ?? '').toString(),
      balance: _asDouble(json['balance']),
      role: (json['role'] ?? 'USER').toString(),
      companyId: _nullableInt(json['company_id'] ?? json['companyId']),
      membershipRole: (json['membership_role'] ?? json['membershipRole'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson({String? password}) {
    final json = {
      'name': name,
      'surname': surname,
      'email': mail,
      'balance': balance,
    };
    if (password != null) {
      json['password'] = password;
    }
    return json;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
