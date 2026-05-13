class Reservation {
  const Reservation({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.chargerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.status,
    required this.stationId,
    this.stationName = '',
    this.chargerConnectorType = '',
    this.chargerCurrentType = '',
  });

  final int id;
  final int userId;
  final int vehicleId;
  final int chargerId;
  final int stationId;
  final String date;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final String status;
  final String stationName;
  final String chargerConnectorType;
  final String chargerCurrentType;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      vehicleId: _asInt(json['vehicle_id'] ?? json['vehicleId']),
      chargerId: _asInt(json['charger_id'] ?? json['chargerId']),
      stationId: _asInt(json['station_id'] ?? json['stationId']),
      date: (json['date'] ?? '').toString(),
      startTime: (json['start_time'] ?? json['startTime'] ?? '').toString(),
      endTime: (json['end_time'] ?? json['endTime'] ?? '').toString(),
      durationMinutes: _asInt(
        json['duration_minutes'] ?? json['durationMinutes'] ?? 120,
      ),
      status: (json['status'] ?? '').toString(),
      stationName: (json['station_name'] ?? json['stationName'] ?? '')
          .toString(),
      chargerConnectorType:
          (json['charger_connector_type'] ?? json['chargerConnectorType'] ?? '')
              .toString(),
      chargerCurrentType:
          (json['charger_current_type'] ?? json['chargerCurrentType'] ?? '')
              .toString(),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ReservationInput {
  const ReservationInput({
    this.stationId,
    required this.vehicleId,
    required this.chargerId,
    required this.date,
    required this.startTime,
    this.endTime,
    this.status = 'PENDING',
  });

  final int? stationId;
  final int vehicleId;
  final int chargerId;
  final String date;
  final String startTime;
  final String? endTime;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      if (stationId != null) 'station_id': stationId,
      'vehicle_id': vehicleId,
      'charger_id': chargerId,
      if (!_isIsoDateTime(startTime)) 'date': date,
      'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      'status': status,
    };
  }

  bool _isIsoDateTime(String value) => value.contains('T');
}
