from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.payment_service import PaymentService
from app.core.dependencies import (
    AuthenticatedUser,
    get_admin_or_station_manager,
    get_current_user,
    get_payment_service,
)
from app.domain.models.payment import PaymentEntity
from app.schemas.payment import (
    PaymentCreate,
    PaymentResponse,
    PaymentUpdate,
)

router = APIRouter()


@router.post("", response_model=PaymentResponse, status_code=201)
def create_payment(
    payment: PaymentCreate,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    if payment.user_id != current_user.id and not current_user.is_staff:
        raise HTTPException(status_code=403, detail="Cannot create payment for another user")

    payment_entity = PaymentEntity(**payment.model_dump())
    try:
        return service.create_payment(payment_entity)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("", response_model=List[PaymentResponse])
def get_payments(
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    return service.get_payments_by_status("COMPLETED")


@router.get("/my", response_model=List[PaymentResponse])
def get_my_payments(
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    return service.get_user_payments(current_user.id)


@router.get("/status/{status}", response_model=List[PaymentResponse])
def get_payments_by_status(
    status: str,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    try:
        return service.get_payments_by_status(status.upper())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/charging-session/{charging_session_id}", response_model=PaymentResponse)
def get_payment_by_charging_session(
    charging_session_id: int,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    try:
        payment = service.get_payment_for_charging_session(charging_session_id)
        if not payment:
            raise HTTPException(status_code=404, detail="Payment not found for this charging session")
        if payment.user_id != current_user.id and not current_user.is_staff:
            raise HTTPException(status_code=403, detail="Access denied")
        return payment
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/{payment_id}", response_model=PaymentResponse)
def get_payment(
    payment_id: int,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    payment = service.get_payment(payment_id)
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    if payment.user_id != current_user.id and not current_user.is_staff:
        raise HTTPException(status_code=403, detail="Access denied")
    return payment


@router.patch("/{payment_id}", response_model=PaymentResponse)
def update_payment(
    payment_id: int,
    payment_update: PaymentUpdate,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    existing_payment = service.get_payment(payment_id)
    if not existing_payment:
        raise HTTPException(status_code=404, detail="Payment not found")

    update_data = payment_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(existing_payment, key, value)

    try:
        return service.update_payment(existing_payment)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    
@router.patch("/{payment_id}/remove-coupon", response_model=PaymentResponse)
def remove_coupon(
    payment_id: int,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_current_user),  
):
    try:
        payment = service.remove_coupon(payment_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return payment

@router.post("/{payment_id}/complete", response_model=PaymentResponse)
def complete_payment(
    payment_id: int,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    try:
        return service.complete_payment(payment_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/{payment_id}/fail", response_model=PaymentResponse)
def fail_payment(
    payment_id: int,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    try:
        return service.fail_payment(payment_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/{payment_id}/refund", response_model=PaymentResponse)
def refund_payment(
    payment_id: int,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    try:
        return service.refund_payment(payment_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.delete("/{payment_id}", status_code=204)
def delete_payment(
    payment_id: int,
    service: PaymentService = Depends(get_payment_service),
    current_user: AuthenticatedUser = Depends(get_admin_or_station_manager),
):
    if not service.delete_payment(payment_id):
        raise HTTPException(status_code=404, detail="Payment not found")

