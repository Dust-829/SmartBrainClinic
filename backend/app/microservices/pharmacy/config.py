from app.common.config import BaseMicroserviceSettings

class PharmacySettings(BaseMicroserviceSettings):
    SERVICE_NAME: str = "pharmacy-service"
    SERVICE_PORT: int = 8004
    PATIENT_SERVICE_URL: str = "http://localhost:8002/api/v1/patient"
    MEDICAL_SERVICE_URL: str = "http://localhost:8003/api/v1/medical"

settings = PharmacySettings()
