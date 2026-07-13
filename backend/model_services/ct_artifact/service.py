"""Local, single-concurrency FastAPI service for CT artifact segmentation."""

from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager
from pathlib import Path, PurePosixPath, PureWindowsPath
from typing import Literal

import numpy as np
import SimpleITK as sitk
from fastapi import FastAPI, HTTPException
from PIL import Image
from pydantic import BaseModel, Field

from .inference import EXPECTED_WEIGHT_SHA256, CTArtifactInfer, load_single_dicom_series


RUNTIME_ROOT = Path(__file__).resolve().parents[2] / "runtime" / "data" / "ct_artifact"
INPUT_ROOT = RUNTIME_ROOT / "input"
OUTPUT_ROOT = RUNTIME_ROOT / "output"
MODEL_NAME = "attention-unet2d"
MODEL_VERSION = "attention_unet2d/best.pth"
THRESHOLD = 0.5
_inference_lock = asyncio.Lock()


class ArtifactSegmentationRequest(BaseModel):
    task_id: str = Field(min_length=1, max_length=64)
    source_ref: str = Field(min_length=1, max_length=1024)
    source_format: Literal["dicom", "nifti"]


def resolve_input_ref(source_ref: str) -> Path:
    raw_ref = source_ref.strip()
    if not raw_ref or raw_ref.startswith(("/", "\\")) or PureWindowsPath(raw_ref).drive:
        raise ValueError("source_ref must be relative to the managed input directory")
    relative = PurePosixPath(raw_ref.replace("\\", "/"))
    if any(part in ("", ".", "..") for part in relative.parts):
        raise ValueError("source_ref contains an invalid path segment")
    candidate = (INPUT_ROOT / Path(*relative.parts)).resolve()
    if INPUT_ROOT.resolve() not in candidate.parents and candidate != INPUT_ROOT.resolve():
        raise ValueError("source_ref escapes the managed input directory")
    if not candidate.exists():
        raise FileNotFoundError("source_ref does not exist in the managed input directory")
    return candidate


def _list_input_sources() -> list[dict[str, str]]:
    sources: list[dict[str, str]] = []
    if not INPUT_ROOT.exists():
        return sources

    for path in sorted(INPUT_ROOT.rglob("*")):
        if path.is_file() and (path.name.endswith(".nii") or path.name.endswith(".nii.gz")):
            sources.append({"source_ref": path.relative_to(INPUT_ROOT).as_posix(), "source_format": "nifti"})
        elif path.is_dir() and not any(child.is_dir() for child in path.iterdir()):
            # This list endpoint is called while the doctor opens the encounter page.
            # Reading every DICOM header to discover a SeriesInstanceUID makes the UI
            # block on large local data sets. The inference path performs the strict
            # single-series validation before it reads any volume.
            if any(child.is_file() and child.suffix.lower() == ".dcm" for child in path.iterdir()):
                sources.append({"source_ref": path.relative_to(INPUT_ROOT).as_posix(), "source_format": "dicom"})
    return sources


def _write_overlay(ct_image: sitk.Image, mask_image: sitk.Image, destination: Path) -> tuple[int, int]:
    volume = sitk.GetArrayViewFromImage(ct_image)
    mask = sitk.GetArrayViewFromImage(mask_image)
    slice_counts = mask.reshape(mask.shape[0], -1).sum(axis=1)
    selected_slice = int(slice_counts.argmax())
    pixels = int(slice_counts[selected_slice])
    source = volume[selected_slice].astype(np.float32)
    low, high = np.percentile(source, (1, 99))
    normalized = np.clip((source - low) / max(high - low, 1e-6), 0, 1)
    rgb = np.repeat((normalized * 255).astype(np.uint8)[..., None], 3, axis=2)
    rgb[mask[selected_slice] > 0] = np.array([220, 38, 38], dtype=np.uint8)
    Image.fromarray(rgb).save(destination)
    return selected_slice, pixels


def _run_inference(request: ArtifactSegmentationRequest, infer: CTArtifactInfer) -> dict:
    source_path = resolve_input_ref(request.source_ref)
    if request.source_format == "dicom":
        if not source_path.is_dir():
            raise ValueError("A DICOM source_ref must identify one series directory")
        image = load_single_dicom_series(source_path)
    else:
        if not source_path.is_file():
            raise ValueError("A NIfTI source_ref must identify one file")
        image = sitk.ReadImage(str(source_path))

    output_dir = OUTPUT_ROOT / request.task_id
    output_dir.mkdir(parents=True, exist_ok=True)
    mask_path = output_dir / "artifact_mask.nii.gz"
    overlay_path = output_dir / "artifact_overlay.png"
    mask_image = infer.predict_from_sitk(image, mask_path)
    selected_slice, selected_slice_pixels = _write_overlay(image, mask_image, overlay_path)
    mask_array = sitk.GetArrayViewFromImage(mask_image)
    return {
        "model_name": MODEL_NAME,
        "model_version": MODEL_VERSION,
        "model_weight_sha256": EXPECTED_WEIGHT_SHA256,
        "threshold": THRESHOLD,
        "mask_object_ref": f"output/{request.task_id}/artifact_mask.nii.gz",
        "overlay_object_ref": f"output/{request.task_id}/artifact_overlay.png",
        "result_metadata": {
            "artifact_pixel_count": int(mask_array.sum()),
            "selected_slice": selected_slice,
            "selected_slice_artifact_pixel_count": selected_slice_pixels,
            "image_size": list(image.GetSize()),
            "image_spacing": list(image.GetSpacing()),
        },
    }


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.infer = CTArtifactInfer()
    yield


app = FastAPI(title="CT Artifact Inference Service", version="1.0.0", lifespan=lifespan)


@app.get("/health")
async def health_check():
    return {"status": "healthy", "model_name": MODEL_NAME, "model_version": MODEL_VERSION}


@app.get("/v1/artifact-inputs")
async def list_artifact_inputs():
    return {"items": await asyncio.to_thread(_list_input_sources)}


@app.post("/v1/artifact-segmentation")
async def artifact_segmentation(request: ArtifactSegmentationRequest):
    try:
        async with _inference_lock:
            return await asyncio.to_thread(_run_inference, request, app.state.infer)
    except (FileNotFoundError, ValueError) as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Artifact inference failed") from exc
