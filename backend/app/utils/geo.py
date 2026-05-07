from math import radians, sin, cos, sqrt, atan2


EARTH_RADIUS_KM = 6371.0


def calculate_distance_km(
    lat1: float,
    lon1: float,
    lat2: float,
    lon2: float,
) -> float:
    """
    Calculates distance between two coordinates using the Haversine formula.
    """
    lat1_rad = radians(lat1)
    lon1_rad = radians(lon1)
    lat2_rad = radians(lat2)
    lon2_rad = radians(lon2)

    delta_lat = lat2_rad - lat1_rad
    delta_lon = lon2_rad - lon1_rad

    a = (
        sin(delta_lat / 2) ** 2
        + cos(lat1_rad) * cos(lat2_rad) * sin(delta_lon / 2) ** 2
    )

    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return EARTH_RADIUS_KM * c


def is_coordinate_inside_bounds(
    latitude: float,
    longitude: float,
    north: float,
    south: float,
    east: float,
    west: float,
) -> bool:
    return (
        south <= latitude <= north
        and west <= longitude <= east
    )