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

  Future<List<Reservation>> getChargerReservations({
    required int chargerId,
    required DateTime date,
  }) async {
    return parseList(
      await _apiClient.get(
        '/chargers/$chargerId/reservations',
        queryParameters: {'date': _formatBackendDate(date)},
      ),
      Reservation.fromJson,
    );
  }

  Future<List<Reservation>> getReservations() async {
    return parseList(
      await _apiClient.get('/reservations/my'),
      Reservation.fromJson,
    );
  }

  Future<List<Reservation>> getAllReservations() async {
    return parseList(
      await _apiClient.get('/reservations/all'),
      Reservation.fromJson,
    );
  }

  Future<Reservation> getReservation(int reservationId) async {
    return Reservation.fromJson(
      parseObject(await _apiClient.get('/reservations/my/$reservationId')),
    );
  }

  Future<void> deleteReservation(int reservationId) {
    return _apiClient.delete('/reservations/my/$reservationId');
  }

  Future<Reservation> updateReservationStatus(
    int reservationId,
    String status,
  ) async {
    return Reservation.fromJson(
      parseObject(
        await _apiClient.patch(
          '/reservations/my/$reservationId/status',
          body: {'status': status},
        ),
      ),
    );
  }

  String _formatBackendDate(DateTime date) {
    return [
      date.day.toString().padLeft(2, '0'),
      date.month.toString().padLeft(2, '0'),
      date.year.toString().padLeft(4, '0'),
    ].join('-');
  }
}
