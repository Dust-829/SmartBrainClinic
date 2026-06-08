import httpx
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

app = FastAPI(
    title="智慧云脑诊疗平台 - 微服务网关",
    description="统一入口，负责将请求转发至各领域微服务",
    version="2.0.0"
)

# 微服务地址映射 (开发环境)
import os

FALLBACK_URLS = {
    "auth": os.getenv("AUTH_SERVICE_BASE", "http://localhost:8001"),
    "patient": os.getenv("PATIENT_SERVICE_BASE", "http://localhost:8002"),
    "medical": os.getenv("MEDICAL_SERVICE_BASE", "http://localhost:8003"),
    "pharmacy": os.getenv("PHARMACY_SERVICE_BASE", "http://localhost:8004"),
    "bill": os.getenv("BILLING_SERVICE_BASE", "http://localhost:8005"),
}

@app.api_route("/api/v1/{service}", methods=["GET", "POST", "PUT", "DELETE"])
async def gateway_proxy_root(service: str, request: Request):
    return await gateway_proxy(service, "", request)

@app.api_route("/api/v1/{service}/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def gateway_proxy(service: str, path: str, request: Request):
    """
    通用反向代理逻辑：
    根据 URL 中的 service 段匹配目标子服务地址，并转发剩余 path。
    """
    if service not in FALLBACK_URLS:
        return JSONResponse(
            status_code=404, 
            content={"code": 404, "message": f"Service '{service}' not found", "data": None}
        )
    
    from app.common.nacos_client import nacos_manager
    service_app_name = f"{service}-service"
    # bill service is named billing-service
    if service == "bill":
        service_app_name = "billing-service"
        
    base_url = nacos_manager.get_service_url(service_app_name, FALLBACK_URLS[service])
    
    # 构建 target_url 时，如果 path 为空，则不加后面的斜杠，防止微服务再 307 重定向
    if path:
        target_url = f"{base_url}/api/v1/{service}/{path}"
    else:
        target_url = f"{base_url}/api/v1/{service}"
    
    # 获取原始请求数据
    body = await request.body()
    headers = dict(request.headers)
    # 移除 host 头部，由 httpx 自动处理
    headers.pop("host", None)
    
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.request(
                method=request.method,
                url=target_url,
                params=request.query_params,
                content=body,
                headers=headers,
                timeout=30.0
            )
            # 构造并返回响应
            return Response(
                content=resp.content,
                status_code=resp.status_code,
                headers=dict(resp.headers)
            )
        except httpx.ConnectError:
            return JSONResponse(
                status_code=503, 
                content={"code": 503, "message": f"Service '{service}' is unavailable", "data": None}
            )
        except Exception as e:
            return JSONResponse(
                status_code=500, 
                content={"code": 500, "message": f"Gateway error: {str(e)}", "data": None}
            )

@app.get("/health", tags=["网关健康检查"])
async def health():
    return {"status": "gateway_running", "services": list(FALLBACK_URLS.keys())}

@app.get("/", include_in_schema=False)
async def index():
    return {"message": "Welcome to Smart Brain HIS Gateway. Use /docs for API documentation."}
