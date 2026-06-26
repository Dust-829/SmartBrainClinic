import uuid as uuid_pkg
from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_session
from ..services import patient_service as svc
from app.common.response import success, created
from app.common.ai_audit import query_ai_audit_logs
from app.common.security import require_ai_audit_admin
from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
from ..config import settings
from ..services.ai_triage import run_ai_triage, DEPT_LIST

router = APIRouter(prefix="/api/v1/patient", tags=["患者与挂号服务"])

class PatientCreate(BaseModel):
    real_name: str
    gender: str
    card_number: str
    birthdate: date
    home_address: str = None

class PatientFeedbackCreate(BaseModel):
    register_uuid: uuid_pkg.UUID
    doctor_uuid: uuid_pkg.UUID
    content: str

class RegisterCreate(BaseModel):
    patient_uuid: uuid_pkg.UUID
    employee_uuid: uuid_pkg.UUID
    scheduling_actual_id: Optional[int] = None
    scheduling_time_slot_uuid: Optional[uuid_pkg.UUID] = None
    settle_category_uuid: Optional[uuid_pkg.UUID] = None
    regist_method: str = "微信"
    is_emergency: bool = False
    symptoms: str = None

class TriageMessage(BaseModel):
    role: str  # "user" 或 "assistant"
    content: str

class TriageRequest(BaseModel):
    messages: list[TriageMessage]

class DoctorRecommendRequest(BaseModel):
    symptoms: Optional[str] = ""   # 来自AI分诊的symptom_summary或用户原始输入，可为空（后端会兜底）
    dept_code: str                 # 必传：来自AI分诊结果或用户手动选科
    gender_preference: Optional[str] = "不限"
    limit: Optional[int] = 3

class OnlineRegisterCreate(BaseModel):
    patient_uuid: uuid_pkg.UUID
    employee_uuid: uuid_pkg.UUID
    scheduling_actual_id: Optional[int] = None
    scheduling_time_slot_uuid: Optional[uuid_pkg.UUID] = None
    settle_category_uuid: Optional[uuid_pkg.UUID] = None
    is_emergency: bool = False
    symptoms: Optional[str] = None

class DisruptionResolveRequest(BaseModel):
    action: str
    new_time_slot_uuid: Optional[uuid_pkg.UUID] = None

class ConfirmPaymentRequest(BaseModel):
    register_uuid: uuid_pkg.UUID
    pay_method: str = "微信"
    amount: float = 0.01
    idempotency_key: Optional[str] = None

@router.post("", summary="患者注册建档")
async def create_patient_record(data: PatientCreate, session: AsyncSession = Depends(get_session)):
    try:
        patient = await svc.create_patient(session, data.model_dump())
        return created(patient.model_dump(exclude={"id", "patient_id"}))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/feedback", summary="患者提交评价(异步大模型跑批用)")
async def create_feedback(data: PatientFeedbackCreate, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.create_patient_feedback(session, data.model_dump())
        return created(result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/card/{card_number}", summary="根据就诊卡查询患者")
async def get_patient_by_card(card_number: str, session: AsyncSession = Depends(get_session)):
    patient = await svc.get_patient_by_card(session, card_number)
    if not patient:
        raise HTTPException(status_code=404, detail="患者未建档")
    return success(patient.model_dump(exclude={"id", "patient_id"}))



@router.post("/register", summary="挂号")
async def register_visit(data: RegisterCreate, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.create_register(session, data.model_dump())
        return created(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/register/{uuid}", summary="查询挂号详情")
async def get_register_info(uuid: str, session: AsyncSession = Depends(get_session)):
    reg = await svc.get_register_by_uuid(session, uuid_pkg.UUID(uuid))
    if not reg:
        raise HTTPException(status_code=404, detail="挂号记录不存在")
    return success(reg.model_dump(exclude={"id", "patient_id", "scheduling_actual_id", "settle_category_id"}))



@router.post("/triage", summary="AI 智能分诊（多轮对话）")
async def ai_triage(data: TriageRequest):
    try:
        messages = [{"role": m.role, "content": m.content} for m in data.messages]
        res = await run_ai_triage(
            messages=messages,
            api_key=settings.LLM_API_KEY,
            api_base=settings.LLM_API_BASE,
            model=settings.LLM_MODEL
        )
        return success(res)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/departments", summary="获取所有可选科室列表（用于手动选择科室）")
async def list_departments():
    return success(DEPT_LIST)


@router.get(
    "/admin/ai-audits",
    summary="查询AI审计日志",
    dependencies=[Depends(require_ai_audit_admin)],
)
async def list_ai_audits(
    module_name: Optional[str] = None,
    source: Optional[str] = None,
    validated: Optional[bool] = None,
    created_from: Optional[datetime] = None,
    created_to: Optional[datetime] = None,
    limit: int = 50,
    offset: int = 0,
    session: AsyncSession = Depends(get_session),
):
    logs = await query_ai_audit_logs(
        session,
        module_name=module_name,
        source=source,
        validated=validated,
        created_from=created_from,
        created_to=created_to,
        limit=limit,
        offset=offset,
    )
    return success(logs)


@router.post("/recommend-doctors", summary="智能医生推荐")
async def recommend_doctors(data: DoctorRecommendRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.recommend_doctors(session, data.model_dump())
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/schedules", summary="查询医生有效排班")
async def get_doctor_schedules(employee_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        schedules = await svc.get_schedules_by_doctor(session, employee_uuid)
        return success(schedules)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class TodayAvailableRequest(BaseModel):
    employee_uuids: list[str]

@router.post("/schedules/today-available", summary="批量查询今日在岗员工")
async def get_today_available_employees(data: TodayAvailableRequest, session: AsyncSession = Depends(get_session)):
    available = await svc.get_today_available_employees(session, data.employee_uuids)
    return success(available)

@router.post("/online-register", summary="线上待支付预挂号锁源")
async def online_register(data: OnlineRegisterCreate, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.create_online_register(session, data.model_dump())
        return created(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/online-register/pay", summary="线上支付模拟与激活")
async def confirm_payment(
    data: ConfirmPaymentRequest,
    session: AsyncSession = Depends(get_session),
    idempotency_key: Optional[str] = Header(default=None, alias="Idempotency-Key"),
):
    try:
        res = await svc.confirm_online_payment(
            session=session,
            register_uuid=data.register_uuid,
            pay_method=data.pay_method,
            amount=data.amount,
            idempotency_key=idempotency_key or data.idempotency_key,
        )
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/register/{uuid}/state", summary="更新挂号单状态")
async def update_register_state(uuid: uuid_pkg.UUID, visit_state: int, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.update_visit_state(session, uuid, visit_state)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/register/{uuid}/cancel", summary="退号")
async def cancel_register(uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.cancel_register(session, uuid)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class AIScheduleRequest(BaseModel):
    employee_uuid: uuid_pkg.UUID
    prompt: str

@router.post("/ai-schedule", summary="AI 智能排班微调")
async def ai_schedule(data: AIScheduleRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.ai_schedule(session, data.employee_uuid, data.prompt)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class GenerateScheduleRequest(BaseModel):
    start_date: str
    end_date: str

@router.post("/schedule/generate", summary="常规排班自动批量生成")
async def generate_schedule(data: GenerateScheduleRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.generate_scheduling_actuals(session, data.start_date, data.end_date)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/doctor/{employee_uuid}/queue", summary="获取医生名下的当天候诊患者队列")
async def get_doctor_queue(employee_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        queue = await svc.get_doctor_queue(session, employee_uuid)
        return success(queue)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/register/{register_uuid}/queue-status", summary="查询特定挂号单的排队进度")
async def get_queue_status(register_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        status = await svc.get_queue_status(session, register_uuid)
        return success(status)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

from fastapi import WebSocket, WebSocketDisconnect
from app.microservices.patient.ws_manager import manager as ws_manager

@router.websocket("/ws/queue/{scheduling_actual_id}")
async def websocket_queue_endpoint(websocket: WebSocket, scheduling_actual_id: int):
    """
    建立 WebSocket 长连接，监听指定排班的队列状态变化。
    只要前端连接到这个 room，有人状态变化时就会收到 {"type": "queue_updated"} 的广播。
    """
    await ws_manager.connect(websocket, scheduling_actual_id)
    try:
        while True:
            # 仅仅是为了保持连接，不需要处理客户端发来的消息
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, scheduling_actual_id)
    except Exception:
        ws_manager.disconnect(websocket, scheduling_actual_id)

class SchedulingApplicationCreate(BaseModel):
    employee_uuid: uuid_pkg.UUID
    prompt: str

@router.post("/scheduling-applications", summary="提交排班申请(Agent专用)")
async def create_scheduling_application(data: SchedulingApplicationCreate, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.create_scheduling_application(session, data.employee_uuid, data.prompt)
        return success(res)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/admin/scheduling-applications", summary="管理员获取待审批排班申请")
async def get_pending_applications(session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.get_pending_scheduling_applications(session)
        return success(res)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/admin/scheduling-applications/{uuid}/approve", summary="管理员同意排班申请(触发自动排班)")
async def approve_scheduling_application(uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.approve_scheduling_application(session, uuid)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

class RejectRequest(BaseModel):
    reason: Optional[str] = ""

@router.post("/admin/scheduling-applications/{uuid}/reject", summary="管理员拒绝排班申请")
async def reject_scheduling_application(uuid: uuid_pkg.UUID, data: RejectRequest = None, session: AsyncSession = Depends(get_session)):
    try:
        reason = data.reason if data else ""
        res = await svc.reject_scheduling_application(session, uuid, reason)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
class AdminUpdateRuleRequest(BaseModel):
    employee_uuid: uuid_pkg.UUID
    rule_name: Optional[str] = None
    week_rule: Optional[str] = None
    llm_text_rule: Optional[str] = None
    regist_quota: Optional[int] = None

@router.post("/admin/scheduling-rules", summary="管理员强制干预排班规则")
async def admin_update_scheduling_rule(data: AdminUpdateRuleRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.admin_update_scheduling_rule(session, data.model_dump(exclude_unset=True))
        return success(res)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class AdminUpdateActualRequest(BaseModel):
    employee_uuid: uuid_pkg.UUID
    schedule_date: str
    noon: str
    regist_quota: int

@router.put("/admin/scheduling-actuals", summary="管理员紧急干预某日实际排班")
async def admin_update_scheduling_actual(data: AdminUpdateActualRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.admin_update_scheduling_actual(session, data.model_dump())
        return success(res)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{uuid}", summary="获取患者信息")
async def get_patient_info(uuid: str, session: AsyncSession = Depends(get_session)):
    patient = await svc.get_patient_by_uuid(session, uuid_pkg.UUID(uuid))
    if not patient:
        raise HTTPException(status_code=404, detail="患者不存在")
    return success(patient.model_dump(exclude={"id", "patient_id"}))

@router.get("/{patient_uuid}/registers", summary="查询患者的所有历史挂号单")
async def get_patient_registers(patient_uuid: str, session: AsyncSession = Depends(get_session)):
    registers = await svc.get_registers_by_patient_uuid(session, uuid_pkg.UUID(patient_uuid))
    return success([r.model_dump(exclude={"id", "patient_id", "scheduling_actual_id", "settle_category_id"}) for r in registers])

@router.get("/{patient_uuid}/registers/detail", summary="查询患者的所有历史挂号单（含详细的医生、科室、就诊时间信息）")
async def get_patient_registers_detail(patient_uuid: str, session: AsyncSession = Depends(get_session)):
    rich_registers = await svc.get_rich_registers_by_patient_uuid(session, uuid_pkg.UUID(patient_uuid))
    return success(rich_registers)

@router.get("/{patient_uuid}/my-disruptions", summary="获取患者未读的站内冲突工单")
async def get_my_disruptions(patient_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.get_patient_disruptions(session, patient_uuid)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/disruption/{uuid}/resolve", summary="处理异常冲突工单")
async def resolve_disruption(uuid: uuid_pkg.UUID, data: DisruptionResolveRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.resolve_schedule_disruption(session, uuid, data.action, data.new_time_slot_uuid)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
