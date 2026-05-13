class Company {
  const Company({
    required this.id,
    required this.name,
    this.taxNumber,
    this.phone,
    this.email,
    this.address,
    required this.isActive,
  });

  final int id;
  final String name;
  final String? taxNumber;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      taxNumber: json['tax_number']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      isActive: json['is_active'] != false,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
