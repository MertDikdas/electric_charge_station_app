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
          '/charging-sessions/',
          body: {
            'reservation_id': reservationId,
            'start_time': _formatTime(DateTime.now()),
            'status': 'active',
          },
        ),
      ),
    );
  }

  Future<List<ChargingSession>> getSessions() async {
    return parseList(
      await _apiClient.get('/charging-sessions/'),
      ChargingSession.fromJson,
    );
  }

  String _formatTime(DateTime value) {
    String pad(int component) => component.toString().padLeft(2, '0');
    return '${pad(value.hour)}:${pad(value.minute)}:${pad(value.second)}';
  }
}
