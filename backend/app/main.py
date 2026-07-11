import os
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.common.clients import close_shared_async_client, get_shared_async_client


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await close_shared_async_client()

app = FastAPI(
    title="智慧云脑诊疗平台 - 微服务网关",
    description="统一入口，负责将请求转发至各领域微服务",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

FALLBACK_URLS = {
    "auth": os.getenv("AUTH_SERVICE_BASE", "http://localhost:8001"),
    "patient": os.getenv("PATIENT_SERVICE_BASE", "http://localhost:8002"),
    "medical": os.getenv("MEDICAL_SERVICE_BASE", "http://localhost:8003"),
    "pharmacy": os.getenv("PHARMACY_SERVICE_BASE", "http://localhost:8004"),
    "bill": os.getenv("BILLING_SERVICE_BASE", "http://localhost:8005"),
}


@app.api_route("/api/v1/{service}", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])
async def gateway_proxy_root(service: str, request: Request):
    return await gateway_proxy(service, "", request)


@app.api_route("/api/v1/{service}/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])
async def gateway_proxy(service: str, path: str, request: Request):
    if service not in FALLBACK_URLS:
        return JSONResponse(
            status_code=404,
            content={"code": 404, "message": f"Service '{service}' not found", "data": None},
        )

    from app.common.nacos_client import nacos_manager

    service_app_name = f"{service}-service"
    if service == "bill":
        service_app_name = "billing-service"

    base_url = nacos_manager.get_service_url(service_app_name, FALLBACK_URLS[service])
    target_url = f"{base_url}/api/v1/{service}/{path}" if path else f"{base_url}/api/v1/{service}"

    body = await request.body()
    headers = dict(request.headers)
    headers.pop("host", None)

    client = await get_shared_async_client()
    try:
        resp = await client.request(
            method=request.method,
            url=target_url,
            params=request.query_params,
            content=body,
            headers=headers,
            timeout=60.0,
        )
        return Response(
            content=resp.content,
            status_code=resp.status_code,
            headers=dict(resp.headers),
        )
    except httpx.ConnectError:
        return JSONResponse(
            status_code=503,
            content={"code": 503, "message": f"Service '{service}' is unavailable", "data": None},
        )
    except Exception as exc:
        return JSONResponse(
            status_code=500,
            content={"code": 500, "message": f"Gateway error: {str(exc)}", "data": None},
        )


@app.get("/health", tags=["网关健康检查"])
async def health():
    return {"status": "gateway_running", "services": list(FALLBACK_URLS.keys())}


@app.get("/", include_in_schema=False)
async def index():
    return {"message": "欢迎使用智慧云脑诊疗平台微服务网关。接口文档见 /docs。"}
