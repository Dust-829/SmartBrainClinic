-- Doctor-reviewed reports and internal CT artifact inference tasks.
-- This migration is intentionally idempotent for local development deployments.

CREATE TABLE IF NOT EXISTS public.artifact_inference_task (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL,
    check_uuid UUID NOT NULL,
    register_uuid UUID NOT NULL,
    submitted_by_employee_uuid UUID,
    source_image_ref VARCHAR(1024) NOT NULL,
    source_format VARCHAR(32),
    selected_series_ref VARCHAR(1024),
    task_state VARCHAR(32) NOT NULL DEFAULT 'queued',
    model_name VARCHAR(128) NOT NULL DEFAULT 'attention-unet2d',
    model_version VARCHAR(128),
    model_weight_sha256 VARCHAR(64),
    threshold NUMERIC(4, 3),
    mask_object_ref VARCHAR(1024),
    overlay_object_ref VARCHAR(1024),
    result_metadata JSONB,
    error_code VARCHAR(64),
    error_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    CONSTRAINT uq_artifact_inference_task_uuid UNIQUE (uuid)
);

CREATE INDEX IF NOT EXISTS idx_artifact_inference_task_check_created
    ON public.artifact_inference_task (check_uuid, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_artifact_inference_task_register_created
    ON public.artifact_inference_task (register_uuid, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_artifact_inference_task_state_created
    ON public.artifact_inference_task (task_state, created_at DESC);

CREATE TABLE IF NOT EXISTS public.medical_report (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL,
    register_uuid UUID NOT NULL,
    source_request_uuid UUID NOT NULL,
    report_type VARCHAR(32) NOT NULL,
    report_state VARCHAR(32) NOT NULL DEFAULT 'draft',
    conclusion TEXT,
    structured_result JSONB,
    artifact_task_uuid UUID,
    reviewer_employee_uuid UUID,
    reviewed_at TIMESTAMP,
    published_at TIMESTAMP,
    version INTEGER NOT NULL DEFAULT 1,
    supersedes_report_uuid UUID,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_medical_report_uuid UNIQUE (uuid)
);

CREATE INDEX IF NOT EXISTS idx_medical_report_register_state_published
    ON public.medical_report (register_uuid, report_state, published_at DESC);

CREATE INDEX IF NOT EXISTS idx_medical_report_request_version
    ON public.medical_report (source_request_uuid, version DESC);

CREATE INDEX IF NOT EXISTS idx_medical_report_artifact_task
    ON public.medical_report (artifact_task_uuid);
