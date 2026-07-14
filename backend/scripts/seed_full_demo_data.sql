BEGIN;

DO $$
BEGIN
    IF to_regclass('public.ai_conversation_session') IS NULL
        OR to_regclass('public.ai_conversation_message') IS NULL THEN
        RAISE EXCEPTION
            'Missing ai_conversation tables. Run backend/migrations/20260708_01_create_ai_conversation_tables.sql first.';
    END IF;
END $$;

CREATE OR REPLACE FUNCTION pg_temp.sbc_demo_uuid(seed text)
RETURNS uuid
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT (
        substr(md5('smartbrainclinic-full-demo:' || seed), 1, 8) || '-' ||
        substr(md5('smartbrainclinic-full-demo:' || seed), 9, 4) || '-' ||
        substr(md5('smartbrainclinic-full-demo:' || seed), 13, 4) || '-' ||
        substr(md5('smartbrainclinic-full-demo:' || seed), 17, 4) || '-' ||
        substr(md5('smartbrainclinic-full-demo:' || seed), 21, 12)
    )::uuid;
$$;

SELECT setval(pg_get_serial_sequence('department', 'id'), COALESCE((SELECT MAX(id) FROM department), 1), TRUE);
SELECT setval(pg_get_serial_sequence('clinic_room', 'id'), COALESCE((SELECT MAX(id) FROM clinic_room), 1), TRUE);
SELECT setval(pg_get_serial_sequence('regist_level', 'id'), COALESCE((SELECT MAX(id) FROM regist_level), 1), TRUE);
SELECT setval(pg_get_serial_sequence('settle_category', 'id'), COALESCE((SELECT MAX(id) FROM settle_category), 1), TRUE);
SELECT setval(pg_get_serial_sequence('employee', 'id'), COALESCE((SELECT MAX(id) FROM employee), 1), TRUE);
SELECT setval(pg_get_serial_sequence('patient', 'id'), COALESCE((SELECT MAX(id) FROM patient), 1), TRUE);
SELECT setval(pg_get_serial_sequence('scheduling_rule', 'id'), COALESCE((SELECT MAX(id) FROM scheduling_rule), 1), TRUE);
SELECT setval(pg_get_serial_sequence('scheduling_actual', 'id'), COALESCE((SELECT MAX(id) FROM scheduling_actual), 1), TRUE);
SELECT setval(pg_get_serial_sequence('scheduling_time_slot', 'id'), COALESCE((SELECT MAX(id) FROM scheduling_time_slot), 1), TRUE);
SELECT setval(pg_get_serial_sequence('register', 'id'), COALESCE((SELECT MAX(id) FROM register), 1), TRUE);
SELECT setval(pg_get_serial_sequence('disease', 'id'), COALESCE((SELECT MAX(id) FROM disease), 1), TRUE);
SELECT setval(pg_get_serial_sequence('medical_technology', 'id'), COALESCE((SELECT MAX(id) FROM medical_technology), 1), TRUE);
SELECT setval(pg_get_serial_sequence('medical_record', 'id'), COALESCE((SELECT MAX(id) FROM medical_record), 1), TRUE);
SELECT setval(pg_get_serial_sequence('check_request', 'id'), COALESCE((SELECT MAX(id) FROM check_request), 1), TRUE);
SELECT setval(pg_get_serial_sequence('inspection_request', 'id'), COALESCE((SELECT MAX(id) FROM inspection_request), 1), TRUE);
SELECT setval(pg_get_serial_sequence('disposal_request', 'id'), COALESCE((SELECT MAX(id) FROM disposal_request), 1), TRUE);
SELECT setval(pg_get_serial_sequence('drug_info', 'id'), COALESCE((SELECT MAX(id) FROM drug_info), 1), TRUE);
SELECT setval(pg_get_serial_sequence('prescription', 'id'), COALESCE((SELECT MAX(id) FROM prescription), 1), TRUE);
SELECT setval(pg_get_serial_sequence('prescription_item', 'id'), COALESCE((SELECT MAX(id) FROM prescription_item), 1), TRUE);
SELECT setval(pg_get_serial_sequence('outpatient_bill', 'id'), COALESCE((SELECT MAX(id) FROM outpatient_bill), 1), TRUE);
SELECT setval(pg_get_serial_sequence('outpatient_bill_detail', 'id'), COALESCE((SELECT MAX(id) FROM outpatient_bill_detail), 1), TRUE);
SELECT setval(pg_get_serial_sequence('ai_conversation_session', 'id'), COALESCE((SELECT MAX(id) FROM ai_conversation_session), 1), TRUE);
SELECT setval(pg_get_serial_sequence('ai_conversation_message', 'id'), COALESCE((SELECT MAX(id) FROM ai_conversation_message), 1), TRUE);
SELECT setval(pg_get_serial_sequence('patient_feedback', 'id'), COALESCE((SELECT MAX(id) FROM patient_feedback), 1), TRUE);
SELECT setval(pg_get_serial_sequence('schedule_disruption', 'id'), COALESCE((SELECT MAX(id) FROM schedule_disruption), 1), TRUE);
SELECT setval(pg_get_serial_sequence('scheduling_application', 'id'), COALESCE((SELECT MAX(id) FROM scheduling_application), 1), TRUE);

CREATE TEMP TABLE tmp_demo_departments (
    dept_key text PRIMARY KEY,
    dept_uuid uuid NOT NULL,
    dept_code text NOT NULL,
    dept_name text NOT NULL,
    dept_type text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_departments VALUES
    ('sjwk', pg_temp.sbc_demo_uuid('department:sjwk'), 'SJWK', '神经外科', 'outpatient'),
    ('sjnk', pg_temp.sbc_demo_uuid('department:sjnk'), 'SJNK', '神经内科', 'outpatient'),
    ('image', pg_temp.sbc_demo_uuid('department:image'), 'JCYX', '医学影像', 'check'),
    ('lab', pg_temp.sbc_demo_uuid('department:lab'), 'JYYX', '检验中心', 'inspection'),
    ('treatment', pg_temp.sbc_demo_uuid('department:treatment'), 'ZLZX', '治疗处置', 'disposal'),
    ('pharmacy', pg_temp.sbc_demo_uuid('department:pharmacy'), 'YF', '门诊药房', 'pharmacy'),
    ('admin', pg_temp.sbc_demo_uuid('department:admin'), 'ADMIN', '院务管理', 'management');

CREATE TEMP TABLE tmp_demo_rooms (
    room_key text PRIMARY KEY,
    room_uuid uuid NOT NULL,
    dept_key text NOT NULL,
    room_name text NOT NULL,
    location text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_rooms VALUES
    ('sjwk_01', pg_temp.sbc_demo_uuid('room:sjwk_01'), 'sjwk', '神外一诊室', 'A楼2层东侧'),
    ('sjwk_02', pg_temp.sbc_demo_uuid('room:sjwk_02'), 'sjwk', '神外二诊室', 'A楼2层西侧'),
    ('sjnk_01', pg_temp.sbc_demo_uuid('room:sjnk_01'), 'sjnk', '神内一诊室', 'B楼3层东侧'),
    ('sjnk_02', pg_temp.sbc_demo_uuid('room:sjnk_02'), 'sjnk', '神内二诊室', 'B楼3层西侧'),
    ('image_01', pg_temp.sbc_demo_uuid('room:image_01'), 'image', '影像检查一室', 'C楼1层影像区'),
    ('lab_01', pg_temp.sbc_demo_uuid('room:lab_01'), 'lab', '检验采样一室', 'C楼1层检验区'),
    ('treat_01', pg_temp.sbc_demo_uuid('room:treat_01'), 'treatment', '治疗处置一室', 'C楼2层治疗区');

CREATE TEMP TABLE tmp_demo_regist_levels (
    level_key text PRIMARY KEY,
    level_uuid uuid NOT NULL,
    regist_code text NOT NULL,
    regist_name text NOT NULL,
    regist_fee numeric(8, 2) NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_regist_levels VALUES
    ('normal', pg_temp.sbc_demo_uuid('regist:normal'), 'DEMO_NORMAL', '普通门诊', 20.00),
    ('expert', pg_temp.sbc_demo_uuid('regist:expert'), 'DEMO_EXPERT', '专家门诊', 60.00),
    ('senior', pg_temp.sbc_demo_uuid('regist:senior'), 'DEMO_SENIOR', '高级专家门诊', 80.00);

CREATE TEMP TABLE tmp_demo_settles (
    settle_key text PRIMARY KEY,
    settle_uuid uuid NOT NULL,
    settle_code text NOT NULL,
    settle_name text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_settles VALUES
    ('zf', pg_temp.sbc_demo_uuid('settle:zf'), 'ZF', '自费'),
    ('yb', pg_temp.sbc_demo_uuid('settle:yb'), 'YB', '医保');

CREATE TEMP TABLE tmp_demo_employees (
    employee_key text PRIMARY KEY,
    employee_uuid uuid NOT NULL,
    dept_key text NOT NULL,
    level_key text,
    realname text NOT NULL,
    password text NOT NULL,
    expertise text NOT NULL,
    gender text NOT NULL,
    ai_eval_score numeric(3, 1) NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_employees VALUES
    ('chen', pg_temp.sbc_demo_uuid('employee:chen'), 'sjwk', 'expert', '陈松涛', '123', '脑肿瘤、颅脑手术、术后复诊', 'male', 4.9),
    ('gu', pg_temp.sbc_demo_uuid('employee:gu'), 'sjwk', 'expert', '顾宁', '123', '头痛、眩晕、脑血管随访', 'female', 4.8),
    ('lin', pg_temp.sbc_demo_uuid('employee:lin'), 'sjnk', 'normal', '林致远', '123', '偏头痛、短暂性脑缺血、肢体麻木', 'male', 4.6),
    ('xu', pg_temp.sbc_demo_uuid('employee:xu'), 'sjnk', 'senior', '许知夏', '123', '眩晕、步态不稳、神经系统查体评估', 'female', 4.7),
    ('zhou', pg_temp.sbc_demo_uuid('employee:zhou'), 'sjwk', 'expert', '周砚', '123', '脑积水、占位性病变复查、手术后随访', 'male', 4.5),
    ('su', pg_temp.sbc_demo_uuid('employee:su'), 'sjnk', 'normal', '苏禾', '123', '慢性头痛、周围神经病、睡眠相关神经症状', 'female', 4.4),
    ('admin_manager', pg_temp.sbc_demo_uuid('employee:admin_manager'), 'admin', NULL, '周院管', '123', '排班审核、运营协同、异常工单流转', 'female', 4.5),
    ('image_staff', pg_temp.sbc_demo_uuid('employee:image_staff'), 'image', NULL, '马会影', '123', '头颅 CT、MRI 结果录入与影像回传', 'male', 4.3),
    ('lab_staff', pg_temp.sbc_demo_uuid('employee:lab_staff'), 'lab', NULL, '赵检验', '123', '血常规、电解质、凝血项目录入', 'female', 4.2),
    ('treat_staff', pg_temp.sbc_demo_uuid('employee:treat_staff'), 'treatment', NULL, '孙治疗', '123', '康复训练、静脉补液、处置记录', 'male', 4.2);

CREATE TEMP TABLE tmp_demo_patients (
    patient_key text PRIMARY KEY,
    patient_uuid uuid NOT NULL,
    case_number text NOT NULL,
    real_name text NOT NULL,
    gender text NOT NULL,
    card_number text NOT NULL,
    birthdate date NOT NULL,
    home_address text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_patients VALUES
    ('p01', pg_temp.sbc_demo_uuid('patient:p01'), 'SBC-FULL-P001', '张晨曦', 'female', '310101199001010011', DATE '1990-01-01', '浦东新区演示路18号'),
    ('p02', pg_temp.sbc_demo_uuid('patient:p02'), 'SBC-FULL-P002', '李沐川', 'male', '310101198812120022', DATE '1988-12-12', '杨浦区复诊巷18号'),
    ('p03', pg_temp.sbc_demo_uuid('patient:p03'), 'SBC-FULL-P003', '王若岚', 'female', '310101199511050033', DATE '1995-11-05', '徐汇区康复路66号'),
    ('p04', pg_temp.sbc_demo_uuid('patient:p04'), 'SBC-FULL-P004', '赵志远', 'male', '310101198503030044', DATE '1985-03-03', '静安区门诊街28号'),
    ('p05', pg_temp.sbc_demo_uuid('patient:p05'), 'SBC-FULL-P005', '何雨桐', 'female', '310101199307150055', DATE '1993-07-15', '虹口区平衡路9号'),
    ('p06', pg_temp.sbc_demo_uuid('patient:p06'), 'SBC-FULL-P006', '孙立新', 'male', '310101197911280066', DATE '1979-11-28', '普陀区复查路51号'),
    ('p07', pg_temp.sbc_demo_uuid('patient:p07'), 'SBC-FULL-P007', '周一诺', 'female', '310101196906090077', DATE '1969-06-09', '长宁区康宁里12号'),
    ('p08', pg_temp.sbc_demo_uuid('patient:p08'), 'SBC-FULL-P008', '吴泽航', 'male', '310101198102140088', DATE '1981-02-14', '闵行区影像路80号'),
    ('p09', pg_temp.sbc_demo_uuid('patient:p09'), 'SBC-FULL-P009', '郑可欣', 'female', '310101199702220099', DATE '1997-02-22', '嘉定区安稳街16号'),
    ('p10', pg_temp.sbc_demo_uuid('patient:p10'), 'SBC-FULL-P010', '冯子墨', 'male', '310101198905170110', DATE '1989-05-17', '宝山区镇痛路37号'),
    ('p11', pg_temp.sbc_demo_uuid('patient:p11'), 'SBC-FULL-P011', '钱雨薇', 'female', '310101199403010121', DATE '1994-03-01', '浦东新区睡眠街22号'),
    ('p12', pg_temp.sbc_demo_uuid('patient:p12'), 'SBC-FULL-P012', '沈星河', 'male', '310101197612300132', DATE '1976-12-30', '黄浦区健康路77号'),
    ('p13', pg_temp.sbc_demo_uuid('patient:p13'), 'SBC-FULL-P013', '梁书瑶', 'female', '310101198610100143', DATE '1986-10-10', '徐汇区眩晕路31号'),
    ('p14', pg_temp.sbc_demo_uuid('patient:p14'), 'SBC-FULL-P014', '高远山', 'male', '310101197803080154', DATE '1978-03-08', '奉贤区神经路63号'),
    ('p15', pg_temp.sbc_demo_uuid('patient:p15'), 'SBC-FULL-P015', '程雅静', 'female', '310101199209190165', DATE '1992-09-19', '松江区随访路20号'),
    ('p16', pg_temp.sbc_demo_uuid('patient:p16'), 'SBC-FULL-P016', '韩致诚', 'male', '310101196512010176', DATE '1965-12-01', '青浦区颅脑路41号'),
    ('p17', pg_temp.sbc_demo_uuid('patient:p17'), 'SBC-FULL-P017', '郭晓棠', 'female', '310101198707070187', DATE '1987-07-07', '嘉定区复健路25号'),
    ('p18', pg_temp.sbc_demo_uuid('patient:p18'), 'SBC-FULL-P018', '邓明轩', 'male', '310101199811180198', DATE '1998-11-18', '金山区门诊路11号'),
    ('p19', pg_temp.sbc_demo_uuid('patient:p19'), 'SBC-FULL-P019', '彭若溪', 'female', '310101197405040209', DATE '1974-05-04', '浦东新区会诊路52号'),
    ('p20', pg_temp.sbc_demo_uuid('patient:p20'), 'SBC-FULL-P020', '曹以安', 'male', '310101199602260210', DATE '1996-02-26', '杨浦区预约路61号'),
    ('p21', pg_temp.sbc_demo_uuid('patient:p21'), 'SBC-FULL-P021', '谢轻舟', 'female', '310101198204150221', DATE '1982-04-15', '虹口区调班路13号'),
    ('p22', pg_temp.sbc_demo_uuid('patient:p22'), 'SBC-FULL-P022', '罗景然', 'male', '310101197108120232', DATE '1971-08-12', '普陀区留观路99号'),
    ('p23', pg_temp.sbc_demo_uuid('patient:p23'), 'SBC-FULL-P023', '戴欣妍', 'female', '310101199912090243', DATE '1999-12-09', '闵行区恢复路76号'),
    ('p24', pg_temp.sbc_demo_uuid('patient:p24'), 'SBC-FULL-P024', '许澄宇', 'male', '310101198001250254', DATE '1980-01-25', '宝山区平诊路15号');

CREATE TEMP TABLE tmp_demo_diseases (
    disease_key text PRIMARY KEY,
    disease_code text NOT NULL,
    disease_name text NOT NULL,
    disease_type text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_diseases VALUES
    ('brain_mass', 'NEU_BRAIN_MASS', '颅内占位性病变待排', 'neurosurgery'),
    ('migraine', 'NEU_MIGRAINE', '偏头痛', 'neurology'),
    ('tia', 'NEU_TIA', '短暂性脑缺血发作待排', 'neurology'),
    ('vertigo', 'NEU_VERTIGO', '眩晕综合征', 'neurology'),
    ('cervical', 'NEU_CERVICAL', '颈源性头晕头痛', 'neurology'),
    ('neuropathy', 'NEU_NEUROPATHY', '周围神经病变', 'neurology'),
    ('cerebellar', 'NEU_CEREBELLAR', '小脑性眩晕待排', 'neurology'),
    ('post_op', 'NEU_POST_OP', '术后神经系统随访', 'neurosurgery');

CREATE TEMP TABLE tmp_demo_techs (
    tech_key text PRIMARY KEY,
    tech_uuid uuid NOT NULL,
    tech_code text NOT NULL,
    tech_name text NOT NULL,
    tech_type text NOT NULL,
    price numeric(8, 2) NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_techs VALUES
    ('ct_head', pg_temp.sbc_demo_uuid('tech:ct_head'), 'DEMO_CT_HEAD', '头颅CT', 'check', 180.00),
    ('mri_head', pg_temp.sbc_demo_uuid('tech:mri_head'), 'DEMO_MRI_HEAD', '头颅MRI', 'check', 680.00),
    ('cta_head', pg_temp.sbc_demo_uuid('tech:cta_head'), 'DEMO_CTA_HEAD', '头颈CTA', 'check', 520.00),
    ('eeg', pg_temp.sbc_demo_uuid('tech:eeg'), 'DEMO_EEG', '脑电图', 'check', 160.00),
    ('blood_routine', pg_temp.sbc_demo_uuid('tech:blood_routine'), 'DEMO_BLOOD_ROUTINE', '血常规', 'inspection', 38.00),
    ('electrolyte', pg_temp.sbc_demo_uuid('tech:electrolyte'), 'DEMO_ELECTROLYTE', '电解质', 'inspection', 52.00),
    ('coagulation', pg_temp.sbc_demo_uuid('tech:coagulation'), 'DEMO_COAGULATION', '凝血功能', 'inspection', 86.00),
    ('rehab', pg_temp.sbc_demo_uuid('tech:rehab'), 'DEMO_REHAB', '康复训练', 'disposal', 120.00),
    ('infusion', pg_temp.sbc_demo_uuid('tech:infusion'), 'DEMO_INFUSION', '静脉补液', 'disposal', 96.00);

CREATE TEMP TABLE tmp_demo_drugs (
    drug_key text PRIMARY KEY,
    drug_uuid uuid NOT NULL,
    drug_code text NOT NULL,
    drug_name text NOT NULL,
    specification text NOT NULL,
    unit text NOT NULL,
    price numeric(8, 2) NOT NULL,
    stock integer NOT NULL,
    min_stock_limit integer NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_drugs VALUES
    ('mannitol', pg_temp.sbc_demo_uuid('drug:mannitol'), 'DEMO_MANNITOL', '甘露醇注射液', '250ml:50g', '瓶', 32.00, 200, 20),
    ('levetiracetam', pg_temp.sbc_demo_uuid('drug:levetiracetam'), 'DEMO_LEVETIRACETAM', '左乙拉西坦片', '0.5g*30', '盒', 86.00, 120, 12),
    ('betahistine', pg_temp.sbc_demo_uuid('drug:betahistine'), 'DEMO_BETAHISTINE', '倍他司汀片', '6mg*30', '盒', 28.00, 180, 18),
    ('aspirin', pg_temp.sbc_demo_uuid('drug:aspirin'), 'DEMO_ASPIRIN', '阿司匹林肠溶片', '100mg*30', '盒', 18.00, 260, 26),
    ('mecobalamin', pg_temp.sbc_demo_uuid('drug:mecobalamin'), 'DEMO_MECOBALAMIN', '甲钴胺片', '0.5mg*20', '盒', 24.00, 210, 21),
    ('pregabalin', pg_temp.sbc_demo_uuid('drug:pregabalin'), 'DEMO_PREGABALIN', '普瑞巴林胶囊', '75mg*14', '盒', 58.00, 140, 14);

CREATE TEMP TABLE tmp_demo_schedule_rules (
    rule_key text PRIMARY KEY,
    rule_uuid uuid NOT NULL,
    doctor_key text NOT NULL,
    rule_name text NOT NULL,
    week_rule text NOT NULL,
    llm_text_rule text NOT NULL,
    regist_quota integer NOT NULL,
    room_key text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_schedule_rules VALUES
    ('rule_chen', pg_temp.sbc_demo_uuid('rule:chen'), 'chen', '陈松涛工作日门诊', '1,2,3,4,5', '工作日上午神经外科门诊，优先处理占位性病变复查与术后随访。', 4, 'sjwk_01'),
    ('rule_gu', pg_temp.sbc_demo_uuid('rule:gu'), 'gu', '顾宁工作日门诊', '1,2,3,4,5', '工作日上午神经外科门诊，重点处理头痛眩晕与脑血管随访。', 4, 'sjwk_02'),
    ('rule_lin', pg_temp.sbc_demo_uuid('rule:lin'), 'lin', '林致远工作日门诊', '1,2,3,4,5', '工作日上午神经内科门诊，偏头痛与短暂性脑缺血随访优先。', 4, 'sjnk_01'),
    ('rule_xu', pg_temp.sbc_demo_uuid('rule:xu'), 'xu', '许知夏工作日门诊', '1,2,3,4,5', '工作日下午神经内科门诊，眩晕和平衡障碍评估优先。', 4, 'sjnk_02'),
    ('rule_zhou', pg_temp.sbc_demo_uuid('rule:zhou'), 'zhou', '周砚工作日门诊', '1,2,3,4,5', '工作日上午神经外科复查门诊。', 4, 'sjwk_01'),
    ('rule_su', pg_temp.sbc_demo_uuid('rule:su'), 'su', '苏禾工作日门诊', '1,2,3,4,5', '工作日上午神经内科随访门诊。', 4, 'sjnk_01');

CREATE TEMP TABLE tmp_demo_schedules (
    schedule_key text PRIMARY KEY,
    schedule_uuid uuid NOT NULL,
    doctor_key text NOT NULL,
    day_offset integer NOT NULL,
    noon text NOT NULL,
    regist_quota integer NOT NULL,
    room_key text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_demo_schedules VALUES
    ('chen_yday_am', pg_temp.sbc_demo_uuid('schedule:chen_yday_am'), 'chen', -1, '上午', 4, 'sjwk_01'),
    ('chen_today_am', pg_temp.sbc_demo_uuid('schedule:chen_today_am'), 'chen', 0, '上午', 4, 'sjwk_01'),
    ('chen_tomorrow_am', pg_temp.sbc_demo_uuid('schedule:chen_tomorrow_am'), 'chen', 1, '上午', 4, 'sjwk_01'),
    ('chen_day2_pm', pg_temp.sbc_demo_uuid('schedule:chen_day2_pm'), 'chen', 2, '下午', 4, 'sjwk_01'),
    ('gu_yday_am', pg_temp.sbc_demo_uuid('schedule:gu_yday_am'), 'gu', -1, '上午', 4, 'sjwk_02'),
    ('gu_today_am', pg_temp.sbc_demo_uuid('schedule:gu_today_am'), 'gu', 0, '上午', 4, 'sjwk_02'),
    ('gu_tomorrow_am', pg_temp.sbc_demo_uuid('schedule:gu_tomorrow_am'), 'gu', 1, '上午', 4, 'sjwk_02'),
    ('lin_yday_am', pg_temp.sbc_demo_uuid('schedule:lin_yday_am'), 'lin', -1, '上午', 4, 'sjnk_01'),
    ('lin_today_am', pg_temp.sbc_demo_uuid('schedule:lin_today_am'), 'lin', 0, '上午', 4, 'sjnk_01'),
    ('lin_tomorrow_pm', pg_temp.sbc_demo_uuid('schedule:lin_tomorrow_pm'), 'lin', 1, '下午', 4, 'sjnk_01'),
    ('xu_yday_pm', pg_temp.sbc_demo_uuid('schedule:xu_yday_pm'), 'xu', -1, '下午', 4, 'sjnk_02'),
    ('xu_today_pm', pg_temp.sbc_demo_uuid('schedule:xu_today_pm'), 'xu', 0, '下午', 4, 'sjnk_02'),
    ('xu_tomorrow_pm', pg_temp.sbc_demo_uuid('schedule:xu_tomorrow_pm'), 'xu', 1, '下午', 4, 'sjnk_02'),
    ('zhou_today_am', pg_temp.sbc_demo_uuid('schedule:zhou_today_am'), 'zhou', 0, '上午', 4, 'sjwk_01'),
    ('zhou_tomorrow_am', pg_temp.sbc_demo_uuid('schedule:zhou_tomorrow_am'), 'zhou', 1, '上午', 4, 'sjwk_01'),
    ('su_today_pm', pg_temp.sbc_demo_uuid('schedule:su_today_pm'), 'su', 0, '下午', 4, 'sjnk_01'),
    ('su_tomorrow_am', pg_temp.sbc_demo_uuid('schedule:su_tomorrow_am'), 'su', 1, '上午', 4, 'sjnk_01');

INSERT INTO department (uuid, dept_code, dept_name, dept_type, delmark)
SELECT dept_uuid, dept_code, dept_name, dept_type, 1 FROM tmp_demo_departments
ON CONFLICT (dept_code) DO UPDATE SET uuid = EXCLUDED.uuid, dept_name = EXCLUDED.dept_name, dept_type = EXCLUDED.dept_type, delmark = 1;
INSERT INTO clinic_room (uuid, dept_uuid, room_name, location, delmark)
SELECT r.room_uuid, d.uuid, r.room_name, r.location, 1 FROM tmp_demo_rooms r JOIN tmp_demo_departments td ON td.dept_key = r.dept_key JOIN department d ON d.dept_code = td.dept_code
ON CONFLICT (uuid) DO UPDATE SET dept_uuid = EXCLUDED.dept_uuid, room_name = EXCLUDED.room_name, location = EXCLUDED.location, delmark = 1;
INSERT INTO regist_level (uuid, regist_code, regist_name, regist_fee, delmark)
SELECT level_uuid, regist_code, regist_name, regist_fee, 1 FROM tmp_demo_regist_levels
ON CONFLICT (regist_code) DO UPDATE SET uuid = EXCLUDED.uuid, regist_name = EXCLUDED.regist_name, regist_fee = EXCLUDED.regist_fee, delmark = 1;
INSERT INTO settle_category (uuid, settle_code, settle_name, delmark)
SELECT settle_uuid, settle_code, settle_name, 1 FROM tmp_demo_settles
ON CONFLICT (settle_code) DO UPDATE SET uuid = EXCLUDED.uuid, settle_name = EXCLUDED.settle_name, delmark = 1;
INSERT INTO employee (uuid, dept_id, regist_level_id, realname, password, expertise, gender, ai_eval_score, delmark)
SELECT e.employee_uuid, d.id, rl.id, e.realname, e.password, e.expertise, e.gender, e.ai_eval_score, 1 FROM tmp_demo_employees e JOIN tmp_demo_departments td ON td.dept_key=e.dept_key JOIN department d ON d.dept_code=td.dept_code LEFT JOIN tmp_demo_regist_levels tl ON tl.level_key=e.level_key LEFT JOIN regist_level rl ON rl.regist_code=tl.regist_code
ON CONFLICT (uuid) DO UPDATE SET dept_id=EXCLUDED.dept_id, regist_level_id=EXCLUDED.regist_level_id, realname=EXCLUDED.realname, password=EXCLUDED.password, expertise=EXCLUDED.expertise, gender=EXCLUDED.gender, ai_eval_score=EXCLUDED.ai_eval_score, delmark=1;
INSERT INTO patient (uuid, case_number, real_name, gender, card_number, birthdate, home_address, created_at)
SELECT patient_uuid, case_number, real_name, gender, card_number, birthdate, home_address, NOW() FROM tmp_demo_patients
ON CONFLICT (card_number) DO UPDATE SET uuid=EXCLUDED.uuid, case_number=EXCLUDED.case_number, real_name=EXCLUDED.real_name, gender=EXCLUDED.gender, birthdate=EXCLUDED.birthdate, home_address=EXCLUDED.home_address;
INSERT INTO disease (disease_code, disease_name, disease_type, delmark, disease_vector)
SELECT disease_code, disease_name, disease_type, 1, NULL FROM tmp_demo_diseases
ON CONFLICT (disease_code) DO UPDATE SET disease_name=EXCLUDED.disease_name, disease_type=EXCLUDED.disease_type, delmark=1;
INSERT INTO medical_technology (uuid, tech_code, tech_name, tech_type, price, delmark)
SELECT tech_uuid, tech_code, tech_name, tech_type, price, 1 FROM tmp_demo_techs
ON CONFLICT (tech_code) DO UPDATE SET uuid=EXCLUDED.uuid, tech_name=EXCLUDED.tech_name, tech_type=EXCLUDED.tech_type, price=EXCLUDED.price, delmark=1;
INSERT INTO drug_info (uuid, drug_code, drug_name, specification, unit, price, stock, min_stock_limit, delmark)
SELECT drug_uuid, drug_code, drug_name, specification, unit, price, stock, min_stock_limit, 1 FROM tmp_demo_drugs
ON CONFLICT (drug_code) DO UPDATE SET uuid=EXCLUDED.uuid, drug_name=EXCLUDED.drug_name, specification=EXCLUDED.specification, unit=EXCLUDED.unit, price=EXCLUDED.price, stock=EXCLUDED.stock, min_stock_limit=EXCLUDED.min_stock_limit, delmark=1;
INSERT INTO scheduling_rule (uuid, employee_uuid, rule_name, week_rule, llm_text_rule, regist_quota, slot_duration_minutes, clinic_room_uuid, delmark)
SELECT r.rule_uuid, e.employee_uuid, r.rule_name, r.week_rule, r.llm_text_rule, r.regist_quota, 10, room.room_uuid, 1 FROM tmp_demo_schedule_rules r JOIN tmp_demo_employees e ON e.employee_key=r.doctor_key JOIN tmp_demo_rooms room ON room.room_key=r.room_key
ON CONFLICT (uuid) DO UPDATE SET employee_uuid=EXCLUDED.employee_uuid, rule_name=EXCLUDED.rule_name, week_rule=EXCLUDED.week_rule, llm_text_rule=EXCLUDED.llm_text_rule, regist_quota=EXCLUDED.regist_quota, slot_duration_minutes=EXCLUDED.slot_duration_minutes, clinic_room_uuid=EXCLUDED.clinic_room_uuid, delmark=1;
INSERT INTO scheduling_actual (uuid, employee_uuid, schedule_date, noon, regist_quota, registered_count, slot_duration_minutes, clinic_room_uuid)
SELECT s.schedule_uuid, e.employee_uuid, CURRENT_DATE+s.day_offset, s.noon, s.regist_quota, 0, 10, room.room_uuid FROM tmp_demo_schedules s JOIN tmp_demo_employees e ON e.employee_key=s.doctor_key JOIN tmp_demo_rooms room ON room.room_key=s.room_key
ON CONFLICT (uuid) DO UPDATE SET employee_uuid=EXCLUDED.employee_uuid, schedule_date=EXCLUDED.schedule_date, noon=EXCLUDED.noon, regist_quota=EXCLUDED.regist_quota, slot_duration_minutes=EXCLUDED.slot_duration_minutes, clinic_room_uuid=EXCLUDED.clinic_room_uuid;
INSERT INTO scheduling_time_slot (uuid, scheduling_actual_id, time_range, is_booked)
SELECT pg_temp.sbc_demo_uuid('slot:'||s.schedule_key||':'||n), sa.id, CASE WHEN s.noon='上午' THEN to_char(time '08:00' + ((n-1) * sa.slot_duration_minutes) * interval '1 minute', 'HH24:MI')||'-'||to_char(time '08:00' + (n * sa.slot_duration_minutes) * interval '1 minute', 'HH24:MI') ELSE to_char(time '13:00' + ((n-1) * sa.slot_duration_minutes) * interval '1 minute', 'HH24:MI')||'-'||to_char(time '13:00' + (n * sa.slot_duration_minutes) * interval '1 minute', 'HH24:MI') END, FALSE FROM tmp_demo_schedules s JOIN scheduling_actual sa ON sa.uuid=s.schedule_uuid CROSS JOIN generate_series(1, sa.regist_quota) n
ON CONFLICT (uuid) DO UPDATE SET scheduling_actual_id=EXCLUDED.scheduling_actual_id, time_range=EXCLUDED.time_range;
CREATE TEMP TABLE tmp_demo_registers (register_key text PRIMARY KEY, register_uuid uuid NOT NULL, patient_key text NOT NULL, schedule_key text NOT NULL, slot_no integer NOT NULL, settle_key text NOT NULL, visit_state integer NOT NULL, symptoms text NOT NULL) ON COMMIT DROP;
INSERT INTO tmp_demo_registers VALUES
('r001',pg_temp.sbc_demo_uuid('register:r001'),'p01','chen_yday_am',1,'zf',3,'持续头痛伴恶心'),('r002',pg_temp.sbc_demo_uuid('register:r002'),'p02','chen_yday_am',2,'zf',3,'术后头部闷胀复查'),('r003',pg_temp.sbc_demo_uuid('register:r003'),'p03','gu_yday_am',1,'yb',3,'眩晕伴恶心'),('r004',pg_temp.sbc_demo_uuid('register:r004'),'p04','gu_yday_am',2,'zf',3,'反复偏头痛'),('r005',pg_temp.sbc_demo_uuid('register:r005'),'p05','lin_yday_am',1,'yb',3,'右臂麻木'),('r006',pg_temp.sbc_demo_uuid('register:r006'),'p06','lin_yday_am',2,'zf',3,'足部麻木半年'),('r007',pg_temp.sbc_demo_uuid('register:r007'),'p07','xu_yday_pm',1,'yb',3,'急性眩晕步态不稳'),('r008',pg_temp.sbc_demo_uuid('register:r008'),'p08','xu_yday_pm',2,'zf',3,'术后轻度头晕复查'),('r009',pg_temp.sbc_demo_uuid('register:r009'),'p09','chen_yday_am',3,'zf',4,'历史取消挂号'),('r010',pg_temp.sbc_demo_uuid('register:r010'),'p01','chen_today_am',1,'zf',2,'今日头痛加重'),('r011',pg_temp.sbc_demo_uuid('register:r011'),'p10','chen_today_am',2,'yb',1,'头晕视物模糊'),('r012',pg_temp.sbc_demo_uuid('register:r012'),'p11','chen_today_am',3,'zf',1,'晨起头部压迫感'),('r013',pg_temp.sbc_demo_uuid('register:r013'),'p03','gu_today_am',1,'yb',2,'眩晕复发'),('r014',pg_temp.sbc_demo_uuid('register:r014'),'p12','gu_today_am',2,'zf',1,'搏动性头痛'),('r015',pg_temp.sbc_demo_uuid('register:r015'),'p13','gu_today_am',3,'zf',1,'颈部僵硬头晕'),('r016',pg_temp.sbc_demo_uuid('register:r016'),'p14','lin_today_am',1,'yb',1,'右手短暂麻木'),('r017',pg_temp.sbc_demo_uuid('register:r017'),'p15','lin_today_am',2,'zf',1,'偏头痛复诊'),('r018',pg_temp.sbc_demo_uuid('register:r018'),'p16','xu_today_pm',1,'yb',1,'步态不稳伴眩晕');
INSERT INTO register (uuid, patient_id, visit_date, noon, dept_uuid, employee_uuid, scheduling_actual_id, settle_category_uuid, regist_method, regist_money, is_emergency, visit_state, symptoms, scheduling_time_slot_id)
SELECT r.register_uuid,p.id,sa.schedule_date,sa.noon,d.uuid,e.employee_uuid,sa.id,sc.uuid,'online',rl.regist_fee,FALSE,r.visit_state,r.symptoms,sts.id FROM tmp_demo_registers r JOIN tmp_demo_patients tp ON tp.patient_key=r.patient_key JOIN patient p ON p.uuid=tp.patient_uuid JOIN tmp_demo_schedules s ON s.schedule_key=r.schedule_key JOIN scheduling_actual sa ON sa.uuid=s.schedule_uuid JOIN tmp_demo_employees e ON e.employee_key=s.doctor_key JOIN tmp_demo_departments td ON td.dept_key=e.dept_key JOIN department d ON d.dept_code=td.dept_code JOIN tmp_demo_settles ts ON ts.settle_key=r.settle_key JOIN settle_category sc ON sc.settle_code=ts.settle_code JOIN tmp_demo_regist_levels tl ON tl.level_key=e.level_key JOIN regist_level rl ON rl.regist_code=tl.regist_code JOIN scheduling_time_slot sts ON sts.uuid=pg_temp.sbc_demo_uuid('slot:'||r.schedule_key||':'||r.slot_no)
ON CONFLICT (uuid) DO UPDATE SET patient_id=EXCLUDED.patient_id, visit_date=EXCLUDED.visit_date, noon=EXCLUDED.noon, dept_uuid=EXCLUDED.dept_uuid, employee_uuid=EXCLUDED.employee_uuid, scheduling_actual_id=EXCLUDED.scheduling_actual_id, settle_category_uuid=EXCLUDED.settle_category_uuid, visit_state=EXCLUDED.visit_state, symptoms=EXCLUDED.symptoms, scheduling_time_slot_id=EXCLUDED.scheduling_time_slot_id;
UPDATE scheduling_actual sa SET registered_count=(SELECT COUNT(*) FROM register r WHERE r.scheduling_actual_id=sa.id AND r.visit_state IN (1,2,3));
UPDATE scheduling_time_slot sts SET is_booked=EXISTS (SELECT 1 FROM register r WHERE r.scheduling_time_slot_id=sts.id AND r.visit_state IN (1,2,3));
CREATE TEMP TABLE tmp_demo_records (record_key text PRIMARY KEY, record_uuid uuid NOT NULL, register_key text NOT NULL, is_doctor_confirmed boolean NOT NULL, readme text, present text, history text, allergy text, physique text, proposal text, diagnosis text, cure text) ON COMMIT DROP;
INSERT INTO tmp_demo_records VALUES
('mr001',pg_temp.sbc_demo_uuid('record:mr001'),'r001',TRUE,'头痛','头痛两周','无特殊','无','神经查体无明显异常','影像复查','疑似颅内占位','复诊'),('mr002',pg_temp.sbc_demo_uuid('record:mr002'),'r002',TRUE,'术后复查','术后头闷','术后半年','无','生命体征平稳','继续随访','术后恢复期','随访'),('mr003',pg_temp.sbc_demo_uuid('record:mr003'),'r003',TRUE,'眩晕','眩晕三天','既往类似发作','无','步态轻度不稳','血管评估','前庭性眩晕','复诊'),('mr004',pg_temp.sbc_demo_uuid('record:mr004'),'r004',TRUE,'偏头痛','反复头痛','多年病史','无','畏光','调整用药','偏头痛','用药'),('mr005',pg_temp.sbc_demo_uuid('record:mr005'),'r005',TRUE,'肢体麻木','右臂麻木','两周','无','感觉减退','神经电生理','周围神经病','复诊'),('mr006',pg_temp.sbc_demo_uuid('record:mr006'),'r006',TRUE,'足部麻木','半年','糖代谢异常史','无','感觉减退','营养神经','周围神经病','用药'),('mr007',pg_temp.sbc_demo_uuid('record:mr007'),'r007',TRUE,'急性眩晕','步态不稳','急诊排除出血','无','小脑体征待查','观察','小脑性眩晕','随访'),('mr008',pg_temp.sbc_demo_uuid('record:mr008'),'r008',TRUE,'术后复查','轻度头晕','术后半年','无','状态稳定','继续影像随访','术后神经外科随访','随访'),('mr009',pg_temp.sbc_demo_uuid('record:mr009'),'r010',FALSE,'头痛加重','今日加重','外院影像待阅','无','需影像对照','MRI后评估','疑似颅内占位','待确认'),('mr010',pg_temp.sbc_demo_uuid('record:mr010'),'r011',FALSE,'头晕视物模糊','反复一周','无明显肢体无力','无','建议影像','检查化验','中枢性头晕待排','待确认'),('mr011',pg_temp.sbc_demo_uuid('record:mr011'),'r013',FALSE,'眩晕复发','发作频繁','既往类似','无','轻度步态不稳','CTA及化验','血管性眩晕待排','待确认'),('mr012',pg_temp.sbc_demo_uuid('record:mr012'),'r016',FALSE,'右手麻木','短暂发作','既往类似','无','无持续缺损','评估TIA风险','TIA待排','待确认');
INSERT INTO medical_record (
    uuid,
    register_uuid,
    readme,
    present,
    history,
    allergy,
    physique,
    proposal,
    diagnosis,
    is_doctor_confirmed,
    cure,
    dialog_vector
)
SELECT
    rec.record_uuid,
    reg.register_uuid,
    rec.readme,
    rec.present,
    rec.history,
    rec.allergy,
    rec.physique,
    rec.proposal,
    rec.diagnosis,
    rec.is_doctor_confirmed,
    rec.cure,
    NULL
FROM tmp_demo_records rec
JOIN tmp_demo_registers reg ON reg.register_key = rec.register_key
ON CONFLICT (register_uuid) DO UPDATE
SET uuid = EXCLUDED.uuid,
    readme = EXCLUDED.readme,
    present = EXCLUDED.present,
    history = EXCLUDED.history,
    allergy = EXCLUDED.allergy,
    physique = EXCLUDED.physique,
    proposal = EXCLUDED.proposal,
    diagnosis = EXCLUDED.diagnosis,
    is_doctor_confirmed = EXCLUDED.is_doctor_confirmed,
    cure = EXCLUDED.cure;

DELETE FROM medical_record_disease
WHERE medical_record_id IN (
    SELECT mr.id
    FROM medical_record mr
    JOIN tmp_demo_records tr ON tr.record_uuid = mr.uuid
);

INSERT INTO medical_record_disease (medical_record_id, disease_id, is_primary)
SELECT mr.id, d.id, links.is_primary
FROM (
    VALUES
        ('r001', 'mass', TRUE),
        ('r002', 'postop', TRUE),
        ('r003', 'tia', TRUE),
        ('r004', 'migraine', TRUE),
        ('r005', 'tia', TRUE),
        ('r006', 'neuropathy', TRUE),
        ('r007', 'cerebellar', TRUE),
        ('r008', 'postop', TRUE),
        ('r010', 'mass', TRUE),
        ('r011', 'vertigo', TRUE),
        ('r013', 'tia', TRUE),
        ('r016', 'tia', TRUE),
        ('r013', 'vertigo', FALSE),
        ('r004', 'cervical', FALSE)
) AS links(register_key, disease_key, is_primary)
JOIN tmp_demo_records tr ON tr.register_key = links.register_key
JOIN medical_record mr ON mr.uuid = tr.record_uuid
JOIN tmp_demo_diseases td ON td.disease_key = links.disease_key
JOIN disease d ON d.disease_code = td.disease_code;

INSERT INTO check_request (
    uuid,
    register_uuid,
    medical_technology_id,
    check_info,
    check_position,
    creation_time,
    inputcheck_employee_uuid,
    check_time,
    image_path,
    ai_tumor_prob,
    check_result,
    check_state
)
SELECT
    src.req_uuid,
    reg.register_uuid,
    mt.id,
    src.check_info,
    src.check_position,
    NOW() - INTERVAL '1 day',
    img.employee_uuid,
    src.check_time,
    src.image_path,
    src.ai_tumor_prob,
    src.check_result,
    src.check_state
FROM (
    VALUES
        ('check001', pg_temp.sbc_demo_uuid('check:001'), 'r001', 'mri_head', 'mass evaluation', 'head', NOW() - INTERVAL '20 hours', '/demo/mri-r001.dcm', 0.18::numeric, 'left frontal mass needs enhanced review', U&'\5DF2\6267\884C'),
        ('check002', pg_temp.sbc_demo_uuid('check:002'), 'r003', 'cta_head', 'vascular evaluation', 'head-neck', NOW() - INTERVAL '18 hours', '/demo/cta-r003.dcm', 0.05::numeric, 'no large vessel occlusion seen', U&'\5DF2\9000\8D39'),
        ('check003', pg_temp.sbc_demo_uuid('check:003'), 'r010', 'mri_head', 'today headache worse', 'head', NULL::timestamp, NULL, NULL::numeric, NULL, U&'\672A\7F34\8D39'),
        ('check004', pg_temp.sbc_demo_uuid('check:004'), 'r013', 'ct_head', 'vertigo relapse image check', 'head', NULL::timestamp, NULL, NULL::numeric, NULL, U&'\5DF2\7F34\8D39')
) AS src(req_key, req_uuid, register_key, tech_key, check_info, check_position, check_time, image_path, ai_tumor_prob, check_result, check_state)
JOIN tmp_demo_registers reg ON reg.register_key = src.register_key
JOIN tmp_demo_techs tt ON tt.tech_key = src.tech_key
JOIN medical_technology mt ON mt.tech_code = tt.tech_code
JOIN tmp_demo_employees img ON img.employee_key = 'image_staff'
ON CONFLICT (uuid) DO UPDATE
SET register_uuid = EXCLUDED.register_uuid,
    medical_technology_id = EXCLUDED.medical_technology_id,
    check_info = EXCLUDED.check_info,
    check_position = EXCLUDED.check_position,
    inputcheck_employee_uuid = EXCLUDED.inputcheck_employee_uuid,
    check_time = EXCLUDED.check_time,
    image_path = EXCLUDED.image_path,
    ai_tumor_prob = EXCLUDED.ai_tumor_prob,
    check_result = EXCLUDED.check_result,
    check_state = EXCLUDED.check_state;

INSERT INTO inspection_request (
    uuid,
    register_uuid,
    medical_technology_id,
    creation_time,
    input_employee_uuid,
    inspection_time,
    test_results,
    inspection_state
)
SELECT
    src.req_uuid,
    reg.register_uuid,
    mt.id,
    NOW() - INTERVAL '1 day',
    lab.employee_uuid,
    src.inspect_time,
    src.test_results,
    src.inspect_state
FROM (
    VALUES
        ('inspect001', pg_temp.sbc_demo_uuid('inspect:001'), 'r001', 'blood', NOW() - INTERVAL '17 hours', '{"WBC":"6.2","Hb":"132"}'::jsonb, U&'\5DF2\6267\884C'),
        ('inspect002', pg_temp.sbc_demo_uuid('inspect:002'), 'r003', 'electrolyte', NOW() - INTERVAL '16 hours', '{"Na":"139","K":"4.1"}'::jsonb, U&'\5DF2\9000\8D39'),
        ('inspect003', pg_temp.sbc_demo_uuid('inspect:003'), 'r011', 'coag', NULL::timestamp, NULL::jsonb, U&'\672A\7F34\8D39'),
        ('inspect004', pg_temp.sbc_demo_uuid('inspect:004'), 'r016', 'blood', NULL::timestamp, NULL::jsonb, U&'\5DF2\7F34\8D39')
) AS src(req_key, req_uuid, register_key, tech_key, inspect_time, test_results, inspect_state)
JOIN tmp_demo_registers reg ON reg.register_key = src.register_key
JOIN tmp_demo_techs tt ON tt.tech_key = src.tech_key
JOIN medical_technology mt ON mt.tech_code = tt.tech_code
JOIN tmp_demo_employees lab ON lab.employee_key = 'lab_staff'
ON CONFLICT (uuid) DO UPDATE
SET register_uuid = EXCLUDED.register_uuid,
    medical_technology_id = EXCLUDED.medical_technology_id,
    input_employee_uuid = EXCLUDED.input_employee_uuid,
    inspection_time = EXCLUDED.inspection_time,
    test_results = EXCLUDED.test_results,
    inspection_state = EXCLUDED.inspection_state;

INSERT INTO disposal_request (
    uuid,
    register_uuid,
    medical_technology_id,
    creation_time,
    disposal_time,
    disposal_state,
    disposal_result
)
SELECT
    src.req_uuid,
    reg.register_uuid,
    mt.id,
    NOW() - INTERVAL '1 day',
    src.dispose_time,
    src.dispose_state,
    src.dispose_result
FROM (
    VALUES
        ('dispose001', pg_temp.sbc_demo_uuid('dispose:001'), 'r005', 'infusion', NOW() - INTERVAL '15 hours', U&'\5DF2\6267\884C', 'infusion completed and symptoms improved'),
        ('dispose002', pg_temp.sbc_demo_uuid('dispose:002'), 'r016', 'rehab', NULL::timestamp, U&'\5DF2\7F34\8D39', NULL),
        ('dispose003', pg_temp.sbc_demo_uuid('dispose:003'), 'r018', 'rehab', NULL::timestamp, U&'\672A\7F34\8D39', NULL)
) AS src(req_key, req_uuid, register_key, tech_key, dispose_time, dispose_state, dispose_result)
JOIN tmp_demo_registers reg ON reg.register_key = src.register_key
JOIN tmp_demo_techs tt ON tt.tech_key = src.tech_key
JOIN medical_technology mt ON mt.tech_code = tt.tech_code
ON CONFLICT (uuid) DO UPDATE
SET register_uuid = EXCLUDED.register_uuid,
    medical_technology_id = EXCLUDED.medical_technology_id,
    disposal_time = EXCLUDED.disposal_time,
    disposal_state = EXCLUDED.disposal_state,
    disposal_result = EXCLUDED.disposal_result;

INSERT INTO prescription (
    uuid,
    register_uuid,
    prescription_code,
    creation_time,
    is_ai_recommended,
    drug_state
)
SELECT
    pg_temp.sbc_demo_uuid('prescription:' || src.pres_key),
    reg.register_uuid,
    src.prescription_code,
    NOW() - INTERVAL '1 day',
    src.is_ai_recommended,
    src.drug_state
FROM (
    VALUES
        ('rx001', 'r001', 'RX-DEMO-001', FALSE, U&'\5DF2\53D1\836F'),
        ('rx002', 'r003', 'RX-DEMO-002', TRUE, U&'\5DF2\9000\8D39'),
        ('rx003', 'r006', 'RX-DEMO-003', TRUE, U&'\5DF2\7F34\8D39'),
        ('rx004', 'r008', 'RX-DEMO-004', FALSE, U&'\5F00\7ACB')
    ) AS src(pres_key, register_key, prescription_code, is_ai_recommended, drug_state)
JOIN tmp_demo_registers reg ON reg.register_key = src.register_key
ON CONFLICT (uuid) DO UPDATE
SET register_uuid = EXCLUDED.register_uuid,
    prescription_code = EXCLUDED.prescription_code,
    is_ai_recommended = EXCLUDED.is_ai_recommended,
    drug_state = EXCLUDED.drug_state;

INSERT INTO prescription_item (
    uuid,
    prescription_id,
    drug_id,
    drug_usage,
    drug_number
)
SELECT
    pg_temp.sbc_demo_uuid('presitem:' || src.item_key),
    p.id,
    d.id,
    src.drug_usage,
    src.drug_number
FROM (
    VALUES
        ('rxi001', 'rx001', 'mannitol', 'iv once daily', 2),
        ('rxi002', 'rx001', 'levetiracetam', 'po bid', 1),
        ('rxi003', 'rx002', 'betahistine', 'po tid', 1),
        ('rxi004', 'rx003', 'mecobalamin', 'po tid', 2),
        ('rxi005', 'rx004', 'pregabalin', 'po nightly', 1)
    ) AS src(item_key, pres_key, drug_key, drug_usage, drug_number)
JOIN prescription p ON p.uuid = pg_temp.sbc_demo_uuid('prescription:' || src.pres_key)
JOIN tmp_demo_drugs td ON td.drug_key = src.drug_key
JOIN drug_info d ON d.drug_code = td.drug_code
ON CONFLICT (uuid) DO UPDATE
SET prescription_id = EXCLUDED.prescription_id,
    drug_id = EXCLUDED.drug_id,
    drug_usage = EXCLUDED.drug_usage,
    drug_number = EXCLUDED.drug_number;

INSERT INTO outpatient_bill (
    uuid,
    register_uuid,
    bill_code,
    total_amount,
    settle_category_uuid,
    pay_method,
    pay_time,
    transaction_id,
    bill_state
)
SELECT
    pg_temp.sbc_demo_uuid('bill:' || src.bill_key),
    reg.register_uuid,
    src.bill_code,
    src.total_amount,
    sc.uuid,
    src.pay_method,
    NOW() - INTERVAL '1 day',
    src.transaction_id,
    src.bill_state
FROM (
    VALUES
        ('bill001', 'r001', 'FPDEMO001', 718.00::numeric, 'zf', 'wechat', 'TXN-DEMO-001', U&'\5DF2\6536\8D39'),
        ('bill002', 'r003', 'FPDEMO002', 572.00::numeric, 'yb', 'alipay', 'TXN-DEMO-002', U&'\5DF2\9000\8D39'),
        ('bill003', 'r005', 'FPDEMO003', 96.00::numeric, 'yb', 'wechat', 'TXN-DEMO-003', U&'\5DF2\6536\8D39'),
        ('bill004', 'r006', 'FPDEMO004', 48.00::numeric, 'zf', 'wechat', 'TXN-DEMO-004', U&'\5DF2\6536\8D39'),
        ('bill005', 'r010', 'FPDEMO005', 60.00::numeric, 'zf', 'wechat', 'TXN-DEMO-005', U&'\5DF2\6536\8D39'),
        ('bill006', 'r013', 'FPDEMO006', 60.00::numeric, 'yb', 'wechat', 'TXN-DEMO-006', U&'\5DF2\6536\8D39')
    ) AS src(bill_key, register_key, bill_code, total_amount, settle_key, pay_method, transaction_id, bill_state)
JOIN tmp_demo_registers reg ON reg.register_key = src.register_key
JOIN tmp_demo_settles st ON st.settle_key = src.settle_key
JOIN settle_category sc ON sc.settle_code = st.settle_code
ON CONFLICT (uuid) DO UPDATE
SET register_uuid = EXCLUDED.register_uuid,
    bill_code = EXCLUDED.bill_code,
    total_amount = EXCLUDED.total_amount,
    settle_category_uuid = EXCLUDED.settle_category_uuid,
    pay_method = EXCLUDED.pay_method,
    transaction_id = EXCLUDED.transaction_id,
    bill_state = EXCLUDED.bill_state;

INSERT INTO outpatient_bill_detail (uuid, bill_id, item_type, item_source_id, amount)
SELECT
    pg_temp.sbc_demo_uuid('billdetail:' || src.detail_key),
    bill.id,
    src.item_type,
    src.item_source_id,
    src.amount
FROM (
    VALUES
        ('bd001', 'bill001', U&'\68C0\67E5', pg_temp.sbc_demo_uuid('check:001')::text, 680.00::numeric),
        ('bd002', 'bill001', U&'\68C0\9A8C', pg_temp.sbc_demo_uuid('inspect:001')::text, 38.00::numeric),
        ('bd003', 'bill002', U&'\68C0\67E5', pg_temp.sbc_demo_uuid('check:002')::text, 520.00::numeric),
        ('bd004', 'bill002', U&'\68C0\9A8C', pg_temp.sbc_demo_uuid('inspect:002')::text, 52.00::numeric),
        ('bd005', 'bill003', U&'\5904\7F6E', pg_temp.sbc_demo_uuid('dispose:001')::text, 96.00::numeric),
        ('bd006', 'bill004', U&'\836F\54C1', pg_temp.sbc_demo_uuid('presitem:rxi004')::text, 48.00::numeric)
    ) AS src(detail_key, bill_key, item_type, item_source_id, amount)
JOIN outpatient_bill bill ON bill.uuid = pg_temp.sbc_demo_uuid('bill:' || src.bill_key)
ON CONFLICT (uuid) DO UPDATE
SET bill_id = EXCLUDED.bill_id,
    item_type = EXCLUDED.item_type,
    item_source_id = EXCLUDED.item_source_id,
    amount = EXCLUDED.amount;

INSERT INTO billing_item_charge_lock (item_type, item_source_id, bill_id, bill_code, created_at)
SELECT detail.item_type, detail.item_source_id, detail.bill_id, bill.bill_code, NOW() - INTERVAL '1 day'
FROM outpatient_bill_detail detail
JOIN outpatient_bill bill ON bill.id = detail.bill_id
WHERE detail.uuid IN (
    SELECT pg_temp.sbc_demo_uuid('billdetail:bd001')
    UNION ALL SELECT pg_temp.sbc_demo_uuid('billdetail:bd002')
    UNION ALL SELECT pg_temp.sbc_demo_uuid('billdetail:bd003')
    UNION ALL SELECT pg_temp.sbc_demo_uuid('billdetail:bd004')
    UNION ALL SELECT pg_temp.sbc_demo_uuid('billdetail:bd005')
    UNION ALL SELECT pg_temp.sbc_demo_uuid('billdetail:bd006')
)
ON CONFLICT (item_type, item_source_id) DO UPDATE
SET bill_id = EXCLUDED.bill_id,
    bill_code = EXCLUDED.bill_code;

INSERT INTO billing_refund_saga_step (
    bill_code,
    step_name,
    status,
    request_payload,
    response_payload,
    error_message,
    created_at,
    updated_at
)
SELECT bill.bill_code, 'medical', 'succeeded',
       '{"items":[{"type":"check","id":"check-2"},{"type":"inspection","id":"inspect-2"}]}',
       '{"refunded_items":[{"type":"check","id":"check-2"},{"type":"inspection","id":"inspect-2"}]}',
       NULL,
       NOW() - INTERVAL '16 hours',
       NOW() - INTERVAL '16 hours'
FROM outpatient_bill bill
WHERE bill.uuid = pg_temp.sbc_demo_uuid('bill:bill002')
ON CONFLICT (bill_code, step_name) DO UPDATE
SET status = EXCLUDED.status,
    request_payload = EXCLUDED.request_payload,
    response_payload = EXCLUDED.response_payload,
    error_message = EXCLUDED.error_message,
    updated_at = EXCLUDED.updated_at;

INSERT INTO patient_feedback (uuid, register_uuid, doctor_uuid, content, is_processed, created_at)
SELECT
    pg_temp.sbc_demo_uuid('feedback:' || src.fb_key),
    reg.register_uuid,
    emp.employee_uuid,
    src.content,
    src.is_processed,
    NOW() - INTERVAL '10 hours'
FROM (
    VALUES
        ('fb001', 'r001', 'chen', 'doctor explained image review clearly', FALSE),
        ('fb002', 'r003', 'gu', 'follow up flow was smooth', FALSE),
        ('fb003', 'r005', 'lin', 'risk explanation was clear', TRUE),
        ('fb004', 'r006', 'lin', 'medication plan was clear', TRUE),
        ('fb005', 'r007', 'xu', 'exam was careful during acute vertigo', FALSE),
        ('fb006', 'r008', 'xu', 'post op review plan was clear', FALSE)
    ) AS src(fb_key, register_key, doctor_key, content, is_processed)
JOIN tmp_demo_registers reg ON reg.register_key = src.register_key
JOIN tmp_demo_employees emp ON emp.employee_key = src.doctor_key
ON CONFLICT (uuid) DO UPDATE
SET register_uuid = EXCLUDED.register_uuid,
    doctor_uuid = EXCLUDED.doctor_uuid,
    content = EXCLUDED.content,
    is_processed = EXCLUDED.is_processed,
    created_at = EXCLUDED.created_at;

INSERT INTO schedule_disruption (
    uuid,
    patient_id,
    register_id,
    original_employee_uuid,
    original_time_range,
    original_schedule_date,
    original_noon,
    message,
    status,
    created_at
)
SELECT
    pg_temp.sbc_demo_uuid('disruption:' || src.dis_key),
    p.id,
    r.id,
    emp.employee_uuid,
    CASE src.slot_key
        WHEN 's1' THEN CASE WHEN sa.noon = U&'\4E0A\5348' THEN '08:00-08:10' ELSE '13:00-13:10' END
        WHEN 's2' THEN CASE WHEN sa.noon = U&'\4E0A\5348' THEN '08:10-08:20' ELSE '13:10-13:20' END
        WHEN 's3' THEN CASE WHEN sa.noon = U&'\4E0A\5348' THEN '08:20-08:30' ELSE '13:20-13:30' END
        ELSE CASE WHEN sa.noon = U&'\4E0A\5348' THEN '08:30-08:40' ELSE '13:30-13:40' END
    END,
    sa.schedule_date,
    sa.noon,
    src.message,
    'unread',
    NOW() - INTERVAL '2 hours'
FROM (
    VALUES
        ('dis001', 'r023', 'p21', 'chen', 's2', 'tomorrow clinic may be adjusted, watch for reschedule notice'),
        ('dis002', 'r024', 'p22', 'gu', 's1', 'tomorrow clinic has schedule fluctuation, watch for update'),
        ('dis003', 'r029', 'p02', 'chen', 's1', 'day two follow up may move to afternoon')
    ) AS src(dis_key, register_key, patient_key, doctor_key, slot_key, message)
JOIN tmp_demo_registers tr ON tr.register_key = src.register_key
JOIN register r ON r.uuid = tr.register_uuid
JOIN tmp_demo_patients tp ON tp.patient_key = src.patient_key
JOIN patient p ON p.uuid = tp.patient_uuid
JOIN tmp_demo_employees emp ON emp.employee_key = src.doctor_key
JOIN scheduling_actual sa ON sa.id = r.scheduling_actual_id
ON CONFLICT (uuid) DO UPDATE
SET patient_id = EXCLUDED.patient_id,
    register_id = EXCLUDED.register_id,
    original_employee_uuid = EXCLUDED.original_employee_uuid,
    original_time_range = EXCLUDED.original_time_range,
    original_schedule_date = EXCLUDED.original_schedule_date,
    original_noon = EXCLUDED.original_noon,
    message = EXCLUDED.message,
    status = EXCLUDED.status,
    created_at = EXCLUDED.created_at;

INSERT INTO scheduling_application (uuid, employee_uuid, prompt, status, created_at)
SELECT
    pg_temp.sbc_demo_uuid('schedapp:' || src.app_key),
    emp.employee_uuid,
    src.prompt,
    src.status,
    NOW() - INTERVAL '6 hours'
FROM (
    VALUES
        ('app001', 'zhou', 'add one extra post op review block next week', 'pending'),
        ('app002', 'su', 'move tomorrow pm clinic to am to centralize chronic headache reviews', 'approved'),
        ('app003', 'xu', 'cancel one friday pm clinic and notify patients', 'rejected')
    ) AS src(app_key, doctor_key, prompt, status)
JOIN tmp_demo_employees emp ON emp.employee_key = src.doctor_key
ON CONFLICT (uuid) DO UPDATE
SET employee_uuid = EXCLUDED.employee_uuid,
    prompt = EXCLUDED.prompt,
    status = EXCLUDED.status,
    created_at = EXCLUDED.created_at;

INSERT INTO ai_conversation_session (uuid, surface, module_name, patient_uuid, register_uuid, employee_uuid, status, summary_text, source, model, validated)
SELECT pg_temp.sbc_demo_uuid('ai-session:'||r.register_key), 'patient', 'triage', p.uuid, r.register_uuid, e.employee_uuid, 'linked', '已完成分诊，建议结合病历和检查结果继续接诊。', 'demo_seed', 'demo', TRUE
FROM tmp_demo_registers r JOIN tmp_demo_patients tp ON tp.patient_key=r.patient_key JOIN patient p ON p.uuid=tp.patient_uuid JOIN tmp_demo_schedules s ON s.schedule_key=r.schedule_key JOIN tmp_demo_employees e ON e.employee_key=s.doctor_key
WHERE r.register_key IN ('r001','r003','r005','r007','r010','r011','r013','r016','r018')
ON CONFLICT (uuid) DO UPDATE SET patient_uuid=EXCLUDED.patient_uuid, register_uuid=EXCLUDED.register_uuid, employee_uuid=EXCLUDED.employee_uuid, summary_text=EXCLUDED.summary_text, validated=TRUE;
INSERT INTO ai_conversation_message (uuid, session_uuid, turn_index, role, content)
SELECT pg_temp.sbc_demo_uuid('ai-message:'||r.register_key||':1'), pg_temp.sbc_demo_uuid('ai-session:'||r.register_key), 1, 'user', r.symptoms FROM tmp_demo_registers r WHERE r.register_key IN ('r001','r003','r005','r007','r010','r011','r013','r016','r018')
ON CONFLICT (uuid) DO UPDATE SET content=EXCLUDED.content;
INSERT INTO ai_conversation_message (uuid, session_uuid, turn_index, role, content)
SELECT pg_temp.sbc_demo_uuid('ai-message:'||r.register_key||':2'), pg_temp.sbc_demo_uuid('ai-session:'||r.register_key), 2, 'assistant', '已记录症状，建议按预约时间到诊并携带既往检查资料。' FROM tmp_demo_registers r WHERE r.register_key IN ('r001','r003','r005','r007','r010','r011','r013','r016','r018')
ON CONFLICT (uuid) DO UPDATE SET content=EXCLUDED.content;
COMMIT;
