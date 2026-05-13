class StationUsage {
  const StationUsage({
    required this.stationId,
    required this.stationName,
    required this.usageCount,
    required this.energyDelivered,
  });

  final int stationId;
  final String stationName;
  final int usageCount;
  final double energyDelivered;

  factory StationUsage.fromJson(Map<String, dynamic> json) {
    return StationUsage(
      stationId: _asInt(json['station_id'] ?? json['stationId']),
      stationName: (json['station_name'] ?? json['stationName'] ?? '')
          .toString(),
      usageCount: _asInt(json['usage_count'] ?? json['usageCount']),
      energyDelivered: _asDouble(
        json['energy_delivered'] ?? json['energyDelivered'],
      ),
    );
  }
}

class MonthlyRevenuePoint {
  const MonthlyRevenuePoint({
    required this.month,
    required this.revenue,
    required this.kwh,
  });

  final int month;
  final double revenue;
  final double kwh;

  factory MonthlyRevenuePoint.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenuePoint(
      month: _asInt(json['month']),
      revenue: _asDouble(json['revenue']),
      kwh: _asDouble(json['kwh']),
    );
  }
}

class StationRevenue {
  const StationRevenue({
    required this.stationId,
    required this.stationName,
    required this.revenue,
  });

  final int stationId;
  final String stationName;
  final double revenue;

  factory StationRevenue.fromJson(Map<String, dynamic> json) {
    return StationRevenue(
      stationId: _asInt(json['station_id'] ?? json['stationId']),
      stationName: (json['station_name'] ?? json['stationName'] ?? '')
          .toString(),
      revenue: _asDouble(json['revenue']),
    );
  }
}

class CompanyRevenue {
  const CompanyRevenue({
    required this.revenue,
    required this.monthly,
    required this.stations,
  });

  final double revenue;
  final List<MonthlyRevenuePoint> monthly;
  final List<StationRevenue> stations;

  factory CompanyRevenue.fromJson(Map<String, dynamic> json) {
    return CompanyRevenue(
      revenue: _asDouble(json['revenue']),
      monthly: (json['monthly'] as List<dynamic>? ?? [])
          .map((item) => MonthlyRevenuePoint.fromJson(item))
          .toList(),
      stations: (json['stations'] as List<dynamic>? ?? [])
          .map((item) => StationRevenue.fromJson(item))
          .toList(),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
