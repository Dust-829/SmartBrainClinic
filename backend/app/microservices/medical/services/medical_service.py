import uuid as uuid_pkg
from dataclasses import dataclass
from typing import Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.medical import MedicalRecord, CheckRequest, InspectionRequest, DisposalRequest, MedicalTechnology
from .ai_image_inference import analyze_brain_image
from app.common.enums import CheckState, InspectionState, DisposalState
from app.common.ai_client import AIClient
from app.common.ai_embedding import get_embedding
from app.common.clients import PatientClient, AuthClient
from app.common.state_machine import (
    ensure_check_transition,
    ensure_disposal_transition,
    ensure_inspection_transition,
    normalize_check_state,
    normalize_disposal_state,
    normalize_inspection_state,
)
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

MIN_SIMILAR_CASE_SCORE = 35.0


def _normalize_visit_state_value(state: Any) -> int | None:
    try:
        return int(state)
    except (TypeError, ValueError):
        return None


async def _ensure_register_allows_medical_order(register_uuid: uuid_pkg.UUID) -> dict:
    reg = await PatientClient.get_register(register_uuid)
    if not reg:
        raise ValueError("挂号记录不存在")

    visit_state = _normalize_visit_state_value(reg.get("visit_state"))
    if visit_state in (int(VisitState.UNPAID), int(VisitState.CANCELLED)):
        state_map = {
            int(VisitState.UNPAID): "待支付",
            int(VisitState.REGISTERED): "已挂号",
            int(VisitState.RECEPTION): "接诊中",
            int(VisitState.FINISHED): "已结束",
            int(VisitState.CANCELLED): "已退号",
        }
        raise ValueError(f"挂号单当前状态为 '{state_map.get(visit_state, '未知')}'，无法开立医技项目")
    return reg


@dataclass(frozen=True)
class SimilarRecordMatch:
    record: MedicalRecord
    similarity_score: float
    cosine_distance: float


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


async def list_medical_technologies(
    session: AsyncSession,
    tech_type: str | None = None,
) -> list[MedicalTechnology]:
    stmt = select(MedicalTechnology).where(MedicalTechnology.delmark == 1)
    if tech_type:
        stmt = stmt.where(MedicalTechnology.tech_type == tech_type)
    stmt = stmt.order_by(MedicalTechnology.id.asc())
    result = await session.execute(stmt)
    return list(result.scalars().all())

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
        result = await AIClient(
            api_key=settings.LLM_API_KEY,
            api_base=settings.LLM_API_BASE,
        ).chat_completion(
            model=settings.LLM_MODEL,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.1,
            max_tokens=50,
            timeout=10.0,
        )
        if result:
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
    await _ensure_register_allows_medical_order(data["register_uuid"])
    
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
    await _ensure_register_allows_medical_order(data["register_uuid"])
    
    inspection = InspectionRequest(
        register_uuid=uuid_pkg.UUID(str(data["register_uuid"])),
        medical_technology_id=data["medical_technology_id"],
        inspection_state=InspectionState.UNPAID,
    )
    session.add(inspection)
    await session.flush()
    return inspection

async def create_disposal_request(session: AsyncSession, data: dict) -> DisposalRequest:
    await _ensure_register_allows_medical_order(data["register_uuid"])
    
    disposal = DisposalRequest(
        register_uuid=uuid_pkg.UUID(str(data["register_uuid"])),
        medical_technology_id=data["medical_technology_id"],
        disposal_state=DisposalState.UNPAID,
    )
    session.add(disposal)
    await session.flush()
    return disposal



async def create_signed_orders(
    session: AsyncSession,
    register_uuid: uuid_pkg.UUID | str,
    items: list[dict],
    background_tasks=None,
) -> list[dict]:
    """Create a mixed order set in one local transaction before downstream dispatch."""
    if not items:
        raise ValueError("至少需要开立一项医疗项目")

    normalized_register_uuid = uuid_pkg.UUID(str(register_uuid))
    await _ensure_register_allows_medical_order(normalized_register_uuid)

    order_types = {"check", "inspection", "disposal"}
    tech_ids = {item.get("medical_technology_id") for item in items}
    if not all(isinstance(tech_id, int) and tech_id > 0 for tech_id in tech_ids):
        raise ValueError("医疗项目不合法")

    for item in items:
        if item.get("type") not in order_types:
            raise ValueError("医疗项目类型不支持")
        if item["type"] == "check":
            if not str(item.get("check_position") or "").strip():
                raise ValueError("检查项目需要填写检查部位")
            if not str(item.get("check_info") or "").strip():
                raise ValueError("检查项目需要填写检查目的")

    tech_result = await session.execute(
        select(MedicalTechnology).where(
            MedicalTechnology.id.in_(tech_ids),
            MedicalTechnology.delmark == 1,
        )
    )
    tech_map = {tech.id: tech for tech in tech_result.scalars().all()}
    if len(tech_map) != len(tech_ids):
        raise ValueError("存在不可用的医疗项目")

    for item in items:
        tech = tech_map[item["medical_technology_id"]]
        if tech.tech_type != item["type"]:
            raise ValueError(f"医疗项目“{tech.tech_name}”与开单类型不匹配")

    created_items: list[tuple[str, CheckRequest | InspectionRequest | DisposalRequest, MedicalTechnology]] = []
    try:
        for item in items:
            item_type = item["type"]
            tech = tech_map[item["medical_technology_id"]]
            if item_type == "check":
                request_obj = CheckRequest(
                    register_uuid=normalized_register_uuid,
                    medical_technology_id=tech.id,
                    check_info=item["check_info"].strip(),
                    check_position=item["check_position"].strip(),
                    check_state=CheckState.UNPAID,
                    inputcheck_employee_uuid=None,
                )
            elif item_type == "inspection":
                request_obj = InspectionRequest(
                    register_uuid=normalized_register_uuid,
                    medical_technology_id=tech.id,
                    inspection_state=InspectionState.UNPAID,
                )
            else:
                request_obj = DisposalRequest(
                    register_uuid=normalized_register_uuid,
                    medical_technology_id=tech.id,
                    disposal_state=DisposalState.UNPAID,
                )
            session.add(request_obj)
            created_items.append((item_type, request_obj, tech))

        await session.flush()
    except Exception:
        await session.rollback()
        raise

    if background_tasks:
        for item_type, request_obj, tech in created_items:
            if item_type == "check":
                background_tasks.add_task(assign_tech_to_check_task, str(request_obj.uuid), tech.tech_name)

    return [
        {
            "uuid": str(request_obj.uuid),
            "type": item_type,
            "state": (
                request_obj.check_state
                if item_type == "check"
                else request_obj.inspection_state
                if item_type == "inspection"
                else request_obj.disposal_state
            ),
        }
        for item_type, request_obj, _ in created_items
    ]


async def _load_tech_map(session: AsyncSession, tech_ids: set[int]) -> dict[int, MedicalTechnology]:
    if not tech_ids:
        return {}

    stmt = select(MedicalTechnology).where(MedicalTechnology.id.in_(list(tech_ids)))
    techs = (await session.execute(stmt)).scalars().all()
    return {tech.id: tech for tech in techs}


def _serialize_medical_request_item(
    item_type: str,
    request_obj: CheckRequest | InspectionRequest | DisposalRequest,
    tech: MedicalTechnology | None,
) -> dict:
    base = {
        "uuid": str(request_obj.uuid),
        "register_uuid": str(request_obj.register_uuid),
        "item_type": item_type,
        "state": (
            request_obj.check_state
            if item_type == "check"
            else request_obj.inspection_state
            if item_type == "inspection"
            else request_obj.disposal_state
        ),
        "medical_technology_id": request_obj.medical_technology_id,
        "medical_technology_uuid": str(tech.uuid) if tech else None,
        "tech_code": tech.tech_code if tech else None,
        "tech_name": tech.tech_name if tech else None,
        "tech_type": tech.tech_type if tech else None,
        "price": str(tech.price) if tech else "0.00",
        "creation_time": request_obj.creation_time.isoformat() if request_obj.creation_time else None,
    }

    if item_type == "check":
        base["check_info"] = request_obj.check_info
        base["check_position"] = request_obj.check_position
        base["result"] = request_obj.check_result
    elif item_type == "inspection":
        base["result"] = request_obj.test_results
    else:
        base["result"] = request_obj.disposal_result

    return base


async def list_requests_by_register(session: AsyncSession, register_uuid: uuid_pkg.UUID | str) -> dict:
    register_uuid_obj = uuid_pkg.UUID(str(register_uuid))

    check_stmt = (
        select(CheckRequest)
        .where(CheckRequest.register_uuid == register_uuid_obj)
        .order_by(CheckRequest.creation_time.desc(), CheckRequest.id.desc())
    )
    inspection_stmt = (
        select(InspectionRequest)
        .where(InspectionRequest.register_uuid == register_uuid_obj)
        .order_by(InspectionRequest.creation_time.desc(), InspectionRequest.id.desc())
    )
    disposal_stmt = (
        select(DisposalRequest)
        .where(DisposalRequest.register_uuid == register_uuid_obj)
        .order_by(DisposalRequest.creation_time.desc(), DisposalRequest.id.desc())
    )

    checks = list((await session.execute(check_stmt)).scalars().all())
    inspections = list((await session.execute(inspection_stmt)).scalars().all())
    disposals = list((await session.execute(disposal_stmt)).scalars().all())

    tech_ids = {
        request_obj.medical_technology_id
        for request_obj in [*checks, *inspections, *disposals]
        if request_obj.medical_technology_id
    }
    tech_map = await _load_tech_map(session, tech_ids)

    return {
        "checks": [
            _serialize_medical_request_item("check", item, tech_map.get(item.medical_technology_id))
            for item in checks
        ],
        "inspections": [
            _serialize_medical_request_item("inspection", item, tech_map.get(item.medical_technology_id))
            for item in inspections
        ],
        "disposals": [
            _serialize_medical_request_item("disposal", item, tech_map.get(item.medical_technology_id))
            for item in disposals
        ],
    }

async def update_check_state(session: AsyncSession, check_uuid: str, state: str) -> CheckRequest:
    stmt = select(CheckRequest).where(CheckRequest.uuid == uuid_pkg.UUID(check_uuid)).with_for_update()
    result = await session.execute(stmt)
    check = result.scalar_one_or_none()
    if check:
        target_state = ensure_check_transition(check.check_state, state)
        check.check_state = target_state.value
        session.add(check)
        await session.flush()
    return check

async def update_inspection_state(session: AsyncSession, inspection_uuid: str, state: str) -> InspectionRequest:
    stmt = select(InspectionRequest).where(InspectionRequest.uuid == uuid_pkg.UUID(inspection_uuid)).with_for_update()
    result = await session.execute(stmt)
    inspection = result.scalar_one_or_none()
    if inspection:
        target_state = ensure_inspection_transition(inspection.inspection_state, state)
        inspection.inspection_state = target_state.value
        session.add(inspection)
        await session.flush()
    return inspection

async def update_disposal_state(session: AsyncSession, disposal_uuid: str, state: str) -> DisposalRequest:
    stmt = select(DisposalRequest).where(DisposalRequest.uuid == uuid_pkg.UUID(disposal_uuid)).with_for_update()
    result = await session.execute(stmt)
    disposal = result.scalar_one_or_none()
    if disposal:
        target_state = ensure_disposal_transition(disposal.disposal_state, state)
        disposal.disposal_state = target_state.value
        session.add(disposal)
        await session.flush()
    return disposal


async def refund_items(session: AsyncSession, items: list[dict]) -> dict:
    check_uuids, inspection_uuids, disposal_uuids = [], [], []

    for item in items:
        item_type = item.get("type")
        item_id = item.get("id")
        if item_type == "检查":
            check_uuids.append(item_id)
        elif item_type == "检验":
            inspection_uuids.append(item_id)
        elif item_type == "处置":
            disposal_uuids.append(item_id)
        else:
            raise ValueError(f"不支持的医技退费项目类型: {item_type}")

    refunded_items = []
    refunded_items.extend(
        await _refund_medical_rows(
            session,
            CheckRequest,
            CheckRequest.check_state,
            check_uuids,
            CheckState.REFUNDED,
            ensure_check_transition,
            "检查",
        )
    )
    refunded_items.extend(
        await _refund_medical_rows(
            session,
            InspectionRequest,
            InspectionRequest.inspection_state,
            inspection_uuids,
            InspectionState.REFUNDED,
            ensure_inspection_transition,
            "检验",
        )
    )
    refunded_items.extend(
        await _refund_medical_rows(
            session,
            DisposalRequest,
            DisposalRequest.disposal_state,
            disposal_uuids,
            DisposalState.REFUNDED,
            ensure_disposal_transition,
            "处置",
        )
    )
    await session.flush()
    return {"refunded_items": refunded_items}


async def _refund_medical_rows(
    session: AsyncSession,
    model,
    state_column,
    item_uuids: list[str],
    target_state,
    ensure_transition,
    item_type: str,
) -> list[dict]:
    if not item_uuids:
        return []

    uuid_objs = sorted({uuid_pkg.UUID(str(item_uuid)) for item_uuid in item_uuids})
    stmt = (
        select(model)
        .where(model.uuid.in_(uuid_objs))
        .order_by(model.uuid)
        .with_for_update()
    )
    rows = list((await session.execute(stmt)).scalars().all())
    rows_by_uuid = {row.uuid: row for row in rows}
    missing = [str(item_uuid) for item_uuid in uuid_objs if item_uuid not in rows_by_uuid]
    if missing:
        raise ValueError(f"退费失败：未找到{item_type}项目 {', '.join(missing)}")

    refunded = []
    for row in rows:
        current_state = getattr(row, state_column.key)
        new_state = ensure_transition(current_state, target_state)
        setattr(row, state_column.key, new_state.value)
        session.add(row)
        refunded.append({"type": item_type, "id": str(row.uuid), "state": new_state.value})
    return refunded


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
    matched_diseases = []
    if diag_vec:
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
    stmt = select(CheckRequest).where(CheckRequest.uuid == uuid_pkg.UUID(check_uuid)).with_for_update()
    result = await session.execute(stmt)
    check = result.scalar_one_or_none()
    if not check:
        raise ValueError("检查单不存在")
        
    if normalize_check_state(check.check_state) != CheckState.PAID:
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
    target_state = ensure_check_transition(check.check_state, CheckState.EXECUTED)
    check.check_state = target_state.value
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


async def input_inspection_result(
    session: AsyncSession,
    inspection_uuid: str,
    input_employee_uuid: uuid_pkg.UUID,
    test_results: Any = None,
) -> dict:
    stmt = select(InspectionRequest).where(InspectionRequest.uuid == uuid_pkg.UUID(inspection_uuid)).with_for_update()
    result = await session.execute(stmt)
    inspection = result.scalar_one_or_none()
    if not inspection:
        raise ValueError("检验单不存在")

    if normalize_inspection_state(inspection.inspection_state) != InspectionState.PAID:
        raise ValueError(
            f"当前检验单状态为 '{inspection.inspection_state}'，必须为 '{InspectionState.PAID.value}' 状态才能执行录入"
        )

    inspection.test_results = test_results
    inspection.input_employee_uuid = input_employee_uuid
    inspection.inspection_time = datetime.now()
    target_state = ensure_inspection_transition(inspection.inspection_state, InspectionState.EXECUTED)
    inspection.inspection_state = target_state.value
    session.add(inspection)
    await session.flush()

    return {
        "id": inspection.id,
        "inspection_state": inspection.inspection_state,
        "test_results": inspection.test_results,
        "input_employee_uuid": str(inspection.input_employee_uuid) if inspection.input_employee_uuid else None,
    }


async def input_disposal_result(
    session: AsyncSession,
    disposal_uuid: str,
    disposal_result: str = None,
) -> dict:
    stmt = select(DisposalRequest).where(DisposalRequest.uuid == uuid_pkg.UUID(disposal_uuid)).with_for_update()
    result = await session.execute(stmt)
    disposal = result.scalar_one_or_none()
    if not disposal:
        raise ValueError("处置单不存在")

    if normalize_disposal_state(disposal.disposal_state) != DisposalState.PAID:
        raise ValueError(
            f"当前处置单状态为 '{disposal.disposal_state}'，必须为 '{DisposalState.PAID.value}' 状态才能执行录入"
        )

    disposal.disposal_result = disposal_result
    disposal.disposal_time = datetime.now()
    target_state = ensure_disposal_transition(disposal.disposal_state, DisposalState.EXECUTED)
    disposal.disposal_state = target_state.value
    session.add(disposal)
    await session.flush()

    return {
        "id": disposal.id,
        "disposal_state": disposal.disposal_state,
        "disposal_result": disposal.disposal_result,
    }

async def search_similar_record_matches(
    session: AsyncSession,
    query_text: str,
    top_k: int = 5,
    min_similarity_score: float = MIN_SIMILAR_CASE_SCORE,
) -> list[SimilarRecordMatch]:
    """
    根据给定的病历描述，使用向量搜索找出最相似的历史真实病历，并返回证据质量分。
    """

    query_vec = await get_embedding(query_text)
    if not query_vec:
        return []

    distance_col = MedicalRecord.dialog_vector.cosine_distance(query_vec).label("cosine_distance")
    # 使用 PGVector 进行余弦距离搜索 ( <=> 在部分 pgvector 版本是 cosine distance, 或者 <-> 是 L2 distance)
    # 我们这里使用 cosine_distance
    stmt = select(MedicalRecord, distance_col).where(
        MedicalRecord.dialog_vector.is_not(None),
        MedicalRecord.is_doctor_confirmed == True
    ).order_by(
        distance_col
    ).limit(top_k)

    result = await session.execute(stmt)
    matches: list[SimilarRecordMatch] = []
    for record, distance in result.all():
        cosine_distance = float(distance)
        similarity_score = max(0.0, (1.0 - cosine_distance) * 100.0)
        if similarity_score < min_similarity_score:
            continue
        matches.append(
            SimilarRecordMatch(
                record=record,
                similarity_score=round(similarity_score, 1),
                cosine_distance=round(cosine_distance, 4),
            )
        )
    return matches


async def search_similar_records(session: AsyncSession, query_text: str, top_k: int = 5) -> List[MedicalRecord]:
    """
    根据给定的病历描述，使用向量搜索找出最相似的历史真实病历。
    保留旧返回结构，供已有调用方兼容使用。
    """

    matches = await search_similar_record_matches(session, query_text, top_k=top_k)
    return [match.record for match in matches]

async def ai_assistant_query(
    session: AsyncSession,
    patient_uuid: str,
    question: str,
    employee_uuid: str = None,
    top_k: int = 5,
    confirm_action: bool = False,
) -> str:
    """
    LangGraph Agent 驱动的医生智能助理。
    
    相比原来的单轮 httpx 调用，现在支持：
    - 多轮循环推理：Agent 可连续调用多个工具后汇总回答
    - 4 种工具能力：相似病历检索、排班申请、候诊队列、排班查询
    - RAG 上下文预注入：当前患者的历史病历自动注入 SystemPrompt
    
    函数签名保持不变，API 层零改动。
    """
    return await build_and_run_agent(
        session,
        patient_uuid,
        question,
        employee_uuid,
        top_k,
        confirm_action=confirm_action,
    )

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

    tech_map = {tech_id: str(tech.price) for tech_id, tech in (await _load_tech_map(session, tech_ids)).items()}

    for item_dict in ret.values():
        for item in item_dict.values():
            item["price"] = tech_map.get(item.get("tech_id"), "0.00")
            
    return ret
