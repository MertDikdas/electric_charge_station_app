class Reservation {
  const Reservation({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.chargerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  final int id;
  final int userId;
  final int vehicleId;
  final int chargerId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      vehicleId: _asInt(json['vehicle_id'] ?? json['vehicleId']),
      chargerId: _asInt(json['charger_id'] ?? json['chargerId']),
      date: (json['date'] ?? '').toString(),
      startTime: (json['start_time'] ?? json['startTime'] ?? '').toString(),
      endTime: (json['end_time'] ?? json['endTime'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
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
    required this.vehicleId,
    required this.chargerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'PENDING',
  });

  final int vehicleId;
  final int chargerId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'charger_id': chargerId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
    };
  }
}
