import json
import os
import subprocess
import sys
import textwrap
import uuid
from pathlib import Path

import pytest

from app.common.clients import BaseClient, PatientClient
from app.microservices.medical.services.agent import tools as agent_tools


def run_isolated_python(code: str) -> dict:
    env = {**os.environ, "PYTHONPATH": "."}
    result = subprocess.run(
        [sys.executable, "-c", textwrap.dedent(code)],
        cwd=Path.cwd(),
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


class FakeRowsResult:
    def __init__(self, rows):
        self._rows = rows

    def all(self):
        return self._rows


def test_doctor_queue_filters_by_schedule_date_not_register_creation_date():
    source = Path("app/microservices/patient/services/patient_service.py").read_text(encoding="utf-8")

    assert "select(Register, Patient, SchedulingActual)" in source
    assert ".join(SchedulingActual, Register.scheduling_actual_id == SchedulingActual.id)" in source
    assert "SchedulingActual.schedule_date == date.today()" in source
    assert "func.date(Register.visit_date)" not in source


@pytest.mark.asyncio
async def test_submit_scheduling_application_uses_required_post(monkeypatch):
    captured = {}

    def fake_get_url(service_name):
        assert service_name == "patient"
        return "http://patient-service/api/v1/patient"

    async def fake_post_required(url, json_data=None):
        captured["url"] = url
        captured["json_data"] = json_data
        return {"uuid": str(uuid.uuid4()), "status": "pending"}

    monkeypatch.setattr(BaseClient, "get_url", fake_get_url)
    monkeypatch.setattr(BaseClient, "post_required", fake_post_required)

    result = await PatientClient.submit_scheduling_application(
        "00000000-0000-0000-0000-000000000001",
        "cancel tomorrow morning",
    )

    assert result["status"] == "pending"
    assert captured == {
        "url": "http://patient-service/api/v1/patient/scheduling-applications",
        "json_data": {
            "employee_uuid": "00000000-0000-0000-0000-000000000001",
            "prompt": "cancel tomorrow morning",
        },
    }


@pytest.mark.asyncio
async def test_scheduling_tool_reports_downstream_failure(monkeypatch):
    async def fake_submit_scheduling_application(employee_uuid, prompt):
        raise ValueError("downstream unavailable")

    monkeypatch.setattr(
        agent_tools.PatientClient,
        "submit_scheduling_application",
        fake_submit_scheduling_application,
    )
    submit_tool = next(
        tool for tool in agent_tools.create_agent_tools(
            None,
            employee_uuid=str(uuid.uuid4()),
            confirm_action=True,
        )
        if tool.name == "submit_scheduling_application"
    )

    result = await submit_tool.ainvoke({"prompt": "cancel tomorrow morning"})

    assert "downstream unavailable" in result
    assert "成功" not in result


@pytest.mark.asyncio
async def test_scheduling_tool_requires_confirmation_before_side_effect(monkeypatch):
    called = False

    async def fake_submit_scheduling_application(employee_uuid, prompt):
        nonlocal called
        called = True
        return {"uuid": str(uuid.uuid4()), "status": "pending"}

    monkeypatch.setattr(
        agent_tools.PatientClient,
        "submit_scheduling_application",
        fake_submit_scheduling_application,
    )
    submit_tool = next(
        tool for tool in agent_tools.create_agent_tools(
            None,
            employee_uuid=str(uuid.uuid4()),
            confirm_action=False,
        )
        if tool.name == "submit_scheduling_application"
    )

    result = await submit_tool.ainvoke({"prompt": "下周一上午停诊"})

    assert called is False
    assert "待确认排班申请" in result
    assert "尚未提交" in result


@pytest.mark.asyncio
async def test_scheduling_tool_reports_deduplicated_confirmed_application(monkeypatch):
    app_uuid = str(uuid.uuid4())

    async def fake_submit_scheduling_application(employee_uuid, prompt):
        return {"uuid": app_uuid, "status": "pending", "deduplicated": True}

    monkeypatch.setattr(
        agent_tools.PatientClient,
        "submit_scheduling_application",
        fake_submit_scheduling_application,
    )
    submit_tool = next(
        tool for tool in agent_tools.create_agent_tools(
            None,
            employee_uuid=str(uuid.uuid4()),
            confirm_action=True,
        )
        if tool.name == "submit_scheduling_application"
    )

    result = await submit_tool.ainvoke({"prompt": "   下周一上午停诊   "})

    assert app_uuid in result
    assert "复用原申请" in result
    assert "未重复创建" in result


@pytest.mark.asyncio
async def test_similar_record_matches_return_scores_and_apply_threshold(monkeypatch):
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from types import SimpleNamespace
        from app.microservices.medical.services import medical_service

        async def fake_get_embedding(*args, **kwargs):
            return [0.03125] * 1024

        class FakeRowsResult:
            def __init__(self, rows):
                self._rows = rows
            def all(self):
                return self._rows

        class SimilarCaseSession:
            async def execute(self, statement):
                record_a = SimpleNamespace(
                    uuid=uuid.UUID("10000000-0000-0000-0000-000000000001"),
                    register_uuid=uuid.UUID("20000000-0000-0000-0000-000000000001"),
                    readme="头痛",
                    present="头痛两天",
                    diagnosis="紧张性头痛",
                    cure="休息观察",
                )
                record_b = SimpleNamespace(
                    uuid=uuid.UUID("10000000-0000-0000-0000-000000000002"),
                    register_uuid=uuid.UUID("20000000-0000-0000-0000-000000000002"),
                    readme="腹痛",
                    present="腹痛一周",
                    diagnosis="腹痛待查",
                    cure="随诊",
                )
                return FakeRowsResult([(record_a, 0.12), (record_b, 0.82)])

        async def main():
            medical_service.get_embedding = fake_get_embedding
            matches = await medical_service.search_similar_record_matches(
                SimilarCaseSession(),
                "头痛两天",
                top_k=5,
                min_similarity_score=35.0,
            )
            print(json.dumps({
                "count": len(matches),
                "uuid": str(matches[0].record.uuid),
                "similarity_score": matches[0].similarity_score,
                "cosine_distance": matches[0].cosine_distance,
            }))

        asyncio.run(main())
        """
    )

    assert data == {
        "count": 1,
        "uuid": "10000000-0000-0000-0000-000000000001",
        "similarity_score": 88.0,
        "cosine_distance": 0.12,
    }


@pytest.mark.asyncio
async def test_search_similar_cases_tool_includes_evidence_quality(monkeypatch):
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from types import SimpleNamespace
        from app.microservices.medical.services import medical_service
        from app.microservices.medical.services.agent import tools as agent_tools

        record = SimpleNamespace(
            uuid=uuid.UUID("10000000-0000-0000-0000-000000000003"),
            readme="心悸",
            present="活动后心悸",
            diagnosis="心悸待查",
            cure="门诊随诊",
        )

        async def fake_search_similar_record_matches(session, query, top_k=5):
            return [
                medical_service.SimilarRecordMatch(
                    record=record,
                    similarity_score=91.5,
                    cosine_distance=0.085,
                )
            ]

        async def main():
            medical_service.search_similar_record_matches = fake_search_similar_record_matches
            similar_tool = next(
                tool for tool in agent_tools.create_agent_tools(None)
                if tool.name == "search_similar_cases"
            )
            result = await similar_tool.ainvoke({"query": "活动后心悸"})
            print(json.dumps({"result": result}, ensure_ascii=False))

        asyncio.run(main())
        """
    )
    result = data["result"]

    assert "10000000-0000-0000-0000-000000000003" in result
    assert "相似度: 91.5" in result
    assert "仅供医生参考" in result


def test_extract_agent_tool_context_captures_calls_and_results():
    context = run_isolated_python(
        """
        import json
        from langchain_core.messages import AIMessage, ToolMessage
        from app.microservices.medical.services.agent import graph as agent_graph

        messages = [
            AIMessage(
                content="",
                tool_calls=[
                    {
                        "id": "call-1",
                        "name": "get_doctor_queue",
                        "args": {},
                    }
                ],
            ),
            ToolMessage(
                content="今天暂无候诊患者。",
                name="get_doctor_queue",
                tool_call_id="call-1",
            ),
        ]
        print(json.dumps(agent_graph._extract_agent_tool_context(messages), ensure_ascii=False))
        """
    )

    assert context["message_count"] == 2
    assert context["tool_calls"] == [
        {"id": "call-1", "name": "get_doctor_queue", "args": {}}
    ]
    assert context["tool_results"][0]["name"] == "get_doctor_queue"
    assert context["tool_results"][0]["content"] == "今天暂无候诊患者。"


@pytest.mark.asyncio
async def test_record_agent_audit_includes_tool_context(monkeypatch):
    captured = run_isolated_python(
        """
        import asyncio
        import json
        from langchain_core.messages import AIMessage, ToolMessage
        from app.common.ai_audit import start_ai_timer
        from app.microservices.medical.services.agent import graph as agent_graph

        captured = {}

        async def fake_record_ai_audit(**kwargs):
            captured.update(kwargs)

        async def main():
            agent_graph.record_ai_audit = fake_record_ai_audit
            messages = [
                AIMessage(
                    content="",
                    tool_calls=[
                        {
                            "id": "call-2",
                            "name": "search_similar_cases",
                            "args": {"query": "心悸"},
                        }
                    ],
                ),
                ToolMessage(
                    content="【相似病例 1 | 病历UUID: 10000000-0000-0000-0000-000000000003 | 相似度: 91.5】",
                    name="search_similar_cases",
                    tool_call_id="call-2",
                ),
            ]
            await agent_graph._record_agent_audit(
                question="帮我找相似病例",
                answer="已找到相似病例。",
                patient_uuid="patient-1",
                employee_uuid="doctor-1",
                top_k=3,
                confirm_action=True,
                messages=messages,
                started_at=start_ai_timer(),
                validated=True,
            )
            print(json.dumps(captured, ensure_ascii=False, default=str))

        asyncio.run(main())
        """
    )

    assert captured["module_name"] == "medical.agent"
    assert captured["result"]["source"] == "llm"
    assert captured["result"]["validated"] is True
    assert captured["context"]["confirm_action"] is True
    assert captured["context"]["tool_calls"][0]["name"] == "search_similar_cases"
    assert captured["context"]["tool_results"][0]["name"] == "search_similar_cases"
