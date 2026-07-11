import asyncio
import json
import re
import uuid as uuid_pkg
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import List, Optional

from sqlalchemy import and_, case, delete, func, or_, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.ai_embedding import get_embedding
from app.common.ai_schema import unwrap_ai_data
from app.common.ai_validator import AIResultValidator
from app.common.ai_conversation import get_ai_conversation_session, update_ai_conversation_session
from app.common.enums import BillState, VisitState
from app.common.idempotency import begin_idempotency, complete_idempotency
from app.common.state_machine import ensure_visit_transition
from app.microservices.patient.ws_manager import manager as ws_manager

from ..models.patient import (
    OutboxEvent,
    Patient,
    PatientFeedback,
    Register,
    ScheduleDisruption,
    SchedulingActual,
    SchedulingApplication,
    SchedulingRule,
    SchedulingTimeSlot,
)
from .ai_scheduling import run_ai_scheduling
from .internal_client import AuthClient

async def _sync_time_slots(session: AsyncSession, actual: SchedulingActual, is_new: bool = False):
    interval = 10  # 强制固定每号 10 分钟
    start_time_str = "08:00" if actual.noon == "上午" else "13:00"
    dt_start = datetime.strptime(start_time_str, "%H:%M")

    if is_new:
        for i in range(actual.regist_quota):
            slot_start = dt_start + timedelta(minutes=i * interval)
            slot_end = dt_start + timedelta(minutes=(i + 1) * interval)
            time_range_str = f"{slot_start.strftime('%H:%M')}-{slot_end.strftime('%H:%M')}"
            
            ts = SchedulingTimeSlot(
                scheduling_actual_id=actual.id,
                time_range=time_range_str,
                is_booked=False
            )
            session.add(ts)
    else:
        # 当非新建时（如管理员直接修改额度）
        stmt = select(SchedulingTimeSlot).where(
            SchedulingTimeSlot.scheduling_actual_id == actual.id
        ).order_by(SchedulingTimeSlot.time_range)
        res = await session.execute(stmt)
        existing_slots = res.scalars().all()
        
        current_total = len(existing_slots)
        target_total = actual.regist_quota
        
        if target_total > current_total:
            # 追加 slots
            if existing_slots:
                last_time_str = existing_slots[-1].time_range.split("-")[1]
                dt_append_start = datetime.strptime(last_time_str, "%H:%M")
            else:
                dt_append_start = dt_start
                
            for i in range(target_total - current_total):
                slot_start = dt_append_start + timedelta(minutes=i * interval)
                slot_end = dt_append_start + timedelta(minutes=(i + 1) * interval)
                ts = SchedulingTimeSlot(
                    scheduling_actual_id=actual.id,
                    time_range=f"{slot_start.strftime('%H:%M')}-{slot_end.strftime('%H:%M')}",
                    is_booked=False
                )
                session.add(ts)
        elif target_total < current_total:
            # 从末尾裁剪未被预约的 slots
            to_remove = current_total - target_total
            removed_count = 0
            for ts in reversed(existing_slots):
                if not ts.is_booked:
                    await session.delete(ts)
                    removed_count += 1
                    if removed_count == to_remove:
                        break
            
            # 如果末尾可删的空槽不够，强制让 quota 匹配真实剩余
            if removed_count < to_remove:
                actual.regist_quota = current_total - removed_count
                session.add(actual)

_STATE_MAP = {
    VisitState.UNPAID: "待支付",
    VisitState.REGISTERED: "已挂号",
    VisitState.RECEPTION: "接诊中",
    VisitState.FINISHED: "已结束",
    VisitState.CANCELLED: "已退号"
}


def _ensure_schedule_matches_employee(schedule: SchedulingActual, employee_uuid: uuid_pkg.UUID) -> None:
    if str(schedule.employee_uuid) != str(employee_uuid):
        raise ValueError("所选号源不属于当前医生，请重新选择医生对应的排班")


def _queue_noon_order():
    return case(
        (SchedulingActual.noon == "上午", 0),
        (SchedulingActual.noon == "下午", 1),
        else_=2,
    )


def _queue_state_order():
    return case(
        (Register.visit_state == VisitState.RECEPTION, 0),
        else_=1,
    )


def _broadcast_queue_event(scheduling_actual_id: Optional[int], event_type: str, **payload) -> None:
    if not scheduling_actual_id:
        return
    message = {"type": event_type, **payload}
    try:
        asyncio.create_task(
            ws_manager.broadcast(
                scheduling_actual_id,
                json.dumps(message, ensure_ascii=False),
            )
        )
    except RuntimeError:
        pass


def _broadcast_queue_update(scheduling_actual_id: Optional[int]) -> None:
    _broadcast_queue_event(scheduling_actual_id, "queue_updated")

def _gen_case_number() -> str:
    now = datetime.now()
    import random
    seq = random.randint(1000, 9999)
    return f"BLH{now.strftime('%Y%m%d%H%M%S')}{seq}"


def _serialize_patient(patient: Patient) -> dict:
    return {
        "uuid": str(patient.uuid),
        "case_number": patient.case_number,
        "real_name": patient.real_name,
        "gender": patient.gender,
        "card_number": patient.card_number,
        "birthdate": patient.birthdate.isoformat() if patient.birthdate else None,
        "home_address": patient.home_address,
        "created_at": patient.created_at.isoformat() if patient.created_at else None,
    }


_VALID_NOON_VALUES = {"上午", "下午"}
_VALID_WEEK_RULE_VALUES = {str(i) for i in range(1, 8)}
_VALID_APPLICATION_STATUSES = {"pending", "approved", "rejected", "duplicate"}


def _normalize_noon_value(noon: str) -> str:
    normalized = str(noon or "").strip()
    if normalized not in _VALID_NOON_VALUES:
        raise ValueError("午别仅支持 上午 或 下午")
    return normalized


def _normalize_week_rule(week_rule: str) -> str:
    parts = [item.strip() for item in str(week_rule or "").replace("，", ",").split(",") if item.strip()]
    if not parts:
        raise ValueError("week_rule 不能为空")
    if any(item not in _VALID_WEEK_RULE_VALUES for item in parts):
        raise ValueError("week_rule 仅支持 1-7 的逗号分隔格式")
    deduped: list[str] = []
    for item in parts:
        if item not in deduped:
            deduped.append(item)
    return ",".join(deduped)


def _serialize_scheduling_application(app: SchedulingApplication) -> dict:
    return {
        "uuid": str(app.uuid),
        "employee_uuid": str(app.employee_uuid),
        "prompt": app.prompt,
        "status": app.status,
        "reject_reason": app.reject_reason,
        "created_at": app.created_at.isoformat() if app.created_at else None,
        "processed_at": app.processed_at.isoformat() if app.processed_at else None,
    }


async def _find_scheduling_actual(
    session: AsyncSession,
    employee_uuid: uuid_pkg.UUID,
    schedule_date: date,
    noon: str,
) -> Optional[SchedulingActual]:
    stmt = select(SchedulingActual).where(
        SchedulingActual.employee_uuid == employee_uuid,
        SchedulingActual.schedule_date == schedule_date,
        SchedulingActual.noon == noon,
    )
    return (await session.execute(stmt)).scalar_one_or_none()


async def _list_scheduling_time_slots(session: AsyncSession, scheduling_actual_id: int) -> list[SchedulingTimeSlot]:
    stmt = (
        select(SchedulingTimeSlot)
        .where(SchedulingTimeSlot.scheduling_actual_id == scheduling_actual_id)
        .order_by(SchedulingTimeSlot.time_range.asc())
    )
    return (await session.execute(stmt)).scalars().all()


async def _find_active_register_for_slot(session: AsyncSession, time_slot_id: int) -> Optional[Register]:
    stmt = (
        select(Register)
        .where(
            Register.scheduling_time_slot_id == time_slot_id,
            Register.visit_state != VisitState.CANCELLED,
        )
        .order_by(Register.id.desc())
    )
    return (await session.execute(stmt)).scalars().first()


async def _upsert_schedule_disruption(
    session: AsyncSession,
    register: Register,
    actual: SchedulingActual,
    time_slot: SchedulingTimeSlot,
    message: str,
) -> bool:
    stmt = select(ScheduleDisruption).where(
        ScheduleDisruption.register_id == register.id,
        ScheduleDisruption.status == "unread",
    )
    disruption = (await session.execute(stmt)).scalars().first()
    created = disruption is None
    if disruption is None:
        disruption = ScheduleDisruption(
            patient_id=register.patient_id,
            register_id=register.id,
            original_employee_uuid=actual.employee_uuid,
            original_time_range=time_slot.time_range,
            original_schedule_date=actual.schedule_date,
            original_noon=actual.noon,
            message=message,
        )
    else:
        disruption.original_employee_uuid = actual.employee_uuid
        disruption.original_time_range = time_slot.time_range
        disruption.original_schedule_date = actual.schedule_date
        disruption.original_noon = actual.noon
        disruption.message = message
    session.add(disruption)
    return created


async def _cancel_scheduling_actual(
    session: AsyncSession,
    actual: SchedulingActual,
) -> dict:
    slots = await _list_scheduling_time_slots(session, actual.id)
    disruptions_created = 0
    booked_slots = 0

    for time_slot in slots:
        if time_slot.is_booked:
            booked_slots += 1
            register = await _find_active_register_for_slot(session, time_slot.id)
            if register:
                created = await _upsert_schedule_disruption(
                    session,
                    register,
                    actual,
                    time_slot,
                    f"您预约的 {actual.schedule_date} {actual.noon} 门诊因故取消，请尽快退号或改签",
                )
                disruptions_created += int(created)
        else:
            await session.delete(time_slot)

    if booked_slots == 0:
        await session.execute(delete(SchedulingTimeSlot).where(SchedulingTimeSlot.scheduling_actual_id == actual.id))
        await session.delete(actual)
        return {
            "status": "cancelled",
            "changed": True,
            "disruptions_created": disruptions_created,
            "final_regist_quota": 0,
            "registered_count": 0,
        }

    actual.regist_quota = booked_slots
    if actual.registered_count > booked_slots:
        actual.registered_count = booked_slots
    session.add(actual)
    await session.flush()
    await _sync_time_slots(session, actual, is_new=False)
    return {
        "status": "cancelled_with_existing_registrations",
        "changed": True,
        "disruptions_created": disruptions_created,
        "final_regist_quota": actual.regist_quota,
        "registered_count": actual.registered_count,
    }


async def _cancel_scheduling_after_time(
    session: AsyncSession,
    actual: SchedulingActual,
    time_threshold: str,
) -> dict:
    normalized_threshold = str(time_threshold or "").strip()
    if not re.fullmatch(r"\d{2}:\d{2}", normalized_threshold):
        raise ValueError("cancel_after_time 必须提供 HH:MM 格式的 time_threshold")

    slots = await _list_scheduling_time_slots(session, actual.id)
    disruptions_created = 0
    deleted_unbooked = 0
    affected_slots = 0

    for time_slot in slots:
        slot_start = time_slot.time_range.split("-")[0]
        if slot_start < normalized_threshold:
            continue
        affected_slots += 1
        if time_slot.is_booked:
            register = await _find_active_register_for_slot(session, time_slot.id)
            if register:
                created = await _upsert_schedule_disruption(
                    session,
                    register,
                    actual,
                    time_slot,
                    f"您预约的 {actual.schedule_date} {time_slot.time_range} 时段因故停诊，请尽快退号或改签",
                )
                disruptions_created += int(created)
        else:
            await session.delete(time_slot)
            deleted_unbooked += 1

    if affected_slots == 0:
        return {
            "status": "no_slots_after_threshold",
            "changed": False,
            "disruptions_created": 0,
            "final_regist_quota": actual.regist_quota,
            "registered_count": actual.registered_count,
        }

    remaining_slots = len(slots) - deleted_unbooked
    if remaining_slots <= 0:
        await session.execute(delete(SchedulingTimeSlot).where(SchedulingTimeSlot.scheduling_actual_id == actual.id))
        await session.delete(actual)
        return {
            "status": "cancelled",
            "changed": True,
            "disruptions_created": disruptions_created,
            "final_regist_quota": 0,
            "registered_count": 0,
        }

    actual.regist_quota = remaining_slots
    if actual.registered_count > remaining_slots:
        actual.registered_count = remaining_slots
    session.add(actual)
    await session.flush()
    await _sync_time_slots(session, actual, is_new=False)
    return {
        "status": "trimmed",
        "changed": True,
        "disruptions_created": disruptions_created,
        "final_regist_quota": actual.regist_quota,
        "registered_count": actual.registered_count,
    }


async def _apply_scheduling_actual_change(
    session: AsyncSession,
    *,
    employee_uuid: uuid_pkg.UUID,
    schedule_date: date,
    noon: str,
    regist_quota: int,
    clinic_room_uuid: Optional[uuid_pkg.UUID] = None,
    action_type: str = "modify",
    time_threshold: Optional[str] = None,
) -> dict:
    normalized_noon = _normalize_noon_value(noon)
    target_quota = int(regist_quota)
    if target_quota < 0:
        raise ValueError("regist_quota 不能小于 0")

    actual = await _find_scheduling_actual(session, employee_uuid, schedule_date, normalized_noon)

    if action_type in {"cancel", "cancel_after_time"} and actual is None:
        return {
            "action_type": action_type,
            "target_date": schedule_date.isoformat(),
            "noon": normalized_noon,
            "status": "missing_schedule",
            "changed": False,
            "disruptions_created": 0,
            "final_regist_quota": 0,
            "registered_count": 0,
            "clinic_room_uuid": str(clinic_room_uuid) if clinic_room_uuid else None,
        }

    if action_type == "cancel":
        result = await _cancel_scheduling_actual(session, actual)
    elif action_type == "cancel_after_time":
        result = await _cancel_scheduling_after_time(session, actual, time_threshold or "")
    elif action_type in {"modify", "add"}:
        if actual is None:
            if target_quota <= 0:
                result = {
                    "status": "skipped_zero_quota",
                    "changed": False,
                    "disruptions_created": 0,
                    "final_regist_quota": 0,
                    "registered_count": 0,
                }
            else:
                actual = SchedulingActual(
                    employee_uuid=employee_uuid,
                    schedule_date=schedule_date,
                    noon=normalized_noon,
                    regist_quota=target_quota,
                    registered_count=0,
                    clinic_room_uuid=clinic_room_uuid,
                )
                session.add(actual)
                await session.flush()
                await _sync_time_slots(session, actual, is_new=True)
                result = {
                    "status": "created",
                    "changed": True,
                    "disruptions_created": 0,
                    "final_regist_quota": actual.regist_quota,
                    "registered_count": actual.registered_count,
                }
        else:
            clamped = target_quota < actual.registered_count
            actual.regist_quota = max(target_quota, actual.registered_count)
            if clinic_room_uuid is not None:
                actual.clinic_room_uuid = clinic_room_uuid
            session.add(actual)
            await session.flush()
            await _sync_time_slots(session, actual, is_new=False)
            result = {
                "status": "updated",
                "changed": True,
                "disruptions_created": 0,
                "final_regist_quota": actual.regist_quota,
                "registered_count": actual.registered_count,
                "clamped_to_registered_count": clamped,
            }
    else:
        raise ValueError(f"不支持的排班动作: {action_type}")

    return {
        "action_type": action_type,
        "target_date": schedule_date.isoformat(),
        "noon": normalized_noon,
        "clinic_room_uuid": str(actual.clinic_room_uuid) if actual and actual.clinic_room_uuid else (str(clinic_room_uuid) if clinic_room_uuid else None),
        **result,
    }

async def create_patient(session: AsyncSession, data: dict) -> Patient:
    existing = await session.execute(select(Patient).where(Patient.card_number == data["card_number"]))
    if existing.scalar_one_or_none():
        raise ValueError("该身份证号已注册，请直接登录")
    patient = Patient(
        case_number=_gen_case_number(),
        real_name=data["real_name"],
        gender=data["gender"],
        card_number=data["card_number"],
        birthdate=data["birthdate"],
        home_address=data.get("home_address"),
    )
    session.add(patient)
    await session.flush()
    return patient


async def list_admin_patients(session: AsyncSession, keyword: str = "", limit: int = 20) -> list[dict]:
    normalized_keyword = str(keyword or "").strip()
    safe_limit = max(1, min(int(limit or 20), 100))
    stmt = select(Patient)

    if normalized_keyword:
        fuzzy_keyword = f"%{normalized_keyword}%"
        stmt = stmt.where(
            or_(
                Patient.real_name.ilike(fuzzy_keyword),
                Patient.card_number.ilike(fuzzy_keyword),
            )
        )

    stmt = stmt.order_by(Patient.created_at.desc()).limit(safe_limit)
    result = await session.execute(stmt)
    return [_serialize_patient(patient) for patient in result.scalars().all()]


async def get_admin_patient_stats(session: AsyncSession) -> dict[str, int]:
    patient_total = (
        await session.execute(select(func.count()).select_from(Patient))
    ).scalar_one()
    return {"patient_total": int(patient_total or 0)}


async def update_admin_patient(session: AsyncSession, patient_uuid: uuid_pkg.UUID, data: dict) -> dict:
    patient = await get_patient_by_uuid(session, patient_uuid)
    if not patient:
        raise ValueError("鎮ｈ€呬笉瀛樺湪")

    patient.real_name = data["real_name"]
    patient.gender = data["gender"]
    patient.birthdate = data["birthdate"]
    patient.home_address = data.get("home_address")
    session.add(patient)
    await session.flush()
    return _serialize_patient(patient)

async def get_patient_by_uuid(session: AsyncSession, patient_uuid: uuid_pkg.UUID) -> Optional[Patient]:
    result = await session.execute(select(Patient).where(Patient.uuid == patient_uuid))
    return result.scalar_one_or_none()

async def get_patient_by_card(session: AsyncSession, card_number: str) -> Optional[Patient]:
    result = await session.execute(select(Patient).where(Patient.card_number == card_number))
    return result.scalar_one_or_none()

async def create_register(session: AsyncSession, data: dict) -> dict:
    patient = await get_patient_by_uuid(session, data["patient_uuid"])
    if not patient:
        raise ValueError("患者不存在")

    employee = await AuthClient.get_employee(data["employee_uuid"])
    if not employee:
        raise ValueError("医生不存在")

    # 1. 悲观锁获取并锁定具体的 Time Slot
    if "scheduling_time_slot_uuid" in data and data["scheduling_time_slot_uuid"]:
        stmt_ts = (
            select(SchedulingTimeSlot)
            .where(
                SchedulingTimeSlot.uuid == uuid_pkg.UUID(str(data["scheduling_time_slot_uuid"])),
                SchedulingTimeSlot.is_booked == False
            )
            .with_for_update()
        )
        res_ts = await session.execute(stmt_ts)
        time_slot = res_ts.scalar_one_or_none()
        if not time_slot:
            raise ValueError("排班记录不存在或当前具体时段已被抢占")
            
        schedule = await session.get(SchedulingActual, time_slot.scheduling_actual_id)
        if not schedule:
            raise ValueError("实际排班记录不存在")
        _ensure_schedule_matches_employee(schedule, data["employee_uuid"])
    else:
        # 线下挂号或兼容老接口：自动分配最早可用的空闲时段
        schedule_id = data.get("scheduling_actual_id")
        if not schedule_id:
            raise ValueError("必须提供排班记录ID或具体时段UUID")
            
        schedule = await session.get(SchedulingActual, schedule_id)
        if not schedule:
            raise ValueError("实际排班记录不存在")
        _ensure_schedule_matches_employee(schedule, data["employee_uuid"])
            
        # 使用 skip_locked=True 允许高并发抢号时自动跳过其他事务正在锁定的号段，寻找下一个空闲号段
        stmt_ts_auto = (
            select(SchedulingTimeSlot)
            .where(
                SchedulingTimeSlot.scheduling_actual_id == schedule.id,
                SchedulingTimeSlot.is_booked == False
            )
            .order_by(SchedulingTimeSlot.time_range.asc())
            .with_for_update(skip_locked=True)
            .limit(1)
        )
        res_ts_auto = await session.execute(stmt_ts_auto)
        time_slot = res_ts_auto.scalar_one_or_none()
        if not time_slot:
            raise ValueError("当前门诊号源已满，无可用时段")

    # 3. 检查患者是否已经在当前半天排班下挂过号（且未退号）
    stmt_dup = select(Register).where(
        Register.patient_id == patient.id,
        Register.scheduling_actual_id == schedule.id,
        Register.visit_state != VisitState.CANCELLED
    )
    res_dup = await session.execute(stmt_dup)
    if res_dup.scalar_one_or_none():
        raise ValueError("您已经挂过该医生的当前班次，请勿重复挂号")

    # 4. 更新 Time Slot 状态
    time_slot.is_booked = True
    session.add(time_slot)
    
    # 5. 原子更新上层已挂号总数，防止多个不同 TimeSlot 并发挂号时丢失更新
    stmt_update = (
        update(SchedulingActual)
        .where(SchedulingActual.id == schedule.id)
        .values(registered_count=SchedulingActual.registered_count + 1)
    )
    await session.execute(stmt_update)

    if not employee.get("regist_level_uuid"):
        raise ValueError("无法获取对应医生的挂号级别，请检查医生字典配置")
        
    level = await AuthClient.get_regist_level(employee["regist_level_uuid"])
    if not level:
        raise ValueError("无法获取对应医生的挂号费用，请检查医生字典配置")
        
    regist_fee = Decimal(str(level["regist_fee"]))

    dept = await AuthClient.get_department(employee["dept_uuid"])

    settle_category_uuid_str = data.get("settle_category_uuid")
    if not settle_category_uuid_str:
        zf_settle = await AuthClient.get_settle_category_by_code("ZF")
        if zf_settle and zf_settle.get("uuid"):
            settle_category_uuid_str = zf_settle["uuid"]
            
    settle_category_uuid = uuid_pkg.UUID(str(settle_category_uuid_str)) if settle_category_uuid_str else None

    register = Register(
        patient_id=patient.id,
        visit_date=datetime.now(),
        noon=schedule.noon,
        dept_uuid=uuid_pkg.UUID(str(dept["uuid"])) if dept and dept.get("uuid") else None,
        employee_uuid=uuid_pkg.UUID(str(employee["uuid"])) if employee.get("uuid") else None,
        scheduling_actual_id=schedule.id,
        scheduling_time_slot_id=time_slot.id,
        settle_category_uuid=settle_category_uuid,
        regist_method=data.get("regist_method", "微信"),
        regist_money=regist_fee,
        is_emergency=data.get("is_emergency", False),
        visit_state=VisitState.REGISTERED,
        symptoms=data.get("symptoms", None),
    )
    session.add(register)
    await session.flush()

    # 触发线下挂号成功的 MQ 消息，以便自动生成 AI 病历初稿
    outbox_event = OutboxEvent(
        topic="register:paid",
        payload=json.dumps({
            "register_uuid": str(register.uuid),
            "symptoms": register.symptoms
        }, ensure_ascii=False)
    )
    session.add(outbox_event)
    await session.commit()
    _broadcast_queue_update(register.scheduling_actual_id)

    return {
        "uuid": str(register.uuid),
        "patient_name": patient.real_name,
        "patient_case_number": patient.case_number,
        "doctor_name": employee["realname"],
        "dept_name": dept["dept_name"] if dept else "",
        "visit_date": register.visit_date.isoformat(),
        "noon": register.noon,
        "visit_state": register.visit_state,
        "visit_state_text": _STATE_MAP.get(register.visit_state, "未知"),
    }



async def get_register_by_uuid(session: AsyncSession, register_uuid: uuid_pkg.UUID) -> Optional[Register]:
    result = await session.execute(select(Register).where(Register.uuid == register_uuid))
    return result.scalar_one_or_none()

async def get_registers_by_patient_uuid(session: AsyncSession, patient_uuid: uuid_pkg.UUID) -> list[Register]:
    patient = await get_patient_by_uuid(session, patient_uuid)
    if not patient:
        return []
    result = await session.execute(
        select(Register)
        .where(Register.patient_id == patient.id)
        .order_by(Register.visit_date.desc())
    )
    return result.scalars().all()

async def get_rich_registers_by_patient_uuid(session: AsyncSession, patient_uuid: uuid_pkg.UUID) -> list[dict]:
    raw_registers = await get_registers_by_patient_uuid(session, patient_uuid)
    if not raw_registers:
        return []

    actual_ids = {reg.scheduling_actual_id for reg in raw_registers if reg.scheduling_actual_id}
    slot_ids = {reg.scheduling_time_slot_id for reg in raw_registers if reg.scheduling_time_slot_id}

    actual_map = {}
    if actual_ids:
        actual_result = await session.execute(
            select(SchedulingActual).where(SchedulingActual.id.in_(actual_ids))
        )
        actual_map = {actual.id: actual for actual in actual_result.scalars().all()}

    slot_map = {}
    if slot_ids:
        slot_result = await session.execute(
            select(SchedulingTimeSlot).where(SchedulingTimeSlot.id.in_(slot_ids))
        )
        slot_map = {slot.id: slot for slot in slot_result.scalars().all()}

    employee_cache: dict[str, Optional[dict]] = {}
    department_cache: dict[str, Optional[dict]] = {}
    clinic_room_cache: dict[str, Optional[dict]] = {}
    rich_registers = []

    async def get_employee_cached(employee_uuid) -> Optional[dict]:
        key = str(employee_uuid)
        if key not in employee_cache:
            employee_cache[key] = await AuthClient.get_employee(key)
        return employee_cache[key]

    async def get_department_cached(dept_uuid: str) -> Optional[dict]:
        if dept_uuid not in department_cache:
            department_cache[dept_uuid] = await AuthClient.get_department(dept_uuid)
        return department_cache[dept_uuid]

    async def get_clinic_room_cached(room_uuid) -> Optional[dict]:
        key = str(room_uuid)
        if key not in clinic_room_cache:
            clinic_room_cache[key] = await AuthClient.get_clinic_room(key)
        return clinic_room_cache[key]
    
    for reg in raw_registers:
        # Pydantic V2 model_dump method is not available on SQLAlchemy models, we need to construct it manually or use __dict__
        # SQLAlchemy object doesn't have model_dump. So we manually construct the dict.
        reg_dict = {
            "uuid": str(reg.uuid),
            "visit_date": reg.visit_date.isoformat() if reg.visit_date else None,
            "noon": reg.noon,
            "dept_uuid": str(reg.dept_uuid) if reg.dept_uuid else None,
            "employee_uuid": str(reg.employee_uuid) if reg.employee_uuid else None,
            "regist_method": reg.regist_method,
            "regist_money": float(reg.regist_money) if reg.regist_money else 0.0,
            "is_emergency": reg.is_emergency,
            "visit_state": reg.visit_state,
            "visit_state_str": _STATE_MAP.get(reg.visit_state, "未知状态"),
            "symptoms": reg.symptoms,
            "created_at": reg.visit_date.isoformat() if reg.visit_date else None # map visit_date to created_at
        }
        
        # 1. 查询医生和科室名称
        employee_name = "未知医生"
        dept_name = "未知科室"
        if reg.employee_uuid:
            emp = await get_employee_cached(reg.employee_uuid)
            if emp:
                employee_name = emp.get("realname", "未知医生")
                dept_uuid = emp.get("dept_uuid")
                if dept_uuid:
                    dept = await get_department_cached(str(dept_uuid))
                    if dept:
                        dept_name = dept.get("dept_name", "未知科室")
        
        # 2. 查询确切的排班日期和时间段
        actual = actual_map.get(reg.scheduling_actual_id) if reg.scheduling_actual_id else None
        ts = slot_map.get(reg.scheduling_time_slot_id) if reg.scheduling_time_slot_id else None
        schedule_date = actual.schedule_date.isoformat() if actual else None
        time_range = ts.time_range if ts else None
                
        # 3. 查询具体的诊室信息
        room_name = None
        room_location = None
        if actual and actual.clinic_room_uuid:
            room_info = await get_clinic_room_cached(actual.clinic_room_uuid)
            if room_info:
                room_name = room_info.get("room_name")
                room_location = room_info.get("location")
                
        reg_dict["employee_name"] = employee_name
        reg_dict["dept_name"] = dept_name
        reg_dict["actual_schedule_date"] = schedule_date
        reg_dict["actual_time_range"] = time_range
        reg_dict["clinic_room_name"] = room_name
        reg_dict["clinic_room_location"] = room_location
        rich_registers.append(reg_dict)
        
    return rich_registers

# 医生擅长医疗领域现已通过AuthClient从Employee的expertise读取

async def recommend_doctors(session: AsyncSession, data: dict) -> list:
    """
    智能医生推荐算法 (全自然语言版)
    dept_code 必须由前端在分诊对话或手动选科后传入
    symptoms 来自 AI 分诊的 symptom_summary，或用户手动输入的原始文本
    """

    symptoms = data.get("symptoms", "")
    limit = data.get("limit", 3)

    # 1. 科室确认：必须由前端传入（来自AI分诊结果或用户手动选择）
    dept_code = data.get("dept_code")
    gender_pref = data.get("gender_preference", "不限")
    
    if not dept_code:
        raise ValueError("请先完成AI分诊或手动选择科室后再进行医生推荐")

    # 如果 symptoms 为空（比如用户跳过了AI分诊直接选科室），
    # 用科室名作为兜底文本进行向量检索，不会导致接口失效
    if not symptoms or not symptoms.strip():
        from .ai_triage import DEPT_MAP
        symptoms = DEPT_MAP.get(dept_code, "常规门诊")

    # 2. 获取科室ID
    dept = await AuthClient.get_department_by_code(dept_code)
    if not dept:
        raise ValueError(f"AI识别出的科室[{dept_code}]不存在")

    # 3. 将症状转化为 1024 维向量
    query_vector = await get_embedding(symptoms)

    # 4. 调用 Auth 服务的向量检索接口
    doctors = await AuthClient.search_similar_doctors(
        dept_id=dept["id"],
        gender_preference=gender_pref,
        query_vector=query_vector,
        limit=limit * 3  # 放大查询范围，预留给排班过滤
    )
    
    if not doctors:
        return []

    unique_level_uuids = {doc.get("regist_level_uuid") for doc in doctors if doc.get("regist_level_uuid")}
    level_cache = {}
    if unique_level_uuids:
        async def fetch_level(lvl_uuid):
            return lvl_uuid, await AuthClient.get_regist_level(lvl_uuid)
        results = await asyncio.gather(*(fetch_level(lvl_uuid) for lvl_uuid in unique_level_uuids))
        for lvl_uuid, lvl_data in results:
            if lvl_data:
                level_cache[lvl_uuid] = str(lvl_data["regist_fee"])

    # ====== 1. 批量加载可用排班和时段 (解决 N+1 问题与过期号源问题) ======
    now = datetime.now()
    today_date = now.date()
    now_time_str = now.strftime("%H:%M")

    doc_uuids = [uuid_pkg.UUID(str(doc["uuid"])) for doc in doctors]
    stmt = (
        select(SchedulingActual, SchedulingTimeSlot)
        .join(SchedulingTimeSlot, SchedulingTimeSlot.scheduling_actual_id == SchedulingActual.id)
        .where(
            SchedulingActual.employee_uuid.in_(doc_uuids),
            SchedulingActual.schedule_date >= today_date,
            SchedulingTimeSlot.is_booked == False
        )
        .order_by(SchedulingActual.schedule_date, SchedulingTimeSlot.time_range)
    )
    res = await session.execute(stmt)
    rows = res.all()

    # 按医生聚合有效时段
    doc_schedules = {} # doc_uuid -> dict[actual_id, list[TimeSlot]]
    doc_actuals = {}   # actual_id -> SchedulingActual
    for actual, ts in rows:
        if actual.schedule_date == today_date:
            ts_start = ts.time_range.split("-")[0]
            if ts_start < now_time_str:
                continue # 已过期槽位，作废
                
        doc_id_str = str(actual.employee_uuid)
        if doc_id_str not in doc_schedules:
            doc_schedules[doc_id_str] = {}
        if actual.id not in doc_schedules[doc_id_str]:
            doc_schedules[doc_id_str][actual.id] = []
            doc_actuals[actual.id] = actual
            
        doc_schedules[doc_id_str][actual.id].append(ts)

    # ====== 2. 按医生维度聚合打分并筛选最近排班 ======
    doctor_map = {}  # doctor_uuid -> {doctor_info, best_schedule}

    for doc in doctors:
        doc_uuid = str(doc.get("uuid"))
        if doc_uuid not in doc_schedules or not doc_schedules[doc_uuid]:
            continue  # 该医生没有有效且未过期的排班，跳过
            
        similarity = doc.get("similarity_score", 50.0)

        # 取最近的一个可用班次作为推荐班次
        actual_ids = list(doc_schedules[doc_uuid].keys())
        # 按日期、时段早晚排序
        actual_ids.sort(key=lambda aid: (doc_actuals[aid].schedule_date, doc_schedules[doc_uuid][aid][0].time_range))
        best_actual_id = actual_ids[0]
        best_sched = doc_actuals[best_actual_id]
        
        valid_slots = doc_schedules[doc_uuid][best_actual_id]
        remaining = len(valid_slots)
        earliest_time_slot = valid_slots[0].time_range  # 精确到具体时段
        
        # 组装所有有效排班供前端切换展示
        all_available_schedules = []
        for aid in actual_ids:
            act = doc_actuals[aid]
            all_available_schedules.append({
                "scheduling_actual_uuid": str(act.uuid),
                "schedule_date": act.schedule_date.isoformat(),
                "noon": act.noon,
                "remaining_quota": len(doc_schedules[doc_uuid][aid]),
                "earliest_time_slot": doc_schedules[doc_uuid][aid][0].time_range
            })

        # 专长标签
        if doc.get("expertise"):
            doc_specialties = [x.strip() for x in doc["expertise"].split(",") if x.strip()]
        else:
            doc_specialties = ["常规门诊", "全科医疗"]

        # ====== 综合评分 ======
        # 1. 语义匹配度（基础权重 60%）：来自向量检索的 similarity_score [0, 100]
        score_similarity = similarity * 0.60

        # 2. 性别偏好加成（权重 10%）：匹配+10分，不限+5分，不匹配0分
        score_gender = 0.0
        if gender_pref in ["男", "女"]:
            if doc.get("gender") == gender_pref:
                score_gender = 10.0
        else:
            score_gender = 5.0

        # 3. 号源余裕度（权重 20%）：余号越多越好，满分 100 * 0.2 = 20
        avail_ratio = remaining / best_sched.regist_quota if best_sched.regist_quota > 0 else 0
        score_availability = avail_ratio * 100.0 * 0.20

        # 4. AI 评价分（权重 10%）：来自 employee.ai_eval_score [0, 5] 映射到 [0, 10]
        ai_eval = float(doc.get("ai_eval_score", 3.0) or 3.0)
        score_eval = (ai_eval / 5.0) * 10.0

        composite_score = round(score_similarity + score_gender + score_availability + score_eval, 1)

        lvl_uuid = doc.get("regist_level_uuid")
        regist_fee = level_cache.get(lvl_uuid, "0.00")

        # 如果同一医生已存在（理论上不应该，因为 auth 端已去重），取分数更高的
        if doc_uuid not in doctor_map or composite_score > doctor_map[doc_uuid]["match_score"]:
            doctor_map[doc_uuid] = {
                "doctor_uuid": doc_uuid,
                "doctor_name": doc["realname"],
                "specialties": doc_specialties,
                "match_score": composite_score,
                "similarity_score": round(similarity, 1),
                "scheduling_actual_uuid": str(best_sched.uuid),
                "schedule_date": best_sched.schedule_date.isoformat(),
                "noon": best_sched.noon,
                "earliest_time_slot": earliest_time_slot,
                "regist_fee": regist_fee,
                "remaining_quota": remaining,
                "available_schedules": all_available_schedules
            }

    recommendations = sorted(doctor_map.values(), key=lambda x: x["match_score"], reverse=True)
    return recommendations[:limit]

async def get_schedules_by_doctor(session: AsyncSession, employee_uuid: uuid_pkg.UUID) -> list:
    """
    获取指定医生的有效排班列表（未来7天，自动过滤当天过期时段）
    """
    now = datetime.now()
    today_date = now.date()
    max_date = today_date + timedelta(days=7)
    now_time_str = now.strftime("%H:%M")

    stmt = select(SchedulingActual).where(
        SchedulingActual.employee_uuid == employee_uuid,
        SchedulingActual.schedule_date >= today_date,
        SchedulingActual.schedule_date <= max_date,
        SchedulingActual.registered_count < SchedulingActual.regist_quota
    ).order_by(SchedulingActual.schedule_date, SchedulingActual.noon)
    res = await session.execute(stmt)
    schedules = res.scalars().all()
    
    results = []
    for sched in schedules:
        # 查询该 schedule 的 time slots
        stmt_ts = select(SchedulingTimeSlot).where(
            SchedulingTimeSlot.scheduling_actual_id == sched.id
        ).order_by(SchedulingTimeSlot.time_range)
        res_ts = await session.execute(stmt_ts)
        time_slots = res_ts.scalars().all()
        
        valid_ts_list = []
        for ts in time_slots:
            # 如果是今天的排班，并且未被预约，还需要检查是否已过期
            if sched.schedule_date == today_date and not ts.is_booked:
                ts_start = ts.time_range.split("-")[0]
                if ts_start < now_time_str:
                    continue # 已经过期，作废不展示
            
            valid_ts_list.append({
                "uuid": str(ts.uuid),
                "time_range": ts.time_range,
                "is_booked": ts.is_booked
            })

        # 计算真实的剩余可用号数（非过期且未被占用的）
        real_remaining = sum(1 for ts in valid_ts_list if not ts["is_booked"])
        
        if real_remaining == 0:
            continue

        results.append({
            "scheduling_actual_uuid": str(sched.uuid),
            "employee_uuid": str(sched.employee_uuid),
            "schedule_date": sched.schedule_date.isoformat(),
            "noon": sched.noon,
            "regist_quota": sched.regist_quota,
            "registered_count": sched.regist_quota - real_remaining,
            "remaining_quota": real_remaining,
            "time_slots": valid_ts_list
        })
    return results

async def create_online_register(session: AsyncSession, data: dict) -> dict:
    """
    线上待支付预挂号 (第一阶段：号源槽锁定)
    """
    patient = await get_patient_by_uuid(session, data["patient_uuid"])
    if not patient:
        raise ValueError("患者不存在")

    triage_session_uuid = data.get("triage_session_uuid")
    triage_session = None
    if triage_session_uuid:
        triage_session = await get_ai_conversation_session(session, triage_session_uuid)
        if not triage_session:
            raise ValueError("AI 分诊会话不存在，请重新开始分诊")
        if triage_session.patient_uuid and triage_session.patient_uuid != patient.uuid:
            raise ValueError("AI 分诊会话与当前患者不匹配，请重新开始分诊")

    employee = await AuthClient.get_employee(data["employee_uuid"])
    if not employee:
        raise ValueError("医生不存在")

    # 1. 悲观锁获取并锁定具体的 Time Slot
    if "scheduling_time_slot_uuid" in data and data["scheduling_time_slot_uuid"]:
        stmt_ts = (
            select(SchedulingTimeSlot)
            .where(
                SchedulingTimeSlot.uuid == uuid_pkg.UUID(str(data["scheduling_time_slot_uuid"])),
                SchedulingTimeSlot.is_booked == False
            )
            .with_for_update()
        )
        res_ts = await session.execute(stmt_ts)
        time_slot = res_ts.scalar_one_or_none()
        if not time_slot:
            raise ValueError("排班记录不存在或当前具体时段已被占用")
            
        schedule = await session.get(SchedulingActual, time_slot.scheduling_actual_id)
        if not schedule:
            raise ValueError("实际排班记录不存在")
        _ensure_schedule_matches_employee(schedule, data["employee_uuid"])
    else:
        schedule_id = data.get("scheduling_actual_id")
        if not schedule_id:
            raise ValueError("必须提供排班记录ID或具体时段UUID")
            
        schedule = await session.get(SchedulingActual, schedule_id)
        if not schedule:
            raise ValueError("实际排班记录不存在")
        _ensure_schedule_matches_employee(schedule, data["employee_uuid"])
            
        stmt_ts_auto = (
            select(SchedulingTimeSlot)
            .where(
                SchedulingTimeSlot.scheduling_actual_id == schedule.id,
                SchedulingTimeSlot.is_booked == False
            )
            .order_by(SchedulingTimeSlot.time_range.asc())
            .with_for_update(skip_locked=True)
            .limit(1)
        )
        res_ts_auto = await session.execute(stmt_ts_auto)
        time_slot = res_ts_auto.scalar_one_or_none()
        if not time_slot:
            raise ValueError("当前门诊号源已满，无可用时段")

    # 3. 检查患者是否已经在当前班次挂过号
    stmt_dup = select(Register).where(
        Register.patient_id == patient.id,
        Register.scheduling_actual_id == schedule.id,
        Register.visit_state != VisitState.CANCELLED
    )
    res_dup = await session.execute(stmt_dup)
    if res_dup.scalar_one_or_none():
        raise ValueError("您已经挂过该医生的当前班次，请勿重复挂号")

    # 4. 更新 Time Slot 为占用
    time_slot.is_booked = True
    session.add(time_slot)
    
    # 5. 原子更新上层已挂号总数，防止并发丢失更新
    stmt_update = (
        update(SchedulingActual)
        .where(SchedulingActual.id == schedule.id)
        .values(registered_count=SchedulingActual.registered_count + 1)
    )
    await session.execute(stmt_update)

    # 获取价格
    regist_fee = Decimal("10.00")
    if employee.get("regist_level_uuid"):
        level = await AuthClient.get_regist_level(employee["regist_level_uuid"])
        if level:
            regist_fee = Decimal(str(level["regist_fee"]))

    dept = await AuthClient.get_department(employee["dept_uuid"])

    settle_category_uuid_str = data.get("settle_category_uuid")
    if not settle_category_uuid_str:
        zf_settle = await AuthClient.get_settle_category_by_code("ZF")
        if zf_settle and zf_settle.get("uuid"):
            settle_category_uuid_str = zf_settle["uuid"]
            
    settle_category_uuid = uuid_pkg.UUID(str(settle_category_uuid_str)) if settle_category_uuid_str else None

    # 创建挂号单记录，此时设置状态为 0 (待支付)
    register = Register(
        patient_id=patient.id,
        visit_date=datetime.now(),
        noon=schedule.noon,
        dept_uuid=uuid_pkg.UUID(str(dept["uuid"])) if dept and dept.get("uuid") else None,
        employee_uuid=uuid_pkg.UUID(str(employee["uuid"])) if employee.get("uuid") else None,
        scheduling_actual_id=schedule.id,
        scheduling_time_slot_id=time_slot.id,
        settle_category_uuid=settle_category_uuid,
        regist_method="微信",
        regist_money=regist_fee,
        is_emergency=data.get("is_emergency", False),
        visit_state=VisitState.UNPAID, # 待支付状态锁源
        symptoms=data.get("symptoms", None),
    )
    session.add(register)
    await session.flush()

    if triage_session:
        await update_ai_conversation_session(
            session,
            triage_session.uuid,
            patient_uuid=patient.uuid,
            register_uuid=register.uuid,
            status="linked",
        )

    return {
        "register_uuid": str(register.uuid),
        "regist_money": str(register.regist_money),
        "visit_state": register.visit_state,
        "visit_state_text": "待支付",
        "qr_code_url": f"weixin://wxpay/bizpayurl?pr=simulated_online_reg_{register.uuid}"
    }

async def confirm_online_payment(
    session: AsyncSession,
    register_uuid: uuid_pkg.UUID,
    pay_method: str,
    amount: float,
    idempotency_key: Optional[str] = None,
) -> dict:
    """
    线上模拟支付确认 (第二阶段：正式扣源激活与病历初稿预加载)
    """
    idem = await begin_idempotency(
        session,
        scope="patient.confirm_online_payment",
        idempotency_key=idempotency_key,
        request_payload={
            "register_uuid": str(register_uuid),
            "pay_method": pay_method,
            "amount": str(Decimal(str(amount))),
        },
    )
    if idem and idem.is_replay:
        return idem.response or {}

    register = await get_register_by_uuid(session, register_uuid)
    if not register:
        raise ValueError("挂号单不存在")
    if register.visit_state != VisitState.UNPAID:
        raise ValueError("该挂号单状态已改变，无法支付")
    if amount <= 0:
        raise ValueError("支付金额必须大于 0")
    if round(Decimal(str(amount)), 2) != round(register.regist_money, 2):
        raise ValueError("支付金额与应收挂号费不符")

    schedule = await session.get(SchedulingActual, register.scheduling_actual_id)
    if not schedule:
        raise ValueError("排班记录已失效")

    # 2. 更新挂号单状态为 1 (已挂号)
    target_state = ensure_visit_transition(register.visit_state, VisitState.REGISTERED)
    register.visit_state = int(target_state)
    register.regist_method = pay_method
    session.add(register)
    
    # 3. 发件箱模式：将 MQ 消息体写入本地同事务的 OutboxEvent 表，保证数据强一致性
    
    outbox_event = OutboxEvent(
        topic="register:paid",
        payload=json.dumps({
            "register_uuid": str(register.uuid),
            "symptoms": register.symptoms
        }, ensure_ascii=False)
    )
    session.add(outbox_event)

    result = {
        "register_uuid": str(register.uuid),
        "visit_state": register.visit_state,
        "visit_state_text": "已挂号",
        "queue_number": schedule.registered_count,
        "transaction_id": f"{'WX' if pay_method == '微信' else 'ALI'}{datetime.now().strftime('%Y%m%d%H%M%S')}{register.id}"
    }
    await complete_idempotency(session, idem, result)

    # 统一提交本地事务（挂号单状态变更 + 发件箱事件 + 幂等记录）
    await session.commit()
    _broadcast_queue_update(register.scheduling_actual_id)

    return result

async def update_visit_state(session: AsyncSession, register_uuid: uuid_pkg.UUID, visit_state: int) -> dict:
    """
    更新挂号单状态
    """
    return await _transition_visit_state(session, register_uuid, visit_state)


async def start_reception(session: AsyncSession, register_uuid: uuid_pkg.UUID) -> dict:
    return await _transition_visit_state(session, register_uuid, VisitState.RECEPTION)


async def finish_visit(session: AsyncSession, register_uuid: uuid_pkg.UUID) -> dict:
    return await _transition_visit_state(session, register_uuid, VisitState.FINISHED)


async def _transition_visit_state(session: AsyncSession, register_uuid: uuid_pkg.UUID, visit_state: int | VisitState) -> dict:
    stmt = select(Register).where(Register.uuid == register_uuid).with_for_update()
    res = await session.execute(stmt)
    register = res.scalar_one_or_none()
    if not register:
        raise ValueError("挂号单不存在")

    target_state = ensure_visit_transition(register.visit_state, visit_state)
    if int(target_state) == int(VisitState.RECEPTION) and register.visit_state != int(VisitState.RECEPTION):
        active_stmt = (
            select(Register)
            .where(
                Register.employee_uuid == register.employee_uuid,
                Register.visit_state == VisitState.RECEPTION,
                Register.uuid != register.uuid,
            )
            .with_for_update()
            .limit(1)
        )
        active_register = (await session.execute(active_stmt)).scalar_one_or_none()
        if active_register:
            raise ValueError("当前医生已有接诊中的患者，请先完成当前接诊后再开始下一位。")

    register.visit_state = int(target_state)
    session.add(register)
    await session.flush()

    # 状态发生变化（接诊、结束等），触发同排班房间的队列广播
    _broadcast_queue_update(register.scheduling_actual_id)

    return {
        "uuid": str(register.uuid),
        "visit_state": register.visit_state,
        "visit_state_text": _STATE_MAP.get(register.visit_state, "未知")
    }


async def call_next_patient(session: AsyncSession, employee_uuid: uuid_pkg.UUID) -> dict:
    stmt = (
        select(Register, Patient, SchedulingActual, SchedulingTimeSlot)
        .join(Patient, Register.patient_id == Patient.id)
        .join(SchedulingActual, Register.scheduling_actual_id == SchedulingActual.id)
        .outerjoin(SchedulingTimeSlot, Register.scheduling_time_slot_id == SchedulingTimeSlot.id)
        .where(
            Register.employee_uuid == employee_uuid,
            SchedulingActual.schedule_date == date.today(),
            Register.visit_state == VisitState.REGISTERED,
        )
        .order_by(
            _queue_noon_order(),
            SchedulingTimeSlot.time_range.asc().nullslast(),
            Register.visit_date,
        )
        .limit(1)
    )
    row = (await session.execute(stmt)).first()
    if not row:
        return {"called": False, "message": "今日暂无待叫号患者"}

    register, patient, actual, slot = row
    result = {
        "called": True,
        "register_uuid": str(register.uuid),
        "patient_uuid": str(patient.uuid),
        "patient_name": patient.real_name,
        "patient_case_number": patient.case_number,
        "visit_state": register.visit_state,
        "visit_state_text": _STATE_MAP.get(register.visit_state, "未知"),
        "time_range": slot.time_range if slot else None,
        "clinic_room_uuid": str(actual.clinic_room_uuid) if actual.clinic_room_uuid else None,
    }
    _broadcast_queue_event(
        register.scheduling_actual_id,
        "queue_called",
        register_uuid=str(register.uuid),
        patient_uuid=str(patient.uuid),
        patient_name=patient.real_name,
        time_range=slot.time_range if slot else None,
    )
    return result

async def get_queue_status(session: AsyncSession, register_uuid: uuid_pkg.UUID) -> dict:
    """
    动态计算当前挂号单前面的等待人数
    """
    register = await get_register_by_uuid(session, register_uuid)
    if not register:
        raise ValueError("挂号单不存在")
        
    if register.visit_state not in [VisitState.REGISTERED, VisitState.RECEPTION]:
        return {"ahead_of_you": 0, "status": register.visit_state}
        
    if register.visit_state == VisitState.RECEPTION:
        ahead = 0
    else:
        current_slot = None
        if register.scheduling_time_slot_id:
            current_slot = await session.get(SchedulingTimeSlot, register.scheduling_time_slot_id)

        if current_slot:
            ahead_condition = or_(
                SchedulingTimeSlot.time_range < current_slot.time_range,
                and_(
                    SchedulingTimeSlot.time_range == current_slot.time_range,
                    Register.id < register.id,
                ),
            )
            stmt = (
                select(func.count())
                .select_from(Register)
                .join(
                    SchedulingTimeSlot,
                    Register.scheduling_time_slot_id == SchedulingTimeSlot.id,
                )
                .where(
                    Register.scheduling_actual_id == register.scheduling_actual_id,
                    Register.visit_state.in_([VisitState.REGISTERED, VisitState.RECEPTION]),
                    ahead_condition,
                )
            )
        else:
            stmt = select(func.count()).where(
                Register.scheduling_actual_id == register.scheduling_actual_id,
                Register.visit_state.in_([VisitState.REGISTERED, VisitState.RECEPTION]),
                Register.id < register.id,
            )

        result = await session.execute(stmt)
        ahead = result.scalar() or 0
    # 查询诊室信息
    clinic_room_name = None
    clinic_room_location = None
    if register.scheduling_actual_id:
        actual = await session.get(SchedulingActual, register.scheduling_actual_id)
        if actual and actual.clinic_room_uuid:
            from app.common.clients import AuthClient
            room_info = await AuthClient.get_clinic_room(str(actual.clinic_room_uuid))
            if room_info:
                clinic_room_name = room_info.get("room_name")
                clinic_room_location = room_info.get("location")

    return {
        "ahead_of_you": ahead,
        "status": register.visit_state,
        "clinic_room_name": clinic_room_name,
        "clinic_room_location": clinic_room_location
    }
async def cancel_register(session: AsyncSession, register_uuid: uuid_pkg.UUID) -> dict:
    """
    退号逻辑：释放号源，状态变更为已退号
    """
    # 使用 Select for Update 悲观锁对挂号单记录加锁，防止并发退号产生的数据不一致
    stmt_lock = select(Register).where(Register.uuid == register_uuid).with_for_update()
    res = await session.execute(stmt_lock)
    register = res.scalar_one_or_none()
    
    if not register:
        raise ValueError("挂号单不存在")
        
    from app.common.clients import BillingClient
    bills = await BillingClient.get_bills_by_register(register_uuid)
    blocking_bills = [
        b for b in bills
        if b.get("bill_state") != BillState.REFUNDED.value
    ]
    if blocking_bills:
        states = "、".join(sorted({str(b.get("bill_state")) for b in blocking_bills}))
        raise ValueError(f"该挂号单下存在未完成退费账单（{states}），请先完成退费操作后再退号")
        
    if register.visit_state in [VisitState.RECEPTION, VisitState.FINISHED]:
        raise ValueError("该患者已在看诊或已结束看诊，无法退号！")
        
    if register.visit_state == VisitState.CANCELLED:
        raise ValueError("退号失败：该单据状态已变更或正在处理中！")
        
    # 更新挂号单状态
    target_state = ensure_visit_transition(register.visit_state, VisitState.CANCELLED)
    register.visit_state = int(target_state)
    session.add(register)
        
    # 原子恢复号源
    if register.scheduling_time_slot_id:
        stmt_ts = update(SchedulingTimeSlot).where(SchedulingTimeSlot.id == register.scheduling_time_slot_id).values(is_booked=False)
        await session.execute(stmt_ts)

    stmt = (
        update(SchedulingActual)
        .where(
            SchedulingActual.id == register.scheduling_actual_id,
            SchedulingActual.registered_count > 0
        )
        .values(registered_count=SchedulingActual.registered_count - 1)
    )
    await session.execute(stmt)
    await session.flush()
    _broadcast_queue_update(register.scheduling_actual_id)
    
    return {
        "register_uuid": str(register.uuid),
        "visit_state": register.visit_state,
        "visit_state_text": "已退号",
        "message": "退号成功，号源已释放"
    }

async def ai_schedule(session: AsyncSession, employee_uuid: uuid_pkg.UUID, prompt: str) -> dict:
    """
    通过自然语言智能微调排班
    """
    employee = await AuthClient.get_employee(str(employee_uuid))
    if not employee:
        raise ValueError("医生不存在")

    ai_res = await run_ai_scheduling(prompt, str(employee_uuid))
    res = unwrap_ai_data(ai_res)
    if not isinstance(res, dict):
        raise ValueError("AI 排班结果格式异常")

    validation = AIResultValidator.validate_scheduling(res, base_date=date.today())
    if not validation.is_valid:
        raise ValueError(f"AI 排班建议无效: {'; '.join(validation.messages)}")

    actions = res.get("actions", [])
    llm_text_rule = str(res.get("llm_text_rule", "") or "").strip()

    applied_count = 0
    disruptions_created = 0
    action_summaries = []
    for act in actions:
        action_type = str(act.get("action_type") or "").strip()
        target_date_str = str(act.get("target_date") or "").strip()
        if not target_date_str:
            raise ValueError("AI 排班动作缺少 target_date")
        target_date = date.fromisoformat(target_date_str)
        if target_date < date.today():
            raise ValueError(f"AI 排班动作日期不能早于今天: {target_date_str}")

        noon = _normalize_noon_value(str(act.get("noon") or "").strip())
        quota = int(act.get("regist_quota", 0))
        if quota < 0:
            raise ValueError("AI 排班动作的 regist_quota 不能为负数")

        clinic_room_uuid = None
        clinic_room_name = str(act.get("clinic_room_name") or "").strip()
        if clinic_room_name:
            room_info = await AuthClient.get_clinic_room_by_name(clinic_room_name)
            if not room_info or not room_info.get("uuid"):
                raise ValueError(f"未找到诊室: {clinic_room_name}")
            clinic_room_uuid = uuid_pkg.UUID(str(room_info["uuid"]))

        summary = await _apply_scheduling_actual_change(
            session,
            employee_uuid=employee_uuid,
            schedule_date=target_date,
            noon=noon,
            regist_quota=quota,
            clinic_room_uuid=clinic_room_uuid,
            action_type=action_type,
            time_threshold=act.get("time_threshold"),
        )
        if summary.get("changed"):
            applied_count += 1
        disruptions_created += int(summary.get("disruptions_created", 0) or 0)
        action_summaries.append(summary)

    stmt_rule = select(SchedulingRule).where(
        SchedulingRule.employee_uuid == employee_uuid
    )
    rule_res = await session.execute(stmt_rule)
    rules = rule_res.scalars().all()
    if rules:
        for r in rules:
            r.llm_text_rule = llm_text_rule
            r.employee_uuid = employee_uuid
            session.add(r)
    else:
        new_rule = SchedulingRule(
            employee_uuid=employee_uuid,
            rule_name=f"{employee.get('realname', '医生')}的AI规则",
            week_rule="1,2,3,4,5",
            llm_text_rule=llm_text_rule,
            regist_quota=30,
            delmark=1
        )
        session.add(new_rule)
        
    await session.flush()
    return {
        "employee_uuid": str(employee_uuid),
        "employee_name": employee.get("realname"),
        "llm_text_rule": llm_text_rule,
        "actions_applied": applied_count,
        "disruptions_created": disruptions_created,
        "action_summaries": action_summaries,
        "success": True
    }


async def generate_scheduling_actuals(session: AsyncSession, start_date_str: str, end_date_str: str) -> dict:
    """
    根据排班规律自动批量生成实际排班。
    """
    start_date = date.fromisoformat(start_date_str)
    end_date = date.fromisoformat(end_date_str)
    
    if end_date < start_date:
        raise ValueError(f"结束日期 {end_date_str} 不能早于开始日期 {start_date_str}")
        
    if (end_date - start_date).days > 180:
        raise ValueError("单次排班生成跨度不能超过 180 天")
    
    stmt = select(SchedulingRule).where(SchedulingRule.delmark == 1)
    rule_res = await session.execute(stmt)
    rules = rule_res.scalars().all()
    
    generated_count = 0
    skipped_count = 0
    current_date = start_date
    delta = timedelta(days=1)
    
    while current_date <= end_date:
        wday = str(current_date.weekday() + 1)
        for rule in rules:
            active_days = _normalize_week_rule(rule.week_rule).split(",")
            if wday in active_days:
                for noon in ["上午", "下午"]:
                    existing = await _find_scheduling_actual(session, rule.employee_uuid, current_date, noon)
                    if existing:
                        skipped_count += 1
                        continue
                    if rule.regist_quota <= 0:
                        skipped_count += 1
                        continue

                    new_actual = SchedulingActual(
                        employee_uuid=rule.employee_uuid,
                        schedule_date=current_date,
                        noon=noon,
                        regist_quota=rule.regist_quota,
                        registered_count=0,
                        clinic_room_uuid=rule.clinic_room_uuid
                    )
                    session.add(new_actual)
                    await session.flush()
                    await _sync_time_slots(session, new_actual, is_new=True)
                    generated_count += 1
        current_date += delta
        
    await session.flush()
    return {
        "start_date": start_date_str,
        "end_date": end_date_str,
        "generated_count": generated_count,
        "skipped_count": skipped_count,
        "success": True
    }

async def get_doctor_queue(session: AsyncSession, employee_uuid: uuid_pkg.UUID) -> list:
    """
    获取指定医生的当天候诊队列（已挂号、接诊中）
    """
    stmt = (
        select(Register, Patient, SchedulingActual, SchedulingTimeSlot)
        .join(Patient, Register.patient_id == Patient.id)
        .join(SchedulingActual, Register.scheduling_actual_id == SchedulingActual.id)
        .outerjoin(SchedulingTimeSlot, Register.scheduling_time_slot_id == SchedulingTimeSlot.id)
        .where(
            Register.employee_uuid == employee_uuid,
            SchedulingActual.schedule_date == date.today(),
            Register.visit_state.in_([VisitState.REGISTERED, VisitState.RECEPTION])
        )
        .order_by(
            _queue_state_order(),
            _queue_noon_order(),
            SchedulingTimeSlot.time_range.asc().nullslast(),
            Register.visit_date,
        )
    )
    res = await session.execute(stmt)
    rows = res.all()
    
    results = []
    for reg, pat, actual, slot in rows:
        clinic_room_name = "未指定诊室"
        if actual.clinic_room_uuid:
            room_info = await AuthClient.get_clinic_room(str(actual.clinic_room_uuid))
            if room_info and room_info.get("room_name"):
                clinic_room_name = room_info["room_name"]

        results.append({
            "register_uuid": str(reg.uuid),
            "patient_uuid": str(pat.uuid),
            "patient_name": pat.real_name,
            "patient_case_number": pat.case_number,
            "gender": pat.gender,
            "symptoms": reg.symptoms,
            "visit_state": reg.visit_state,
            "visit_state_text": _STATE_MAP.get(reg.visit_state, "未知"),
            "visit_date": reg.visit_date.isoformat(),
            "time_range": slot.time_range if slot else None,
            "clinic_room_name": clinic_room_name
        })
    return results

async def create_patient_feedback(session: AsyncSession, data: dict) -> dict:
    feedback = PatientFeedback(
        register_uuid=uuid_pkg.UUID(str(data["register_uuid"])),
        doctor_uuid=uuid_pkg.UUID(str(data["doctor_uuid"])),
        content=data["content"]
    )
    session.add(feedback)
    await session.commit()
    return {"uuid": str(feedback.uuid), "status": "success"}


async def create_scheduling_application(session: AsyncSession, employee_uuid: uuid_pkg.UUID, prompt: str) -> dict:
    normalized_prompt = " ".join(str(prompt or "").split())
    if not normalized_prompt:
        raise ValueError("排班申请内容不能为空")

    employee = await AuthClient.get_employee(str(employee_uuid))
    if not employee:
        raise ValueError("医生不存在")

    existing_stmt = (
        select(SchedulingApplication)
        .where(
            SchedulingApplication.employee_uuid == employee_uuid,
            SchedulingApplication.prompt == normalized_prompt,
            SchedulingApplication.status == "pending",
        )
        .order_by(SchedulingApplication.created_at.desc())
    )
    existing = (await session.execute(existing_stmt)).scalars().first()
    if existing:
        return {"uuid": str(existing.uuid), "status": existing.status, "deduplicated": True}

    app = SchedulingApplication(
        employee_uuid=employee_uuid,
        prompt=normalized_prompt,
        status="pending"
    )
    session.add(app)
    try:
        await session.flush()
    except IntegrityError:
        await session.rollback()
        existing = (await session.execute(existing_stmt)).scalars().first()
        if existing:
            return {"uuid": str(existing.uuid), "status": existing.status, "deduplicated": True}
        raise
    return {
        "uuid": str(app.uuid),
        "status": "pending",
        "deduplicated": False,
        "reject_reason": None,
        "processed_at": None,
    }

async def get_pending_scheduling_applications(session: AsyncSession, status: Optional[str] = "pending") -> list:
    normalized_status = str(status or "pending").strip().lower()
    stmt = select(SchedulingApplication)
    if normalized_status not in {"all", "*"}:
        if normalized_status not in _VALID_APPLICATION_STATUSES:
            raise ValueError("status 仅支持 pending/approved/rejected/duplicate/all")
        stmt = stmt.where(SchedulingApplication.status == normalized_status)
    stmt = stmt.order_by(SchedulingApplication.created_at.desc())
    res = await session.execute(stmt)
    apps = res.scalars().all()
    return [_serialize_scheduling_application(app) for app in apps]

async def approve_scheduling_application(session: AsyncSession, app_uuid: uuid_pkg.UUID) -> dict:
    stmt = select(SchedulingApplication).where(SchedulingApplication.uuid == app_uuid)
    res = await session.execute(stmt)
    app = res.scalar_one_or_none()
    if not app:
        raise ValueError("申请不存在")
    if app.status != "pending":
        raise ValueError("该申请已处理，请勿重复操作")

    ai_result = await ai_schedule(session, app.employee_uuid, app.prompt)
    app.status = "approved"
    app.reject_reason = None
    app.processed_at = datetime.now()
    session.add(app)
    await session.flush()
    
    return {
        "uuid": str(app.uuid),
        "status": "approved",
        "reject_reason": app.reject_reason,
        "processed_at": app.processed_at.isoformat() if app.processed_at else None,
        "ai_result": ai_result,
    }

async def reject_scheduling_application(session: AsyncSession, app_uuid: uuid_pkg.UUID, reason: str = "") -> dict:
    stmt = select(SchedulingApplication).where(SchedulingApplication.uuid == app_uuid)
    res = await session.execute(stmt)
    app = res.scalar_one_or_none()
    if not app:
        raise ValueError("申请不存在")
    if app.status != "pending":
        raise ValueError("该申请已处理，请勿重复操作")

    app.status = "rejected"
    app.reject_reason = str(reason or "").strip() or None
    app.processed_at = datetime.now()
    session.add(app)
    await session.flush()
    
    return {
        "uuid": str(app.uuid),
        "status": "rejected",
        "reason": app.reject_reason,
        "reject_reason": app.reject_reason,
        "processed_at": app.processed_at.isoformat() if app.processed_at else None,
    }

async def admin_update_scheduling_rule(session: AsyncSession, data: dict) -> dict:
    employee_uuid = uuid_pkg.UUID(str(data["employee_uuid"]))
    employee = await AuthClient.get_employee(str(employee_uuid))
    if not employee:
        raise ValueError("医生不存在")

    week_rule = _normalize_week_rule(data.get("week_rule", "1,2,3,4,5"))
    regist_quota = data.get("regist_quota", 30)
    if regist_quota is not None and int(regist_quota) < 0:
        raise ValueError("regist_quota 不能小于 0")

    stmt = select(SchedulingRule).where(SchedulingRule.employee_uuid == employee_uuid)
    res = await session.execute(stmt)
    rule = res.scalar_one_or_none()
    
    if rule:
        if "week_rule" in data:
            rule.week_rule = week_rule
        if "regist_quota" in data:
            rule.regist_quota = int(regist_quota)
        if "llm_text_rule" in data:
            rule.llm_text_rule = data["llm_text_rule"]
        if "rule_name" in data and data["rule_name"]:
            rule.rule_name = str(data["rule_name"]).strip()
        if "clinic_room_uuid" in data:
            rule.clinic_room_uuid = uuid_pkg.UUID(str(data["clinic_room_uuid"])) if data["clinic_room_uuid"] else None
        session.add(rule)
    else:
        rule = SchedulingRule(
            employee_uuid=employee_uuid,
            rule_name=data.get("rule_name", "管理员强制新增规则"),
            week_rule=week_rule,
            llm_text_rule=data.get("llm_text_rule", "管理员后台人工介入"),
            regist_quota=int(regist_quota),
            clinic_room_uuid=uuid_pkg.UUID(str(data["clinic_room_uuid"])) if data.get("clinic_room_uuid") else None,
            delmark=1
        )
        session.add(rule)
        
    await session.flush()
    return {
        "employee_uuid": str(employee_uuid),
        "week_rule": rule.week_rule,
        "regist_quota": rule.regist_quota,
        "clinic_room_uuid": str(rule.clinic_room_uuid) if rule.clinic_room_uuid else None,
        "success": True,
    }

async def admin_update_scheduling_actual(session: AsyncSession, data: dict) -> dict:
    employee_uuid = uuid_pkg.UUID(str(data["employee_uuid"]))
    employee = await AuthClient.get_employee(str(employee_uuid))
    if not employee:
        raise ValueError("医生不存在")
    target_date = date.fromisoformat(data["schedule_date"])
    noon = _normalize_noon_value(data["noon"])
    regist_quota = int(data.get("regist_quota", 0))
    clinic_room_uuid = uuid_pkg.UUID(str(data["clinic_room_uuid"])) if data.get("clinic_room_uuid") else None

    summary = await _apply_scheduling_actual_change(
        session,
        employee_uuid=employee_uuid,
        schedule_date=target_date,
        noon=noon,
        regist_quota=regist_quota,
        clinic_room_uuid=clinic_room_uuid,
        action_type="cancel" if regist_quota == 0 else "modify",
    )

    await session.flush()
    return {
        "employee_uuid": str(employee_uuid),
        "schedule_date": str(target_date),
        "noon": noon,
        "regist_quota": summary.get("final_regist_quota", regist_quota),
        "registered_count": summary.get("registered_count", 0),
        "disruptions_created": summary.get("disruptions_created", 0),
        "status": summary.get("status"),
        "clinic_room_uuid": summary.get("clinic_room_uuid"),
        "success": True,
    }

async def get_patient_disruptions(session: AsyncSession, patient_uuid: uuid_pkg.UUID) -> list[dict]:
    stmt_p = select(Patient).where(Patient.uuid == patient_uuid)
    res_p = await session.execute(stmt_p)
    patient = res_p.scalar_one_or_none()
    if not patient:
        raise ValueError("患者不存在")
        
    stmt = select(ScheduleDisruption).where(
        ScheduleDisruption.patient_id == patient.id,
        ScheduleDisruption.status == "unread"
    )
    res = await session.execute(stmt)
    disruptions = res.scalars().all()
    
    out = []
    for d in disruptions:
        out.append({
            "uuid": str(d.uuid),
            "original_employee_uuid": str(d.original_employee_uuid),
            "original_schedule_date": d.original_schedule_date.isoformat(),
            "original_noon": d.original_noon,
            "original_time_range": d.original_time_range,
            "message": d.message,
            "status": d.status,
            "created_at": d.created_at.isoformat() if d.created_at else None
        })
    return out

async def resolve_schedule_disruption(session: AsyncSession, uuid: uuid_pkg.UUID, action: str, new_time_slot_uuid: Optional[uuid_pkg.UUID] = None) -> dict:
    stmt = select(ScheduleDisruption).where(ScheduleDisruption.uuid == uuid).with_for_update()
    res = await session.execute(stmt)
    disruption = res.scalar_one_or_none()
    if not disruption:
        raise ValueError("异常工单不存在")
    if disruption.status != "unread":
        raise ValueError("异常工单已处理")
        
    stmt_reg = select(Register).where(Register.id == disruption.register_id).with_for_update()
    res_reg = await session.execute(stmt_reg)
    register = res_reg.scalar_one_or_none()
    if not register or register.visit_state == VisitState.CANCELLED:
        disruption.status = "resolved"
        session.add(disruption)
        await session.flush()
        return {"success": True, "message": "该挂号单已退号，工单自动关闭"}
        
    if action == "cancel":
        await cancel_register(session, register.uuid)
        disruption.status = "resolved"
        session.add(disruption)
        
    elif action == "reassign_doctor":
        dept_uuid = register.dept_uuid
        if not dept_uuid:
            raise ValueError("挂号单缺少科室信息，无法平替")
        doctors = await AuthClient.get_doctors_by_department(str(dept_uuid))
        doctor_uuids = [d["uuid"] for d in doctors if str(d["uuid"]) != str(disruption.original_employee_uuid)]
        
        found_slot = None
        found_actual = None
        for d_uuid_str in doctor_uuids:
            stmt_act = select(SchedulingActual).where(
                SchedulingActual.employee_uuid == uuid_pkg.UUID(d_uuid_str),
                SchedulingActual.schedule_date == disruption.original_schedule_date,
                SchedulingActual.noon == disruption.original_noon
            )
            res_act = await session.execute(stmt_act)
            actual = res_act.scalar_one_or_none()
            if actual:
                stmt_ts = select(SchedulingTimeSlot).where(
                    SchedulingTimeSlot.scheduling_actual_id == actual.id,
                    SchedulingTimeSlot.time_range == disruption.original_time_range,
                    SchedulingTimeSlot.is_booked == False
                ).with_for_update()
                res_ts = await session.execute(stmt_ts)
                ts = res_ts.scalar_one_or_none()
                if ts:
                    found_slot = ts
                    found_actual = actual
                    break
                    
        if not found_slot:
            raise ValueError("抱歉，当前时间段同科室的其他医生均已约满，请尝试改签其他时间")
            
        if register.scheduling_time_slot_id:
            old_ts_stmt = select(SchedulingTimeSlot).where(SchedulingTimeSlot.id == register.scheduling_time_slot_id)
            old_ts = (await session.execute(old_ts_stmt)).scalar_one_or_none()
            if old_ts:
                await session.delete(old_ts)
                
            old_act_stmt = select(SchedulingActual).where(SchedulingActual.id == register.scheduling_actual_id)
            old_act = (await session.execute(old_act_stmt)).scalar_one_or_none()
            if old_act and old_act.registered_count > 0:
                stmt_dec = update(SchedulingActual).where(SchedulingActual.id == old_act.id, SchedulingActual.registered_count > 0).values(registered_count=SchedulingActual.registered_count - 1)
                await session.execute(stmt_dec)
                
        found_slot.is_booked = True
        stmt_inc = update(SchedulingActual).where(SchedulingActual.id == found_actual.id).values(registered_count=SchedulingActual.registered_count + 1)
        await session.execute(stmt_inc)
        
        register.employee_uuid = found_actual.employee_uuid
        register.scheduling_actual_id = found_actual.id
        register.scheduling_time_slot_id = found_slot.id
        
        session.add(found_slot)
        session.add(register)
        disruption.status = "resolved"
        session.add(disruption)
        
    elif action == "reassign_time":
        if not new_time_slot_uuid:
            raise ValueError("改签时间必须提供 new_time_slot_uuid")
            
        stmt_ts = select(SchedulingTimeSlot).where(SchedulingTimeSlot.uuid == new_time_slot_uuid, SchedulingTimeSlot.is_booked == False).with_for_update()
        res_ts = await session.execute(stmt_ts)
        new_ts = res_ts.scalar_one_or_none()
        if not new_ts:
            raise ValueError("选择的新时间槽不可用或已被占用")
            
        stmt_act = select(SchedulingActual).where(SchedulingActual.id == new_ts.scheduling_actual_id).with_for_update()
        res_act = await session.execute(stmt_act)
        new_actual = res_act.scalar_one_or_none()
        if not new_actual:
            raise ValueError("新排班数据异常")
            
        if register.scheduling_time_slot_id:
            old_ts_stmt = select(SchedulingTimeSlot).where(SchedulingTimeSlot.id == register.scheduling_time_slot_id)
            old_ts = (await session.execute(old_ts_stmt)).scalar_one_or_none()
            if old_ts:
                await session.delete(old_ts)
                
            old_act_stmt = select(SchedulingActual).where(SchedulingActual.id == register.scheduling_actual_id)
            old_act = (await session.execute(old_act_stmt)).scalar_one_or_none()
            if old_act and old_act.registered_count > 0:
                stmt_dec = update(SchedulingActual).where(SchedulingActual.id == old_act.id, SchedulingActual.registered_count > 0).values(registered_count=SchedulingActual.registered_count - 1)
                await session.execute(stmt_dec)
                
        new_ts.is_booked = True
        stmt_inc = update(SchedulingActual).where(SchedulingActual.id == new_actual.id).values(registered_count=SchedulingActual.registered_count + 1)
        await session.execute(stmt_inc)
        
        register.scheduling_actual_id = new_actual.id
        register.scheduling_time_slot_id = new_ts.id
        register.employee_uuid = new_actual.employee_uuid 
        
        session.add(new_ts)
        session.add(register)
        disruption.status = "resolved"
        session.add(disruption)
    else:
        raise ValueError("无效的处理操作")

    await session.flush()
    return {"uuid": str(uuid), "status": "resolved", "success": True}

async def auto_resolve_expired_disruptions(session: AsyncSession, threshold_hours: int = 12) -> int:
    """
    自动处理即将过期或已过期的未读冲突工单（自动退号兜底）
    """
    now = datetime.now()
    
    # 查找所有 unread 状态的工单
    stmt = select(ScheduleDisruption).where(ScheduleDisruption.status == "unread")
    res = await session.execute(stmt)
    disruptions = res.scalars().all()
    
    resolved_count = 0
    
    for d in disruptions:
        # 解析原本就诊时间的起点
        # original_time_range 格式如 "08:00-08:08" 或 "08:00"
        try:
            start_time_str = d.original_time_range.split("-")[0]
            dt_str = f"{d.original_schedule_date.isoformat()} {start_time_str}:00"
            dt_target = datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S")
        except Exception:
            continue
            
        # 如果 当前时间 + 阈值时间 >= 原就诊时间，则兜底强制退号
        if now + timedelta(hours=threshold_hours) >= dt_target:
            stmt_reg = select(Register).where(Register.id == d.register_id)
            reg = (await session.execute(stmt_reg)).scalar_one_or_none()
            if reg and reg.visit_state != VisitState.CANCELLED:
                try:
                    await cancel_register(session, reg.uuid)
                except Exception as e:
                    # 退费失败等情况（如已看诊），跳过
                    print(f"Auto-cancel failed for register {reg.uuid}: {e}")
                    continue
                    
            d.status = "resolved"
            d.message = d.message + f"\n[系统通知] 由于临近原定就诊时间（不足{threshold_hours}小时），系统已自动为您办理了退号与原路退费。"
            session.add(d)
            resolved_count += 1
            
    await session.flush()
    return resolved_count
