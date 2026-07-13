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
            )
            draft_state_before_publish = report.report_state
            publish_session = FakeSession([report])
            published = await medical_service.publish_check_report(
                publish_session,
                str(report.uuid),
                uuid.uuid4(),
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
