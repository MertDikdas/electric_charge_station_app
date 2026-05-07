# API Endpoints

Last Updated: 2026-05-07

## AUTH

GET /auth/me
- Returns the authenticated user's info.
- Response schema: `User`
- Authentication: Required (Bearer Token)

POST /auth/logout
- Logs out the authenticated user.
- Authentication: Required (Bearer Token)
- Response: `{"message": "Logged out successfully"}`

---

## USERS

POST /users
- Creates a new user (registration).
- Request schema: `UserCreate`
  - `name: str`
  - `surname: str`
  - `email: str`
  - `password: str` (min length 6, max length 72)
- Response schema: `AuthResponse`
  - `access_token: str`
  - `token_type: str`
  - `user: User`
- Status Code: 201

POST /users/login
- Authenticates a user and returns access token.
- Request schema: `UserLogin`
  - `email: str`
  - `password: str`
- Response schema: `AuthResponse`
  - `access_token: str`
  - `token_type: str`
  - `user: User`

GET /users/all
- Returns all users.
- Response schema: `List[User]`
- Authentication: Required (Admin or Station Manager)

GET /users/me
- Returns the authenticated user's info.
- Response schema: `User`
- Authentication: Required (Bearer Token)

DELETE /users/me
- Deletes the authenticated user.
- Status Code: 204
- Authentication: Required (Bearer Token)

DELETE /users/{user_id}
- Deletes a user by id.
- Status Code: 204
- Authentication: Required (Admin or Station Manager)

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
- Status Code: 201
- Authentication: Required

GET /vehicles/all
- Returns all vehicles.
- Response schema: `List[Vehicle]`
- Authentication: Required (Admin or Station Manager)

GET /vehicles/my
- Returns vehicles for the authenticated user.
- Response schema: `List[Vehicle]`
- Authentication: Required

GET /vehicles/{vehicle_id}
- Returns a vehicle by id.
- Response schema: `Vehicle`
- Authentication: Required (Owner or Admin)

GET /vehicles/{vehicle_id}/compatible-chargers
- Returns chargers compatible with the vehicle.
- Response schema: `List[Charger]`
- Authentication: Required (Owner or Admin)

PUT /vehicles/{vehicle_id}
- Updates a vehicle.
- Request schema: `VehicleCreate`
- Response schema: `Vehicle`
- Authentication: Required (Owner or Admin)

DELETE /vehicles/{vehicle_id}
- Deletes a vehicle.
- Status Code: 204
- Authentication: Required (Owner or Admin)

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
- Status Code: 201
- Authentication: Required

GET /reservations/all
- Returns all reservations.
- Response schema: `List[Reservation]`
- Authentication: Required (Admin or Station Manager)

GET /reservations/my
- Returns reservations for the authenticated user.
- Response schema: `List[Reservation]`
- Authentication: Required

GET /reservations/my/{reservation_id}
- Returns a specific reservation by id.
- Response schema: `Reservation`
- Authentication: Required (Owner or Staff)

DELETE /reservations/my/{reservation_id}
- Deletes a reservation.
- Status Code: 204
- Authentication: Required (Owner or Staff)

PATCH /reservations/my/{reservation_id}/status
- Updates the reservation status.
- Request schema: `ReservationStatusUpdate`
  - `status: str`
- Response schema: `Reservation`
- Authentication: Required (Owner or Staff)

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
- Status Code: 201
- Authentication: Required (Admin or Station Manager)

GET /stations
- Returns all stations (public).
- Response schema: `List[Station]`
- Authentication: Optional

GET /stations/nearby
- Returns nearby stations by location.
- Query params:
  - `location: str` (required, min_length=1)
- Response schema: `List[Station]`
- Authentication: Optional

GET /stations/{station_id}
- Returns a station by id.
- Response schema: `Station`
- Authentication: Optional

GET /stations/{station_id}/chargers
- Returns chargers at a station.
- Response schema: `List[Charger]`
- Authentication: Optional

PUT /stations/{station_id}
- Updates a station.
- Request schema: `StationCreate`
- Response schema: `Station`
- Authentication: Required (Admin or Station Manager)

DELETE /stations/{station_id}
- Deletes a station.
- Status Code: 204
- Authentication: Required (Admin or Station Manager)

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
- Status Code: 201
- Authentication: Required (Admin or Station Manager)

GET /chargers/all
- Returns all chargers.
- Response schema: `List[Charger]`
- Authentication: Optional

GET /chargers/{charger_id}
- Returns a charger by id.
- Response schema: `Charger`
- Authentication: Optional

GET /chargers/{charger_id}/reservations
- Returns reservations for a charger on a specific date.
- Query params:
  - `date: str` (required, format: DD-MM-YYYY)
- Response schema: `List[Reservation]`
- Authentication: Optional

GET /chargers/{charger_id}/availability
- Returns availability slots for a charger in a date range.
- Query params:
  - `start_date: str` (required, format: YYYY-MM-DD)
  - `end_date: str` (required, format: YYYY-MM-DD)
- Response schema: Availability data
- Authentication: Optional

PUT /chargers/{charger_id}
- Updates a charger.
- Request schema: `ChargerCreate`
- Response schema: `Charger`
- Authentication: Required

PATCH /chargers/status/{charger_id}
- Updates charger status only.
- Request schema: `ChargerStatusUpdate`
  - `status: ChargerStatus`
- Response schema: `Charger`
- Authentication: Optional

DELETE /chargers/{charger_id}
- Deletes a charger.
- Status Code: 204
- Authentication: Optional

---

## CHARGING SESSIONS

POST /charging-sessions/start
- Starts a charging session from a reservation.
- Request schema: `ChargingSessionStartRequest`
  - `reservation_id: int`
- Response schema: `ChargingSession`
- Status Code: 201
- Authentication: Required

PATCH /charging-sessions/finish
- Finishes the active charging session for the authenticated user.
- Request schema: `ChargingSessionFinishRequest` (optional)
  - `end_time: Optional[time]`
- Response schema: `ChargingSession`
- Authentication: Required

PATCH /charging-sessions/{session_id}/finish
- Finishes a specific charging session by id.
- Request schema: `ChargingSessionFinishRequest` (optional)
  - `end_time: Optional[time]`
- Response schema: `ChargingSession`
- Authentication: Required (Owner or Staff)

GET /charging-sessions/all
- Returns all charging sessions.
- Response schema: `List[ChargingSession]`
- Authentication: Required (Admin or Station Manager)

GET /charging-sessions/my
- Returns charging sessions for the authenticated user.
- Response schema: `List[ChargingSession]`
- Authentication: Required

GET /charging-sessions/my/active
- Returns active (ongoing) charging sessions for the authenticated user.
- Response schema: `List[ChargingSession]`
- Authentication: Required

GET /charging-sessions/{session_id}
- Returns a specific charging session by id.
- Response schema: `ChargingSession`
- Authentication: Required (Owner or Staff)

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
- Status Code: 201
- Authentication: Required (Admin or Station Manager)

GET /coupons/all
- Returns all coupons.
- Response schema: `List[Coupon]`
- Authentication: Required (Admin or Station Manager)

GET /coupons/my
- Returns coupons for the authenticated user.
- Response schema: `List[Coupon]`
- Authentication: Required

GET /coupons/my/by-code/{code}
- Returns a specific coupon by code for the authenticated user.
- Response schema: `Coupon`
- Authentication: Required

GET /coupons/users/{user_id}
- Returns coupons for a specific user.
- Response schema: `List[Coupon]`
- Authentication: Required (Admin or Station Manager)

GET /coupons/users/{user_id}/by-code/{code}
- Returns a specific coupon by user id and code.
- Response schema: `Coupon`
- Authentication: Required (Admin or Station Manager)

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
- Authentication: Required

POST /coupons/apply
- Applies a coupon and consumes one usage.
- Request schema: `CouponApplyRequest`
  - `code: str`
  - `order_amount: float`
- Response schema: `CouponApplyResult`
- Authentication: Required

GET /coupons/{coupon_id}
- Returns a coupon by id.
- Response schema: `Coupon`
- Authentication: Required (Admin or Station Manager)

DELETE /coupons/{coupon_id}
- Deletes a coupon.
- Status Code: 204
- Authentication: Required (Admin or Station Manager)

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
- Status Code: 201
- Authentication: Required (Owner or Staff)

GET /payments
- Returns completed payments.
- Response schema: `List[PaymentResponse]`
- Authentication: Required (Admin or Station Manager)

GET /payments/my
- Returns payments for the authenticated user.
- Response schema: `List[PaymentResponse]`
- Authentication: Required

GET /payments/status/{status}
- Returns payments filtered by status (e.g., PENDING, COMPLETED, FAILED).
- Response schema: `List[PaymentResponse]`
- Authentication: Required (Admin or Station Manager)

GET /payments/transaction/{transaction_id}
- Returns payment by transaction id.
- Response schema: `PaymentResponse`
- Authentication: Required (Admin or Station Manager)

GET /payments/charging-session/{charging_session_id}
- Returns payment for a specific charging session.
- Response schema: `PaymentResponse`
- Authentication: Required (Owner or Staff)

GET /payments/{payment_id}
- Returns a payment by id.
- Response schema: `PaymentResponse`
- Authentication: Required (Owner or Staff)

PATCH /payments/{payment_id}
- Updates payment fields.
- Request schema: `PaymentUpdate`
  - `amount: Optional[float]`
  - `status: Optional[str]`
  - `transaction_id: Optional[str]`
  - `payment_date: Optional[datetime]`
  - `description: Optional[str]`
- Response schema: `PaymentResponse`
- Authentication: Required (Admin or Station Manager)

POST /payments/{payment_id}/complete
- Marks payment as completed with transaction id.
- Request params:
  - `transaction_id: str` (query param)
- Response schema: `PaymentResponse`
- Authentication: Required (Admin or Station Manager)

POST /payments/{payment_id}/fail
- Marks payment as failed.
- Response schema: `PaymentResponse`
- Authentication: Required (Admin or Station Manager)

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
- Status Code: 201
- Authentication: Optional

GET /notifications/my
- Returns notifications for the authenticated user.
- Query params (optional):
  - `unread_only: bool` (default: false)
- Response schema: `List[Notification]`
- Authentication: Required

GET /notifications/all
- Returns all notifications in the system.
- Response schema: `List[Notification]`
- Authentication: Required (Admin or Station Manager)

GET /notifications/my/{notification_id}
- Returns a specific notification by id for the authenticated user.
- Response schema: `Notification`
- Authentication: Required (Owner or Staff)

PATCH /notifications/my/{notification_id}/read
- Marks a notification as read.
- Response schema: `Notification`
- Authentication: Required (Owner or Staff)

DELETE /notifications/my/{notification_id}
- Deletes a notification.
- Status Code: 204
- Authentication: Required (Owner or Staff)