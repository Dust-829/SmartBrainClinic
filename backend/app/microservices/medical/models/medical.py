import uuid as uuid_pkg
from typing import Optional, Any
from datetime import datetime
from decimal import Decimal
from sqlmodel import SQLModel, Field
from sqlalchemy import Column, Boolean, Text, JSON, SmallInteger
from sqlalchemy.dialects.postgresql import JSONB
from pgvector.sqlalchemy import Vector
from app.common.enums import CheckState, InspectionState, DisposalState

class MedicalRecord(SQLModel, table=True):
    __tablename__ = "medical_record"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    register_uuid: uuid_pkg.UUID = Field(unique=True, nullable=False) # Logic link to Patient Service
    readme: Optional[str] = Field(default=None, sa_column=Column(Text))
    present: Optional[str] = Field(default=None, sa_column=Column(Text))
    history: Optional[str] = Field(default=None, sa_column=Column(Text))
    allergy: Optional[str] = Field(default=None, max_length=512)
    physique: Optional[str] = Field(default=None, sa_column=Column(Text))
    proposal: Optional[str] = Field(default=None, sa_column=Column(Text))
    diagnosis: Optional[str] = Field(default=None, sa_column=Column(Text))
    is_doctor_confirmed: Optional[bool] = Field(default=False, sa_column=Column(Boolean, default=False))
    cure: Optional[str] = Field(default=None, sa_column=Column(Text))
    dialog_vector: Optional[Any] = Field(default=None, sa_column=Column(Vector(1024)))

class Disease(SQLModel, table=True):
    __tablename__ = "disease"
    id: Optional[int] = Field(default=None, primary_key=True)
    disease_code: str = Field(max_length=64, unique=True, nullable=False)
    disease_name: str = Field(max_length=255, nullable=False)
    disease_type: Optional[str] = Field(default=None, max_length=64)
    delmark: Optional[int] = Field(default=1, sa_column=Column(SmallInteger, default=1))
    disease_vector: Optional[Any] = Field(default=None, sa_column=Column(Vector(1024)))

class MedicalTechnology(SQLModel, table=True):
    __tablename__ = "medical_technology"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    tech_code: str = Field(max_length=64, unique=True, nullable=False)
    tech_name: str = Field(max_length=255, nullable=False)
    tech_type: str = Field(max_length=64, nullable=False)
    price: Decimal = Field(max_digits=8, decimal_places=2, nullable=False)
    delmark: Optional[int] = Field(default=1, sa_column=Column(SmallInteger, default=1))

class CheckRequest(SQLModel, table=True):
    __tablename__ = "check_request"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    register_uuid: uuid_pkg.UUID = Field(nullable=False) # Logic link
    medical_technology_id: int = Field(nullable=False, foreign_key="medical_technology.id")
    check_info: Optional[str] = Field(default=None, max_length=512)
    check_position: Optional[str] = Field(default=None, max_length=255)
    creation_time: Optional[datetime] = Field(default_factory=datetime.now)
    inputcheck_employee_uuid: Optional[uuid_pkg.UUID] = Field(default=None)
    check_time: Optional[datetime] = Field(default=None)
    image_path: Optional[str] = Field(default=None, max_length=512)
    ai_tumor_prob: Optional[Decimal] = Field(default=None, max_digits=5, decimal_places=2)
    check_result: Optional[str] = Field(default=None, sa_column=Column(Text))
    check_state: str = Field(default=CheckState.UNPAID, max_length=64, nullable=False)

class InspectionRequest(SQLModel, table=True):
    __tablename__ = "inspection_request"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    register_uuid: uuid_pkg.UUID = Field(nullable=False)
    medical_technology_id: int = Field(nullable=False, foreign_key="medical_technology.id")
    creation_time: Optional[datetime] = Field(default_factory=datetime.now)
    input_employee_uuid: Optional[uuid_pkg.UUID] = Field(default=None)
    inspection_time: Optional[datetime] = Field(default=None)
    test_results: Optional[Any] = Field(default=None, sa_column=Column(JSONB))
    inspection_state: str = Field(default=InspectionState.UNPAID, max_length=64, nullable=False)

class DisposalRequest(SQLModel, table=True):
    __tablename__ = "disposal_request"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    register_uuid: uuid_pkg.UUID = Field(nullable=False)
    medical_technology_id: int = Field(nullable=False, foreign_key="medical_technology.id")
    creation_time: Optional[datetime] = Field(default_factory=datetime.now)
    disposal_time: Optional[datetime] = Field(default=None)
    disposal_state: str = Field(default=DisposalState.UNPAID, max_length=64, nullable=False)
    disposal_result: Optional[str] = Field(default=None, sa_column=Column(Text))


class MedicalRecordDisease(SQLModel, table=True):
    __tablename__ = "medical_record_disease"
    id: Optional[int] = Field(default=None, primary_key=True)
    medical_record_id: int = Field(nullable=False, foreign_key="medical_record.id")
    disease_id: int = Field(nullable=False, foreign_key="disease.id")
    is_primary: Optional[bool] = Field(default=True, sa_column=Column(Boolean, default=True))

class OutboxEvent(SQLModel, table=True):
    __tablename__ = "outbox_event"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    topic: str = Field(max_length=255, nullable=False)
    payload: str = Field(sa_column=Column(Text, nullable=False))
    status: str = Field(default="pending", max_length=20, index=True)
    retry_count: Optional[int] = Field(default=0)
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
