import uuid as uuid_pkg
from datetime import datetime
from decimal import Decimal
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.drug import DrugInfo, Prescription, PrescriptionItem
from .internal_client import PatientClient, MedicalClient
from .ai_prescription import run_ai_prescription
from app.common.ai_schema import unwrap_ai_data
from app.common.enums import DrugState

def _gen_prescription_code() -> str:
    now = datetime.now()
    import random
    seq = random.randint(1000, 9999)
    return f"CF{now.strftime('%Y%m%d%H%M%S')}{seq}"

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

async def update_prescription_state_by_item(session: AsyncSession, item_uuid: str, state: str) -> Prescription:
    result = await session.execute(select(PrescriptionItem).where(PrescriptionItem.uuid == uuid_pkg.UUID(item_uuid)))
    pi = result.scalar_one_or_none()
    if not pi:
        return None
    # 为防并发重复退库，使用 with_for_update() 获取处方锁
    stmt_pres = select(Prescription).where(Prescription.id == pi.prescription_id).with_for_update()
    prescription = (await session.execute(stmt_pres)).scalar_one_or_none()
    if prescription:
        # [修复退费不退库] 如果是从“已发药”状态退费，说明库存已被扣减，必须加回来
        if state == "已退费" and prescription.drug_state == DrugState.DISPENSED:
            stmt = update(DrugInfo).where(DrugInfo.id == pi.drug_id).values(stock=DrugInfo.stock + pi.drug_number)
            await session.execute(stmt)
            
        prescription.drug_state = state
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

async def dispense_drugs(session: AsyncSession, prescription_uuid: str) -> dict:
    """
    药房发药逻辑：校验缴费状态、扣减库存、更新处方状态
    """
    # 1. 查找处方单 (使用悲观锁，防止并发发药超扣库存)
    stmt = select(Prescription).where(Prescription.uuid == uuid_pkg.UUID(prescription_uuid)).with_for_update()
    result = await session.execute(stmt)
    prescription = result.scalar_one_or_none()
    
    if not prescription:
        raise ValueError("未找到对应的处方记录")
        
    # 2. 状态校验
    if prescription.drug_state != DrugState.PAID:
        raise ValueError(f"当前处方状态为 '{prescription.drug_state}'，不满足发药条件（仅限'{DrugState.PAID.value}'）")
        
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
    prescription.drug_state = DrugState.DISPENSED
    session.add(prescription)
    
    await session.flush()
    
    return {
        "prescription_uuid": str(prescription.uuid),
        "prescription_code": prescription.prescription_code,
        "drug_state": prescription.drug_state,
        "items_count": len(items),
        "stock_warnings": warnings
    }


async def return_drugs(session: AsyncSession, prescription_uuid: str) -> dict:
    """
    退药逻辑：检查状态、恢复库存、扭转状态为已退药
    """
    # 查找处方单 (使用悲观锁，防止并发退药造成多加库存)
    stmt = select(Prescription).where(Prescription.uuid == uuid_pkg.UUID(prescription_uuid)).with_for_update()
    result = await session.execute(stmt)
    prescription = result.scalar_one_or_none()
    
    if not prescription:
        raise ValueError("未找到对应的处方记录")
        
    if prescription.drug_state != DrugState.DISPENSED:
        raise ValueError(f"当前处方状态为 '{prescription.drug_state}'，未发药无法执行退药！")
        
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
            
    prescription.drug_state = DrugState.REFUNDED
    session.add(prescription)
    await session.flush()
    
    return {
        "prescription_uuid": str(prescription.uuid),
        "prescription_code": prescription.prescription_code,
        "drug_state": prescription.drug_state,
        "returned_items": len(items)
    }

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

async def batch_import_drugs(session: AsyncSession, drugs_input: list[dict]) -> list[dict]:
    """
    批量入库药品，并在入库时自动生成向量以便 RAG 检索
    """
    from app.common.ai_embedding import get_embedding
    
    new_drugs = []
    for d in drugs_input:
        text_to_embed = f"药品名称: {d['drug_name']}, 规格/适应症: {d['specification']}"
        vector = await get_embedding(text_to_embed)
        
        drug = DrugInfo(
            uuid=uuid_pkg.uuid4(),
            drug_code=d["drug_code"],
            drug_name=d["drug_name"],
            specification=d["specification"],
            unit=d["unit"],
            price=Decimal(str(d["price"])),
            stock=d["stock"],
            min_stock_limit=d.get("min_stock_limit", 10),
            vector=vector
        )
        new_drugs.append(drug)
        
    session.add_all(new_drugs)
    await session.commit()
    
    return [
        {"uuid": str(d.uuid), "drug_name": d.drug_name, "drug_code": d.drug_code}
        for d in new_drugs
    ]

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
