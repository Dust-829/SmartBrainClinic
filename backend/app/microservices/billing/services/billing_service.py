from datetime import datetime
from decimal import Decimal
import random
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.bill import OutpatientBill, OutpatientBillDetail
from .internal_client import PatientClient, MedicalClient, PharmacyClient
import uuid as uuid_pkg
from app.common.clients import AuthClient
import json
from ..models.bill import OutboxEvent
from sqlalchemy import select
from app.common.enums import VisitState

def _gen_bill_code() -> str:
    now = datetime.now()
    import random
    seq = random.randint(1000, 9999)
    return f"FP{now.strftime('%Y%m%d%H%M%S')}{seq}"

async def create_bill(session: AsyncSession, data: dict) -> dict:
    
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
    import asyncio
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
        PharmacyClient.get_prescription_items_batch(drug_uuids)
    )
    
    pharmacy_dict = {pi["uuid"]: pi for pi in pharmacy_data} if pharmacy_data else {}

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
                
            amount = Decimal(str(pi.get("price", "0.00"))) * pi.get("drug_number", 1)

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
        bill_state="已收费",
    )
    session.add(bill)
    await session.flush()

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

    # 强制提交事务，确保账单与发件箱事件原子落盘
    await session.commit()
    await session.refresh(bill)

    return {
        "uuid": str(bill.uuid),
        "bill_code": bill.bill_code,
        "total_amount": str(bill.total_amount),
        "transaction_id": bill.transaction_id,
    }

async def refund_bill(session: AsyncSession, bill_code: str) -> dict:
    """
    退费逻辑：变更为已退费，并通过 MQ 通知医疗和药房取消相关单据执行
    """
    # 增加行级悲观锁，防止并发退费
    stmt = select(OutpatientBill).where(OutpatientBill.bill_code == bill_code).with_for_update()
    result = await session.execute(stmt)
    bill = result.scalar_one_or_none()
    
    if not bill:
        raise ValueError("收费单不存在")
        
    if bill.bill_state == "已退费":
        raise ValueError("该单据已经是已退费状态，请勿重复操作")
        
    bill.bill_state = "已退费"
    session.add(bill)
    
    # 查找关联的明细，准备 MQ 消息
    stmt_detail = select(OutpatientBillDetail).where(OutpatientBillDetail.bill_id == bill.id)
    detail_result = await session.execute(stmt_detail)
    details = detail_result.scalars().all()
    
    await session.flush()
    
    # 发件箱模式投递退费成功事件
    message_payload = {
        "bill_code": bill.bill_code,
        "items": [
            {"type": d.item_type, "id": d.item_source_id}
            for d in details
        ]
    }
    
    evt_medical = OutboxEvent(
        topic="billing.refund.success.medical",
        payload=json.dumps(message_payload, ensure_ascii=False)
    )
    evt_pharmacy = OutboxEvent(
        topic="billing.refund.success.pharmacy",
        payload=json.dumps(message_payload, ensure_ascii=False)
    )
    session.add(evt_medical)
    session.add(evt_pharmacy)
    
    # 因为 FastAPI 的 get_session 通常是在整个请求结束时统一提交，或者调用者自己 flush，这里为了发件箱立刻生效，显式提交
    await session.commit()
        
    return {
        "bill_code": bill.bill_code,
        "bill_state": bill.bill_state,
        "refund_amount": str(bill.total_amount)
    }


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
