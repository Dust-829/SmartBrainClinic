import asyncio
import json
import logging
from app.common.mq import RabbitMQClient
from app.microservices.medical.models.medical import MedicalRecord
from app.microservices.medical.services.ai_draft import run_ai_medical_draft
from app.common.ai_embedding import get_embedding
from app.common.ai_schema import unwrap_ai_data
from app.microservices.medical.config import settings
from app.microservices.medical.database import session_factory
from sqlalchemy import select
import uuid as uuid_pkg

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

    # [前置拦截] 防重检查：如果病历已存在，直接返回，避免调用昂贵的 LLM API
    async with session_factory() as session:
        stmt = select(MedicalRecord).where(MedicalRecord.register_uuid == register_uuid_obj)
        res = await session.execute(stmt)
        if res.scalar_one_or_none():
            logger.info(f"MedicalRecord already exists for register_uuid {register_uuid}, skipping LLM.")
            return

    # 使用专用的病历初稿生成引擎
    draft_result = await run_ai_medical_draft(
        conversation_json=symptoms,  # symptoms 字段现在存储的是对话历史 JSON
        api_key=settings.LLM_API_KEY,
        api_base=settings.LLM_API_BASE,
        model=settings.LLM_MODEL
    )
    draft = unwrap_ai_data(draft_result)

    readme = draft.get("readme", "未详细说明")
    present = draft.get("present", "未详细说明")
    history = draft.get("history", "未详细说明")
    allergy = draft.get("allergy", "未详细说明")
    proposal = draft.get("proposal", "待医生问诊后补充")
    cure = draft.get("cure", "待医生问诊后确定")
    
    # 生成症状的语义向量，供未来"相似病历召回"使用
    dialog_vector = None
    if symptoms:
        try:
            # 从对话中提取用户文本用于 embedding
            user_text = symptoms
            try:
                msgs = json.loads(symptoms) if isinstance(symptoms, str) else symptoms
                if isinstance(msgs, list):
                    user_text = " ".join([m.get("content", "") for m in msgs if m.get("role") == "user"])
            except (json.JSONDecodeError, TypeError):
                pass
            
            if user_text and user_text.strip():
                dialog_vector = await get_embedding(
                    text=user_text,
                    api_key=settings.LLM_API_KEY,
                    api_base=settings.LLM_API_BASE,
                    model=settings.LLM_EMBEDDING_MODEL
                )
        except Exception as e:
            logger.error(f"Embedding generation failed: {e}")

    async with session_factory() as session:
        try:
            # [二次拦截] 防止在调用 LLM 期间有并发请求写入
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
                dialog_vector=dialog_vector
            )
            session.add(record)
            await session.commit()
            logger.info(f"Successfully created async MedicalRecord for register {register_uuid}")
        except Exception as e:
            await session.rollback()
            logger.error(f"Failed to create MedicalRecord: {e}")
            raise e

async def start_register_consumer():
    """监听挂号支付成功事件"""
    mq_client = RabbitMQClient(settings.RABBITMQ_URL)
    queue_name = "register:paid"
    logger.info(f"Register Consumer started. Listening to '{queue_name}'...")
    
    async for message in mq_client.listen(queue_name):
        try:
            logger.info(f"Received register:paid message: {message}")
            # 必须 await，不能 create_task，否则会提前 Ack 消息导致数据丢失
            await process_register_paid(message)
        except Exception as e:
            logger.error(f"Error processing register:paid message: {e}")
            raise e
