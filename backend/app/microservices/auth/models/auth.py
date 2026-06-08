"""
基础字典与人员配置模块 ORM 实体
对应数据库表: department, regist_level, settle_category, employee
"""

import uuid as uuid_pkg
from typing import Optional
from decimal import Decimal
from datetime import datetime
from sqlmodel import SQLModel, Field
from sqlalchemy import Column, SmallInteger, Text
from pgvector.sqlalchemy import Vector


# ====================================================================
# 1. 科室字典表 (department)
# ====================================================================
class Department(SQLModel, table=True):
    __tablename__ = "department"

    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    dept_code: str = Field(max_length=64, unique=True, nullable=False,
                           description="科室编码，如 SJWK (神经外科)")
    dept_name: str = Field(max_length=64, nullable=False,
                           description="科室名称，如 神经外科")
    dept_type: str = Field(max_length=64, nullable=False,
                           description="科室类型: 门诊/检查/检验/处置/药房")
    delmark: Optional[int] = Field(
        default=1, sa_column=Column(SmallInteger, default=1),
        description="软删除标记: 1-生效, 0-已删除"
    )


class ClinicRoom(SQLModel, table=True):
    __tablename__ = "clinic_room"

    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    dept_uuid: uuid_pkg.UUID = Field(nullable=False, index=True, description="所属科室UUID")
    room_name: str = Field(max_length=64, nullable=False, description="诊室名称，如 第一诊室")
    location: Optional[str] = Field(default=None, max_length=128, description="物理位置")
    delmark: Optional[int] = Field(
        default=1, sa_column=Column(SmallInteger, default=1)
    )

# ====================================================================
# 2. 挂号级别表 (regist_level)
# ====================================================================
class RegistLevel(SQLModel, table=True):
    __tablename__ = "regist_level"

    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    regist_code: str = Field(max_length=64, unique=True, nullable=False,
                             description="级别编码，如 ZJH (专家号)")
    regist_name: str = Field(max_length=64, nullable=False,
                             description="级别名称，如 专家门诊")
    regist_fee: Decimal = Field(max_digits=8, decimal_places=2, nullable=False,
                                description="挂号单价 (元)")
    delmark: Optional[int] = Field(
        default=1, sa_column=Column(SmallInteger, default=1)
    )


# ====================================================================
# 3. 结算类别表 (settle_category)
# ====================================================================
class SettleCategory(SQLModel, table=True):
    __tablename__ = "settle_category"

    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    settle_code: str = Field(max_length=64, unique=True, nullable=False,
                             description="结算编码，如 ZF (自费), YB (医保)")
    settle_name: str = Field(max_length=64, nullable=False,
                             description="结算名称")
    delmark: Optional[int] = Field(
        default=1, sa_column=Column(SmallInteger, default=1)
    )


# ====================================================================
# 4. 医院员工表 (employee) —— 含企业级 UUID
# ====================================================================
class Employee(SQLModel, table=True):
    __tablename__ = "employee"

    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(
        default_factory=uuid_pkg.uuid4,
        unique=True, nullable=False, index=True,
        description="逻辑业务ID，用于对外接口交互与 JWT Token"
    )
    dept_id: Optional[int] = Field(default=None, foreign_key="department.id",
                                   description="所属科室ID")
    regist_level_id: Optional[int] = Field(default=None, foreign_key="regist_level.id",
                                           description="号别级别ID (门诊医生有效)")
    realname: str = Field(max_length=64, nullable=False,
                          description="员工真实姓名")
    password: str = Field(max_length=128, nullable=False,
                          description="Bcrypt 哈希加密后的安全密码密文")
    expertise: Optional[str] = Field(
        default=None, max_length=512,
        description="医生专长领域 (用逗号分隔)"
    )
    gender: Optional[str] = Field(
        default=None, max_length=10,
        description="性别: 男/女"
    )
    expertise_vector: Optional[list[float]] = Field(
        default=None, sa_column=Column(Vector(1024)),
        description="医生专长的向量表示 (bge-m3 1024维)"
    )
    ai_eval_score: Optional[Decimal] = Field(
        default=Decimal("3.0"), max_digits=3, decimal_places=1,
        description="AI 星级评估 (0.0-5.0)"
    )
    delmark: Optional[int] = Field(
        default=1, sa_column=Column(SmallInteger, default=1)
    )

class OutboxEvent(SQLModel, table=True):
    __tablename__ = "outbox_event"
    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    topic: str = Field(max_length=255, nullable=False)
    payload: str = Field(sa_column=Column(Text, nullable=False))
    status: str = Field(default="pending", max_length=20, index=True)
    retry_count: Optional[int] = Field(default=0)
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
