class Station {
  const Station({
    required this.id,
    required this.address,
    required this.company,
    required this.location,
    required this.status,
  });

  final int id;
  final String address;
  final String company;
  final String location;
  final String status;

  double? get latitude => _coordinateAt(0);
  double? get longitude => _coordinateAt(1);

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: _asInt(json['id']),
      address: (json['address'] ?? '').toString(),
      company: (json['company'] ?? json['name'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'company': company,
      'location': location,
      'status': status,
    };
  }

  double? _coordinateAt(int index) {
    final parts = location
        .split(RegExp(r'[,;\s]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.length <= index) return null;
    return double.tryParse(parts[index]);
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
