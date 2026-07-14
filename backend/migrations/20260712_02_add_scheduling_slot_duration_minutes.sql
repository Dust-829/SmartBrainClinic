ALTER TABLE public.scheduling_rule
    ADD COLUMN IF NOT EXISTS slot_duration_minutes integer NOT NULL DEFAULT 10;

ALTER TABLE public.scheduling_actual
    ADD COLUMN IF NOT EXISTS slot_duration_minutes integer NOT NULL DEFAULT 10;
