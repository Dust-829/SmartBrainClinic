import uuid as uuid_pkg
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.medical import MedicalRecord, CheckRequest, InspectionRequest, DisposalRequest, MedicalTechnology
from .ai_image_inference import analyze_brain_image
from app.common.enums import CheckState, InspectionState, DisposalState
from app.common.ai_embedding import get_embedding
from app.common.clients import PatientClient, AuthClient
from ..models.medical import Disease, MedicalRecordDisease
from sqlalchemy import delete
from datetime import datetime
from app.microservices.medical.config import settings
from .agent.graph import build_and_run_agent
from app.common.enums import VisitState
import json
from ..models.medical import OutboxEvent
from app.microservices.medical.database import session_factory
from sqlalchemy import select


async def create_medical_record(session: AsyncSession, data: dict) -> MedicalRecord:
    reg = await PatientClient.get_register(data["register_uuid"])
    if not reg:
        raise ValueError("挂号记录不存在")
    
    register_uuid = uuid_pkg.UUID(str(data["register_uuid"]))
    
    record = MedicalRecord(
        register_uuid=register_uuid,
        readme=data.get("readme"),
        present=data.get("present"),
        is_doctor_confirmed=False,
        dialog_vector=[0.0] * 1024
    )
    session.add(record)
    await session.flush()
    return record

async def get_tech_by_uuid(session: AsyncSession, tech_uuid: str) -> MedicalTechnology:
    stmt = select(MedicalTechnology).where(MedicalTechnology.uuid == uuid_pkg.UUID(tech_uuid))
    result = await session.execute(stmt)
    return result.scalar_one_or_none()

async def recommend_tech_ai(tech_name: str, available_techs: list[dict]) -> str | None:
    if not available_techs:
        return None
        
    prompt = f"""
    You are an intelligent scheduling assistant for a hospital.
    A patient needs the following medical check/technology performed: "{tech_name}"
    
    Here is a list of available technicians today:
    """
    for tech in available_techs:
        prompt += f"- UUID: {tech['uuid']}, Name: {tech['realname']}, Expertise: {tech.get('expertise', 'None')}, AI Score: {tech.get('ai_eval_score', 0)}\n"
        
    prompt += """
    Based on the required check and the technicians' expertise and scores, select the BEST technician for the job.
    Return ONLY their UUID. If no one seems perfectly matching, pick the one with the highest AI score. Return EXACTLY the UUID string and nothing else.
    """
    
    try:
        import httpx
        payload = {
            "model": settings.LLM_MODEL,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.1,
            "max_tokens": 50
        }
        headers = {
            "Authorization": f"Bearer {settings.LLM_API_KEY}",
            "Content-Type": "application/json"
        }
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{settings.LLM_API_BASE.rstrip('/')}/chat/completions",
                json=payload,
                headers=headers,
                timeout=10.0
            )
            if resp.status_code == 200:
                result = resp.json()["choices"][0]["message"]["content"].strip()
                for tech in available_techs:
                    if tech["uuid"] in result:
                        return tech["uuid"]
        return None
    except Exception as e:
        print(f"AI Tech Recommendation Failed: {e}")
        return None

async def assign_tech_to_check_task(check_uuid: str, tech_name: str):
    
    assigned_uuid = None
    try:
        all_techs = await AuthClient.get_employees_by_dept_type("检查")
        if all_techs:
            all_uuids = [t["uuid"] for t in all_techs]
            today_available_uuids = await PatientClient.get_today_available_employees(all_uuids)
            if today_available_uuids:
                available_techs = [t for t in all_techs if t["uuid"] in today_available_uuids]
                assigned_uuid = await recommend_tech_ai(tech_name, available_techs)
                if not assigned_uuid and available_techs:
                    assigned_uuid = available_techs[0]["uuid"]
    except Exception as e:
        print(f"Error assigning tech: {e}")
        return
        
    if assigned_uuid:
        async with session_factory() as session:
            try:
                stmt = select(CheckRequest).where(CheckRequest.uuid == uuid_pkg.UUID(check_uuid)).with_for_update()
                res = await session.execute(stmt)
                check = res.scalar_one_or_none()
                if check and check.inputcheck_employee_uuid is None:
                    check.inputcheck_employee_uuid = uuid_pkg.UUID(assigned_uuid)
                    session.add(check)
                    await session.commit()
            except Exception as e:
                await session.rollback()
                print(f"Error updating check request tech: {e}")

async def create_check_request(session: AsyncSession, data: dict, background_tasks=None) -> CheckRequest:
    reg = await PatientClient.get_register(data["register_uuid"])
    if not reg:
        raise ValueError("挂号记录不存在")
    
    tech_stmt = select(MedicalTechnology).where(MedicalTechnology.id == data["medical_technology_id"])
    tech_res = await session.execute(tech_stmt)
    tech = tech_res.scalar_one_or_none()
    tech_name = tech.tech_name if tech else "医学检查"
    
    check = CheckRequest(
        register_uuid=uuid_pkg.UUID(str(data["register_uuid"])),
        medical_technology_id=data["medical_technology_id"],
        check_info=data.get("check_info"),
        check_position=data.get("check_position"),
        check_state=CheckState.UNPAID,
        inputcheck_employee_uuid=None
    )
    session.add(check)
    await session.flush()
    
    if background_tasks:
        background_tasks.add_task(assign_tech_to_check_task, str(check.uuid), tech_name)
        
    return check

async def create_inspection_request(session: AsyncSession, data: dict) -> InspectionRequest:
    reg = await PatientClient.get_register(data["register_uuid"])
    if not reg:
        raise ValueError("挂号记录不存在")
    
    inspection = InspectionRequest(
        register_uuid=uuid_pkg.UUID(str(data["register_uuid"])),
        medical_technology_id=data["medical_technology_id"],
        inspection_state=InspectionState.UNPAID,
    )
    session.add(inspection)
    await session.flush()
    return inspection

async def create_disposal_request(session: AsyncSession, data: dict) -> DisposalRequest:
    reg = await PatientClient.get_register(data["register_uuid"])
    if not reg:
        raise ValueError("挂号记录不存在")
    
    disposal = DisposalRequest(
        register_uuid=uuid_pkg.UUID(str(data["register_uuid"])),
        medical_technology_id=data["medical_technology_id"],
        disposal_state=DisposalState.UNPAID,
    )
    session.add(disposal)
    await session.flush()
    return disposal

async def update_check_state(session: AsyncSession, check_uuid: str, state: str) -> CheckRequest:
    stmt = select(CheckRequest).where(CheckRequest.uuid == uuid_pkg.UUID(check_uuid)).with_for_update()
    result = await session.execute(stmt)
    check = result.scalar_one_or_none()
    if check:
        # 状态机防脏写/防篡改：如果已经退费，禁止再被改写为已执行等其他状态
        if check.check_state in (CheckState.REFUNDED, CheckState.REFUNDED.value) and state not in (CheckState.REFUNDED, CheckState.REFUNDED.value):
            raise ValueError(f"当前检查单状态为'{check.check_state}'，禁止流转至'{state}'！")
        check.check_state = state
        session.add(check)
        await session.flush()
    return check

async def update_inspection_state(session: AsyncSession, inspection_uuid: str, state: str) -> InspectionRequest:
    stmt = select(InspectionRequest).where(InspectionRequest.uuid == uuid_pkg.UUID(inspection_uuid)).with_for_update()
    result = await session.execute(stmt)
    inspection = result.scalar_one_or_none()
    if inspection:
        if inspection.inspection_state in (InspectionState.REFUNDED, InspectionState.REFUNDED.value) and state not in (InspectionState.REFUNDED, InspectionState.REFUNDED.value):
            raise ValueError(f"当前检验单状态为'{inspection.inspection_state}'，禁止流转至'{state}'！")
        inspection.inspection_state = state
        session.add(inspection)
        await session.flush()
    return inspection

async def update_disposal_state(session: AsyncSession, disposal_uuid: str, state: str) -> DisposalRequest:
    stmt = select(DisposalRequest).where(DisposalRequest.uuid == uuid_pkg.UUID(disposal_uuid)).with_for_update()
    result = await session.execute(stmt)
    disposal = result.scalar_one_or_none()
    if disposal:
        if disposal.disposal_state in (DisposalState.REFUNDED, DisposalState.REFUNDED.value) and state not in (DisposalState.REFUNDED, DisposalState.REFUNDED.value):
            raise ValueError(f"当前处置单状态为'{disposal.disposal_state}'，禁止流转至'{state}'！")
        disposal.disposal_state = state
        session.add(disposal)
        await session.flush()
    return disposal

async def get_check_request_by_uuid(session: AsyncSession, check_uuid: str) -> CheckRequest:
    result = await session.execute(select(CheckRequest).where(CheckRequest.uuid == uuid_pkg.UUID(check_uuid)))
    return result.scalar_one_or_none()

async def get_inspection_request_by_uuid(session: AsyncSession, inspection_uuid: str) -> InspectionRequest:
    result = await session.execute(select(InspectionRequest).where(InspectionRequest.uuid == uuid_pkg.UUID(inspection_uuid)))
    return result.scalar_one_or_none()

async def get_disposal_request_by_uuid(session: AsyncSession, disposal_uuid: str) -> DisposalRequest:
    result = await session.execute(select(DisposalRequest).where(DisposalRequest.uuid == uuid_pkg.UUID(disposal_uuid)))
    return result.scalar_one_or_none()

async def get_medical_record_draft(session: AsyncSession, register_uuid: uuid_pkg.UUID) -> MedicalRecord:
    reg = await PatientClient.get_register(register_uuid)
    if not reg:
        raise ValueError("挂号记录不存在")
    
    result = await session.execute(select(MedicalRecord).where(MedicalRecord.register_uuid == register_uuid))
    return result.scalar_one_or_none()

async def confirm_medical_record_draft(
    session: AsyncSession, 
    register_uuid: uuid_pkg.UUID, 
    readme: str, 
    present: str, 
    history: str, 
    physique: str, 
    diagnosis: str,
    allergy: str = None,
    proposal: str = None,
    cure: str = None
) -> MedicalRecord:
    """
    医生确认/修改病历草稿，并建立与 ICD-10 疾病字典的关联
    """
    record = await get_medical_record_draft(session, register_uuid)
    if not record:
        raise ValueError("病历草稿不存在")
        
    record.readme = readme
    record.present = present
    record.history = history
    record.physique = physique
    record.diagnosis = diagnosis
    if allergy is not None:
        record.allergy = allergy
    if proposal is not None:
        record.proposal = proposal
    if cure is not None:
        record.cure = cure
    record.is_doctor_confirmed = True
    
    # --- AI: Generate Embedding for the dialog and diagnosis ---
    dialog_text = f"主诉: {present}\n现病史: {history}\n查体: {physique}\n诊断: {diagnosis}"
    record_vec = await get_embedding(dialog_text)
    record.dialog_vector = record_vec
    
    diag_vec = await get_embedding(diagnosis)
    # -----------------------------------------------------------
    
    session.add(record)
    await session.flush()

    # 清除旧的疾病映射记录
    await session.execute(
        delete(MedicalRecordDisease).where(MedicalRecordDisease.medical_record_id == record.id)
    )
    
    # 匹配 ICD-10 疾病字典 (使用 PGVector 的余弦距离进行语义匹配)
    # 取相似度最高（距离最近）的前 3 个疾病
    stmt = select(Disease).where(Disease.delmark == 1, Disease.disease_vector.is_not(None)).order_by(Disease.disease_vector.cosine_distance(diag_vec)).limit(3)
    disease_res = await session.execute(stmt)
    matched_diseases = disease_res.scalars().all()
    
    # 如果数据库中没有带 vector 的疾病，则回退到基础字符串匹配 (防御性逻辑)
    if not matched_diseases:
        from sqlalchemy import or_, func, literal
        normalized_diag = diagnosis.replace("部", "")
        
        conditions = [
            # 数据库列名 包含 用户输入
            Disease.disease_name.ilike(f"%{diagnosis}%"),
            # 用户输入 包含 数据库列名
            literal(diagnosis).ilike(func.concat('%', Disease.disease_name, '%')),
            # 剔除“部”字后的模糊容错匹配
            func.replace(Disease.disease_name, "部", "").ilike(f"%{normalized_diag}%"),
            literal(normalized_diag).ilike(func.concat('%', func.replace(Disease.disease_name, "部", ""), '%'))
        ]
        
        # 特殊恶性肿瘤兜底
        if "脑恶性肿瘤" in normalized_diag:
            conditions.append(Disease.disease_name.ilike("%脑恶性肿瘤%"))
        
        # 将百万级/十万级的 Python 内存循环遍历，下推给底层 PostgreSQL 数据库引擎执行，彻底消除 OOM 内存爆炸隐患
        stmt_fallback = select(Disease).where(
            Disease.delmark == 1,
            or_(*conditions)
        ).limit(3)
        
        fallback_res = await session.execute(stmt_fallback)
        matched_diseases = fallback_res.scalars().all()
            
    # 落库多对多关联表
    for idx, d in enumerate(matched_diseases):
        mapping = MedicalRecordDisease(
            medical_record_id=record.id,
            disease_id=d.id,
            is_primary=(idx == 0)
        )
        session.add(mapping)
        
    
    payload = {
        "register_uuid": str(register_uuid),
        "visit_state": int(VisitState.FINISHED)
    }
    evt = OutboxEvent(
        topic="medical.record.confirmed",
        payload=json.dumps(payload, ensure_ascii=False)
    )
    session.add(evt)
    
    await session.commit()
    await session.refresh(record)
    
    return record
async def input_check_result(
    session: AsyncSession, 
    check_uuid: str, 
    inputcheck_employee_uuid: uuid_pkg.UUID,
    image_path: str = None, 
    check_result: str = None
) -> dict:
    """
    影像科录入检查结果，自动进行 AI 推理并扭转状态
    """
    result = await session.execute(select(CheckRequest).where(CheckRequest.uuid == uuid_pkg.UUID(check_uuid)))
    check = result.scalar_one_or_none()
    if not check:
        raise ValueError("检查单不存在")
        
    if check.check_state != CheckState.PAID:
        raise ValueError(f"当前检查单状态为 '{check.check_state}'，必须为 '{CheckState.PAID.value}' 状态才能执行录入")

    ai_prob = None
    ai_report = ""

    # 如果上传了影像路径，则触发 AI 模型进行诊断分析
    if image_path:
        ai_prob, ai_report = analyze_brain_image(image_path)
        check.image_path = image_path
        check.ai_tumor_prob = ai_prob
        
    # 合并 AI 报告和医生的报告
    final_result = ""
    if ai_report:
        final_result += ai_report + "\n\n"
    if check_result:
        final_result += f"【医生出具的结论】\n{check_result}"
        
    check.check_result = final_result.strip()
    check.check_state = CheckState.EXECUTED
    check.inputcheck_employee_uuid = inputcheck_employee_uuid

    check.check_time = datetime.now()
    
    session.add(check)
    await session.flush()
    
    return {
        "id": check.id,
        "check_state": check.check_state,
        "image_path": check.image_path,
        "ai_tumor_prob": str(check.ai_tumor_prob) if check.ai_tumor_prob is not None else None,
        "check_result": check.check_result
    }

async def search_similar_records(session: AsyncSession, query_text: str, top_k: int = 5) -> List[MedicalRecord]:
    """
    根据给定的病历描述，使用向量搜索找出最相似的历史真实病历
    """

    query_vec = await get_embedding(query_text)
    
    # 使用 PGVector 进行余弦距离搜索 ( <=> 在部分 pgvector 版本是 cosine distance, 或者 <-> 是 L2 distance)
    # 我们这里使用 cosine_distance
    stmt = select(MedicalRecord).where(
        MedicalRecord.dialog_vector.is_not(None),
        MedicalRecord.is_doctor_confirmed == True
    ).order_by(
        MedicalRecord.dialog_vector.cosine_distance(query_vec)
    ).limit(top_k)
    
    result = await session.execute(stmt)
    return result.scalars().all()

async def ai_assistant_query(session: AsyncSession, patient_uuid: str, question: str, employee_uuid: str = None, top_k: int = 5) -> str:
    """
    LangGraph Agent 驱动的医生智能助理。
    
    相比原来的单轮 httpx 调用，现在支持：
    - 多轮循环推理：Agent 可连续调用多个工具后汇总回答
    - 4 种工具能力：相似病历检索、排班申请、候诊队列、排班查询
    - RAG 上下文预注入：当前患者的历史病历自动注入 SystemPrompt
    
    函数签名保持不变，API 层零改动。
    """
    return await build_and_run_agent(session, patient_uuid, question, employee_uuid, top_k)

async def get_requests_batch(session: AsyncSession, check_uuids: list[str], inspection_uuids: list[str], disposal_uuids: list[str]) -> dict:
    ret = {"checks": {}, "inspections": {}, "disposals": {}}
    tech_ids = set()

    if check_uuids:
        c_objs = [uuid_pkg.UUID(u) for u in check_uuids]
        stmt = select(CheckRequest).where(CheckRequest.uuid.in_(c_objs))
        checks = (await session.execute(stmt)).scalars().all()
        for c in checks:
            ret["checks"][str(c.uuid)] = {"state": c.check_state, "tech_id": c.medical_technology_id, "register_uuid": str(c.register_uuid)}
            if c.medical_technology_id:
                tech_ids.add(c.medical_technology_id)
                
    if inspection_uuids:
        i_objs = [uuid_pkg.UUID(u) for u in inspection_uuids]
        stmt = select(InspectionRequest).where(InspectionRequest.uuid.in_(i_objs))
        inspections = (await session.execute(stmt)).scalars().all()
        for i in inspections:
            ret["inspections"][str(i.uuid)] = {"state": i.inspection_state, "tech_id": i.medical_technology_id, "register_uuid": str(i.register_uuid)}
            if i.medical_technology_id:
                tech_ids.add(i.medical_technology_id)
                
    if disposal_uuids:
        d_objs = [uuid_pkg.UUID(u) for u in disposal_uuids]
        stmt = select(DisposalRequest).where(DisposalRequest.uuid.in_(d_objs))
        disposals = (await session.execute(stmt)).scalars().all()
        for d in disposals:
            ret["disposals"][str(d.uuid)] = {"state": d.disposal_state, "tech_id": d.medical_technology_id, "register_uuid": str(d.register_uuid)}
            if d.medical_technology_id:
                tech_ids.add(d.medical_technology_id)

    tech_map = {}
    if tech_ids:
        stmt_tech = select(MedicalTechnology).where(MedicalTechnology.id.in_(list(tech_ids)))
        techs = (await session.execute(stmt_tech)).scalars().all()
        tech_map = {t.id: str(t.price) for t in techs}

    for item_dict in ret.values():
        for item in item_dict.values():
            item["price"] = tech_map.get(item.get("tech_id"), "0.00")
            
    return ret
