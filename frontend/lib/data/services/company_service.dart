import '../api/api_client.dart';
import '../models/company.dart';
import 'json_helpers.dart';

class CompanyService {
  CompanyService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Company>> getCompanies() async {
    final response = await _apiClient.get('/admin/all/');

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
}
