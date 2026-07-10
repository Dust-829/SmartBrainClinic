from datetime import datetime
from decimal import Decimal
from types import SimpleNamespace

import pytest

from app.microservices.billing.services import billing_service
from app.microservices.pharmacy.services import pharmacy_service


class FakeScalarResult:
    def __init__(self, rows):
        self._rows = rows

    def scalars(self):
        return self

    def all(self):
        return self._rows


class FakeSession:
    def __init__(self, rows):
        self.rows = rows
        self.statements = []

    async def execute(self, statement):
        self.statements.append(str(statement))
        return FakeScalarResult(self.rows)


@pytest.mark.asyncio
async def test_list_drugs_serializes_inventory_fields():
    session = FakeSession(
        [
            SimpleNamespace(
                id=1,
                uuid='00000000-0000-0000-0000-000000000011',
                drug_code='D001',
                drug_name='Mannitol Injection',
                specification='250ml/bottle',
                unit='bottle',
                price=Decimal('38.00'),
                stock=6,
                min_stock_limit=10,
            )
        ]
    )

    result = await pharmacy_service.list_drugs(session, low_stock_only=True, limit=10)

    assert result == [
        {
            'uuid': '00000000-0000-0000-0000-000000000011',
            'drug_code': 'D001',
            'drug_name': 'Mannitol Injection',
            'specification': '250ml/bottle',
            'unit': 'bottle',
            'price': '38.00',
            'stock': 6,
            'min_stock_limit': 10,
            'is_low_stock': True,
        }
    ]
    assert any('drug_info.stock <=' in statement for statement in session.statements)


@pytest.mark.asyncio
async def test_list_prescriptions_serializes_recent_items():
    session = FakeSession(
        [
            SimpleNamespace(
                id=1,
                uuid='00000000-0000-0000-0000-000000000021',
                register_uuid='00000000-0000-0000-0000-000000000031',
                prescription_code='CF202607080001',
                creation_time=datetime(2026, 7, 8, 9, 30, 0),
                is_ai_recommended=True,
                drug_state='paid',
            )
        ]
    )

    result = await pharmacy_service.list_prescriptions(session, state='paid', limit=10)

    assert result == [
        {
            'uuid': '00000000-0000-0000-0000-000000000021',
            'register_uuid': '00000000-0000-0000-0000-000000000031',
            'prescription_code': 'CF202607080001',
            'creation_time': '2026-07-08T09:30:00',
            'is_ai_recommended': True,
            'drug_state': 'paid',
        }
    ]


@pytest.mark.asyncio
async def test_list_bills_serializes_recent_records():
    session = FakeSession(
        [
            SimpleNamespace(
                id=1,
                uuid='00000000-0000-0000-0000-000000000041',
                register_uuid='00000000-0000-0000-0000-000000000051',
                bill_code='FP202607080001',
                total_amount=Decimal('128.50'),
                bill_state='paid',
                pay_method='wechat',
                transaction_id='WX123456789',
                pay_time=datetime(2026, 7, 8, 10, 15, 0),
            )
        ]
    )

    result = await billing_service.list_bills(session, state='paid', limit=10)

    assert result == [
        {
            'uuid': '00000000-0000-0000-0000-000000000041',
            'register_uuid': '00000000-0000-0000-0000-000000000051',
            'bill_code': 'FP202607080001',
            'total_amount': '128.50',
            'bill_state': 'paid',
            'pay_method': 'wechat',
            'transaction_id': 'WX123456789',
            'pay_time': '2026-07-08T10:15:00',
            'fee_status': 1,
        }
    ]
