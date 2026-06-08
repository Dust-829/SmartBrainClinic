import logging
from app.common.mq import RabbitMQClient
from ..config import settings
from ..database import session_factory
from ..services import pharmacy_service

logger = logging.getLogger("pharmacy.worker")

async def start_billing_consumer():
    mq_client = RabbitMQClient(settings.RABBITMQ_URL)
    queue_name = "billing.payment.success.pharmacy"
    
    print(f"🚀 [Pharmacy Worker] Starting billing consumer on queue '{queue_name}'...", flush=True)
    
    async for message in mq_client.listen(queue_name):
        try:
            print(f"📥 [Pharmacy Worker] Received message: {message}", flush=True)
            items = message.get("items", [])
            for item in items:
                item_type = item.get("type")
                item_id = item.get("id")
                
                if item_type == "药品":
                    print(f"⚙️ [Pharmacy Worker] Processing drug prescription item ID {item_id}...", flush=True)
                    async with session_factory() as session:
                        try:
                            await pharmacy_service.update_prescription_state_by_item(session, item_id, "已缴费")
                            await session.commit()
                            print(f"✅ [Pharmacy Worker] Updated Prescription State for Item ID {item_id} to '已缴费'", flush=True)
                        except Exception as inner_e:
                            await session.rollback()
                            print(f"❌ [Pharmacy Worker] Failed to update prescription state for Item ID {item_id}: {inner_e}", flush=True)
                            raise inner_e
        except Exception as e:
            print(f"⚠️ [Pharmacy Worker] Error processing billing message: {e}", flush=True)
            raise e

async def start_billing_refund_consumer():
    mq_client = RabbitMQClient(settings.RABBITMQ_URL)
    queue_name = "billing.refund.success.pharmacy"
    
    print(f"🚀 [Pharmacy Worker] Starting refund consumer on queue '{queue_name}'...", flush=True)
    
    async for message in mq_client.listen(queue_name):
        try:
            print(f"📥 [Pharmacy Worker] Received refund message: {message}", flush=True)
            items = message.get("items", [])
            for item in items:
                item_type = item.get("type")
                item_id = item.get("id")
                
                if item_type == "药品":
                    print(f"⚙️ [Pharmacy Worker] Processing refund for drug prescription item ID {item_id}...", flush=True)
                    async with session_factory() as session:
                        try:
                            await pharmacy_service.update_prescription_state_by_item(session, item_id, "已退费")
                            await session.commit()
                            print(f"✅ [Pharmacy Worker] Updated Prescription State for Item ID {item_id} to '已退费'", flush=True)
                        except Exception as inner_e:
                            await session.rollback()
                            print(f"❌ [Pharmacy Worker] Failed to update prescription state for Item ID {item_id} for refund: {inner_e}", flush=True)
                            raise inner_e
        except Exception as e:
            print(f"⚠️ [Pharmacy Worker] Error processing refund message: {e}", flush=True)
            raise e

