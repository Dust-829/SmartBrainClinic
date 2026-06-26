import asyncio
import json
import logging
from sqlalchemy import select
from app.common.mq import RabbitMQClient
from ..config import settings
from ..database import session_factory
from ..models.auth import OutboxEvent

logger = logging.getLogger("auth.outbox_sweeper")

async def sweep_outbox_events():
    """
    后台守护任务：定时扫描发件箱表中的 pending 消息并发送至 RabbitMQ
    确保在分布式环境下消息至少投递一次（At-Least-Once Delivery）
    """
    logger.info("📤 [Auth Outbox Sweeper] Started background task for Outbox Pattern.")
    
    mq_client = RabbitMQClient(getattr(settings, "RABBITMQ_URL", "amqp://guest:guest@localhost/"))
    
    while True:
        try:
            async with session_factory() as session:
                # 只查 pending 的消息，并且为了防止单次拉取过多，可以加个 limit
                stmt = select(OutboxEvent).where(OutboxEvent.status == "pending").with_for_update(skip_locked=True).limit(50)
                result = await session.execute(stmt)
                events = result.scalars().all()
                
                sent_count = 0
                for event in events:
                    try:
                        payload_dict = json.loads(event.payload)
                        published = await mq_client.publish(event.topic, payload_dict)
                        if not published:
                            raise RuntimeError("RabbitMQ publish returned False")
                        # 发送成功，更新状态
                        event.status = "sent"
                        sent_count += 1
                        session.add(event)
                    except Exception as pub_err:
                        logger.error(f"⚠️ [Auth Outbox Sweeper] Failed to publish event {event.uuid}: {pub_err}")
                        event.retry_count = (event.retry_count or 0) + 1
                        if event.retry_count >= 3:
                            event.status = "dead_letter"
                            logger.error(f"⚠️ [Auth Outbox Sweeper] Event {event.uuid} moved to dead_letter after 3 retries.")
                        session.add(event)
                        
                if events:
                    await session.commit()
                    logger.info(f"📤 [Auth Outbox Sweeper] Successfully sent {sent_count}/{len(events)} events.")
                    
        except Exception as e:
            logger.error(f"⚠️ [Auth Outbox Sweeper] Error during outbox sweep: {e}", exc_info=True)
            
        await asyncio.sleep(5)  # 轮询间隔 5 秒
