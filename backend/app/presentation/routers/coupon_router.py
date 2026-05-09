from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.application.services.coupon_service import CouponService
from app.core.dependencies import (
    AuthenticatedUser,
    get_admin,
    get_coupon_service,
    get_current_user,
)
from app.domain.models.coupon import CouponEntity
from app.schemas.coupon import Coupon, CouponApplyRequest, CouponApplyResult, CouponCreate

router = APIRouter()


@router.post("", response_model=Coupon, status_code=201)
def create_coupon(
    coupon: CouponCreate,
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    coupon_entity = CouponEntity(**coupon.model_dump())
    try:
        return service.create_coupon(coupon_entity)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/all", response_model=List[Coupon])
def get_coupons(
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_all_coupons()


@router.get("/my", response_model=List[Coupon])
def get_my_coupons(
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    return service.get_user_coupons(current_user.id)


@router.get("/my/by-code/{code}", response_model=Coupon)
def get_my_coupon_by_code(
    code: str,
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    coupon = service.get_user_coupon_by_code(current_user.id, code)
    if not coupon:
        raise HTTPException(status_code=404, detail="Coupon not found")
    return coupon


@router.get("/users/{user_id}", response_model=List[Coupon])
def get_user_coupons(
    user_id: int,
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    return service.get_user_coupons(user_id)


@router.get("/users/{user_id}/by-code/{code}", response_model=Coupon)
def get_user_coupon_by_code(
    user_id: int,
    code: str,
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    coupon = service.get_user_coupon_by_code(user_id, code)
    if not coupon:
        raise HTTPException(status_code=404, detail="Coupon not found")
    return coupon


@router.post("/preview", response_model=CouponApplyResult)
def preview_coupon(
    request: CouponApplyRequest,
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    try:
        return service.preview_discount(
            current_user.id,
            request.code,
            request.order_amount,
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/apply", response_model=CouponApplyResult)
def apply_coupon(
    request: CouponApplyRequest,
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    try:
        return service.apply_coupon(
            current_user.id,
            request.code,
            request.order_amount,
        )
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.delete("/{coupon_id}", status_code=204)
def delete_coupon(
    coupon_id: int,
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    if not service.delete_coupon(coupon_id):
        raise HTTPException(status_code=404, detail="Coupon not found")


@router.get("/{coupon_id}", response_model=Coupon)
def get_coupon(
    coupon_id: int,
    service: CouponService = Depends(get_coupon_service),
    current_user: AuthenticatedUser = Depends(get_admin),
):
    coupon = service.get_coupon(coupon_id)
    if not coupon:
        raise HTTPException(status_code=404, detail="Coupon not found")
    return coupon
