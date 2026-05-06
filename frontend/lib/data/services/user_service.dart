import '../api/api_client.dart';
import '../models/charging_session.dart';
import '../models/reservation.dart';
import '../models/user.dart';
import '../models/vehicle.dart';
import 'json_helpers.dart';

class UserService {
  UserService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AppUser> createUser({
    required String name,
    required String surname,
    required String mail,
    required String password,
  }) async {
    final json = parseObject(
      await _apiClient.post(
        '/users/',
        body: {
          'name': name,
          'surname': surname,
          'mail': mail,
          'balance': 0.0,
          'password': password,
        },
      ),
    );
    return AppUser.fromJson(json);
  }

  Future<List<AppUser>> getUsers() async {
    return parseList(await _apiClient.get('/users/'), AppUser.fromJson);
  }

  Future<AppUser> getUser(int userId) async {
    return AppUser.fromJson(
      parseObject(await _apiClient.get('/users/$userId')),
    );
  }

  Future<AppUser> updateUser(
    int userId,
    AppUser user, {
    String? password,
  }) async {
    return AppUser.fromJson(
      parseObject(
        await _apiClient.put(
          '/users/$userId',
          body: user.toJson(password: password),
        ),
      ),
    );
  }

  Future<List<Vehicle>> getUserVehicles(int userId) async {
    return parseList(
      await _apiClient.get('/users/$userId/vehicles'),
      Vehicle.fromJson,
    );
  }

  Future<List<Reservation>> getUserReservations(int userId) async {
    return parseList(
      await _apiClient.get('/users/$userId/reservations'),
      Reservation.fromJson,
    );
  }

  Future<List<ChargingSession>> getUserChargingSessions(int userId) async {
    return parseList(
      await _apiClient.get('/users/$userId/charging_sessions'),
      ChargingSession.fromJson,
    );
  }

  Future<void> deleteUser(int userId) {
    return _apiClient.delete('/users/$userId');
  }
}
