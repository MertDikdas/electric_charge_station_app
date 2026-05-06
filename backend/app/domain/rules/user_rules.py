from app.domain.models.user import UserEntity

def validate_user_email(user: UserEntity) -> bool:
    """Checks whether the user's email is valid."""
    if "@" not in user.email or "." not in user.email:
        return False
    return True

def validate_user_password(user: UserEntity) -> bool:
    """Checks whether the user's password meets the minimum requirements."""
    if len(user.password_hash) < 2:
        return False
    return True

def validate_balance(user: UserEntity) -> bool:
    """Checks whether the user's balance is non-negative."""
    if user.balance < 0:
        return False
    return True