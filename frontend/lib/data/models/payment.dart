class Payment {
  const Payment({
    required this.id,
    required this.userId,
    required this.reservationId,
    required this.amount,
    required this.status,
    this.paymentDate,
    this.couponId,
    this.couponCode,
    this.discountAmount = 0,
    double? finalAmount,
  }) : finalAmount = finalAmount ?? amount;

  final int id;
  final int userId;
  final int reservationId;
  final double amount;
  final String status;
  final String? paymentDate;
  final int? couponId;
  final String? couponCode;
  final double discountAmount;
  final double finalAmount;

  factory Payment.fromJson(Map<String, dynamic> json) {
    final amount = _asDouble(json['amount']);

    return Payment(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      reservationId: _asInt(json['reservation_id'] ?? json['reservationId']),
      amount: amount,
      status: (json['status'] ?? '').toString(),
      paymentDate: _asNullableString(
        json['payment_date'] ?? json['paymentDate'],
      ),
      couponId: _asNullableInt(json['coupon_id'] ?? json['couponId']),
      couponCode: _asNullableString(json['coupon_code'] ?? json['couponCode']),
      discountAmount: _asDouble(
        json['discount_amount'] ?? json['discountAmount'] ?? 0,
      ),
      finalAmount: _asDouble(
        json['final_amount'] ?? json['finalAmount'] ?? amount,
      ),
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
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
