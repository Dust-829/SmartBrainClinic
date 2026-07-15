import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.microservices.patient.services.ai_triage import _mock_multi_turn_triage


def test_rule_fallback_routes_hypertension_to_cardiology():
    result = _mock_multi_turn_triage(
        [{'role': 'user', 'content': '我有高血压应该挂什么科室的号'}]
    )

    assert result['dept_determined'] is True
    assert result['recommended_dept_code'] == 'XNK'
    assert '心内科' in result['reply']
