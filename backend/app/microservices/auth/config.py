from app.common.config import BaseMicroserviceSettings

class AuthSettings(BaseMicroserviceSettings):
    SERVICE_NAME: str = "auth-service"
    SERVICE_PORT: int = 8001
    DB_NAME: str = "his_db" # For now sharing the same DB, but using different URL potential

settings = AuthSettings()
