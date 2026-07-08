import uuid
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from types import SimpleNamespace

import pytest

from app.common.clients import AuthClient, BaseClient, BillingClient
from app.microservices.patient.services import patient_service


@pytest.mark.asyncio
async def test_billing_client_uses_bill_route_and_required_get(monkeypatch):
    captured = {}
    register_uuid = uuid.uuid4()

    def fake_get_url(service_name):
        assert service_name == "billing"
        return "http://billing:8005/api/v1/billing"

    async def fake_get_required(url, params=None):
        captured["url"] = url
        captured["params"] = params
        return [{"bill_state": "已退费"}]

    monkeypatch.setattr(BaseClient, "get_url", fake_get_url)
    monkeypatch.setattr(BaseClient, "get_required", fake_get_required)

    result = await BillingClient.get_bills_by_register(register_uuid)

    assert result == [{"bill_state": "已退费"}]
    assert captured == {
        "url": f"http://billing:8005/api/v1/bill/register/{register_uuid}",
        "params": None,
    }


@pytest.mark.asyncio
async def test_rich_register_history_reuses_cached_remote_lookups(monkeypatch):
    employee_uuid = uuid.uuid4()
    patient_uuid = uuid.uuid4()
    room_uuid = uuid.uuid4()
    register_a_uuid = uuid.uuid4()
    register_b_uuid = uuid.uuid4()

    raw_registers = [
        SimpleNamespace(
            uuid=register_a_uuid,
            visit_date=datetime(2026, 7, 8, 8, 30),
            noon="上午",
            dept_uuid=None,
            employee_uuid=employee_uuid,
            regist_method="微信",
            regist_money=Decimal("20.00"),
            is_emergency=False,
            visit_state=1,
            symptoms="头痛",
            scheduling_actual_id=11,
            scheduling_time_slot_id=21,
        ),
        SimpleNamespace(
            uuid=register_b_uuid,
            visit_date=datetime(2026, 7, 8, 9, 0),
            noon="上午",
            dept_uuid=None,
            employee_uuid=employee_uuid,
            regist_method="微信",
            regist_money=Decimal("20.00"),
            is_emergency=False,
            visit_state=1,
            symptoms="恶心",
            scheduling_actual_id=11,
            scheduling_time_slot_id=22,
        ),
    ]

    class FakeScalarResult:
        def __init__(self, values):
            self._values = values

        def all(self):
            return self._values

    class FakeExecuteResult:
        def __init__(self, values):
            self._values = values

        def scalars(self):
            return FakeScalarResult(self._values)

    class FakeSession:
        def __init__(self):
            self.execute_calls = 0

        async def execute(self, stmt):
            self.execute_calls += 1
            entity = stmt.column_descriptions[0]["entity"]
            if entity is patient_service.SchedulingActual:
                return FakeExecuteResult([
                    SimpleNamespace(id=11, schedule_date=date(2026, 7, 9), clinic_room_uuid=room_uuid),
                ])
            if entity is patient_service.SchedulingTimeSlot:
                return FakeExecuteResult([
                    SimpleNamespace(id=21, time_range="08:00-08:10"),
                    SimpleNamespace(id=22, time_range="08:10-08:20"),
                ])
            raise AssertionError(f"Unexpected query entity: {entity}")

    async def fake_get_registers_by_patient_uuid(session, target_patient_uuid):
        assert target_patient_uuid == patient_uuid
        return raw_registers

    lookup_counts = {"employee": 0, "department": 0, "clinic_room": 0}

    async def fake_get_employee(target_employee_uuid):
        lookup_counts["employee"] += 1
        assert str(target_employee_uuid) == str(employee_uuid)
        return {"realname": "王医生", "dept_uuid": "dept-001"}

    async def fake_get_department(target_dept_uuid):
        lookup_counts["department"] += 1
        assert target_dept_uuid == "dept-001"
        return {"dept_name": "神经外科"}

    async def fake_get_clinic_room(target_room_uuid):
        lookup_counts["clinic_room"] += 1
        assert str(target_room_uuid) == str(room_uuid)
        return {"room_name": "A101", "location": "门诊一层"}

    monkeypatch.setattr(patient_service, "get_registers_by_patient_uuid", fake_get_registers_by_patient_uuid)
    monkeypatch.setattr(AuthClient, "get_employee", fake_get_employee)
    monkeypatch.setattr(AuthClient, "get_department", fake_get_department)
    monkeypatch.setattr(AuthClient, "get_clinic_room", fake_get_clinic_room)

    session = FakeSession()
    result = await patient_service.get_rich_registers_by_patient_uuid(session, patient_uuid)

    assert len(result) == 2
    assert [item["actual_time_range"] for item in result] == ["08:00-08:10", "08:10-08:20"]
    assert all(item["dept_name"] == "神经外科" for item in result)
    assert all(item["clinic_room_name"] == "A101" for item in result)
    assert lookup_counts == {"employee": 1, "department": 1, "clinic_room": 1}
    assert session.execute_calls == 2


def test_patient_registration_validates_selected_schedule_belongs_to_doctor():
    source = Path("app/microservices/patient/services/patient_service.py").read_text(encoding="utf-8")

    assert "def _ensure_schedule_matches_employee" in source
    assert "所选号源不属于当前医生" in source
    assert source.count("_ensure_schedule_matches_employee(schedule, data[\"employee_uuid\"])") >= 4


def test_queue_status_counts_by_time_slot_before_falling_back_to_register_id():
    source = Path("app/microservices/patient/services/patient_service.py").read_text(encoding="utf-8")

    assert "current_slot = await session.get(SchedulingTimeSlot, register.scheduling_time_slot_id)" in source
    assert "SchedulingTimeSlot.time_range < current_slot.time_range" in source
    assert "Register.id < register.id" in source


def test_cancel_register_blocks_every_non_refunded_bill():
    source = Path("app/microservices/patient/services/patient_service.py").read_text(encoding="utf-8")

    assert "blocking_bills = [" in source
    assert "b.get(\"bill_state\") != BillState.REFUNDED.value" in source
    assert "存在未完成退费账单" in source


def test_medical_record_confirmed_can_close_registered_visit():
    source = Path("app/microservices/patient/workers/medical_consumer.py").read_text(encoding="utf-8")

    assert "VisitState.FINISHED" in source
    assert "register.visit_state == VisitState.REGISTERED" in source
    assert "VisitState.RECEPTION" in source
    assert "ws_manager.broadcast" in source


def test_patient_api_exposes_explicit_queue_and_visit_actions():
    api_source = Path("app/microservices/patient/api/patient.py").read_text(encoding="utf-8")
    service_source = Path("app/microservices/patient/services/patient_service.py").read_text(encoding="utf-8")

    assert "/register/{uuid}/start-reception" in api_source
    assert "/register/{uuid}/finish" in api_source
    assert "/doctor/{employee_uuid}/queue/call-next" in api_source
    assert "async def call_next_patient" in service_source
    assert "queue_called" in service_source
    assert "with_for_update()" in service_source


def test_start_reception_blocks_parallel_active_patients_for_same_doctor():
    source = Path("app/microservices/patient/services/patient_service.py").read_text(encoding="utf-8")

    assert "Register.employee_uuid == register.employee_uuid" in source
    assert "Register.visit_state == VisitState.RECEPTION" in source
    assert "当前医生已有接诊中的患者，请先完成当前接诊后再开始下一位。" in source
