import '../api/api_client.dart';
import '../models/charging_session.dart';
import 'json_helpers.dart';

class ChargingSessionService {
  ChargingSessionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ChargingSession> startSession() async {
    return ChargingSession.fromJson(
      parseObject(await _apiClient.post('/charging-sessions/start', body: {})),
    );
  }

  Future<ChargingSession> finishSession({required int sessionId}) async {
    final now = DateTime.now();

    final endTime =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    return ChargingSession.fromJson(
      parseObject(
        await _apiClient.patch(
          '/charging-sessions/finish',
          body: {'end_time': endTime},
        ),
      ),
    );
  }

  Future<List<ChargingSession>> getSessions() async {
    return parseList(
      await _apiClient.get('/charging-sessions/my'),
      ChargingSession.fromJson,
    );
  }

  Future<List<ChargingSession>> getAllSessions() async {
    return parseList(
      await _apiClient.get('/charging-sessions/all'),
      ChargingSession.fromJson,
    );
  }

  Future<ChargingSession?> getActiveSession() async {
    try {
      final response = await _apiClient.get('/charging-sessions/active');

      if (response == null) return null;

      return ChargingSession.fromJson(parseObject(response));
    } catch (error) {
      final message = error.toString();

      if (message.contains('404') ||
          message.contains('No active') ||
          message.contains('not found')) {
        return null;
      }

      rethrow;
    }
  }

  Future<ChargingSession> getSession(int sessionId) async {
    return ChargingSession.fromJson(
      parseObject(await _apiClient.get('/charging-sessions/$sessionId')),
    );
  }
}
