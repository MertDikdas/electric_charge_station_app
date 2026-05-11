import '../api/api_client.dart';
import '../models/charging_session.dart';
import '../api/api_exception.dart';
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

  Future<ChargingSessionProgress?> fetchActiveProgress() async {
    try {
      return ChargingSessionProgress.fromJson(
        parseObject(await _apiClient.get('/charging-sessions/active/progress')),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
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
      final progress = await fetchActiveProgress();

      if (progress == null) return null;

      return ChargingSession(
        id: progress.sessionId,
        reservationId: progress.reservationId,
        startTime: '',
        endTime: '',
        consumedEnergy: progress.estimatedEnergyKwh,
        totalCost: progress.estimatedCost,
        status: progress.status,
      );
    } catch (error) {
      return null;
    }
  }

  Future<ChargingSession> getSession(int sessionId) async {
    return ChargingSession.fromJson(
      parseObject(await _apiClient.get('/charging-sessions/$sessionId')),
    );
  }
}
