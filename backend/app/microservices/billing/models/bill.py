import uuid as uuid_pkg
from typing import Optional
from datetime import datetime
from decimal import Decimal
from sqlalchemy import Column, Text, UniqueConstraint
from sqlmodel import SQLModel, Field
from app.common.enums import BillState

class OutpatientBill(SQLModel, table=True):
    __tablename__ = "outpatient_bill"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    register_uuid: uuid_pkg.UUID = Field(nullable=False) # Logic link
    bill_code: str = Field(max_length=64, unique=True, nullable=False)
    total_amount: Decimal = Field(max_digits=10, decimal_places=2, nullable=False)
    settle_category_uuid: Optional[uuid_pkg.UUID] = Field(default=None) # Logic link
    pay_method: str = Field(max_length=32, nullable=False)
    pay_time: Optional[datetime] = Field(default_factory=datetime.now)
    transaction_id: Optional[str] = Field(default=None, max_length=128)
    bill_state: str = Field(default=BillState.PAID.value, max_length=32, nullable=False)

class OutpatientBillDetail(SQLModel, table=True):
    __tablename__ = "outpatient_bill_detail"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    bill_id: int = Field(nullable=False, foreign_key="outpatient_bill.id")
    item_type: str = Field(max_length=64, nullable=False)
    item_source_id: str = Field(max_length=64, nullable=False)
    amount: Decimal = Field(max_digits=8, decimal_places=2, nullable=False)

class BillingItemChargeLock(SQLModel, table=True):
    __tablename__ = "billing_item_charge_lock"
    __table_args__ = (
        UniqueConstraint("item_type", "item_source_id", name="uq_billing_item_charge_lock_item"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    item_type: str = Field(max_length=64, nullable=False)
    item_source_id: str = Field(max_length=64, nullable=False)
    bill_id: int = Field(nullable=False, foreign_key="outpatient_bill.id")
    bill_code: str = Field(max_length=64, nullable=False)
    created_at: Optional[datetime] = Field(default_factory=datetime.now)

class BillingRefundSagaStep(SQLModel, table=True):
    __tablename__ = "billing_refund_saga_step"
    __table_args__ = (
        UniqueConstraint("bill_code", "step_name", name="uq_billing_refund_saga_step"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    bill_code: str = Field(max_length=64, nullable=False, index=True)
    step_name: str = Field(max_length=64, nullable=False)
    status: str = Field(default="pending", max_length=32, nullable=False, index=True)
    request_payload: Optional[str] = Field(default=None, sa_column=Column(Text))
    response_payload: Optional[str] = Field(default=None, sa_column=Column(Text))
    error_message: Optional[str] = Field(default=None, sa_column=Column(Text))
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = Field(default_factory=datetime.now)

class OutboxEvent(SQLModel, table=True):
    __tablename__ = "outbox_event"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    topic: str = Field(max_length=255, nullable=False)
    payload: str = Field(sa_column=Column(Text, nullable=False))
    status: str = Field(default="pending", max_length=20, index=True)
    retry_count: Optional[int] = Field(default=0)
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
