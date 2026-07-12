import uuid as uuid_pkg
from datetime import datetime
from decimal import Decimal
from sqlalchemy import func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.drug import DrugInfo, Prescription, PrescriptionItem
from .internal_client import PatientClient, MedicalClient
from .ai_prescription import run_ai_prescription
from app.common.ai_schema import unwrap_ai_data
from app.common.enums import DrugState
from app.common.idempotency import begin_idempotency, complete_idempotency
from app.common.state_machine import ensure_drug_transition, normalize_drug_state

def _gen_prescription_code() -> str:
    now = datetime.now()
    import random
    seq = random.randint(1000, 9999)
    return f"CF{now.strftime('%Y%m%d%H%M%S')}{seq}"


def _serialize_drug_list_item(drug: DrugInfo) -> dict:
    return {
        "uuid": str(drug.uuid),
        "drug_code": drug.drug_code,
        "drug_name": drug.drug_name,
        "specification": drug.specification,
        "unit": drug.unit,
        "price": str(drug.price),
        "stock": drug.stock,
        "min_stock_limit": drug.min_stock_limit,
        "is_low_stock": drug.stock <= (drug.min_stock_limit or 10),
    }


def _prescription_action_flags(drug_state: str) -> tuple[bool, bool, str | None]:
    current_state = normalize_drug_state(drug_state)
    can_dispense = current_state == DrugState.PAID
    can_return = current_state == DrugState.DISPENSED
    primary_action = "dispense" if can_dispense else "return" if can_return else None
    return can_dispense, can_return, primary_action


def _normalize_workbench_state(state: str | None) -> str | None:
    normalized = str(state or "").strip().lower()
    if normalized in {"", "all"}:
        return None
    if normalized == "actionable":
        return "actionable"
    if normalized in {"paid", DrugState.PAID.value.lower()}:
        return DrugState.PAID.value
    if normalized in {"dispensed", DrugState.DISPENSED.value.lower()}:
        return DrugState.DISPENSED.value
    if normalized in {"prescribed", DrugState.PRESCRIBED.value.lower()}:
        return DrugState.PRESCRIBED.value
    if normalized in {"refunded", DrugState.REFUNDED.value.lower()}:
        return DrugState.REFUNDED.value
    raise ValueError("unsupported prescription state filter")


async def _load_prescription_item_counts(session: AsyncSession, prescription_ids: list[int]) -> dict[int, int]:
    if not prescription_ids:
        return {}

    stmt = (
        select(PrescriptionItem.prescription_id, func.count(PrescriptionItem.id))
        .where(PrescriptionItem.prescription_id.in_(prescription_ids))
        .group_by(PrescriptionItem.prescription_id)
    )
    rows = (await session.execute(stmt)).all()
    return {int(prescription_id): int(items_count) for prescription_id, items_count in rows}


async def get_admin_workbench_overview(session: AsyncSession) -> dict:
    paid_prescription_count = int(
        (
            await session.execute(
                select(func.count()).select_from(Prescription).where(Prescription.drug_state == DrugState.PAID.value)
            )
        ).scalar()
        or 0
    )
    dispensed_prescription_count = int(
        (
            await session.execute(
                select(func.count()).select_from(Prescription).where(Prescription.drug_state == DrugState.DISPENSED.value)
            )
        ).scalar()
        or 0
    )
    low_stock_drug_count = int(
        (
            await session.execute(
                select(func.count()).select_from(DrugInfo).where(
                    DrugInfo.delmark == 1,
                    DrugInfo.stock <= func.coalesce(DrugInfo.min_stock_limit, 10),
                )
            )
        ).scalar()
        or 0
    )
    total_drug_count = int(
        (
            await session.execute(select(func.count()).select_from(DrugInfo).where(DrugInfo.delmark == 1))
        ).scalar()
        or 0
    )

    low_stock_drugs_page = await list_admin_workbench_drugs(session, low_stock_only=True, limit=6, offset=0)
    actionable_prescriptions_page = await list_admin_workbench_prescriptions(
        session,
        state="actionable",
        limit=6,
        offset=0,
    )

    return {
        "paid_prescription_count": paid_prescription_count,
        "dispensed_prescription_count": dispensed_prescription_count,
        "low_stock_drug_count": low_stock_drug_count,
        "total_drug_count": total_drug_count,
        "low_stock_drugs": low_stock_drugs_page["items"],
        "actionable_prescriptions": actionable_prescriptions_page["items"],
    }


async def list_admin_workbench_prescriptions(
    session: AsyncSession,
    *,
    state: str | None = None,
    limit: int = 20,
    offset: int = 0,
    prescription_code: str | None = None,
) -> dict:
    limit = max(1, min(int(limit), 100))
    offset = max(0, int(offset))
    normalized_state = _normalize_workbench_state(state)
    normalized_code = " ".join((prescription_code or "").split())

    count_stmt = select(func.count()).select_from(Prescription)
    stmt = select(Prescription)

    if normalized_state == "actionable":
        state_filter = Prescription.drug_state.in_([DrugState.PAID.value, DrugState.DISPENSED.value])
        count_stmt = count_stmt.where(state_filter)
        stmt = stmt.where(state_filter)
    elif normalized_state:
        count_stmt = count_stmt.where(Prescription.drug_state == normalized_state)
        stmt = stmt.where(Prescription.drug_state == normalized_state)

    if normalized_code:
        pattern = f"%{normalized_code}%"
        count_stmt = count_stmt.where(Prescription.prescription_code.ilike(pattern))
        stmt = stmt.where(Prescription.prescription_code.ilike(pattern))

    total = int((await session.execute(count_stmt)).scalar() or 0)
    stmt = stmt.order_by(Prescription.creation_time.desc(), Prescription.id.desc()).offset(offset).limit(limit)
    prescriptions = (await session.execute(stmt)).scalars().all()
    item_counts = await _load_prescription_item_counts(session, [prescription.id for prescription in prescriptions])

    items = []
    for prescription in prescriptions:
        register_context = await PatientClient.get_register(prescription.register_uuid) or {}
        can_dispense, can_return, _ = _prescription_action_flags(prescription.drug_state)
        items.append(
            {
                "uuid": str(prescription.uuid),
                "register_uuid": str(prescription.register_uuid),
                "prescription_code": prescription.prescription_code,
                "creation_time": prescription.creation_time.isoformat() if prescription.creation_time else None,
                "is_ai_recommended": bool(prescription.is_ai_recommended),
                "drug_state": prescription.drug_state,
                "patient_name": register_context.get("patient_name"),
                "patient_case_number": register_context.get("patient_case_number"),
                "employee_name": register_context.get("employee_name"),
                "dept_name": register_context.get("dept_name"),
                "actual_time_range": register_context.get("actual_time_range"),
                "clinic_room_name": register_context.get("clinic_room_name"),
                "items_count": int(item_counts.get(prescription.id, 0)),
                "can_dispense": can_dispense,
                "can_return": can_return,
            }
        )

    return {
        "items": items,
        "pagination": {
            "total": total,
            "limit": limit,
            "offset": offset,
        },
    }


async def get_admin_workbench_prescription_detail(session: AsyncSession, prescription_uuid: str) -> dict:
    stmt = select(Prescription).where(Prescription.uuid == uuid_pkg.UUID(str(prescription_uuid)))
    prescription = (await session.execute(stmt)).scalar_one_or_none()
    if not prescription:
        raise ValueError("prescription not found")

    items_stmt = (
        select(PrescriptionItem)
        .where(PrescriptionItem.prescription_id == prescription.id)
        .order_by(PrescriptionItem.id.asc())
    )
    prescription_items = (await session.execute(items_stmt)).scalars().all()
    register_context = await PatientClient.get_register(prescription.register_uuid) or {}

    items = []
    for item in prescription_items:
        drug = await session.get(DrugInfo, item.drug_id)
        items.append(
            {
                "uuid": str(item.uuid),
                "drug_uuid": str(drug.uuid) if drug else None,
                "drug_code": drug.drug_code if drug else None,
                "drug_name": drug.drug_name if drug else None,
                "specification": drug.specification if drug else None,
                "unit": drug.unit if drug else None,
                "price": str(drug.price) if drug else "0.00",
                "stock": drug.stock if drug else None,
                "min_stock_limit": drug.min_stock_limit if drug else None,
                "drug_usage": item.drug_usage,
                "drug_number": item.drug_number,
            }
        )

    can_dispense, can_return, primary_action = _prescription_action_flags(prescription.drug_state)
    return {
        "header": {
            "uuid": str(prescription.uuid),
            "register_uuid": str(prescription.register_uuid),
            "prescription_code": prescription.prescription_code,
            "creation_time": prescription.creation_time.isoformat() if prescription.creation_time else None,
            "is_ai_recommended": bool(prescription.is_ai_recommended),
            "drug_state": prescription.drug_state,
        },
        "register_context": {
            "patient_name": register_context.get("patient_name"),
            "patient_case_number": register_context.get("patient_case_number"),
            "employee_name": register_context.get("employee_name"),
            "dept_name": register_context.get("dept_name"),
            "actual_time_range": register_context.get("actual_time_range"),
            "clinic_room_name": register_context.get("clinic_room_name"),
            "visit_state_text": register_context.get("visit_state_text"),
        },
        "items": items,
        "actions": {
            "can_dispense": can_dispense,
            "can_return": can_return,
            "primary_action": primary_action,
        },
    }


async def list_admin_workbench_drugs(
    session: AsyncSession,
    *,
    keyword: str | None = None,
    low_stock_only: bool = False,
    limit: int = 20,
    offset: int = 0,
) -> dict:
    limit = max(1, min(int(limit), 100))
    offset = max(0, int(offset))
    normalized_keyword = " ".join((keyword or "").split())

    count_stmt = select(func.count()).select_from(DrugInfo).where(DrugInfo.delmark == 1)
    stmt = select(DrugInfo).where(DrugInfo.delmark == 1)

    if normalized_keyword:
        pattern = f"%{normalized_keyword}%"
        keyword_filter = or_(DrugInfo.drug_code.ilike(pattern), DrugInfo.drug_name.ilike(pattern))
        count_stmt = count_stmt.where(keyword_filter)
        stmt = stmt.where(keyword_filter)

    if low_stock_only:
        low_stock_filter = DrugInfo.stock <= func.coalesce(DrugInfo.min_stock_limit, 10)
        count_stmt = count_stmt.where(low_stock_filter)
        stmt = stmt.where(low_stock_filter)

    total = int((await session.execute(count_stmt)).scalar() or 0)
    stmt = stmt.order_by(DrugInfo.stock.asc(), DrugInfo.id.desc()).offset(offset).limit(limit)
    drugs = (await session.execute(stmt)).scalars().all()
    return {
        "items": [_serialize_drug_list_item(drug) for drug in drugs],
        "pagination": {
            "total": total,
            "limit": limit,
            "offset": offset,
        },
    }


async def adjust_drug_stock(session: AsyncSession, drug_uuid: str, data: dict) -> dict:
    mode = str(data.get("mode") or "").strip().lower()
    if mode not in {"increase", "set"}:
        raise ValueError("unsupported stock adjustment mode")

    try:
        quantity = int(data.get("quantity"))
    except (TypeError, ValueError):
        raise ValueError("quantity must be a positive integer")

    if quantity <= 0:
        raise ValueError("quantity must be a positive integer")

    stmt = select(DrugInfo).where(DrugInfo.uuid == uuid_pkg.UUID(str(drug_uuid))).with_for_update()
    drug = (await session.execute(stmt)).scalar_one_or_none()
    if not drug:
        raise ValueError("药品不存在")

    previous_stock = int(drug.stock or 0)
    if mode == "increase":
        drug.stock = previous_stock + quantity
    else:
        drug.stock = quantity

    session.add(drug)
    await session.flush()
    return {
        "drug_uuid": str(drug.uuid),
        "previous_stock": previous_stock,
        "current_stock": int(drug.stock),
        "mode": mode,
        "quantity": quantity,
    }

async def create_prescription(session: AsyncSession, data: dict) -> dict:
    reg = await PatientClient.get_register(data["register_uuid"])
    if not reg:
        raise ValueError("挂号记录不存在")

    medical_record = await MedicalClient.get_medical_record(data["register_uuid"])
    if not medical_record:
        raise ValueError("未找到该挂号单对应的病历记录，请确保医生已填写并确认病历")
        
    if not medical_record.get("is_doctor_confirmed"):
        raise ValueError("病历尚未确认，无法进行开方。请先确诊（包含诊断编码）后再试。")

    prescription = Prescription(
        register_uuid=uuid_pkg.UUID(str(data["register_uuid"])),
        prescription_code=_gen_prescription_code(),
        drug_state=DrugState.PRESCRIBED,
    )
    session.add(prescription)
    await session.flush()

    total_amount = Decimal("0.00")
    created_items = []
    for item_data in data["items"]:
        drug = await session.get(DrugInfo, item_data["drug_id"])
        if not drug:
            raise ValueError(f"药品ID {item_data['drug_id']} 不存在")

        pi = PrescriptionItem(
            prescription_id=prescription.id,
            drug_id=drug.id,
            drug_usage=item_data["drug_usage"],
            drug_number=item_data["drug_number"],
        )
        session.add(pi)
        await session.flush()
        created_items.append({"uuid": str(pi.uuid)})
        total_amount += drug.price * item_data["drug_number"]

    await session.flush()
    return {
        "uuid": str(prescription.uuid),
        "prescription_code": prescription.prescription_code,
        "total_amount": str(total_amount),
        "items": created_items
    }

async def get_drug_by_uuid(session: AsyncSession, drug_uuid: str) -> DrugInfo:
    stmt = select(DrugInfo).where(DrugInfo.uuid == uuid_pkg.UUID(drug_uuid))
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def list_drugs(
    session: AsyncSession,
    *,
    keyword: str | None = None,
    low_stock_only: bool = False,
    limit: int = 20,
) -> list[dict]:
    limit = max(1, min(limit, 100))
    stmt = select(DrugInfo).where(DrugInfo.delmark == 1)

    normalized_keyword = " ".join((keyword or "").split())
    if normalized_keyword:
        pattern = f"%{normalized_keyword}%"
        stmt = stmt.where(
            or_(
                DrugInfo.drug_code.ilike(pattern),
                DrugInfo.drug_name.ilike(pattern),
            )
        )

    if low_stock_only:
        stmt = stmt.where(DrugInfo.stock <= func.coalesce(DrugInfo.min_stock_limit, 10))

    stmt = stmt.order_by(DrugInfo.stock.asc(), DrugInfo.id.desc()).limit(limit)
    result = await session.execute(stmt)
    drugs = result.scalars().all()
    return [_serialize_drug_list_item(drug) for drug in drugs]


async def list_prescriptions(
    session: AsyncSession,
    *,
    state: str | None = None,
    limit: int = 20,
) -> list[dict]:
    limit = max(1, min(limit, 100))
    stmt = select(Prescription).order_by(Prescription.creation_time.desc(), Prescription.id.desc())
    if state:
        stmt = stmt.where(Prescription.drug_state == state)
    stmt = stmt.limit(limit)

    result = await session.execute(stmt)
    prescriptions = result.scalars().all()
    return [
        {
            "uuid": str(prescription.uuid),
            "register_uuid": str(prescription.register_uuid),
            "prescription_code": prescription.prescription_code,
            "creation_time": prescription.creation_time.isoformat() if prescription.creation_time else None,
            "is_ai_recommended": bool(prescription.is_ai_recommended),
            "drug_state": prescription.drug_state,
        }
        for prescription in prescriptions
    ]

async def update_prescription_state_by_item(session: AsyncSession, item_uuid: str, state: str) -> Prescription:
    result = await session.execute(select(PrescriptionItem).where(PrescriptionItem.uuid == uuid_pkg.UUID(item_uuid)))
    pi = result.scalar_one_or_none()
    if not pi:
        return None
    # 为防并发重复退库，使用 with_for_update() 获取处方锁
    stmt_pres = select(Prescription).where(Prescription.id == pi.prescription_id).with_for_update()
    prescription = (await session.execute(stmt_pres)).scalar_one_or_none()
    if prescription:
        current_state = normalize_drug_state(prescription.drug_state)
        target_state = ensure_drug_transition(current_state, state)
        if target_state == DrugState.REFUNDED:
            raise ValueError("处方退费必须按整张处方批量处理，不能只按单个处方项更新")
        prescription.drug_state = target_state.value
        session.add(prescription)
        await session.flush()
    return prescription

async def get_prescription_item_by_uuid(session: AsyncSession, item_uuid: str) -> dict:
    stmt = select(PrescriptionItem).where(PrescriptionItem.uuid == uuid_pkg.UUID(item_uuid))
    result = await session.execute(stmt)
    pi = result.scalar_one_or_none()
    if not pi:
        return None
    
    prescription = await session.get(Prescription, pi.prescription_id)
    drug = await session.get(DrugInfo, pi.drug_id)
    
    return {
        "uuid": str(pi.uuid),
        "prescription_id": pi.prescription_id,
        "register_uuid": str(prescription.register_uuid) if prescription else None,
        "drug_state": prescription.drug_state if prescription else None,
        "drug_id": pi.drug_id,
        "drug_uuid": str(drug.uuid) if drug else None,
        "drug_number": pi.drug_number
    }

async def dispense_drugs(session: AsyncSession, prescription_uuid: str, idempotency_key: str = None) -> dict:
    """
    药房发药逻辑：校验缴费状态、扣减库存、更新处方状态
    """
    idem = await begin_idempotency(
        session,
        scope="pharmacy.dispense_drugs",
        idempotency_key=idempotency_key,
        request_payload={"prescription_uuid": str(prescription_uuid)},
    )
    if idem and idem.is_replay:
        return idem.response or {}

    # 1. 查找处方单 (使用悲观锁，防止并发发药超扣库存)
    stmt = select(Prescription).where(Prescription.uuid == uuid_pkg.UUID(prescription_uuid)).with_for_update()
    result = await session.execute(stmt)
    prescription = result.scalar_one_or_none()
    
    if not prescription:
        raise ValueError("未找到对应的处方记录")
        
    # 2. 状态校验
    current_state = normalize_drug_state(prescription.drug_state)
    if current_state != DrugState.PAID:
        raise ValueError(f"当前处方状态为 '{prescription.drug_state}'，不满足发药条件（仅限'{DrugState.PAID.value}'）")
    target_state = ensure_drug_transition(current_state, DrugState.DISPENSED)
        
    # 3. 查找所有的处方明细
    stmt_items = select(PrescriptionItem).where(PrescriptionItem.prescription_id == prescription.id)
    items_result = await session.execute(stmt_items)
    items = items_result.scalars().all()
    
    # 按照 drug_id 升序排序，保证高并发下获取行锁的顺序一致，彻底杜绝死锁 (Deadlock)
    items = sorted(items, key=lambda x: x.drug_id)
    
    warnings = []
    # 4. 原子扣减库存并核验警戒线
    for item in items:
        stmt = (
            update(DrugInfo)
            .where(
                DrugInfo.id == item.drug_id,
                DrugInfo.stock >= item.drug_number
            )
            .values(stock=DrugInfo.stock - item.drug_number)
            .returning(DrugInfo)
        )
        res = await session.execute(stmt)
        drug = res.scalar_one_or_none()
        if not drug:
            # Check if drug doesn't exist or stock insufficient
            d = await session.get(DrugInfo, item.drug_id)
            if not d:
                raise ValueError(f"系统中不存在 ID 为 {item.drug_id} 的药品信息")
            else:
                raise ValueError(f"库存不足！【{d.drug_name}】当前库存 {d.stock}，本次需发药 {item.drug_number}")
                
        # 校验最低水位预警
        min_limit = drug.min_stock_limit if drug.min_stock_limit is not None else 10
        if drug.stock < min_limit:
            warning_msg = f"警告：药品【{drug.drug_name}】当前库存仅为 {drug.stock} 件，已低于最低库存警戒线 {min_limit} 件！请尽快补货！"
            warnings.append(warning_msg)
            import logging
            logging.warning(warning_msg)
        
    # 5. 更新单据发药状态
    prescription.drug_state = target_state.value
    session.add(prescription)
    
    await session.flush()
    
    result = {
        "prescription_uuid": str(prescription.uuid),
        "prescription_code": prescription.prescription_code,
        "drug_state": prescription.drug_state,
        "items_count": len(items),
        "stock_warnings": warnings
    }
    await complete_idempotency(session, idem, result)
    return result


async def return_drugs(session: AsyncSession, prescription_uuid: str, idempotency_key: str = None) -> dict:
    """
    退药逻辑：检查状态、恢复库存、扭转状态为已退药
    """
    idem = await begin_idempotency(
        session,
        scope="pharmacy.return_drugs",
        idempotency_key=idempotency_key,
        request_payload={"prescription_uuid": str(prescription_uuid)},
    )
    if idem and idem.is_replay:
        return idem.response or {}

    # 查找处方单 (使用悲观锁，防止并发退药造成多加库存)
    stmt = select(Prescription).where(Prescription.uuid == uuid_pkg.UUID(prescription_uuid)).with_for_update()
    result = await session.execute(stmt)
    prescription = result.scalar_one_or_none()
    
    if not prescription:
        raise ValueError("未找到对应的处方记录")
        
    current_state = normalize_drug_state(prescription.drug_state)
    if current_state != DrugState.DISPENSED:
        raise ValueError(f"当前处方状态为 '{prescription.drug_state}'，未发药无法执行退药！")
    target_state = ensure_drug_transition(current_state, DrugState.REFUNDED)
        
    stmt_items = select(PrescriptionItem).where(PrescriptionItem.prescription_id == prescription.id)
    items_result = await session.execute(stmt_items)
    items = items_result.scalars().all()
    # 3. 原子恢复库存
    for item in items:
        stmt = (
            update(DrugInfo)
            .where(DrugInfo.id == item.drug_id)
            .values(stock=DrugInfo.stock + item.drug_number)
        )
        await session.execute(stmt)
            
    prescription.drug_state = target_state.value
    session.add(prescription)
    await session.flush()
    
    result = {
        "prescription_uuid": str(prescription.uuid),
        "prescription_code": prescription.prescription_code,
        "drug_state": prescription.drug_state,
        "returned_items": len(items)
    }
    await complete_idempotency(session, idem, result)
    return result

async def recommend_prescription(session: AsyncSession, register_uuid: uuid_pkg.UUID) -> dict:
    """
    AI 智能开方推荐：引入 RAG 架构进行向量检索
    """
    # 1. RPC 查询完整电子病历记录
    medical_record = await MedicalClient.get_medical_record(register_uuid)
    if not medical_record:
        raise ValueError("未找到该挂号单对应的病历记录，请确保医生已填写并确认病历")
        
    if not medical_record.get("is_doctor_confirmed"):
        raise ValueError("病历尚未确认，无法进行智能开方推荐。请先确诊（包含诊断编码）后再试。")
        
    # 2. 将病历核心信息转化为高维向量
    from app.common.ai_embedding import get_embedding
    query_text = f"诊断结果: {medical_record.get('diagnosis')}，患者症状: {medical_record.get('present')}，既往史: {medical_record.get('history')}，过敏史: {medical_record.get('allergy')}"
    query_vector = await get_embedding(query_text)
    
    # 3. 基于 pgvector 执行余弦相似度检索 (Cosine Similarity)，只召回最匹配的 Top 20 药品
    if query_vector:
        stmt = (
            select(DrugInfo)
            .where(DrugInfo.delmark == 1, DrugInfo.vector.is_not(None))
            .order_by(DrugInfo.vector.cosine_distance(query_vector))
            .limit(20)
        )
    else:
        # 如果 Embedding 失败降级为最多取前 20 条，避免 OOM
        stmt = select(DrugInfo).where(DrugInfo.delmark == 1).limit(20)
        
    res = await session.execute(stmt)
    drugs = res.scalars().all()
    
    available_drugs = []
    for d in drugs:
        available_drugs.append({
            "id": d.id,
            "uuid": str(d.uuid),
            "drug_code": d.drug_code,
            "drug_name": d.drug_name,
            "specification": d.specification,
            "unit": d.unit,
            "price": float(d.price),
            "stock": d.stock
        })
        
    # 4. 运行 AI 大模型 / 规则阻断推荐引擎
    recommendations_result = await run_ai_prescription(medical_record, available_drugs)
    recommendations = unwrap_ai_data(recommendations_result)
    
    return {
        "register_uuid": str(register_uuid),
        "patient_allergy": medical_record.get("allergy") or "无",
        "diagnosis": medical_record.get("diagnosis") or "未确诊",
        "recommendations": recommendations,
        "ai_result": recommendations_result
    }

async def batch_import_drugs(session: AsyncSession, drugs_input: list[dict]) -> dict:
    """
    批量入库药品，并在入库时自动生成向量以便 RAG 检索
    """
    from app.common.ai_embedding import get_embedding
    
    new_drugs = []
    failures = []
    seen_codes = set()
    existing_codes = set()
    if drugs_input:
        stmt_existing = select(DrugInfo).where(
            DrugInfo.delmark == 1,
            DrugInfo.drug_code.in_([str(item["drug_code"]).strip() for item in drugs_input]),
        )
        existing_rows = (await session.execute(stmt_existing)).scalars().all()
        existing_codes = {row.drug_code for row in existing_rows}
    for item in drugs_input:
        drug_code = str(item["drug_code"]).strip()
        if not drug_code:
            raise ValueError("drug_code is required")
        if drug_code in seen_codes:
            raise ValueError("duplicate drug_code found in request")
        seen_codes.add(drug_code)
        if drug_code in existing_codes:
            failures.append({"drug_code": drug_code, "reason": "drug_code already exists"})
            continue
        d = item
        text_to_embed = f"药品名称: {d['drug_name']}, 规格/适应症: {d['specification']}"
        vector = await get_embedding(text_to_embed)
        
        drug = DrugInfo(
            uuid=uuid_pkg.uuid4(),
            drug_code=drug_code,
            drug_name=str(item["drug_name"]).strip(),
            specification=str(item["specification"]).strip(),
            unit=str(item["unit"]).strip(),
            price=Decimal(str(item["price"])),
            stock=int(item["stock"]),
            min_stock_limit=int(item.get("min_stock_limit", 10)),
            vector=vector
        )
        new_drugs.append(drug)
        
    if new_drugs:
        for drug in new_drugs:
            session.add(drug)
        await session.flush()
    await session.commit()
    
    return {
        "successes": [
            {"uuid": str(d.uuid), "drug_name": d.drug_name, "drug_code": d.drug_code}
            for d in new_drugs
        ],
        "failures": failures,
    }

async def get_prescription_items_batch(session: AsyncSession, item_uuids: list[str]) -> list[dict]:
    if not item_uuids:
        return []
    item_uuid_objs = [uuid_pkg.UUID(u) for u in item_uuids]
    stmt = select(PrescriptionItem).where(PrescriptionItem.uuid.in_(item_uuid_objs))
    result = await session.execute(stmt)
    pis = result.scalars().all()
    
    drug_ids = list(set([pi.drug_id for pi in pis]))
    drugs = {}
    if drug_ids:
        stmt_drugs = select(DrugInfo).where(DrugInfo.id.in_(drug_ids))
        result_drugs = await session.execute(stmt_drugs)
        drugs = {d.id: d for d in result_drugs.scalars().all()}
    
    pres_ids = list(set([pi.prescription_id for pi in pis]))
    prescriptions = {}
    if pres_ids:
        stmt_pres = select(Prescription).where(Prescription.id.in_(pres_ids))
        result_pres = await session.execute(stmt_pres)
        prescriptions = {p.id: p for p in result_pres.scalars().all()}

    ret = []
    for pi in pis:
        pres = prescriptions.get(pi.prescription_id)
        drug = drugs.get(pi.drug_id)
        ret.append({
            "uuid": str(pi.uuid),
            "register_uuid": str(pres.register_uuid) if pres else None,
            "drug_state": pres.drug_state if pres else None,
            "drug_uuid": str(drug.uuid) if drug else None,
            "drug_number": pi.drug_number,
            "price": str(drug.price) if drug else "0.00"
        })
    return ret


async def get_prescription_items_for_billing(session: AsyncSession, item_uuids: list[str]) -> list[dict]:
    if not item_uuids:
        return []

    requested_uuid_objs = [uuid_pkg.UUID(u) for u in item_uuids]
    stmt_requested = select(PrescriptionItem).where(PrescriptionItem.uuid.in_(requested_uuid_objs))
    requested_result = await session.execute(stmt_requested)
    requested_items = requested_result.scalars().all()
    prescription_ids = sorted({item.prescription_id for item in requested_items})
    if not prescription_ids:
        return []

    stmt_items = (
        select(PrescriptionItem)
        .where(PrescriptionItem.prescription_id.in_(prescription_ids))
        .order_by(PrescriptionItem.prescription_id, PrescriptionItem.id)
    )
    result = await session.execute(stmt_items)
    items = result.scalars().all()

    drug_ids = sorted({item.drug_id for item in items})
    drugs = {}
    if drug_ids:
        stmt_drugs = select(DrugInfo).where(DrugInfo.id.in_(drug_ids))
        result_drugs = await session.execute(stmt_drugs)
        drugs = {drug.id: drug for drug in result_drugs.scalars().all()}

    stmt_prescriptions = select(Prescription).where(Prescription.id.in_(prescription_ids))
    result_prescriptions = await session.execute(stmt_prescriptions)
    prescriptions = {prescription.id: prescription for prescription in result_prescriptions.scalars().all()}
    requested_set = {str(item_uuid) for item_uuid in requested_uuid_objs}

    return [
        _prescription_item_payload(
            item,
            prescriptions.get(item.prescription_id),
            drugs.get(item.drug_id),
            requested=str(item.uuid) in requested_set,
        )
        for item in items
    ]


async def refund_prescription_items(session: AsyncSession, item_uuids: list[str]) -> dict:
    if not item_uuids:
        return {"refunded_items": [], "refunded_prescriptions": []}

    requested_uuid_objs = sorted({uuid_pkg.UUID(str(item_uuid)) for item_uuid in item_uuids})
    stmt_requested = select(PrescriptionItem).where(PrescriptionItem.uuid.in_(requested_uuid_objs))
    requested_items = list((await session.execute(stmt_requested)).scalars().all())
    requested_by_uuid = {item.uuid: item for item in requested_items}
    missing = [str(item_uuid) for item_uuid in requested_uuid_objs if item_uuid not in requested_by_uuid]
    if missing:
        raise ValueError(f"退费失败：未找到处方项 {', '.join(missing)}")

    prescription_ids = sorted({item.prescription_id for item in requested_items})
    stmt_prescriptions = (
        select(Prescription)
        .where(Prescription.id.in_(prescription_ids))
        .order_by(Prescription.id)
        .with_for_update()
    )
    prescriptions = list((await session.execute(stmt_prescriptions)).scalars().all())
    prescriptions_by_id = {prescription.id: prescription for prescription in prescriptions}

    stmt_all_items = (
        select(PrescriptionItem)
        .where(PrescriptionItem.prescription_id.in_(prescription_ids))
        .order_by(PrescriptionItem.prescription_id, PrescriptionItem.drug_id, PrescriptionItem.id)
    )
    all_items = list((await session.execute(stmt_all_items)).scalars().all())
    items_by_prescription: dict[int, list[PrescriptionItem]] = {}
    for item in all_items:
        items_by_prescription.setdefault(item.prescription_id, []).append(item)

    requested_set = set(requested_uuid_objs)
    for prescription_id, items in items_by_prescription.items():
        full_set = {item.uuid for item in items}
        if not full_set.issubset(requested_set):
            prescription = prescriptions_by_id.get(prescription_id)
            raise ValueError(
                "处方退费必须包含整张处方所有项目: "
                f"{prescription.prescription_code if prescription else prescription_id}"
            )

    refunded_items = []
    refunded_prescriptions = []
    for prescription in prescriptions:
        current_state = normalize_drug_state(prescription.drug_state)
        target_state = ensure_drug_transition(current_state, DrugState.REFUNDED)
        if target_state == DrugState.REFUNDED and current_state == DrugState.DISPENSED:
            for item in items_by_prescription.get(prescription.id, []):
                stmt = update(DrugInfo).where(DrugInfo.id == item.drug_id).values(
                    stock=DrugInfo.stock + item.drug_number
                )
                await session.execute(stmt)

        prescription.drug_state = target_state.value
        session.add(prescription)
        refunded_prescriptions.append({
            "uuid": str(prescription.uuid),
            "prescription_code": prescription.prescription_code,
            "drug_state": prescription.drug_state,
        })
        for item in items_by_prescription.get(prescription.id, []):
            refunded_items.append({"type": "药品", "id": str(item.uuid), "state": prescription.drug_state})

    await session.flush()
    return {"refunded_items": refunded_items, "refunded_prescriptions": refunded_prescriptions}


def _prescription_item_payload(
    item: PrescriptionItem,
    prescription: Prescription | None,
    drug: DrugInfo | None,
    *,
    requested: bool = False,
) -> dict:
    return {
        "uuid": str(item.uuid),
        "prescription_id": item.prescription_id,
        "prescription_uuid": str(prescription.uuid) if prescription else None,
        "register_uuid": str(prescription.register_uuid) if prescription else None,
        "drug_state": prescription.drug_state if prescription else None,
        "drug_id": item.drug_id,
        "drug_uuid": str(drug.uuid) if drug else None,
        "drug_number": item.drug_number,
        "price": str(drug.price) if drug else "0.00",
        "requested": requested,
    }
