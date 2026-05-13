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
          'email': mail,
          'balance': 0.0,
          'password': password,
        },
      ),
    );
    return AppUser.fromJson(parseObject(json['user']));
  }

  Future<List<AppUser>> getUsers() async {
    return parseList(
      await _apiClient.get('/users/admin/all'),
      AppUser.fromJson,
    );
  }

  Future<AppUser> getUser(int userId) async {
    return AppUser.fromJson(parseObject(await _apiClient.get('/users/me')));
  }

  Future<AppUser> getCurrentUser() async {
    return AppUser.fromJson(parseObject(await _apiClient.get('/users/me')));
  }

  Future<AppUser> updateUser(int userId, AppUser user, {String? password}) {
    throw UnsupportedError('User update endpoint is not available.');
  }

  Future<List<Vehicle>> getUserVehicles(int userId) async {
    return parseList(await _apiClient.get('/vehicles/my'), Vehicle.fromJson);
  }

  Future<List<Reservation>> getUserReservations(int userId) async {
    return parseList(
      await _apiClient.get('/reservations/my'),
      Reservation.fromJson,
    );
  }

  Future<List<ChargingSession>> getUserChargingSessions(int userId) async {
    return parseList(
      await _apiClient.get('/charging-sessions/my'),
      ChargingSession.fromJson,
    );
  }

  Future<AppUser> addBalance(double amount) async {
    return AppUser.fromJson(
      parseObject(
        await _apiClient.patch(
          '/users/add_balance/me',
          queryParameters: {'amount': amount.toString()},
        ),
      ),
    );
  }

  Future<void> deleteUser(int userId) {
    return _apiClient.delete('/users/$userId');
  }
}
