class Charger {
  const Charger({
    required this.id,
    required this.stationId,
    required this.connectorType,
    required this.currentType,
    this.maxPower = 0,
    this.pricePerKwh = 0,
    required this.status,
    required this.isReservedNow,
  });

  final int id;
  final int stationId;
  final String connectorType;
  final String currentType;
  final double maxPower;
  final double pricePerKwh;
  final String status;
  final bool isReservedNow;

  factory Charger.fromJson(Map<String, dynamic> json) {
    return Charger(
      id: _asInt(json['id']),
      stationId: _asInt(json['station_id'] ?? json['stationId']),
      connectorType: (json['connector_type'] ?? json['connectorType'] ?? '')
          .toString(),
      currentType: (json['current_type'] ?? json['currentType'] ?? '')
          .toString(),
      maxPower: _asDouble(json['max_power'] ?? json['maxPower']),
      pricePerKwh: _asDouble(json['price_per_kwh'] ?? json['pricePerKwh']),
      status: (json['status'] ?? '').toString(),
      isReservedNow: json['is_reserved_now'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'connector_type': connectorType,
      'current_type': currentType,
      'max_power': maxPower,
      'price_per_kwh': pricePerKwh,
      'status': status,
      'isReservedNow': isReservedNow,
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
