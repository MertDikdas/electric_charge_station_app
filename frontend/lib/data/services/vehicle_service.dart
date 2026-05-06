import '../api/api_client.dart';
import '../models/charger.dart';
import '../models/vehicle.dart';
import 'json_helpers.dart';

class VehicleService {
  VehicleService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Vehicle> createVehicle(VehicleInput input) async {
    return Vehicle.fromJson(
      parseObject(await _apiClient.post('/vehicles/', body: input.toJson())),
    );
  }

  Future<List<Vehicle>> getVehicles() async {
    return parseList(await _apiClient.get('/vehicles/'), Vehicle.fromJson);
  }

  Future<Vehicle> getVehicle(int vehicleId) async {
    return Vehicle.fromJson(
      parseObject(await _apiClient.get('/vehicles/$vehicleId')),
    );
  }

  Future<List<Charger>> getCompatibleChargers(int vehicleId) async {
    return parseList(
      await _apiClient.get('/vehicles/$vehicleId/compatible-chargers'),
      Charger.fromJson,
    );
  }

  Future<Vehicle> updateVehicle(int vehicleId, VehicleInput input) async {
    return Vehicle.fromJson(
      parseObject(
        await _apiClient.put('/vehicles/$vehicleId', body: input.toJson()),
      ),
    );
  }

  Future<void> deleteVehicle(int vehicleId) {
    return _apiClient.delete('/vehicles/$vehicleId');
  }
}
