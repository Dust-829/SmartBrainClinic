"""Safe, catalog-bound fallback candidates for doctor-facing medical orders."""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from typing import Any


_NEUROLOGY_TERMS = (
    "头痛",
    "头晕",
    "眩晕",
    "麻木",
    "无力",
    "意识",
    "颅",
    "脑",
    "神经",
    "tia",
    "卒中",
    "headache",
    "dizziness",
    "vertigo",
)
_VASCULAR_TERMS = ("血管", "tia", "卒中", "短暂", "偏瘫", "speech", "vascular")
_ACUTE_NEUROLOGY_TERMS = ("急性", "突发", "剧烈", "昏迷", "意识", "出血", "acute", "sudden")
_LAB_TERMS = ("高血压", "心慌", "心悸", "乏力", "呕吐", "脱水", "电解质", "血压", "hypertension")


def build_rule_order_candidates(
    *,
    clinical_text: str,
    technologies: Iterable[Mapping[str, Any]],
    ordered_technology_ids: Iterable[int],
    max_items: int = 3,
) -> list[dict[str, Any]]:
    """Return catalog-backed check and inspection candidates without side effects."""

    normalized_text = (clinical_text or "").lower()
    if not normalized_text or max_items <= 0:
        return []

    ordered_ids = {int(value) for value in ordered_technology_ids}
    candidates: list[tuple[int, int, dict[str, Any]]] = []
    for technology in technologies:
        technology_id = technology.get("id")
        technology_type = str(technology.get("tech_type") or "").strip().lower()
        if not isinstance(technology_id, int) or technology_id in ordered_ids:
            continue
        if technology_type not in {"check", "inspection"}:
            continue

        score, trigger = _score_technology(normalized_text, technology)
        if score <= 0:
            continue

        item = {
            "type": technology_type,
            "medical_technology_id": technology_id,
            "tech_code": technology.get("tech_code"),
            "tech_name": technology.get("tech_name"),
            "price": str(technology.get("price") or "0.00"),
            "reason": f"病历提及“{trigger}”，请医生结合查体判断是否需要 {technology.get('tech_name')}。",
        }
        if technology_type == "check":
            item["check_position"] = "头部"
            item["check_info"] = f"结合“{trigger}”进一步评估；请医生确认检查目的。"
        candidates.append((score, technology_id, item))

    candidates.sort(key=lambda value: (-value[0], value[1]))
    return [item for _, _, item in candidates[:max_items]]


def select_validated_llm_order_candidates(
    *,
    rule_candidates: Iterable[Mapping[str, Any]],
    llm_items: Any,
    max_items: int = 3,
) -> tuple[list[dict[str, Any]], list[str]]:
    """Keep only LLM rankings that reference the server-generated candidate whitelist.

    The LLM may change ordering and supply a concise reason. Catalog identity, type,
    price, and check details always remain the server-generated values.
    """

    fallback_items = [dict(item) for item in rule_candidates][:max_items]
    if max_items <= 0:
        return [], []
    if not isinstance(llm_items, list):
        return fallback_items, [
            "llm_order_invalid_payload_fallback",
            "llm_order_no_valid_result_fallback",
        ]

    candidates_by_id = {
        item.get("medical_technology_id"): dict(item)
        for item in fallback_items
        if isinstance(item.get("medical_technology_id"), int)
    }
    selected: list[dict[str, Any]] = []
    warnings: list[str] = []
    selected_ids: set[int] = set()
    for item in llm_items:
        if not isinstance(item, Mapping):
            warnings.append("llm_order_invalid_item_discarded")
            continue
        technology_id = item.get("medical_technology_id")
        if not isinstance(technology_id, int) or technology_id not in candidates_by_id:
            warnings.append("llm_order_catalog_mismatch_discarded")
            continue
        if technology_id in selected_ids:
            warnings.append("llm_order_duplicate_discarded")
            continue
        reason = item.get("reason")
        if not isinstance(reason, str) or not reason.strip():
            warnings.append("llm_order_reason_missing_discarded")
            continue

        selected_item = candidates_by_id[technology_id]
        selected_item["reason"] = reason.strip()
        selected.append(selected_item)
        selected_ids.add(technology_id)
        if len(selected) >= max_items:
            break

    if not selected:
        return fallback_items, [*warnings, "llm_order_no_valid_result_fallback"]
    return selected, warnings


def _score_technology(clinical_text: str, technology: Mapping[str, Any]) -> tuple[int, str]:
    name = f"{technology.get('tech_code') or ''} {technology.get('tech_name') or ''}".lower()
    neuro_trigger = _first_match(clinical_text, _NEUROLOGY_TERMS)
    if neuro_trigger:
        if "cta" in name and (trigger := _first_match(clinical_text, _VASCULAR_TERMS)):
            return 9, trigger
        if "ct" in name and (trigger := _first_match(clinical_text, _ACUTE_NEUROLOGY_TERMS)):
            return 8, trigger
        if "mri" in name:
            return 7, neuro_trigger
        if "ct" in name:
            return 6, neuro_trigger
        if "脑电" in name:
            return 5, neuro_trigger

    lab_trigger = _first_match(clinical_text, _LAB_TERMS)
    if lab_trigger and "电解质" in name:
        return 5, lab_trigger
    if lab_trigger and "血常规" in name:
        return 4, lab_trigger
    if _first_match(clinical_text, _VASCULAR_TERMS) and "凝血" in name:
        return 4, _first_match(clinical_text, _VASCULAR_TERMS)
    return 0, ""


def _first_match(text: str, terms: Iterable[str]) -> str | None:
    return next((term for term in terms if term in text), None)
