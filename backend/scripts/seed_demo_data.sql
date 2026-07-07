BEGIN;

-- Sync sequences before inserts on an existing database snapshot.
SELECT setval(pg_get_serial_sequence('department', 'id'), COALESCE((SELECT MAX(id) FROM department), 1), TRUE);
SELECT setval(pg_get_serial_sequence('clinic_room', 'id'), COALESCE((SELECT MAX(id) FROM clinic_room), 1), TRUE);
SELECT setval(pg_get_serial_sequence('regist_level', 'id'), COALESCE((SELECT MAX(id) FROM regist_level), 1), TRUE);
SELECT setval(pg_get_serial_sequence('settle_category', 'id'), COALESCE((SELECT MAX(id) FROM settle_category), 1), TRUE);
SELECT setval(pg_get_serial_sequence('employee', 'id'), COALESCE((SELECT MAX(id) FROM employee), 1), TRUE);
SELECT setval(pg_get_serial_sequence('patient', 'id'), COALESCE((SELECT MAX(id) FROM patient), 1), TRUE);
SELECT setval(pg_get_serial_sequence('scheduling_actual', 'id'), COALESCE((SELECT MAX(id) FROM scheduling_actual), 1), TRUE);
SELECT setval(pg_get_serial_sequence('scheduling_time_slot', 'id'), COALESCE((SELECT MAX(id) FROM scheduling_time_slot), 1), TRUE);
SELECT setval(pg_get_serial_sequence('register', 'id'), COALESCE((SELECT MAX(id) FROM register), 1), TRUE);
SELECT setval(pg_get_serial_sequence('scheduling_rule', 'id'), COALESCE((SELECT MAX(id) FROM scheduling_rule), 1), TRUE);
SELECT setval(pg_get_serial_sequence('medical_record', 'id'), COALESCE((SELECT MAX(id) FROM medical_record), 1), TRUE);
SELECT setval(pg_get_serial_sequence('medical_technology', 'id'), COALESCE((SELECT MAX(id) FROM medical_technology), 1), TRUE);
SELECT setval(pg_get_serial_sequence('drug_info', 'id'), COALESCE((SELECT MAX(id) FROM drug_info), 1), TRUE);

-- Demo reference data
INSERT INTO department (uuid, dept_code, dept_name, dept_type, delmark)
VALUES
  ('90000000-0000-0000-0000-000000000001', 'ADMIN', '院务管理', 'management', 1)
ON CONFLICT (dept_code) DO UPDATE
SET dept_name = EXCLUDED.dept_name,
    dept_type = EXCLUDED.dept_type,
    delmark = 1;

INSERT INTO clinic_room (uuid, dept_uuid, room_name, location, delmark)
VALUES
  (
    '90000000-0000-0000-0000-000000000011',
    (SELECT uuid FROM department WHERE dept_code = 'SJWK'),
    '神外一诊室',
    'A楼5层东侧',
    1
  ),
  (
    '90000000-0000-0000-0000-000000000012',
    (SELECT uuid FROM department WHERE dept_code = 'SJWK'),
    '神外二诊室',
    'A楼5层西侧',
    1
  )
ON CONFLICT (uuid) DO UPDATE
SET dept_uuid = EXCLUDED.dept_uuid,
    room_name = EXCLUDED.room_name,
    location = EXCLUDED.location,
    delmark = 1;

INSERT INTO regist_level (uuid, regist_code, regist_name, regist_fee, delmark)
VALUES
  ('90000000-0000-0000-0000-000000000021', 'DEMO_ZJH', '演示专家号', 60.00, 1)
ON CONFLICT (regist_code) DO UPDATE
SET regist_name = EXCLUDED.regist_name,
    regist_fee = EXCLUDED.regist_fee,
    delmark = 1;

INSERT INTO settle_category (uuid, settle_code, settle_name, delmark)
VALUES
  ('22222222-2222-2222-2222-222222222222', 'ZF', '自费', 1)
ON CONFLICT (settle_code) DO NOTHING;

-- Demo staff and doctors
INSERT INTO employee (uuid, dept_id, regist_level_id, realname, password, expertise, gender, ai_eval_score, delmark)
VALUES
  (
    '90000000-0000-0000-0000-000000000101',
    (SELECT id FROM department WHERE dept_code = 'SJWK'),
    (SELECT id FROM regist_level WHERE regist_code = 'DEMO_ZJH'),
    '陈松涛',
    '123',
    '脑肿瘤、颅脑手术、术中导航',
    'male',
    4.8,
    1
  ),
  (
    '90000000-0000-0000-0000-000000000102',
    (SELECT id FROM department WHERE dept_code = 'SJWK'),
    (SELECT id FROM regist_level WHERE regist_code = 'DEMO_ZJH'),
    '顾宁',
    '123',
    '头痛、眩晕、脑血管随访',
    'female',
    4.7,
    1
  ),
  (
    '90000000-0000-0000-0000-000000000201',
    (SELECT id FROM department WHERE dept_code = 'ADMIN'),
    NULL,
    '周院管',
    '123',
    '排班审核、运营协调',
    'female',
    4.5,
    1
  )
ON CONFLICT (uuid) DO UPDATE
SET dept_id = EXCLUDED.dept_id,
    regist_level_id = EXCLUDED.regist_level_id,
    realname = EXCLUDED.realname,
    password = EXCLUDED.password,
    expertise = EXCLUDED.expertise,
    gender = EXCLUDED.gender,
    ai_eval_score = EXCLUDED.ai_eval_score,
    delmark = 1;

-- Demo patients
INSERT INTO patient (uuid, case_number, real_name, gender, card_number, birthdate, home_address, created_at)
VALUES
  ('90000000-0000-0000-0000-000000000301', 'SBC-DEMO-P001', '张晨曦', 'female', '310101199001010011', DATE '1990-01-01', '浦东新区演示路88号', NOW()),
  ('90000000-0000-0000-0000-000000000302', 'SBC-DEMO-P002', '李沐川', 'male', '310101198812120022', DATE '1988-12-12', '杨浦区门诊巷18号', NOW()),
  ('90000000-0000-0000-0000-000000000303', 'SBC-DEMO-P003', '王若岚', 'female', '310101199511050033', DATE '1995-11-05', '徐汇区康复路66号', NOW()),
  ('90000000-0000-0000-0000-000000000304', 'SBC-DEMO-P004', '赵志远', 'male', '310101198503030044', DATE '1985-03-03', '静安区复诊路28号', NOW())
ON CONFLICT (card_number) DO UPDATE
SET case_number = EXCLUDED.case_number,
    real_name = EXCLUDED.real_name,
    gender = EXCLUDED.gender,
    birthdate = EXCLUDED.birthdate,
    home_address = EXCLUDED.home_address;

-- Demo schedules for today and tomorrow
INSERT INTO scheduling_actual (uuid, employee_uuid, schedule_date, noon, regist_quota, registered_count, clinic_room_uuid)
VALUES
  ('90000000-0000-0000-0000-000000000401', '90000000-0000-0000-0000-000000000101', CURRENT_DATE, U&'\4E0A\5348', 4, 3, '90000000-0000-0000-0000-000000000011'),
  ('90000000-0000-0000-0000-000000000402', '90000000-0000-0000-0000-000000000101', CURRENT_DATE + 1, U&'\4E0A\5348', 4, 0, '90000000-0000-0000-0000-000000000011'),
  ('90000000-0000-0000-0000-000000000403', '90000000-0000-0000-0000-000000000102', CURRENT_DATE, U&'\4E0A\5348', 4, 1, '90000000-0000-0000-0000-000000000012'),
  ('90000000-0000-0000-0000-000000000404', '90000000-0000-0000-0000-000000000102', CURRENT_DATE + 1, U&'\4E0B\5348', 4, 0, '90000000-0000-0000-0000-000000000012')
ON CONFLICT (uuid) DO UPDATE
SET employee_uuid = EXCLUDED.employee_uuid,
    schedule_date = EXCLUDED.schedule_date,
    noon = EXCLUDED.noon,
    regist_quota = EXCLUDED.regist_quota,
    registered_count = EXCLUDED.registered_count,
    clinic_room_uuid = EXCLUDED.clinic_room_uuid;

-- Demo time slots
INSERT INTO scheduling_time_slot (uuid, scheduling_actual_id, time_range, is_booked)
VALUES
  ('90000000-0000-0000-0000-000000000501', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000401'), '08:00-08:10', TRUE),
  ('90000000-0000-0000-0000-000000000502', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000401'), '08:10-08:20', TRUE),
  ('90000000-0000-0000-0000-000000000503', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000401'), '08:20-08:30', TRUE),
  ('90000000-0000-0000-0000-000000000504', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000401'), '08:30-08:40', FALSE),
  ('90000000-0000-0000-0000-000000000505', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000402'), '08:00-08:10', FALSE),
  ('90000000-0000-0000-0000-000000000506', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000402'), '08:10-08:20', FALSE),
  ('90000000-0000-0000-0000-000000000507', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000402'), '08:20-08:30', FALSE),
  ('90000000-0000-0000-0000-000000000508', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000402'), '08:30-08:40', FALSE),
  ('90000000-0000-0000-0000-000000000509', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000403'), '08:00-08:10', TRUE),
  ('90000000-0000-0000-0000-00000000050a', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000403'), '08:10-08:20', FALSE),
  ('90000000-0000-0000-0000-00000000050b', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000403'), '08:20-08:30', FALSE),
  ('90000000-0000-0000-0000-00000000050c', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000403'), '08:30-08:40', FALSE),
  ('90000000-0000-0000-0000-00000000050d', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000404'), '13:00-13:10', FALSE),
  ('90000000-0000-0000-0000-00000000050e', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000404'), '13:10-13:20', FALSE),
  ('90000000-0000-0000-0000-00000000050f', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000404'), '13:20-13:30', FALSE),
  ('90000000-0000-0000-0000-000000000510', (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000404'), '13:30-13:40', FALSE)
ON CONFLICT (uuid) DO UPDATE
SET scheduling_actual_id = EXCLUDED.scheduling_actual_id,
    time_range = EXCLUDED.time_range,
    is_booked = EXCLUDED.is_booked;

-- Demo registers for doctor workbench
INSERT INTO register (
  uuid, patient_id, visit_date, noon, dept_uuid, employee_uuid, scheduling_actual_id, scheduling_time_slot_id,
  settle_category_uuid, regist_method, regist_money, is_emergency, visit_state, symptoms
)
VALUES
  (
    '90000000-0000-0000-0000-000000000601',
    (SELECT id FROM patient WHERE card_number = '310101199001010011'),
    CURRENT_DATE::timestamp + TIME '08:00',
    U&'\4E0A\5348',
    (SELECT uuid FROM department WHERE dept_code = 'SJWK'),
    '90000000-0000-0000-0000-000000000101',
    (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000401'),
    (SELECT id FROM scheduling_time_slot WHERE uuid = '90000000-0000-0000-0000-000000000501'),
    '22222222-2222-2222-2222-222222222222',
    'wechat',
    60.00,
    FALSE,
    2,
    '头痛伴恶心两周，外院影像提示需进一步复诊。'
  ),
  (
    '90000000-0000-0000-0000-000000000602',
    (SELECT id FROM patient WHERE card_number = '310101198812120022'),
    CURRENT_DATE::timestamp + TIME '08:10',
    U&'\4E0A\5348',
    (SELECT uuid FROM department WHERE dept_code = 'SJWK'),
    '90000000-0000-0000-0000-000000000101',
    (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000401'),
    (SELECT id FROM scheduling_time_slot WHERE uuid = '90000000-0000-0000-0000-000000000502'),
    '22222222-2222-2222-2222-222222222222',
    'wechat',
    60.00,
    FALSE,
    1,
    '头晕伴右上肢麻木三天。'
  ),
  (
    '90000000-0000-0000-0000-000000000603',
    (SELECT id FROM patient WHERE card_number = '310101199511050033'),
    CURRENT_DATE::timestamp + TIME '08:20',
    U&'\4E0A\5348',
    (SELECT uuid FROM department WHERE dept_code = 'SJWK'),
    '90000000-0000-0000-0000-000000000101',
    (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000401'),
    (SELECT id FROM scheduling_time_slot WHERE uuid = '90000000-0000-0000-0000-000000000503'),
    '22222222-2222-2222-2222-222222222222',
    'alipay',
    60.00,
    FALSE,
    1,
    '反复头痛伴视物模糊，希望进一步做磁共振评估。'
  ),
  (
    '90000000-0000-0000-0000-000000000604',
    (SELECT id FROM patient WHERE card_number = '310101198503030044'),
    CURRENT_DATE::timestamp + TIME '08:00',
    U&'\4E0A\5348',
    (SELECT uuid FROM department WHERE dept_code = 'SJWK'),
    '90000000-0000-0000-0000-000000000102',
    (SELECT id FROM scheduling_actual WHERE uuid = '90000000-0000-0000-0000-000000000403'),
    (SELECT id FROM scheduling_time_slot WHERE uuid = '90000000-0000-0000-0000-000000000509'),
    '22222222-2222-2222-2222-222222222222',
    'wechat',
    60.00,
    FALSE,
    1,
    '突发眩晕伴步态不稳，需要门诊继续评估。'
  )
ON CONFLICT (uuid) DO UPDATE
SET patient_id = EXCLUDED.patient_id,
    visit_date = EXCLUDED.visit_date,
    noon = EXCLUDED.noon,
    dept_uuid = EXCLUDED.dept_uuid,
    employee_uuid = EXCLUDED.employee_uuid,
    scheduling_actual_id = EXCLUDED.scheduling_actual_id,
    scheduling_time_slot_id = EXCLUDED.scheduling_time_slot_id,
    settle_category_uuid = EXCLUDED.settle_category_uuid,
    regist_method = EXCLUDED.regist_method,
    regist_money = EXCLUDED.regist_money,
    is_emergency = EXCLUDED.is_emergency,
    visit_state = EXCLUDED.visit_state,
    symptoms = EXCLUDED.symptoms;

-- Sync counts and slot occupancy
UPDATE scheduling_actual sa
SET registered_count = counts.cnt
FROM (
  SELECT scheduling_actual_id, COUNT(*)::int AS cnt
  FROM register
  WHERE uuid IN (
    '90000000-0000-0000-0000-000000000601',
    '90000000-0000-0000-0000-000000000602',
    '90000000-0000-0000-0000-000000000603',
    '90000000-0000-0000-0000-000000000604'
  )
  GROUP BY scheduling_actual_id
) counts
WHERE sa.id = counts.scheduling_actual_id;

UPDATE scheduling_actual
SET registered_count = 0
WHERE uuid IN ('90000000-0000-0000-0000-000000000402', '90000000-0000-0000-0000-000000000404');

UPDATE scheduling_time_slot
SET is_booked = CASE
  WHEN uuid IN (
    '90000000-0000-0000-0000-000000000501',
    '90000000-0000-0000-0000-000000000502',
    '90000000-0000-0000-0000-000000000503',
    '90000000-0000-0000-0000-000000000509'
  ) THEN TRUE
  ELSE FALSE
END
WHERE uuid IN (
  '90000000-0000-0000-0000-000000000501',
  '90000000-0000-0000-0000-000000000502',
  '90000000-0000-0000-0000-000000000503',
  '90000000-0000-0000-0000-000000000504',
  '90000000-0000-0000-0000-000000000505',
  '90000000-0000-0000-0000-000000000506',
  '90000000-0000-0000-0000-000000000507',
  '90000000-0000-0000-0000-000000000508',
  '90000000-0000-0000-0000-000000000509',
  '90000000-0000-0000-0000-00000000050a',
  '90000000-0000-0000-0000-00000000050b',
  '90000000-0000-0000-0000-00000000050c',
  '90000000-0000-0000-0000-00000000050d',
  '90000000-0000-0000-0000-00000000050e',
  '90000000-0000-0000-0000-00000000050f',
  '90000000-0000-0000-0000-000000000510'
);

-- Demo AI medical drafts for doctor encounter page
INSERT INTO medical_record (
  uuid, register_uuid, readme, present, history, allergy, physique, proposal, diagnosis, is_doctor_confirmed, cure, dialog_vector
)
VALUES
  (
    '90000000-0000-0000-0000-000000000801',
    '90000000-0000-0000-0000-000000000601',
    '间断头痛伴恶心两周。',
    '晨起头痛较重，偶有恶心，无发热。',
    '外院影像提示颅内占位待排，无既往神经外科手术史。',
    '否认已知药物过敏史。',
    '神志清楚，对答切题，四肢肌力尚可，未见明显脑膜刺激征。',
    '建议调阅外院影像，并完善头颅增强MRI。',
    '颅内占位性病变待排。',
    FALSE,
    '医生确认后给予对症处理。',
    NULL
  ),
  (
    '90000000-0000-0000-0000-000000000802',
    '90000000-0000-0000-0000-000000000602',
    '头晕伴短暂右上肢麻木。',
    '阵发性头晕三天，期间有一次短暂右上肢麻木。',
    '既往有颈部不适史，否认外伤及意识丧失。',
    '否认已知药物过敏史。',
    '生命体征平稳，未见明显构音障碍，四肢肌力基本对称。',
    '建议完善神经系统查体，症状持续时考虑血管影像评估。',
    '后循环缺血待排。',
    FALSE,
    '确认后继续观察并完善影像检查。',
    NULL
  ),
  (
    '90000000-0000-0000-0000-000000000803',
    '90000000-0000-0000-0000-000000000603',
    '反复头痛伴视物模糊。',
    '头痛反复一个月，近期伴随视物模糊。',
    '否认癫痫发作史，家属述近期乏力、睡眠欠佳。',
    '否认已知药物过敏史。',
    '神志清楚，双瞳等大等圆，对光反射存在，床旁未见明确定位体征。',
    '建议完善头颅MRI并联合眼底检查。',
    '颅内压增高或结构性病变待排。',
    FALSE,
    '医生复核后先予止痛处理。',
    NULL
  ),
  (
    '90000000-0000-0000-0000-000000000804',
    '90000000-0000-0000-0000-000000000604',
    '突发眩晕伴步态不稳。',
    '今晨开始急性眩晕，行走不稳。',
    '既往因头晕门诊随访，近期否认感染史。',
    '否认已知药物过敏史。',
    '建议重点完成小脑体征与前庭系统床旁查体。',
    '建议补充卒中风险筛查及前庭评估。',
    '中枢性眩晕待排。',
    FALSE,
    '医生确认后继续完善检查。',
    NULL
  )
ON CONFLICT (register_uuid) DO UPDATE
SET readme = EXCLUDED.readme,
    present = EXCLUDED.present,
    history = EXCLUDED.history,
    allergy = EXCLUDED.allergy,
    physique = EXCLUDED.physique,
    proposal = EXCLUDED.proposal,
    diagnosis = EXCLUDED.diagnosis,
    is_doctor_confirmed = EXCLUDED.is_doctor_confirmed,
    cure = EXCLUDED.cure,
    dialog_vector = EXCLUDED.dialog_vector;

-- Demo rules for later admin/scheduling work
INSERT INTO scheduling_rule (uuid, employee_uuid, rule_name, week_rule, llm_text_rule, regist_quota, clinic_room_uuid, delmark)
VALUES
  ('90000000-0000-0000-0000-000000000901', '90000000-0000-0000-0000-000000000101', '陈松涛工作日上午门诊', '1,2,3,4,5', '工作日上午神经外科复诊门诊。', 4, '90000000-0000-0000-0000-000000000011', 1),
  ('90000000-0000-0000-0000-000000000902', '90000000-0000-0000-0000-000000000102', '顾宁工作日门诊', '1,2,3,4,5', '工作日门诊，重点处理头痛与眩晕随访。', 4, '90000000-0000-0000-0000-000000000012', 1)
ON CONFLICT (uuid) DO UPDATE
SET employee_uuid = EXCLUDED.employee_uuid,
    rule_name = EXCLUDED.rule_name,
    week_rule = EXCLUDED.week_rule,
    llm_text_rule = EXCLUDED.llm_text_rule,
    regist_quota = EXCLUDED.regist_quota,
    clinic_room_uuid = EXCLUDED.clinic_room_uuid,
    delmark = 1;

-- Demo ancillary data
INSERT INTO medical_technology (uuid, tech_code, tech_name, tech_type, price, delmark)
VALUES
  ('90000000-0000-0000-0000-000000000701', 'DEMO_CT_HEAD', '头颅CT', 'check', 180.00, 1),
  ('90000000-0000-0000-0000-000000000702', 'DEMO_MRI_HEAD', '头颅MRI', 'check', 680.00, 1)
ON CONFLICT (tech_code) DO UPDATE
SET tech_name = EXCLUDED.tech_name,
    tech_type = EXCLUDED.tech_type,
    price = EXCLUDED.price,
    delmark = 1;

INSERT INTO drug_info (uuid, drug_code, drug_name, specification, unit, price, stock, min_stock_limit, delmark)
VALUES
  ('90000000-0000-0000-0000-000000000801', 'DEMO_MANNITOL', '甘露醇注射液', '250ml:50g', '瓶', 32.00, 200, 20, 1),
  ('90000000-0000-0000-0000-000000000802', 'DEMO_LEVETIRACETAM', '左乙拉西坦片', '0.5g*30', '盒', 86.00, 120, 12, 1)
ON CONFLICT (drug_code) DO UPDATE
SET drug_name = EXCLUDED.drug_name,
    specification = EXCLUDED.specification,
    unit = EXCLUDED.unit,
    price = EXCLUDED.price,
    stock = EXCLUDED.stock,
    min_stock_limit = EXCLUDED.min_stock_limit,
    delmark = 1;

COMMIT;
