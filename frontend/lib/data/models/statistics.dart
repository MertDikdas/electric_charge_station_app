class AdminOverviewStatistics {
  const AdminOverviewStatistics({
    required this.totalUsers,
    required this.totalCompanies,
    required this.activeCompanies,
    required this.totalStations,
    required this.availableStations,
    required this.totalChargers,
    required this.availableChargers,
    required this.activeSessions,
    required this.totalReservations,
    required this.completedPayments,
    required this.monthlyRevenue,
    required this.totalEnergyConsumed,
  });

  final int totalUsers;
  final int totalCompanies;
  final int activeCompanies;
  final int totalStations;
  final int availableStations;
  final int totalChargers;
  final int availableChargers;
  final int activeSessions;
  final int totalReservations;
  final int completedPayments;
  final double monthlyRevenue;
  final double totalEnergyConsumed;

  factory AdminOverviewStatistics.fromJson(Map<String, dynamic> json) {
    return AdminOverviewStatistics(
      totalUsers: _asInt(json['total_users'] ?? json['totalUsers']),
      totalCompanies: _asInt(json['total_companies'] ?? json['totalCompanies']),
      activeCompanies: _asInt(
        json['active_companies'] ?? json['activeCompanies'],
      ),
      totalStations: _asInt(json['total_stations'] ?? json['totalStations']),
      availableStations: _asInt(
        json['available_stations'] ?? json['availableStations'],
      ),
      totalChargers: _asInt(json['total_chargers'] ?? json['totalChargers']),
      availableChargers: _asInt(
        json['available_chargers'] ?? json['availableChargers'],
      ),
      activeSessions: _asInt(json['active_sessions'] ?? json['activeSessions']),
      totalReservations: _asInt(
        json['total_reservations'] ?? json['totalReservations'],
      ),
      completedPayments: _asInt(
        json['completed_payments'] ?? json['completedPayments'],
      ),
      monthlyRevenue: _asDouble(
        json['monthly_revenue'] ?? json['monthlyRevenue'],
      ),
      totalEnergyConsumed: _asDouble(
        json['total_energy_consumed'] ?? json['totalEnergyConsumed'],
      ),
    );
  }
}

class CompanyRevenue {
  const CompanyRevenue({
    required this.companyId,
    required this.companyName,
    required this.revenue,
  });

  final int companyId;
  final String companyName;
  final double revenue;

  factory CompanyRevenue.fromJson(Map<String, dynamic> json) {
    return CompanyRevenue(
      companyId: _asInt(json['company_id'] ?? json['companyId']),
      companyName: (json['company_name'] ?? json['companyName'] ?? '')
          .toString(),
      revenue: _asDouble(json['revenue']),
    );
  }
}

class StationRevenue {
  const StationRevenue({
    required this.stationId,
    required this.stationAddress,
    required this.revenue,
  });

  final int stationId;
  final String stationAddress;
  final double revenue;

  factory StationRevenue.fromJson(Map<String, dynamic> json) {
    return StationRevenue(
      stationId: _asInt(json['station_id'] ?? json['stationId']),
      stationAddress: (json['station_address'] ?? json['stationAddress'] ?? '')
          .toString(),
      revenue: _asDouble(json['revenue']),
    );
  }
}

class StationUsage {
  const StationUsage({
    required this.stationId,
    required this.stationAddress,
    required this.usageCount,
  });

  final int stationId;
  final String stationAddress;
  final int usageCount;

  factory StationUsage.fromJson(Map<String, dynamic> json) {
    return StationUsage(
      stationId: _asInt(json['station_id'] ?? json['stationId']),
      stationAddress: (json['station_address'] ?? json['stationAddress'] ?? '')
          .toString(),
      usageCount: _asInt(json['usage_count'] ?? json['usageCount']),
    );
  }
}

class StatusCount {
  const StatusCount({required this.status, required this.count});

  final String status;
  final int count;

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      status: (json['status'] ?? '').toString(),
      count: _asInt(json['count']),
    );
  }
}

class AdminStatistics {
  const AdminStatistics({
    required this.overview,
    required this.companyRevenue,
    required this.stationRevenue,
    required this.stationUsage,
    required this.chargerStatuses,
    required this.reservationStatuses,
  });

  final AdminOverviewStatistics overview;
  final List<CompanyRevenue> companyRevenue;
  final List<StationRevenue> stationRevenue;
  final List<StationUsage> stationUsage;
  final List<StatusCount> chargerStatuses;
  final List<StatusCount> reservationStatuses;
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
