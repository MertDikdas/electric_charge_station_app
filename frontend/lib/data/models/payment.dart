class Payment {
  const Payment({
    required this.id,
    required this.userId,
    required this.reservationId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.paymentDate,
    this.description,
    this.couponId,
    this.originalAmount,
  });

  final int id;
  final int userId;
  final int reservationId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final String? paymentDate;
  final String? description;
  final int? couponId;
  final double? originalAmount;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      reservationId: _asInt(json['reservation_id'] ?? json['reservationId']),
      amount: _asDouble(json['amount']),
      paymentMethod: (json['payment_method'] ?? json['paymentMethod'] ?? '')
          .toString(),
      status: (json['status'] ?? '').toString(),
      transactionId: _asNullableString(
        json['transaction_id'] ?? json['transactionId'],
      ),
      paymentDate: _asNullableString(json['payment_date'] ?? json['paymentDate']),
      description: _asNullableString(json['description']),
      couponId: _asNullableInt(json['coupon_id'] ?? json['couponId']),
      originalAmount: _asNullableDouble(
        json['original_amount'] ?? json['originalAmount'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'reservation_id': reservationId,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status,
      'transaction_id': transactionId,
      'description': description,
      'coupon_id': couponId,
      'original_amount': originalAmount,
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

  static double? _asNullableDouble(Object? value) {
    if (value == null) return null;
    return _asDouble(value);
  }

  static String? _asNullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }
}
