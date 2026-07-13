import asyncio
import json
import os
import subprocess
import sys
import textwrap
import uuid
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


def test_artifact_source_reference_rejects_paths_outside_managed_input():
    data = run_isolated_python(
        """
        import json
        from app.microservices.medical.services.medical_service import normalize_artifact_source_ref

        accepted = normalize_artifact_source_ref('CQ500CT0/Unknown Study/CT PLAIN THIN')
        rejected = []
        for value in ('../outside', 'C:/outside', '/outside', 'CQ500CT0/../outside'):
            try:
                normalize_artifact_source_ref(value)
            except ValueError:
                rejected.append(value)
        print(json.dumps({'accepted': accepted, 'rejected': rejected}))
        """
    )

    assert data["accepted"] == "CQ500CT0/Unknown Study/CT PLAIN THIN"
    assert len(data["rejected"]) == 4


def test_medical_api_exposes_artifact_task_submit_and_query_routes():
    source = Path("app/microservices/medical/api/medical.py").read_text(encoding="utf-8")

    assert '@router.post("/check/{uuid}/artifact-inference"' in source
    assert '@router.get("/artifact-inference/{task_uuid}"' in source
    assert '@router.get("/check/{uuid}/artifact-inference/latest"' in source
    assert '@router.get("/artifact-inference/{task_uuid}/overlay"' in source
    assert '@router.get("/artifact-inference/input-sources"' in source
    assert "background_tasks.add_task(svc.run_artifact_inference_task, str(task.uuid))" in source


def test_ct_artifact_service_keeps_input_and_output_references_relative():
    source = Path("model_services/ct_artifact/service.py").read_text(encoding="utf-8")

    assert 'INPUT_ROOT = RUNTIME_ROOT / "input"' in source
    assert 'OUTPUT_ROOT = RUNTIME_ROOT / "output"' in source
    assert 'async with _inference_lock:' in source
    assert '@app.get("/v1/artifact-inputs")' in source
    assert '"mask_object_ref": f"output/{request.task_id}/artifact_mask.nii.gz"' in source
    assert '"probability_object_ref": f"output/{request.task_id}/artifact_probability.nii.gz"' in source
    assert 'child.suffix.lower() == ".dcm"' in source
    assert "The inference path performs the strict" in source
