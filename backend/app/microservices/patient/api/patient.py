import uuid as uuid_pkg
from datetime import date, datetime
from typing import Literal, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.ai_audit import (
    export_ai_audit_logs_csv,
    get_ai_audit_log,
    query_ai_audit_logs,
    review_ai_audit_log,
)
from app.common.ai_conversation import (
    append_ai_conversation_messages,
    create_ai_conversation_session,
    get_ai_conversation_session,
    get_latest_ai_conversation_session_by_register,
    list_ai_conversation_messages,
    update_ai_conversation_session,
)
from app.common.clients import AuthClient
from app.common.response import created, success
from app.common.security import AdminPrincipal, require_admin
from app.microservices.patient.ws_manager import manager as ws_manager

from ..config import settings
from ..database import get_session
from ..models.patient import Patient, SchedulingActual, SchedulingTimeSlot
from ..services import patient_service as svc
from ..services.ai_triage import DEPT_LIST, TriageAIUnavailableError, run_ai_triage

router = APIRouter(prefix='/api/v1/patient', tags=['患者与挂号服务'])


class PatientCreate(BaseModel):
    real_name: str
    gender: str
    card_number: str
    birthdate: date
    home_address: str | None = None


class PatientAdminUpdate(BaseModel):
    real_name: str
    gender: str
    birthdate: date
    home_address: str | None = None


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
    regist_method: str = '微信'
    is_emergency: bool = False
    symptoms: str | None = None


class TriageMessage(BaseModel):
    role: str
    content: str


class TriageRequest(BaseModel):
    patient_uuid: Optional[uuid_pkg.UUID] = None
    session_uuid: Optional[uuid_pkg.UUID] = None
    messages: list[TriageMessage]


class DoctorRecommendRequest(BaseModel):
    symptoms: Optional[str] = ''
    dept_code: str
    gender_preference: Optional[str] = '不限'
    limit: Optional[int] = 3


class OnlineRegisterCreate(BaseModel):
    patient_uuid: uuid_pkg.UUID
    employee_uuid: uuid_pkg.UUID
    scheduling_actual_id: Optional[int] = None
    scheduling_time_slot_uuid: Optional[uuid_pkg.UUID] = None
    triage_session_uuid: Optional[uuid_pkg.UUID] = None
    settle_category_uuid: Optional[uuid_pkg.UUID] = None
    is_emergency: bool = False
    symptoms: Optional[str] = None


class DisruptionResolveRequest(BaseModel):
    action: str
    new_time_slot_uuid: Optional[uuid_pkg.UUID] = None


class ConfirmPaymentRequest(BaseModel):
    register_uuid: uuid_pkg.UUID
    pay_method: str = '微信'
    amount: float = 0.01
    idempotency_key: Optional[str] = None


class PatientPaymentItem(BaseModel):
    uuid: uuid_pkg.UUID
    type: Literal['check', 'inspection', 'disposal']


class PatientPaymentItemsRequest(BaseModel):
    patient_uuid: uuid_pkg.UUID
    register_uuid: uuid_pkg.UUID
    items: list[PatientPaymentItem]
    pay_method: str = '微信'
    idempotency_key: Optional[str] = None


class TodayAvailableRequest(BaseModel):
    employee_uuids: list[str]


class AIScheduleRequest(BaseModel):
    employee_uuid: uuid_pkg.UUID
    prompt: str


class GenerateScheduleRequest(BaseModel):
    start_date: str
    end_date: str


class SchedulingApplicationCreate(BaseModel):
    employee_uuid: uuid_pkg.UUID
    prompt: str


class RejectRequest(BaseModel):
    reason: Optional[str] = ''


class AdminUpdateRuleRequest(BaseModel):
    employee_uuid: uuid_pkg.UUID
    rule_name: Optional[str] = None
    week_rule: Optional[str] = None
    llm_text_rule: Optional[str] = None
    regist_quota: Optional[int] = None
    slot_duration_minutes: Optional[int] = None
    clinic_room_uuid: Optional[uuid_pkg.UUID] = None


class AdminUpdateActualRequest(BaseModel):
    employee_uuid: uuid_pkg.UUID
    schedule_date: str
    noon: str
    regist_quota: int
    slot_duration_minutes: Optional[int] = None
    clinic_room_uuid: Optional[uuid_pkg.UUID] = None


class AuditReviewRequest(BaseModel):
    review_status: Literal['approved', 'rejected']
    review_note: str | None = None
    reviewer: str | None = None


async def _sync_triage_session_messages(
    session: AsyncSession,
    session_uuid: uuid_pkg.UUID,
    messages: list[dict[str, str]],
) -> None:
    existing_messages = await list_ai_conversation_messages(session, session_uuid)
    existing_payload = [{'role': item.role, 'content': item.content} for item in existing_messages]

    if len(messages) < len(existing_payload):
        raise ValueError('AI 会话消息长度异常，无法回写本轮分诊记录')

    if existing_payload and messages[: len(existing_payload)] != existing_payload:
        raise ValueError('AI 会话历史与当前提交不一致，请重新开始分诊')

    new_messages = messages[len(existing_payload):]
    if new_messages:
        await append_ai_conversation_messages(session, session_uuid, new_messages, start_turn_index=len(existing_payload) + 1)


@router.post('', summary='API endpoint')
async def create_patient_record(data: PatientCreate, session: AsyncSession = Depends(get_session)):
    try:
        patient = await svc.create_patient(session, data.model_dump())
        return created(patient.model_dump(exclude={'id', 'patient_id'}))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post('/feedback', summary='API endpoint')
async def create_feedback(data: PatientFeedbackCreate, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.create_patient_feedback(session, data.model_dump())
        return created(result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/card/{card_number}', summary='API endpoint')
async def get_patient_by_card(card_number: str, session: AsyncSession = Depends(get_session)):
    patient = await svc.get_patient_by_card(session, card_number)
    if not patient:
        raise HTTPException(status_code=404, detail='患者未建档')
    return success(patient.model_dump(exclude={'id', 'patient_id'}))


@router.post('/register', summary='API endpoint')
async def register_visit(data: RegisterCreate, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.create_register(session, data.model_dump())
        return created(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get('/register/{uuid}', summary='API endpoint')
async def get_register_info(uuid: str, session: AsyncSession = Depends(get_session)):
    reg = await svc.get_register_by_uuid(session, uuid_pkg.UUID(uuid))
    if not reg:
        raise HTTPException(status_code=404, detail='挂号记录不存在')

    patient = await session.get(Patient, reg.patient_id)
    schedule = await session.get(SchedulingActual, reg.scheduling_actual_id) if reg.scheduling_actual_id else None
    slot = await session.get(SchedulingTimeSlot, reg.scheduling_time_slot_id) if reg.scheduling_time_slot_id else None

    employee_name = None
    dept_name = None
    clinic_room_name = None
    clinic_room_location = None

    if reg.employee_uuid:
        employee = await AuthClient.get_employee(reg.employee_uuid)
        if employee:
            employee_name = employee.get('realname')

    if reg.dept_uuid:
        department = await AuthClient.get_department(str(reg.dept_uuid))
        if department:
            dept_name = department.get('dept_name')

    if schedule and schedule.clinic_room_uuid:
        clinic_room = await AuthClient.get_clinic_room(str(schedule.clinic_room_uuid))
        if clinic_room:
            clinic_room_name = clinic_room.get('room_name')
            clinic_room_location = clinic_room.get('location')

    payload = reg.model_dump(exclude={'id', 'patient_id', 'scheduling_actual_id', 'settle_category_id'})
    payload.update(
        {
            'patient_uuid': str(patient.uuid) if patient else None,
            'patient_name': patient.real_name if patient else None,
            'patient_case_number': patient.case_number if patient else None,
            'patient_gender': patient.gender if patient else None,
            'employee_name': employee_name,
            'dept_name': dept_name,
            'visit_state_text': svc._STATE_MAP.get(reg.visit_state, '未知'),
            'actual_schedule_date': schedule.schedule_date.isoformat() if schedule else None,
            'actual_time_range': slot.time_range if slot else None,
            'clinic_room_name': clinic_room_name,
            'clinic_room_location': clinic_room_location,
        }
    )
    return success(payload)


@router.get('/register/{register_uuid}/ai-context', summary='查询挂号关联 AI 上下文')
async def get_register_ai_context(register_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    triage_session = await get_latest_ai_conversation_session_by_register(
        session,
        register_uuid,
        module_name='patient.triage',
        surface='patient_triage',
    )
    if not triage_session:
        raise HTTPException(status_code=404, detail='当前挂号暂无关联 AI 分诊记录')

    messages = await list_ai_conversation_messages(session, triage_session.uuid)
    payload = {
        'session_uuid': str(triage_session.uuid),
        'register_uuid': str(triage_session.register_uuid) if triage_session.register_uuid else None,
        'patient_uuid': str(triage_session.patient_uuid) if triage_session.patient_uuid else None,
        'employee_uuid': str(triage_session.employee_uuid) if triage_session.employee_uuid else None,
        'surface': triage_session.surface,
        'module_name': triage_session.module_name,
        'status': triage_session.status,
        'summary_text': triage_session.summary_text,
        'profile_snapshot': triage_session.profile_snapshot_json,
        'latest_result': triage_session.latest_result_json,
        'source': triage_session.source,
        'model': triage_session.model,
        'validated': triage_session.validated,
        'created_at': triage_session.created_at.isoformat() if triage_session.created_at else None,
        'updated_at': triage_session.updated_at.isoformat() if triage_session.updated_at else None,
        'message_count': len(messages),
        'messages': [
            {
                'turn_index': item.turn_index,
                'role': item.role,
                'content': item.content,
            }
            for item in messages
        ],
    }
    return success(payload)


@router.post('/triage', summary='AI 智能分诊')
async def ai_triage(data: TriageRequest, session: AsyncSession = Depends(get_session)):
    try:
        messages = [{'role': m.role, 'content': m.content} for m in data.messages]
        triage_session = None

        if data.session_uuid:
            triage_session = await get_ai_conversation_session(session, data.session_uuid)
            if not triage_session:
                raise HTTPException(status_code=400, detail='AI 会话不存在，请重新开始分诊')
        else:
            triage_session = await create_ai_conversation_session(
                session,
                surface='patient_triage',
                module_name='patient.triage',
                patient_uuid=data.patient_uuid,
                status='draft',
            )

        await _sync_triage_session_messages(session, triage_session.uuid, messages)
        res = await run_ai_triage(
            messages=messages,
            api_key=settings.LLM_API_KEY,
            api_base=settings.LLM_API_BASE,
            model=settings.LLM_MODEL,
        )
        triage_data = res.get('data') if isinstance(res, dict) else None
        assistant_reply = triage_data.get('reply') if isinstance(triage_data, dict) else None
        symptom_summary = triage_data.get('symptom_summary') if isinstance(triage_data, dict) else None
        if assistant_reply:
            await append_ai_conversation_messages(
                session,
                triage_session.uuid,
                [{'role': 'assistant', 'content': assistant_reply}],
            )
        await update_ai_conversation_session(
            session,
            triage_session.uuid,
            patient_uuid=data.patient_uuid if data.patient_uuid else triage_session.patient_uuid,
            latest_result_json=res,
            summary_text=symptom_summary,
            source=res.get('source') if isinstance(res, dict) else None,
            model=res.get('model') if isinstance(res, dict) else None,
            validated=bool(res.get('validated')) if isinstance(res, dict) else False,
        )
        res['session_uuid'] = str(triage_session.uuid)
        return success(res)
    except TriageAIUnavailableError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/departments', summary='API endpoint')
async def list_departments():
    return success(DEPT_LIST)


@router.get(
    '/admin/ai-audits',
    summary='API endpoint',
)
async def list_ai_audits(
    module_name: Optional[str] = None,
    source: Optional[str] = None,
    validated: Optional[bool] = None,
    review_status: Optional[Literal['pending', 'approved', 'rejected', 'none']] = None,
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
        review_status=review_status,
        created_from=created_from,
        created_to=created_to,
        limit=limit,
        offset=offset,
    )
    return success(logs)


@router.get(
    '/admin/ai-audits/export',
    summary='API endpoint',
)
async def export_ai_audits(
    module_name: Optional[str] = None,
    source: Optional[str] = None,
    validated: Optional[bool] = None,
    review_status: Optional[Literal['pending', 'approved', 'rejected', 'none']] = None,
    created_from: Optional[datetime] = None,
    created_to: Optional[datetime] = None,
    session: AsyncSession = Depends(get_session),
):
    csv_text = await export_ai_audit_logs_csv(
        session,
        module_name=module_name,
        source=source,
        validated=validated,
        review_status=review_status,
        created_from=created_from,
        created_to=created_to,
    )
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    return StreamingResponse(
        iter([csv_text]),
        media_type='text/csv; charset=utf-8',
        headers={
            'Content-Disposition': f'attachment; filename=ai-audits-{timestamp}.csv',
        },
    )


@router.get(
    '/admin/ai-audits/{audit_uuid}',
    summary='API endpoint',
)
async def get_ai_audit_detail(
    audit_uuid: str,
    session: AsyncSession = Depends(get_session),
):
    log = await get_ai_audit_log(session, audit_uuid)
    if not log:
        raise HTTPException(status_code=404, detail='AI 审计记录不存在')
    return success(log)


@router.post(
    '/admin/ai-audits/{audit_uuid}/review',
    summary='API endpoint',
)
async def submit_ai_audit_review(
    audit_uuid: str,
    data: AuditReviewRequest,
    session: AsyncSession = Depends(get_session),
):
    try:
        log = await review_ai_audit_log(
            session,
            audit_uuid,
            review_status=data.review_status,
            review_note=data.review_note,
            reviewer=data.reviewer,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    if not log:
        raise HTTPException(status_code=404, detail='AI 审计记录不存在')
    return success(log)


@router.post('/recommend-doctors', summary='API endpoint')
async def recommend_doctors(data: DoctorRecommendRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.recommend_doctors(session, data.model_dump())
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/schedules', summary='API endpoint')
async def get_doctor_schedules(employee_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        schedules = await svc.get_schedules_by_doctor(session, employee_uuid)
        return success(schedules)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post('/schedules/today-available', summary='API endpoint')
async def get_today_available_employees(data: TodayAvailableRequest, session: AsyncSession = Depends(get_session)):
    available = await svc.get_today_available_employees(session, data.employee_uuids)
    return success(available)


@router.post('/online-register', summary='API endpoint')
async def online_register(data: OnlineRegisterCreate, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.create_online_register(session, data.model_dump())
        return created(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post('/online-register/pay', summary='API endpoint')
async def confirm_payment(
    data: ConfirmPaymentRequest,
    session: AsyncSession = Depends(get_session),
    idempotency_key: Optional[str] = Header(default=None, alias='Idempotency-Key'),
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


@router.get('/{patient_uuid}/payment-items', summary='查询患者待缴医疗项目')
async def get_patient_payment_items(patient_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        return success(await svc.list_patient_payment_items(session, patient_uuid))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get('/{patient_uuid}/payment-records', summary='查询患者缴费记录')
async def get_patient_payment_records(patient_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        return success(await svc.list_patient_payment_records(session, patient_uuid))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get('/{patient_uuid}/reports', summary='查询患者已发布检查检验报告')
async def get_patient_published_reports(patient_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        return success(await svc.list_patient_published_reports(session, patient_uuid))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post('/payment-items/pay', summary='支付患者待缴医疗项目')
async def pay_patient_payment_items(
    data: PatientPaymentItemsRequest,
    session: AsyncSession = Depends(get_session),
    idempotency_key: Optional[str] = Header(default=None, alias='Idempotency-Key'),
):
    try:
        result = await svc.pay_patient_payment_items(
            session=session,
            patient_uuid=data.patient_uuid,
            register_uuid=data.register_uuid,
            items=[item.model_dump() for item in data.items],
            pay_method=data.pay_method,
            idempotency_key=data.idempotency_key or idempotency_key,
        )
        return created(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put('/register/{uuid}/state', summary='API endpoint')
async def update_register_state(uuid: uuid_pkg.UUID, visit_state: int, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.update_visit_state(session, uuid, visit_state)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put('/register/{uuid}/start-reception', summary='API endpoint')
async def start_reception(uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.start_reception(session, uuid)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put('/register/{uuid}/finish', summary='API endpoint')
async def finish_visit(uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.finish_visit(session, uuid)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put('/register/{uuid}/cancel', summary='API endpoint')
async def cancel_register(uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.cancel_register(session, uuid)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post('/ai-schedule', summary='API endpoint')
async def ai_schedule(data: AIScheduleRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.ai_schedule(session, data.employee_uuid, data.prompt)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post('/schedule/generate', summary='API endpoint')
async def generate_schedule(data: GenerateScheduleRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.generate_scheduling_actuals(session, data.start_date, data.end_date)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/doctor/{employee_uuid}/queue', summary='API endpoint')
async def get_doctor_queue(employee_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        queue = await svc.get_doctor_queue(session, employee_uuid)
        return success(queue)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post('/doctor/{employee_uuid}/queue/call-next', summary='API endpoint')
async def call_next_patient(employee_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.call_next_patient(session, employee_uuid)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/register/{register_uuid}/queue-status', summary='API endpoint')
async def get_queue_status(register_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        status = await svc.get_queue_status(session, register_uuid)
        return success(status)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.websocket('/ws/queue/{scheduling_actual_id}')
async def websocket_queue_endpoint(websocket: WebSocket, scheduling_actual_id: int):
    await ws_manager.connect(websocket, scheduling_actual_id)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, scheduling_actual_id)
    except Exception:
        ws_manager.disconnect(websocket, scheduling_actual_id)


@router.post('/scheduling-applications', summary='API endpoint')
async def create_scheduling_application(data: SchedulingApplicationCreate, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.create_scheduling_application(session, data.employee_uuid, data.prompt)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/admin/scheduling-applications', summary='API endpoint')
async def get_pending_applications(
    status: Optional[str] = 'pending',
    session: AsyncSession = Depends(get_session),
):
    try:
        res = await svc.get_pending_scheduling_applications(session, status=status)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post('/admin/scheduling-applications/{uuid}/approve', summary='API endpoint')
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


@router.post('/admin/scheduling-applications/{uuid}/reject', summary='API endpoint')
async def reject_scheduling_application(
    uuid: uuid_pkg.UUID,
    data: RejectRequest | None = None,
    session: AsyncSession = Depends(get_session),
):
    try:
        reason = data.reason if data else ''
        res = await svc.reject_scheduling_application(session, uuid, reason)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post('/admin/scheduling-rules', summary='API endpoint')
async def admin_update_scheduling_rule(data: AdminUpdateRuleRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.admin_update_scheduling_rule(session, data.model_dump(exclude_unset=True))
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put('/admin/scheduling-actuals', summary='API endpoint')
async def admin_update_scheduling_actual(data: AdminUpdateActualRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.admin_update_scheduling_actual(session, data.model_dump())
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/admin/patients', summary='API endpoint')
async def list_admin_patients(
    keyword: str = '',
    limit: int = 20,
    offset: int = 0,
    session: AsyncSession = Depends(get_session),
    _: AdminPrincipal = Depends(require_admin),
):
    try:
        patients = await svc.list_admin_patients(session, keyword=keyword, limit=limit, offset=offset)
        return success(patients)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/admin/stats', summary='API endpoint')
async def get_admin_patient_stats(session: AsyncSession = Depends(get_session)):
    try:
        stats = await svc.get_admin_patient_stats(session)
        return success(stats)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put('/admin/patients/{uuid}', summary='API endpoint')
async def update_admin_patient(
    uuid: uuid_pkg.UUID,
    data: PatientAdminUpdate,
    session: AsyncSession = Depends(get_session),
    _: AdminPrincipal = Depends(require_admin),
):
    try:
        patient = await svc.update_admin_patient(session, uuid, data.model_dump())
        return success(patient)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/admin/patients/{uuid}', summary='管理员查看患者完整档案')
async def get_admin_patient_detail(
    uuid: uuid_pkg.UUID,
    session: AsyncSession = Depends(get_session),
    _: AdminPrincipal = Depends(require_admin),
):
    try:
        return success(await svc.get_admin_patient_detail(session, uuid))
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/admin/doctors/{employee_uuid}/deactivation-check', summary='检查医生是否可停用')
async def get_doctor_deactivation_check(
    employee_uuid: uuid_pkg.UUID,
    session: AsyncSession = Depends(get_session),
    _: AdminPrincipal = Depends(require_admin),
):
    try:
        return success(await svc.get_doctor_deactivation_check(session, employee_uuid))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get('/{uuid}', summary='API endpoint')
async def get_patient_info(uuid: str, session: AsyncSession = Depends(get_session)):
    patient = await svc.get_patient_by_uuid(session, uuid_pkg.UUID(uuid))
    if not patient:
        raise HTTPException(status_code=404, detail='患者不存在')
    return success(patient.model_dump(exclude={'id', 'patient_id'}))


@router.get('/{patient_uuid}/registers', summary='API endpoint')
async def get_patient_registers(patient_uuid: str, session: AsyncSession = Depends(get_session)):
    registers = await svc.get_registers_by_patient_uuid(session, uuid_pkg.UUID(patient_uuid))
    return success([
        r.model_dump(exclude={'id', 'patient_id', 'scheduling_actual_id', 'settle_category_id'})
        for r in registers
    ])


@router.get('/{patient_uuid}/registers/detail', summary='API endpoint')
async def get_patient_registers_detail(patient_uuid: str, session: AsyncSession = Depends(get_session)):
    rich_registers = await svc.get_rich_registers_by_patient_uuid(session, uuid_pkg.UUID(patient_uuid))
    return success(rich_registers)


@router.get('/{patient_uuid}/my-disruptions', summary='API endpoint')
async def get_my_disruptions(patient_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.get_patient_disruptions(session, patient_uuid)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post('/disruption/{uuid}/resolve', summary='API endpoint')
async def resolve_disruption(uuid: uuid_pkg.UUID, data: DisruptionResolveRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.resolve_schedule_disruption(session, uuid, data.action, data.new_time_slot_uuid)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

