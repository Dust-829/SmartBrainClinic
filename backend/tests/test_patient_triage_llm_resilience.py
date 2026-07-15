import sys
from pathlib import Path

import httpx
import pytest


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.common.ai_client import AIClient
from app.microservices.patient.services.ai_triage import _mock_multi_turn_triage, _should_use_rule_fallback


@pytest.mark.asyncio
async def test_ai_client_retries_once_on_read_timeout(monkeypatch):
    attempts = {"count": 0}

    class FakeResponse:
        status_code = 200

        @staticmethod
        def json():
            return {"choices": [{"message": {"content": '{"ok": true}'}}]}

    class FakeAsyncClient:
        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return None

        async def post(self, *args, **kwargs):
            attempts["count"] += 1
            if attempts["count"] == 1:
                raise httpx.ReadTimeout("timed out")
            return FakeResponse()

    monkeypatch.setattr(httpx, "AsyncClient", FakeAsyncClient)

    client = AIClient(api_key="test-key", api_base="https://example.com/v1")
    result = await client.chat_json(
        model="test-model",
        messages=[{"role": "user", "content": "hello"}],
        timeout=1.0,
        retries=1,
    )

    assert result == {"ok": True}
    assert attempts["count"] == 2


def test_triage_uses_rule_fallback_for_department_selection_query_when_llm_is_generic():
    messages = [{"role": "user", "content": "我有高血压应该挂什么科室的号"}]
    fallback_candidate = _mock_multi_turn_triage(messages)
    llm_data = {
        "reply": "您好，我是医院分诊助手。请问您哪里不舒服？请描述您的症状，例如疼痛部位、持续时间、伴随症状等。",
        "dept_determined": False,
        "recommended_dept_code": None,
        "symptom_summary": "",
        "gender_preference": "不限",
    }

    assert fallback_candidate["dept_determined"] is True
    assert fallback_candidate["recommended_dept_code"] == "XNK"
    assert _should_use_rule_fallback(llm_data, fallback_candidate, messages) is True
