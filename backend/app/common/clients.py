import sys
import httpx
import uuid as uuid_pkg
from app.common.nacos_client import nacos_manager

class BaseClient:
    @staticmethod
    def get_settings():
        # Check running microservice settings
        for mod_name in ["app.microservices.patient.config", "app.microservices.medical.config", 
                         "app.microservices.pharmacy.config", "app.microservices.billing.config", 
                         "app.microservices.auth.config"]:
            if mod_name in sys.modules:
                mod = sys.modules[mod_name]
                if hasattr(mod, "settings"):
                    return mod.settings
        try:
            from app.common.config import BaseMicroserviceSettings
            return BaseMicroserviceSettings()
        except ImportError:
            import os
            class DummySettings:
                AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8001/api/v1/auth")
                PATIENT_SERVICE_URL = os.getenv("PATIENT_SERVICE_URL", "http://localhost:8002/api/v1/patient")
                MEDICAL_SERVICE_URL = os.getenv("MEDICAL_SERVICE_URL", "http://localhost:8003/api/v1/medical")
                PHARMACY_SERVICE_URL = os.getenv("PHARMACY_SERVICE_URL", "http://localhost:8004/api/v1/pharmacy")
                BILLING_SERVICE_URL = os.getenv("BILLING_SERVICE_URL", "http://localhost:8005/api/v1/billing")
            return DummySettings()

    @staticmethod
    def get_url(service_name: str) -> str:
        s = BaseClient.get_settings()
        attr = f"{service_name.upper()}_SERVICE_URL"
        fallback = getattr(s, attr, f"http://localhost:8000/api/v1/{service_name}")
        

        app_name = f"{service_name}-service"
        
        # Try to infer base_fallback from fallback URL
        base_fallback = fallback.rsplit(f"/api/v1/{service_name}", 1)[0] if f"/api/v1/{service_name}" in fallback else fallback
        
        base_url = nacos_manager.get_service_url(app_name, base_fallback)
        if base_url.endswith("/"):
            base_url = base_url[:-1]
            
        return f"{base_url}/api/v1/{service_name}"

    @staticmethod
    async def get(url: str, params: dict = None):
        async with httpx.AsyncClient() as client:
            resp = await client.get(url, params=params)
            if resp.status_code == 200:
                return resp.json()["data"]
            return None

    @staticmethod
    async def put(url: str, params: dict = None):
        async with httpx.AsyncClient() as client:
            resp = await client.put(url, params=params)
            if resp.status_code == 200:
                return resp.json()["data"]
            return None

    @staticmethod
    async def post(url: str, json_data: dict = None):
        async with httpx.AsyncClient() as client:
            resp = await client.post(url, json=json_data)
            if resp.status_code in (200, 201):
                return resp.json()["data"]
            return None


class AuthClient:
    @staticmethod
    async def get_employee(uuid: uuid_pkg.UUID):
        url = f"{BaseClient.get_url('auth')}/employee/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_regist_level(uuid: str):
        url = f"{BaseClient.get_url('auth')}/regist-level/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_department(uuid: str):
        url = f"{BaseClient.get_url('auth')}/department/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_department_by_code(code: str):
        url = f"{BaseClient.get_url('auth')}/department/code/{code}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_clinic_room(uuid: str):
        url = f"{BaseClient.get_url('auth')}/clinic-room/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_clinic_room_by_name(name: str):
        url = f"{BaseClient.get_url('auth')}/clinic-room/name/{name}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_doctors_by_department(dept_uuid: str):
        url = f"{BaseClient.get_url('auth')}/doctors?dept_uuid={dept_uuid}"
        res = await BaseClient.get(url)
        return res if res is not None else []

    @staticmethod
    async def search_similar_doctors(dept_id: int, gender_preference: str, query_vector: list[float], limit: int = 5):
        url = f"{BaseClient.get_url('auth')}/doctors/search-similar"
        payload = {
            "dept_id": dept_id,
            "gender_preference": gender_preference,
            "query_vector": query_vector,
            "limit": limit
        }
        res = await BaseClient.post(url, json_data=payload)
        return res if res is not None else []

    @staticmethod
    async def get_settle_category_by_code(code: str):
        url = f"{BaseClient.get_url('auth')}/settle-category/code/{code}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_employees_by_dept_type(dept_type: str):
        url = f"{BaseClient.get_url('auth')}/employees/by-dept-type/{dept_type}"
        res = await BaseClient.get(url)
        return res if res is not None else []


class PatientClient:
    @staticmethod
    async def get_register(uuid: uuid_pkg.UUID):
        url = f"{BaseClient.get_url('patient')}/register/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_patient_registers(patient_uuid: str):
        url = f"{BaseClient.get_url('patient')}/{patient_uuid}/registers"
        res = await BaseClient.get(url)
        return res if res is not None else []

    @staticmethod
    async def update_register_state(uuid: uuid_pkg.UUID, visit_state: int):
        url = f"{BaseClient.get_url('patient')}/register/{uuid}/state"
        return await BaseClient.put(url, params={"visit_state": visit_state})

    @staticmethod
    async def get_today_available_employees(employee_uuids: list[str]):
        url = f"{BaseClient.get_url('patient')}/schedules/today-available"
        res = await BaseClient.post(url, json_data={"employee_uuids": employee_uuids})
        return res if res is not None else []

    @staticmethod
    async def submit_scheduling_application(employee_uuid: str, prompt: str):
        url = f"{BaseClient.get_url('patient')}/scheduling-applications"
        payload = {
            "employee_uuid": employee_uuid,
            "prompt": prompt
        }
        return await BaseClient.post(url, json_data=payload)


class MedicalClient:
    @staticmethod
    async def create_medical_record(register_uuid: uuid_pkg.UUID, readme: str = None, present: str = None):
        url = f"{BaseClient.get_url('medical')}/record"
        payload = {
            "register_uuid": str(register_uuid),
            "readme": readme,
            "present": present
        }
        return await BaseClient.post(url, json_data=payload)

    @staticmethod
    async def get_medical_record(register_uuid: uuid_pkg.UUID):
        url = f"{BaseClient.get_url('medical')}/record/{register_uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_medical_record_draft(register_uuid: uuid_pkg.UUID):
        url = f"{BaseClient.get_url('medical')}/record/draft/{register_uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_tech(uuid: str):
        url = f"{BaseClient.get_url('medical')}/tech/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_check_request(uuid: str):
        url = f"{BaseClient.get_url('medical')}/check/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_inspection_request(uuid: str):
        url = f"{BaseClient.get_url('medical')}/inspection/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_disposal_request(uuid: str):
        url = f"{BaseClient.get_url('medical')}/disposal/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def update_check_state(uuid: str, state: str):
        url = f"{BaseClient.get_url('medical')}/check/{uuid}/state"
        return await BaseClient.put(url, params={"state": state})

    @staticmethod
    async def update_inspection_state(uuid: str, state: str):
        url = f"{BaseClient.get_url('medical')}/inspection/{uuid}/state"
        return await BaseClient.put(url, params={"state": state})

    @staticmethod
    async def update_disposal_state(uuid: str, state: str):
        url = f"{BaseClient.get_url('medical')}/disposal/{uuid}/state"
        return await BaseClient.put(url, params={"state": state})

    @staticmethod
    async def get_requests_batch(check_uuids: list[str], inspection_uuids: list[str], disposal_uuids: list[str]):
        url = f"{BaseClient.get_url('medical')}/requests/batch"
        payload = {
            "check_uuids": check_uuids,
            "inspection_uuids": inspection_uuids,
            "disposal_uuids": disposal_uuids
        }
        res = await BaseClient.post(url, json_data=payload)
        return res if res is not None else {"checks": {}, "inspections": {}, "disposals": {}}


class PharmacyClient:
    @staticmethod
    async def get_drug(uuid: str):
        url = f"{BaseClient.get_url('pharmacy')}/drug/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def get_prescription_item(uuid: str):
        url = f"{BaseClient.get_url('pharmacy')}/prescription-item/{uuid}"
        return await BaseClient.get(url)

    @staticmethod
    async def update_prescription_state(item_uuid: str, state: str):
        url = f"{BaseClient.get_url('pharmacy')}/prescription-item/{item_uuid}/state"
        return await BaseClient.put(url, params={"state": state})

    @staticmethod
    async def get_prescription_items_batch(item_uuids: list[str]):
        url = f"{BaseClient.get_url('pharmacy')}/prescription-items/batch"
        res = await BaseClient.post(url, json_data={"item_uuids": item_uuids})
        return res if res is not None else []

class BillingClient:
    @staticmethod
    async def get_bills_by_register(register_uuid: uuid_pkg.UUID):
        url = f"{BaseClient.get_url('bill')}/register/{register_uuid}"
        res = await BaseClient.get(url)
        return res if res is not None else []
