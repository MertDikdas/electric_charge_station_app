import '../api/api_client.dart';
import '../models/charger.dart';
import 'json_helpers.dart';

class ChargerService {
  ChargerService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Charger> createCharger(Charger charger) async {
    return Charger.fromJson(
      parseObject(await _apiClient.post('/chargers/', body: charger.toJson())),
    );
  }

  Future<List<Charger>> getChargers() async {
    return parseList(await _apiClient.get('/chargers/'), Charger.fromJson);
  }

  Future<Charger> getCharger(int chargerId) async {
    return Charger.fromJson(
      parseObject(await _apiClient.get('/chargers/$chargerId')),
    );
  }
}
