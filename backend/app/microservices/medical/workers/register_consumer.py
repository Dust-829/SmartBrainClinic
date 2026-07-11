import json
import logging
import uuid as uuid_pkg
from typing import Any

from sqlalchemy import select

from app.common.ai_embedding import get_embedding
from app.common.ai_schema import unwrap_ai_data
from app.common.mq import RabbitMQClient
from app.microservices.medical.config import settings
from app.microservices.medical.database import session_factory
from app.microservices.medical.models.medical import MedicalRecord
from app.microservices.medical.services.ai_draft import run_ai_medical_draft
from app.microservices.medical.services.internal_client import PatientClient

logger = logging.getLogger("medical.register_consumer")


async def process_register_paid(msg_data: dict):
    register_uuid = msg_data.get("register_uuid")
    symptoms = msg_data.get("symptoms")

    if not register_uuid:
        logger.error("Missing register_uuid in message")
        return

    try:
        register_uuid_obj = uuid_pkg.UUID(register_uuid)
    except ValueError:
        logger.error(f"Invalid register_uuid format: {register_uuid}")
        return

    async with session_factory() as session:
        stmt = select(MedicalRecord).where(MedicalRecord.register_uuid == register_uuid_obj)
        res = await session.execute(stmt)
        if res.scalar_one_or_none():
            logger.info(f"MedicalRecord already exists for register_uuid {register_uuid}, skipping LLM.")
            return

    ai_context = None
    try:
        ai_context = await PatientClient.get_register_ai_context(register_uuid_obj)
    except Exception as exc:
        logger.warning(
            "Failed to fetch register ai-context for %s, fallback to register.symptoms: %s",
            register_uuid,
            exc,
        )

    draft_context_payload = _build_draft_context_payload(ai_context, symptoms)
    draft_input_json = _serialize_draft_input(draft_context_payload)

    draft_result = await run_ai_medical_draft(
        conversation_json=draft_input_json,
        api_key=settings.LLM_API_KEY,
        api_base=settings.LLM_API_BASE,
        model=settings.LLM_MODEL,
    )
    draft = unwrap_ai_data(draft_result)

    readme = draft.get("readme", "未详细说明")
    present = draft.get("present", "未详细说明")
    history = draft.get("history", "未详细说明")
    allergy = draft.get("allergy", "未详细说明")
    proposal = draft.get("proposal", "待医生问诊后补充")
    cure = draft.get("cure", "待医生问诊后确定")

    dialog_vector = None
    embedding_text = _extract_embedding_text(draft_context_payload)
    if embedding_text:
        try:
            dialog_vector = await get_embedding(
                text=embedding_text,
                api_key=settings.LLM_API_KEY,
                api_base=settings.LLM_API_BASE,
                model=settings.LLM_EMBEDDING_MODEL,
            )
        except Exception as exc:
            logger.error(f"Embedding generation failed: {exc}")

    async with session_factory() as session:
        try:
            stmt = select(MedicalRecord).where(MedicalRecord.register_uuid == register_uuid_obj)
            res = await session.execute(stmt)
            if res.scalar_one_or_none():
                return

            record = MedicalRecord(
                uuid=uuid_pkg.uuid4(),
                register_uuid=register_uuid_obj,
                readme=readme,
                present=present,
                history=history,
                allergy=allergy,
                proposal=proposal,
                cure=cure,
                is_doctor_confirmed=False,
                dialog_vector=dialog_vector,
            )
            session.add(record)
            await session.commit()
            logger.info(f"Successfully created async MedicalRecord for register {register_uuid}")
        except Exception as exc:
            await session.rollback()
            logger.error(f"Failed to create MedicalRecord: {exc}")
            raise


def _build_draft_context_payload(ai_context: dict[str, Any] | None, symptoms: Any) -> dict[str, Any] | Any:
    if not isinstance(ai_context, dict):
        return symptoms

    return {
        "profile_snapshot": ai_context.get("profile_snapshot"),
        "summary_text": ai_context.get("summary_text"),
        "latest_result": ai_context.get("latest_result"),
        "messages": ai_context.get("messages") or [],
        "fallback_symptoms": symptoms,
    }


def _serialize_draft_input(draft_context_payload: dict[str, Any] | Any) -> str:
    if isinstance(draft_context_payload, dict):
        return json.dumps(draft_context_payload, ensure_ascii=False)
    if draft_context_payload in (None, ""):
        return ""
    return str(draft_context_payload)


def _extract_embedding_text(draft_context_payload: dict[str, Any] | Any) -> str:
    if isinstance(draft_context_payload, dict):
        parts: list[str] = []

        messages = draft_context_payload.get("messages") or []
        if isinstance(messages, list):
            user_text = " ".join(
                str(item.get("content") or "").strip()
                for item in messages
                if isinstance(item, dict) and item.get("role") == "user"
            ).strip()
            if user_text:
                parts.append(user_text)

        summary_text = str(draft_context_payload.get("summary_text") or "").strip()
        if summary_text:
            parts.append(summary_text)

        latest_result = draft_context_payload.get("latest_result")
        if isinstance(latest_result, dict):
            data = latest_result.get("data")
            if isinstance(data, dict):
                symptom_summary = str(data.get("symptom_summary") or "").strip()
                if symptom_summary and symptom_summary not in parts:
                    parts.append(symptom_summary)

        fallback_symptoms = str(draft_context_payload.get("fallback_symptoms") or "").strip()
        if fallback_symptoms and fallback_symptoms not in parts:
            parts.append(fallback_symptoms)

        return "\n".join(part for part in parts if part).strip()

    if draft_context_payload in (None, ""):
        return ""

    text = str(draft_context_payload).strip()
    if not text:
        return ""

    try:
        payload = json.loads(text)
    except (json.JSONDecodeError, TypeError):
        return text

    if isinstance(payload, list):
        return " ".join(
            str(item.get("content") or "").strip()
            for item in payload
            if isinstance(item, dict) and item.get("role") == "user"
        ).strip()

    if isinstance(payload, dict):
        return _extract_embedding_text(payload)

    return text


async def start_register_consumer():
    """监听挂号支付成功事件"""
    mq_client = RabbitMQClient(settings.RABBITMQ_URL)
    queue_name = "register:paid"
    logger.info(f"Register Consumer started. Listening to '{queue_name}'...")

    async for message in mq_client.listen(queue_name):
        try:
            logger.info(f"Received register:paid message: {message}")
            await process_register_paid(message)
        except Exception as exc:
            logger.error(f"Error processing register:paid message: {exc}")
            raise
