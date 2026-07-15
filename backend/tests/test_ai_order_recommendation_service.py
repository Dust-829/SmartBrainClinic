from types import SimpleNamespace
from pathlib import Path

import pytest

from app.microservices.medical.services import ai_order_recommendation_service as recommendation_service


def test_medical_api_exposes_read_only_ai_order_recommendation_route():
    source = Path("app/microservices/medical/api/medical.py").read_text(encoding="utf-8")

    assert 'class AIOrderRecommendationRequest(BaseModel):' in source
    assert '@router.post("/orders/ai-recommendation", summary="AI 检查检验候选建议")' in source
    assert "recommend_order_candidates(session, data.register_uuid)" in source


class _ScalarResult:
    def __init__(self, values):
        self.values = values

    def scalar_one_or_none(self):
        return self.values[0] if self.values else None

    def scalars(self):
        return self

    def all(self):
        return self.values


class _ReadOnlySession:
    def __init__(self, results):
        self.results = iter(results)
        self.write_calls = []

    async def execute(self, _statement):
        return _ScalarResult(next(self.results))

    def add(self, value):
        self.write_calls.append(value)


@pytest.mark.asyncio
async def test_recommendation_service_requires_a_confirmed_record(monkeypatch):
    async def no_context(_register_uuid):
        return None

    monkeypatch.setattr(recommendation_service.PatientClient, "get_register_ai_context", no_context)
    session = _ReadOnlySession([[SimpleNamespace(is_doctor_confirmed=False)]])

    with pytest.raises(ValueError, match="确认病历"):
        await recommendation_service.recommend_order_candidates(session, "e47f3a0d-4f59-4699-902a-f24aac30f972")

    assert session.write_calls == []


@pytest.mark.asyncio
async def test_recommendation_service_uses_catalog_and_excludes_existing_orders(monkeypatch):
    async def triage_context(_register_uuid):
        return {"summary_text": "突发头痛伴眩晕", "messages": []}

    monkeypatch.setattr(recommendation_service.PatientClient, "get_register_ai_context", triage_context)
    record = SimpleNamespace(
        is_doctor_confirmed=True,
        readme="头痛",
        present="突发头痛伴眩晕",
        history="",
        physique="",
        diagnosis="急性神经系统症状待排",
        proposal="",
    )
    catalog = [
        SimpleNamespace(id=1, tech_code="DEMO_CT_HEAD", tech_name="头颅CT", tech_type="check", price="180.00"),
        SimpleNamespace(id=2, tech_code="DEMO_MRI_HEAD", tech_name="头颅MRI", tech_type="check", price="680.00"),
        SimpleNamespace(id=3, tech_code="DEMO_REHAB", tech_name="康复训练", tech_type="disposal", price="120.00"),
    ]
    session = _ReadOnlySession([[record], catalog, [1], []])

    result = await recommendation_service.recommend_order_candidates(session, "e47f3a0d-4f59-4699-902a-f24aac30f972")

    assert result["source"] == "record_catalog_rule"
    assert result["triage_context_used"] is True
    assert all(item["medical_technology_id"] != 1 for item in result["items"])
    assert all(item["type"] in {"check", "inspection"} for item in result["items"])
    assert session.write_calls == []
