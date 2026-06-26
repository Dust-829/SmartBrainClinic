-- Create idempotency records for high-risk write operations.
-- This migration is idempotent and can be run repeatedly.

CREATE TABLE IF NOT EXISTS public.idempotency_record (
    id BIGSERIAL PRIMARY KEY,
    scope VARCHAR(128) NOT NULL,
    idempotency_key VARCHAR(128) NOT NULL,
    request_hash VARCHAR(64) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'processing',
    response_body TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_idempotency_record_scope_key UNIQUE (scope, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_idempotency_record_scope_created
    ON public.idempotency_record (scope, created_at DESC);

