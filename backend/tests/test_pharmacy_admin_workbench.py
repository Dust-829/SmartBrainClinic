from datetime import datetime
from decimal import Decimal
from types import SimpleNamespace
import uuid

import pytest

from app.common.enums import DrugState
from app.microservices.pharmacy.models.drug import DrugInfo
from app.microservices.pharmacy.services import pharmacy_service


class FakeScalarResult:
    def __init__(self, *, scalar_value=None, values=None):
        self._scalar_value = scalar_value
        self._values = values or []

    def scalar_one_or_none(self):
        return self._scalar_value

    def scalar(self):
        return self._scalar_value

    def scalars(self):
        return self

    def all(self):
        return self._values


class FakeExecuteResult:
    def __init__(self, *, scalar_value=None, values=None):
        self._result = FakeScalarResult(scalar_value=scalar_value, values=values)

    def scalar_one_or_none(self):
        return self._result.scalar_one_or_none()

    def scalar(self):
        return self._result.scalar()

    def scalars(self):
        return self._result.scalars()

    def all(self):
        return self._result.all()


class FakeSession:
    def __init__(self, execute_results=None, get_results=None):
        self.execute_results = list(execute_results or [])
        self.get_results = get_results or {}
        self.statements = []
        self.added = []
        self.flush_count = 0
        self.commit_count = 0

    async def execute(self, statement):
        self.statements.append(str(statement))
        if not self.execute_results:
            return FakeExecuteResult()
        result = self.execute_results.pop(0)
        if callable(result):
            return result(statement)
        return result

    async def get(self, model, key):
        return self.get_results.get((model, key))

    def add(self, obj):
        self.added.append(obj)

    async def flush(self):
        self.flush_count += 1

    async def commit(self):
        self.commit_count += 1


@pytest.mark.asyncio
async def test_list_admin_workbench_prescriptions_returns_context_and_actions(monkeypatch):
    register_uuid_one = uuid.uuid4()
    register_uuid_two = uuid.uuid4()
    prescription_uuid_one = uuid.uuid4()
    prescription_uuid_two = uuid.uuid4()

    prescriptions = [
        SimpleNamespace(
            id=11,
            uuid=prescription_uuid_one,
            register_uuid=register_uuid_one,
            prescription_code='CF202607120001',
            creation_time=datetime(2026, 7, 12, 9, 0, 0),
            is_ai_recommended=True,
            drug_state=DrugState.PAID.value,
        ),
        SimpleNamespace(
            id=12,
            uuid=prescription_uuid_two,
            register_uuid=register_uuid_two,
            prescription_code='CF202607120002',
            creation_time=datetime(2026, 7, 12, 9, 10, 0),
            is_ai_recommended=False,
            drug_state=DrugState.DISPENSED.value,
        ),
    ]

    async def fake_get_register(register_uuid):
        mapping = {
            str(register_uuid_one): {
                'patient_name': '张三',
                'patient_case_number': 'CASE-001',
                'employee_name': '王医生',
                'dept_name': '神经外科',
                'actual_time_range': '09:00-09:10',
                'clinic_room_name': '101诊室',
            },
            str(register_uuid_two): {
                'patient_name': '李四',
                'patient_case_number': 'CASE-002',
                'employee_name': '赵医生',
                'dept_name': '骨科',
                'actual_time_range': '09:10-09:20',
                'clinic_room_name': '202诊室',
            },
        }
        return mapping[str(register_uuid)]

    async def fake_load_item_counts(session, prescription_ids):
        assert prescription_ids == [11, 12]
        return {11: 2, 12: 1}

    monkeypatch.setattr(pharmacy_service.PatientClient, 'get_register', fake_get_register)
    monkeypatch.setattr(pharmacy_service, '_load_prescription_item_counts', fake_load_item_counts)

    session = FakeSession(
        execute_results=[
            FakeExecuteResult(scalar_value=2),
            FakeExecuteResult(values=prescriptions),
        ]
    )

    result = await pharmacy_service.list_admin_workbench_prescriptions(
        session,
        state='actionable',
        limit=2,
        offset=0,
    )

    assert result['pagination'] == {'total': 2, 'limit': 2, 'offset': 0}
    assert result['items'] == [
        {
            'uuid': str(prescription_uuid_one),
            'register_uuid': str(register_uuid_one),
            'prescription_code': 'CF202607120001',
            'creation_time': '2026-07-12T09:00:00',
            'is_ai_recommended': True,
            'drug_state': DrugState.PAID.value,
            'patient_name': '张三',
            'patient_case_number': 'CASE-001',
            'employee_name': '王医生',
            'dept_name': '神经外科',
            'actual_time_range': '09:00-09:10',
            'clinic_room_name': '101诊室',
            'items_count': 2,
            'can_dispense': True,
            'can_return': False,
        },
        {
            'uuid': str(prescription_uuid_two),
            'register_uuid': str(register_uuid_two),
            'prescription_code': 'CF202607120002',
            'creation_time': '2026-07-12T09:10:00',
            'is_ai_recommended': False,
            'drug_state': DrugState.DISPENSED.value,
            'patient_name': '李四',
            'patient_case_number': 'CASE-002',
            'employee_name': '赵医生',
            'dept_name': '骨科',
            'actual_time_range': '09:10-09:20',
            'clinic_room_name': '202诊室',
            'items_count': 1,
            'can_dispense': False,
            'can_return': True,
        },
    ]


@pytest.mark.asyncio
async def test_get_admin_workbench_prescription_detail_returns_header_context_items_and_actions(monkeypatch):
    prescription_uuid = uuid.uuid4()
    register_uuid = uuid.uuid4()
    drug_uuid = uuid.uuid4()

    prescription = SimpleNamespace(
        id=21,
        uuid=prescription_uuid,
        register_uuid=register_uuid,
        prescription_code='CF202607120101',
        creation_time=datetime(2026, 7, 12, 11, 30, 0),
        is_ai_recommended=True,
        drug_state=DrugState.PAID.value,
    )
    items = [
        SimpleNamespace(
            uuid=uuid.uuid4(),
            prescription_id=21,
            drug_id=301,
            drug_usage='每日两次',
            drug_number=3,
        )
    ]

    async def fake_get_register(register_uuid_value):
        assert str(register_uuid_value) == str(register_uuid)
        return {
            'patient_name': '王五',
            'patient_case_number': 'CASE-101',
            'employee_name': '周医生',
            'dept_name': '神经内科',
            'actual_time_range': '11:30-11:40',
            'clinic_room_name': '303诊室',
            'visit_state_text': '已挂号',
        }

    session = FakeSession(
        execute_results=[
            FakeExecuteResult(scalar_value=prescription),
            FakeExecuteResult(values=items),
        ],
        get_results={
            (DrugInfo, 301): SimpleNamespace(
                uuid=drug_uuid,
                drug_code='D-301',
                drug_name='阿司匹林',
                specification='100mg*30片',
                unit='盒',
                price=Decimal('12.50'),
                stock=18,
                min_stock_limit=5,
            )
        },
    )

    monkeypatch.setattr(pharmacy_service.PatientClient, 'get_register', fake_get_register)

    result = await pharmacy_service.get_admin_workbench_prescription_detail(session, str(prescription_uuid))

    assert result == {
        'header': {
            'uuid': str(prescription_uuid),
            'register_uuid': str(register_uuid),
            'prescription_code': 'CF202607120101',
            'creation_time': '2026-07-12T11:30:00',
            'is_ai_recommended': True,
            'drug_state': DrugState.PAID.value,
        },
        'register_context': {
            'patient_name': '王五',
            'patient_case_number': 'CASE-101',
            'employee_name': '周医生',
            'dept_name': '神经内科',
            'actual_time_range': '11:30-11:40',
            'clinic_room_name': '303诊室',
            'visit_state_text': '已挂号',
        },
        'items': [
            {
                'uuid': str(items[0].uuid),
                'drug_uuid': str(drug_uuid),
                'drug_code': 'D-301',
                'drug_name': '阿司匹林',
                'specification': '100mg*30片',
                'unit': '盒',
                'price': '12.50',
                'stock': 18,
                'min_stock_limit': 5,
                'drug_usage': '每日两次',
                'drug_number': 3,
            }
        ],
        'actions': {
            'can_dispense': True,
            'can_return': False,
            'primary_action': 'dispense',
        },
    }


@pytest.mark.asyncio
async def test_get_admin_workbench_overview_returns_metrics_and_slices(monkeypatch):
    async def fake_list_admin_workbench_prescriptions(session, **kwargs):
        assert kwargs['state'] == 'actionable'
        return {
            'items': [
                {'uuid': 'p1', 'drug_state': DrugState.PAID.value},
                {'uuid': 'p2', 'drug_state': DrugState.DISPENSED.value},
            ],
            'pagination': {'total': 2, 'limit': 6, 'offset': 0},
        }

    async def fake_list_admin_workbench_drugs(session, **kwargs):
        assert kwargs['low_stock_only'] is True
        return {
            'items': [
                {'uuid': 'd1', 'is_low_stock': True},
                {'uuid': 'd2', 'is_low_stock': True},
            ],
            'pagination': {'total': 2, 'limit': 6, 'offset': 0},
        }

    session = FakeSession(
        execute_results=[
            FakeExecuteResult(scalar_value=3),
            FakeExecuteResult(scalar_value=4),
            FakeExecuteResult(scalar_value=2),
            FakeExecuteResult(scalar_value=12),
        ]
    )

    monkeypatch.setattr(pharmacy_service, 'list_admin_workbench_prescriptions', fake_list_admin_workbench_prescriptions)
    monkeypatch.setattr(pharmacy_service, 'list_admin_workbench_drugs', fake_list_admin_workbench_drugs)

    result = await pharmacy_service.get_admin_workbench_overview(session)

    assert result == {
        'paid_prescription_count': 3,
        'dispensed_prescription_count': 4,
        'low_stock_drug_count': 2,
        'total_drug_count': 12,
        'low_stock_drugs': [
            {'uuid': 'd1', 'is_low_stock': True},
            {'uuid': 'd2', 'is_low_stock': True},
        ],
        'actionable_prescriptions': [
            {'uuid': 'p1', 'drug_state': DrugState.PAID.value},
            {'uuid': 'p2', 'drug_state': DrugState.DISPENSED.value},
        ],
    }


@pytest.mark.asyncio
async def test_adjust_drug_stock_supports_increase_and_set():
    drug_uuid = uuid.uuid4()
    drug = SimpleNamespace(
        uuid=drug_uuid,
        stock=8,
        min_stock_limit=3,
    )

    session = FakeSession(execute_results=[FakeExecuteResult(scalar_value=drug)])
    increased = await pharmacy_service.adjust_drug_stock(
        session,
        str(drug_uuid),
        {'mode': 'increase', 'quantity': 5},
    )

    assert increased == {
        'drug_uuid': str(drug_uuid),
        'previous_stock': 8,
        'current_stock': 13,
        'mode': 'increase',
        'quantity': 5,
    }
    assert drug.stock == 13

    set_session = FakeSession(execute_results=[FakeExecuteResult(scalar_value=drug)])
    updated = await pharmacy_service.adjust_drug_stock(
        set_session,
        str(drug_uuid),
        {'mode': 'set', 'quantity': 4},
    )

    assert updated == {
        'drug_uuid': str(drug_uuid),
        'previous_stock': 13,
        'current_stock': 4,
        'mode': 'set',
        'quantity': 4,
    }
    assert drug.stock == 4


@pytest.mark.asyncio
async def test_adjust_drug_stock_rejects_invalid_quantity_and_missing_drug():
    missing_session = FakeSession(execute_results=[FakeExecuteResult(scalar_value=None)])
    with pytest.raises(ValueError, match='药品不存在'):
        await pharmacy_service.adjust_drug_stock(
            missing_session,
            str(uuid.uuid4()),
            {'mode': 'increase', 'quantity': 2},
        )

    drug = SimpleNamespace(uuid=uuid.uuid4(), stock=6, min_stock_limit=3)
    invalid_session = FakeSession(execute_results=[FakeExecuteResult(scalar_value=drug)])
    with pytest.raises(ValueError, match='quantity'):
        await pharmacy_service.adjust_drug_stock(
            invalid_session,
            str(drug.uuid),
            {'mode': 'increase', 'quantity': 0},
        )


@pytest.mark.asyncio
async def test_batch_import_drugs_rejects_duplicate_codes_in_request():
    session = FakeSession()

    with pytest.raises(ValueError, match='drug_code'):
        await pharmacy_service.batch_import_drugs(
            session,
            [
                {
                    'drug_code': 'DRUG-001',
                    'drug_name': 'A',
                    'specification': '10mg',
                    'unit': '盒',
                    'price': 12,
                    'stock': 10,
                    'min_stock_limit': 3,
                },
                {
                    'drug_code': 'DRUG-001',
                    'drug_name': 'B',
                    'specification': '20mg',
                    'unit': '盒',
                    'price': 18,
                    'stock': 8,
                    'min_stock_limit': 2,
                },
            ],
        )


@pytest.mark.asyncio
async def test_batch_import_drugs_returns_successes_and_failures_for_existing_codes(monkeypatch):
    existing_drug = SimpleNamespace(drug_code='DRUG-002')

    async def fake_get_embedding(text):
        return [0.1, 0.2]

    monkeypatch.setattr('app.common.ai_embedding.get_embedding', fake_get_embedding)

    session = FakeSession(
        execute_results=[
            FakeExecuteResult(values=[existing_drug]),
        ]
    )

    result = await pharmacy_service.batch_import_drugs(
        session,
        [
            {
                'drug_code': 'DRUG-001',
                'drug_name': '甘露醇注射液',
                'specification': '250ml/瓶',
                'unit': '瓶',
                'price': 38,
                'stock': 60,
                'min_stock_limit': 10,
            },
            {
                'drug_code': 'DRUG-002',
                'drug_name': '阿司匹林',
                'specification': '100mg*30片',
                'unit': '盒',
                'price': 12,
                'stock': 20,
                'min_stock_limit': 5,
            },
        ],
    )

    assert result['successes'] == [
        {
            'uuid': str(session.added[0].uuid),
            'drug_name': '甘露醇注射液',
            'drug_code': 'DRUG-001',
        }
    ]
    assert result['failures'] == [
        {
            'drug_code': 'DRUG-002',
            'reason': 'drug_code already exists',
        }
    ]
