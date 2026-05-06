# API Endpoints

> Note: The current backend does not include a mounted `/auth` router, so `POST /auth/register` and `POST /auth/login` are not implemented in this codebase.

## USERS

POST /users
- Creates a new user.
- Request schema: `UserCreate`
  - `name: str`
  - `surname: str`
  - `mail: str`
  - `password: str` (min length 6, max length 72)
- Response schema: `AuthResponse`
  - `access_token: str`
  - `token_type: str`
  - `user: User`

POST /users/login
- Authenticates a user.
- Request schema: `UserLogin`
  - `email: str`
  - `password: str`
- Response schema: `AuthResponse`
  - `access_token: str`
  - `token_type: str`
  - `user: User`

GET /users
- Returns all users.
- Response schema: `List[User]`

GET /users/me/reservations
- Returns reservations for the authenticated user.
- Response schema: `List[Reservation]`

GET /users/me/charging_sessions
- Returns charging sessions for the authenticated user.
- Response schema: `List[ChargingSession]`

DELETE /users/me
- Deletes the authenticated user.

GET /users/{user_id}
- Returns a user by id.
- Response schema: `User`

GET /users/{user_id}/vehicles
- Returns vehicles for the specified user.
- Response schema: `List[Vehicle]`

GET /users/{user_id}/reservations
- Returns reservations for the specified user.
- Response schema: `List[Reservation]`

GET /users/{user_id}/charging_sessions
- Returns charging sessions for the specified user.
- Response schema: `List[ChargingSession]`

DELETE /users/{user_id}
- Deletes a user by id.

---

## VEHICLES

POST /vehicles
- Creates a vehicle for the authenticated user.
- Request schema: `VehicleCreate`
  - `model: str`
  - `plate: str`
  - `max_charging_power: float`
  - `battery_capacity: float`
  - `connector_type: str`
  - `current_type: str`
- Response schema: `Vehicle`
  - `id: int`
  - `user_id: int`
  - all `VehicleCreate` fields

GET /vehicles
- Returns all vehicles.
- Response schema: `List[Vehicle]`
- Admin-only

GET /vehicles/{vehicle_id}
- Returns a vehicle by id.
- Response schema: `Vehicle`

GET /vehicles/{vehicle_id}/compatible-chargers
- Returns chargers compatible with the vehicle.
- Response schema: `List[Charger]`

PUT /vehicles/{vehicle_id}
- Updates a vehicle.
- Request schema: `VehicleCreate`
- Response schema: `Vehicle`

DELETE /vehicles/{vehicle_id}
- Deletes a vehicle.

---

## RESERVATIONS

POST /reservations
- Creates a reservation for the authenticated user.
- Request schema: `ReservationCreate`
  - `vehicle_id: int`
  - `charger_id: int`
  - `date: date`
  - `start_time: time`
  - `end_time: time`
  - `status: str` (default: `PENDING`)
- Response schema: `Reservation`
  - `id: int`
  - `user_id: int`
  - all `ReservationCreate` fields

GET /reservations
- Returns all reservations.
- Response schema: `List[Reservation]`
- Admin or station manager only

GET /reservations/{reservation_id}
- Returns a reservation by id.
- Response schema: `Reservation`

DELETE /reservations/{reservation_id}
- Deletes a reservation.

---

## STATIONS

POST /stations
- Creates a charging station.
- Request schema: `StationCreate`
  - `address: str`
  - `company: str`
  - `location: str`
  - `status: str`
- Response schema: `Station`
  - `id: int`
  - all `StationCreate` fields

GET /stations
- Returns all stations.
- Response schema: `List[Station]`

GET /stations/nearby
- Returns nearby stations by `location` query param.
- Query params:
  - `location: str`
- Response schema: `List[Station]`

GET /stations/{station_id}
- Returns a station by id.
- Response schema: `Station`

GET /stations/{station_id}/chargers
- Returns chargers at a station.
- Response schema: `List[Charger]`

PUT /stations/{station_id}
- Updates a station.
- Request schema: `StationCreate`
- Response schema: `Station`

DELETE /stations/{station_id}
- Deletes a station.

---

## CHARGERS

POST /chargers
- Creates a charger.
- Request schema: `ChargerCreate`
  - `station_id: int`
  - `connector_type: ConnectorType`
  - `current_type: CurrentType`
  - `max_power: float`
  - `price_per_kwh: float`
  - `status: ChargerStatus`
- Response schema: `Charger`
  - `id: int`
  - all `ChargerCreate` fields

GET /chargers
- Returns all chargers.
- Response schema: `List[Charger]`

GET /chargers/{charger_id}
- Returns a charger by id.
- Response schema: `Charger`

GET /chargers/{charger_id}/reservations
- Returns reservations for a charger on a date.
- Query params:
  - `date: DD-MM-YYYY`
- Response schema: `List[Reservation]`

GET /chargers/{charger_id}/availability
- Returns availability for a charger.
- Query params:
  - `start_date: YYYY-MM-DD`
  - `end_date: YYYY-MM-DD`

PUT /chargers/{charger_id}
- Updates a charger.
- Request schema: `ChargerCreate`
- Response schema: `Charger`

DELETE /chargers/{charger_id}
- Deletes a charger.

PATCH /chargers/status/{charger_id}
- Updates charger status.
- Request schema: `ChargerStatusUpdate`
  - `status: ChargerStatus`

---

## CHARGING SESSIONS

POST /charging-sessions/start
- Starts a charging session.
- Request schema: `ChargingSessionStartRequest`
  - `reservation_id: int`
- Response schema: `ChargingSession`
  - `id: int`
  - `reservation_id: int`
  - `start_time: time`
  - `end_time: Optional[time]`
  - `consuming_power: float`
  - `cost: float`
  - `status: str`

PATCH /charging-sessions/{session_id}/finish
- Finishes a charging session.
- Request schema: `ChargingSessionFinishRequest`
  - `end_time: Optional[time]`
- Response schema: `ChargingSession`

GET /charging-sessions
- Returns all charging sessions.
- Response schema: `List[ChargingSession]`
- Admin or station manager only

GET /charging-sessions/{session_id}
- Returns a charging session by id.
- Response schema: `ChargingSession`

---

## COUPONS

POST /coupons
- Creates a coupon.
- Request schema: `CouponCreate`
  - `user_id: int`
  - `code: str`
  - `discount_type: str`
  - `discount_value: float`
  - `valid_from: datetime`
  - `valid_until: datetime`
  - `min_order_amount: float`
  - `max_discount_amount: Optional[float]`
  - `usage_limit: Optional[int]`
  - `is_active: bool`
- Response schema: `Coupon`
  - `id: int`
  - `used_count: int`
  - all `CouponCreate` fields

GET /coupons
- Returns all coupons.
- Response schema: `List[Coupon]`
- Admin or station manager only

GET /coupons/{coupon_id}
- Returns a coupon by id.
- Response schema: `Coupon`

GET /coupons/my
- Returns coupons for authenticated user.
- Response schema: `List[Coupon]`

GET /coupons/my/by-code/{code}
- Returns current user coupon by code.
- Response schema: `Coupon`

GET /coupons/users/{user_id}
- Returns coupons for a user.
- Response schema: `List[Coupon]`

GET /coupons/users/{user_id}/by-code/{code}
- Returns a coupon by user and code.
- Response schema: `Coupon`

POST /coupons/preview
- Previews coupon discount without consuming usage.
- Request schema: `CouponApplyRequest`
  - `code: str`
  - `order_amount: float`
- Response schema: `CouponApplyResult`
  - `user_id: int`
  - `code: str`
  - `order_amount: float`
  - `discount_amount: float`
  - `final_amount: float`

POST /coupons/apply
- Applies a coupon and consumes usage.
- Request schema: `CouponApplyRequest`
- Response schema: `CouponApplyResult`

DELETE /coupons/{coupon_id}
- Deletes a coupon.

---

## PAYMENTS

POST /payments
- Creates a payment.
- Request schema: `PaymentCreate`
  - `user_id: int`
  - `charging_session_id: int`
  - `amount: float`
  - `payment_method: str`
  - `status: str`
  - `transaction_id: Optional[str]`
  - `description: Optional[str]`
  - `coupon_id: Optional[int]`
  - `original_amount: Optional[float]`
- Response schema: `PaymentResponse`
  - `id: int`
  - `user_id: int`
  - `charging_session_id: int`
  - `amount: float`
  - `payment_method: str`
  - `status: str`
  - `transaction_id: Optional[str]`
  - `payment_date: Optional[datetime]`
  - `description: Optional[str]`
  - `coupon_id: Optional[int]`
  - `original_amount: Optional[float]`

GET /payments
- Returns completed payments.
- Response schema: `List[PaymentResponse]`
- Admin/station manager only

GET /payments/my
- Returns authenticated user payments.
- Response schema: `List[PaymentResponse]`

GET /payments/status/{status}
- Returns payments filtered by status.
- Response schema: `List[PaymentResponse]`

GET /payments/transaction/{transaction_id}
- Returns payment by transaction id.
- Response schema: `PaymentResponse`

GET /payments/charging-session/{charging_session_id}
- Returns payment for a charging session.
- Response schema: `PaymentResponse`

GET /payments/{payment_id}
- Returns a payment by id.
- Response schema: `PaymentResponse`

PATCH /payments/{payment_id}
- Updates payment fields.
- Request schema: `PaymentUpdate`
  - `amount: Optional[float]`
  - `status: Optional[str]`
  - `transaction_id: Optional[str]`
  - `payment_date: Optional[datetime]`
  - `description: Optional[str}`
- Response schema: `PaymentResponse`

POST /payments/{payment_id}/complete
- Marks payment complete.
- Response schema: `PaymentResponse`

POST /payments/{payment_id}/fail
- Marks payment failed.
- Response schema: `PaymentResponse`

POST /payments/{payment_id}/refund
- Refunds a payment.
- Response schema: `PaymentResponse`

DELETE /payments/{payment_id}
- Deletes a payment.

---

## NOTIFICATIONS

POST /notifications
- Creates a notification.
- Request schema: `NotificationCreate`
  - `user_id: int`
  - `title: str`
  - `message: str`
  - `notification_type: str`
- Response schema: `Notification`
  - `id: int`
  - `user_id: int`
  - `title: str`
  - `message: str`
  - `notification_type: str`
  - `is_read: bool`
  - `created_at: datetime`

GET /notifications
- Returns notifications for authenticated user.
- Optional query: `unread_only: bool`
- Response schema: `List[Notification]`

GET /notifications/all
- Returns all notifications.
- Response schema: `List[Notification]`
- Admin only

GET /notifications/{notification_id}
- Returns a notification by id.
- Response schema: `Notification`

PATCH /notifications/{notification_id}/read
- Marks a notification read.
- Response schema: `Notification`

DELETE /notifications/{notification_id}
- Deletes a notification.