import '../api/api_client.dart';
import '../models/charging_session.dart';
import 'json_helpers.dart';

class ChargingSessionService {
  ChargingSessionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ChargingSession> startSession({required int reservationId}) async {
    return ChargingSession.fromJson(
      parseObject(
        await _apiClient.post(
          '/charging-sessions/start',
          body: {'reservation_id': reservationId},
        ),
      ),
    );
  }

  Future<ChargingSession> finishSession({
    required int sessionId,
    String? endTime,
  }) async {
    return ChargingSession.fromJson(
      parseObject(
        await _apiClient.patch(
          '/charging-sessions/$sessionId/finish',
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

  Future<List<ChargingSession>> getActiveSessions() async {
    return parseList(
      await _apiClient.get('/charging-sessions/my/active'),
      ChargingSession.fromJson,
    );
  }

  Future<ChargingSession> getSession(int sessionId) async {
    return ChargingSession.fromJson(
      parseObject(await _apiClient.get('/charging-sessions/$sessionId')),
    );
  }
}
