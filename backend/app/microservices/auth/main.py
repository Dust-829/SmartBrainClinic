from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.common.nacos_client import nacos_manager
from .api.auth import router
from .config import settings

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
    
    import asyncio
    from .mq_worker import start_vector_sync_listener
    from .services.outbox_sweeper import sweep_outbox_events
    worker_task = asyncio.create_task(start_vector_sync_listener())
    outbox_task = asyncio.create_task(sweep_outbox_events())
    
    yield
    worker_task.cancel()
    outbox_task.cancel()
    nacos_manager.deregister_service(settings.SERVICE_NAME, service_host, settings.SERVICE_PORT)

app = FastAPI(title="Auth Service", version="1.0.0", lifespan=lifespan)

app.include_router(router)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": settings.SERVICE_NAME}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.SERVICE_PORT)
