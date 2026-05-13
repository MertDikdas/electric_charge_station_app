import '../api/api_client.dart';
import '../models/company_member.dart';
import 'json_helpers.dart';

class CompanyMemberService {
  CompanyMemberService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CompanyMember>> getMembersByCompany(int companyId) async {
    final response = await _apiClient.get(
      '/admin/company-members/by-company/$companyId',
    );

    if (response is List) {
      return response
          .map((item) => CompanyMember.fromJson(parseObject(item)))
          .toList();
    }

    final object = parseObject(response);
    final members = object['members'];

    if (members is! List) {
      return [];
    }

    return members
        .map((item) => CompanyMember.fromJson(parseObject(item)))
        .toList();
  }
}
