import '../api/api_client.dart';
import '../models/company.dart';
import 'json_helpers.dart';

class CompanyService {
  CompanyService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Company>> getCompanies() async {
    final response = await _apiClient.get('/admin/companies/all');

    if (response is List) {
      return response
          .map((item) => Company.fromJson(parseObject(item)))
          .toList();
    }

    final object = parseObject(response);
    final companies = object['companies'];

    if (companies is! List) {
      return [];
    }

    return companies
        .map((item) => Company.fromJson(parseObject(item)))
        .toList();
  }

  Future<Company> createCompany({
    required String name,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    bool isActive = true,
  }) async {
    return Company.fromJson(
      parseObject(
        await _apiClient.post(
          '/admin/companies/',
          body: {
            'name': name,
            'tax_number': taxNumber,
            'phone': phone,
            'email': email,
            'address': address,
            'is_active': isActive,
          },
        ),
      ),
    );
  }

  Future<Company> updateCompanyStatus(int companyId, bool isActive) async {
    return Company.fromJson(
      parseObject(
        await _apiClient.patch(
          '/admin/companies/$companyId/status',
          body: {'is_active': isActive},
        ),
      ),
    );
  }

  Future<void> deleteCompany(int companyId) {
    return _apiClient.delete('/admin/companies/$companyId');
  }
}
