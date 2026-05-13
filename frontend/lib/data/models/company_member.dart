class CompanyMember {
  const CompanyMember({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    required this.isActive,
    this.name,
    this.email,
  });

  final int id;
  final int companyId;
  final int userId;
  final String role;
  final bool isActive;
  final String? name;
  final String? email;

  factory CompanyMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    return CompanyMember(
      id: _asInt(json['id']),
      companyId: _asInt(json['company_id'] ?? json['companyId']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      role: (json['role'] ?? '').toString(),
      isActive: json['is_active'] != false,
      name: user is Map<String, dynamic>
          ? '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim()
          : json['name']?.toString(),
      email: user is Map<String, dynamic>
          ? (user['email'] ?? user['mail'])?.toString()
          : (json['email'] ?? json['mail'])?.toString(),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
