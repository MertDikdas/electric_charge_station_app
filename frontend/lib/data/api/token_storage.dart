class TokenStorage {
  static String? _token;
  static int? _userId;
  static String? _role;

  Future<String?> readToken() async => _token;

  Future<int?> readUserId() async => _userId;

  Future<String?> readUserRole() async => _role;

  Future<void> saveSession({String? token, int? userId, String? role}) async {
    if (token != null && token.isNotEmpty) {
      _token = token;
    }
    if (userId != null) {
      _userId = userId;
    }
    if (role != null && role.isNotEmpty) {
      _role = role;
    }
  }

  Future<void> clear() async {
    _token = null;
    _userId = null;
    _role = null;
  }
}
