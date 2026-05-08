import '../api/api_client.dart';
import '../models/charger.dart';
import '../models/station.dart';
import 'json_helpers.dart';

class StationService {
  StationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Station> createStation(Station station) async {
    return Station.fromJson(
      parseObject(await _apiClient.post('/stations/', body: station.toJson())),
    );
  }

  Future<List<Station>> getStations() async {
    return parseList(await _apiClient.get('/stations/'), Station.fromJson);
  }

  Future<Station> getStation(int stationId) async {
    return Station.fromJson(
      parseObject(await _apiClient.get('/stations/$stationId')),
    );
  }

  Future<Station> updateStation(int stationId, Station station) async {
    return Station.fromJson(
      parseObject(
        await _apiClient.put('/stations/$stationId', body: station.toJson()),
      ),
    );
  }

  Future<void> deleteStation(int stationId) {
    return _apiClient.delete('/stations/$stationId');
  }

  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    double kmRadius = 5,
  }) async {
    return parseList(
      await _apiClient.get(
        '/stations/nearby',
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'km_radius': kmRadius.toString(),
        },
      ),
      Station.fromJson,
    );
  }

  Future<List<Charger>> getStationChargers(int stationId) async {
    return parseList(
      await _apiClient.get('/stations/$stationId/chargers'),
      Charger.fromJson,
    );
  }
}
