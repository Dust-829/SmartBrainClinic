from app.common.config import BaseMicroserviceSettings

class BillingSettings(BaseMicroserviceSettings):
    SERVICE_NAME: str = "billing-service"
    SERVICE_PORT: int = 8005
    PATIENT_SERVICE_URL: str = "http://localhost:8002/api/v1/patient"
    MEDICAL_SERVICE_URL: str = "http://localhost:8003/api/v1/medical"
    PHARMACY_SERVICE_URL: str = "http://localhost:8004/api/v1/pharmacy"

settings = BillingSettings()
