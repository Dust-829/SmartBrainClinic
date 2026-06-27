"""
End-to-end workflow checks for SmartBrainClinic microservices.

The script prepares minimal dictionary data directly in PostgreSQL, then drives
business workflows through HTTP APIs. It intentionally fails fast and does not
fall back to fake IDs, so a passing run means the current service chain really
accepted the workflow.
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import os
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from datetime import date, timedelta
from decimal import Decimal
from pathlib import Path
from typing import Any, Callable

import asyncpg
import httpx


ROOT = Path(__file__).resolve().parent

AUTH_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8001/api/v1/auth")
PATIENT_URL = os.getenv("PATIENT_SERVICE_URL", "http://localhost:8002/api/v1/patient")
MEDICAL_URL = os.getenv("MEDICAL_SERVICE_URL", "http://localhost:8003/api/v1/medical")
PHARMACY_URL = os.getenv("PHARMACY_SERVICE_URL", "http://localhost:8004/api/v1/pharmacy")
BILL_URL = os.getenv("BILLING_SERVICE_URL", "http://localhost:8005/api/v1/bill")

REQUEST_TIMEOUT = 60.0
POLL_TIMEOUT = 45.0
AUTO_DRAFT_TIMEOUT = 90.0

TRIAGE_DEPARTMENTS = {
    "SJWK": "神经外科",
    "XNK": "心内科",
    "GK": "骨科",
    "EK": "儿科",
    "FCK": "妇产科",
}


@dataclass(frozen=True)
class SeedData:
    tech_id: int
    drug_id: int


def load_env_file() -> None:
    env_path = ROOT / ".env"
    if not env_path.exists():
        return

    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


async def ensure_seed_data() -> SeedData:
    load_env_file()
    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST", "localhost") or "localhost",
        port=int(os.getenv("DB_PORT", "5432") or "5432"),
        database=os.getenv("DB_NAME", "his_db") or "his_db",
        user=os.getenv("DB_USER", "lujuntong") or "lujuntong",
        password=os.getenv("DB_PASSWORD", ""),
    )
    try:
        await apply_migrations(conn)
        await sync_id_sequences(conn)
        await conn.execute(
            """
            INSERT INTO department (uuid, dept_code, dept_name, dept_type, delmark)
            VALUES ($1, 'E2E_DEPT', 'E2E Test Department', '门诊', 1)
            ON CONFLICT (dept_code)
            DO UPDATE SET dept_name = EXCLUDED.dept_name, dept_type = EXCLUDED.dept_type, delmark = 1
            """,
            uuid.uuid4(),
        )
        for dept_code, dept_name in TRIAGE_DEPARTMENTS.items():
            await conn.execute(
                """
                INSERT INTO department (uuid, dept_code, dept_name, dept_type, delmark)
                VALUES ($1, $2, $3, '门诊', 1)
                ON CONFLICT (dept_code)
                DO UPDATE SET dept_name = EXCLUDED.dept_name, dept_type = EXCLUDED.dept_type, delmark = 1
                """,
                uuid.uuid4(),
                dept_code,
                dept_name,
            )
        await conn.execute(
            """
            INSERT INTO regist_level (uuid, regist_code, regist_name, regist_fee, delmark)
            VALUES ($1, 'E2E_LEVEL', 'E2E Normal Visit', 10.00, 1)
            ON CONFLICT (regist_code)
            DO UPDATE SET regist_name = EXCLUDED.regist_name, regist_fee = EXCLUDED.regist_fee, delmark = 1
            """,
            uuid.uuid4(),
        )
        await conn.execute(
            """
            INSERT INTO settle_category (uuid, settle_code, settle_name, delmark)
            VALUES ($1, 'ZF', 'Self Pay', 1)
            ON CONFLICT (settle_code)
            DO UPDATE SET settle_name = EXCLUDED.settle_name, delmark = 1
            """,
            uuid.uuid4(),
        )
        tech = await conn.fetchrow(
            """
            INSERT INTO medical_technology (uuid, tech_code, tech_name, tech_type, price, delmark)
            VALUES ($1, 'E2E_CHECK', 'E2E Cranial CT', '检查', 30.00, 1)
            ON CONFLICT (tech_code)
            DO UPDATE SET tech_name = EXCLUDED.tech_name, tech_type = EXCLUDED.tech_type,
                          price = EXCLUDED.price, delmark = 1
            RETURNING id
            """,
            uuid.uuid4(),
        )
        drug = await conn.fetchrow(
            """
            INSERT INTO drug_info (
                uuid, drug_code, drug_name, specification, unit, price, stock, min_stock_limit, delmark
            )
            VALUES ($1, 'E2E_DRUG', 'E2E Test Drug', '10mg*10', 'box', 5.00, 1000, 10, 1)
            ON CONFLICT (drug_code)
            DO UPDATE SET drug_name = EXCLUDED.drug_name, specification = EXCLUDED.specification,
                          unit = EXCLUDED.unit, price = EXCLUDED.price, stock = 1000,
                          min_stock_limit = EXCLUDED.min_stock_limit, delmark = 1
            RETURNING id
            """,
            uuid.uuid4(),
        )
        return SeedData(tech_id=tech["id"], drug_id=drug["id"])
    finally:
        await conn.close()


async def apply_migrations(conn: asyncpg.Connection) -> None:
    for migration in sorted((ROOT / "migrations").glob("*.sql")):
        await conn.execute(migration.read_text(encoding="utf-8"))


async def sync_id_sequences(conn: asyncpg.Connection) -> None:
    rows = await conn.fetch(
        """
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND column_name = 'id'
        ORDER BY table_name
        """
    )
    for row in rows:
        table_name = row["table_name"]
        sequence_name = await conn.fetchval(
            "SELECT pg_get_serial_sequence($1, 'id')",
            f"public.{table_name}",
        )
        if not sequence_name:
            continue

        quoted_table = quote_ident(table_name)
        max_id = await conn.fetchval(f"SELECT COALESCE(MAX(id), 0) FROM public.{quoted_table}")
        if max_id:
            await conn.execute("SELECT setval($1, $2, true)", sequence_name, max_id)
        else:
            await conn.execute("SELECT setval($1, 1, false)", sequence_name)


def quote_ident(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


async def get_drug_stock(drug_id: int) -> int:
    load_env_file()
    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST", "localhost") or "localhost",
        port=int(os.getenv("DB_PORT", "5432") or "5432"),
        database=os.getenv("DB_NAME", "his_db") or "his_db",
        user=os.getenv("DB_USER", "lujuntong") or "lujuntong",
        password=os.getenv("DB_PASSWORD", ""),
    )
    try:
        value = await conn.fetchval("SELECT stock FROM drug_info WHERE id = $1", drug_id)
        return int(value)
    finally:
        await conn.close()


async def list_pending_scheduling_applications(employee_uuid: str, prompt: str) -> list[dict[str, Any]]:
    load_env_file()
    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST", "localhost") or "localhost",
        port=int(os.getenv("DB_PORT", "5432") or "5432"),
        database=os.getenv("DB_NAME", "his_db") or "his_db",
        user=os.getenv("DB_USER", "lujuntong") or "lujuntong",
        password=os.getenv("DB_PASSWORD", ""),
    )
    try:
        rows = await conn.fetch(
            """
            SELECT uuid, status, prompt
            FROM scheduling_application
            WHERE employee_uuid = $1::uuid
              AND prompt = $2
              AND status = 'pending'
            ORDER BY created_at, id
            """,
            employee_uuid,
            prompt,
        )
        return [dict(row) for row in rows]
    finally:
        await conn.close()


async def count_bill_details_for_item(item_type: str, item_source_id: str) -> int:
    load_env_file()
    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST", "localhost") or "localhost",
        port=int(os.getenv("DB_PORT", "5432") or "5432"),
        database=os.getenv("DB_NAME", "his_db") or "his_db",
        user=os.getenv("DB_USER", "lujuntong") or "lujuntong",
        password=os.getenv("DB_PASSWORD", ""),
    )
    try:
        value = await conn.fetchval(
            """
            SELECT COUNT(*)
            FROM outpatient_bill_detail
            WHERE item_type = $1 AND item_source_id = $2
            """,
            item_type,
            item_source_id,
        )
        return int(value)
    finally:
        await conn.close()


async def seed_stale_idempotency(scope: str, idempotency_key: str, request_payload: dict[str, Any]) -> None:
    load_env_file()
    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST", "localhost") or "localhost",
        port=int(os.getenv("DB_PORT", "5432") or "5432"),
        database=os.getenv("DB_NAME", "his_db") or "his_db",
        user=os.getenv("DB_USER", "lujuntong") or "lujuntong",
        password=os.getenv("DB_PASSWORD", ""),
    )
    try:
        request_hash = hashlib.sha256(
            json.dumps(request_payload, ensure_ascii=False, sort_keys=True, default=str).encode("utf-8")
        ).hexdigest()
        await conn.execute(
            """
            INSERT INTO idempotency_record (
                scope, idempotency_key, request_hash, status, created_at, updated_at
            )
            VALUES ($1, $2, $3, 'processing', CURRENT_TIMESTAMP - INTERVAL '10 minutes',
                    CURRENT_TIMESTAMP - INTERVAL '10 minutes')
            ON CONFLICT (scope, idempotency_key)
            DO UPDATE SET request_hash = EXCLUDED.request_hash,
                          status = 'processing',
                          response_body = NULL,
                          updated_at = CURRENT_TIMESTAMP - INTERVAL '10 minutes'
            """,
            scope,
            idempotency_key,
            request_hash,
        )
    finally:
        await conn.close()


async def seed_active_refund_in_progress(bill_code: str, active_idempotency_key: str) -> None:
    load_env_file()
    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST", "localhost") or "localhost",
        port=int(os.getenv("DB_PORT", "5432") or "5432"),
        database=os.getenv("DB_NAME", "his_db") or "his_db",
        user=os.getenv("DB_USER", "lujuntong") or "lujuntong",
        password=os.getenv("DB_PASSWORD", ""),
    )
    try:
        request_payload = {"bill_code": bill_code}
        request_hash = hashlib.sha256(
            json.dumps(request_payload, ensure_ascii=False, sort_keys=True, default=str).encode("utf-8")
        ).hexdigest()
        await conn.execute(
            "UPDATE outpatient_bill SET bill_state = '退费中' WHERE bill_code = $1",
            bill_code,
        )
        await conn.execute(
            """
            INSERT INTO idempotency_record (
                scope, idempotency_key, request_hash, status, created_at, updated_at
            )
            VALUES ('billing.refund_bill', $1, $2, 'processing', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT (scope, idempotency_key)
            DO UPDATE SET request_hash = EXCLUDED.request_hash,
                          status = 'processing',
                          response_body = NULL,
                          updated_at = CURRENT_TIMESTAMP
            """,
            active_idempotency_key,
            request_hash,
        )
    finally:
        await conn.close()


async def set_employee_expertise_vector(employee_uuid: str) -> None:
    load_env_file()
    conn = await asyncpg.connect(
        host=os.getenv("DB_HOST", "localhost") or "localhost",
        port=int(os.getenv("DB_PORT", "5432") or "5432"),
        database=os.getenv("DB_NAME", "his_db") or "his_db",
        user=os.getenv("DB_USER", "lujuntong") or "lujuntong",
        password=os.getenv("DB_PASSWORD", ""),
    )
    try:
        normalized_vector = "[" + ",".join(["0.03125"] * 1024) + "]"
        await conn.execute(
            """
            UPDATE employee
            SET expertise_vector = $2::vector
            WHERE uuid = $1::uuid
            """,
            employee_uuid,
            normalized_vector,
        )
    finally:
        await conn.close()


class E2EClient:
    def __init__(self) -> None:
        self.client = httpx.Client(timeout=REQUEST_TIMEOUT)

    def close(self) -> None:
        self.client.close()

    def request(
        self,
        method: str,
        url: str,
        *,
        expected: tuple[int, ...] = (200,),
        **kwargs: Any,
    ) -> Any:
        response = self.client.request(method, url, **kwargs)
        if response.status_code not in expected:
            raise AssertionError(
                f"{method} {url} expected {expected}, got {response.status_code}: {response.text}"
            )
        if not response.content:
            return None
        data = response.json()
        return data.get("data", data)

    def expect_failure(
        self,
        method: str,
        url: str,
        *,
        expected: tuple[int, ...] = (400,),
        **kwargs: Any,
    ) -> None:
        response = self.client.request(method, url, **kwargs)
        if response.status_code not in expected:
            raise AssertionError(
                f"{method} {url} expected failure {expected}, got {response.status_code}: {response.text}"
            )


def wait_until(description: str, predicate: Callable[[], bool], timeout: float = POLL_TIMEOUT) -> None:
    deadline = time.monotonic() + timeout
    last_error: Exception | None = None
    while time.monotonic() < deadline:
        try:
            if predicate():
                return
        except Exception as exc:
            last_error = exc
        time.sleep(1)
    if last_error:
        raise AssertionError(f"Timed out waiting for {description}; last error: {last_error}") from last_error
    raise AssertionError(f"Timed out waiting for {description}")


def check_health(api: E2EClient) -> None:
    health_urls = [
        "http://localhost:8001/health",
        "http://localhost:8002/health",
        "http://localhost:8003/health",
        "http://localhost:8004/health",
        "http://localhost:8005/health",
        "http://localhost:8000/health",
    ]
    for url in health_urls:
        api.request("GET", url)


def wait_for_auto_medical_draft(api: E2EClient, register_uuid: str, expected_hint: str) -> dict[str, Any]:
    holder: dict[str, Any] = {}

    def draft_is_ready() -> bool:
        draft = api.request("GET", f"{MEDICAL_URL}/record/draft/{register_uuid}")
        if draft.get("is_doctor_confirmed"):
            raise AssertionError("Auto-generated medical draft should not be doctor-confirmed yet")
        draft_text = " ".join(
            str(draft.get(field) or "")
            for field in ("readme", "present", "history", "allergy", "proposal", "cure")
        )
        if expected_hint and expected_hint not in draft_text:
            raise AssertionError(f"Auto-generated medical draft does not contain expected hint {expected_hint}")
        holder["draft"] = draft
        return True

    wait_until(
        "auto-generated medical record draft",
        draft_is_ready,
        timeout=AUTO_DRAFT_TIMEOUT,
    )
    return holder["draft"]


def create_ai_guided_visit(api: E2EClient, seed: SeedData) -> dict[str, Any]:
    run_id = uuid.uuid4().hex[:10]
    symptoms = "心悸两天，活动后加重，既往有高血压史，想咨询应该挂哪个科。"
    triage = api.request(
        "POST",
        f"{PATIENT_URL}/triage",
        json={"messages": [{"role": "user", "content": symptoms}]},
    )
    triage_data = triage.get("data", {})
    dept_code = triage_data.get("recommended_dept_code")
    if not triage_data.get("dept_determined") or dept_code not in TRIAGE_DEPARTMENTS:
        raise AssertionError(f"AI triage should determine a supported department, got {triage}")
    if not triage.get("validated"):
        raise AssertionError(f"AI triage result should pass validation, got {triage}")
    confidence = triage.get("confidence")
    if confidence is None or float(confidence) <= 0:
        raise AssertionError(f"AI triage should return a positive confidence, got {triage}")

    doctor = api.request(
        "POST",
        f"{AUTH_URL}/employee",
        expected=(200, 201),
        json={
            "realname": f"E2E AI Doctor {run_id}",
            "password": "123456",
            "dept_code": dept_code,
            "regist_level_code": "E2E_LEVEL",
            "gender": "男",
            "expertise": f"{TRIAGE_DEPARTMENTS[dept_code]}, 心悸, 高血压, 门诊 e2e",
            "ai_eval_score": 4.8,
        },
    )
    doctor_uuid = doctor["uuid"]
    asyncio.run(set_employee_expertise_vector(doctor_uuid))

    schedule_date = (date.today() + timedelta(days=3)).isoformat()
    api.request(
        "PUT",
        f"{PATIENT_URL}/admin/scheduling-actuals",
        json={
            "employee_uuid": doctor_uuid,
            "schedule_date": schedule_date,
            "noon": "上午",
            "regist_quota": 8,
        },
    )

    recommendations = api.request(
        "POST",
        f"{PATIENT_URL}/recommend-doctors",
        json={
            "symptoms": triage_data.get("symptom_summary") or symptoms,
            "dept_code": dept_code,
            "gender_preference": triage_data.get("gender_preference") or "不限",
            "limit": 3,
        },
    )
    if not recommendations:
        raise AssertionError("AI doctor recommendation should return at least one available doctor")

    recommended = recommendations[0]
    recommended_doctor_uuid = recommended["doctor_uuid"]
    schedules = api.request("GET", f"{PATIENT_URL}/schedules", params={"employee_uuid": recommended_doctor_uuid})
    if not schedules:
        raise AssertionError("Recommended doctor should have available schedules")
    time_slot_uuid = None
    for schedule in schedules:
        for slot in schedule["time_slots"]:
            if not slot["is_booked"]:
                time_slot_uuid = slot["uuid"]
                break
        if time_slot_uuid:
            break
    if not time_slot_uuid:
        raise AssertionError("Recommended doctor should have an unbooked time slot")

    patient = api.request(
        "POST",
        PATIENT_URL,
        expected=(200, 201),
        json={
            "real_name": f"E2E AI Patient {run_id}",
            "gender": "男",
            "card_number": f"E2EAI{run_id}",
            "birthdate": "1988-03-15",
            "home_address": "E2E AI workflow address",
        },
    )
    patient_uuid = patient["uuid"]

    register = api.request(
        "POST",
        f"{PATIENT_URL}/online-register",
        expected=(200, 201),
        json={
            "patient_uuid": patient_uuid,
            "employee_uuid": recommended_doctor_uuid,
            "scheduling_time_slot_uuid": time_slot_uuid,
            "symptoms": triage_data.get("symptom_summary") or symptoms,
        },
    )
    register_uuid = register["register_uuid"]
    api.request(
        "POST",
        f"{PATIENT_URL}/online-register/pay",
        json={
            "register_uuid": register_uuid,
            "pay_method": "微信",
            "amount": float(Decimal(str(register["regist_money"]))),
            "idempotency_key": f"ai-pay-register-{run_id}",
        },
    )
    wait_for_auto_medical_draft(api, register_uuid, "心悸")
    api.request(
        "PUT",
        f"{MEDICAL_URL}/record/draft/{register_uuid}/confirm",
        json={
            "readme": "心悸",
            "present": triage_data.get("symptom_summary") or symptoms,
            "history": "既往高血压史",
            "physique": "生命体征平稳",
            "diagnosis": "心悸待查",
            "allergy": "无",
            "proposal": "门诊随诊，必要时进一步检查",
            "cure": "休息观察",
        },
    )
    return {"register_uuid": register_uuid, "doctor_uuid": recommended_doctor_uuid, "seed": seed}


def create_base_visit(api: E2EClient, seed: SeedData) -> dict[str, Any]:
    run_id = uuid.uuid4().hex[:10]
    doctor = api.request(
        "POST",
        f"{AUTH_URL}/employee",
        expected=(200, 201),
        json={
            "realname": f"E2E Doctor {run_id}",
            "password": "123456",
            "dept_code": "E2E_DEPT",
            "regist_level_code": "E2E_LEVEL",
            "gender": "男",
            "expertise": "headache, cranial CT, outpatient e2e",
            "ai_eval_score": 5.0,
        },
    )
    doctor_uuid = doctor["uuid"]
    schedule_date = (date.today() + timedelta(days=7)).isoformat()
    api.request(
        "PUT",
        f"{PATIENT_URL}/admin/scheduling-actuals",
        json={
            "employee_uuid": doctor_uuid,
            "schedule_date": schedule_date,
            "noon": "上午",
            "regist_quota": 8,
        },
    )
    schedules = api.request("GET", f"{PATIENT_URL}/schedules", params={"employee_uuid": doctor_uuid})
    if not schedules or not schedules[0]["time_slots"]:
        raise AssertionError("No available schedule slots after schedule setup")
    time_slot_uuid = next(slot["uuid"] for slot in schedules[0]["time_slots"] if not slot["is_booked"])

    patient = api.request(
        "POST",
        PATIENT_URL,
        expected=(200, 201),
        json={
            "real_name": f"E2E Patient {run_id}",
            "gender": "男",
            "card_number": f"E2E{run_id}",
            "birthdate": "1990-01-01",
            "home_address": "E2E test address",
        },
    )
    patient_uuid = patient["uuid"]

    register = api.request(
        "POST",
        f"{PATIENT_URL}/online-register",
        expected=(200, 201),
        json={
            "patient_uuid": patient_uuid,
            "employee_uuid": doctor_uuid,
            "scheduling_time_slot_uuid": time_slot_uuid,
            "symptoms": "headache and dizziness for e2e workflow",
        },
    )
    register_uuid = register["register_uuid"]

    api.request(
        "POST",
        f"{PATIENT_URL}/online-register/pay",
        json={
            "register_uuid": register_uuid,
            "pay_method": "微信",
            "amount": float(Decimal(str(register["regist_money"]))),
            "idempotency_key": f"pay-register-{run_id}",
        },
    )
    wait_for_auto_medical_draft(api, register_uuid, "headache")
    replay_payment = api.request(
        "POST",
        f"{PATIENT_URL}/online-register/pay",
        json={
            "register_uuid": register_uuid,
            "pay_method": "微信",
            "amount": float(Decimal(str(register["regist_money"]))),
            "idempotency_key": f"pay-register-{run_id}",
        },
    )
    if replay_payment["register_uuid"] != register_uuid:
        raise AssertionError("Idempotent register payment replay did not return the original register")
    api.expect_failure(
        "POST",
        f"{PATIENT_URL}/online-register/pay",
        json={
            "register_uuid": register_uuid,
            "pay_method": "微信",
            "amount": float(Decimal(str(register["regist_money"]))),
        },
    )
    api.request(
        "PUT",
        f"{MEDICAL_URL}/record/draft/{register_uuid}/confirm",
        json={
            "readme": "headache",
            "present": "headache and dizziness",
            "history": "no major medical history",
            "physique": "stable vital signs",
            "diagnosis": "tension headache",
            "allergy": "无",
            "proposal": "follow up if symptoms worsen",
            "cure": "rest and observation",
        },
    )
    return {"register_uuid": register_uuid, "doctor_uuid": doctor_uuid, "seed": seed}


def create_check(api: E2EClient, register_uuid: str, tech_id: int) -> str:
    check = api.request(
        "POST",
        f"{MEDICAL_URL}/check",
        expected=(200, 201),
        json={
            "register_uuid": register_uuid,
            "medical_technology_id": tech_id,
            "check_info": "cranial CT",
            "check_position": "head",
        },
    )
    return check["uuid"]


def create_prescription(
    api: E2EClient,
    register_uuid: str,
    drug_id: int,
    number: int = 1,
    numbers: list[int] | None = None,
) -> dict[str, Any]:
    drug_numbers = numbers if numbers is not None else [number]
    prescription = api.request(
        "POST",
        f"{PHARMACY_URL}/prescription",
        expected=(200, 201),
        json={
            "register_uuid": register_uuid,
            "items": [
                {
                    "drug_id": drug_id,
                    "drug_usage": "oral, e2e test usage",
                    "drug_number": drug_number,
                }
                for drug_number in drug_numbers
            ],
        },
    )
    item_uuids = [item["uuid"] for item in prescription["items"]]
    return {
        "prescription_uuid": prescription["uuid"],
        "item_uuid": item_uuids[0],
        "item_uuids": item_uuids,
    }


def pay_bill(
    api: E2EClient,
    register_uuid: str,
    items: list[dict[str, str]],
    *,
    idempotency_key: str,
) -> dict[str, Any]:
    first = api.request(
        "POST",
        f"{BILL_URL}/pay",
        expected=(200, 201),
        json={
            "register_uuid": register_uuid,
            "item_ids": items,
            "pay_method": "微信",
            "idempotency_key": idempotency_key,
        },
    )
    replay = api.request(
        "POST",
        f"{BILL_URL}/pay",
        expected=(200, 201),
        json={
            "register_uuid": register_uuid,
            "item_ids": items,
            "pay_method": "微信",
            "idempotency_key": idempotency_key,
        },
    )
    if replay["bill_code"] != first["bill_code"]:
        raise AssertionError("Idempotent bill payment replay created a different bill")
    return first


def check_state(api: E2EClient, check_uuid: str) -> str:
    return api.request("GET", f"{MEDICAL_URL}/check/{check_uuid}")["check_state"]


def drug_state(api: E2EClient, item_uuid: str) -> str:
    return api.request("GET", f"{PHARMACY_URL}/prescription-item/{item_uuid}")["drug_state"]


def assert_bill_state(api: E2EClient, register_uuid: str, bill_code: str, expected_state: str) -> None:
    bills = api.request("GET", f"{BILL_URL}/register/{register_uuid}")
    for bill in bills:
        if bill["bill_code"] == bill_code:
            if bill["bill_state"] != expected_state:
                raise AssertionError(
                    f"Bill {bill_code} expected state {expected_state}, got {bill['bill_state']}"
                )
            return
    raise AssertionError(f"Bill {bill_code} not found")


def run_agent_scheduling_confirmation_flow(api: E2EClient, visit: dict[str, Any]) -> None:
    doctor_uuid = visit["doctor_uuid"]
    run_id = uuid.uuid4().hex[:10]
    application_prompt = f"E2E_AGENT_SCHEDULE_{run_id}: 申请下周一上午停诊，原因是参加院内培训。"
    tool_instruction = (
        "请为我提交排班调整申请。"
        f"调用 submit_scheduling_application 工具时，prompt 参数必须严格等于：{application_prompt}"
    )

    before_rows = asyncio.run(list_pending_scheduling_applications(doctor_uuid, application_prompt))
    preview = api.request(
        "POST",
        f"{MEDICAL_URL}/record/ai-assistant",
        json={
            "employee_uuid": doctor_uuid,
            "question": tool_instruction,
            "confirm_action": False,
        },
    )
    after_preview_rows = asyncio.run(list_pending_scheduling_applications(doctor_uuid, application_prompt))
    if len(after_preview_rows) != len(before_rows):
        raise AssertionError("Unconfirmed Agent scheduling request should not create a scheduling application")
    preview_answer = preview.get("answer", "")
    if "确认" not in preview_answer and "尚未提交" not in preview_answer:
        raise AssertionError(f"Unconfirmed Agent scheduling response should ask for confirmation: {preview_answer}")

    confirm_question = (
        "我确认提交这个排班调整申请。"
        f"调用 submit_scheduling_application 工具时，prompt 参数必须严格等于：{application_prompt}"
    )
    confirmed = api.request(
        "POST",
        f"{MEDICAL_URL}/record/ai-assistant",
        json={
            "employee_uuid": doctor_uuid,
            "question": confirm_question,
            "confirm_action": True,
        },
    )
    confirmed_answer = confirmed.get("answer", "")
    if "提交" not in confirmed_answer and "申请" not in confirmed_answer:
        raise AssertionError(f"Confirmed Agent scheduling response should mention submission: {confirmed_answer}")

    def one_application_created() -> bool:
        rows = asyncio.run(list_pending_scheduling_applications(doctor_uuid, application_prompt))
        return len(rows) == len(before_rows) + 1

    wait_until("confirmed Agent scheduling application", one_application_created)

    repeated = api.request(
        "POST",
        f"{MEDICAL_URL}/record/ai-assistant",
        json={
            "employee_uuid": doctor_uuid,
            "question": confirm_question,
            "confirm_action": True,
        },
    )
    repeated_answer = repeated.get("answer", "")
    if "申请" not in repeated_answer:
        raise AssertionError(f"Repeated confirmed Agent scheduling response should reference the application: {repeated_answer}")

    final_rows = asyncio.run(list_pending_scheduling_applications(doctor_uuid, application_prompt))
    if len(final_rows) != len(before_rows) + 1:
        raise AssertionError("Repeated confirmed Agent scheduling request should be deduplicated")


def run_registration_payment_order_refund_happy_path(api: E2EClient, visit: dict[str, Any]) -> None:
    register_uuid = visit["register_uuid"]
    seed = visit["seed"]

    register = api.request("GET", f"{PATIENT_URL}/register/{register_uuid}")
    if str(register.get("visit_state")) != "1":
        raise AssertionError(f"Register should be active after registration payment, got {register.get('visit_state')}")

    check_uuid = create_check(api, register_uuid, seed.tech_id)
    prescription = create_prescription(api, register_uuid, seed.drug_id)

    if check_state(api, check_uuid) != "未缴费":
        raise AssertionError("New check request should start as unpaid")
    if drug_state(api, prescription["item_uuid"]) != "开立":
        raise AssertionError("New prescription should start as prescribed")

    bill = pay_bill(
        api,
        register_uuid,
        [
            {"type": "检查", "id": check_uuid},
            {"type": "药品", "id": prescription["item_uuid"]},
        ],
        idempotency_key=f"happy-path-pay-{check_uuid}",
    )

    wait_until("happy path check paid", lambda: check_state(api, check_uuid) == "已缴费")
    wait_until("happy path drug paid", lambda: drug_state(api, prescription["item_uuid"]) == "已缴费")
    assert_bill_state(api, register_uuid, bill["bill_code"], "已收费")

    refund_key = f"happy-path-refund-{bill['bill_code']}"
    refund = api.request(
        "PUT",
        f"{BILL_URL}/{bill['bill_code']}/refund",
        headers={"Idempotency-Key": refund_key},
    )
    if refund["bill_state"] != "已退费":
        raise AssertionError(f"Happy path refund should finish as refunded, got {refund['bill_state']}")

    wait_until("happy path check refunded", lambda: check_state(api, check_uuid) == "已退费")
    wait_until("happy path drug refunded", lambda: drug_state(api, prescription["item_uuid"]) == "已退费")
    assert_bill_state(api, register_uuid, bill["bill_code"], "已退费")


def run_refund_blocked_by_executed_check(api: E2EClient, visit: dict[str, Any]) -> None:
    register_uuid = visit["register_uuid"]
    seed = visit["seed"]
    check_uuid = create_check(api, register_uuid, seed.tech_id)
    prescription = create_prescription(api, register_uuid, seed.drug_id)
    bill = pay_bill(
        api,
        register_uuid,
        [
            {"type": "检查", "id": check_uuid},
            {"type": "药品", "id": prescription["item_uuid"]},
        ],
        idempotency_key=f"blocked-refund-pay-{check_uuid}",
    )

    wait_until("check paid", lambda: check_state(api, check_uuid) == "已缴费")
    wait_until("drug paid", lambda: drug_state(api, prescription["item_uuid"]) == "已缴费")

    api.request(
        "PUT",
        f"{MEDICAL_URL}/check/{check_uuid}/result",
        json={
            "image_path": "/tmp/e2e_normal_brain.png",
            "check_result": "No acute abnormality in e2e check.",
            "inputcheck_employee_uuid": visit["doctor_uuid"],
        },
    )
    wait_until("check executed", lambda: check_state(api, check_uuid) == "已执行")
    api.expect_failure(
        "PUT",
        f"{BILL_URL}/{bill['bill_code']}/refund",
        headers={"Idempotency-Key": f"blocked-refund-{bill['bill_code']}"},
    )
    assert_bill_state(api, register_uuid, bill["bill_code"], "退费失败")


def run_concurrent_duplicate_payment_guard(api: E2EClient, visit: dict[str, Any]) -> None:
    register_uuid = visit["register_uuid"]
    seed = visit["seed"]
    check_uuid = create_check(api, register_uuid, seed.tech_id)
    payload = {
        "register_uuid": register_uuid,
        "item_ids": [{"type": "检查", "id": check_uuid}],
        "pay_method": "微信",
    }
    api.expect_failure("POST", f"{BILL_URL}/pay", json=payload)

    def attempt_pay(idempotency_key: str) -> httpx.Response:
        with httpx.Client(timeout=REQUEST_TIMEOUT) as client:
            return client.post(
                f"{BILL_URL}/pay",
                json={**payload, "idempotency_key": idempotency_key},
            )

    with ThreadPoolExecutor(max_workers=2) as executor:
        responses = list(
            executor.map(
                attempt_pay,
                [f"race-pay-a-{check_uuid}", f"race-pay-b-{check_uuid}"],
            )
        )

    successes = [response for response in responses if response.status_code in (200, 201)]
    failures = [response for response in responses if response.status_code == 400]
    if len(successes) != 1 or len(failures) != 1:
        summary = [(response.status_code, response.text) for response in responses]
        raise AssertionError(f"Concurrent duplicate payment guard failed: {summary}")

    detail_count = asyncio.run(count_bill_details_for_item("检查", check_uuid))
    if detail_count != 1:
        raise AssertionError(f"Expected exactly one bill detail for {check_uuid}, got {detail_count}")

    wait_until("concurrent check paid", lambda: check_state(api, check_uuid) == "已缴费")
    api.expect_failure(
        "POST",
        f"{BILL_URL}/pay",
        json={**payload, "idempotency_key": f"race-pay-c-{check_uuid}"},
    )


def run_prescription_billing_unit_guard(api: E2EClient, visit: dict[str, Any]) -> None:
    register_uuid = visit["register_uuid"]
    seed = visit["seed"]
    prescription = create_prescription(api, register_uuid, seed.drug_id, numbers=[1, 2])
    bill = pay_bill(
        api,
        register_uuid,
        [{"type": "药品", "id": prescription["item_uuids"][0]}],
        idempotency_key=f"full-prescription-pay-{prescription['prescription_uuid']}",
    )

    for item_uuid in prescription["item_uuids"]:
        detail_count = asyncio.run(count_bill_details_for_item("药品", item_uuid))
        if detail_count != 1:
            raise AssertionError(f"Expected bill detail for full prescription item {item_uuid}, got {detail_count}")

    wait_until("full prescription paid", lambda: drug_state(api, prescription["item_uuid"]) == "已缴费")
    refund_key = f"full-prescription-refund-{bill['bill_code']}"
    api.request(
        "PUT",
        f"{BILL_URL}/{bill['bill_code']}/refund",
        headers={"Idempotency-Key": refund_key},
    )
    wait_until("full prescription refunded", lambda: drug_state(api, prescription["item_uuid"]) == "已退费")


def run_refund_success_boundaries(api: E2EClient, visit: dict[str, Any]) -> None:
    register_uuid = visit["register_uuid"]
    seed = visit["seed"]
    check_uuid = create_check(api, register_uuid, seed.tech_id)
    prescription = create_prescription(api, register_uuid, seed.drug_id)
    bill = pay_bill(
        api,
        register_uuid,
        [
            {"type": "检查", "id": check_uuid},
            {"type": "药品", "id": prescription["item_uuid"]},
        ],
        idempotency_key=f"success-refund-pay-{check_uuid}",
    )

    wait_until("second check paid", lambda: check_state(api, check_uuid) == "已缴费")
    wait_until("second drug paid", lambda: drug_state(api, prescription["item_uuid"]) == "已缴费")

    api.expect_failure("PUT", f"{BILL_URL}/{bill['bill_code']}/refund")

    refund_key = f"refund-{bill['bill_code']}"
    asyncio.run(seed_stale_idempotency(
        "billing.refund_bill",
        refund_key,
        {"bill_code": bill["bill_code"]},
    ))
    refund_result = api.request(
        "PUT",
        f"{BILL_URL}/{bill['bill_code']}/refund",
        headers={"Idempotency-Key": refund_key},
    )
    refund_replay = api.request(
        "PUT",
        f"{BILL_URL}/{bill['bill_code']}/refund",
        headers={"Idempotency-Key": refund_key},
    )
    if refund_replay["bill_code"] != refund_result["bill_code"]:
        raise AssertionError("Idempotent refund replay did not return the original refund")
    wait_until("second check refunded", lambda: check_state(api, check_uuid) == "已退费")
    wait_until("second drug refunded", lambda: drug_state(api, prescription["item_uuid"]) == "已退费")
    api.expect_failure(
        "PUT",
        f"{BILL_URL}/{bill['bill_code']}/refund",
        headers={"Idempotency-Key": f"refund-again-{bill['bill_code']}"},
    )
    api.expect_failure(
        "PUT",
        f"{MEDICAL_URL}/check/{check_uuid}/result",
        json={
            "image_path": "/tmp/e2e_refunded_check.png",
            "check_result": "This should not be accepted.",
            "inputcheck_employee_uuid": visit["doctor_uuid"],
        },
    )
    api.expect_failure(
        "PUT",
        f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/dispense",
        headers={"Idempotency-Key": f"dispense-refunded-{prescription['prescription_uuid']}"},
    )


def run_refunding_duplicate_key_guard(api: E2EClient, visit: dict[str, Any]) -> None:
    register_uuid = visit["register_uuid"]
    seed = visit["seed"]
    check_uuid = create_check(api, register_uuid, seed.tech_id)
    prescription = create_prescription(api, register_uuid, seed.drug_id)
    bill = pay_bill(
        api,
        register_uuid,
        [
            {"type": "检查", "id": check_uuid},
            {"type": "药品", "id": prescription["item_uuid"]},
        ],
        idempotency_key=f"refunding-guard-pay-{check_uuid}",
    )

    wait_until("refunding guard check paid", lambda: check_state(api, check_uuid) == "已缴费")
    wait_until("refunding guard drug paid", lambda: drug_state(api, prescription["item_uuid"]) == "已缴费")

    active_key = f"active-refund-{bill['bill_code']}"
    asyncio.run(seed_active_refund_in_progress(bill["bill_code"], active_key))
    api.expect_failure(
        "PUT",
        f"{BILL_URL}/{bill['bill_code']}/refund",
        headers={"Idempotency-Key": f"different-refund-{bill['bill_code']}"},
    )

    if check_state(api, check_uuid) != "已缴费":
        raise AssertionError("Duplicate refund while refunding should not mutate medical item")
    if drug_state(api, prescription["item_uuid"]) != "已缴费":
        raise AssertionError("Duplicate refund while refunding should not mutate prescription item")


def run_dispense_refund_stock_boundary(api: E2EClient, visit: dict[str, Any], stock_before: int) -> None:
    register_uuid = visit["register_uuid"]
    seed = visit["seed"]
    prescription = create_prescription(api, register_uuid, seed.drug_id, number=2)
    bill = pay_bill(
        api,
        register_uuid,
        [{"type": "药品", "id": prescription["item_uuid"]}],
        idempotency_key=f"dispense-pay-{prescription['item_uuid']}",
    )
    wait_until("third drug paid", lambda: drug_state(api, prescription["item_uuid"]) == "已缴费")
    api.expect_failure("PUT", f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/dispense")

    dispense_key = f"dispense-{prescription['prescription_uuid']}"
    dispense_result = api.request(
        "PUT",
        f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/dispense",
        headers={"Idempotency-Key": dispense_key},
    )
    dispense_replay = api.request(
        "PUT",
        f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/dispense",
        headers={"Idempotency-Key": dispense_key},
    )
    if dispense_replay["prescription_uuid"] != dispense_result["prescription_uuid"]:
        raise AssertionError("Idempotent dispense replay did not return the original dispense")
    wait_until("third drug dispensed", lambda: drug_state(api, prescription["item_uuid"]) == "已发药")
    api.expect_failure(
        "PUT",
        f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/dispense",
        headers={"Idempotency-Key": f"dispense-again-{prescription['prescription_uuid']}"},
    )

    refund_key = f"dispensed-refund-{bill['bill_code']}"
    api.request(
        "PUT",
        f"{BILL_URL}/{bill['bill_code']}/refund",
        headers={"Idempotency-Key": refund_key},
    )
    api.request(
        "PUT",
        f"{BILL_URL}/{bill['bill_code']}/refund",
        headers={"Idempotency-Key": refund_key},
    )
    wait_until("third drug refunded", lambda: drug_state(api, prescription["item_uuid"]) == "已退费")
    api.expect_failure(
        "PUT",
        f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/return",
        headers={"Idempotency-Key": f"return-refunded-{prescription['prescription_uuid']}"},
    )

    stock_after = asyncio.run(get_drug_stock(seed.drug_id))
    if stock_after != stock_before:
        raise AssertionError(f"Drug stock should be restored to {stock_before}, got {stock_after}")


def run_return_drugs_idempotency(api: E2EClient, visit: dict[str, Any], stock_before: int) -> None:
    register_uuid = visit["register_uuid"]
    seed = visit["seed"]
    prescription = create_prescription(api, register_uuid, seed.drug_id, number=3)
    pay_bill(
        api,
        register_uuid,
        [{"type": "药品", "id": prescription["item_uuid"]}],
        idempotency_key=f"return-pay-{prescription['item_uuid']}",
    )
    wait_until("return drug paid", lambda: drug_state(api, prescription["item_uuid"]) == "已缴费")

    dispense_key = f"return-dispense-{prescription['prescription_uuid']}"
    api.request(
        "PUT",
        f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/dispense",
        headers={"Idempotency-Key": dispense_key},
    )
    wait_until("return drug dispensed", lambda: drug_state(api, prescription["item_uuid"]) == "已发药")
    api.expect_failure("PUT", f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/return")

    return_key = f"return-drugs-{prescription['prescription_uuid']}"
    returned = api.request(
        "PUT",
        f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/return",
        headers={"Idempotency-Key": return_key},
    )
    replay = api.request(
        "PUT",
        f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/return",
        headers={"Idempotency-Key": return_key},
    )
    if replay["prescription_uuid"] != returned["prescription_uuid"]:
        raise AssertionError("Idempotent return replay did not return the original return")
    api.expect_failure(
        "PUT",
        f"{PHARMACY_URL}/prescription/{prescription['prescription_uuid']}/return",
        headers={"Idempotency-Key": f"return-again-{prescription['prescription_uuid']}"},
    )

    stock_after = asyncio.run(get_drug_stock(seed.drug_id))
    if stock_after != stock_before:
        raise AssertionError(f"Drug stock should be restored to {stock_before}, got {stock_after}")


def main() -> None:
    seed = asyncio.run(ensure_seed_data())
    api = E2EClient()
    try:
        check_health(api)
        visit = create_ai_guided_visit(api, seed)
        stock_before = asyncio.run(get_drug_stock(seed.drug_id))

        run_agent_scheduling_confirmation_flow(api, visit)
        run_registration_payment_order_refund_happy_path(api, visit)
        run_refund_blocked_by_executed_check(api, visit)
        run_concurrent_duplicate_payment_guard(api, visit)
        run_prescription_billing_unit_guard(api, visit)
        run_refund_success_boundaries(api, visit)
        run_refunding_duplicate_key_guard(api, visit)
        run_dispense_refund_stock_boundary(api, visit, stock_before)
        run_return_drugs_idempotency(api, visit, stock_before)

        print("full workflow e2e checks passed")
    finally:
        api.close()


if __name__ == "__main__":
    main()
