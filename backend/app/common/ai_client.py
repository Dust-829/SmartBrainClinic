"""
Shared OpenAI-compatible AI client.

This module centralizes low-level HTTP calls, JSON cleanup, timeout handling,
and log redaction for LLM chat and embedding APIs. Business modules still own
their prompts, schemas, fallback behavior, and domain validation.
"""

import json
import logging
from typing import Any, Optional

import httpx

from app.common.config import BaseMicroserviceSettings

logger = logging.getLogger("common.ai_client")


class AIClient:
    def __init__(
        self,
        api_key: Optional[str] = None,
        api_base: Optional[str] = None,
    ):
        settings = BaseMicroserviceSettings()
        self.api_key = api_key if api_key is not None else settings.LLM_API_KEY
        self.api_base = (api_base if api_base is not None else settings.LLM_API_BASE).rstrip("/")

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key and self.api_key.strip() and self.api_base)

    @staticmethod
    def strip_markdown_json(content: str) -> str:
        cleaned = (content or "").strip()
        if not cleaned.startswith("```"):
            return cleaned

        parts = cleaned.split("```")
        if len(parts) < 2:
            return cleaned.strip("` \n")

        cleaned = parts[1].strip()
        if cleaned.lower().startswith("json"):
            cleaned = cleaned[4:].strip()
        return cleaned.strip("` \n")

    async def chat_completion(
        self,
        *,
        model: str,
        messages: list[dict[str, str]],
        temperature: float = 0.2,
        timeout: float = 30.0,
        max_tokens: Optional[int] = None,
        response_format: Optional[dict[str, Any]] = None,
        retries: int = 0,
    ) -> Optional[str]:
        if not self.is_configured:
            logger.info("[AIClient] API key/base not configured; skipping chat completion.")
            return None

        payload: dict[str, Any] = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
        }
        if max_tokens is not None:
            payload["max_tokens"] = max_tokens
        if response_format is not None:
            payload["response_format"] = response_format

        for attempt in range(retries + 1):
            try:
                async with httpx.AsyncClient() as client:
                    resp = await client.post(
                        f"{self.api_base}/chat/completions",
                        json=payload,
                        headers=self._headers(),
                        timeout=timeout,
                    )
                if resp.status_code != 200:
                    logger.error(
                        "[AIClient] Chat completion HTTP %s: %s",
                        resp.status_code,
                        resp.text[:500],
                    )
                    return None

                result = resp.json()
                return result["choices"][0]["message"]["content"].strip()
            except httpx.ReadTimeout as exc:
                if attempt < retries:
                    logger.warning(
                        "[AIClient] Chat completion read timeout on attempt %s/%s, retrying.",
                        attempt + 1,
                        retries + 1,
                    )
                    continue
                logger.error("[AIClient] Chat completion failed after timeout: %s", exc, exc_info=True)
                return None
            except Exception as exc:
                logger.error("[AIClient] Chat completion failed: %s", exc, exc_info=True)
                return None

    async def chat_json(
        self,
        *,
        model: str,
        messages: list[dict[str, str]],
        temperature: float = 0.2,
        timeout: float = 10.0,
        max_tokens: Optional[int] = None,
        response_format: Optional[dict[str, Any]] = None,
        retries: int = 0,
    ) -> Optional[Any]:
        content = await self.chat_completion(
            model=model,
            messages=messages,
            temperature=temperature,
            timeout=timeout,
            max_tokens=max_tokens,
            response_format=response_format,
            retries=retries,
        )
        if content is None:
            return None

        try:
            return json.loads(self.strip_markdown_json(content))
        except json.JSONDecodeError as exc:
            logger.error("[AIClient] Failed to parse JSON response: %s", exc)
            return None

    async def embedding(
        self,
        *,
        model: str,
        text: str,
        timeout: float = 30.0,
    ) -> Optional[list[float]]:
        if not self.is_configured:
            logger.info("[AIClient] API key/base not configured; skipping embedding.")
            return None

        payload = {
            "model": model,
            "input": text,
            "encoding_format": "float",
        }

        try:
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    f"{self.api_base}/embeddings",
                    json=payload,
                    headers=self._headers(),
                    timeout=timeout,
                )
            if resp.status_code != 200:
                logger.error(
                    "[AIClient] Embedding HTTP %s: %s",
                    resp.status_code,
                    resp.text[:500],
                )
                return None

            result = resp.json()
            vector = result["data"][0]["embedding"]
            return vector if isinstance(vector, list) else None
        except Exception as exc:
            logger.error("[AIClient] Embedding failed: %s", exc, exc_info=True)
            return None

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
