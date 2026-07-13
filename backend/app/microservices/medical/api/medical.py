import uuid as uuid_pkg
from typing import Any, Literal, Optional
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_session
from ..services import medical_service as svc
from app.common.response import success, created
from ..models.medical import MedicalTechnology
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/v1/medical", tags=["临床与医技服务"])

class MedicalRecordCreate(BaseModel):
    register_uuid: uuid_pkg.UUID
    readme: str = None
    present: str = None

class CheckRequestCreate(BaseModel):
    register_uuid: uuid_pkg.UUID
    medical_technology_id: int
    check_info: str = None
    check_position: str = None

class InspectionRequestCreate(BaseModel):
    register_uuid: uuid_pkg.UUID
    medical_technology_id: int

class DisposalRequestCreate(BaseModel):
    register_uuid: uuid_pkg.UUID
    medical_technology_id: int


class OrderSignItem(BaseModel):
    type: Literal["check", "inspection", "disposal"]
    medical_technology_id: int
    check_info: str | None = None
    check_position: str | None = None


class OrderSignRequest(BaseModel):
    register_uuid: uuid_pkg.UUID
    items: list[OrderSignItem] = Field(min_length=1)


class RefundItem(BaseModel):
    type: str
    id: str

class RefundItemsRequest(BaseModel):
    items: list[RefundItem]

class MedicalRecordConfirm(BaseModel):
    readme: str
    present: str
    history: str
    physique: str
    diagnosis: str
    allergy: str = None
    proposal: str = None
    cure: str = None

class CheckResultInput(BaseModel):
    image_path: str = None
    check_result: str = None
    inputcheck_employee_uuid: uuid_pkg.UUID


class ArtifactInferenceSubmit(BaseModel):
    source_image_ref: str = Field(min_length=1, max_length=1024)
    source_format: Literal["dicom", "nifti"]
    submitted_by_employee_uuid: uuid_pkg.UUID


class InspectionResultInput(BaseModel):
    test_results: Any = None
    input_employee_uuid: uuid_pkg.UUID


class DisposalResultInput(BaseModel):
    disposal_result: str = None


class SearchSimilarRequest(BaseModel):
    query_text: str
    top_k: int = 5

class AIAssistantRequest(BaseModel):
    patient_uuid: Optional[uuid_pkg.UUID] = None
    employee_uuid : Optional[uuid_pkg.UUID] = None
    question: str
    top_k: int = 5
    confirm_action: bool = False

@router.post("/record/ai-assistant", summary="AI医生辅助查询(RAG)")
async def ai_assistant(data: AIAssistantRequest, session: AsyncSession = Depends(get_session)):
    try:
        answer = await svc.ai_assistant_query(
            session=session,
            patient_uuid=data.patient_uuid,
            question=data.question,
            employee_uuid=data.employee_uuid,
            top_k=data.top_k,
            confirm_action=data.confirm_action,
        )
        return success({"answer": answer})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/record/search-similar", summary="AI相似病历召回")
async def search_similar(data: SearchSimilarRequest, session: AsyncSession = Depends(get_session)):
    try:
        matches = await svc.search_similar_record_matches(session, data.query_text, data.top_k)
        results = [
            {
                "uuid": str(match.record.uuid),
                "register_uuid": str(match.record.register_uuid),
                "present": match.record.present,
                "history": match.record.history,
                "diagnosis": match.record.diagnosis,
                "similarity_score": match.similarity_score,
                "cosine_distance": match.cosine_distance,
            } for match in matches
        ]
        return success(results)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/record", summary="创建病历")
async def create_record(data: MedicalRecordCreate, session: AsyncSession = Depends(get_session)):
    try:
        record = await svc.create_medical_record(session, data.model_dump())
        return created({"uuid": str(record.uuid)})
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/check", summary="开立检查")
async def create_check(data: CheckRequestCreate, background_tasks: BackgroundTasks, session: AsyncSession = Depends(get_session)):
    try:
        check = await svc.create_check_request(session, data.model_dump(), background_tasks)
        return created({"uuid": str(check.uuid)})
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/inspection", summary="开立检验")
async def create_inspection(data: InspectionRequestCreate, session: AsyncSession = Depends(get_session)):
    try:
        inspection = await svc.create_inspection_request(session, data.model_dump())
        return created({"uuid": str(inspection.uuid)})
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/disposal", summary="开立处置")
async def create_disposal(data: DisposalRequestCreate, session: AsyncSession = Depends(get_session)):
    try:
        disposal = await svc.create_disposal_request(session, data.model_dump())
        return created({"uuid": str(disposal.uuid)})
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/orders/sign", summary="统一签署检查检验处置医嘱")
async def sign_orders(
    data: OrderSignRequest,
    background_tasks: BackgroundTasks,
    session: AsyncSession = Depends(get_session),
):
    try:
        items = await svc.create_signed_orders(
            session,
            data.register_uuid,
            [item.model_dump() for item in data.items],
            background_tasks,
        )
        return created({"count": len(items), "items": items})
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/tech", summary="获取医技项目列表")
async def list_techs(tech_type: Optional[str] = None, session: AsyncSession = Depends(get_session)):
    try:
        techs = await svc.list_medical_technologies(session, tech_type=tech_type)
        return success([
            {
                "id": tech.id,
                "uuid": str(tech.uuid),
                "tech_code": tech.tech_code,
                "tech_name": tech.tech_name,
                "tech_type": tech.tech_type,
                "price": str(tech.price),
            }
            for tech in techs
        ])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/tech/{uuid}", summary="获取医技项目信息")
async def get_tech(uuid: str, session: AsyncSession = Depends(get_session)):
    tech = await svc.get_tech_by_uuid(session, uuid)
    if not tech:
        raise HTTPException(status_code=404, detail="项目不存在")
    return success(tech.model_dump(mode="json"))

@router.get("/check/{uuid}", summary="获取检查单明细")
async def get_check_request(uuid: str, session: AsyncSession = Depends(get_session)):
    check = await svc.get_check_request_by_uuid(session, uuid)
    if not check:
        raise HTTPException(status_code=404, detail="检查单不存在")
    
    tech = await session.get(MedicalTechnology, check.medical_technology_id)
    return success({
        "uuid": str(check.uuid),
        "register_uuid": str(check.register_uuid),
        "check_state": check.check_state,
        "medical_technology_id": check.medical_technology_id,
        "medical_technology_uuid": str(tech.uuid) if tech else None,
        "check_result": check.check_result,
        "image_path": check.image_path,
        "ai_tumor_prob": str(check.ai_tumor_prob) if check.ai_tumor_prob is not None else None,
    })


@router.post("/check/{uuid}/artifact-inference", summary="提交 CT 伪影分析任务", status_code=202)
async def submit_artifact_inference_task(
    uuid: str,
    data: ArtifactInferenceSubmit,
    background_tasks: BackgroundTasks,
    session: AsyncSession = Depends(get_session),
):
    try:
        task = await svc.create_artifact_inference_task(
            session=session,
            check_uuid=uuid,
            submitted_by_employee_uuid=data.submitted_by_employee_uuid,
            source_image_ref=data.source_image_ref,
            source_format=data.source_format,
        )
        background_tasks.add_task(svc.run_artifact_inference_task, str(task.uuid))
        return {"code": 202, "message": "任务已提交", "data": svc.serialize_artifact_inference_task(task)}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@router.get("/artifact-inference/{task_uuid}", summary="查询 CT 伪影分析任务")
async def get_artifact_inference_task(task_uuid: str, session: AsyncSession = Depends(get_session)):
    task = await svc.get_artifact_inference_task(session, task_uuid)
    if not task:
        raise HTTPException(status_code=404, detail="伪影分析任务不存在")
    return success(svc.serialize_artifact_inference_task(task))

@router.get("/inspection/{uuid}", summary="获取检验单明细")
async def get_inspection_request(uuid: str, session: AsyncSession = Depends(get_session)):
    check = await svc.get_inspection_request_by_uuid(session, uuid)
    if not check:
        raise HTTPException(status_code=404, detail="检验单不存在")
    tech = await session.get(MedicalTechnology, check.medical_technology_id)
    return success({"uuid": str(check.uuid), "register_uuid": str(check.register_uuid), "inspection_state": check.inspection_state, "medical_technology_id": check.medical_technology_id, "medical_technology_uuid": str(tech.uuid) if tech else None, "test_results": check.test_results})

@router.get("/disposal/{uuid}", summary="获取处置单明细")
async def get_disposal_request(uuid: str, session: AsyncSession = Depends(get_session)):
    check = await svc.get_disposal_request_by_uuid(session, uuid)
    if not check:
        raise HTTPException(status_code=404, detail="处置单不存在")
    tech = await session.get(MedicalTechnology, check.medical_technology_id)
    return success({"uuid": str(check.uuid), "register_uuid": str(check.register_uuid), "disposal_state": check.disposal_state, "medical_technology_id": check.medical_technology_id, "medical_technology_uuid": str(tech.uuid) if tech else None, "disposal_result": check.disposal_result})

@router.put("/check/{uuid}/state", summary="更新检查单状态")
async def update_check_state(uuid: str, state: str, session: AsyncSession = Depends(get_session)):
    check = await svc.update_check_state(session, uuid, state)
    if not check:
        raise HTTPException(status_code=404, detail="检查单不存在")
    return success({"uuid": str(check.uuid), "check_state": check.check_state})

@router.put("/inspection/{uuid}/state", summary="更新检验单状态")
async def update_inspection_state(uuid: str, state: str, session: AsyncSession = Depends(get_session)):
    inspection = await svc.update_inspection_state(session, uuid, state)
    if not inspection:
        raise HTTPException(status_code=404, detail="检验单不存在")
    return success({"uuid": str(inspection.uuid), "inspection_state": inspection.inspection_state})

@router.put("/disposal/{uuid}/state", summary="更新处置单状态")
async def update_disposal_state(uuid: str, state: str, session: AsyncSession = Depends(get_session)):
    disposal = await svc.update_disposal_state(session, uuid, state)
    if not disposal:
        raise HTTPException(status_code=404, detail="处置单不存在")
    return success({"uuid": str(disposal.uuid), "disposal_state": disposal.disposal_state})

@router.post("/refund-items", summary="内部原子退费医技项目")
async def refund_items(data: RefundItemsRequest, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.refund_items(session, [item.model_dump() for item in data.items])
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/record/draft/{register_uuid}", summary="获取AI预装载病历草稿")
async def get_medical_record_draft(register_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        record = await svc.get_medical_record_draft(session, register_uuid)
        if not record:
            raise HTTPException(status_code=404, detail="AI预装载病历不存在")
        return success({
            "uuid": str(record.uuid),
            "register_uuid": str(record.register_uuid),
            "readme": record.readme,
            "present": record.present,
            "history": record.history,
            "allergy": record.allergy,
            "physique": record.physique,
            "proposal": record.proposal,
            "diagnosis": record.diagnosis,
            "cure": record.cure,
            "is_doctor_confirmed": record.is_doctor_confirmed
        })
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/record/draft/{register_uuid}/confirm", summary="医生确认修改病历草稿")
async def confirm_draft(register_uuid: uuid_pkg.UUID, data: MedicalRecordConfirm, session: AsyncSession = Depends(get_session)):
    try:
        record = await svc.confirm_medical_record_draft(
            session=session,
            register_uuid=register_uuid,
            readme=data.readme,
            present=data.present,
            history=data.history,
            physique=data.physique,
            diagnosis=data.diagnosis,
            allergy=data.allergy,
            proposal=data.proposal,
            cure=data.cure
        )
        return success({"uuid": str(record.uuid), "is_doctor_confirmed": record.is_doctor_confirmed})
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/check/{uuid}/result", summary="录入检查结果与影像")
async def input_check_result(uuid: str, data: CheckResultInput, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.input_check_result(
            session=session,
            check_uuid=uuid,
            inputcheck_employee_uuid=data.inputcheck_employee_uuid,
            image_path=data.image_path,
            check_result=data.check_result
        )
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/inspection/{uuid}/result", summary="录入检验结果")
async def input_inspection_result(uuid: str, data: InspectionResultInput, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.input_inspection_result(
            session=session,
            inspection_uuid=uuid,
            input_employee_uuid=data.input_employee_uuid,
            test_results=data.test_results,
        )
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/disposal/{uuid}/result", summary="录入处置结果")
async def input_disposal_result(uuid: str, data: DisposalResultInput, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.input_disposal_result(
            session=session,
            disposal_uuid=uuid,
            disposal_result=data.disposal_result,
        )
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/record/{register_uuid}", summary="根据挂号单UUID获取完整病历记录")
async def get_medical_record(register_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        record = await svc.get_medical_record_draft(session, register_uuid)
        if not record:
            raise HTTPException(status_code=404, detail="病历记录不存在")
        if not record.is_doctor_confirmed:
            raise HTTPException(status_code=404, detail="病历尚未经医生确认，暂不可查阅")
        return success({
            "uuid": str(record.uuid),
            "register_uuid": str(record.register_uuid),
            "readme": record.readme,
            "present": record.present,
            "history": record.history,
            "allergy": record.allergy,
            "physique": record.physique,
            "proposal": record.proposal,
            "diagnosis": record.diagnosis,
            "cure": record.cure,
            "is_doctor_confirmed": record.is_doctor_confirmed
        })
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/requests/register/{register_uuid}", summary="按挂号单获取检查检验处置队列")
async def get_register_requests(register_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.list_requests_by_register(session, register_uuid)
        return success(result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class BatchRequestsInput(BaseModel):
    check_uuids: list[str] = []
    inspection_uuids: list[str] = []
    disposal_uuids: list[str] = []

@router.post("/requests/batch", summary="批量获取医疗项目明细及价格")
async def get_requests_batch(data: BatchRequestsInput, session: AsyncSession = Depends(get_session)):
    try:
        ret = await svc.get_requests_batch(session, data.check_uuids, data.inspection_uuids, data.disposal_uuids)
        return success(ret)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
