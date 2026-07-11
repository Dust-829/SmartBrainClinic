import json
import os
import subprocess
import sys
import textwrap
from pathlib import Path


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


def test_check_detail_api_exposes_result_fields():
    source = Path("app/microservices/medical/api/medical.py").read_text(encoding="utf-8")

    assert '"check_result": check.check_result' in source
    assert '"image_path": check.image_path' in source
    assert '"ai_tumor_prob": str(check.ai_tumor_prob)' in source


def test_medical_api_exposes_tech_list_and_register_request_routes():
    source = Path("app/microservices/medical/api/medical.py").read_text(encoding="utf-8")

    assert '@router.get("/tech", summary="获取医技项目列表")' in source
    assert '@router.get("/requests/register/{register_uuid}", summary="按挂号单获取检查检验处置队列")' in source


def test_medical_api_exposes_unified_order_signing_route():
    source = Path("app/microservices/medical/api/medical.py").read_text(encoding="utf-8")

    assert 'class OrderSignRequest(BaseModel):' in source
    assert '@router.post("/orders/sign", summary="统一签署检查检验处置医嘱")' in source


def test_medical_order_rejects_unpaid_register():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from app.common.enums import VisitState
        from app.microservices.medical.services import medical_service

        async def fake_get_register(register_uuid):
            return {"uuid": str(register_uuid), "visit_state": int(VisitState.UNPAID)}

        async def main():
            medical_service.PatientClient.get_register = fake_get_register
            try:
                await medical_service._ensure_register_allows_medical_order(uuid.uuid4())
            except ValueError as exc:
                print(json.dumps({"error": str(exc)}, ensure_ascii=False))
                return
            raise AssertionError("unpaid register should be rejected")

        asyncio.run(main())
        """
    )

    assert "待支付" in data["error"]


def test_medical_order_allows_active_register():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from app.common.enums import VisitState
        from app.microservices.medical.services import medical_service

        register_uuid = uuid.uuid4()

        async def fake_get_register(value):
            return {"uuid": str(value), "visit_state": int(VisitState.RECEPTION)}

        async def main():
            medical_service.PatientClient.get_register = fake_get_register
            result = await medical_service._ensure_register_allows_medical_order(register_uuid)
            print(json.dumps(result))

        asyncio.run(main())
        """
    )

    assert data["visit_state"] == 2


def test_input_inspection_and_disposal_result_execute_paid_requests():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from types import SimpleNamespace
        from app.common.enums import DisposalState, InspectionState
        from app.microservices.medical.services import medical_service

        class FakeScalarResult:
            def __init__(self, row):
                self.row = row
            def scalar_one_or_none(self):
                return self.row

        class FakeSession:
            def __init__(self, row):
                self.row = row
                self.added = []
                self.flushed = False
            async def execute(self, statement):
                return FakeScalarResult(self.row)
            def add(self, row):
                self.added.append(row)
            async def flush(self):
                self.flushed = True

        async def main():
            employee_uuid = uuid.uuid4()
            inspection = SimpleNamespace(
                id=1,
                inspection_state=InspectionState.PAID.value,
                test_results=None,
                input_employee_uuid=None,
                inspection_time=None,
            )
            inspection_session = FakeSession(inspection)
            inspection_result = await medical_service.input_inspection_result(
                inspection_session,
                str(uuid.uuid4()),
                employee_uuid,
                {"WBC": "6.0"},
            )

            disposal = SimpleNamespace(
                id=2,
                disposal_state=DisposalState.PAID.value,
                disposal_result=None,
                disposal_time=None,
            )
            disposal_session = FakeSession(disposal)
            disposal_result = await medical_service.input_disposal_result(
                disposal_session,
                str(uuid.uuid4()),
                "完成雾化处置，患者无不适",
            )

            print(json.dumps({
                "inspection_state": inspection_result["inspection_state"],
                "inspection_results": inspection_result["test_results"],
                "inspection_employee": inspection_result["input_employee_uuid"],
                "inspection_flushed": inspection_session.flushed,
                "disposal_state": disposal_result["disposal_state"],
                "disposal_result": disposal_result["disposal_result"],
                "disposal_flushed": disposal_session.flushed,
            }, ensure_ascii=False))

        asyncio.run(main())
        """
    )

    assert data["inspection_state"] == "已执行"
    assert data["inspection_results"] == {"WBC": "6.0"}
    assert data["inspection_employee"]
    assert data["inspection_flushed"] is True
    assert data["disposal_state"] == "已执行"
    assert data["disposal_result"] == "完成雾化处置，患者无不适"
    assert data["disposal_flushed"] is True


def test_list_requests_by_register_returns_grouped_queue_payload():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from decimal import Decimal
        from datetime import datetime
        from types import SimpleNamespace
        from app.microservices.medical.services import medical_service

        class FakeScalars:
            def __init__(self, rows):
                self._rows = rows
            def all(self):
                return self._rows

        class FakeExecuteResult:
            def __init__(self, rows):
                self._rows = rows
            def scalars(self):
                return FakeScalars(self._rows)

        class FakeSession:
            def __init__(self, rows):
                self._rows = list(rows)
            async def execute(self, statement):
                return FakeExecuteResult(self._rows.pop(0))

        async def main():
            register_uuid = uuid.UUID("90000000-0000-0000-0000-000000000601")
            tech_check = SimpleNamespace(
                id=101,
                uuid=uuid.UUID("90000000-0000-0000-0000-000000000701"),
                tech_code="DEMO_CT_HEAD",
                tech_name="头颅CT",
                tech_type="check",
                price=Decimal("180.00"),
            )
            tech_inspection = SimpleNamespace(
                id=102,
                uuid=uuid.UUID("90000000-0000-0000-0000-000000000703"),
                tech_code="DEMO_BLOOD",
                tech_name="血常规",
                tech_type="inspection",
                price=Decimal("38.00"),
            )
            check = SimpleNamespace(
                id=1,
                uuid=uuid.UUID("91000000-0000-0000-0000-000000000001"),
                register_uuid=register_uuid,
                medical_technology_id=101,
                creation_time=datetime(2026, 7, 7, 9, 0, 0),
                check_state="未缴费",
                check_info="排查颅内病变",
                check_position="头部",
                check_result=None,
            )
            inspection = SimpleNamespace(
                id=2,
                uuid=uuid.UUID("91000000-0000-0000-0000-000000000002"),
                register_uuid=register_uuid,
                medical_technology_id=102,
                creation_time=datetime(2026, 7, 7, 9, 5, 0),
                inspection_state="已缴费",
                test_results=None,
            )
            session = FakeSession([
                [check],
                [inspection],
                [],
                [tech_check, tech_inspection],
            ])
            result = await medical_service.list_requests_by_register(session, register_uuid)
            print(json.dumps(result, ensure_ascii=False))

        asyncio.run(main())
        """
    )

    assert data["checks"][0]["tech_name"] == "头颅CT"
    assert data["checks"][0]["state"] == "未缴费"
    assert data["checks"][0]["check_position"] == "头部"
    assert data["inspections"][0]["tech_name"] == "血常规"
    assert data["inspections"][0]["state"] == "已缴费"
    assert data["disposals"] == []


def test_unified_order_signing_creates_mixed_requests_and_dispatches_checks_after_flush():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from types import SimpleNamespace
        from app.common.enums import VisitState
        from app.microservices.medical.services import medical_service

        class FakeScalars:
            def __init__(self, rows):
                self.rows = rows
            def all(self):
                return self.rows

        class FakeResult:
            def __init__(self, rows):
                self.rows = rows
            def scalars(self):
                return FakeScalars(self.rows)

        class FakeSession:
            def __init__(self, technologies):
                self.technologies = technologies
                self.added = []
                self.flushed = False
                self.rolled_back = False
            async def execute(self, statement):
                return FakeResult(self.technologies)
            def add(self, value):
                self.added.append(value)
            async def flush(self):
                self.flushed = True
            async def rollback(self):
                self.rolled_back = True

        class FakeTasks:
            def __init__(self):
                self.calls = []
            def add_task(self, task, *args):
                self.calls.append((task.__name__, args))

        async def fake_get_register(register_uuid):
            return {"uuid": str(register_uuid), "visit_state": int(VisitState.RECEPTION)}

        async def main():
            medical_service.PatientClient.get_register = fake_get_register
            technologies = [
                SimpleNamespace(id=101, tech_name="头颅CT", tech_type="check"),
                SimpleNamespace(id=102, tech_name="血常规", tech_type="inspection"),
                SimpleNamespace(id=103, tech_name="门诊观察", tech_type="disposal"),
            ]
            session = FakeSession(technologies)
            tasks = FakeTasks()
            items = await medical_service.create_signed_orders(
                session,
                uuid.uuid4(),
                [
                    {"type": "check", "medical_technology_id": 101, "check_position": "头部", "check_info": "排查占位"},
                    {"type": "inspection", "medical_technology_id": 102},
                    {"type": "disposal", "medical_technology_id": 103},
                ],
                tasks,
            )
            print(json.dumps({
                "types": [item["type"] for item in items],
                "states": [item["state"] for item in items],
                "created": [type(item).__name__ for item in session.added],
                "flushed": session.flushed,
                "task_names": [call[0] for call in tasks.calls],
            }, ensure_ascii=False))

        asyncio.run(main())
        """
    )

    assert data["types"] == ["check", "inspection", "disposal"]
    assert data["states"] == ["未缴费", "未缴费", "未缴费"]
    assert data["created"] == ["CheckRequest", "InspectionRequest", "DisposalRequest"]
    assert data["flushed"] is True
    assert data["task_names"] == ["assign_tech_to_check_task"]


def test_unified_order_signing_rejects_mismatched_type_before_creating_requests():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from types import SimpleNamespace
        from app.common.enums import VisitState
        from app.microservices.medical.services import medical_service

        class FakeScalars:
            def all(self):
                return [SimpleNamespace(id=101, tech_name="头颅CT", tech_type="check")]

        class FakeResult:
            def scalars(self):
                return FakeScalars()

        class FakeSession:
            def __init__(self):
                self.added = []
                self.flushed = False
            async def execute(self, statement):
                return FakeResult()
            def add(self, value):
                self.added.append(value)
            async def flush(self):
                self.flushed = True

        async def fake_get_register(register_uuid):
            return {"uuid": str(register_uuid), "visit_state": int(VisitState.RECEPTION)}

        async def main():
            medical_service.PatientClient.get_register = fake_get_register
            session = FakeSession()
            try:
                await medical_service.create_signed_orders(
                    session,
                    uuid.uuid4(),
                    [{"type": "inspection", "medical_technology_id": 101}],
                )
            except ValueError as exc:
                print(json.dumps({
                    "error": str(exc),
                    "created": len(session.added),
                    "flushed": session.flushed,
                }, ensure_ascii=False))
                return
            raise AssertionError("mismatched type should be rejected")

        asyncio.run(main())
        """
    )

    assert "类型不匹配" in data["error"]
    assert data["created"] == 0
    assert data["flushed"] is False


def test_unified_order_signing_rolls_back_when_flush_fails():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from types import SimpleNamespace
        from app.common.enums import VisitState
        from app.microservices.medical.services import medical_service

        class FakeScalars:
            def all(self):
                return [SimpleNamespace(id=101, tech_name="头颅CT", tech_type="check")]

        class FakeResult:
            def scalars(self):
                return FakeScalars()

        class FakeSession:
            def __init__(self):
                self.added = []
                self.rolled_back = False
            async def execute(self, statement):
                return FakeResult()
            def add(self, value):
                self.added.append(value)
            async def flush(self):
                raise RuntimeError("database write failed")
            async def rollback(self):
                self.rolled_back = True

        async def fake_get_register(register_uuid):
            return {"uuid": str(register_uuid), "visit_state": int(VisitState.RECEPTION)}

        async def main():
            medical_service.PatientClient.get_register = fake_get_register
            session = FakeSession()
            try:
                await medical_service.create_signed_orders(
                    session,
                    uuid.uuid4(),
                    [{"type": "check", "medical_technology_id": 101, "check_position": "头部", "check_info": "排查占位"}],
                )
            except RuntimeError as exc:
                print(json.dumps({
                    "error": str(exc),
                    "rolled_back": session.rolled_back,
                    "created": len(session.added),
                }, ensure_ascii=False))
                return
            raise AssertionError("flush failure should be re-raised")

        asyncio.run(main())
        """
    )

    assert data["error"] == "database write failed"
    assert data["rolled_back"] is True
    assert data["created"] == 1
