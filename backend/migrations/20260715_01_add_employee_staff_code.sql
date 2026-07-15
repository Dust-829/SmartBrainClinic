-- 为医生账号密码登录补齐可管理的工号。
ALTER TABLE public.employee
    ADD COLUMN IF NOT EXISTS staff_code character varying(64);

UPDATE public.employee
SET staff_code = 'DOC-' || lpad(id::text, 6, '0')
WHERE staff_code IS NULL OR btrim(staff_code) = '';

ALTER TABLE public.employee
    ALTER COLUMN staff_code SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ix_employee_staff_code
    ON public.employee USING btree (staff_code);
