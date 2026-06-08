from app.common.config import BaseMicroserviceSettings

class MedicalSettings(BaseMicroserviceSettings):
    SERVICE_NAME: str = "medical-service"
    SERVICE_PORT: int = 8003
    PATIENT_SERVICE_URL: str = "http://localhost:8002/api/v1/patient"

settings = MedicalSettings()
