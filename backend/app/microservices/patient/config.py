from app.common.config import BaseMicroserviceSettings

class PatientSettings(BaseMicroserviceSettings):
    SERVICE_NAME: str = "patient-service"
    SERVICE_PORT: int = 8002
    AUTH_SERVICE_URL: str = "http://localhost:8001/api/v1/auth"
    MEDICAL_SERVICE_URL: str = "http://localhost:8003/api/v1/medical"

settings = PatientSettings()
