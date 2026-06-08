import asyncio
import logging
import json
import uuid as uuid_pkg
from app.common.mq import RabbitMQClient
from app.microservices.patient.database import session_factory
from app.microservices.patient.models.patient import Register
from app.microservices.patient.config import settings
from sqlalchemy import select

logger = logging.getLogger("patient.medical_consumer")

async def process_medical_record_confirmed(msg_data: dict):
    register_uuid_str = msg_data.get("register_uuid")
    visit_state = msg_data.get("visit_state")

    if not register_uuid_str or visit_state is None:
        logger.error("Missing register_uuid or visit_state in message")
        return

    async with session_factory() as session:
        try:
            stmt = select(Register).where(Register.uuid == uuid_pkg.UUID(register_uuid_str)).with_for_update()
            res = await session.execute(stmt)
            register = res.scalar_one_or_none()
            if not register:
                logger.error(f"Register not found: {register_uuid_str}")
                return
                
            register.visit_state = visit_state
            session.add(register)
            await session.commit()
            logger.info(f"Successfully updated register {register_uuid_str} state to {visit_state} via MQ")
        except Exception as e:
            await session.rollback()
            logger.error(f"Failed to update register state via MQ: {e}")
            raise e

async def start_medical_consumer():
    """监听医生确诊病历事件"""
    mq_client = RabbitMQClient(settings.RABBITMQ_URL)
    queue_name = "medical.record.confirmed"
    logger.info(f"Medical Consumer started. Listening to '{queue_name}'...")
    
    async for message in mq_client.listen(queue_name):
        try:
            logger.info(f"Received medical.record.confirmed message: {message}")
            # 必须 await 保证成功执行才让 aio_pika 自动 ACK
            await process_medical_record_confirmed(message)
        except Exception as e:
            logger.error(f"Error processing medical.record.confirmed message: {e}")
            raise e
