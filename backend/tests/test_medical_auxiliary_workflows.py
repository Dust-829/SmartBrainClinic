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
