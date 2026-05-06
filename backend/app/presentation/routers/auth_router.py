from fastapi import APIRouter, Depends, HTTPException

from app.application.services.user_service import UserService
from app.core.dependencies import AuthenticatedUser, get_current_user, get_user_service
from app.schemas.user import User

router = APIRouter()


@router.get("/me", response_model=User)
def get_me(
    current_user: AuthenticatedUser = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
):
    user = service.get_user(current_user.id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
