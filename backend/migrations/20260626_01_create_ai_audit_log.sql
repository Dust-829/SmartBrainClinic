-- Create AI audit log table.
-- This migration is idempotent and can be run repeatedly.

CREATE TABLE IF NOT EXISTS public.ai_audit_log (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL,
    module_name VARCHAR(128) NOT NULL,
    source VARCHAR(32),
    model VARCHAR(128),
    input_summary TEXT,
    output_summary TEXT,
    warnings TEXT,
    validated BOOLEAN DEFAULT FALSE,
    validator_messages TEXT,
    latency_ms INTEGER,
    context TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_audit_log_module_created
    ON public.ai_audit_log (module_name, created_at DESC);

