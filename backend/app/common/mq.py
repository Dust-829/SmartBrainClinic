"""
基于 RabbitMQ 的企业级异步消息队列客户端
"""

import json
import logging
import asyncio
import uuid
from decimal import Decimal
from datetime import datetime, date
from typing import AsyncGenerator
import aio_pika

logger = logging.getLogger("common.mq")

class MQJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, uuid.UUID):
            return str(obj)
        if isinstance(obj, Decimal):
            return str(obj)
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        return super().default(obj)

class RabbitMQClient:
    def __init__(self, mq_url: str):
        self.mq_url = mq_url
        self.connection = None

    async def get_connection(self):
        """获取或创建连接"""
        if self.connection is None or self.connection.is_closed:
            self.connection = await aio_pika.connect_robust(self.mq_url)
        return self.connection

    async def close(self):
        """关闭连接"""
        if self.connection and not self.connection.is_closed:
            await self.connection.close()

    async def publish(self, queue_name: str, message: dict) -> bool:
        """
        向指定队列发布一条 JSON 序列化的消息
        """
        try:
            connection = await self.get_connection()
            async with connection.channel() as channel:
                # 声明队列（幂等操作，确保目标队列存在）
                await channel.declare_queue(queue_name, durable=True)
                payload = json.dumps(message, cls=MQJSONEncoder, ensure_ascii=False)
                await channel.default_exchange.publish(
                    aio_pika.Message(
                        body=payload.encode(),
                        delivery_mode=aio_pika.DeliveryMode.PERSISTENT
                    ),
                    routing_key=queue_name
                )
            logger.info(f"📬 [MQ Publish] Sent message to RabbitMQ queue '{queue_name}': {message}")
            return True
        except Exception as e:
            logger.error(f"❌ [MQ Publish] Failed to send message to RabbitMQ queue '{queue_name}': {e}", exc_info=True)
            return False

    async def listen(self, queue_name: str, poll_timeout: int = 2) -> AsyncGenerator[dict, None]:
        """
        持续监听指定队列的消息 (带有 ACK)
        """
        logger.info(f"📥 [MQ Listen] Starting listener on RabbitMQ queue '{queue_name}'...")
        while True:
            try:
                connection = await self.get_connection()
                # 我们不需要 async with channel() 并在里面使用 yield，因为 yield 会在上下文外部挂起
                # 所以我们手动管理 channel 和 connection
                channel = await connection.channel()
                await channel.set_qos(prefetch_count=1)
                queue = await channel.declare_queue(queue_name, durable=True)
                
                async with queue.iterator() as queue_iter:
                    async for message in queue_iter:
                        async with message.process(): # This provides auto-ack upon successful block completion
                            try:
                                payload_str = message.body.decode()
                                payload_dict = json.loads(payload_str)
                                logger.info(f"📥 [MQ Listen] Received message from RabbitMQ queue '{queue_name}': {payload_dict}")
                                yield payload_dict
                            except json.JSONDecodeError as jde:
                                logger.error(f"❌ [MQ Listen] Failed to decode JSON payload: {message.body}, error: {jde}")
            except Exception as e:
                logger.error(f"⚠️ [MQ Listen] Connection issue or error in RabbitMQ listener: {e}. Reconnecting in 3s...", exc_info=True)
                await asyncio.sleep(3)
