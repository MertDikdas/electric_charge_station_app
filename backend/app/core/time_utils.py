from datetime import datetime
from zoneinfo import ZoneInfo


TURKEY_TZ = ZoneInfo("Europe/Istanbul")


def now_in_turkey() -> datetime:
    return datetime.now(TURKEY_TZ)