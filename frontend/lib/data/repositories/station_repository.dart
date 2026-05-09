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

  Future<List<Station>> fetchNearbyStationsByAreaByVehicle({
    required double northLatitude,
    required double southLatitude,
    required double eastLongitude,
    required double westLongitude,
    required int vehicleId,
  }) {
    return _stationService.getNearbyStationsByAreaByVehicle(
      northLatitude: northLatitude,
      southLatitude: southLatitude,
      eastLongitude: eastLongitude,
      westLongitude: westLongitude,
      vehicleId: vehicleId,
    );
  }

  Future<List<Station>> fetchNearbyStationsByArea({
    required double northLatitude,
    required double southLatitude,
    required double eastLongitude,
    required double westLongitude,
  }) {
    return _stationService.getNearbyStationsByArea(
      northLatitude: northLatitude,
      southLatitude: southLatitude,
      eastLongitude: eastLongitude,
      westLongitude: westLongitude,
    );
  }

  Future<List<Charger>> fetchStationChargers(int stationId) {
    return _stationService.getStationChargers(stationId);
  }
}
