import '../api/api_client.dart';
import '../models/reservation.dart';
import 'json_helpers.dart';

class ReservationService {
  ReservationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Reservation> createReservation(ReservationInput input) async {
    return Reservation.fromJson(
      parseObject(await _apiClient.post('/reservations', body: input.toJson())),
    );
  }

  Future<List<Reservation>> getReservations() async {
    return parseList(
      await _apiClient.get('/reservations'),
      Reservation.fromJson,
    );
  }

  Future<Reservation> getReservation(int reservationId) async {
    return Reservation.fromJson(
      parseObject(await _apiClient.get('/reservations/$reservationId')),
    );
  }

  Future<void> deleteReservation(int reservationId) {
    return _apiClient.delete('/reservations/$reservationId');
  }
}
