from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parents[1]


def test_ai_conversation_migration_creates_shared_session_and_message_tables():
    source = (BACKEND_DIR / "migrations" / "20260708_01_create_ai_conversation_tables.sql").read_text(
        encoding="utf-8"
    )

    assert "CREATE TABLE IF NOT EXISTS public.ai_conversation_session" in source
    assert "CREATE TABLE IF NOT EXISTS public.ai_conversation_message" in source
    assert "FOREIGN KEY (session_uuid)" in source
    assert "UNIQUE (session_uuid, turn_index)" in source


def test_ai_conversation_models_expose_json_and_tracking_fields():
    source = (BACKEND_DIR / "app" / "common" / "ai_conversation.py").read_text(encoding="utf-8")

    assert 'class AIConversationSession(SQLModel, table=True):' in source
    assert '__tablename__ = "ai_conversation_session"' in source
    assert "profile_snapshot_json" in source
    assert "latest_result_json" in source
    assert 'class AIConversationMessage(SQLModel, table=True):' in source
    assert '__tablename__ = "ai_conversation_message"' in source
    assert "session_uuid" in source
    assert "turn_index" in source


def test_ai_conversation_helpers_create_append_and_update_records():
    source = (BACKEND_DIR / "app" / "common" / "ai_conversation.py").read_text(encoding="utf-8")

    assert "async def create_ai_conversation_session(" in source
    assert "async def append_ai_conversation_messages(" in source
    assert "async def update_ai_conversation_session(" in source
    assert "async def _get_next_turn_index(" in source
    assert "turn_index=next_turn_index + offset" in source
    assert 'raise ValueError("AI conversation session not found")' in source
    assert "record.updated_at = datetime.now()" in source
