AUTH

POST /auth/register
    Creates a new user account.

POST /auth/login
    Authenticates the user and returns an access token.


USERS

POST /users +
    Creates a new user.
    This endpoint may be used by the system or admin panel. For public registration, /auth/register should be preferred.

GET /users +
    Gets all users.
    This endpoint should be restricted to administrators.

GET /users/{user_id} +
    Gets a specific user by id.
    This endpoint should be restricted to administrators or authorized support staff.

PUT /users/{user_id} 
    Updates a specific user's information.
    Only the user themselves or an administrator should be allowed to update this information.

GET /users/{user_id}/vehicles
    Gets all vehicles of the currently logged-in user.

GET /users/{user_id}/reservations
    Gets all reservations of the currently logged-in user.

GET /users/{user_id}/charging-sessions
    Gets all charging sessions of the currently logged-in user.

DELETE /users/{user_id}
    Deletes a specific user.
    This endpoint should be restricted to administrators.


VEHICLES

POST /vehicles
    Creates a new vehicle for the currently authenticated user.
    The user_id should be taken from the authentication token.

GET /vehicles
    Gets all vehicles.
    This endpoint should be restricted to administrators.

GET /vehicles/{vehicle_id}
    Gets a specific vehicle by id.
    The system should check whether the vehicle belongs to the logged-in user, unless the requester is an administrator.

PUT /vehicles/{vehicle_id}
    Updates a specific vehicle.
    The system should check vehicle ownership before updating.

DELETE /vehicles/{vehicle_id}
    Deletes a specific vehicle.
    The system should check vehicle ownership before deleting.

RESERVATIONS

POST /reservations
    Creates a new reservation for the currently authenticated user.
    The system should check charger availability, reservation rules, and double booking before creating the reservation.

GET /reservations
    Gets all reservations.
    This endpoint should be restricted to administrators or station managers.

GET /reservations/{reservation_id}
    Gets a specific reservation by id.
    The system should check whether the reservation belongs to the logged-in user, unless the requester is an administrator or authorized staff.

DELETE /reservations/{reservation_id}
    Deletes a specific reservation.
    In most cases, cancellation should be preferred instead of deletion, because reservation history may be needed later.

------------------------------------------------------------------------------------------------------------------
STATIONS

POST /stations
    Creates a new charging station.
    This endpoint should be restricted to station managers or administrators.

GET /stations
    Gets all charging stations.

GET /stations/{station_id}
    Gets a specific charging station by id.

PUT /stations/{station_id}
    Updates a specific charging station.
    This endpoint should be restricted to station managers or administrators.

DELETE /stations/{station_id}
    Deletes a specific charging station.
    This endpoint should be restricted to administrators or authorized station managers.

GET /stations/nearby
    Gets nearby charging stations based on user location.

GET /stations/{station_id}/chargers
    Gets all chargers that belong to a specific charging station.


CHARGERS

POST /chargers
    Creates a new charger for a charging station.
    This endpoint should be restricted to station managers or administrators.

GET /chargers
    Gets all chargers.

GET /chargers/{charger_id}
    Gets a specific charger by id.

GET /chargers/{charger_id}/reservations?data=DD-MM-YYYY
    Gets all reservations for a specific charger on a given date.

GET /chargers/{charger_id}/availability?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
    Gets available time slots for a specific charger between two dates.

PUT /chargers/{charger_id}
    Updates a specific charger's information.

DELETE /chargers/{charger_id}
    Deletes a specific charger.

PATCH /chargers/status/{charger_id}
    Changes the status of charger.


CHARGING SESSIONS

POST /charging-sessions/start
    Starts a charging session for a valid reservation.
    The system should check whether the reservation is active and whether the charger is available.

PATCH /charging-sessions/{session_id}/finish
    Finishes a charging session.
    The system should calculate consumed energy and total cost.

GET /charging-sessions/{session_id}
    Gets a specific charging session by id.

GET /charging-sessions
    Gets all charging sessions.
    This endpoint should be restricted to administrators or station managers.



