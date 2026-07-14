from datetime import datetime
from decimal import Decimal
from types import SimpleNamespace
import uuid as uuid_pkg

import pytest

from app.common.enums import BillState, VisitState
from app.microservices.billing.models.bill import OutpatientBill
from app.microservices.billing.services import billing_service
from app.microservices.pharmacy.services import pharmacy_service


class FakeScalarResult:
    def __init__(self, rows):
        self._rows = rows

    def scalars(self):
        return self

    def all(self):
        return self._rows


class FakeExecuteResult:
    def __init__(self, rows=None, scalar_rows=None):
        self._rows = rows or []
        self._scalar_rows = scalar_rows if scalar_rows is not None else self._rows

    def all(self):
        return self._rows

    def first(self):
        return self._rows[0] if self._rows else None

    def scalars(self):
        return FakeScalarResult(self._scalar_rows)


class FakeSession:
    def __init__(self, rows):
        self.rows = rows
        self.statements = []

    async def execute(self, statement):
        self.statements.append(str(statement))
        return FakeScalarResult(self.rows)


class FakeSequentialSession:
    def __init__(self, responses):
        self.responses = list(responses)
        self.statements = []

    async def execute(self, statement):
        self.statements.append(str(statement))
        if not self.responses:
            raise AssertionError("No fake responses left for execute()")
        return self.responses.pop(0)


class FakeRow:
    def __init__(self, mapping):
        self._mapping = mapping


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


@pytest.mark.asyncio
async def test_get_bills_by_register_includes_register_uuid_and_pay_time():
    session = FakeSession(
        [
            SimpleNamespace(
                uuid='00000000-0000-0000-0000-000000000061',
                register_uuid='00000000-0000-0000-0000-000000000071',
                bill_code='FP202607080009',
                total_amount=Decimal('64.00'),
                bill_state=BillState.PAID.value,
                pay_method='wechat',
                transaction_id='WX0001',
                pay_time=datetime(2026, 7, 8, 11, 20, 0),
            )
        ]
    )

    result = await billing_service.get_bills_by_register(
        session,
        uuid_pkg.UUID('00000000-0000-0000-0000-000000000071'),
    )

    assert result == [
        {
            'uuid': '00000000-0000-0000-0000-000000000061',
            'register_uuid': '00000000-0000-0000-0000-000000000071',
            'bill_code': 'FP202607080009',
            'total_amount': '64.00',
            'bill_state': BillState.PAID.value,
            'pay_method': 'wechat',
            'transaction_id': 'WX0001',
            'pay_time': '2026-07-08T11:20:00',
            'fee_status': 1,
        }
    ]


@pytest.mark.asyncio
async def test_get_admin_bills_page_returns_summary_and_masked_patient_context():
    bill = SimpleNamespace(
        id=1,
        uuid='00000000-0000-0000-0000-000000000081',
        register_uuid='00000000-0000-0000-0000-000000000091',
        bill_code='FP202607080021',
        total_amount=Decimal('128.50'),
        bill_state=BillState.REFUNDING.value,
        pay_method='wechat',
        transaction_id='WX9988',
        pay_time=datetime(2026, 7, 8, 10, 15, 0),
    )
    item_row = FakeRow(
        {
            OutpatientBill: bill,
            'patient_name': '张三',
            'case_number': 'CASE-001',
            'card_number': '210102199001011234',
            'visit_date': datetime(2026, 7, 8, 9, 0, 0),
            'detail_count': 3,
        }
    )
    summary_rows = [
        FakeRow({'bill_state': BillState.REFUNDING.value, 'total_amount': Decimal('128.50')}),
        FakeRow({'bill_state': BillState.REFUNDED.value, 'total_amount': Decimal('56.00')}),
    ]
    session = FakeSequentialSession(
        [
            FakeExecuteResult(rows=[item_row]),
            FakeExecuteResult(rows=summary_rows),
        ]
    )

    result = await billing_service.get_admin_bills_page(
        session,
        keyword='张三',
        state=BillState.REFUNDING.value,
        limit=8,
        offset=0,
    )

    assert result == {
        'items': [
            {
                'uuid': '00000000-0000-0000-0000-000000000081',
                'register_uuid': '00000000-0000-0000-0000-000000000091',
                'bill_code': 'FP202607080021',
                'total_amount': '128.50',
                'bill_state': BillState.REFUNDING.value,
                'pay_method': 'wechat',
                'transaction_id': 'WX9988',
                'pay_time': '2026-07-08T10:15:00',
                'fee_status': 1,
                'patient_name': '张三',
                'case_number': 'CASE-001',
                'card_number_masked': '2101**********1234',
                'visit_date': '2026-07-08T09:00:00',
                'detail_count': 3,
            }
        ],
        'pagination': {
            'total': 2,
            'limit': 8,
            'offset': 0,
        },
        'summary': {
            'total_count': 2,
            'paid_count': 0,
            'refunding_count': 1,
            'refunded_count': 1,
            'refund_failed_count': 0,
            'state_counts': {
                BillState.REFUNDING.value: 1,
                BillState.REFUNDED.value: 1,
            },
            'total_amount': '184.50',
            'refunded_amount': '56.00',
        },
    }
    assert any('patient.real_name' in statement for statement in session.statements)
    assert any('outpatient_bill.bill_state' in statement for statement in session.statements)


@pytest.mark.asyncio
async def test_get_admin_bill_detail_serializes_details_and_refund_steps():
    bill = SimpleNamespace(
        id=2,
        uuid='00000000-0000-0000-0000-000000000101',
        register_uuid='00000000-0000-0000-0000-000000000111',
        bill_code='FP202607080031',
        total_amount=Decimal('88.00'),
        bill_state=BillState.REFUND_FAILED.value,
        pay_method='wechat',
        transaction_id='WX2233',
        pay_time=datetime(2026, 7, 8, 13, 15, 0),
    )
    detail_rows = [
        SimpleNamespace(
            uuid='00000000-0000-0000-0000-000000000121',
            item_type='检查',
            item_source_id='source-check-1',
            amount=Decimal('28.00'),
        ),
        SimpleNamespace(
            uuid='00000000-0000-0000-0000-000000000122',
            item_type='药品',
            item_source_id='source-drug-1',
            amount=Decimal('60.00'),
        ),
    ]
    refund_steps = [
        SimpleNamespace(
            id=1,
            step_name='medical',
            status='succeeded',
            error_message=None,
            request_payload='{"items":[{"id":"source-check-1","type":"检查"}]}',
            response_payload='{"ok":true}',
            updated_at=datetime(2026, 7, 8, 13, 20, 0),
        ),
        SimpleNamespace(
            id=2,
            step_name='pharmacy',
            status='failed',
            error_message='库存回滚失败',
            request_payload='{"item_uuids":["source-drug-1"]}',
            response_payload=None,
            updated_at=datetime(2026, 7, 8, 13, 22, 0),
        ),
    ]
    detail_row = FakeRow(
        {
            OutpatientBill: bill,
            'patient_uuid': uuid_pkg.UUID('00000000-0000-0000-0000-000000000131'),
            'patient_name': '李四',
            'case_number': 'CASE-002',
            'card_number': '310101198812120022',
            'visit_date': datetime(2026, 7, 8, 8, 40, 0),
            'visit_state': VisitState.REGISTERED,
        }
    )
    session = FakeSequentialSession(
        [
            FakeExecuteResult(rows=[detail_row]),
            FakeExecuteResult(scalar_rows=detail_rows),
            FakeExecuteResult(scalar_rows=refund_steps),
        ]
    )

    result = await billing_service.get_admin_bill_detail(session, 'FP202607080031')

    assert result == {
        'uuid': '00000000-0000-0000-0000-000000000101',
        'register_uuid': '00000000-0000-0000-0000-000000000111',
        'bill_code': 'FP202607080031',
        'total_amount': '88.00',
        'bill_state': BillState.REFUND_FAILED.value,
        'pay_method': 'wechat',
        'transaction_id': 'WX2233',
        'pay_time': '2026-07-08T13:15:00',
        'fee_status': 1,
        'patient_uuid': '00000000-0000-0000-0000-000000000131',
        'patient_name': '李四',
        'case_number': 'CASE-002',
        'card_number_masked': '3101**********0022',
        'visit_date': '2026-07-08T08:40:00',
        'visit_state': VisitState.REGISTERED,
        'visit_state_label': '已挂号',
        'details': [
            {
                'uuid': '00000000-0000-0000-0000-000000000121',
                'item_type': '检查',
                'item_source_id': 'source-check-1',
                'amount': '28.00',
            },
            {
                'uuid': '00000000-0000-0000-0000-000000000122',
                'item_type': '药品',
                'item_source_id': 'source-drug-1',
                'amount': '60.00',
            },
        ],
        'refund_steps': [
            {
                'step_name': 'medical',
                'status': 'succeeded',
                'error_message': None,
                'request_payload': {'items': [{'id': 'source-check-1', 'type': '检查'}]},
                'response_payload': {'ok': True},
                'updated_at': '2026-07-08T13:20:00',
            },
            {
                'step_name': 'pharmacy',
                'status': 'failed',
                'error_message': '库存回滚失败',
                'request_payload': {'item_uuids': ['source-drug-1']},
                'response_payload': None,
                'updated_at': '2026-07-08T13:22:00',
            },
        ],
    }
