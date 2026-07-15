"""Local, single-concurrency FastAPI service for CT artifact segmentation."""

from __future__ import annotations

import asyncio
import io
from contextlib import asynccontextmanager
from collections import OrderedDict
from dataclasses import dataclass
from pathlib import Path, PurePosixPath, PureWindowsPath
from typing import Literal

import numpy as np
import SimpleITK as sitk
from fastapi import FastAPI, HTTPException, Query, Response
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
_slice_render_lock = asyncio.Lock()
_RENDER_VOLUME_CACHE_LIMIT = 2


@dataclass
class RenderVolume:
    volume: np.ndarray
    probability: np.ndarray
    spacing: tuple[float, float, float]


_render_volume_cache: OrderedDict[tuple[str, str, str, str], RenderVolume] = OrderedDict()


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
    probability_path = output_dir / "artifact_probability.nii.gz"
    overlay_path = output_dir / "artifact_overlay.png"
    probability_image = infer.predict_probability_from_sitk(image, probability_path)
    probability = sitk.GetArrayViewFromImage(probability_image)
    mask_image = sitk.GetImageFromArray((probability > THRESHOLD).astype(np.int16))
    mask_image.CopyInformation(image)
    sitk.WriteImage(mask_image, str(mask_path))
    selected_slice, selected_slice_pixels = _write_overlay(image, mask_image, overlay_path)
    mask_array = sitk.GetArrayViewFromImage(mask_image)
    return {
        "model_name": MODEL_NAME,
        "model_version": MODEL_VERSION,
        "model_weight_sha256": EXPECTED_WEIGHT_SHA256,
        "threshold": THRESHOLD,
        "mask_object_ref": f"output/{request.task_id}/artifact_mask.nii.gz",
        "probability_object_ref": f"output/{request.task_id}/artifact_probability.nii.gz",
        "overlay_object_ref": f"output/{request.task_id}/artifact_overlay.png",
        "result_metadata": {
            "artifact_pixel_count": int(mask_array.sum()),
            "selected_slice": selected_slice,
            "selected_slice_artifact_pixel_count": selected_slice_pixels,
            "image_size": list(image.GetSize()),
            "image_spacing": list(image.GetSpacing()),
        },
    }


def _load_source_image(source_ref: str, source_format: Literal["dicom", "nifti"]) -> sitk.Image:
    source_path = resolve_input_ref(source_ref)
    if source_format == "dicom":
        if not source_path.is_dir():
            raise ValueError("A DICOM source_ref must identify one series directory")
        return load_single_dicom_series(source_path)
    if not source_path.is_file():
        raise ValueError("A NIfTI source_ref must identify one file")
    return sitk.ReadImage(str(source_path))


def _resolve_probability_ref(task_id: str, probability_object_ref: str) -> Path:
    expected = PurePosixPath("output") / task_id / "artifact_probability.nii.gz"
    actual = PurePosixPath(probability_object_ref.replace("\\", "/"))
    if actual != expected:
        raise ValueError("probability_object_ref is not valid for this task")
    candidate = (RUNTIME_ROOT / Path(*actual.parts)).resolve()
    if OUTPUT_ROOT.resolve() not in candidate.parents or not candidate.is_file():
        raise FileNotFoundError("The task probability volume is unavailable")
    return candidate


def _resample_plane_for_display(
    source: np.ndarray,
    probability: np.ndarray,
    plane: Literal["axial", "coronal", "sagittal"],
    spacing: tuple[float, float, float],
) -> tuple[np.ndarray, np.ndarray]:
    """Correct non-axial pixel aspect ratios for display without changing volume data."""
    if plane == "axial":
        return source, probability

    row_spacing = spacing[2]
    column_spacing = spacing[0] if plane == "coronal" else spacing[1]
    if row_spacing <= 0 or column_spacing <= 0:
        return source, probability

    target_height = max(1, round(source.shape[0] * row_spacing / column_spacing))
    if target_height == source.shape[0]:
        return source, probability

    target_size = (source.shape[1], target_height)
    source_resampled = np.asarray(
        Image.fromarray(source.astype(np.float32), mode="F").resize(target_size, resample=Image.Resampling.BILINEAR)
    )
    probability_resampled = np.asarray(
        Image.fromarray(probability.astype(np.float32), mode="F").resize(target_size, resample=Image.Resampling.BILINEAR)
    )
    return source_resampled, probability_resampled


def _load_render_volume(
    task_id: str,
    source_ref: str,
    source_format: Literal["dicom", "nifti"],
    probability_object_ref: str,
) -> RenderVolume:
    cache_key = (task_id, source_ref, source_format, probability_object_ref)
    cached = _render_volume_cache.pop(cache_key, None)
    if cached is not None:
        _render_volume_cache[cache_key] = cached
        return cached

    image = _load_source_image(source_ref, source_format)
    probability_image = sitk.ReadImage(str(_resolve_probability_ref(task_id, probability_object_ref)))
    # Keep owned arrays. SimpleITK views tied to temporary image instances can
    # outlive their backing buffers and terminate the native process.
    rendered = RenderVolume(
        volume=sitk.GetArrayFromImage(image),
        probability=sitk.GetArrayFromImage(probability_image),
        spacing=tuple(float(value) for value in image.GetSpacing()),
    )
    _render_volume_cache[cache_key] = rendered
    while len(_render_volume_cache) > _RENDER_VOLUME_CACHE_LIMIT:
        _render_volume_cache.popitem(last=False)
    return rendered


def _render_artifact_slice(
    task_id: str,
    source_ref: str,
    source_format: Literal["dicom", "nifti"],
    probability_object_ref: str,
    plane: Literal["axial", "coronal", "sagittal"],
    axial_index: int,
    coronal_index: int,
    sagittal_index: int,
    threshold: float,
    show_mask: bool,
    opacity: float,
) -> bytes:
    rendered_volume = _load_render_volume(task_id, source_ref, source_format, probability_object_ref)
    probability = rendered_volume.probability
    volume = rendered_volume.volume
    if probability.shape != volume.shape:
        raise ValueError("The probability volume does not match the CT volume")
    depth, height, width = volume.shape
    if not 0 <= axial_index < depth:
        raise ValueError("axial_index is outside the available CT volume")
    if not 0 <= coronal_index < height:
        raise ValueError("coronal_index is outside the available CT volume")
    if not 0 <= sagittal_index < width:
        raise ValueError("sagittal_index is outside the available CT volume")

    if plane == "axial":
        source, mask_probability = volume[axial_index], probability[axial_index]
    elif plane == "coronal":
        source, mask_probability = volume[:, coronal_index, :], probability[:, coronal_index, :]
    else:
        source, mask_probability = volume[:, :, sagittal_index], probability[:, :, sagittal_index]

    source, mask_probability = _resample_plane_for_display(
        source,
        mask_probability,
        plane,
        rendered_volume.spacing,
    )
    source = source.astype(np.float32)
    low, high = np.percentile(source, (1, 99))
    normalized = np.clip((source - low) / max(high - low, 1e-6), 0, 1)
    rgb = np.repeat((normalized * 255).astype(np.uint8)[..., None], 3, axis=2).astype(np.float32)
    if show_mask:
        mask = mask_probability > threshold
        coral = np.array([220, 82, 72], dtype=np.float32)
        rgb[mask] = rgb[mask] * (1 - opacity) + coral * opacity
    buffer = io.BytesIO()
    Image.fromarray(rgb.astype(np.uint8)).save(buffer, format="PNG")
    return buffer.getvalue()


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


@app.get("/v1/artifact-slice")
async def get_artifact_slice(
    task_id: str = Query(min_length=1, max_length=64),
    source_ref: str = Query(min_length=1, max_length=1024),
    source_format: Literal["dicom", "nifti"] = Query(),
    probability_object_ref: str = Query(min_length=1, max_length=1024),
    plane: Literal["axial", "coronal", "sagittal"] = Query(default="axial"),
    slice_index: int | None = Query(default=None, ge=0),
    axial_index: int | None = Query(default=None, ge=0),
    coronal_index: int | None = Query(default=None, ge=0),
    sagittal_index: int | None = Query(default=None, ge=0),
    threshold: float = Query(ge=0.05, le=0.95),
    show_mask: bool = Query(default=True),
    opacity: float = Query(default=0.55, ge=0.2, le=0.9),
):
    try:
        async with _slice_render_lock:
            content = await asyncio.to_thread(
                _render_artifact_slice,
                task_id,
                source_ref,
                source_format,
                probability_object_ref,
                plane,
                axial_index if axial_index is not None else (slice_index if slice_index is not None else 0),
                coronal_index if coronal_index is not None else 0,
                sagittal_index if sagittal_index is not None else 0,
                threshold,
                show_mask,
                opacity,
            )
        return Response(content=content, media_type="image/png", headers={"Cache-Control": "no-store"})
    except (FileNotFoundError, ValueError) as exc:
        raise HTTPException(status_code=400, detail=str(exc))
