from types import SimpleNamespace
from datetime import datetime, timedelta

import pytest

from app.common.enums import BillState
from app.common.idempotency import has_active_processing_request
from app.microservices.billing.services import billing_service


class DummySession:
    def __init__(self):
        self.commit_count = 0

    async def commit(self):
        self.commit_count += 1


class FakeMappingResult:
    def __init__(self, rows):
        self.rows = rows

    def mappings(self):
        return self

    def all(self):
        return self.rows


class FakeIdempotencySession:
    def __init__(self, rows):
        self.rows = rows
        self.params = None

    async def execute(self, statement, params):
        self.params = params
        return FakeMappingResult(self.rows)


@pytest.mark.asyncio
async def test_refunded_bill_rejects_duplicate_refund(monkeypatch):
    called = False

    async def fake_has_active_processing_request(*args, **kwargs):
        nonlocal called
        called = True
        return False

    monkeypatch.setattr(
        billing_service,
        "has_active_processing_request",
        fake_has_active_processing_request,
    )
    bill = SimpleNamespace(bill_state=BillState.REFUNDED.value)
    idem = SimpleNamespace(key="refund-key-1")

    with pytest.raises(ValueError, match="已经是已退费"):
        await billing_service._ensure_refund_request_can_continue(
            DummySession(),
            bill,
            "FP001",
            idem,
        )

    assert called is False


@pytest.mark.asyncio
async def test_refunding_bill_rejects_different_active_idempotency_key(monkeypatch):
    captured = {}

    async def fake_has_active_processing_request(*args, **kwargs):
        captured.update(kwargs)
        return True

    monkeypatch.setattr(
        billing_service,
        "has_active_processing_request",
        fake_has_active_processing_request,
    )
    bill = SimpleNamespace(bill_state=BillState.REFUNDING.value)
    idem = SimpleNamespace(key="refund-key-2")

    with pytest.raises(ValueError, match="正在退费中"):
        await billing_service._ensure_refund_request_can_continue(
            DummySession(),
            bill,
            "FP002",
            idem,
        )

    assert captured == {
        "scope": "billing.refund_bill",
        "request_payload": {"bill_code": "FP002"},
        "exclude_idempotency_key": "refund-key-2",
    }


@pytest.mark.asyncio
async def test_refunding_bill_can_resume_when_no_other_active_request(monkeypatch):
    captured = {}

    async def fake_has_active_processing_request(*args, **kwargs):
        captured.update(kwargs)
        return False

    monkeypatch.setattr(
        billing_service,
        "has_active_processing_request",
        fake_has_active_processing_request,
    )
    bill = SimpleNamespace(bill_state=BillState.REFUNDING.value)
    idem = SimpleNamespace(key="refund-key-3")

    await billing_service._ensure_refund_request_can_continue(
        DummySession(),
        bill,
        "FP003",
        idem,
    )

    assert captured["exclude_idempotency_key"] == "refund-key-3"


@pytest.mark.asyncio
async def test_paid_bill_does_not_query_processing_idempotency(monkeypatch):
    called = False

    async def fake_has_active_processing_request(*args, **kwargs):
        nonlocal called
        called = True
        return False

    monkeypatch.setattr(
        billing_service,
        "has_active_processing_request",
        fake_has_active_processing_request,
    )
    bill = SimpleNamespace(bill_state=BillState.PAID.value)
    idem = SimpleNamespace(key="refund-key-4")

    await billing_service._ensure_refund_request_can_continue(
        DummySession(),
        bill,
        "FP004",
        idem,
    )

    assert called is False


@pytest.mark.asyncio
async def test_active_processing_request_detects_non_stale_other_key():
    session = FakeIdempotencySession(
        [{"updated_at": datetime.now() - timedelta(seconds=30)}]
    )

    result = await has_active_processing_request(
        session,
        scope="billing.refund_bill",
        request_payload={"bill_code": "FP009"},
        exclude_idempotency_key="current-key",
        processing_timeout_seconds=300,
    )

    assert result is True
    assert session.params["exclude_idempotency_key"] == "current-key"


@pytest.mark.asyncio
async def test_active_processing_request_ignores_stale_other_key():
    session = FakeIdempotencySession(
        [{"updated_at": datetime.now() - timedelta(seconds=600)}]
    )

    result = await has_active_processing_request(
        session,
        scope="billing.refund_bill",
        request_payload={"bill_code": "FP010"},
        exclude_idempotency_key="current-key",
        processing_timeout_seconds=300,
    )

    assert result is False


@pytest.mark.asyncio
async def test_refund_step_skips_already_succeeded_step(monkeypatch):
    recorded = []
    operation_called = False

    async def fake_get_refund_step_status(session, bill_code, step_name):
        return "succeeded"

    async def fake_record_refund_step(*args, **kwargs):
        recorded.append(kwargs)

    async def fake_operation():
        nonlocal operation_called
        operation_called = True
        return {"ok": True}

    monkeypatch.setattr(
        billing_service,
        "_get_refund_step_status",
        fake_get_refund_step_status,
    )
    monkeypatch.setattr(
        billing_service,
        "_record_refund_step",
        fake_record_refund_step,
    )
    session = DummySession()

    result = await billing_service._run_refund_step(
        session,
        bill_code="FP005",
        step_name="medical",
        request_payload={"items": []},
        operation=fake_operation,
    )

    assert result == {"step_name": "medical", "status": "succeeded", "skipped": True}
    assert operation_called is False
    assert recorded == []
    assert session.commit_count == 0


@pytest.mark.asyncio
async def test_refund_step_records_pending_and_success(monkeypatch):
    recorded = []

    async def fake_get_refund_step_status(session, bill_code, step_name):
        return None

    async def fake_record_refund_step(*args, **kwargs):
        recorded.append(kwargs)

    async def fake_operation():
        return {"refunded_items": [{"id": "item-1"}]}

    monkeypatch.setattr(
        billing_service,
        "_get_refund_step_status",
        fake_get_refund_step_status,
    )
    monkeypatch.setattr(
        billing_service,
        "_record_refund_step",
        fake_record_refund_step,
    )
    session = DummySession()

    result = await billing_service._run_refund_step(
        session,
        bill_code="FP006",
        step_name="medical",
        request_payload={"items": [{"id": "item-1"}]},
        operation=fake_operation,
    )

    assert result == {"refunded_items": [{"id": "item-1"}]}
    assert [item["status"] for item in recorded] == ["pending", "succeeded"]
    assert recorded[1]["response_payload"] == {"refunded_items": [{"id": "item-1"}]}
    assert session.commit_count == 2


@pytest.mark.asyncio
async def test_refund_step_records_failure(monkeypatch):
    recorded = []

    async def fake_get_refund_step_status(session, bill_code, step_name):
        return None

    async def fake_record_refund_step(*args, **kwargs):
        recorded.append(kwargs)

    async def fake_operation():
        raise RuntimeError("pharmacy timeout")

    monkeypatch.setattr(
        billing_service,
        "_get_refund_step_status",
        fake_get_refund_step_status,
    )
    monkeypatch.setattr(
        billing_service,
        "_record_refund_step",
        fake_record_refund_step,
    )
    session = DummySession()

    with pytest.raises(RuntimeError, match="pharmacy timeout"):
        await billing_service._run_refund_step(
            session,
            bill_code="FP007",
            step_name="pharmacy",
            request_payload={"item_uuids": ["drug-item-1"]},
            operation=fake_operation,
        )

    assert [item["status"] for item in recorded] == ["pending", "failed"]
    assert recorded[1]["error_message"] == "pharmacy timeout"
    assert session.commit_count == 2


@pytest.mark.asyncio
async def test_refund_downstream_items_records_partial_failure(monkeypatch):
    steps = []

    class Detail:
        def __init__(self, item_type, item_source_id):
            self.item_type = item_type
            self.item_source_id = item_source_id

    async def fake_run_refund_step(session, *, bill_code, step_name, request_payload, operation):
        steps.append((bill_code, step_name, request_payload))
        if step_name == "pharmacy":
            raise RuntimeError("pharmacy unavailable")
        return {"ok": True}

    monkeypatch.setattr(
        billing_service,
        "_run_refund_step",
        fake_run_refund_step,
    )

    with pytest.raises(RuntimeError, match="pharmacy unavailable"):
        await billing_service._refund_downstream_items(
            DummySession(),
            "FP008",
            [
                Detail("检查", "check-1"),
                Detail("药品", "drug-item-1"),
            ],
        )

    assert steps == [
        ("FP008", "medical", {"items": [{"type": "检查", "id": "check-1"}]}),
        ("FP008", "pharmacy", {"item_uuids": ["drug-item-1"]}),
    ]
