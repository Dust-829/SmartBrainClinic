import json
import os
import subprocess
import sys
import textwrap
from pathlib import Path


def run_isolated_python(code: str) -> dict:
    result = subprocess.run(
        [sys.executable, "-c", textwrap.dedent(code)],
        cwd=Path.cwd(),
        env={**os.environ, "PYTHONPATH": "."},
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def test_medical_models_define_separate_report_and_artifact_task_contracts():
    source = Path("app/microservices/medical/models/medical.py").read_text(encoding="utf-8")

    assert 'class ArtifactInferenceTask(SQLModel, table=True):' in source
    assert 'task_state: str = Field(default="queued"' in source
    assert 'mask_object_ref: Optional[str]' in source
    assert 'overlay_object_ref: Optional[str]' in source
    assert 'class MedicalReport(SQLModel, table=True):' in source
    assert 'report_state: str = Field(default="draft"' in source
    assert 'artifact_task_uuid: Optional[uuid_pkg.UUID]' in source


def test_report_and_artifact_migration_is_present_and_idempotent():
    migration = Path("migrations/20260713_01_create_report_and_artifact_inference_tables.sql").read_text(encoding="utf-8")

    assert "CREATE TABLE IF NOT EXISTS public.artifact_inference_task" in migration
    assert "CREATE TABLE IF NOT EXISTS public.medical_report" in migration
    assert "idx_artifact_inference_task_state_created" in migration
    assert "idx_medical_report_register_state_published" in migration


def test_medical_api_exposes_check_report_draft_and_publish_routes():
    source = Path("app/microservices/medical/api/medical.py").read_text(encoding="utf-8")

    assert '@router.get("/check/{uuid}/report/latest"' in source
    assert '@router.put("/check/{uuid}/report"' in source
    assert '@router.post("/report/{report_uuid}/publish"' in source
    assert '@router.post("/report/{report_uuid}/correction-draft"' in source


def test_medical_api_exposes_structured_inspection_report_routes():
    source = Path("app/microservices/medical/api/medical.py").read_text(encoding="utf-8")
    service_source = Path("app/microservices/medical/services/medical_service.py").read_text(encoding="utf-8")

    assert 'class InspectionReportResultItem(BaseModel):' in source
    assert '@router.get("/inspection/{uuid}/report/latest"' in source
    assert '@router.put("/inspection/{uuid}/report"' in source
    assert '@router.post("/inspection-report/{report_uuid}/publish"' in source
    assert '@router.post("/inspection-report/{report_uuid}/correction-draft"' in source
    assert 'async def save_inspection_report_draft(' in service_source
    assert 'async def publish_inspection_report(' in service_source
    assert 'async def create_inspection_report_correction_draft(' in service_source


def test_published_check_report_is_not_overwritten_by_draft_save():
    source = Path("app/microservices/medical/services/medical_service.py").read_text(encoding="utf-8")

    assert 'if report and report.report_state == "published":' in source
    assert 'raise ValueError("已发布报告不可直接修改，请创建更正版本")' in source
    assert 'raise ValueError("检查单执行完成后才能保存正式报告")' in source


def test_check_report_draft_can_be_saved_then_published_after_execution():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from app.common.enums import CheckState
        from app.microservices.medical.models.medical import CheckRequest
        from app.microservices.medical.services import medical_service

        class ScalarResult:
            def __init__(self, row):
                self.row = row
            def scalar_one_or_none(self):
                return self.row

        class FakeSession:
            def __init__(self, rows):
                self.rows = list(rows)
                self.added = []
                self.flushed = False
            async def execute(self, statement):
                return ScalarResult(self.rows.pop(0))
            def add(self, value):
                self.added.append(value)
            async def flush(self):
                self.flushed = True

        async def main():
            doctor_uuid = uuid.uuid4()

            async def get_register(_register_uuid):
                return {'employee_uuid': str(doctor_uuid)}

            medical_service.PatientClient.get_register = staticmethod(get_register)
            check = CheckRequest(
                register_uuid=uuid.uuid4(),
                medical_technology_id=1,
                check_state=CheckState.EXECUTED.value,
            )
            draft_session = FakeSession([check, None])
            report = await medical_service.save_check_report_draft(
                draft_session,
                str(check.uuid),
                '未见明显影响诊断的伪影，结合临床判断。',
                doctor_uuid,
            )
            draft_state_before_publish = report.report_state
            publish_session = FakeSession([report, check])
            published = await medical_service.publish_check_report(
                publish_session,
                str(report.uuid),
                doctor_uuid,
            )
            print(json.dumps({
                'draft_state': draft_state_before_publish,
                'draft_flushed': draft_session.flushed,
                'published_state': published.report_state,
                'published_flushed': publish_session.flushed,
                'has_published_at': published.published_at is not None,
            }))

        asyncio.run(main())
        """
    )

    assert data["draft_state"] == "draft"
    assert data["draft_flushed"] is True
    assert data["published_state"] == "published"
    assert data["published_flushed"] is True
    assert data["has_published_at"] is True


def test_inspection_report_draft_can_be_saved_then_published_after_execution():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from app.common.enums import InspectionState
        from app.microservices.medical.models.medical import InspectionRequest
        from app.microservices.medical.services import medical_service

        class ScalarResult:
            def __init__(self, row): self.row = row
            def scalar_one_or_none(self): return self.row

        class FakeSession:
            def __init__(self, rows):
                self.rows = list(rows)
                self.flushed = False
            async def execute(self, statement): return ScalarResult(self.rows.pop(0))
            def add(self, value): pass
            async def flush(self): self.flushed = True

        async def main():
            doctor_uuid = uuid.uuid4()
            async def get_register(_register_uuid): return {'employee_uuid': str(doctor_uuid)}
            medical_service.PatientClient.get_register = staticmethod(get_register)
            inspection = InspectionRequest(
                register_uuid=uuid.uuid4(), medical_technology_id=1,
                inspection_state=InspectionState.EXECUTED.value,
            )
            draft_session = FakeSession([inspection, None])
            report = await medical_service.save_inspection_report_draft(
                draft_session, str(inspection.uuid), '检验结果结合临床判断。',
                [{'item_name': '白细胞', 'value': '6.2', 'unit': '10^9/L', 'reference_range': '3.5-9.5'}],
                doctor_uuid,
            )
            publish_session = FakeSession([report, inspection])
            published = await medical_service.publish_inspection_report(publish_session, str(report.uuid), doctor_uuid)
            print(json.dumps({
                'state_after_publish': report.report_state,
                'draft_result': report.structured_result,
                'published_state': published.report_state,
                'published_at': published.published_at is not None,
            }))

        asyncio.run(main())
        """
    )

    assert data["state_after_publish"] == "published"
    assert data["draft_result"][0]["item_name"] == "白细胞"
    assert data["published_state"] == "published"
    assert data["published_at"] is True


def test_published_report_creates_a_linked_correction_draft_without_overwriting_source():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from app.common.enums import CheckState
        from app.microservices.medical.models.medical import CheckRequest, MedicalReport
        from app.microservices.medical.services import medical_service

        class ScalarResult:
            def __init__(self, row):
                self.row = row
            def scalar_one_or_none(self):
                return self.row

        class FakeSession:
            def __init__(self, rows):
                self.rows = list(rows)
                self.added = []
                self.flushed = False
            async def execute(self, statement):
                return ScalarResult(self.rows.pop(0))
            def add(self, value):
                self.added.append(value)
            async def flush(self):
                self.flushed = True

        async def main():
            doctor_uuid = uuid.uuid4()

            async def get_register(_register_uuid):
                return {'employee_uuid': str(doctor_uuid)}

            medical_service.PatientClient.get_register = staticmethod(get_register)
            check = CheckRequest(
                register_uuid=uuid.uuid4(),
                medical_technology_id=1,
                check_state=CheckState.EXECUTED.value,
            )
            source = MedicalReport(
                register_uuid=check.register_uuid,
                source_request_uuid=check.uuid,
                report_type='check',
                report_state='published',
                conclusion='原始结论',
                version=1,
            )
            session = FakeSession([source, check, None])
            correction = await medical_service.create_check_report_correction_draft(
                session,
                str(source.uuid),
                doctor_uuid,
            )
            print(json.dumps({
                'source_state': source.report_state,
                'source_version': source.version,
                'correction_state': correction.report_state,
                'correction_version': correction.version,
                'supersedes_source': str(correction.supersedes_report_uuid) == str(source.uuid),
                'copied_conclusion': correction.conclusion,
                'flushed': session.flushed,
            }))

        asyncio.run(main())
        """
    )

    assert data["source_state"] == "published"
    assert data["source_version"] == 1
    assert data["correction_state"] == "draft"
    assert data["correction_version"] == 2
    assert data["supersedes_source"] is True
    assert data["copied_conclusion"] == "原始结论"
    assert data["flushed"] is True


def test_check_report_rejects_doctor_who_is_not_assigned_to_register():
    data = run_isolated_python(
        """
        import asyncio
        import json
        import uuid
        from app.microservices.medical.models.medical import CheckRequest
        from app.microservices.medical.services import medical_service

        async def main():
            assigned_uuid = uuid.uuid4()
            async def get_register(_register_uuid):
                return {'employee_uuid': str(assigned_uuid)}

            medical_service.PatientClient.get_register = staticmethod(get_register)
            check = CheckRequest(register_uuid=uuid.uuid4(), medical_technology_id=1)
            try:
                await medical_service.ensure_check_report_doctor_assignment(check, uuid.uuid4())
            except ValueError as exc:
                print(json.dumps({'message': str(exc)}))
                return
            raise AssertionError('non-assigned doctor was accepted')

        asyncio.run(main())
        """
    )

    assert data["message"] == "当前医生无权处理该检查报告"
