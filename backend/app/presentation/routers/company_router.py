from fastapi import APIRouter, Depends, HTTPException

from app.application.services.company_service import CompanyService
from app.core.dependencies import get_admin, get_company_service
from app.domain.models.company import CompanyEntity
from app.schemas.company import Company, CompanyCreate, CompanyUpdate

router = APIRouter()


@router.post("/", response_model=Company, status_code=201)
def create_company(
    company: CompanyCreate,
    service: CompanyService = Depends(get_company_service),
    current_user=Depends(get_admin),
):
    company_entity = CompanyEntity(**company.model_dump())

    try:
        return service.create_company(company_entity)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/all", response_model=list[Company])
def get_companies(
    service: CompanyService = Depends(get_company_service),
    current_user=Depends(get_admin),
):
    return service.get_all_companies()


@router.get("/active", response_model=list[Company])
def get_active_companies(
    service: CompanyService = Depends(get_company_service),
    current_user=Depends(get_admin),
):
    return service.get_all_active_companies()


@router.get("/{company_id}", response_model=Company)
def get_company(
    company_id: int,
    service: CompanyService = Depends(get_company_service),
    current_user=Depends(get_admin),
):
    company = service.get_company(company_id)

    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    return company


@router.patch("/{company_id}", response_model=Company)
def update_company(
    company_id: int,
    company_update: CompanyUpdate,
    service: CompanyService = Depends(get_company_service),
    current_user=Depends(get_admin),
):
    update_data = company_update.model_dump(exclude_unset=True)

    try:
        return service.update_company(company_id, update_data)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.patch("/{company_id}/deactivate", response_model=Company)
def deactivate_company(
    company_id: int,
    service: CompanyService = Depends(get_company_service),
    current_user=Depends(get_admin),
):
    try:
        return service.deactivate_company(company_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    
@router.delete("/{company_id}", status_code=204)
def delete_company(
    company_id: int,
    service: CompanyService = Depends(get_company_service),
    current_user=Depends(get_admin),
):
    try:
        service.delete_company(company_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    
@router.patch("/{company_id}/activate", response_model=Company)
def activate_company(
    company_id: int,
    service: CompanyService = Depends(get_company_service),
    current_user=Depends(get_admin),
):
    try:
        return service.activate_company(company_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc