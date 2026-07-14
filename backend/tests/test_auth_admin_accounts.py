from types import SimpleNamespace
import uuid

import pytest
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
