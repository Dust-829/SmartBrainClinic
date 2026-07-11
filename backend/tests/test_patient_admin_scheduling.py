import uuid
from datetime import date, datetime
from types import SimpleNamespace

import pytest

from app.microservices.patient.services import ai_scheduling, patient_service


class FakeScalarResult:
    def __init__(self, value=None, values=None):
        self._value = value
        self._values = values or []

    def scalar_one_or_none(self):
        return self._value

    def first(self):
        return self._value

    def all(self):
        return self._values


class FakeExecuteResult:
    def __init__(self, value=None, values=None):
        self._scalar = FakeScalarResult(value=value, values=values)

    def scalar_one_or_none(self):
        return self._scalar.scalar_one_or_none()

    def scalars(self):
        return self._scalar


class FakeSession:
    def __init__(self, execute_result=None):
        self.execute_result = execute_result
        self.added = []
        self.deleted = []
        self.executed = []
        self.flush_count = 0

    async def execute(self, stmt):
        self.executed.append(stmt)
        if callable(self.execute_result):
            return self.execute_result(stmt)
        if self.execute_result is not None:
            return self.execute_result
        return FakeExecuteResult()

    def add(self, obj):
        self.added.append(obj)

    async def delete(self, obj):
        self.deleted.append(obj)

    async def flush(self):
        self.flush_count += 1
        for index, obj in enumerate(self.added, start=1):
            if getattr(obj, "id", None) is None:
                obj.id = index

    async def rollback(self):
        return None


def _mojibake(text: str) -> str:
    return text.encode("utf-8").decode("latin-1")


def test_resolve_relative_date_uses_current_week_or_next_occurrence():
    base_date = date(2026, 7, 11)

    assert ai_scheduling.resolve_relative_date("本周一", base_date) == date(2026, 7, 6)
    assert ai_scheduling.resolve_relative_date("下周三", base_date) == date(2026, 7, 15)
    assert ai_scheduling.resolve_relative_date("周一", base_date) == date(2026, 7, 13)
    assert ai_scheduling.resolve_relative_date("明天", base_date) == date(2026, 7, 12)


@pytest.mark.asyncio
async def test_generate_scheduling_actuals_skips_existing_and_uses_sync_time_slots(monkeypatch):
    employee_uuid = uuid.uuid4()
    rule = SimpleNamespace(
        employee_uuid=employee_uuid,
        week_rule="1,2,3,4,5",
        regist_quota=3,
        clinic_room_uuid=uuid.uuid4(),
        delmark=1,
    )

    async def fake_find_scheduling_actual(session, target_employee_uuid, schedule_date, noon):
        assert target_employee_uuid == employee_uuid
        if noon == "上午":
            return SimpleNamespace(id=9)
        return None

    sync_calls = []

    async def fake_sync_time_slots(session, actual, is_new=False):
        sync_calls.append((actual.schedule_date, actual.noon, actual.regist_quota, is_new))

    monkeypatch.setattr(patient_service, "_find_scheduling_actual", fake_find_scheduling_actual)
    monkeypatch.setattr(patient_service, "_sync_time_slots", fake_sync_time_slots)

    session = FakeSession(execute_result=FakeExecuteResult(values=[rule]))
    result = await patient_service.generate_scheduling_actuals(session, "2026-07-13", "2026-07-13")

    assert result == {
        "start_date": "2026-07-13",
        "end_date": "2026-07-13",
        "generated_count": 1,
        "skipped_count": 1,
        "success": True,
    }
    assert sync_calls == [(date(2026, 7, 13), "下午", 3, True)]


@pytest.mark.asyncio
async def test_admin_update_scheduling_rule_persists_clinic_room_uuid(monkeypatch):
    employee_uuid = uuid.uuid4()
    room_uuid = uuid.uuid4()
    rule = SimpleNamespace(
        employee_uuid=employee_uuid,
        rule_name="旧规则",
        week_rule="1,2,3",
        llm_text_rule="旧文案",
        regist_quota=10,
        clinic_room_uuid=None,
    )

    async def fake_get_employee(target_employee_uuid):
        assert str(target_employee_uuid) == str(employee_uuid)
        return {"uuid": str(employee_uuid), "realname": "张医生"}

    monkeypatch.setattr(patient_service.AuthClient, "get_employee", fake_get_employee)
    session = FakeSession(execute_result=FakeExecuteResult(value=rule))
    result = await patient_service.admin_update_scheduling_rule(
        session,
        {
            "employee_uuid": str(employee_uuid),
            "week_rule": "1,2,2,5",
            "regist_quota": 18,
            "clinic_room_uuid": str(room_uuid),
        },
    )

    assert rule.week_rule == "1,2,5"
    assert rule.regist_quota == 18
    assert rule.clinic_room_uuid == room_uuid
    assert result["clinic_room_uuid"] == str(room_uuid)
    assert result["week_rule"] == "1,2,5"


@pytest.mark.asyncio
async def test_apply_scheduling_actual_change_clamps_quota_and_updates_room(monkeypatch):
    employee_uuid = uuid.uuid4()
    room_uuid = uuid.uuid4()
    actual = SimpleNamespace(
        id=1,
        employee_uuid=employee_uuid,
        schedule_date=date(2026, 7, 13),
        noon="上午",
        regist_quota=10,
        registered_count=6,
        clinic_room_uuid=None,
    )

    async def fake_find_scheduling_actual(session, target_employee_uuid, schedule_date, noon):
        return actual

    sync_calls = []

    async def fake_sync_time_slots(session, target_actual, is_new=False):
        sync_calls.append((target_actual.regist_quota, is_new))

    monkeypatch.setattr(patient_service, "_find_scheduling_actual", fake_find_scheduling_actual)
    monkeypatch.setattr(patient_service, "_sync_time_slots", fake_sync_time_slots)

    session = FakeSession()
    summary = await patient_service._apply_scheduling_actual_change(
        session,
        employee_uuid=employee_uuid,
        schedule_date=date(2026, 7, 13),
        noon="上午",
        regist_quota=3,
        clinic_room_uuid=room_uuid,
        action_type="modify",
    )

    assert actual.regist_quota == 6
    assert actual.clinic_room_uuid == room_uuid
    assert summary["status"] == "updated"
    assert summary["clamped_to_registered_count"] is True
    assert summary["final_regist_quota"] == 6
    assert sync_calls == [(6, False)]


@pytest.mark.asyncio
async def test_cancel_after_time_creates_disruption_and_trims_quota(monkeypatch):
    employee_uuid = uuid.uuid4()
    actual = SimpleNamespace(
        id=1,
        employee_uuid=employee_uuid,
        schedule_date=date(2026, 7, 13),
        noon="下午",
        regist_quota=3,
        registered_count=1,
        clinic_room_uuid=None,
    )
    slots = [
        SimpleNamespace(id=11, time_range="14:00-14:10", is_booked=False),
        SimpleNamespace(id=12, time_range="15:00-15:10", is_booked=False),
        SimpleNamespace(id=13, time_range="15:10-15:20", is_booked=True),
    ]
    register = SimpleNamespace(id=21, patient_id=31)

    async def fake_list_scheduling_time_slots(session, scheduling_actual_id):
        assert scheduling_actual_id == 1
        return slots

    async def fake_find_active_register_for_slot(session, time_slot_id):
        return register if time_slot_id == 13 else None

    async def fake_upsert_schedule_disruption(session, target_register, target_actual, target_slot, message):
        assert target_register is register
        assert target_actual is actual
        assert "停诊" in message
        return True

    sync_calls = []

    async def fake_sync_time_slots(session, target_actual, is_new=False):
        sync_calls.append((target_actual.regist_quota, is_new))

    monkeypatch.setattr(patient_service, "_list_scheduling_time_slots", fake_list_scheduling_time_slots)
    monkeypatch.setattr(patient_service, "_find_active_register_for_slot", fake_find_active_register_for_slot)
    monkeypatch.setattr(patient_service, "_upsert_schedule_disruption", fake_upsert_schedule_disruption)
    monkeypatch.setattr(patient_service, "_sync_time_slots", fake_sync_time_slots)

    session = FakeSession()
    summary = await patient_service._cancel_scheduling_after_time(session, actual, "15:00")

    assert summary["status"] == "trimmed"
    assert summary["disruptions_created"] == 1
    assert actual.regist_quota == 2
    assert session.deleted == [slots[1]]
    assert sync_calls == [(2, False)]


@pytest.mark.asyncio
async def test_approve_and_reject_scheduling_application_persist_fields(monkeypatch):
    app_uuid = uuid.uuid4()
    employee_uuid = uuid.uuid4()
    app = SimpleNamespace(
        uuid=app_uuid,
        employee_uuid=employee_uuid,
        prompt="下周三下午停诊",
        status="pending",
        reject_reason=None,
        processed_at=None,
    )

    async def fake_ai_schedule(session, target_employee_uuid, prompt):
        assert target_employee_uuid == employee_uuid
        assert prompt == "下周三下午停诊"
        return {"actions_applied": 1}

    monkeypatch.setattr(patient_service, "ai_schedule", fake_ai_schedule)

    approve_session = FakeSession(execute_result=FakeExecuteResult(value=app))
    approved = await patient_service.approve_scheduling_application(approve_session, app_uuid)
    assert app.status == "approved"
    assert app.reject_reason is None
    assert app.processed_at is not None
    assert approved["status"] == "approved"
    assert approved["ai_result"] == {"actions_applied": 1}

    rejected_app = SimpleNamespace(
        uuid=app_uuid,
        employee_uuid=employee_uuid,
        prompt="下周三下午停诊",
        status="pending",
        reject_reason=None,
        processed_at=None,
    )
    reject_session = FakeSession(execute_result=FakeExecuteResult(value=rejected_app))
    rejected = await patient_service.reject_scheduling_application(reject_session, app_uuid, "诊室冲突")
    assert rejected_app.status == "rejected"
    assert rejected_app.reject_reason == "诊室冲突"
    assert rejected_app.processed_at is not None
    assert rejected["reason"] == "诊室冲突"


def test_serialize_scheduling_application_repairs_mojibake_prompt():
    expected_prompt = "\u8bf7\u5c062026-08-15\u4e0b\u5348\u95e8\u8bca\u9650\u989d\u8c03\u6574\u4e3a7\u4e2a"
    app = SimpleNamespace(
        uuid=uuid.uuid4(),
        employee_uuid=uuid.uuid4(),
        prompt=_mojibake(expected_prompt),
        status="approved",
        reject_reason=None,
        created_at=datetime(2026, 7, 11, 15, 9, 19),
        processed_at=None,
    )

    serialized = patient_service._serialize_scheduling_application(app)

    assert serialized["prompt"] == expected_prompt


@pytest.mark.asyncio
async def test_create_scheduling_application_normalizes_prompt_before_persisting(monkeypatch):
    employee_uuid = uuid.uuid4()
    expected_prompt = "\u7533\u8bf7\u5c062026-08-16\u4e0a\u5348\u95e8\u8bca\u6392\u73ed\u9650\u989d\u8c03\u6574\u4e3a6\u4eba\u3002"

    async def fake_get_employee(target_employee_uuid):
        assert str(target_employee_uuid) == str(employee_uuid)
        return {"uuid": str(employee_uuid), "realname": "doctor"}

    monkeypatch.setattr(patient_service.AuthClient, "get_employee", fake_get_employee)

    session = FakeSession()
    result = await patient_service.create_scheduling_application(session, employee_uuid, _mojibake(expected_prompt))

    assert result["status"] == "pending"
    assert session.added[0].prompt == expected_prompt


@pytest.mark.asyncio
async def test_processed_scheduling_application_cannot_be_reprocessed():
    app_uuid = uuid.uuid4()
    app = SimpleNamespace(
        uuid=app_uuid,
        employee_uuid=uuid.uuid4(),
        prompt="下周三下午停诊",
        status="approved",
        reject_reason=None,
        processed_at=datetime.now(),
    )
    session = FakeSession(execute_result=FakeExecuteResult(value=app))

    with pytest.raises(ValueError, match="已处理"):
        await patient_service.reject_scheduling_application(session, app_uuid, "重复审批")


@pytest.mark.asyncio
async def test_get_pending_scheduling_applications_rejects_unknown_status():
    with pytest.raises(ValueError, match="status"):
        await patient_service.get_pending_scheduling_applications(FakeSession(), status="invalid")


@pytest.mark.asyncio
async def test_ai_schedule_returns_action_summaries(monkeypatch):
    employee_uuid = uuid.uuid4()
    expected_prompt = "\u8bf7\u5e2e\u6211\u4e0b\u5468\u8c03\u73ed"

    async def fake_get_employee(target_employee_uuid):
        assert str(target_employee_uuid) == str(employee_uuid)
        return {"uuid": str(employee_uuid), "realname": "张医生"}

    async def fake_run_ai_scheduling(prompt, employee_uuid_str):
        assert prompt == expected_prompt
        return {
            "source": "rule",
            "data": {
                "actions": [
                    {"action_type": "modify", "target_date": "2026-07-13", "noon": "上午", "regist_quota": 12},
                    {"action_type": "add", "target_date": "2026-07-14", "noon": "下午", "regist_quota": 8},
                    {
                        "action_type": "cancel_after_time",
                        "target_date": "2026-07-15",
                        "noon": "下午",
                        "regist_quota": 0,
                        "time_threshold": "15:00",
                    },
                    {"action_type": "cancel", "target_date": "2026-07-16", "noon": "上午", "regist_quota": 0},
                ],
                "llm_text_rule": "测试规则",
            },
        }

    async def fake_apply_scheduling_actual_change(session, **kwargs):
        return {
            "action_type": kwargs["action_type"],
            "target_date": kwargs["schedule_date"].isoformat(),
            "noon": kwargs["noon"],
            "status": "updated",
            "changed": True,
            "disruptions_created": 1 if kwargs["action_type"] in {"cancel", "cancel_after_time"} else 0,
            "final_regist_quota": kwargs["regist_quota"],
            "registered_count": 0,
            "clinic_room_uuid": None,
        }

    monkeypatch.setattr(patient_service.AuthClient, "get_employee", fake_get_employee)
    monkeypatch.setattr(patient_service, "run_ai_scheduling", fake_run_ai_scheduling)
    monkeypatch.setattr(patient_service, "_apply_scheduling_actual_change", fake_apply_scheduling_actual_change)

    result = await patient_service.ai_schedule(FakeSession(), employee_uuid, _mojibake(expected_prompt))

    assert result["actions_applied"] == 4
    assert result["disruptions_created"] == 2
    assert [item["action_type"] for item in result["action_summaries"]] == [
        "modify",
        "add",
        "cancel_after_time",
        "cancel",
    ]
