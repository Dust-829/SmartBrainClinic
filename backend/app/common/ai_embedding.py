"""
AI Embedding Engine
Handles converting text to vector embeddings using SiliconFlow or fallback.
"""

import logging
import random
from typing import Optional
from app.common.ai_client import AIClient
from app.common.config import BaseMicroserviceSettings
from app.common.ai_audit import elapsed_ms, record_ai_audit, start_ai_timer
from app.common.ai_schema import AISource, build_ai_result
from app.common.ai_validator import AIResultValidator

logger = logging.getLogger("common.ai_embedding")

async def get_embedding(
    text: str,
    api_key: str = None,
    api_base: str = None,
    model: str = None,
) -> Optional[list[float]]:
    """
    Get the embedding vector for a given text.
    Uses SiliconFlow BAAI/bge-m3 by default. Returns a 1024-dimensional float vector.
    In development, an explicit mock fallback can generate a normalized vector.
    In production, failures return None to avoid polluting vector indexes.
    """
    settings = BaseMicroserviceSettings()
    
    api_key = api_key or settings.LLM_API_KEY
    api_base = api_base or settings.LLM_API_BASE
    model = model or getattr(settings, "LLM_EMBEDDING_MODEL", "BAAI/bge-m3")

    if api_key and api_key.strip():
        logger.info(f"🧬 [AI Embedding] Calling Real Embedding API ({model})...")
        vector = await AIClient(api_key=api_key, api_base=api_base).embedding(
            model=model,
            text=text,
            timeout=10.0,
        )
        if vector:
            logger.info(f"✅ [AI Embedding] Successfully retrieved embedding of length {len(vector)}")
            return vector

    allow_mock = settings.AI_ALLOW_MOCK_FALLBACK and settings.APP_ENV != "production"
    if not allow_mock:
        logger.warning(
            "[AI Embedding] Embedding unavailable and mock fallback is disabled; returning None."
        )
        return None

    logger.info("[AI Embedding] Using development Mock Vector Engine (1024-dim).")
    import math
    mock_vector = [random.uniform(-1, 1) for _ in range(1024)]
    magnitude = math.sqrt(sum(x*x for x in mock_vector))
    normalized_mock = [x/magnitude for x in mock_vector]
    return normalized_mock


async def get_embedding_result(
    text: str,
    api_key: str = None,
    api_base: str = None,
    model: str = None,
) -> dict:
    started_at = start_ai_timer()
    settings = BaseMicroserviceSettings()
    model_name = model or getattr(settings, "LLM_EMBEDDING_MODEL", "BAAI/bge-m3")
    vector = await get_embedding(text, api_key=api_key, api_base=api_base, model=model)
    source = AISource.EMBEDDING if vector is not None else AISource.FALLBACK
    validation = AIResultValidator.validate_embedding(vector)
    result = build_ai_result(
        {"vector": vector, "dimension": len(vector) if vector else 0},
        source=source,
        model=model_name,
        confidence=1.0 if vector is not None else 0.0,
        **validation.as_result_kwargs(),
    )
    await record_ai_audit(
        module_name="embedding",
        input_text=text,
        result={**result, "data": {"dimension": len(vector) if vector else 0}},
        latency_ms=elapsed_ms(started_at),
    )
    return result
