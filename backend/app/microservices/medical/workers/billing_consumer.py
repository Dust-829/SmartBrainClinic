import logging
from app.common.mq import RabbitMQClient
from ..config import settings
from ..database import session_factory
from ..services import medical_service

logger = logging.getLogger("medical.worker")

async def start_billing_consumer():
    mq_client = RabbitMQClient(settings.RABBITMQ_URL)
    queue_name = "billing.payment.success.medical"
    
    print(f"🚀 [Medical Worker] Starting billing consumer on queue '{queue_name}'...", flush=True)
    
    async for message in mq_client.listen(queue_name):
        try:
            print(f"📥 [Medical Worker] Received message: {message}", flush=True)
            items = message.get("items", [])
            for item in items:
                item_type = item.get("type")
                item_id = item.get("id")
                
                if item_type in ["检查", "检验", "处置"]:
                    print(f"⚙️ [Medical Worker] Processing {item_type} ID {item_id}...", flush=True)
                    async with session_factory() as session:
                        try:
                            if item_type == "检查":
                                await medical_service.update_check_state(session, item_id, "已缴费")
                            elif item_type == "检验":
                                await medical_service.update_inspection_state(session, item_id, "已缴费")
                            elif item_type == "处置":
                                await medical_service.update_disposal_state(session, item_id, "已缴费")
                            
                            await session.commit()
                            print(f"✅ [Medical Worker] Updated {item_type} ID {item_id} state to '已缴费'", flush=True)
                        except Exception as inner_e:
                            await session.rollback()
                            print(f"❌ [Medical Worker] Failed to update {item_type} ID {item_id} state: {inner_e}", flush=True)
                            raise inner_e
        except Exception as e:
            print(f"⚠️ [Medical Worker] Error processing billing message: {e}", flush=True)
            raise e

async def start_billing_refund_consumer():
    mq_client = RabbitMQClient(settings.RABBITMQ_URL)
    queue_name = "billing.refund.success.medical"
    
    print(f"🚀 [Medical Worker] Starting refund consumer on queue '{queue_name}'...", flush=True)
    
    async for message in mq_client.listen(queue_name):
        try:
            print(f"📥 [Medical Worker] Received refund message: {message}", flush=True)
            items = message.get("items", [])
            for item in items:
                item_type = item.get("type")
                item_id = item.get("id")
                
                if item_type in ["检查", "检验", "处置"]:
                    print(f"⚙️ [Medical Worker] Processing refund for {item_type} ID {item_id}...", flush=True)
                    async with session_factory() as session:
                        try:
                            if item_type == "检查":
                                await medical_service.update_check_state(session, item_id, "已退费")
                            elif item_type == "检验":
                                await medical_service.update_inspection_state(session, item_id, "已退费")
                            elif item_type == "处置":
                                await medical_service.update_disposal_state(session, item_id, "已退费")
                            
                            await session.commit()
                            print(f"✅ [Medical Worker] Updated {item_type} ID {item_id} state to '已退费'", flush=True)
                        except Exception as inner_e:
                            await session.rollback()
                            print(f"❌ [Medical Worker] Failed to update {item_type} ID {item_id} state for refund: {inner_e}", flush=True)
                            raise inner_e
        except Exception as e:
            print(f"⚠️ [Medical Worker] Error processing refund message: {e}", flush=True)
            raise e

