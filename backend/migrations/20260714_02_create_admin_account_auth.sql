-- Administrator identities and account-management operation audit.
-- Apply after the existing migrations. This migration is idempotent.

CREATE TABLE IF NOT EXISTS public.admin_account (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    staff_code VARCHAR(64) NOT NULL UNIQUE,
    display_name VARCHAR(64) NOT NULL,
    password_hash VARCHAR(128) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_admin_account_active_staff_code
    ON public.admin_account (is_active, staff_code);

CREATE TABLE IF NOT EXISTS public.account_operation_audit (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    actor_admin_uuid UUID NOT NULL,
    target_type VARCHAR(32) NOT NULL,
    target_uuid UUID NOT NULL,
    action VARCHAR(64) NOT NULL,
    result VARCHAR(16) NOT NULL,
    detail TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_account_operation_audit_target_created
    ON public.account_operation_audit (target_type, target_uuid, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_account_operation_audit_actor_created
    ON public.account_operation_audit (actor_admin_uuid, created_at DESC);
