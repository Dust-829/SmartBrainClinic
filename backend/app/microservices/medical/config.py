from app.common.config import BaseMicroserviceSettings

class MedicalSettings(BaseMicroserviceSettings):
    SERVICE_NAME: str = "medical-service"
    SERVICE_PORT: int = 8003
    PATIENT_SERVICE_URL: str = "http://localhost:8002/api/v1/patient"
    CT_ARTIFACT_SERVICE_URL: str = "http://127.0.0.1:8013"
    CT_ARTIFACT_SERVICE_TIMEOUT_SECONDS: float = 120.0

settings = MedicalSettings()
