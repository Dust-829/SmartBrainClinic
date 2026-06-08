"""
AI Embedding Engine
Handles converting text to vector embeddings using SiliconFlow or fallback.
"""

import httpx
import logging
import random
from typing import List
from app.common.config import BaseMicroserviceSettings

logger = logging.getLogger("common.ai_embedding")

async def get_embedding(
    text: str,
    api_key: str = None,
    api_base: str = None,
    model: str = None,
) -> List[float]:
    """
    Get the embedding vector for a given text.
    Uses SiliconFlow BAAI/bge-m3 by default. Returns a 1024-dimensional float vector.
    Falls back to a random mock vector if API fails.
    """
    settings = BaseMicroserviceSettings()
    
    api_key = api_key or settings.LLM_API_KEY
    api_base = api_base or settings.LLM_API_BASE
    model = model or getattr(settings, "LLM_EMBEDDING_MODEL", "BAAI/bge-m3")

    if api_key and api_key.strip():
        logger.info(f"🧬 [AI Embedding] Calling Real Embedding API ({model})...")
        try:
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }
            payload = {
                "model": model,
                "input": text,
                "encoding_format": "float"
            }
            
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    f"{api_base.rstrip('/')}/embeddings",
                    json=payload,
                    headers=headers,
                    timeout=10.0
                )
                if resp.status_code == 200:
                    result = resp.json()
                    vector = result["data"][0]["embedding"]
                    logger.info(f"✅ [AI Embedding] Successfully retrieved embedding of length {len(vector)}")
                    return vector
                else:
                    logger.error(f"❌ [AI Embedding] HTTP error {resp.status_code}: {resp.text}")
        except Exception as e:
            logger.error(f"⚠️ [AI Embedding] API invocation failed: {e}. Falling back to Mock Engine...")

    # Fallback: Generate a normalized mock 1024-dimensional vector
    logger.info("🔌 [AI Embedding] Using Mock Vector Engine (1024-dim)...")
    import math
    mock_vector = [random.uniform(-1, 1) for _ in range(1024)]
    magnitude = math.sqrt(sum(x*x for x in mock_vector))
    normalized_mock = [x/magnitude for x in mock_vector]
    return normalized_mock
