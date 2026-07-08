from pathlib import Path


def test_patient_triage_api_now_accepts_and_returns_session_tracking():
    source = Path("app/microservices/patient/api/patient.py").read_text(encoding="utf-8")

    assert "patient_uuid: Optional[uuid_pkg.UUID] = None" in source
    assert "session_uuid: Optional[uuid_pkg.UUID] = None" in source
    assert "create_ai_conversation_session(" in source
    assert "get_ai_conversation_session(session, data.session_uuid)" in source
    assert "update_ai_conversation_session(" in source
    assert "res['session_uuid'] = str(triage_session.uuid)" in source


def test_patient_triage_syncs_only_new_messages_into_ai_session():
    source = Path("app/microservices/patient/api/patient.py").read_text(encoding="utf-8")

    assert "async def _sync_triage_session_messages(" in source
    assert "existing_messages = await list_ai_conversation_messages(session, session_uuid)" in source
    assert "messages[: len(existing_payload)] != existing_payload" in source
    assert "new_messages = messages[len(existing_payload):]" in source
    assert "append_ai_conversation_messages(session, session_uuid, new_messages" in source
    assert "assistant_reply = triage_data.get('reply')" in source
    assert "{'role': 'assistant', 'content': assistant_reply}" in source
