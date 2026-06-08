"""
通用配置基础类
"""

from pydantic_settings import BaseSettings

class BaseMicroserviceSettings(BaseSettings):
    APP_ENV: str = "development"
    APP_DEBUG: bool = True
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # AI/LLM 大模型配置
    LLM_API_KEY: str = "sk-wqfehktkatxtixynbkrnjovthhzmporaxwwufzxnfhwxbpsa"
    LLM_API_BASE: str = "https://api.siliconflow.cn/v1"
    LLM_MODEL: str = "deepseek-ai/DeepSeek-V4-Pro"
    LLM_EMBEDDING_MODEL: str = "BAAI/bge-m3"
    
    # 基础数据库配置 (各服务可覆盖)
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_USER: str = "lujuntong"
    DB_PASSWORD: str = ""
    DB_NAME: str = "his_db"
    
    # 默认微服务内部通信 URLs (跨服务 RPC)
    AUTH_SERVICE_URL: str = "http://localhost:8001/api/v1/auth"
    PATIENT_SERVICE_URL: str = "http://localhost:8002/api/v1/patient"
    MEDICAL_SERVICE_URL: str = "http://localhost:8003/api/v1/medical"
    PHARMACY_SERVICE_URL: str = "http://localhost:8004/api/v1/pharmacy"
    BILLING_SERVICE_URL: str = "http://localhost:8005/api/v1/billing"

    # Nacos 服务发现配置
    NACOS_SERVER_ADDR: str = "127.0.0.1:8848"
    NACOS_NAMESPACE: str = "public"
    
    # 消息队列配置
    RABBITMQ_URL: str = "amqp://guest:guest@localhost:5672/"

    def get_db_url(self, db_name: str = None) -> str:
        name = db_name or self.DB_NAME
        pwd_part = f":{self.DB_PASSWORD}" if self.DB_PASSWORD else ""
        return f"postgresql+asyncpg://{self.DB_USER}{pwd_part}@{self.DB_HOST}:{self.DB_PORT}/{name}"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"
