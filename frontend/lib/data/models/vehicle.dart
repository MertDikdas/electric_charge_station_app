class Vehicle {
  const Vehicle({
    required this.id,
    required this.userId,
    required this.model,
    required this.plate,
    required this.maxChargingPower,
    required this.batteryCapacity,
    required this.connectorType,
    required this.currentType,
  });

  final int id;
  final int userId;
  final String model;
  final String plate;
  final double maxChargingPower;
  final double batteryCapacity;
  final String connectorType;
  final String currentType;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      model: (json['model'] ?? '').toString(),
      plate: (json['plate'] ?? json['license_plate'] ?? '').toString(),
      maxChargingPower: _asDouble(
        json['max_charging_power'] ?? json['maxChargingPower'],
      ),
      batteryCapacity: _asDouble(
        json['battery_capacity'] ?? json['batteryCapacity'],
      ),
      connectorType: (json['connector_type'] ?? json['connectorType'] ?? '')
          .toString(),
      currentType: (json['current_type'] ?? json['currentType'] ?? '')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'model': model,
      'plate': plate,
      'max_charging_power': maxChargingPower,
      'battery_capacity': batteryCapacity,
      'connector_type': connectorType,
      'current_type': currentType,
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

class VehicleInput {
  const VehicleInput({
    required this.userId,
    required this.model,
    required this.plate,
    required this.maxChargingPower,
    required this.batteryCapacity,
    required this.connectorType,
    required this.currentType,
  });

  final int userId;
  final String model;
  final String plate;
  final double maxChargingPower;
  final double batteryCapacity;
  final String connectorType;
  final String currentType;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'model': model,
      'plate': plate,
      'max_charging_power': maxChargingPower,
      'battery_capacity': batteryCapacity,
      'connector_type': connectorType,
      'current_type': currentType,
    };
  }
}
