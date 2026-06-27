-- Harden AI audit log querying.
-- Desensitization is applied in application code before rows are inserted.

CREATE INDEX IF NOT EXISTS idx_ai_audit_log_created_at
    ON public.ai_audit_log (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_audit_log_validated_created
    ON public.ai_audit_log (validated, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_audit_log_source_created
    ON public.ai_audit_log (source, created_at DESC);

COMMENT ON TABLE public.ai_audit_log IS
    'Desensitized AI request/response audit summaries for trust, validation, and traceability.';
