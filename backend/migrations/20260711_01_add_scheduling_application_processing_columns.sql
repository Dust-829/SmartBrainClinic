ALTER TABLE public.scheduling_application
    ADD COLUMN IF NOT EXISTS reject_reason text;

ALTER TABLE public.scheduling_application
    ADD COLUMN IF NOT EXISTS processed_at timestamp without time zone;
