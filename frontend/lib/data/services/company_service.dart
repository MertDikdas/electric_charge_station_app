import '../api/api_client.dart';
import '../models/company_member.dart';
import '../models/company_statistics.dart';
import '../models/station.dart';
import 'json_helpers.dart';

class CompanyService {
  CompanyService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CompanyEmployee>> getMyCompanyEmployees() async {
    return parseList(
      await _apiClient.get('/users/my/company'),
      CompanyEmployee.fromJson,
    );
  }

  Future<CompanyMember> addCompanyMember({
    required int companyId,
    required int userId,
    required String role,
  }) async {
    return CompanyMember.fromJson(
      parseObject(
        await _apiClient.post(
          '/company-members',
          body: {
            'company_id': companyId,
            'user_id': userId,
            'role': role,
            'is_active': true,
          },
        ),
      ),
    );
  }

  Future<CompanyMember> removeCompanyMember(int memberId) async {
    return CompanyMember.fromJson(
      parseObject(
        await _apiClient.patch(
          '/admin/company-members/$memberId/status',
          body: {'is_active': false},
        ),
      ),
    );
  }

  Future<List<Station>> getMyCompanyStations() async {
    return parseList(
      await _apiClient.get('/stations/my/company'),
      Station.fromJson,
    );
  }

  Future<CompanyRevenue> getCompanyRevenue({int? year, int? month}) async {
    return CompanyRevenue.fromJson(
      parseObject(
        await _apiClient.get(
          '/statistics/company-revenue',
          queryParameters: {
            if (year != null) 'year': year.toString(),
            if (month != null) 'month': month.toString(),
          },
        ),
      ),
    );
  }

  Future<List<StationUsage>> getStationUsage() async {
    return parseList(
      await _apiClient.get('/statistics/station-usage'),
      StationUsage.fromJson,
    );
  }
}
