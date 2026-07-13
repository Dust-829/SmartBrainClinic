"""Inference adapter for the locally deployed CT artifact-segmentation model."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path

import numpy as np
import SimpleITK as sitk
import torch

from .model import UNet2D


BACKEND_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MODEL_WEIGHT_PATH = BACKEND_ROOT / "runtime" / "models" / "ct_artifact" / "attention_unet2d_best.pth"
EXPECTED_WEIGHT_SHA256 = "8F61F71964621BB104CBF8CD72D4872FD257DFF8123CC9B9B0E17575E0D3FBE1"


class CTArtifactInfer:
    """Loads the attention UNet2D once and produces binary artifact masks."""

    def __init__(self, model_weight_path: str | Path | None = None, device: str | None = None):
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        self.model_weight_path = Path(model_weight_path or os.getenv("CT_ARTIFACT_MODEL_WEIGHT") or DEFAULT_MODEL_WEIGHT_PATH)
        self._validate_weight()
        self.model = self._load_model()

    def _validate_weight(self) -> None:
        if not self.model_weight_path.is_file():
            raise FileNotFoundError(f"CT artifact model weight not found: {self.model_weight_path}")
        digest = hashlib.sha256(self.model_weight_path.read_bytes()).hexdigest().upper()
        if digest != EXPECTED_WEIGHT_SHA256:
            raise RuntimeError("CT artifact model weight checksum does not match the approved attention checkpoint")

    def _load_model(self) -> UNet2D:
        model = UNet2D().to(self.device)
        model.load_state_dict(torch.load(self.model_weight_path, map_location=self.device))
        model.eval()
        return model

    def predict_probability_slice(self, image_slice: np.ndarray) -> np.ndarray:
        image_slice = image_slice.astype(np.float32)
        normalized = (image_slice - image_slice.mean()) / (image_slice.std() + 1e-7)
        tensor = torch.from_numpy(normalized).unsqueeze(0).unsqueeze(0).to(self.device)
        with torch.no_grad():
            return torch.sigmoid(self.model(tensor)).squeeze().cpu().numpy().astype(np.float32)

    def predict_slice(self, image_slice: np.ndarray, threshold: float = 0.5) -> np.ndarray:
        return (self.predict_probability_slice(image_slice) > threshold).astype(np.int16)

    def predict_probability_from_sitk(
        self,
        ct_image: sitk.Image,
        save_probability_path: str | Path | None = None,
    ) -> sitk.Image:
        volume = sitk.GetArrayFromImage(ct_image)
        if volume.ndim != 3:
            raise ValueError(f"Expected a single-channel 3D CT volume, got shape {volume.shape}")
        _, height, width = volume.shape
        if height % 8 or width % 8:
            raise ValueError(f"CT slice width and height must be divisible by 8, got {width}x{height}")

        probability_volume = np.zeros(volume.shape, dtype=np.float32)
        for index, image_slice in enumerate(volume):
            probability_volume[index] = self.predict_probability_slice(image_slice)

        probability_image = sitk.GetImageFromArray(probability_volume)
        probability_image.CopyInformation(ct_image)
        if save_probability_path is not None:
            destination = Path(save_probability_path)
            destination.parent.mkdir(parents=True, exist_ok=True)
            sitk.WriteImage(probability_image, str(destination))
        return probability_image

    def predict_from_sitk(self, ct_image: sitk.Image, save_mask_path: str | Path | None = None) -> sitk.Image:
        volume = sitk.GetArrayFromImage(ct_image)
        if volume.ndim != 3:
            raise ValueError(f"Expected a single-channel 3D CT volume, got shape {volume.shape}")
        _, height, width = volume.shape
        if height % 8 or width % 8:
            raise ValueError(f"CT slice width and height must be divisible by 8, got {width}x{height}")

        probability_image = self.predict_probability_from_sitk(ct_image)
        probability_volume = sitk.GetArrayViewFromImage(probability_image)
        mask_volume = (probability_volume > 0.5).astype(np.int16)

        mask_image = sitk.GetImageFromArray(mask_volume)
        mask_image.CopyInformation(ct_image)
        if save_mask_path is not None:
            destination = Path(save_mask_path)
            destination.parent.mkdir(parents=True, exist_ok=True)
            sitk.WriteImage(mask_image, str(destination))
        return mask_image

    def predict_from_nii(self, nii_path: str | Path, save_mask_path: str | Path | None = None) -> sitk.Image:
        return self.predict_from_sitk(sitk.ReadImage(str(nii_path)), save_mask_path)


def load_single_dicom_series(dicom_dir: str | Path) -> sitk.Image:
    """Read one DICOM series from a directory for the future local service."""

    directory = Path(dicom_dir)
    series_ids = sitk.ImageSeriesReader.GetGDCMSeriesIDs(str(directory)) or []
    if len(series_ids) != 1:
        raise ValueError(f"Expected one DICOM series in {directory}, found {len(series_ids)}")
    file_names = sitk.ImageSeriesReader.GetGDCMSeriesFileNames(str(directory), series_ids[0])
    reader = sitk.ImageSeriesReader()
    reader.SetFileNames(file_names)
    return reader.Execute()
