from pathlib import Path


def test_ai_draft_supports_structured_triage_context_envelope():
    source = Path("app/microservices/medical/services/ai_draft.py").read_text(encoding="utf-8")

    assert "def _normalize_draft_context(" in source
    assert 'payload.get("profile_snapshot")' in source
    assert 'payload.get("summary_text")' in source
    assert 'payload.get("latest_result")' in source
    assert 'payload.get("messages")' in source
    assert 'payload.get("fallback_symptoms")' in source
    assert "def _build_draft_context_text(" in source
    assert "def _build_patient_text(" in source
    assert "【AI分诊摘要】" in source
    assert "【分诊对话记录】" in source


def test_register_consumer_prefers_ai_context_before_legacy_symptoms():
    source = Path("app/microservices/medical/workers/register_consumer.py").read_text(encoding="utf-8")

    assert "PatientClient.get_register_ai_context(register_uuid_obj)" in source
    assert "_build_draft_context_payload(ai_context, symptoms)" in source
    assert '"profile_snapshot": ai_context.get("profile_snapshot")' in source
    assert '"summary_text": ai_context.get("summary_text")' in source
    assert '"latest_result": ai_context.get("latest_result")' in source
    assert '"messages": ai_context.get("messages") or []' in source
    assert '"fallback_symptoms": symptoms' in source
    assert "conversation_json=draft_input_json" in source


def test_register_consumer_embedding_text_uses_new_triage_context_fields():
    source = Path("app/microservices/medical/workers/register_consumer.py").read_text(encoding="utf-8")

    assert "def _extract_embedding_text(" in source
    assert 'draft_context_payload.get("messages") or []' in source
    assert 'draft_context_payload.get("summary_text")' in source
    assert 'latest_result.get("data")' in source
    assert 'data.get("symptom_summary")' in source
    assert 'draft_context_payload.get("fallback_symptoms")' in source
