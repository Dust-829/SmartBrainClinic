-- Create shared AI conversation session/message tables.
-- These tables keep full transcripts separate from register.symptoms and ai_audit_log.

CREATE TABLE IF NOT EXISTS public.ai_conversation_session (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL,
    surface VARCHAR(64) NOT NULL,
    module_name VARCHAR(128) NOT NULL,
    patient_uuid UUID,
    register_uuid UUID,
    employee_uuid UUID,
    status VARCHAR(32) NOT NULL DEFAULT 'draft',
    profile_snapshot_json JSONB,
    latest_result_json JSONB,
    summary_text TEXT,
    source VARCHAR(32),
    model VARCHAR(128),
    validated BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ai_conversation_session_uuid UNIQUE (uuid)
);

CREATE INDEX IF NOT EXISTS idx_ai_conversation_session_patient_surface_created
    ON public.ai_conversation_session (patient_uuid, surface, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_conversation_session_register
    ON public.ai_conversation_session (register_uuid);

CREATE INDEX IF NOT EXISTS idx_ai_conversation_session_status_updated
    ON public.ai_conversation_session (status, updated_at DESC);

CREATE TABLE IF NOT EXISTS public.ai_conversation_message (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL,
    session_uuid UUID NOT NULL,
    turn_index INTEGER NOT NULL,
    role VARCHAR(32) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ai_conversation_message_uuid UNIQUE (uuid),
    CONSTRAINT uq_ai_conversation_message_turn UNIQUE (session_uuid, turn_index),
    CONSTRAINT fk_ai_conversation_message_session
        FOREIGN KEY (session_uuid)
        REFERENCES public.ai_conversation_session (uuid)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ai_conversation_message_session_turn
    ON public.ai_conversation_message (session_uuid, turn_index);

CREATE INDEX IF NOT EXISTS idx_ai_conversation_message_created
    ON public.ai_conversation_message (created_at DESC);

