import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth.token';
  static const _userIdKey = 'auth.userId';
  static const _roleKey = 'auth.role';
  static const _rememberMeKey = 'auth.rememberMe';
  static const _expiresAtKey = 'auth.expiresAt';
  static const _rememberMeDuration = Duration(days: 30);

  static String? _token;
  static int? _userId;
  static String? _role;
  static bool _loadedPersistedSession = false;

  Future<String?> readToken() async {
    await _loadPersistedSession();
    return _token;
  }

  Future<int?> readUserId() async {
    await _loadPersistedSession();
    return _userId;
  }

  Future<String?> readUserRole() async {
    await _loadPersistedSession();
    return _role;
  }

  Future<bool> hasRememberedSession() async {
    await _loadPersistedSession();
    return _token != null && _token!.isNotEmpty;
  }

  Future<void> saveSession({
    String? token,
    int? userId,
    String? role,
    bool rememberMe = false,
  }) async {
    if (token != null && token.isNotEmpty) {
      _token = token;
    }
    if (userId != null) {
      _userId = userId;
    }
    if (role != null && role.isNotEmpty) {
      _role = role;
    }

    final prefs = await SharedPreferences.getInstance();
    if (rememberMe && _token != null && _token!.isNotEmpty) {
      await prefs.setString(_tokenKey, _token!);
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(
        _expiresAtKey,
        DateTime.now().add(_rememberMeDuration).toIso8601String(),
      );
      if (_userId != null) {
        await prefs.setInt(_userIdKey, _userId!);
      }
      if (_role != null && _role!.isNotEmpty) {
        await prefs.setString(_roleKey, _role!);
      }
    } else {
      await _clearPersistedSession(prefs);
    }
  }

  Future<void> clear() async {
    _token = null;
    _userId = null;
    _role = null;
    _loadedPersistedSession = false;
    await _clearPersistedSession(await SharedPreferences.getInstance());
  }

  Future<void> _loadPersistedSession() async {
    if (_loadedPersistedSession) return;
    _loadedPersistedSession = true;

    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final token = prefs.getString(_tokenKey);
    final expiresAt = DateTime.tryParse(prefs.getString(_expiresAtKey) ?? '');

    if (!rememberMe ||
        token == null ||
        token.isEmpty ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      await _clearPersistedSession(prefs);
      return;
    }

    _token = token;
    _userId = prefs.getInt(_userIdKey);
    _role = prefs.getString(_roleKey);
  }

  Future<void> _clearPersistedSession(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_expiresAtKey);
  }
}
