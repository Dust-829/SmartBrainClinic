-- Reserve billable source items to prevent concurrent duplicate charges.
-- The lock is retained after refund because refunded items are terminal in the
-- current state machine and should not be charged again without an explicit
-- reopen/reissue workflow.

CREATE TABLE IF NOT EXISTS public.billing_item_charge_lock (
    id BIGSERIAL PRIMARY KEY,
    item_type VARCHAR(64) NOT NULL,
    item_source_id VARCHAR(64) NOT NULL,
    bill_id INTEGER NOT NULL REFERENCES public.outpatient_bill(id),
    bill_code VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_billing_item_charge_lock_item UNIQUE (item_type, item_source_id)
);

CREATE INDEX IF NOT EXISTS idx_billing_item_charge_lock_bill_id
    ON public.billing_item_charge_lock (bill_id);

CREATE TABLE IF NOT EXISTS public.billing_duplicate_charge_audit (
    id BIGSERIAL PRIMARY KEY,
    item_type VARCHAR(64) NOT NULL,
    item_source_id VARCHAR(64) NOT NULL,
    duplicate_count INTEGER NOT NULL,
    bill_ids TEXT NOT NULL,
    bill_codes TEXT NOT NULL,
    detail_ids TEXT NOT NULL,
    audited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_billing_duplicate_charge_audit_item UNIQUE (item_type, item_source_id)
);

INSERT INTO public.billing_duplicate_charge_audit (
    item_type,
    item_source_id,
    duplicate_count,
    bill_ids,
    bill_codes,
    detail_ids,
    audited_at
)
SELECT
    d.item_type,
    d.item_source_id,
    COUNT(*)::INTEGER AS duplicate_count,
    STRING_AGG(b.id::TEXT, ',' ORDER BY b.pay_time ASC, b.id ASC) AS bill_ids,
    STRING_AGG(b.bill_code, ',' ORDER BY b.pay_time ASC, b.id ASC) AS bill_codes,
    STRING_AGG(d.id::TEXT, ',' ORDER BY b.pay_time ASC, b.id ASC) AS detail_ids,
    CURRENT_TIMESTAMP
FROM public.outpatient_bill_detail d
JOIN public.outpatient_bill b ON b.id = d.bill_id
GROUP BY d.item_type, d.item_source_id
HAVING COUNT(*) > 1
ON CONFLICT (item_type, item_source_id) DO UPDATE SET
    duplicate_count = EXCLUDED.duplicate_count,
    bill_ids = EXCLUDED.bill_ids,
    bill_codes = EXCLUDED.bill_codes,
    detail_ids = EXCLUDED.detail_ids,
    audited_at = CURRENT_TIMESTAMP;

INSERT INTO public.billing_item_charge_lock (
    item_type,
    item_source_id,
    bill_id,
    bill_code,
    created_at
)
SELECT DISTINCT ON (d.item_type, d.item_source_id)
    d.item_type,
    d.item_source_id,
    b.id,
    b.bill_code,
    COALESCE(b.pay_time, CURRENT_TIMESTAMP)
FROM public.outpatient_bill_detail d
JOIN public.outpatient_bill b ON b.id = d.bill_id
ORDER BY d.item_type, d.item_source_id, b.pay_time ASC, b.id ASC
ON CONFLICT (item_type, item_source_id) DO NOTHING;
