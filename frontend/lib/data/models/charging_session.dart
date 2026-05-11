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
        json['consuming_power'] ??
            json['consumed_energy'] ??
            json['consumedEnergy'],
      ),
      totalCost: _asDouble(
        json['cost'] ?? json['total_cost'] ?? json['totalCost'],
      ),
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

class ChargingSessionProgress {
  const ChargingSessionProgress({
    required this.sessionId,
    required this.reservationId,
    required this.status,
    required this.elapsedMinutes,
    required this.estimatedEnergyKwh,
    required this.estimatedCost,
    required this.progressPercent,
  });

  final int sessionId;
  final int reservationId;
  final String status;
  final int elapsedMinutes;
  final double estimatedEnergyKwh;
  final double estimatedCost;
  final double progressPercent;

  factory ChargingSessionProgress.fromJson(Map<String, dynamic> json) {
    return ChargingSessionProgress(
      sessionId: json['session_id'] as int,
      reservationId: json['reservation_id'] as int,
      status: json['status'] as String,
      elapsedMinutes: json['elapsed_minutes'] as int,
      estimatedEnergyKwh: (json['estimated_energy_kwh'] as num).toDouble(),
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
      progressPercent: (json['progress_percent'] as num).toDouble(),
    );
  }
}
