import asyncio
import logging
from sqlalchemy import update
from app.common.mq import RabbitMQClient
from app.common.ai_embedding import get_embedding
from app.microservices.auth.config import settings
from app.microservices.auth.database import get_session
from app.microservices.auth.models.auth import Employee

logger = logging.getLogger("auth.mq_worker")

async def process_vector_sync(payload: dict):
    employee_uuid = payload.get("employee_uuid")
    expertise = payload.get("expertise")
    
    if not employee_uuid or not expertise:
        logger.warning(f"⚠️ [MQ Worker] Invalid payload: {payload}")
        return
        
    logger.info(f"🚀 [MQ Worker] Generating embedding for employee {employee_uuid}: {expertise[:20]}...")
    
    try:
        vector = await get_embedding(expertise)
        
        # AsyncSession generation
        # get_session() is a generator, so we iterate it
        session_gen = get_session()
        session = await anext(session_gen)
        try:
            stmt = update(Employee).where(Employee.uuid == employee_uuid).values(expertise_vector=vector)
            result = await session.execute(stmt)
            await session.commit()
            if result.rowcount > 0:
                logger.info(f"✅ [MQ Worker] Successfully updated expertise_vector for employee {employee_uuid}")
            else:
                logger.warning(f"⚠️ [MQ Worker] Employee {employee_uuid} not found during vector update")
        finally:
            # We don't strictly need to close the generator, but it's good practice
            try:
                await anext(session_gen)
            except StopAsyncIteration:
                pass
                
    except Exception as e:
        logger.error(f"❌ [MQ Worker] Failed to process vector sync for {employee_uuid}: {e}", exc_info=True)
        # 抛出异常让 RabbitMQ 知道没完成，以便 DLX 或重新入队
        raise

async def start_vector_sync_listener():
    mq_url = getattr(settings, "RABBITMQ_URL", "amqp://guest:guest@localhost/")
    mq = RabbitMQClient(mq_url)
    try:
        logger.info("🎧 [MQ Worker] Starting listener for 'employee_vector_sync' queue...")
        async for payload in mq.listen("employee_vector_sync"):
            # 在后台独立任务处理，避免阻塞监听主循环过久
            # 但为了保证 ack 准确，可以直接 await
            await process_vector_sync(payload)
    except asyncio.CancelledError:
        logger.info("⏹️ [MQ Worker] Listener task cancelled.")
    finally:
        await mq.close()
