import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from .api.patient import router
from .config import settings
from .services.zombie_sweeper import sweep_zombie_slots
from .services.outbox_sweeper import sweep_outbox_events
from .workers.medical_consumer import start_medical_consumer

@asynccontextmanager
async def lifespan(app: FastAPI):
    from app.common.nacos_client import nacos_manager
    nacos_manager.register_service(settings.SERVICE_NAME, "127.0.0.1", settings.SERVICE_PORT)
    # Startup
    task = asyncio.create_task(sweep_zombie_slots())
    outbox_task = asyncio.create_task(sweep_outbox_events())
    medical_consumer_task = asyncio.create_task(start_medical_consumer())
    yield
    # Shutdown
    task.cancel()
    outbox_task.cancel()
    medical_consumer_task.cancel()
    nacos_manager.deregister_service(settings.SERVICE_NAME, "127.0.0.1", settings.SERVICE_PORT)

app = FastAPI(title="Patient Service", version="1.0.0", lifespan=lifespan)
app.include_router(router)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": settings.SERVICE_NAME}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.SERVICE_PORT)
