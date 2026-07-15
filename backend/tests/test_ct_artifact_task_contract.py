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


def test_ct_artifact_slice_contract_supports_three_linked_planes():
    service_source = Path("model_services/ct_artifact/service.py").read_text(encoding="utf-8")
    medical_source = Path("app/microservices/medical/api/medical.py").read_text(encoding="utf-8")

    assert 'Literal["axial", "coronal", "sagittal"]' in service_source
    assert 'plane: Literal["axial", "coronal", "sagittal"] = Query(default="axial")' in service_source
    assert 'coronal_index: int | None' in service_source
    assert 'sagittal_index: int | None' in service_source
    assert 'plane not in {"axial", "coronal", "sagittal"}' in medical_source
    assert '_RENDER_VOLUME_CACHE_LIMIT = 2' in service_source
    assert 'def _load_render_volume(' in service_source


def test_non_axial_plane_display_respects_physical_voxel_spacing():
    data = run_isolated_python(
        """
        import json
        import numpy as np
        from model_services.ct_artifact.service import _resample_plane_for_display

        source = np.zeros((36, 512), dtype=np.float32)
        probability = np.zeros((36, 512), dtype=np.float32)
        coronal_source, coronal_probability = _resample_plane_for_display(
            source, probability, 'coronal', (0.5, 0.5, 5.0)
        )
        axial_source, axial_probability = _resample_plane_for_display(
            source, probability, 'axial', (0.5, 0.5, 5.0)
        )
        print(json.dumps({
            'coronal': list(coronal_source.shape),
            'coronal_probability': list(coronal_probability.shape),
            'axial': list(axial_source.shape),
            'axial_probability': list(axial_probability.shape),
        }))
        """
    )

    assert data["coronal"] == [360, 512]
    assert data["coronal_probability"] == [360, 512]
    assert data["axial"] == [36, 512]
    assert data["axial_probability"] == [36, 512]
