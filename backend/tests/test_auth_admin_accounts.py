from types import SimpleNamespace
import uuid

import pytest
import bcrypt
from sqlmodel import SQLModel

SQLModel.metadata.clear()
from app.microservices.auth.services import auth_service


class FakeResult:
    def __init__(self, rows):
        self._rows = rows

    def all(self):
        return self._rows

    def first(self):
        return self._rows[0] if self._rows else None

    def scalar_one_or_none(self):
        return self._rows[0] if self._rows else None

    def scalar_one(self):
        return self._rows[0] if self._rows else 0


class FakeSession:
    def __init__(self, rows):
        self.rows = rows
        self.statements = []
        self.added = []
        self.commit_count = 0

    async def execute(self, statement):
        self.statements.append(str(statement))
        if "count(" in str(statement).lower():
            return FakeResult([len(self.rows)])
        return FakeResult(self.rows)

    def add(self, row):
        self.added.append(row)

    async def commit(self):
        self.commit_count += 1


@pytest.mark.asyncio
async def test_list_doctor_accounts_serializes_keyword_results():
    doctor_uuid = uuid.UUID('00000000-0000-0000-0000-000000000101')
    dept_uuid = uuid.UUID('00000000-0000-0000-0000-000000000201')
    regist_level_uuid = uuid.UUID('00000000-0000-0000-0000-000000000301')
    session = FakeSession(
        [
            (
                SimpleNamespace(
                    uuid=doctor_uuid,
                    realname='王若岚',
                    gender='女',
                    expertise='头痛,神经影像',
                    ai_eval_score='4.5',
                    model_dump=lambda **kwargs: {
                        'uuid': str(doctor_uuid),
                        'realname': '王若岚',
                        'gender': '女',
                        'expertise': '头痛,神经影像',
                        'ai_eval_score': '4.5',
                    },
                ),
                dept_uuid,
                'SJWK',
                regist_level_uuid,
                'ZJ',
            )
        ]
    )

    result = await auth_service.list_doctor_accounts(session, keyword='王', limit=10, offset=7)

    assert result == {
        'items': [
            {
                'uuid': str(doctor_uuid),
                'realname': '王若岚',
                'gender': '女',
                'expertise': '头痛,神经影像',
                'ai_eval_score': '4.5',
                'dept_uuid': str(dept_uuid),
                'dept_code': 'SJWK',
                'regist_level_uuid': str(regist_level_uuid),
                'regist_level_code': 'ZJ',
            }
        ],
        'pagination': {
            'total': 1,
            'limit': 10,
            'offset': 7,
        },
    }
    assert any('employee.realname' in statement.lower() for statement in session.statements)
    assert any('offset' in statement.lower() for statement in session.statements)


@pytest.mark.asyncio
async def test_update_employee_profile_updates_editable_fields():
    dept = SimpleNamespace(
        id=11,
        uuid=uuid.UUID('00000000-0000-0000-0000-000000000202'),
        dept_code='SJWK',
    )
    level = SimpleNamespace(
        id=21,
        uuid=uuid.UUID('00000000-0000-0000-0000-000000000302'),
        regist_code='PT',
    )
    employee = SimpleNamespace(
        uuid=uuid.UUID('00000000-0000-0000-0000-000000000102'),
        realname='李沐川',
        gender='男',
        dept_id=1,
        regist_level_id=2,
        expertise='旧专长',
        ai_eval_score='4.0',
        model_dump=lambda **kwargs: {
            'uuid': '00000000-0000-0000-0000-000000000102',
            'realname': '李沐川(更新)',
            'gender': '女',
            'expertise': '新专长',
            'ai_eval_score': '4.0',
        },
    )
    session = FakeSession([(employee, None, None)])

    async def fake_get_department_by_code(_session, dept_code):
        assert dept_code == 'SJWK'
        return dept

    async def fake_get_regist_level_by_code(_session, regist_code):
        assert regist_code == 'PT'
        return level

    original_get_department_by_code = auth_service.get_department_by_code
    auth_service.get_department_by_code = fake_get_department_by_code
    original_get_regist_level_by_code = auth_service.get_regist_level_by_code
    auth_service.get_regist_level_by_code = fake_get_regist_level_by_code

    original_select = auth_service.select

    def fake_select(*_models):
        class Query:
            def outerjoin(self, *args, **kwargs):
                return self
            def where(self, *args, **kwargs):
                return self
        return Query()

    auth_service.select = fake_select

    try:
      result = await auth_service.update_employee_profile(
          session,
          employee.uuid,
          {
              'realname': '李沐川(更新)',
              'gender': '女',
              'dept_code': 'SJWK',
              'regist_level_code': 'PT',
              'expertise': '新专长',
          },
      )
    finally:
      auth_service.get_department_by_code = original_get_department_by_code
      auth_service.get_regist_level_by_code = original_get_regist_level_by_code
      auth_service.select = original_select

    assert employee.realname == '李沐川(更新)'
    assert employee.gender == '女'
    assert employee.dept_id == 11
    assert employee.regist_level_id == 21
    assert employee.expertise == '新专长'
    assert session.added == [employee]
    assert session.commit_count == 1
    assert result['realname'] == '李沐川(更新)'


@pytest.mark.asyncio
async def test_reset_employee_password_persists_only_bcrypt_hash():
    employee_uuid = uuid.UUID('00000000-0000-0000-0000-000000000103')
    employee = SimpleNamespace(
        uuid=employee_uuid,
        password='old-password-hash',
    )
    session = FakeSession([employee])

    result = await auth_service.reset_employee_password(session, employee_uuid, 'NewSecurePass8')

    assert result == {'uuid': str(employee_uuid), 'credentials_reset': True}
    assert employee.password != 'NewSecurePass8'
    assert bcrypt.checkpw(b'NewSecurePass8', employee.password.encode('utf-8'))
    assert session.added == [employee]
    assert session.commit_count == 1


@pytest.mark.asyncio
async def test_deactivation_check_delegates_to_patient_client():
    employee_uuid = uuid.UUID('00000000-0000-0000-0000-000000000108')
    original_check = auth_service.PatientClient.get_doctor_deactivation_check

    async def fake_check(received_employee_uuid, received_authorization):
        assert received_employee_uuid == str(employee_uuid)
        assert received_authorization == 'Bearer test'
        return {'can_deactivate': True, 'blockers': []}

    auth_service.PatientClient.get_doctor_deactivation_check = fake_check
    try:
        result = await auth_service.get_employee_deactivation_check(employee_uuid, 'Bearer test')
    finally:
        auth_service.PatientClient.get_doctor_deactivation_check = original_check

    assert result == {'can_deactivate': True, 'blockers': []}


@pytest.mark.asyncio
async def test_reset_employee_password_records_a_safe_account_audit():
    employee_uuid = uuid.UUID('00000000-0000-0000-0000-000000000106')
    admin_uuid = uuid.UUID('00000000-0000-0000-0000-000000000901')
    employee = SimpleNamespace(uuid=employee_uuid, password='old-password-hash')
    session = FakeSession([employee])

    await auth_service.reset_employee_password(session, employee_uuid, 'NewSecurePass8', admin_uuid)

    audit = session.added[-1]
    assert audit.actor_admin_uuid == admin_uuid
    assert audit.target_uuid == employee_uuid
    assert audit.target_type == 'employee'
    assert audit.action == 'credentials_reset'
    assert audit.result == 'success'
    assert audit.detail == 'credentials_reset'
    assert 'NewSecurePass8' not in str(audit.detail)


@pytest.mark.asyncio
async def test_update_employee_active_status_rejects_blocked_deactivation():
    employee_uuid = uuid.UUID('00000000-0000-0000-0000-000000000104')
    employee = SimpleNamespace(uuid=employee_uuid, delmark=1)
    session = FakeSession([employee])

    original_check = auth_service.get_employee_deactivation_check

    async def fake_check(_employee_uuid, _authorization):
        return {
            'can_deactivate': False,
            'blockers': [{'message': '仍存在待接诊挂号', 'count': 2}],
        }

    auth_service.get_employee_deactivation_check = fake_check
    try:
        with pytest.raises(ValueError, match='仍存在待接诊挂号'):
            await auth_service.update_employee_active_status(session, employee_uuid, False, 'Bearer test')
    finally:
        auth_service.get_employee_deactivation_check = original_check

    assert employee.delmark == 1
    assert session.commit_count == 0


@pytest.mark.asyncio
async def test_update_employee_active_status_deactivates_when_no_blocker():
    employee_uuid = uuid.UUID('00000000-0000-0000-0000-000000000105')
    employee = SimpleNamespace(uuid=employee_uuid, delmark=1)
    session = FakeSession([employee])

    original_check = auth_service.get_employee_deactivation_check

    async def fake_check(_employee_uuid, _authorization):
        return {'can_deactivate': True, 'blockers': []}

    auth_service.get_employee_deactivation_check = fake_check
    try:
        result = await auth_service.update_employee_active_status(session, employee_uuid, False, 'Bearer test')
    finally:
        auth_service.get_employee_deactivation_check = original_check

    assert result == {'uuid': str(employee_uuid), 'is_active': False}
    assert employee.delmark == 0
    assert session.added == [employee]
    assert session.commit_count == 1


@pytest.mark.asyncio
async def test_blocked_deactivation_records_failed_audit_without_sensitive_detail():
    employee_uuid = uuid.UUID('00000000-0000-0000-0000-000000000107')
    admin_uuid = uuid.UUID('00000000-0000-0000-0000-000000000902')
    employee = SimpleNamespace(uuid=employee_uuid, delmark=1)
    session = FakeSession([employee])

    original_check = auth_service.get_employee_deactivation_check

    async def fake_check(_employee_uuid, _authorization):
        return {'can_deactivate': False, 'blockers': [{'message': '存在待接诊挂号', 'count': 2}]}

    auth_service.get_employee_deactivation_check = fake_check
    try:
        with pytest.raises(ValueError, match='存在待接诊挂号'):
            await auth_service.update_employee_active_status(
                session, employee_uuid, False, 'Bearer test', admin_uuid
            )
    finally:
        auth_service.get_employee_deactivation_check = original_check

    audit = session.added[-1]
    assert audit.action == 'deactivate'
    assert audit.result == 'failed'
    assert audit.detail == 'deactivation_blocked'
    assert session.commit_count == 1
