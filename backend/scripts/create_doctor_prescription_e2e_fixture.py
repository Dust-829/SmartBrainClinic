"""Create isolated data for the doctor prescription browser regression."""

from __future__ import annotations

import asyncio
import json
import os
import sys
import uuid
from datetime import date, timedelta
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from test_full_workflow import (  # noqa: E402
    AUTH_URL,
    PATIENT_URL,
    E2EClient,
    check_health,
    ensure_seed_data,
    load_env_file,
    register_state,
    start_reception,
    wait_for_auto_medical_draft,
)


FIXTURE_PREFIX = "E2E Prescription"
FIXTURE_SCHEDULE_DATE = date.today() + timedelta(days=1)


def get_admin_headers(api: E2EClient) -> dict[str, str]:
    load_env_file()
    staff_code = str(os.getenv("ADMIN_BOOTSTRAP_STAFF_CODE") or "").strip()
    password = str(os.getenv("ADMIN_BOOTSTRAP_PASSWORD") or "").strip()
    if not staff_code or not password:
        raise SystemExit("Missing ADMIN_BOOTSTRAP_STAFF_CODE or ADMIN_BOOTSTRAP_PASSWORD")

    login = api.request(
        "POST",
        f"{AUTH_URL}/admin/login",
        json={"staff_code": staff_code, "password": password},
    )
    access_token = str(login.get("access_token") or "").strip()
    if not access_token:
        raise AssertionError("Administrator login did not return an access token")
    return {"Authorization": f"Bearer {access_token}"}


def create_fixture(api: E2EClient, admin_headers: dict[str, str]) -> dict[str, Any]:
    run_id = uuid.uuid4().hex[:10]
    doctor = api.request(
        "POST",
        f"{AUTH_URL}/employee",
        expected=(200, 201),
        headers=admin_headers,
        json={
            "realname": f"{FIXTURE_PREFIX} Doctor {run_id}",
            "password": "E2Epass123",
            "dept_code": "XNK",
            "regist_level_code": "E2E_LEVEL",
            "gender": "\u7537",
            "expertise": "prescription browser regression fixture",
            "ai_eval_score": 5.0,
        },
    )
    doctor_uuid = doctor["uuid"]

    api.request(
        "PUT",
        f"{PATIENT_URL}/admin/scheduling-actuals",
        json={
            "employee_uuid": doctor_uuid,
            "schedule_date": FIXTURE_SCHEDULE_DATE.isoformat(),
            "noon": "\u4e0a\u5348",
            "regist_quota": 8,
        },
    )
    schedules = api.request("GET", f"{PATIENT_URL}/schedules", params={"employee_uuid": doctor_uuid})
    if not schedules:
        raise AssertionError("Fixture doctor has no available schedules")

    time_slot_uuid = next(
        (
            slot["uuid"]
            for schedule in schedules
            for slot in schedule.get("time_slots", [])
            if not slot.get("is_booked")
        ),
        None,
    )
    if not time_slot_uuid:
        raise AssertionError("Fixture doctor has no unbooked time slot")

    patient = api.request(
        "POST",
        PATIENT_URL,
        expected=(200, 201),
        json={
            "real_name": f"{FIXTURE_PREFIX} Patient {run_id}",
            "gender": "\u7537",
            "card_number": f"E2EPRES{run_id}",
            "birthdate": "1990-01-01",
            "home_address": "E2E browser regression fixture",
        },
    )
    register = api.request(
        "POST",
        f"{PATIENT_URL}/online-register",
        expected=(200, 201),
        json={
            "patient_uuid": patient["uuid"],
            "employee_uuid": doctor_uuid,
            "scheduling_time_slot_uuid": time_slot_uuid,
            "symptoms": "headache and high blood pressure for prescription regression",
        },
    )
    register_uuid = register["register_uuid"]
    api.request(
        "POST",
        f"{PATIENT_URL}/online-register/pay",
        json={
            "register_uuid": register_uuid,
            "pay_method": "\u5fae\u4fe1",
            "amount": float(register["regist_money"]),
            "idempotency_key": f"e2e-prescription-register-{run_id}",
        },
    )
    wait_for_auto_medical_draft(api, register_uuid, "")
    start_reception(api, register_uuid)
    if register_state(api, register_uuid) != 2:
        raise AssertionError("Fixture register did not enter reception")

    return {
        "fixture_prefix": FIXTURE_PREFIX,
        "run_id": run_id,
        "doctor_uuid": doctor_uuid,
        "register_uuid": register_uuid,
        "schedule_date": FIXTURE_SCHEDULE_DATE.isoformat(),
        "doctor_login_url": "/doctor/login",
        "encounter_url": f"/doctor/encounter/{register_uuid}",
    }


def main() -> None:
    asyncio.run(ensure_seed_data())
    api = E2EClient()
    try:
        check_health(api)
        print(json.dumps(create_fixture(api, get_admin_headers(api)), ensure_ascii=False))
    finally:
        api.close()


if __name__ == "__main__":
    main()
