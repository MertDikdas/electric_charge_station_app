from app.domain.models.company_member import CompanyMemberEntity


ALLOWED_COMPANY_MEMBER_ROLES = {
    "COMPANY_MANAGER",
    "COMPANY_OPERATOR",
    "STATION_MANAGER",
    "STATION_OPERATOR",
}


def _validate_positive_int(value: int, field_name: str) -> None:
    if type(value) is not int or value <= 0:
        raise ValueError(f"{field_name} must be a positive integer")


def validate_company_member_entity(member: CompanyMemberEntity) -> None:
    if member is None:
        raise ValueError("Company member cannot be empty")

    _validate_positive_int(member.company_id, "company_id")
    _validate_positive_int(member.user_id, "user_id")
    member.role = validate_company_member_role(member.role)
    validate_company_member_status(member.is_active)


def validate_company_member_role(role: str) -> str:
    if role is None:
        raise ValueError("Role is required")
    if not isinstance(role, str):
        raise ValueError("Role must be a string")

    normalized_role = role.strip().upper()
    if normalized_role not in ALLOWED_COMPANY_MEMBER_ROLES:
        raise ValueError("Invalid role")

    return normalized_role


def validate_company_member_status(is_active: bool) -> None:
    if type(is_active) is not bool:
        raise ValueError("Company member status must be a boolean")
