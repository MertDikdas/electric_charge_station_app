from typing import List

from app.domain.models.vehicle import VehicleEntity
from app.infrastructure.database.tables import Vehicle as VehicleModel
from app.infrastructure.repositories.abstract.vehicle_repository import (
    AbstractVehicleRepository,
)
from app.infrastructure.repositories.sqlalchemy.base import SqlAlchemyRepository


class SqlAlchemyVehicleRepository(
    SqlAlchemyRepository[VehicleEntity, VehicleModel],
    AbstractVehicleRepository,
):
    model = VehicleModel

    def to_model(self, entity: VehicleEntity) -> VehicleModel:
        return VehicleModel(
            id=entity.id,
            user_id=entity.user_id,
            name =entity.name,
            brand=entity.brand,
            model=entity.model,
            plate=entity.plate,
            max_charging_power=entity.max_charging_power,
            battery_capacity=entity.battery_capacity,
            connector_type=entity.connector_type,
            current_type=entity.current_type,
            is_active=entity.is_active,
        )

    def to_entity(self, model: VehicleModel) -> VehicleEntity:
        return VehicleEntity(
            id=model.id,
            user_id=model.user_id,
            name = model.name,
            brand=model.brand,
            model=model.model,
            plate=model.plate,
            max_charging_power=model.max_charging_power,
            battery_capacity=model.battery_capacity,
            connector_type=model.connector_type,
            current_type=model.current_type,
            is_active=model.is_active,
        )

    def list_by_user_id(self, user_id: int) -> List[VehicleEntity]:
        models = (
            self.session.query(VehicleModel)
            .filter(VehicleModel.user_id == user_id)
            .all()
        )
        return [self.to_entity(model) for model in models]

    def update(self, vehicle: VehicleEntity) -> None:
        model = self.session.query(VehicleModel).get(vehicle.id)
        if model:
            model.user_id = vehicle.user_id
            model.name = vehicle.name
            model.brand = vehicle.brand
            model.model = vehicle.model
            model.plate = vehicle.plate
            model.max_charging_power = vehicle.max_charging_power
            model.battery_capacity = vehicle.battery_capacity
            model.connector_type = vehicle.connector_type
            model.current_type = vehicle.current_type
            model.is_active = vehicle.is_active
            self.session.commit()

    def get_all_vehicles_by_plate(self, plate: str) -> list[VehicleEntity]:
        models = self.session.query(VehicleModel).filter(VehicleModel.plate == plate).all()
        return [self.to_entity(model) for model in models]
    
    def get_by_id(self, vehicle_id: int) -> VehicleEntity | None:
        model = self.session.query(VehicleModel).get(vehicle_id)
        if model:
            return self.to_entity(model)
        return None
    
    def deactivate_by_user_id(self, user_id: int) -> None:
        self.session.query(VehicleModel).filter(
            VehicleModel.user_id == user_id,
            VehicleModel.is_active.is_(True),
        ).update(
            {VehicleModel.is_active: False},
            synchronize_session=False,
        )