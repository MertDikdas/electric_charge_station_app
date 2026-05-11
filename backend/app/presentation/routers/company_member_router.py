from fastapi import APIRouter, Depends, HTTPException

from app.application.services.company_member_service import CompanyMemberService
from app.core.dependencies import get_admin, get_company_member_service
from app.domain.models.company_member import CompanyMemberEntity
from app.schemas.company_member import CompanyMember, CompanyMemberCreate, CompanyMemberRoleUpdate, CompanyMemberStatusUpdate, CompanyMemberUpdate

router = APIRouter()

@router.post("/", response_model=CompanyMember, status_code=201)
def add_company_member(
    member: CompanyMemberCreate,
    service: CompanyMemberService = Depends(get_company_member_service),
    current_user=Depends(get_admin),
):
    member_entity = CompanyMemberEntity(**member.model_dump())

    try:
        return service.add_member(member_entity)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    
@router.get("/all/active", response_model=list[CompanyMember])
def get_active_company_members(
    service: CompanyMemberService = Depends(get_company_member_service),
    current_user=Depends(get_admin),
):
    return service.get_active_members()

@router.get("/all/active/{company_id}", response_model=list[CompanyMember])
def get_active_company_members_by_company(
    company_id: int,
    service: CompanyMemberService = Depends(get_company_member_service),
    current_user=Depends(get_admin),
):
    try:
        return service.get_active_members_by_company(company_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

@router.get("/all/{company_id}", response_model=list[CompanyMember])
def get_company_members(
    company_id: int,
    service: CompanyMemberService = Depends(get_company_member_service),
    current_user=Depends(get_admin),
):
    try:
        return service.get_active_members_by_company(company_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

@router.get("/{member_id}", response_model=CompanyMember)
def get_company_member(
    member_id: int,
    service: CompanyMemberService = Depends(get_company_member_service),
    current_user=Depends(get_admin),
):
    try:
        return service.get_member(member_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    
@router.patch("/{member_id}/status", response_model=CompanyMember)
def update_company_member_status(
    member_id: int,
    status_update: CompanyMemberStatusUpdate,
    service: CompanyMemberService = Depends(get_company_member_service),
    current_user=Depends(get_admin),
):
    try:
        return service.update_member_status(member_id, status_update.is_active)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    
@router.patch("/{member_id}/role", response_model=CompanyMember)
def update_company_member_role(
    member_id: int,
    role_update: CompanyMemberRoleUpdate,
    service: CompanyMemberService = Depends(get_company_member_service),
    current_user=Depends(get_admin),
):
    try:
        return service.update_member_role(member_id, role_update.role)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    

