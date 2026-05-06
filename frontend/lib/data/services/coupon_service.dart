import '../api/api_client.dart';
import '../models/coupon.dart';
import 'json_helpers.dart';

class CouponService {
  CouponService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Coupon> createCoupon(Coupon coupon) async {
    return Coupon.fromJson(
      parseObject(await _apiClient.post('/coupons', body: coupon.toJson())),
    );
  }

  Future<List<Coupon>> getCoupons() async {
    return parseList(await _apiClient.get('/coupons'), Coupon.fromJson);
  }

  Future<Coupon> getCoupon(int couponId) async {
    return Coupon.fromJson(
      parseObject(await _apiClient.get('/coupons/$couponId')),
    );
  }

  Future<List<Coupon>> getMyCoupons() async {
    return parseList(await _apiClient.get('/coupons/my'), Coupon.fromJson);
  }

  Future<Coupon> getMyCouponByCode(String code) async {
    return Coupon.fromJson(
      parseObject(await _apiClient.get('/coupons/my/by-code/$code')),
    );
  }

  Future<List<Coupon>> getUserCoupons(int userId) async {
    return parseList(
      await _apiClient.get('/coupons/users/$userId'),
      Coupon.fromJson,
    );
  }

  Future<Coupon> getUserCouponByCode(int userId, String code) async {
    return Coupon.fromJson(
      parseObject(await _apiClient.get('/coupons/users/$userId/by-code/$code')),
    );
  }

  Future<CouponApplyResult> previewCoupon({
    required String code,
    required double orderAmount,
  }) async {
    return CouponApplyResult.fromJson(
      parseObject(
        await _apiClient.post(
          '/coupons/preview',
          body: {'code': code, 'order_amount': orderAmount},
        ),
      ),
    );
  }

  Future<CouponApplyResult> applyCoupon({
    required String code,
    required double orderAmount,
  }) async {
    return CouponApplyResult.fromJson(
      parseObject(
        await _apiClient.post(
          '/coupons/apply',
          body: {'code': code, 'order_amount': orderAmount},
        ),
      ),
    );
  }

  Future<void> deleteCoupon(int couponId) {
    return _apiClient.delete('/coupons/$couponId');
  }
}
