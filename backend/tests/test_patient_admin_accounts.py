from datetime import date, datetime
from types import SimpleNamespace
import uuid

import pytest
from sqlmodel import SQLModel

SQLModel.metadata.clear()
from app.microservices.patient.services import patient_service


class FakeScalarResult:
    def __init__(self, rows):
        self._rows = rows

    def scalars(self):
        return self

    def all(self):
        return self._rows

    def scalar_one_or_none(self):
        if isinstance(self._rows, list):
            return self._rows[0] if self._rows else None
        return self._rows

    def scalar_one(self):
        if isinstance(self._rows, list):
            return self._rows[0] if self._rows else 0
        return self._rows


class FakeSession:
    def __init__(self, rows):
        self.rows = rows
        self.statements = []
        self.flush_count = 0
        self.added = []

    async def execute(self, statement):
        self.statements.append(str(statement))
        if 'count(' in str(statement).lower():
            return FakeScalarResult([len(self.rows)])
        return FakeScalarResult(self.rows)

    def add(self, row):
        self.added.append(row)

    async def flush(self):
        self.flush_count += 1


@pytest.mark.asyncio
async def test_list_admin_patients_serializes_recent_records():
    patient_uuid = uuid.UUID('00000000-0000-0000-0000-000000000061')
    session = FakeSession(
        [
            SimpleNamespace(
                id=1,
                uuid=patient_uuid,
                case_number='BLH202607090001',
                real_name='Zhang San',
                gender='男',
                card_number='210102199001011234',
                birthdate=date(1990, 1, 1),
                home_address='Shenyang 1',
                created_at=datetime(2026, 7, 9, 10, 30, 0),
            )
        ]
    )

    result = await patient_service.list_admin_patients(session, keyword='Zhang', limit=10, offset=4)

    assert result == {
        'items': [
            {
                'uuid': str(patient_uuid),
                'case_number': 'BLH202607090001',
                'real_name': 'Zhang San',
                'gender': '男',
                'card_number': '210102199001011234',
                'birthdate': '1990-01-01',
                'home_address': 'Shenyang 1',
                'created_at': '2026-07-09T10:30:00',
            }
        ],
        'pagination': {
            'total': 1,
            'limit': 10,
            'offset': 4,
        },
    }
    assert any('patient.real_name' in statement for statement in session.statements)
    assert any('patient.card_number' in statement for statement in session.statements)


@pytest.mark.asyncio
async def test_update_admin_patient_profile_updates_allowed_fields_only():
    patient_uuid = uuid.UUID('00000000-0000-0000-0000-000000000071')
    patient = SimpleNamespace(
        id=1,
        uuid=patient_uuid,
        case_number='BLH202607090002',
        real_name='Li Si',
        gender='女',
        card_number='210102199202022222',
        birthdate=date(1992, 2, 2),
        home_address='Old Address',
        created_at=datetime(2026, 7, 9, 11, 0, 0),
    )
    session = FakeSession(patient)

    result = await patient_service.update_admin_patient(
        session,
        patient_uuid,
        {
            'real_name': 'Li Si Updated',
            'gender': '男',
            'birthdate': date(1993, 3, 3),
            'home_address': 'New Address',
        },
    )

    assert patient.real_name == 'Li Si Updated'
    assert patient.gender == '男'
    assert patient.birthdate == date(1993, 3, 3)
    assert patient.home_address == 'New Address'
    assert patient.card_number == '210102199202022222'
    assert session.flush_count == 1
    assert session.added == [patient]
    assert result == {
        'uuid': str(patient_uuid),
        'case_number': 'BLH202607090002',
        'real_name': 'Li Si Updated',
        'gender': '男',
        'card_number': '210102199202022222',
        'birthdate': '1993-03-03',
        'home_address': 'New Address',
        'created_at': '2026-07-09T11:00:00',
    }
