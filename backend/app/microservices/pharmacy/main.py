import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from .api.pharmacy import router
from .config import settings
from .workers.billing_consumer import start_billing_consumer, start_billing_refund_consumer

@asynccontextmanager
async def lifespan(app: FastAPI):
    from app.common.nacos_client import nacos_manager
    import os, socket
    service_host = os.getenv("SERVICE_HOST")
    if not service_host:
        try:
            service_host = socket.gethostbyname(socket.gethostname())
        except Exception:
            service_host = "127.0.0.1"
    nacos_manager.register_service(settings.SERVICE_NAME, service_host, settings.SERVICE_PORT)
    # Startup: Launch background Redis MQ consumers
    task_payment = asyncio.create_task(start_billing_consumer())
    task_refund = asyncio.create_task(start_billing_refund_consumer())
    yield
    # Shutdown: Cancel the worker tasks cleanly
    task_payment.cancel()
    task_refund.cancel()
    try:
        await asyncio.gather(task_payment, task_refund)
    except asyncio.CancelledError:
        pass
    nacos_manager.deregister_service(settings.SERVICE_NAME, service_host, settings.SERVICE_PORT)

app = FastAPI(title="Pharmacy Service", version="1.0.0", lifespan=lifespan)
app.include_router(router)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": settings.SERVICE_NAME}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.SERVICE_PORT)

