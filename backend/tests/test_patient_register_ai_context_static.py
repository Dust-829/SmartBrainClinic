from pathlib import Path


def test_patient_register_ai_context_endpoint_and_client_exist():
    api_source = Path("app/microservices/patient/api/patient.py").read_text(encoding="utf-8")
    client_source = Path("app/common/clients.py").read_text(encoding="utf-8")
    conversation_source = Path("app/common/ai_conversation.py").read_text(encoding="utf-8")

    assert "async def get_latest_ai_conversation_session_by_register(" in conversation_source
    assert "@router.get('/register/{register_uuid}/ai-context'" in api_source
    assert "async def get_register_ai_context(register_uuid: uuid_pkg.UUID" in api_source
    assert "get_latest_ai_conversation_session_by_register(" in api_source
    assert "module_name='patient.triage'" in api_source
    assert "surface='patient_triage'" in api_source
    assert "'profile_snapshot': triage_session.profile_snapshot_json" in api_source
    assert "'latest_result': triage_session.latest_result_json" in api_source
    assert "'messages': [" in api_source
    assert "async def get_register_ai_context(register_uuid: uuid_pkg.UUID):" in client_source
    assert "/register/{register_uuid}/ai-context" in client_source
