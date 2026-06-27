-- Track downstream refund saga steps for billing refunds.
-- This makes partial cross-service refund results observable and retryable.

CREATE TABLE IF NOT EXISTS public.billing_refund_saga_step (
    id BIGSERIAL PRIMARY KEY,
    bill_code VARCHAR(64) NOT NULL,
    step_name VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    request_payload TEXT,
    response_payload TEXT,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_billing_refund_saga_step UNIQUE (bill_code, step_name)
);

CREATE INDEX IF NOT EXISTS idx_billing_refund_saga_step_bill
    ON public.billing_refund_saga_step (bill_code);

CREATE INDEX IF NOT EXISTS idx_billing_refund_saga_step_status
    ON public.billing_refund_saga_step (status);
