import uuid as uuid_pkg
from typing import Optional
from datetime import date, datetime
from decimal import Decimal
from sqlmodel import SQLModel, Field
from sqlalchemy import Column, SmallInteger, Boolean, Text

class Patient(SQLModel, table=True):
    __tablename__ = "patient"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    case_number: str = Field(max_length=64, unique=True, nullable=False)
    real_name: str = Field(max_length=64, nullable=False)
    gender: str = Field(max_length=10, nullable=False)
    card_number: str = Field(max_length=18, unique=True, nullable=False)
    birthdate: date = Field(nullable=False)
    home_address: Optional[str] = Field(default=None, max_length=255)
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

class SchedulingActual(SQLModel, table=True):
    __tablename__ = "scheduling_actual"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    employee_uuid: uuid_pkg.UUID = Field(nullable=False, index=True)
    schedule_date: date = Field(nullable=False)
    noon: str = Field(max_length=10, nullable=False)
    regist_quota: int = Field(default=30, nullable=False)
    registered_count: int = Field(default=0, nullable=False)
    slot_duration_minutes: int = Field(default=10, nullable=False)
    clinic_room_uuid: Optional[uuid_pkg.UUID] = Field(default=None, index=True)

class SchedulingTimeSlot(SQLModel, table=True):
    __tablename__ = "scheduling_time_slot"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    scheduling_actual_id: int = Field(nullable=False, foreign_key="scheduling_actual.id")
    time_range: str = Field(max_length=64, nullable=False) # e.g. "08:00-08:08"
    is_booked: bool = Field(default=False, sa_column=Column(Boolean, default=False))

class SchedulingRule(SQLModel, table=True):
    __tablename__ = "scheduling_rule"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    employee_uuid: uuid_pkg.UUID = Field(nullable=False, index=True)
    rule_name: str = Field(max_length=64, nullable=False)
    week_rule: str = Field(max_length=14, nullable=False) # e.g. "1,2,3,4,5" bitmap or list
    llm_text_rule: Optional[str] = Field(default=None, sa_column=Column(Text))
    regist_quota: int = Field(default=30, nullable=False)
    slot_duration_minutes: int = Field(default=10, nullable=False)
    clinic_room_uuid: Optional[uuid_pkg.UUID] = Field(default=None, index=True)
    delmark: Optional[int] = Field(
        default=1, sa_column=Column(SmallInteger, default=1)
    )

class PatientFeedback(SQLModel, table=True):
    __tablename__ = "patient_feedback"

    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    register_uuid: uuid_pkg.UUID = Field(nullable=False, description="关联的挂号单")
    doctor_uuid: uuid_pkg.UUID = Field(nullable=False, description="评价的医生")
    content: str = Field(sa_column=Column(Text, nullable=False), description="评价内容")
    is_processed: bool = Field(default=False, description="是否已被夜间AI脚本处理")
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

from app.common.enums import VisitState

class Register(SQLModel, table=True):
    __tablename__ = "register"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    patient_id: int = Field(nullable=False, foreign_key="patient.id")
    visit_date: datetime = Field(nullable=False)
    noon: str = Field(max_length=10, nullable=False)
    dept_uuid: Optional[uuid_pkg.UUID] = Field(default=None, nullable=True, index=True)
    employee_uuid: uuid_pkg.UUID = Field(nullable=False, index=True)
    scheduling_actual_id: Optional[int] = Field(default=None, foreign_key="scheduling_actual.id")
    scheduling_time_slot_id: Optional[int] = Field(default=None, foreign_key="scheduling_time_slot.id")
    settle_category_uuid: Optional[uuid_pkg.UUID] = Field(default=None) # Logic link to Auth
    regist_method: Optional[str] = Field(default=None, max_length=20)
    regist_money: Decimal = Field(max_digits=8, decimal_places=2, nullable=False)
    is_emergency: Optional[bool] = Field(default=False, sa_column=Column(Boolean, default=False))
    visit_state: Optional[int] = Field(default=VisitState.UNPAID, sa_column=Column(SmallInteger, default=VisitState.UNPAID))
    symptoms: Optional[str] = Field(default=None, sa_column=Column(Text))  # 存储对话历史JSON或纯文本症状

class OutboxEvent(SQLModel, table=True):
    __tablename__ = "outbox_event"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    topic: str = Field(max_length=255, nullable=False)
    payload: str = Field(sa_column=Column(Text, nullable=False))
    status: str = Field(default="pending", max_length=20, index=True)
    retry_count: Optional[int] = Field(default=0)
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

class SchedulingApplication(SQLModel, table=True):
    __tablename__ = "scheduling_application"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    employee_uuid: uuid_pkg.UUID = Field(nullable=False, index=True, description="提交申请的医生UUID")
    prompt: str = Field(sa_column=Column(Text, nullable=False), description="医生的排班诉求")
    status: str = Field(default="pending", max_length=20, index=True, description="状态: pending/approved/rejected")
    reject_reason: Optional[str] = Field(default=None, sa_column=Column(Text))
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
    processed_at: Optional[datetime] = Field(default=None)

class ScheduleDisruption(SQLModel, table=True):
    __tablename__ = "schedule_disruption"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    patient_id: int = Field(nullable=False, foreign_key="patient.id", index=True)
    register_id: int = Field(nullable=False, foreign_key="register.id")
    original_employee_uuid: uuid_pkg.UUID = Field(nullable=False)
    original_time_range: str = Field(max_length=64, nullable=False)
    original_schedule_date: date = Field(nullable=False)
    original_noon: str = Field(max_length=10, nullable=False)
    message: str = Field(sa_column=Column(Text, nullable=False))
    status: str = Field(default="unread", max_length=20, index=True) # unread, resolved
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
