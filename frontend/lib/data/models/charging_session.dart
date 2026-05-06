class ChargingSession {
  const ChargingSession({
    required this.id,
    required this.reservationId,
    required this.startTime,
    required this.endTime,
    required this.consumedEnergy,
    required this.totalCost,
    required this.status,
  });

  final int id;
  final int reservationId;
  final String startTime;
  final String endTime;
  final double consumedEnergy;
  final double totalCost;
  final String status;

  factory ChargingSession.fromJson(Map<String, dynamic> json) {
    return ChargingSession(
      id: _asInt(json['id']),
      reservationId: _asInt(json['reservation_id'] ?? json['reservationId']),
      startTime: (json['start_time'] ?? json['startTime'] ?? '').toString(),
      endTime: (json['end_time'] ?? json['endTime'] ?? '').toString(),
      consumedEnergy: _asDouble(
        json['consumed_energy'] ?? json['consumedEnergy'],
      ),
      totalCost: _asDouble(json['total_cost'] ?? json['totalCost']),
      status: (json['status'] ?? '').toString(),
    );
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
