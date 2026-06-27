-- Prevent duplicate pending scheduling applications for the same doctor/content.
-- Rejected or approved applications are historical facts and remain repeatable.

WITH ranked_duplicates AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY employee_uuid, md5(prompt)
            ORDER BY created_at ASC, id ASC
        ) AS row_no
    FROM public.scheduling_application
    WHERE status = 'pending'
)
UPDATE public.scheduling_application app
SET status = 'duplicate'
FROM ranked_duplicates dup
WHERE app.id = dup.id AND dup.row_no > 1;

CREATE UNIQUE INDEX IF NOT EXISTS ux_scheduling_application_pending_content
    ON public.scheduling_application (employee_uuid, md5(prompt))
    WHERE status = 'pending';
