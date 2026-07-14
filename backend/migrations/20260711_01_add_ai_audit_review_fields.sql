-- Add human review workflow fields to AI audit log.
-- This migration is idempotent and can be run repeatedly.

ALTER TABLE public.ai_audit_log
    ADD COLUMN IF NOT EXISTS review_status VARCHAR(16) NOT NULL DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS review_note TEXT,
    ADD COLUMN IF NOT EXISTS reviewer VARCHAR(64),
    ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_ai_audit_log_review_status_created
    ON public.ai_audit_log (review_status, created_at DESC);

COMMENT ON COLUMN public.ai_audit_log.review_status IS
    'Human review state: pending, approved, or rejected.';
