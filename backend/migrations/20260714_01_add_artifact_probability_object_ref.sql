ALTER TABLE public.artifact_inference_task
    ADD COLUMN IF NOT EXISTS probability_object_ref VARCHAR(1024);
