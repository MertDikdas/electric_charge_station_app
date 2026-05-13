import '../api/api_client.dart';
import '../models/charger.dart';
import 'json_helpers.dart';

class ChargerService {
  ChargerService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Charger> createCharger(Charger charger) async {
    return Charger.fromJson(
      parseObject(await _apiClient.post('/chargers', body: charger.toJson())),
    );
  }

  Future<List<Charger>> getChargers() async {
    return parseList(await _apiClient.get('/chargers/all'), Charger.fromJson);
  }

  Future<Charger> getCharger(int chargerId) async {
    return Charger.fromJson(
      parseObject(await _apiClient.get('/chargers/$chargerId')),
    );
  }

  Future<Charger> updateCharger(int chargerId, Charger charger) async {
    return Charger.fromJson(
      parseObject(
        await _apiClient.put('/chargers/$chargerId', body: charger.toJson()),
      ),
    );
  }

  Future<void> deleteCharger(int chargerId) {
    return _apiClient.delete('/chargers/$chargerId');
  }

  Future<Charger> updateChargerStatus(int chargerId, String status) async {
    return Charger.fromJson(
      parseObject(
        await _apiClient.patch(
          '/chargers/$chargerId/status',
          body: {'status': status},
        ),
      ),
    );
  }

  Future<List<dynamic>> getChargerAvailability({
    required int chargerId,
    required String startDate,
    required String endDate,
  }) async {
    final json = await _apiClient.get(
      '/chargers/$chargerId/availability',
      queryParameters: {'start_date': startDate, 'end_date': endDate},
    );
    return json is List ? json : const [];
  }
}
