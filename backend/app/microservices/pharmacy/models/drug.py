import uuid as uuid_pkg
from typing import Optional
from datetime import datetime
from decimal import Decimal
from sqlmodel import SQLModel, Field
from sqlalchemy import Column, SmallInteger, Boolean
from pgvector.sqlalchemy import Vector

class DrugInfo(SQLModel, table=True):
    __tablename__ = "drug_info"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    drug_code: str = Field(max_length=64, unique=True, nullable=False)
    drug_name: str = Field(max_length=255, nullable=False)
    specification: str = Field(max_length=128, nullable=False)
    unit: str = Field(max_length=32, nullable=False)
    price: Decimal = Field(max_digits=8, decimal_places=2, nullable=False)
    stock: int = Field(default=0, nullable=False)
    min_stock_limit: Optional[int] = Field(default=10, nullable=True)
    delmark: Optional[int] = Field(default=1, sa_column=Column(SmallInteger, default=1))
    vector: Optional[list[float]] = Field(default=None, sa_column=Column(Vector(1024)))

from app.common.enums import DrugState

class Prescription(SQLModel, table=True):
    __tablename__ = "prescription"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    register_uuid: uuid_pkg.UUID = Field(nullable=False) # Logic link
    prescription_code: str = Field(max_length=64, unique=True, nullable=False)
    creation_time: Optional[datetime] = Field(default_factory=datetime.now)
    is_ai_recommended: Optional[bool] = Field(default=True, sa_column=Column(Boolean, default=True))
    drug_state: str = Field(default=DrugState.PRESCRIBED, max_length=64, nullable=False)


class PrescriptionItem(SQLModel, table=True):
    __tablename__ = "prescription_item"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    prescription_id: int = Field(nullable=False, foreign_key="prescription.id")
    drug_id: int = Field(nullable=False, foreign_key="drug_info.id")
    drug_usage: str = Field(max_length=255, nullable=False)
    drug_number: int = Field(nullable=False)
