-- Refine AI audit human review queue semantics.
-- review_status is only populated when a log enters the human review queue.

ALTER TABLE public.ai_audit_log
    ALTER COLUMN review_status DROP NOT NULL,
    ALTER COLUMN review_status DROP DEFAULT;

UPDATE public.ai_audit_log
SET review_status = CASE
    WHEN validated = FALSE THEN 'pending'
    WHEN COALESCE(NULLIF(BTRIM(validator_messages), ''), '[]') <> '[]' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%_llm_second_review_rejected:%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%_llm_second_review_schema_invalid:%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%llm_triage_low_quality_fallback%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%llm_triage_request_failed_fallback%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%llm_triage_no_valid_result_fallback%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%llm_triage_not_configured_fallback%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%no_valid_draft_context%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%agent_execution_failed%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%allergy_conflict%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%stock_insufficient%' THEN 'pending'
    WHEN LOWER(COALESCE(warnings, '')) LIKE '%not_found_in_db%' THEN 'pending'
    ELSE NULL
END
WHERE review_status = 'pending';

COMMENT ON COLUMN public.ai_audit_log.review_status IS
    'Human review state: NULL means not queued; pending, approved, or rejected indicate queued/reviewed logs.';
