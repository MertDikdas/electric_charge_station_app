import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, TokenStorage? tokenStorage})
    : _httpClient = httpClient ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;

  Future<dynamic> get(
    String path, {
    Map<String, String?> queryParameters = const {},
    bool authorized = true,
  }) {
    return _send(
      'GET',
      path,
      queryParameters: queryParameters,
      authorized: authorized,
    );
  }

  Future<dynamic> post(String path, {Object? body, bool authorized = true}) {
    return _send('POST', path, body: body, authorized: authorized);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String?> queryParameters = const {},
    bool authorized = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: {
        for (final entry in queryParameters.entries)
          if (entry.value != null) entry.key: entry.value,
      },
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authorized) {
      final userId = await _tokenStorage.readUserId();
      if (userId != null) {
        headers['X-User-Id'] = userId.toString();
      }

      final role = await _tokenStorage.readUserRole();
      if (role != null && role.isNotEmpty) {
        headers['X-User-Role'] = role;
      }

      final token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final encodedBody = body == null ? null : jsonEncode(body);
    final response = switch (method) {
      'GET' => await _httpClient.get(uri, headers: headers),
      'POST' => await _httpClient.post(
        uri,
        headers: headers,
        body: encodedBody,
      ),
      'PUT' => await _httpClient.put(uri, headers: headers, body: encodedBody),
      'PATCH' => await _httpClient.patch(
        uri,
        headers: headers,
        body: encodedBody,
      ),
      'DELETE' => await _httpClient.delete(uri, headers: headers),
      _ => throw ArgumentError('Unsupported method: $method'),
    };

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw ApiException(
      _extractErrorMessage(response),
      statusCode: response.statusCode,
    );
  }

  String _extractErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Sunucu hatasi (${response.statusCode})';
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final detail =
            decoded['detail'] ?? decoded['message'] ?? decoded['error'];
        if (detail is String) {
          return detail;
        }
        if (detail is List && detail.isNotEmpty) {
          return detail.first.toString();
        }
      }
    } catch (_) {
      return response.body;
    }

    return 'Sunucu hatasi (${response.statusCode})';
  }
}
