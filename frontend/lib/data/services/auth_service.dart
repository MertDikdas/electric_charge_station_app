import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/token_storage.dart';
import '../models/user.dart';
import 'json_helpers.dart';

class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      _apiClient = apiClient ?? ApiClient(tokenStorage: tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AppUser?> login({
    required String identifier,
    required String password,
  }) async {
    final normalized = identifier.trim();
    if (normalized.isEmpty) {
      throw const ApiException('Telefon/e-posta gerekli');
    }

    final numericUserId = int.tryParse(normalized);
    if (numericUserId != null) {
      final user = AppUser.fromJson(
        parseObject(
          await _apiClient.get('/users/$numericUserId', authorized: false),
        ),
      );
      await _tokenStorage.saveSession(userId: user.id);
      return user;
    }

    final users = parseList(
      await _apiClient.get('/users/', authorized: false),
      AppUser.fromJson,
    );

    final user = users
        .where((candidate) {
          return candidate.mail.toLowerCase() == normalized.toLowerCase();
        })
        .cast<AppUser?>()
        .firstWhere((value) => value != null, orElse: () => null);

    if (user == null) {
      throw const ApiException('Kullanici bulunamadi');
    }

    await _tokenStorage.saveSession(userId: user.id);
    return user;
  }

  Future<AppUser> register({
    required String fullName,
    required String mail,
    required String password,
  }) async {
    final names = _splitName(fullName);
    final json = parseObject(
      await _apiClient.post(
        '/users/',
        authorized: false,
        body: {
          'name': names.$1,
          'surname': names.$2,
          'mail': mail,
          'balance': 0.0,
          'password': password,
        },
      ),
    );
    final user = AppUser.fromJson(json);
    await _tokenStorage.saveSession(userId: user.id);
    return user;
  }

  Future<void> logout() => _tokenStorage.clear();

  (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return (fullName.trim(), '');
    return (parts.first, parts.skip(1).join(' '));
  }
}
