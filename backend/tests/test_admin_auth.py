from types import SimpleNamespace

import bcrypt
import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from sqlmodel import SQLModel

SQLModel.metadata.clear()

from app.common.security import create_admin_access_token, require_admin
from app.microservices.auth.api import auth as auth_api
from app.microservices.auth.services import auth_service


class FakeResult:
    def __init__(self, row):
        self._row = row

    def scalar_one_or_none(self):
        return self._row


class FakeSession:
    def __init__(self, rows):
        self.rows = list(rows)
        self.added = []
        self.committed = False
        self.refreshed = []

    async def execute(self, _statement):
        return FakeResult(self.rows.pop(0) if self.rows else None)

    def add(self, row):
        self.added.append(row)

    async def commit(self):
        self.committed = True

    async def refresh(self, row):
        self.refreshed.append(row)


@pytest.mark.asyncio
async def test_admin_access_token_requires_valid_bearer_credentials(monkeypatch):
    monkeypatch.setenv("JWT_SECRET_KEY", "test-admin-secret")
    monkeypatch.setenv("JWT_EXPIRE_MINUTES", "30")
    token, expires_in = create_admin_access_token(
        admin_uuid="00000000-0000-0000-0000-000000000001",
        staff_code="ADMIN-001",
        display_name="值班管理员",
    )

    principal = await require_admin(HTTPAuthorizationCredentials(scheme="Bearer", credentials=token))

    assert expires_in == 1800
    assert principal.staff_code == "ADMIN-001"
    with pytest.raises(HTTPException) as error:
        await require_admin(HTTPAuthorizationCredentials(scheme="Bearer", credentials="not-a-token"))
    assert error.value.status_code == 401


@pytest.mark.asyncio
async def test_authenticate_admin_rejects_disabled_or_wrong_password():
    password_hash = bcrypt.hashpw(b"correct-password", bcrypt.gensalt()).decode("utf-8")
    enabled = SimpleNamespace(staff_code="ADMIN-001", password_hash=password_hash, is_active=True)
    disabled = SimpleNamespace(staff_code="ADMIN-002", password_hash=password_hash, is_active=False)

    assert await auth_service.authenticate_admin(FakeSession([enabled]), "admin-001", "correct-password") is enabled
    assert await auth_service.authenticate_admin(FakeSession([enabled]), "ADMIN-001", "wrong-password") is None
    assert await auth_service.authenticate_admin(FakeSession([disabled]), "ADMIN-002", "correct-password") is None


@pytest.mark.asyncio
async def test_login_endpoints_return_their_own_session_payloads(monkeypatch):
    monkeypatch.setenv("JWT_SECRET_KEY", "test-admin-secret")
    monkeypatch.setenv("JWT_EXPIRE_MINUTES", "30")
    admin = SimpleNamespace(uuid="00000000-0000-0000-0000-000000000001", staff_code="ADMIN-001", display_name="值班管理员")

    async def fake_authenticate_admin(*_args):
        return admin

    async def fake_authenticate_doctor(*_args):
        return {
            "uuid": "00000000-0000-0000-0000-000000000101",
            "staff_code": "DOC-000101",
            "display_name": "王医生",
            "dept_code": "SJWK",
            "dept_name": "神经外科",
        }

    monkeypatch.setattr(auth_api.svc, "authenticate_admin", fake_authenticate_admin)
    monkeypatch.setattr(auth_api.svc, "authenticate_doctor", fake_authenticate_doctor)

    admin_response = await auth_api.admin_login(auth_api.AdminLoginRequest(staff_code="ADMIN-001", password="test"), FakeSession([]))
    doctor_response = await auth_api.doctor_login(auth_api.DoctorLoginRequest(staff_code="DOC-000101", password="test"), FakeSession([]))

    assert admin_response["data"]["staff"]["staff_code"] == "ADMIN-001"
    assert admin_response["data"]["access_token"]
    assert doctor_response == {
        "code": 200,
        "message": "success",
        "data": {"staff": await fake_authenticate_doctor()},
    }


@pytest.mark.asyncio
async def test_bootstrap_admin_creation_hashes_password_and_rejects_duplicate_staff_code():
    session = FakeSession([None])

    admin = await auth_service.create_admin_account(
        session,
        staff_code="admin-001",
        display_name="值班管理员",
        password="initial-password",
    )

    assert admin.staff_code == "ADMIN-001"
    assert admin.password_hash != "initial-password"
    assert bcrypt.checkpw(b"initial-password", admin.password_hash.encode("utf-8"))
    assert session.committed is True

    with pytest.raises(ValueError, match="已存在"):
        await auth_service.create_admin_account(
            FakeSession([SimpleNamespace()]),
            staff_code="ADMIN-001",
            display_name="重复管理员",
            password="another-password",
        )


def test_admin_auth_migration_contains_identity_and_audit_tables():
    migration = open("migrations/20260714_02_create_admin_account_auth.sql", encoding="utf-8").read()

    assert "CREATE TABLE IF NOT EXISTS public.admin_account" in migration
    assert "CREATE TABLE IF NOT EXISTS public.account_operation_audit" in migration
    assert "password_hash" in migration


def test_doctor_login_migration_backfills_unique_staff_codes():
    migration = open("migrations/20260715_01_add_employee_staff_code.sql", encoding="utf-8").read()

    assert "ADD COLUMN IF NOT EXISTS staff_code" in migration
    assert "UPDATE public.employee" in migration
    assert "CREATE UNIQUE INDEX IF NOT EXISTS ix_employee_staff_code" in migration
