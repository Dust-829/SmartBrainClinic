"""
Lightweight validation for AI-generated business payloads.

This validator catches malformed structures, unsafe medical wording, invalid
enums, impossible dates, obvious allergy conflicts, and optional database facts
passed in by the service layer before the payload is marked as validated.
"""

from dataclasses import dataclass
from datetime import date
from typing import Any, Iterable, Mapping, Optional

from pydantic import ValidationError

from app.common.ai_schema import (
    MedicalDraftData,
    PrescriptionRecommendationData,
    SchedulingParseData,
    TriageResultData,
)


@dataclass(frozen=True)
class AIValidationResult:
    is_valid: bool
    messages: tuple[str, ...] = ()
    warnings: tuple[str, ...] = ()

    def as_result_kwargs(self) -> dict:
        return {
            "validated": self.is_valid,
            "validator_messages": list(self.messages),
            "warnings": list(self.warnings),
        }


class AIResultValidator:
    FORBIDDEN_TRIAGE_TERMS = (
        "确诊",
        "诊断为",
        "治疗方案",
        "处方",
        "建议服用",
        "用药",
        "开药",
    )
    FORBIDDEN_DRAFT_TERMS = (
        "确诊为",
        "诊断为",
        "建议服用",
        "开具",
        "处方",
    )
    VALID_GENDER_PREFERENCES = ("男", "女", "不限")
    VALID_ACTION_TYPES = ("cancel", "modify", "add", "cancel_after_time")
    VALID_NOON_VALUES = ("上午", "下午")
    EMERGENCY_TERMS = (
        "胸痛",
        "胸闷严重",
        "呼吸困难",
        "喘不上气",
        "意识不清",
        "昏迷",
        "抽搐",
        "大出血",
        "中风",
        "偏瘫",
        "剧烈头痛",
        "自杀",
        "服毒",
    )
    EMERGENCY_RESPONSE_TERMS = ("急诊", "急救", "120", "立即")

    @classmethod
    def combine(cls, *results: AIValidationResult) -> AIValidationResult:
        messages: list[str] = []
        warnings: list[str] = []
        for result in results:
            messages.extend(result.messages)
            warnings.extend(result.warnings)
        return AIValidationResult(
            not messages,
            tuple(cls._dedupe(messages)),
            tuple(cls._dedupe(warnings)),
        )

    @classmethod
    def validate_triage(
        cls,
        data: Any,
        *,
        allowed_dept_codes: Optional[Iterable[str]] = None,
        dept_exists_in_db: Optional[bool] = None,
        require_db_fact_check: bool = False,
    ) -> AIValidationResult:
        messages: list[str] = []
        warnings: list[str] = []

        try:
            triage = TriageResultData(**data)
        except ValidationError as exc:
            return AIValidationResult(False, (f"triage_schema_invalid: {exc}",))

        allowed = set(allowed_dept_codes or ())
        if triage.gender_preference not in cls.VALID_GENDER_PREFERENCES:
            messages.append(f"invalid_gender_preference: {triage.gender_preference}")

        if triage.dept_determined:
            if not triage.recommended_dept_code:
                messages.append("dept_determined_without_recommended_dept_code")
            elif allowed and triage.recommended_dept_code not in allowed:
                messages.append(f"unknown_recommended_dept_code: {triage.recommended_dept_code}")
            elif dept_exists_in_db is False:
                messages.append(f"recommended_dept_not_found_in_db: {triage.recommended_dept_code}")
            elif require_db_fact_check and dept_exists_in_db is None:
                warnings.append("recommended_dept_db_fact_check_unavailable")
        elif triage.recommended_dept_code:
            warnings.append("recommended_dept_code_present_when_dept_not_determined")

        unsafe_text = " ".join(
            part for part in [triage.reply, triage.symptom_summary or ""] if part
        )
        cls._append_forbidden_term_messages(
            unsafe_text,
            cls.FORBIDDEN_TRIAGE_TERMS,
            messages,
            prefix="triage_contains_forbidden_medical_advice",
        )

        return AIValidationResult(not messages, tuple(messages), tuple(warnings))

    @classmethod
    def secondary_verify_triage(cls, data: Any, *, patient_text: str) -> AIValidationResult:
        messages: list[str] = []
        warnings: list[str] = []

        try:
            triage = TriageResultData(**data)
        except ValidationError as exc:
            return AIValidationResult(False, (f"secondary_triage_schema_invalid: {exc}",))

        emergency_terms = cls.detect_emergency_terms(patient_text)
        if emergency_terms:
            combined_reply = triage.reply or ""
            if not any(term in combined_reply for term in cls.EMERGENCY_RESPONSE_TERMS):
                messages.append(
                    "secondary_triage_emergency_not_escalated: "
                    + ",".join(emergency_terms)
                )
            else:
                warnings.append(
                    "secondary_triage_emergency_escalation_verified: "
                    + ",".join(emergency_terms)
                )

        return AIValidationResult(not messages, tuple(messages), tuple(warnings))

    @classmethod
    def validate_medical_draft(cls, data: Any) -> AIValidationResult:
        messages: list[str] = []
        warnings: list[str] = []

        try:
            draft = MedicalDraftData(**data)
        except ValidationError as exc:
            return AIValidationResult(False, (f"medical_draft_schema_invalid: {exc}",))

        for field_name in ("readme", "present", "history", "allergy", "proposal", "cure"):
            value = getattr(draft, field_name)
            if not value or not value.strip():
                messages.append(f"medical_draft_empty_field: {field_name}")

        combined_text = " ".join(
            [draft.readme, draft.present, draft.history, draft.allergy, draft.proposal, draft.cure]
        )
        cls._append_forbidden_term_messages(
            combined_text,
            cls.FORBIDDEN_DRAFT_TERMS,
            warnings,
            prefix="medical_draft_possible_hallucination",
        )

        return AIValidationResult(not messages, tuple(messages), tuple(warnings))

    @classmethod
    def validate_prescription(
        cls,
        data: Any,
        *,
        patient_allergy: Optional[str] = None,
        available_drugs: Optional[Iterable[Mapping[str, Any]]] = None,
    ) -> AIValidationResult:
        messages: list[str] = []
        warnings: list[str] = []

        if not isinstance(data, list):
            return AIValidationResult(False, ("prescription_result_must_be_list",))

        allergy_tokens = cls._split_allergy_terms(patient_allergy)
        drug_fact_map = cls._build_drug_fact_map(available_drugs)
        for idx, item in enumerate(data):
            try:
                rec = PrescriptionRecommendationData(**item)
            except ValidationError as exc:
                messages.append(f"prescription_item_schema_invalid[{idx}]: {exc}")
                continue

            if rec.drug_id <= 0:
                messages.append(f"prescription_item_invalid_drug_id[{idx}]")

            drug_fact = drug_fact_map.get(rec.drug_id) if drug_fact_map else None
            if drug_fact_map and not drug_fact:
                messages.append(f"prescription_drug_not_found_in_db[{idx}]: {rec.drug_id}")
            elif drug_fact:
                db_name = str(drug_fact.get("drug_name") or "")
                if db_name and rec.drug_name and db_name != rec.drug_name:
                    warnings.append(
                        f"prescription_drug_name_mismatch[{idx}]: ai={rec.drug_name}, db={db_name}"
                    )
                stock = cls._to_int(drug_fact.get("stock"))
                if stock is not None and rec.drug_number > stock:
                    messages.append(
                        f"prescription_drug_stock_insufficient[{idx}]: requested={rec.drug_number}, stock={stock}"
                    )

            if allergy_tokens and cls._matches_allergy(rec.drug_name, allergy_tokens):
                if not any(term in rec.allergy_check for term in ("警告", "过敏", "禁用", "禁止")):
                    messages.append(f"prescription_allergy_conflict_not_flagged[{idx}]")
                else:
                    warnings.append(f"prescription_allergy_conflict_flagged[{idx}]")

        return AIValidationResult(not messages, tuple(messages), tuple(warnings))

    @classmethod
    def secondary_verify_prescription(
        cls,
        data: Any,
        *,
        patient_allergy: Optional[str] = None,
        available_drugs: Optional[Iterable[Mapping[str, Any]]] = None,
    ) -> AIValidationResult:
        primary = cls.validate_prescription(
            data,
            patient_allergy=patient_allergy,
            available_drugs=available_drugs,
        )
        messages = list(primary.messages)
        warnings = list(primary.warnings)

        if not isinstance(data, list):
            return AIValidationResult(
                False,
                tuple(messages or ["secondary_prescription_result_must_be_list"]),
                tuple(warnings),
            )

        seen_drug_ids: set[int] = set()
        allergy_tokens = cls._split_allergy_terms(patient_allergy)
        for idx, item in enumerate(data):
            try:
                rec = PrescriptionRecommendationData(**item)
            except ValidationError:
                continue

            if rec.drug_id in seen_drug_ids:
                messages.append(f"secondary_prescription_duplicate_drug[{idx}]: {rec.drug_id}")
            seen_drug_ids.add(rec.drug_id)

            if allergy_tokens and cls._matches_allergy(rec.drug_name, allergy_tokens):
                messages.append(f"secondary_prescription_allergy_conflict[{idx}]: {rec.drug_name}")

        if not messages:
            warnings.append("secondary_prescription_verification_passed")

        return AIValidationResult(
            not messages,
            tuple(cls._dedupe(messages)),
            tuple(cls._dedupe(warnings)),
        )

    @classmethod
    def validate_scheduling(
        cls,
        data: Any,
        *,
        base_date: Optional[date] = None,
    ) -> AIValidationResult:
        messages: list[str] = []
        warnings: list[str] = []

        try:
            parsed = SchedulingParseData(**data)
        except ValidationError as exc:
            return AIValidationResult(False, (f"scheduling_schema_invalid: {exc}",))

        today = base_date or date.today()
        for idx, action in enumerate(parsed.actions):
            if action.action_type not in cls.VALID_ACTION_TYPES:
                messages.append(f"scheduling_invalid_action_type[{idx}]: {action.action_type}")

            if action.noon not in cls.VALID_NOON_VALUES:
                messages.append(f"scheduling_invalid_noon[{idx}]: {action.noon}")

            try:
                target_date = date.fromisoformat(action.target_date)
                if target_date < today:
                    messages.append(f"scheduling_target_date_in_past[{idx}]: {action.target_date}")
            except ValueError:
                messages.append(f"scheduling_invalid_target_date[{idx}]: {action.target_date}")

            if action.action_type == "cancel_after_time" and not action.time_threshold:
                messages.append(f"scheduling_missing_time_threshold[{idx}]")

        if not parsed.actions:
            warnings.append("scheduling_no_actions_detected")

        return AIValidationResult(not messages, tuple(messages), tuple(warnings))

    @classmethod
    def validate_embedding(cls, vector: Any, *, expected_dimension: int = 1024) -> AIValidationResult:
        if vector is None:
            return AIValidationResult(False, ("embedding_unavailable",))
        if not isinstance(vector, list):
            return AIValidationResult(False, ("embedding_vector_must_be_list",))
        if len(vector) != expected_dimension:
            return AIValidationResult(
                False,
                (f"embedding_dimension_mismatch: expected {expected_dimension}, got {len(vector)}",),
            )
        return AIValidationResult(True)

    @classmethod
    def _append_forbidden_term_messages(
        cls,
        text: str,
        terms: Iterable[str],
        target: list[str],
        *,
        prefix: str,
    ) -> None:
        for term in terms:
            if term in text:
                target.append(f"{prefix}: {term}")

    @classmethod
    def detect_emergency_terms(cls, text: str) -> tuple[str, ...]:
        return tuple(term for term in cls.EMERGENCY_TERMS if term in (text or ""))

    @staticmethod
    def _split_allergy_terms(allergy: Optional[str]) -> tuple[str, ...]:
        if not allergy or allergy in ("无", "未详细说明"):
            return ()
        normalized = allergy.replace(",", " ").replace("，", " ").replace("、", " ")
        return tuple(term.strip().lower() for term in normalized.split() if term.strip())

    @staticmethod
    def _matches_allergy(drug_name: str, allergy_tokens: tuple[str, ...]) -> bool:
        drug_name_lower = (drug_name or "").lower()
        if not drug_name_lower:
            return False
        return any(token in drug_name_lower or drug_name_lower in token for token in allergy_tokens)

    @staticmethod
    def _build_drug_fact_map(
        available_drugs: Optional[Iterable[Mapping[str, Any]]],
    ) -> dict[int, Mapping[str, Any]]:
        if not available_drugs:
            return {}
        facts: dict[int, Mapping[str, Any]] = {}
        for drug in available_drugs:
            drug_id = AIResultValidator._to_int(drug.get("id"))
            if drug_id is not None:
                facts[drug_id] = drug
        return facts

    @staticmethod
    def _to_int(value: Any) -> Optional[int]:
        try:
            return int(value)
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _dedupe(values: Iterable[str]) -> tuple[str, ...]:
        seen: set[str] = set()
        deduped: list[str] = []
        for value in values:
            if value not in seen:
                seen.add(value)
                deduped.append(value)
        return tuple(deduped)
