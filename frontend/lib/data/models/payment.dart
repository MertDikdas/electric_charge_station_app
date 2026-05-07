class Payment {
  const Payment({
    required this.id,
    required this.userId,
    required this.reservationId,
    required this.amount,
    required this.status,
    this.paymentDate,
    this.couponId,
  });

  final int id;
  final int userId;
  final int reservationId;
  final double amount;
  final String status;
  final String? paymentDate;
  final int? couponId;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      reservationId: _asInt(json['reservation_id'] ?? json['reservationId']),
      amount: _asDouble(json['amount']),
      status: (json['status'] ?? '').toString(),
      paymentDate: _asNullableString(json['payment_date'] ?? json['paymentDate']),
      couponId: _asNullableInt(json['coupon_id'] ?? json['couponId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'reservation_id': reservationId,
      'amount': amount,
      'status': status,
      'coupon_id': couponId,
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    return _asInt(value);
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _asNullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }
}
