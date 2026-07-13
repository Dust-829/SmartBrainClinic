from pathlib import Path


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
