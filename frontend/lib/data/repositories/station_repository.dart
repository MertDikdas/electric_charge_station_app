import '../models/charger.dart';
import '../models/station.dart';
import '../services/station_service.dart';

class StationRepository {
  StationRepository({StationService? stationService})
    : _stationService = stationService ?? StationService();

  final StationService _stationService;

  Future<List<Station>> fetchStations() {
    return _stationService.getStations();
  }

  Future<List<Charger>> fetchStationChargers(int stationId) {
    return _stationService.getStationChargers(stationId);
  }
}
