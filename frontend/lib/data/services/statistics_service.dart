import '../api/api_client.dart';
import '../models/statistics.dart';
import 'json_helpers.dart';

class StatisticsService {
  StatisticsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AdminStatistics> getAdminStatistics({
    required int year,
    required int month,
    int limit = 10,
  }) async {
    final queryParameters = {
      'year': year.toString(),
      'month': month.toString(),
    };
    final limitedQueryParameters = {
      ...queryParameters,
      'limit': limit.toString(),
    };

    final responses = await Future.wait([
      _apiClient.get(
        '/statistics/admin/overview',
        queryParameters: queryParameters,
      ),
      _apiClient.get(
        '/statistics/admin/companies/revenue',
        queryParameters: limitedQueryParameters,
      ),
      _apiClient.get(
        '/statistics/admin/stations/revenue',
        queryParameters: limitedQueryParameters,
      ),
      _apiClient.get(
        '/statistics/admin/stations/usage',
        queryParameters: limitedQueryParameters,
      ),
      _apiClient.get('/statistics/admin/chargers/status'),
      _apiClient.get('/statistics/admin/reservations/status'),
    ]);

    return AdminStatistics(
      overview: AdminOverviewStatistics.fromJson(parseObject(responses[0])),
      companyRevenue: parseList(responses[1], CompanyRevenue.fromJson),
      stationRevenue: parseList(responses[2], StationRevenue.fromJson),
      stationUsage: parseList(responses[3], StationUsage.fromJson),
      chargerStatuses: parseList(responses[4], StatusCount.fromJson),
      reservationStatuses: parseList(responses[5], StatusCount.fromJson),
    );
  }
}
