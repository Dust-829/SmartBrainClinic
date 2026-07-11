from datetime import datetime
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.common.ai_audit import (
    export_ai_audit_logs_csv,
    get_ai_audit_log,
    query_ai_audit_logs,
    review_ai_audit_log,
)
from app.common.security import require_ai_audit_admin
from app.microservices.medical.services.ai_draft import run_ai_medical_draft
from app.microservices.patient.services.ai_triage import run_ai_triage
from app.microservices.pharmacy.services.ai_prescription import run_ai_prescription
from app.common.ai_embedding import get_embedding_result


class FakeMappingResult:
    def __init__(self, rows):
        self._rows = rows

    def mappings(self):
        return self

    def all(self):
        return self._rows


class FakeSession:
    def __init__(self, rows):
        self.rows = rows
        self.statements = []
        self.committed = False

    async def execute(self, statement, params=None):
        self.statements.append((str(statement), params or {}))
        return FakeMappingResult(self.rows)

    async def commit(self):
        self.committed = True


@pytest.mark.asyncio
async def test_query_ai_audit_logs_returns_summary_and_pagination():
    session = FakeSession(
        [
            {
                "uuid": "00000000-0000-0000-0000-000000000111",
                "module_name": "patient.triage",
                "source": "llm",
                "model": "gpt-test",
                "input_summary": "患者主诉头痛",
                "output_summary": "建议神经外科",
                "warnings": '["low_confidence"]',
                "validated": True,
                "validator_messages": '["ok"]',
                "latency_ms": 128,
                "context": '{"patient_uuid":"p-1"}',
                "review_status": "pending",
                "review_note": None,
                "reviewer": None,
                "reviewed_at": None,
                "created_at": datetime(2026, 7, 11, 9, 30, 0),
            }
        ]
    )

    result = await query_ai_audit_logs(
        session,
        module_name="patient.triage",
        source="llm",
        validated=True,
        created_from=datetime(2026, 7, 1, 0, 0, 0),
        created_to=datetime(2026, 7, 31, 23, 59, 59),
        limit=999,
        offset=-10,
    )

    assert result["items"][0]["uuid"] == "00000000-0000-0000-0000-000000000111"
    assert result["items"][0]["review_status"] == "pending"
    assert result["pagination"] == {"total": 1, "limit": 200, "offset": 0}
    assert result["summary"]["validated_count"] == 1
    assert result["summary"]["review_pending_count"] == 1


@pytest.mark.asyncio
async def test_get_ai_audit_log_returns_detail_fields():
    session = FakeSession(
        [
            {
                "uuid": "00000000-0000-0000-0000-000000000112",
                "module_name": "medical.draft",
                "source": "fallback",
                "model": "draft-engine",
                "input_summary": "[]",
                "output_summary": "未详细说明",
                "warnings": '["no_user_message"]',
                "validated": False,
                "validator_messages": '["doctor_review_needed"]',
                "latency_ms": 42,
                "context": '{"patient_uuid":"p-2"}',
                "review_status": "approved",
                "review_note": "人工确认通过",
                "reviewer": "ADMIN001",
                "reviewed_at": datetime(2026, 7, 11, 10, 0, 0),
                "created_at": datetime(2026, 7, 11, 9, 50, 0),
            }
        ]
    )

    result = await get_ai_audit_log(session, "00000000-0000-0000-0000-000000000112")

    assert result["review_status"] == "approved"
    assert result["review_note"] == "人工确认通过"
    assert result["reviewer"] == "ADMIN001"
    assert result["reviewed_at"] == "2026-07-11T10:00:00"


@pytest.mark.asyncio
async def test_review_ai_audit_log_updates_review_fields():
    session = FakeSession(
        [
            {
                "uuid": "00000000-0000-0000-0000-000000000113",
                "module_name": "pharmacy.prescription",
                "source": "llm",
                "model": "prescription-model",
                "input_summary": "头痛",
                "output_summary": "阿司匹林",
                "warnings": "[]",
                "validated": True,
                "validator_messages": "[]",
                "latency_ms": 99,
                "context": '{"register_uuid":"r-1"}',
                "review_status": "rejected",
                "review_note": "建议补充人工核对过敏史",
                "reviewer": "ADMIN002",
                "reviewed_at": datetime(2026, 7, 11, 11, 0, 0),
                "created_at": datetime(2026, 7, 11, 10, 30, 0),
            }
        ]
    )

    result = await review_ai_audit_log(
        session,
        "00000000-0000-0000-0000-000000000113",
        review_status="rejected",
        review_note="建议补充人工核对过敏史",
        reviewer="ADMIN002",
    )

    assert session.committed is True
    assert result["review_status"] == "rejected"
    assert result["review_note"] == "建议补充人工核对过敏史"
    assert result["reviewer"] == "ADMIN002"
    assert any("UPDATE ai_audit_log" in statement for statement, _ in session.statements)


@pytest.mark.asyncio
async def test_export_ai_audit_logs_csv_contains_review_columns():
    session = FakeSession(
        [
            {
                "uuid": "00000000-0000-0000-0000-000000000114",
                "module_name": "embedding",
                "source": "fallback",
                "model": "BAAI/bge-m3",
                "input_summary": "脑卒中相关文本",
                "output_summary": '{"dimension": 0}',
                "warnings": "[]",
                "validated": False,
                "validator_messages": '["embedding_missing"]',
                "latency_ms": 12,
                "context": '{"scene":"search"}',
                "review_status": "pending",
                "review_note": None,
                "reviewer": None,
                "reviewed_at": None,
                "created_at": datetime(2026, 7, 11, 12, 0, 0),
            }
        ]
    )

    csv_text = await export_ai_audit_logs_csv(session, module_name="embedding")

    assert "review_status,reviewer,reviewed_at,review_note" in csv_text
    assert "00000000-0000-0000-0000-000000000114" in csv_text
    assert "pending" in csv_text


def test_review_migration_adds_expected_columns():
    migration = open("migrations/20260711_01_add_ai_audit_review_fields.sql", encoding="utf-8").read()

    assert "review_status" in migration
    assert "review_note" in migration
    assert "reviewer" in migration
    assert "reviewed_at" in migration
    assert "DEFAULT 'pending'" in migration


@pytest.mark.asyncio
async def test_require_ai_audit_admin_rejects_when_token_missing(monkeypatch):
    monkeypatch.delenv("AI_AUDIT_ADMIN_TOKEN", raising=False)
    monkeypatch.delenv("ADMIN_API_TOKEN", raising=False)

    with pytest.raises(HTTPException) as exc_info:
        await require_ai_audit_admin()

    assert exc_info.value.status_code == 403
    assert exc_info.value.detail == "AI audit admin token is not configured"


@pytest.mark.asyncio
async def test_ai_triage_records_audit_without_api_key(monkeypatch):
    captured = {}

    async def fake_record_ai_audit(**kwargs):
        captured.update(kwargs)

    monkeypatch.setattr("app.microservices.patient.services.ai_triage.record_ai_audit", fake_record_ai_audit)
    result = await run_ai_triage(
        messages=[{"role": "user", "content": "我头痛两天了"}],
        api_key="",
        api_base="",
        model="",
    )

    assert result["source"] in {"llm", "rule", "fallback", "mock"}
    assert captured["module_name"] == "patient.triage"


@pytest.mark.asyncio
async def test_ai_medical_draft_records_audit(monkeypatch):
    captured = {}

    async def fake_record_ai_audit(**kwargs):
        captured.update(kwargs)

    monkeypatch.setattr("app.microservices.medical.services.ai_draft.record_ai_audit", fake_record_ai_audit)
    result = await run_ai_medical_draft("[]", api_key="", api_base="", model="")

    assert result["source"] == "fallback"
    assert captured["module_name"] == "medical.draft"


@pytest.mark.asyncio
async def test_ai_prescription_records_audit(monkeypatch):
    captured = {}

    async def fake_record_ai_audit(**kwargs):
        captured.update(kwargs)

    monkeypatch.setattr("app.microservices.pharmacy.services.ai_prescription.record_ai_audit", fake_record_ai_audit)
    result = await run_ai_prescription(
        medical_record={
            "diagnosis": "脑卒中",
            "readme": "头痛",
            "present": "头痛两天",
            "history": "",
            "allergy": "",
        },
        available_drugs=[{"id": 1, "drug_name": "阿司匹林", "stock": 10}],
        api_key="",
        api_base="",
        model="",
    )

    assert result["source"] in {"llm", "rule"}
    assert captured["module_name"] == "pharmacy.prescription"


@pytest.mark.asyncio
async def test_embedding_result_records_audit(monkeypatch):
    captured = {}

    async def fake_record_ai_audit(**kwargs):
        captured.update(kwargs)

    async def fake_get_embedding(*args, **kwargs):
        return None

    monkeypatch.setattr("app.common.ai_embedding.record_ai_audit", fake_record_ai_audit)
    monkeypatch.setattr("app.common.ai_embedding.get_embedding", fake_get_embedding)
    result = await get_embedding_result("脑卒中相关文本", api_key="", api_base="", model="")

    assert result["source"] == "fallback"
    assert captured["module_name"] == "embedding"
