import uuid
from pathlib import Path

import pytest

from app.common.clients import BaseClient, BillingClient


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
