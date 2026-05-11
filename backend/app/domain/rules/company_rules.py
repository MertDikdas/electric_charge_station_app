from typing import Any

from app.domain.models.company import CompanyEntity


ALLOWED_COMPANY_UPDATE_FIELDS = {
    "name",
    "tax_number",
    "phone",
    "email",
    "address",
    "is_active",
}
OPTIONAL_COMPANY_STRING_FIELDS = {"tax_number", "phone", "email", "address"}


def _normalize_optional_string(value: Any, field_name: str) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str):
        raise ValueError(f"{field_name} must be a string")

    value = value.strip()
    return value or None


def _validate_email(email: str | None) -> None:
    if email and ("@" not in email or "." not in email):
        raise ValueError("Invalid email format")


def validate_company_entity(company: CompanyEntity) -> None:
    if company is None:
        raise ValueError("Company cannot be empty")
    if not isinstance(company.name, str) or not company.name.strip():
        raise ValueError("Company name cannot be empty")

    company.name = company.name.strip()

    for field in OPTIONAL_COMPANY_STRING_FIELDS:
        setattr(company, field, _normalize_optional_string(getattr(company, field), field))

    _validate_email(company.email)
    validate_company_status(company.is_active)


def validate_company_update_data(update_data: dict) -> None:
    if not update_data:
        raise ValueError("No fields provided for update")

    unsupported_fields = set(update_data) - ALLOWED_COMPANY_UPDATE_FIELDS
    if unsupported_fields:
        fields = ", ".join(sorted(unsupported_fields))
        raise ValueError(f"Unsupported fields for company update: {fields}")

    if "name" in update_data:
        name = update_data["name"]
        if not isinstance(name, str) or not name.strip():
            raise ValueError("Company name cannot be empty")
        update_data["name"] = name.strip()

    for field in OPTIONAL_COMPANY_STRING_FIELDS:
        if field in update_data:
            update_data[field] = _normalize_optional_string(update_data[field], field)

    if "email" in update_data:
        _validate_email(update_data["email"])

    if "is_active" in update_data:
        validate_company_status(update_data["is_active"])


def validate_company_status(is_active: bool) -> None:
    if type(is_active) is not bool:
        raise ValueError("Company status must be a boolean")
