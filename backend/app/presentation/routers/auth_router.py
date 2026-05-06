from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.application.services.user_service import UserService
from app.core.dependencies import AuthenticatedUser, get_current_user, get_user_service
from app.schemas.user import User

router = APIRouter()
security = HTTPBearer(auto_error=False)


@router.get("/me", response_model=User)
def get_me(
    current_user: AuthenticatedUser = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
):
    user = service.get_user(current_user.id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post("/logout")
def logout(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    service: UserService = Depends(get_user_service),
):
    if credentials is None:
        raise HTTPException(status_code=401, detail="Authentication required")

    if credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Invalid authentication header")

    token = credentials.credentials

    revoked = service.logout_user(token)
    if not revoked:
        raise HTTPException(status_code=401, detail="Invalid session")

    return {"message": "Logged out successfully"}
