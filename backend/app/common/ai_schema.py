"""
Shared schemas for AI-generated results.

Every AI integration should return the business payload under ``data`` and
attach metadata that makes source, fallback behavior, and validation status
explicit.
"""

from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field


class AISource(str, Enum):
    LLM = "llm"
    RULE = "rule"
    MOCK = "mock"
    FALLBACK = "fallback"
    OCR = "ocr"
    ASR = "asr"
    IMAGE_MODEL = "image_model"
    EMBEDDING = "embedding"


class AIResult(BaseModel):
    source: AISource
    model: Optional[str] = None
    confidence: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    warnings: tuple[str, ...] = ()
    validated: bool = False
    validator_messages: tuple[str, ...] = ()
    data: Any = None


class TriageResultData(BaseModel):
    reply: str
    dept_determined: bool
    recommended_dept_code: Optional[str] = None
    symptom_summary: Optional[str] = None
    gender_preference: str = "不限"


class MedicalDraftData(BaseModel):
    readme: str
    present: str
    history: str
    allergy: str
    proposal: str
    cure: str


class PrescriptionRecommendationData(BaseModel):
    drug_id: int
    drug_name: str
    drug_usage: str
    drug_number: int = Field(gt=0)
    reason: str
    allergy_check: str


class SchedulingActionData(BaseModel):
    action_type: str
    target_date: str
    noon: str
    regist_quota: int = Field(ge=0)
    time_threshold: Optional[str] = None
    clinic_room_name: Optional[str] = None


class SchedulingParseData(BaseModel):
    actions: tuple[SchedulingActionData, ...] = ()
    llm_text_rule: str


class ImageInferenceData(BaseModel):
    tumor_probability: float = Field(ge=0.0, le=1.0)
    report: str
    risk_level: str


def build_ai_result(
    data: Any,
    *,
    source: AISource,
    model: Optional[str] = None,
    confidence: Optional[float] = None,
    warnings: Optional[list[str]] = None,
    validated: bool = False,
    validator_messages: Optional[list[str]] = None,
) -> dict:
    return AIResult(
        source=source,
        model=model,
        confidence=confidence,
        warnings=warnings or [],
        validated=validated,
        validator_messages=validator_messages or [],
        data=data,
    ).model_dump(mode="json")


def unwrap_ai_data(result: Any) -> Any:
    if isinstance(result, dict) and "data" in result and "source" in result:
        return result.get("data")
    return result
