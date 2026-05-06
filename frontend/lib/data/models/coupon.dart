class Coupon {
  const Coupon({
    required this.id,
    required this.userId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.validFrom,
    required this.validUntil,
    required this.minOrderAmount,
    this.maxDiscountAmount,
    this.usageLimit,
    required this.isActive,
    required this.usedCount,
  });

  final int id;
  final int userId;
  final String code;
  final String discountType;
  final double discountValue;
  final String validFrom;
  final String validUntil;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final bool isActive;
  final int usedCount;

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      code: (json['code'] ?? '').toString(),
      discountType: (json['discount_type'] ?? json['discountType'] ?? '')
          .toString(),
      discountValue: _asDouble(json['discount_value'] ?? json['discountValue']),
      validFrom: (json['valid_from'] ?? json['validFrom'] ?? '').toString(),
      validUntil: (json['valid_until'] ?? json['validUntil'] ?? '').toString(),
      minOrderAmount: _asDouble(
        json['min_order_amount'] ?? json['minOrderAmount'],
      ),
      maxDiscountAmount: _asNullableDouble(
        json['max_discount_amount'] ?? json['maxDiscountAmount'],
      ),
      usageLimit: _asNullableInt(json['usage_limit'] ?? json['usageLimit']),
      isActive: json['is_active'] == true || json['isActive'] == true,
      usedCount: _asInt(json['used_count'] ?? json['usedCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'code': code,
      'discount_type': discountType,
      'discount_value': discountValue,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'min_order_amount': minOrderAmount,
      'max_discount_amount': maxDiscountAmount,
      'usage_limit': usageLimit,
      'is_active': isActive,
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
}

class CouponApplyResult {
  const CouponApplyResult({
    required this.userId,
    required this.code,
    required this.orderAmount,
    required this.discountAmount,
    required this.finalAmount,
  });

  final int userId;
  final String code;
  final double orderAmount;
  final double discountAmount;
  final double finalAmount;

  factory CouponApplyResult.fromJson(Map<String, dynamic> json) {
    return CouponApplyResult(
      userId: Coupon._asInt(json['user_id'] ?? json['userId']),
      code: (json['code'] ?? '').toString(),
      orderAmount: Coupon._asDouble(json['order_amount'] ?? json['orderAmount']),
      discountAmount: Coupon._asDouble(
        json['discount_amount'] ?? json['discountAmount'],
      ),
      finalAmount: Coupon._asDouble(json['final_amount'] ?? json['finalAmount']),
    );
  }
}
