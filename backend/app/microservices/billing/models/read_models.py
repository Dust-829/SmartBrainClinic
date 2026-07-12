import uuid as uuid_pkg
from datetime import datetime

from sqlalchemy import DateTime, Integer, SmallInteger, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class BillingReadBase(DeclarativeBase):
    pass


class BillingPatientReadModel(BillingReadBase):
    __tablename__ = "patient"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    uuid: Mapped[uuid_pkg.UUID] = mapped_column(UUID(as_uuid=True))
    case_number: Mapped[str] = mapped_column(String(64))
    real_name: Mapped[str] = mapped_column(String(64))
    card_number: Mapped[str] = mapped_column(String(18))


class BillingRegisterReadModel(BillingReadBase):
    __tablename__ = "register"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    uuid: Mapped[uuid_pkg.UUID] = mapped_column(UUID(as_uuid=True))
    patient_id: Mapped[int] = mapped_column(Integer)
    visit_date: Mapped[datetime] = mapped_column(DateTime)
    visit_state: Mapped[int | None] = mapped_column(SmallInteger)
