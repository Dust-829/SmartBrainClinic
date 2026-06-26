from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.common.nacos_client import nacos_manager
from .api.billing import router
import asyncio
from .config import settings
from .services.outbox_sweeper import sweep_outbox_events

@asynccontextmanager
async def lifespan(app: FastAPI):
    import os, socket
    service_host = os.getenv("SERVICE_HOST")
    if not service_host:
        try:
            service_host = socket.gethostbyname(socket.gethostname())
        except Exception:
            service_host = "127.0.0.1"
    nacos_manager.register_service(settings.SERVICE_NAME, service_host, settings.SERVICE_PORT)
    outbox_task = asyncio.create_task(sweep_outbox_events())
    yield
    outbox_task.cancel()
    nacos_manager.deregister_service(settings.SERVICE_NAME, service_host, settings.SERVICE_PORT)

app = FastAPI(title="Billing Service", version="1.0.0", lifespan=lifespan)
app.include_router(router)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": settings.SERVICE_NAME}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.SERVICE_PORT)
