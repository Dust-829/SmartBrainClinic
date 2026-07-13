"""Internal HTTP client for the local CT artifact inference process."""

from typing import Any

from app.common.clients import get_shared_async_client

from ..config import settings


class ArtifactInferenceClient:
    @staticmethod
    async def list_input_sources() -> list[dict[str, str]]:
        client = await get_shared_async_client()
        response = await client.get(
            f"{settings.CT_ARTIFACT_SERVICE_URL.rstrip('/')}/v1/artifact-inputs",
            timeout=settings.CT_ARTIFACT_SERVICE_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        return response.json()["items"]

    @staticmethod
    async def segment_ct_artifact(payload: dict[str, Any]) -> dict[str, Any]:
        client = await get_shared_async_client()
        response = await client.post(
            f"{settings.CT_ARTIFACT_SERVICE_URL.rstrip('/')}/v1/artifact-segmentation",
            json=payload,
            timeout=settings.CT_ARTIFACT_SERVICE_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        return response.json()
