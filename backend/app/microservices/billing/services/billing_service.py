from datetime import datetime
from decimal import Decimal
import asyncio
import random
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.postgresql import insert as pg_insert
from ..models.bill import BillingItemChargeLock, OutpatientBill, OutpatientBillDetail
from .internal_client import PatientClient, MedicalClient, PharmacyClient
import uuid as uuid_pkg
from app.common.clients import AuthClient
import json
from ..models.bill import OutboxEvent
from sqlalchemy import select
from app.common.enums import (
    BillState,
    VisitState,
)
from app.common.idempotency import begin_idempotency, complete_idempotency, fail_idempotency
from app.common.state_machine import (
    ensure_bill_transition,
)

def _gen_bill_code() -> str:
    now = datetime.now()
    import random
    seq = random.randint(1000, 9999)
    return f"FP{now.strftime('%Y%m%d%H%M%S')}{seq}"


def _item_key(detail: dict) -> tuple[str, str]:
    return detail["item_type"], detail["item_source_id"]


def _ensure_no_duplicate_request_items(detail_records: list[dict]) -> None:
    seen: set[tuple[str, str]] = set()
    duplicates: list[str] = []
    for detail in detail_records:
        key = _item_key(detail)
        if key in seen:
            duplicates.append(f"{key[0]}:{key[1]}")
        seen.add(key)

    if duplicates:
        raise ValueError(f"同一收费请求中包含重复项目: {', '.join(duplicates)}")


async def _reserve_bill_items(
    session: AsyncSession,
    bill: OutpatientBill,
    detail_records: list[dict],
) -> None:
    """
    Reserve source items in the billing database before writing bill details.

    The unique constraint on (item_type, item_source_id) is the concurrency
    guard: two different idempotency keys can race, but only one transaction can
    reserve a source item.
    """
    _ensure_no_duplicate_request_items(detail_records)
    values = [
        {
            "item_type": detail["item_type"],
            "item_source_id": detail["item_source_id"],
            "bill_id": bill.id,
            "bill_code": bill.bill_code,
        }
        for detail in detail_records
    ]
    if not values:
        return

    stmt = (
        pg_insert(BillingItemChargeLock)
        .values(values)
        .on_conflict_do_nothing(index_elements=["item_type", "item_source_id"])
        .returning(BillingItemChargeLock.item_type, BillingItemChargeLock.item_source_id)
    )
    result = await session.execute(stmt)
    reserved_keys = {(row[0], row[1]) for row in result.all()}
    expected_keys = [_item_key(detail) for detail in detail_records]

    if len(reserved_keys) != len(expected_keys):
        conflicts = [
            f"{item_type}:{item_source_id}"
            for item_type, item_source_id in expected_keys
            if (item_type, item_source_id) not in reserved_keys
        ]
        raise ValueError(f"重复扣款拦截: 以下项目已被其他账单占用: {', '.join(conflicts)}")


async def create_bill(session: AsyncSession, data: dict) -> dict:
    idempotency_key = data.get("idempotency_key")
    idem = await begin_idempotency(
        session,
        scope="billing.create_bill",
        idempotency_key=idempotency_key,
        request_payload={
            "register_uuid": str(data.get("register_uuid")),
            "item_ids": data.get("item_ids", []),
            "pay_method": data.get("pay_method", "微信"),
            "settle_category_uuid": str(data.get("settle_category_uuid")) if data.get("settle_category_uuid") else None,
        },
    )
    if idem and idem.is_replay:
        return idem.response or {}
    
    reg = await PatientClient.get_register(data["register_uuid"])
    if not reg:
        raise ValueError("挂号记录不存在")
        
    if reg.get("visit_state") in [VisitState.CANCELLED, VisitState.UNPAID]:
        state_map = {0: "待支付", 1: "已挂号", 2: "接诊中", 3: "已结束", 4: "已退号"}
        curr_state = state_map.get(reg.get("visit_state"), "未知")
        raise ValueError(f"挂号单当前状态为 '{curr_state}'，无法进行缴费操作")

    # 动态 [合规性防腐]：如果是给处方药缴费，必须要求病历确诊；如果是检查检验，则放行
    has_drug = any(item["type"] == "药品" for item in data["item_ids"])
    if has_drug:
        record_draft = await MedicalClient.get_medical_record_draft(data["register_uuid"])
        if not record_draft or not record_draft.get("is_doctor_confirmed"):
            raise ValueError("处方药缴费被拦截：病历尚未经过医生最后确诊，请等待确诊后再行缴费发药")

    total_amount = Decimal("0.00")
    detail_records = []

    # 1. 分类聚合请求
    check_uuids, inspection_uuids, disposal_uuids, drug_uuids = [], [], [], []
    for item in data["item_ids"]:
        item_type = item["type"]
        item_id = str(item["id"])
        try:
            uuid_pkg.UUID(item_id)
        except ValueError:
            raise ValueError(f"项目 {item_type} 的 ID 必须是有效的 UUID 字符串")

        if item_type == "检查":
            check_uuids.append(item_id)
        elif item_type == "检验":
            inspection_uuids.append(item_id)
        elif item_type == "处置":
            disposal_uuids.append(item_id)
        elif item_type == "药品":
            drug_uuids.append(item_id)
        else:
            raise ValueError(f"未知的项目类型: {item_type}")

    # 2. 并发发起批量网络请求 (极大消除 N+1 瓶颈)
    medical_data, pharmacy_data = await asyncio.gather(
        MedicalClient.get_requests_batch(check_uuids, inspection_uuids, disposal_uuids),
        PharmacyClient.get_prescription_items_for_billing(drug_uuids)
    )
    
    pharmacy_dict = {pi["uuid"]: pi for pi in pharmacy_data} if pharmacy_data else {}
    pharmacy_by_prescription = {}
    for pi in pharmacy_data or []:
        prescription_key = pi.get("prescription_uuid") or str(pi.get("prescription_id"))
        pharmacy_by_prescription.setdefault(prescription_key, []).append(pi)
    charged_prescriptions = set()

    # 3. 内存处理与计算
    for item in data["item_ids"]:
        item_type = item["type"]
        item_id = str(item["id"])
        amount = Decimal("0.00")

        if item_type in ["检查", "检验", "处置"]:
            if item_type == "检查":
                request_data = medical_data.get("checks", {}).get(item_id)
            elif item_type == "检验":
                request_data = medical_data.get("inspections", {}).get(item_id)
            else:
                request_data = medical_data.get("disposals", {}).get(item_id)

            if not request_data or str(request_data.get("register_uuid")) != str(reg["uuid"]):
                raise ValueError(f"项目所有权校验失败: 无法为不属于当前挂号单的{item_type}项目 {item_id} 缴费")
            if request_data.get("state") != "未缴费":
                raise ValueError(f"重复扣款拦截: {item_type}项目 {item_id} 已处于 '{request_data.get('state')}' 状态")

            amount = Decimal(str(request_data.get("price", "0.00")))
            
        elif item_type == "药品":
            pi = pharmacy_dict.get(item_id)
            if not pi or str(pi.get("register_uuid")) != str(reg["uuid"]):
                raise ValueError(f"项目所有权校验失败: 无法为不属于当前挂号单的药品处方项 {item_id} 缴费")
            if pi.get("drug_state") != "开立":
                raise ValueError(f"重复扣款拦截: 药品处方项 {item_id} 已处于 '{pi.get('drug_state')}' 状态")

            prescription_key = pi.get("prescription_uuid") or str(pi.get("prescription_id"))
            if prescription_key in charged_prescriptions:
                continue

            prescription_items = pharmacy_by_prescription.get(prescription_key, [])
            if not prescription_items:
                raise ValueError(f"处方收费失败：无法加载处方 {prescription_key} 的完整明细")

            for prescription_item in prescription_items:
                if str(prescription_item.get("register_uuid")) != str(reg["uuid"]):
                    raise ValueError(f"项目所有权校验失败: 处方 {prescription_key} 中存在不属于当前挂号单的药品")
                if prescription_item.get("drug_state") != "开立":
                    raise ValueError(
                        "重复扣款拦截: "
                        f"药品处方项 {prescription_item.get('uuid')} 已处于 '{prescription_item.get('drug_state')}' 状态"
                    )

                amount = Decimal(str(prescription_item.get("price", "0.00"))) * prescription_item.get("drug_number", 1)
                total_amount += amount
                detail_records.append({
                    "item_type": item_type,
                    "item_source_id": prescription_item["uuid"],
                    "amount": amount,
                })
            charged_prescriptions.add(prescription_key)
            continue

        total_amount += amount
        detail_records.append({"item_type": item_type, "item_source_id": item_id, "amount": amount})
        
    if total_amount <= 0:
        raise ValueError("账单金额必须大于 0")

    transaction_id = f"WX{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(100000, 999999)}"

    settle_category_uuid_str = data.get("settle_category_uuid")
    if not settle_category_uuid_str:
        zf_settle = await AuthClient.get_settle_category_by_code("ZF")
        if zf_settle and zf_settle.get("uuid"):
            settle_category_uuid_str = zf_settle["uuid"]
            
    settle_category_uuid = uuid_pkg.UUID(str(settle_category_uuid_str)) if settle_category_uuid_str else None

    bill = OutpatientBill(
        register_uuid=uuid_pkg.UUID(str(data["register_uuid"])),
        bill_code=_gen_bill_code(),
        total_amount=total_amount,
        settle_category_uuid=settle_category_uuid,
        pay_method=data.get("pay_method", "微信"),
        transaction_id=transaction_id,
        bill_state=BillState.PAID.value,
    )
    session.add(bill)
    await session.flush()

    await _reserve_bill_items(session, bill, detail_records)

    for d in detail_records:
        detail = OutpatientBillDetail(
            bill_id=bill.id,
            item_type=d["item_type"],
            item_source_id=d["item_source_id"],
            amount=d["amount"],
        )
        session.add(detail)

    # 缴费成功状态联动同步 (发件箱模式，本地原子事务)

    message_payload = {
        "register_uuid": str(data["register_uuid"]),
        "items": [
            {"type": d["item_type"], "id": d["item_source_id"]}
            for d in detail_records
        ]
    }
    
    evt_medical = OutboxEvent(
        topic="billing.payment.success.medical",
        payload=json.dumps(message_payload, ensure_ascii=False)
    )
    evt_pharmacy = OutboxEvent(
        topic="billing.payment.success.pharmacy",
        payload=json.dumps(message_payload, ensure_ascii=False)
    )
    session.add(evt_medical)
    session.add(evt_pharmacy)

    result = {
        "uuid": str(bill.uuid),
        "bill_code": bill.bill_code,
        "total_amount": str(bill.total_amount),
        "transaction_id": bill.transaction_id,
    }
    await complete_idempotency(session, idem, result)

    # 强制提交事务，确保账单、发件箱事件与幂等记录原子落盘
    await session.commit()
    await session.refresh(bill)

    return result

def _split_refund_details(details: list[OutpatientBillDetail]) -> tuple[list[dict], list[str]]:
    medical_items = []
    drug_item_uuids = []
    for detail in details:
        if detail.item_type in ["检查", "检验", "处置"]:
            medical_items.append({"type": detail.item_type, "id": detail.item_source_id})
        elif detail.item_type == "药品":
            drug_item_uuids.append(detail.item_source_id)
        else:
            raise ValueError(f"未知退费项目类型: {detail.item_type}")
    return medical_items, drug_item_uuids


async def _refund_downstream_items(details: list[OutpatientBillDetail]) -> None:
    medical_items, drug_item_uuids = _split_refund_details(details)
    if medical_items:
        await MedicalClient.refund_items(medical_items)
    if drug_item_uuids:
        await PharmacyClient.refund_items(drug_item_uuids)


async def _mark_refund_failed(session: AsyncSession, bill_code: str, idem) -> None:
    stmt = select(OutpatientBill).where(OutpatientBill.bill_code == bill_code).with_for_update()
    result = await session.execute(stmt)
    bill = result.scalar_one_or_none()
    if bill and bill.bill_state != BillState.REFUNDED.value:
        target_state = ensure_bill_transition(bill.bill_state, BillState.REFUND_FAILED)
        bill.bill_state = target_state.value
        session.add(bill)
    await fail_idempotency(session, idem)
    await session.commit()

async def refund_bill(session: AsyncSession, bill_code: str, idempotency_key: str = None) -> dict:
    """
    退费逻辑：先标记退费中，再同步调用下游原子退费接口；
    只有所有下游项目退费成功后，账单才进入已退费。
    """
    idem = await begin_idempotency(
        session,
        scope="billing.refund_bill",
        idempotency_key=idempotency_key,
        request_payload={"bill_code": bill_code},
    )
    if idem and idem.is_replay:
        return idem.response or {}

    # 增加行级悲观锁，防止并发退费
    stmt = select(OutpatientBill).where(OutpatientBill.bill_code == bill_code).with_for_update()
    result = await session.execute(stmt)
    bill = result.scalar_one_or_none()
    
    if not bill:
        raise ValueError("收费单不存在")
        
    if bill.bill_state == BillState.REFUNDED.value:
        raise ValueError("该单据已经是已退费状态，请勿重复操作")
    
    # 查找关联明细，后续同步调用下游原子退费接口
    stmt_detail = select(OutpatientBillDetail).where(OutpatientBillDetail.bill_id == bill.id)
    detail_result = await session.execute(stmt_detail)
    details = detail_result.scalars().all()

    if bill.bill_state != BillState.REFUNDING.value:
        target_state = ensure_bill_transition(bill.bill_state, BillState.REFUNDING)
        bill.bill_state = target_state.value
        session.add(bill)

    await session.commit()

    try:
        await _refund_downstream_items(details)
    except Exception as exc:
        await _mark_refund_failed(session, bill_code, idem)
        raise ValueError(f"退费下游处理失败: {exc}") from exc

    stmt = select(OutpatientBill).where(OutpatientBill.bill_code == bill_code).with_for_update()
    result = await session.execute(stmt)
    bill = result.scalar_one_or_none()
    if not bill:
        raise ValueError("收费单不存在")

    if bill.bill_state != BillState.REFUNDED.value:
        target_state = ensure_bill_transition(bill.bill_state, BillState.REFUNDED)
        bill.bill_state = target_state.value
        session.add(bill)
    
    result = {
        "bill_code": bill.bill_code,
        "bill_state": bill.bill_state,
        "refund_amount": str(bill.total_amount)
    }
    await complete_idempotency(session, idem, result)

    # 因为 FastAPI 的 get_session 通常是在整个请求结束时统一提交，或者调用者自己 flush，这里为了发件箱立刻生效，显式提交
    await session.commit()

    return result


async def get_bills_by_register(session: AsyncSession, register_uuid: uuid_pkg.UUID) -> list[dict]:
    stmt = select(OutpatientBill).where(OutpatientBill.register_uuid == register_uuid)
    result = await session.execute(stmt)
    bills = result.scalars().all()
    return [
        {
            "uuid": str(b.uuid),
            "bill_code": b.bill_code,
            "total_amount": str(b.total_amount),
            "bill_state": b.bill_state,
            "pay_method": b.pay_method,
            "transaction_id": b.transaction_id,
            "fee_status": 0 if b.bill_state in ["未缴费", "待支付"] else 1
        }
        for b in bills
    ]
