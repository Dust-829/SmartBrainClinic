import sys
import uuid
from datetime import date
from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.microservices.patient.api.patient import _build_triage_profile_snapshot
from app.microservices.patient.models.patient import Patient
from app.microservices.patient.services.ai_triage import _build_triage_llm_messages


def test_triage_profile_snapshot_uses_gender_and_calculated_age():
    patient = Patient(
        uuid=uuid.uuid4(),
        case_number='P-001',
        real_name='张三',
        gender='男',
        card_number='210102199001011234',
        birthdate=date(1990, 7, 16),
    )

    snapshot = _build_triage_profile_snapshot(patient, today=date(2026, 7, 15))

    assert snapshot == {'gender': '男', 'age': 35}


def test_triage_prompt_includes_profile_and_does_not_include_identity():
    llm_messages = _build_triage_llm_messages(
        [{'role': 'user', 'content': '我头痛两天了'}],
        profile_snapshot={'gender': '女', 'age': 36},
    )

    profile_context = llm_messages[1]['content']
    assert '性别为女，年龄为36岁' in profile_context
    assert '不要再次询问患者年龄或性别' in profile_context
    assert '张三' not in profile_context
