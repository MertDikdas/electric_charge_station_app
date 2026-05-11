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
    bool rememberMe = false,
  }) async {
    final normalized = identifier.trim();
    if (normalized.isEmpty) {
      throw const ApiException('Telefon/e-posta gerekli');
    }

    final response = parseObject(
      await _apiClient.post(
        '/users/login',
        authorized: false,
        body: {'email': normalized, 'password': password},
      ),
    );

    final user = AppUser.fromJson(parseObject(response['user']));
    await _tokenStorage.saveSession(
      token: response['access_token']?.toString(),
      userId: user.id,
      role: user.role,
      rememberMe: rememberMe,
    );
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
          'email': mail,
          'balance': 0.0,
          'password': password,
        },
      ),
    );
    final user = AppUser.fromJson(parseObject(json['user']));
    await _tokenStorage.saveSession(
      token: json['access_token']?.toString(),
      userId: user.id,
      role: user.role,
    );
    return user;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } finally {
      await _tokenStorage.clear();
    }
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return (fullName.trim(), '');
    return (parts.first, parts.skip(1).join(' '));
  }
}
