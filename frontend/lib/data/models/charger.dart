class Charger {
  const Charger({
    required this.id,
    required this.stationId,
    required this.connectorType,
    required this.currentType,
    required this.status,
  });

  final int id;
  final int stationId;
  final String connectorType;
  final String currentType;
  final String status;

  factory Charger.fromJson(Map<String, dynamic> json) {
    return Charger(
      id: _asInt(json['id']),
      stationId: _asInt(json['station_id'] ?? json['stationId']),
      connectorType: (json['connector_type'] ?? json['connectorType'] ?? '')
          .toString(),
      currentType: (json['current_type'] ?? json['currentType'] ?? '')
          .toString(),
      status: (json['status'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'connector_type': connectorType,
      'current_type': currentType,
      'status': status,
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
