class Station {
  const Station({
    required this.id,
    required this.address,
    required this.companyId,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  final int id;
  final String address;
  final int companyId;
  final double latitude;
  final double longitude;
  final String status;

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: _asInt(json['id']),
      address: (json['address'] ?? '').toString(),
      companyId: _asInt(json['company_id'] ?? json['companyId']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      status: (json['status'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'company_id': companyId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
