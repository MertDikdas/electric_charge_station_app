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
- Users receive a reminder notification 30 minutes before their reservation starts.

## Coupon Rules

- A coupon must belong to a user.
- A coupon code must be unique for the same user.
- Different users may have coupons with the same code.
- A user can only preview or apply coupons that belong to them.
- A coupon code must be 3-32 characters and may contain only uppercase letters, numbers, underscores, or hyphens.
- Coupon codes are normalized to uppercase before they are stored or used.
- A coupon discount type must be `PERCENTAGE` or `FIXED_AMOUNT`.
- A percentage coupon must have a discount value greater than 0 and no more than 100.
- A fixed amount coupon must have a discount value greater than 0.
- A coupon `valid_until` date must be after its `valid_from` date.
- A coupon can only be used while it is active and inside its valid date range.
- A coupon cannot be used after its usage limit is reached.
- A coupon can require a minimum order amount.
- A coupon discount cannot reduce the final amount below 0.
- A coupon maximum discount amount limits the calculated discount when present.

## Purpose

These rules ensure vehicle-charger compatibility, prevent invalid reservations, avoid double booking, allow charging sessions to start only under valid conditions, and keep coupon discounts predictable.
