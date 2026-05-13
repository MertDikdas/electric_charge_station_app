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

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String?> queryParameters = const {},
  }) {
    return _send('PUT', path, body: body, queryParameters: queryParameters);
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, String?> queryParameters = const {},
  }) {
    return _send('PATCH', path, body: body, queryParameters: queryParameters);
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
    late final http.Response response;
    try {
      response = switch (method) {
        'GET' => await _httpClient.get(uri, headers: headers),
        'POST' => await _httpClient.post(
          uri,
          headers: headers,
          body: encodedBody,
        ),
        'PUT' => await _httpClient.put(
          uri,
          headers: headers,
          body: encodedBody,
        ),
        'PATCH' => await _httpClient.patch(
          uri,
          headers: headers,
          body: encodedBody,
        ),
        'DELETE' => await _httpClient.delete(uri, headers: headers),
        _ => throw ArgumentError('Unsupported method: $method'),
      };
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Could not connect to the server. Please check your internet connection and try again.',
      );
    }

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
      return _statusMessage(response.statusCode);
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final detail =
            decoded['detail'] ?? decoded['message'] ?? decoded['error'];
        if (detail is String) {
          return _friendlyStringMessage(detail, response.statusCode);
        }
        if (detail is List && detail.isNotEmpty) {
          return _friendlyValidationErrors(detail, response.statusCode);
        }
      }
    } catch (_) {
      return _friendlyStringMessage(response.body, response.statusCode);
    }

    return _statusMessage(response.statusCode);
  }

  String _friendlyValidationErrors(List<dynamic> errors, int statusCode) {
    final messages = errors
        .whereType<Map>()
        .map((error) => _friendlyValidationError(error))
        .where((message) => message.isNotEmpty)
        .toList();

    if (messages.isEmpty) {
      return _statusMessage(statusCode);
    }

    return messages.take(3).join('\n');
  }

  String _friendlyValidationError(Map<dynamic, dynamic> error) {
    final field = _fieldLabel(error['loc']);
    final type = error['type']?.toString() ?? '';
    final message = error['msg']?.toString() ?? '';

    if (message.toLowerCase().contains('field cannot be empty')) {
      return '$field cannot be empty.';
    }
    if (message.toLowerCase().contains('field required') || type == 'missing') {
      return '$field is required.';
    }
    if (type.contains('none_required')) {
      return '$field has an invalid value. Please check it and try again.';
    }
    if (type.contains('int_parsing') || type.contains('float_parsing')) {
      return '$field must be a number.';
    }
    if (type.contains('greater_than')) {
      return '$field must be greater than zero.';
    }
    if (type.contains('greater_than_equal')) {
      return '$field cannot be negative.';
    }
    if (type.contains('literal_error')) {
      return '$field has an unsupported option selected.';
    }
    if (type.contains('value_error') && message.isNotEmpty) {
      return '$field: ${_stripTechnicalPrefix(message)}';
    }
    if (message.isNotEmpty) {
      return '$field: ${_stripTechnicalPrefix(message)}';
    }

    return '$field has an invalid value.';
  }

  String _friendlyStringMessage(String message, int statusCode) {
    final clean = _stripTechnicalPrefix(message).trim();
    final lower = clean.toLowerCase();

    if (lower.contains('invalid credentials')) {
      return 'Email or password is incorrect.';
    }
    if (lower.contains('deactivated') || lower.contains('inactive account')) {
      return 'Your account has been deactivated. Please contact support.';
    }
    if (lower.contains('authentication required') ||
        lower.contains('invalid or expired')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (lower.contains('not enough permissions') ||
        lower.contains('permission') ||
        lower.contains('forbidden')) {
      return 'You do not have permission to perform this action.';
    }
    if (lower.contains('already registered')) {
      return 'This email is already registered.';
    }
    if (lower.contains('already a member')) {
      return 'This user is already a member of the company.';
    }
    if (lower.contains('company membership required')) {
      return 'You need an active company membership to use this page.';
    }
    if (lower.contains('not found')) {
      return 'The requested item could not be found. It may have been removed.';
    }
    if (lower.contains('one reservation per day')) {
      return 'You already have a reservation for this day.';
    }
    if (lower.contains('slot is already occupied') ||
        lower.contains('conflict') ||
        lower.contains('overlap')) {
      return 'That time range is already reserved. Please choose another time.';
    }
    if (lower.contains('reservation is in the past')) {
      return 'That time has already passed. Please choose a future time.';
    }
    if (lower.contains('duration cannot exceed')) {
      return 'Reservation duration cannot exceed 2 hours.';
    }
    if (lower.contains('duration must be at least')) {
      return 'Reservation duration must be at least 15 minutes.';
    }
    if (lower.contains('align to 15-minute')) {
      return 'Reservation time must align to 15-minute intervals.';
    }
    if (lower.contains('charger is not available')) {
      return 'This charger is not available right now.';
    }
    if (lower.contains('station is not available')) {
      return 'This station is not available right now.';
    }
    if (lower.contains('vehicle does not belong')) {
      return 'Please choose one of your own vehicles.';
    }
    if (lower.contains('vehicle and charger are not compatible')) {
      return 'This vehicle is not compatible with the selected charger.';
    }
    if (clean.isNotEmpty && !clean.startsWith('{') && !clean.startsWith('[')) {
      return clean;
    }

    return _statusMessage(statusCode);
  }

  String _statusMessage(int statusCode) {
    return switch (statusCode) {
      400 =>
        'The request could not be completed. Please check the entered information.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested item could not be found.',
      409 =>
        'This action conflicts with existing data. Please refresh and try again.',
      422 => 'Some information is missing or invalid. Please check the form.',
      >= 500 => 'The server had a problem. Please try again shortly.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  String _fieldLabel(Object? loc) {
    final rawField = switch (loc) {
      List values when values.isNotEmpty => values.last.toString(),
      String value => value,
      _ => 'This field',
    };

    final labels = {
      'name': 'Name',
      'surname': 'Surname',
      'email': 'Email',
      'password': 'Password',
      'balance': 'Balance',
      'vehicle_id': 'Vehicle',
      'charger_id': 'Charger',
      'station_id': 'Station',
      'company_id': 'Company',
      'user_id': 'User',
      'date': 'Date',
      'start_time': 'Start time',
      'end_time': 'End time',
      'duration_minutes': 'Duration',
      'connector_type': 'Connector type',
      'current_type': 'Current type',
      'max_power': 'Power output',
      'price_per_kwh': 'Price per kWh',
      'status': 'Status',
      'plate': 'Plate number',
      'battery_capacity': 'Battery capacity',
      'max_charging_power': 'Max charging power',
    };

    return labels[rawField] ??
        rawField
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
  }

  String _stripTechnicalPrefix(String message) {
    return message
        .replaceFirst(RegExp(r'^Value error,\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^ApiException:\s*', caseSensitive: false), '');
  }
}
