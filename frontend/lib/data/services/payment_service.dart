import '../api/api_client.dart';
import '../models/payment.dart';
import 'json_helpers.dart';

class PaymentService {
  PaymentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Payment> createPayment(Payment payment) async {
    return Payment.fromJson(
      parseObject(await _apiClient.post('/payments', body: payment.toJson())),
    );
  }

  Future<List<Payment>> getPayments() async {
    return parseList(await _apiClient.get('/payments'), Payment.fromJson);
  }

  Future<List<Payment>> getMyPayments() async {
    return parseList(await _apiClient.get('/payments/my'), Payment.fromJson);
  }

  Future<List<Payment>> getPaymentsByStatus(String status) async {
    return parseList(
      await _apiClient.get('/payments/status/$status'),
      Payment.fromJson,
    );
  }

  Future<Payment> getPaymentByChargingSession(int chargingSessionId) async {
    return Payment.fromJson(
      parseObject(
        await _apiClient.get('/payments/charging-session/$chargingSessionId'),
      ),
    );
  }

  Future<Payment> getPayment(int paymentId) async {
    return Payment.fromJson(
      parseObject(await _apiClient.get('/payments/$paymentId')),
    );
  }

  Future<Payment> updatePayment(
    int paymentId, {
    double? amount,
    String? status,
    String? paymentDate,
  }) async {
    return Payment.fromJson(
      parseObject(
        await _apiClient.patch(
          '/payments/$paymentId',
          body: {
            'amount': amount,
            'status': status,
            'payment_date': paymentDate,
          },
        ),
      ),
    );
  }

  Future<Payment> completePayment(int paymentId) async {
    return Payment.fromJson(
      parseObject(await _apiClient.post('/payments/$paymentId/complete')),
    );
  }

  Future<Payment> failPayment(int paymentId) async {
    return Payment.fromJson(
      parseObject(await _apiClient.post('/payments/$paymentId/fail')),
    );
  }

  Future<Payment> refundPayment(int paymentId) async {
    return Payment.fromJson(
      parseObject(await _apiClient.post('/payments/$paymentId/refund')),
    );
  }

  Future<void> deletePayment(int paymentId) {
    return _apiClient.delete('/payments/$paymentId');
  }

  Future<Payment> removeCoupon(int paymentId) async {
    return Payment.fromJson(
      parseObject(await _apiClient.patch('/payments/$paymentId/remove-coupon')),
    );
  }
}
