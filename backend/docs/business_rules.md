# Business Rules

## Compatibility Rules

- A vehicle can only use a charger if the vehicle connector type matches the charger connector type.
- A vehicle can only use a charger if the vehicle current type matches the charger current type.
- Incompatible vehicle and charger combinations are rejected.
- The system can list only compatible chargers for a selected vehicle.

## Charger Rules

- A charger can be reserved only if its status is `AVAILABLE`.
- A charging session can only be started if the charger is available.
- A charging session can only be started if the vehicle and charger are compatible.

## Reservation Rules

- A reservation must belong to the selected vehicle.
- A reservation must belong to the selected charger.
- A reservation start time must be earlier than its end time.
- A reservation cannot be created for a past time.
- A reservation cannot be created too far in the future.
- By default, a reservation cannot be created more than 30 days in advance.
- A reservation duration cannot exceed 2 hours by default.
- A charger cannot have overlapping reservations for the same time slot.

## Purpose

These rules ensure vehicle-charger compatibility, prevent invalid reservations, avoid double booking, and allow charging sessions to start only under valid conditions.