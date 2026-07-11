--
-- PostgreSQL database dump
--

\restrict yEaNPETiPDZ4818lVqyhHkV2S9FpJgwq4TSrfaJDBMWNXqDJOmWFeNieBFfz5kC

-- Dumped from database version 16.14 (Homebrew)
-- Dumped by pg_dump version 16.14 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS his_db;
--
-- Name: his_db; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE his_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


\unrestrict yEaNPETiPDZ4818lVqyhHkV2S9FpJgwq4TSrfaJDBMWNXqDJOmWFeNieBFfz5kC
\connect his_db
\restrict yEaNPETiPDZ4818lVqyhHkV2S9FpJgwq4TSrfaJDBMWNXqDJOmWFeNieBFfz5kC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: check_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.check_request (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    register_uuid uuid NOT NULL,
    medical_technology_id integer NOT NULL,
    check_info character varying(512),
    check_position character varying(255),
    creation_time timestamp without time zone,
    check_time timestamp without time zone,
    image_path character varying(512),
    ai_tumor_prob numeric(5,2),
    check_result text,
    check_state character varying(64) NOT NULL,
    inputcheck_employee_uuid uuid
);


--
-- Name: check_request_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.check_request_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: check_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.check_request_id_seq OWNED BY public.check_request.id;


--
-- Name: clinic_room; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clinic_room (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    dept_uuid uuid NOT NULL,
    room_name character varying(64) NOT NULL,
    location character varying(128),
    delmark smallint DEFAULT 1
);


--
-- Name: clinic_room_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clinic_room_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clinic_room_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clinic_room_id_seq OWNED BY public.clinic_room.id;


--
-- Name: department; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.department (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    dept_code character varying(64) NOT NULL,
    dept_name character varying(64) NOT NULL,
    dept_type character varying(64) NOT NULL,
    delmark smallint
);


--
-- Name: department_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.department_id_seq OWNED BY public.department.id;


--
-- Name: disease; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disease (
    id integer NOT NULL,
    disease_code character varying(64) NOT NULL,
    disease_name character varying(255) NOT NULL,
    disease_type character varying(64),
    delmark smallint,
    disease_vector public.vector(1024)
);


--
-- Name: disease_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disease_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disease_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disease_id_seq OWNED BY public.disease.id;


--
-- Name: disposal_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disposal_request (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    register_uuid uuid NOT NULL,
    medical_technology_id integer NOT NULL,
    creation_time timestamp without time zone,
    disposal_time timestamp without time zone,
    disposal_state character varying(64) NOT NULL,
    disposal_result text
);


--
-- Name: disposal_request_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disposal_request_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disposal_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disposal_request_id_seq OWNED BY public.disposal_request.id;


--
-- Name: drug_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drug_info (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    drug_code character varying(64) NOT NULL,
    drug_name character varying(255) NOT NULL,
    specification character varying(128) NOT NULL,
    unit character varying(32) NOT NULL,
    price numeric(8,2) NOT NULL,
    stock integer NOT NULL,
    min_stock_limit integer,
    delmark smallint,
    vector public.vector(1024)
);


--
-- Name: drug_info_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.drug_info_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: drug_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.drug_info_id_seq OWNED BY public.drug_info.id;


--
-- Name: employee; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    dept_id integer,
    regist_level_id integer,
    realname character varying(64) NOT NULL,
    password character varying(128) NOT NULL,
    expertise character varying(512),
    ai_eval_score numeric(3,1),
    delmark smallint,
    gender character varying(10),
    expertise_vector public.vector(1024)
);


--
-- Name: employee_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employee_id_seq OWNED BY public.employee.id;


--
-- Name: inspection_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspection_request (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    register_uuid uuid NOT NULL,
    medical_technology_id integer NOT NULL,
    creation_time timestamp without time zone,
    inspection_time timestamp without time zone,
    test_results jsonb,
    inspection_state character varying(64) NOT NULL,
    input_employee_uuid uuid
);


--
-- Name: inspection_request_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inspection_request_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inspection_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inspection_request_id_seq OWNED BY public.inspection_request.id;


--
-- Name: medical_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medical_record (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    register_uuid uuid NOT NULL,
    readme text,
    present text,
    history text,
    allergy character varying(512),
    physique text,
    proposal text,
    diagnosis text,
    is_doctor_confirmed boolean,
    cure text,
    dialog_vector public.vector(1024)
);


--
-- Name: medical_record_disease; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medical_record_disease (
    id integer NOT NULL,
    medical_record_id integer NOT NULL,
    disease_id integer NOT NULL,
    is_primary boolean
);


--
-- Name: medical_record_disease_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.medical_record_disease_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medical_record_disease_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.medical_record_disease_id_seq OWNED BY public.medical_record_disease.id;


--
-- Name: medical_record_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.medical_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medical_record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.medical_record_id_seq OWNED BY public.medical_record.id;


--
-- Name: medical_technology; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medical_technology (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    tech_code character varying(64) NOT NULL,
    tech_name character varying(255) NOT NULL,
    tech_type character varying(64) NOT NULL,
    price numeric(8,2) NOT NULL,
    delmark smallint
);


--
-- Name: medical_technology_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.medical_technology_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medical_technology_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.medical_technology_id_seq OWNED BY public.medical_technology.id;


--
-- Name: outbox_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outbox_event (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    topic character varying(255) NOT NULL,
    payload text NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    created_at timestamp without time zone,
    retry_count integer DEFAULT 0
);


--
-- Name: outbox_event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outbox_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outbox_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outbox_event_id_seq OWNED BY public.outbox_event.id;


--
-- Name: outpatient_bill; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outpatient_bill (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    register_uuid uuid NOT NULL,
    bill_code character varying(64) NOT NULL,
    total_amount numeric(10,2) NOT NULL,
    settle_category_uuid uuid,
    pay_method character varying(32) NOT NULL,
    pay_time timestamp without time zone,
    transaction_id character varying(128),
    bill_state character varying(32) NOT NULL
);


--
-- Name: outpatient_bill_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outpatient_bill_detail (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    bill_id integer NOT NULL,
    item_type character varying(64) NOT NULL,
    item_source_id character varying(64) NOT NULL,
    amount numeric(8,2) NOT NULL
);


--
-- Name: outpatient_bill_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outpatient_bill_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outpatient_bill_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outpatient_bill_detail_id_seq OWNED BY public.outpatient_bill_detail.id;


--
-- Name: outpatient_bill_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outpatient_bill_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outpatient_bill_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outpatient_bill_id_seq OWNED BY public.outpatient_bill.id;


--
-- Name: patient; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    case_number character varying(64) NOT NULL,
    real_name character varying(64) NOT NULL,
    gender character varying(10) NOT NULL,
    card_number character varying(18) NOT NULL,
    birthdate date NOT NULL,
    home_address character varying(255),
    created_at timestamp without time zone
);


--
-- Name: patient_feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_feedback (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    register_uuid uuid NOT NULL,
    doctor_uuid uuid NOT NULL,
    content text NOT NULL,
    is_processed boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: patient_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.patient_feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patient_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.patient_feedback_id_seq OWNED BY public.patient_feedback.id;


--
-- Name: patient_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.patient_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patient_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.patient_id_seq OWNED BY public.patient.id;


--
-- Name: prescription; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prescription (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    register_uuid uuid NOT NULL,
    prescription_code character varying(64) NOT NULL,
    creation_time timestamp without time zone,
    is_ai_recommended boolean,
    drug_state character varying(64) NOT NULL
);


--
-- Name: prescription_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prescription_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prescription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prescription_id_seq OWNED BY public.prescription.id;


--
-- Name: prescription_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prescription_item (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    prescription_id integer NOT NULL,
    drug_id integer NOT NULL,
    drug_usage character varying(255) NOT NULL,
    drug_number integer NOT NULL
);


--
-- Name: prescription_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prescription_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prescription_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prescription_item_id_seq OWNED BY public.prescription_item.id;


--
-- Name: regist_level; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regist_level (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    regist_code character varying(64) NOT NULL,
    regist_name character varying(64) NOT NULL,
    regist_fee numeric(8,2) NOT NULL,
    delmark smallint
);


--
-- Name: regist_level_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regist_level_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regist_level_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regist_level_id_seq OWNED BY public.regist_level.id;


--
-- Name: register; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.register (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    patient_id integer NOT NULL,
    visit_date timestamp without time zone NOT NULL,
    noon character varying(10) NOT NULL,
    dept_uuid uuid,
    employee_uuid uuid NOT NULL,
    scheduling_actual_id integer,
    settle_category_uuid uuid,
    regist_method character varying(20),
    regist_money numeric(8,2) NOT NULL,
    is_emergency boolean,
    visit_state smallint,
    symptoms text,
    scheduling_time_slot_id integer
);


--
-- Name: register_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.register_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: register_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.register_id_seq OWNED BY public.register.id;


--
-- Name: schedule_disruption; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schedule_disruption (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    patient_id integer NOT NULL,
    register_id integer NOT NULL,
    original_employee_uuid uuid NOT NULL,
    original_time_range character varying(64) NOT NULL,
    original_schedule_date date NOT NULL,
    original_noon character varying(10) NOT NULL,
    message text NOT NULL,
    status character varying(20) NOT NULL,
    created_at timestamp without time zone
);


--
-- Name: schedule_disruption_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schedule_disruption_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_disruption_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schedule_disruption_id_seq OWNED BY public.schedule_disruption.id;


--
-- Name: scheduling_actual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduling_actual (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    employee_uuid uuid NOT NULL,
    schedule_date date NOT NULL,
    noon character varying(10) NOT NULL,
    regist_quota integer NOT NULL,
    registered_count integer NOT NULL,
    clinic_room_uuid uuid
);


--
-- Name: scheduling_actual_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scheduling_actual_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduling_actual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scheduling_actual_id_seq OWNED BY public.scheduling_actual.id;


--
-- Name: scheduling_application; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduling_application (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    employee_uuid uuid NOT NULL,
    prompt text NOT NULL,
    status character varying(20) NOT NULL,
    reject_reason text,
    created_at timestamp without time zone,
    processed_at timestamp without time zone
);


--
-- Name: scheduling_application_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scheduling_application_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduling_application_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scheduling_application_id_seq OWNED BY public.scheduling_application.id;


--
-- Name: scheduling_rule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduling_rule (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    employee_uuid uuid NOT NULL,
    rule_name character varying(64) NOT NULL,
    week_rule character varying(14) NOT NULL,
    llm_text_rule text,
    regist_quota integer NOT NULL,
    delmark smallint,
    clinic_room_uuid uuid
);


--
-- Name: scheduling_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scheduling_rule_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduling_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scheduling_rule_id_seq OWNED BY public.scheduling_rule.id;


--
-- Name: scheduling_time_slot; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduling_time_slot (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    scheduling_actual_id integer NOT NULL,
    time_range character varying(30) NOT NULL,
    is_booked boolean DEFAULT false
);


--
-- Name: scheduling_time_slot_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scheduling_time_slot_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduling_time_slot_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scheduling_time_slot_id_seq OWNED BY public.scheduling_time_slot.id;


--
-- Name: settle_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settle_category (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    settle_code character varying(64) NOT NULL,
    settle_name character varying(64) NOT NULL,
    delmark smallint
);


--
-- Name: settle_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settle_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settle_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settle_category_id_seq OWNED BY public.settle_category.id;


--
-- Name: check_request id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.check_request ALTER COLUMN id SET DEFAULT nextval('public.check_request_id_seq'::regclass);


--
-- Name: clinic_room id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_room ALTER COLUMN id SET DEFAULT nextval('public.clinic_room_id_seq'::regclass);


--
-- Name: department id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department ALTER COLUMN id SET DEFAULT nextval('public.department_id_seq'::regclass);


--
-- Name: disease id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disease ALTER COLUMN id SET DEFAULT nextval('public.disease_id_seq'::regclass);


--
-- Name: disposal_request id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disposal_request ALTER COLUMN id SET DEFAULT nextval('public.disposal_request_id_seq'::regclass);


--
-- Name: drug_info id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_info ALTER COLUMN id SET DEFAULT nextval('public.drug_info_id_seq'::regclass);


--
-- Name: employee id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee ALTER COLUMN id SET DEFAULT nextval('public.employee_id_seq'::regclass);


--
-- Name: inspection_request id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_request ALTER COLUMN id SET DEFAULT nextval('public.inspection_request_id_seq'::regclass);


--
-- Name: medical_record id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_record ALTER COLUMN id SET DEFAULT nextval('public.medical_record_id_seq'::regclass);


--
-- Name: medical_record_disease id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_record_disease ALTER COLUMN id SET DEFAULT nextval('public.medical_record_disease_id_seq'::regclass);


--
-- Name: medical_technology id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_technology ALTER COLUMN id SET DEFAULT nextval('public.medical_technology_id_seq'::regclass);


--
-- Name: outbox_event id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_event ALTER COLUMN id SET DEFAULT nextval('public.outbox_event_id_seq'::regclass);


--
-- Name: outpatient_bill id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outpatient_bill ALTER COLUMN id SET DEFAULT nextval('public.outpatient_bill_id_seq'::regclass);


--
-- Name: outpatient_bill_detail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outpatient_bill_detail ALTER COLUMN id SET DEFAULT nextval('public.outpatient_bill_detail_id_seq'::regclass);


--
-- Name: patient id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient ALTER COLUMN id SET DEFAULT nextval('public.patient_id_seq'::regclass);


--
-- Name: patient_feedback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_feedback ALTER COLUMN id SET DEFAULT nextval('public.patient_feedback_id_seq'::regclass);


--
-- Name: prescription id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription ALTER COLUMN id SET DEFAULT nextval('public.prescription_id_seq'::regclass);


--
-- Name: prescription_item id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription_item ALTER COLUMN id SET DEFAULT nextval('public.prescription_item_id_seq'::regclass);


--
-- Name: regist_level id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regist_level ALTER COLUMN id SET DEFAULT nextval('public.regist_level_id_seq'::regclass);


--
-- Name: register id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.register ALTER COLUMN id SET DEFAULT nextval('public.register_id_seq'::regclass);


--
-- Name: schedule_disruption id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_disruption ALTER COLUMN id SET DEFAULT nextval('public.schedule_disruption_id_seq'::regclass);


--
-- Name: scheduling_actual id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_actual ALTER COLUMN id SET DEFAULT nextval('public.scheduling_actual_id_seq'::regclass);


--
-- Name: scheduling_application id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_application ALTER COLUMN id SET DEFAULT nextval('public.scheduling_application_id_seq'::regclass);


--
-- Name: scheduling_rule id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_rule ALTER COLUMN id SET DEFAULT nextval('public.scheduling_rule_id_seq'::regclass);


--
-- Name: scheduling_time_slot id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_time_slot ALTER COLUMN id SET DEFAULT nextval('public.scheduling_time_slot_id_seq'::regclass);


--
-- Name: settle_category id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settle_category ALTER COLUMN id SET DEFAULT nextval('public.settle_category_id_seq'::regclass);


--
-- Data for Name: check_request; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.check_request (id, uuid, register_uuid, medical_technology_id, check_info, check_position, creation_time, check_time, image_path, ai_tumor_prob, check_result, check_state, inputcheck_employee_uuid) FROM stdin;
2	01bfe300-3c06-4d2d-b880-5b7bb24734bc	b5b44f78-352b-43d4-b28e-670047981745	1	脑部磁共振成像，排查颅内占位	\N	2026-05-23 11:11:23.745797	\N	\N	\N	\N	未缴费	\N
3	fa6d67d9-a18d-4392-a21f-7168880f06ae	59fb6156-4035-4275-a9bc-29625d3fdc10	1	脑部磁共振成像，排查颅内占位	\N	2026-05-23 11:12:02.915566	\N	\N	\N	\N	未缴费	\N
16	0ce2d612-725f-4ba1-adf2-9653b1916db7	505c8fd6-c8a8-439c-90ec-9a02f13a84fd	1	脑部磁共振成像，排查颅内占位	\N	2026-05-24 12:19:11.128246	\N	\N	\N	\N	已缴费	\N
4	a98cf3ef-a1d8-43d2-9f07-05578daafff8	3df51db8-498b-4ccb-951e-c909547147eb	1	脑部磁共振成像，排查颅内占位	\N	2026-05-23 11:14:10.522657	\N	/pacs/mri/patient_brain_tumor_suspected.dcm	0.80	【AI 智能阅片结果】\n1. 发现高密度/异常信号阴影，疑似颅内占位性病变。\n2. 病灶边缘不规则，有轻度水肿带。\n3. 恶性脑肿瘤预警概率: 80.0%\n建议：结合增强核磁共振(MRI)进一步排查，并建议立刻联系专科医生复诊。\n\n【医生出具的结论】\nMRI影像已扫描完毕，发现异常高密度影。	已执行	\N
17	9e95cd87-0b8c-432d-ae4e-f9bb44a3aac3	40cc2c9f-432b-40c8-a659-511360b769b4	1	脑部磁共振成像，排查颅内占位	\N	2026-05-24 12:22:15.221052	2026-05-24 12:22:18.503048	/pacs/mri/patient_brain_tumor_suspected.dcm	0.87	【AI 智能阅片结果】\n1. 发现高密度/异常信号阴影，疑似颅内占位性病变。\n2. 病灶边缘不规则，有轻度水肿带。\n3. 恶性脑肿瘤预警概率: 87.0%\n建议：结合增强核磁共振(MRI)进一步排查，并建议立刻联系专科医生复诊。\n\n【医生出具的结论】\nMRI影像已扫描完毕，发现异常高密度影。	已执行	11111111-1111-1111-1111-111111111111
18	bc9f1e8f-ca5a-4f2f-9cdc-6e082d0c1000	98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a	1	头晕排查	头部	2026-05-27 21:05:00.185232	2026-05-27 21:24:10.077798	/tmp/img.png	0.43	【AI 智能阅片结果】\n1. 脑实质内未见明显典型大面积异常密度影。\n2. 局部可见少许斑片状模糊影，性质待定。\n3. 脑肿瘤预警概率: 43.0%。\n建议：如患者有明显临床症状，建议随访观察或增加检查序列。\n\n【医生出具的结论】\n未见明显异常	已执行	00000000-0000-0000-0000-000000000000
19	b5b510c3-d137-448c-9851-17582027ea51	518376ad-a7d7-4221-8495-2d74d90973c0	1	加急做个脑部核磁	脑部	2026-05-28 20:51:40.991339	\N	\N	\N	\N	未缴费	\N
8	173c7818-3fac-49e0-bcc9-91b81bb1af05	522575f5-810e-4ee4-8290-467c6f401f3b	1	脑部磁共振成像，排查颅内占位	\N	2026-05-23 17:18:12.966688	\N	/pacs/mri/patient_brain_tumor_suspected.dcm	0.78	【AI 智能阅片结果】\n1. 发现高密度/异常信号阴影，疑似颅内占位性病变。\n2. 病灶边缘不规则，有轻度水肿带。\n3. 恶性脑肿瘤预警概率: 78.0%\n建议：结合增强核磁共振(MRI)进一步排查，并建议立刻联系专科医生复诊。\n\n【医生出具的结论】\nMRI影像已扫描完毕，发现异常高密度影。	已执行	\N
20	5ef6498f-ccb8-4d19-bfe0-242cfcafdf80	c6dc2419-8255-4b00-9d9b-56a94ad9feaa	1	加急做个脑部核磁	脑部	2026-05-28 20:53:05.806366	\N	\N	\N	\N	已缴费	\N
21	901a5b13-8d6d-4197-abb9-3ac99ec56e62	2f5d38eb-2c00-4d41-88d2-18e2ad56f7fc	1	加急做个脑部核磁	脑部	2026-05-28 20:54:14.605077	\N	\N	\N	\N	已缴费	\N
11	29f0a308-93e5-4c33-b371-d87b2c00386d	17038ffe-7621-47df-9f9a-13cd4fbe41d5	1	脑部MRI，排查占位	\N	2026-05-23 22:02:06.487519	\N	\N	\N	\N	未缴费	\N
12	e323db5a-c9b3-4a40-a9e3-505554619c52	f53d35f8-0c77-4eb9-a027-97083e934a7a	1	脑部MRI，排查占位	\N	2026-05-23 22:03:48.205691	\N	\N	\N	\N	未缴费	\N
13	76366440-7604-44e1-9641-2b3899507b8c	3a91916c-7ba0-4ebd-bbf1-024b67e30b97	1	患者头晕，怀疑有血块	头部	2026-05-24 12:00:57.223662	\N	\N	\N	\N	未缴费	\N
14	f3a1a457-06e5-4df5-bb07-ba9de2a22f9e	3a91916c-7ba0-4ebd-bbf1-024b67e30b97	1	患者头晕，怀疑有血块	头部	2026-05-24 12:01:12.791004	\N	\N	\N	\N	未缴费	\N
15	b7be7469-bf46-4a35-8f32-817652c994e3	3a91916c-7ba0-4ebd-bbf1-024b67e30b97	1	患者主诉头晕，伴随耳鸣，怀疑有小面积梗死或血块	头部	2026-05-24 12:02:44.50696	\N	\N	\N	\N	未缴费	\N
22	54b7cccf-9123-4a66-ac6a-0bb88f739fd0	50cf0ba7-41f3-45b5-88ca-d25bf2fdf69d	1	加急做个脑部核磁	脑部	2026-05-28 20:55:34.769512	2026-05-28 20:55:36.923024	\N	\N	【医生出具的结论】\n未见明显异常	已执行	5ca2828e-90ed-46b3-8476-f60b81019aa5
23	b72601b8-ba3a-4dab-a9e5-7b3cf9605b59	5ed3c049-4490-43a6-8b12-3fd64eb6163d	1	加急做个脑部核磁	脑部	2026-05-28 20:56:29.501554	2026-05-28 20:56:31.629885	\N	\N	【医生出具的结论】\n未见明显异常	已执行	5ca2828e-90ed-46b3-8476-f60b81019aa5
24	2cc59f6d-8bb5-498f-a71a-dab37ea3f636	45cd4007-3bf2-4814-8007-ae8116680208	1	加急做个脑部核磁	脑部	2026-05-28 21:03:04.078613	2026-05-28 21:03:06.227925	\N	\N	【医生出具的结论】\n未见明显异常	已执行	5ca2828e-90ed-46b3-8476-f60b81019aa5
\.


--
-- Data for Name: clinic_room; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.clinic_room (id, uuid, dept_uuid, room_name, location, delmark) FROM stdin;
1	55555555-5555-5555-5555-555555555555	33333333-3333-3333-3333-333333333333	特需2号诊室	A栋3楼	1
2	66666666-6666-6666-6666-666666666666	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	妇科一诊室	B栋2楼	1
\.


--
-- Data for Name: department; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.department (id, uuid, dept_code, dept_name, dept_type, delmark) FROM stdin;
1	33333333-3333-3333-3333-333333333333	SJWK	神经外科	门诊	1
2	a4d3af24-e83b-4a84-8094-f6d6f31b9b3a	XNK	心内科	门诊	1
3	40504a01-c105-401d-8acf-8c9c9ac3663a	GK	骨科	门诊	1
4	c35a9ac0-38a1-4165-bca2-621bb889d562	EK	儿科	门诊	1
5	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	FCK	妇产科	门诊	1
\.


--
-- Data for Name: disease; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.disease (id, disease_code, disease_name, disease_type, delmark, disease_vector) FROM stdin;
1	C71.900	脑恶性肿瘤	肿瘤	1	[-0.04348464,0.020852283,-0.033004005,-0.03465693,-0.029861633,0.014912652,0.05431039,0.00407782,0.010680438,-0.00869602,0.017546434,0.007306473,0.0031764312,0.028917104,0.020361856,-0.06989511,-0.010217256,-0.004023328,-0.031896003,-0.013168907,-0.008364527,-0.009799483,-0.07628884,0.017537352,-0.025247974,-0.0032740629,-0.03796278,-0.037926454,0.03347627,0.009327219,0.023667704,-0.00910471,-0.017419286,-0.07810524,0.020470839,-0.05027798,-0.023722196,0.02350423,-0.052639302,-0.0041686404,0.030243076,0.070222065,0.03316748,-0.023667704,0.04050574,-0.029007923,0.01843647,-0.036346182,0.020325527,-0.023994656,0.017201317,-0.038289733,0.017709909,0.0040800907,0.008941234,0.020053066,-0.017473778,-0.0152305225,-0.02898976,-0.008355444,-0.009926631,-0.0028154214,-0.01998041,0.0042049685,-0.007855934,0.03153272,0.011334342,0.015212358,0.021397203,0.014712848,-0.009626925,0.017283056,-0.019199358,-0.015348588,-0.043920577,-0.0016699537,0.037890125,-0.048570562,-0.0014054403,0.010544208,0.0811568,-0.032604396,0.029589172,-0.004534191,-0.013768319,0.066698246,0.033694237,0.012188051,-0.030515537,-0.025175318,0.0011607937,0.026519455,-0.023576885,0.0049133645,-0.0150670465,-0.060813107,-0.024666725,-0.014349568,-0.001843647,0.032876857,0.007347342,0.024703054,0.0059577953,-0.0115069,-0.031732526,-0.015030718,-0.005635384,0.054092422,-0.038580358,0.005703499,0.0011409268,0.03211397,-0.013268809,-0.017537352,-0.021887632,-0.02473938,-0.019653458,-0.055327576,-0.005040513,-0.014985308,0.023322588,0.018999554,-0.01236969,-0.0067887986,0.017610008,-0.008364527,0.07134823,0.027918084,-2.250989e-05,-0.022759505,-0.0039302376,0.07890446,-0.03650966,-0.011951919,-0.002255743,-0.03256807,0.015003473,-0.0035351703,-0.010190009,-0.011397916,-0.00044785638,0.045627993,0.0047317245,-0.029934289,-0.005090464,-0.044247527,0.005812483,0.041522928,0.038217075,-0.059105687,0.0005778426,0.0020775087,-0.008705102,0.039343245,-0.017192235,0.043266673,-0.03147823,0.026537618,0.04493776,0.047626033,-0.02889894,-0.017473778,0.030388389,0.006034992,-0.0052630217,0.008187427,0.09692316,0.049842045,-0.023431573,0.015566557,-0.01934467,-0.02695539,0.0064527644,0.0021751402,0.02101576,-0.0033013087,0.045228384,0.014785504,-0.032677054,-0.035111032,-0.017101415,-0.022432553,0.009141038,0.042867064,-0.0063664853,-0.019399162,-0.02219642,0.018563619,0.0052448576,0.065572076,-0.018200338,-0.013078087,0.012151723,0.023940165,0.03262256,-0.022087436,0.0069250287,-0.032132134,-0.05500062,0.014458552,-0.043302998,0.010407978,0.02744582,0.016256789,-0.005921467,0.007197489,0.011924673,-0.035456147,-0.019653458,-0.062120914,-0.016374854,-0.020489004,-0.009717746,0.007215653,0.0018538643,-0.08340913,0.002831315,0.03378506,0.007419998,-0.037926454,0.0022182798,0.04788033,-0.0023034236,-0.0003144644,0.040251445,0.001417928,0.0016052444,-0.011179948,0.03645517,-0.02025287,-0.018999554,0.011688541,-0.022341732,0.016411183,0.056090463,0.027572967,0.013977205,0.019617131,0.0052630217,0.009309055,0.012605823,0.009563351,0.053474844,0.024067312,0.018463716,0.03247725,0.010253583,0.0029516516,-0.012178969,-0.004102796,0.01590259,0.026374143,-0.043811593,-0.050895557,-0.0070703407,-0.0051949066,0.011225358,0.009990205,0.030697176,0.030097764,0.02971632,0.038870983,0.019962247,0.024485085,0.005258481,-0.032459084,0.020888612,0.00027203443,0.010217256,-0.027754607,-0.019816935,-0.0065072565,-0.022705013,0.025883714,0.011070964,-0.044465497,0.009281809,0.0006351727,0.0031605377,0.0052312347,0.023140948,0.03641884,-0.036364347,-0.03140557,0.0480983,0.0018232125,-0.07832321,-0.04566432,-0.026265157,0.0011954189,-0.025883714,-0.0362372,0.07152987,0.0047635115,-0.015848098,0.03044288,-0.015702786,-0.12751135,-0.0108257495,-0.017455613,0.030061437,-0.014549372,-0.008818626,-0.011170866,-0.010680438,-0.023431573,0.009508859,0.015820853,-0.050713915,-0.03996082,0.012778381,-0.026392307,-0.023794852,-0.027209686,-0.048679546,-0.0052493988,-0.046899475,-0.04206785,0.009086546,-0.00017511241,-0.0050768405,-0.02668293,0.0088822,0.027518475,-0.024757545,-0.027300507,0.0043956903,-0.048352595,-0.059251,-0.012351527,0.067824416,0.008146558,-0.031278424,0.008178346,-0.02395833,0.008010329,-0.016747218,-0.03296768,0.112180926,-0.00055144797,0.07461775,0.05336586,0.021415368,0.040287774,0.00077197043,0.03912528,-0.03492939,0.027845427,-0.0023136407,0.0029334875,-0.019944083,0.026210666,0.014894488,-0.005267563,0.0026474043,0.027663788,-0.008705102,-0.027100703,-0.05398344,-0.029062416,0.0604135,0.061684977,0.008936693,0.0033489894,-0.053256877,0.043375656,-0.012106312,-0.007574392,-0.024176298,0.036564153,0.016910693,0.038798325,-0.020761464,0.014095272,-0.026337814,-0.00028125834,-0.072692364,-0.05285727,0.048679546,0.007433621,0.052530315,-0.01607515,-0.057107646,0.026392307,0.01096198,0.00724744,0.21419,0.011933754,0.02419446,0.00448424,0.0024067312,0.017301219,0.026156174,-0.008060279,-0.022886652,-0.007919508,-0.018963227,0.025883714,0.0059623364,0.027482146,-0.031768855,0.072002135,-0.031332918,-0.018191256,0.10273564,-0.041922536,-0.0059623364,-0.04036043,0.054927967,0.003596474,0.0136865815,-0.03641884,-0.021342712,0.05776155,0.004102796,-0.031223932,-0.017146826,-0.008251001,0.04195886,-0.029407531,-0.025338793,-0.017737156,-0.029462025,-0.0103988955,-0.0064436826,0.010308076,-0.009408957,-0.051622115,-0.04257644,0.030497372,0.022305405,0.003596474,-0.014958062,0.024212625,-0.010798504,-0.049696732,0.025302466,-0.0066616507,0.013277891,-0.025720239,0.0034943013,0.0099084675,-0.0103988955,0.0115069,-0.012696642,0.023576885,0.038943637,0.007415457,-0.037072744,0.0041868044,0.013232481,0.053111564,-0.07708806,0.02550227,-0.014394978,0.02789992,0.06328341,-0.0048634135,-0.01952631,0.018672602,0.022705013,0.03912528,-0.017855221,0.026628438,0.07185683,0.005485531,0.011797524,-0.008014869,-0.02744582,-0.045773305,0.0036941054,0.010208174,0.020761464,-0.0011965542,-0.02374036,0.01399537,0.016138723,-0.011833852,-0.0385077,-0.0012215297,-0.055727184,0.036219034,0.028862612,-0.009935713,-0.01494898,0.021869468,-0.02980714,-0.034893062,-0.017673582,-0.00048730633,0.045918617,0.040069807,-0.05394711,-0.014331404,-0.07116659,0.049297124,0.017827976,0.008251001,-0.05209438,0.019017719,-0.018500043,0.019889591,-0.073818535,0.022160092,0.015866263,0.0362372,-0.019235685,0.005399252,-0.022850323,0.086097404,0.029389368,-0.012396936,0.038435046,-0.0025929124,-0.052348677,0.034947556,-0.000855979,0.00066298636,-0.05598148,0.015348588,0.026246995,-0.021270055,0.053111564,0.023249932,0.067933396,0.02541145,0.033712402,0.04897017,-5.1511997e-05,0.0049179057,0.0385077,-0.019689787,-0.0035170063,-0.0050359718,-0.010625945,0.03356709,0.0034761373,0.06582637,0.033639748,-0.03547431,0.0008383826,-0.04352097,-0.038035437,0.01137067,0.018781586,-0.04406589,0.031314753,0.03723622,0.031223932,0.018154928,0.0012351527,0.026846407,0.01394996,-0.0108257495,0.038943637,0.015303179,-0.037036415,0.011479654,-0.029225891,0.04947876,-0.0451194,0.07687009,0.013005431,0.0029947911,0.019453654,0.0024021904,0.007311014,-0.0062075504,-0.000613603,0.03854403,0.06771543,-0.0066116997,0.039851837,-8.642095e-05,-0.028299527,-0.012887365,-0.020271035,0.06088576,0.01599341,-0.027645623,0.010762176,-0.002586101,-0.012251625,-0.008092066,0.0034193748,-0.008359985,0.035092868,0.027754607,-0.022359896,-0.014930816,-0.0007163431,0.022686848,0.018363815,-0.018191256,0.02097943,0.005349301,-0.017964207,0.0020411806,-0.011579556,0.0291714,-0.048497908,0.00289943,-0.07766931,0.010389813,-0.0021910337,-0.009236399,0.021088416,-0.019054046,0.042758077,-0.056635384,-0.039379574,-0.0077514914,-0.006030451,-0.022341732,-0.0011312772,0.070839636,0.0038621225,-0.052566644,0.022632357,0.00086051994,-0.0010177522,-0.03796278,-0.017682664,0.007342801,0.06462755,-0.026210666,0.06648028,-0.059178345,-0.0081647225,0.08747787,-0.0065163383,-0.01467652,0.063937314,-0.006961357,0.044102214,-0.0038484996,-0.010898406,-0.010635028,0.01998041,-0.014558454,-0.030642685,-0.005326596,-0.015757278,-0.025211645,-0.043956906,0.037490517,-0.0039007212,-0.007692458,-0.027881755,0.020597987,-0.03184151,-0.005494613,-0.007424539,0.08173805,-0.014667438,-0.06328341,0.018763423,-0.003982459,-0.008900365,-0.012269788,0.027463984,0.018227585,-0.013568515,0.035129193,0.04050574,0.001988959,0.011198112,-0.017319383,-0.030152256,0.043557294,-0.0065708305,0.0060077463,0.01508521,0.030479208,0.017337548,-0.0207433,-0.039306916,-0.0066661914,-0.030461045,0.022668684,-0.034856737,-0.022250911,-0.035492476,-0.01572095,0.0048997416,0.026355978,-0.034529783,-0.047771346,-0.06306544,-0.045337368,0.015975246,0.0035533344,0.014667438,-0.030951472,-0.011515982,0.019635295,0.0173103,-0.06575371,-0.021851303,0.039888166,-0.10317157,-0.023994656,0.024884693,-0.057289287,-0.03198682,0.018908734,0.0038712046,-0.040396757,0.00064652524,-0.020888612,-0.012614905,0.04221316,-0.031914167,-0.019090375,-0.026646603,-0.024030985,-0.008582494,-0.014258748,0.029007923,-0.032041315,-0.034329977,0.018926898,-0.0098085655,-0.011334342,0.034239158,-0.041740894,-0.00023428735,-0.01531226,0.06600801,0.013514023,-0.050677586,-0.0047135605,0.015666459,0.025920043,0.029189564,0.015121538,0.02274134,0.01159772,-0.007597097,-0.03044288,0.015848098,0.035619624,0.005848811,0.015684623,-0.018109517,0.005326596,-0.016229542,-0.020597987,0.010998308,0.031968657,0.024394264,0.018963227,-0.030152256,-0.017537352,0.061176386,-0.0016245437,-0.016729053,-0.014803668,-0.027863592,-0.0013486777,-0.0396702,-0.008437183,-0.0015325883,-0.010807586,0.016193215,-0.039524887,-0.0008031898,0.0033126613,-0.033857714,-0.017355712,0.021360876,0.005562728,-0.012533166,-0.013377793,0.054056093,0.012406019,-0.032440923,-0.040832695,-0.021088416,-0.015875345,-0.14117068,-0.01907221,-0.00015297502,-0.042721752,-0.039524887,-0.009095628,0.008546167,0.033966698,-0.019435491,-0.0314419,0.006598077,-0.030115929,-0.015848098,-0.023231769,0.005372006,0.025120826,0.026446799,-0.0010762176,0.014413142,0.016810792,-0.0066525685,0.010989226,-0.038979966,0.021760484,-0.000874143,-0.011906508,0.0033126613,0.012178969,-0.0362372,0.074981034,0.0071339146,-0.009490695,0.024721218,0.01666548,0.0005886274,-0.00892307,-0.011125456,-0.031242097,-0.009050217,-0.006961357,-0.009590597,0.013977205,0.017455613,-0.024993677,-0.09132864,-0.008051197,0.008945775,-0.0043184934,0.030134093,-0.04108699,-0.012769299,0.036618643,-0.032095805,-0.028099723,-0.05688968,0.007311014,-0.034874897,-0.024703054,0.05049595,0.039343245,0.042721752,-0.047989313,-0.03536533,0.009863057,-0.012033656,0.007905886,-0.07360057,0.001458797,-0.0035101948,0.027554803,-0.05481898,0.0061939275,0.0050632176,-0.049297124,0.03810809,0.010971062,0.004091443,-0.038253404,0.011988247,-0.011606802,0.011070964,-0.014413142,8.393759e-05,-0.10905672,0.034366306,-0.019998575,-0.0020911316,0.018536372,0.013613925,0.009168284,-0.014431306,-0.022541536,0.015057964,-0.024357937,-0.057289287,0.005308432,0.00029062416,0.007919508,-0.045736976,-0.012941857,0.020634316,-0.038398717,0.031187605,-0.03360342,-0.03393037,-0.00051228184,0.024539577,-0.005880598,0.018472798,0.01752827,-0.02401282,-0.01508521,0.0038939095,0.011134538,-0.037853796,-0.0038712046,0.042467456,-0.0122062145,-0.005308432,0.023031965,-0.039851837,-0.0029471107,-0.0014338215,-0.031278424,-0.0027563884,-0.026828242,0.041304957,-0.025157154,-0.00068001513,-0.0207433,0.046499863,-0.013659336,0.025938205,0.01513062,0.020162052,0.057652567,0.005599056,0.040287774,-0.016420266,-0.034057517,0.016974267,-0.013713827,-0.011343424,0.005058677,0.004177722,-0.020416347,0.010535126,-0.014549372,-0.0027155194,0.0031877838,0.025447778,-0.032313775,-0.004409313,-0.05343852,-0.017918795,0.020725135,-0.020325527,0.009863057,0.03140557,0.02750031,0.014522126,-0.035329,-0.023940165,0.022160092,-0.0047271834,0.009227317,-0.0041323123,-0.010081026,-0.0050268895,-0.022705013,-0.011942836,0.03129659,-0.030424716,0.01658374,-0.009926631,-0.019617131,-0.010317158,0.034275487,0.0070022256,-0.01096198,0.027336834,0.013205235,-0.037036415,-0.027082538,-0.014367732,0.018363815,-0.012723889,0.047807675,0.016265871,-0.015784524,-0.0015393998,-0.021869468,0.049587745,0.00029743565,0.03026124,0.045192055,-0.00801941,-0.022759505,-0.03723622,0.044320185,0.041922536,-0.016565576,-0.028372183,-0.07527166,0.008359985,-0.010526043,-0.0067524705,0.0036305315,-0.011443326,0.008128394,0.043775264,0.017818894,-0.020616151,0.021124743,0.03908895,-0.039815508,-0.040796366,-0.018854242,-0.004597765,-0.014894488,-0.010616864,0.007606179,0.0020502626,0.013395958,0.050604932,-0.02097943,-0.017646335,-0.0044683465,0.007778737,-0.029207727,-0.0070521766,0.019780606,-0.011761196,0.018327486,0.0649545,-0.0018708931,0.0041754516,0.044792447,-0.05394711,0.008482592,0.024176298,-0.0062938295,0.016965184,-0.0024634937]
2	G43.900	偏头痛	神经系统疾病	1	[-0.026084138,0.0025789004,-0.031949323,-0.011271271,-0.016133938,-0.0026070084,0.0182514,0.028801236,0.03841414,-0.030394018,0.012030184,-0.013473057,-0.027770612,0.008807144,0.03787072,-0.017839152,-0.002632774,-0.018195186,0.006066623,-0.02981312,-0.018307617,-0.010156324,-0.019563103,0.0024196224,-0.04448545,0.025315855,0.0065116654,-0.015637366,0.046284355,-0.02081859,0.011646043,-0.025090992,0.061162807,-0.021380749,-0.0065959888,-0.0046776244,0.01920707,-0.025072254,-0.03327976,-0.014222601,0.028032953,0.018991577,0.034572724,-0.0005899733,0.0058230213,-0.041037545,-0.012526757,-0.011627304,0.038076844,-0.033017423,0.009172547,-0.038901344,0.036727667,-0.069257885,-0.009893984,0.008540119,-0.02216777,-0.02471622,-0.03479759,-0.034141738,-0.0057714903,0.0021912456,-0.026383955,0.0013444949,-0.008418318,0.09699102,0.009594166,0.010306233,-0.014475572,0.017679874,-0.018626174,0.0035205155,-0.016349433,-0.05036937,-0.04392329,0.030112939,0.0032253824,0.005546627,0.05763995,0.0067224745,0.06730907,-0.022692451,0.016227633,0.024472618,-0.010718482,0.041262407,0.018710498,-0.012611081,-0.044073198,-0.02029391,-0.034160476,-0.0066709435,-0.023666859,-0.044635355,-0.012020815,-0.017885998,-0.043548517,-0.0014358456,0.022804882,0.0010599024,0.0373273,0.022992268,0.026365217,-0.014662959,0.03680262,0.03007546,0.045160037,0.02282362,0.008868045,-0.0004918884,0.012517388,0.022542542,-0.011215055,-0.027452055,0.0010956228,-0.019263286,-0.03464768,-0.054454386,0.01719267,0.01047488,-0.002553135,0.0029091684,-0.020856068,-0.011711628,0.005696536,0.05614086,0.034479033,0.025334595,-0.0045160037,0.03320481,0.04954487,-0.003497092,0.0007606702,-0.025784321,-0.029738165,-0.023198392,0.021418225,0.02003157,0.023348302,-0.045384903,-0.0030825005,0.08634749,0.026796205,-0.031274732,0.005139062,-0.034085523,0.014653589,0.0478584,0.015599889,-0.039538458,0.020256432,-0.0043051946,0.040737726,0.025409548,0.025409548,0.038357925,-0.063036665,0.039276116,0.031930584,0.0038203332,0.04448545,0.04257411,-0.0001420767,0.012395587,0.002015571,-0.059026606,0.03640911,0.061350193,0.011486765,-0.009922091,-0.02297353,0.0082262475,0.00042659606,0.0020448503,0.0024079108,0.014007107,0.039126206,0.0037125861,0.013576119,-0.073267944,-0.018738605,-0.02282362,0.04429806,-0.0044199685,-0.014260079,-0.046022013,0.04163718,0.0023657489,0.0072049936,0.029325917,0.008015438,-0.012198832,0.0073923795,-0.024060369,0.043098792,0.018607434,-0.04875785,0.020856068,-0.01961932,-0.023573166,-0.018429417,-0.005054739,0.0053498717,-0.02565315,-0.015093946,-0.023085961,-0.079976365,-0.008596335,-0.023723073,0.010409295,0.0147472825,0.020931022,0.045234993,-0.005949507,-0.0054341955,-0.0271335,0.006310225,-0.015777905,0.0061041005,-0.024285233,-0.02430397,0.026383955,0.0019043108,-0.017707981,0.014972146,0.022729928,0.02580306,0.018916622,0.012320633,-0.011205685,-0.028913667,0.028707543,-0.026046662,-0.019488148,0.081625365,-0.017080238,-0.002963042,0.004511319,0.010999561,-0.01221757,0.04579715,-0.030600142,0.06802113,0.000282543,0.028295293,0.041337363,0.037383515,0.04216186,-0.01194586,0.023217132,-0.012929637,-0.008437057,-0.03196806,-0.017764198,0.05452934,0.022055337,0.0040381695,0.0017473749,0.0035205155,0.0017227805,0.0106060505,0.053704843,0.036202986,0.034066785,-0.00919597,0.017098976,-0.0072237323,0.036165506,0.031199777,-0.0075844503,-0.010624789,-0.014391249,-0.016499342,-0.017773567,0.0060525695,-0.02861385,0.01920707,-0.026421433,0.02445388,-0.022336418,0.021811737,0.034085523,0.016499342,0.058914173,-0.00141008,0.027039807,-0.035921905,-0.01866365,-0.014166385,-0.0075235497,0.02094976,-0.016986545,0.060675602,0.004872037,-0.024660004,0.0120582925,-0.010952715,-0.15620501,-0.02458505,0.013772875,0.03035654,-0.0041131238,0.0038718642,-0.018232662,-0.049282532,-0.08155041,-0.031799413,0.016087092,-0.0370837,0.0072705788,-0.024116585,0.017220778,0.017239517,-0.0024008837,-0.056515634,-0.0006230586,-0.046696603,-0.006624097,0.030319063,-0.007495442,-0.0048017674,-0.024341447,0.0069801304,0.051793505,-0.04793335,-0.01679916,-0.02068742,0.0026725936,0.014278817,-0.027208455,0.019029053,0.009238132,-0.016030876,-0.017698612,0.022317678,0.021811737,0.00611347,0.049282532,0.06982004,0.0030262847,-0.021474442,0.0026655665,-0.031143561,-0.015281333,-0.034197953,0.012245678,-0.03320481,0.07825241,-0.00014968925,0.050706666,0.022486325,-0.0112244245,0.0051531163,0.018982207,0.047296237,-0.041562226,-0.020799851,-0.010521727,-0.12315011,0.03787072,0.0124705415,-0.016349433,0.00859165,-0.0101938015,0.0020682735,0.0059120297,-0.012039553,0.01746438,-0.012601712,-0.0032417786,-0.016358802,0.03022537,-0.001147154,0.052692957,0.025615674,0.007851476,-0.1136309,-0.043623473,0.026590081,-0.0021572819,0.020181477,-0.024772435,-0.032324094,0.009697228,0.05089405,-0.0072049936,0.27913025,0.09002026,0.030899959,-0.073830105,0.026402695,-0.01774546,-0.040625297,-0.006015092,0.005555996,-0.018082753,-0.025859274,0.021024715,0.011655413,-0.00069508515,0.0017953926,0.07176886,-0.07735296,-0.005734013,0.07589135,-0.012030184,-0.0292697,0.00015678942,0.034591466,0.016977176,0.01840131,-0.054229524,-0.020144,0.06352387,-0.007870214,0.016967807,-0.019769229,-0.0043871757,0.0069660763,0.034535248,-0.017117716,-0.0072752633,-0.04403572,-0.053929705,-0.00011067488,-0.03183689,0.0024875498,-0.022074077,-0.018588696,0.014335033,0.006047885,-0.0039819535,0.025671888,0.048682895,-0.014897191,-0.0072705788,-0.005673113,-0.0365028,0.001554133,-0.012423695,-0.0024664688,-0.01262982,-0.040213045,-0.032455266,-0.016152678,0.029494565,0.012283156,0.02698359,-0.025971707,-0.024678743,-0.009552004,0.029850598,0.0130327,0.05224323,-0.014588004,0.03157455,0.011177578,-0.033954352,0.00017128256,-0.0055138343,0.014250709,0.0015494484,-0.005757436,0.026234047,-0.0044293376,0.00085787673,-0.00712067,-0.003979611,-0.020069046,-0.064011075,-0.008788406,0.025090992,0.0071815704,0.018869774,-0.002611693,-0.013913414,-0.0026866475,-0.0068817525,-0.054454386,0.033766966,-0.017248886,-0.00966912,0.036990006,-0.013313779,-0.007898322,0.0030731312,0.04418563,-0.0059167147,-0.029794382,0.0119646,0.019544365,-0.07847728,-0.013210717,-0.0027733136,-0.049619827,-0.018157708,-0.043848336,0.031612027,-0.019787967,-0.025465764,0.026140355,0.021118408,-0.028857451,0.038901344,0.0124705415,-0.0077156206,0.00523744,0.013107654,0.009299032,0.071618944,0.006258694,-0.0026749359,-0.0016771051,0.0017754828,-0.08042609,0.029213484,0.02391046,-0.018148338,-0.0787771,0.005738698,0.023460733,-0.008301202,-0.017811043,0.030468972,0.0011407125,0.038208015,0.034722634,-0.034141738,-0.004682309,0.0019464726,0.008465164,-0.066934295,-0.005682482,-0.018776082,-0.027583227,0.0049750996,0.032099232,0.051643595,0.017080238,-0.039688364,0.0137072895,-0.052543048,-0.054491863,-0.039313592,0.047671013,-0.016452495,0.021305794,0.019122746,0.0478584,0.029625734,0.005926084,0.04137484,-0.047446147,0.022804882,0.04984469,-0.014831605,-0.008685343,-0.030281585,-0.012657927,0.026084138,-0.012245678,0.020612465,0.016012138,0.016077723,0.01141181,0.053030252,-0.0078139985,-0.0008403093,-0.02336704,0.04137484,0.06431089,0.022055337,-0.021287056,-0.0131919775,-0.029232224,-0.03867648,-0.039575934,0.09519211,0.00103238,-0.021568134,0.04444797,0.016967807,0.048458032,0.004853299,0.008244986,-0.018101493,-0.0019171935,-0.0074251723,0.011664782,0.028688803,-0.013388733,-0.010109478,-0.06273685,-0.0105029885,-0.00080751674,0.04321122,-0.009388041,-0.0241728,-0.01893536,-0.01732384,-0.02657134,0.01732384,0.061687488,0.026084138,-0.07221858,-0.0072986865,0.024060369,-0.008882099,0.006417972,-0.072968125,-0.01679916,0.03987575,-0.023591904,-0.00825904,0.03144338,0.03749595,0.004345014,-0.06648457,-0.0057527516,-0.020912282,0.022392632,-0.021699304,0.0049001453,-0.0061556315,0.022804882,0.012198832,0.018195186,-0.039013777,0.051718548,-0.020743636,0.021193363,0.0016080065,-0.013716659,-0.0564032,0.01569358,-0.012077031,0.005064108,0.011486765,0.0077249897,-0.056365725,-0.039500978,0.047483623,0.002280254,0.0041131238,-0.01667736,0.06685934,-0.008451111,0.03787072,-0.0060291463,0.01692096,-0.0025039462,-0.018701127,0.020181477,0.0075797657,-0.0015927814,-0.0754791,-0.017567443,-0.015524934,-0.008928945,-0.05250557,0.024341447,-0.0018996261,-0.0550915,0.03639037,0.038489096,-0.026421433,-0.00994083,0.023648119,-0.00032851117,0.09309339,0.011402441,0.056215815,0.047221284,-0.019282024,-0.024378926,0.02027517,0.024154061,-0.037271086,-0.025409548,0.027751874,-0.023460733,0.007209678,-0.02996303,0.024060369,-0.033617057,0.01168352,-0.02739584,0.01973175,-0.06573503,-0.060675602,-0.014250709,-0.015103316,0.0047174436,0.001154181,-0.034048047,-0.007837421,0.003279256,0.00564032,-0.016986545,0.0042419517,0.003935107,-0.023029745,0.009430203,-0.019975353,-0.019282024,0.027845567,-0.011852168,0.003487723,0.0014569266,-0.06524782,-0.007495442,-0.008352733,0.02580306,0.0092662405,-0.04163718,-0.030412756,-0.020743636,0.01852311,0.0034900652,-0.048195694,0.030899959,0.01813897,0.0071487776,-0.009270925,-0.01866365,-0.0032675443,0.034347862,-0.02404163,0.028576372,-0.0056871665,-0.029606996,-0.0027100707,0.0030942122,-0.010559204,0.003705559,0.023835506,0.029176008,0.003028627,-0.008479219,-0.019188331,-0.008184086,-0.009303717,-0.012826575,-0.012273787,0.035697043,-0.03277382,-0.025165947,-0.018485634,-0.009032007,0.014990884,0.018288879,-0.02510973,0.0014639535,-0.043998245,-0.02915727,-0.012817206,-0.027377103,0.027170977,-0.014653589,0.013941522,-0.021287056,-0.01797969,0.010718482,0.01181469,0.015880968,-0.032979943,-0.010146955,0.0051905937,-0.055803567,-0.034010567,0.02645891,0.002036652,-0.030187892,-0.03599686,0.063898645,0.03384192,-0.0007401749,0.0065866197,-0.02389172,-0.011580458,-0.15133297,-0.03717739,-0.021661827,-0.029082315,-0.04448545,-0.012292525,0.019787967,-0.0071909395,0.001971067,0.009036692,0.03048771,0.04257411,0.018598065,-0.0012508018,-0.0069379685,0.040887635,0.008605705,-0.020500034,-0.049732257,0.049769733,-0.006689682,-0.01034371,0.04392329,0.033523366,0.011927122,-5.797256e-05,-0.047221284,0.026234047,-0.030562665,0.07206868,0.0028365564,-0.053180162,0.029625734,0.033467147,0.051793505,0.02940087,0.012133246,-0.0008420661,0.018879145,-0.043585993,0.025746843,0.022074077,0.003035654,-0.003466642,-0.02216777,0.052618004,-0.01732384,-0.0026515126,-0.0016080065,-0.057415087,-0.002597639,0.047745965,-0.005776175,0.024285233,-0.026946114,-0.010849652,0.0121613545,-0.022486325,0.045609765,0.036915053,0.012920268,-0.015346917,-0.04403572,-0.010634159,-0.038976297,-0.017417533,-0.030525187,0.037439734,-0.008980476,0.005078162,-0.01732384,-0.037364777,0.042086907,-0.012198832,0.008343364,0.015899707,0.030300325,-0.031237254,-0.032043014,-0.022336418,-0.0032113285,0.009280294,-0.025184685,-0.020893544,0.013754136,0.016190154,-0.018907253,-0.027339624,-0.00061895954,-0.027470795,-0.048795328,-0.051568642,0.0008063456,-0.038114324,-0.032099232,-0.037027482,-0.0067458977,-0.041712135,-0.029457087,-0.012639189,0.0103999255,-0.019010315,-0.004914199,-0.014672328,-0.028913667,-0.034835067,0.031368423,0.0047174436,0.007837421,0.028670065,-0.015197009,0.014269448,-0.0032862828,0.038058106,-0.008526065,0.015553042,0.0026702513,0.04381086,0.014025846,0.0349475,-0.017895367,-0.024866128,-0.008905522,-0.023704335,-0.008184086,0.003986638,0.02445388,0.026046662,0.038357925,-0.0025414233,0.037139915,-0.07457965,-0.0039725844,0.016714836,-0.016621143,0.0360156,-0.020406341,0.030787528,-0.027845567,-0.0054435646,0.010062631,0.0020694446,-0.007092562,-0.023872983,-0.0432487,-0.0016244028,0.022092815,0.01961932,-0.064011075,-0.007776521,0.04096259,-0.014766021,-0.034853805,0.025896752,-0.009017954,-0.022392632,-0.028295293,0.029363394,0.038639,0.028707543,0.029026099,-0.053704843,-0.011674151,0.042611588,-0.0067458977,0.047521103,0.0021408857,0.0050266306,-0.0022111554,-0.008774351,-0.020518772,-0.00779526,-0.028801236,0.015674843,0.020724896,-0.0041037546,-0.0066287816,0.0039960076,0.00271944,-0.017436272,0.031724457,0.04396077,-0.008024808,-0.016883483,0.039051253,-0.015909076,0.01771735,-0.0130889155,-0.012835944,-0.035415962,-0.045347422,-0.015946552,0.020106522,0.028295293,0.008165347,0.038339186,-0.012573604,-0.015318809,-0.022280201,0.052992776,0.021586873,-0.020968499,-0.01852311,-0.045309946,-0.050069552,0.03260517,-0.012770359,-0.00994083,-0.022617497,0.017342579,0.01893536,-0.01181469,-0.0058792373,0.014681697,0.027976736,-0.03421669,-0.03824549,0.012423695,0.013782244,-0.05333007,-0.021849213,0.032942466,-0.033504624,-0.0070831925,0.0394635,0.002208813,0.032830037,0.030656358,0.00436141,-0.0044551035,-0.028314032,-0.00036745233,-0.008839937,0.0014885479,-0.03923864,-0.009950199,0.032043014,0.0077812057,-0.052018367,0.023404518,-0.009903353,-0.013416841,-0.027245931,-0.01156172]
3	G47.000	失眠症	神经系统疾病	1	[0.042972203,0.015481012,-0.028225759,-0.073126204,-0.0318986,0.010283946,0.03900554,0.0156095615,0.009696292,-0.023561256,0.003094366,-0.00068463996,-0.025544588,-0.0004163506,0.042641647,-0.031751685,0.0037325216,-0.027729927,-0.0298969,-0.020751534,0.0050042416,0.005904087,0.05325615,0.015765658,0.006973801,0.025562951,0.009159139,-0.016188033,0.023267427,0.0004883727,-0.025875144,-0.039556466,0.043853685,-0.069453366,-0.046718497,-0.0145536205,-0.0007385847,-0.030154,-0.057700284,0.059499975,0.01727152,0.025801687,0.012331554,-0.017032785,0.026683167,-0.063576825,0.005894905,-0.015774839,-0.01972314,-0.0046667997,-0.01354359,-0.006193323,0.058508307,-0.0054679373,-0.026352612,0.0143791605,0.0071253055,0.008135336,-0.03397375,-0.060014173,-0.007106941,0.020843355,-0.024369279,-0.018024452,0.028684864,0.06611108,0.0410256,0.038491342,-0.017152153,-0.048738558,-0.025012026,0.015058636,0.03678347,0.013837417,-0.061226208,0.021320824,0.0146362595,0.0009331304,0.0060923197,0.011854084,0.041099057,-0.012074455,-0.039042268,0.04895893,-0.018465193,0.02484675,0.0070380755,0.004148011,0.0075017717,-0.040401217,0.016720595,-0.004145716,-0.0051649283,-0.05553331,-0.012175458,-0.014966815,0.0036980887,-0.029456161,0.04921603,-0.0035741304,0.021467738,0.021706471,0.013433404,-0.033129,0.032724988,-0.0067304755,-0.0326148,0.011532711,0.011358251,0.023157243,0.024773292,0.007157443,0.020329159,-0.0041043963,-0.0009032886,-0.0074879983,0.0063631916,-0.04198054,-0.0015311143,-0.009806477,0.026003692,0.00872299,-0.016996058,-0.027674833,-0.015223913,0.0038518887,-0.011927541,-0.0095401965,-0.028739957,0.0012900843,0.0073319026,-0.012285643,-0.030558012,-0.034432855,-0.007951695,0.0171797,0.029143969,-0.0072033536,-0.00021979639,-0.046277758,0.0064228754,-0.017262338,-0.004444134,-0.036856927,0.016151305,-0.01937422,0.024828384,0.008603623,0.0031448675,0.013157941,0.014617895,-0.0026283746,-0.052668497,0.044367883,-0.01590339,0.045286093,-0.010449224,0.045653377,-0.007469634,-0.028042117,-0.0061520035,0.005513848,-0.009769749,-0.004597934,0.0015196367,-0.008364888,0.008621987,0.03511233,-0.003036978,0.015481012,-0.033808473,-0.025085483,0.031678226,-0.0016252308,-0.02455292,0.0028074256,0.030704925,0.02392854,0.014443435,-0.023744898,-0.014324068,0.018933479,-0.017583711,-0.08388762,-0.007377813,-0.0244611,-0.029786715,0.04800399,0.025746593,0.023285793,-0.026279155,-0.020200608,-0.011936723,-0.031366035,0.03397375,-0.032633167,-0.00034404162,0.0010111782,0.0013623933,-0.0190253,0.0066432455,-0.0030277958,0.031880233,0.009696292,-0.036361095,0.0043683816,-0.04583702,-0.027234092,-0.030686561,-0.004811418,0.019759867,0.02139428,-0.027895205,0.026774988,-0.0029107241,-0.0437435,0.006496332,-0.02357962,-0.014792355,-0.051493187,0.04686541,0.050207693,0.00015078721,-0.05795738,0.049326215,0.025140576,0.07154688,0.010182943,0.0064504216,0.028997056,-0.046314485,-0.015526922,-0.023616347,-0.014057787,0.070959225,0.02958471,0.017087879,-0.0030461599,0.028372673,-0.013185488,-0.044588253,-0.010926693,0.032798443,-0.02572823,-0.014700534,-0.018153,0.029529616,-0.014874994,-0.031476222,0.021761565,-0.0048022354,-0.021835022,-0.049142573,0.03160477,-0.0020280953,-0.015315734,0.009154549,0.0063953293,0.032357704,-0.0065238783,0.007648685,0.048224363,0.02152283,0.025342582,0.0058489945,0.009025999,-0.0078093717,0.014443435,0.009448376,0.015150457,-0.03375338,-0.027840111,-0.003840411,0.02301033,0.020274065,-0.04396387,-0.004327062,-0.032908626,0.035516344,-0.008649534,0.0016137531,-0.038491342,0.006982983,0.0031793003,0.0070334845,-0.006083138,0.03801387,-0.028905235,0.00060946157,-0.029107241,0.014094516,0.012102001,0.056818802,0.021541195,0.03182514,0.056341335,0.014002695,-0.13824561,0.033606466,0.018079545,0.058214482,0.004361495,-0.0036475873,-0.027032087,0.011404161,-0.04984041,0.0064458307,0.036232546,-0.056157693,0.026995359,-0.0019075802,-0.026242428,0.020696443,0.006771795,-0.021449374,-0.008539348,-0.041649982,-0.024057088,-0.010945057,0.026976995,0.0017090174,0.010715504,-0.023506163,0.05703917,0.0072079445,-0.042898748,-0.016224762,-0.0016103099,-0.0031104346,-0.016766505,0.029199062,-0.0022002594,-0.021816658,0.029033784,0.0031310944,0.0042857425,-0.0015024203,0.010917511,0.0410256,0.0035075601,0.017969359,0.012928389,0.008121563,-0.027546285,-0.0025778732,-0.023065422,-0.031053845,0.02888687,0.005527621,-0.021467738,0.033202454,0.013975148,0.03180678,0.033698287,0.019870054,0.049473125,0.007970058,-0.029603073,-0.08116972,0.0054633464,0.041539796,-0.021504465,-0.0038932082,-0.008296022,0.004811418,0.020531164,-0.012083637,0.030466191,-0.023946904,-0.007855282,-0.014002695,0.038564797,0.012368281,-0.025562951,-0.066037625,-0.008442936,-0.08396108,-0.019612955,0.022294126,-0.0058857226,0.025012026,-0.04616757,-0.01748271,-0.018198911,0.011275613,-0.0016470383,0.27884185,0.03489196,-0.0032550525,-0.0326148,0.016555317,-0.018639652,0.01494845,0.022330854,-0.020935176,-0.014415889,-0.076982684,-0.014783173,0.028648136,0.0063356454,0.007460452,0.04759998,-0.025948599,-0.024406008,0.08910305,-0.002704127,-0.040915415,-0.02266141,0.03783023,-0.04036449,-0.004565797,-0.0669191,-0.008525575,0.04715924,0.0063356454,-0.01880493,-0.0491793,-0.002993363,0.024038725,-0.08197774,-0.012331554,0.037187483,-0.051272817,-0.029217426,-0.009953391,-0.021320824,-0.027509555,0.007919556,-0.0032114377,0.06258516,0.020053696,-0.025618045,0.006482559,0.030760018,0.004806827,-0.031182393,-0.009870752,-0.03480014,-0.0066111083,0.009898298,-0.016904237,-0.032192424,-0.033073906,-0.0027890613,-0.0070977593,0.026279155,0.04668177,0.03375338,-0.08454873,0.007621139,0.02481002,0.063723736,-0.02888687,0.017436799,0.030154,0.040217575,0.02537931,-0.01227646,-0.01008194,0.020402614,-0.0009296871,0.028795049,-0.016702231,0.029529616,0.032761715,0.009632017,0.009062728,-0.00020128874,-0.008787265,-0.11488637,0.008341933,0.035938717,0.018474374,0.013268127,-0.030043814,-0.04506572,0.03511233,0.021926843,-0.015719747,0.026150607,-0.0432293,0.00955856,0.06008763,0.0011362842,-0.00929228,0.08197774,-0.002708718,-0.01166126,0.00440511,0.006174959,-0.015664654,-0.016931783,0.053733617,0.004531364,-0.0044257697,-0.00088262884,-0.020678077,0.015178002,0.053586707,-0.05641479,-0.013534408,-0.004014871,-0.059095964,-0.0027362641,0.045396276,-0.029217426,0.002178452,0.00011872162,-0.052815408,0.029694894,-0.03239443,0.016178852,0.011018514,-0.02559968,-0.0013945306,0.024130546,0.023726532,-0.027987026,-0.022147212,0.023102151,0.03760986,0.01915385,0.012652927,0.019135486,0.10511662,-0.006404511,0.02765647,0.0030323868,0.01727152,0.011523529,0.01643595,0.030962024,-0.054504916,-0.02708718,-0.022955237,0.013855781,0.0024837567,0.008433754,0.044882078,-0.019098757,-0.02042098,-0.07639503,-0.038895354,-0.047306154,0.03751804,-0.025691502,0.030833473,0.034598134,-0.0043729725,0.075293176,0.0006220869,0.045212634,-0.035020508,0.031972054,-0.020531164,0.015582015,0.025342582,0.025416039,-0.05079535,-0.0045084087,0.021688107,-0.0464614,-0.054504916,0.028941963,-0.019888418,0.009852388,0.011413344,-0.0050042416,0.013203852,0.0030002494,0.029639803,0.05986726,-0.009301462,0.0026214882,-0.0023552072,-0.0370773,-0.03527761,0.07734997,-0.00047488647,-0.0067626126,0.007850691,-0.0065192874,0.034028843,0.04826109,0.06644164,-0.018483557,0.07977404,-0.046130843,0.04014412,0.029731624,-0.017859174,-0.028501222,-0.002313888,-0.022422675,0.0039414144,0.009163731,-0.0051236087,-0.0128824795,-0.04624103,-0.0029313837,0.0074145417,0.027068816,0.007818554,-0.0029818853,-0.042715106,-0.0432293,0.0343594,-0.019098757,0.032596435,-0.10173761,-0.023193972,-0.024993662,-0.01512291,-0.038564797,0.072354905,0.04392714,0.0048894654,-0.0004545137,0.014801537,-0.027381007,-0.009705475,0.027821748,-0.0059499973,-0.01582075,-0.009393283,0.00019928016,0.005798493,-0.04513918,-0.0020923698,-0.008080243,-0.0035580618,-0.030649832,-0.04300893,0.0029244972,0.0058214483,0.04007066,-0.03426758,0.05777374,0.0432293,-0.011330705,-0.0021945206,0.015242278,0.0056699435,-0.041576527,-0.027013723,-0.0012223664,-0.00047287787,0.04939967,-0.01178981,-0.007194171,-0.05843485,-0.037352763,0.038674984,0.02582005,0.005233794,-0.050244424,-0.008116972,-0.018951844,-0.06346664,-0.015049454,0.04176017,-0.023175607,-0.04804072,0.039336093,0.050281152,0.0016034233,0.015940117,0.0066983383,0.011753081,0.016004391,-0.0113031585,0.009159139,0.020806627,0.05325615,0.00907191,-0.02537931,-0.025985328,-0.013075303,-0.060454912,0.022936873,0.004047008,0.012129547,-0.025140576,0.04785708,-0.008649534,0.037536405,-0.041539796,0.04238455,-0.019704776,-0.019631319,-0.016417585,-0.040658318,-0.00135895,-0.023873447,0.02042098,0.015885023,-0.025030391,-0.02332252,0.009012226,-0.025360946,0.02196357,0.008585258,0.01595848,-0.05509257,0.034616496,0.017822446,-0.025673138,0.0018582265,-0.016849143,0.0063586007,0.0177949,0.016463496,-0.054541644,0.009521833,-0.007465043,-0.03239443,-0.015031089,-0.006101502,-0.016206397,-0.009370328,-0.01131234,0.005119018,-0.021779928,-0.026187334,0.01946604,-0.015673837,-0.0059362245,0.013479315,0.03024582,-0.055239484,0.027032087,0.043633316,-0.030356005,0.0069692098,0.017455162,0.016637955,0.07305275,0.018134637,0.031861868,-0.018079545,0.040033933,0.06747003,-0.026536254,-0.031274214,0.02064135,-0.0032688258,-0.02550786,0.043780226,-0.021504465,0.019080393,-0.047710165,0.03992375,0.02354289,-0.018033635,0.016087031,-0.007175807,-0.027638106,0.014489345,0.021118818,-0.016821597,-0.05395399,0.035644893,-0.004719597,-0.016977694,-0.0066340636,0.03874844,-0.027325913,-0.046791956,-0.032761715,-0.05002405,0.018676382,-0.035442885,-0.03191696,-0.012377464,0.029290883,-0.027803384,-0.002279455,0.013084485,-0.04209072,-0.01240501,-0.13405858,-0.0072033536,0.030300913,-0.016821597,-0.033955388,-0.0012659814,-0.024865113,0.0110368775,0.00037101403,-0.034120664,-0.04422097,-0.0048022354,0.03199042,-0.031861868,-0.030888567,-0.014654623,0.005031788,0.012708019,0.009214232,0.078525275,0.0010220819,0.0075430907,0.10423514,0.007924148,0.005114427,-0.029951993,-0.015793202,-0.045175906,-0.033790108,0.030447826,-0.0051787016,-0.029125605,0.011753081,0.00925096,-0.00762573,-0.004962922,-0.0229736,0.008250112,0.034010477,0.009521833,0.0067580217,0.016077848,0.014920904,-0.019484404,0.009301462,0.03944628,0.002568691,-0.0022255103,0.013359948,-0.0022874894,-0.024828384,0.0050593344,-0.034506314,0.047416337,-0.027950296,-0.011771445,-0.03142113,-0.01275393,-0.0045290682,-0.010678777,0.0070885774,-0.03529597,-0.0054771197,-0.03524088,-0.019870054,0.06886571,-0.047269423,0.02582005,-0.025012026,0.02642607,-0.010990967,-0.026224062,0.022422675,-0.06335645,-0.011413344,0.030962024,-0.0010479066,-0.02016388,-0.032449525,-0.025030391,-0.008185837,0.022496132,0.055386394,-0.020310793,-0.03024582,0.020329159,-0.017647985,0.02266141,-0.019429313,0.026315883,-0.054908928,-0.037866957,0.049362943,0.047232695,-0.028703228,-0.00088951545,-0.004086032,0.0025273715,-0.07007775,0.00089410646,-0.042053994,-0.079920955,-0.005169519,-0.05050152,-0.027913569,0.020549528,-0.021504465,-0.009531015,0.0011672738,-0.011367434,-0.010660412,-0.010926693,0.0047333697,0.01911712,-0.020696443,0.017629622,-0.034304306,0.012652927,-0.024424372,0.03208224,0.02222067,-0.0051603373,-0.016665502,-0.034212485,0.019264035,0.030356005,0.031568043,0.0070931683,0.046718497,0.05031788,0.02673826,-0.048150904,-0.016775686,-0.0025916463,0.0016791755,0.032908626,-0.006592744,0.032412793,-0.0032412794,-0.04168671,-0.0022335446,0.0037945006,0.01994351,-0.013167124,-0.0026214882,-0.025397675,-0.004322471,-0.0056056688,-0.009113229,-0.024626378,0.033092268,-0.014608713,0.015967663,-0.012726383,-0.009264734,0.011798992,-0.0011454663,-0.0004651305,0.07316293,0.018051999,0.00059109734,-0.035644893,-0.0165645,0.009411647,-0.003991916,0.046387944,0.031072209,0.0044165878,-0.033698287,-0.0031747094,0.021981934,0.011238884,-0.0052980687,0.009696292,0.006285144,0.010541045,0.032284245,-0.0099809375,0.025764959,-0.02367144,0.007263037,0.0019466041,-0.0032642346,0.03344119,0.006780977,0.035828535,0.012340736,0.024442736,0.010173761,-0.029915266,0.027068816,-0.026058786,-0.01814382,0.009273916,0.07099596,0.047453064,0.04785708,-0.008837766,-0.022606317,0.016087031,-0.06324627,-0.042017266,0.0029130196,-0.023818353,-0.014324068,0.034469582,-0.01880493,0.011817356,-0.0052429764,0.004926194,-0.0407685,-0.02897869,0.03801387,0.009769749,0.016077848,-0.020971905,-0.0044211787,-0.009140776,0.02642607,0.001233844,0.0060326364,0.02165138,-0.030135635,0.011404161,0.02187175,0.018566195,-0.002616897,0.017721443,-0.05457837,0.00029038376,-0.025048755,-0.031145666,-0.03988702,0.007841509,0.044551525,-0.0412827,0.009003044,0.010412496,-0.01183572,0.024001995,0.018134637,-0.04693887,-0.017170517,-0.0328719]
4	I63.900	脑梗死	脑血管疾病	1	[0.011871016,0.008206606,-0.0025033168,-0.041390646,-0.04127918,-0.0039964826,0.031117296,0.007941877,0.014927013,-0.016190283,0.0055453805,-0.0145275965,0.052351367,0.036077484,0.041873664,-0.024745217,-0.015549359,-0.009205146,-0.010069,0.0008650144,-0.0040568593,-0.008647822,-0.052239902,0.0069294036,0.01850318,0.012911355,0.010561303,-0.023519102,0.0024336511,-0.019729294,0.026993092,-0.0038455403,-0.030467084,-0.0458864,0.008573512,-0.020713901,0.006581076,-0.0044841417,-0.053837564,0.045514848,0.015149943,0.05060508,0.036876317,0.0020876455,0.020509548,-0.0356502,0.032975044,-0.04146496,0.036616232,-0.030318463,-0.0017880833,-0.01849389,0.0039732605,-0.02664012,0.03388534,0.007895433,-0.054134805,0.036449034,-0.07360402,-0.04402865,-0.022385875,0.014462575,0.006172371,-0.012772025,0.023853498,0.094447955,0.036393303,0.009911091,-0.0008243761,0.009270167,-0.014351111,0.027104558,0.019302012,0.014462575,-0.039681517,0.02175424,0.08248405,-0.02864649,0.008968283,0.0061259274,0.082335435,-0.022980355,0.025172498,0.015001323,-0.05231421,0.047892768,0.012539806,0.006483544,0.0043331995,-0.059076417,0.0017613783,0.020658169,0.006906182,0.0053688944,0.017648615,-0.04700105,-0.019877914,-0.024485132,0.0024011405,0.0027750125,0.053949032,0.04358279,0.017128445,-0.028906574,-0.031247338,-0.012632693,0.03115445,0.009497741,-0.008090497,-0.004649017,-0.013431525,0.038752645,-0.0008679171,0.028070588,0.0011396129,-0.03217621,-0.02716029,-0.027197445,-0.024875259,-0.0019099981,-0.017852968,0.042430986,-0.00977176,-0.0018159496,0.0014118892,-0.043322705,0.019116238,-0.027940545,0.030745745,0.009154058,0.019302012,0.046889585,-0.028962307,-0.011211515,-0.0056940005,-0.048561558,0.018753976,-0.012242566,0.0021747274,-0.067956455,-0.0012539806,0.014118892,0.0019332201,0.015707267,-0.019952225,-0.04581209,0.010152598,0.06450105,0.035483006,-0.0046559833,-0.0030861855,-0.012911355,-0.02123407,0.07579616,-0.041353494,0.01169453,-0.042059436,0.037136402,-0.02063959,0.009163347,-0.01598593,0.0030234864,-0.019116238,0.0016313358,0.008132296,-0.048004232,0.080997854,0.036820583,-0.019747872,0.017091291,-0.027921967,-0.043322705,0.039458588,0.011462311,0.018986195,0.0020179797,0.02708598,0.0031395957,0.004400543,-0.024225047,0.0017311898,-0.0124283405,0.01976645,0.03137738,-0.016004506,0.04127918,-0.018884018,0.0050530774,0.010988586,0.022404453,-0.022906044,-0.023351904,-0.028887996,0.001384023,0.030652858,-0.051311027,0.018753976,0.010561303,-0.050790858,0.051979817,-0.040090222,0.026082795,-0.015744423,-0.026064219,-0.027438952,0.0038989508,0.028832264,-0.017342087,-0.01866109,-0.012744158,0.016756896,0.0027355354,0.0002285902,-0.029705405,-0.029073771,-0.024968145,-0.018921174,-0.050902322,0.0034925682,-0.02160562,-0.009585985,0.045997865,0.004853369,-0.061231405,0.052983,-0.0045212964,-0.012010347,0.0071802,0.002679803,-0.03492568,-0.053688947,0.024447976,-0.03204617,-0.028386405,0.06554139,0.022218678,-0.009892513,0.022404453,0.010737789,-0.017054135,-0.0016115973,-0.021717086,0.05060508,0.025878442,0.0074913725,-0.014026005,0.01162022,0.011016452,-0.009335188,0.019952225,0.025488315,-0.012391185,-0.051348183,0.011369424,-0.00069085043,0.0072730873,0.010598458,0.0027494684,0.021661352,0.021252649,0.024522286,0.050939478,0.040684704,0.040276,0.0067761396,-0.013087842,0.027364643,0.017778657,0.015623669,-0.020398084,-0.0029096992,-0.0139145395,-0.032659225,0.012902067,0.015809445,-0.033699565,-0.0016185638,-0.002295481,0.015883753,0.011406579,0.031693198,-0.018029453,-0.0002079808,0.021196917,0.046035018,-0.009576696,-0.059113573,-0.022664538,-0.025265386,0.004105625,-0.00518312,0.065764315,0.057627372,0.012539806,-0.052202746,0.033272285,-0.006186304,-0.14728233,-0.0009015888,-0.04544054,0.055769626,-0.011926749,0.012168256,-0.0075378167,-0.026677275,-0.0052852957,0.00257066,0.027438952,-0.033811033,0.0021909827,0.008559578,0.044065807,-0.029835448,0.01139729,-0.06669319,-0.011871016,-0.029426744,-0.039161347,0.035724513,0.010737789,-0.037043516,-0.026064219,0.00925159,0.022590227,-0.009107614,-0.0071523334,-0.008554934,-0.06208597,-0.039309967,-0.0151127875,0.04417727,-0.0021294449,-0.014704083,0.017286355,0.008926484,0.004168324,-0.013301482,0.028107742,0.09964965,-0.017481418,0.039309967,0.0008394703,-0.029073771,0.014276801,-0.034498397,0.063906565,0.005113454,-0.010774944,-0.005485004,0.0018229162,0.0033276929,0.015168521,0.013050687,0.035557315,0.004923035,-0.0026287148,0.015930198,-0.0007454218,-0.082632676,-0.010914275,0.059633743,0.016413212,0.07631633,0.0082391165,0.003093152,0.07401272,-0.015298563,0.007974387,0.0032231945,-0.0010200203,-0.008972928,-0.016896227,-0.009126192,-0.0018983872,-0.027494686,-0.022404453,-0.11035029,-0.05328024,0.027494686,0.019877914,0.030132689,-0.016376058,-0.075759,0.026658697,-0.018373137,0.057367288,0.24433115,-0.014861992,-0.0059262193,0.001771828,0.018763265,-0.02316613,0.01813163,0.0042960444,-0.015679402,-0.012669848,-0.0077328803,-0.016413212,-0.015642246,0.01139729,-0.014397554,0.037247866,-0.032677803,0.0022362652,0.08122078,-0.025153922,0.007384552,0.012846334,0.05766453,-0.01568869,0.007045513,-0.053094465,-0.007672503,0.04425158,0.0007320692,0.0034229024,-0.012233277,-0.028869418,0.03886411,-0.054506354,-0.017676482,0.043545637,-0.047595527,-0.008090497,-0.028943729,0.005749733,-0.0039732605,-0.02153131,-0.046666656,0.035334386,0.050902322,-0.0052063414,-0.025488315,0.00014709598,0.009056526,-0.039198503,0.014750527,0.0279777,0.0051784753,-0.021884283,0.0019970802,0.00821125,0.0059540854,-0.009669583,-0.0352415,0.004154391,0.051756885,0.033848185,-0.043136932,-0.014945591,-0.028590757,-0.029036617,-0.021289803,0.001521032,-0.016905516,0.054506354,0.02418789,0.0030211643,-0.0043680323,0.072415054,0.024280779,0.0139145395,0.021940015,0.07958597,0.051868353,-0.006474255,-0.0022641316,-0.021512734,-0.007296309,-0.043099776,0.018791132,-0.02398354,0.0006258292,0.017369952,0.0046652723,-0.012066079,0.0056522014,0.0150199,-0.04477175,-0.004451631,-0.012391185,0.0025660158,0.017072713,-0.016227437,-0.05952228,0.022961777,-0.044288736,-0.03633757,-0.008123008,0.003244094,0.014490442,0.007444929,-0.041427802,0.0044702087,-0.023649145,-0.0059401523,0.026900206,-0.0061305715,0.0121403895,-0.022534495,-0.025674092,0.0028470003,-0.04402865,0.012391185,0.034442667,0.041353494,-0.050344996,0.00053700554,-0.020082267,0.045403384,0.009892513,-0.015549359,0.0017811168,-0.036226105,-0.041873664,0.02951963,-0.022831734,-0.02049097,-0.040387463,0.016543254,0.04358279,5.4281103e-05,0.045329075,0.047744147,0.09221866,-0.0121403895,0.003278927,0.029723983,-0.036374725,0.016450368,0.014081737,-0.02812632,0.0062652584,-0.080180444,-0.011601643,-0.026528655,0.0031210182,0.022330143,0.025339697,-0.050828014,-0.0006084128,-0.062866226,-0.02820063,-0.012846334,0.018818997,-0.044883214,0.010886409,0.012530517,0.044734593,0.0054199826,0.0028237784,0.029389588,0.021977171,0.051050942,0.022906044,0.024095004,-0.012409763,0.019952225,-0.061454337,-0.011192937,-0.017434973,0.043954343,-0.011127916,0.012084657,-0.0089868605,0.030392773,0.01619957,0.0021004174,0.012019636,0.06022822,-0.0069433367,0.041539267,0.050828014,-0.013580145,0.013162152,-0.020695323,-0.0671762,0.079140104,-0.016385347,-0.02309182,0.04923035,0.007017647,-0.02331475,0.022014325,-0.006320991,0.0023546969,0.032454874,-0.0040568593,0.0035808112,-0.0044307313,-0.010412683,0.013710188,0.05253714,-0.043434173,0.008071919,0.032231946,0.011508754,0.0077050137,-0.045626316,0.022683116,-0.025153922,-0.025952753,0.019357745,0.040498927,-0.029333856,0.00488588,-0.013830941,0.028887996,0.039681517,-0.06457535,-0.041985128,0.0015721201,-0.003093152,-0.025674092,0.03767515,0.03249203,0.003169784,-0.033625256,0.014100315,-0.0020934509,0.03189755,-0.03626326,-0.02996549,0.0061537935,0.038641177,-0.022032904,0.056364104,-0.030132689,-0.036727697,0.101878956,-0.03472133,0.0064278115,0.04492037,0.03472133,0.017722925,0.04904457,-0.011768839,0.02309182,0.044808906,-0.030875787,-0.04298831,0.03055997,0.00518312,-0.021029718,-0.040536083,0.028553601,-0.014128181,0.048078544,-0.027030248,0.006325635,-0.05889064,-0.03145169,0.029333856,0.027661882,-0.007728236,-0.042876847,0.017091291,0.0048905243,-0.018298827,0.015623669,0.010960719,0.015447183,-0.024206469,0.003055997,0.0103290845,-0.015930198,-0.0350743,-0.025358273,0.006599653,0.055323765,0.0097253155,0.056326948,0.037340753,0.049824826,-0.010459127,-0.026231416,-0.013208595,-0.01265127,-0.054803595,0.031953283,-0.01592091,-0.0048440807,-0.03100583,0.09422503,-0.012762736,0.015790867,-0.025135344,-0.03546443,-0.057590216,-0.06438958,0.024893837,-0.01924628,0.002355858,-0.025655514,0.0007506467,-0.020825366,-0.0048069255,-0.075721845,-0.004337844,0.009530252,0.011443733,-0.006502121,0.023221862,-0.035334386,-0.026119951,0.0040986584,0.005424627,-0.0060051735,-0.008438825,-0.018466026,-0.017852968,0.04744691,-0.022441607,0.023277594,-0.033179395,-0.00962314,-0.01634819,0.009799626,-0.01901406,-0.027494686,-0.0014931657,0.032584917,-0.017574305,-0.011462311,0.015029189,-0.05365179,-0.0035506228,-0.030931521,0.03670912,0.007282376,-0.04057324,0.019469209,0.022924623,0.0013631233,0.02502388,0.031953283,0.023500524,0.060711235,-0.027717615,-0.0043982207,-0.0057450887,0.0133293485,0.0092748115,0.009808915,-0.007835057,-0.013143574,-0.0051691867,-0.017583594,-0.026138527,0.013477969,0.00076341874,0.025711246,-0.015038478,-0.001546576,0.06736198,-0.0005654523,-0.0029956202,0.030597126,-0.031098718,-0.033495214,-0.020379506,-0.01235403,0.007793257,-0.020695323,0.0045189746,-0.06684181,-0.02944532,-0.023351904,-0.031563155,-0.021345535,0.040907633,-0.024968145,-0.037749458,0.00045572905,0.087908685,0.027866235,0.010784233,-0.011610931,-0.023927806,0.047595527,-0.15040335,-0.008304138,-0.0010653029,-0.03018842,-0.053986184,0.044065807,-0.008271627,0.02537685,-0.020472394,0.0060701948,-0.0038734067,-0.011165071,0.019376323,-0.019487787,-0.06873671,0.017481418,0.02346337,-0.017434973,-0.016970538,0.019339167,-0.013960984,-0.0014200169,-0.03665339,0.016264591,0.0023523746,-0.070483,-0.022813158,-0.012223988,-0.03856687,0.026194261,-0.0058054654,-0.035631627,0.021587044,0.02812632,-0.016413212,-0.013357216,-0.012595538,0.012827757,0.05357748,0.021141183,0.021382691,0.0010699473,0.040238842,0.0017010014,-0.07713374,0.028237784,-0.024540864,-0.043285552,0.043285552,-0.02892515,0.0143604,0.014091026,0.030671436,-0.008020831,-0.04283969,0.0062420364,-0.016608275,0.008164806,0.04685243,-0.015326429,0.00907046,-0.019822182,-0.024559442,-0.017174888,-0.030411351,0.0043587433,-0.0510881,0.009595273,-0.004909102,0.029928336,-0.03494426,-0.0100411335,0.012502651,-0.027253177,-0.009883225,0.0024800948,0.040387463,-0.034349777,0.01117436,-0.024169315,0.012149679,0.010747078,0.0029236325,-0.029110927,-0.013533701,-0.008652465,-0.008438825,-0.029148081,0.02502388,-0.02021231,0.008935773,-0.017787946,0.026510078,-0.020398084,0.0028493225,0.012186834,-0.023054665,-0.025636936,-0.024540864,-0.0025102834,0.032937888,-0.020175153,0.005345673,-0.00765857,-0.017128445,0.009762471,-0.015818732,-0.018447448,0.017007692,0.005573247,-0.038158163,-0.01199177,0.004251923,-0.00094977417,-0.006320991,-0.03241772,0.002656581,-0.017156312,0.00039506194,0.016589697,-0.012158967,-0.0045096856,-0.0069990694,-0.015939485,-0.019506365,-0.024336511,0.044325892,-0.004063826,-0.05179404,-0.009558119,0.05513799,-0.09043522,0.0032069392,0.023537679,0.0055593136,0.034591287,-0.028702222,0.02309182,0.011499466,-0.0115366215,0.06004245,-0.031210182,-0.038678333,-0.0074356403,-0.0056940005,-0.012985665,-0.017323509,-0.021178339,0.012363319,-0.005949441,0.046443723,-0.015447183,-0.0035901,0.032770693,-0.027940545,-0.014666928,-0.02338906,-0.0056057577,0.025841288,-0.009126192,0.042616762,-0.08010614,-0.025246808,0.008457402,-0.020138,-0.004126525,0.006785428,-0.0085270675,-0.018215228,-0.0013770565,-0.033495214,-0.0061027054,-0.03735933,0.011257959,-0.020695323,0.020138,0.03440551,0.04231952,0.025785556,-0.014917724,0.021847129,0.028832264,-0.033253707,-0.014945591,-0.03735933,-0.015038478,-0.005136676,-0.011155782,-0.0044539534,-0.026008485,0.009892513,-0.007468151,0.034089692,-0.0059076417,0.05573247,0.036541924,-0.026027063,-0.042765383,-0.00026240703,0.04506899,-0.007900078,-0.049193192,-0.043619946,-0.06479828,-0.015883753,-0.0021317669,0.016821917,0.0060887723,-0.044140115,-0.00481157,-0.0019877914,0.00651141,0.019599251,-0.006771495,0.036077484,-0.020249464,-0.028869418,-0.0024104293,0.018763265,0.00813694,-0.03576167,0.009836781,0.016840495,-0.00043424882,0.029408166,0.043545637,0.014648351,-0.00058780337,-0.019413477,0.01369161,-0.02132696,-0.011898882,-0.03256634,-0.004802281,0.03070859,0.007927944,-0.01909766,0.026249994,-0.016496811,-0.026658697,-0.0027610795,-0.023444792,0.028887996,0.06104563]
5	G20.x00	帕金森病	神经系统疾病	1	[-0.015782045,0.005019567,-0.028600572,-0.043102518,-0.014756212,-0.017228732,0.034475,-0.004410205,0.039490182,-0.003592607,-0.024672598,0.055763226,0.008583679,0.02202472,0.037596337,-0.01692186,-0.027671184,-0.026110517,-0.037596337,-0.029898208,0.020692015,-0.02693469,0.035106283,0.009767332,-0.01628181,0.022252683,0.0013820248,-0.011275394,0.031458877,-0.04454044,-0.022077328,-0.021691544,0.018447457,-0.099672385,-0.04489115,-0.0393499,-0.031827122,-0.021165475,-0.100864805,0.015536547,-0.004151555,-0.023357427,-0.01747423,0.03128352,0.030354133,-0.04261152,-0.015992472,-0.030073563,0.0393499,-0.01942945,0.010994825,-0.009144818,0.04888927,-0.06084855,-0.03594799,0.017149823,0.0020264585,0.025391556,-0.031353664,-0.0355096,-0.022498181,0.0488542,-0.041875027,-0.031388734,0.050537616,0.0042830715,-0.008855481,0.0058831954,0.012634404,-0.010670416,-0.013239382,-0.02896882,-0.0034873935,0.0053089047,-0.06726658,0.021516187,0.05856892,-0.004228273,-0.005251914,0.016737735,0.08452162,-0.00042934835,-0.012432744,0.005295753,0.0013140744,0.023164535,0.026706727,-0.06821351,0.007886639,0.005317672,0.022568325,-0.0043751337,0.005646465,-0.028179718,-0.037526194,-0.07617467,0.0244271,0.037526194,0.04689021,-0.0041603222,0.049695905,0.010617809,-0.007649908,-0.0067249048,0.044189725,-0.022515718,0.009477994,0.023637995,0.02481288,-0.024321884,-0.011485822,0.029705316,0.02733801,0.05330824,0.005422886,-0.0067292885,0.0028298083,-0.04394423,-0.016588682,0.0054272697,0.0037307001,0.011862837,0.003737276,-0.0024177216,-0.011564732,-0.004585561,0.043277875,0.06425046,0.02039391,-0.0076060686,-0.0032725823,-0.01958727,-0.029354604,-0.03435225,0.010126812,0.0020154987,0.010758094,-0.023865959,0.02333989,-0.029161712,0.016176596,0.021691544,0.05913006,-0.047170777,-0.005826205,-0.03084513,0.010889611,0.0016275233,-0.0019201487,0.003785499,-0.026917154,-0.008851097,0.059796415,0.0319148,0.0010532324,0.021323295,-0.03172191,0.03591292,-0.034334715,-0.020955049,0.02362046,-0.0016658825,0.03519396,-0.001155158,0.0128799025,0.043874085,0.045592573,-0.0007014242,-0.04454044,0.015098156,-0.008658205,-0.03379111,-0.017211197,0.034702964,0.022533253,-0.024199136,0.0038008424,0.010004063,0.00853984,-0.020674478,0.0016066999,0.041839954,-0.006181301,-0.03594799,-0.027916683,-0.028740857,0.014782515,0.0140197165,0.038473118,0.005826205,-0.017737266,-0.03331765,0.026408622,-0.005479877,0.008469697,-0.030003421,0.017684657,0.004585561,0.013546255,0.03347547,-0.0069309482,0.019797698,-0.017684657,0.044996362,-0.010170651,-0.004399245,-0.05888456,-0.013195543,-0.0009962416,0.028302466,-0.019920448,0.033650827,0.04548736,-0.01575574,0.015291048,-0.0039783902,-0.00020741334,0.013493649,-0.027478294,-0.05243146,0.003952087,0.069651425,-0.0015003902,0.0205868,0.004311567,-0.020183481,0.0393499,-0.023287283,0.035684958,0.020797228,-0.017544374,-0.016062615,-0.03072238,0.014335358,0.012950044,-0.014650999,0.02928446,-0.0023015481,0.022463111,0.0069002607,-0.025952697,-0.008903704,0.009688422,0.0016242354,0.015326119,-0.01795646,0.05450066,0.02665412,-0.042190667,-0.014344125,0.036123347,0.032896794,-0.013581326,0.036088277,-0.019289166,0.021603866,0.008246118,-0.004151555,0.0034325947,-0.021042727,0.0070887683,0.10430178,0.02637355,0.058639064,-0.020043196,-0.0024308732,0.00614623,0.009399084,0.006211988,0.019183952,-0.003908248,-0.03435225,-0.02965271,-0.012055729,0.04948548,-0.0050984775,0.019078739,-0.02242804,0.02011334,0.01779864,-0.015054317,0.017465463,-0.009635815,0.027636115,0.02142851,-0.044154655,-0.023322355,-0.07505239,-0.03998118,0.0334404,-0.0051773875,0.050818183,0.042471237,0.021814292,-0.023199607,0.024356956,0.0126431715,-0.09497284,0.0061988365,0.0023716907,0.047346134,-0.04808263,-0.0033449167,-0.09455198,0.036333773,-0.031546555,-0.014440571,0.016018776,-0.04345323,0.011047431,0.027513364,-0.035334244,0.0057166074,-0.025759805,-0.034089215,-0.027197724,-0.023269748,0.00684327,-0.017386552,0.0075359265,0.041839954,-0.0133708995,-0.019657414,0.009556905,-0.025724733,-0.048924338,-0.018798169,-0.007864719,0.037841838,-0.027074974,0.03131859,-0.00079293817,-0.0016965698,-0.0031388733,-0.037491124,0.016886787,-0.017860014,-0.010118044,0.076314956,0.02227022,0.032809116,-0.012046961,0.016956931,-0.01396711,0.02158633,0.003024892,-0.0024352572,-0.017105984,0.015632993,-0.013274454,0.01951713,0.05681536,0.0010006254,0.026075445,-0.002667604,0.03770155,-0.013791754,-0.03917454,-0.056534793,0.008583679,0.0036167186,0.022673538,0.03340533,-0.01273085,-0.006032248,0.01472114,-0.029319532,0.03052949,0.010021598,-0.013958341,0.005913883,-0.0154927075,0.010915915,0.019341772,-0.0065933876,-0.044224795,-0.01181023,-0.028267397,0.007943629,-0.0025492387,0.07224669,-0.027706256,-0.05797271,0.014791283,0.010705487,0.009688422,0.21407467,-0.045943286,0.021551259,-0.0026851397,0.018885847,-0.020692015,0.017377784,-0.0045811767,-0.04085796,-0.040928103,-0.03794705,-0.04145417,0.042962234,-0.0025952696,0.0049581924,0.07975193,-0.020955049,-0.037035197,0.095954835,-0.0064574867,-0.029529959,0.039770752,0.037000127,-0.038929045,0.007145759,-0.055798296,-0.024269277,0.084451474,-0.0040989476,0.015668062,-0.036894914,-0.020095803,0.07238698,-0.0044255485,-0.0036780932,-0.0033646442,0.01795646,0.024918096,0.03587785,-0.030283991,0.0035246566,-0.04404944,-0.029038962,0.0060454,0.002444025,-0.02956503,-0.028635643,-0.021516187,-0.005738527,-0.024777811,-0.009311407,-0.01612399,-0.011021128,0.007781425,-0.016150292,0.01464223,0.013309524,-0.02227022,-0.03084513,0.036965057,0.005856892,0.007553462,0.0065977713,0.00933771,-0.028460288,-0.003906056,-0.037911978,0.025689662,-0.03878876,0.0064969417,0.039735682,0.0023431953,-0.0062382915,0.00033893037,0.02988067,0.048222914,0.009749796,0.029319532,-0.00049127097,-0.0033931397,-0.02230529,-0.020919977,-0.046118643,-0.10128566,-0.022515718,0.00419101,0.041068386,0.0002719389,0.039490182,-0.02988067,0.025286343,-0.006637227,-0.020937514,0.00096665026,-0.05362388,-0.0041142916,0.045978356,-0.0019223407,-0.028653178,0.033913862,-0.014870194,-0.00083677715,0.017991532,-0.036123347,0.0033120376,-0.0015387493,0.07547325,0.0411736,-0.040402036,-0.021042727,-0.0118979085,0.018482529,0.04113853,-0.027969291,-0.034738034,0.007948013,-0.03622856,0.049099695,0.010319704,0.078278944,-0.051975533,0.011915443,0.0051730038,0.03279158,0.022726145,0.015878491,-0.052536674,-0.06954621,-0.07070356,-0.010556434,-0.03770155,-0.01273085,-0.026426157,-0.0012373561,0.06396989,0.011231556,-0.008745884,0.017851247,0.07301826,0.013274454,-0.012134639,0.012502886,-0.01636072,0.022217613,0.025356485,0.026706727,-0.022322826,-0.044996362,-0.009548137,0.0057911337,0.009162353,-0.025900088,0.019867841,-0.0127220815,-0.027460758,-0.0038600252,-0.029635172,-0.03068731,0.034878317,0.019534664,0.04541722,0.032370728,0.007939246,0.036403917,0.027039904,0.06112912,-0.013660236,-0.032142766,-0.010749326,-0.0182721,0.028723322,0.021796757,-0.07266755,-0.010907146,0.0039455113,0.020569265,0.016536076,-0.0005164784,0.00079787005,0.02824986,0.0071326075,-0.041278817,0.0018105513,0.007772657,0.042471237,0.017132286,-0.00965335,0.0019223407,0.013853128,-0.03650913,0.0016636905,0.06316325,-0.04425987,-0.016264275,0.01855267,0.024111457,0.000932127,0.013949574,0.04233095,-0.0386134,0.08227706,-0.039455112,0.021551259,0.04895941,-0.031073093,-0.0015464212,-0.0048222914,-0.017167358,-0.011538428,0.00830311,0.0027903533,-0.03822762,-0.014423035,0.015913561,-0.01720243,0.04664471,0.022603394,0.01464223,-0.042997304,0.0008049939,0.05909499,0.0025448548,0.00014453175,-0.024953166,-0.0076674432,-0.016930627,0.0065539326,0.00266322,0.020130875,0.038157478,0.009346478,-0.022761216,-0.05334331,-0.012862367,0.018535135,0.064180315,-0.014186305,0.03247594,-0.00905714,-0.041875027,0.00640488,-0.053483598,-0.018464992,0.028775929,0.0075797653,-0.02840768,-0.0023388113,-0.027899148,0.037175484,-0.007996236,-0.004760917,-0.0069484836,0.07421068,-0.041313887,-0.0017447927,-0.03738591,-0.009434156,-0.043874085,-0.046434283,0.023059322,-0.008211047,0.06891493,0.00023933362,-0.005278217,-0.023848424,0.0074482486,0.0115735,0.010074206,-0.013633933,-0.029424746,0.035562206,-0.0012395481,-0.0015979321,0.014010949,0.03321244,-0.037596337,0.0048179077,0.04573286,0.019639878,0.05330824,-0.018447457,-0.04113853,-0.0012362602,0.03906933,0.014773748,0.009986527,0.0011814614,0.067968,-0.015711902,0.005738527,-0.027443223,0.010354775,-0.040472176,0.065267526,0.04261152,-0.0705282,-0.019867841,0.058428638,-0.022778751,0.04576793,-0.050783113,0.016711432,-0.02490056,0.0054360377,0.014475642,-0.02390103,0.016781574,-0.030810058,-0.06400496,0.0030007805,-0.013844361,-0.00074526324,0.019639878,-0.003643022,0.0013228422,0.018605277,-0.047696847,0.005159852,0.011205252,0.063549034,0.017211197,-0.0066416105,0.010161883,-0.041910097,0.031616695,0.021323295,-0.009758565,-0.021516187,-0.022287754,-0.056885503,0.011696248,-0.033861253,-0.036333773,0.005019567,-0.03140627,0.002441833,-0.004931889,-0.05485137,0.01715859,0.030073563,-0.0439793,-0.024409562,0.035895385,-0.019324237,-0.029757923,0.011915443,-0.003423827,0.020358838,0.021007655,-0.011950515,0.027758863,0.0060673193,-0.037000127,-0.018570205,0.012423976,0.034457464,-0.018307172,0.035649884,-0.0015519011,0.012020658,-0.03312476,-0.021042727,-0.041278817,0.0009743221,0.017860014,0.034457464,-0.018096745,0.009100979,-0.011257859,-0.021779222,-0.0481177,-0.018973526,-0.008649438,-0.010968521,-0.06256704,0.0020144028,0.01556285,0.004931889,-0.00418005,0.014580856,-0.0015836844,-0.001868638,-0.024462169,-0.016790342,0.057551857,-0.06607416,-0.02637355,-0.0102934,0.056289293,0.052852314,-0.034264572,0.00035235606,-0.023988709,-0.013423506,-0.12436251,-0.043277875,0.012362602,-0.031493947,-0.046820067,0.0045899446,-0.017649587,0.053483598,-0.028039433,-0.08922116,-0.018798169,-0.057762284,-0.0024527928,-0.03279158,-0.069686495,0.026706727,0.0033164213,0.015010478,0.02102519,0.06519738,-0.039560325,0.020008126,0.034194432,0.01304649,0.028267397,-0.044750866,0.0040112697,-0.036123347,-0.020201018,0.0040616845,-0.007549078,-0.05849878,0.02725033,0.026513835,-0.021446045,-0.020656943,-0.01464223,-0.029670244,0.021165475,0.0067731277,-0.011441982,0.020481586,-0.011678713,-0.0024834801,-0.03219537,0.023550319,0.0025536225,0.015229673,-0.026145587,-0.048257984,-0.030950343,-0.018692955,0.002533895,0.0069441,-0.011599803,-0.008745884,0.0026128052,-0.0077463537,0.008531072,0.066495016,0.018482529,-0.025110986,-0.018131817,-0.05499166,-0.024199136,0.020464052,-0.03829776,0.038157478,0.054781232,-0.038683545,-0.027706256,-0.0015409413,0.051203966,-0.08585432,-0.008088298,0.020376373,-0.007676211,0.009179889,-0.04874898,-0.013142936,-0.014712373,0.019692484,0.033896327,-0.018517599,-0.009846242,-0.018201958,-0.023708139,0.008592446,0.023480175,0.014782515,-0.013896967,-0.009890081,0.019446986,0.04138403,-0.002354155,0.018780634,-0.028355073,-0.0027443222,-0.038964115,0.005615778,0.005896347,-0.05941063,-0.005431654,0.019183952,-0.055728152,0.020849835,-0.026583977,-0.024479706,0.043137588,-0.013458577,-0.02465506,-0.0046776226,0.007290428,0.032072622,-0.041769814,-0.0027618578,0.0010351487,0.015782045,0.021568794,0.039455112,0.014107395,-0.011950515,0.01073179,-0.03400154,0.017535605,-0.02565459,0.01628181,-0.00023248377,0.048293058,0.024707668,0.0032747744,-0.038929045,0.0039718146,0.020043196,0.030389205,0.015659295,0.06105898,0.046820067,0.02274368,-0.026601514,0.023410033,0.0264963,-0.027425686,-0.030669773,-0.007509623,-0.01221355,0.046749923,-0.02988067,-0.0145107135,-0.00843901,0.045908216,-0.05127411,-0.0041581304,0.01368654,-0.021972114,0.0026785638,0.02709251,0.01811428,0.035158888,-0.05972627,0.0073167314,-0.05825328,-0.022883965,-0.005414118,-0.018429922,0.024865488,0.0032638146,-0.009705958,-0.061164193,0.01121402,0.021270689,0.007115072,-0.03766648,-0.03682477,0.022112397,-0.017763568,-0.0024242974,-0.008666973,-0.016202899,-0.038648475,0.028723322,0.02709251,0.026040373,9.178794e-05,-0.01113511,0.061199263,0.021007655,-0.019745091,0.007636756,-0.014826355,0.028425217,-0.0016308113,0.00640488,-0.008816025,0.047591634,0.022498181,0.031038022,-0.036614344,-0.051800177,0.05011676,-0.03882383,-0.00524753,-0.043593515,-0.017246269,-0.040051322,0.0001516556,0.020902442,0.043874085,-0.01935931,0.008745884,-0.01612399,-0.029828064,-0.014589624,0.03440486,0.005063406,-0.051414397,0.04843334,-0.019236559,0.018009067,0.06884479,-0.038367905,0.0016691705,-0.026426157,0.03068731,0.025356485,0.024672598,0.015790813,-0.0024790962,-0.037315767,-0.0205868,-0.013555023,-0.024707668,-0.036333773,0.014116162,0.011249091,-0.047416277,0.023918565,0.026338479,-0.048328128,0.017737266,-0.023883494,-0.013932038,-0.010179419,-0.00851792]
6	G30.900	阿尔茨海默病	神经系统疾病	1	[0.020998903,0.0022299923,-0.04155957,-0.009134523,-0.012654122,-0.024888266,0.035807695,-0.00037917856,0.02795593,-0.011184199,0.020944124,0.020871084,-0.010033824,0.03485818,0.035844214,-0.042216927,-0.02404831,-0.033579987,-0.028905448,-0.019282471,0.003394062,-0.0036633958,0.033598244,-0.0057975235,-0.009394727,0.022112759,0.0059527326,-0.020578925,0.0478775,-0.045394152,-0.010198163,-0.016653044,0.021254541,-0.057956975,-0.040098775,-0.01710041,-0.0131288795,-0.034091264,-0.088743195,0.051164284,0.0007834645,-0.024322208,-0.016397405,0.021108463,0.06091508,-0.048973095,-0.020505887,-0.010170774,0.054706708,-0.0475123,-0.005943603,-0.02841243,0.045065474,-0.03969706,-0.00646401,0.02821157,-0.055400584,0.0005460856,-0.07406222,-0.011814166,-0.00270475,0.033561725,-0.025472583,0.0030151687,0.022131018,0.028375909,0.024559587,-0.00032297228,-0.0014105785,-0.0124258725,-0.014662713,0.02393875,-0.038857102,0.0066237845,-0.055144947,0.029434985,0.038418863,-0.013777107,0.021528441,0.018935533,0.08143923,0.0003931588,0.008687155,0.026367318,0.0027001852,0.016342625,0.021309322,-0.008216962,-0.013987096,-0.028814148,0.031772252,0.012106325,0.03022016,-0.03248439,-0.0016958897,-0.055071905,-0.025180424,0.015676137,0.06339843,0.025545623,0.026677737,-0.0140418755,-0.020451106,0.002588343,0.01984853,-0.03200963,-0.009234953,0.013777107,0.035497278,0.0012599342,-0.019264212,0.0033506947,0.03540598,0.04977653,-0.026787296,-0.013256699,-0.0152378995,-0.048352256,-0.0038459948,-0.0016993134,-0.010992469,0.019903308,0.014416204,-0.033908665,-0.003259395,0.0131288795,0.049411334,-0.0028462645,0.002224286,-0.023281394,0.03708589,-0.021838859,-0.07720292,-0.047147103,0.0008896003,-0.044590715,0.041778687,0.0218206,0.03473036,-0.05430499,0.022733595,-0.0005746167,-0.005683399,-0.040390935,0.016050465,-0.0093673365,-0.0064731403,0.049630452,0.015813088,-0.0002368083,-0.01742909,-0.0012188494,0.020049388,0.04623411,0.029690623,0.021291062,-0.022788376,0.052661598,-0.031352274,0.0008821822,0.042582124,0.01944681,0.019264212,-0.0005894529,0.014598803,0.0119328555,0.048717458,0.029288905,0.0038619721,0.027262054,-0.029307166,-0.060805522,-0.0029444115,0.009125393,-0.019154651,-0.016753472,0.023500511,0.0034054744,0.008394997,-0.018479034,0.013256699,-0.010271203,-0.009668626,0.00061513094,-0.013557987,-0.032082673,-0.035972036,-0.0016593699,0.023390952,-0.0015167142,-0.03664765,-0.035424236,0.0070985425,-0.00024822072,-0.012873241,-0.0047110585,-0.007687425,-0.013530598,-0.04532111,0.0016593699,-0.030055821,0.017073022,0.002602038,0.041961286,-0.0027618124,0.007153322,-0.054085873,-0.0065096603,0.0038208875,-0.027700292,-0.013448428,0.033269566,-0.011458097,0.005624054,0.006523355,-0.068730325,0.013685807,0.024961306,-0.027700292,-0.011193329,-0.008481731,0.05185816,-0.011558527,0.001180047,0.048571378,-0.025965601,0.023537032,-0.0029740839,0.03863798,-0.031352274,-0.007230927,-0.041778687,-0.04188825,-0.008244352,0.039441418,0.008824104,0.0348034,-0.023299653,0.042216927,-0.014544023,-0.048936576,0.016580004,0.021144982,-0.0039007745,-0.041815206,-0.021838859,0.0037478479,-0.001864794,0.002896479,0.0036177458,0.01951985,0.0023327044,-0.03730501,0.022003198,-0.009896874,0.018360345,0.007952194,0.013174529,0.043823797,-0.009002139,-0.0009284026,0.062485434,0.0010664932,0.042180408,-0.04813314,-0.02171104,0.006906813,0.015356589,0.003711328,0.013393648,-0.04780446,0.0009512275,-0.056751817,0.009002139,0.031187937,-0.018196007,0.0012827591,-0.01962941,0.036465053,0.019647669,0.011859816,0.009239517,0.005733614,-0.008509121,0.0018944663,-0.0047110585,-0.011841555,-0.02382919,-0.031589653,-0.031991374,-0.011823296,0.021327581,0.051602524,-0.020925865,-0.026568178,0.03431038,-0.027152495,-0.13169052,-0.015648749,-0.014233605,0.03235657,-0.03206441,-0.0007321085,-0.074573494,0.015959166,0.019939829,0.0046037813,0.035862476,-0.06296019,-0.02828461,0.011631566,-0.06719649,0.03266699,0.002148964,-0.025399543,-0.027280314,-0.0392223,-0.010134254,-0.025965601,-0.01096508,0.0027755073,0.007801549,-0.010362502,0.055327546,-0.028905448,-0.012462392,-0.022477956,-0.0823157,-0.033926923,-0.011713736,0.040281374,-0.00044251766,-0.012361963,0.039441418,-0.0436412,0.0026819252,-0.0043869447,0.01074596,0.008554771,0.02802897,0.011019859,-0.0261482,-0.0025404107,0.042764723,0.025509102,-0.0021295627,0.004243148,-0.04517503,0.004793228,-0.023482252,0.022386657,0.03263047,-0.004261408,0.026604697,0.01710041,0.038345825,-0.013886666,-0.03027494,-0.038126703,-0.023281394,0.023299653,0.0073359213,0.019866789,-0.040390935,-0.0019047374,-0.003067666,-0.035150338,0.025344763,-0.01292802,-0.009650365,0.003152118,-0.023628332,0.022240577,-0.00072069606,-0.027755072,-0.021546701,-0.044152476,-0.05660574,0.02832113,0.013329739,0.03445646,-0.029197605,-0.03257569,0.010399022,0.027700292,0.055108428,0.24891917,0.0029695188,0.010572491,-0.0020211444,0.0026088855,0.011859816,0.033141747,-0.013804496,-0.013877536,-0.022806635,-0.07095803,-0.0012781941,0.031881813,0.000558354,0.0021432575,0.054743227,-0.05883345,0.015037041,0.1045928,0.023774412,-0.007208102,-0.029142827,0.024742186,-0.0033780844,0.040171817,-0.033689544,-0.036154635,0.06562614,0.035990294,0.0012747704,-0.02583778,-0.0050534317,0.05711702,-0.020195467,0.018287307,-0.01752952,0.0077193794,-0.031753995,-0.0152013805,-0.004350425,-0.020396326,-0.0476949,-0.028868927,-0.003907622,0.025271723,-0.02156496,-0.037761506,0.0061444617,-0.028941967,-0.05386675,0.0032205926,-0.018332956,-0.01080987,0.018269045,-0.0012816179,0.014991391,0.007167017,-0.0073359213,-0.01304671,0.022204058,0.058614332,0.0055464497,-0.048936576,0.022441437,-0.048023578,0.009686885,-0.031461835,0.013850146,-0.039989214,0.026476879,0.054706708,0.0123893535,-0.018935533,-0.0017461044,0.033616506,0.03253917,0.00762808,0.04608803,0.014297514,-0.005660574,0.010115993,0.0026682303,-0.0057381787,-0.1250439,0.014817921,0.033999965,0.010499451,-0.020560665,0.018880753,-0.01743822,-0.0123893535,0.0062175016,-0.028010711,-0.019866789,-0.048644416,-0.00030785077,0.06734257,-0.01524703,-0.019647669,0.0788098,-0.027170755,-0.012508042,-0.035935514,-0.03496774,0.0217293,-0.009253212,-0.008048058,0.003366672,-0.040171817,0.011193329,0.0147448825,0.01308323,0.040281374,-0.009349077,-0.005487105,0.028010711,-0.016370015,-0.0025746482,0.022697076,0.05032433,-0.0436412,-0.014909222,-0.047256663,0.04375076,0.029982783,0.0053821104,-0.0004339583,-0.047585342,-0.064055786,0.028795887,-0.02403005,-0.018287307,-0.034566022,0.027901152,0.038090184,-0.008185008,-0.025728222,0.044006396,0.055108428,-0.0013592225,-0.045978468,0.0028941967,-0.020140687,-0.008408692,0.044517674,0.037542388,-0.019355511,0.004421182,-0.029453244,0.015913516,0.02393875,-0.013357129,0.035533797,-0.06401926,-0.026276018,-0.0118963355,-0.021144982,-0.0001709014,0.05057997,-0.011604177,0.046708867,0.012252403,0.031078378,0.04984957,0.053757194,0.052734636,-0.020140687,7.539348e-05,0.017209971,-0.0029352815,0.021601481,0.018734673,-0.045211554,-0.0016479574,0.013357129,-0.0030927733,-0.0068565984,0.007669165,-0.004934742,0.04323948,-0.008230657,-0.009969914,-0.0152013805,0.0044280295,0.013512338,0.040902212,0.015813088,0.0057655685,-0.012489783,-0.01777603,-0.00029444115,0.0478775,-0.05865085,-0.024376988,0.018716414,0.021382362,0.025490843,0.016278716,0.05204076,-0.040062256,0.037195448,-0.023555292,0.017730378,0.0035698137,-0.021364102,0.02629428,0.025527362,-0.029928003,0.014206215,0.053830232,0.015922647,-0.042253446,-0.033488687,0.018844234,-0.0079613235,0.018972052,-0.014397943,0.02419439,-0.027061196,-0.022989234,0.07168843,-0.009842095,0.046818424,-0.042764723,0.015018781,0.00653705,-0.04970349,-0.0037546952,0.015520928,0.051346883,0.0076006902,-0.03261221,0.040756132,0.020122427,0.033762585,0.027736813,0.008358477,0.017493,0.011220719,-0.0032274402,0.04992261,-0.07625341,-0.01931899,0.008139358,-0.011823296,-0.018159486,-0.003049406,-0.015676137,0.036811993,-0.013987096,-0.04349512,0.014763142,0.07183451,-0.021053683,0.02616646,0.008157617,0.03878406,-0.029854963,-0.049484372,0.05448759,-0.011722866,0.038382344,0.00764634,-0.052734636,-0.049009614,-0.031443577,0.026549919,0.05481627,-0.029964522,-0.06737909,-0.014096655,-0.0062129362,-0.008440646,-0.03650157,-0.009422117,-0.012571952,-0.038382344,0.06584526,0.022112759,0.0020793478,0.031808775,-0.0028782194,0.019958088,0.059636887,-0.037761506,0.04371424,-0.0045855213,0.051018205,-0.015950037,-0.014270124,-0.03487644,-0.018068187,-0.038272783,0.05277116,-0.0004773256,-0.048680935,-0.02149192,0.05025129,-0.04375076,0.03058536,-0.059235167,-0.0008034363,-0.0100703435,0.016123505,0.015383979,-0.024303949,0.018972052,-0.042107366,-0.019191172,-0.031407055,-0.024157869,-0.027134236,0.017255621,-0.006934203,-0.020542406,0.0024034614,0.008043493,-0.01726475,0.0074911304,0.03478514,0.04827922,-0.014425334,-0.027006416,-0.040025737,0.025180424,0.03907622,-0.04988609,0.016296975,0.008198703,-0.04108481,0.018752934,0.0003318169,-0.009175608,-0.006687694,-0.047147103,-0.014169695,-0.002009732,-0.014434463,0.03281307,0.028941967,-0.027736813,-0.040865693,0.06712345,0.0005660574,-0.0475123,0.011631566,0.009358207,0.008116533,0.0007469447,0.010262073,0.055510145,0.018241657,-0.04568631,-0.047001023,0.02406657,0.020049388,-0.040573534,0.011814166,0.038017146,0.008819539,0.016004816,-0.009796445,0.014133175,0.038857102,0.040062256,0.011485487,-0.022185799,0.0087465,-0.02815679,0.03662939,-0.036245935,0.030968817,0.007815244,-0.021382362,-0.058139574,0.011503747,0.05189468,0.04145001,-0.03723197,-0.029106306,-0.029015006,-0.03896666,-0.03918578,-0.043056883,0.011001599,-0.04082917,-0.020286767,-0.02622124,0.050360847,-0.006947898,-0.0142518645,0.0069889827,-0.026276018,-0.025107384,-0.14644453,-0.028850667,-0.0151466,-0.035387717,-0.0565327,0.026951635,-0.03721371,0.032374833,-0.016077856,-0.049630452,0.009714276,-0.03252091,-0.00438238,-0.041011773,-0.044700276,0.016497834,-0.020524146,0.029453244,-0.006614655,0.05642314,-0.01970245,-0.0028234394,0.034474723,0.009253212,0.009467767,-0.05897953,-0.012498912,-0.0045238943,-0.025655182,0.023226613,0.0041335886,-0.028996747,0.02833939,0.049009614,-0.016205676,0.005185816,-0.008956489,-0.014370554,0.010535971,0.007860894,-0.0022414047,0.01966593,-0.0041153287,-0.012508042,-0.0075824303,0.0075093904,-0.00060371845,0.015575709,-0.0047064936,-0.030402761,0.0014094373,0.021546701,0.016132636,0.02421265,8.0172445e-05,-0.0074272207,0.009161913,0.033780843,0.033945184,0.084068656,0.028521989,-0.016479574,-0.0016536637,-0.024906525,-0.029051526,0.05222336,-0.022185799,0.027024675,0.016342625,0.027115975,-0.008038928,-0.003403192,0.062229794,-0.078006364,-0.0009557925,-0.011960245,0.01736518,-0.009216692,-0.0068155136,-0.008783019,0.001902455,0.051237326,0.028613288,-0.06146288,0.014169695,0.014416204,-0.04342208,0.0020542406,-0.016278716,0.035387717,-0.026641218,-0.026988156,-0.0001901599,0.06069596,-0.05463367,0.015968297,-0.036392014,-0.0005974416,-0.035716396,0.033634767,-0.010462932,-0.0125993425,0.037341528,-0.0061946767,-0.02855851,-0.0080845775,-0.016443055,-0.06632002,0.03703111,-0.0044828095,-0.038491905,-0.043093402,0.042618643,0.010691181,-0.019903308,-0.013813626,0.039989214,-0.017757768,-0.021911899,0.020250248,-0.006075987,-0.014197085,0.013786237,-0.022861416,0.0007623515,0.034073003,0.0055373195,0.0044599846,0.049082655,-0.0028097446,0.04137697,-0.065516576,0.014817921,0.015429629,0.030074082,0.037578907,0.000489594,0.03487644,-0.013676677,-0.02830287,0.015758308,0.04185173,-0.002293902,-0.0020154382,-0.060769,-0.033324346,0.026604697,-0.012005894,-0.048863534,-0.017082151,0.031407055,-0.07044676,0.037798025,0.007870024,-0.027828112,-0.019355511,0.022240577,0.018488165,0.03969706,-0.014023615,0.022550996,-0.0475123,-0.024486547,0.020633705,-0.01937377,-0.014507503,0.008604986,-0.007208102,-0.033379126,0.012106325,0.02169278,0.010618141,-0.0064274906,-0.008061753,0.008888015,-0.027937671,-0.0018145791,-0.01096508,-0.020944124,-0.039879657,0.023263132,0.0049301772,0.016187416,0.006733344,-0.007920238,0.019282471,0.010097734,-0.0023418341,-0.00011490908,-0.008723675,0.000106278414,-0.00875563,-0.01291889,0.0042773853,0.07720292,0.026622958,-0.0026842076,-0.008404126,-0.020560665,0.04995913,-0.06745213,-0.022550996,-0.03312349,-0.02165626,0.0024810662,-0.001301019,0.02171104,0.028631547,-0.025874302,-0.004802358,-0.021345843,-0.029763663,0.013247569,0.03644679,-0.0070711523,-0.011768516,0.016068727,-0.07073891,0.021254541,0.036063336,-0.008687155,0.005646879,0.005181251,0.016662173,0.033598244,0.033780843,0.01984853,0.011257239,-0.033196528,0.002396614,0.026531657,-0.020542406,-0.027371613,0.041048292,-0.00882867,-0.003193203,0.008303697,0.010663791,-0.02403005,0.02392049,-0.0013158552,0.017839938,0.019428551,-0.0390397]
7	S06.900	脑外伤	创伤	1	[0.010343607,0.028505709,-0.026373392,-0.017095944,-0.0010217351,0.007383615,0.044629015,0.031760298,0.020593692,-0.036342908,0.021510214,0.033443704,-0.0040518697,0.040701065,0.047883607,-0.02364253,0.013018356,-0.026841005,-0.024446825,-0.046200197,-0.024559053,-0.0137665365,-0.0041313637,-0.0117183905,-0.02367994,-0.008865949,-0.00046556751,-0.04563906,0.043768607,-0.014056457,0.03237755,-0.02066851,0.01803117,-0.07291027,-0.013467264,-0.02689712,0.008987528,0.008842568,-0.072685815,0.010343607,-0.029758913,0.05454242,0.0131212305,0.028992027,0.026130233,-0.043806016,0.011316243,-0.027645301,0.024166258,-0.031049525,-0.00085105625,-0.03445375,0.00499411,-0.017788012,0.008879977,0.03469691,-0.010222027,-0.01204572,-0.025718734,0.0035258045,-0.044329744,0.020631101,-0.044666424,-0.004942673,0.01815275,0.09973257,0.050240375,-0.004952025,-0.034846544,0.003614651,-0.03153584,-0.00063829223,-0.020294419,-0.017937647,-0.044741243,0.011297538,0.047247652,-0.034715615,0.034397636,0.015487353,0.06468028,-0.0354825,0.015337718,0.015898854,-0.018536193,0.02966539,0.009960164,-0.010081744,-0.022595076,-0.03434152,-0.021846894,0.018302387,0.00046381398,-0.017610319,0.028150322,-0.02669137,-0.06288464,-0.008094387,0.009300829,0.0038718383,0.034509864,0.061163824,-0.005185832,-0.0149262175,0.012784549,-0.016693797,0.037409067,0.03226532,-0.030881185,0.0046550906,-0.00833287,0.06613923,0.003472029,0.0021556974,-0.004182801,0.0034603386,-0.043656383,-0.062024232,-0.023567712,0.00066167285,-0.0003211919,0.036941454,-0.014916865,-0.0064670923,0.026074119,-0.025064075,0.038755793,-0.010633527,0.023792166,-0.022838235,-0.012681673,0.028767573,-0.048295107,-0.0135794915,0.025120188,-0.041187383,0.020799441,-0.031909935,0.0029950633,-0.0025368023,0.01419674,0.0041149976,-0.0021451763,-0.01183997,-0.007935398,-0.050651878,0.0041313637,0.047172833,0.055066146,-0.04492829,-0.017441977,-0.0008107246,0.00994146,0.021023896,-0.004975406,-0.004598977,-0.018910283,0.008744369,0.03924211,-0.019621056,-0.054654647,-0.0006681025,-0.054991327,-0.0198081,0.003013768,0.00477667,0.059106324,0.044629015,-0.009450465,-0.0046130056,-0.0046550906,-0.006836507,0.052784193,-0.010914096,0.010259436,0.012597503,-0.010409073,0.001101814,0.0027916515,-0.035669547,0.009389676,-0.028898504,0.03363075,0.04563906,-0.008220643,0.03267682,-0.0033574637,0.027645301,0.0103155505,0.022707304,-0.019228261,-0.0074631087,0.022015236,-0.009291477,0.05450501,-0.008599409,0.00981988,0.0022749389,-0.05398128,0.010081744,-0.059218552,-0.005915309,0.012279526,0.009492551,-0.024409415,-0.004933321,-0.035426386,-0.025756143,-0.016656388,-0.044629015,0.030413572,-0.009707653,0.017675783,-0.009006233,-0.026560437,-0.042309653,0.031872526,0.011540697,-0.00094574795,-0.04575129,-0.0144960135,0.032994796,0.0048164176,-0.01790959,0.009660891,-0.005994803,0.034547273,-0.025943188,0.01819951,-0.031461027,0.0035445092,0.030058185,-0.03428541,0.0013525715,0.07208727,0.010708345,-0.024820916,0.010932799,0.047846198,-0.023605121,0.033836503,0.01732975,-0.023305848,0.030525798,0.0054196385,0.00301143,0.030638026,-0.012083129,-0.045788698,0.022146167,0.009113784,0.013355037,-0.014655002,-0.036716998,0.012775197,0.0048210933,-0.0063642175,0.008875301,0.017806716,0.0126068555,0.0068879444,0.054804284,0.026317278,0.026803596,-0.012999651,2.2503891e-05,-0.020275714,0.035706956,-0.010231379,-0.021678554,-0.018667124,-0.018844817,-0.021061305,-0.01988292,0.012503981,0.039092474,-0.0031166428,-0.021173531,0.03581918,0.035501204,0.02384828,-0.01551541,-0.00569553,0.020088669,0.024970552,-0.008052302,-0.078334585,-0.03359334,-0.046985786,-0.00990405,-0.0017465358,-0.026560437,0.055889145,0.0014449252,0.008739693,0.04691097,-0.015393831,-0.15247935,-0.020107374,0.008388983,0.053831648,-0.022426736,-0.0017231551,0.0012672321,-0.021828191,-0.03378039,0.017918942,0.020986486,-0.051437467,-0.00018003113,-0.0033107025,0.048332516,-0.040214747,-0.013813298,-0.07133909,0.02124835,-0.023960507,-0.014365082,0.008795807,0.0011275327,-0.0044750595,-0.04459161,-0.049903695,0.037053682,-0.040326975,-0.018180806,-0.0036964833,-0.09262485,-0.018293034,-0.016478693,0.052036013,0.018003114,-0.0074771373,-0.053569783,0.0093709715,0.0064250072,0.0255878,-0.0032101655,0.07601523,-0.00046761334,0.08895876,0.004252943,-0.026205052,-0.0008645002,-0.013111878,0.03147973,-0.009885346,-0.013878764,-0.03003948,0.020631101,-0.033892613,0.008964147,0.021977827,0.0105587095,0.01700242,0.01221406,0.029104253,-0.0051437467,-0.06396951,-0.036623478,0.05936819,0.031292684,0.03551991,0.020949077,0.005573951,0.034584682,-0.0135233775,0.023287144,-0.04889365,0.008758398,-0.015908206,0.039803248,-0.022426736,0.004168773,-0.022108758,-0.0009831571,-0.09067958,-0.06699964,0.05083892,0.031629365,0.019284373,-0.035613433,-0.036978863,0.06168755,-0.020275714,0.03363075,0.23687421,0.006944058,-9.907557e-05,-0.0004936243,0.024746098,-0.029216481,0.051138196,0.014393139,-0.009515932,-0.01914409,-0.08259922,0.003958347,0.001157343,0.03574436,-0.055066146,0.0018330442,-0.041935563,0.023979211,0.07601523,-0.042983018,-9.834493e-05,0.018788705,0.03783927,-0.016357115,-0.01002563,-0.0841704,0.03123657,0.062024232,0.038755793,-0.005891928,-0.02244544,-0.0068224785,0.047098015,-0.029927254,0.004802389,0.031012116,-0.057497736,-0.052821603,-0.025438165,-0.007537927,0.011063731,-0.0416737,-0.0021814161,0.05409351,0.033032205,0.009604778,-0.0112320725,-0.034472454,0.00462002,-0.023773462,0.01151264,-0.00022109343,4.648734e-06,-0.021117419,-0.0070936945,6.458909e-05,0.0031306713,0.0130651165,-0.008145824,0.00994146,0.021491509,0.032826457,-0.056412872,-0.010296846,-0.022800826,-0.0023368977,-0.048744015,-0.013270866,0.010053687,0.034191888,0.03147973,-0.0059480416,-0.009193278,0.027907165,0.02983373,0.024297189,-0.020556282,0.060864553,0.087312765,-0.027925868,0.0017173099,-0.031461027,-0.015833387,-0.06224869,0.0101098,0.0042880145,0.018620363,-0.028243845,0.00060497475,0.00083001365,0.020574987,-0.021435395,-0.058096282,0.021192236,-0.064829916,0.034846544,-0.00020326568,-0.0045872866,-0.021173531,-0.023193622,-0.04500311,-0.030002072,0.004468045,0.0140096955,-0.005438343,-0.009586073,-0.020369237,-0.002705143,-0.05398128,0.033237956,0.008978176,0.007893313,-0.014458604,-0.04219743,0.0004573843,0.02083685,-0.024989257,0.013205401,0.017975057,0.015010388,-0.026205052,0.0050268434,-0.029609276,0.10467057,0.0039349664,-0.028861094,-0.018760648,-0.0020458084,-0.018751295,0.039915476,-0.022557667,0.004178125,-0.029104253,0.009347591,0.062398322,0.011026323,0.012055072,0.01650675,0.06367023,0.027383437,0.046836153,0.015730513,-0.026392097,0.0071685123,0.006682195,-0.021510214,-0.03336889,-0.01856425,-0.0018786365,0.014617593,-0.004706528,0.040925518,0.01943401,-0.024035325,0.024502939,-0.020294419,-0.01139106,0.030376162,0.04216002,-0.027196392,0.00234625,-0.00821129,0.0038648243,0.037034977,-0.0031470377,0.08147695,0.019789396,0.0053401445,0.03192864,-0.00019858954,-0.009375648,-0.018994454,-0.024166258,0.035295453,-0.022258395,0.07152613,-0.0063034277,0.038718384,-0.00056931924,0.030450981,-0.0198081,0.0027238477,0.027458254,0.06138828,0.02586837,0.013738479,0.046200197,-0.023081394,-0.03821336,-0.0056908545,-0.056038782,0.07575336,-0.0015150672,-0.028243845,0.030843776,0.0066681663,0.0026490295,-0.012036367,-0.00315639,-0.02785105,-0.0064343596,0.020126078,-0.007916694,0.007257359,-0.00066459546,0.015749218,0.038793202,-0.027158983,-0.025400756,0.03164807,-0.010465186,-0.051025968,-0.008571353,0.0144398995,-0.049604423,0.009515932,0.030750252,0.044404563,-0.0064998255,-0.038718384,-0.012064424,0.01501974,0.047546923,-0.058844462,0.0014753201,0.039915476,0.03247107,-0.04242188,0.025475575,0.058283325,0.005807758,-0.070478685,-0.0045896247,-0.024671279,0.008543296,-0.028786277,-0.011596811,0.03415448,0.031498436,-0.025363347,0.028804982,-0.053943876,-0.036193274,0.07253618,-0.025007961,0.02083685,0.03441634,-0.018059228,-0.019995145,0.044254925,0.03378039,0.024315894,0.03263941,-0.03886802,-0.032789048,0.010259436,0.03551991,0.012401106,-0.034266707,0.015814682,0.009810528,0.041374426,-0.021566328,0.0090202615,0.010156562,-0.030207822,0.00012267544,0.033911318,-0.031835116,-0.026635256,-0.02699064,0.0012134566,-0.05098856,-0.034883954,0.012466571,-0.006172496,-0.030881185,0.021884304,0.051774148,0.023100099,-0.017058535,-0.04971665,0.00074467424,0.038456522,0.047958422,-0.02001385,0.049492195,0.039429158,0.037278134,-0.011709038,-0.0037198642,-0.029085549,-0.03477173,0.018124692,-0.026747482,-0.02425978,-0.033312775,0.025569098,0.0022702627,0.0027191716,-0.0392047,0.0018003114,-0.0041991677,-0.03729684,0.020780737,-0.025438165,-0.014533423,-0.045489427,-0.03333148,-0.009188602,-0.026130233,-0.016553512,-0.027196392,-0.034678206,-0.016394524,-0.025550393,-0.0043254234,-0.039803248,-0.021323169,0.040326975,0.044666424,-0.011606163,-0.0297028,-0.024353303,-0.030600617,0.0061163823,-0.030918594,0.0057937293,-0.03209698,-0.06004155,0.005255974,-0.006841183,0.020687213,-0.016357115,-0.01803117,0.025026666,0.012737787,0.021641145,0.04129961,-0.052709375,-0.020238305,-0.012466571,0.052746784,-0.009913403,-0.034098364,0.0013443884,0.02829996,0.019116033,0.04201038,-0.013373741,0.01200831,-0.011914788,-0.012083129,-0.032452367,-0.018470727,0.028580528,-0.024970552,-0.049567014,0.062286098,0.021566328,0.0011146733,0.01592691,-0.012560094,0.010455834,0.034509864,0.019527532,-0.0210426,-0.0018657772,0.04238447,0.021940418,-0.027252505,0.017750602,-0.018667124,-0.018601658,-0.013701071,-0.0058685476,-0.027607892,-0.01736716,0.016740557,-0.051923785,-0.0039139236,0.008028921,-0.030207822,-0.011213368,-0.0052887066,-0.022127463,-0.010418425,-0.036623478,0.02244544,4.062391e-05,-0.024951847,0.0012800915,-0.014748525,-0.03574436,-0.1464191,-0.003231208,0.013196048,-0.0051437467,-0.041449245,-0.00853862,-0.02285694,0.019284373,0.024839621,-0.010418425,-0.011381709,0.009221335,0.030114299,-0.013186696,-0.02583096,0.011774504,0.025382051,-0.01642258,-0.015066502,0.006027536,-0.036529955,0.00064764445,0.030357458,0.003016106,-0.0038016965,-0.053607192,-0.017554205,0.04930515,-0.03537027,0.03894284,-0.015608933,-0.05573951,0.011765151,0.01897575,0.028599232,0.013009003,-0.016525455,-0.017788012,0.008487182,-0.009875993,-0.003404225,0.02545687,0.0046854857,0.010427778,-0.03226532,0.068383776,-0.017254932,0.000518174,0.04556424,-0.012260822,0.0038695002,0.02843089,-0.018882226,0.0033901967,-0.014664354,0.032433663,-0.027944572,-0.01943401,0.055851735,0.051587105,0.0064296834,-0.056412872,-0.006630757,-0.010839277,-0.030507093,0.0077623813,-0.051961195,0.0003276216,-0.0041196733,-0.0031423615,-0.029553162,-0.015225491,0.023081394,-0.0010299183,0.027121574,0.050427422,0.057535145,-0.014842047,-0.0040799263,-0.005573951,0.0033387593,-0.022033941,-0.028543118,-0.07433181,0.026915824,0.0016986055,-0.0050081387,-0.02685971,0.009497227,0.0010971378,-0.06569032,-0.01270973,0.024596462,-0.0026420155,-0.028935913,-0.021903008,-0.0012087804,-0.0441427,-0.03469691,-0.0033107025,0.049230333,-0.06468028,0.0019663142,-0.018143397,-0.05046483,-0.0020937386,-0.023567712,0.00035246354,0.03510841,0.008239347,-0.024502939,-0.019069271,-0.0036543983,0.016843433,-0.017788012,0.031947345,0.038269475,-0.017657079,-0.02124835,0.028992027,-0.01811534,-0.019920329,-0.00266072,-0.030020775,-0.0034813813,0.0033598018,0.08072877,0.0028337368,-0.036623478,0.0014005019,0.06052787,-0.04930515,0.0039747134,-0.00015095143,0.0441427,0.09741321,-0.002630325,0.04047661,0.0037245401,-0.02285694,0.04047661,-0.045452017,0.0049286447,-0.012466571,-0.041935563,0.018246273,-0.0032826457,-0.044441972,-0.035837885,0.005573951,0.042983018,-0.010839277,-0.00078032975,0.06224869,-0.024895733,-0.014121923,0.005807758,0.011643572,0.02966539,0.020986486,0.027738823,-0.05136265,-0.03452857,-0.038568746,-0.0010252423,0.0032031513,-0.019733284,-0.007645478,-0.0058825756,0.004521821,-0.03733425,0.018508136,-0.041449245,-0.00017214016,-0.028580528,-0.020182192,0.0018061565,-0.0015197434,0.040962927,0.010923447,0.019957738,0.0128219575,-0.0005941612,-0.0017161409,-0.04287079,-0.0014975317,0.02669137,0.02583096,-0.0045007784,-0.008744369,0.012466571,-0.024147553,0.020892965,-0.030974707,0.034565978,0.034229297,-0.004339452,-0.003366816,-0.03222791,0.06299687,0.03883061,-0.012429163,-0.02525112,-0.073995136,-0.01142847,0.02665396,-0.024315894,0.018798057,-0.0039326283,-0.016291648,0.038755793,0.006350189,-0.027981982,0.052073423,-0.008711636,0.012765844,-0.032732934,-0.01464565,0.034509864,0.0033270689,-0.022202281,0.013392446,-0.0077015916,-0.033237956,0.054879103,0.005887252,0.010708345,-0.00027428445,0.00680845,-0.00028173704,-0.0076641827,-0.008468477,-0.0023310524,0.022314508,0.023492893,-0.007187217,0.0073415292,0.043020427,-0.017694488,-0.0096141305,0.0255878,0.00042055975,0.0018985101,0.0033761682]
8	D43.200	脑良性肿瘤	肿瘤	1	[-0.022477573,0.020563425,-0.0180568,-0.05133564,-0.019086795,-0.0076748244,0.036915723,0.012314356,0.019651925,-0.005077051,-0.002896289,0.008827871,-0.021274393,0.037517313,0.005368731,-0.06358619,-0.021638993,0.0009337171,-0.045502044,-0.034801044,-0.014711599,-0.016060619,-0.06635715,0.0086045535,-0.004689664,-0.010126757,-0.023717212,-0.036387052,0.030881597,0.018549012,-0.0010436667,0.024501102,-0.045283288,-0.073029324,0.034691665,-0.0548358,-0.020235285,-0.007241862,-0.048418842,-0.02588658,0.017282028,0.02681631,0.029751338,0.0018571799,0.032485835,-0.01310736,0.032923356,-0.037553772,0.028220018,-0.02626941,0.031319115,-0.014456379,0.021930674,0.02586835,-0.007861681,0.0074469494,-0.014839209,-0.035056263,-0.015878318,-0.021657225,-0.021638993,0.05159086,-0.04356967,-0.0062939026,0.015686903,0.030681066,-0.010655427,0.009953572,0.014082665,0.005696871,-0.015522833,0.0086045535,-0.050059542,-0.022823943,-0.04057995,-0.003657391,0.036514662,-0.042257108,0.032412916,0.00635315,0.070258364,-0.017364062,0.018940955,0.009479593,-0.012569576,0.07911814,0.0033998925,0.030024787,-0.03642351,0.0005699719,-0.019487856,0.0002643348,-0.022222353,-0.015048854,-0.0039992034,-0.07273765,-0.05600252,-0.0006420373,-0.013298775,-0.004552939,0.02679808,0.047215663,-0.0021613927,0.029022139,-0.022240583,-0.0037462623,-0.016835392,0.051663782,-0.019050336,0.0072919945,0.023735443,0.034819275,-0.018740427,0.005751561,-0.025376141,-0.036131833,-0.019232636,-0.06799785,-0.05129918,-0.0018868035,0.016315838,0.008084999,-0.029204438,-0.011585156,0.018494321,-0.023425533,0.08057654,0.0060614706,0.021857753,-0.014392574,-0.020071216,0.05600252,-0.025594901,0.009260833,0.0038169033,-0.05600252,0.022769254,0.021821294,0.011512237,-0.0010317033,-0.0022684939,0.050497063,-0.000948529,-0.030826908,-0.010381977,-0.06369557,0.0043683606,0.04309569,0.045574967,-0.05582022,-0.012715415,0.035202105,0.002816533,0.034053616,-0.017974766,0.014547529,-0.0535597,0.014985049,0.04189251,0.057643216,-0.076930545,-0.018111492,-0.01281568,-0.016388757,-0.0065217777,0.015723363,0.060158957,0.056367118,-0.016425218,0.022313504,-0.020818645,-0.0067131924,0.0054462086,0.019852456,0.014921244,-0.0132714305,0.02922267,0.0048491764,-0.03724386,-0.025102692,-0.045939565,-0.02776427,0.008239954,0.031355575,-0.004320507,-0.017965652,-0.0017671693,0.017856272,0.0054188636,0.050497063,0.00024638965,-0.023498453,0.009078533,0.008718491,0.047543805,-0.020691035,-0.015340533,-0.027363209,-0.025212072,-0.0045506605,-0.021456694,0.031829555,0.029514348,0.024008892,-0.015522833,-0.015960352,0.015486374,-0.004074402,-0.0074742944,-0.06427893,-0.031100357,-0.017883617,0.0021477202,0.013736295,0.0015484095,-0.05078874,0.0045073642,0.029477889,-0.008467829,-0.020089446,-0.01378187,0.053742,-0.016917428,0.019141486,0.048856363,0.0031104914,-0.010600737,-0.011840376,0.034946885,0.0038601996,-0.016744243,0.024883932,0.00025707128,0.012232321,0.034017153,0.029897178,0.025029771,0.023389073,0.003702966,-0.011357281,-0.0033019064,0.0094249025,0.077003464,0.05242944,0.007693054,0.016197342,0.0270533,0.018339366,-0.0035707986,0.004525594,0.04119977,0.007588232,-0.046705224,-0.023279693,-0.029623728,0.0059657632,0.02712622,-0.0053185984,0.041600827,0.012405505,0.031319115,0.009516053,0.020125905,0.04036119,0.018448746,-0.0020041591,0.03598599,0.004762584,0.023370843,-0.061836112,-0.022295274,-0.022240583,-0.030735757,0.025339682,0.0019904866,-0.037517313,0.015832743,0.0076839393,0.019761305,-0.02754551,0.006143505,0.0046030716,-0.029259128,-0.01827556,0.058737017,-0.023972431,-0.051663782,-0.018494321,-0.018849805,0.0014094058,-0.004436723,-0.016762473,0.07146154,-0.0035411748,-0.004972229,0.011758341,-0.01851255,-0.13111006,-0.02743613,-0.012104711,-0.0072190748,-0.005386961,-0.006330363,-0.015841858,-0.0025658705,0.0055874907,0.007250977,0.015568408,-0.048929285,-0.02672516,-0.008905348,-0.031392038,-0.02643348,-0.044189487,-0.045319747,0.014693369,-0.049220964,-0.03831943,0.010336402,0.05487226,-0.02566782,0.00023926857,0.015386108,0.021930674,-0.030571688,-0.023316152,-0.015349649,-0.030717527,-0.07230013,-0.011065601,0.05458058,0.013809214,0.0039718584,-0.0011598829,-0.024300572,-0.027600199,-0.0056102783,-0.025813662,0.077440985,-0.0057424456,0.101942085,0.021784835,0.010956222,-0.00032927914,0.0038442484,0.07124279,0.008659244,-0.006603813,0.008631898,-0.010956222,-0.034655206,0.0037850009,0.018667506,0.0056877555,-0.0071643847,0.0021636714,-0.007405932,-0.038210053,-0.062856995,-0.017309371,0.057643216,0.036952183,0.013955055,0.0155501785,-0.05217422,0.06643007,-0.00932008,-0.02575897,-0.02743613,0.016452562,0.0061981953,0.028584618,0.0056011635,0.045137446,-0.02663401,-0.012141171,-0.07817018,-0.05421598,0.023461992,0.0053550587,0.032267075,-0.022514034,-0.030535227,0.0152584985,0.0261418,0.012770105,0.19950897,-0.00334976,0.014374345,0.0070413323,0.022185894,-0.006020453,0.017564591,-0.02692569,-0.006325805,-0.0017079219,-0.020089446,0.007706727,-0.0055829333,0.032832205,-0.02792834,0.09763981,-0.03857465,-0.021438465,0.09836901,-0.022933323,0.010691887,-0.059502676,0.02745436,-0.0003814055,0.003926283,-0.030097708,-0.0018526224,0.06453415,0.0130709,-0.023370843,-0.011503122,0.0028917317,0.021711914,-0.03908509,-0.0036459973,-0.028220018,-0.04006951,0.021438465,0.0053824033,-0.007168942,-0.013389925,-0.050497063,-0.036696963,0.019141486,-0.0027025954,0.00048993086,0.021675454,0.035548475,-0.008116902,-0.04076225,0.031811327,0.044772845,0.022131203,-0.018612817,0.029186208,0.033524945,-0.0052274484,0.034436446,-0.017692203,0.029587267,0.03970491,0.010281713,-0.031938937,-0.0020440372,0.020928025,0.046595845,-0.07361268,-0.006143505,0.019961836,0.019524315,0.038975712,-0.0026000517,-0.0074196043,0.015869204,0.022112973,0.05279404,-0.0030421289,0.06314867,0.070951104,-0.006239213,-0.0049403263,-0.021875983,-0.022277044,-0.012132056,-0.0015415732,0.029204438,0.021803064,-0.0048127165,-0.008012079,-0.0044936915,-0.016297609,-0.000968468,-0.043642588,-0.02718091,-0.028657539,0.022021823,0.017792467,-0.011967986,-0.011402857,-0.0049129813,-0.021711914,-0.025576672,-0.0050314763,-0.032175925,0.06344035,0.0508252,-0.024063582,-0.020417584,-0.033670783,0.058007818,-0.004726124,0.016352298,-0.015996814,-0.0057606758,0.007638364,0.0055555883,-0.07671178,0.028821608,0.0128065655,0.010336402,-0.015942123,-0.0013307891,-0.060596474,0.082691215,0.016944772,-0.034454674,0.04076225,-0.011940641,-0.033142116,0.027490819,0.0017181762,0.009652778,-0.017537247,0.0051135113,0.02781896,-0.0013763639,0.06818015,0.030790446,0.05461704,0.035603162,0.030024787,0.07802434,0.0009707468,-0.0011826704,0.021110324,-0.018995646,0.030097708,-0.005054264,-0.020836875,0.017409638,-0.014839209,0.073977284,0.016133538,-0.05421598,0.014893899,-0.035749003,-0.03857465,0.021967134,0.055893138,-0.046632305,0.017765122,0.047325045,0.034983344,0.031246196,-0.02719914,0.023935972,0.031847786,0.008217166,0.04021535,-0.029313818,-0.020253515,0.0008061072,-0.021092094,0.04360613,-0.036478203,0.075545065,0.033853084,0.0510075,0.023498453,-0.0036528336,0.021511383,-0.006576468,0.016698668,0.031282656,0.061544433,0.009256275,0.01838494,-0.012195861,-0.008499731,-0.01865839,-0.033616096,0.051372103,0.012350815,-0.013718065,0.018521667,-0.0019414936,-0.01319851,-0.0054826685,-0.014757174,0.0020201104,0.015650444,0.011967986,-0.02659755,-0.03642351,0.0030375714,0.038939252,-0.029532578,-0.017309371,-0.008982826,-0.017701317,-0.033597864,-0.011503122,-0.008057654,0.008905348,-0.01349019,-0.004853734,-0.07022191,0.0026319544,0.0048765214,-0.02694392,0.028529929,-0.010710117,0.035275023,-0.07109695,-0.050898124,0.009634548,-0.004320507,0.0012897715,-0.033087425,0.038465273,0.0018913611,-0.07142509,0.034144763,0.0029897178,0.031446725,-0.04338737,0.01314382,0.017874502,0.05341386,-0.02690746,0.018093262,-0.049038664,-6.5941276e-05,0.063987255,-0.007961947,0.005956648,0.08137866,-0.004949441,0.014957704,-0.019651925,-0.02506623,0.046595845,0.0031742963,0.005564703,-0.011585156,0.013699835,0.001303444,-0.008303759,-0.045866646,0.022714563,-0.014292309,0.0002800012,-0.023370843,0.01449284,-0.020855105,0.00053094834,0.016735127,0.03861111,-0.012359931,-0.057533838,-0.020071216,0.0059976657,-0.015449913,-0.011557811,0.022514034,0.011904181,-0.031337347,0.015495488,0.01352665,-0.008568093,-0.004607629,-0.017081497,-0.0184214,0.04408011,-0.010555162,-0.009516053,0.0029441428,0.018977417,0.02789188,-0.032267075,-0.02528499,0.0034636974,-0.018102376,0.03864757,-0.03759023,-0.0031332788,-0.047799025,-0.031045666,0.010299942,0.030571688,-0.019724846,-0.049658485,-0.08159742,-0.024719862,0.031118587,0.00067963667,0.0042749317,-0.056695256,-0.060815234,-0.002670693,-0.0014868833,-0.05509102,-0.010427552,0.028110638,-0.076420106,-0.016507253,0.0004731251,-0.04240295,-0.033069197,0.015477259,0.010928877,-0.029368509,0.0040994682,-0.035712544,0.008189822,0.020891564,-0.0142649645,0.0033110213,0.0061252755,-0.019396706,-0.015942123,0.00066539453,0.036915723,-0.020326436,-0.013225855,0.002743613,0.022878634,0.011111177,0.032959815,-0.048309464,0.014009745,-0.011083832,0.089618616,0.018995646,-0.044153027,-0.0022912815,0.021967134,0.01359957,0.016671322,0.00336799,0.0006500129,0.03831943,-0.018612817,-0.015659558,0.029605499,0.04105393,-0.007601904,0.0032107565,0.019287325,-0.024428181,-0.019925375,-0.013462845,0.007857124,0.0014196602,0.021256164,0.014666024,0.007378587,-0.03759023,0.077951424,0.014246735,-0.010536932,-0.019524315,-0.035749003,-0.019542545,-0.026871,-0.007497082,-0.014994164,-0.03737147,0.0041928967,-0.034746353,0.0132532,-0.0011308289,-0.031537876,-0.030553456,0.0060705855,-0.029824257,0.0005286696,-0.023735443,0.04039765,0.008659244,-0.041819587,-0.03886633,-0.01277922,-0.00021334781,-0.13614154,-0.020326436,0.0037895583,-0.014912128,-0.03645997,-0.00077990163,-0.014656909,0.036095373,-0.007948274,-0.020180594,0.018685736,-0.049549103,-0.0116398465,-0.022933323,0.016735127,0.0074742944,0.017838042,-0.0008989662,0.01803857,0.024646942,-0.0057971356,-0.015586638,-0.042038348,0.03948615,-0.0128065655,-0.0056877555,-0.006075143,0.032157697,-0.03828297,0.077951424,-0.008932693,-0.023680752,0.02792834,0.0015210644,0.034418214,-0.006945625,-0.008627341,-0.011111177,0.008732163,0.00075939286,0.0074196043,0.012113826,0.016634863,-0.018202642,-0.09435841,-0.0024519332,0.020217055,-0.018813346,0.022149434,-0.038027752,-0.009497823,0.024555791,-0.032741055,-0.023079162,-0.062383015,-0.0142649645,-0.044481166,0.02667047,0.050205383,0.04185605,0.017710432,-0.05272112,-0.03915801,-0.018959185,-0.01257869,-0.0012954684,-0.07412312,-0.0009878374,-0.009060304,0.02898568,-0.033834856,0.01853078,0.024008892,-0.06522689,0.05334094,-0.008818756,-0.0052274484,-0.047215663,-0.01354488,-0.0068954923,0.02696215,-0.017045038,0.014192045,-0.09625433,0.05286696,-0.003819182,0.00010026492,-0.0126333805,-0.001598542,0.028183559,0.0033133,-0.01349019,-0.0051362985,-0.07237305,-0.071899064,0.012369046,-0.02812887,-0.0021967134,-0.025449062,-0.014328769,0.033543173,-0.02712622,0.031574335,-0.02667047,-0.042548787,-0.0075791166,0.04236649,-0.018959185,0.04214773,0.012022676,-0.04940326,-0.020964485,0.030753987,-0.0055601457,-0.0075700018,-0.01394594,0.03890279,-0.01425585,0.019305555,0.030316466,-0.021256164,-0.0041268133,0.009046631,-0.034910426,-0.008021194,-0.019378476,0.057059858,-0.0062665576,-0.007497082,-0.017564591,0.0524659,-0.05388784,0.0066220425,0.018685736,0.0059976657,0.04356967,-0.029204438,0.030662837,-0.024847472,-0.04262171,0.016197342,-0.009743928,-0.0125148855,0.0076884967,-0.03882987,0.016078848,0.0035092724,0.010254367,-0.021383774,0.019159716,0.031902477,-0.009488708,0.0043774755,-0.033780165,-0.045757268,-0.00056114176,-0.012177631,0.031355575,0.020928025,0.034728125,0.015659558,-0.045028068,-0.030535227,0.02648817,-0.020381125,-0.0043524094,-0.008481502,0.00047853714,-0.016972117,-0.004555218,-0.037954833,0.021274393,-0.04065287,0.014866554,-0.023808362,-0.016051503,0.009753043,0.027983028,0.016443448,-0.010217907,0.004646368,0.009953572,-0.041783128,0.008021194,-0.0006260861,-0.017026808,-0.0041951756,0.03904863,0.033944234,-0.0134355,-0.011421086,-0.043642588,0.033670783,-0.014583989,0.039668452,0.043897808,0.004397984,-0.044845767,-0.02696215,0.06723219,0.06511751,-0.013663375,-0.04098101,-0.057861976,-0.011831261,-0.014155584,0.008084999,0.008973711,-0.006330363,0.009279063,0.03912155,0.009753043,-0.030826908,0.036150064,0.04138207,-0.012241436,0.010281713,-0.024245882,0.009825963,-0.0058244807,-0.015522833,0.00064260705,-0.009561628,0.016963003,0.028220018,0.0054416507,-0.024519332,-0.009434018,0.014802749,0.0030580803,0.014155584,0.030188857,-0.017272912,0.0031287214,0.08210786,0.0010220186,0.021584304,0.033944234,-0.05432536,0.0009377049,0.018940955,-0.012013561,0.020964485,-0.00908309]
9	J06.900	急性上呼吸道感染	呼吸系统疾病	1	[-0.053777587,0.05757709,-0.010284233,-0.0034113328,-0.018723514,0.05037995,0.034268595,0.012987725,-0.02655999,-0.014969678,-0.012960325,0.018221175,0.027783867,0.010448634,0.043475084,-0.024952507,-0.026048517,-0.003943355,-0.019983927,-0.0033839326,0.043073215,-0.0009144838,0.02794827,0.010978373,-0.022687418,0.024568904,-0.01273199,-0.0242401,-0.025135176,0.01943592,-0.0070327343,-0.059257638,0.009188222,-0.098421745,-0.017353501,-0.019508988,-0.038177703,0.03916411,-0.05819816,0.026578257,0.0021280872,0.008393615,0.030578695,-0.023345025,0.016339691,-0.019801257,-0.0063203275,-0.014914877,-0.051804766,-0.030889232,-0.00485898,0.006914,0.028770277,-0.030012423,-0.018102441,0.016458426,0.011553778,-0.009042087,-0.017664038,-0.018796582,0.0061011254,0.05860003,-0.03916411,-0.0047859126,0.061084323,0.018814849,0.013828,0.024203567,-0.005352185,-0.046215113,0.008991853,-0.036917288,-0.0055302866,-0.0172165,-0.06977934,-0.021682743,0.10945492,-0.011316309,0.051037557,0.02279702,0.06382435,0.016458426,0.028569343,-0.007950643,0.00519235,0.004447976,-0.023874763,-0.020458864,0.002092695,-0.008822885,-0.005868223,0.034853134,-0.036424085,-0.0075533395,0.00045638566,0.0026852258,-0.011298042,0.02933655,0.009498758,0.03956598,0.039821718,-0.018997516,0.04303668,-0.046068978,0.06711238,-0.040223587,0.038908374,0.02122607,-0.041904137,-0.022723952,-0.026176386,0.030542161,-0.007781675,-0.0033656657,-0.017335234,-0.031492036,0.013115593,-0.015983487,-0.001282104,-0.0042561744,-0.024367968,0.015800819,-0.015097545,-0.041794535,0.01823031,-0.016832896,0.011279776,0.025847582,0.075697795,0.012074383,-0.03825077,0.023308491,-0.054179456,0.042306006,-0.0018734931,-0.012302718,0.03788543,-0.007448305,0.0242401,-0.04212334,0.04997808,0.037520096,0.021317406,0.014640874,-0.022559552,-0.037118226,0.009206489,0.034871403,0.012257052,-0.015727751,0.016157022,-0.009201922,0.057723224,0.012202251,-0.002564208,0.038689174,-0.02308929,0.008032844,0.0064755958,0.022194214,0.009818428,-0.028514542,0.01273199,-0.02984802,0.017316967,0.04135613,0.018942716,0.0019271519,-0.051695164,0.009809295,0.03518194,-0.027509864,0.020276196,0.0035300674,0.04015052,-0.013371329,0.040625457,0.0068043987,0.027619466,-0.047311123,-0.05929417,0.0018049924,-0.0044160094,-0.028989479,-0.023162358,-0.00038902665,0.0312911,0.02349116,-0.004027839,0.033537924,0.0019260102,-0.013919334,-0.02170101,0.02498904,0.01075917,-0.012722856,0.057650156,-0.024806373,0.0010440642,0.04398656,-0.0041557066,0.013873667,0.023765162,-0.015481149,-0.035455942,-0.023162358,-0.06404355,-0.016120488,0.003740136,-0.06513956,-0.004986848,-0.040771592,0.00623356,-0.0067450316,-0.022997955,-0.017106898,0.020550199,-0.010941839,-0.012311852,-0.070510015,0.030998832,0.06305714,0.00050776114,0.01692423,0.035127137,-0.0042059408,0.013416996,0.03457913,-0.014850943,0.00081401615,0.0033268488,0.016157022,-0.029427884,-0.012165717,0.08066638,0.0111610405,-0.016759828,0.02621292,-0.036241416,1.1149197e-06,-0.03366579,-0.009361757,0.015554217,0.01614789,-0.013389596,-0.024715038,-0.0048087463,-0.026340786,-0.03704516,-0.020002192,0.02372863,0.0021737544,-0.092137955,-0.013243461,0.008804618,-0.017554436,0.0063340277,0.014613474,0.048516735,0.013325661,0.015499416,0.047420725,0.010174631,0.03048736,0.007466572,-0.06404355,0.025610114,0.0054663527,0.0060965586,-0.015983487,-0.02036753,-0.0012672623,-0.037995033,0.044972967,0.02493424,-0.036478885,-0.0032149644,-0.025390912,0.007197136,0.016887696,-0.022650884,0.009873228,-0.0207146,0.032441914,-0.0011896282,-0.0079780435,-0.037995033,-0.05107409,0.00896902,0.00038303286,0.027235862,-0.014595208,0.056663748,0.019125385,-0.041794535,0.01943592,-0.0007306737,-0.13195968,-0.0003379366,-0.00937089,0.02261435,-0.030797897,0.029300015,0.0076629403,-0.016394492,-0.016403625,-0.027144529,-0.008425581,-0.062399536,-0.0055120196,0.024331434,0.047128454,0.022997955,0.009037521,-0.009398291,0.006516696,-0.018011106,-0.04669005,-0.00019565501,0.0415388,-0.01967339,-0.030962298,0.032843783,0.046470847,-0.02372863,-0.022175947,0.011727313,-0.0016873996,-0.020568466,-0.008854852,0.0010942981,0.00623356,0.0060508917,0.009791028,0.03395806,-0.06353208,0.015289348,0.026888793,0.049685813,0.0240209,0.00902382,0.027327197,0.02730893,0.022815287,-0.035255007,-0.016622826,-0.05235277,0.0019671107,-0.009074054,0.0006484729,0.027199328,0.041794535,4.3776203e-05,0.012750256,-0.010457767,0.03788543,-0.009891495,-0.050124217,-0.052571975,0.013015126,-0.014485606,-0.0030300126,0.019636856,0.040625457,-0.027455065,-0.018431244,0.023016222,0.016083956,0.025007308,-0.021901945,0.028825078,0.033939794,0.061997663,-0.013773199,-0.010393834,-0.017837573,-0.046434313,-0.039821718,0.010421234,-0.0141385365,-0.043767355,0.0027468766,-0.027984804,0.022815287,-0.03395806,-0.014019802,0.20546545,0.02036753,-0.008781784,0.0042379075,0.037921965,-0.0138371335,0.033811927,-0.0027925435,0.018275976,-0.05969604,-0.031090166,-0.03611355,0.02274222,-0.0055713872,-0.0058956235,0.054690927,-0.042415608,0.0061193923,0.12786789,-0.03985825,-0.0018403844,0.0108231045,0.018595645,-0.027564665,0.02314409,-0.007562473,-0.004523327,0.03651542,0.0009978263,-0.004292708,-0.037282627,-0.0027765601,0.03401286,-0.059403773,-0.017371768,-0.018349044,0.025719715,-0.016440159,-0.029537484,0.026706124,-0.0018814848,-0.04482683,-0.027674267,0.016549759,0.046653517,-0.06046325,-0.030651761,-0.03094403,0.027637733,-0.03934678,-0.01521628,-0.0027331763,-0.017737104,-0.0062244264,0.010457767,0.03963905,-0.0242401,-0.0049000806,0.01620269,0.038798776,0.0586731,0.012905524,-0.041904137,0.02111647,-0.003322282,0.04581324,0.003367949,0.06353208,-0.01006503,0.02701666,-0.03574821,0.0023176058,0.0077908086,0.04212334,-0.005274551,0.015965221,0.0046991454,0.035839546,-0.00071354856,0.038798776,-0.004046106,-0.009644893,-0.020276196,-0.09389157,0.002609875,-0.033702325,0.032697648,0.016558893,-0.03280725,0.011389377,-0.0050873156,-0.0040506725,0.015179747,0.050489552,-0.014028935,0.047530323,0.025938917,-0.020477131,-0.033811927,0.04818793,0.01169078,0.0071469024,-0.019454187,-0.034542598,0.012430587,0.03457913,0.023290224,-0.016805496,-0.04639778,-0.001664566,0.010740903,0.0030277292,0.017919773,-0.029007746,0.008407314,0.011151907,0.005457219,0.029921088,0.037995033,0.037848897,-0.018193776,-0.03633275,-0.020915534,0.03644235,0.0062929275,-0.016275756,-0.0021737544,-0.030980565,-0.012905524,0.028368406,-0.030596962,-0.018641314,-0.03713649,0.039967854,0.099883094,-0.0058179894,0.0726655,0.016942497,0.043511618,0.05717522,0.0009247589,0.026103318,-0.0025733414,0.0022570968,0.050197285,0.008521482,-0.017536169,-0.048334066,-0.017600102,0.013343928,0.041100398,0.004249324,0.03686249,-0.009873228,-0.023619028,0.038177703,-0.040369723,0.0073478376,0.015554217,-0.027199328,0.007178869,0.051220227,-0.012923791,-0.03697209,0.004607811,0.014092869,-0.02637732,0.051110625,-0.016485825,0.0056946883,-0.025957184,0.0014841809,-0.051914368,0.017664038,0.021481806,-0.027911736,0.009891495,0.02487944,0.01652236,0.027071461,-0.014038068,-0.0034661335,0.00023190328,-0.003984455,0.008512349,-0.022870088,0.02845974,0.004795046,0.009699694,-0.014074602,-0.028916413,0.08497735,-0.016485825,0.00020535928,-0.02685226,0.037447028,0.03467047,0.019015783,-0.0011445319,-0.025062108,0.008626517,-0.05235277,0.009507892,0.011097107,-0.01897925,-0.031090166,-0.011471577,-0.0045849774,-0.004646628,-0.022851821,-0.0027240429,0.014905743,0.006708498,0.043438554,-0.03182084,-0.026450388,0.027126262,0.057029083,0.0048361467,-0.049612746,0.020696333,-0.034506068,0.08000877,-0.077159144,0.012631522,-0.008804618,-0.032441914,0.008731551,0.026870526,0.032514982,0.013060792,-0.043182816,0.032021776,-0.027144529,0.018403845,0.022468217,-0.032588046,0.032441914,0.0051192828,-0.06692971,-0.0625822,-0.038396902,-0.031254567,0.014631741,-0.0045986776,0.057138685,0.022778753,0.0017821589,0.011060573,0.031674705,-0.008781784,0.008873119,0.0060326247,-0.04749379,0.045922842,-0.014284671,-0.016211823,-0.0414292,-0.0242401,0.0017285,-0.035656877,0.041648403,0.01273199,-0.020805934,0.013353062,-0.045776706,0.021043403,0.038031567,0.0024135066,-0.021207804,0.009206489,-0.012540188,0.011489844,0.0020104945,0.03240538,-0.032332312,-0.08052024,0.07295777,0.01657716,-0.00059024733,-0.012403186,-0.04252521,-0.01553595,0.02314409,-0.03355619,-0.013782333,-0.026998393,0.041794535,0.00093275064,-0.0056764213,-0.019837791,-0.029172149,-0.030633496,0.056517612,0.010686103,-0.06448195,0.029245215,0.038104635,-0.013937601,0.0060508917,-0.011955649,-0.029007746,-0.028624143,-0.006598897,0.002100687,0.022687418,-0.01767317,-0.06309368,0.014348605,-0.03510887,0.02325369,-0.05501973,0.041063864,0.015289348,0.021755809,0.034560867,0.01454954,-0.025025574,-0.019527255,0.004406876,-0.060244046,-0.030816164,-0.017874105,0.035821278,-0.025500512,0.05311998,-0.038177703,0.029774955,-0.026687857,-0.044351894,-0.011170174,-0.04391349,-0.029774955,-0.018778315,-0.008526049,0.028496275,-0.039017975,-0.024495836,-0.025537046,-0.010101564,0.0041488567,-0.02122607,0.019125385,0.0017616086,0.0038634373,-0.011188441,-0.024057431,0.02909908,0.030998832,0.025390912,0.017362634,-0.026395587,-0.020824201,-0.060024846,-0.029464418,0.03576648,-0.018997516,-0.001760467,0.025646647,0.043255884,-0.030852698,0.016029155,-0.061011255,0.026870526,0.019801257,-0.0019134518,-0.029665353,-0.007822775,0.022413416,-0.03766623,0.0034044827,0.036204882,-0.026121585,0.009338924,-0.03019509,0.057248287,0.0014031219,-0.03395806,-0.0036784855,0.009973696,-0.017664038,0.0022159964,0.0059093237,0.0021166704,0.050014615,0.0096540265,-0.029318282,0.05107409,0.0065806303,-0.009325223,-0.057759758,0.004406876,-0.021207804,0.03684422,-0.13261728,-0.05023382,-0.029482685,-0.017253034,-0.05849043,0.022230748,-0.0055896537,0.0060828584,-0.020294461,-0.017353501,-0.027674267,-0.024660237,0.040479325,-0.026121585,-0.03478007,-0.002093837,-0.011818647,-0.012183984,0.07518633,0.0073798043,-0.027126262,-0.044461496,0.08833845,-0.02261435,0.018778315,-0.04807833,-0.018997516,-0.008713284,-0.04818793,0.036588486,0.016531494,-0.041100398,0.043657754,0.07547859,-0.032478448,-0.040004384,0.005429819,-0.018148107,0.016823763,-0.004959448,-0.014832676,-0.008489515,0.007320437,0.035200205,0.016403625,0.016750695,-0.02637732,-0.005402419,0.04738419,-0.029263481,-0.021627942,0.039712116,0.018668713,-0.024093965,-0.01700643,-0.01414767,-0.054179456,0.018924449,0.0022765053,0.01310646,0.0034866836,-0.016613694,-0.03777583,0.0111610405,-0.024861174,0.008489515,-0.046799652,0.013325661,-0.03043256,-0.0076355403,-0.054398656,0.012330119,0.03923718,-0.0061376593,0.018376444,-0.027856935,-0.005352185,-0.05092796,-0.012695456,-0.056663748,0.026450388,-0.008813752,-0.0061148256,-0.014412539,0.0013506047,-0.011024039,-0.031729504,-0.0382873,0.01348093,0.017426567,-0.03390326,-0.02730893,-0.019636856,-0.00623356,0.004292708,-0.010284233,-0.012887257,-0.022559552,-0.025555313,-0.015490282,-0.012914658,-0.026468655,0.040369723,-0.032076575,-0.014622607,0.013709266,-0.013124727,0.033008184,-0.015755152,-0.04051586,-0.032332312,0.015006212,0.014978811,-0.0007769117,-0.08198159,-0.0053476184,-0.041977204,-0.041977204,0.002092695,-0.021719277,0.032003507,0.02210288,0.06174193,-0.03523674,0.0039890218,-0.025610114,0.04292708,-0.033793658,-0.023125824,0.041319598,-0.003580301,-0.019582056,-0.02210288,0.030268159,-0.010786571,0.04541137,-0.0031213467,0.050526086,-0.027455065,-0.036716353,0.001590357,0.043876957,0.0105399685,0.0047448124,-0.03876224,-0.04420576,0.032770716,0.010265966,0.0051375497,-0.006690231,9.3403505e-05,-0.01812984,0.037246093,0.030048957,0.014275538,0.022924887,0.002819944,0.0009892636,-0.0028062437,0.04033319,-0.002589325,-0.029592285,-0.04778606,-0.019856058,-0.014321204,0.044863366,0.020751134,-0.043840423,-0.04201374,0.027546398,0.019527255,0.026578257,-0.03558381,-0.010412101,0.044278827,0.007338704,-0.0011428193,-0.03478007,0.027235862,0.0012341535,0.014905743,0.004607811,0.0043749087,-0.02626772,-0.0029135614,0.099444695,-0.0015401231,-0.01273199,0.0014293805,-0.042379074,-0.00043583545,-0.0054891864,0.024587171,0.008233779,0.07083882,-0.0046557616,-0.0013426129,0.010850505,0.006534963,0.04102733,0.015892154,-0.010558235,-0.043657754,-0.01492401,-0.014942277,0.033172585,-0.030158557,0.019308053,-0.010640436,0.004162557,0.028916413,0.02199328,-0.024167033,0.011416777,0.023399826,-0.012247918,-0.0033017318,-0.03366579,-0.015599884,0.0022981972,-0.047311123,0.058819234,-0.028971212,0.028039604,0.02794827,0.028861612,-0.028642409,-0.0207694,-0.042854015,0.015398948,-0.014485606,0.00969056,-0.029117348,0.044571098,-0.015727751,-0.06638171,0.03441473,0.039785184,-0.026176386,0.0108413715,0.0052928175,-0.00054629275,0.0052288836,-0.0065760636]
10	K29.700	胃炎	消化系统疾病	1	[-0.046286695,0.005988687,-0.01633865,-0.009663039,-0.02843589,0.054732636,0.011239737,0.015628675,0.007971086,-0.026849972,0.024452653,0.021004202,-0.021870924,0.010898581,0.034521393,-0.045364648,-0.009418697,-0.037988283,-0.043631203,-0.025116526,-0.016255666,-0.0088793,0.018450135,0.0066018472,-0.0021276206,-0.00031724136,0.00433592,-0.019860866,0.019418282,-0.034373865,0.005988687,-0.046471104,-0.0010136741,-0.039352912,-0.008602686,-0.012392295,-0.021815602,-0.009132863,-0.047282506,0.030206218,0.0030957686,1.5181339e-05,-0.0047900276,0.0035383506,-0.012862538,-0.050675634,-0.02017436,-0.02177872,-0.026296744,0.0026762378,-0.0019950764,-0.013756922,0.07453818,-0.05447446,0.01612658,0.016246445,0.017979892,0.034816448,-0.04374185,-0.048942186,-0.00049963355,0.015582573,0.004955996,-0.03370999,-0.0074501294,0.061813947,-0.016624484,0.027458522,-0.022885175,0.04053313,-0.0012009646,-0.017445106,-0.0021829433,-0.018772852,-0.056539845,-0.0015847661,-0.001991619,0.0056751915,0.049642943,0.025356257,0.040201195,0.036642097,0.020524738,0.010105621,0.036513012,0.029265732,0.013471088,0.021797162,-0.010179385,-0.039832376,-0.017408224,-0.047909494,-0.022239743,-0.0019432114,0.023880985,0.021723397,-0.07232527,0.019123228,0.025577549,0.003729675,0.037637908,0.032124072,0.006836969,-0.017989112,0.033433378,-0.02723723,0.06933784,0.032363806,0.020192802,-0.015269077,0.040053666,0.021077964,0.00927117,-0.035812255,-0.0062837414,-0.0026923735,-0.0014141876,-0.05687178,0.037803873,0.0041469005,-0.0346136,-0.0022405712,-0.048684016,-0.02602013,0.0070213783,0.052888542,0.030095574,-0.0026370508,-0.008455159,0.010778715,0.022405712,0.0132036945,-0.023253994,-0.016642926,0.0012355413,-0.025927925,0.067124926,-0.012115681,0.0012136427,-0.03813581,-0.014642086,0.04152894,0.012871758,-0.01715005,0.021354578,-0.05366306,-0.0062422496,-0.014642086,0.028011749,-0.047319386,-0.011433367,-0.0030266151,0.06933784,-0.013489529,0.050085522,0.014098079,-0.009188185,0.017970672,-0.006574186,-0.027181908,0.06258846,0.051339507,-0.021834042,0.0020423313,0.015794644,0.025042761,0.04577035,-0.0014579848,-0.039279148,0.012613585,0.009206627,-0.023493726,-0.024028512,-0.0024342006,0.032566655,0.0020215854,0.028196158,0.004575652,0.017786263,-0.030943854,-0.022553239,-0.006265301,0.04293045,0.037766993,0.010741833,-0.02661024,-0.016569162,0.038172692,0.00826614,0.028583417,-0.010631187,-0.010953903,0.0038795073,0.00867184,-0.009095981,-0.009105202,0.010714171,0.016652146,-0.0029735975,0.036660537,-0.009229678,0.041086357,0.005988687,-0.017887687,-0.020119037,-0.018487018,-0.054253172,-0.017813923,0.023217112,-0.057756945,0.021133289,-0.029118204,-0.061518893,-0.07055494,-0.0037780823,-0.053884353,0.018662205,-0.053183597,-0.034005046,0.0014072723,0.009128253,0.018717527,0.045327768,-0.049716707,0.024323566,-0.02297738,-0.0140427565,-0.0036812676,0.018459355,-0.0058734315,0.004209139,0.022221303,-0.006209978,-0.025725076,0.03730597,0.030519713,0.0040454757,0.017611073,-0.0024365059,-0.007178126,0.0075746058,-0.016762791,0.051118214,0.052925427,-0.007763625,0.033783756,0.031349555,0.006832359,-0.045622822,0.02760605,-0.0024480314,-0.01713161,-0.020875115,0.012844097,-0.0014015095,-0.004677077,0.024858354,-0.001814125,0.009211237,0.010428337,0.023106465,0.03809893,0.009248119,0.028067073,-0.022627002,-0.033304293,-0.015370502,-0.010317692,0.040606894,-0.012346192,-0.016191123,-0.030206218,-0.019602692,0.045512177,0.018044434,0.019713338,0.004635585,-0.044663895,0.039020974,-0.01916011,-0.018652985,0.042487867,0.02922885,-0.022903616,-0.027034381,-0.0053570857,-0.023217112,0.009746023,-0.039279148,0.011313501,0.022331947,0.07988604,0.026849972,-0.0042852075,-0.04897907,0.0035798426,0.010621967,-0.14214256,0.013793804,-0.014227166,0.04901595,-0.027071262,0.0065050325,-0.057572536,-0.02458174,-0.03404193,-0.045106478,0.01310227,-0.041197002,-0.037951402,0.018016774,0.010704951,0.010760274,0.0034161794,-0.07520205,-0.03533279,-0.059232216,-0.021538988,0.0072288383,-0.009017607,-0.048757777,0.0055368845,-0.027145026,0.067309335,-0.028767826,-0.04329927,-0.0507494,0.010926242,-0.051044453,-0.013388104,0.057609417,0.039574202,-0.012678129,0.021538988,-0.018468576,0.00968148,0.033378057,0.030353745,0.043852493,-0.0067678154,0.025061203,-0.01998995,0.058715872,0.007602267,-0.012632026,-0.073136665,-0.015942171,0.050306816,-0.00057685486,0.037803873,0.01349875,0.0110000055,0.03424478,-0.013858347,0.05506457,0.0080955615,0.007846609,-0.07420624,-0.10312159,0.057166833,-0.02439733,-0.0535893,-0.008542754,-0.0023177925,-0.025706636,0.023346199,0.0066802213,0.038799684,0.0019005667,0.021004202,0.024286684,0.035793815,-0.00084943464,-0.0049652164,-0.0038841176,0.017915348,-0.07627162,-0.042598512,0.040606894,0.025430022,0.029579228,-0.026942177,-0.04009055,-0.001673513,0.030206218,-0.059342865,0.2538945,0.05163456,0.05004864,-0.012585924,0.06561277,-0.031699933,0.005868821,0.024544857,-0.00504359,-0.03570161,-0.054068763,-0.012761113,0.029966487,-0.0083721755,-0.011875949,0.07951722,-0.012134122,0.009570834,0.08940155,-0.0010759122,-0.032382246,-0.02078291,0.030114014,0.012346192,0.031515524,-0.025448462,-0.011608556,0.033285853,0.025485344,0.0035199095,-0.052704133,-0.018708307,0.023364639,-0.07383742,-0.040422484,-0.020801352,-0.03251133,-0.027790459,-0.0054216287,-0.001683886,0.007371756,-0.017979892,-0.027108144,-0.0017207678,0.007625318,-0.022700766,-0.033119883,-0.013673938,-0.0025540667,-0.039389793,-0.0039694067,-0.0025402359,-0.02218442,0.007422468,-0.023438402,0.024010072,-0.025466902,-0.02137302,-0.0009935043,0.029726755,0.019123228,0.03247445,-0.030519713,0.01934452,-0.017675616,0.037637908,-0.0029920384,0.0600805,-0.032345366,0.03063036,-0.046839923,0.010105621,0.014134961,0.0063575055,0.015195314,0.022534797,-0.055544034,0.021280816,0.030187776,0.046876803,-0.0015985968,-0.019860866,-0.020709148,-0.020303447,0.020303447,0.01108299,0.025245612,0.009178965,0.008805537,-0.024157599,0.0078143375,-0.024102276,-0.04883154,-0.027772017,0.028952235,-0.03714,-0.022405712,-0.034853328,-0.025466902,0.030409068,0.014430015,-0.027200349,0.025540667,0.010732613,-0.02058006,-0.013231357,0.0011329637,0.004923724,-0.023493726,-0.012613585,0.03607043,0.030833209,-0.0019374486,-0.029505463,-0.0026577967,-0.0042621563,-0.021612752,0.014134961,0.037435055,0.06826827,-0.007938813,0.015435046,-0.029302614,0.005808888,0.015831525,-0.03953732,0.010529762,-0.010133282,-0.030925414,0.015259856,-0.011018447,-0.0140427565,-0.064248145,0.023880985,-0.0069291736,0.046729278,0.034134135,0.009893551,-0.014614425,0.008321463,-0.001644699,0.042377222,0.008736383,-0.016670587,0.023272434,-0.035129942,0.029191967,-0.002602474,0.009441748,0.010373014,0.07988604,-0.015665557,0.02664712,-0.030575037,-0.013471088,0.008178545,-0.0507494,-0.020893557,0.018865056,-0.0043220893,0.0059564156,-0.0111383125,-0.011304281,-0.016181903,0.04879466,0.008436718,-0.010105621,0.07343172,0.007703692,0.033949725,0.016062036,0.011461029,-0.03905786,0.0010776409,0.002159892,0.01834871,-0.021502106,0.007178126,-0.00848282,0.04757756,-0.036771182,-0.029892722,0.040422484,-0.012253988,-0.014761952,0.026112335,0.009902772,-0.01952893,0.044663895,-0.006491202,-0.0102992505,0.07428,-0.0069015124,-0.027126586,-0.006569576,0.02157587,0.011258178,-0.010723392,-0.009985755,-0.0023327756,0.017491208,-0.014466898,0.024710825,0.0010620814,-0.020063715,0.0122447675,-0.07321043,-0.022442592,-0.03247445,0.053736825,-0.012715011,0.015647115,0.0025494564,0.0090590995,0.018394813,-0.022700766,0.052261554,0.07534958,-0.039463557,-0.022073776,0.04300421,-0.0120972395,0.021188611,-0.027901104,0.0112673985,0.0076160976,-0.02823304,-0.039574202,0.00907293,0.018809732,0.0032801777,0.021907806,0.012650467,-0.004091578,0.031552404,-0.015112329,0.022534797,0.014411575,-0.025946368,-0.016569162,0.0051680664,-0.031497084,-0.003489943,-0.0036121141,0.011608556,0.016698249,0.0042898175,-0.01006874,0.02622298,0.003427705,-0.0009479783,0.022036893,0.0075838263,-0.03404193,-0.0040616114,0.0056751915,-0.0011001158,-0.0072703306,-0.01731602,0.030482832,-0.008515093,0.034908652,-0.010778715,-0.021612752,0.011949712,0.018293388,0.010926242,0.05045434,0.021280816,-0.0011174042,-0.01330512,0.0094786305,0.0040846625,0.011931271,0.030538155,-0.028712504,-0.059232216,0.052556608,0.03269574,-0.00988433,0.01531518,-0.0035637068,0.034982417,0.07664044,0.0169472,0.05808888,7.477214e-05,0.054253172,-0.013729261,-0.007417858,-0.026776208,0.01391367,-0.028786268,0.06052308,-0.026425831,0.0149187,-0.022110656,0.021926247,-0.01855156,0.016974863,-0.035554085,0.016255666,-0.011147533,-0.015942171,0.04329927,-0.019012583,-0.003711234,-0.016412415,-0.015794644,-0.023217112,0.020285007,-0.04473766,0.030814769,0.05026993,0.04138141,-0.029984927,0.059047807,0.009367985,-0.018616103,0.039869256,0.00392561,-0.026149217,0.002501049,-0.084385626,0.0030127845,0.043815613,0.0066710007,0.010142503,-0.015601014,-0.014844936,-0.017675616,-0.011212076,0.001834871,-0.0024733876,0.011792965,0.017998332,0.008123223,-0.0015236805,0.024876794,-0.032216277,-0.018440915,-0.05606038,0.04455325,-0.019436724,0.015896069,0.032548215,0.0014199504,0.03533279,0.027310995,0.004294428,0.04861025,0.019104788,-0.01332356,0.0018567696,-0.0010845563,0.0041653416,-0.01230009,0.0041422904,0.046065405,0.011663878,-0.013176033,-0.015398163,-0.06052308,0.066645466,0.009690701,-0.014808054,0.020395651,0.037803873,0.007994137,-0.0012689654,-0.002846816,-0.002703899,0.003909474,0.015508809,-0.045106478,0.044258196,0.026425831,0.005407798,-0.017998332,-0.053884353,0.00785122,-0.042598512,-0.03286171,-0.031331114,0.035388116,0.018413253,-0.012281649,-0.03887345,0.010907801,-0.000953741,-0.048905306,0.0014015095,-0.0016089698,0.01731602,-0.12857005,-0.020672265,-0.025632871,0.0031395657,-0.009317272,-0.012742672,-0.018035214,0.0025748126,-0.0122355465,0.017841585,0.031533964,0.013655498,0.04816767,-0.014411575,-0.069891065,0.0076160976,0.016984083,0.009985755,-0.00036997086,0.032419126,0.0032502112,-0.019381402,0.034226336,-0.027310995,-0.045217123,0.017297577,0.04816767,-0.017869247,-0.013756922,0.020192802,0.047098096,-0.018062877,-0.004753146,0.04558594,-0.00231664,-0.04495895,-0.019381402,0.022774529,0.03675274,-0.02137302,0.058568344,0.0031994986,-0.022700766,-0.009663039,0.002602474,-0.03387596,-0.027255671,-0.0033654668,0.00015717998,-0.027845781,-0.02218442,0.07907464,0.069854185,-0.017657176,-0.006611068,0.025134966,-0.020911997,0.0062376396,0.009012997,0.094048664,-0.016569162,-0.0076068775,0.0022624696,-0.004942165,-0.04901595,0.020801352,-0.06741998,0.011977374,0.0041399854,-0.025761958,-0.067051165,0.00047658238,0.010917021,-0.033839077,0.034705803,-0.015508809,0.05679802,-0.045549057,-0.021907806,-0.010354574,0.02236883,0.037914522,0.025688194,-0.010824817,0.01954737,0.030943854,-0.028730946,0.011709981,-0.0076944716,0.0173068,-0.07619786,-0.02096732,-0.046065405,-0.05222467,-0.055285864,-0.040865067,-0.049495414,-0.04459013,-0.040975712,0.014494559,-0.020672265,-0.0050850823,0.0034622818,0.011175194,-0.0067447643,0.009137473,-0.029948045,0.002480303,0.01047444,0.013646277,-0.008561195,-0.023917867,-0.00033020764,-0.004393548,-0.06542836,-0.016467737,-0.034189455,-0.009395646,-0.025559107,0.045475297,0.020819793,-0.033746872,0.04595476,-0.02500588,0.009183575,-0.02679465,-0.007482401,0.01531518,-0.034798007,0.014798834,0.054990806,-0.051892735,-0.0112766195,-0.020063715,-0.01632943,-0.00282146,-0.049974877,0.042377222,-0.043262385,-0.062072117,0.012060358,0.010345353,-0.019584252,0.020709148,-0.0056336992,-0.05488016,0.046803042,0.0014718155,-0.067272455,-0.010465219,0.02742164,-0.020727588,-0.016412415,-0.03129423,-0.00023886748,-0.02823304,0.015564132,-0.035978224,-0.012014256,0.008409057,-0.02559599,0.006749375,0.008930013,0.024489535,-0.05687178,0.03450295,0.017297577,0.002045789,-0.040053666,-0.0054216287,0.042450987,0.036623657,0.0016285633,-0.012761113,0.020690706,-0.02460018,-0.05141327,-0.058715872,0.00036795388,0.0060209585,-8.5361266e-05,0.036125753,0.03428166,0.0006050925,0.029948045,0.030519713,-0.04234034,-0.0056567504,-0.0039163893,0.0049928776,-0.026388949,-0.01008718,-0.0073487046,0.012456838,0.0030289202,-0.06487514,-0.010741833,0.04414755,0.0018014469,0.03527747,-0.049274124,-0.013683159,-0.014088859,-0.013535631,-0.009598496,-0.006375946,-0.035756934,0.030833209,-0.012419956,0.036310162,0.013664718,0.008634958,-0.025430022,0.056761134,0.021502106,-0.043409914,-0.037877638,0.023327757,-0.0037619467,-0.029911164,-0.03264042,0.026093895,-0.015259856,0.028103953,0.015665557,-0.025245612,-0.0045318548,-0.00011561589,0.0057028527,-0.027882664,-0.02921041,-0.030759446,-0.06070749,0.008989946,-0.027956426,-0.049458534,0.04071754,-0.026296744,0.0022140623,0.012005036,-0.020819793,0.006975276,-0.049937997,-0.007030599]
11	I10.x00	原发性高血压	心血管疾病	1	[-0.0011443463,0.017959163,-0.0420814,-0.01246091,-0.005394936,0.0020427536,0.025676481,0.046214074,0.016009618,-0.026323335,-0.012056626,-0.037589364,-0.03431916,0.011715231,0.04333917,-0.028964652,-0.009648895,-0.03927837,-0.053437266,0.009487181,-0.024688233,0.029198239,0.0116074225,0.020896954,-0.046142202,0.0114636775,-0.011409773,-0.000921429,0.02946776,-0.029916964,-0.005255683,-0.043087617,0.03083334,-0.045423474,-0.007717319,-0.011742184,-0.018776713,-0.022514088,-0.06712899,0.038703386,0.04790308,0.0027738325,0.012380053,0.0092446115,0.0057587908,-0.037265934,0.00807219,-0.024023412,0.039601795,-0.07007577,-0.02016026,-0.018776713,0.03207314,-0.046789054,0.04786714,0.0047346065,-0.04488443,-0.07697554,0.008817868,-0.06490094,0.006405644,0.047651526,-0.032935612,0.030420072,0.014599119,0.0044808066,0.033025455,0.014024138,-0.0046178135,-0.01206561,-0.025317118,-0.00513889,0.0138803935,0.021256316,-0.05527002,0.02258596,0.026503015,-0.040068965,0.012856209,-0.04711248,0.069249235,-0.016890058,0.0057183625,0.017500974,-0.027688913,0.016000634,-0.002333613,-0.026538953,-0.03586442,0.0019349448,-0.025424927,0.022064883,-0.0075106854,-0.028443577,-0.02210082,0.023250781,0.008521394,0.05854022,0.010601207,0.009945369,0.052610733,0.006854848,0.023053132,-0.010924633,0.047579654,-0.038128406,-0.015299877,0.0017721085,-0.04107518,0.009936385,-0.014194836,0.03917056,0.041542355,-0.0035037885,-0.015048322,0.004788511,-0.045135982,-0.07755052,-0.018031035,-0.0046267975,-0.012775352,0.033097327,0.050238937,-0.00848995,-0.003798017,-0.00615409,0.040212713,0.060912017,-0.04236889,0.027796723,-0.0065359133,0.04402196,-0.044776622,-0.046609372,-0.011688279,-0.027257679,0.040068965,0.060265165,0.048154633,-0.038523708,0.016791234,0.0711898,-0.011562502,-0.032432504,0.012119515,-0.07855674,-0.010430509,-0.0036407956,0.0033263532,-0.015183084,-0.033384815,0.025928035,0.043411043,0.024867915,-0.0037575886,-0.00072995597,-0.024939787,0.020052452,0.0092625795,0.024867915,0.016018603,-0.0151741,0.02560461,-0.025460863,-0.016611552,0.0017238191,0.06845864,0.011041426,-0.002092166,-0.03142629,0.046142202,-0.03924243,0.031947363,-0.009496165,0.00022207506,-0.0037710648,0.058755837,0.01749199,0.0008136201,-0.012398021,-0.008934661,-0.00516135,0.015093243,0.0044561005,0.04384228,0.014356549,0.003422932,-0.018273605,0.011715231,-0.0047166385,-0.0319833,-0.013368301,0.020016516,-0.042045463,0.017168565,-0.03992522,-0.014877626,-0.035990197,-0.032881707,0.031677842,-0.016413901,0.016773265,-8.106722e-05,0.024382776,-0.010753936,-0.0021685306,-0.056563724,-0.036493305,-0.005902536,1.47745895e-05,-0.05070611,-0.016854122,0.06382286,0.017321292,0.0030276326,-0.022514088,0.073453784,0.01129298,0.007973365,0.016494758,-0.0043393075,0.060804207,-0.010789872,0.011149235,0.07618494,0.03791279,0.05706683,-0.0020741979,0.042907935,-0.021543808,-0.01574908,0.00010556286,-0.0021617927,-0.018255636,0.0053589996,0.044848494,0.05041862,0.02461636,0.028479513,-0.026143653,-0.005363492,-0.00910985,0.011562502,-0.00024228923,0.017500974,-0.030006805,-0.0022842006,-0.047507778,-0.01076292,-0.0049906527,0.033582468,-0.019441534,-0.065152496,0.04175797,-0.0015138163,-0.029791187,-0.024490584,0.009882481,0.006998593,0.014805753,0.022891419,0.0323786,0.017563863,0.034409,-0.038200278,-0.0025110485,0.012335133,0.036619082,-0.010691047,0.026233494,0.01323354,-0.028749034,-0.03487617,0.013512046,0.026808474,0.02220863,-0.0028861335,-0.0457469,-0.0005657159,-0.0025514767,-0.019998547,0.031462226,0.006028313,0.01777948,0.008620218,-0.040787693,-0.019693088,-0.0295576,-0.028623257,0.0011712986,0.029431824,0.0028816415,0.063032255,-0.002580675,-0.046070326,0.00029029787,0.0073040514,-0.11858977,0.033690274,-0.022729706,0.017384183,-0.03992522,-0.0013419959,0.001955159,-0.0070255455,-0.021471934,-0.041326735,0.027203774,-0.054155994,-0.055018466,-0.014302645,-0.0115894545,-0.019657152,-0.008355188,-0.03176768,0.0018462271,-0.009882481,-0.03613394,0.0023807795,0.056204364,-0.02298126,0.006338264,0.029377919,0.0340137,-0.005978901,-0.036080036,-0.018075956,-0.008144062,-0.07111792,-0.018093923,0.013323381,0.0063742,0.0019955873,0.0041978084,-0.026610825,-0.0023830254,0.0053589996,-0.007483733,0.07726303,0.009846544,0.008409092,0.0062753754,0.04064395,-0.030456008,-0.02395154,0.01929779,0.0054084123,0.0074298284,0.0115714865,-0.06637433,0.04254857,-0.0067021186,0.0068009435,0.014697944,0.03674486,0.014239756,-1.9674594e-06,0.0049592084,-0.046860926,-0.0140960105,0.020052452,0.011436725,0.018102909,-0.026592856,-0.00019582472,0.025119469,-0.0055566495,0.035648804,0.004253959,0.0043393075,0.017438086,-0.0045684013,-0.012550751,0.006252915,0.002710944,-0.0035936292,-0.07190852,0.00022726897,0.019639185,-0.00032286512,-0.011957802,-0.037445616,-0.014060074,-0.016045555,-0.005129906,0.0254968,0.23947945,0.057713687,0.023861699,0.03228876,-0.0048513995,-0.03723,-0.0038361992,6.653829e-05,-0.012811288,-0.026682697,0.0005558895,-0.0017664934,0.026251461,-0.016081491,-0.021597711,0.047148418,-0.014500294,0.017447071,0.10378402,-0.043482915,-0.008894232,0.071800716,0.035055853,-0.003294909,-0.006486501,-0.049412403,0.048873357,0.030132582,-0.011598439,0.0027536184,-0.024077317,0.0011993737,0.025766322,-0.0554497,0.029809155,0.0024099776,-0.040284585,-0.04991551,0.00736694,0.02152584,0.028281862,-0.052718543,-0.042728253,-0.028227959,0.003685716,-0.008022778,-0.007977857,-0.015210036,-0.03142629,-0.054443482,0.0069851168,0.019261854,-0.035738643,-0.002832229,-0.0034723443,0.001467773,-0.020789146,-0.010026226,-0.020214165,0.034660555,-0.0138983615,-0.013619855,-0.019028267,-0.047435906,-0.014122963,-0.011634375,0.024095284,0.04373447,-0.02578429,-0.012218339,0.020896954,-0.011706247,-0.033079356,0.01740215,0.037625298,-0.008269839,0.014994418,0.10838386,0.047831208,-0.0258921,0.0026031353,-0.009415309,-0.032522347,-0.09824982,0.015470574,0.014410454,0.039422113,-0.0036115975,-0.007164798,-0.0056105535,-0.005628522,0.017303325,-0.051999815,0.06252915,-0.02617959,0.011203139,0.06720087,-0.065583736,-0.029234175,0.08754081,0.020735241,-0.03139035,-0.007968873,0.008256364,0.010178955,0.042620443,-0.012290212,-0.00034055253,-0.022927355,-0.0014419438,-0.017177548,0.03297155,0.017042788,-0.02646708,0.042332955,0.049520213,0.0036205815,0.019657152,0.06260102,0.040823627,0.013125731,-0.04973583,-0.007825128,0.04402196,-0.024670266,0.018057987,0.00041326738,-0.04053614,-0.03913462,-0.0055656335,-0.009918417,0.00051686494,0.0021135032,0.0075106854,0.091853164,0.01206561,0.03665502,-0.0034835744,0.03528944,0.025424927,0.008265347,-0.042871997,-0.011526566,-0.0037418664,0.013350333,-0.026772538,0.012829256,0.009159262,-0.035325374,0.033905894,0.02587413,0.009145787,0.056851216,-0.0020023254,-0.016656471,-0.006495485,-0.011176188,-0.009936385,0.03837996,-0.0070524975,0.040140837,-0.013637823,0.025173374,0.024077317,0.017384183,0.02316094,-0.0319833,-0.028443577,-0.025101501,-0.0036924542,-0.034283224,-0.036619082,-0.003699192,-0.02220863,-0.0077936836,0.02587413,-0.0033982256,-0.01096057,0.00685934,0.031731747,0.007905984,0.01561432,0.024005443,0.008310268,0.05710277,0.035720676,-0.013458142,-0.008997549,-0.020034483,-0.056671534,-0.025730386,0.10306529,-0.012910114,-0.010439493,6.0467024e-05,-0.006405644,0.023196878,0.034786332,0.028677162,0.019028267,0.06508063,-0.03433713,-0.001347611,-0.023861699,-0.004761559,-0.026538953,-0.027491264,-0.054227866,-0.0013318888,-0.0021662847,-0.019028267,0.018120876,-0.020124324,0.03491211,0.0033847496,0.024688233,0.0076454463,0.014455373,0.00021351212,0.008710059,0.06540405,-0.026592856,0.019459503,-0.053437266,-0.03674486,-0.06116357,-0.023592176,-0.03712219,-0.0021730228,0.037265934,0.009855528,-0.030078677,0.0049412404,-0.004453854,0.0060013607,0.03449884,0.008251871,0.014410454,0.008952629,-0.045315664,0.00785208,-0.05516221,0.012353101,0.027473295,0.023394527,0.020807113,0.025658512,0.009747719,0.029593537,0.001040468,0.010646127,0.033205133,0.0048424155,-0.05110141,-0.0059249965,-0.0022347881,0.0080093015,-0.012083579,-0.037194062,0.007721811,-0.017105676,0.0021090112,0.008674122,-0.027509233,-0.044345386,-0.029898996,0.045782838,-0.012191388,-0.025766322,-0.011957802,-0.024472615,-0.033312943,-0.017770497,-0.039889283,0.025353055,-0.0010241844,-0.015955715,0.038236216,-0.004036095,0.012182403,-0.005120922,-0.022657832,0.0024301917,-0.023610145,0.016225236,0.030204454,0.055593446,0.040931437,-0.041039247,-0.0076544303,-0.046465628,-0.0138444565,-0.023250781,0.04369853,0.025928035,-0.025568673,0.0115714865,0.020573528,-0.048513997,0.023286717,0.00564649,-0.017878305,-0.052610733,-0.09336249,0.02452652,0.002084305,0.03740968,0.00085404847,-0.01614438,0.015407685,0.019441534,-0.056851216,0.03723,-0.019172013,0.0024369298,-4.1270585e-05,-0.022316437,-0.03131848,-0.012236307,0.01724942,-0.020375878,-0.022550024,-0.0044695763,-0.03924243,-0.060804207,0.020214165,-0.0029265617,0.012766368,0.014841689,-0.019926675,0.006383184,-0.010987521,0.025910066,-0.012685511,-0.026934251,-0.03809247,-0.05088579,0.018165797,-0.0115714865,-0.047471844,0.019154044,-0.050849855,-0.024652297,-0.0062753754,-0.0021494394,-0.02626943,0.015569399,0.025999907,0.019531375,-0.019028267,0.020411814,0.005430872,-0.036780797,-0.050059255,0.009891464,-0.015003403,-0.03866745,-0.014140931,0.028551385,0.00807219,0.017465038,-0.013745632,-0.024778074,0.0038272152,0.009559054,0.028407639,0.020789146,0.026934251,0.013799537,0.016934978,-0.0016216253,0.029881028,-0.045818772,0.035630833,0.0050984616,0.029719314,0.012999954,-0.009478197,0.0067200866,-0.02714987,-0.040679883,-0.012433957,-0.03122864,-0.016225236,0.029395888,-0.018920459,-0.03122864,-0.033402786,0.022442214,-0.0052332226,-0.011912881,-0.025353055,-0.041650165,0.019064203,-0.14978246,-0.035253502,-0.015138163,-0.024993692,-0.043015745,0.009132311,-0.009190707,-0.032612186,-0.030420072,-0.025353055,-0.043375105,-0.014653023,0.0037553427,-0.012442942,-0.052071687,0.051999815,0.009478197,-0.01061019,0.0020753208,-0.022550024,-0.0517842,-0.021741457,0.07532247,0.01521902,-0.006980625,-0.030114613,-0.011841008,0.012757384,-0.02404138,-0.005264667,-0.009981305,-0.0550544,0.050167065,0.04430945,0.012317165,-0.00086190953,-0.011526566,-0.02423903,0.030491944,0.021453967,0.032198917,0.026503015,-0.014329596,-1.673108e-05,0.01927982,0.014365533,-0.029539634,-0.012730432,-0.0017855846,-0.042728253,0.015434638,-0.0043640137,0.03498398,0.010385589,-0.039386176,-0.012011706,-0.007119878,0.002198852,0.006765007,0.04175797,0.018650936,-0.014437405,-0.047543716,-0.039781477,0.0058755837,-0.0013610871,-0.06270883,0.06418222,0.02927011,0.011230092,-0.04175797,0.007339988,0.03191143,-0.05106547,0.013467126,-0.03433713,0.045495346,-0.0040046507,-0.005264667,-0.029916964,-0.009487181,-0.007357956,-0.00059407187,-0.014203819,0.028138118,-0.020896954,-0.006890784,-0.027976405,0.032791868,0.012856209,-0.054659102,0.0004129866,-0.015210036,0.019800898,5.6747056e-05,0.032881707,-0.025065564,-0.02210082,-0.030060709,-0.0639666,-0.009586006,0.023879666,-0.0078026676,-0.009127818,-0.06349943,-0.030312262,-0.039386176,-0.0017507713,0.018111892,0.031947363,-0.044920366,-0.015003403,-0.014410454,-0.00057947275,-0.03712219,-0.02095086,0.030977085,0.00010738775,-0.007447797,0.01182304,0.0009045839,0.044093832,-0.01008013,-0.017671673,-0.007932937,-0.0062035024,0.017626751,-0.013512046,0.085456505,0.015039339,0.056132488,-0.071656965,0.0043752436,0.017411133,0.019926675,0.050813917,-0.019136077,0.018794682,0.006994101,-0.032324694,0.006598802,0.060444843,-0.0026166113,-0.0044808066,-0.023412494,0.007977857,0.02190317,-0.0138803935,-0.016710376,-0.0031758698,0.007950905,-0.03286374,0.009738736,0.00030405473,-0.02820999,-0.015254957,-0.021058667,0.011221107,0.0550544,-0.031588003,0.03769717,-0.04510005,-0.027868595,-0.017914241,-0.0064236126,0.030186485,-0.015811969,-0.0060642497,-0.04926866,0.018057987,-0.008719043,0.020286037,-0.055845,-0.030563816,0.027455328,-0.021939106,-0.031785652,-0.03945805,0.060732335,-0.0025469847,0.016252188,0.05174826,0.037373744,0.007115386,0.012658559,0.08905014,0.03974554,0.030402103,0.0050804936,-0.016539678,0.008144062,-0.018794682,0.05785743,0.005421888,0.051460773,-0.042979807,0.015677208,0.00963991,0.004878352,0.073453784,0.021166477,-0.008458505,-0.03139035,-0.059402693,-0.0275272,0.02113054,-0.0052152546,-0.020986795,-0.0061585824,0.008804392,-0.011894913,-0.005920504,-0.010466445,0.034409,0.007272607,-0.044129767,0.021400062,-0.040464267,-0.017635737,0.018615,-0.014509278,0.026503015,-0.018920459,0.014356549,0.027491264,0.06533218,0.011652343,-0.02461636,0.04664531,0.029916964,-0.014886609,0.0014632809,-0.017348245,0.03385199,-0.0041259355,0.0037396206,-0.0127484,0.03733781,-0.02655692,0.004393212,0.018282589,0.0030388627,0.033366848,0.018794682]
12	E11.900	2型糖尿病	内分泌系统疾病	1	[-0.034125727,0.030602954,-0.011209642,0.0011595793,-0.016728653,0.023123838,-0.04559732,0.036131,0.0034030883,-0.0077952626,0.017324813,0.027857,0.0021249542,0.0037169764,-0.016313145,-0.00183139,-0.069479905,-0.002626272,-0.062470496,-0.0028701562,-0.024749734,-0.036311653,0.032373372,0.0018686501,-0.05069179,0.06565002,0.024984585,-0.007086192,0.0376485,-0.000515149,-0.0040331227,-0.05802638,-0.0546662,-0.06716753,-0.007280396,-0.0105231535,-0.03905761,-0.031632688,-0.069335386,0.023683868,0.02966355,0.044441126,0.0123839,-0.06261502,0.052931912,-0.015012429,-0.037576236,-0.0035927761,-0.009059847,-0.019601066,0.016304113,-0.0054106168,0.046825774,-0.026556283,0.009610846,0.030241646,0.005627403,0.027315034,-0.038190465,-0.032246914,-0.028886732,0.0146782175,0.011543854,-0.017785484,0.049354944,0.014208515,0.005067372,-0.003023713,0.009926992,-0.021877319,-0.0015344383,0.0355529,0.03259016,-0.009190823,-0.0124019645,0.025743335,-0.013359437,0.01800227,0.05246221,0.028489292,0.05426876,0.005812574,-0.0058983853,0.015427936,-0.022563808,-0.0030756511,0.030331973,-0.06893794,-0.0048280046,-0.020522406,-0.001422658,-0.0175145,0.025869794,-0.0042589414,-0.03022358,-0.032535963,-0.00037175408,0.021516008,0.058857396,0.0034279283,0.021949582,-0.000668988,0.0032969536,-0.0069326353,0.0029717747,-0.01836358,-0.0074565345,0.0025472352,-0.023828393,0.0038998895,0.018571332,-0.00021212848,0.021046307,-0.0325179,-0.030458432,-0.008852094,-0.0036898782,-0.05835156,0.004060221,-0.04093642,-0.0018934901,0.04100868,0.012663915,-0.025653008,-0.0135852555,0.03488448,0.033945072,0.028362833,-0.04715095,0.014045925,-0.016927373,0.0226722,-0.041369993,0.007840427,-0.0042205523,-0.04812649,0.025779467,0.05802638,-0.0062732445,-0.054630067,0.011263839,0.060916863,-0.03475802,-0.011525788,-0.006133237,0.004351527,0.04888524,0.009394059,-0.0137839755,0.0201069,0.0018031626,0.05220929,0.05795412,0.046645116,-0.0148679055,-0.040358324,-0.0020131741,0.014208515,0.04711482,-0.007569444,-0.015446002,0.0020549505,0.018643595,-0.023250297,-0.020341752,0.063951865,0.02227476,0.05069179,0.02588786,0.0059706476,0.042779103,0.009601813,-0.01771322,0.041767433,-0.018029368,-0.010649611,0.06333764,0.0068423077,-0.047945835,-0.0011426428,-0.043284934,-0.033547632,-0.025418157,-0.022148302,0.012329703,0.01889651,0.012022589,-0.02874221,0.0025901408,-0.0067384313,-0.047223214,0.0030508111,0.018011302,-0.00788559,-0.008824996,-0.00913211,0.017722255,-0.025544615,0.008612727,-0.054088105,0.009619878,0.00150734,0.02966355,-0.018932642,-0.006955217,-0.00046575113,0.009818599,-0.01609636,-0.03475802,-0.004496051,-0.045019224,-0.027857,0.017089961,0.009710206,-0.040249933,-0.01589764,0.03495674,-0.0008665794,-0.030548759,0.003497932,0.032120455,0.09227857,0.03367409,-0.02950096,0.084907845,0.004292814,-0.047223214,-0.0046563824,-0.0016834787,-0.014795643,-0.0039608604,-0.015518264,-0.022943184,-0.008576595,0.049607858,0.009520518,-0.011697411,0.05213703,0.03459543,-0.003809562,-0.03866017,-0.018950708,-0.0068152095,0.010333465,-0.014118187,0.04823488,-0.0067790784,-0.015581492,-0.0453444,-0.004977045,0.03847951,0.019366214,-0.06861276,0.048307143,0.009619878,-0.022563808,0.023430953,0.02894093,0.03672716,0.012808438,0.022202497,0.017225454,0.021263093,0.009674075,-0.026375629,-0.024009047,-0.031199116,0.05249834,-0.024352292,-0.005966131,-0.020161096,0.003933762,-0.032987602,-0.0046563824,0.0124019645,0.018679725,-0.010487022,-0.031560425,0.070708364,-0.03511933,-0.0006486643,0.026176907,-0.019113299,0.0058667706,-0.0062280805,-0.0030056473,-0.04635607,-0.047223214,-0.028326701,0.00070229627,-0.023141904,-0.0009506969,0.05358227,-0.0006548743,-0.011381264,-0.067564964,0.0076868697,-0.123784795,-0.0051306016,-0.019004906,-0.00019011115,-0.007537829,-0.0048505864,-0.023864524,0.0032721134,-0.03392701,-0.074429855,0.037576236,-0.05820704,0.000113050504,0.009412125,0.022148302,-0.01898684,-0.03876856,-0.042598445,0.0012611976,-0.024334228,-0.026231105,-0.0438269,0.025508484,-0.026158843,-0.009836664,-0.016024098,0.030801676,0.019799788,-0.02050434,-0.039382786,-0.014976298,-0.028398965,-0.005785476,0.03387281,0.055930786,-0.0014599181,0.025707204,-0.058857396,-0.0061287205,-0.019402346,0.016782848,0.0141814165,-0.024894258,0.055352688,0.014885971,-0.043176543,0.049607858,0.0035747106,0.023774197,-0.003315019,0.02588786,-0.008639825,-0.018128728,-0.018553268,0.00629131,-0.009421158,-0.00028735434,0.003784722,0.032319177,-0.006173884,-0.018733922,-0.06095299,0.01994431,0.043863032,-0.0018844573,0.018571332,0.03376442,-0.01129997,0.0049589793,-0.019438477,0.032969534,-0.022328956,-0.016313145,-0.0037643984,-0.004651866,-0.0005944678,0.019221691,0.01589764,-0.046211544,-0.122989915,0.012374867,0.07135872,0.038190465,0.0077681644,-0.020143032,-0.059941325,0.01314265,0.054051973,-0.051558934,0.25349507,0.041948088,-0.016078293,-0.012591653,0.033836678,0.022292826,-0.0052118963,0.048776846,-0.060772337,-0.0016823496,-0.05213703,-0.05640049,0.019456543,-0.023683868,0.017089961,0.03978023,-0.024731668,-0.011878066,0.079849504,-0.038226597,-0.03492061,0.017523535,0.040141538,0.0033398592,0.018932642,-0.08165605,-0.005315773,0.01898684,-0.011083184,-0.014741447,-0.044296604,-0.039635703,0.018309383,-0.054196496,-0.021678599,-0.0022988347,0.014533694,-0.012447129,0.010017319,0.03495674,0.024659406,-0.02644789,-0.023051577,-0.023394821,-0.024352292,-0.013016192,0.011191577,0.025580747,-0.024370357,-0.04852393,-0.03920213,0.01346783,-0.017433206,-0.034450907,0.024731668,0.008192704,-0.026140777,-0.009683107,-0.010297335,0.024821995,-0.005144151,0.033529565,-0.02881447,0.005582239,-0.012528423,0.06669782,0.034288317,0.009565681,-0.039418917,0.031849474,0.015129855,0.012438096,-0.021967646,0.004069254,0.05387132,0.035823885,0.008102376,0.05860448,0.013639452,-0.04129773,0.0005210767,-0.021588271,-0.05983293,-0.028904798,0.015987966,0.0048189717,0.032012064,0.05502751,-0.008043664,-0.018842315,-0.04202035,0.037142664,-0.027441492,0.04700643,-0.026484022,0.007614608,0.08266772,-0.02969968,-0.019203626,0.055244297,-0.06525258,-0.017451271,0.018679725,-0.079849504,0.053510007,-0.03125331,-0.007050061,-0.046898033,0.021299222,-0.03448704,-0.03170495,0.024207769,0.0016337986,-0.009375994,-0.030024858,0.02917578,-0.022328956,0.0050041433,-0.010098614,0.04270684,-0.04747613,0.0058487053,0.0113090025,0.032246914,0.022455415,-0.0015366965,-0.02082952,-0.020883717,-0.042851362,0.025743335,-0.028868668,-0.014362072,-0.04519988,0.008730153,0.008892742,0.029446764,-0.02323223,0.04704256,0.013368469,0.03392701,-0.011001889,-0.031072658,-0.0041505485,-0.008016565,0.0273331,0.048632324,-0.001975914,-0.0040263482,-0.02247348,0.013341371,0.04202035,-0.009646976,0.009064364,-0.057412155,0.0015716983,-0.04306815,-0.026411759,0.014000761,0.0027459557,0.0072261994,0.0644577,0.019402346,-0.041406125,0.02933837,0.0026353046,0.06572229,-0.04353785,0.0052841585,0.03006099,-0.015662787,0.008278515,0.00675198,-0.044079818,-0.042237137,0.0206308,0.02957322,-0.067781754,0.07052771,0.034541234,0.0034663177,-0.022509612,-0.013440731,-0.0026465955,0.055966914,0.059796803,0.04772905,0.010803169,-0.029067388,-0.034396708,-0.012338736,0.02845316,0.0593271,-0.025020717,-0.038913086,-0.016069261,0.044404995,-0.008278515,0.04100868,0.045488928,-0.0073842728,0.038298856,-0.012817471,0.024460685,-0.025382025,-0.04165904,-0.0068919878,-0.0070319953,-0.025923992,0.046103153,0.043248802,-0.0020583377,-0.015735049,-0.0053112567,0.019890115,0.034053463,-0.010360563,0.03222885,-0.013991728,0.012094852,0.011019954,0.0048370375,0.005812574,0.028958995,-0.025092978,-0.004532182,-0.01222131,-0.035065133,0.010884463,-0.006878439,0.035661295,0.011074151,0.02456908,0.030693283,-0.010893496,0.0075604115,0.043212675,-0.010342498,0.043863032,0.011047052,-0.022202497,-0.022563808,0.027441492,-0.024171637,0.03643811,0.0024749734,0.0075242803,0.0068061766,0.0059525818,0.027802803,-0.022130236,-0.0005848705,0.02661048,0.042779103,-0.021985712,0.013251043,0.027260838,-0.03616713,0.0029220944,-0.045019224,-0.033005666,-0.019438477,0.0206308,0.026520152,-0.044657912,-0.04957173,-0.041875828,0.046103153,0.04100868,-0.03768463,0.0104237925,-0.04559732,0.020955978,-0.036131,-0.021696664,0.019041035,-0.016791882,0.037829153,0.029248042,-0.012248408,-0.0011979684,-0.0025607843,0.014515628,0.031975932,0.017704189,-0.029808072,-0.025978187,0.0021159216,0.029916465,-0.030476496,-0.023105772,-0.051161494,0.005085438,-0.038334988,0.040069275,-0.020161096,-0.062145315,-0.028218308,-0.011254806,-0.035932276,-0.007199101,-0.032770816,0.011850967,0.009213405,-0.063265376,-0.005135118,-0.030657152,-0.013910434,-0.061784007,0.00027098248,-0.026393693,-0.013901401,-0.0073481416,-0.037720762,-0.0002372508,0.019691393,0.01603313,-0.023250297,0.0035882597,0.009818599,0.0096379435,0.019059101,0.013892368,0.022057975,0.020919848,0.0151659865,0.033132125,-0.009001135,-0.018950708,-0.032644358,0.0032766298,-0.038298856,-0.032481767,-0.020757258,-0.014018827,-0.0070455447,0.0009038395,0.013278142,-0.031036528,0.0029153198,-0.037106536,-0.013702681,0.02484006,0.05748442,0.012564555,0.024171637,-0.0027436977,0.008084311,-0.0072713634,-0.057773463,0.014217547,0.05621983,-0.0025359443,0.034830283,-0.025345895,0.0028656397,0.004505084,-0.025237503,-0.0131878145,0.03920213,0.06673395,-0.016114425,0.028995126,0.0068648895,-0.002834025,0.01954687,0.02874221,-0.035823885,-0.013242011,-0.009764402,0.017234486,0.019763656,0.040249933,0.016701553,-0.014425301,-0.031090723,0.051269885,0.03735945,-0.020684997,0.006896504,-0.044332735,0.015012429,-0.05430489,-0.011670312,-0.0041053845,-0.017749352,0.0030508111,-0.027513755,0.011869033,0.07775391,0.03430638,-0.033366974,-0.00556869,-0.015599558,0.01846294,-0.121400155,0.002121567,-0.010857365,-0.006548743,-0.022943184,-0.0022401218,0.00073108816,-0.0019691393,-0.016764782,-0.034450907,0.0021339871,-0.020757258,-0.00337599,-0.02661048,-0.030458432,-0.023322558,-0.007307494,-0.007930754,0.057376023,0.05802638,-0.014307875,-0.0063229245,0.04924655,-0.008879193,-0.016186686,-0.038190465,0.02713438,0.015455035,0.024803929,3.0714877e-05,-0.03322245,-0.041803565,0.0059932293,0.06691461,0.011878066,-0.023774197,-0.02263607,-0.0056951484,-0.008694021,-0.0040444136,0.009990221,0.010188941,-0.009208888,-0.040394455,0.041803565,0.063988,-0.010767037,-0.0036176161,-0.02969968,-0.039021477,-0.0024140023,0.061386567,-0.0066119726,-0.011408363,-0.014949201,-0.0023778712,0.059110314,0.037503976,-0.01777645,0.02901319,0.014217547,-0.00032207396,-0.012727144,-0.054124236,-0.013820106,-0.0012352285,-0.038515642,0.031849474,-0.0031614623,0.0072261994,0.0031659787,0.023196101,-0.01849907,-0.06308472,0.006733915,0.021479879,0.0053248056,-0.0067655295,0.014642087,-0.03275275,-0.020269489,0.021895384,-0.014145286,-0.03985249,-0.017622894,0.04017767,-0.04523601,-0.027459558,-0.014741447,0.04675351,0.011525788,-0.020486275,-0.01005345,-0.016249916,-0.06120591,-0.0046202512,-0.0002829791,-0.015536329,-0.007172003,0.012329703,-0.012871668,-0.050438873,0.03275275,-0.007036512,-0.012853602,0.021136634,-0.01849907,-0.041153207,0.005582239,0.03127138,0.019962376,-0.04675351,0.020341752,0.0020820487,-0.047981966,0.009258568,-0.021028241,-0.003965377,0.015879573,0.015400838,0.0022107654,0.016159588,0.042056482,-0.031054592,-0.017451271,-0.00036977816,0.022581873,-0.0201069,0.026140777,-0.018164858,0.025580747,-0.06774562,-0.05148667,0.014000761,0.04996917,0.012194212,0.025905926,0.06940765,-0.028850602,-0.05148667,-0.03392701,0.01954687,-0.021931516,0.0012961995,-0.06333764,-0.011209642,0.024731668,-0.010568317,-0.026140777,-0.007135872,0.06467449,-0.027080182,-0.008129475,0.019980442,0.018715857,-0.023449017,8.163876e-06,0.021949582,0.016349277,0.02283479,0.0007643964,-0.0029966147,-0.010432825,0.017704189,0.026682742,0.017902909,-0.020703062,-0.027188575,0.0041302247,-0.00036977816,-0.038334988,0.0041889376,-0.020612733,0.03544451,-0.012754242,-0.031470098,-0.009872795,-0.063951865,0.044477258,-0.03022358,0.022383153,-0.02391872,-0.019655263,-0.008459169,0.020775324,0.04530827,0.0073978216,0.0050809216,-0.011634181,0.011318035,-0.010866398,-0.015816344,-0.00218028,-0.027513755,0.06478288,0.032933403,0.010387662,0.0489575,-0.010161843,0.03847951,0.00037542364,-0.017875811,-0.05397971,-0.030313907,0.02894093,-0.004557022,-0.012465194,-0.027983457,0.014389169,0.013476863,-0.005446748,-0.03278888,-0.0015265347,0.008016565,0.046500593,-0.013494927,0.0046563824,-0.011715476,0.040538978,0.0005236172,0.027315034,0.032084327,-0.004351527,0.029248042,0.043899164,-0.025418157,0.011019954,0.0067068166,-0.014669185,-0.022690266,0.00893339,0.036329716,-0.023394821,0.06080847,0.018228088,0.021895384,-0.005482879,-0.012781341,-0.013332338,0.009114044,-0.017857745,0.024731668,-0.008590145,0.0003898196]
\.


--
-- Data for Name: disposal_request; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.disposal_request (id, uuid, register_uuid, medical_technology_id, creation_time, disposal_time, disposal_state, disposal_result) FROM stdin;
\.


--
-- Data for Name: drug_info; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.drug_info (id, uuid, drug_code, drug_name, specification, unit, price, stock, min_stock_limit, delmark, vector) FROM stdin;
1	44444444-4444-4444-4444-444444444444	DRUG001	阿司匹林	100mg	盒	10.00	100	\N	1	[0.012073073,0.015416818,-0.04357171,0.0005075327,-0.022422759,-0.03982522,0.049903285,0.002526541,0.043684106,0.010883561,0.0043201745,0.024352204,-0.004619894,-0.00027264515,0.039975077,0.034842383,0.015501114,-0.038026903,0.010808632,-0.032969136,0.008349996,0.0402748,0.03079617,-0.0153793525,-0.035629146,-0.026019393,0.0017994873,0.018423378,0.025906997,-0.029897012,0.013543571,-0.06466447,0.014470829,-0.023378115,0.037427463,0.0066266092,-0.0055963234,-0.011417436,-0.03147054,0.052563295,0.01640964,-0.03223857,-0.008729328,0.013974418,0.034336608,-0.043384388,-0.024108682,-0.020380922,-0.032781813,-0.028229823,0.07882621,-0.0014658154,0.023509242,-0.05466133,-0.030440254,0.024127414,-0.045032844,0.024108682,-0.003533411,-0.024277274,-0.025213897,0.008855772,-0.028286021,-0.02113022,0.039562963,0.03654704,-0.0028122112,0.0049313214,-0.03772718,-0.030515185,-0.015032803,0.03177026,-0.03647211,0.013833925,-0.0524509,0.02304093,0.03435534,-0.020624442,-0.02341558,0.034036886,0.029372504,0.022441491,-0.004149241,0.015800834,-0.055148374,-0.015697805,0.029578561,0.012410257,-0.04439594,0.042148042,-0.009740882,-0.0066266092,-0.015369987,-0.0128692025,0.01071497,-0.021504868,-0.004477059,-0.0020254478,0.036134925,0.0034889213,-0.056309786,-0.00247971,0.01675619,-0.0088510895,0.051664136,-0.009061829,-0.013712164,-0.0024703436,0.058332894,0.00013017599,0.012831738,0.01946303,0.025382489,-0.03458013,-0.0208305,-0.0042616357,-0.032407165,-0.028623205,0.0043927627,0.0025031255,0.03665943,0.015042169,-0.018189223,-0.018554505,0.015754003,0.031508006,0.0088651385,0.05083991,0.031227017,0.031114623,0.013056528,0.01011553,-0.049004126,-0.01946303,0.014555125,-0.0044466187,0.020118667,0.056759365,0.017767742,-0.039862685,0.021467404,0.02120515,0.03967536,0.0031072474,0.041773394,-0.051252022,0.013955685,0.023246989,0.023752764,0.0042054383,0.013449909,0.03495478,0.033100262,-0.028941657,0.021579798,0.03620985,-0.026150519,-0.023546707,-0.005338752,0.0125132855,0.020661907,0.021561066,0.030683776,-0.03002814,0.018975986,-0.01570717,0.0067671025,0.080100015,-0.017112106,-0.04151114,0.04285988,-0.057808384,-0.009525458,-0.018357815,-0.035722807,0.017926969,0.038663805,0.001184243,-0.012878569,-0.026881086,-0.0697597,-0.019172678,-0.023209523,0.02781771,0.00052538706,-0.025345024,-0.0042148046,0.014152377,0.0035427772,0.00933345,0.019013451,-0.009993769,-0.002992511,-0.0028028449,0.022179237,-0.014648787,-0.016063089,-0.043759037,-0.0071698506,0.0047908276,-0.04439594,0.004573063,0.0445458,0.01379646,0.017514855,0.040649448,-0.079125926,-0.026899818,-0.022366563,-0.063203335,-0.053087804,0.0064627,-0.052188646,0.04514524,-0.02866067,0.00991884,0.008663764,-0.06818617,-0.012766174,-0.021167684,-0.012953498,0.027461791,-0.0029597294,0.05488612,0.007792705,-0.04357171,0.0424103,0.03506717,0.014470829,0.024839247,-0.032575756,0.024558261,-0.0122791305,-0.017627249,0.08894174,-0.0096191205,-0.0012539043,0.019987538,0.0034467734,-0.017664714,-0.0017069958,-0.011660959,0.06893547,0.0053012874,-0.036921687,-0.016212948,-0.01257885,0.0045754043,-0.026244182,-0.010396518,0.00431315,-0.027536722,-0.022385294,-0.021017825,0.033343785,-0.0006140736,0.007858269,0.019444298,-0.028979123,0.0043740305,-0.0011368265,0.0014529368,-0.0028754333,0.0165314,0.004444277,-0.024502063,0.0222729,-0.012176102,-0.0077271415,0.037670985,0.011445535,-0.034542665,-0.027574187,0.026918551,0.011426803,0.0373338,-0.0021624288,0.024801783,0.019669088,-0.007460204,0.0005148501,0.046718765,0.046643835,-0.01983768,0.068448424,-0.022647548,-0.07133322,-0.059269518,0.002177649,0.025307558,0.014957872,-0.033044066,0.045182705,0.009665951,-0.0057180845,0.008565419,0.0028567007,-0.15405579,0.027798977,0.030702509,-0.051963855,-0.022441491,0.018919788,-0.017102739,-0.06058079,0.01197941,-0.04143621,0.034992244,-0.04780525,0.007891051,0.023677835,-0.0017198743,-0.033774633,-0.044508334,0.01665316,-0.024651922,0.009108661,-0.037221406,-0.06683743,0.042372834,-0.040162403,-0.013983784,-0.009103977,0.09141442,-0.0031517372,-0.010817998,-0.02577587,-0.058108103,0.008748061,-0.006785835,-0.0036458059,0.010930393,0.017102739,0.027630385,0.0028098696,0.024820514,0.010452715,0.024670655,0.05102723,0.03261322,0.05627232,0.00449345,-0.018573238,0.011689058,-0.030365324,0.004633943,-0.021710927,-0.013478008,-0.0020430093,-0.0057415003,0.028997853,-0.028192358,0.021542333,0.02463319,0.019238241,0.052750617,0.007151118,-0.018451476,-0.058632612,0.005825796,-0.016596964,-0.032407165,-0.008710596,0.006945061,0.013965052,-0.00030850025,-0.03192012,-0.028417148,0.0016601647,0.0073665413,0.018498309,0.008668448,0.02105529,0.040312264,-0.010284123,-0.03336252,-0.09950685,-0.03679056,-0.002681084,-0.036771826,0.010152996,-0.027405595,-0.04203565,-0.021635996,-0.031564202,0.028342217,0.26615086,0.026131786,0.03399942,-0.028061232,-0.0050437157,-0.019950075,0.0069731595,0.0066406587,-0.0060927337,-0.034036886,-0.07875128,-0.039525498,-0.012073073,-0.0136466,0.018685633,0.023453046,-0.05001568,0.01178272,0.061892062,-0.012944133,0.004477059,-0.02766785,-0.023471778,-0.03399942,-0.016522033,-0.026468972,-0.00315642,0.051289488,0.01197941,0.006017804,-0.011801452,-0.024876712,-0.015922595,-0.03497351,0.054436542,-0.03368097,0.0109491255,-0.053799637,-0.035685346,0.012606949,-0.022235435,-0.029840816,-0.017767742,0.017683446,-0.027855175,-0.018301617,-0.01881676,0.027536722,0.021167684,-0.018526407,0.026731227,0.014302236,-0.018526407,-0.021879518,0.025438687,-0.003903377,-0.024370935,0.011857649,-0.028023766,0.038439017,0.005933508,-0.0053949496,0.009235105,-0.01911648,-0.025326291,0.028623205,-0.016493935,0.021448672,0.009464578,0.009216372,0.009890741,-0.011005322,-0.012560117,-0.0101810945,0.022160504,-0.0016390906,-0.008368729,0.016475203,-0.013758995,-0.009239788,-0.017336896,0.013356247,0.009010315,-0.038663805,0.009314718,-0.0028028449,0.023453046,0.011276944,0.007834853,0.004921955,-0.011576663,0.03407435,0.0016870926,0.030290395,-0.030702509,0.014386533,0.060093746,-0.021692194,-0.01235406,0.015126465,0.015266959,0.011248845,-0.023752764,-0.060356,0.015473016,-0.034936044,0.021148952,-0.0096472185,-0.043871433,0.07725268,-0.057995707,0.026712494,0.012297862,-0.04705595,0.012709977,0.05732134,0.003894011,0.019369368,0.026768692,0.042522695,0.0066453414,0.010883561,-0.009787712,0.02356544,0.035797738,-0.01459259,0.0038846447,-0.009965671,0.007994079,-0.0040719695,0.0024118046,-0.046718765,-0.04402129,0.010995956,0.032444626,0.039975077,0.03542309,0.015098366,-0.015847664,0.021767123,-0.036678165,-0.024221076,-0.0074976687,0.043197062,0.0272932,0.014452096,0.053837102,0.019706553,0.021448672,0.028286021,-0.0025241994,-0.02652517,0.06271629,-0.0725321,-0.060393464,-0.041848324,-0.035235766,0.02379023,0.00819077,-0.0019153944,0.030346591,0.007937881,0.039113384,0.046981018,0.009862643,0.017617883,-0.009403697,0.029822083,-0.012653779,-0.025738405,-0.006476749,-0.002891824,-0.016934147,-0.005732134,-0.03527323,-0.035685346,-0.02023106,0.027649118,0.015866397,0.020268526,-0.012044975,-0.03656577,-0.042297903,-0.019931342,0.031807724,0.0430472,-0.019135213,-0.010780533,0.04083677,-0.05046526,0.0074086897,0.07534197,-0.011454902,-0.045407493,0.01523886,-0.039787754,-0.004847025,0.0031330045,-0.0061957627,0.014255405,0.064214885,0.03768972,0.0014494244,0.003205593,-0.005610373,0.029016586,-0.08324707,0.010274757,-0.020924162,0.058632612,0.053424988,-0.011829551,0.0042101215,0.03634098,-0.037521124,0.0019961782,0.037989438,0.006851399,-0.00020576442,-0.026787424,-0.08616933,0.046456512,0.053649776,-0.03566661,0.010312221,0.07155801,-0.024108682,0.0011625836,0.005006251,-0.006261326,-0.00991884,-0.016241046,-0.0043904213,-0.06503911,0.017786475,-0.00022961904,0.06500165,0.030234197,-0.0323135,-0.021579798,0.022816142,-0.007137069,-0.0059569236,-0.035853937,-0.010293489,0.056609508,-0.016746823,-0.05945684,0.00069427193,-0.012419623,-0.06147995,-0.031077158,0.043459315,-0.0066453414,-0.013496741,0.008542004,-0.008874505,0.00503435,-0.014349068,-0.008059642,-0.045857072,0.044508334,0.00991884,-0.029466165,0.0067998846,-0.012260398,0.03945057,-0.018985352,-0.036753096,0.0052778716,-0.041773394,0.0049547367,-0.04394636,-0.04773032,0.03787704,-0.015613508,-0.000120882934,0.042185508,0.01645647,0.0041070925,0.0057883314,-0.044133686,-0.02129881,0.020867964,-0.020193595,0.022010645,0.011267577,0.022085575,0.030084338,-0.0128692025,-0.01170779,-0.01991261,-0.06556363,0.042185508,0.050540186,-0.014246039,-0.032875475,0.0032828643,-0.019219508,-0.03800817,-0.0072494633,0.02744306,-0.018732464,-0.029335039,-0.0070761885,-0.021954447,0.020174863,-0.03945057,-0.007717775,-0.032631952,-0.029522363,-0.07226985,-0.012035608,0.0074836193,-0.01911648,-0.020287259,0.019800214,-0.043346923,-0.019275706,0.01523886,0.001594601,-0.020006271,-0.019762749,0.013056528,-0.01983768,0.0016332367,-0.020924162,0.02068064,0.004116459,-0.012831738,-0.003343745,0.012466455,-0.06282868,0.018975986,0.0027724046,0.0308711,0.005216991,0.0047861445,0.0222729,-0.0012328303,-0.028941657,-0.019331902,0.021991912,-0.016896682,0.0015372328,-0.042747483,0.01908838,0.02418361,-0.023621637,-0.029616026,0.03654704,0.000823643,-0.040087473,-0.027480524,0.025794603,0.011988777,0.011127084,0.01876993,0.007792705,-0.021167684,-0.015547945,-0.005408999,0.012466455,-0.016821753,0.005572908,0.03611619,0.019987538,-0.03755859,0.010480814,-0.012119904,0.00488449,0.016625062,-0.00553076,0.04735567,-0.026731227,0.022553887,-0.01197941,0.0010964345,0.012382159,0.04874187,-0.021561066,-0.03192012,-0.01300033,-0.0193881,0.033025336,-0.10699984,-0.040349726,0.0010332125,0.042672552,0.008649715,-0.0012702952,-0.028304754,-0.011183281,0.008621616,-0.1156917,-0.019079015,-0.069534905,-0.010902294,0.015754003,0.021954447,-0.0430472,-0.017065275,-0.048404686,-0.055597953,-0.043271992,-0.018582605,0.047243275,-0.027237002,0.0024164878,0.03800817,0.01802063,0.008396827,-0.031639133,-0.005006251,-0.0072447807,0.001531379,0.07024674,-0.0053855833,0.011370606,-0.0079331985,0.022834873,0.0062098117,-0.03132068,-0.021991912,0.038588874,-0.018067462,-0.00063222065,0.059306983,0.018451476,0.041173957,-0.02364037,-0.005207625,0.0011479488,0.012560117,0.037745915,0.021467404,0.026637563,-0.017898869,0.011820185,0.02652517,0.019294437,-0.013655966,-0.0036856122,0.03620985,-0.011838918,-0.016896682,-0.03641591,-0.0032688149,-0.025569813,-0.012438356,-0.06503911,0.014695618,0.022160504,0.04608186,-0.023752764,0.0122791305,-0.04690609,-0.005942874,-0.004355298,0.052563295,-0.042710017,0.042560156,0.033250123,-0.0287356,-0.04979089,-0.056684434,0.044283547,-0.019275706,-0.03566661,0.0138432905,-0.00193881,-0.05147681,-0.07601634,-0.040349726,-0.018526407,0.040949166,0.007057456,0.00080432516,0.018975986,0.034711257,-0.03945057,0.0087152785,-0.06597574,0.02090543,-0.060468394,-0.02204811,-0.010995956,0.034655057,-0.034467734,0.020811768,0.0251577,-0.021261347,-0.0071839,0.008176721,-0.0051561105,-0.05200132,0.0012773199,-0.014433363,-0.005661887,0.023134593,-0.01630661,-0.0017678763,-0.0071698506,-0.053799637,-0.042073116,-0.02525136,-0.032051247,0.043759037,-0.018573238,-0.020418385,-0.014461462,0.0076803104,-0.0008177891,0.0037956655,-0.0047861445,0.03169533,0.061067834,-0.010864829,0.021579798,-0.028173625,0.06440221,0.022610083,0.016091187,0.048629478,-0.008499855,-0.057883315,-0.04615679,-0.010293489,-0.021710927,0.048030037,-0.0041305083,0.036453374,-0.013899488,-0.013300049,0.04136128,0.019818947,0.029822083,-0.01680302,-0.025757138,0.00092140306,0.010836731,-0.01832035,0.012288497,0.0035380942,-0.02630038,-0.03761479,0.013384346,0.04514524,-0.04409622,-0.031039692,-0.017102739,-0.0071839,0.0026365942,-0.020343456,-0.009487993,-0.009431795,-0.009455211,0.009487993,-0.005919459,0.06829856,0.000451628,-0.036603235,-0.0041562654,0.020418385,0.025738405,0.026956016,-0.01071497,-0.021804588,0.05162667,0.031114623,-0.023078395,-0.033474915,-0.016990345,0.004964103,0.04690609,0.035629146,0.03398069,0.029260108,0.010883561,0.0011678521,-0.010939759,0.0100312345,0.025288826,-0.030908566,-0.024445865,-0.0023087761,1.6349746e-06,-0.017121471,0.00703404,0.032669418,0.008630983,-0.026244182,0.04211058,0.038738735,0.027311932,0.0029058736,0.040874235,0.008926019,0.010658772,0.010817998,0.009787712,0.019013451,0.017552318,0.039263245,0.023078395,0.021710927,0.00305105,0.024989108,0.018011265,-0.017121471,0.003252424,0.0509523,0.044808052,0.014423997,0.012747441,0.029054051,-0.037427463,-0.012457089,0.028454613,-0.020699373,0.015135831,0.03141434,-0.02334065,0.04439594,-0.012035608,-0.047542993,-0.04492045,0.054474004,-0.039637893,-0.0022315048,0.035085905,-0.003739468,-0.017205767,0.0038073733,0.04394636,0.03330632,-0.023284452,0.014573857]
3	55555555-5555-5555-5555-555555555555	D003	布洛芬缓释胶囊	0.3g*20粒	盒	18.50	84	10	\N	[0.0069575706,0.006846693,-0.054662663,-0.05347997,-0.021695053,-0.054256115,0.0790927,0.022415757,0.05954128,-0.021935288,-0.04608813,0.060132626,-0.024041964,-0.036183063,0.045903333,0.0072809635,-0.01725071,-0.056621503,-0.0073364023,-0.021713533,-0.022415757,0.020309083,0.011743788,0.019181827,-0.00022218835,0.0066064578,-0.017315388,0.022452718,-0.0027534608,0.019810135,-0.00079693284,-0.047381703,0.00044668664,-0.023931086,0.053406052,-0.0061629475,0.005303646,-0.018008374,-0.02975216,0.014053738,0.008625355,-0.026703026,0.021972248,0.06663745,-0.0068374528,-0.01949598,-0.0045760116,-0.008223423,0.030620702,-0.036608092,0.04597725,-0.01951446,7.2582974e-05,-0.014977718,-0.018461123,-0.0047584977,-0.03154468,-0.03631242,0.0006433212,-0.004555222,-0.020272125,0.03431662,-0.03760599,-0.015411989,0.02603776,0.057878114,0.015273391,-0.021990728,-0.024411555,-0.028902099,-0.011475833,0.025668168,-0.013120518,-0.0399529,-0.032875214,0.03627546,0.04331619,-0.010108342,0.02559425,0.040802963,0.018461123,0.034963407,-0.0298076,0.012372094,-0.0042965077,-0.025354015,0.041283432,-0.036589615,-0.0668592,0.015873978,-0.028458588,-0.011411155,-0.018442644,-0.03721792,-0.041135594,0.010311618,-0.024522433,-0.019144868,0.021787452,-0.007608976,-0.0241898,-0.0028481688,0.055586644,0.03625698,0.016003337,0.005945812,0.009170502,0.0017728868,0.053073417,0.00932296,0.016483806,0.029401047,0.044905435,-0.031821877,-0.01673328,-0.0043427064,-0.07292051,-0.041098636,-0.03899196,-0.016936556,0.011494312,0.021787452,-0.0006456311,-0.0288097,0.0071007875,0.010034424,0.007341022,0.05588232,0.0483796,0.030047834,-0.008717753,-0.0044004554,-0.0241898,-0.022083126,-0.028255312,0.00085872406,0.04272484,0.017518664,0.025224658,-0.028698822,-0.020087328,0.021658095,0.028661864,-0.0069806697,0.03254258,-0.017592581,0.051373295,0.026314953,0.006883652,-0.041542146,-0.026795425,0.029844558,0.0064309016,-0.042466126,0.032930654,0.00836202,-0.029382568,0.03535148,-0.030121753,-0.007294823,-0.02280383,0.03577651,-0.019736215,0.011891624,0.00034273887,-0.012769406,0.0038091082,0.08182768,0.0003236818,-0.0391398,-0.012944962,-0.031359885,-0.0019045541,-0.0148298815,0.00030289224,0.018673638,0.030103272,0.01817469,-0.010551853,-0.016335968,-0.031489242,-0.019717736,0.017537143,-0.0120579405,0.005409904,0.032376263,-0.027238935,0.02834771,0.044166252,0.016197372,0.02091891,-0.020530839,0.006324644,-0.005428383,0.012926482,0.007830732,-0.024319157,-0.014220054,0.010533374,-5.29123e-05,-0.009406118,0.0037444294,0.023506055,0.015485907,0.020549318,0.030602222,-0.01815621,-0.0024993662,-0.04789913,-0.016077254,-0.06334808,0.039805066,-0.0298076,0.018036092,0.0050125923,0.010385537,0.011531272,-0.01533807,0.010089863,-0.048231762,-0.04239221,0.048083927,0.010976884,0.028218353,-0.026666068,-0.047640417,-0.0023538393,0.054219153,-0.0033309483,-0.015097835,-0.04793609,0.0027580806,-0.021011308,-0.012372094,0.038881086,-0.023857167,-0.02051236,0.06464165,0.046827313,-0.036090665,-0.03581347,0.00838512,0.0650482,-0.033226326,-0.017999133,-0.0035411539,0.026351914,0.010163781,0.0035180543,0.0005558318,3.3169443e-05,-0.035961308,-0.0139521,-0.027996598,0.005405284,-0.005248207,0.0104132565,-0.000106257714,-0.0586173,-0.02651823,0.024965944,0.01674252,-0.00044813036,-0.012011741,0.011355716,0.027590048,0.007063828,-0.021306982,-0.004643,0.011762267,0.03727336,-0.0455707,-0.04760346,0.052297276,0.0018906944,0.009429217,-0.02657367,-0.01071817,0.028698822,0.006366223,0.021990728,0.05950432,-0.005797975,0.013259115,0.03581347,-0.030343508,-0.05540185,-0.022877747,0.0079739485,0.025889924,0.019348145,-0.0043496364,0.055180095,0.02374629,0.0018941592,0.016160412,0.0035041946,-0.14236686,-0.016003337,0.038289737,-0.041505188,0.015957138,0.053258214,-0.081605926,-0.041542146,-0.02090043,-0.01860896,0.037883185,-0.04420321,0.0044489643,0.0008685413,-0.011558992,0.0108752465,-0.04146823,0.023376698,-0.023413656,-0.019939492,-0.0044258647,-0.020604758,0.056880217,-0.021639615,-0.051336337,0.0075951167,0.0511885,0.017731179,-0.04549678,-0.030306548,-0.039287634,0.05067107,0.00038431797,0.0068051135,0.058025952,0.019921012,0.0053637046,0.0021482538,0.039694186,-0.01531959,0.018239368,0.018710598,0.029493446,0.034094866,0.020992829,-0.010311618,0.025760567,-0.012270456,0.022249442,-0.053258214,-0.018673638,-0.0037975584,0.020272125,0.0065233,-0.049821008,0.016493045,0.04239221,0.045238066,0.019422062,0.02511378,0.009960506,-0.01814697,0.023450615,-0.01632673,-0.07244004,-0.047233865,0.0042988174,-0.012344374,-0.026647586,-0.009461557,-0.00698991,-0.04871223,0.022415757,0.008648454,0.002926707,0.000907233,0.038844123,-0.0064309016,0.010792088,-0.11346476,-0.03627546,0.0013778853,-0.03708856,0.028957536,0.004975633,-0.023099503,-0.022452718,0.0073733614,0.046790354,0.23195598,0.06393942,0.026462791,0.01118016,0.024577871,-0.029474966,0.02041996,-0.029936956,-0.025427934,-0.01958838,-0.023062544,-0.020364523,-0.0108752465,-0.020641716,-0.018812235,0.0060751694,-0.03431662,0.027165016,0.06715488,-0.006010491,-0.0122889355,-0.024466993,-0.0326165,-0.031452283,-0.0030514444,-0.004472064,0.028532507,0.03917676,0.008648454,0.014173855,-0.055845357,-0.020383002,-0.0049571535,-0.03294913,0.036478736,-0.045681577,0.031563163,-0.01999493,-0.039731145,0.019921012,-0.009313719,-0.010071384,0.0060243504,-0.007669035,-0.030158712,-0.019921012,-0.030953335,-0.022933187,0.030010875,-0.0057748756,0.0033309483,0.010884486,0.0037120902,0.003950015,0.030380467,-0.00837588,-0.025705127,-0.04852744,-0.030879416,0.058765136,0.03675593,0.00014733152,-0.005299026,-0.006666517,-0.036718972,0.0066618966,-0.027553087,0.015254912,0.001303967,-0.009461557,0.009115064,0.015116315,0.021639615,0.015301111,0.047049068,-0.026370393,0.008140265,0.0012208087,0.025427934,-0.01859972,-0.046753395,0.023321258,0.030934855,-0.05902385,0.0132129155,0.003943085,0.060169585,0.046753395,0.016844157,-0.02232336,-0.025982322,0.031803396,0.020124286,0.023173422,0.004559842,0.061943628,0.0016238951,-0.028181395,-0.00050328043,0.04653164,0.0250953,-0.0023492195,-0.009336819,-0.05484746,-0.010431736,0.0008962607,2.4976338e-05,-0.017038194,-0.033244804,0.009738751,-0.06460469,0.034815572,0.0019161038,-0.026314953,0.041505188,0.04087688,-0.05676934,0.0016354448,0.03398399,0.022508156,0.054625705,0.015873978,-0.028273793,0.06390247,0.033762235,-0.007040729,0.00050674536,-0.00034764752,-0.026998699,0.008486758,-0.019884052,-0.026629107,-0.042022616,-0.025002902,0.008495998,0.050005805,0.0012612329,0.0081033055,0.019200306,-0.027774842,-0.0053683245,-0.028624905,-0.014663565,0.05902385,-0.01163291,-0.023653891,0.036866806,-0.010551853,0.0019819373,0.026887821,0.018341005,0.0081033055,0.069076754,-0.017897496,-0.035739552,-0.064530775,-0.035129726,-0.00045592643,-0.0083204415,0.010949165,0.0101822615,0.050781947,-0.003160012,0.028273793,-0.027793322,0.030546783,0.007341022,0.015883218,0.0033609776,-0.028643385,0.041135594,0.019403582,-0.027719405,-0.033115447,-0.0038345174,-0.051262416,-0.020771073,0.019385103,0.026758464,-0.026296474,0.00017035884,0.021768972,-0.02041996,0.014201575,0.0004279183,0.037920143,-0.05858034,-0.0023342047,0.040248573,-0.019348145,-0.021676574,0.07584029,-0.0078723105,-0.004522883,0.032209948,-0.008588395,0.0035157443,-0.0047122985,-0.012076421,0.018535042,0.06634177,0.012362855,0.020364523,0.0027511509,0.0008073276,-0.0030860936,-0.053997397,0.046346843,0.039805066,0.03387311,0.035628673,-0.008556056,0.05407132,0.007114647,-0.019385103,0.0042965077,0.055254012,0.017879015,-0.0056177992,-0.01997645,-0.044831514,-0.012603089,0.009050385,-0.03721792,-0.015199473,0.05495834,-0.016825678,-0.0059273327,0.056510624,-0.005959672,-0.00039702273,0.043944497,-0.013693386,-0.016539244,-0.036109142,-0.015264152,0.04412929,0.014469529,-0.034279663,0.008736232,-0.019477502,0.0058949934,0.013314554,0.013434671,0.009738751,0.027774842,-0.049525335,-0.050301477,0.028772742,0.025686648,-0.026074719,-0.02886514,0.037070084,0.002829689,-0.046162046,0.033337202,0.023062544,0.0019195687,0.019847093,-0.019237267,-0.053332135,0.046642516,0.03398399,0.018572,-0.027682444,-0.034630775,0.041283432,0.01678872,-0.010598052,0.019828614,-0.03664505,-0.017259948,-0.030879416,-0.016936556,0.006153708,-0.026333435,-0.03950939,0.07280964,0.024744188,0.029899998,-0.024041964,-0.0511885,0.020992829,0.011789987,0.0028412389,0.008301961,0.03917676,-0.0030560642,-0.010283899,-0.03998986,0.0049201944,0.011743788,-0.074953265,0.03991594,0.052703828,-0.013924381,-0.022064645,-0.024818106,-0.023598453,-0.010034424,0.0130466,0.026425831,0.017324628,-0.0066387975,0.03581347,-0.04549678,0.031433806,-0.06334808,-0.014940759,0.025889924,0.0032708896,-0.067044,-0.0288097,0.032727376,-0.0026726124,-0.04605117,0.01811001,-0.0419487,0.01628053,0.016206611,-0.024910504,0.027793322,-0.008990327,-0.010792088,-0.010579572,-0.011993262,-0.012362855,-0.044979353,-0.022508156,0.0021482538,-0.057397645,0.013406952,-0.019551419,0.0021621136,0.0073271627,0.017380066,0.016391408,0.00790465,0.036718972,0.037532073,-0.026887821,-0.0373288,0.05436699,-0.012205778,0.0030653041,-0.002229102,-0.015153274,-0.014949999,-0.016160412,-0.033614397,0.01302812,-0.006102889,-0.010348577,-0.0024416174,0.056621503,-0.016539244,0.022545116,0.04871223,0.006648037,-0.012695487,-0.010071384,-0.03494493,-0.03115661,0.00979419,0.0022926256,0.042429168,0.04516415,-0.03437206,0.019292705,0.003067614,0.0213809,0.0015476667,-0.003347118,0.068115816,-0.04826872,0.00067104056,-0.005539261,-0.020789552,0.053775642,0.049821008,-0.01626205,-0.020142768,0.0026333435,-0.04930358,0.044388007,-0.032283865,-0.003670511,0.0315262,0.039768104,0.025963841,-0.014524967,-0.017814336,-0.03017719,0.007271724,-0.102155246,-0.012630808,-0.013647187,-0.028477067,0.011078522,0.0043011275,0.0022418068,-0.02467027,0.001765957,-0.060687017,-0.03806798,-0.063421994,0.029548885,-0.007377981,0.034686215,0.045238066,0.055475768,-0.01442333,-0.019329665,-0.0024762668,-0.019163348,-0.019680778,0.014848361,-0.021306982,-0.017047433,0.0033217086,0.05776724,0.022120085,-0.01772194,0.00419718,0.011392675,-0.017795857,0.01489456,0.015716903,-0.0047261585,0.01910791,-0.04180086,0.014524967,0.02321038,-0.030491345,0.021713533,0.0063477433,-0.005308266,-0.016483806,0.010043664,0.060095668,0.02795964,-0.017860536,-0.030602222,0.033263285,-0.055956237,0.017601822,-0.0297152,-0.031045733,-0.0012381334,-0.057804197,-0.040802963,-0.02555729,0.018886155,0.030435905,-0.032838255,0.0034348962,-0.040692084,-0.04139431,0.0060243504,0.031747956,-0.034649257,0.05776724,0.021491777,-0.005710197,-0.03825278,0.002838929,0.02043844,-0.01723223,-0.06264585,-0.0074749994,0.00042618584,-0.082123354,-0.061500117,-0.022951666,-0.068855,0.00209397,0.021325462,-0.020105807,-0.005266687,0.0045829415,-0.01255689,-0.005548501,-0.06874412,0.01767574,-0.06815278,-0.029216252,-0.009336819,0.03479709,-0.03500037,0.034298144,-0.0130466,-0.03865933,-0.020346042,-0.015670704,-0.01350859,-0.04608813,0.0031299826,0.02786724,0.022138564,0.027146537,0.022101605,-0.038511492,-0.025834484,0.013175957,-0.046605557,-0.033355683,-0.023321258,0.03115661,-0.015642984,-0.01259385,-0.04054425,0.011614431,-0.0023526845,-0.010487175,-0.00788155,-0.016945796,-0.015254912,-0.009978985,-0.011300277,-0.053738683,0.04741866,-0.015753862,0.013166717,0.053516928,-0.0122612165,-0.010773608,-0.049118783,0.011318756,0.033651356,0.06660049,-0.02051236,0.016363688,-0.03069462,-0.0024508573,0.050781947,-0.018858435,0.029179292,-0.050781947,0.019902533,0.034113348,-0.03158164,0.018719837,-0.050005805,0.019625338,-0.0298076,0.012926482,-0.02744221,0.04608813,-0.084414825,-0.002554805,-0.049525335,-0.031267487,-0.00084370933,0.023579974,-0.047973048,0.0075489176,0.0056085596,0.05773028,-0.010921445,0.07643164,-0.019884052,-0.036866806,-0.030158712,0.011374195,0.040766004,0.03531452,-0.010173021,0.021695053,0.06327416,0.009480036,-0.01394286,-0.05813683,-0.03991594,-0.013194436,-0.006865172,0.012039461,0.04653164,0.014303212,-0.02232336,0.022064645,-0.03348504,0.010976884,0.01443257,0.040618166,0.0065233,-0.031249007,0.0034741652,0.0032778196,0.040137697,0.021325462,0.017509423,-0.040802963,0.012640048,0.07480543,0.018257847,-0.026666068,0.015735382,-0.024041964,-0.022859268,0.004044723,0.010145302,0.005054171,0.004409695,0.011753027,0.052260317,0.017102873,-0.021306982,-0.009096584,0.027922679,0.0047192285,0.029142333,0.037642952,0.03163708,0.009969746,0.0074241804,0.011882384,-0.008167984,-0.008944128,-0.02136242,-0.018451883,0.005691718,0.015541346,-0.025520332,-0.0326165,-0.015744621,-0.03254258,-0.05115154,0.009655592,-0.027275894,-0.018341005,0.005802595,-0.0021713532,-0.029419528,0.003940775,0.060576137,-0.019403582,-0.010662731,0.009188983]
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee (id, uuid, dept_id, regist_level_id, realname, password, expertise, ai_eval_score, delmark, gender, expertise_vector) FROM stdin;
6	5ca2828e-90ed-46b3-8476-f60b81019aa5	5	1	孙妇医	$2b$12$fThWbSV36r1kcXarVDbDaOMhto4bOSNvDsP56prC/6h6hl.PjFnXy	高危妊娠，妇科肿瘤，月经不调，子宫肌瘤微创手术	3.5	1	女	[0.038107466,-0.0045724357,-0.06424882,0.0101711955,-0.0067424444,0.0064570988,0.013549321,0.010336881,-0.00140947,-0.00057500624,-0.008505145,-0.00019128522,-0.00023975373,-0.010999619,0.066347495,-0.019606015,0.005361739,-0.010309266,-0.017967578,-0.005973852,-0.04911629,0.03059643,-0.031424854,0.019090552,-0.018455427,0.013337613,0.01035529,-0.029731188,0.03275033,-0.013484889,-0.009379592,0.032308504,0.026325447,-0.04359347,-0.0062868115,-0.028350482,-0.023692904,-0.0110180285,-0.051141325,0.057105973,0.01789394,0.017194383,-0.0017569475,-0.019403512,0.03462809,-0.07628857,0.028092751,-0.022938117,0.01853827,-0.03374444,-0.020544896,-0.02562589,0.006581362,-0.026472723,0.056443233,0.0008842267,-0.014000352,-0.044882126,-0.011993727,-0.009987102,-0.015058893,-0.037242226,0.003067467,-0.0040063467,-0.009849031,0.055522762,0.02472383,-0.0010562396,-0.022441063,-0.053571366,0.00495213,0.05504412,0.03832838,-0.008551168,-0.042120717,0.024134729,0.020857856,-0.0250552,-0.0072441003,0.053829096,0.023251077,0.012223844,-0.018749978,0.03586152,-0.027430013,-0.00035035398,-0.0053525344,0.0555964,-0.02260675,-0.009305954,-0.016034592,0.009094246,-0.02198083,-0.048343096,-0.01655926,0.02871867,-0.0373895,0.008772081,0.03326579,0.018584294,-0.003513895,-0.0052328734,0.0077043357,-0.0068252864,0.013981942,0.0028212413,-0.031645767,0.017967578,0.006751649,-0.010990415,0.0044780876,0.028000703,0.018335767,-0.00988585,-0.042893913,-0.058615543,0.0073407497,-0.055412307,-0.005679301,-0.022735614,0.043777563,0.057584617,0.043777563,-0.026712045,-0.011515083,0.014552634,0.045066223,0.05434456,-0.044403482,0.024613373,0.048122182,0.07312215,-0.05136224,-0.00894697,0.003985636,-0.045508046,0.029123677,0.003511594,0.016080614,-0.0017143758,-0.0032285494,-0.0039580218,0.0012575925,-0.008284232,0.023379944,-0.04999994,-0.01949556,0.02533134,0.051214963,-0.06145059,-0.05445502,0.04970539,0.020949902,-0.009710961,0.0048969015,-0.01885123,-0.060014658,-0.0094072055,0.00393501,-0.011929294,0.01758098,-0.0106958635,-0.023858588,-0.040316597,0.03742632,0.00270158,0.020931493,0.046170786,-0.024005864,-0.016688125,0.016909039,-0.030688478,-0.04263618,-0.033873305,-0.0009302502,0.00393501,0.06520611,0.0038222526,-0.018943276,-0.055449124,-0.04167889,0.0016200276,-0.0014497406,0.03335784,0.052393164,-0.025110427,0.00073867734,-0.042746637,0.0042571747,0.010456542,-0.026638407,-0.041494798,0.027430013,0.034756955,0.041899804,-0.023011755,0.020857856,-0.054749567,0.017985988,-0.020802626,-0.018786797,0.038733386,0.001990517,-0.017479729,-0.06723114,-0.0027153871,0.020765807,-0.04042705,-0.018602703,-0.03825474,0.024594964,0.0073361476,0.0072302935,0.00555964,-0.042120717,0.008818105,0.03370762,0.014230469,0.008518952,0.0038751797,-0.05471275,-0.007860815,0.021226043,0.00571612,0.022017647,0.027871838,0.05191452,0.019201009,0.035069916,-0.04171571,-0.027779792,0.02871867,0.048085365,-0.014672295,0.061082404,0.0015958652,0.030946208,-0.022459473,0.015878111,-0.032032363,0.034849003,-0.031700995,0.0636229,0.02196242,-0.029491866,0.037739277,0.0005312839,0.0034172456,-0.006452496,-0.00765371,0.025791576,0.056075044,-0.05434456,0.056369595,0.026509542,-0.0072717145,-0.0034402574,-0.019845339,-0.0063926657,-0.01867634,0.002123985,0.055854134,-0.021262862,-0.0040293583,-0.008219799,-0.028055932,0.036561076,-0.024834286,0.00266246,0.015960954,0.009324363,-0.018354176,0.00448269,0.018437019,-0.010208014,-0.039727494,-0.045360774,-0.011358602,0.031590536,0.02875549,0.005320318,-0.0058357813,-0.0013105194,-0.033762846,0.017387683,-0.0039879372,-0.023306306,-0.024337232,-0.049889486,-0.03437036,-0.04720171,-0.016329141,0.06653158,-0.00794826,0.0063144257,0.061376955,0.025828395,-0.13969056,-0.050846774,0.001750044,-0.009236919,-0.014175241,0.0052374755,-0.0346465,0.03155372,-0.059793744,-0.008712251,-0.032787148,-0.0512886,-0.003815349,0.030320289,-0.09639164,-0.0037210009,-0.02069217,-0.0023794156,0.008956175,-0.024116319,-0.0636229,-0.011515083,-0.0013830065,-0.004415956,-0.011146895,-0.002255152,-0.011220532,0.023969045,-0.029804826,-0.04086888,-0.05633278,-0.018842025,-0.00046052274,0.025865212,0.030467564,-0.010603817,-0.0128313545,-0.016743353,-0.011505878,0.002947806,0.0021251356,0.0685198,-0.011735995,0.047091257,-0.009720165,0.008514349,0.043446194,-0.009269135,0.038181104,-0.0389543,-0.00038285807,0.015095712,0.032621466,-0.029234134,-0.012739308,0.010189605,0.011496673,0.04819582,0.018317357,0.0051592356,-0.011643948,-0.09491889,-0.023913816,-0.035677426,-0.00045908452,-0.036874037,-0.029823234,-0.006503122,0.009186293,-0.05136224,0.008459121,-0.022809252,0.016568463,0.023011755,0.0043101017,-0.018823616,-0.01066825,-0.054491837,-0.0026578577,-0.08615601,-0.049300384,0.036634713,-0.031756222,0.008818105,-0.03553015,-0.012546009,0.0013715007,0.014976051,0.016319936,0.24241504,0.040611144,0.01268408,-0.022754023,0.014046376,-0.024153138,0.061597865,0.029510275,0.019955793,-0.024981562,0.029583912,0.009628118,0.013125905,0.009305954,-0.0009026361,0.056038227,-0.047496263,0.0054998095,0.07636221,-0.033597164,-0.01975329,-0.000554008,0.0051684403,-0.024650192,-0.024171548,-0.019219417,-0.019421922,0.04329892,-0.055854134,0.02256993,-0.036855627,-0.00096246664,0.047974907,-0.0118648615,-0.05073632,-0.018998506,0.002045745,-0.0027821213,-0.026840912,0.002051498,-0.0011632442,-0.01980852,-0.034517635,-0.0036657725,0.0034977868,-0.015049688,-0.02562589,0.0015555946,-0.0123895295,-0.04263618,-0.012030546,-0.0036634714,-0.0184002,-0.012628851,-0.032069184,-0.0071152346,-0.018924868,-0.011993727,0.01435013,0.06321789,0.03519878,0.01871316,-0.09263612,0.017875532,-0.021667868,0.043188464,-0.06273925,0.052393164,0.032069184,0.014460587,0.010318471,-0.005532026,-0.02223856,0.033228975,-0.012858969,0.014801161,-0.0014083195,0.088806964,0.0071796677,-0.013595345,-0.015933339,0.011073257,-0.02965755,-0.013622959,0.008449917,0.009977897,0.04348301,-0.009895055,0.033210564,-0.0059324307,-0.01771905,0.013825462,-0.0636229,0.024981562,0.0012104183,0.0017765075,0.021281272,-0.052393164,-0.034775365,0.02905004,-0.017838713,-0.024337232,-0.0017419899,-0.010999619,0.0039534196,0.04086888,-0.009849031,-0.038438834,-0.05460229,-0.016310733,-0.05522821,0.01051177,0.008606397,-0.014147627,0.005283499,0.02196242,-0.008716853,0.03400217,0.07201759,0.059830565,-0.034775365,0.020784218,-0.030099375,0.085787825,-0.013309999,-0.03983795,-0.045581684,0.034812182,-0.0134756835,0.044256207,-0.0039212033,-0.023066983,-0.03219805,-0.009172485,0.0058679977,0.061892416,-0.017645413,0.032952834,0.010723478,0.043372557,-0.03339466,0.0074834228,-0.012858969,0.043998476,0.0086202035,0.0010711972,-0.019053733,0.06594249,0.026988186,0.029694369,0.0039281067,0.02260675,0.061303318,-0.030338699,-0.0234904,-0.022533111,-0.01127576,0.0059876586,0.010999619,-0.02627022,0.012325096,-0.02595726,0.025460206,0.11185554,-0.005923226,0.029528685,0.0352356,0.03551174,0.015049688,-0.023343125,0.019072143,0.0022701097,-0.039359305,-0.014478996,0.012380324,0.00649852,0.01313511,-0.0029846246,0.0014405359,-0.015362647,0.029823234,0.034186263,0.013834667,0.012904992,-0.0004173757,-0.0041191042,0.0067792633,-0.02871867,-0.042194355,-0.035474923,0.025184065,0.10427087,-0.019421922,-0.024907924,-0.018749978,0.04234163,0.019974204,-0.01867634,0.013171929,0.014285698,0.03433354,0.054786388,0.0009820267,0.030209832,-0.036100842,-0.024558146,0.011377011,-0.041826166,0.013374432,0.01297863,-0.011367807,0.0037025914,-0.02719069,0.03155372,0.019219417,-0.0072302935,-0.0012460866,0.026822502,-0.063549265,-0.021097178,0.011082461,-0.032142818,0.033486705,-0.04944766,-0.056406416,0.046612613,-0.020839445,-0.019385103,-0.0041789347,0.008348665,0.009213907,0.015574356,0.03424149,0.004484991,0.0021723097,-0.04296755,0.029952101,0.04414575,0.05279817,-8.2267026e-05,0.018703954,-0.001961752,-0.029675959,0.034941047,-0.01636596,-0.003603641,-0.027117053,0.015031278,0.04668625,-0.011478264,-0.0336708,-0.018078035,0.010751092,-0.058284175,-0.0283873,0.01452502,-0.015344239,0.00133123,-0.035953566,-0.0015486912,-0.012739308,0.04473485,0.0044136546,0.04259936,-0.04885856,-0.05633278,0.022938117,0.048895378,-0.04105297,-0.012601237,-0.03153531,-0.02842412,0.02012148,0.02750365,0.010760297,-0.036671534,-0.01794917,0.022993347,-0.017737461,0.015371853,0.010686659,-0.027061824,-0.002910987,-0.029749596,-0.015196963,0.03245578,0.035290826,0.016863015,0.0036864833,-0.008293437,-0.006111922,0.013319204,-0.0065629524,0.015123325,-0.0219256,0.026012488,-0.02161264,-0.014000352,-0.012122593,-0.0059968634,-0.00054163917,-0.030265061,-0.02689614,-0.008509747,0.035290826,-0.016172662,0.0076399026,-0.05751098,0.012233049,0.010769501,0.020471258,-0.069624364,-0.032308504,0.022643568,-0.010318471,-0.01268408,0.024226775,-0.02844253,0.020563304,0.03606402,-0.01794917,0.023876997,-0.005610266,-0.052650895,0.000933702,0.054823205,-0.052761354,0.0095268665,-0.02376654,0.009839826,-0.04042705,0.01730484,0.015942544,-0.06520611,0.0118648615,0.021723097,0.019992612,0.0013680488,0.020489667,-0.06778342,-0.03707654,-0.0055366284,0.06491156,0.028055932,-0.006047489,-0.034683317,0.020195117,0.029933691,0.036874037,0.031406444,0.030541202,-0.02807434,-0.0063788584,-0.04606033,0.056811422,0.0450294,0.023361534,0.00080713734,0.019882157,0.037463136,-0.031388033,0.013107495,-0.0056931083,-0.033284202,0.016448803,0.044698033,-0.021704687,-0.020139888,0.036321755,-0.0074235923,0.024245186,0.0059462376,-0.01082473,0.056921877,-0.040684782,0.034775365,0.022993347,-0.011625539,0.020857856,-0.04539759,-0.0067424444,0.0076767216,0.016550055,-0.005532026,0.0017661522,0.008072523,0.008541964,0.0003512169,0.0017891639,0.02409791,-0.028240027,-0.0034908834,-0.014819571,-0.0050441767,-0.16818832,-0.048232637,-0.013981942,-0.019734882,-0.01838179,0.0018766086,0.027135462,0.0042824876,-0.016108228,-0.022496292,0.030136194,0.004165128,-0.00013253333,0.0017063216,0.043703925,0.047054436,0.012288277,-0.035143554,0.020802626,0.06273925,0.0066273855,-0.019550787,0.06524293,0.029731188,0.018906457,-0.011220532,0.007985079,0.0037716266,-0.024705421,-0.045066223,-0.0151693495,-0.033173747,0.07393217,-0.0059968634,0.02225697,-0.024337232,-0.017737461,0.04856401,-0.0077825757,-0.024355642,-0.016246298,0.01562038,0.020913083,-0.0010619925,-0.055412307,0.025902031,0.017673029,-0.0080265,0.008072523,-0.009766189,-0.0042939936,0.021446956,-0.051804062,-0.0035898339,-0.018906457,0.01575845,-0.0017592487,0.02315903,0.00096246664,0.035622198,0.011220532,-0.039911587,-0.010999619,-0.03676358,0.012159412,0.009609709,0.0034793774,0.029234134,0.011459854,-0.0015475405,-0.027982295,0.00038228277,-0.020213526,-0.040353414,0.018298948,-0.019882157,0.016752558,-0.05007358,-0.026877731,-0.0031618152,0.017277226,-0.0047128075,0.039764315,-0.017231202,0.0395434,-0.015905725,0.0001372076,0.043519832,-0.024889514,0.012564419,-0.040905695,-0.08173776,0.005057984,-0.023251077,-0.027871838,0.021502184,-0.023416761,-0.04675989,-0.028240027,-0.04790127,-0.012895788,-0.021115586,-0.0074926275,-0.03862293,-0.030467564,0.032216456,0.017028699,0.0024599566,0.004625363,-0.012113388,-0.038402017,0.0040592737,-0.042083897,0.02654636,-0.030762114,2.2148815e-05,0.02198083,0.010797116,-0.05379228,0.0129510155,-0.021759916,-0.015657198,0.008841116,-0.0501104,-0.009867441,-0.004077683,0.041200247,0.035640605,0.013116701,0.0066918186,0.025883622,-0.036045615,-0.018796002,-0.007437399,0.026454315,0.013282385,-0.011579515,0.047753993,-0.0506995,-0.036100842,-0.0028120365,-0.016568463,-0.002031938,-0.028184798,-0.0027130859,-0.046538975,0.0030237446,0.0039879372,0.015408671,-0.0004823839,0.009471638,0.008109342,-0.0014854087,-0.0027222906,0.015224577,0.034867413,-0.02043444,0.024594964,-0.012601237,0.04451394,0.027448421,-0.031259168,-0.019348284,0.022717204,-0.03120394,0.05751098,0.0007150903,-0.0062591974,-0.010161991,-0.009793803,-0.009655733,-0.024263594,-0.04576578,0.00266246,0.03275033,0.012555214,-0.027025005,-0.032326914,0.010502565,0.006908129,0.037131768,-0.013549321,-0.006802275,0.020563304,-0.0074005807,0.014552634,0.01808724,-0.0015636488,-0.0073453523,-0.0037647232,0.014147627,-0.007957465,0.041531615,-0.028405711,0.043703925,0.027006596,-0.0123066865,-0.043078005,-0.010300062,0.052761354,0.014478996,0.02871867,0.031332806,-0.035659015,0.017341658,0.0025635096,0.038659748,-0.024447689,0.006608976,0.015657198,-0.026086126,0.013457274,0.015104916,0.019403512,-0.020821037,-0.030338699,0.059094187,0.019016914,0.03182986,0.007828599,0.028479349,-0.023637675,0.017663823,0.008399291,0.023858588,-0.017415296,-0.00820139,0.004448172,0.0256443,-0.020508077,-0.07945499,-0.00804491,-0.020600123,0.009849031,0.004657579,0.01064984,0.004814059,-0.0022401945,-0.0064432914,0.021594232,0.029362999,0.034849003,-0.004008648,-0.0250552]
9	11111111-1111-1111-1111-111111111111	1	1	李医生	123	脑肿瘤切除,脑积水诊治,复杂性脑外伤,脑出血	5.0	1	\N	\N
7	67fe32fb-91d9-447f-a2da-ee6baa7ebb3d	\N	\N	Dr. E2E	$2b$12$dmLxtGnk4J27kQZT42XEq.hqa/6wW5auVGYZhtuvEtHk1tYPbEgXa	全科测试	5.0	1	男	[0.0024914418,0.007694021,-0.026045617,-0.027092677,-0.01630422,0.015472181,-0.00041543506,-0.030252554,-0.0021069744,-0.024381539,-0.0033234805,-0.007521069,0.029093308,0.012648858,0.0076145567,-0.0545967,-0.04154584,-0.011732681,0.007544441,-0.014023124,-0.019819349,-0.0153226005,0.023577547,0.0063524754,0.049585767,0.03874122,-0.042443324,-0.01391094,-0.028831543,-0.00852606,0.0043588546,0.018117877,0.002818648,-0.06611436,-0.0657778,-0.033487223,0.020137208,-0.024643304,-0.034141634,0.024344144,0.01301346,-0.01592092,0.0009646741,-0.006137454,-0.016612729,-0.024138471,0.0006012415,-0.026943097,-0.0061655003,-0.009002846,0.0030663898,-0.0040830662,0.03619836,-0.045921057,0.055681154,0.025690364,0.040797945,-0.0007607545,-0.079875715,-0.038890798,0.0057027373,0.028513687,0.0123310005,0.01555632,0.0018522211,0.03281411,0.023577547,-0.012097282,0.0051231147,-0.027578812,0.013882893,-0.009694654,0.019576281,-0.020642038,-0.08481186,0.006100059,0.036104873,0.03333764,0.03986307,-0.03258974,0.005511088,-0.0073060477,-0.02340927,-0.0063291034,-0.04053618,0.010489297,-0.028962426,-0.005151161,-0.009984464,0.0065394505,-0.042218953,-0.014967348,0.014976697,-0.018519873,-0.026456961,0.010367763,-0.027877972,-0.012546022,0.017183002,-0.023427967,0.032122303,-0.0021852702,0.014387726,-0.007974483,0.041246682,0.01884708,0.03724542,0.016640775,-0.01084455,0.0010084964,0.011788773,-0.012312303,0.018304853,0.028008854,0.017519558,0.022904437,0.0084278975,0.010909991,0.008222225,0.0048800474,0.06312276,0.01974456,0.025035951,-0.026307382,0.0042980877,-0.0073294197,0.035637435,0.026662635,-0.02535381,-0.011386777,-0.030402133,0.06488033,-0.04315383,0.031374402,-0.022455696,-0.0018463781,0.0023850997,-0.008423223,-0.004889396,-0.038180295,0.052427787,0.052652158,-0.023446664,-0.022006957,0.013041506,-0.04891266,0.013686569,-0.043266013,0.01406052,-0.03948912,0.020959897,0.016939934,0.026887003,0.007946437,0.011125012,0.029934697,-0.026213894,0.021558218,-0.0089748,0.016079849,0.021913469,0.010040557,0.037507184,0.0043962495,-0.01353699,0.004852001,0.0068806796,0.004199926,-0.030084277,0.030327344,-0.006707728,-0.04375215,-0.0358992,-0.03165487,0.0065534734,0.003204284,0.045285344,0.01548153,0.0231849,-0.040498782,0.010115347,-0.0014502248,0.0069881906,-0.032346673,-0.0426303,-0.00930668,0.052166022,-0.041209288,-0.0052353,-0.017912205,-0.007147119,-0.015537622,0.07015302,-0.007441605,0.03335634,0.019968929,0.013116295,-0.005945805,0.03313197,-0.0058803638,-0.053063504,0.012873229,0.029336376,0.0022296768,-0.03416033,-0.009058938,-0.040237017,-0.01989414,0.028308013,0.009189821,-0.00029945213,-0.0050062556,0.01629487,0.008502688,0.0018487152,-0.018304853,0.03769416,-0.008194179,0.007432256,-0.028083645,0.009054264,0.033318944,0.036665797,-0.03507651,0.012396442,-0.019389307,0.05885973,0.027765786,0.02587734,-0.055830732,0.0074462793,0.0129012745,-0.009610515,-0.031954028,0.0064506372,0.030140368,0.008848592,-0.007941763,0.025017254,0.019277122,-0.022100445,0.020211997,0.050558038,-0.0069040516,-0.009316029,-0.023353176,0.013219132,0.020305485,-0.043639965,-0.034870837,0.022380907,-0.0021373578,-0.03851685,0.03717063,0.03545046,-0.010853899,0.012461883,0.0011031525,0.014920604,0.0035805712,0.028906334,-0.0050670225,0.027728392,0.019333214,-0.015154324,-0.006735774,-0.016631426,0.0039685443,-0.0381242,0.009881629,-0.019445399,-0.012648858,0.02849499,-0.005712086,-0.018360944,0.06903117,0.0014233472,-0.029803814,0.07441605,0.0054549957,-0.019594979,-0.027709695,-0.006885354,-0.05990679,-0.005071697,-0.0069180746,-0.010442553,-0.045696687,0.0160892,-0.019987626,0.018716197,0.02759751,0.088177405,-0.015294555,-0.028195828,-0.037413698,-0.003031332,-0.15287076,-0.02832671,-0.030196462,-0.03236537,-0.0020730852,-0.0057167606,0.0011563235,0.013583734,-0.0057448065,0.047304675,0.015182369,-0.07292025,-0.014527957,-0.0023512105,0.01899666,-0.0261765,-0.01615464,-0.012134677,-0.017267141,-0.04053618,0.012312303,-0.042518113,0.033917263,-0.00900752,-0.014107264,-0.01764109,0.057663087,-0.027541416,-0.0010534872,-0.010405159,-0.014939302,0.022923134,0.0011311987,0.029654235,0.028663266,0.015004743,-0.0032720624,0.016173337,-0.018061785,0.0134622,0.001895459,0.03270193,0.013331317,0.018061785,-0.0013508943,-0.004973535,0.04367736,0.015238462,-0.012546022,-0.008895336,-0.0014432132,-0.021296453,0.013649175,0.0059177587,-0.020754224,-0.0026036268,-0.041022312,0.052016445,-0.0051090918,-0.010180788,-0.037189327,-0.058523174,0.042742483,0.026008222,-0.02077292,-0.0006310406,-0.043490384,-0.062748805,-0.031897932,-0.04135887,0.03859164,-0.02623259,0.010274276,-0.04165803,-0.014827117,0.012284257,-0.025222927,-0.014079217,-0.03154268,-0.11854215,0.0061514773,0.035226088,0.010685621,0.038890798,-0.013695918,-0.05508283,-0.009414191,0.024549816,0.035917897,0.24486245,-0.0070396084,-0.056728214,-0.067385785,0.018482478,-0.003865708,0.00044552636,-0.044612233,0.032047514,-0.034197725,-0.025896037,0.0358992,0.029205494,0.013593082,-0.012985413,0.026943097,0.010853899,0.031224824,0.089149676,0.0075304178,0.021558218,0.019426702,0.018893823,-0.010274276,-0.0366471,-0.033730287,-0.02834541,0.024568515,-0.0056653423,0.00501093,-0.023110108,-0.0151075795,0.014462516,-0.053437453,-0.015612412,0.044350468,0.005613924,-0.011975748,0.00788567,0.009844233,0.01592092,-0.047716018,-0.004837978,0.033786383,0.054858465,0.027522719,-0.02430675,-0.018398339,-0.003316469,0.009825536,-0.0003052951,0.014275541,0.011330685,0.019538887,0.008890661,0.050109297,0.0034006077,-0.02677482,-0.027391836,0.06013116,0.0009868774,0.012835833,-0.089149676,0.0047561764,0.04105971,0.02161431,-0.043490384,0.005398903,0.003503444,0.0071845143,0.11345643,0.0016114907,-0.027167467,0.040162228,0.019800652,0.016210731,-0.0050623477,0.027616207,0.001446719,0.010891293,-0.0036366635,-0.0060907104,-0.0725089,-0.039152563,0.00800253,-0.021707797,0.038853403,0.031897932,0.007899693,-0.045360133,-0.03298239,-0.0027648928,-0.029803814,-0.015229113,-0.05698998,0.013321969,0.022343513,-0.015462832,-0.04764123,-0.0336555,-0.014322285,-0.031037848,0.016734261,0.020492459,-0.0043798895,-0.023465361,0.016584681,0.0029355073,0.010779109,0.014855163,-0.020679435,0.029785117,0.021782586,-0.025914734,-0.0025405227,-0.0049828836,-0.0016640774,0.010601482,0.04995972,0.030944362,-0.0209412,0.005936456,-0.014602747,0.03335634,-0.03371159,-0.0014478876,-0.014677537,0.03520739,-0.027915366,0.0605799,0.047454253,-0.033244155,-0.047828205,0.05519502,0.000982203,-0.016042454,0.025522087,0.023315782,0.035637435,0.03387987,0.031449195,-0.045060974,-0.016182685,-0.0075117205,0.0009553254,-0.016397707,0.01256472,0.020305485,0.013368712,0.030476924,0.006034618,0.012611464,-0.022680067,-0.039152563,-0.0031505288,-0.04218156,-0.022960529,-0.004347169,0.010377112,-0.055045437,0.018230062,-0.007581836,-0.004040997,0.068881586,0.054334935,0.024044985,-0.0039965906,-0.005478367,0.021801284,-0.0057448065,0.037432395,-0.009666607,-0.013770708,-0.0042606927,-0.0085681295,-0.026438264,-0.05437233,-0.026363473,-0.032926295,0.00942354,0.041732818,-0.03649752,0.0071891886,0.022810949,0.03986307,0.0045738756,-0.010797806,-0.012658207,0.0075537898,-0.0104706,-0.0058523174,0.09662867,-0.0003643091,-0.032103606,0.030551715,0.016565984,0.017622393,-0.03477735,-0.019183634,0.0054409723,0.009133728,0.012527324,-0.025690364,0.0028092994,0.034197725,-0.0231849,-0.056952585,-0.020492459,0.007829578,0.030944362,-0.022306116,-0.00061584887,0.008273643,0.0018265119,-0.055008043,0.03328155,0.024269354,0.005034302,-0.0071284217,-0.01487386,0.0101714395,0.0023173213,0.018435735,-0.018491827,0.008946753,0.008455944,0.0013251853,-0.021202965,0.06465595,0.012611464,0.010003163,-0.013705267,0.0032580392,-0.04031181,0.02864457,0.005595227,-0.01406052,0.030327344,-0.03393596,-0.009044915,0.0039475095,0.026849609,-0.011564404,0.08727993,-0.00020012168,0.011573752,0.0056419703,0.036534913,0.0153693445,0.034739953,0.052427787,0.015079534,0.0008875469,-0.04909963,-0.021389939,0.0635715,-0.027167467,0.006025269,-0.016537938,0.012807787,-0.004087741,0.016248127,-0.03677798,-0.015219765,-0.029112007,-0.1038833,0.016435102,-0.024886372,-0.0043308083,-0.063982844,-0.041321475,-0.016014408,0.006039292,0.0114054745,0.023633638,0.012807787,-0.024026286,-0.03707714,-0.0024283377,0.01443447,0.057550903,0.034048147,0.011779425,-0.0028607175,-0.02974772,0.011059571,-0.008404526,0.02183868,-0.0028116365,0.013406107,0.029280284,0.01771588,-0.03171096,0.043041643,-0.010442553,0.030009486,-0.06865722,-0.022044351,-0.055456784,0.014116612,-0.030719992,0.023427967,-0.064282,-0.016622078,0.008713035,-0.015378693,-0.025166834,-0.0018335235,0.08727993,-0.015584365,-0.021576915,-0.049772743,0.016883843,-0.01600506,0.016622078,0.019127542,0.0344034,-0.016472496,-0.029859906,0.040797945,-0.018949915,-0.068956375,-0.014733629,-0.071761005,-0.004847327,-0.0073527917,-0.013041506,0.031467892,0.004791234,0.017323233,0.006525427,-0.004604259,0.00201115,-0.016631426,-0.03058911,0.02481158,0.025035951,-0.029093308,-0.028382804,-0.0231849,0.009002846,-0.028438896,0.073144615,-0.009559097,0.021932166,-0.031019151,0.021932166,-0.005277369,0.008381154,0.028999822,0.025970826,-0.04001265,-0.023371873,-0.0403866,0.0002968228,0.014032473,0.027017886,0.039713487,0.032402765,-0.023427967,0.011022176,0.0433782,0.011461567,0.0028887636,-0.047753412,-0.016425753,0.029336376,-0.02922419,-0.0123310005,-0.025017254,-0.018351596,0.09782532,-0.026830912,-0.004524795,-0.0002826536,0.060617294,0.026999189,-0.011770076,0.019034054,0.0055812034,0.0068386104,-0.049847532,-0.044126097,-0.008133412,0.0426303,-0.025110742,-0.0048052575,-0.006520753,0.037638064,-0.015939618,-0.033674195,0.0064272652,-0.0076519516,-0.022025654,-0.15586236,0.012976064,-0.009503004,-0.05803704,-0.04599585,0.0046159453,0.0039101145,-0.0157059,-0.018547919,-0.018230062,-0.047229882,-0.02870066,0.08698077,-0.004866024,0.0035314902,0.008540083,0.001127693,0.0060299435,0.034291215,0.024026286,-0.029280284,0.014144658,0.048276942,-0.0054456466,0.013331317,-0.022867043,-0.027242256,-0.0051698587,-0.024886372,-0.04375215,-0.00033509426,0.02655045,-0.014939302,0.044836603,0.0064506372,-0.036310542,-0.016248127,-0.011994446,0.026737424,-0.03468386,0.022867043,0.007862299,-0.04135887,0.0051651844,0.015014092,0.0026480334,-0.023465361,0.013237829,-0.07299504,-0.036927562,-0.02378322,-0.008755104,-0.03859164,0.032346673,-0.031523984,-0.00022831399,-0.0011107483,-0.014696235,0.009484307,0.030495621,0.0047818855,0.033692893,-0.017089514,0.010676272,-0.06873201,0.018230062,-0.039526515,0.056316867,-0.034496885,0.0058149225,-0.019108845,0.045397528,0.019408004,-0.006595543,0.0077501135,0.04966056,0.059719812,-0.014312936,0.017912205,-0.011022176,0.022006957,0.008811196,-0.035992686,0.022493092,-0.016612729,-0.027504021,0.00957312,0.0007817892,-0.047977783,0.004809932,-0.023502756,-0.02924289,0.0051184404,-0.032552347,-0.002678417,-0.06162696,-0.01862271,0.009302006,-0.017594347,0.004101764,0.011003478,0.014742978,0.032720625,0.0157059,-0.02430675,0.046407193,0.03933954,-0.008100691,0.022268722,0.032571044,-0.013808103,-0.025690364,-0.034646466,-0.014172705,0.023054017,0.007581836,-0.014266192,0.020511156,-0.035787012,-0.010909991,0.009900326,0.023390573,-0.004550504,-0.017790671,-0.010956734,0.02780318,0.030233856,-0.045285344,-0.029953394,-0.0019877779,0.020660738,-0.060841665,0.026363473,0.037488487,-0.015285206,-0.023858009,0.0017423732,0.053587034,-0.048650894,-0.035001718,-0.053811405,0.022081748,0.017622393,-0.0035852455,-0.027148768,-0.006885354,0.016911888,0.012190769,-0.029729024,-0.012340349,0.0875043,0.002418989,-0.017594347,0.056354262,-0.03904038,0.041919794,-0.0009307849,0.018304853,0.017360628,0.008063297,-0.027560115,0.016519241,-0.0034473515,-0.009778792,-0.036628403,0.032402765,-0.002007644,-0.0078108804,-0.044387862,-0.012732998,-0.023801917,-0.009484307,-0.02849499,0.010938037,0.01084455,0.021651704,0.020380273,0.051904257,0.047379464,-0.013518292,0.017089514,0.06271141,0.0038259758,0.007890345,-0.026887003,0.01577134,0.014612095,0.011255895,0.05792485,0.018594664,0.042443324,-0.0029588793,0.07415428,-0.007848276,0.028457593,-0.002212148,-0.022268722,0.001005575,-0.00059218484,-0.009086985,-0.04397652,0.007020911,-0.102761455,-0.010246229,0.00058751047,0.018445084,-0.018566618,-0.06611436,-0.014574701,-0.042892065,-0.037881132,-0.024998557,0.020698132,0.058597963,0.019968929,0.02535381,-0.0011820325,0.017042771,0.021745192,-0.024886372,-0.010816503,0.019408004,0.04891266,-0.027410533,-0.02077292,0.016837098,0.007156468,-0.0050670225,0.029672932,-0.033001088,-0.05437233,-0.0179496,-0.044313073,0.024998557,0.0036647099,-0.0321784,0.049473584,0.0023488733,-0.06832066,0.036609706,0.04472442,-0.019800652,-0.048276942,0.045734085]
8	310f297e-d179-4e33-ad71-26ea827175b2	\N	\N	Dr. E2E	$2b$12$AGXu9I9IAIbZQFLlBXYJEe7n1E58LxSUY9ZHSDbx2akFIu/7wkbse	全科测试	5.0	1	男	[0.0024914418,0.007694021,-0.026045617,-0.027092677,-0.01630422,0.015472181,-0.00041543506,-0.030252554,-0.0021069744,-0.024381539,-0.0033234805,-0.007521069,0.029093308,0.012648858,0.0076145567,-0.0545967,-0.04154584,-0.011732681,0.007544441,-0.014023124,-0.019819349,-0.0153226005,0.023577547,0.0063524754,0.049585767,0.03874122,-0.042443324,-0.01391094,-0.028831543,-0.00852606,0.0043588546,0.018117877,0.002818648,-0.06611436,-0.0657778,-0.033487223,0.020137208,-0.024643304,-0.034141634,0.024344144,0.01301346,-0.01592092,0.0009646741,-0.006137454,-0.016612729,-0.024138471,0.0006012415,-0.026943097,-0.0061655003,-0.009002846,0.0030663898,-0.0040830662,0.03619836,-0.045921057,0.055681154,0.025690364,0.040797945,-0.0007607545,-0.079875715,-0.038890798,0.0057027373,0.028513687,0.0123310005,0.01555632,0.0018522211,0.03281411,0.023577547,-0.012097282,0.0051231147,-0.027578812,0.013882893,-0.009694654,0.019576281,-0.020642038,-0.08481186,0.006100059,0.036104873,0.03333764,0.03986307,-0.03258974,0.005511088,-0.0073060477,-0.02340927,-0.0063291034,-0.04053618,0.010489297,-0.028962426,-0.005151161,-0.009984464,0.0065394505,-0.042218953,-0.014967348,0.014976697,-0.018519873,-0.026456961,0.010367763,-0.027877972,-0.012546022,0.017183002,-0.023427967,0.032122303,-0.0021852702,0.014387726,-0.007974483,0.041246682,0.01884708,0.03724542,0.016640775,-0.01084455,0.0010084964,0.011788773,-0.012312303,0.018304853,0.028008854,0.017519558,0.022904437,0.0084278975,0.010909991,0.008222225,0.0048800474,0.06312276,0.01974456,0.025035951,-0.026307382,0.0042980877,-0.0073294197,0.035637435,0.026662635,-0.02535381,-0.011386777,-0.030402133,0.06488033,-0.04315383,0.031374402,-0.022455696,-0.0018463781,0.0023850997,-0.008423223,-0.004889396,-0.038180295,0.052427787,0.052652158,-0.023446664,-0.022006957,0.013041506,-0.04891266,0.013686569,-0.043266013,0.01406052,-0.03948912,0.020959897,0.016939934,0.026887003,0.007946437,0.011125012,0.029934697,-0.026213894,0.021558218,-0.0089748,0.016079849,0.021913469,0.010040557,0.037507184,0.0043962495,-0.01353699,0.004852001,0.0068806796,0.004199926,-0.030084277,0.030327344,-0.006707728,-0.04375215,-0.0358992,-0.03165487,0.0065534734,0.003204284,0.045285344,0.01548153,0.0231849,-0.040498782,0.010115347,-0.0014502248,0.0069881906,-0.032346673,-0.0426303,-0.00930668,0.052166022,-0.041209288,-0.0052353,-0.017912205,-0.007147119,-0.015537622,0.07015302,-0.007441605,0.03335634,0.019968929,0.013116295,-0.005945805,0.03313197,-0.0058803638,-0.053063504,0.012873229,0.029336376,0.0022296768,-0.03416033,-0.009058938,-0.040237017,-0.01989414,0.028308013,0.009189821,-0.00029945213,-0.0050062556,0.01629487,0.008502688,0.0018487152,-0.018304853,0.03769416,-0.008194179,0.007432256,-0.028083645,0.009054264,0.033318944,0.036665797,-0.03507651,0.012396442,-0.019389307,0.05885973,0.027765786,0.02587734,-0.055830732,0.0074462793,0.0129012745,-0.009610515,-0.031954028,0.0064506372,0.030140368,0.008848592,-0.007941763,0.025017254,0.019277122,-0.022100445,0.020211997,0.050558038,-0.0069040516,-0.009316029,-0.023353176,0.013219132,0.020305485,-0.043639965,-0.034870837,0.022380907,-0.0021373578,-0.03851685,0.03717063,0.03545046,-0.010853899,0.012461883,0.0011031525,0.014920604,0.0035805712,0.028906334,-0.0050670225,0.027728392,0.019333214,-0.015154324,-0.006735774,-0.016631426,0.0039685443,-0.0381242,0.009881629,-0.019445399,-0.012648858,0.02849499,-0.005712086,-0.018360944,0.06903117,0.0014233472,-0.029803814,0.07441605,0.0054549957,-0.019594979,-0.027709695,-0.006885354,-0.05990679,-0.005071697,-0.0069180746,-0.010442553,-0.045696687,0.0160892,-0.019987626,0.018716197,0.02759751,0.088177405,-0.015294555,-0.028195828,-0.037413698,-0.003031332,-0.15287076,-0.02832671,-0.030196462,-0.03236537,-0.0020730852,-0.0057167606,0.0011563235,0.013583734,-0.0057448065,0.047304675,0.015182369,-0.07292025,-0.014527957,-0.0023512105,0.01899666,-0.0261765,-0.01615464,-0.012134677,-0.017267141,-0.04053618,0.012312303,-0.042518113,0.033917263,-0.00900752,-0.014107264,-0.01764109,0.057663087,-0.027541416,-0.0010534872,-0.010405159,-0.014939302,0.022923134,0.0011311987,0.029654235,0.028663266,0.015004743,-0.0032720624,0.016173337,-0.018061785,0.0134622,0.001895459,0.03270193,0.013331317,0.018061785,-0.0013508943,-0.004973535,0.04367736,0.015238462,-0.012546022,-0.008895336,-0.0014432132,-0.021296453,0.013649175,0.0059177587,-0.020754224,-0.0026036268,-0.041022312,0.052016445,-0.0051090918,-0.010180788,-0.037189327,-0.058523174,0.042742483,0.026008222,-0.02077292,-0.0006310406,-0.043490384,-0.062748805,-0.031897932,-0.04135887,0.03859164,-0.02623259,0.010274276,-0.04165803,-0.014827117,0.012284257,-0.025222927,-0.014079217,-0.03154268,-0.11854215,0.0061514773,0.035226088,0.010685621,0.038890798,-0.013695918,-0.05508283,-0.009414191,0.024549816,0.035917897,0.24486245,-0.0070396084,-0.056728214,-0.067385785,0.018482478,-0.003865708,0.00044552636,-0.044612233,0.032047514,-0.034197725,-0.025896037,0.0358992,0.029205494,0.013593082,-0.012985413,0.026943097,0.010853899,0.031224824,0.089149676,0.0075304178,0.021558218,0.019426702,0.018893823,-0.010274276,-0.0366471,-0.033730287,-0.02834541,0.024568515,-0.0056653423,0.00501093,-0.023110108,-0.0151075795,0.014462516,-0.053437453,-0.015612412,0.044350468,0.005613924,-0.011975748,0.00788567,0.009844233,0.01592092,-0.047716018,-0.004837978,0.033786383,0.054858465,0.027522719,-0.02430675,-0.018398339,-0.003316469,0.009825536,-0.0003052951,0.014275541,0.011330685,0.019538887,0.008890661,0.050109297,0.0034006077,-0.02677482,-0.027391836,0.06013116,0.0009868774,0.012835833,-0.089149676,0.0047561764,0.04105971,0.02161431,-0.043490384,0.005398903,0.003503444,0.0071845143,0.11345643,0.0016114907,-0.027167467,0.040162228,0.019800652,0.016210731,-0.0050623477,0.027616207,0.001446719,0.010891293,-0.0036366635,-0.0060907104,-0.0725089,-0.039152563,0.00800253,-0.021707797,0.038853403,0.031897932,0.007899693,-0.045360133,-0.03298239,-0.0027648928,-0.029803814,-0.015229113,-0.05698998,0.013321969,0.022343513,-0.015462832,-0.04764123,-0.0336555,-0.014322285,-0.031037848,0.016734261,0.020492459,-0.0043798895,-0.023465361,0.016584681,0.0029355073,0.010779109,0.014855163,-0.020679435,0.029785117,0.021782586,-0.025914734,-0.0025405227,-0.0049828836,-0.0016640774,0.010601482,0.04995972,0.030944362,-0.0209412,0.005936456,-0.014602747,0.03335634,-0.03371159,-0.0014478876,-0.014677537,0.03520739,-0.027915366,0.0605799,0.047454253,-0.033244155,-0.047828205,0.05519502,0.000982203,-0.016042454,0.025522087,0.023315782,0.035637435,0.03387987,0.031449195,-0.045060974,-0.016182685,-0.0075117205,0.0009553254,-0.016397707,0.01256472,0.020305485,0.013368712,0.030476924,0.006034618,0.012611464,-0.022680067,-0.039152563,-0.0031505288,-0.04218156,-0.022960529,-0.004347169,0.010377112,-0.055045437,0.018230062,-0.007581836,-0.004040997,0.068881586,0.054334935,0.024044985,-0.0039965906,-0.005478367,0.021801284,-0.0057448065,0.037432395,-0.009666607,-0.013770708,-0.0042606927,-0.0085681295,-0.026438264,-0.05437233,-0.026363473,-0.032926295,0.00942354,0.041732818,-0.03649752,0.0071891886,0.022810949,0.03986307,0.0045738756,-0.010797806,-0.012658207,0.0075537898,-0.0104706,-0.0058523174,0.09662867,-0.0003643091,-0.032103606,0.030551715,0.016565984,0.017622393,-0.03477735,-0.019183634,0.0054409723,0.009133728,0.012527324,-0.025690364,0.0028092994,0.034197725,-0.0231849,-0.056952585,-0.020492459,0.007829578,0.030944362,-0.022306116,-0.00061584887,0.008273643,0.0018265119,-0.055008043,0.03328155,0.024269354,0.005034302,-0.0071284217,-0.01487386,0.0101714395,0.0023173213,0.018435735,-0.018491827,0.008946753,0.008455944,0.0013251853,-0.021202965,0.06465595,0.012611464,0.010003163,-0.013705267,0.0032580392,-0.04031181,0.02864457,0.005595227,-0.01406052,0.030327344,-0.03393596,-0.009044915,0.0039475095,0.026849609,-0.011564404,0.08727993,-0.00020012168,0.011573752,0.0056419703,0.036534913,0.0153693445,0.034739953,0.052427787,0.015079534,0.0008875469,-0.04909963,-0.021389939,0.0635715,-0.027167467,0.006025269,-0.016537938,0.012807787,-0.004087741,0.016248127,-0.03677798,-0.015219765,-0.029112007,-0.1038833,0.016435102,-0.024886372,-0.0043308083,-0.063982844,-0.041321475,-0.016014408,0.006039292,0.0114054745,0.023633638,0.012807787,-0.024026286,-0.03707714,-0.0024283377,0.01443447,0.057550903,0.034048147,0.011779425,-0.0028607175,-0.02974772,0.011059571,-0.008404526,0.02183868,-0.0028116365,0.013406107,0.029280284,0.01771588,-0.03171096,0.043041643,-0.010442553,0.030009486,-0.06865722,-0.022044351,-0.055456784,0.014116612,-0.030719992,0.023427967,-0.064282,-0.016622078,0.008713035,-0.015378693,-0.025166834,-0.0018335235,0.08727993,-0.015584365,-0.021576915,-0.049772743,0.016883843,-0.01600506,0.016622078,0.019127542,0.0344034,-0.016472496,-0.029859906,0.040797945,-0.018949915,-0.068956375,-0.014733629,-0.071761005,-0.004847327,-0.0073527917,-0.013041506,0.031467892,0.004791234,0.017323233,0.006525427,-0.004604259,0.00201115,-0.016631426,-0.03058911,0.02481158,0.025035951,-0.029093308,-0.028382804,-0.0231849,0.009002846,-0.028438896,0.073144615,-0.009559097,0.021932166,-0.031019151,0.021932166,-0.005277369,0.008381154,0.028999822,0.025970826,-0.04001265,-0.023371873,-0.0403866,0.0002968228,0.014032473,0.027017886,0.039713487,0.032402765,-0.023427967,0.011022176,0.0433782,0.011461567,0.0028887636,-0.047753412,-0.016425753,0.029336376,-0.02922419,-0.0123310005,-0.025017254,-0.018351596,0.09782532,-0.026830912,-0.004524795,-0.0002826536,0.060617294,0.026999189,-0.011770076,0.019034054,0.0055812034,0.0068386104,-0.049847532,-0.044126097,-0.008133412,0.0426303,-0.025110742,-0.0048052575,-0.006520753,0.037638064,-0.015939618,-0.033674195,0.0064272652,-0.0076519516,-0.022025654,-0.15586236,0.012976064,-0.009503004,-0.05803704,-0.04599585,0.0046159453,0.0039101145,-0.0157059,-0.018547919,-0.018230062,-0.047229882,-0.02870066,0.08698077,-0.004866024,0.0035314902,0.008540083,0.001127693,0.0060299435,0.034291215,0.024026286,-0.029280284,0.014144658,0.048276942,-0.0054456466,0.013331317,-0.022867043,-0.027242256,-0.0051698587,-0.024886372,-0.04375215,-0.00033509426,0.02655045,-0.014939302,0.044836603,0.0064506372,-0.036310542,-0.016248127,-0.011994446,0.026737424,-0.03468386,0.022867043,0.007862299,-0.04135887,0.0051651844,0.015014092,0.0026480334,-0.023465361,0.013237829,-0.07299504,-0.036927562,-0.02378322,-0.008755104,-0.03859164,0.032346673,-0.031523984,-0.00022831399,-0.0011107483,-0.014696235,0.009484307,0.030495621,0.0047818855,0.033692893,-0.017089514,0.010676272,-0.06873201,0.018230062,-0.039526515,0.056316867,-0.034496885,0.0058149225,-0.019108845,0.045397528,0.019408004,-0.006595543,0.0077501135,0.04966056,0.059719812,-0.014312936,0.017912205,-0.011022176,0.022006957,0.008811196,-0.035992686,0.022493092,-0.016612729,-0.027504021,0.00957312,0.0007817892,-0.047977783,0.004809932,-0.023502756,-0.02924289,0.0051184404,-0.032552347,-0.002678417,-0.06162696,-0.01862271,0.009302006,-0.017594347,0.004101764,0.011003478,0.014742978,0.032720625,0.0157059,-0.02430675,0.046407193,0.03933954,-0.008100691,0.022268722,0.032571044,-0.013808103,-0.025690364,-0.034646466,-0.014172705,0.023054017,0.007581836,-0.014266192,0.020511156,-0.035787012,-0.010909991,0.009900326,0.023390573,-0.004550504,-0.017790671,-0.010956734,0.02780318,0.030233856,-0.045285344,-0.029953394,-0.0019877779,0.020660738,-0.060841665,0.026363473,0.037488487,-0.015285206,-0.023858009,0.0017423732,0.053587034,-0.048650894,-0.035001718,-0.053811405,0.022081748,0.017622393,-0.0035852455,-0.027148768,-0.006885354,0.016911888,0.012190769,-0.029729024,-0.012340349,0.0875043,0.002418989,-0.017594347,0.056354262,-0.03904038,0.041919794,-0.0009307849,0.018304853,0.017360628,0.008063297,-0.027560115,0.016519241,-0.0034473515,-0.009778792,-0.036628403,0.032402765,-0.002007644,-0.0078108804,-0.044387862,-0.012732998,-0.023801917,-0.009484307,-0.02849499,0.010938037,0.01084455,0.021651704,0.020380273,0.051904257,0.047379464,-0.013518292,0.017089514,0.06271141,0.0038259758,0.007890345,-0.026887003,0.01577134,0.014612095,0.011255895,0.05792485,0.018594664,0.042443324,-0.0029588793,0.07415428,-0.007848276,0.028457593,-0.002212148,-0.022268722,0.001005575,-0.00059218484,-0.009086985,-0.04397652,0.007020911,-0.102761455,-0.010246229,0.00058751047,0.018445084,-0.018566618,-0.06611436,-0.014574701,-0.042892065,-0.037881132,-0.024998557,0.020698132,0.058597963,0.019968929,0.02535381,-0.0011820325,0.017042771,0.021745192,-0.024886372,-0.010816503,0.019408004,0.04891266,-0.027410533,-0.02077292,0.016837098,0.007156468,-0.0050670225,0.029672932,-0.033001088,-0.05437233,-0.0179496,-0.044313073,0.024998557,0.0036647099,-0.0321784,0.049473584,0.0023488733,-0.06832066,0.036609706,0.04472442,-0.019800652,-0.048276942,0.045734085]
10	f26799d5-06e5-4d8e-bc48-464ef26b9325	\N	\N	Dr. E2E 03172b	$2b$12$edBZFUN8tRtO8APRuEvluOsv2cM.u/1JsBnxZjbiww3bfc4.lgVr2	全科测试	5.0	1	男	[0.0024914418,0.007694021,-0.026045617,-0.027092677,-0.01630422,0.015472181,-0.00041543506,-0.030252554,-0.0021069744,-0.024381539,-0.0033234805,-0.007521069,0.029093308,0.012648858,0.0076145567,-0.0545967,-0.04154584,-0.011732681,0.007544441,-0.014023124,-0.019819349,-0.0153226005,0.023577547,0.0063524754,0.049585767,0.03874122,-0.042443324,-0.01391094,-0.028831543,-0.00852606,0.0043588546,0.018117877,0.002818648,-0.06611436,-0.0657778,-0.033487223,0.020137208,-0.024643304,-0.034141634,0.024344144,0.01301346,-0.01592092,0.0009646741,-0.006137454,-0.016612729,-0.024138471,0.0006012415,-0.026943097,-0.0061655003,-0.009002846,0.0030663898,-0.0040830662,0.03619836,-0.045921057,0.055681154,0.025690364,0.040797945,-0.0007607545,-0.079875715,-0.038890798,0.0057027373,0.028513687,0.0123310005,0.01555632,0.0018522211,0.03281411,0.023577547,-0.012097282,0.0051231147,-0.027578812,0.013882893,-0.009694654,0.019576281,-0.020642038,-0.08481186,0.006100059,0.036104873,0.03333764,0.03986307,-0.03258974,0.005511088,-0.0073060477,-0.02340927,-0.0063291034,-0.04053618,0.010489297,-0.028962426,-0.005151161,-0.009984464,0.0065394505,-0.042218953,-0.014967348,0.014976697,-0.018519873,-0.026456961,0.010367763,-0.027877972,-0.012546022,0.017183002,-0.023427967,0.032122303,-0.0021852702,0.014387726,-0.007974483,0.041246682,0.01884708,0.03724542,0.016640775,-0.01084455,0.0010084964,0.011788773,-0.012312303,0.018304853,0.028008854,0.017519558,0.022904437,0.0084278975,0.010909991,0.008222225,0.0048800474,0.06312276,0.01974456,0.025035951,-0.026307382,0.0042980877,-0.0073294197,0.035637435,0.026662635,-0.02535381,-0.011386777,-0.030402133,0.06488033,-0.04315383,0.031374402,-0.022455696,-0.0018463781,0.0023850997,-0.008423223,-0.004889396,-0.038180295,0.052427787,0.052652158,-0.023446664,-0.022006957,0.013041506,-0.04891266,0.013686569,-0.043266013,0.01406052,-0.03948912,0.020959897,0.016939934,0.026887003,0.007946437,0.011125012,0.029934697,-0.026213894,0.021558218,-0.0089748,0.016079849,0.021913469,0.010040557,0.037507184,0.0043962495,-0.01353699,0.004852001,0.0068806796,0.004199926,-0.030084277,0.030327344,-0.006707728,-0.04375215,-0.0358992,-0.03165487,0.0065534734,0.003204284,0.045285344,0.01548153,0.0231849,-0.040498782,0.010115347,-0.0014502248,0.0069881906,-0.032346673,-0.0426303,-0.00930668,0.052166022,-0.041209288,-0.0052353,-0.017912205,-0.007147119,-0.015537622,0.07015302,-0.007441605,0.03335634,0.019968929,0.013116295,-0.005945805,0.03313197,-0.0058803638,-0.053063504,0.012873229,0.029336376,0.0022296768,-0.03416033,-0.009058938,-0.040237017,-0.01989414,0.028308013,0.009189821,-0.00029945213,-0.0050062556,0.01629487,0.008502688,0.0018487152,-0.018304853,0.03769416,-0.008194179,0.007432256,-0.028083645,0.009054264,0.033318944,0.036665797,-0.03507651,0.012396442,-0.019389307,0.05885973,0.027765786,0.02587734,-0.055830732,0.0074462793,0.0129012745,-0.009610515,-0.031954028,0.0064506372,0.030140368,0.008848592,-0.007941763,0.025017254,0.019277122,-0.022100445,0.020211997,0.050558038,-0.0069040516,-0.009316029,-0.023353176,0.013219132,0.020305485,-0.043639965,-0.034870837,0.022380907,-0.0021373578,-0.03851685,0.03717063,0.03545046,-0.010853899,0.012461883,0.0011031525,0.014920604,0.0035805712,0.028906334,-0.0050670225,0.027728392,0.019333214,-0.015154324,-0.006735774,-0.016631426,0.0039685443,-0.0381242,0.009881629,-0.019445399,-0.012648858,0.02849499,-0.005712086,-0.018360944,0.06903117,0.0014233472,-0.029803814,0.07441605,0.0054549957,-0.019594979,-0.027709695,-0.006885354,-0.05990679,-0.005071697,-0.0069180746,-0.010442553,-0.045696687,0.0160892,-0.019987626,0.018716197,0.02759751,0.088177405,-0.015294555,-0.028195828,-0.037413698,-0.003031332,-0.15287076,-0.02832671,-0.030196462,-0.03236537,-0.0020730852,-0.0057167606,0.0011563235,0.013583734,-0.0057448065,0.047304675,0.015182369,-0.07292025,-0.014527957,-0.0023512105,0.01899666,-0.0261765,-0.01615464,-0.012134677,-0.017267141,-0.04053618,0.012312303,-0.042518113,0.033917263,-0.00900752,-0.014107264,-0.01764109,0.057663087,-0.027541416,-0.0010534872,-0.010405159,-0.014939302,0.022923134,0.0011311987,0.029654235,0.028663266,0.015004743,-0.0032720624,0.016173337,-0.018061785,0.0134622,0.001895459,0.03270193,0.013331317,0.018061785,-0.0013508943,-0.004973535,0.04367736,0.015238462,-0.012546022,-0.008895336,-0.0014432132,-0.021296453,0.013649175,0.0059177587,-0.020754224,-0.0026036268,-0.041022312,0.052016445,-0.0051090918,-0.010180788,-0.037189327,-0.058523174,0.042742483,0.026008222,-0.02077292,-0.0006310406,-0.043490384,-0.062748805,-0.031897932,-0.04135887,0.03859164,-0.02623259,0.010274276,-0.04165803,-0.014827117,0.012284257,-0.025222927,-0.014079217,-0.03154268,-0.11854215,0.0061514773,0.035226088,0.010685621,0.038890798,-0.013695918,-0.05508283,-0.009414191,0.024549816,0.035917897,0.24486245,-0.0070396084,-0.056728214,-0.067385785,0.018482478,-0.003865708,0.00044552636,-0.044612233,0.032047514,-0.034197725,-0.025896037,0.0358992,0.029205494,0.013593082,-0.012985413,0.026943097,0.010853899,0.031224824,0.089149676,0.0075304178,0.021558218,0.019426702,0.018893823,-0.010274276,-0.0366471,-0.033730287,-0.02834541,0.024568515,-0.0056653423,0.00501093,-0.023110108,-0.0151075795,0.014462516,-0.053437453,-0.015612412,0.044350468,0.005613924,-0.011975748,0.00788567,0.009844233,0.01592092,-0.047716018,-0.004837978,0.033786383,0.054858465,0.027522719,-0.02430675,-0.018398339,-0.003316469,0.009825536,-0.0003052951,0.014275541,0.011330685,0.019538887,0.008890661,0.050109297,0.0034006077,-0.02677482,-0.027391836,0.06013116,0.0009868774,0.012835833,-0.089149676,0.0047561764,0.04105971,0.02161431,-0.043490384,0.005398903,0.003503444,0.0071845143,0.11345643,0.0016114907,-0.027167467,0.040162228,0.019800652,0.016210731,-0.0050623477,0.027616207,0.001446719,0.010891293,-0.0036366635,-0.0060907104,-0.0725089,-0.039152563,0.00800253,-0.021707797,0.038853403,0.031897932,0.007899693,-0.045360133,-0.03298239,-0.0027648928,-0.029803814,-0.015229113,-0.05698998,0.013321969,0.022343513,-0.015462832,-0.04764123,-0.0336555,-0.014322285,-0.031037848,0.016734261,0.020492459,-0.0043798895,-0.023465361,0.016584681,0.0029355073,0.010779109,0.014855163,-0.020679435,0.029785117,0.021782586,-0.025914734,-0.0025405227,-0.0049828836,-0.0016640774,0.010601482,0.04995972,0.030944362,-0.0209412,0.005936456,-0.014602747,0.03335634,-0.03371159,-0.0014478876,-0.014677537,0.03520739,-0.027915366,0.0605799,0.047454253,-0.033244155,-0.047828205,0.05519502,0.000982203,-0.016042454,0.025522087,0.023315782,0.035637435,0.03387987,0.031449195,-0.045060974,-0.016182685,-0.0075117205,0.0009553254,-0.016397707,0.01256472,0.020305485,0.013368712,0.030476924,0.006034618,0.012611464,-0.022680067,-0.039152563,-0.0031505288,-0.04218156,-0.022960529,-0.004347169,0.010377112,-0.055045437,0.018230062,-0.007581836,-0.004040997,0.068881586,0.054334935,0.024044985,-0.0039965906,-0.005478367,0.021801284,-0.0057448065,0.037432395,-0.009666607,-0.013770708,-0.0042606927,-0.0085681295,-0.026438264,-0.05437233,-0.026363473,-0.032926295,0.00942354,0.041732818,-0.03649752,0.0071891886,0.022810949,0.03986307,0.0045738756,-0.010797806,-0.012658207,0.0075537898,-0.0104706,-0.0058523174,0.09662867,-0.0003643091,-0.032103606,0.030551715,0.016565984,0.017622393,-0.03477735,-0.019183634,0.0054409723,0.009133728,0.012527324,-0.025690364,0.0028092994,0.034197725,-0.0231849,-0.056952585,-0.020492459,0.007829578,0.030944362,-0.022306116,-0.00061584887,0.008273643,0.0018265119,-0.055008043,0.03328155,0.024269354,0.005034302,-0.0071284217,-0.01487386,0.0101714395,0.0023173213,0.018435735,-0.018491827,0.008946753,0.008455944,0.0013251853,-0.021202965,0.06465595,0.012611464,0.010003163,-0.013705267,0.0032580392,-0.04031181,0.02864457,0.005595227,-0.01406052,0.030327344,-0.03393596,-0.009044915,0.0039475095,0.026849609,-0.011564404,0.08727993,-0.00020012168,0.011573752,0.0056419703,0.036534913,0.0153693445,0.034739953,0.052427787,0.015079534,0.0008875469,-0.04909963,-0.021389939,0.0635715,-0.027167467,0.006025269,-0.016537938,0.012807787,-0.004087741,0.016248127,-0.03677798,-0.015219765,-0.029112007,-0.1038833,0.016435102,-0.024886372,-0.0043308083,-0.063982844,-0.041321475,-0.016014408,0.006039292,0.0114054745,0.023633638,0.012807787,-0.024026286,-0.03707714,-0.0024283377,0.01443447,0.057550903,0.034048147,0.011779425,-0.0028607175,-0.02974772,0.011059571,-0.008404526,0.02183868,-0.0028116365,0.013406107,0.029280284,0.01771588,-0.03171096,0.043041643,-0.010442553,0.030009486,-0.06865722,-0.022044351,-0.055456784,0.014116612,-0.030719992,0.023427967,-0.064282,-0.016622078,0.008713035,-0.015378693,-0.025166834,-0.0018335235,0.08727993,-0.015584365,-0.021576915,-0.049772743,0.016883843,-0.01600506,0.016622078,0.019127542,0.0344034,-0.016472496,-0.029859906,0.040797945,-0.018949915,-0.068956375,-0.014733629,-0.071761005,-0.004847327,-0.0073527917,-0.013041506,0.031467892,0.004791234,0.017323233,0.006525427,-0.004604259,0.00201115,-0.016631426,-0.03058911,0.02481158,0.025035951,-0.029093308,-0.028382804,-0.0231849,0.009002846,-0.028438896,0.073144615,-0.009559097,0.021932166,-0.031019151,0.021932166,-0.005277369,0.008381154,0.028999822,0.025970826,-0.04001265,-0.023371873,-0.0403866,0.0002968228,0.014032473,0.027017886,0.039713487,0.032402765,-0.023427967,0.011022176,0.0433782,0.011461567,0.0028887636,-0.047753412,-0.016425753,0.029336376,-0.02922419,-0.0123310005,-0.025017254,-0.018351596,0.09782532,-0.026830912,-0.004524795,-0.0002826536,0.060617294,0.026999189,-0.011770076,0.019034054,0.0055812034,0.0068386104,-0.049847532,-0.044126097,-0.008133412,0.0426303,-0.025110742,-0.0048052575,-0.006520753,0.037638064,-0.015939618,-0.033674195,0.0064272652,-0.0076519516,-0.022025654,-0.15586236,0.012976064,-0.009503004,-0.05803704,-0.04599585,0.0046159453,0.0039101145,-0.0157059,-0.018547919,-0.018230062,-0.047229882,-0.02870066,0.08698077,-0.004866024,0.0035314902,0.008540083,0.001127693,0.0060299435,0.034291215,0.024026286,-0.029280284,0.014144658,0.048276942,-0.0054456466,0.013331317,-0.022867043,-0.027242256,-0.0051698587,-0.024886372,-0.04375215,-0.00033509426,0.02655045,-0.014939302,0.044836603,0.0064506372,-0.036310542,-0.016248127,-0.011994446,0.026737424,-0.03468386,0.022867043,0.007862299,-0.04135887,0.0051651844,0.015014092,0.0026480334,-0.023465361,0.013237829,-0.07299504,-0.036927562,-0.02378322,-0.008755104,-0.03859164,0.032346673,-0.031523984,-0.00022831399,-0.0011107483,-0.014696235,0.009484307,0.030495621,0.0047818855,0.033692893,-0.017089514,0.010676272,-0.06873201,0.018230062,-0.039526515,0.056316867,-0.034496885,0.0058149225,-0.019108845,0.045397528,0.019408004,-0.006595543,0.0077501135,0.04966056,0.059719812,-0.014312936,0.017912205,-0.011022176,0.022006957,0.008811196,-0.035992686,0.022493092,-0.016612729,-0.027504021,0.00957312,0.0007817892,-0.047977783,0.004809932,-0.023502756,-0.02924289,0.0051184404,-0.032552347,-0.002678417,-0.06162696,-0.01862271,0.009302006,-0.017594347,0.004101764,0.011003478,0.014742978,0.032720625,0.0157059,-0.02430675,0.046407193,0.03933954,-0.008100691,0.022268722,0.032571044,-0.013808103,-0.025690364,-0.034646466,-0.014172705,0.023054017,0.007581836,-0.014266192,0.020511156,-0.035787012,-0.010909991,0.009900326,0.023390573,-0.004550504,-0.017790671,-0.010956734,0.02780318,0.030233856,-0.045285344,-0.029953394,-0.0019877779,0.020660738,-0.060841665,0.026363473,0.037488487,-0.015285206,-0.023858009,0.0017423732,0.053587034,-0.048650894,-0.035001718,-0.053811405,0.022081748,0.017622393,-0.0035852455,-0.027148768,-0.006885354,0.016911888,0.012190769,-0.029729024,-0.012340349,0.0875043,0.002418989,-0.017594347,0.056354262,-0.03904038,0.041919794,-0.0009307849,0.018304853,0.017360628,0.008063297,-0.027560115,0.016519241,-0.0034473515,-0.009778792,-0.036628403,0.032402765,-0.002007644,-0.0078108804,-0.044387862,-0.012732998,-0.023801917,-0.009484307,-0.02849499,0.010938037,0.01084455,0.021651704,0.020380273,0.051904257,0.047379464,-0.013518292,0.017089514,0.06271141,0.0038259758,0.007890345,-0.026887003,0.01577134,0.014612095,0.011255895,0.05792485,0.018594664,0.042443324,-0.0029588793,0.07415428,-0.007848276,0.028457593,-0.002212148,-0.022268722,0.001005575,-0.00059218484,-0.009086985,-0.04397652,0.007020911,-0.102761455,-0.010246229,0.00058751047,0.018445084,-0.018566618,-0.06611436,-0.014574701,-0.042892065,-0.037881132,-0.024998557,0.020698132,0.058597963,0.019968929,0.02535381,-0.0011820325,0.017042771,0.021745192,-0.024886372,-0.010816503,0.019408004,0.04891266,-0.027410533,-0.02077292,0.016837098,0.007156468,-0.0050670225,0.029672932,-0.033001088,-0.05437233,-0.0179496,-0.044313073,0.024998557,0.0036647099,-0.0321784,0.049473584,0.0023488733,-0.06832066,0.036609706,0.04472442,-0.019800652,-0.048276942,0.045734085]
2	80f0503d-1693-49b4-ad8c-7177ce17e6f6	1	1	张天才	$2b$12$FB4GkD5mjiWMBBMC22Qa5uWeI8y5rCnQ3Y2V/Cb.K0zMeuJlzUow2	不仅会做手术，还擅长中医号脉	5.0	1	男	[-0.021210456,0.034630477,-0.0264799,0.011941544,0.018642077,0.008382774,-0.0070985844,-0.008145839,0.007932597,0.03572986,-0.02651781,0.03561613,0.0153723685,0.021324186,0.058835797,-0.006378301,0.011145441,-0.018187162,0.02189283,-0.013903369,-0.0509885,-0.000342964,-0.04181436,0.0192202,-0.03135129,0.020983,0.01239646,-0.02600603,0.008534413,-0.054248728,-0.024148455,-0.0065109846,-0.010993803,0.011382377,0.020092122,-0.033095136,-0.01041568,0.00043655347,-0.02189283,0.028508067,0.028887164,0.018139774,0.022935346,0.0021928372,-0.0123206405,-0.07248328,0.022840573,-0.007036981,0.038819496,-0.008742916,-0.00072265294,0.0026536766,-0.027484506,0.006212446,0.009221526,0.014794246,0.007875733,-0.0035729858,0.015192297,0.036507007,-0.005591675,0.053793814,0.009600623,0.026423035,-0.021191502,0.1235855,0.020167941,0.022878483,-0.016348543,-0.022139244,0.017011961,0.03557822,0.006212446,-0.015741987,-0.059176985,-0.0009755815,-0.0064635975,-0.028906118,0.012879808,0.021229412,0.022556249,0.0016478857,0.0054447753,0.016718162,-0.08180905,-0.027996287,-0.011666699,0.057054043,-0.018566258,0.025778571,-0.0052504884,0.023712495,-0.020565992,-0.020850316,-0.016111607,0.0024060789,-0.0171636,0.011107531,0.022613114,0.0016632865,0.022385657,0.020262714,-0.022347746,-0.010567319,0.0054021273,-0.034820028,-0.03531285,0.031199653,0.023826223,0.024394868,0.062399305,0.040335882,-0.023390263,-0.040184245,-0.018755807,-0.027863603,0.029057758,0.017646948,0.008482288,0.030915331,0.04496086,0.056750767,-0.0013694866,-0.040335882,-0.008747655,-0.062361397,0.044695493,0.038080256,-0.039160684,0.02160851,0.005582198,0.07354475,-0.047804087,-0.040146332,-0.028470157,-0.038383536,-0.0042079724,0.020660767,0.012785034,-0.01092746,-0.019921528,0.0635366,-0.0033550053,-0.01547662,-0.0031749343,-0.055840936,2.8950544e-05,0.0020779234,0.0012877439,-0.040184245,-0.04037379,0.013514795,-0.012349073,-0.01012188,0.005842827,-0.056030482,-0.05405918,-0.02640408,-0.03531285,0.017988136,0.007757265,0.0017580607,-0.005629585,-0.07073943,0.0050182915,-0.01690771,-0.0372652,0.019542431,-0.0013292076,-0.045643236,-0.025664842,0.02149478,-0.036222685,0.0223667,0.013135699,0.015486098,0.031502932,0.0016893494,0.010576796,-0.040866617,-0.0031891505,-0.009847035,0.039160684,-0.010368293,0.039956786,0.00022079417,-0.0016810567,0.0029024587,-0.001070948,-0.0032886632,0.022309838,-0.02321967,0.011287603,-0.0036606519,0.07149763,0.019115947,0.03392915,-0.016111607,0.03880054,0.02574066,0.013713821,0.021475824,0.015173343,-0.022764754,-0.02141896,-0.0103967255,-0.054438278,-0.02035749,-0.0077620037,-0.008596016,0.0564854,-0.026934816,-0.010131357,-0.049699567,-0.009979719,0.032507535,0.0025731183,-0.0023717233,-0.045415778,-0.04617397,-0.014907976,0.036999833,-0.004229297,-0.05841879,0.0037862277,0.017921794,0.044430126,-0.00029705776,-0.031123834,-0.04503668,-0.014339331,0.016007356,-0.051405504,-0.0029996021,0.08218815,0.029076712,0.0045278356,0.0107947765,0.0029143053,-0.022309838,0.0264799,-0.0015898366,0.0374737,0.03487689,-0.010538886,0.020224806,-0.025702752,-0.014993272,-0.0107189575,-0.024660237,0.07017079,0.01976989,-0.05186042,0.020603903,0.051178046,0.0123206405,0.021873876,0.0032483842,-0.021532688,-0.007283394,-0.025987074,0.012813467,-0.038023394,0.029361034,0.02160851,-0.008605493,-0.0107189575,-0.00034622184,0.012339596,0.0024854522,0.014159259,-0.03135129,-0.017277328,0.018765284,0.02687795,0.0065915426,-0.013647479,-0.014841633,0.02310594,0.017144645,0.027996287,0.006795307,0.039956786,-0.025058288,-0.010548364,0.030725783,-0.01888849,0.044543855,-0.04753872,-0.022575205,0.0132873375,-0.03044146,0.07149763,-0.011145441,-0.020016303,0.074833676,0.033550054,-0.16285992,0.0035445536,-0.016670775,0.005241011,-0.030934285,0.002911936,-0.0020601533,0.04185227,-0.012121615,-0.048789736,-0.03953978,-0.042041816,0.003975776,0.015192297,-0.020433309,0.007221791,0.014566788,-0.042003907,-0.009183616,-0.038080256,-0.05785015,-0.029986544,0.06770666,-0.031900983,0.0067431815,-0.016215859,-0.04515041,0.007624581,-0.008264307,-0.03366378,0.0288303,0.011363422,-0.019049605,0.027996287,-0.0020779234,-0.029038802,-0.0047766175,-0.023788314,0.0036724987,0.015334459,0.019087516,0.010301951,-0.020547038,0.0651288,-0.034687344,-0.04606024,-0.0044401693,0.009790171,-0.006771614,-0.012225866,-0.027484506,-0.014964839,-0.008008417,-0.016888754,-0.023598766,-0.046666797,0.0059802495,0.025285745,0.07676707,0.0032626004,-0.0674792,-0.018063955,-0.00968118,0.017400535,0.003106223,-0.044278488,0.021153592,-0.00081979646,0.016557045,-0.009392119,-0.011334989,0.005970772,-0.012965105,0.011060145,0.015457666,7.2487426e-05,-0.014784769,-0.034459885,-0.015931536,-0.075250685,-0.048259,0.016594956,0.011050667,0.031370245,-0.00304462,-0.0047221226,0.034687344,0.016130561,0.001492693,0.22412193,0.022669978,-0.024224276,0.026915861,0.04621188,-0.041207805,0.0073213037,0.029190442,-0.0024736056,0.004335918,0.028564932,0.02196865,-0.025513204,-0.0023432912,-0.03051728,0.0057954397,-0.070511974,-0.007122278,0.056902405,-0.031597704,-0.011382377,-0.032697085,0.0028005764,-0.024489643,-0.01899274,-0.032583356,0.009088842,0.06251304,-0.037682205,0.04154899,-0.010178745,0.02013003,0.027522415,-0.018916922,-0.031313382,-0.043861482,0.010842164,-0.026024984,0.010188222,-0.03154084,-0.025437385,-0.027048545,-0.04056334,-0.007771481,0.04484713,0.0029735393,-0.01885058,0.07566769,0.0020127662,-0.03459257,7.663379e-05,0.017229943,-0.021172548,-0.02596812,0.049168833,-0.052542794,-0.017296284,0.0030161876,0.0044330615,0.04268628,0.023883088,0.05546184,-0.012709214,0.02479292,-0.030972196,0.03754952,-0.0039378665,-0.010216654,0.034838982,-0.0241295,0.028621797,-0.013306292,-0.051746693,-0.0066768397,0.030915331,0.00038916638,-0.0051699304,0.03715147,0.026934816,-0.006169798,-0.04382357,-0.04370984,-0.024375914,-0.012586009,0.024565462,0.0038170293,-0.042610463,0.04044961,-0.0058286106,-0.0049614273,0.008795042,0.01287033,-0.07161135,-0.02809106,0.0024522813,-0.040904526,-0.01760904,-0.025835436,-0.025645887,-0.01155297,-0.014187692,-0.013979188,-0.0044141063,0.049168833,0.038648903,-0.02212029,-0.023485037,0.04048752,-0.033550054,0.029038802,0.003407131,0.0174574,-0.01467104,0.015903104,0.020603903,-0.026707359,-0.037208334,-0.00986599,0.026138714,0.03311409,-0.04389939,0.017656425,-0.0059565557,0.0010887182,-0.031123834,0.011827815,0.028659705,0.044505946,0.0006379486,0.041966,-0.009666964,-0.014130827,0.0016455164,-0.027181229,0.055689298,0.039805148,-0.009690658,-0.0012569423,-0.000556502,0.054741554,-0.03290559,0.028147925,-0.040790796,0.03612791,0.018357754,-0.021817012,-0.031370245,0.06205812,0.02075554,-0.018547302,0.017248897,-0.013979188,-0.010226131,-0.0337396,-0.011372899,-0.009998674,-0.013723298,0.014178215,0.075288594,-0.044657584,0.024773965,-0.010519932,0.0011669068,0.11827815,-0.014329853,0.031408157,0.018158728,0.04173854,0.062247667,-0.02636617,-0.041435264,-0.008813997,-0.014092918,0.019788845,0.032810815,0.017210986,-0.059442353,0.02321967,-0.01914438,-0.013552705,0.0077809584,0.022461476,0.019343406,-0.015400801,0.045908604,0.0103967255,0.037530567,-0.011827815,-0.017931271,-0.03334155,0.013003015,0.09659382,-0.052391157,-0.012775557,0.020565992,0.024489643,-0.035767768,-0.01269026,-0.022613114,-0.08006521,0.0013197302,0.016841369,-0.01261444,0.022309838,-0.021267321,-0.0030872682,-0.027484506,0.009420551,-0.021134637,0.0005105958,-0.002582596,0.00025870383,-0.07877628,0.009562713,0.014907976,-0.021437915,-0.006781091,0.004091874,-0.011913111,-0.0093542095,-0.0043288097,0.011060145,0.021779101,-0.058494613,-0.01555244,-0.08696477,-0.012661828,-0.013040924,-0.041056167,0.008941942,0.0126428725,-0.0074397717,-0.02534261,-0.01382755,0.05292189,-0.03165457,0.034895845,0.034611523,0.0108800735,-0.013969711,-0.012443847,0.011287603,0.010643138,-0.00063617155,0.041207805,0.06095874,-0.038857404,0.04139735,-0.006875865,0.014358285,0.017229943,0.0034616261,-0.0079894615,-0.0037056697,-0.023295488,-0.009695397,-0.040146332,0.008273784,-0.012756602,0.012301686,-0.031711433,0.021817012,-0.035919406,0.007013288,-0.06869231,0.0025328393,0.04515041,-0.0031370246,-0.022840573,-0.06076919,0.0015685123,0.023826223,-0.060541734,-0.012093183,0.036071043,0.013799118,-0.008998807,0.011211783,-0.031502932,0.094167605,0.031900983,-0.041283622,0.018661031,0.016196905,-0.030631008,0.065962814,-0.006667362,0.02522888,0.0014287204,0.00090390857,-0.009098319,0.012633395,-0.019343406,0.028678661,-0.029285215,0.021570599,-0.035559263,0.017694335,-0.004646303,-0.010226131,-0.009434768,-0.009510587,-0.053604264,0.0029498457,0.046477247,-0.002229562,-0.003627481,-0.052504886,-0.015922058,-0.048334822,0.0048145275,-0.0069706393,0.0032649697,0.041207805,0.0036914535,-0.019883618,0.0065631107,0.018689465,0.023883088,0.011524538,-0.030706828,-0.0017687228,0.008354343,0.017571129,-0.014424627,0.0047624013,-0.04814527,0.029569538,-0.027162274,0.009093581,-0.03102906,0.027484506,0.014566788,-0.014718427,0.051405504,0.013732776,0.022651024,-0.0049235174,0.04621188,-0.066986375,-0.01624429,-0.024906648,0.0439373,-0.015723033,0.016111607,-0.06789621,-0.01848096,-0.0014405672,0.027920468,0.010188222,-0.040146332,0.05841879,0.013183085,-0.048941378,-0.0009530726,0.0105578415,-0.010207177,-0.036260594,0.046590976,0.007823607,-0.0022034992,0.064484335,0.023333399,0.03698088,-0.004205603,0.005335785,-0.0008274969,-0.020452263,0.033493187,0.003963929,-0.007695662,0.022575205,0.0033242037,-0.025058288,-0.017220465,0.014206646,-0.03025191,-0.03051728,-0.017438445,-0.029929679,-0.023333399,-0.02208238,0.0017391058,0.0057243593,-0.014263511,-0.014149782,-0.0038241374,-0.045605324,0.010140835,-0.022878483,-0.037644297,0.009520064,-0.005350001,0.033910193,-0.17059349,0.00048601374,-0.011477151,0.011467673,-0.040146332,0.006634191,-0.049017195,0.016206382,0.015959969,-0.0059565557,0.03749266,0.040184245,-0.023162805,-0.015694601,-0.005823872,-0.019997347,0.024565462,-0.033057228,-0.0032389069,0.042951647,-0.0054258206,0.009150445,0.045832783,0.00436435,0.021362096,0.004155847,-0.025835436,0.04598442,-0.058077604,-0.0044093677,-0.0034711035,-0.09477416,0.03809921,0.053263076,0.054665737,-0.020205852,0.00913149,0.031237563,0.05739523,-0.043558203,-0.00906041,0.028110016,-0.007695662,-0.011496105,-0.033170957,-0.005511117,0.02926626,0.008652881,0.0050419853,-0.039615598,0.0036488052,0.024338003,-0.013713821,0.012093183,0.010178745,0.008288,-0.02263207,0.055840936,0.002798207,0.037852798,0.011372899,-0.05887371,-0.002783991,0.0060371137,-0.057774328,-0.022252973,0.005857043,-0.008373297,0.017817542,-0.013372634,-0.0058996915,-0.06410524,-0.024224276,-0.011979453,0.026252443,-0.014453059,0.040070515,0.013988666,0.028034197,-0.006771614,0.0056911884,-0.0037980743,-0.0024179257,0.063422866,-0.02013003,0.032185305,0.008306955,0.029152531,-0.021646418,0.02486874,0.0022189,-0.03290559,0.015978923,-0.028583886,-0.030214002,0.02486874,0.04526414,-0.0034829504,0.013382112,-0.0153723685,-0.001954717,-0.0054400368,-0.01261444,-0.03707565,-0.059252806,0.040942438,0.0529598,-0.009989196,0.034611523,0.006193491,0.01555244,0.011789906,-0.023883088,-0.0041203066,-0.0071649263,-0.002398971,0.028887164,-0.018547302,0.008117407,0.010510454,-0.02996759,-0.019959439,-0.0072312686,-0.06429479,0.0010555472,0.030915331,0.023466082,0.04026006,-0.013391589,0.038535174,0.037246246,-0.07441667,-0.019182289,0.023636675,0.028887164,-0.009415813,0.0011426209,0.020774495,-0.033152,-0.018935878,0.01562826,-0.011837292,-0.012633395,0.00036073415,0.018149251,-0.021172548,-0.04166272,-0.0033644827,0.0053594788,0.003004341,0.04734917,-0.0017651687,0.012443847,-0.050836857,0.032450672,0.01812082,0.0064825523,-0.020660767,0.029929679,-0.0038904792,0.04530205,-0.031142788,-0.018196639,-0.032981407,-0.014310898,-0.023485037,0.0023267055,0.0117614735,0.009515326,-0.018860057,0.06524253,0.047045894,-0.014585743,0.0059660333,0.021589553,-0.005174669,0.032848723,0.0337396,0.008761871,-0.0028053152,0.010832686,-0.020660767,-0.011714086,-0.0033644827,-0.05193624,-0.045794874,-0.0072928714,-0.011609835,-0.039880965,-0.011420286,0.011240215,-0.010046061,0.0057148817,-0.013107266,0.009074626,0.019305496,-0.04162481,0.016452795,-0.050230306,0.00462024,-0.04515041,0.009292606,0.02321967,-0.03425138,0.03942605,0.01735315,0.039084863,-0.026233487,-0.058722068,-0.022101333,-0.03531285,0.003989992,-0.010055538,0.051405504,0.0050372467,-0.03345528,0.0013280229,0.022556249,-0.009847035,0.035255987,-0.015893627,0.003426086,-0.017845973,-0.03652596,0.03165457,-0.0066768397,-0.013619047,0.0282427,-0.035559263,9.196055e-05,-0.061375745,0.04609815,-0.024641281,0.039805148,0.010813732,-0.045226227,0.06380197,0.0076861843,-0.011221261,-0.03047937,0.03381542,-0.010102926,0.013884414,0.017675381]
3	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2	1	张心医	$2b$12$sifZi.rhDazNoqvOh3vd7.7LwDtGrFj7cdDrO8CPsjr5fdWDvEsL.	冠心病，心律失常，高血压，心力衰竭的诊治	5.0	1	女	[-0.016979484,0.005510215,-0.038027167,-0.012834886,-0.015489721,-0.02085669,0.04175158,-0.016120005,0.0033877795,-0.02574617,-0.012863535,-0.025077686,-0.0016831463,0.016998583,0.029661573,0.028171811,0.0041159494,-0.027044937,-0.012395596,-0.008518391,-0.027617924,0.013570217,-0.018965837,0.00049181294,-0.01183216,0.011154127,0.03625091,-0.005314445,0.032068115,0.007148,-0.029432379,-0.035009444,0.011765312,-0.007066827,-0.01268209,0.00775441,-0.016511546,0.00086425385,-0.065625995,0.046946652,0.08457273,0.0017643193,0.017733917,0.0065988884,0.040682003,-0.067115754,-0.019070882,-0.023435127,0.017638419,-0.06700116,2.2158441e-05,-0.0068376325,0.04667926,0.013302824,0.004383343,0.00073175086,-0.058177177,-0.033615176,-0.013016331,0.0025020388,0.002638123,0.026204558,-0.03712949,-0.01718003,0.038065366,0.05405168,0.036575604,0.017476073,-0.011316473,-0.039994422,0.0070095286,0.012901735,0.042630155,-0.0026261858,-0.04813082,0.021124084,0.010084553,-0.012004056,0.021792566,0.009587965,-0.0010833016,-0.029546976,0.005066151,0.015375123,-0.063486844,-0.0084228935,0.030750247,0.005429042,0.019653419,0.0059877033,-0.014658892,0.03057835,-0.012366948,-0.05970514,-0.0141814025,-0.036212713,-0.021334177,0.02081849,0.074144386,0.004335594,0.045418687,-0.0049181296,0.01391401,-0.0047175847,0.05431907,-0.03386347,-0.019128181,0.04125499,0.030750247,0.015728464,0.010371046,0.057718787,-0.016120005,0.025039487,0.0142769,-0.02085669,-0.0050136275,-0.06757414,0.022155458,-0.013971308,-0.010781686,0.0021009485,0.021582471,-0.04568608,-0.014019057,-0.007993154,0.048436414,0.036422808,-0.00959274,0.033271387,-0.00016070466,0.02326323,-0.036881197,-0.04656466,-0.0058301324,-0.038160864,-0.01633965,-0.020207305,-0.0048894803,-0.054395467,0.013560668,0.061767887,-0.012720289,-0.0042209965,-0.0127298385,-0.07697111,0.0007233948,0.023989012,0.0017619318,-0.0028720922,-0.048283618,-0.022384653,0.04209537,0.06352504,0.03059745,0.009635714,-0.08411434,0.009578415,-0.04568608,-0.036919396,0.021716168,0.027121335,0.042630155,-0.0031227735,0.0137421135,-0.013293275,0.025707971,0.054166272,-0.004903805,0.0031609726,-0.02087579,-0.037740678,0.050040774,0.0090818275,-0.0022131584,0.019653419,0.06211168,0.016798038,-0.01760977,-0.023874415,-0.024810292,0.023053136,0.01021825,-0.017418774,0.06570239,0.031514227,0.002654835,-0.001256988,0.006465192,-0.00063625316,-0.04450191,-0.048780207,0.016941285,0.03342418,0.04209537,-0.04285935,0.0085088415,-0.011927658,0.021104984,0.009248949,0.006278971,-0.021467874,0.013035431,0.06402163,-0.004526589,0.012023156,-0.042248167,-0.07937766,0.005281021,-0.005510215,0.0027336206,-0.0047319094,-0.029604275,-0.029967166,-0.010151401,-0.012118653,0.0057823835,-0.027064037,0.02780892,-0.016950835,-0.027617924,0.06360144,0.020111809,-0.037033994,0.041560583,0.0020078383,0.023969913,0.008862183,0.045151293,-0.043928925,-0.045380488,-0.0009281179,-0.019338276,0.00096034835,0.074182585,-0.008919481,0.038485557,-0.004980203,0.048360016,-0.021506073,-0.004951554,-0.0045409137,0.0045886626,-0.015174579,-0.026777545,0.026070861,0.000837992,-0.044234518,-0.024657497,0.0075013414,0.023091335,0.01183216,-0.031495128,0.043164942,-0.008160275,0.008098202,0.009683463,0.004454966,0.001816843,-0.0049611037,-0.012701189,0.063486844,-0.028687498,0.028649298,-0.031265933,-0.029967166,0.030883944,-0.018908538,0.02408451,-0.011946757,0.00980761,-0.02536418,0.0018645918,0.010972681,0.052905705,0.04247736,0.00024068395,-0.013035431,0.054395467,0.012557942,-0.016807588,0.024657497,0.015298725,0.009449494,0.058941156,-0.045915276,-0.0125101935,-0.024199108,-0.041102193,-0.012739388,0.013121379,0.012796687,0.065587796,-0.01227145,0.019882614,0.021181382,0.00794063,-0.16929826,0.012806237,-0.025918065,0.04580068,-0.04037641,-0.007668462,-0.037396885,0.016301451,-0.0022704569,-0.05806258,-0.0063887937,-0.053898882,-0.03233551,-0.009735987,-0.04003262,0.0030105638,0.014964484,-0.015766663,0.007678012,-0.013006781,-0.04324134,-0.011860809,0.005109125,0.0038031945,0.0070716017,0.034818448,0.005949504,-0.022518348,-0.021563372,-0.0052619213,0.005677336,-0.026166359,-0.012128203,0.002449515,0.00048882863,-0.049544185,0.05959054,0.009229849,0.01957702,0.000978851,0.02326323,0.07483197,0.011879909,0.015040882,-0.01790581,-0.012290549,-0.004686548,0.014830787,0.05069016,-0.008785785,0.0068806065,0.016979484,0.025879867,0.02486759,-0.03968883,-0.025096785,0.018049058,0.054471865,0.03764518,-0.03965063,0.02127688,-0.049658783,-0.043585133,-0.012281,-0.011488369,-0.015184129,0.0025593373,-0.0072530475,0.0028935792,0.002778982,0.011306923,0.02735053,0.01671209,0.012615241,-0.0075443154,0.0005705985,-0.012004056,0.0044955523,0.0036002619,-0.082662776,-0.025115885,0.0530585,-0.005887431,-0.0137421135,-0.036155414,-0.046870254,-0.001616298,0.019280978,0.02901219,0.24202928,0.010390146,0.027694322,0.019080432,0.025077686,-0.03061655,0.036938496,0.04331774,-0.017829414,-0.012462445,-0.02207906,-0.0103996955,-0.0038413934,0.0026476728,0.012214151,0.070133485,-0.08220439,-0.029737972,0.08663548,-0.031227736,-0.013866261,0.045074895,-0.028649298,-0.0021439225,-0.03344328,-0.066046186,0.017361475,0.031552427,-0.015995858,-0.008231899,-0.04526589,0.026815744,0.04125499,-0.026032662,-0.027656123,-0.036632903,0.0030774123,-0.028057214,-0.009683463,0.03563973,0.0062264474,-0.036117215,-0.048742007,0.02284304,-0.006178699,-0.027885318,-0.022403752,-0.0076493626,-0.0023265618,-0.015441972,0.016425598,-0.005949504,0.010647989,-0.011478819,-0.018230503,0.03428366,-0.036480106,0.008298747,-0.0051664235,0.023587922,0.05351689,-0.002984302,-0.04450191,0.019023133,-0.029298684,-0.0014563394,0.020627495,-0.008413344,0.0071289004,0.01468754,-0.00208543,-0.009960406,-0.004860831,0.02608996,0.01466844,0.014229151,-0.020207305,0.032144513,-0.022250956,-0.033710673,-0.018020408,-0.044807505,-0.023855316,-0.080982015,0.017103631,0.008451543,0.036002617,-0.020226404,-0.0245429,0.008991105,-0.028859394,0.037377786,-0.047443237,-0.020551097,-0.043470535,0.016396949,0.029203186,-0.026452852,-0.025058586,0.07704751,0.0027694323,0.0033686801,-0.02123868,0.0004249646,0.06272286,-0.016587945,-0.0003557288,-0.01467799,-0.06356324,0.003282732,0.016511546,0.018622044,0.037530582,0.015547019,-0.0084228935,0.008346495,-0.026796645,0.0028267307,0.061767887,0.033958968,0.002475777,0.06631358,-0.031991716,0.05844457,-0.017762566,0.026892142,0.051645137,-0.008952905,0.009969956,0.01790581,0.005600938,-0.015795313,-0.020780291,-0.034990344,0.04824542,0.03835186,-0.04450191,0.0026572226,0.044731107,0.036040816,-0.077353105,-0.053249497,-0.02702584,0.0067278105,0.041063994,0.003834231,0.0077448604,0.0025354628,-0.026892142,0.021104984,0.046832055,0.0064460924,0.017695718,-0.021066785,-0.0068758316,-0.047978025,-0.03382527,-0.028229108,0.022270055,-0.027847119,0.02654835,-0.004175635,0.040185418,0.06998069,-0.014582493,0.035353236,-0.018077707,-0.02576527,0.013025881,0.014974033,-0.016817138,-0.025115885,-0.054892056,-0.036098115,0.0019887388,-0.03392077,-0.028057214,-0.0004073572,-0.021525173,0.01589081,-0.0063123954,0.01790581,0.040643804,-0.013035431,0.030807545,0.05519765,0.011918108,-0.011564767,-0.0073580947,-0.043355938,-0.0081984745,0.095726855,-0.04366153,-0.010542942,0.037721578,0.040987596,0.038542856,-0.00898633,0.022270055,0.030463755,0.05603803,-0.0036862097,0.035486933,0.0037697703,-0.020226404,0.012806237,-0.03965063,-0.005271471,0.00551499,-0.011583867,0.018650694,0.05057556,-0.062531866,0.023492426,-0.043623332,-0.019959012,-0.015823962,0.042248167,-0.0013190615,-0.012118653,0.010867634,-0.020302802,0.024581099,-0.084878325,-0.00695223,0.008055228,-0.030750247,-0.032431006,0.012806237,0.025879867,0.009014979,-0.05519765,0.025574274,-0.022346454,-0.020799391,-0.029145887,0.024275506,0.025211383,-0.010743487,-0.0055293147,-0.010170501,-0.029164987,0.024657497,-0.04824542,0.0035167015,-0.026701147,-0.021849865,-0.024199108,0.018249603,0.015241427,-0.049124,0.03233551,0.019023133,-0.06845272,0.0017177642,-0.0011382127,-0.047901627,-0.02981437,-0.045647882,-0.020665694,-0.0052428218,0.0010540554,0.013092729,-0.021907164,-0.04702305,-0.004851281,0.02532598,0.0068042083,-0.026930341,-0.03187712,-0.038160864,-0.0025975364,-0.056305423,-0.009559316,0.015365574,-0.009205975,0.009554541,0.065625995,-0.0285729,0.0050040777,0.016167754,-0.058177177,0.03178162,0.026815744,0.008298747,0.101074725,0.049353193,0.046259068,-0.0144010475,0.002141535,-0.040720202,0.0012617628,-0.014248251,0.023836216,-0.019959012,0.010103652,-0.010304198,0.026701147,-0.013302824,0.0010510711,-0.02578437,0.009960406,-0.031724323,-0.057833385,0.034016266,-0.013761213,0.07169964,-0.005147324,-0.011001331,-0.014114554,0.023587922,-0.060851112,0.047672432,0.015699815,0.014057256,-0.005481566,-0.023053136,-0.038523756,-0.023435127,0.0286111,-0.011975407,-0.011068179,-0.0002875375,0.0066323127,-0.010944032,-0.0018932412,0.002475777,0.009673913,-0.034474656,-0.042286366,0.0033280936,0.01759067,-0.019128181,-0.012051805,-0.024141809,0.0407966,-0.015747564,0.021104984,0.025937164,-0.02733143,-0.0367666,-0.04045281,0.047978025,0.012204601,-0.0007532378,-0.037033994,0.014878536,-0.019806216,0.004197122,-0.009874458,0.027980816,0.026815744,-0.029967166,-0.03516224,-0.0026787093,0.051912528,-0.049162198,0.04706125,0.0053717433,0.013035431,-0.014792588,0.006770784,-0.0032302085,0.029279584,-0.002693034,0.02939418,-0.0077830595,-0.04171338,0.02528778,0.03796987,-0.024313705,0.024390103,-0.012414696,0.018927637,-0.028248208,0.037282288,0.01145017,-0.011488369,-0.017094081,0.0077066612,-0.018326001,0.013293275,-0.0026500602,-0.014229151,-0.013589317,-0.08373235,-0.0163492,-0.008613889,0.023186833,-0.0014742451,0.013417422,0.0037602205,-0.024657497,-0.022346454,-0.14859436,-0.02081849,-0.0032516953,-0.013235976,-0.025058586,0.013608417,0.003693372,0.012395596,-0.012529293,-0.034531955,0.018039508,-0.005954279,-0.0030296633,-0.015356024,0.019548371,0.017103631,0.04698485,-0.044005323,0.009120027,0.015623418,-0.028305506,-0.03722499,0.07402979,0.023989012,0.018163655,-0.01797266,-0.0032636325,-0.0075490903,-0.013264625,-0.012634341,0.010237349,-0.0327366,0.027961716,0.024982188,0.06917851,0.033615176,-0.030349158,0.0052475967,0.03625091,0.0047438466,-0.00024441432,0.012748938,-0.0035930995,-0.020321902,-0.03191532,-0.0071718744,-0.002009032,-0.025898965,0.01917593,-0.0080695525,-0.02003541,0.020130908,0.028038114,-0.009301472,-0.019939912,-0.03180072,-0.026051762,0.021181382,0.0010301811,0.045418687,0.016960384,-0.034952145,-0.013656165,0.017304176,-0.015441972,0.045189492,-0.065167606,0.023817116,0.02608996,-0.0100941025,-0.006699161,0.00978851,0.0124242455,-0.033710673,-0.016024508,0.0032158839,0.0117175635,-0.013952209,-0.008270098,-0.015671166,-0.009511567,-0.024351904,0.041522384,0.012090004,0.03923044,0.003335256,-0.0066848365,0.005061376,0.004851281,0.012853986,-0.042744752,-0.052867506,0.046908453,-0.03344328,0.013150028,0.020684794,-0.0065845638,-0.043928925,-0.0064460924,-0.010113202,-0.015174579,0.006045002,-0.009673913,-0.04171338,-0.075519554,0.019672519,0.008064778,0.013933109,0.020111809,0.0034403033,-0.058253575,-0.024676597,0.0007944212,0.055235848,-0.04736684,-0.028763896,0.011373771,0.0043236567,-0.013665715,0.039020345,-0.01711318,0.028802095,-0.016100906,-0.038179964,0.000418996,-0.023435127,0.031647924,0.03145693,-0.0023003,0.048742007,0.016874436,-0.0652822,-0.03881025,0.01142152,0.024409203,0.020551097,-0.058177177,0.041560583,0.023530625,-0.01711318,0.0063505946,0.015308275,-0.03428366,0.013837611,-0.026682047,0.024657497,-0.01305453,-0.0025808243,-0.0021045296,0.0028625424,0.072425425,-0.020913988,-0.013971308,0.030845745,-0.024600198,-0.018306902,-0.00857569,0.00046764011,0.0163874,0.01019915,0.032526504,-0.048016224,-0.038141765,0.014257801,3.2696757e-05,0.04033821,-0.009282373,-0.012777587,-0.025020387,0.004206672,0.029184086,-0.006770784,-0.036480106,-0.011354672,0.038581055,0.06444182,-0.0054481416,-0.028095413,0.010036805,-0.027675223,0.03311859,0.013665715,-0.0072960216,0.005314445,-0.03961243,-0.052791107,0.02290034,-0.01959612,0.02775162,-0.009325347,0.008451543,0.014105004,0.05768059,-0.017017683,0.06287566,0.07658912,0.011182777,0.021849865,0.00795973,0.02696854,-0.017246878,0.01919503,-0.0076971115,-0.05275291,-0.0204365,-0.012519743,0.045151293,-0.029222285,-0.0046101497,0.008107752,-0.04652646,-0.009855359,-0.022231856,0.009855359,-0.008933806,-0.03766428,0.024829391,-0.04377613,-0.0016843401,0.000658337,-0.00016249524,-0.020990387,-0.0017022458,-0.013436521,0.016253702,0.019997211,0.025879867,-0.018994484,-0.04041461,-0.026338255,0.004411992,-0.015098181,-0.0285538,0.028878493,0.0033877795,-0.0144869955,0.0023790854,-0.008838309,0.00204365,-0.0036145865,0.02165887,0.03229731,0.025440577,-0.013293275]
4	87ee7a64-f696-417c-bc89-7697dfca10f0	3	2	王骨医	$2b$12$zH76888CJ7eQctt9e3Vpde4BzgCsOq7xQ5KuzollvfJQlG/URvXFq	骨折保守治疗，关节炎，颈椎病，腰椎间盘突出	5.0	1	男	[-0.008701741,0.04521511,-0.0049448134,0.0017394053,-0.015565085,-0.00021889874,0.04370668,0.021344248,0.016498424,-0.044385474,0.03805008,0.0052936375,-0.034033895,0.034392145,0.036089126,-0.0031134884,0.0054067695,-0.04687438,-0.0131704565,-0.051550504,-0.014509186,0.018610222,-0.012915909,0.014688311,-0.06919911,-0.027434522,0.0015131412,0.01416979,0.047025222,0.004640771,-0.04008646,0.026604887,0.032129504,-0.019873532,-0.03688105,-0.001722907,-0.008697026,-0.03182782,-0.06361792,0.063580215,0.0071508884,-0.0072357375,0.013311871,-0.00033114693,0.011605463,-0.049212445,-0.029621743,-0.010577847,-0.009545517,-0.023361769,-0.007862678,-0.027113982,0.014867437,-0.071461745,0.018421669,-0.016969807,-0.024153693,-0.040576696,-0.023852007,-0.008277495,0.0006440278,0.020080939,0.034769252,0.0315827,0.021702498,0.103930645,0.025303869,0.02121226,0.007900388,-0.008169077,0.0021707213,0.022928096,-0.009272114,-0.033449378,-0.038389478,0.03222378,-0.019345582,0.014000092,0.028999517,-0.009965048,0.0048505366,-0.018770494,0.035429187,0.04958955,-0.049853526,0.045365952,-0.011586607,0.05275725,0.0075798477,-0.08537699,-0.014952286,-0.028415,0.011652602,-0.008371772,0.009446527,-0.0009162518,-0.023550322,-0.00069352303,0.065088645,0.018676216,0.02149509,0.032544322,0.036730208,-0.0009899054,0.047025222,-0.02230587,0.0046926234,0.029414333,0.0008066551,0.006891628,0.0076316996,0.04087838,-0.00029977047,-0.043744393,-0.007683552,-0.028754396,-0.048533652,-0.044046078,0.00012388549,0.019854676,0.017667456,0.03861574,0.032148357,-0.03226149,0.016159028,-0.006311826,0.051512796,-0.008715882,-0.011181218,0.008880866,0.010785256,0.006825634,-0.06659707,-0.021928763,-0.045064267,-0.050947133,0.0152445445,-0.007994665,0.044196922,-0.030979328,-0.021306537,0.05566097,0.07161259,-0.024700498,0.023908574,-0.063203104,-0.0134344315,-0.010398721,0.0035330197,0.005166364,-0.008466049,-0.009776495,-0.02513417,0.01088896,0.026114648,-0.014528041,-0.037465565,-0.011709168,-0.03241233,-0.008956288,-0.04804341,0.018129412,-0.018600795,0.017695738,0.034505278,0.002488905,0.029734874,0.044310056,-0.03493895,0.033562507,-0.0043956516,-0.052606404,-0.01598933,0.0014306491,0.012435098,0.013990664,0.043744393,0.027660787,0.027377957,-0.04744004,-0.006014854,0.016526707,0.023889719,-0.0033232542,0.06237347,0.017884292,0.012746211,-0.010078181,0.027453378,0.06271287,0.0010317408,-0.028151026,0.014754306,0.008466049,0.04630872,-0.026001517,-0.01789372,-0.03427901,0.021608222,0.030922761,-0.04291476,0.013311871,0.02626549,-0.028697832,-0.0638819,-0.039332245,-0.02967831,-0.04351813,0.03088505,-0.027717354,-0.0112754945,-0.029923428,-0.026567178,-0.0035094505,0.0040044035,0.005072087,0.035278346,-0.039709352,0.008070086,-0.05128653,-0.06101589,0.03493895,-0.0037616407,0.014678884,0.021589367,-0.005670744,0.0402373,-0.01598933,0.027359102,0.028886383,-0.049363285,0.00020298954,0.004126963,-0.03165812,0.08205845,0.0019585986,0.025002183,-0.008880866,0.01849709,-0.050796293,0.0005830425,-0.038238633,0.045403663,0.03554232,-0.04902389,0.031111315,0.05007979,0.010794683,-0.0182614,0.025115317,0.020194072,0.04744004,-0.05121111,0.032977995,-0.035316058,0.00024968598,0.011020947,-0.0044333623,-0.026359769,-0.0034175308,-0.01833682,0.08711168,0.002696314,0.032544322,-0.015612223,-0.0118034445,0.0134815695,-0.052455563,-0.002277961,-0.022777254,-0.003297328,0.028810963,-0.0046030604,0.041519463,0.035523463,-0.007396008,-0.011888294,-0.021136839,0.037635263,0.026303202,0.017639173,0.02485134,-0.005840442,-0.054755915,0.0036225826,-0.007452574,-0.03363793,-0.013302444,-0.014396054,-0.042009704,0.0025666836,0.050306052,0.07704293,-0.010662696,-0.009804778,0.05290809,-0.011605463,-0.15868656,-0.022004185,-8.492269e-05,0.029621743,-0.03963393,-0.0103233,-0.03821978,-0.025077606,-0.07051898,-0.052606404,-0.0021424382,-0.059696015,-0.0053832,0.053058933,0.0029155072,0.002833015,-0.021268826,-0.035975993,-0.031149026,-0.04468716,-0.010785256,-0.015565085,-0.015442525,-0.014565752,-0.011850582,0.015744211,0.016300444,0.00032083545,-0.018695071,0.010408149,0.013321299,0.057018556,-0.0048505366,0.027472233,-0.005189933,-0.021891052,-0.0017111223,0.021136839,0.028509278,0.004020902,0.035768583,0.056151208,-0.018138839,0.03650394,0.0039784773,-0.009578514,-0.0026138218,0.035561174,-0.009455954,-0.0017594391,-0.021683643,-0.035881717,0.052040745,-0.0094418125,-0.0255867,0.0044569317,0.002863655,0.0705944,0.0033727493,-0.015602795,0.018204832,-0.055849522,0.02121226,0.0011702097,0.016470142,-0.038596887,-0.04246223,-0.02999885,0.026227782,-0.019967807,0.013839821,-0.0038629882,0.012717929,0.0023616317,-0.024021706,-0.0027552368,-0.026001517,-0.011039803,0.029602887,-0.056566026,-0.014829727,0.020288348,0.024983328,-0.008041804,-0.018478235,0.0068822,0.0016863747,-0.003731001,0.036032557,0.23938742,0.025096461,-0.0007005938,-0.010662696,0.0053407755,-0.021966474,0.045516796,-0.010153602,0.03120559,-0.057169396,-0.08545241,-0.012963048,-0.015414243,0.011360344,-0.0054821908,0.031752396,0.003926625,0.0116714565,0.12942307,-0.035636596,0.02311665,0.05238014,-0.015583941,-0.003551875,-0.006212835,-0.031413,-0.021872196,0.0589418,-0.019091034,0.052417852,-0.038068935,0.0044899285,0.05339833,-0.086055785,-0.036937617,0.013670123,0.03177125,-0.010172457,-0.008847869,0.0054869046,-0.015206833,-0.023418335,-0.08643289,0.026567178,0.0054256245,-0.00055328646,0.008928005,-0.07583619,-0.024097128,-0.011709168,-0.003695647,0.009540803,0.0039690495,-0.029697165,0.003726287,0.006589942,-0.020835154,-0.011077514,0.0077024074,-0.00056949025,0.007909816,-0.0028283014,-0.0800975,0.014924004,-0.049891237,0.048231967,0.008173791,0.06588057,0.036843337,0.02124997,0.007989951,-0.005878153,0.0112283565,0.028471567,0.022777254,-0.019930096,-0.026868863,0.057093978,-0.013868104,0.035806295,-0.019609556,-0.042688496,0.0033067556,-0.0430656,-0.013556991,0.032318056,0.01267079,0.0010388115,-0.002726954,-0.02043919,-0.019628411,-0.019892385,0.0070613255,0.03180896,0.0059959986,-0.047515463,0.03250661,-0.058263008,-0.04630872,-0.013179884,-0.0069764764,-0.013019614,-0.029093793,-0.02343719,0.024794774,0.026340913,0.040350433,-0.028773252,-0.0019574203,0.0069293384,-0.01643243,0.018808205,0.022965807,-0.011209501,0.009092988,-0.008805444,0.023738876,0.012727356,0.033543654,0.02537929,-0.0137455445,0.0069387658,-0.06380648,0.056452893,-0.025567845,0.005816873,0.009554945,-0.015442525,-0.020740876,0.010134746,0.01591391,-0.025473567,0.013594702,0.010181885,0.058149874,0.032035228,-0.00822093,0.014443192,-0.0067219296,0.03861574,-0.052681826,0.017922003,-0.017639173,-0.011341488,0.016187312,-0.031149026,0.0076222722,0.02485134,-0.018591367,-0.0070330426,0.015565085,-0.020231782,0.0030592792,-0.013047897,-0.0094653815,0.028415,-0.03080963,0.020571178,0.01133206,-0.041368622,0.0028990088,-0.0441215,0.045365952,0.06746441,0.0352972,-0.020571178,-0.0054821908,0.04740233,-0.02760422,0.0074101496,0.030790774,-0.015932765,-0.04246223,-0.024172548,0.020703165,0.024870196,0.002075266,0.03671135,0.006250546,0.01773345,-0.03327968,0.013613557,-0.014678884,0.019043896,0.03346823,-0.0054963324,0.03490124,-0.0136984065,0.029810296,-0.013264733,0.020872863,0.081832185,-0.0022614626,-0.026058083,0.02586953,0.012699073,0.016724689,-0.0441215,-0.014820299,0.016705833,-0.034392145,0.03982248,0.039973326,-0.021231115,-0.041670308,-0.008753593,0.052568693,0.02311665,-0.0050579454,-0.011567753,-0.0068067787,0.021759065,-0.039897904,0.048194256,-0.052153878,0.013594702,0.014414909,0.02445538,-0.067916945,-0.01663984,0.08220929,0.0058970083,0.018959047,-0.047176067,-0.009262687,0.053021222,0.033619076,0.0064579546,-0.005765021,0.0033939616,0.0029437903,-0.022041894,-0.0093333945,9.280364e-05,0.017827727,-0.0022225734,0.01858194,0.051060267,0.07048127,-0.0024724067,0.017724022,0.0006587585,-0.016988663,-0.031054748,-0.041670308,-0.019364437,-0.048797626,-0.012736783,-0.022136172,0.05339833,-0.03903056,0.031714685,0.048684493,0.0043956516,-0.006514521,0.04287705,-0.034599554,0.0043131597,-0.07017958,-0.011190645,-0.018553657,0.0326386,-0.052229296,-0.004812826,-0.032035228,0.012010853,-0.0028612982,0.0245308,0.0014707167,-0.0067219296,-0.034580696,0.001435363,-0.037333578,0.007626986,0.025737543,-0.011680884,-0.05848927,0.0441215,-0.038955137,-0.016998092,-0.0053502033,-0.028829819,0.00045871513,0.023060083,-0.024681643,0.028773252,0.043141022,0.03590057,-0.029131504,-0.012453954,-0.033185404,0.011322633,-0.021928763,0.0056613167,-0.019741543,-0.00025130637,0.027623076,-0.013990664,-0.016903814,-0.01036101,-0.021664789,0.018063419,-0.07806112,0.014311205,0.020269493,-0.04698751,0.021645933,-0.024889052,-0.015103129,-0.018016279,0.01708294,-0.08341604,0.025285013,0.02092943,0.008503759,-0.023531467,0.015715927,-0.0064532408,-0.011416909,-0.025153026,-0.041142356,0.011841155,-0.025285013,-0.0011112867,-0.02781163,0.03914369,0.0061704107,0.027302535,-0.03914369,-0.012293683,0.00043367286,0.013736117,0.036051415,0.0048316815,0.032204926,0.061845522,0.0056377472,0.01845938,0.060827333,0.0060808477,-0.0737621,-0.017054657,0.034392145,-0.0021895766,0.019779254,0.011181218,-0.004963669,0.0010588453,0.04785486,-0.014594035,0.013811538,0.07889075,-0.04068983,-0.05675458,0.022192737,-0.019043896,0.0027316676,0.00919198,0.041368622,0.015357676,-0.018317966,0.018591367,-0.041142356,0.028000183,0.0046525556,-0.00444279,-0.02926349,-0.014848582,-0.009210834,0.027773919,-0.00578859,0.043404996,-0.013368438,0.032921426,-0.040312722,0.038766585,-0.00932868,0.0021836844,0.007862678,0.019986663,-0.02505875,0.021721354,-0.014264067,-0.011690312,0.035127502,-0.0002882805,-0.01865736,-0.006448527,-0.02290924,0.020665456,0.01457518,-0.00076717674,-0.0027387384,-0.012359677,-0.16185425,-0.0073441556,-0.014603463,0.00082786736,-0.032280345,0.0044946424,-0.024172548,-0.0050296625,-0.005670744,-0.0041693877,0.0044498607,0.02085401,0.038842004,0.0019291372,0.04231139,0.026020372,0.019892385,-0.030771919,0.006905769,0.033713352,-0.058828667,-0.0103044445,0.027943617,0.01757318,-0.0040680403,0.03165812,-0.008442479,0.0056094644,-0.01238796,-0.004188243,-0.004362655,-0.034373287,0.021193404,0.004386224,0.015093702,0.0041764583,-0.019760398,0.012755639,0.009012854,-0.014952286,-0.009488951,-0.006189266,-0.017271493,0.025812963,-0.04562993,-0.008895008,0.00072534144,0.0053077787,-0.0040774676,-0.015631078,-0.010219595,-0.010587275,-0.014433765,0.034788106,0.006127986,0.012736783,-0.017912576,0.016177883,0.03663593,0.023456046,-0.0068444894,-0.027736207,-0.071461745,-0.011709168,-0.011256639,0.01591391,0.028754396,0.018035134,-0.019930096,-0.027340246,0.00060337095,0.023550322,0.036277678,-0.0046831956,-0.006825634,-0.017535469,0.07221596,-0.030696496,0.005156936,-0.01283106,0.024078272,0.029056082,-0.009220262,0.0019220664,0.050607737,-0.0039973324,-0.051361952,-0.0069387658,-0.027773919,0.018808205,-0.057207108,-0.028641265,0.034788106,0.00919198,-0.037823815,-0.0006840954,-0.050306052,-0.025888385,-0.021947619,-0.00979535,0.009083561,-0.019383293,-0.008989285,0.010474143,-0.0800975,0.002835372,-0.023738876,0.00043131594,-0.012755639,-0.007839109,-0.02400285,-0.03680563,-0.0029461472,0.011058658,-0.020608889,0.006038423,-0.021796776,0.0176486,-0.026114648,0.009437099,0.020250637,0.050419185,0.007372439,-0.019477569,-0.022814965,-0.01696038,0.04687438,0.018487664,-0.060374808,0.027717354,0.026303202,-0.079720385,-0.04355584,-0.017658029,-0.013227022,0.033713352,-0.0815305,0.042575363,0.001992774,-0.03590057,0.027057417,-0.024719354,0.008527328,-0.020080939,-0.004386224,-0.0045394236,-0.016177883,0.016743544,0.0072121685,-0.008692313,-0.011039803,-0.02004323,-0.020420335,-0.003669721,-0.010191312,-0.028886383,-0.020552322,-0.0062316908,-0.0042070984,0.006915197,0.044385474,-0.08371772,-0.0024229116,0.0018961404,-0.03088505,0.043819815,0.010266734,-0.015310538,0.023361769,0.004039757,0.0030569225,0.012717929,-0.029414333,0.012010853,-0.013161029,-0.054227963,0.01906275,-0.024587367,0.018930763,-0.019402146,0.02967831,-0.0015343535,0.010587275,0.006104417,-0.015027707,-0.01773345,0.014113223,-0.013490997,-0.00341046,0.019006185,-0.0018089344,-0.024587367,0.0069199107,0.019628411,0.05403941,-0.055774104,-0.028565843,-0.036485087,0.01590448,-0.0063683917,-0.028169882,0.0011130545,-0.046949804,-0.007829681,-0.006109131,-0.010785256,-0.018629078,0.00047108895,0.017997425,0.018600795,-0.0039737634,0.017752305,-0.0013363723,-0.0011790481,-0.03190324,0.0074337185,-0.006589942,-0.0012692002,0.012585941,0.011190645,0.017271493,-0.02862241,-0.015565085,0.026981995,0.020891719,-0.058715537,0.050607737,0.024964472,-0.0037663546,-0.026359769,-0.00922969,0.016913243,-0.015367104,0.020194072,-0.014396054,0.011341488,0.04845823,-0.0022001828,0.00024320446,0.011181218,0.029602887,-0.000540618,0.030979328,-0.01016303]
5	a48c2085-a9dc-4486-ae89-09dc24564330	4	3	赵儿医	$2b$12$n6S2wt.29311hp.SGV4t4exytlU4djIcQc6W379D/zzsGcMxPOsx.	小儿哮喘，小儿消化不良，呼吸道感染，新生儿护理	5.0	1	女	[-0.016782098,0.05034629,-0.02626602,-0.029674303,-0.05379162,0.030544898,-0.009210704,0.015309496,0.0061543616,0.0038412663,0.019227171,-0.028674046,-0.016772835,0.011197326,-0.029285315,-0.019227171,-0.027432986,-0.012151276,-0.008576281,-0.028173918,0.021672245,0.050198104,0.017134039,0.040936463,-0.022894781,-0.015865194,0.039602786,-0.03319373,-0.017059946,-0.058422443,0.0027368155,0.007747364,-0.0037671733,-0.03156368,0.0036421411,-0.026914334,-0.047493704,0.005001287,-0.036101885,0.03725033,-0.0019542067,-0.01939388,0.02695138,-0.043752,-0.007951121,-0.03043376,0.01618009,-0.0049642404,-0.037287373,-0.05034629,-0.003111912,0.035657324,0.011947519,-0.006895293,0.013688708,-0.010669412,0.0061358386,0.010206331,-0.024265504,-0.021579627,-0.029081559,0.027970161,0.009159765,0.0058672507,0.026303066,0.04904966,0.035861082,0.0058811433,-0.0026812456,-0.016485725,-0.016893236,0.019208647,0.03291588,-0.016281968,-0.06246052,0.021005405,0.04115874,0.009687678,0.027673788,0.04041781,-0.015689222,0.0023235145,-0.010734244,0.03608336,-0.019542066,-0.008103938,0.028562907,0.036379732,0.011901211,-0.0224317,-0.03715771,-0.025173144,0.03901004,-0.022802165,-0.00355184,0.0061589926,-0.032211993,0.03297145,0.040565997,0.026451252,0.036398258,0.01550399,0.017161824,-0.035861082,0.04041781,-0.07524159,0.04634526,-0.014281454,0.030878317,0.019467974,-0.0023431957,0.000589272,-0.009613586,0.0063164406,0.012919992,-0.026766147,0.063905336,-0.03523129,0.00806226,-0.0055338317,-0.010502703,0.025191668,0.0071083107,-0.032656554,0.018634425,-0.0017736047,-0.008275278,0.012744021,-0.004797531,-0.0041723703,-0.011354774,0.09002317,-0.017171087,0.0067980457,0.022505792,-0.022468746,0.0346015,0.034119893,0.028266534,-0.010734244,0.004609983,0.026914334,0.041047603,-0.014022128,-0.028877802,-0.041047603,-0.01183638,-0.005047595,0.016958067,-0.043492675,-0.04464112,-0.0062886556,0.034360696,-0.022468746,0.040121436,-0.047715984,-0.043048117,0.016661696,0.0019403142,-0.020875743,0.018412147,0.008770776,0.003225367,0.00355184,0.030711608,0.023024444,0.021727813,0.022357605,-0.03117469,-0.012438387,0.019430926,0.002125547,0.029025989,0.01983844,0.056903534,0.029952154,0.03636121,0.031434014,0.0022505792,-0.046938006,0.019819915,-0.007900181,0.026617961,-0.01420736,0.023469003,0.009437614,-0.03291588,0.017949063,0.023524573,0.02576589,-0.002526113,-0.029896583,-0.019856961,0.016161567,0.010724982,-0.013688708,0.047382563,0.02074608,-0.020764602,0.026932858,-0.001646257,0.021857478,0.005316183,0.015568822,-0.009743248,0.020357091,-0.015105739,-0.05845949,0.016948806,-0.054384366,0.030693084,-0.033360437,-0.06872139,-0.004954979,-0.054087993,-0.016226398,0.018875228,0.009307951,-0.00035252128,-0.012160537,-0.037176233,0.006321071,0.01730075,0.009141241,0.07409314,0.0210795,0.08602214,0.0043552876,-0.00653872,0.013540522,-0.02656239,-0.008557758,0.028618477,-0.008715206,0.04201081,0.027266277,0.021524059,0.025173144,0.026655009,0.015133524,-0.011632623,-0.09357964,-0.004806793,-0.041121695,-0.05845949,0.011864165,0.0073491135,-0.026488299,-0.03280474,-0.008090045,-0.008242862,-0.0050661187,-0.019227171,0.026803194,0.0005415167,-0.041121695,0.017736046,-0.026692055,-0.035990745,-0.0321379,0.022468746,0.05964498,-0.03710214,-0.011595577,0.006978648,-0.027784929,-0.004207101,0.033508625,-0.0032554674,-0.022765119,-0.01928274,-0.016995115,-0.03465707,0.04960536,0.023802422,-0.03276769,-0.04734552,-0.0026696685,0.03128583,-0.044048373,-0.0007762414,0.034342173,0.015994858,0.0004211153,0.030822746,-0.037972737,-0.024598923,-0.03360124,-0.033749428,-0.037009526,0.04052895,-0.0014390277,0.07524159,-0.0013846155,-0.04567842,0.06616518,0.015911503,-0.1458153,-0.00081734,0.0024057117,0.034916393,0.0029289946,0.020060718,0.012123491,-0.009460768,-0.016846929,-0.09417238,0.027488556,-0.047641892,-0.009372783,0.025469517,-0.005274506,0.03613893,0.018143559,0.017439673,-0.019634683,-0.020542324,-0.05004992,-0.0022621562,0.024284028,0.00080634176,-0.025265763,0.027488556,0.04482635,-0.0064183185,-0.06071933,0.017699,-0.041047603,-0.028229488,0.0042256247,-0.008136353,0.020468231,0.0130033465,0.008497558,0.00580705,0.018189866,0.015429897,0.022227943,0.054828927,-0.005631079,0.055718042,0.041825578,-0.019301264,0.025099052,0.03541652,-0.05923747,-0.032045282,-0.018282482,0.009947005,0.032952927,0.015698485,-0.014651919,-0.033249296,0.0011316569,0.009650632,0.021468488,0.060422957,-0.018282482,-0.08742991,-0.004341395,-0.05090199,-0.0025052745,-0.01736558,0.0010587216,-0.032619506,0.035249814,-0.030767178,0.035749942,-0.008604066,0.012827375,0.018439932,-0.011438129,0.005779265,0.021301778,-0.044492934,-0.0126884505,-0.12758839,-0.01731001,0.02019038,-0.02830358,-0.020171858,-0.011326989,-0.07346335,-0.011086186,0.037009526,0.06301622,0.23502345,-0.0116141,0.006589659,0.013262672,0.023765376,-0.030674562,-0.0037787503,0.0035865712,0.0030864426,-0.047604844,-0.02695138,-0.019801393,-0.017393366,0.0074370992,-0.0019657838,-0.0022413176,-0.013151533,-0.0005429638,0.05994135,-0.027655266,-0.030581946,-0.0041283774,0.0069693862,-0.040010296,0.009159765,-0.030267049,-0.040047344,-0.0006778365,-0.015124262,0.04545614,-0.031841528,0.019597637,-0.009613586,-0.028173918,-0.05920042,-0.04401133,0.01900489,-0.045937747,0.0071222032,-0.014929769,-0.021561105,-0.021505535,0.00052357226,-0.00032907774,-0.0012213791,-0.04312221,-0.023431957,-0.018134296,0.0072426046,-0.03815797,-0.016846929,-0.028711094,-0.0045520975,-0.0050614877,0.015744792,-0.009659894,-0.003838951,-0.045345005,-0.002078081,0.08179883,0.007969644,0.021838954,-0.007543608,0.032730646,-0.018115774,0.038306154,0.0083169555,0.039417554,0.014457424,0.008358632,-0.0583854,0.025376901,0.016902499,0.007812196,0.020671986,-0.015365065,-0.038454343,0.017569337,-0.0011768074,0.001555956,-0.041010555,-0.06623927,-0.04245537,-0.027988685,0.0054087993,-0.017967587,0.09343145,0.018282482,0.0143185,-0.009928481,-0.024154365,0.0022332137,0.015133524,-0.03236018,-0.008465142,0.012790329,-0.020153334,-0.03534243,-0.053347062,0.045122724,-0.0151798325,-0.0240247,-0.0063673793,0.019319788,0.0024404428,0.051161315,-0.016939545,0.029377932,-0.015374327,-0.009632109,0.04289993,0.015170571,-0.010030359,-0.019968102,-0.017226655,-0.022968873,0.07312993,-0.0043321336,0.03471264,0.019208647,-0.029748397,0.022246467,0.024987912,0.004519682,0.004735015,-0.0008161823,0.039713923,0.002227425,-0.0594227,0.033212252,0.019801393,-0.009780295,-0.04301107,0.052050434,0.07157397,0.044344746,0.012336508,-0.0092431195,-0.006228455,0.046938006,-0.041121695,0.008974532,-0.008085414,0.0017435043,0.024876773,0.014142528,0.033638287,-0.014142528,-0.010947262,0.035546184,0.011975304,0.032841787,0.045752514,-0.0035749942,-0.014855675,-0.0069323396,-0.004494212,-0.005181889,0.025839984,-0.011938258,-0.010928739,0.006478519,0.03208233,0.068313874,0.0020850273,-0.0076130703,-0.016430154,-0.007756626,0.019912532,0.019375356,-0.0051309504,-0.013447905,-0.045937747,0.0038551588,-0.01691176,-0.02441369,0.008576281,0.007886289,0.018328791,0.09520969,0.0054597384,-0.008085414,0.014485209,-0.020338567,-0.008562389,0.013179318,-0.024710063,-0.012475433,0.03800978,-0.020671986,-0.014411116,0.08950452,-0.027710835,-0.001190121,0.008798561,0.023598665,0.023765376,0.028155394,-0.0006558401,0.034027275,0.038491387,0.009118088,0.021116545,0.025062006,-0.0039987145,0.01815282,-0.06672087,0.0049735024,-0.013855417,0.009622847,0.016281968,0.043418583,-0.027747883,0.020727556,-0.032730646,-0.03150811,0.039602786,0.057977885,-0.06827683,-0.042307183,0.0058440967,-0.02750708,0.06349783,-0.019597637,0.02835915,0.0066220746,0.016680218,0.0062840246,-0.015531775,-0.026191926,-0.0020259845,0.0055060466,-0.020486753,0.0056218174,-0.018615901,0.040454857,0.016189352,0.0151798325,-0.03445331,-0.049123753,-0.05923747,-0.025895553,0.0139480345,0.045974795,-0.03963983,0.023135584,-0.03793569,-0.021375872,-0.0069693862,0.009483922,-0.04460407,-0.022450222,0.01674505,-0.04401133,0.029563164,-0.0038366355,-0.009317213,-0.004183947,-0.017106254,-0.0058718817,-0.043418583,0.041640345,0.0037509655,-0.015383589,-0.02835915,-0.034082845,0.04660459,0.019616159,0.045085676,0.007029587,-0.012734759,-0.016494986,-0.016754312,-0.030804224,0.05638488,-0.01719887,-0.09187549,0.07553796,0.039269365,-0.031304352,-0.011188065,-0.046011843,-0.022635454,0.030470805,0.016393108,0.040454857,0.021561105,0.015717007,-0.026543869,0.023950608,0.00055801397,0.016226398,-0.026247496,0.043529723,0.0068628774,-0.0006888347,0.029100081,-0.0045729363,-0.025488041,0.0123828165,-0.019708777,-0.022857735,0.021283256,-0.038972992,0.02869257,-0.023061492,0.008974532,-0.054273225,0.0047929003,-0.021116545,0.031600725,-0.06546129,0.028859278,-0.011688193,0.02480268,0.015198356,0.028618477,-0.026655009,0.019153077,0.03986211,-0.032397225,0.0059459745,-0.044789303,0.04227014,-0.067387715,0.038491387,-0.012771806,0.0033874458,-0.029748397,-0.023042968,-0.013410859,-0.006612813,-0.014809367,-0.043048117,0.02841472,0.003382815,0.034490358,-0.0012167484,0.012142014,-0.028637,-0.014022128,-0.032378703,0.033582717,0.023580143,0.019245693,-0.009826603,-0.0184955,0.04660459,0.022616932,0.0051911506,0.035064578,-0.007895551,-0.022579886,-0.007974274,0.013503475,0.045085676,-0.011993827,0.007844611,0.00789092,0.014726012,-0.023876516,-0.0007947647,-0.083354786,0.004357603,-0.012364293,0.009284797,-0.0089282235,0.04556728,-0.0130126085,-0.022579886,-0.0017006692,0.025080528,0.0035819404,0.029396454,-0.02626602,0.020783126,0.010938,-0.021894524,0.029377932,0.029803967,-0.007261128,0.040047344,0.020783126,-0.018301006,0.020023672,0.006376641,-0.036972478,0.019023415,0.03765784,-0.008418833,-0.034416266,0.0020734502,-0.044492934,-0.0031489586,-0.13484952,0.0014425009,-0.031211736,-0.026525345,-0.031674817,-0.032582458,0.04256651,0.024321074,-0.01994958,-0.044270653,0.0068628774,-0.0009053256,0.049123753,-0.007895551,0.014411116,0.012299461,0.0245804,-0.01313301,0.034360696,0.030396711,0.0013487267,-0.04171444,0.04678982,0.0040056603,-0.01116028,-0.0599784,0.004278879,0.047382563,-0.012957038,0.032489844,0.024987912,-0.016596865,0.05293955,0.0337309,-0.021283256,-0.006635967,-0.004091331,0.019801393,0.037120666,-0.0041168,0.0016613072,0.00032560463,0.012410602,0.007446361,-0.021913048,0.004765115,0.0026279911,-0.0015698485,-0.019727299,0.0030910734,0.0077103176,0.025339855,-0.02232056,0.01313301,-0.03280474,-0.011465914,-0.026784671,-0.0042140475,-0.006473888,0.042603556,-0.06464627,-0.0077381027,-0.018365838,-0.03495344,0.011678931,0.049308985,0.011586315,0.041195787,0.0018777981,0.023413433,-0.045974795,0.00084686145,-0.008872654,-0.02452483,0.022653978,-0.0061914083,0.04008439,-0.03815797,0.008645743,-0.03625007,0.005339337,0.010706459,-0.004711861,-0.0006685748,0.06320145,0.0065248273,-0.0049642404,0.00093368936,0.023691282,0.018226912,-0.05390276,-0.061200935,0.002616414,-0.041788533,-0.05001287,0.034008753,-0.0063442253,-0.030285573,-0.046419352,-0.010391563,-0.052717272,-0.03462002,-0.008414202,-0.0033758688,0.005311552,0.038083874,-0.007515823,0.0077149486,-0.011762287,0.0007490354,-0.08357707,-0.039084133,-0.010122975,-0.052235667,-0.08068743,0.024395168,-0.057533324,0.01736558,-0.04019553,0.003827374,0.05175406,0.018782612,0.007923336,-0.028599953,0.0005131529,-0.0068628774,0.032619506,-0.0126977125,0.0057746344,-0.023098538,-0.012919992,-0.03534243,-0.023932084,0.053717528,-0.0020966043,-0.005445846,-0.03856548,0.030081816,-0.028266534,-0.021913048,-0.02102393,-0.0068212,0.015818886,-0.024561876,-0.0038922054,-0.0621271,-0.018625164,0.008386417,-0.009678417,0.009043994,-0.010104452,-0.029285315,-0.015587345,0.05664421,-0.00018827184,0.040788274,0.0063905334,0.02604374,0.020023672,-0.005024441,-0.014161052,-0.06535015,-0.03462002,0.0139480345,-0.039454598,0.04301107,0.014522256,-0.014337023,-0.055199392,-0.0009504761,0.033175204,0.007520454,0.009511707,-0.02119064,0.03693543,-0.041084647,0.011725239,-0.013725755,-0.0245804,-0.031823006,0.030007724,0.046308216,0.0073305904,-0.003433754,-0.00012828823,0.06894367,-0.01758786,0.005422692,-0.004109854,-0.023598665,0.03224904,0.00055917166,0.0018523285,0.012614357,0.054532554,-0.0042534093,0.03867662,0.018801134,-0.0037000263,0.031674817,-0.037694886,0.023376387,-0.009043994,0.0061960393,-0.025543611,0.0047512227,-0.014049912,-0.011567792,0.0042302553,-0.05156883,0.0056681256,-0.028766662,0.042196047,0.053458203,-0.029396454,-0.04301107,0.03789864,-0.03978802,-0.014985338,0.03788012,0.021783384,-0.013762801,-0.029322362,0.042603556,-0.0014864936,-0.023950608,-0.017634168,-0.019153077,-0.010697197,-0.017013637,-0.03106355,0.04460407,-0.03247132,-0.028118348,0.042418323,-0.018115774,0.023246724,-0.060460005,-0.0029336254,0.043603815,0.0075528696,0.03287883,0.0033920766,-0.03528686]
\.


--
-- Data for Name: inspection_request; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inspection_request (id, uuid, register_uuid, medical_technology_id, creation_time, inspection_time, test_results, inspection_state, input_employee_uuid) FROM stdin;
\.


--
-- Data for Name: medical_record; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.medical_record (id, uuid, register_uuid, readme, present, history, allergy, physique, proposal, diagnosis, is_doctor_confirmed, cure, dialog_vector) FROM stdin;
11	adefbf7b-1e69-4e7e-a148-77e788a78181	25dcae83-1fc8-40a7-881c-dac05935bed0	无	患者未提供明显症状描述。	\N	\N	\N	\N	\N	f	\N	\N
13	8f37b758-3587-4098-8890-9858e3acadd2	78b9ac99-8f59-4588-8e5e-1d7bfef1e9a7	无	患者未提供明显症状描述。	\N	\N	\N	\N	\N	f	\N	\N
14	51885204-4ecb-4a82-a6bf-fde6605c5ce2	453ef75c-e0e5-4a8a-87f1-ea8185a22633	无	患者未提供明显症状描述。	\N	\N	\N	\N	\N	f	\N	\N
15	f0b30aa2-bd28-4311-9b7d-f9049043fc5c	c147bef9-cbdc-4bba-9375-bccfc0a62b1f	无	患者未提供明显症状描述。	\N	\N	\N	\N	\N	f	\N	\N
16	c6926ae0-2a47-44e1-8ec0-e5dac9f0d1b7	356cf39f-28db-4ccd-b1c3-c8b618ee8331	无	患者未提供明显症状描述。	\N	\N	\N	\N	\N	f	\N	\N
17	4e343351-c6b7-4e5b-8a57-e6d20415fa23	2fa948f0-4adf-466c-b950-471d49964413	无	患者未提供明显症状描述。	\N	\N	\N	\N	\N	f	\N	\N
18	cd05d0f6-eb53-48ea-990d-1e3dcf51ca0d	9f0570da-d37f-4601-be19-07df88614326	主诉头痛	现病史无	既往史无	\N	查体无	\N	头痛	t	\N	[-0.04848236,0.042883843,-0.044826187,-0.03147735,-0.021080114,-0.004870135,0.016690804,0.076132156,0.05480449,-0.02915416,0.0019661442,-0.020775434,-0.016281389,0.00093130016,0.03764714,0.022355964,0.025402775,-0.0051272092,-0.036714055,-0.0142533565,0.0018138038,0.0012353861,0.0032800809,-0.025269477,-0.028392456,0.0119682485,-0.012006334,0.013139366,0.03229618,0.016500378,0.018528411,-0.04612108,0.053890444,0.0015567293,0.010216333,-0.03035384,-0.01443426,-0.009978302,-0.025955008,-0.0043702675,0.055033,0.0071742847,0.019347241,0.017147826,0.021841817,-0.0146627715,-0.02997299,-0.026640542,-8.784868e-05,0.021156283,0.005646119,0.007788407,0.04791108,-0.04143661,-0.02603118,-0.027478414,0.013653516,-0.0076122633,0.0119016,-0.027402245,-0.04619725,-0.0072123697,-0.021975115,-0.0028325808,0.046463847,0.062688105,0.0011568355,0.015900537,-0.02142288,-0.022717774,-0.022622561,-0.04650193,-0.010168727,-0.036428418,-0.047301717,0.01732873,-0.0069457735,-0.019013995,0.0095165195,-0.009049976,0.039760865,0.016043358,-0.0016412307,0.019299634,-0.020070858,0.036333203,-0.0122919725,0.05891768,-0.037132993,0.012625217,-0.031705864,-0.010263939,-0.047339804,-0.03719012,-0.01569107,-0.019728092,-0.027630754,0.01889974,0.028830435,0.00020188089,0.009502238,0.055832785,0.04353129,-0.011806387,0.0109875575,0.020737348,0.010540057,0.026659584,0.028735222,0.010168727,0.013082239,0.024964796,0.011577876,-0.0035942832,-0.001272281,-0.004960587,-0.009568886,-0.052176613,-0.05712768,-0.00535572,0.010282982,0.0023743692,-0.0009854524,0.0013698741,-0.0077931676,0.047377888,0.009787876,0.0028111578,-0.0284115,0.0068934066,0.0044583394,0.020261284,-0.015938623,-0.043721717,-0.0053271563,-0.011111334,-0.010978036,0.050386615,-0.012825164,0.0041631795,0.011292238,0.06954343,0.029287457,-0.016167134,0.062459596,-0.046349593,0.03831363,0.03341969,0.03987512,-0.035666715,0.016528942,0.0014174805,0.01539591,0.032334268,0.057241935,0.0056365975,-0.04158895,0.0064982735,0.017557241,-0.0003957282,-0.00019964934,0.043378953,-0.018709315,0.025231391,-0.0026159717,-0.00483443,-0.0038489774,-0.0010241327,0.0013067956,-0.018918782,0.00676963,-0.009611732,-0.031934373,0.015862452,-0.0070314654,0.04261725,0.049129803,0.009378461,-0.0006605388,-0.04082725,-0.053738102,-0.015167399,0.0045963977,0.009768833,-0.03987512,-0.013567824,-0.008769099,0.019804262,0.02327001,-0.008673886,-0.022489263,-0.026754797,0.020147027,-0.0034657458,-0.014843675,-0.0041393763,-0.03680927,-0.025002882,-0.03086799,0.010054472,0.015814846,0.031439267,0.033438735,-0.00490822,-0.0053509595,-0.007993114,-0.030410968,-0.001294894,-0.008064524,-0.056061298,-0.04791108,0.0105019715,-0.02797352,0.0013365496,0.0105591,-0.048406187,0.028525755,0.010673354,0.05712768,-0.05602321,-0.029801605,-0.008264471,0.03496214,-0.018242773,-0.018871177,-0.047720656,0.018890219,0.0229082,0.026202563,0.0014841295,-0.020585008,0.050691295,0.027211819,-0.017347772,0.058803424,-0.046997037,0.005565188,0.00386802,0.023765115,-0.0016317094,-0.010016386,0.011625483,0.0739613,-0.012882291,-0.02254639,0.007350428,0.022260752,0.0003347325,-0.024279265,-0.007564657,0.00691721,-0.016243303,-0.014120058,0.013206015,0.035209693,0.0028611447,-0.00023103981,-0.0051129274,-0.028011605,-0.011263674,0.010073514,-0.02945884,0.019956604,0.042045973,0.009735509,-0.010492451,-0.0042274483,0.00065696833,0.016424207,0.009035694,-0.0070457472,-0.016500378,-0.010425801,0.020185113,0.0062697628,0.02239405,0.022451177,-0.015015058,0.022793945,-0.0042203073,-0.019328197,0.007521811,0.028011605,0.03475267,0.02641203,-0.0056413584,-0.0019244887,-0.07015279,0.0027207057,0.00028831625,0.02142288,-0.0006974338,0.084320456,-0.015119793,-0.063068956,0.040408313,0.0041108127,-0.16940261,-0.022279795,0.024165008,-0.031458307,-0.021994157,0.029325543,-0.023993626,-0.000721237,-0.020661177,-0.019842347,0.036752142,-0.044597674,-0.01644325,0.022032242,-0.029515969,0.0014627066,-0.0310965,-0.03332448,0.032905545,-0.027573626,-0.025726499,0.057241935,0.009497477,-0.06333555,-0.018975912,0.006488752,0.042274483,-0.031229798,-0.00728854,-0.019432932,-0.010939951,0.019975645,-0.016738411,0.026792882,0.021403838,0.018109474,0.005936518,0.036123738,0.0047796825,-0.00877386,0.022222668,0.045321293,-0.00751229,0.011463621,0.01978522,0.01770006,0.0022851073,-0.05884151,-0.041246183,-0.013101282,0.025231391,-0.0119016,-0.01472942,0.021537134,-0.028182989,-0.0049939114,0.026659584,0.03311501,-0.01130176,-0.028506713,-0.025688414,-0.09871663,0.060745765,0.0071600024,-0.044292994,-0.025136178,-0.034543205,-0.0043274215,0.0150721865,-0.010311546,-0.0006480421,-0.026621498,0.012739472,0.002932554,-0.035019267,-0.018833091,0.005926997,0.005179576,0.003801371,-0.09041408,-0.023079583,0.032619905,-0.0169574,0.0034086183,-0.010740004,0.008973806,0.014538994,-0.0072790184,0.020794475,0.27025202,0.064897045,0.010168727,-0.016481336,0.02871618,0.009130907,-0.044026397,0.043607462,0.011892078,-0.03376246,-0.02707852,-0.015376867,-0.008826227,0.011625483,0.010673354,0.052252784,-0.041703206,-0.0016590831,0.07000045,-0.011368408,0.03979895,-0.0070457472,0.015871974,-0.008545348,-0.028506713,-0.025764583,-0.041741293,0.09726939,-0.01584341,-0.0024053133,-0.017081177,-0.005317635,0.029268414,0.0017900006,-0.019518623,-0.030982245,0.0012734712,-0.07129534,-0.057394277,-0.013948675,0.00974027,-0.023841284,-0.0016424208,0.012015855,-0.054423638,0.037532885,0.017804794,0.06131704,-0.016643198,0.001651942,-0.009235642,-0.02864001,0.0039037247,-0.017947612,-0.0016186176,-0.023498518,-0.05385236,-0.032696076,-0.044140656,0.049015548,0.0048677544,0.012891813,-0.0105019715,0.018709315,0.0033348282,0.011396972,-0.030810863,0.025021924,0.03250565,0.04143661,0.047377888,0.010406759,-0.0037656662,-0.0038489774,0.03964661,0.014072452,-0.058803424,0.047035124,-0.008216864,0.048672784,0.011320801,-0.008445376,-0.022070328,0.012472876,-0.00084144314,0.022527348,0.03065852,0.05267172,-0.0032800809,-0.053242996,0.0036133258,-0.0028659052,-0.06569683,0.0650113,-0.038351715,0.0046654274,0.030487139,-0.03311501,-0.028240116,0.017966656,0.0006492323,0.0025398014,-0.01963288,-0.053738102,-0.0082121035,-0.033362564,0.009806918,0.004372648,-0.022489263,-0.007855056,-0.054347467,0.0011883747,-0.0054461723,-0.041969802,0.012510962,0.029763522,0.019956604,0.013253622,0.0040679667,-0.019499581,-0.0071885665,0.0246982,-0.0310965,0.04353129,0.017500112,-0.014548516,-0.01137793,0.015215006,-0.055566188,0.05213853,0.022565434,-0.013939153,-0.08630088,-0.0078836195,0.061507467,-0.01264426,0.05183385,0.03035384,0.0033586314,0.009021413,-0.013263143,-0.006412582,-0.04143661,0.010387717,0.0041441373,-0.0141771855,0.004858233,-0.053585764,0.0016900272,0.027573626,0.008940482,-0.0045345095,0.049129803,-0.028944692,-0.004336943,-0.040370226,-0.040332142,-0.00572705,0.031248841,-0.024355434,-0.00039037247,0.04284576,0.047073208,0.06664896,0.021080114,0.0125395255,-0.0075979815,0.033000756,0.02357469,-0.0145866005,0.009687902,-0.033343524,-0.022298837,-0.010901866,-0.007312343,-0.035362035,-0.037513845,0.068781726,0.05415704,-0.06463045,0.009864046,-0.0039013445,-0.010616227,0.027135648,0.037132993,0.013634473,0.0030658522,-0.017271603,-0.0074218377,-0.041055758,-0.023936497,0.12750898,0.010806653,-0.019766178,0.016919315,0.012587132,0.03837076,0.037837565,0.015652984,-0.005550906,0.019204421,-0.019556709,0.006331651,0.005841305,0.0024088838,0.029211286,-0.023041498,-0.0072266515,0.024507774,-0.009454631,0.0182999,-0.027211819,-0.027440328,-0.013434526,-0.047872994,0.0028754266,0.04486427,0.023612775,-0.06478279,-0.01420575,0.04817768,-0.022070328,0.027307032,-0.049053635,-0.0014591361,0.056708742,0.0048677544,-0.012825164,-0.004498805,0.008716731,-0.0030967963,-0.027402245,0.020318411,-0.026716711,-0.019194901,-0.03949427,0.039608523,0.011844472,0.010625748,-0.020946816,0.004932023,-0.0078788595,0.03540012,0.026811924,0.002765932,0.024431605,-0.0046297223,-0.053319167,0.02254639,0.015976708,-0.01770006,-0.030011075,-0.007683673,-0.034619372,-0.033343524,0.06497321,0.010330589,0.034467034,-0.045625973,0.014462824,-0.0128632495,0.058879595,0.00085155945,-0.00290161,-0.029992031,-0.054614063,-0.0011514798,0.010168727,-0.030906074,-0.035933312,-0.0007194517,0.006455428,-0.04315044,-0.03732342,-0.036333203,-0.021594264,-0.047339804,0.061545555,0.006798194,0.008521546,-0.010378195,-0.026888095,0.015234048,0.042312566,0.031248841,0.057508532,0.0034562247,-0.0020030392,0.010168727,0.009402264,0.036866397,-0.004893938,-0.05050087,0.030734692,0.019899474,0.014986495,-0.021518093,0.04254108,-0.03050618,0.002023272,-0.035209693,-0.006998141,-0.056365978,-0.03117267,-0.046616185,-0.021822773,0.007269497,-0.04151278,-0.020394582,0.0017269221,-0.01748107,-0.06364024,-0.006079337,-0.03995129,0.040217888,-0.014738942,0.021917986,-0.01867123,0.029477883,0.017566761,-0.015833888,0.013072717,-0.0066410927,-0.04977725,-0.035000224,0.0054794964,0.035381075,-0.0021910844,0.006517316,-0.037171077,-0.017423943,-0.022451177,0.0020482654,-0.005884151,0.00040346425,0.013901069,-0.0043202806,0.04056065,0.040294055,-0.031572565,-0.014605643,-0.050272357,0.049739167,-0.018528411,-0.012034898,0.0012615696,-0.0005489613,-0.01264426,0.0149960155,0.01711926,0.0055842306,-0.0052319434,-0.026792882,-0.03496214,0.06261194,0.031344052,0.040751077,-0.021022987,0.05602321,0.0050319964,-0.030182457,0.051986188,-0.015852932,0.0141771855,-0.031934373,-0.0010223475,0.018833091,-0.022622561,0.042655334,-0.014929367,-0.011416014,0.03161065,0.009454631,0.00028310932,-0.01889974,0.013348835,-0.0015555391,0.008269232,-0.0077503216,0.024145966,-0.025764583,0.028316287,-0.03896108,-0.004713034,0.030620437,-0.024831498,-0.016376602,0.021708518,-0.007193327,-0.005846066,0.021765646,-0.02574554,-0.012206281,-0.02142288,-0.13474515,-0.0016697944,-0.011987291,-0.017757187,-0.06444002,0.011787345,-0.03271512,0.021879902,0.02923033,-0.00290161,-0.03926576,0.053738102,0.068172365,-0.0074504013,0.004253632,0.033514906,0.018014261,0.011701653,0.011282717,0.008745296,-0.005103406,-0.002128006,0.06626811,0.03949427,-0.01212059,0.0036918763,-0.047492143,0.017509634,-0.011844472,0.033057883,0.008564391,-0.027440328,0.023479477,0.036428418,0.054956827,0.038485013,0.0066982205,-0.037989907,0.044902354,-0.005155773,-0.024203094,0.017661974,-0.048253845,-0.028582882,-0.03227714,0.025574157,0.029801605,0.013977239,-0.005155773,-0.042883843,-0.019518623,0.037475757,-0.017043091,0.039037246,-0.027935436,-0.040751077,-0.03892299,-0.024679158,-0.04097959,-0.0011961107,-0.027459372,-0.015557772,-0.029706394,-0.062878534,-0.02454586,0.024679158,-0.07727471,0.03496214,-0.037437674,0.01926155,-0.016557505,-0.043188527,0.035362035,0.0012222943,-0.011787345,0.033134054,0.044026397,0.013148888,-0.064668536,-0.027211819,-0.035514373,0.02306054,-0.038047034,-0.012149153,0.006702981,-0.012825164,-0.016224261,-0.020565964,-0.031058416,0.006798194,-0.06687747,-0.03182012,0.007821731,-0.00039662083,-0.009492716,0.0165099,-0.00083132676,-0.06131704,-0.0074932473,-0.0092737265,-0.004505946,-0.03629512,0.0073837526,-0.022584476,-0.00066113385,0.028544797,-0.020775434,-0.026735755,0.0073837526,0.01153027,-0.025935967,-0.00930229,-0.022889158,0.022432135,-0.02938267,0.023517562,0.031058416,0.05594704,0.024717243,0.00506056,-0.009221359,-0.034314692,-0.025497988,-0.025021924,0.042312566,-0.030239586,0.025916925,0.018033303,0.032086715,0.040865332,0.010111599,-0.06344981,-0.0045725945,0.024069795,0.011063728,0.04551172,-0.033990968,0.005179576,0.01465325,-0.032258097,0.016043358,-0.010682876,-0.0025921685,-0.043988314,-0.035419162,0.0017769089,0.026507244,0.009254684,-0.026621498,-0.01205394,0.0074218377,-0.017052613,-0.011768302,0.076360665,0.0054652146,0.0015614899,-0.030810863,-0.027764052,0.0025040966,0.029915862,0.013624951,-0.04806342,-0.038942035,-0.024983838,-0.026792882,0.07045747,-0.013044153,-0.01115894,-0.040789165,0.028773308,-0.021441922,-0.0026754797,-0.026088307,-0.042388737,0.047035124,0.016528942,-0.0027064239,0.0019244887,0.06105045,-0.005274789,0.05236704,0.015376867,-0.0018590299,0.010359152,0.030391926,0.005079603,0.035133522,0.027440328,0.023174796,-0.028963733,-0.011663568,-0.006160268,-0.042312566,0.036866397,0.035000224,0.016414687,0.0056794435,0.026240647,0.009959259,0.04425491,0.00079026626,0.0037680466,-0.009245163,-0.048710868,-0.054233212,0.01204442,0.0045940178,0.013796335,-0.013748729,0.010454365,-0.017100219,-0.012406228,0.010378195,0.014862718,-0.021156283,-0.030734692,0.005555667,0.028125862,-0.005460454,0.024203094,0.04284576,0.027116606,-0.03206767,0.0018768823,0.01420575,-0.016024314,0.026888095,0.0004989746,0.030030116,0.015948145,-0.005588991,-0.043683633,0.008102609,0.024012668,-0.038865864,-0.017738145,-0.060136404,-0.013044153,-0.07220939,0.02603118,0.011987291,0.007259976,0.045245122,-0.057622787]
20	50120b8a-f0be-419e-99fc-4dc44b0d94d3	62620bb0-bdd0-41e6-862e-eb04dcdde639	主诉头痛	现病史无	既往史无	\N	查体无	\N	头痛	t	\N	[-0.04840438,0.04292033,-0.044786427,-0.031457134,-0.021041242,-0.004798546,0.016737785,0.07605314,0.054764356,-0.029114986,0.0019601204,-0.020793699,-0.016290301,0.0009366209,0.03768382,0.02235513,0.025382785,-0.0050794133,-0.036693644,-0.014290907,0.0018161163,0.0012912754,0.0032632968,-0.025287574,-0.028410438,0.0119678015,-0.011986843,0.013138875,0.032294974,0.01648072,0.018565802,-0.046081275,0.053888433,0.0015185875,0.010244515,-0.030409832,-0.014471805,-0.009968407,-0.025973082,-0.0043415413,0.055030942,0.0071406933,0.019346518,0.017194789,0.021802917,-0.014671745,-0.02997187,-0.026620504,2.00832e-05,0.021136452,0.005679231,0.0078262,0.047871206,-0.041435063,-0.02606829,-0.027439304,0.013748215,-0.0076167393,0.011920197,-0.027420262,-0.046157442,-0.0072121,-0.021955252,-0.0027682087,0.04646211,0.062685765,0.0011044273,0.015909465,-0.021422079,-0.0226598,-0.022602674,-0.04646211,-0.0101683475,-0.03642706,-0.047338035,0.017385207,-0.0069502746,-0.01904185,0.009535206,-0.009021075,0.039721295,0.016099883,-0.0016387891,0.019317955,-0.020032024,0.036312804,-0.012310555,0.05891548,-0.037112564,0.012615224,-0.031685635,-0.01030164,-0.04737612,-0.0372649,-0.015680963,-0.019689271,-0.027667806,0.018899035,0.028886484,0.00019250119,0.009516164,0.055868782,0.043529667,-0.011824988,0.011053793,0.020774657,0.010549184,0.02667763,0.02873415,0.010139785,0.013062708,0.024963863,0.01163457,-0.0035989094,-0.001266283,-0.0049699224,-0.009563768,-0.052174665,-0.057125546,-0.005384083,0.010254036,0.0023742805,-0.0010205241,0.0013710131,-0.007745272,0.047452286,0.009739906,0.0027896308,-0.02842948,0.0068455446,0.004512918,0.020241486,-0.015871381,-0.043720085,-0.005336478,-0.011091877,-0.011063314,0.050422814,-0.012796123,0.0041844463,0.011301337,0.06954083,0.029286364,-0.016166529,0.062457263,-0.046309777,0.038274117,0.033437487,0.039835546,-0.035703465,0.016528325,0.0013745835,0.015423898,0.03237114,0.057201713,0.0057220757,-0.04170165,0.0064551868,0.017585147,-0.0004153503,-0.0002456101,0.043377332,-0.018718136,0.02524949,-0.002606353,-0.0048247282,-0.0038773965,-0.0010359955,0.0012888951,-0.018851431,0.006831263,-0.009601852,-0.03200935,0.015871381,-0.0070359632,0.042615656,0.049089886,0.00937811,-0.00063492666,-0.040825725,-0.053812265,-0.01514779,0.0045795646,0.00978751,-0.03987363,-0.013614922,-0.008764011,0.019841606,0.023288181,-0.008673562,-0.022488423,-0.026734756,0.020070108,-0.0034775175,-0.0148336,-0.0041178,-0.036731727,-0.02492578,-0.030885879,0.010016012,0.015842818,0.031457134,0.03338036,-0.0048889946,-0.0053698015,-0.007949972,-0.030485999,-0.001298416,-0.008040421,-0.05602112,-0.047871206,0.0105111,-0.027972477,0.0013531614,0.010568226,-0.048442464,0.028543731,0.010682477,0.057201713,-0.055983037,-0.029838577,-0.008264163,0.034960832,-0.018146882,-0.019003766,-0.04771887,0.018899035,0.022945428,0.026182542,0.0015114468,-0.020641364,0.0506894,0.027210802,-0.017318562,0.05880123,-0.0469572,0.0054840525,0.003863115,0.023821352,-0.0016435495,-0.010006491,0.0116440905,0.073996626,-0.012881811,-0.022583632,0.007340633,0.022221837,0.00034483598,-0.024240274,-0.007559614,0.006945514,-0.01626174,-0.014090968,0.013176959,0.03524646,0.0028776994,-0.00022448554,-0.0051032156,-0.027991518,-0.011310858,0.01009218,-0.029419657,0.01999394,0.042006318,0.009744666,-0.0104920585,-0.004196347,0.0005679826,0.016423594,0.009049638,-0.0070502446,-0.016499761,-0.010463496,0.020241486,0.0063028517,0.022393214,0.022431297,-0.015014498,0.022888303,-0.0041582636,-0.019298913,0.007540572,0.028067686,0.03473233,0.026430085,-0.005655429,-0.0019434587,-0.070188254,0.002718224,0.00024605638,0.021364953,-0.0007366815,0.084317304,-0.015138269,-0.06310469,0.04036872,0.0040844767,-0.16939628,-0.022278963,0.024183149,-0.03141905,-0.021993335,0.029324448,-0.023992728,-0.00080689834,-0.020660406,-0.01978448,0.03676981,-0.04459601,-0.016347427,0.022107586,-0.029514866,0.0014781235,-0.031095339,-0.033304192,0.0329424,-0.027591638,-0.025706496,0.057201713,0.009554247,-0.0632951,-0.019003766,0.0064551868,0.042310987,-0.0313048,-0.007307309,-0.019441728,-0.010949063,0.019917773,-0.016718743,0.02677284,0.02144112,0.018118318,0.005922015,0.036122385,0.004765223,-0.00875449,0.022183754,0.04535768,-0.007459644,0.011453672,0.019822564,0.017670836,0.0022933527,-0.05880123,-0.04128273,-0.013148396,0.025287574,-0.011920197,-0.014719349,0.021479206,-0.028181937,-0.0050365687,0.02667763,0.033132818,-0.01133942,-0.028543731,-0.025687454,-0.09878911,0.060705412,0.0072121,-0.044329423,-0.025154281,-0.03448479,-0.0043391613,0.015100186,-0.01030164,-0.00066527457,-0.026658589,0.012758039,0.0029229238,-0.034979876,-0.018813346,0.0058553685,0.005212706,0.003801229,-0.09056303,-0.023078721,0.03263773,-0.016918683,0.0034394339,-0.01072056,0.009016315,0.01452893,-0.0072692255,0.020831782,0.27024192,0.06489462,0.010158827,-0.016490242,0.028772233,0.009106765,-0.044024754,0.043605834,0.011872592,-0.033742156,-0.027115593,-0.015433419,-0.008887783,0.011596486,0.010682477,0.052250832,-0.041663565,-0.0016625914,0.06999783,-0.011348941,0.03975938,-0.0070502446,0.015833298,-0.008578353,-0.02852469,-0.025782663,-0.041777816,0.0971896,-0.015842818,-0.002377851,-0.017071018,-0.0052603106,0.029305406,0.0018458692,-0.019498853,-0.031019172,0.0012746138,-0.07133076,-0.0574683,-0.013986238,0.00968754,-0.02389752,-0.001659021,0.012015406,-0.054421604,0.037531484,0.017851733,0.061352838,-0.016642576,0.0016387891,-0.009292422,-0.028657982,0.0039297617,-0.0179279,-0.0016959147,-0.023459557,-0.05377418,-0.03275198,-0.04417709,0.048975635,0.0048580514,0.012929415,-0.010473017,0.018727658,0.003356126,0.0114346305,-0.03079067,0.024963863,0.03254252,0.041435063,0.04737612,0.010415891,-0.0037940883,-0.003863115,0.03956896,0.014081447,-0.05880123,0.046995282,-0.008264163,0.048632883,0.0113299,-0.008421257,-0.02205046,0.0124914525,-0.00082058465,0.022545548,0.030657377,0.052669752,-0.00329662,-0.053317178,0.0035584455,-0.002813433,-0.06569438,0.064970784,-0.038369324,0.0046128877,0.030466957,-0.033113774,-0.028277146,0.018004067,0.0006438525,0.0026134937,-0.01967023,-0.053698014,-0.008216558,-0.033323236,0.009911282,0.0043510622,-0.022526506,-0.007816679,-0.054345436,0.0011573874,-0.005488813,-0.041968234,0.0124914525,0.029743368,0.01999394,0.013281689,0.0040559135,-0.019498853,-0.007159735,0.02462111,-0.031057255,0.043491583,0.01750898,-0.014576535,-0.011396547,0.015214437,-0.055602197,0.052098498,0.022602674,-0.013957675,-0.08629766,-0.007830961,0.061505172,-0.012605703,0.05179383,0.030371748,0.0033109013,0.008978232,-0.013253126,-0.006407582,-0.04151123,0.010339724,0.0041892068,-0.014129052,0.0048675723,-0.053583764,0.0017351884,0.027572596,0.008949669,-0.0045057773,0.049166054,-0.028962651,-0.004334401,-0.040330637,-0.04036872,-0.0057315966,0.031266715,-0.024354525,-0.0003213312,0.042844158,0.047033366,0.06668455,0.021079326,0.012520015,-0.007602458,0.03307569,0.023554767,-0.014576535,0.009606613,-0.03338036,-0.022240879,-0.010872896,-0.0073358724,-0.035360713,-0.037531484,0.06881724,0.0541931,-0.06458995,0.009882719,-0.0038916778,-0.010644393,0.027134635,0.037150647,0.013624443,0.0030728783,-0.017261436,-0.007454884,-0.041054226,-0.023916561,0.12742805,0.010749124,-0.019708313,0.016928203,0.012529536,0.038350284,0.037836153,0.0156524,-0.005584022,0.01916562,-0.019594062,0.0063456963,0.005850608,0.0023968928,0.02915307,-0.023021596,-0.0072168605,0.02450686,-0.009482841,0.01832778,-0.027210802,-0.027363136,-0.013424504,-0.047833122,0.0028753192,0.044900678,0.02368806,-0.06485654,-0.014186177,0.048213962,-0.022012377,0.027382178,-0.049089886,-0.0014995455,0.056706626,0.004922318,-0.012815164,-0.0045200586,0.008673562,-0.0031085818,-0.027344095,0.02027957,-0.026696673,-0.019194184,-0.039492793,0.039607044,0.011824988,0.010634872,-0.020965075,0.0049794433,-0.007864283,0.035398796,0.026791882,0.0027348856,0.02441165,-0.004677154,-0.05335526,0.022545548,0.015938027,-0.017680356,-0.030009953,-0.007692907,-0.034637123,-0.033323236,0.064970784,0.010330203,0.034465745,-0.04562427,0.0144242,-0.012900853,0.058877397,0.00086818927,-0.0028753192,-0.029952828,-0.054535855,-0.001174644,0.0101683475,-0.030847795,-0.035893884,-0.00071109406,0.0064742286,-0.04314883,-0.037360106,-0.036350887,-0.021574415,-0.047452286,0.061505172,0.0066979704,0.008516467,-0.010368287,-0.026849007,0.0152334785,0.042310987,0.031266715,0.0574683,0.0033942095,-0.0019732115,0.010158827,0.00937811,0.036826935,-0.0048747133,-0.050537065,0.03079067,0.019917773,0.015014498,-0.021612499,0.04246332,-0.030466957,0.0020065347,-0.035265505,-0.007064526,-0.056287706,-0.031152464,-0.04665253,-0.021879084,0.0072073396,-0.041549314,-0.02039382,0.0017018652,-0.01742329,-0.06375211,-0.0060933917,-0.039911713,0.040216383,-0.01472887,0.02193621,-0.018680053,0.029533908,0.017547064,-0.015833298,0.013119834,-0.0066694077,-0.04985156,-0.034960832,0.0054745316,0.035341673,-0.0021398277,0.006498031,-0.037169687,-0.017404249,-0.02246938,0.0020458086,-0.0059267753,0.00039987883,0.013929112,-0.004291557,0.04055914,0.04029255,-0.031571385,-0.014586056,-0.050232396,0.04973731,-0.018527718,-0.01204397,0.0012377201,-0.00048556714,-0.012634266,0.015014498,0.017147185,0.0055887825,-0.005317436,-0.026810924,-0.03492275,0.062647685,0.03141905,0.040711474,-0.020984117,0.055983037,0.0050127665,-0.030238455,0.05202233,-0.01586186,0.0142813865,-0.031895097,-0.0009979119,0.01884191,-0.022602674,0.042501405,-0.01493833,-0.0114346305,0.03159043,0.009392392,0.00030615722,-0.018889515,0.013357857,-0.0015388194,0.008283204,-0.0077928766,0.024106981,-0.025820747,0.028353313,-0.03894058,-0.0047033364,0.030638335,-0.024811529,-0.016433116,0.02172675,-0.007221621,-0.005893452,0.02172675,-0.025820747,-0.012234388,-0.02144112,-0.13466395,-0.0016947245,-0.011996364,-0.017689878,-0.06443761,0.011805946,-0.032694854,0.021917168,0.029248279,-0.0028991215,-0.03926429,0.05365993,0.068245985,-0.0074501233,0.004272515,0.033437487,0.01803263,0.011691695,0.011263253,0.008716406,-0.005098455,-0.002089843,0.066303715,0.039492793,-0.012082053,0.0037345826,-0.047414202,0.017547064,-0.011824988,0.033113774,0.008597394,-0.027458346,0.023440516,0.036503226,0.054954775,0.038464535,0.0067074914,-0.037950404,0.04493876,-0.00515082,-0.024145065,0.017661314,-0.048252046,-0.028543731,-0.03225689,0.025592245,0.029781451,0.013929112,-0.0051746224,-0.042844158,-0.019517895,0.0374934,-0.016985329,0.03903579,-0.02801056,-0.040749557,-0.03884537,-0.024640152,-0.041016143,-0.0011526269,-0.027477387,-0.0155476695,-0.029743368,-0.06287619,-0.024468776,0.024697278,-0.07723374,0.03492275,-0.037417233,0.019241787,-0.016509283,-0.043186914,0.035341673,0.0012270091,-0.011796425,0.033018567,0.044062838,0.013196001,-0.06474228,-0.027248885,-0.03553209,0.023040637,-0.03800753,-0.012101095,0.0067312936,-0.012796123,-0.016204612,-0.020546155,-0.031038214,0.006788419,-0.06695114,-0.031876054,0.0078500025,-0.00038172957,-0.009563768,0.016528325,-0.0008467672,-0.061352838,-0.0074739256,-0.009230536,-0.0045676637,-0.03625568,0.007373956,-0.022602674,-0.0006605141,0.02852469,-0.020736573,-0.026734756,0.0073596747,0.011453672,-0.025973082,-0.009311464,-0.02285022,0.022488423,-0.029381573,0.023497641,0.031019172,0.055944953,0.02471632,0.0050222874,-0.009230536,-0.034351494,-0.02553512,-0.025001947,0.042272903,-0.03018133,0.025915956,0.018023109,0.032199766,0.040825725,0.010082659,-0.063485526,-0.004551002,0.024068898,0.0110157095,0.045471933,-0.033970658,0.0051746224,0.014671745,-0.032218806,0.016042758,-0.010672956,-0.0026230146,-0.04398667,-0.03541784,0.0017494699,0.026544336,0.009206734,-0.026620504,-0.012015406,0.0074120397,-0.016975809,-0.011767862,0.07643398,0.005488813,0.0015864241,-0.030809712,-0.027763015,0.002523045,0.029895702,0.013567317,-0.048061624,-0.03894058,-0.025020989,-0.026791882,0.07045484,-0.013024624,-0.011149002,-0.04078764,0.028772233,-0.02144112,-0.0026896612,-0.026106374,-0.042387154,0.047033366,0.016499761,-0.0027229844,0.0019279872,0.061048165,-0.005193664,0.052365083,0.015404856,-0.0018042151,0.010349245,0.030428873,0.005017527,0.035075083,0.027382178,0.023116805,-0.028981693,-0.011672653,-0.00617908,-0.042387154,0.03684598,0.034998916,0.016414074,0.005645908,0.026258709,0.00999697,0.044253256,0.00073727657,0.0037536244,-0.009254338,-0.048670966,-0.054231185,0.012082053,0.004562903,0.013776777,-0.013786298,0.010473017,-0.017109102,-0.012396243,0.01030164,0.014843121,-0.021193577,-0.030733544,0.0055602198,0.028181937,-0.0055030943,0.024259316,0.042844158,0.02707751,-0.0321236,0.0019517895,0.014252824,-0.0160618,0.026925175,0.0004656327,0.030028995,0.015918985,-0.0056221057,-0.043682,0.008116588,0.024068898,-0.038902495,-0.017670836,-0.06017224,-0.013072229,-0.07220669,0.025992123,0.012024928,0.007254944,0.045281515,-0.05758255]
22	2fa19c1f-711c-47d0-921d-068c8ea9bc4e	1d443963-4326-4dc6-b971-65732ab806bb	主诉头痛	现病史无	既往史无	\N	查体无	\N	头痛	t	\N	[-0.048482616,0.042922158,-0.044826426,-0.031496562,-0.021061184,-0.004798751,0.016700415,0.07605639,0.054842867,-0.029097186,0.0019721056,-0.020794587,-0.016300518,0.00095629867,0.03764734,0.022356085,0.025421953,-0.005122476,-0.03669521,-0.014224868,0.0018280955,0.0013317962,0.0032348721,-0.025231527,-0.028411651,0.011958792,-0.012054005,0.01315848,0.032277312,0.016471902,0.018566595,-0.046121325,0.05392882,0.0015305539,0.01022591,-0.030392088,-0.014510509,-0.009968833,-0.025936104,-0.0043393467,0.055033293,0.007217169,0.019328302,0.01716696,0.021841932,-0.0146818925,-0.02997315,-0.026621642,-1.7592147e-05,0.021137355,0.0056747133,0.007783688,0.04791134,-0.041513003,-0.026012275,-0.027440475,0.0136535885,-0.007574219,0.011882621,-0.02740239,-0.046197496,-0.0072314506,-0.021975232,-0.0028230746,0.046464093,0.06268844,0.0011443449,0.01587206,-0.021403952,-0.022660768,-0.02260364,-0.046464093,-0.010197345,-0.03642861,-0.047340058,0.017328823,-0.0069505717,-0.019042661,0.009497528,-0.009073828,0.039684907,0.016091049,-0.0016031541,0.019328302,-0.02003288,0.03635244,-0.012320602,0.058917996,-0.037114147,0.01266337,-0.031686988,-0.010311602,-0.047340058,-0.03720936,-0.01566259,-0.019690113,-0.027592817,0.018918885,0.028868675,0.00023416523,0.009540373,0.055833083,0.043531526,-0.011815972,0.0110447435,0.020756502,0.010568677,0.026621642,0.028773462,0.0101687815,0.01309183,0.024983972,0.011606502,-0.003620486,-0.0012472944,-0.0049701347,-0.009549895,-0.05210072,-0.0570899,-0.005408116,0.010254473,0.0023993754,-0.0010193775,0.0013758324,-0.007740842,0.04741623,0.009735561,0.002768327,-0.02839261,0.006931529,0.004477406,0.020223306,-0.01588158,-0.04372195,-0.005379552,-0.011111394,-0.011006659,0.050386883,-0.012777626,0.0041465396,0.011273256,0.06961997,0.029249528,-0.016214827,0.06245993,-0.04634984,0.03827575,0.033438914,0.039875332,-0.03562882,0.016509987,0.001409157,0.0154721625,0.032296356,0.057204157,0.00565091,-0.041589174,0.006474505,0.01752877,-0.00038025816,-0.00020203074,0.043341096,-0.018680852,0.025250569,-0.0026302678,-0.0048677805,-0.0038299554,-0.0010473464,0.0012794288,-0.0188808,0.0068553584,-0.009635587,-0.031953588,0.015824452,-0.007026742,0.042617477,0.04916815,0.009364229,-0.0005688995,-0.040827468,-0.053814564,-0.015110352,0.0045749997,0.009735561,-0.039875332,-0.0135774175,-0.008764385,0.019804368,0.023270132,-0.008688214,-0.022489384,-0.026716854,0.020185221,-0.0034610038,-0.014872319,-0.0041155955,-0.036809467,-0.025003014,-0.030925283,0.010035483,0.01581493,0.03147752,0.03341987,-0.0049272887,-0.005379552,-0.007945551,-0.030430174,-0.0013246551,-0.008064567,-0.056061596,-0.04791134,0.010578198,-0.027935585,0.00135917,0.010530592,-0.04844453,0.028563993,0.010654369,0.057204157,-0.056023512,-0.029839851,-0.008269276,0.034962326,-0.018214306,-0.018909363,-0.047644738,0.018852236,0.022927364,0.02618366,0.0015079408,-0.02060416,0.050691567,0.027211964,-0.017338343,0.058841825,-0.046959203,0.0055652177,0.0038680406,0.023727156,-0.0016138656,-0.010045004,0.0116731515,0.073999785,-0.012891882,-0.022584597,0.0073171426,0.022241829,0.00033860232,-0.024279393,-0.007612304,0.0069362894,-0.016290996,-0.014148697,0.013206086,0.035209883,0.0028659205,-0.00021913939,-0.005112955,-0.027954627,-0.011263735,0.010073568,-0.029458998,0.019975752,0.042008113,0.009759364,-0.010530592,-0.0042250906,0.00059062004,0.016367167,0.009073828,-0.0070505454,-0.016500466,-0.010397294,0.020223306,0.0062935995,0.022413213,0.022489384,-0.01502466,0.022832152,-0.004194146,-0.019290216,0.0075218515,0.028049842,0.034714773,0.026393129,-0.005646149,-0.0018840333,-0.07019125,0.0027445236,0.0002780526,0.02138491,-0.00072957197,0.0843209,-0.015119873,-0.0630693,0.04040853,0.004091792,-0.16940352,-0.02226087,0.024146095,-0.03145848,-0.021994274,0.02926857,-0.023993753,-0.00075932615,-0.020623203,-0.019823411,0.036790423,-0.044597913,-0.016405253,0.022089487,-0.02947804,0.0014531931,-0.031115709,-0.033343703,0.03298189,-0.027573774,-0.02576472,0.057204157,0.009545134,-0.06325972,-0.018976012,0.0064792656,0.042312793,-0.031229965,-0.007355228,-0.019423515,-0.010968573,0.01989958,-0.016700415,0.02675494,0.021442037,0.01810005,0.0059555923,0.036123928,0.0047701867,-0.008778667,0.022203743,0.045321535,-0.0074790055,0.011454161,0.019804368,0.017652547,0.0022625062,-0.05880374,-0.04120832,-0.0131775215,0.025269613,-0.0119111845,-0.014729499,0.02153725,-0.028202182,-0.0049653742,0.026678769,0.033153273,-0.011311341,-0.02854495,-0.025669508,-0.09871716,0.060746092,0.0071505196,-0.044293232,-0.025098229,-0.03448626,-0.004306022,0.015062746,-0.010330644,-0.0006373341,-0.026640683,0.012739541,0.0029230486,-0.03498137,-0.018776065,0.005846097,0.005198647,0.003777588,-0.09049073,-0.02304162,0.032658163,-0.016919404,0.00343482,-0.010701976,0.008964333,0.014548593,-0.007264775,0.020813629,0.27025345,0.06489739,0.010121175,-0.016509987,0.028773462,0.00908811,-0.04406472,0.04364578,0.011863578,-0.033724554,-0.027078666,-0.015348385,-0.008816753,0.011606502,0.010711498,0.052253064,-0.041665345,-0.0016840853,0.06992465,-0.011349427,0.039761078,-0.007045785,0.015824452,-0.008602522,-0.028506864,-0.025802806,-0.041741513,0.09719375,-0.015843494,-0.0023517688,-0.017071746,-0.0052986206,0.029249528,0.0017257412,-0.019556813,-0.030963369,0.0012818092,-0.07133381,-0.057470754,-0.013958271,0.009787928,-0.023822369,-0.0016650427,0.011977835,-0.05442393,0.037495002,0.017804889,0.061431628,-0.016643286,0.0016257672,-0.009245212,-0.028640164,0.0038823227,-0.01794771,-0.001666233,-0.023498645,-0.053814564,-0.032734334,-0.044178974,0.049015813,0.0048130327,0.012920446,-0.0104829855,0.018699894,0.0033015215,0.011397033,-0.030811027,0.0250411,0.03248678,0.041474916,0.047340058,0.010387772,-0.0037252207,-0.0038585193,0.039608736,0.014043963,-0.05872757,0.04699729,-0.008235951,0.048673045,0.011311341,-0.0083502075,-0.022051401,0.012482464,-0.0008456132,0.022565555,0.030658685,0.052672002,-0.003256295,-0.053281367,0.0035824007,-0.002846878,-0.065697186,0.06501165,-0.03835192,0.0046535507,0.0304873,-0.033134233,-0.028297395,0.017966751,0.0006539964,0.00257552,-0.019632984,-0.053738393,-0.00822643,-0.033362743,0.009845057,0.004327445,-0.022546511,-0.007831295,-0.05430967,0.0011723138,-0.005422398,-0.041931942,0.012501507,0.029782724,0.019937666,0.013244172,0.004063228,-0.019537771,-0.0071886047,0.024641205,-0.031058582,0.04349344,0.017500207,-0.014577158,-0.011387512,0.015196044,-0.055604573,0.05213881,0.022546511,-0.013939229,-0.08637752,-0.007859859,0.06139354,-0.012653849,0.051834125,0.030411132,0.0032634363,0.008969094,-0.013196564,-0.006431659,-0.041436832,0.010416336,0.00414892,-0.014082048,0.0048630196,-0.053624135,0.0017459741,0.027573774,0.008883402,-0.004536914,0.04916815,-0.028963888,-0.0043345857,-0.04029427,-0.04029427,-0.005731841,0.031229965,-0.024336522,-0.0003621081,0.04276982,0.04707346,0.06664932,0.021023098,0.012501507,-0.007645629,0.03303902,0.023498645,-0.014586679,0.009673672,-0.033457957,-0.022279914,-0.010920966,-0.0073028607,-0.035381265,-0.03755213,0.06878209,0.05415733,-0.06463079,0.009864098,-0.0038799422,-0.01058772,0.02719292,0.037114147,0.013615503,0.0031063342,-0.017271694,-0.00744092,-0.041094065,-0.02395567,0.12758583,0.010778147,-0.019690113,0.01694797,0.012530072,0.038313836,0.03791394,0.015653068,-0.0055033294,0.019233089,-0.019613942,0.0062983604,0.0058556185,0.002426749,0.029173357,-0.02304162,-0.007240972,0.024507906,-0.009459442,0.018338082,-0.027211964,-0.02740239,-0.013406034,-0.047835167,0.0028873435,0.044902597,0.023708114,-0.06478313,-0.014177262,0.048177935,-0.02203236,0.027383348,-0.049130067,-0.0014365308,0.056709047,0.0048749214,-0.012739541,-0.004494068,0.008692975,-0.0031063342,-0.027326219,0.020280434,-0.026735896,-0.019223567,-0.039456394,0.039646823,0.011844535,0.010597241,-0.021004057,0.0049701347,-0.007855098,0.03540031,0.026812067,0.0027064383,0.024431735,-0.0046868753,-0.053357538,0.02252747,0.015948229,-0.017633505,-0.03004932,-0.0076599107,-0.034638602,-0.03332466,0.06497356,0.010321123,0.034429133,-0.04562622,0.014434338,-0.012872839,0.058917996,0.0008277607,-0.0029182879,-0.029992193,-0.05457627,-0.001173504,0.010149739,-0.030925283,-0.03589542,-0.00071945554,0.0064983084,-0.04315067,-0.037285533,-0.03642861,-0.021575335,-0.047340058,0.06158397,0.0067791874,0.008493027,-0.0104068145,-0.026869196,0.015177001,0.04227471,0.031287093,0.057432666,0.0034395808,-0.0019780565,0.0101687815,0.009459442,0.036866594,-0.004836836,-0.050463054,0.030772941,0.019918624,0.014967532,-0.021556294,0.042465135,-0.030468259,0.001981627,-0.035286054,-0.007002939,-0.056328192,-0.031153794,-0.046616435,-0.02182289,0.007183844,-0.041474916,-0.020375649,0.0017209805,-0.017462121,-0.06367866,-0.006093652,-0.03991342,0.0402181,-0.0146818925,0.021937147,-0.018642766,0.029497083,0.017557334,-0.015853016,0.013110872,-0.006669692,-0.04973943,-0.035019454,0.0054557226,0.03536222,-0.0022137095,0.006560197,-0.03713319,-0.017424036,-0.022489384,0.0020625582,-0.00593655,0.00036538107,0.0138916215,-0.004315543,0.040560868,0.04029427,-0.031572733,-0.014577158,-0.05027263,0.04966326,-0.018518988,-0.012054005,0.001252055,-0.0005165322,-0.012615764,0.015034181,0.01715744,0.005593782,-0.0052700564,-0.026831111,-0.03498137,0.06265036,0.03132518,0.040751297,-0.021004057,0.055985425,0.004998699,-0.030182619,0.05202455,-0.01587206,0.014177262,-0.031972628,-0.00096701016,0.018871278,-0.022622682,0.042541306,-0.014967532,-0.011444639,0.03155369,0.009449921,0.000279094,-0.018871278,0.01337747,-0.0015115113,0.008307361,-0.0077503636,0.024127053,-0.025783764,0.02833548,-0.0389232,-0.0046916357,0.030601557,-0.024774503,-0.016405253,0.021708634,-0.007240972,-0.0058556185,0.021765763,-0.025802806,-0.012215868,-0.021442037,-0.13474588,-0.001667423,-0.011977835,-0.01773824,-0.06451654,0.011825493,-0.032677207,0.021860976,0.029230487,-0.0029492322,-0.039227884,0.053662222,0.06817273,-0.0074742446,0.004272697,0.03341987,0.017985795,0.011654109,0.011254213,0.008750103,-0.00515104,-0.0020994535,0.06626847,0.039456394,-0.012139697,0.0037490241,-0.04741623,0.017547812,-0.011863578,0.03311519,0.008621565,-0.027421433,0.02340343,0.03648574,0.054995205,0.038447134,0.0067363414,-0.037952024,0.044902597,-0.005112955,-0.024222266,0.017662069,-0.048330277,-0.028583035,-0.03225827,0.025631422,0.029858893,0.013939229,-0.005179604,-0.042922158,-0.019471122,0.037456915,-0.017043183,0.039037455,-0.02797367,-0.04071321,-0.038885117,-0.024660246,-0.040979806,-0.0011574368,-0.027440475,-0.015519769,-0.029706553,-0.06287887,-0.024488863,0.024717376,-0.07723703,0.03498137,-0.037399787,0.019233089,-0.016529031,-0.04318876,0.035324138,0.0012401533,-0.011815972,0.033019975,0.044026636,0.01315848,-0.06470697,-0.027231006,-0.035590734,0.023022577,-0.03804724,-0.012082569,0.0067220596,-0.012825233,-0.016176742,-0.020547032,-0.031039538,0.0068077515,-0.06687783,-0.031782202,0.007817012,-0.00031569164,-0.009502288,0.016538551,-0.0008634657,-0.06131737,-0.007488527,-0.009264255,-0.0044321795,-0.036295313,0.00736951,-0.022622682,-0.0006599472,0.028525908,-0.020775544,-0.026735896,0.0072981003,0.011473204,-0.025993234,-0.009321383,-0.022946408,0.022508426,-0.029344741,0.023498645,0.031020496,0.056023512,0.024736417,0.005065348,-0.0092166485,-0.034372006,-0.025479082,-0.025003014,0.04235088,-0.03025879,0.025955148,0.017985795,0.032105926,0.04086555,0.010035483,-0.06345015,-0.004591662,0.024069924,0.0110447435,0.04551196,-0.033953067,0.005179604,0.01466285,-0.032277312,0.016072007,-0.010635327,-0.0026136052,-0.043950465,-0.035457436,0.0017352626,0.026488343,0.009240451,-0.026640683,-0.01209209,0.00736951,-0.017014619,-0.011768365,0.07643724,0.0055176113,0.0015115113,-0.030791985,-0.027726116,0.0024803067,0.029935064,0.013605982,-0.048101764,-0.0389232,-0.025060143,-0.026773982,0.070457846,-0.0130156595,-0.011168521,-0.04086555,0.028792504,-0.021480123,-0.0026873956,-0.02605036,-0.04242705,0.047035374,0.016529031,-0.0026992974,0.0018399972,0.06108886,-0.005193886,0.05236732,0.015424556,-0.001831666,0.010340165,0.030411132,0.00507963,0.035133712,0.027364304,0.023117792,-0.02904006,-0.011682673,-0.0061841044,-0.042312793,0.03684755,0.035038497,0.01639573,0.0056794737,0.02625983,0.009968833,0.04421706,0.0007117195,0.0037395027,-0.009254734,-0.048673045,-0.0542335,0.012054005,0.004520252,0.0137297595,-0.013720238,0.010473464,-0.017081268,-0.012368209,0.010330644,0.0148437545,-0.021137355,-0.030715814,0.005536654,0.028145054,-0.005479526,0.024260351,0.042884074,0.02711675,-0.032086886,0.0018935547,0.014186783,-0.016052963,0.026869196,0.0004808272,0.03004932,0.015948229,-0.0055985427,-0.043683864,0.008107414,0.024088968,-0.038904157,-0.017700154,-0.06009864,-0.013101351,-0.0721336,0.026012275,0.011977835,0.0073028607,0.045283448,-0.05766118]
24	dd9f8599-a39a-43e5-a007-9fee6c122b96	0d3225c5-f692-4787-96c7-d93d0754d3ba	无	患者未提供明显症状描述。	\N	\N	\N	\N	\N	f	\N	\N
25	e2deda51-b6a5-4816-a373-2999575a933e	86cbe7b9-0d68-4db4-b1ef-b084fb4ceab7	头疼	患者一直觉得头脑像要裂开一样	无	\N	体温正常	\N	脑部恶性肿瘤	t	\N	[0.008788242,0.042947758,-0.030758848,-0.013230125,-0.029440612,-0.039088573,0.055480555,0.029459717,0.018522177,-0.030090177,0.026976082,0.001945115,-0.015627788,0.010842017,0.02970808,0.010937541,0.028408948,0.019544287,-0.019248161,0.015398529,0.0048860717,0.011462925,-0.04397942,0.003997695,-0.044094052,-0.0012848028,-0.029994654,-0.023766464,0.05200347,0.01347849,0.04092264,-0.06789873,-0.008831228,-0.030892583,0.059874676,-0.03307054,-0.03444609,0.03962351,-0.00075643364,-0.0025194553,0.051010016,0.052500196,0.034828186,0.02065237,-0.0011445014,0.0036179856,-0.013144154,-0.025218435,0.010927988,0.0114056105,0.021435669,-0.010297528,0.018073212,0.027014293,-0.025791582,-0.0004907565,-0.0044586,-0.036547627,-0.0017146625,-0.003212007,-0.035420436,-0.0014042082,-0.050742548,-0.0119596515,0.01493046,0.055900864,0.027167132,0.031714093,0.00059344515,-0.014433733,-0.0047666663,-0.012179358,-0.029421506,-0.060294986,-0.03358637,0.012666532,0.030414961,-0.036356576,-0.01936279,0.026670406,0.046233796,-0.005177421,0.0093757175,-0.0021946726,-0.03156125,0.022027921,0.03906947,0.052385565,-0.010393051,-0.03649031,0.0018292918,0.04122832,-0.015923914,-0.02881015,-0.015885703,-0.05513667,-0.036337472,-0.021282831,0.015159718,-0.0018245155,0.0085446555,0.013726853,0.01900935,-0.03165678,-0.013631328,0.0134116225,0.012551903,0.05043687,0.026422042,0.0065147625,0.037063457,0.027262656,-0.0054210084,-0.023002269,0.009203773,0.02464529,-0.01834068,-0.055633396,-0.022677487,-0.020384902,0.02277301,0.020499531,-0.030071072,-0.008047928,-0.026383832,0.053149763,0.027988642,0.025715161,0.03687241,0.0018603372,-0.01347849,0.03224903,-0.0070449226,-0.0024812457,0.01654482,-0.040999062,-0.012064729,0.03966172,-0.020136539,-0.017232597,4.182923e-05,0.07779505,-0.005526085,-0.012637875,0.018808749,-0.06805156,0.03973814,0.05479278,0.03809512,-0.024320506,-0.01477762,0.018273814,-0.0017600366,0.011625316,-0.014376419,0.030357646,-0.022868535,0.019773545,0.008793019,0.029459717,-0.014223579,-0.014882698,0.00983901,-0.0060562454,-9.865877e-05,0.0036824646,0.043903,0.076572336,-0.024148561,-0.01602899,0.021607613,-0.027090713,-0.0058174343,0.0064335666,-0.0010842016,0.02966987,0.042259984,0.006218637,-0.04302418,-0.031465728,-0.030051969,-0.0146343345,0.025333064,0.010584101,-0.022753906,0.0026770707,-0.016468402,0.02124462,0.02046132,0.013287441,-0.010822912,-0.043177016,0.028752837,0.025810685,0.042527452,-0.03868737,-0.011023513,-0.03719719,-0.043864794,0.00257677,-0.012255778,0.021053571,0.012656979,0.036509417,0.0037708248,0.016640346,-0.029593451,-0.018130526,-0.008143453,-0.018483967,-0.014949565,-0.046654105,-0.021932397,-0.00406695,-0.0037111219,-0.01814008,0.012485036,0.025715161,0.016258249,-0.036375683,-0.0032191714,0.016821843,-0.009748262,0.014194922,0.025409484,0.019496525,-0.0035964926,0.014577019,0.032344554,-0.008659285,-0.010106479,0.026039945,0.019229056,-0.015522711,0.07687802,-0.001157039,-0.009657514,0.0010209167,0.00085673423,-0.008578089,0.0153030045,-0.026192782,0.04084622,0.0008674807,0.0028920004,0.04145758,0.0041003837,-0.011864128,-0.01453881,-0.054639943,-0.010116031,0.03771302,-0.028045956,-0.029383298,0.038840212,-0.017251702,-0.0117972605,-0.013774615,0.030892583,-0.027128922,0.026383832,0.012217567,0.007364929,0.016000332,0.020556845,-0.00226751,-0.0025457246,0.010106479,0.03209619,-0.037884966,-0.03249739,-0.009046158,-0.031962454,0.000634043,0.00778046,-0.00795718,0.01407074,0.010498129,0.026039945,0.0076801595,0.015876152,-0.010708283,-0.007909418,-0.016095856,0.048373543,-0.024759918,-0.058766596,-0.03832438,-0.0057983296,0.026918769,-0.00983901,-0.0454696,0.08375577,-0.034541614,-0.016449297,0.043826584,-0.007704041,-0.17056832,-0.05181242,0.044972874,-0.0014328656,-0.003278874,0.015589578,-0.021282831,-0.014882698,-0.020212958,0.021473879,0.040311284,-0.041534,-0.0037278386,0.009323179,-0.04122832,-0.0235181,-0.03358637,-0.036337472,0.037865862,-0.0454696,-0.04088443,0.0036514192,0.011396058,-0.023881093,-0.0013743569,0.044667196,0.038744684,-0.015866598,-0.012083833,-0.018589044,-0.056244753,-0.019152638,-0.021626718,0.025180224,0.029383298,-0.006118336,0.022333598,-0.00080897205,-0.00035523126,-0.020289376,0.018503072,0.104465455,-0.00991543,0.069121435,-0.014032531,0.016200934,0.0031833497,-0.016124515,0.014204474,-0.0533026,0.038553637,-0.040769804,-0.041610416,-0.024855442,-0.010106479,0.007532097,0.0029517033,0.0199837,0.024836337,-0.029364193,-0.009404374,-0.09651783,0.0012776385,0.007961957,0.0069159647,-0.016449297,-0.01105217,-0.02135925,0.011644421,-0.014739411,-0.007756579,-0.02837074,0.023785569,0.0016633181,-0.0005441904,-0.04145758,0.009203773,0.00087703316,-0.008836005,-0.08536058,-0.035210285,0.04619559,0.0048621907,0.040349495,-0.015159718,-0.04298597,0.018655911,-0.0061899796,0.031752303,0.25218436,0.02426319,-0.02433961,-0.013956111,0.037884966,-0.009337507,-0.005826987,0.038935736,0.033892047,-0.0025839342,-0.011739946,0.004802488,-0.02046132,0.025791582,-0.009542885,0.038419902,-0.01951563,0.018846959,0.05479278,-0.015513158,0.021015363,-0.04279492,0.07515858,-0.008367935,-0.015197928,-0.03373921,-0.0442851,0.054601733,-0.02053774,0.021531194,-0.021913292,0.007446125,0.032592915,-0.016926918,-0.020442216,-0.014089845,-0.0020024297,-0.05635938,-0.02695698,0.020041013,0.024855442,-0.020021908,-0.010918436,0.03691062,-0.021454774,0.018493518,0.01963981,0.045431394,-0.011768603,-0.021855976,0.027224446,-0.03872558,0.0160672,-0.013096391,-0.008511222,-0.01026887,-0.012551903,-0.010068269,-0.03161857,0.031733196,0.012914895,0.018980693,-0.04401763,0.03377742,0.030911688,0.03398757,-0.04707441,0.021225516,0.032077085,0.059912886,0.06224368,-0.002293779,-0.00654342,-0.033643685,0.046921574,0.0009886773,-0.044094052,0.069465324,0.029325983,0.01347849,0.026498461,-0.005674148,-0.05192705,-0.0067583495,0.0130199725,0.02386199,0.04738009,0.0380187,-0.020251168,-0.021569403,-0.0066246153,0.0016322727,-0.065032996,-0.0025385602,0.0021958665,0.021569403,-0.0055833994,-0.0136886425,-0.0011904725,-0.016220039,-0.01744275,-0.021015363,-0.02053774,0.0013683867,0.0050293584,-0.009829458,-0.035439543,0.0052060783,-0.061746955,0.029440612,-0.029058514,-0.008621075,-0.03249739,0.0060849027,-0.0069159647,0.018627252,-0.045354974,0.017872611,-0.0043057613,0.009413927,-0.015618235,0.025256645,-0.033758312,0.06518583,0.023384366,-0.03962351,0.037273612,0.012676084,-0.05043687,0.021129992,0.008998396,0.0013516699,-0.09468376,0.010832464,0.043826584,-0.0052299593,0.034598928,0.010584101,0.061708745,0.055671606,0.008697494,-0.0064192377,0.006662825,-0.042947758,0.0045254673,-0.0074986634,-0.004506362,-0.055404138,-0.0015164494,0.03910768,0.04867922,0.047494717,0.021607613,-0.059989307,0.013526252,-0.0486028,-0.030797059,0.012208015,0.00079046417,-0.03465624,-0.012571008,0.044055842,0.04306239,0.070802666,0.006046693,0.015016432,0.010641416,-0.02881015,0.053111553,0.01254235,-0.018789645,-0.0134116225,-0.019429658,-0.019267267,-0.038076017,0.025180224,-0.035687905,0.029727185,0.011195457,0.002423931,0.010211555,-0.015131061,-0.0073171672,0.04871743,0.07042057,0.013067734,0.052538406,-0.010822912,0.003866349,-0.03522939,-0.032898594,0.09865757,0.013382965,-0.026937874,0.044055842,-0.012265329,0.037923176,0.028351635,-0.00742702,-0.007966733,0.015217033,0.030892583,-0.011157247,-0.02218076,-0.010373947,0.012895791,0.017003339,-0.005311155,0.03746466,0.06461269,-0.00083165907,-0.014940012,0.0063666995,0.0030400632,-0.09162698,-0.01332565,-0.0142426845,0.01375551,-0.0364521,0.012036071,0.014787173,-0.03735003,0.022257179,-0.062855035,-0.008726152,-0.014280894,-0.008850333,-0.03989098,-0.03992919,0.0074556773,-0.008520775,-0.021645823,0.007555978,0.0059081824,0.013230125,-0.028523577,-0.012427721,0.0147489635,0.017767534,-0.020174747,0.007169104,-0.048449963,0.017289912,0.10484755,0.0070210416,0.036987036,0.039394252,-0.031962454,0.044781826,-0.009867668,0.031179156,-0.025333064,-3.6120153e-05,-0.040464126,-0.052461985,0.05391396,0.014901802,0.019401,0.0077709076,-0.0020406395,-0.014806278,0.041534,0.011109484,-0.012045624,-0.034159515,-0.05334081,-0.01414716,0.037617497,-0.014557915,-0.058078818,-0.020805208,-0.00018657104,-0.06392491,-0.046310216,0.004059786,-0.028676417,-0.03559238,0.08100467,0.044514358,-0.030414961,-0.0011062917,-0.012790713,0.0044920337,0.03500013,0.010163793,0.005306379,0.043368068,0.0006901636,0.032975014,-0.020174747,0.01885651,0.0040717265,-0.048411753,0.046539474,-0.039088573,0.043482695,-0.03777034,0.014691649,-0.00019254132,0.007933299,-0.022581963,-0.0341022,-0.043291647,-0.049481627,0.0038759015,-0.021473879,0.008969739,-0.038228855,-0.0061995317,0.0012310704,0.030969001,-0.087347485,-0.013449832,0.01269519,-0.04745651,-0.03156125,0.036432996,-0.00023149735,0.000980916,0.039012153,-0.019229056,-0.008477788,-0.013468937,0.021340145,-0.018627252,-0.010536338,-0.022257179,-0.050895385,-0.020671474,-0.03534402,0.020021908,-0.024053037,0.023957513,-0.0063858046,-0.014061188,-0.005072344,-0.008549431,0.0049529388,0.05494562,-0.05949258,-0.026880559,-0.0431006,0.052882295,0.026479356,-0.023346158,0.042030726,-0.0043535233,-0.0005824002,0.012895791,0.023651835,0.004043069,0.035802536,-0.008788242,-0.025562322,0.058957644,0.039164994,0.027988642,-0.027854908,-0.0021898963,-0.004219789,-0.01407074,0.039164994,0.043520905,0.025294853,-0.00051165244,0.020977153,-0.012208015,-0.0019570556,0.06304609,-0.024358716,-0.025638742,0.038782895,0.011166799,-0.011109484,-0.043635532,-0.013344755,-0.04569886,0.007532097,0.0274346,-0.001943921,-0.008769138,0.040731594,-0.059989307,-0.049978353,0.0110139605,-0.01916219,-0.038037807,0.008157781,0.0037493317,0.0032191714,0.0035296257,-0.017509617,0.011290981,-0.04092264,-0.14412718,0.027224446,0.0027224447,-0.03287949,-0.056091912,-0.019697126,-0.027186237,0.006658049,0.00519175,-0.025581427,0.010192451,0.016124515,0.03433146,-0.02539038,0.02751102,0.06136486,0.013287441,-0.0097912485,-0.008043152,0.0055213086,0.01418537,-0.0077183694,-0.008750033,0.030319436,-0.030281227,-0.015981227,-0.024530658,0.029478822,0.00025164703,0.0399674,0.006839545,0.0021898963,0.010870674,0.032650232,0.035248496,0.012523245,-0.006853874,-0.03966172,0.0055356375,-0.023995724,0.012255778,0.01857949,-0.005397127,-0.015771074,-0.0501694,0.010364395,-0.00107047,0.016181828,0.018569939,-0.043750163,0.0028108046,0.07481469,-0.014682096,0.016879156,-0.025103806,-0.0005919526,-0.034388773,-0.033376217,0.04298597,0.0075225444,-0.010030059,-0.035439543,-0.078941345,-0.035878956,-0.016630793,-0.0013552521,-0.04592812,0.0014782397,0.015732864,0.003883066,-0.07470006,-0.0050341347,0.03165678,-0.027109817,0.00453502,0.020155642,0.011290981,-0.034121305,-0.0066723777,-0.0031570806,-0.0340831,-0.010039612,-0.014787173,-0.06442164,0.017347226,0.013583566,-0.018923378,0.006352371,-0.008726152,0.025887106,-0.046042748,-0.028943885,-0.001287191,-0.018130526,-0.028408948,0.039814558,0.016306011,-0.03954709,0.005349365,-0.0364521,0.0024394537,-0.037273612,0.006481329,-0.020136539,-0.013602671,0.0352676,0.015713759,-0.040311284,0.03989098,0.019420106,-0.03989098,-0.021664929,0.0030161822,-0.0025600533,-0.02539038,-0.014042083,0.04394121,0.024683498,-0.004929058,0.00043344183,-0.046348426,-0.012895791,0.005631162,-0.024511555,0.031886037,-0.002973196,0.050589707,-0.0042723278,0.03198156,0.020002805,0.010020507,-0.04462899,-0.022199865,0.039470673,0.035401333,0.05815524,-0.03597448,0.005631162,0.02288764,-0.014510153,0.04000561,-0.032898594,-0.0099058775,-0.02132104,-0.051583163,0.008367935,0.015360319,-0.004386957,-0.029517032,0.0011045006,0.055480555,-0.0024310953,-0.019620707,0.009557214,-0.023537206,0.031465728,0.011892784,-0.04397942,0.04887027,0.048106074,0.012093386,-0.04887027,-0.047838606,0.007866432,-0.008773914,0.024779022,-0.0077470266,-0.012064729,-0.03750287,0.0064096856,-0.03989098,0.0046186033,-0.021798663,-0.046424847,0.0021337757,-0.032994118,0.0017313793,-0.0045087505,0.052844085,-0.023002269,0.050054774,0.011806813,-0.03899305,0.002339153,0.005635938,-0.019391447,-0.037178088,0.036031794,0.0049481625,-0.012036071,-0.032955907,-0.016391983,0.01963981,0.0037970939,0.036929723,-0.035363123,-0.010526786,-0.013115496,-0.035878956,0.020996258,0.021817766,0.015217033,0.022276284,-0.049863722,-0.0356497,0.008119572,-0.0013003255,-0.0011445014,-0.008157781,0.031886037,0.005024582,-0.0036347024,-0.014137607,0.013287441,0.009366165,-0.04699799,-0.013564461,0.0039284397,0.017891714,-0.010784701,-0.016181828,-0.0074365726,-0.034618035,-0.0056407144,0.01811142,-0.014615229,-0.032038875,0.013564461,0.025466798,-0.011061722,-0.012962658,-0.006266399,-0.012953105,-0.0019642198,-0.0019104874,0.0018507848,-0.045966327,0.025313959,-0.04264208,0.024779022,-0.001965414,0.004785771,0.050016563,-0.03425504]
26	2044ee86-9ade-495b-8a55-043af39c2916	0e5091ae-ff55-46fb-b55a-162deffc3974	无	患者未提供明显症状描述。	\N	\N	\N	\N	\N	f	\N	\N
27	9e6ef4ca-85e9-4125-a86c-f43b44e6abeb	3ccf28cf-8189-4886-8a04-27a2d37bb00d	头疼	患者一直觉得头脑像要裂开一样	无	\N	体温正常	\N	脑部恶性肿瘤	t	\N	[0.008788242,0.042947758,-0.030758848,-0.013230125,-0.029440612,-0.039088573,0.055480555,0.029459717,0.018522177,-0.030090177,0.026976082,0.001945115,-0.015627788,0.010842017,0.02970808,0.010937541,0.028408948,0.019544287,-0.019248161,0.015398529,0.0048860717,0.011462925,-0.04397942,0.003997695,-0.044094052,-0.0012848028,-0.029994654,-0.023766464,0.05200347,0.01347849,0.04092264,-0.06789873,-0.008831228,-0.030892583,0.059874676,-0.03307054,-0.03444609,0.03962351,-0.00075643364,-0.0025194553,0.051010016,0.052500196,0.034828186,0.02065237,-0.0011445014,0.0036179856,-0.013144154,-0.025218435,0.010927988,0.0114056105,0.021435669,-0.010297528,0.018073212,0.027014293,-0.025791582,-0.0004907565,-0.0044586,-0.036547627,-0.0017146625,-0.003212007,-0.035420436,-0.0014042082,-0.050742548,-0.0119596515,0.01493046,0.055900864,0.027167132,0.031714093,0.00059344515,-0.014433733,-0.0047666663,-0.012179358,-0.029421506,-0.060294986,-0.03358637,0.012666532,0.030414961,-0.036356576,-0.01936279,0.026670406,0.046233796,-0.005177421,0.0093757175,-0.0021946726,-0.03156125,0.022027921,0.03906947,0.052385565,-0.010393051,-0.03649031,0.0018292918,0.04122832,-0.015923914,-0.02881015,-0.015885703,-0.05513667,-0.036337472,-0.021282831,0.015159718,-0.0018245155,0.0085446555,0.013726853,0.01900935,-0.03165678,-0.013631328,0.0134116225,0.012551903,0.05043687,0.026422042,0.0065147625,0.037063457,0.027262656,-0.0054210084,-0.023002269,0.009203773,0.02464529,-0.01834068,-0.055633396,-0.022677487,-0.020384902,0.02277301,0.020499531,-0.030071072,-0.008047928,-0.026383832,0.053149763,0.027988642,0.025715161,0.03687241,0.0018603372,-0.01347849,0.03224903,-0.0070449226,-0.0024812457,0.01654482,-0.040999062,-0.012064729,0.03966172,-0.020136539,-0.017232597,4.182923e-05,0.07779505,-0.005526085,-0.012637875,0.018808749,-0.06805156,0.03973814,0.05479278,0.03809512,-0.024320506,-0.01477762,0.018273814,-0.0017600366,0.011625316,-0.014376419,0.030357646,-0.022868535,0.019773545,0.008793019,0.029459717,-0.014223579,-0.014882698,0.00983901,-0.0060562454,-9.865877e-05,0.0036824646,0.043903,0.076572336,-0.024148561,-0.01602899,0.021607613,-0.027090713,-0.0058174343,0.0064335666,-0.0010842016,0.02966987,0.042259984,0.006218637,-0.04302418,-0.031465728,-0.030051969,-0.0146343345,0.025333064,0.010584101,-0.022753906,0.0026770707,-0.016468402,0.02124462,0.02046132,0.013287441,-0.010822912,-0.043177016,0.028752837,0.025810685,0.042527452,-0.03868737,-0.011023513,-0.03719719,-0.043864794,0.00257677,-0.012255778,0.021053571,0.012656979,0.036509417,0.0037708248,0.016640346,-0.029593451,-0.018130526,-0.008143453,-0.018483967,-0.014949565,-0.046654105,-0.021932397,-0.00406695,-0.0037111219,-0.01814008,0.012485036,0.025715161,0.016258249,-0.036375683,-0.0032191714,0.016821843,-0.009748262,0.014194922,0.025409484,0.019496525,-0.0035964926,0.014577019,0.032344554,-0.008659285,-0.010106479,0.026039945,0.019229056,-0.015522711,0.07687802,-0.001157039,-0.009657514,0.0010209167,0.00085673423,-0.008578089,0.0153030045,-0.026192782,0.04084622,0.0008674807,0.0028920004,0.04145758,0.0041003837,-0.011864128,-0.01453881,-0.054639943,-0.010116031,0.03771302,-0.028045956,-0.029383298,0.038840212,-0.017251702,-0.0117972605,-0.013774615,0.030892583,-0.027128922,0.026383832,0.012217567,0.007364929,0.016000332,0.020556845,-0.00226751,-0.0025457246,0.010106479,0.03209619,-0.037884966,-0.03249739,-0.009046158,-0.031962454,0.000634043,0.00778046,-0.00795718,0.01407074,0.010498129,0.026039945,0.0076801595,0.015876152,-0.010708283,-0.007909418,-0.016095856,0.048373543,-0.024759918,-0.058766596,-0.03832438,-0.0057983296,0.026918769,-0.00983901,-0.0454696,0.08375577,-0.034541614,-0.016449297,0.043826584,-0.007704041,-0.17056832,-0.05181242,0.044972874,-0.0014328656,-0.003278874,0.015589578,-0.021282831,-0.014882698,-0.020212958,0.021473879,0.040311284,-0.041534,-0.0037278386,0.009323179,-0.04122832,-0.0235181,-0.03358637,-0.036337472,0.037865862,-0.0454696,-0.04088443,0.0036514192,0.011396058,-0.023881093,-0.0013743569,0.044667196,0.038744684,-0.015866598,-0.012083833,-0.018589044,-0.056244753,-0.019152638,-0.021626718,0.025180224,0.029383298,-0.006118336,0.022333598,-0.00080897205,-0.00035523126,-0.020289376,0.018503072,0.104465455,-0.00991543,0.069121435,-0.014032531,0.016200934,0.0031833497,-0.016124515,0.014204474,-0.0533026,0.038553637,-0.040769804,-0.041610416,-0.024855442,-0.010106479,0.007532097,0.0029517033,0.0199837,0.024836337,-0.029364193,-0.009404374,-0.09651783,0.0012776385,0.007961957,0.0069159647,-0.016449297,-0.01105217,-0.02135925,0.011644421,-0.014739411,-0.007756579,-0.02837074,0.023785569,0.0016633181,-0.0005441904,-0.04145758,0.009203773,0.00087703316,-0.008836005,-0.08536058,-0.035210285,0.04619559,0.0048621907,0.040349495,-0.015159718,-0.04298597,0.018655911,-0.0061899796,0.031752303,0.25218436,0.02426319,-0.02433961,-0.013956111,0.037884966,-0.009337507,-0.005826987,0.038935736,0.033892047,-0.0025839342,-0.011739946,0.004802488,-0.02046132,0.025791582,-0.009542885,0.038419902,-0.01951563,0.018846959,0.05479278,-0.015513158,0.021015363,-0.04279492,0.07515858,-0.008367935,-0.015197928,-0.03373921,-0.0442851,0.054601733,-0.02053774,0.021531194,-0.021913292,0.007446125,0.032592915,-0.016926918,-0.020442216,-0.014089845,-0.0020024297,-0.05635938,-0.02695698,0.020041013,0.024855442,-0.020021908,-0.010918436,0.03691062,-0.021454774,0.018493518,0.01963981,0.045431394,-0.011768603,-0.021855976,0.027224446,-0.03872558,0.0160672,-0.013096391,-0.008511222,-0.01026887,-0.012551903,-0.010068269,-0.03161857,0.031733196,0.012914895,0.018980693,-0.04401763,0.03377742,0.030911688,0.03398757,-0.04707441,0.021225516,0.032077085,0.059912886,0.06224368,-0.002293779,-0.00654342,-0.033643685,0.046921574,0.0009886773,-0.044094052,0.069465324,0.029325983,0.01347849,0.026498461,-0.005674148,-0.05192705,-0.0067583495,0.0130199725,0.02386199,0.04738009,0.0380187,-0.020251168,-0.021569403,-0.0066246153,0.0016322727,-0.065032996,-0.0025385602,0.0021958665,0.021569403,-0.0055833994,-0.0136886425,-0.0011904725,-0.016220039,-0.01744275,-0.021015363,-0.02053774,0.0013683867,0.0050293584,-0.009829458,-0.035439543,0.0052060783,-0.061746955,0.029440612,-0.029058514,-0.008621075,-0.03249739,0.0060849027,-0.0069159647,0.018627252,-0.045354974,0.017872611,-0.0043057613,0.009413927,-0.015618235,0.025256645,-0.033758312,0.06518583,0.023384366,-0.03962351,0.037273612,0.012676084,-0.05043687,0.021129992,0.008998396,0.0013516699,-0.09468376,0.010832464,0.043826584,-0.0052299593,0.034598928,0.010584101,0.061708745,0.055671606,0.008697494,-0.0064192377,0.006662825,-0.042947758,0.0045254673,-0.0074986634,-0.004506362,-0.055404138,-0.0015164494,0.03910768,0.04867922,0.047494717,0.021607613,-0.059989307,0.013526252,-0.0486028,-0.030797059,0.012208015,0.00079046417,-0.03465624,-0.012571008,0.044055842,0.04306239,0.070802666,0.006046693,0.015016432,0.010641416,-0.02881015,0.053111553,0.01254235,-0.018789645,-0.0134116225,-0.019429658,-0.019267267,-0.038076017,0.025180224,-0.035687905,0.029727185,0.011195457,0.002423931,0.010211555,-0.015131061,-0.0073171672,0.04871743,0.07042057,0.013067734,0.052538406,-0.010822912,0.003866349,-0.03522939,-0.032898594,0.09865757,0.013382965,-0.026937874,0.044055842,-0.012265329,0.037923176,0.028351635,-0.00742702,-0.007966733,0.015217033,0.030892583,-0.011157247,-0.02218076,-0.010373947,0.012895791,0.017003339,-0.005311155,0.03746466,0.06461269,-0.00083165907,-0.014940012,0.0063666995,0.0030400632,-0.09162698,-0.01332565,-0.0142426845,0.01375551,-0.0364521,0.012036071,0.014787173,-0.03735003,0.022257179,-0.062855035,-0.008726152,-0.014280894,-0.008850333,-0.03989098,-0.03992919,0.0074556773,-0.008520775,-0.021645823,0.007555978,0.0059081824,0.013230125,-0.028523577,-0.012427721,0.0147489635,0.017767534,-0.020174747,0.007169104,-0.048449963,0.017289912,0.10484755,0.0070210416,0.036987036,0.039394252,-0.031962454,0.044781826,-0.009867668,0.031179156,-0.025333064,-3.6120153e-05,-0.040464126,-0.052461985,0.05391396,0.014901802,0.019401,0.0077709076,-0.0020406395,-0.014806278,0.041534,0.011109484,-0.012045624,-0.034159515,-0.05334081,-0.01414716,0.037617497,-0.014557915,-0.058078818,-0.020805208,-0.00018657104,-0.06392491,-0.046310216,0.004059786,-0.028676417,-0.03559238,0.08100467,0.044514358,-0.030414961,-0.0011062917,-0.012790713,0.0044920337,0.03500013,0.010163793,0.005306379,0.043368068,0.0006901636,0.032975014,-0.020174747,0.01885651,0.0040717265,-0.048411753,0.046539474,-0.039088573,0.043482695,-0.03777034,0.014691649,-0.00019254132,0.007933299,-0.022581963,-0.0341022,-0.043291647,-0.049481627,0.0038759015,-0.021473879,0.008969739,-0.038228855,-0.0061995317,0.0012310704,0.030969001,-0.087347485,-0.013449832,0.01269519,-0.04745651,-0.03156125,0.036432996,-0.00023149735,0.000980916,0.039012153,-0.019229056,-0.008477788,-0.013468937,0.021340145,-0.018627252,-0.010536338,-0.022257179,-0.050895385,-0.020671474,-0.03534402,0.020021908,-0.024053037,0.023957513,-0.0063858046,-0.014061188,-0.005072344,-0.008549431,0.0049529388,0.05494562,-0.05949258,-0.026880559,-0.0431006,0.052882295,0.026479356,-0.023346158,0.042030726,-0.0043535233,-0.0005824002,0.012895791,0.023651835,0.004043069,0.035802536,-0.008788242,-0.025562322,0.058957644,0.039164994,0.027988642,-0.027854908,-0.0021898963,-0.004219789,-0.01407074,0.039164994,0.043520905,0.025294853,-0.00051165244,0.020977153,-0.012208015,-0.0019570556,0.06304609,-0.024358716,-0.025638742,0.038782895,0.011166799,-0.011109484,-0.043635532,-0.013344755,-0.04569886,0.007532097,0.0274346,-0.001943921,-0.008769138,0.040731594,-0.059989307,-0.049978353,0.0110139605,-0.01916219,-0.038037807,0.008157781,0.0037493317,0.0032191714,0.0035296257,-0.017509617,0.011290981,-0.04092264,-0.14412718,0.027224446,0.0027224447,-0.03287949,-0.056091912,-0.019697126,-0.027186237,0.006658049,0.00519175,-0.025581427,0.010192451,0.016124515,0.03433146,-0.02539038,0.02751102,0.06136486,0.013287441,-0.0097912485,-0.008043152,0.0055213086,0.01418537,-0.0077183694,-0.008750033,0.030319436,-0.030281227,-0.015981227,-0.024530658,0.029478822,0.00025164703,0.0399674,0.006839545,0.0021898963,0.010870674,0.032650232,0.035248496,0.012523245,-0.006853874,-0.03966172,0.0055356375,-0.023995724,0.012255778,0.01857949,-0.005397127,-0.015771074,-0.0501694,0.010364395,-0.00107047,0.016181828,0.018569939,-0.043750163,0.0028108046,0.07481469,-0.014682096,0.016879156,-0.025103806,-0.0005919526,-0.034388773,-0.033376217,0.04298597,0.0075225444,-0.010030059,-0.035439543,-0.078941345,-0.035878956,-0.016630793,-0.0013552521,-0.04592812,0.0014782397,0.015732864,0.003883066,-0.07470006,-0.0050341347,0.03165678,-0.027109817,0.00453502,0.020155642,0.011290981,-0.034121305,-0.0066723777,-0.0031570806,-0.0340831,-0.010039612,-0.014787173,-0.06442164,0.017347226,0.013583566,-0.018923378,0.006352371,-0.008726152,0.025887106,-0.046042748,-0.028943885,-0.001287191,-0.018130526,-0.028408948,0.039814558,0.016306011,-0.03954709,0.005349365,-0.0364521,0.0024394537,-0.037273612,0.006481329,-0.020136539,-0.013602671,0.0352676,0.015713759,-0.040311284,0.03989098,0.019420106,-0.03989098,-0.021664929,0.0030161822,-0.0025600533,-0.02539038,-0.014042083,0.04394121,0.024683498,-0.004929058,0.00043344183,-0.046348426,-0.012895791,0.005631162,-0.024511555,0.031886037,-0.002973196,0.050589707,-0.0042723278,0.03198156,0.020002805,0.010020507,-0.04462899,-0.022199865,0.039470673,0.035401333,0.05815524,-0.03597448,0.005631162,0.02288764,-0.014510153,0.04000561,-0.032898594,-0.0099058775,-0.02132104,-0.051583163,0.008367935,0.015360319,-0.004386957,-0.029517032,0.0011045006,0.055480555,-0.0024310953,-0.019620707,0.009557214,-0.023537206,0.031465728,0.011892784,-0.04397942,0.04887027,0.048106074,0.012093386,-0.04887027,-0.047838606,0.007866432,-0.008773914,0.024779022,-0.0077470266,-0.012064729,-0.03750287,0.0064096856,-0.03989098,0.0046186033,-0.021798663,-0.046424847,0.0021337757,-0.032994118,0.0017313793,-0.0045087505,0.052844085,-0.023002269,0.050054774,0.011806813,-0.03899305,0.002339153,0.005635938,-0.019391447,-0.037178088,0.036031794,0.0049481625,-0.012036071,-0.032955907,-0.016391983,0.01963981,0.0037970939,0.036929723,-0.035363123,-0.010526786,-0.013115496,-0.035878956,0.020996258,0.021817766,0.015217033,0.022276284,-0.049863722,-0.0356497,0.008119572,-0.0013003255,-0.0011445014,-0.008157781,0.031886037,0.005024582,-0.0036347024,-0.014137607,0.013287441,0.009366165,-0.04699799,-0.013564461,0.0039284397,0.017891714,-0.010784701,-0.016181828,-0.0074365726,-0.034618035,-0.0056407144,0.01811142,-0.014615229,-0.032038875,0.013564461,0.025466798,-0.011061722,-0.012962658,-0.006266399,-0.012953105,-0.0019642198,-0.0019104874,0.0018507848,-0.045966327,0.025313959,-0.04264208,0.024779022,-0.001965414,0.004785771,0.050016563,-0.03425504]
28	7e69db2b-739b-43be-9f8b-fb14849d374f	522575f5-810e-4ee4-8290-467c6f401f3b	患者头痛三天，伴眩晕恶心呕吐	三天前无明显诱因出现头部钝痛，进行性加重	既往体健，否认高血压糖尿病史	\N	神志清，精神可，颈部无抵抗	\N	头痛待查（颅内占位？）	t	\N	[-0.009753718,0.044703342,-0.032541122,-0.028844574,-0.018348673,-0.051138785,0.03857435,0.039608616,0.060025826,-0.032004837,0.007536746,-0.028710501,0.0026790404,0.016088607,0.019143527,0.0144989,0.024420207,-0.013234794,-0.016730236,0.013589127,-0.027082488,-2.58118e-05,0.0021379653,-0.012842156,-0.060140744,-0.029649004,-0.0008211893,0.056884717,0.053513773,0.0054251165,-0.0078384075,-0.07071326,0.06374153,0.011262025,0.008058668,-0.020149065,0.022887958,-0.024458513,-0.01080235,0.024094604,0.04527794,0.013244371,0.015877923,0.0026407342,-0.011041764,-0.0149585735,-0.049874682,-0.017304828,0.016308868,-0.000729015,-0.019593624,-0.010151145,0.048304126,0.017592125,-0.013550821,-0.015389519,0.015590626,-0.028174216,0.025780078,-0.012564436,-0.046733573,0.0072302967,-0.03658243,-0.018195448,0.012018573,0.07921723,-0.0028202946,0.029572392,-0.0011204566,-0.027235713,0.0012120323,-0.0064881137,-0.0023953351,-0.028116755,-0.04592914,0.04091103,0.0024396265,-0.042060215,0.008307659,0.010677855,0.024745809,-0.009112089,0.017419748,0.013426325,-0.016816424,0.024171216,0.014824502,0.012372904,-0.033786073,-0.013761505,-0.008623685,0.0050037485,-0.018808348,-0.017544243,-0.05462465,-0.02419037,-0.054394815,-0.0012605137,0.05274765,-0.0049223476,0.030568354,0.031085487,0.06584837,0.0017213852,-0.019086068,0.021087566,-0.020110758,0.035509855,0.01363701,0.018999878,0.024305288,0.01002665,0.0051186667,-0.011424826,0.0013502938,-0.01505434,-0.034973565,-0.0567698,-0.015494861,0.011281178,0.024630891,0.020398056,0.031468548,0.00663655,-0.034226596,0.056271818,0.01738144,-0.00014873582,-0.04592914,0.0058033904,-0.006287006,0.047921065,-0.0008367512,-0.05918309,-0.024937341,-0.023979686,0.0020206524,0.06029397,-0.009250949,-0.022485744,0.024573432,0.091168776,0.030683272,-0.015379942,0.0543182,-0.021528088,0.014700007,0.0124974,0.03024275,-0.03141109,-0.028633889,0.0028155062,0.00018285228,0.0093850205,0.005889579,0.031545162,-0.046886798,0.031430244,-0.008365118,-0.011118377,0.019373365,0.032081448,-0.011558898,0.06596329,-0.0022265483,-0.03110464,0.027388938,0.049951293,0.005224009,-0.027427245,0.004216077,-0.006090687,-0.020149065,0.02685265,-0.00060422055,0.042060215,0.050372664,0.010936422,-0.013876423,-0.035892915,-0.049644843,-0.016366327,0.040029988,-0.0031794151,0.005195279,-0.03259858,-0.028518971,-0.0057890257,0.011616358,-0.005640589,-0.03167923,-0.033862688,0.0027580468,-0.012143068,0.005348504,-0.027503857,-0.008183164,-0.018281637,-0.025511933,0.008345965,0.0063588303,0.023596624,0.018664699,-0.023366787,-0.017678315,-0.009595705,-0.01941167,-0.010467171,0.0022289425,-0.016481245,-0.031526007,-0.0066509154,-0.013445479,0.0021786655,0.02524379,-0.05937462,0.034303207,0.046005756,0.01691219,-0.0438223,-0.038248748,0.011300331,0.010036226,-0.046925105,-0.035586465,-0.014795773,0.027484704,0.024152063,0.03868927,-0.01674939,-0.015351213,0.051636767,-0.0025377863,0.0007978465,0.08894701,0.0040245457,-0.025397016,0.024592584,0.038650963,-0.0031147734,-0.0021738773,-0.0030621025,0.03030021,-0.016193949,0.038842496,0.020034146,-0.006698798,-0.016050301,-0.011118377,-0.015609779,0.0011827041,-0.008207105,-0.04868719,-0.010055379,0.034858648,0.0016770937,0.008939711,-0.012765544,-0.010390558,-0.01357955,-0.0062487,-0.0029543662,0.022792194,0.027886918,0.024726657,0.0004587767,0.02302203,0.006923847,0.031123793,-0.008235835,-0.023807308,-0.02332848,-0.025205484,0.048878722,0.033556238,0.031085487,0.0012533312,-0.010064956,0.026029067,-0.031545162,-0.010313946,0.020685352,0.0072973324,0.021049261,0.051560156,-0.0090354765,-0.019373365,-0.064814106,-0.0031794151,-0.01108007,0.036199365,0.0002884936,0.08427366,-0.029361708,-0.026584508,-0.0034307996,0.018770041,-0.17207149,-0.00025377862,0.0058225435,-0.009231796,-0.0013838117,0.019038185,-0.013847694,-0.022409132,-0.037310246,-0.023194408,0.004058064,-0.03821044,0.015236294,0.024324441,-0.0070387656,0.002566516,-0.0046087154,-0.045814224,0.019200986,-0.06684433,-0.042481583,-0.006042804,0.05401175,-0.07101971,0.0047188457,0.021815386,0.040949333,-0.010448018,-0.038536046,-0.016500399,-0.021317404,0.0017118086,-0.024209524,0.012995381,0.009930884,0.032311287,0.0075223814,-0.017074991,0.016146066,0.010649125,0.014652125,0.106414646,-0.010084109,0.0450481,0.0058225435,-0.033843532,-0.013924306,-0.05152185,-0.0070100357,0.015839616,0.048725497,-0.008183164,-0.049798068,0.0094329035,-0.059106477,0.028059296,0.016567435,0.049415007,-0.023711542,-0.021738773,-0.0001045939,-0.09331392,0.023290174,0.013340137,-0.044281974,-0.009643587,-0.027139947,-0.004907983,0.0028179004,0.0012114338,0.004220865,-0.043362625,-0.0111088,0.009557399,-0.011013035,0.0017979976,0.014537206,0.0082885055,0.003995816,-0.097297765,-0.012334598,0.025205484,0.0110226115,0.0003178218,-0.010036226,0.041370705,0.030261904,-0.01496815,0.023002878,0.25465965,0.06466088,0.00023312918,-0.052632727,-0.001684276,0.0142116025,-0.03999168,0.041255783,0.029036105,-0.03129617,-0.009988343,-0.0305492,-0.0071441075,0.017304828,0.025569392,0.029265942,-0.0450481,0.0031147734,0.07270518,-0.025358709,0.028135909,0.00037587967,0.026603661,0.004874465,-0.0144989,-0.030166138,-0.021777079,0.045124713,-0.007311697,-0.02826998,-0.049185168,0.008250199,0.015944958,-0.031487703,-0.04251989,-0.0067945635,0.002133177,-0.030836497,-0.038785033,0.024822421,0.02191115,-0.022811346,-0.030185292,0.026910111,-0.02962985,0.002485115,0.014910691,0.043592464,-0.031889915,-0.010524631,0.020953495,-0.031755846,-0.0026479166,-0.01558105,-0.0104767475,-0.00039772617,-0.04646543,0.015312906,-0.033843532,0.044511814,-0.0055879178,0.01474789,-0.015446978,0.027848613,0.014374404,-0.032732654,-0.0054634227,0.054394815,0.02419037,0.058225434,0.06672941,0.0049558654,0.027427245,0.0112237185,0.055314165,0.004101158,-0.041025948,0.037942298,-0.013809388,0.022600662,-0.0018949602,-0.0026239753,-0.0075080167,-0.024152063,0.0063109477,0.06826166,0.0139626125,0.063894756,0.020991802,-0.042864647,0.003002249,0.02055128,-0.054394815,0.037061255,-0.008820004,-0.0043477546,0.02246659,-0.061251625,-0.0016447727,0.012047302,-3.0338217e-05,-0.003002249,-0.0394937,-0.025397016,-0.021317404,-0.0050229016,-0.018837078,0.0033757344,-0.031506855,0.045201324,-0.022907112,0.0011007049,-0.021145027,-0.0388808,-0.0011048947,0.017046262,-0.013100723,0.012363329,-0.009600493,0.008393847,-6.9280366e-05,0.01786027,-0.034264904,0.06316694,0.009298832,-0.025416167,0.036199365,0.0038593505,-0.036199365,0.021432323,0.00024076049,-0.0054442696,-0.075424924,-0.041370705,0.04140901,-0.02216014,0.03851689,0.014058378,0.031028029,0.032847572,-0.034322362,-0.026833499,-0.009021112,0.00941375,0.020627892,-0.026565354,0.012238833,-0.06121332,-0.011827041,0.0068999054,0.03482034,0.0023163285,0.03141109,-0.04098764,-0.014269062,-0.03876588,-0.054586343,-0.05171338,0.031736694,-0.016126914,-0.014393557,0.009921308,0.04121748,0.05171338,-0.003988634,0.032100603,0.00451295,0.017707044,0.01558105,-0.007302121,0.015063916,-0.04531624,-0.02122164,0.002099659,0.0014759861,0.044167057,-0.05979599,0.070330195,0.05634843,-0.016337598,0.020340595,-0.0036702135,-0.016174795,0.012526129,0.05696133,0.047231555,0.020647045,-0.008547072,-0.011779158,-0.03472458,-0.006114628,0.12656371,0.0023809702,-0.0012940315,0.035509855,0.029419167,0.04658035,0.035471547,0.004307054,-0.011357791,-0.01599284,-0.013445479,-0.015485284,0.040259823,0.0038808975,0.007158472,0.025052259,-0.012870885,0.016031148,0.009088147,0.025818383,-0.007847984,-0.057612535,-0.022447437,-0.052173056,-0.0038282266,0.0077665835,0.02129825,-0.07144108,0.0036893666,0.05684641,0.00029836944,-0.0013897971,-0.066001594,-0.005013325,0.032407053,0.0045249206,-0.021681312,-0.02727402,0.000911568,-0.00062127877,-0.034533046,0.032790113,0.00053658616,-0.018559357,-0.025990762,0.03351793,0.0021128268,0.035931222,-0.039417088,-0.0021786655,-0.007393098,0.02233252,0.0116738165,-0.008729027,0.018779619,-0.0057363543,-0.012526129,0.03621852,0.03482034,-0.0009726185,0.0036510604,0.0067610457,-0.02610568,-0.0493767,0.034609657,-0.014058378,0.01360828,-0.02307949,0.040221516,0.0020194554,0.07320316,0.015485284,0.0009744141,-0.038306206,-0.063894756,-0.012238833,0.023673236,-0.020091606,-0.03945539,-0.048495658,0.017544243,-0.048112597,-0.07021528,-0.03257943,-0.035835456,-0.0073356386,0.07381606,-0.0056884717,-0.014182873,0.0038234382,-0.015724698,0.0311621,0.06332016,0.020512974,0.021394016,0.061826218,0.0047188457,-0.026948417,-0.00020484843,0.03413083,-0.016280139,-0.034475587,0.037635848,-0.0071632606,0.042481583,-0.019402094,0.025646005,-0.035758846,0.0007912626,-0.023462553,0.0035050178,-0.056041982,-0.043707382,-0.019766003,-0.038038064,0.026737733,0.004285507,-0.02869135,-0.0016435757,0.020129912,-0.055544,0.012650625,-0.023156103,-0.0028705713,-0.03030021,0.0271591,-0.012679354,-0.018425286,0.037731614,-0.019785156,0.024822421,-0.03158347,-0.015446978,-0.0060475925,-0.0032201156,-0.006521632,0.008743391,-0.031545162,-0.041370705,-0.027791154,-0.01955532,0.008216681,-0.008274141,0.021700466,-0.00025886617,-0.018425286,0.01832952,0.05067911,0.015868347,-0.027618775,-0.053360548,0.0047188457,0.0012066455,-0.022313366,0.017898574,0.008949287,-0.013780658,0.01857851,0.0044147903,0.02055128,-0.0067035863,-0.0083363885,-0.043400932,0.008365118,0.020876883,-0.005314986,-0.020666199,0.039723538,0.017228216,-8.4543e-06,0.050564192,-0.006545573,0.048955332,-0.016433362,-0.00019916234,0.018252907,-0.013818964,0.06305201,-0.0067849867,-0.0007535549,0.00558313,0.061902832,0.005362869,-0.011376943,-0.002342664,0.012238833,-0.017094145,-0.0019667842,-0.011348214,-0.03482034,0.017122874,-0.0010240925,-0.008130493,0.030415129,-0.02721656,-0.017544243,0.024899034,-0.0003217123,0.026201446,0.0016160432,-0.02857643,0.009207854,-0.021279098,-0.13445479,0.005482576,0.0042112884,-0.033154022,-0.052364584,-0.006033228,-0.013886,-0.01802307,0.022715582,-0.015514014,-0.023979686,-0.003646272,0.018865807,-0.007991632,-0.005765084,0.0524412,-0.00930362,-0.008197528,-0.015389519,0.047193248,0.0038952625,-0.007321274,0.057612535,0.030395975,0.010955575,-0.017793233,-0.053666998,0.0018841865,-0.0077857366,0.0087338155,-0.00799642,-0.036314283,0.02357747,0.017343136,0.04351585,0.018951995,0.021949457,-0.03851689,0.040527966,-0.018760465,0.0059278854,0.033594545,-0.013981765,-0.0299363,-0.072015665,0.043477546,0.020742811,0.010017073,-0.033900995,-0.04635051,-0.014451017,0.028020991,-0.025205484,0.0027029817,-0.035509855,-0.0093323495,-0.02110672,-0.009227008,0.044818264,0.028116755,0.027618775,-0.023213562,-0.06515886,-0.06351169,-0.03660158,-0.00053658616,-0.07128785,0.058340352,-0.020761965,0.029706463,-0.058493577,-0.014479746,0.0524412,-0.0097297765,-0.020991802,0.028250828,0.017132452,-0.026335517,-0.062132668,-0.034571353,-0.011587627,-0.002153527,-0.003174627,-0.06979391,0.0073500033,-0.023922225,-0.0044339434,0.00013833628,-0.015418248,0.021853691,-0.07519508,-0.015571473,0.015197988,0.0014293004,-0.0152746,-0.00074278127,0.0062726415,-0.04183038,0.0017680709,-0.023769,0.019804308,-0.023558317,-0.014067954,-0.009705835,-0.046925105,-0.017132452,-0.037616696,-0.015609779,0.017458053,0.03160262,-0.016126914,-0.019325482,9.120169e-05,0.008379483,-0.030721579,0.007919808,0.048112597,0.032617737,0.031526007,0.015293753,0.011003458,-0.02327102,-0.00999792,-0.015389519,0.018281637,-0.008480037,0.030779038,0.026278058,0.07760838,0.008317235,0.016778119,-0.06473749,-0.0074697104,0.030874804,-0.027733695,0.04838074,-0.026584508,-0.009404174,0.028308287,-0.049415007,0.01083108,-0.0042591714,0.006789775,-0.06381814,-0.030510893,-0.01602157,0.0069908826,0.009835118,-0.05270934,0.006349254,0.027369784,-0.04006829,-0.0015274601,0.05301579,0.012574012,-0.0097824475,0.01738144,-0.010764044,0.027676234,0.020781117,0.035031028,-0.0759229,-0.0518283,-0.041753765,-0.0062439116,0.062937096,-0.014853232,0.012008996,-0.031755846,0.012181374,-0.015399096,0.003507412,-0.008882252,-0.021240791,0.02758047,0.0028969068,-0.01441271,-0.027139947,0.042941257,-0.018013494,0.039915066,0.022198446,-0.025818383,0.019344635,0.00805388,-0.008954076,0.0066700685,0.028289134,0.031947378,-0.02807845,-0.021757925,-0.023864767,0.020110758,0.016768541,0.029476626,0.03658243,0.00680414,0.009452056,0.008604532,0.02252405,0.024209524,0.009547822,0.01672066,-0.06358831,-0.028442359,0.0084369425,-0.0008523131,-0.031947378,-0.003260816,-0.0122196805,-0.03010868,-0.0066413386,0.0035768421,-0.009370656,-0.0031028027,-0.042941257,-0.014326521,-0.0117216995,-0.023462553,0.0030549201,0.009724989,0.011262025,-0.03376692,-0.023749849,0.0043286015,-0.021125874,0.010601243,0.0144989,0.0071967784,0.021547241,-0.005817755,-0.0016196343,-0.01224841,0.01061082,-0.016509974,0.000824182,-0.050410967,-0.008700297,-0.054164976,0.01363701,0.0194404,-0.011932383,0.0438223,-0.010917269]
31	7c3e8d0e-1871-4ecf-a7d6-6839f142292b	17038ffe-7621-47df-9f9a-13cd4fbe41d5	症状自诉	现病史：患者自诉 腿折了，骨头刺穿了皮肤。	\N	\N	\N	\N	\N	f	\N	\N
35	c440a10a-a772-41a8-8d07-3dd8e0f56003	3610f304-a74c-41d3-8cdb-0ddfbc7b45dd	头晕伴右半身麻木三四天，晨起恶心	现病史：患者自诉 患者: 医生，我最近总是感觉头晕，而且右半边身体有点麻木。AI助手: 请问这种症状持续多长时间了？另外您之前对什么药物或食物有过敏反应吗?患者:                                                  大概有三四天了吧。我以前打青霉素过敏过，其他没啥。AI助手: 好的，是否有恶心想吐的感觉?患者: 早上起床的时候会有一点想吐。。\nAI建议科室：SJWK\n\n【AI 建议追问】\n头晕是旋转性还是非旋转性？\n右半身麻木是持续存在还是阵发性？\n有无言语不清、口角歪斜或行走不稳？\n有无高血压、糖尿病或心脏病史？\n最近有无头部外伤或感染？	\N	青霉素过敏	\N	【AI辅助建议，请医生核对】\n建议急诊行头颅CT或MRI检查，必要时行脑血管造影	\N	f	【AI辅助建议，请医生核对】\n立即就医，避免延误；可考虑抗血小板聚集、改善脑循环等对症处理，但需明确诊断后用药	\N
37	c23f1577-d943-447a-8101-2fb3b59a7489	505c8fd6-c8a8-439c-90ec-9a02f13a84fd	患者头痛三天，伴眩晕恶心呕吐	三天前无明显诱因出现头部钝痛，进行性加重	既往体健，否认高血压糖尿病史	未提供，待核实	神志清，精神可，颈部无抵抗	【AI辅助建议，请医生核对】\n建议进行头颅MRI增强扫描、CT检查及必要的病理活检	头痛待查（颅内占位？）	t	【AI辅助建议，请医生核对】\n根据肿瘤性质和位置，可能需行脑肿瘤切除手术，术后辅以放疗或化疗	[-0.009753718,0.044703342,-0.032541122,-0.028844574,-0.018348673,-0.051138785,0.03857435,0.039608616,0.060025826,-0.032004837,0.007536746,-0.028710501,0.0026790404,0.016088607,0.019143527,0.0144989,0.024420207,-0.013234794,-0.016730236,0.013589127,-0.027082488,-2.58118e-05,0.0021379653,-0.012842156,-0.060140744,-0.029649004,-0.0008211893,0.056884717,0.053513773,0.0054251165,-0.0078384075,-0.07071326,0.06374153,0.011262025,0.008058668,-0.020149065,0.022887958,-0.024458513,-0.01080235,0.024094604,0.04527794,0.013244371,0.015877923,0.0026407342,-0.011041764,-0.0149585735,-0.049874682,-0.017304828,0.016308868,-0.000729015,-0.019593624,-0.010151145,0.048304126,0.017592125,-0.013550821,-0.015389519,0.015590626,-0.028174216,0.025780078,-0.012564436,-0.046733573,0.0072302967,-0.03658243,-0.018195448,0.012018573,0.07921723,-0.0028202946,0.029572392,-0.0011204566,-0.027235713,0.0012120323,-0.0064881137,-0.0023953351,-0.028116755,-0.04592914,0.04091103,0.0024396265,-0.042060215,0.008307659,0.010677855,0.024745809,-0.009112089,0.017419748,0.013426325,-0.016816424,0.024171216,0.014824502,0.012372904,-0.033786073,-0.013761505,-0.008623685,0.0050037485,-0.018808348,-0.017544243,-0.05462465,-0.02419037,-0.054394815,-0.0012605137,0.05274765,-0.0049223476,0.030568354,0.031085487,0.06584837,0.0017213852,-0.019086068,0.021087566,-0.020110758,0.035509855,0.01363701,0.018999878,0.024305288,0.01002665,0.0051186667,-0.011424826,0.0013502938,-0.01505434,-0.034973565,-0.0567698,-0.015494861,0.011281178,0.024630891,0.020398056,0.031468548,0.00663655,-0.034226596,0.056271818,0.01738144,-0.00014873582,-0.04592914,0.0058033904,-0.006287006,0.047921065,-0.0008367512,-0.05918309,-0.024937341,-0.023979686,0.0020206524,0.06029397,-0.009250949,-0.022485744,0.024573432,0.091168776,0.030683272,-0.015379942,0.0543182,-0.021528088,0.014700007,0.0124974,0.03024275,-0.03141109,-0.028633889,0.0028155062,0.00018285228,0.0093850205,0.005889579,0.031545162,-0.046886798,0.031430244,-0.008365118,-0.011118377,0.019373365,0.032081448,-0.011558898,0.06596329,-0.0022265483,-0.03110464,0.027388938,0.049951293,0.005224009,-0.027427245,0.004216077,-0.006090687,-0.020149065,0.02685265,-0.00060422055,0.042060215,0.050372664,0.010936422,-0.013876423,-0.035892915,-0.049644843,-0.016366327,0.040029988,-0.0031794151,0.005195279,-0.03259858,-0.028518971,-0.0057890257,0.011616358,-0.005640589,-0.03167923,-0.033862688,0.0027580468,-0.012143068,0.005348504,-0.027503857,-0.008183164,-0.018281637,-0.025511933,0.008345965,0.0063588303,0.023596624,0.018664699,-0.023366787,-0.017678315,-0.009595705,-0.01941167,-0.010467171,0.0022289425,-0.016481245,-0.031526007,-0.0066509154,-0.013445479,0.0021786655,0.02524379,-0.05937462,0.034303207,0.046005756,0.01691219,-0.0438223,-0.038248748,0.011300331,0.010036226,-0.046925105,-0.035586465,-0.014795773,0.027484704,0.024152063,0.03868927,-0.01674939,-0.015351213,0.051636767,-0.0025377863,0.0007978465,0.08894701,0.0040245457,-0.025397016,0.024592584,0.038650963,-0.0031147734,-0.0021738773,-0.0030621025,0.03030021,-0.016193949,0.038842496,0.020034146,-0.006698798,-0.016050301,-0.011118377,-0.015609779,0.0011827041,-0.008207105,-0.04868719,-0.010055379,0.034858648,0.0016770937,0.008939711,-0.012765544,-0.010390558,-0.01357955,-0.0062487,-0.0029543662,0.022792194,0.027886918,0.024726657,0.0004587767,0.02302203,0.006923847,0.031123793,-0.008235835,-0.023807308,-0.02332848,-0.025205484,0.048878722,0.033556238,0.031085487,0.0012533312,-0.010064956,0.026029067,-0.031545162,-0.010313946,0.020685352,0.0072973324,0.021049261,0.051560156,-0.0090354765,-0.019373365,-0.064814106,-0.0031794151,-0.01108007,0.036199365,0.0002884936,0.08427366,-0.029361708,-0.026584508,-0.0034307996,0.018770041,-0.17207149,-0.00025377862,0.0058225435,-0.009231796,-0.0013838117,0.019038185,-0.013847694,-0.022409132,-0.037310246,-0.023194408,0.004058064,-0.03821044,0.015236294,0.024324441,-0.0070387656,0.002566516,-0.0046087154,-0.045814224,0.019200986,-0.06684433,-0.042481583,-0.006042804,0.05401175,-0.07101971,0.0047188457,0.021815386,0.040949333,-0.010448018,-0.038536046,-0.016500399,-0.021317404,0.0017118086,-0.024209524,0.012995381,0.009930884,0.032311287,0.0075223814,-0.017074991,0.016146066,0.010649125,0.014652125,0.106414646,-0.010084109,0.0450481,0.0058225435,-0.033843532,-0.013924306,-0.05152185,-0.0070100357,0.015839616,0.048725497,-0.008183164,-0.049798068,0.0094329035,-0.059106477,0.028059296,0.016567435,0.049415007,-0.023711542,-0.021738773,-0.0001045939,-0.09331392,0.023290174,0.013340137,-0.044281974,-0.009643587,-0.027139947,-0.004907983,0.0028179004,0.0012114338,0.004220865,-0.043362625,-0.0111088,0.009557399,-0.011013035,0.0017979976,0.014537206,0.0082885055,0.003995816,-0.097297765,-0.012334598,0.025205484,0.0110226115,0.0003178218,-0.010036226,0.041370705,0.030261904,-0.01496815,0.023002878,0.25465965,0.06466088,0.00023312918,-0.052632727,-0.001684276,0.0142116025,-0.03999168,0.041255783,0.029036105,-0.03129617,-0.009988343,-0.0305492,-0.0071441075,0.017304828,0.025569392,0.029265942,-0.0450481,0.0031147734,0.07270518,-0.025358709,0.028135909,0.00037587967,0.026603661,0.004874465,-0.0144989,-0.030166138,-0.021777079,0.045124713,-0.007311697,-0.02826998,-0.049185168,0.008250199,0.015944958,-0.031487703,-0.04251989,-0.0067945635,0.002133177,-0.030836497,-0.038785033,0.024822421,0.02191115,-0.022811346,-0.030185292,0.026910111,-0.02962985,0.002485115,0.014910691,0.043592464,-0.031889915,-0.010524631,0.020953495,-0.031755846,-0.0026479166,-0.01558105,-0.0104767475,-0.00039772617,-0.04646543,0.015312906,-0.033843532,0.044511814,-0.0055879178,0.01474789,-0.015446978,0.027848613,0.014374404,-0.032732654,-0.0054634227,0.054394815,0.02419037,0.058225434,0.06672941,0.0049558654,0.027427245,0.0112237185,0.055314165,0.004101158,-0.041025948,0.037942298,-0.013809388,0.022600662,-0.0018949602,-0.0026239753,-0.0075080167,-0.024152063,0.0063109477,0.06826166,0.0139626125,0.063894756,0.020991802,-0.042864647,0.003002249,0.02055128,-0.054394815,0.037061255,-0.008820004,-0.0043477546,0.02246659,-0.061251625,-0.0016447727,0.012047302,-3.0338217e-05,-0.003002249,-0.0394937,-0.025397016,-0.021317404,-0.0050229016,-0.018837078,0.0033757344,-0.031506855,0.045201324,-0.022907112,0.0011007049,-0.021145027,-0.0388808,-0.0011048947,0.017046262,-0.013100723,0.012363329,-0.009600493,0.008393847,-6.9280366e-05,0.01786027,-0.034264904,0.06316694,0.009298832,-0.025416167,0.036199365,0.0038593505,-0.036199365,0.021432323,0.00024076049,-0.0054442696,-0.075424924,-0.041370705,0.04140901,-0.02216014,0.03851689,0.014058378,0.031028029,0.032847572,-0.034322362,-0.026833499,-0.009021112,0.00941375,0.020627892,-0.026565354,0.012238833,-0.06121332,-0.011827041,0.0068999054,0.03482034,0.0023163285,0.03141109,-0.04098764,-0.014269062,-0.03876588,-0.054586343,-0.05171338,0.031736694,-0.016126914,-0.014393557,0.009921308,0.04121748,0.05171338,-0.003988634,0.032100603,0.00451295,0.017707044,0.01558105,-0.007302121,0.015063916,-0.04531624,-0.02122164,0.002099659,0.0014759861,0.044167057,-0.05979599,0.070330195,0.05634843,-0.016337598,0.020340595,-0.0036702135,-0.016174795,0.012526129,0.05696133,0.047231555,0.020647045,-0.008547072,-0.011779158,-0.03472458,-0.006114628,0.12656371,0.0023809702,-0.0012940315,0.035509855,0.029419167,0.04658035,0.035471547,0.004307054,-0.011357791,-0.01599284,-0.013445479,-0.015485284,0.040259823,0.0038808975,0.007158472,0.025052259,-0.012870885,0.016031148,0.009088147,0.025818383,-0.007847984,-0.057612535,-0.022447437,-0.052173056,-0.0038282266,0.0077665835,0.02129825,-0.07144108,0.0036893666,0.05684641,0.00029836944,-0.0013897971,-0.066001594,-0.005013325,0.032407053,0.0045249206,-0.021681312,-0.02727402,0.000911568,-0.00062127877,-0.034533046,0.032790113,0.00053658616,-0.018559357,-0.025990762,0.03351793,0.0021128268,0.035931222,-0.039417088,-0.0021786655,-0.007393098,0.02233252,0.0116738165,-0.008729027,0.018779619,-0.0057363543,-0.012526129,0.03621852,0.03482034,-0.0009726185,0.0036510604,0.0067610457,-0.02610568,-0.0493767,0.034609657,-0.014058378,0.01360828,-0.02307949,0.040221516,0.0020194554,0.07320316,0.015485284,0.0009744141,-0.038306206,-0.063894756,-0.012238833,0.023673236,-0.020091606,-0.03945539,-0.048495658,0.017544243,-0.048112597,-0.07021528,-0.03257943,-0.035835456,-0.0073356386,0.07381606,-0.0056884717,-0.014182873,0.0038234382,-0.015724698,0.0311621,0.06332016,0.020512974,0.021394016,0.061826218,0.0047188457,-0.026948417,-0.00020484843,0.03413083,-0.016280139,-0.034475587,0.037635848,-0.0071632606,0.042481583,-0.019402094,0.025646005,-0.035758846,0.0007912626,-0.023462553,0.0035050178,-0.056041982,-0.043707382,-0.019766003,-0.038038064,0.026737733,0.004285507,-0.02869135,-0.0016435757,0.020129912,-0.055544,0.012650625,-0.023156103,-0.0028705713,-0.03030021,0.0271591,-0.012679354,-0.018425286,0.037731614,-0.019785156,0.024822421,-0.03158347,-0.015446978,-0.0060475925,-0.0032201156,-0.006521632,0.008743391,-0.031545162,-0.041370705,-0.027791154,-0.01955532,0.008216681,-0.008274141,0.021700466,-0.00025886617,-0.018425286,0.01832952,0.05067911,0.015868347,-0.027618775,-0.053360548,0.0047188457,0.0012066455,-0.022313366,0.017898574,0.008949287,-0.013780658,0.01857851,0.0044147903,0.02055128,-0.0067035863,-0.0083363885,-0.043400932,0.008365118,0.020876883,-0.005314986,-0.020666199,0.039723538,0.017228216,-8.4543e-06,0.050564192,-0.006545573,0.048955332,-0.016433362,-0.00019916234,0.018252907,-0.013818964,0.06305201,-0.0067849867,-0.0007535549,0.00558313,0.061902832,0.005362869,-0.011376943,-0.002342664,0.012238833,-0.017094145,-0.0019667842,-0.011348214,-0.03482034,0.017122874,-0.0010240925,-0.008130493,0.030415129,-0.02721656,-0.017544243,0.024899034,-0.0003217123,0.026201446,0.0016160432,-0.02857643,0.009207854,-0.021279098,-0.13445479,0.005482576,0.0042112884,-0.033154022,-0.052364584,-0.006033228,-0.013886,-0.01802307,0.022715582,-0.015514014,-0.023979686,-0.003646272,0.018865807,-0.007991632,-0.005765084,0.0524412,-0.00930362,-0.008197528,-0.015389519,0.047193248,0.0038952625,-0.007321274,0.057612535,0.030395975,0.010955575,-0.017793233,-0.053666998,0.0018841865,-0.0077857366,0.0087338155,-0.00799642,-0.036314283,0.02357747,0.017343136,0.04351585,0.018951995,0.021949457,-0.03851689,0.040527966,-0.018760465,0.0059278854,0.033594545,-0.013981765,-0.0299363,-0.072015665,0.043477546,0.020742811,0.010017073,-0.033900995,-0.04635051,-0.014451017,0.028020991,-0.025205484,0.0027029817,-0.035509855,-0.0093323495,-0.02110672,-0.009227008,0.044818264,0.028116755,0.027618775,-0.023213562,-0.06515886,-0.06351169,-0.03660158,-0.00053658616,-0.07128785,0.058340352,-0.020761965,0.029706463,-0.058493577,-0.014479746,0.0524412,-0.0097297765,-0.020991802,0.028250828,0.017132452,-0.026335517,-0.062132668,-0.034571353,-0.011587627,-0.002153527,-0.003174627,-0.06979391,0.0073500033,-0.023922225,-0.0044339434,0.00013833628,-0.015418248,0.021853691,-0.07519508,-0.015571473,0.015197988,0.0014293004,-0.0152746,-0.00074278127,0.0062726415,-0.04183038,0.0017680709,-0.023769,0.019804308,-0.023558317,-0.014067954,-0.009705835,-0.046925105,-0.017132452,-0.037616696,-0.015609779,0.017458053,0.03160262,-0.016126914,-0.019325482,9.120169e-05,0.008379483,-0.030721579,0.007919808,0.048112597,0.032617737,0.031526007,0.015293753,0.011003458,-0.02327102,-0.00999792,-0.015389519,0.018281637,-0.008480037,0.030779038,0.026278058,0.07760838,0.008317235,0.016778119,-0.06473749,-0.0074697104,0.030874804,-0.027733695,0.04838074,-0.026584508,-0.009404174,0.028308287,-0.049415007,0.01083108,-0.0042591714,0.006789775,-0.06381814,-0.030510893,-0.01602157,0.0069908826,0.009835118,-0.05270934,0.006349254,0.027369784,-0.04006829,-0.0015274601,0.05301579,0.012574012,-0.0097824475,0.01738144,-0.010764044,0.027676234,0.020781117,0.035031028,-0.0759229,-0.0518283,-0.041753765,-0.0062439116,0.062937096,-0.014853232,0.012008996,-0.031755846,0.012181374,-0.015399096,0.003507412,-0.008882252,-0.021240791,0.02758047,0.0028969068,-0.01441271,-0.027139947,0.042941257,-0.018013494,0.039915066,0.022198446,-0.025818383,0.019344635,0.00805388,-0.008954076,0.0066700685,0.028289134,0.031947378,-0.02807845,-0.021757925,-0.023864767,0.020110758,0.016768541,0.029476626,0.03658243,0.00680414,0.009452056,0.008604532,0.02252405,0.024209524,0.009547822,0.01672066,-0.06358831,-0.028442359,0.0084369425,-0.0008523131,-0.031947378,-0.003260816,-0.0122196805,-0.03010868,-0.0066413386,0.0035768421,-0.009370656,-0.0031028027,-0.042941257,-0.014326521,-0.0117216995,-0.023462553,0.0030549201,0.009724989,0.011262025,-0.03376692,-0.023749849,0.0043286015,-0.021125874,0.010601243,0.0144989,0.0071967784,0.021547241,-0.005817755,-0.0016196343,-0.01224841,0.01061082,-0.016509974,0.000824182,-0.050410967,-0.008700297,-0.054164976,0.01363701,0.0194404,-0.011932383,0.0438223,-0.010917269]
38	aa22bab9-4544-490f-8ce6-b7978b73818d	40cc2c9f-432b-40c8-a659-511360b769b4	患者头痛三天，伴眩晕恶心呕吐	三天前无明显诱因出现头部钝痛，进行性加重	既往体健，否认高血压糖尿病史	未提供，待核实	神志清，精神可，颈部无抵抗	【AI辅助建议，请医生核对】\n建议进行头颅MRI增强扫描、CT检查及必要的病理活检	头痛待查（颅内占位？）	t	【AI辅助建议，请医生核对】\n根据肿瘤性质、位置和患者状况，可能需行脑肿瘤切除手术，术后辅以放疗或化疗	[-0.009753718,0.044703342,-0.032541122,-0.028844574,-0.018348673,-0.051138785,0.03857435,0.039608616,0.060025826,-0.032004837,0.007536746,-0.028710501,0.0026790404,0.016088607,0.019143527,0.0144989,0.024420207,-0.013234794,-0.016730236,0.013589127,-0.027082488,-2.58118e-05,0.0021379653,-0.012842156,-0.060140744,-0.029649004,-0.0008211893,0.056884717,0.053513773,0.0054251165,-0.0078384075,-0.07071326,0.06374153,0.011262025,0.008058668,-0.020149065,0.022887958,-0.024458513,-0.01080235,0.024094604,0.04527794,0.013244371,0.015877923,0.0026407342,-0.011041764,-0.0149585735,-0.049874682,-0.017304828,0.016308868,-0.000729015,-0.019593624,-0.010151145,0.048304126,0.017592125,-0.013550821,-0.015389519,0.015590626,-0.028174216,0.025780078,-0.012564436,-0.046733573,0.0072302967,-0.03658243,-0.018195448,0.012018573,0.07921723,-0.0028202946,0.029572392,-0.0011204566,-0.027235713,0.0012120323,-0.0064881137,-0.0023953351,-0.028116755,-0.04592914,0.04091103,0.0024396265,-0.042060215,0.008307659,0.010677855,0.024745809,-0.009112089,0.017419748,0.013426325,-0.016816424,0.024171216,0.014824502,0.012372904,-0.033786073,-0.013761505,-0.008623685,0.0050037485,-0.018808348,-0.017544243,-0.05462465,-0.02419037,-0.054394815,-0.0012605137,0.05274765,-0.0049223476,0.030568354,0.031085487,0.06584837,0.0017213852,-0.019086068,0.021087566,-0.020110758,0.035509855,0.01363701,0.018999878,0.024305288,0.01002665,0.0051186667,-0.011424826,0.0013502938,-0.01505434,-0.034973565,-0.0567698,-0.015494861,0.011281178,0.024630891,0.020398056,0.031468548,0.00663655,-0.034226596,0.056271818,0.01738144,-0.00014873582,-0.04592914,0.0058033904,-0.006287006,0.047921065,-0.0008367512,-0.05918309,-0.024937341,-0.023979686,0.0020206524,0.06029397,-0.009250949,-0.022485744,0.024573432,0.091168776,0.030683272,-0.015379942,0.0543182,-0.021528088,0.014700007,0.0124974,0.03024275,-0.03141109,-0.028633889,0.0028155062,0.00018285228,0.0093850205,0.005889579,0.031545162,-0.046886798,0.031430244,-0.008365118,-0.011118377,0.019373365,0.032081448,-0.011558898,0.06596329,-0.0022265483,-0.03110464,0.027388938,0.049951293,0.005224009,-0.027427245,0.004216077,-0.006090687,-0.020149065,0.02685265,-0.00060422055,0.042060215,0.050372664,0.010936422,-0.013876423,-0.035892915,-0.049644843,-0.016366327,0.040029988,-0.0031794151,0.005195279,-0.03259858,-0.028518971,-0.0057890257,0.011616358,-0.005640589,-0.03167923,-0.033862688,0.0027580468,-0.012143068,0.005348504,-0.027503857,-0.008183164,-0.018281637,-0.025511933,0.008345965,0.0063588303,0.023596624,0.018664699,-0.023366787,-0.017678315,-0.009595705,-0.01941167,-0.010467171,0.0022289425,-0.016481245,-0.031526007,-0.0066509154,-0.013445479,0.0021786655,0.02524379,-0.05937462,0.034303207,0.046005756,0.01691219,-0.0438223,-0.038248748,0.011300331,0.010036226,-0.046925105,-0.035586465,-0.014795773,0.027484704,0.024152063,0.03868927,-0.01674939,-0.015351213,0.051636767,-0.0025377863,0.0007978465,0.08894701,0.0040245457,-0.025397016,0.024592584,0.038650963,-0.0031147734,-0.0021738773,-0.0030621025,0.03030021,-0.016193949,0.038842496,0.020034146,-0.006698798,-0.016050301,-0.011118377,-0.015609779,0.0011827041,-0.008207105,-0.04868719,-0.010055379,0.034858648,0.0016770937,0.008939711,-0.012765544,-0.010390558,-0.01357955,-0.0062487,-0.0029543662,0.022792194,0.027886918,0.024726657,0.0004587767,0.02302203,0.006923847,0.031123793,-0.008235835,-0.023807308,-0.02332848,-0.025205484,0.048878722,0.033556238,0.031085487,0.0012533312,-0.010064956,0.026029067,-0.031545162,-0.010313946,0.020685352,0.0072973324,0.021049261,0.051560156,-0.0090354765,-0.019373365,-0.064814106,-0.0031794151,-0.01108007,0.036199365,0.0002884936,0.08427366,-0.029361708,-0.026584508,-0.0034307996,0.018770041,-0.17207149,-0.00025377862,0.0058225435,-0.009231796,-0.0013838117,0.019038185,-0.013847694,-0.022409132,-0.037310246,-0.023194408,0.004058064,-0.03821044,0.015236294,0.024324441,-0.0070387656,0.002566516,-0.0046087154,-0.045814224,0.019200986,-0.06684433,-0.042481583,-0.006042804,0.05401175,-0.07101971,0.0047188457,0.021815386,0.040949333,-0.010448018,-0.038536046,-0.016500399,-0.021317404,0.0017118086,-0.024209524,0.012995381,0.009930884,0.032311287,0.0075223814,-0.017074991,0.016146066,0.010649125,0.014652125,0.106414646,-0.010084109,0.0450481,0.0058225435,-0.033843532,-0.013924306,-0.05152185,-0.0070100357,0.015839616,0.048725497,-0.008183164,-0.049798068,0.0094329035,-0.059106477,0.028059296,0.016567435,0.049415007,-0.023711542,-0.021738773,-0.0001045939,-0.09331392,0.023290174,0.013340137,-0.044281974,-0.009643587,-0.027139947,-0.004907983,0.0028179004,0.0012114338,0.004220865,-0.043362625,-0.0111088,0.009557399,-0.011013035,0.0017979976,0.014537206,0.0082885055,0.003995816,-0.097297765,-0.012334598,0.025205484,0.0110226115,0.0003178218,-0.010036226,0.041370705,0.030261904,-0.01496815,0.023002878,0.25465965,0.06466088,0.00023312918,-0.052632727,-0.001684276,0.0142116025,-0.03999168,0.041255783,0.029036105,-0.03129617,-0.009988343,-0.0305492,-0.0071441075,0.017304828,0.025569392,0.029265942,-0.0450481,0.0031147734,0.07270518,-0.025358709,0.028135909,0.00037587967,0.026603661,0.004874465,-0.0144989,-0.030166138,-0.021777079,0.045124713,-0.007311697,-0.02826998,-0.049185168,0.008250199,0.015944958,-0.031487703,-0.04251989,-0.0067945635,0.002133177,-0.030836497,-0.038785033,0.024822421,0.02191115,-0.022811346,-0.030185292,0.026910111,-0.02962985,0.002485115,0.014910691,0.043592464,-0.031889915,-0.010524631,0.020953495,-0.031755846,-0.0026479166,-0.01558105,-0.0104767475,-0.00039772617,-0.04646543,0.015312906,-0.033843532,0.044511814,-0.0055879178,0.01474789,-0.015446978,0.027848613,0.014374404,-0.032732654,-0.0054634227,0.054394815,0.02419037,0.058225434,0.06672941,0.0049558654,0.027427245,0.0112237185,0.055314165,0.004101158,-0.041025948,0.037942298,-0.013809388,0.022600662,-0.0018949602,-0.0026239753,-0.0075080167,-0.024152063,0.0063109477,0.06826166,0.0139626125,0.063894756,0.020991802,-0.042864647,0.003002249,0.02055128,-0.054394815,0.037061255,-0.008820004,-0.0043477546,0.02246659,-0.061251625,-0.0016447727,0.012047302,-3.0338217e-05,-0.003002249,-0.0394937,-0.025397016,-0.021317404,-0.0050229016,-0.018837078,0.0033757344,-0.031506855,0.045201324,-0.022907112,0.0011007049,-0.021145027,-0.0388808,-0.0011048947,0.017046262,-0.013100723,0.012363329,-0.009600493,0.008393847,-6.9280366e-05,0.01786027,-0.034264904,0.06316694,0.009298832,-0.025416167,0.036199365,0.0038593505,-0.036199365,0.021432323,0.00024076049,-0.0054442696,-0.075424924,-0.041370705,0.04140901,-0.02216014,0.03851689,0.014058378,0.031028029,0.032847572,-0.034322362,-0.026833499,-0.009021112,0.00941375,0.020627892,-0.026565354,0.012238833,-0.06121332,-0.011827041,0.0068999054,0.03482034,0.0023163285,0.03141109,-0.04098764,-0.014269062,-0.03876588,-0.054586343,-0.05171338,0.031736694,-0.016126914,-0.014393557,0.009921308,0.04121748,0.05171338,-0.003988634,0.032100603,0.00451295,0.017707044,0.01558105,-0.007302121,0.015063916,-0.04531624,-0.02122164,0.002099659,0.0014759861,0.044167057,-0.05979599,0.070330195,0.05634843,-0.016337598,0.020340595,-0.0036702135,-0.016174795,0.012526129,0.05696133,0.047231555,0.020647045,-0.008547072,-0.011779158,-0.03472458,-0.006114628,0.12656371,0.0023809702,-0.0012940315,0.035509855,0.029419167,0.04658035,0.035471547,0.004307054,-0.011357791,-0.01599284,-0.013445479,-0.015485284,0.040259823,0.0038808975,0.007158472,0.025052259,-0.012870885,0.016031148,0.009088147,0.025818383,-0.007847984,-0.057612535,-0.022447437,-0.052173056,-0.0038282266,0.0077665835,0.02129825,-0.07144108,0.0036893666,0.05684641,0.00029836944,-0.0013897971,-0.066001594,-0.005013325,0.032407053,0.0045249206,-0.021681312,-0.02727402,0.000911568,-0.00062127877,-0.034533046,0.032790113,0.00053658616,-0.018559357,-0.025990762,0.03351793,0.0021128268,0.035931222,-0.039417088,-0.0021786655,-0.007393098,0.02233252,0.0116738165,-0.008729027,0.018779619,-0.0057363543,-0.012526129,0.03621852,0.03482034,-0.0009726185,0.0036510604,0.0067610457,-0.02610568,-0.0493767,0.034609657,-0.014058378,0.01360828,-0.02307949,0.040221516,0.0020194554,0.07320316,0.015485284,0.0009744141,-0.038306206,-0.063894756,-0.012238833,0.023673236,-0.020091606,-0.03945539,-0.048495658,0.017544243,-0.048112597,-0.07021528,-0.03257943,-0.035835456,-0.0073356386,0.07381606,-0.0056884717,-0.014182873,0.0038234382,-0.015724698,0.0311621,0.06332016,0.020512974,0.021394016,0.061826218,0.0047188457,-0.026948417,-0.00020484843,0.03413083,-0.016280139,-0.034475587,0.037635848,-0.0071632606,0.042481583,-0.019402094,0.025646005,-0.035758846,0.0007912626,-0.023462553,0.0035050178,-0.056041982,-0.043707382,-0.019766003,-0.038038064,0.026737733,0.004285507,-0.02869135,-0.0016435757,0.020129912,-0.055544,0.012650625,-0.023156103,-0.0028705713,-0.03030021,0.0271591,-0.012679354,-0.018425286,0.037731614,-0.019785156,0.024822421,-0.03158347,-0.015446978,-0.0060475925,-0.0032201156,-0.006521632,0.008743391,-0.031545162,-0.041370705,-0.027791154,-0.01955532,0.008216681,-0.008274141,0.021700466,-0.00025886617,-0.018425286,0.01832952,0.05067911,0.015868347,-0.027618775,-0.053360548,0.0047188457,0.0012066455,-0.022313366,0.017898574,0.008949287,-0.013780658,0.01857851,0.0044147903,0.02055128,-0.0067035863,-0.0083363885,-0.043400932,0.008365118,0.020876883,-0.005314986,-0.020666199,0.039723538,0.017228216,-8.4543e-06,0.050564192,-0.006545573,0.048955332,-0.016433362,-0.00019916234,0.018252907,-0.013818964,0.06305201,-0.0067849867,-0.0007535549,0.00558313,0.061902832,0.005362869,-0.011376943,-0.002342664,0.012238833,-0.017094145,-0.0019667842,-0.011348214,-0.03482034,0.017122874,-0.0010240925,-0.008130493,0.030415129,-0.02721656,-0.017544243,0.024899034,-0.0003217123,0.026201446,0.0016160432,-0.02857643,0.009207854,-0.021279098,-0.13445479,0.005482576,0.0042112884,-0.033154022,-0.052364584,-0.006033228,-0.013886,-0.01802307,0.022715582,-0.015514014,-0.023979686,-0.003646272,0.018865807,-0.007991632,-0.005765084,0.0524412,-0.00930362,-0.008197528,-0.015389519,0.047193248,0.0038952625,-0.007321274,0.057612535,0.030395975,0.010955575,-0.017793233,-0.053666998,0.0018841865,-0.0077857366,0.0087338155,-0.00799642,-0.036314283,0.02357747,0.017343136,0.04351585,0.018951995,0.021949457,-0.03851689,0.040527966,-0.018760465,0.0059278854,0.033594545,-0.013981765,-0.0299363,-0.072015665,0.043477546,0.020742811,0.010017073,-0.033900995,-0.04635051,-0.014451017,0.028020991,-0.025205484,0.0027029817,-0.035509855,-0.0093323495,-0.02110672,-0.009227008,0.044818264,0.028116755,0.027618775,-0.023213562,-0.06515886,-0.06351169,-0.03660158,-0.00053658616,-0.07128785,0.058340352,-0.020761965,0.029706463,-0.058493577,-0.014479746,0.0524412,-0.0097297765,-0.020991802,0.028250828,0.017132452,-0.026335517,-0.062132668,-0.034571353,-0.011587627,-0.002153527,-0.003174627,-0.06979391,0.0073500033,-0.023922225,-0.0044339434,0.00013833628,-0.015418248,0.021853691,-0.07519508,-0.015571473,0.015197988,0.0014293004,-0.0152746,-0.00074278127,0.0062726415,-0.04183038,0.0017680709,-0.023769,0.019804308,-0.023558317,-0.014067954,-0.009705835,-0.046925105,-0.017132452,-0.037616696,-0.015609779,0.017458053,0.03160262,-0.016126914,-0.019325482,9.120169e-05,0.008379483,-0.030721579,0.007919808,0.048112597,0.032617737,0.031526007,0.015293753,0.011003458,-0.02327102,-0.00999792,-0.015389519,0.018281637,-0.008480037,0.030779038,0.026278058,0.07760838,0.008317235,0.016778119,-0.06473749,-0.0074697104,0.030874804,-0.027733695,0.04838074,-0.026584508,-0.009404174,0.028308287,-0.049415007,0.01083108,-0.0042591714,0.006789775,-0.06381814,-0.030510893,-0.01602157,0.0069908826,0.009835118,-0.05270934,0.006349254,0.027369784,-0.04006829,-0.0015274601,0.05301579,0.012574012,-0.0097824475,0.01738144,-0.010764044,0.027676234,0.020781117,0.035031028,-0.0759229,-0.0518283,-0.041753765,-0.0062439116,0.062937096,-0.014853232,0.012008996,-0.031755846,0.012181374,-0.015399096,0.003507412,-0.008882252,-0.021240791,0.02758047,0.0028969068,-0.01441271,-0.027139947,0.042941257,-0.018013494,0.039915066,0.022198446,-0.025818383,0.019344635,0.00805388,-0.008954076,0.0066700685,0.028289134,0.031947378,-0.02807845,-0.021757925,-0.023864767,0.020110758,0.016768541,0.029476626,0.03658243,0.00680414,0.009452056,0.008604532,0.02252405,0.024209524,0.009547822,0.01672066,-0.06358831,-0.028442359,0.0084369425,-0.0008523131,-0.031947378,-0.003260816,-0.0122196805,-0.03010868,-0.0066413386,0.0035768421,-0.009370656,-0.0031028027,-0.042941257,-0.014326521,-0.0117216995,-0.023462553,0.0030549201,0.009724989,0.011262025,-0.03376692,-0.023749849,0.0043286015,-0.021125874,0.010601243,0.0144989,0.0071967784,0.021547241,-0.005817755,-0.0016196343,-0.01224841,0.01061082,-0.016509974,0.000824182,-0.050410967,-0.008700297,-0.054164976,0.01363701,0.0194404,-0.011932383,0.0438223,-0.010917269]
39	cd3168d8-25ca-4dd8-99fe-c2f7f19ebb19	ecf81d0b-caa0-4d26-8847-241a83677776	AI summary	Patient has headache	None	None	Normal	Rest	Common Cold	t	Drink water	[-0.010600498,0.008214671,-0.029906167,-0.04472591,-0.0042597237,-0.027887024,0.012219622,0.06385062,0.02203913,-0.031563386,0.0015643592,-0.0121434275,-0.010543352,0.0055478797,0.010429061,0.018781833,0.007990851,0.0028025126,-0.050707143,-0.029791875,0.016448392,0.021905791,0.028115606,-0.036020737,-0.020896219,0.018248476,-0.023372525,-0.014362579,0.014372103,0.021981984,0.0070193773,-0.032972977,0.027601296,-0.012295815,-0.0012988705,-0.02640124,-0.013638736,0.0023322525,-0.03501117,-0.016867459,0.05059285,0.008967088,0.028134655,0.03369682,0.017143661,-0.00032293182,-0.024686873,-0.021981984,-0.0030263325,0.023505865,0.008162288,0.03188721,0.032001503,-0.022705829,-0.009781412,-0.024801165,0.029068032,-0.024629727,-0.028896594,0.005443113,-0.036992215,-0.0048383223,-0.015343578,-0.024782116,0.052116733,0.0743273,0.00836706,0.01718176,-0.044649716,-0.0538311,-0.027848927,-0.024534484,-0.013086328,-0.031734824,-0.03461115,0.023829691,0.018010369,-0.02306775,0.02996331,0.0031191942,0.046173595,-0.016048372,0.02152482,0.0032906306,-0.033887304,0.028001314,-0.00063693465,0.04674505,-0.04026856,-0.018067515,-0.018600874,-0.041944828,-0.0132196685,-0.034915924,-0.027829878,-0.025296425,-0.037296988,0.026686966,0.041601952,-0.009790936,0.005700268,0.042630572,0.03575406,-0.0050621424,0.025658347,0.01913423,0.02459163,0.008305152,0.061869573,0.019391386,0.041335274,0.028229896,0.0146102095,0.025201183,-0.022839168,0.027963217,-0.002488212,-0.020515248,-0.045449752,0.012495825,-0.031163368,0.0036644577,0.0102481,0.0063241064,-0.0051811957,0.024896407,-0.0054764478,-0.014514967,-0.019096134,-0.014391152,0.0036096934,0.01769607,-0.014772122,-0.017257953,-0.015991228,-0.045525946,-0.002241772,0.03624932,-0.0075432113,0.0017893697,0.0019274715,0.06392681,-0.019200902,-0.038611338,0.041944828,-0.017753214,0.048383225,0.0333349,0.005385967,-0.0045049735,0.005762175,0.0040573333,-0.00078456063,0.03535404,0.021867694,-0.003935899,0.0062098154,-0.00069884234,0.028801352,-0.008328962,0.0054812096,0.036877923,0.014943559,-0.014981655,0.015248335,-0.00056907436,-0.011600545,0.020000938,-0.026115512,0.00021578395,0.031563386,-0.016410295,-0.022115324,0.017962748,0.019343765,0.02266773,0.07771794,0.024782116,0.03523975,-0.018715164,-0.028763255,0.004664505,-0.0020072372,-0.010743362,-0.051430985,0.031087173,0.009971897,-0.0057478887,0.03217294,-0.01121005,-0.021200996,-0.031353854,0.031049076,0.010638595,-0.016486488,0.0040954305,-0.009681407,-0.06331726,-0.028267995,-0.011105283,0.0061717182,0.039278034,0.020534297,0.015486442,0.0045478325,-0.01581979,-0.039430425,-0.06613644,-0.0066241208,-0.02946805,-0.0018107994,0.020324763,-0.04304964,0.011819603,-0.025848832,-0.027734635,0.040535238,-0.024363048,0.024229709,-0.037868444,0.012886319,-0.009371868,0.01807704,-0.011981515,8.4155734e-05,-0.0333349,0.0024786878,0.02512499,0.0135339685,0.02615361,-0.050707143,0.041030496,0.02653458,-0.027144132,0.05230722,-0.015114996,0.0005253223,0.00349064,0.023982078,0.021924838,-0.026553627,0.013476823,0.0512405,-0.04365919,-0.017477011,-0.010200479,-0.013838745,-0.018115137,-0.014819743,-0.029315662,-0.012772028,-0.019210426,-0.039659005,0.010619546,0.005524069,-0.017867506,-0.024229709,-0.004300202,0.018334195,-0.014734025,0.021410529,-0.009981421,0.016305527,0.039773297,0.010676691,-0.018953271,-0.037773203,-0.015419772,0.02268678,-0.016572207,-0.02754415,-0.0022024843,-0.016324576,0.0030310948,0.024915455,0.024534484,0.0054097776,0.0075860703,-0.004109717,-0.012962514,-0.019458057,-0.004714507,0.026801258,0.06396491,0.0002928709,-0.02013428,-0.000439604,-0.05097382,0.005119288,-0.039506618,0.015676927,0.021029558,0.07009853,0.008519447,-0.03179197,0.050516658,0.014619734,-0.16777931,0.01928662,0.044878297,-0.037354134,-0.018181806,0.038020834,-0.0301157,0.0027382239,0.0027882261,-0.007343202,0.060079012,-0.053221546,-0.02512499,0.05585024,-0.036020737,-0.0012000564,-0.0224201,-0.05162147,0.06701267,-0.03257296,-0.03036333,0.047240313,0.0134196775,-0.056574084,0.0030501431,0.008824224,0.040459044,-0.054288264,-0.0055335932,-0.012933941,-0.029506147,0.0011250528,-0.017953224,0.038878016,0.011171953,0.011105283,0.029010886,0.019962842,0.027086986,-0.01006714,0.027887024,0.07954659,-0.0026572677,0.056307405,-0.0028382286,0.028096557,0.009829033,-0.04186863,-0.024534484,-0.01447687,0.044611618,-0.025810735,-0.0217915,-0.012743455,-0.029315662,0.022229616,-0.0040859063,0.0054669236,-0.010990992,-0.0064955433,-0.039659005,-0.07135573,0.021867694,-0.031125272,-0.0448402,0.0034120649,-0.031182416,-0.012791077,0.0052573895,-0.0075813085,0.008481351,0.011219574,0.0047621285,-0.010629071,-0.019753309,-0.006828892,-0.019229474,0.0069241347,-0.015334053,-0.081146665,0.000630982,0.01523881,0.017981797,-0.0025810737,-0.019372338,-0.007690837,0.0050383317,0.004816893,0.010238576,0.23132515,0.053335838,-0.027772732,-0.026820308,0.035373088,0.009143286,-0.027791781,0.010009994,-0.004152576,-0.044002067,-0.035925496,-0.0262679,0.012981562,-0.005157385,0.022020081,0.06853655,-0.012600591,-0.022458198,0.08061331,-0.016296003,0.045678336,0.0011357677,0.033030123,-0.012152951,-0.029944263,-0.010657643,-0.025429765,0.08548973,0.012572018,0.0074908277,0.003076335,0.04164005,0.018496107,-0.009005184,0.0064717326,-0.025448814,0.007790842,-0.0756607,-0.031430047,0.016591255,0.022439148,-0.0042716293,0.034649245,0.036173128,-0.045792628,0.029906167,0.025086893,0.038420852,-0.0122291455,0.032763444,0.0043549663,-0.009386155,0.0053192973,-0.021200996,0.0072146244,-0.01935329,-0.03510641,-0.04918326,-0.04830703,0.05996472,-0.012905368,0.016067421,-0.002633457,0.0053240596,0.0011661262,0.050021395,-0.04304964,-0.017067468,0.053221546,0.05550737,0.023734448,0.011048138,-0.0256393,0.026325045,0.03474449,-0.00935282,-0.044573523,0.026782209,-0.024648776,0.04129718,0.003526356,-0.0036144555,-0.019496154,0.0055431174,0.013181571,0.025696445,0.04575453,0.05162147,0.007914658,-0.07855607,0.018677067,-0.00097147416,-0.085946895,0.05047856,-0.021334335,0.020229522,0.017143661,-0.02152482,-0.026782209,-0.0011191001,-0.007976565,-0.03215389,-0.00711462,-0.05226912,0.0036120743,-0.009990945,0.03036333,0.008919466,-0.010657643,-0.029944263,-0.0332968,-0.007443207,-0.009238529,-0.033030123,0.022401052,0.015067374,-0.0071527166,0.013048232,0.017905602,0.017305575,-0.0062193396,-0.009233767,-0.03562072,0.052192926,0.016305527,-0.01306728,-0.011048138,-0.014657831,-0.04830703,0.0538311,0.029315662,-0.01908661,-0.09882369,0.006614596,0.043621097,0.018162757,0.06476495,0.012838698,0.006614596,0.034801632,-0.03383016,0.003957329,-0.053373933,0.001704842,0.0046311696,0.014067328,-0.012048185,-0.016886506,-0.022762973,0.02664887,0.015657878,-0.0110386135,0.0036644577,-0.04186863,-0.037487473,-0.019943794,-0.03535404,0.012581543,0.0204962,0.0024739257,-0.033620626,0.037716057,0.032363426,0.032763444,0.01716271,0.019115184,0.031106222,0.02651553,0.0092813885,-0.027715586,0.04918326,0.0018679448,-0.02268678,-0.038382754,0.038097028,-0.012429155,-0.047087926,0.057678897,0.054783523,-0.028496576,0.027753685,0.0078098904,0.0098480815,0.019210426,0.01203866,0.052726284,0.005004997,-0.01626743,0.012857746,-0.03958281,-0.023220139,0.08907085,-0.01550549,-0.014905462,0.008833748,0.04091621,0.018972319,0.017143661,0.012943465,-0.0146102095,0.00807657,-0.05204054,0.0053288215,-0.00026028007,0.023429671,0.021696256,0.0020227141,0.018448485,-0.009300437,0.0027596534,0.01626743,-0.00070777134,-0.017962748,-0.014181619,-0.0666698,-0.009614737,0.05615502,0.0024334476,-0.01859135,-0.026286948,0.03984949,-0.030268088,0.043125834,-0.066441216,0.014019706,0.048268933,-0.018067515,0.0023548724,-0.007890847,0.026934598,-0.0070812847,-0.0230487,-0.010876701,-0.04327822,0.023162993,-0.05985043,0.0055621658,0.0051526227,0.004526403,-0.022439148,0.013353008,0.00076908374,0.013695881,0.009229004,0.0134482505,0.006566975,-0.016353149,-0.048726097,0.018534204,0.03163958,-0.008509924,-0.0016679354,-0.0053288215,-0.043087736,-0.034992117,0.068955615,0.04164005,0.044230647,-0.03316346,0.02421066,-0.035811204,0.052726284,0.01781036,-0.03487783,-0.06499353,-0.036839824,0.028668012,-0.0064955433,-0.043468706,-0.021772452,0.008862321,-0.01082908,-0.05024998,-0.024420194,0.0054097776,0.0077479826,-0.031601485,0.08228958,0.021334335,0.023220139,-0.039697103,-0.039506618,0.019229474,0.052345313,0.013086328,0.02369635,0.0020215234,0.049907107,0.035182603,0.0028096556,0.01756273,0.005262152,-0.026782209,0.007895608,-0.005538355,0.0022322477,-0.017410342,0.0640792,-0.04640218,0.014334006,0.003947804,-0.011333865,-0.040573332,-0.038001783,-0.038992308,0.0156007325,0.010495731,-0.07840368,-0.0055764522,0.0051811957,-0.034058742,-0.08648025,-0.005004997,-0.035030216,0.051811956,0.019381862,0.009952848,-0.000102460166,0.03230628,0.021924838,-0.024667826,-0.019162804,-0.012000564,0.0143244825,-0.014838792,-0.0054002535,0.004326394,-0.02447734,0.012638689,-0.056955054,-0.021734353,-0.011095759,-0.015105471,0.024001127,0.000843492,0.008400395,0.0065145916,-0.0037049358,0.04129718,-0.056574084,-0.00035031408,-0.022896314,0.04122098,-0.030172845,0.02306775,0.02933471,-0.03217294,-0.0144959185,0.03689697,-0.01628648,0.0010476683,0.037335087,-0.034934975,-0.038611338,0.035430234,-0.00579551,0.027887024,0.009305199,0.05611692,-0.00919567,-0.020343812,0.058898002,-0.012886319,0.008043235,-0.012057709,0.0012667262,0.029696632,-0.009462349,0.032325327,-0.005866942,0.0040454282,0.04754509,-0.014248288,-0.017667497,-0.0010613593,0.037373185,-0.040535238,0.020096181,-0.0332968,0.013438726,-0.023296332,-0.00057800335,-0.018410388,-0.014248288,0.003488259,-0.04430684,-0.017667497,-0.019581871,0.0023846359,-0.021715306,0.0005384181,0.004709745,-0.026877452,-0.03487783,-0.1319681,0.016276956,0.012952989,-0.013895891,-0.058250353,0.02550596,-0.047697477,0.0037930352,0.013762551,-0.03885897,-0.03175387,0.06484114,0.05550737,-0.010438586,-0.019753309,0.008567069,-0.022248663,0.010629071,0.018677067,0.00036340993,-0.013848269,0.011838651,0.04777367,0.013800648,-0.032706298,-0.008114667,-0.08137525,0.027448907,-0.016181713,0.02306775,-0.02664887,-0.028039413,0.020000938,0.005833607,0.052611995,0.016981749,0.005814559,-0.024629727,0.0032144366,0.026096463,-0.0011637451,0.025905978,-0.05097382,-0.014276861,-0.026077416,0.009052806,-0.019753309,0.026172657,-0.043468706,-0.05485972,0.0032906306,0.0499452,-0.012676786,0.03765891,-0.017448438,-0.023029653,-0.044611618,-0.005938374,-0.053373933,0.022077227,-0.025429765,-0.037430327,-0.03676363,-0.06423159,-0.004204959,0.029906167,-0.035715964,0.037468426,-0.012829173,0.021353383,-0.03242057,-0.030306185,0.04922136,-0.0071431925,-0.015200714,0.01859135,0.033868257,-0.011533875,-0.06164099,-0.018677067,-0.038935162,0.007752745,-0.048345126,-0.013753027,-0.02843943,-0.0049526133,-0.010057615,-0.0010863605,-0.029372808,-0.0012333912,-0.06945088,0.00029212682,-0.0010220718,-0.016676974,-0.015086423,0.005857418,0.009662358,-0.04906897,0.010657643,-0.014534016,0.0013262527,-0.046706956,0.01832467,0.0028287042,-0.029315662,0.012962514,-0.051850054,-0.053983487,-0.006200291,0.026686966,-0.034858778,0.009809985,-0.046630763,0.0030287136,-0.03436352,0.008500399,0.046630763,0.03226818,0.010800507,0.024344001,-0.0024036842,-0.015486442,0.032649152,-0.03878277,0.010009994,-0.022629634,0.038077977,-0.003671601,0.043506805,0.07512733,-0.015543587,-0.038839918,0.024305902,0.035582624,0.025658347,0.04956423,-0.06506972,0.01492451,0.0081194285,-0.029734729,0.014695928,-0.019467581,-0.008776602,-0.029734729,-0.083127715,0.009667121,0.04727841,0.021772452,-0.021924838,-0.012400582,0.055621658,-0.046668857,-0.00076194055,0.06868894,-0.009971897,-0.008038472,0.005376443,-0.036458854,0.007533687,0.008500399,-0.00217034,-0.03895421,-0.042592477,-0.00039376848,-0.03179197,0.07916562,0.0028358474,0.001973902,-0.018353242,0.012219622,-0.013181571,-0.006381252,-0.026439337,-0.038382754,0.0474308,0.014038755,0.021353383,-0.036992215,0.048497517,0.0033406331,0.04830703,-0.002335824,0.012733932,0.0423258,0.06640312,0.023258235,0.0017024609,0.034153983,0.0029906167,-0.05177386,-0.034058742,0.003895421,-0.0109528955,0.046859343,0.029258516,-0.0072574834,-0.012543446,-0.0033620626,0.011324341,0.049411844,-0.029582342,-0.006338393,-0.014657831,-0.025277378,-0.04255438,-0.0021584346,-0.030020457,0.038516093,-0.044192553,0.018886602,-0.010410013,-7.47803e-05,-0.0022691542,0.02792512,-0.0042597237,-0.01761035,-0.0024227328,0.04293535,0.010114761,0.019381862,0.01134339,0.001709604,-0.030572863,0.009057568,-0.0031715776,-0.01709604,0.0461355,0.002742986,0.013124426,0.04026856,0.00057830097,-0.05931707,0.01998189,0.039925683,-0.03590645,-0.006109811,-0.034420665,-0.050516658,-0.055964533,0.00675746,0.03099193,0.015286432,0.01523881,-0.049488038]
40	dd5862f8-1397-4395-8f4c-789f1a85dd6d	770bf3f4-921e-46be-94b3-c3aea0d3fb36	未详细说明	未详细说明	未详细说明	未详细说明	\N	待医生问诊后补充	\N	f	待医生问诊后确定	[0.025600284,0.015907424,-0.058138616,-0.010703887,-0.029755693,-0.037751146,0.021148061,-0.0011489983,0.024821145,-0.03947638,0.012855795,0.01255898,-0.023837946,0.0018690063,0.040960453,-0.016185688,-0.0148871215,-0.027214216,-0.024951002,-0.0259342,0.04066364,-0.013894647,0.041962206,0.031388175,0.017873822,0.0057183243,0.033818346,-0.046154715,0.009609382,-0.018003678,0.034078058,-0.07116137,0.000513339,-0.059325878,-0.015146835,-0.031740643,-0.014989152,-0.00801864,-0.036174316,0.0398474,0.024728391,0.010323593,0.023875048,0.051794197,-0.0025530718,-0.04704516,-0.010564755,-0.025655936,-0.039587688,-0.050347228,0.0012521878,-0.001386682,0.06199721,-0.019645436,0.03745433,0.031147012,0.026138261,0.041034658,-0.06811902,-0.030738892,0.010778091,0.0035061259,-0.036322724,-0.046525735,-0.0016904536,0.09579701,0.03370704,0.027084358,-0.017641935,-0.055689894,-0.012883621,0.012466226,0.0041878726,-0.039587688,-0.051126365,0.008788504,0.045746595,-0.034411978,0.02771509,0.018968327,0.07635563,-0.027492478,-0.036712293,-0.01771614,0.0015536405,0.005444698,0.020795593,-0.021259367,0.0012568255,-0.04363179,-0.0011675492,0.0044313534,-0.029403225,-0.019051805,-0.029941201,-0.024951002,-0.03211166,0.025859997,0.030775994,-0.017975852,0.021370672,0.021426326,0.016334094,-0.0458208,0.031017156,-0.012855795,0.020832695,0.03548793,0.031573683,0.009952574,0.022780543,0.036786497,-0.024969554,-0.023782292,-0.010926498,0.0063768825,-0.05902906,-0.016176412,0.00055275974,-0.009256914,-0.0034249655,0.024579983,-0.015313793,-0.016788593,-0.013384497,-0.0024023454,0.009572281,0.018179912,0.009952574,0.039513484,0.005416872,0.014163636,-0.025433326,-0.035302423,0.039661888,-0.02511796,-0.03426357,-0.004558891,0.007151384,-0.038734343,-0.030794544,0.06923208,-0.0065716673,-0.03251978,0.023355622,-0.08704097,0.036415476,-0.0006997179,0.0017843676,-0.00028623507,0.00787487,-0.0018539337,0.06960309,-0.028197415,-0.007911972,-0.0030980054,-0.032816596,0.034374874,0.028531332,-0.016130034,0.02413476,0.016705113,-0.008871983,-0.011408823,0.022632135,0.022854747,-0.0070215273,0.026768994,-0.016658736,0.018745715,-0.008329368,-0.009813442,0.049753595,-0.010490552,0.0070076142,0.008681836,0.05101506,-0.007986176,-0.019014703,-0.05543018,-0.02912496,-0.01276304,0.020368923,0.023207214,-0.0189405,0.004823242,0.008524152,0.011473751,0.022502279,-0.0012266802,-0.013672036,-0.040923353,-0.017298743,0.0064557237,0.04263004,-0.006664422,0.032909352,0.017001929,0.0070168898,0.0094563365,-0.049976207,0.027566683,0.013978126,0.006539203,-0.0498278,-0.02370809,-0.03507981,-0.008723576,0.033873998,-0.051682893,0.001327551,-0.027640887,-0.02354113,0.018541655,-0.040107112,-0.002098574,0.016695838,-0.007095731,0.017372947,-0.029941201,-0.003174528,0.038363326,-0.0021797344,-0.018792093,0.004044103,-0.010583306,0.018782817,0.025767243,0.0006469637,-0.02055443,-0.007884146,0.037788246,-0.026731892,-0.010119532,0.024023455,-0.009349669,0.003710186,0.012688837,-0.0035780107,0.0019014704,-0.011956075,-0.049976207,0.025989855,0.009029666,0.029032206,0.0055420906,-0.003573373,-0.040737845,-0.025563182,-0.0328908,0.013486527,-0.018059332,-0.029792795,0.003990769,0.02949598,0.0031861223,-0.018597309,0.016102208,0.015193212,0.024672737,0.033836897,0.026657688,0.0061218073,0.029273368,-0.005546728,-0.015981628,-0.036174316,0.081178874,0.02712146,0.0023536494,-0.035988804,-0.022539381,-0.044485133,-0.0025113323,0.07709767,0.014172911,-0.01075954,-0.04122017,0.019589784,0.006316592,0.023800844,0.010889396,0.008408209,0.008802417,0.0052823774,0.005430785,0.01474799,-0.062256925,-0.0064742747,-0.015156111,-0.010676061,-0.0398845,0.05405741,-0.010314317,-0.017985128,0.03309486,-0.007953712,-0.14781381,-0.010620408,0.01865296,-0.008807055,-0.0063397805,-0.018643685,-0.044373825,-0.010592582,-0.022390973,-0.021055307,-0.009711412,-0.054094516,-0.006047603,0.018819919,-0.0037380126,0.0085612545,-0.0066226823,-0.03329892,0.021407774,-0.026935952,-0.015425099,0.03947638,0.028995104,-0.026991604,-0.048492134,0.0014342188,0.037806798,-0.01843035,-0.0368978,-0.020368923,-0.015285967,-0.011538679,-0.019385723,0.013208263,0.0077311005,0.0055235396,0.00080232776,-0.038363326,-0.0019153836,0.04244453,0.023392724,0.04708226,-0.032631088,0.025266368,-0.0002505825,0.03313196,-0.018263392,0.0095166275,0.000115073744,-0.0458208,0.037769694,-0.025155062,-0.019441376,0.047935605,0.0053009284,0.031573683,-0.015666261,0.004524108,0.0060429657,0.045190066,-0.032816596,-0.112567045,0.016658736,0.04927127,-0.031054258,0.041591186,0.005551366,-0.019960802,0.012725938,0.020777043,0.033781245,0.007949074,-0.0010794323,0.036619537,0.01802223,0.018690063,0.011121283,-0.029625837,0.00039536672,-0.11627723,0.017586282,-0.0059919506,0.018365422,0.030126711,-0.0048696194,-0.0737956,-0.02650928,0.041776694,0.0638152,0.2754442,0.050940856,0.0113067925,-0.050495632,-0.0028707564,-0.025470428,-0.0498278,0.01951558,0.039550584,-0.049568087,-0.04203641,-0.028772494,0.023058807,-0.03283515,0.004389614,0.05157159,-0.037751146,0.010611133,0.10010082,-0.0047490383,-0.02530347,0.016074382,0.020610085,0.004092799,0.01613931,-0.078359134,-0.015786842,0.058880653,0.0059223846,-0.035580683,-0.014293492,-0.0051757097,0.04203641,-0.025155062,-0.004809329,-0.011585056,0.018699339,-0.018356146,-0.036155764,0.018365422,0.0056116567,-0.024227515,0.015638435,0.022557931,0.033725593,-0.028995104,-0.01855093,-0.023170112,-0.026935952,-0.044077013,0.00400932,0.00558383,-0.022298219,0.008171685,0.022483729,0.010230838,-0.010444174,-0.052202318,-0.0025437963,0.049568087,-0.0008498645,0.027863499,-0.036990557,0.009702137,0.015842495,0.044967458,-0.032816596,-0.004776865,0.0054354225,0.052647542,-0.035599235,0.007879508,-0.026564933,0.020517329,0.017363671,0.011918973,-0.0052684643,0.07887856,0.019014703,0.011668535,0.007536316,-0.016306268,-0.040737845,-0.041145965,-0.0057832524,0.023893598,0.04441093,0.045152966,0.024171863,-0.02133357,0.056320626,0.0077264626,-0.03725027,-0.0259342,0.013894647,0.0045380215,0.0209069,-0.016695838,-0.025785794,0.018513829,-0.006701524,-0.01574974,0.020109208,0.012429124,0.0062423884,-0.08674415,-0.022446627,0.047379076,-0.015861046,-0.015805393,-0.0024603172,0.027882049,-0.032408476,-0.011436649,0.04426252,0.01503553,-0.017604833,0.030646138,0.023615334,0.027566683,0.007619795,0.02953308,-0.004410484,0.046896752,0.029941201,-0.008510239,0.00070493534,-0.039810296,-0.018207738,0.021871548,0.0010203011,-0.024190413,-0.07501996,0.0013403047,0.02133357,-0.0006133401,0.03806651,0.017781068,0.035191115,0.06915787,0.018096432,0.008658647,-0.032853696,0.009924748,0.004677153,-0.032983556,0.004925272,0.002411621,-0.01016591,0.004860344,0.053129867,0.015972352,0.038140714,-0.023949252,-0.02233532,0.034040958,-0.03667519,0.008417484,-4.6522255e-05,-0.026954502,-0.0010214606,0.028345821,0.006951961,0.06797061,0.030238017,0.011362445,0.022428075,-0.01574974,0.049085762,-0.008774591,0.00807893,0.019793844,-0.00593166,-0.036322724,0.017465701,-0.014172911,-0.052276522,0.015610608,0.048529234,0.037009105,0.01245695,-0.034133714,0.04522717,0.047267772,0.02932902,0.034782995,0.018671513,-0.014812918,-0.012605357,0.008389658,-0.04429962,0.1056661,-0.02851278,-0.009331118,0.036563884,0.0066876104,0.024338821,0.024839696,-0.008500964,-0.02953308,0.023003154,-0.04263004,0.010472001,0.013532904,-0.015387997,-0.009178073,0.02053588,-0.007898059,-0.033428777,0.06325867,-0.0062191994,-0.008830243,-0.0339111,-0.012679561,-0.01562916,-0.013022753,0.04403991,0.023837946,-0.046562836,-0.017790342,0.01376479,-0.019682538,0.05405741,-0.06414912,0.029774243,0.022632135,-0.029681489,-0.02073994,-0.012104482,0.022409525,0.0019281374,-0.07687505,-0.024672737,-0.009637209,0.01325464,-0.00023985773,-0.0026249567,0.021556182,-0.020276166,-0.028141761,-0.039142463,-0.02151908,0.016204238,0.041776694,-0.016788593,0.025470428,-0.005110781,0.005412234,0.018996153,0.043149464,-0.015323069,0.00075653015,0.030534832,-0.039661888,-0.011223313,0.00087247347,0.00028913363,-0.009108507,-0.014757265,0.007633708,-0.019348621,0.053723495,-0.0013982764,0.013134059,-0.018690063,-0.0066041313,-0.013421598,0.030349324,-0.03213021,-0.006316592,0.009038941,-0.019756742,0.0027269868,-0.003819173,0.0077079115,0.009178073,-0.03704621,0.06926917,0.0055745547,0.020610085,-0.016538154,-0.014070881,-0.025600284,0.024654187,0.009303291,0.029848447,0.03947638,0.045078762,0.01593525,0.010240113,-0.04444803,-0.0308873,-0.03287225,0.029458879,0.0059409356,-0.0063907956,-0.050718244,-0.015313793,0.008788504,0.032853696,-0.020962551,-0.0076800855,-0.009270827,-0.034319222,-0.009637209,-0.016130034,-0.016111484,-0.024839696,-0.013236089,-0.017827444,0.034207918,-0.015360171,0.031536583,-0.013607108,0.02530347,0.003241775,-0.017586282,-0.008992564,-0.040923353,0.0011820421,0.043520484,-0.04003291,0.009822718,-0.01585177,-0.027770743,0.0019849497,-0.03268674,0.006599494,-0.012095206,-0.0112789655,0.008171685,-0.028828146,-0.010008227,-0.038326222,-0.004282946,-0.021092407,0.0009501555,-0.02053588,0.02970004,-0.046154715,-0.009665035,0.037639838,0.03563634,-0.0009460975,-0.0052313623,-0.03502416,-0.024004905,0.026973054,0.026787544,0.02929192,0.039179567,0.050940856,-0.00503194,-0.020164862,0.007067905,-0.026880298,-0.027195664,-0.021500528,0.05424292,0.028568434,-0.013477251,0.004753676,-0.04263004,0.048306625,0.0057276,-0.0075595044,0.000871314,0.032464128,0.00079247257,-0.015517853,-0.044744845,0.077394485,0.023058807,-0.006938048,-0.03806651,0.012308543,-0.022520829,-0.041591186,-0.002622638,0.005310204,-0.018903399,-0.014274941,-0.028253067,-0.069120765,0.042555835,-0.010462725,-0.058064412,0.004772227,0.008807055,0.015304518,-0.012902172,-0.0024835058,-0.048677642,0.012568256,-0.17007494,-0.005913109,0.019868046,-0.029032206,-0.02309591,0.0076429835,-0.081104666,0.026824646,-0.01732657,0.00842676,-0.0004371063,-0.016148586,0.045895003,-0.02053588,-0.039810296,-0.0031722093,0.009298654,-0.008640096,0.018161362,0.06418622,-0.0020382835,-0.02710291,0.05008751,-0.013857545,-0.019422824,-0.04110886,0.005426147,-0.0021484296,-0.023559682,0.056765847,0.040997557,-0.03450473,0.0015003065,0.015480752,0.04467064,-0.041888002,-0.022687789,0.0015582782,0.017317293,0.011056354,0.024617085,0.021500528,-0.0013008841,-0.022261117,0.019163111,-0.027084358,-0.037955206,-0.0063073165,0.016092932,-0.037825346,-0.045041658,0.029625837,0.05921457,-0.0014284217,-0.0059548486,-0.0004385556,-0.018383972,0.028067559,-0.0034133713,0.056135118,0.029737141,-0.018782817,-0.006608769,0.014738714,-0.00881633,0.0032927901,-0.045190066,0.012336369,0.007267327,-0.009952574,-0.027084358,0.018356146,0.011084181,-0.017966576,0.01603728,0.01873644,0.017892372,-0.019014703,-0.08889606,-0.017298743,0.020035004,0.003749607,-0.01843035,-0.026973054,-0.07821073,0.0130691305,-0.03786245,-0.002323504,0.0040325085,-0.026360873,-0.032593984,-0.039698992,-0.024765493,-0.018254116,-0.050347228,-0.031963255,0.001648714,-0.04901156,-0.028364373,0.008157772,-0.036767945,-0.011130558,-0.012531154,-0.02773364,-0.01476654,0.016065106,-0.026138261,0.015712637,0.031017156,0.016130034,0.021556182,0.020981103,-0.009168797,0.013486527,-0.038548835,-0.010870845,0.017122509,-0.005546728,-0.025563182,0.030998604,-0.0059594866,0.008950824,-0.021092407,-0.040107112,0.0075270403,-0.0044545424,0.06793351,0.0007437764,0.0063258675,0.072200224,-0.0039490294,-0.05197971,-0.016009454,0.03348443,0.00017768313,-0.0048139663,-0.045598187,0.021593284,-0.00074667495,-0.041368574,0.0239307,0.0031838035,0.0072905156,-0.0148685705,-0.02571159,-0.025414774,0.0112604145,-0.0085983565,-0.06934338,-0.024450127,0.07754289,-0.019292967,-0.0018933543,0.014070881,-0.00035942427,0.030442078,-0.03851173,0.0075548664,0.012141584,0.0035849675,-0.013941024,-0.005695136,-0.015425099,-0.0053055664,-0.018411798,0.018523104,0.012419848,-0.01106563,-0.039253768,0.015406548,0.018903399,-0.0020011817,-0.017753242,-0.00091479276,0.01875499,-0.0094609745,-0.014376971,-0.05298146,0.05876935,0.04025552,0.019422824,0.034727342,0.04044103,-0.014163636,0.041888002,0.024765493,0.048788946,-0.015619883,0.019552682,-0.016194962,0.0023629249,0.0028869887,0.0075780554,-0.0013055217,0.039216667,-0.012994927,-0.024079109,0.08140148,-0.02292895,0.044373825,-0.034003858,-0.0057832524,-0.045598187,-0.015016979,-0.032371376,0.019033255,-0.019663986,0.0013147972,-0.0087143,0.017020479,0.01106563,-0.010323593,-0.019589784,0.05223942,0.013690587,-0.039773196,-0.012753765,-0.03708331,0.019793844,0.0014423348,0.007183848,0.053055663,-0.061440684,0.028605536,0.03469024,0.005913109,0.011594332,0.011854045,-0.02172314,-0.014979877,-0.023429826,-0.029477429,-0.024598533,0.037213165,0.023392724,-0.015276692,0.014061606,-0.014599582,0.0036730843,0.0015594376,0.009294016,0.0067710895,0.012382747,-0.037138965]
41	4ce1e3cb-b2f5-4b55-b72d-961d1f456897	58d7aa50-693c-4040-affd-0650ece6f4d0	未详细说明	未详细说明	未详细说明	未详细说明	\N	待医生问诊后补充	\N	f	待医生问诊后确定	\N
42	f3462528-01a5-422d-951f-bec0f95b3e35	98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a	无	无	无	未详细说明	无	待医生问诊后补充	头晕排查无异常	t	多休息	[-0.031076912,0.015963005,-0.039850906,-0.036529996,-0.019585814,-0.012113769,0.019142397,0.052568473,0.046756886,-0.022604821,0.0009882534,-0.0044766227,0.00416057,0.0049766456,0.012057163,0.004545022,0.013057209,-0.02781261,-0.03703945,-0.012245851,-0.013453454,0.007604126,0.010255192,0.0009121885,-0.039888643,0.026793694,-0.0030378767,-0.0059248027,0.022585953,0.009811776,-0.0020437269,-0.050681595,0.04728521,0.0037973458,-0.0012995886,-0.043624662,-0.031699583,0.006566342,-0.02937872,0.02201989,0.06592759,0.0005934827,0.0155573245,0.020208484,0.03851122,-0.019038618,-0.032341123,-0.021944413,0.0027477688,0.008920224,0.02592573,0.0165102,0.045662493,-0.04490774,0.009698562,-0.041058507,0.025246453,-0.016717756,-0.006523887,0.0008384823,-0.03943579,0.009212691,-0.021736857,-0.02011414,0.051889196,0.07026741,-0.007255053,0.0064342604,-0.022680296,-0.028718311,0.0011427416,-0.019774502,-0.003884614,-0.017849883,-0.04951173,0.011604312,0.027567316,-0.049172092,0.013208159,-0.0049766456,0.056795087,0.023284098,0.0021887808,0.023529392,-0.022925591,0.01683097,-0.0010259909,0.023378443,-0.044077516,0.018387645,-0.022850115,-0.019378256,-0.03551108,-0.017406467,-0.006354068,-0.0050238175,0.012962865,0.008113584,0.029435327,-0.011123157,0.011132591,0.041700047,0.041813258,-0.025095502,-0.0023975167,0.0048823017,0.009311752,0.035435606,0.05298359,0.005061555,0.008226796,0.027472971,0.018623505,0.0027336173,-0.0071607092,-0.000528916,-0.015746012,-0.03283171,-0.059021603,-0.0015000695,0.0019800446,-0.0006256186,0.0027855064,0.0147459665,0.0002772829,0.0433605,-0.025114372,-0.0071229716,0.010877863,0.01012311,-0.027152201,-0.013010037,-0.036643207,-0.03109578,0.007089951,-0.01814235,-0.004221894,0.0672484,-0.03226565,-0.0036581885,0.007717339,0.09517422,0.029586278,-0.005995561,0.039133888,-0.046417248,0.037662122,0.060191467,0.0430586,-0.036001667,0.0052926983,0.015170515,0.035095967,0.045587018,0.022567084,0.025510617,-0.043549187,-0.0077031874,0.00284683,0.008868336,-0.008410768,0.032793973,-0.026661614,0.025246453,-0.026435187,0.0057030944,-0.029642884,0.0016156409,-0.00026843816,-0.014500672,0.017491376,-0.015830923,-0.01767063,0.019378256,-0.034171395,0.021416087,0.053511914,0.020000927,0.0069059804,-0.032661892,-0.034341216,-0.029869309,0.0020590576,-0.005806873,-0.029303245,0.022736903,-0.009679694,0.008571152,0.023604868,-0.0049766456,-0.014076124,-0.037284747,0.035473343,-0.024491701,-0.017330991,0.0030024976,-0.042152897,-0.050681595,-0.035360128,0.023001065,0.017944228,0.042492535,0.04573797,-0.008297554,-0.026020074,-0.010085373,-0.028567363,-0.013755354,0.0041511357,-0.08090941,-0.03615262,0.004585118,-0.0442662,0.013849699,-0.00058345863,-0.032869447,0.034001578,-0.012443973,0.04871924,-0.04920983,-0.023114279,0.008500394,0.029737227,-0.011764696,-0.008637193,-0.016632846,0.010689175,0.0731732,0.020453779,0.004887019,-0.029001344,0.054342143,-0.012123204,-0.014915786,0.042492535,-0.04600213,-0.011953385,0.01406669,0.02198215,-0.001115028,0.02028396,0.03473746,0.08023013,-0.005476669,-0.034963883,0.005953106,0.02341618,0.005877631,-0.024133194,-0.013142118,0.005151182,-0.027435234,-0.024699258,0.031775057,0.031152388,-0.005405911,-0.00050798344,0.00019694309,-0.009137216,0.0027100313,0.013727051,-0.023831293,0.023491655,0.048832454,-0.004096888,-0.022850115,0.009080609,0.023378443,0.01782158,-0.0024883228,0.0055662957,0.00823623,-0.02545401,0.045285117,0.00012839628,-0.00318411,0.011906212,0.0040001855,0.014576147,-0.0241898,0.005273829,0.021019842,0.034680855,0.019114094,0.012085466,-0.017170608,0.013991214,-0.0286051,-0.013500626,-0.010038201,0.032152433,0.008311706,0.08332462,-0.0025402121,-0.05373834,0.011321279,0.03802063,-0.16227168,0.00092339184,0.031661846,-0.02294446,-0.03802063,0.015019564,-0.015472415,-0.006943718,-0.009868382,-0.02924664,0.058795176,-0.050681595,-0.008764558,0.02952967,-0.030925961,0.0034270457,0.004118115,-0.02041604,0.0386433,-0.024925683,-0.04920983,0.05604033,0.03549221,-0.071097635,-0.043096337,-0.014491238,0.037341353,-0.034077052,-0.0046771034,-0.01753855,-0.029963654,0.00065215287,-0.026133286,0.019274479,0.0119156465,0.04430394,-0.0125005795,0.016944181,-0.0013514777,-0.015378071,0.018661242,0.03898294,-0.009118347,0.029095689,0.021114185,0.012613792,0.009972161,-0.052719425,-0.0042171767,-0.009943857,0.030869355,0.00031163002,-0.045813445,0.020604728,-0.029869309,0.0073258113,0.026133286,-0.0061040567,0.029605146,-0.014028952,-0.045775708,-0.096834674,0.030435372,0.013019471,-0.030416504,-0.010462749,-0.03583185,0.00085145456,0.005688943,-0.00010901154,-0.0075946916,-0.050794806,0.0013856775,0.011821303,-0.040794343,-0.005330436,0.0067031407,0.02656727,-0.017189477,-0.11917534,-0.0118496055,0.028510755,0.011075985,0.02968062,0.00030838692,-0.011113723,0.021472692,-0.030963698,0.03175619,0.2833339,0.02201989,-0.017000789,0.0028562644,0.038624432,-0.009745735,-0.0156328,0.059097078,-0.008854184,-0.027680527,-0.06615401,-0.004368127,-0.017595155,0.012151507,0.021019842,0.039662216,-0.051436346,0.00864191,0.06947492,-0.03756778,0.044870004,-0.013349676,0.018189522,-0.017170608,-0.031454287,-0.018198956,-0.025963467,0.089664534,0.021472692,-0.02968062,-0.041586835,0.012660964,0.021246267,-0.010368405,-0.014019518,-0.002559081,0.022529347,-0.059738617,-0.042945385,0.022736903,0.019944321,-0.041058507,-0.016198864,0.028039036,-0.038567826,0.018557465,0.004061509,0.054945942,-0.0056087505,-0.021793462,-0.007528651,-0.0037714012,-0.0058681965,-0.010915601,-0.011160894,-0.02656727,-0.029190032,-0.020359434,-0.028642837,0.05358739,0.011368452,0.020340566,-0.021661382,0.018255563,0.016689453,0.018510291,-0.042907648,-0.01640642,0.055738434,0.020963237,0.04177552,-0.004849281,-0.019925453,0.028737182,0.035699766,0.015981873,-0.0430586,0.044832267,0.021434955,0.034397822,0.0027902236,-0.028699443,-0.0034317628,0.016698888,0.008651344,0.017000789,0.03802063,0.05939898,0.009429682,-0.041096244,0.010868428,-0.001105004,-0.06015373,0.06362559,-0.05120992,0.023604868,0.0066654035,-0.03739796,-0.005571013,0.023397312,-0.021548169,0.011509967,-0.017547984,-0.030624062,-0.019029183,-0.028831525,0.0070757996,0.0050143832,-0.02013301,-0.0030567455,-0.051775984,0.0077597937,0.0064625638,-0.043586925,-0.008797578,0.02262369,-0.00955233,0.013160988,0.01979337,-0.025586091,-0.013859133,-0.0061229253,-0.035699766,0.04570023,0.018491423,-0.017632892,-0.019661289,-0.017736671,-0.053964764,0.058002688,0.014887483,-0.0077314903,-0.062342513,0.013311937,0.040416967,0.0017878187,0.07547519,0.022812378,0.009689128,0.018453686,-0.014962957,0.026189893,-0.03424687,0.027756004,-0.0011055938,-0.014274246,-0.0038681037,-0.04822865,0.01664228,0.009009851,-0.009670259,-0.002771355,0.031246731,-0.030227816,-0.021038711,-0.03939805,-0.053059064,-0.003573279,0.045624755,-0.013349676,-0.017632892,0.016519634,0.041926473,0.054342143,-0.0018845213,0.027756004,0.0033327017,0.027756004,0.03034103,-4.8314443e-05,0.033209085,0.006000278,-0.03326569,-0.012708136,0.022435002,-0.011245804,-0.046379507,0.051096708,0.069323964,-0.0330204,-0.0082551,-0.010189151,0.022057626,0.023114279,0.05200241,0.04430394,0.029359851,-0.011283542,-0.009127782,-0.037775334,-0.037492305,0.1138166,-0.025321929,-0.025133241,0.009924988,0.0027619204,0.010915601,0.03471859,0.0056653568,0.003660547,0.015066736,0.0014812007,0.011604312,0.022963328,0.014849745,0.018585768,-0.021453824,-0.0004106912,0.016368683,-0.011264673,0.023114279,-0.014670491,-0.019755634,-0.005943672,-0.03443556,0.0005215454,0.030567454,0.023680342,-0.044417154,-0.029095689,0.036096014,-0.01578375,0.014019518,-0.06464451,0.007877723,0.045020953,-0.0035921477,0.0034765762,-0.037813075,0.023152016,-0.0018727283,-0.003566203,0.022491608,-0.03679416,0.010594831,-0.06822958,0.033944968,0.02354826,-0.009745735,-0.019359387,0.020434909,-0.017472507,0.011943949,0.04166231,-0.0118496055,0.046870098,0.008250383,-0.047662586,0.020491516,-0.010179717,-0.02185007,-0.016934747,-0.00230789,-0.02200102,-0.043549187,0.073286414,0.005471952,0.0133779785,-0.019604683,0.009792907,-0.009981595,0.07400343,0.017302688,-0.01743477,-0.046115346,-0.072229765,0.026529532,0.03269963,-0.053059064,-0.024604915,-0.029171163,0.00089744723,-0.033812888,-0.034020446,-0.030586323,-0.009094761,-0.030265553,0.019887714,-0.0035095967,-0.009745735,0.008486242,-0.060908485,0.024321882,0.02137835,0.020170746,0.018198956,0.021887807,0.033360038,-0.002323221,0.01790649,0.027869217,-0.013227028,-0.05105897,0.04871924,0.010896731,0.019378256,-0.047360685,0.027510708,-0.04713426,0.027378628,-0.020189615,-0.0153308995,-0.035379,-0.018576333,-0.04071887,-0.04083208,-0.0072644874,-0.05939898,-0.033548724,0.011632615,-0.0043233135,-0.061663236,-0.011925081,-0.037492305,0.029322114,0.0039082,0.021453824,-0.007981502,0.03128447,0.019699026,-0.017387599,-0.009358924,-0.031039175,-0.03366194,-0.024699258,-0.011519402,0.0009912016,-0.008009805,0.005377608,-0.02088776,-0.013934609,-0.03800176,-0.024378488,-0.006632383,-0.03173732,0.0076654498,-0.005330436,0.02969949,0.046228558,-0.035794113,-0.008684365,-0.036077145,0.03645452,-0.0053068497,-0.009297601,0.0007895413,0.0070710825,-0.0042761415,0.016906444,0.004320955,0.0009817672,-0.0011610208,-0.03237886,-0.053210013,0.06555021,0.050077792,0.040907558,-0.012915693,0.07128632,0.010547658,-0.026944645,0.025038896,-0.0215293,0.0045780423,-0.028680574,0.02026509,0.038039498,-0.02058586,0.07041836,-0.014028952,-0.0092174085,0.03677529,-0.002429358,-0.030265553,-0.011736393,0.03235999,-0.008783426,-0.020680204,-0.032869447,0.018472554,-0.001996555,0.01501013,-0.041813258,0.008679648,0.040869817,-0.043624662,-0.0067597474,0.03662434,0.008802295,-0.009934423,-0.012962865,-0.058191378,-0.0065474734,-0.01964242,-0.13834603,0.008637193,-0.0107457815,-0.018387645,-0.06064432,0.008160756,-0.051285397,-0.003101559,0.01981224,-0.034322344,-0.035737507,0.0027218242,0.033227954,-0.015566759,0.005943672,0.037643254,0.008118301,-0.009962726,0.014019518,-0.0028491886,-0.013132684,0.00522194,0.052077886,0.037964024,-0.004776165,-0.01603848,-0.044379417,0.00805226,-0.02356713,0.027303152,-0.031171257,-0.030095734,0.0070663653,0.020755678,0.053360965,0.03141655,0.005316284,-0.027888086,0.027756004,0.000495306,-0.009618371,0.026755957,-0.04781354,-0.03185053,-0.010575962,0.0074343067,0.040869817,0.021170793,-0.0016757852,-0.0014316702,-0.0095098745,0.021133054,-0.016868707,0.048530553,-0.023850162,-0.0427567,-0.031039175,-0.005646488,-0.025699304,0.021717988,-0.014727098,-0.028680574,-0.05622902,-0.061323598,0.004594553,0.03707719,-0.021906676,0.043926563,-0.029888177,0.008901356,-0.0362847,-0.040794343,0.03739796,0.030963698,-0.017566852,0.032624155,0.017651761,-0.0002703545,-0.030416504,-0.030076865,-0.03505823,0.012594923,-0.03519031,0.0003422918,-0.024925683,-0.009887251,0.0038751797,-0.017123435,-0.056530923,0.017746106,-0.03724701,-0.037322484,0.014670491,0.009330621,-0.016142258,0.014878048,-0.0076654498,-0.05094576,-0.010321233,-0.010085373,-0.0031628825,-0.06158776,0.023170885,-0.032643024,0.004226611,0.02401998,-0.030227816,-0.023359573,0.0012347271,0.016170561,-0.075814836,-0.029944785,-0.028208856,0.02201989,-0.028378673,0.013953477,-0.0031204277,0.022510476,-0.0054530827,0.028039036,0.00017881136,-0.024001112,-0.018406514,-0.016246036,0.020680204,-0.026925776,0.024887946,-0.010604265,0.018189522,0.03596393,0.0027831479,-0.07524877,0.007622995,0.0022902004,0.024057718,0.05120992,-0.027737135,0.011811868,0.022982197,-0.036699813,0.02390677,-0.016368683,0.028623968,-0.03519031,-0.03315248,0.02735976,0.008528697,0.007080517,-0.015981873,0.0027454102,0.034284607,-0.005523841,-0.01625547,0.10732573,-0.010755216,0.005358739,0.0066040796,0.017632892,0.008358878,0.032454334,0.0049860803,-0.020434909,-0.051625036,-0.047021046,-0.007929613,0.05581391,-0.004719558,-0.008849467,-0.045398332,0.01775554,0.0017489018,-0.016198864,-0.016972484,-0.04271896,0.041624572,0.011566574,0.002292559,-0.029095689,0.052191097,0.003070897,0.036228094,0.017812146,-0.018510291,0.013198725,0.00400962,0.019661289,0.03171845,0.03928484,0.010321233,-0.023642605,-0.012783611,0.0015590346,-0.024887946,0.011019379,0.04664367,0.01696305,0.0062502897,0.015189383,0.016604543,0.04068113,-0.0007630071,-0.00069873524,-0.0030331595,-0.054493092,-0.034228,0.0055379923,0.0024741713,0.022510476,-0.025038896,0.013642142,-0.031642977,-0.0015366279,0.033360038,0.03500162,-0.015047867,-0.007571106,-0.03334117,-0.00037118467,-0.008745688,0.03639791,0.025887992,0.026982382,-0.03962448,0.0054955375,0.00033580567,-0.01640642,0.010566527,0.013311937,0.012160941,0.02530306,-0.021906676,-0.019359387,0.008585304,0.027076727,-0.02656727,-0.0042808587,-0.0442662,-0.02198215,-0.07626769,0.014585582,-0.007825835,-0.007038062,0.04083208,-0.029925914]
43	259ed7a8-313c-40bf-af3a-205742e4c8de	758cc9fb-f779-4c68-9523-6a4726430a40	未详细说明	未详细说明	未详细说明	未详细说明	\N	待医生问诊后补充	\N	f	待医生问诊后确定	[-0.013316657,0.01798552,-0.042227697,-0.036519207,-0.038711872,-0.010821556,0.027578428,0.040148444,0.03447776,-0.039543573,0.02411931,-0.029657679,-0.019847395,0.0056895865,0.031037547,-0.00064681243,0.023098588,-0.032436315,-0.009484219,0.0029204024,0.009673242,0.011416978,-0.049108125,0.023041882,-0.0347991,0.02784306,0.0038796933,-0.012040753,0.015480968,-0.015490419,-0.0049240445,-0.024894305,0.012749589,-0.0046665007,-0.0037166611,-0.016662361,0.02502662,0.025253449,-0.033664964,0.014129455,0.031094253,0.05235932,0.027332699,-0.0031283274,0.022323593,-0.030508282,-0.024799792,-0.0091109,-0.013855373,-0.037596636,0.030016823,0.026614413,0.018599845,0.0002215111,0.0060534556,0.01433738,-0.033967398,-0.020868119,-0.07035429,-0.0066819564,-0.037634443,-0.019185815,-0.019847395,0.0056895865,-0.0053304434,0.11235516,0.036897253,-0.012645626,0.0015972428,0.008009842,-0.024308333,0.012872454,0.055875145,-0.016312668,-0.0488813,-0.006247204,0.028183302,-0.020338854,-0.013883726,-0.0033173503,0.053228825,-0.016841933,0.005287913,0.029374145,-0.016444985,0.03704847,0.042605743,-0.015613284,-0.027672939,0.00056411495,-0.0029818348,0.0031472298,0.0005437359,-0.00201073,-0.031132057,-0.003177946,-0.028447933,-0.015811758,0.02478089,-0.014110553,-0.0058786096,-0.010452962,0.037804563,-0.018429724,0.0223614,0.0018736887,-0.030092431,0.017172722,0.03237961,0.0027361051,0.032587532,-0.002662859,-0.016048037,-0.046348393,0.017598024,-0.018250152,-0.011577647,-0.043853294,0.0093424525,-0.009550378,0.03495032,0.0064409524,-0.01872271,-0.022229083,0.014309027,0.0455923,0.0629446,0.028277813,0.00861944,0.02948756,0.0032795458,0.010821556,-0.03502593,-0.016057488,-0.048578862,0.008019293,0.01996081,0.01632212,0.009077821,-0.03621677,-0.024138212,0.058105614,-0.0013928618,-0.02113275,0.004737384,-0.08150664,0.007731033,0.008936053,0.023703462,-0.0053729736,-0.01946935,-0.06487263,0.011709963,0.006960765,0.05417394,0.044155728,-0.029430851,0.036160063,0.030432673,-0.017465709,0.0894456,0.02510223,0.014961155,0.052926388,0.028561346,-0.0077074054,0.038144805,0.051565424,0.009394433,0.01483829,-0.03205827,-0.052737366,0.0047586495,0.0008234306,-0.01068924,0.029430851,0.091033384,-0.0017531866,0.0050658113,-0.069484785,-0.022323593,-0.045252062,0.034591176,-0.013902628,-0.0013597829,-0.01857149,-0.010226134,0.030527184,0.0076034428,0.018968439,-0.0013066202,-0.04615937,-1.9382222e-05,-0.0178154,0.061659243,0.015008411,-0.016312668,0.01209746,-0.03544178,0.012721235,-0.021019336,-0.0068331747,0.06441897,-0.0016622194,-0.029789995,-0.00604873,-0.059390966,-0.051489815,-0.018703807,-0.033683866,0.0155471265,-0.013997139,-0.016511142,-0.04797399,-0.01904405,-0.061016563,0.021491894,-0.0074616754,0.018495882,-0.03736981,-0.019677274,0.023419926,-0.000978193,-0.057462934,0.013845921,0.0045578126,0.060638517,0.023684558,0.043739878,-0.030205846,-0.009247941,0.01632212,-0.032266196,-0.0031519553,0.07901154,-0.005070537,-0.006015651,-0.0017992608,0.01259837,0.033003382,0.06181046,-0.025461372,0.025839418,-0.006256655,-0.012588919,0.021869939,0.02948756,0.0063747945,-0.026614413,-0.008435143,-0.01549987,0.0138364695,-0.061281197,0.008038195,0.046688635,0.023590047,-0.011747768,-0.00081988645,-0.021435186,0.025952833,0.033948496,0.031699125,0.024516258,0.027767451,-0.004141962,-0.015405359,-0.017323941,0.07549571,0.032285098,-0.022096766,-0.037426516,-0.008444594,-0.02684124,0.0027786354,0.048314232,-0.0052217552,0.011369722,-0.010812105,0.007844447,-0.021832135,-0.0002808761,0.017635828,-0.019941907,0.037521027,0.022304691,0.0014082199,-0.022777248,-0.016170902,0.00811853,-0.013203244,0.0049334955,-0.046424,0.07409694,0.0092526665,0.0042955433,0.020206539,0.007778289,-0.16225718,-0.003969479,0.008709226,0.024346137,-0.02255042,0.0069465884,-0.037218593,-0.0039505768,-0.026368683,-0.041471604,-0.0030078255,-0.042492326,0.0013656898,-0.012730686,-0.022588227,0.009923697,-0.016426083,-0.033438135,-0.018212348,-0.06267996,-0.032001562,0.0020993345,-0.0028164398,-0.0049760253,-0.013741959,0.028807076,0.07035429,-0.053493455,-0.044382557,0.007806642,-0.03869297,0.008137432,-0.026047343,0.043815486,-0.005491113,-0.0050894395,0.0380881,0.012390445,0.034288738,0.0008234306,0.029903408,0.087857805,-0.0015996055,0.015197434,0.028126594,-0.0025919753,0.03296558,-0.02270164,-0.036254574,-0.046348393,0.046613026,-0.021510797,0.0074427733,0.012645626,-0.013307206,-0.009271569,-0.001104602,0.06067632,0.017862655,0.010764849,0.029752191,-0.075344495,0.016142549,0.02617966,0.008487124,-0.014479147,-0.046764243,-0.007301006,-7.895948e-06,-0.04135819,0.02270164,-0.03572531,-0.003969479,0.019790689,0.038069196,-0.00749948,-0.010585277,-0.008567459,0.0136758005,-0.12611602,-0.02444065,0.016974248,0.012380994,0.035328362,-0.012380994,-0.05784098,0.02907171,0.051565424,0.023476634,0.25329056,0.021756526,-0.0126550775,-0.0074427733,0.060827542,0.004985477,-0.05485442,0.03761554,-0.026311975,-0.021964451,-0.05761415,0.015131276,0.009318825,-0.015925173,0.029657679,0.057462934,-0.038749676,0.03818261,0.07923836,-0.0071308855,0.010339548,-0.0372753,0.030640598,-0.0064929337,0.010594728,-0.053795893,-0.019526057,0.047671553,0.0062188506,-0.015235239,-0.054741006,-0.004366427,0.032020465,-0.012503859,-0.02294737,-0.023136392,0.021208359,-0.030848524,-0.018325761,0.014072749,0.0063322643,-0.06370069,0.0076506985,0.032039367,0.018335212,-0.028296715,-0.002184395,0.04581913,-0.03132108,-0.030035725,-0.010093818,-0.049183737,0.00032074808,-0.01823125,-0.02659551,-0.03886309,-0.036386892,-0.014800486,-0.028807076,0.031415593,0.019923005,0.0006249567,-0.02194555,-0.0134962285,0.022172377,0.021586405,-0.036727134,0.035366166,-0.010131623,0.0364436,0.05145201,-0.017919363,0.004619245,-0.020017516,0.02808879,-0.0004164409,-0.04033747,0.037426516,0.03124547,0.004872063,0.0026368683,-0.01598188,-0.040148444,-0.046197176,0.019790689,0.03058389,0.05103616,0.059126336,-0.0109538715,-0.021491894,0.019166913,0.0104435105,-0.070959166,-0.00016273683,-0.027030261,0.005665959,0.04748253,-0.015159629,-0.00065094733,0.05674465,0.002024907,-0.024913207,-0.028731467,0.033116795,-0.0060629067,-0.03961918,-0.009167606,0.011057834,-0.038579557,0.03421313,0.0068331747,0.0008311097,-0.0019185815,-0.008293376,0.034515567,0.01971508,-0.031793635,0.014101102,0.02841013,0.00944169,0.008057097,0.018335212,-0.03033816,0.053606868,0.0035229127,-0.025158936,0.02213457,-0.0207169,-0.0281644,0.04426914,-0.007972037,-0.03546068,-0.07557132,-0.015679441,0.058408048,0.015443164,-0.010263938,0.029846702,-0.012466054,0.059050728,-0.01516908,0.010490766,-0.022758346,-0.012210874,0.028712565,-0.011502038,-0.00012877179,-0.009744126,0.00737189,0.030697305,0.05228371,0.06354947,0.040261857,-0.021567503,0.00064090546,-0.04937276,-0.024761988,0.005784098,-0.022815054,-0.028769271,0.024327235,0.021775428,0.06559092,0.08067494,0.012106911,-0.017692536,-0.0037001215,0.008671422,0.048503254,0.0014094013,-0.023608949,-0.02774855,-0.037350908,-0.0012900807,-0.012059655,-0.0056706844,-0.063625075,-0.020660194,0.033116795,0.06422995,0.0067811934,-0.04838984,0.019062951,0.03761554,0.048994713,0.024629673,-0.003343341,-0.007749935,-0.0024171292,-0.006143241,-0.012787393,0.09670407,0.017361745,-0.02825891,0.056782454,0.006993844,0.021907743,0.0075042057,0.011539843,0.0030503557,0.011445331,-0.01681358,0.007546736,0.011832828,-0.024365041,0.004727933,-0.0020414463,-0.008605263,-0.0071875923,0.020187637,-0.009687419,-0.0068000956,-0.048503254,0.0015074569,-0.055572707,-0.007844447,-0.01441299,-0.02311749,-0.055119053,-0.0032062994,0.0006214125,-0.0005437359,0.027691841,-0.033929594,0.013052025,0.011823377,0.0027124775,-0.04184965,0.011209053,0.018505333,0.002639231,-0.016851384,-0.0024218548,-0.006322813,0.0050894395,0.0099426,-0.011785572,-0.00422466,0.017012052,-0.011199602,0.024251627,-0.06596896,0.033154603,0.015405359,0.013184342,0.011133444,-0.0008145702,-0.054060522,0.01715382,-0.017673632,-0.017966619,-0.0065071103,0.024497356,-0.07855788,-0.04563011,0.012106911,0.0058171772,0.010377352,-0.0055052894,0.043286223,0.0035441776,0.018098934,-0.0097630285,0.027880864,-0.039467964,-0.038333826,-0.011785572,0.010434059,-0.026066246,0.0025636218,-0.0023627852,-0.00076672377,-0.008142157,-0.056971475,-0.041055754,-0.00082461204,-0.03224729,0.055345878,0.029752191,-0.0030527185,0.027994279,-0.04449597,-0.0054769358,0.10033331,-0.009266843,0.029468656,0.06014706,0.027616233,0.00024189013,0.014242869,0.012437701,-0.005996749,-0.04082893,0.0057462933,-0.019157462,0.004399506,-0.011142895,0.01499896,-0.012352641,0.023249807,-0.02850464,-0.029109513,-0.034780197,-0.034572273,0.012787393,-0.009583456,0.01856204,-0.010046562,0.015017862,0.007749935,0.034080815,-0.047255702,-0.0019020421,0.02444065,-0.025971735,-0.027219284,0.025310155,-0.031850345,-0.021907743,0.03024365,-0.032001562,-0.0035229127,-0.018609297,0.008213041,-0.026992457,0.016123645,0.027691841,-0.01068924,-0.041963063,-0.051830053,-0.023230903,0.008539106,0.009574005,-0.037577733,0.00033078992,0.007310457,0.023060784,-0.030961936,0.010320646,-0.03704847,0.002759733,0.00059099164,0.030829621,-0.006776468,-0.0027030262,-0.039581377,0.002561259,0.018694356,0.02659551,0.02527235,0.05436296,-0.0028613328,-0.0198852,-0.02701136,0.030678403,0.031585712,-0.0067339377,0.023703462,0.017267235,-0.01889283,0.0058549815,0.018940086,0.002837705,0.027710745,0.0018169818,0.039959423,-0.020943727,-0.012579468,-0.009262118,-0.012210874,-0.009295197,0.023590047,0.018703807,0.0076176194,-0.033835083,0.03137779,0.008009842,-0.029185122,0.04366427,-0.040715516,-0.0060865344,-0.02892049,-0.048087403,-0.016000781,0.029222926,-0.00083937944,-0.020149833,-0.012740138,0.02999792,-0.021662014,0.019866297,-0.009271569,-0.04298379,-0.026973555,-0.16271083,-0.0029841976,-0.04283257,-0.0430972,-0.041471604,0.0038300748,-0.021435186,-0.000750775,-0.03687835,-0.0010431696,-0.012437701,0.03298448,0.0063180877,-0.019176364,-0.032682043,0.01889283,0.01731449,-0.009725223,-0.0024478454,0.01963947,0.008543831,-0.024402846,0.05651782,0.015055667,-0.00070529134,0.026690021,0.004463301,-0.023986995,-0.030924132,0.02659551,0.010538022,-0.03007353,0.0025116405,0.054211743,0.020225441,0.04997763,0.0024903757,-0.007135611,0.043135006,-0.028636957,0.009025839,0.041736238,-0.00044951987,-0.050015435,-0.01946935,-0.018174544,-0.017683083,0.03886309,-0.0072301226,-0.040980145,-0.027767451,0.069295764,0.018826673,0.037577733,-0.011360271,-0.0011967507,-0.00853438,-0.052321516,0.037332006,0.05935316,0.026897946,-0.03827712,-0.07141282,-0.022852859,-0.04426914,-0.0071214344,-0.08891633,0.031925954,0.04748253,0.014602012,-0.035252754,-0.07749935,0.027332699,-0.008888798,0.0040427255,0.018817222,0.032190584,-0.019998614,-0.024497356,-0.033249114,-0.010670338,-0.004727933,-0.0010786115,-0.039165527,0.0022470087,0.013023672,-0.006535464,-0.008250846,0.00042559666,0.022569323,-0.057803176,-0.043513052,0.029941214,0.01863765,-0.053417847,0.007853898,-0.0031259647,-0.017097114,-0.022304691,-0.00094097917,-0.002024907,0.0020839765,-0.022247985,-0.015310848,-0.035819825,-0.016284315,0.0021595857,0.0022458273,0.017361745,0.017210526,-0.024837598,0.03612226,0.019176364,0.0133355595,-0.049108125,0.010821556,-0.015528224,0.024421748,-0.02600954,0.032625336,-0.027313797,-2.1228148e-05,-0.0070127463,-0.02162421,0.0034118618,-0.010585277,0.031718027,-0.021832135,0.011757219,0.017144369,0.020395562,-0.0265199,-0.0004220525,0.042227697,0.027616233,0.02742721,-0.029865604,0.026727825,-0.0112846615,-0.018439176,0.0079011535,-0.025669297,-0.0045578126,0.00039783394,-0.0053304434,-0.020187637,-0.00840679,0.018524235,-0.0248565,-0.02941195,0.0538715,-0.04192526,-0.036670424,5.0430695e-05,0.014715426,0.0178154,-0.0066725053,0.025329057,0.05508125,0.01963947,0.015414811,-0.025234545,-0.027465014,0.028769271,0.008383161,0.048692275,0.0027219285,0.0048011793,-0.02468638,-0.0060014743,0.01897789,0.005727391,-0.017673632,-0.008416241,0.027275993,0.025952833,0.025820516,-0.032228388,-0.0028424305,0.00965434,0.031302176,-0.0043829666,-0.014422441,-0.030130235,-0.0040852553,0.033324722,0.00050031976,-0.0019906466,0.025310155,-0.015263592,-0.01929923,0.0026510449,0.028636957,0.03530946,0.010084367,0.020697998,-0.022474812,0.03321131,-0.056858063,0.044949625,0.0020591673,-0.013307206,-0.040564295,-0.067178704,-0.045478888,0.034156423,-0.008775384,-0.00054462196,-0.020074222,-0.001130002,0.021094946,-0.034005202,-0.0016409543,-0.034647882,-0.0019717442,-0.02867476,-0.06744334,-0.011152346,0.0059258654,-0.008869896,0.0035016476,-0.0045507243,-0.0038844189,0.0107743,0.020338854,-0.04816301,0.0023285248,0.0043829666,0.009328276,-0.02576381,-0.05088494,0.033097893,-0.038428336,0.0035181872,-0.01813674,0.0042388365,-0.015443164,0.015783405,-0.053644676,0.029109513,-0.023060784,-0.01110509,0.008279199,-0.022966271]
44	cac57754-e3e5-44d0-9df0-0c702e7a0b34	b134b961-246a-4d7a-94b3-960fa773f114	未详细说明	未详细说明	未详细说明	未详细说明	\N	待医生问诊后补充	\N	f	待医生问诊后确定	[0.009019168,-0.002873277,-0.023356333,-0.03126515,-0.05041384,-0.04293358,0.05898497,-0.014220287,-0.013061236,-0.021700548,0.019460365,-0.002739353,-0.00014031575,-0.0140839275,0.012418401,-0.0057562944,-0.0031727797,-0.018466894,0.016012432,-0.009559734,-0.006881255,0.00881463,-0.0030972953,0.0062140706,-0.02386281,0.010626256,0.013314474,0.005405657,0.045660757,0.02014216,-0.02752502,-0.051777426,0.009623043,0.016587088,-0.014570924,-0.011161951,0.015320898,0.02014216,-0.03389493,0.038433734,0.019713603,0.0117268665,0.035959795,0.057387624,0.021934306,-0.051894307,-0.013489793,-0.016567608,0.009321106,-0.021233032,0.008502953,-0.010480156,0.026473109,-0.035784476,0.036914308,0.01381121,-0.0354728,-6.859797e-05,-0.03656367,-0.044258207,-0.017775359,-0.011814526,-0.008132835,0.015145579,-0.020375919,0.07752978,0.031985905,0.017765619,-0.028421095,-0.03397285,-0.050998233,-0.016723447,0.039622005,-0.039738882,-0.046284113,0.017054604,0.043245256,-0.030115841,0.0069689145,-0.010217179,0.013928089,-0.042855658,0.017804578,0.03019376,-0.015145579,0.028148375,0.037011705,0.01877857,-0.02265506,-0.021116152,-0.023434253,0.038063616,-0.02641467,-0.021116152,-0.017161744,-0.022888817,-0.01887597,-4.1242485e-05,0.045816597,-0.01772666,0.015233239,-0.032180704,0.002068516,-0.0175416,0.04118039,0.03151839,0.0052108583,0.010908714,0.052167024,0.0068471655,0.024817323,0.0276419,0.01257424,-0.0049649253,0.008848719,-0.016733186,-0.04889441,-0.039485645,0.024895241,-0.010889233,0.03640783,0.01624619,0.0031898245,-0.02386281,-0.005167029,0.020765515,0.05399813,0.002453243,-0.009954201,0.040634956,-0.0055858456,0.039485645,0.0033042687,-0.054660443,0.020356437,-0.02018112,-0.013197595,0.03516112,0.01265216,-0.035278,0.0064526987,0.029843122,-0.019226607,0.013382654,0.0042539113,-0.09545124,0.011814526,0.02014216,0.010373018,0.030992433,-0.0150579205,0.000654401,0.028304216,0.019947361,0.027408142,-0.016723447,-0.0575045,0.01614879,-0.018135736,-0.0004139467,0.0277393,0.028362654,-0.0026054292,0.011843746,0.008449383,0.001954072,0.034479324,0.02510952,0.022304423,0.0302522,-0.0081084855,-0.019119468,0.033193655,-0.0006811858,0.011648947,0.014726763,0.078075215,-0.008454253,-0.037829857,-0.03932981,-0.03911553,0.0021793076,0.047258105,-0.0067254165,-0.0011127861,-0.023064137,-0.024213448,0.0031167753,0.0043196557,0.030446997,-0.009267536,-0.024057608,-0.0007767588,0.008950989,0.04772562,-0.03147943,-0.0100029,-0.027057504,0.02766138,0.008619831,0.0060241423,0.0225187,0.015242979,0.012369702,-0.021758987,0.017376022,-0.009272406,-0.026960105,0.021057712,-0.007056574,0.0073439013,-0.0034284526,-0.04519324,-0.03632991,-0.0120482845,-0.04655683,0.035823435,-0.03019376,0.0018359753,-0.015369598,-0.042466063,0.040673915,-0.0071052737,-0.0350832,-0.0031240801,-0.0057562944,0.021583669,0.027992537,0.039719403,-0.06786778,-0.04114143,0.029784683,-0.026921146,0.033096258,0.09389285,-0.0012412313,0.0053374777,0.0020405138,0.044647805,0.0003262874,-0.032940418,-0.019343486,0.03777142,0.0154669965,0.024895241,0.009642523,0.040050562,-0.03642731,-0.0301548,0.009301626,0.007251372,-0.0052936478,-0.07655579,0.001024518,0.015165059,0.023278415,-0.005274168,0.004774997,0.019401925,0.000938685,-0.0100613395,0.044530924,-0.008936379,0.03794674,-0.003518547,-0.052011184,0.005800124,0.011775566,0.02637571,0.011804786,-0.03668055,-0.0552838,-0.0138404295,0.01745394,0.058244735,-0.03366117,0.0105872955,-0.020531757,0.038433734,-0.027934097,-0.037615582,0.030446997,0.023297895,0.033388454,0.018320793,-0.025284838,0.007928297,-0.0701664,-0.0015888249,-0.013889129,0.00877567,0.02008372,0.055829234,-0.04114143,-0.004662988,0.056803226,0.0067351563,-0.18435726,-0.042505022,0.016859805,0.030330118,0.011619727,0.005556626,0.0021780902,-0.012944357,-0.029122368,0.011045072,0.017814318,-0.040634956,0.021525228,0.01372355,-0.010509376,-0.024797842,0.020434357,-0.040829755,0.0016350895,-0.033485852,-0.07223126,0.011181431,0.033485852,0.009019168,0.0050842394,0.038472693,0.047491863,-0.005264428,-0.018359754,-0.040868714,-0.010626256,-0.014317686,-0.019947361,0.017210443,0.0008376333,-0.008074395,0.061088793,-0.016976684,0.0063066,-0.0016265671,0.05653051,0.05688115,0.0021342605,0.0133923935,-0.029063929,-0.027778259,-0.034732565,-0.0024763753,-0.009043518,0.020395398,0.048426896,-0.0074072112,-0.0048358715,0.02372645,-0.039290845,0.010694435,-0.011980104,0.07394549,0.04418029,-0.009924981,-0.026551029,-0.053141017,-0.019255826,0.00439514,-0.007611749,0.028362654,0.0076458394,-0.0301548,0.007285462,0.011678167,-0.018564291,0.0056345453,-0.006530618,0.004436535,-0.021642108,0.009632783,-0.04141415,-0.015856594,-0.017288363,-0.08750346,-0.03231706,-0.0030826854,0.0021513053,-0.037070144,-0.0059510926,-0.030563876,0.0034381927,0.038238935,0.031070353,0.24747194,0.028791212,-0.039894722,0.0043586153,0.0016423945,-0.050764475,-0.03794674,0.030563876,0.012866437,-0.025518596,-0.00313869,-0.029511966,-0.010762614,-0.03878437,0.0086782705,0.057153866,-0.038161017,-0.014405346,0.071841665,-0.004794477,-0.005917003,0.016207231,0.026044553,0.015281938,0.015574136,-0.05279038,-0.01513584,0.049595684,-0.016518908,-0.012769039,-0.029862603,0.014405346,0.02892757,-0.0081912745,0.005498186,0.029180808,-0.026628949,-0.020590195,-0.06927033,0.027466582,0.020609677,-0.0038643142,0.018223396,0.0028562322,0.021018753,0.0014682934,-0.018106516,0.018116256,-0.038609054,-0.027914617,-0.0041151172,-0.029726243,0.010674955,0.0060923216,-0.015759194,0.028343175,-0.043206297,-0.024992641,-0.046089314,0.06704962,0.005425137,0.018009117,-0.035959795,0.014298206,0.02119407,0.015009221,0.03880385,0.035570197,-0.021992745,0.024544604,-0.026589988,0.0067546363,-0.012087244,0.00438053,0.03510268,0.009248056,-0.0064673084,0.08275038,0.013538492,0.0068033356,-0.00878541,-0.015652055,-0.047180183,-0.05875121,0.0026882186,0.051738467,0.020804474,0.03017428,-0.0026638687,-0.0021878302,0.0139183495,0.050647598,-0.08672427,-0.05656947,0.032044344,0.02269402,0.014551444,-0.0250316,-0.024603045,0.05392021,-0.004273391,-0.012691119,0.0045826337,0.015398817,0.04390757,-0.06704962,-0.047881458,0.017512381,-0.055361718,-0.026804266,-0.0028002276,0.024232928,0.0024678528,-0.006686457,0.038180497,0.021077191,0.005800124,0.008444513,0.06786778,0.0330573,-0.001963812,0.03401181,-0.0452322,0.06412765,-0.018369494,-0.010353537,0.03627147,-0.048582733,0.005264428,0.018447414,-0.012769039,-0.034226086,-0.043517973,-0.0115223285,0.02131095,-0.0032263494,0.0042344313,0.016694227,0.060971916,0.03888177,-0.021233032,-0.04129727,-0.03632991,0.038199976,0.0064137387,-0.00751435,0.0052205985,-0.031245671,0.016070873,-0.006204331,0.07484157,0.012408662,0.06323158,-0.034459844,0.0060971915,-0.0677509,-0.02018112,-0.04651787,0.004731167,-0.019216867,-0.0028050977,-0.0047628223,0.031226192,0.085321724,-0.0019625945,0.03408973,-0.008624702,0.009842192,0.050920315,0.016100092,-0.016285151,-0.011015852,0.0070857937,-0.025810795,0.024856282,0.0034333228,-0.052050147,0.026940625,0.05660843,0.07889337,0.015866334,-0.020901874,0.010674955,0.06712755,0.039251886,0.06802362,0.0034162777,-0.005503056,-0.012379441,-0.025635475,-0.026044553,0.11010008,-0.020707075,0.007412081,0.017074084,0.020940833,0.028537972,0.02240182,-0.006652367,0.028693812,-0.00013034756,-0.02875225,0.0031776498,0.012778779,0.0013002796,-0.0052059884,-0.03140151,-0.03140151,-0.0039397986,0.009812972,0.033076778,0.0125645,-0.05271246,0.0030510307,-0.049907364,0.009837322,0.07301046,0.028187336,-0.058205776,0.0007359729,0.02386281,0.00044894955,0.07059496,-0.08586716,0.008137705,-0.009491554,-0.030485958,-0.053608533,-0.025927674,0.036641587,0.0064819185,-0.04659579,-0.010207439,0.0044949744,0.015350117,0.001034258,0.045427,0.013080716,0.038336337,-0.03371961,-0.016811106,-0.01998632,0.020375919,0.0063212095,-0.01135675,0.016742926,-0.0016302195,0.021817427,0.027817218,-0.012486581,0.010256139,0.033271573,0.013314474,-0.039388247,-0.006033882,0.025810795,-0.020629156,0.022070665,-0.01896363,-0.0025542947,-0.025167959,0.03899865,-0.024330325,0.015291679,-0.058556415,-0.057972018,0.025401717,0.046946425,-0.02896653,-0.0043367003,-0.029882083,-0.020434357,-0.030427517,-0.034615684,-0.044920523,0.0006312687,-0.012749558,0.034206606,-0.0103437975,-0.020200599,-0.013246294,-0.024466686,0.026102992,0.03136255,1.0928878e-05,0.06790674,0.0326677,0.03490788,0.006516008,0.01254502,-0.0024435031,-0.027583461,-0.054504607,-0.029726243,-0.020862915,0.008020826,-0.015856594,-0.007908817,0.009184747,0.007270852,-0.03531696,-0.0017617085,-0.024739403,-0.04780354,0.002651694,-0.01884675,0.021739507,0.0141618475,-0.041024555,-0.0064624385,0.007416951,-0.03163527,0.017229922,0.004945446,0.025810795,-0.029589884,-0.011405449,0.0275445,-0.032356024,0.01765848,-0.012730079,-0.014395606,-0.010976893,-0.024252407,-0.011551548,-0.022090144,-0.017405242,-0.013713811,-0.029843122,-0.040712874,-0.029745724,0.0030875555,-0.011074292,0.003384623,0.03270666,0.0064575686,0.03260926,0.028654851,0.026278311,-0.023609571,-0.030641796,-0.016674748,0.052946217,0.0044219247,-0.01755134,-0.012145683,0.022849858,0.012096983,0.013713811,0.026628949,0.02514848,0.033174176,0.0015303853,-0.037284423,0.0005430007,-0.0017117914,-0.043440055,-0.00998342,0.05886809,0.010012641,1.1632739e-05,0.031557348,-0.012058024,0.011697647,-0.021330431,0.019918142,-0.0057562944,0.018242875,-0.009627913,-0.013665111,-0.029628845,0.034245566,0.022148583,0.00316304,-0.009637653,-0.013119675,0.034381926,-0.06498476,-0.017229922,-0.009325976,-0.030992433,-0.009793492,-0.003506372,-0.00756792,0.016723447,0.007821158,-0.049478807,-0.04620619,-0.0099395905,-0.012301522,0.016538389,-0.015846854,-0.039660964,0.009778882,-0.1636307,-0.018155215,0.0008565044,-0.04655683,-0.04137519,-0.0033602733,-0.059842084,0.012817738,-0.00052199897,0.004923531,0.044258207,0.014424825,0.024719924,-0.0028367525,-0.010246399,0.02025904,0.048582733,0.0022779244,0.03393389,0.022888817,-0.019294787,-0.0300574,0.035589676,0.0023558438,-0.051193032,-0.0301548,-0.048504815,-0.006759506,-0.025752354,0.059179768,-0.009812972,-0.038141537,0.02894705,0.04008952,0.04554388,0.0023534088,-0.00377909,-0.025693916,0.03753766,0.0074607804,-0.030778155,0.033544295,-0.023609571,-0.049439847,-0.043712772,-0.037128583,-0.03531696,-0.021778466,-0.010908714,-0.03872593,-0.013090456,0.035940316,0.029434046,-0.016070873,-0.0045753284,-0.0020977359,0.0033018338,0.016966945,-0.008215625,0.010597035,-0.0065793176,-0.044414047,0.009588954,-0.016285151,-0.014493004,-0.015145579,-0.07371173,0.026005592,-0.0023631486,0.027193863,-0.035764996,-0.008074395,0.025538078,-0.0012941922,-0.008171795,0.032219663,0.0274471,-0.0038570093,-0.062062785,-0.014717023,0.010197699,0.005303388,0.006671847,-0.0400116,-0.018369494,0.0061020614,-0.021836907,-0.00023664968,0.024408245,0.015486477,-0.06778986,-0.035998754,0.0042125164,-0.0031752146,-0.03161579,0.027758779,-0.03136255,-0.030427517,0.0010853927,-0.0009849496,-0.00032233057,-0.00627738,-0.033622213,-0.0024751578,-0.038219456,0.004015283,-0.0017994507,-0.048543774,0.0055809757,0.008254584,-0.0041881665,-0.0032287843,0.029200288,0.04008952,-0.06490684,-0.029687284,0.055011082,0.020648636,-0.00998342,0.019635683,-0.04881649,0.0016448294,-0.043167338,-0.03892073,0.0026736087,-0.013022277,0.055868194,0.032024864,0.020668115,0.051348872,0.025538078,-0.037089624,-0.009121438,0.048115216,-0.0021695676,0.039641485,-0.02877173,0.021875866,-0.008561391,-0.04008952,0.0074510407,0.008532172,-0.010898973,-0.016742926,-0.023765411,0.012379441,-0.02639519,0.005892653,-0.071413115,0.028089937,0.05505004,-0.012622939,-0.019138947,0.012661899,-0.0036159463,0.023492694,-0.00628712,0.036738988,0.03638835,-0.006150761,0.0030899905,-0.0924903,-0.01641177,-0.0074997405,-0.023492694,0.02148627,-0.009506164,0.012759298,-0.01378199,-0.015106619,0.011580768,-0.009681483,-0.026823746,-0.0044681896,0.039875243,0.004633768,-0.0011353097,-0.0250316,0.008103616,0.027135424,0.027115945,0.005678375,-0.00019251565,0.022830378,-0.015398817,0.015622836,0.055673398,0.012116464,-0.00021001708,-0.010489897,0.00059230905,-0.024310846,0.038686972,0.015671534,0.0526735,0.05543964,-0.02138887,0.037829857,-0.01888571,0.05543964,-0.03531696,-0.028304216,-0.0073536416,-0.0126132,-0.03391441,0.02766138,0.018125996,-0.046673708,0.00010599775,-0.00041333796,0.0019163297,-0.0069883945,-0.023142057,0.022129104,-0.01896363,-0.049673606,-0.0033773181,0.008239974,-0.003384623,0.0075776596,0.017882498,0.024038129,0.017960416,-0.012759298,0.03650523,-0.034615684,-0.032394983,-0.0047433423,-0.0050550196,-0.013256035,-0.016216971,-0.008093876,-0.024505645,0.02518744,-0.009140917,-0.051076155,-0.039290845,0.022323903,-0.029102888,-0.023083616,-0.019557765,0.015233239,-0.02265506,-0.024291366]
45	791d73d8-ecb9-4e16-b50f-e63d0dd250b4	7ca95a34-5096-4c20-85bf-1ac6be1dd105	怀孕，身体乏力	患者自述怀孕，感觉身体乏力，未提及具体症状发展过程。	未详细说明	未详细说明	\N	建议进行孕期常规检查，具体项目待医生问诊后确定。	\N	f	待医生问诊后确定	[0.013175762,0.014352514,-0.05077395,-0.029804617,-0.023110634,-0.060998186,0.01762234,0.013243281,0.016127288,-0.026177905,-0.017853834,-0.015683595,-0.046298433,0.04394493,0.0090716,-0.008020239,0.0026211664,-0.017535532,-0.029920362,0.022879142,-0.0054063066,0.013040725,0.023284255,-0.015162737,-0.0356305,0.024171641,-0.027142456,-0.00062936934,0.07581368,0.001888108,0.023342127,-0.023747237,0.023052761,-0.04054971,0.0015686005,-0.03848557,0.006732564,-0.021085078,-0.029225886,0.046221267,0.018220363,-0.017699504,0.021779554,-0.018008161,0.017593404,-0.036923,-0.021798845,-0.01131418,-0.0034000413,-0.016146578,0.028820775,-0.034936026,0.022416158,-0.021721682,0.019628607,0.020757131,-0.002963582,-0.04247881,-0.038890682,-0.021065786,-0.020525638,0.0001133347,0.019088458,-0.022281121,-0.00084277615,0.062271394,0.03329629,-0.018345755,-0.029881781,-0.053320363,-0.00088497525,0.0063612117,-0.021605935,0.0010881338,-0.049153503,0.03269827,-0.0014383863,-0.040086728,0.011564963,0.018123908,0.026177905,0.039855234,0.022377577,0.011478153,-0.017998517,-0.0024210222,-0.02741253,-0.005907873,-0.047725968,-0.03844699,-0.016416652,0.043867767,-0.046337016,-0.011564963,-0.03862061,-0.0011435954,-0.023072053,-0.034299422,0.025348391,-0.009399546,0.022281121,-0.016889283,0.012674196,-0.0032336563,-0.00018642956,-0.0016566158,0.001168312,-0.012114757,0.030229019,-0.014497197,0.022416158,-0.004193384,0.042324483,0.009129472,0.009544229,-0.0167446,-0.026100742,-0.014014921,-0.00020632343,-0.031039242,0.0468,0.022551196,0.002893652,-0.021162242,-0.035842706,0.031232152,0.042710304,0.024248805,-0.027528277,0.028087717,0.00571014,-0.025425557,-0.05389909,-0.033566363,0.004429699,-0.05104402,0.03555334,0.01760305,-0.034338005,0.008787056,-0.043134708,0.07353734,0.0005922944,-0.02475037,-0.008951031,-0.05208574,0.04147568,-0.0013214344,0.03676867,0.025541302,-0.0521629,0.0020749897,-0.00034753967,0.03372069,0.01103446,0.03802259,0.012423413,0.017834542,-0.04645276,0.034010056,0.07249563,-0.0067373863,-0.04259456,-0.0041258656,-0.030364055,-0.0017000206,0.00126115,0.0038799052,-0.020236274,0.057602968,0.041938663,-0.052240066,0.024133058,-0.032254577,0.016599918,0.019368177,0.077588454,0.029611707,-0.0049047405,-0.036247816,-0.017525885,0.033431325,0.031675845,-0.040781204,-0.007803215,-0.0054448885,-0.004241612,-0.0201784,1.0757001e-05,0.011391344,0.003211954,-0.03595845,0.0021521538,0.022589777,0.07037362,0.003424155,0.012973207,-0.012886398,0.010320692,-0.00013036505,0.07064369,0.032215994,0.020602804,-0.024981864,-0.018393982,0.00023149216,-0.035611212,-0.07411607,0.008719538,-0.040704038,0.030306183,0.03578483,0.006423908,0.0076392414,-0.028608574,0.012114757,-0.022184666,-0.07376884,-0.019262077,0.0057487222,-0.022744106,0.008328895,0.034878153,-0.06068953,-0.017757379,0.044793732,-0.0045864386,0.0364986,0.001972506,-0.030904204,-0.008362655,0.050465293,0.0044200537,-0.0006757883,0.07596801,0.0027007419,-0.004608141,-0.0009832388,0.0010230265,0.010426793,-0.0026452802,-0.029148722,0.029071558,0.024943281,0.0023245672,-0.040858366,0.013397609,0.040858366,-0.016638499,0.002483718,0.039855234,0.006939942,-0.018220363,-0.0076247733,0.00024038412,0.008946207,-0.003945012,-0.01217263,-0.003699052,0.0029732275,-0.02889794,0.025657048,0.014005276,0.033064798,0.00046780708,-0.044948064,-0.0321967,-0.012375185,0.0031613149,0.037848968,-0.0023583265,0.0060670236,0.0352061,0.024268094,0.0029081204,-0.0007342642,-0.0055606347,0.0040342333,0.03364353,-0.027894806,-0.027026711,0.016204452,-0.0033952184,-0.011690354,-0.00050819764,0.00338075,0.0457197,-0.0382155,-0.0048106965,-0.04811179,-0.009110182,-0.009992745,0.05231723,0.012828524,0.02451888,0.02664089,0.03840841,-0.17577972,-0.0044538127,-0.008695425,-0.009303091,-0.02756686,0.013841302,-0.012664551,-0.0034603255,-0.049192086,-0.021991756,0.024113767,-0.034936026,0.03140577,0.02741253,-0.027894806,0.011912201,-0.030190436,-0.016310552,-0.0134169,-0.02056422,-0.035611212,-0.010513603,0.055249464,0.016648145,-0.05594394,0.004231966,0.036324978,-0.017738087,-0.01360981,-0.020660676,-0.0302676,0.034936026,-0.019696126,0.01762234,0.02436455,0.031058533,0.030132564,0.017747732,-0.022474032,0.023998022,-0.009471888,0.048227534,-0.01380272,0.03748244,0.0074704452,-0.02552201,0.013966694,-0.024268094,-0.015828276,-0.015963314,0.022377577,-0.024615334,0.002278751,-0.020872876,-0.048266117,0.0034338005,-0.006771146,0.0102435285,0.030113272,0.031039242,-0.029727452,-0.09784402,-0.001253916,0.036132067,-0.031945918,-0.031540807,-0.05440066,0.0063226297,-0.00598986,0.011304534,0.0098962905,0.024480296,0.016368425,-0.015963314,0.024576752,0.021760264,-0.032447483,-0.017178647,0.0006317807,-0.11628623,-0.05096686,0.0038268548,-0.017574113,0.01541352,-0.005039777,-0.018963067,0.010272465,0.034473043,0.0086279055,0.24831393,-0.0027320897,-0.044253584,-0.010185655,0.026293652,-0.023207089,-0.02037131,0.05798879,0.050889693,-0.04375202,-0.044639405,0.0127127785,0.012191921,-0.026139325,0.0014130668,0.025059028,-0.035649795,-0.02419093,0.07218698,-0.013387963,0.0457197,-0.02149019,0.0048034624,-0.019889034,-0.0007939458,-0.044022094,0.009158409,0.03809975,-0.004552679,0.009500824,-0.041977245,0.01066793,0.05482506,-0.014284995,-0.0124716405,0.028377082,0.030325474,0.04205441,-0.014535779,0.029746743,0.034338005,-0.016281616,-0.0116035445,0.0065300083,-0.009553875,0.005575103,-0.013523,0.00037647618,0.0367108,-0.028492827,0.016532399,-0.007099093,-0.05189283,-0.010214591,-0.015895795,-0.012896042,-0.046529926,-0.0071424977,-0.020969331,0.0729972,0.04166859,0.037578896,-0.08418599,-0.01197972,0.032486066,0.033952184,-0.09089926,0.0033301113,0.012982853,0.008979967,0.049192086,-0.009095713,-0.020892167,-0.029920362,0.02966958,-0.024171641,-0.005531698,0.0015251958,0.024615334,0.034550205,-0.01122737,0.017641632,-0.040048145,-0.015596785,0.03171443,0.0055268756,0.04514097,0.014159604,-0.005025309,0.014564715,-0.01285746,0.008594147,-0.031444352,-0.013117889,-0.018702637,-0.02756686,-0.01161319,-0.044060677,-0.02779835,0.0049819043,-0.018316818,-0.040588293,0.007943075,0.0015698062,-0.042555977,0.025927123,-0.009626216,-0.0048155193,-0.013175762,0.016696373,-0.047648802,0.012355895,-0.008275845,-0.0017048434,-0.02986249,-0.024596043,-0.024673207,0.039893817,0.041977245,0.037231658,-0.04375202,0.036112778,-0.031502225,0.075080626,-0.025637757,-0.013281863,0.007996125,0.0043115416,0.013523,0.044292167,-0.008767766,-0.015963314,-0.08171673,-0.0056426213,0.04220874,0.018094972,0.021625226,0.014207832,0.014294641,0.07210981,-0.02567634,0.0026525145,-0.013156472,0.053706184,-0.014188541,0.0108704865,0.008970321,-0.02548343,-0.012375185,-0.0031154987,0.038543444,0.024596043,0.050195217,-0.062078483,0.0024403133,-0.034318715,-0.016706018,-0.059609234,-0.03250536,-0.036228523,0.0010338777,-0.021181533,0.02451888,0.08665524,0.030730585,0.018664056,0.010339984,-0.017053256,0.027084583,-0.024325969,-0.00011084798,-0.016898928,-0.07195548,-0.084263146,0.019464632,0.016792828,-0.010735449,-0.0057053175,-0.0068965373,0.016947156,0.0251169,0.03536043,0.053050287,0.05196999,0.0058644684,-0.0098962905,-0.024808243,-0.01189291,-0.0074656224,-0.041784335,0.040819786,0.08572926,0.014429678,0.009196991,0.06296587,0.06871459,0.04452366,-0.0060477327,-0.018027453,-0.018500082,0.021200825,0.013127535,-0.0052760923,0.013580874,0.02756686,-0.010359274,-0.044485077,0.046529926,0.0026959192,-0.0031516694,-0.019262077,-0.007875556,0.030209728,-0.0020822238,-0.029013684,-0.009544229,-0.0013467539,0.008820816,-0.00071437034,-0.0058885817,0.023245672,-0.0033445796,0.040626876,-0.01236554,-0.0031806058,0.044948064,-0.031540807,0.0043308325,0.04888343,0.03883281,-0.0036001855,0.013725556,-0.05042671,-0.037463147,0.00937061,-0.050118055,0.008734006,0.03119357,-0.037135202,-0.019194558,-0.029264469,-0.049346413,-0.01768986,-0.007668178,0.022512613,0.021181533,-0.015249547,-0.0020520815,0.03539901,0.051275514,0.025136191,0.017805606,0.0022486087,-0.052973125,-0.0017651278,0.036189944,-0.038138334,-0.017506596,0.0071569663,0.039893817,-0.014053504,0.046761416,0.029264469,0.02436455,-0.022879142,-0.08380017,-0.002108749,0.033971474,-0.008555565,-0.057294313,-0.033373453,-0.0126452595,-0.0012026741,0.0030431575,0.012269084,-0.01236554,-0.012336603,0.04791888,0.019696126,-0.023920856,0.025386974,0.019223494,0.013773784,0.017178647,-0.005358079,-0.034608077,0.042363066,0.021818137,-0.023843693,0.009741962,-0.0053098514,0.0032529472,-0.011150206,0.037135202,-0.011381698,0.029785326,0.014873371,0.0070074606,-0.030981367,0.025078317,-0.03578483,0.037848968,-0.018210717,0.035534047,0.002905709,0.038524155,0.020911459,0.012635614,0.039122175,0.027065292,0.010725804,-0.06802011,-0.00851216,-0.0050590686,0.018789448,-0.0002525917,0.009573165,0.004870981,0.009052308,0.03422226,-0.012230502,-0.032466777,-0.041552845,-0.023650782,-0.0016674671,-0.031154986,-0.00028333676,0.021914592,-0.039855234,-0.03651789,-0.035669085,0.042363066,-0.02284056,-0.022281121,0.0060380874,-0.03578483,0.02739324,-0.019030586,0.029476669,0.004897506,0.0022184665,0.008492868,0.057757296,-0.035649795,-0.010532893,-0.0068579554,0.016368425,0.03119357,0.014815498,0.022107502,-0.0090281945,0.013822012,-0.014342869,-0.015972959,0.0040607583,0.033006925,0.0056233304,0.003142024,0.06300445,-0.03140577,-0.01562572,0.011835037,-0.007398104,-0.013725556,0.027894806,0.012191921,0.007943075,0.039855234,0.016484171,0.0020689613,0.0024017312,0.010446084,-0.0020834296,-0.035842706,0.001427535,0.04853619,-0.04054971,0.0059753917,-0.004096929,-0.0011990571,0.0100023905,-0.03543759,0.0011261129,-0.008237263,0.026853092,0.035842706,-0.009008903,0.0008035913,0.04398351,0.014130668,0.0065444764,-0.020081945,-0.029052267,-0.0039667147,-0.15579423,0.0010121753,-0.025251936,-0.049384996,-0.030846331,-0.005806595,0.00359054,-0.014776916,-0.024248805,-0.031810883,0.0052857376,-0.00053261284,-0.025039736,-0.020718548,0.02037131,0.0231878,-0.0027706719,0.011825391,0.025946414,0.036074195,-0.026332233,-0.015770404,0.01629126,0.036787964,-0.009023372,-0.010272465,0.027914098,0.020815004,-0.046954326,0.016522754,-0.025965706,-0.000936217,0.015702885,0.065550864,0.012105111,-0.012269084,0.022242539,-0.03806117,0.011748227,0.013995631,-0.014217477,0.040279638,0.054130584,0.047996044,-0.013320445,0.0014829967,0.025174772,0.0072437758,-0.029573124,-0.007335408,-0.023998022,0.017699504,-0.07646958,0.0011056162,-0.01064864,-0.00718108,-0.008989613,-0.010484666,0.03273685,0.045758285,0.016677082,-0.04375202,-0.033276998,-0.025213355,-0.040819786,-0.016792828,-0.06639967,0.04564254,0.0053725475,0.018133553,-0.059840724,-0.0126452595,0.00096937345,-0.039893817,-0.0056812037,0.02874361,0.083260015,-0.040086728,-0.059223413,0.0050735367,-0.02777906,0.034202967,0.055635285,-0.011343116,0.0023305956,0.0047697034,0.03483957,0.015481039,-0.014516488,0.021779554,-0.060187962,-0.019348888,0.036730092,-0.03271756,-0.0076344186,-0.0085218055,-0.028627865,-0.060458038,-0.019098103,-0.05536521,0.01777667,0.003354225,-0.012230502,-0.013928112,-0.064084746,0.023515746,-0.026968837,0.0067807916,0.0018362633,0.011073042,0.026853092,0.003942601,-0.039450124,0.04413784,-0.022146083,0.008946207,-0.008444642,-0.015268837,-0.066746905,0.01227873,-0.009558697,-0.020834295,-0.033392746,-0.022281121,0.015866859,-0.018210717,0.04510239,0.0032625927,-0.00965033,0.016628854,0.018538665,-0.08256554,-0.0039932397,0.020988623,0.024499588,0.004441756,-0.0133397365,0.04699291,-0.033392746,-0.00012659728,-0.0021654163,-0.03464666,-0.020429183,-0.020795712,-0.028955812,-0.02968887,0.011381698,0.005454534,0.006472135,-0.010880132,0.0302676,-0.038389117,-0.037328113,0.026563726,0.006221352,-0.015577493,0.01958038,0.03237032,-0.00038823165,0.058297444,0.00026178508,-0.06790437,-0.01236554,-0.023940148,-0.017718796,0.054246332,0.020236274,-0.026312944,-0.07137675,-0.021683099,0.0026332233,0.037540313,-0.030344766,0.053127453,0.012828524,0.038755648,-0.015587139,-0.030846331,0.063969,0.013735202,0.029997526,0.011651772,-0.0019049876,0.050542455,-0.026197197,0.047996044,-0.0022642827,-0.00053984695,0.018712284,0.0028430133,0.023207089,0.013387963,0.013214344,-0.02419093,0.04247881,-0.010774031,0.031039242,0.027508985,-0.045565374,0.012481286,-0.052625887,-0.0073305853,-0.018567601,-0.047841713,-0.027335366,0.005806595,0.01605977,-0.03101995,0.013937757,-0.03329629,-0.03269827,-0.037926134,0.0051555233,0.012085821,-0.0024668383,0.022551196,0.026988128,0.00851216,0.02912943,-0.017950289,-0.02720033,-0.0030311006,-0.0034916734,0.016860345,-0.0062695793,0.0026669826,-0.04286463,0.003040746,-0.017236521,0.012587386,-0.05613685,0.029630996,-0.016416652,0.015519621,-0.0005497939,0.033276998,-0.010899423,0.0036484129,-0.027354658,0.013387963,0.015780048,0.003091385,-0.055480957,-0.033759274]
46	ed18609f-0625-4d9b-84ec-f883418974f3	518376ad-a7d7-4221-8495-2d74d90973c0	孕期常规检查，身体乏力	患者自述怀孕，感觉身体乏力，未提及具体症状发展过程	未详细说明	未详细说明	\N	待医生问诊后补充	\N	f	待医生问诊后确定	[0.013175762,0.014352514,-0.05077395,-0.029804617,-0.023110634,-0.060998186,0.01762234,0.013243281,0.016127288,-0.026177905,-0.017853834,-0.015683595,-0.046298433,0.04394493,0.0090716,-0.008020239,0.0026211664,-0.017535532,-0.029920362,0.022879142,-0.0054063066,0.013040725,0.023284255,-0.015162737,-0.0356305,0.024171641,-0.027142456,-0.00062936934,0.07581368,0.001888108,0.023342127,-0.023747237,0.023052761,-0.04054971,0.0015686005,-0.03848557,0.006732564,-0.021085078,-0.029225886,0.046221267,0.018220363,-0.017699504,0.021779554,-0.018008161,0.017593404,-0.036923,-0.021798845,-0.01131418,-0.0034000413,-0.016146578,0.028820775,-0.034936026,0.022416158,-0.021721682,0.019628607,0.020757131,-0.002963582,-0.04247881,-0.038890682,-0.021065786,-0.020525638,0.0001133347,0.019088458,-0.022281121,-0.00084277615,0.062271394,0.03329629,-0.018345755,-0.029881781,-0.053320363,-0.00088497525,0.0063612117,-0.021605935,0.0010881338,-0.049153503,0.03269827,-0.0014383863,-0.040086728,0.011564963,0.018123908,0.026177905,0.039855234,0.022377577,0.011478153,-0.017998517,-0.0024210222,-0.02741253,-0.005907873,-0.047725968,-0.03844699,-0.016416652,0.043867767,-0.046337016,-0.011564963,-0.03862061,-0.0011435954,-0.023072053,-0.034299422,0.025348391,-0.009399546,0.022281121,-0.016889283,0.012674196,-0.0032336563,-0.00018642956,-0.0016566158,0.001168312,-0.012114757,0.030229019,-0.014497197,0.022416158,-0.004193384,0.042324483,0.009129472,0.009544229,-0.0167446,-0.026100742,-0.014014921,-0.00020632343,-0.031039242,0.0468,0.022551196,0.002893652,-0.021162242,-0.035842706,0.031232152,0.042710304,0.024248805,-0.027528277,0.028087717,0.00571014,-0.025425557,-0.05389909,-0.033566363,0.004429699,-0.05104402,0.03555334,0.01760305,-0.034338005,0.008787056,-0.043134708,0.07353734,0.0005922944,-0.02475037,-0.008951031,-0.05208574,0.04147568,-0.0013214344,0.03676867,0.025541302,-0.0521629,0.0020749897,-0.00034753967,0.03372069,0.01103446,0.03802259,0.012423413,0.017834542,-0.04645276,0.034010056,0.07249563,-0.0067373863,-0.04259456,-0.0041258656,-0.030364055,-0.0017000206,0.00126115,0.0038799052,-0.020236274,0.057602968,0.041938663,-0.052240066,0.024133058,-0.032254577,0.016599918,0.019368177,0.077588454,0.029611707,-0.0049047405,-0.036247816,-0.017525885,0.033431325,0.031675845,-0.040781204,-0.007803215,-0.0054448885,-0.004241612,-0.0201784,1.0757001e-05,0.011391344,0.003211954,-0.03595845,0.0021521538,0.022589777,0.07037362,0.003424155,0.012973207,-0.012886398,0.010320692,-0.00013036505,0.07064369,0.032215994,0.020602804,-0.024981864,-0.018393982,0.00023149216,-0.035611212,-0.07411607,0.008719538,-0.040704038,0.030306183,0.03578483,0.006423908,0.0076392414,-0.028608574,0.012114757,-0.022184666,-0.07376884,-0.019262077,0.0057487222,-0.022744106,0.008328895,0.034878153,-0.06068953,-0.017757379,0.044793732,-0.0045864386,0.0364986,0.001972506,-0.030904204,-0.008362655,0.050465293,0.0044200537,-0.0006757883,0.07596801,0.0027007419,-0.004608141,-0.0009832388,0.0010230265,0.010426793,-0.0026452802,-0.029148722,0.029071558,0.024943281,0.0023245672,-0.040858366,0.013397609,0.040858366,-0.016638499,0.002483718,0.039855234,0.006939942,-0.018220363,-0.0076247733,0.00024038412,0.008946207,-0.003945012,-0.01217263,-0.003699052,0.0029732275,-0.02889794,0.025657048,0.014005276,0.033064798,0.00046780708,-0.044948064,-0.0321967,-0.012375185,0.0031613149,0.037848968,-0.0023583265,0.0060670236,0.0352061,0.024268094,0.0029081204,-0.0007342642,-0.0055606347,0.0040342333,0.03364353,-0.027894806,-0.027026711,0.016204452,-0.0033952184,-0.011690354,-0.00050819764,0.00338075,0.0457197,-0.0382155,-0.0048106965,-0.04811179,-0.009110182,-0.009992745,0.05231723,0.012828524,0.02451888,0.02664089,0.03840841,-0.17577972,-0.0044538127,-0.008695425,-0.009303091,-0.02756686,0.013841302,-0.012664551,-0.0034603255,-0.049192086,-0.021991756,0.024113767,-0.034936026,0.03140577,0.02741253,-0.027894806,0.011912201,-0.030190436,-0.016310552,-0.0134169,-0.02056422,-0.035611212,-0.010513603,0.055249464,0.016648145,-0.05594394,0.004231966,0.036324978,-0.017738087,-0.01360981,-0.020660676,-0.0302676,0.034936026,-0.019696126,0.01762234,0.02436455,0.031058533,0.030132564,0.017747732,-0.022474032,0.023998022,-0.009471888,0.048227534,-0.01380272,0.03748244,0.0074704452,-0.02552201,0.013966694,-0.024268094,-0.015828276,-0.015963314,0.022377577,-0.024615334,0.002278751,-0.020872876,-0.048266117,0.0034338005,-0.006771146,0.0102435285,0.030113272,0.031039242,-0.029727452,-0.09784402,-0.001253916,0.036132067,-0.031945918,-0.031540807,-0.05440066,0.0063226297,-0.00598986,0.011304534,0.0098962905,0.024480296,0.016368425,-0.015963314,0.024576752,0.021760264,-0.032447483,-0.017178647,0.0006317807,-0.11628623,-0.05096686,0.0038268548,-0.017574113,0.01541352,-0.005039777,-0.018963067,0.010272465,0.034473043,0.0086279055,0.24831393,-0.0027320897,-0.044253584,-0.010185655,0.026293652,-0.023207089,-0.02037131,0.05798879,0.050889693,-0.04375202,-0.044639405,0.0127127785,0.012191921,-0.026139325,0.0014130668,0.025059028,-0.035649795,-0.02419093,0.07218698,-0.013387963,0.0457197,-0.02149019,0.0048034624,-0.019889034,-0.0007939458,-0.044022094,0.009158409,0.03809975,-0.004552679,0.009500824,-0.041977245,0.01066793,0.05482506,-0.014284995,-0.0124716405,0.028377082,0.030325474,0.04205441,-0.014535779,0.029746743,0.034338005,-0.016281616,-0.0116035445,0.0065300083,-0.009553875,0.005575103,-0.013523,0.00037647618,0.0367108,-0.028492827,0.016532399,-0.007099093,-0.05189283,-0.010214591,-0.015895795,-0.012896042,-0.046529926,-0.0071424977,-0.020969331,0.0729972,0.04166859,0.037578896,-0.08418599,-0.01197972,0.032486066,0.033952184,-0.09089926,0.0033301113,0.012982853,0.008979967,0.049192086,-0.009095713,-0.020892167,-0.029920362,0.02966958,-0.024171641,-0.005531698,0.0015251958,0.024615334,0.034550205,-0.01122737,0.017641632,-0.040048145,-0.015596785,0.03171443,0.0055268756,0.04514097,0.014159604,-0.005025309,0.014564715,-0.01285746,0.008594147,-0.031444352,-0.013117889,-0.018702637,-0.02756686,-0.01161319,-0.044060677,-0.02779835,0.0049819043,-0.018316818,-0.040588293,0.007943075,0.0015698062,-0.042555977,0.025927123,-0.009626216,-0.0048155193,-0.013175762,0.016696373,-0.047648802,0.012355895,-0.008275845,-0.0017048434,-0.02986249,-0.024596043,-0.024673207,0.039893817,0.041977245,0.037231658,-0.04375202,0.036112778,-0.031502225,0.075080626,-0.025637757,-0.013281863,0.007996125,0.0043115416,0.013523,0.044292167,-0.008767766,-0.015963314,-0.08171673,-0.0056426213,0.04220874,0.018094972,0.021625226,0.014207832,0.014294641,0.07210981,-0.02567634,0.0026525145,-0.013156472,0.053706184,-0.014188541,0.0108704865,0.008970321,-0.02548343,-0.012375185,-0.0031154987,0.038543444,0.024596043,0.050195217,-0.062078483,0.0024403133,-0.034318715,-0.016706018,-0.059609234,-0.03250536,-0.036228523,0.0010338777,-0.021181533,0.02451888,0.08665524,0.030730585,0.018664056,0.010339984,-0.017053256,0.027084583,-0.024325969,-0.00011084798,-0.016898928,-0.07195548,-0.084263146,0.019464632,0.016792828,-0.010735449,-0.0057053175,-0.0068965373,0.016947156,0.0251169,0.03536043,0.053050287,0.05196999,0.0058644684,-0.0098962905,-0.024808243,-0.01189291,-0.0074656224,-0.041784335,0.040819786,0.08572926,0.014429678,0.009196991,0.06296587,0.06871459,0.04452366,-0.0060477327,-0.018027453,-0.018500082,0.021200825,0.013127535,-0.0052760923,0.013580874,0.02756686,-0.010359274,-0.044485077,0.046529926,0.0026959192,-0.0031516694,-0.019262077,-0.007875556,0.030209728,-0.0020822238,-0.029013684,-0.009544229,-0.0013467539,0.008820816,-0.00071437034,-0.0058885817,0.023245672,-0.0033445796,0.040626876,-0.01236554,-0.0031806058,0.044948064,-0.031540807,0.0043308325,0.04888343,0.03883281,-0.0036001855,0.013725556,-0.05042671,-0.037463147,0.00937061,-0.050118055,0.008734006,0.03119357,-0.037135202,-0.019194558,-0.029264469,-0.049346413,-0.01768986,-0.007668178,0.022512613,0.021181533,-0.015249547,-0.0020520815,0.03539901,0.051275514,0.025136191,0.017805606,0.0022486087,-0.052973125,-0.0017651278,0.036189944,-0.038138334,-0.017506596,0.0071569663,0.039893817,-0.014053504,0.046761416,0.029264469,0.02436455,-0.022879142,-0.08380017,-0.002108749,0.033971474,-0.008555565,-0.057294313,-0.033373453,-0.0126452595,-0.0012026741,0.0030431575,0.012269084,-0.01236554,-0.012336603,0.04791888,0.019696126,-0.023920856,0.025386974,0.019223494,0.013773784,0.017178647,-0.005358079,-0.034608077,0.042363066,0.021818137,-0.023843693,0.009741962,-0.0053098514,0.0032529472,-0.011150206,0.037135202,-0.011381698,0.029785326,0.014873371,0.0070074606,-0.030981367,0.025078317,-0.03578483,0.037848968,-0.018210717,0.035534047,0.002905709,0.038524155,0.020911459,0.012635614,0.039122175,0.027065292,0.010725804,-0.06802011,-0.00851216,-0.0050590686,0.018789448,-0.0002525917,0.009573165,0.004870981,0.009052308,0.03422226,-0.012230502,-0.032466777,-0.041552845,-0.023650782,-0.0016674671,-0.031154986,-0.00028333676,0.021914592,-0.039855234,-0.03651789,-0.035669085,0.042363066,-0.02284056,-0.022281121,0.0060380874,-0.03578483,0.02739324,-0.019030586,0.029476669,0.004897506,0.0022184665,0.008492868,0.057757296,-0.035649795,-0.010532893,-0.0068579554,0.016368425,0.03119357,0.014815498,0.022107502,-0.0090281945,0.013822012,-0.014342869,-0.015972959,0.0040607583,0.033006925,0.0056233304,0.003142024,0.06300445,-0.03140577,-0.01562572,0.011835037,-0.007398104,-0.013725556,0.027894806,0.012191921,0.007943075,0.039855234,0.016484171,0.0020689613,0.0024017312,0.010446084,-0.0020834296,-0.035842706,0.001427535,0.04853619,-0.04054971,0.0059753917,-0.004096929,-0.0011990571,0.0100023905,-0.03543759,0.0011261129,-0.008237263,0.026853092,0.035842706,-0.009008903,0.0008035913,0.04398351,0.014130668,0.0065444764,-0.020081945,-0.029052267,-0.0039667147,-0.15579423,0.0010121753,-0.025251936,-0.049384996,-0.030846331,-0.005806595,0.00359054,-0.014776916,-0.024248805,-0.031810883,0.0052857376,-0.00053261284,-0.025039736,-0.020718548,0.02037131,0.0231878,-0.0027706719,0.011825391,0.025946414,0.036074195,-0.026332233,-0.015770404,0.01629126,0.036787964,-0.009023372,-0.010272465,0.027914098,0.020815004,-0.046954326,0.016522754,-0.025965706,-0.000936217,0.015702885,0.065550864,0.012105111,-0.012269084,0.022242539,-0.03806117,0.011748227,0.013995631,-0.014217477,0.040279638,0.054130584,0.047996044,-0.013320445,0.0014829967,0.025174772,0.0072437758,-0.029573124,-0.007335408,-0.023998022,0.017699504,-0.07646958,0.0011056162,-0.01064864,-0.00718108,-0.008989613,-0.010484666,0.03273685,0.045758285,0.016677082,-0.04375202,-0.033276998,-0.025213355,-0.040819786,-0.016792828,-0.06639967,0.04564254,0.0053725475,0.018133553,-0.059840724,-0.0126452595,0.00096937345,-0.039893817,-0.0056812037,0.02874361,0.083260015,-0.040086728,-0.059223413,0.0050735367,-0.02777906,0.034202967,0.055635285,-0.011343116,0.0023305956,0.0047697034,0.03483957,0.015481039,-0.014516488,0.021779554,-0.060187962,-0.019348888,0.036730092,-0.03271756,-0.0076344186,-0.0085218055,-0.028627865,-0.060458038,-0.019098103,-0.05536521,0.01777667,0.003354225,-0.012230502,-0.013928112,-0.064084746,0.023515746,-0.026968837,0.0067807916,0.0018362633,0.011073042,0.026853092,0.003942601,-0.039450124,0.04413784,-0.022146083,0.008946207,-0.008444642,-0.015268837,-0.066746905,0.01227873,-0.009558697,-0.020834295,-0.033392746,-0.022281121,0.015866859,-0.018210717,0.04510239,0.0032625927,-0.00965033,0.016628854,0.018538665,-0.08256554,-0.0039932397,0.020988623,0.024499588,0.004441756,-0.0133397365,0.04699291,-0.033392746,-0.00012659728,-0.0021654163,-0.03464666,-0.020429183,-0.020795712,-0.028955812,-0.02968887,0.011381698,0.005454534,0.006472135,-0.010880132,0.0302676,-0.038389117,-0.037328113,0.026563726,0.006221352,-0.015577493,0.01958038,0.03237032,-0.00038823165,0.058297444,0.00026178508,-0.06790437,-0.01236554,-0.023940148,-0.017718796,0.054246332,0.020236274,-0.026312944,-0.07137675,-0.021683099,0.0026332233,0.037540313,-0.030344766,0.053127453,0.012828524,0.038755648,-0.015587139,-0.030846331,0.063969,0.013735202,0.029997526,0.011651772,-0.0019049876,0.050542455,-0.026197197,0.047996044,-0.0022642827,-0.00053984695,0.018712284,0.0028430133,0.023207089,0.013387963,0.013214344,-0.02419093,0.04247881,-0.010774031,0.031039242,0.027508985,-0.045565374,0.012481286,-0.052625887,-0.0073305853,-0.018567601,-0.047841713,-0.027335366,0.005806595,0.01605977,-0.03101995,0.013937757,-0.03329629,-0.03269827,-0.037926134,0.0051555233,0.012085821,-0.0024668383,0.022551196,0.026988128,0.00851216,0.02912943,-0.017950289,-0.02720033,-0.0030311006,-0.0034916734,0.016860345,-0.0062695793,0.0026669826,-0.04286463,0.003040746,-0.017236521,0.012587386,-0.05613685,0.029630996,-0.016416652,0.015519621,-0.0005497939,0.033276998,-0.010899423,0.0036484129,-0.027354658,0.013387963,0.015780048,0.003091385,-0.055480957,-0.033759274]
47	c9c49cb6-8e61-488c-886b-f16473b7e0d8	c6dc2419-8255-4b00-9d9b-56a94ad9feaa	怀孕，身体乏力	患者自述怀孕，感觉身体乏力，未提及具体症状发展过程。	未详细说明	未详细说明	\N	建议进行孕期常规检查，待医生进一步评估。	\N	f	待医生问诊后确定	[0.013175762,0.014352514,-0.05077395,-0.029804617,-0.023110634,-0.060998186,0.01762234,0.013243281,0.016127288,-0.026177905,-0.017853834,-0.015683595,-0.046298433,0.04394493,0.0090716,-0.008020239,0.0026211664,-0.017535532,-0.029920362,0.022879142,-0.0054063066,0.013040725,0.023284255,-0.015162737,-0.0356305,0.024171641,-0.027142456,-0.00062936934,0.07581368,0.001888108,0.023342127,-0.023747237,0.023052761,-0.04054971,0.0015686005,-0.03848557,0.006732564,-0.021085078,-0.029225886,0.046221267,0.018220363,-0.017699504,0.021779554,-0.018008161,0.017593404,-0.036923,-0.021798845,-0.01131418,-0.0034000413,-0.016146578,0.028820775,-0.034936026,0.022416158,-0.021721682,0.019628607,0.020757131,-0.002963582,-0.04247881,-0.038890682,-0.021065786,-0.020525638,0.0001133347,0.019088458,-0.022281121,-0.00084277615,0.062271394,0.03329629,-0.018345755,-0.029881781,-0.053320363,-0.00088497525,0.0063612117,-0.021605935,0.0010881338,-0.049153503,0.03269827,-0.0014383863,-0.040086728,0.011564963,0.018123908,0.026177905,0.039855234,0.022377577,0.011478153,-0.017998517,-0.0024210222,-0.02741253,-0.005907873,-0.047725968,-0.03844699,-0.016416652,0.043867767,-0.046337016,-0.011564963,-0.03862061,-0.0011435954,-0.023072053,-0.034299422,0.025348391,-0.009399546,0.022281121,-0.016889283,0.012674196,-0.0032336563,-0.00018642956,-0.0016566158,0.001168312,-0.012114757,0.030229019,-0.014497197,0.022416158,-0.004193384,0.042324483,0.009129472,0.009544229,-0.0167446,-0.026100742,-0.014014921,-0.00020632343,-0.031039242,0.0468,0.022551196,0.002893652,-0.021162242,-0.035842706,0.031232152,0.042710304,0.024248805,-0.027528277,0.028087717,0.00571014,-0.025425557,-0.05389909,-0.033566363,0.004429699,-0.05104402,0.03555334,0.01760305,-0.034338005,0.008787056,-0.043134708,0.07353734,0.0005922944,-0.02475037,-0.008951031,-0.05208574,0.04147568,-0.0013214344,0.03676867,0.025541302,-0.0521629,0.0020749897,-0.00034753967,0.03372069,0.01103446,0.03802259,0.012423413,0.017834542,-0.04645276,0.034010056,0.07249563,-0.0067373863,-0.04259456,-0.0041258656,-0.030364055,-0.0017000206,0.00126115,0.0038799052,-0.020236274,0.057602968,0.041938663,-0.052240066,0.024133058,-0.032254577,0.016599918,0.019368177,0.077588454,0.029611707,-0.0049047405,-0.036247816,-0.017525885,0.033431325,0.031675845,-0.040781204,-0.007803215,-0.0054448885,-0.004241612,-0.0201784,1.0757001e-05,0.011391344,0.003211954,-0.03595845,0.0021521538,0.022589777,0.07037362,0.003424155,0.012973207,-0.012886398,0.010320692,-0.00013036505,0.07064369,0.032215994,0.020602804,-0.024981864,-0.018393982,0.00023149216,-0.035611212,-0.07411607,0.008719538,-0.040704038,0.030306183,0.03578483,0.006423908,0.0076392414,-0.028608574,0.012114757,-0.022184666,-0.07376884,-0.019262077,0.0057487222,-0.022744106,0.008328895,0.034878153,-0.06068953,-0.017757379,0.044793732,-0.0045864386,0.0364986,0.001972506,-0.030904204,-0.008362655,0.050465293,0.0044200537,-0.0006757883,0.07596801,0.0027007419,-0.004608141,-0.0009832388,0.0010230265,0.010426793,-0.0026452802,-0.029148722,0.029071558,0.024943281,0.0023245672,-0.040858366,0.013397609,0.040858366,-0.016638499,0.002483718,0.039855234,0.006939942,-0.018220363,-0.0076247733,0.00024038412,0.008946207,-0.003945012,-0.01217263,-0.003699052,0.0029732275,-0.02889794,0.025657048,0.014005276,0.033064798,0.00046780708,-0.044948064,-0.0321967,-0.012375185,0.0031613149,0.037848968,-0.0023583265,0.0060670236,0.0352061,0.024268094,0.0029081204,-0.0007342642,-0.0055606347,0.0040342333,0.03364353,-0.027894806,-0.027026711,0.016204452,-0.0033952184,-0.011690354,-0.00050819764,0.00338075,0.0457197,-0.0382155,-0.0048106965,-0.04811179,-0.009110182,-0.009992745,0.05231723,0.012828524,0.02451888,0.02664089,0.03840841,-0.17577972,-0.0044538127,-0.008695425,-0.009303091,-0.02756686,0.013841302,-0.012664551,-0.0034603255,-0.049192086,-0.021991756,0.024113767,-0.034936026,0.03140577,0.02741253,-0.027894806,0.011912201,-0.030190436,-0.016310552,-0.0134169,-0.02056422,-0.035611212,-0.010513603,0.055249464,0.016648145,-0.05594394,0.004231966,0.036324978,-0.017738087,-0.01360981,-0.020660676,-0.0302676,0.034936026,-0.019696126,0.01762234,0.02436455,0.031058533,0.030132564,0.017747732,-0.022474032,0.023998022,-0.009471888,0.048227534,-0.01380272,0.03748244,0.0074704452,-0.02552201,0.013966694,-0.024268094,-0.015828276,-0.015963314,0.022377577,-0.024615334,0.002278751,-0.020872876,-0.048266117,0.0034338005,-0.006771146,0.0102435285,0.030113272,0.031039242,-0.029727452,-0.09784402,-0.001253916,0.036132067,-0.031945918,-0.031540807,-0.05440066,0.0063226297,-0.00598986,0.011304534,0.0098962905,0.024480296,0.016368425,-0.015963314,0.024576752,0.021760264,-0.032447483,-0.017178647,0.0006317807,-0.11628623,-0.05096686,0.0038268548,-0.017574113,0.01541352,-0.005039777,-0.018963067,0.010272465,0.034473043,0.0086279055,0.24831393,-0.0027320897,-0.044253584,-0.010185655,0.026293652,-0.023207089,-0.02037131,0.05798879,0.050889693,-0.04375202,-0.044639405,0.0127127785,0.012191921,-0.026139325,0.0014130668,0.025059028,-0.035649795,-0.02419093,0.07218698,-0.013387963,0.0457197,-0.02149019,0.0048034624,-0.019889034,-0.0007939458,-0.044022094,0.009158409,0.03809975,-0.004552679,0.009500824,-0.041977245,0.01066793,0.05482506,-0.014284995,-0.0124716405,0.028377082,0.030325474,0.04205441,-0.014535779,0.029746743,0.034338005,-0.016281616,-0.0116035445,0.0065300083,-0.009553875,0.005575103,-0.013523,0.00037647618,0.0367108,-0.028492827,0.016532399,-0.007099093,-0.05189283,-0.010214591,-0.015895795,-0.012896042,-0.046529926,-0.0071424977,-0.020969331,0.0729972,0.04166859,0.037578896,-0.08418599,-0.01197972,0.032486066,0.033952184,-0.09089926,0.0033301113,0.012982853,0.008979967,0.049192086,-0.009095713,-0.020892167,-0.029920362,0.02966958,-0.024171641,-0.005531698,0.0015251958,0.024615334,0.034550205,-0.01122737,0.017641632,-0.040048145,-0.015596785,0.03171443,0.0055268756,0.04514097,0.014159604,-0.005025309,0.014564715,-0.01285746,0.008594147,-0.031444352,-0.013117889,-0.018702637,-0.02756686,-0.01161319,-0.044060677,-0.02779835,0.0049819043,-0.018316818,-0.040588293,0.007943075,0.0015698062,-0.042555977,0.025927123,-0.009626216,-0.0048155193,-0.013175762,0.016696373,-0.047648802,0.012355895,-0.008275845,-0.0017048434,-0.02986249,-0.024596043,-0.024673207,0.039893817,0.041977245,0.037231658,-0.04375202,0.036112778,-0.031502225,0.075080626,-0.025637757,-0.013281863,0.007996125,0.0043115416,0.013523,0.044292167,-0.008767766,-0.015963314,-0.08171673,-0.0056426213,0.04220874,0.018094972,0.021625226,0.014207832,0.014294641,0.07210981,-0.02567634,0.0026525145,-0.013156472,0.053706184,-0.014188541,0.0108704865,0.008970321,-0.02548343,-0.012375185,-0.0031154987,0.038543444,0.024596043,0.050195217,-0.062078483,0.0024403133,-0.034318715,-0.016706018,-0.059609234,-0.03250536,-0.036228523,0.0010338777,-0.021181533,0.02451888,0.08665524,0.030730585,0.018664056,0.010339984,-0.017053256,0.027084583,-0.024325969,-0.00011084798,-0.016898928,-0.07195548,-0.084263146,0.019464632,0.016792828,-0.010735449,-0.0057053175,-0.0068965373,0.016947156,0.0251169,0.03536043,0.053050287,0.05196999,0.0058644684,-0.0098962905,-0.024808243,-0.01189291,-0.0074656224,-0.041784335,0.040819786,0.08572926,0.014429678,0.009196991,0.06296587,0.06871459,0.04452366,-0.0060477327,-0.018027453,-0.018500082,0.021200825,0.013127535,-0.0052760923,0.013580874,0.02756686,-0.010359274,-0.044485077,0.046529926,0.0026959192,-0.0031516694,-0.019262077,-0.007875556,0.030209728,-0.0020822238,-0.029013684,-0.009544229,-0.0013467539,0.008820816,-0.00071437034,-0.0058885817,0.023245672,-0.0033445796,0.040626876,-0.01236554,-0.0031806058,0.044948064,-0.031540807,0.0043308325,0.04888343,0.03883281,-0.0036001855,0.013725556,-0.05042671,-0.037463147,0.00937061,-0.050118055,0.008734006,0.03119357,-0.037135202,-0.019194558,-0.029264469,-0.049346413,-0.01768986,-0.007668178,0.022512613,0.021181533,-0.015249547,-0.0020520815,0.03539901,0.051275514,0.025136191,0.017805606,0.0022486087,-0.052973125,-0.0017651278,0.036189944,-0.038138334,-0.017506596,0.0071569663,0.039893817,-0.014053504,0.046761416,0.029264469,0.02436455,-0.022879142,-0.08380017,-0.002108749,0.033971474,-0.008555565,-0.057294313,-0.033373453,-0.0126452595,-0.0012026741,0.0030431575,0.012269084,-0.01236554,-0.012336603,0.04791888,0.019696126,-0.023920856,0.025386974,0.019223494,0.013773784,0.017178647,-0.005358079,-0.034608077,0.042363066,0.021818137,-0.023843693,0.009741962,-0.0053098514,0.0032529472,-0.011150206,0.037135202,-0.011381698,0.029785326,0.014873371,0.0070074606,-0.030981367,0.025078317,-0.03578483,0.037848968,-0.018210717,0.035534047,0.002905709,0.038524155,0.020911459,0.012635614,0.039122175,0.027065292,0.010725804,-0.06802011,-0.00851216,-0.0050590686,0.018789448,-0.0002525917,0.009573165,0.004870981,0.009052308,0.03422226,-0.012230502,-0.032466777,-0.041552845,-0.023650782,-0.0016674671,-0.031154986,-0.00028333676,0.021914592,-0.039855234,-0.03651789,-0.035669085,0.042363066,-0.02284056,-0.022281121,0.0060380874,-0.03578483,0.02739324,-0.019030586,0.029476669,0.004897506,0.0022184665,0.008492868,0.057757296,-0.035649795,-0.010532893,-0.0068579554,0.016368425,0.03119357,0.014815498,0.022107502,-0.0090281945,0.013822012,-0.014342869,-0.015972959,0.0040607583,0.033006925,0.0056233304,0.003142024,0.06300445,-0.03140577,-0.01562572,0.011835037,-0.007398104,-0.013725556,0.027894806,0.012191921,0.007943075,0.039855234,0.016484171,0.0020689613,0.0024017312,0.010446084,-0.0020834296,-0.035842706,0.001427535,0.04853619,-0.04054971,0.0059753917,-0.004096929,-0.0011990571,0.0100023905,-0.03543759,0.0011261129,-0.008237263,0.026853092,0.035842706,-0.009008903,0.0008035913,0.04398351,0.014130668,0.0065444764,-0.020081945,-0.029052267,-0.0039667147,-0.15579423,0.0010121753,-0.025251936,-0.049384996,-0.030846331,-0.005806595,0.00359054,-0.014776916,-0.024248805,-0.031810883,0.0052857376,-0.00053261284,-0.025039736,-0.020718548,0.02037131,0.0231878,-0.0027706719,0.011825391,0.025946414,0.036074195,-0.026332233,-0.015770404,0.01629126,0.036787964,-0.009023372,-0.010272465,0.027914098,0.020815004,-0.046954326,0.016522754,-0.025965706,-0.000936217,0.015702885,0.065550864,0.012105111,-0.012269084,0.022242539,-0.03806117,0.011748227,0.013995631,-0.014217477,0.040279638,0.054130584,0.047996044,-0.013320445,0.0014829967,0.025174772,0.0072437758,-0.029573124,-0.007335408,-0.023998022,0.017699504,-0.07646958,0.0011056162,-0.01064864,-0.00718108,-0.008989613,-0.010484666,0.03273685,0.045758285,0.016677082,-0.04375202,-0.033276998,-0.025213355,-0.040819786,-0.016792828,-0.06639967,0.04564254,0.0053725475,0.018133553,-0.059840724,-0.0126452595,0.00096937345,-0.039893817,-0.0056812037,0.02874361,0.083260015,-0.040086728,-0.059223413,0.0050735367,-0.02777906,0.034202967,0.055635285,-0.011343116,0.0023305956,0.0047697034,0.03483957,0.015481039,-0.014516488,0.021779554,-0.060187962,-0.019348888,0.036730092,-0.03271756,-0.0076344186,-0.0085218055,-0.028627865,-0.060458038,-0.019098103,-0.05536521,0.01777667,0.003354225,-0.012230502,-0.013928112,-0.064084746,0.023515746,-0.026968837,0.0067807916,0.0018362633,0.011073042,0.026853092,0.003942601,-0.039450124,0.04413784,-0.022146083,0.008946207,-0.008444642,-0.015268837,-0.066746905,0.01227873,-0.009558697,-0.020834295,-0.033392746,-0.022281121,0.015866859,-0.018210717,0.04510239,0.0032625927,-0.00965033,0.016628854,0.018538665,-0.08256554,-0.0039932397,0.020988623,0.024499588,0.004441756,-0.0133397365,0.04699291,-0.033392746,-0.00012659728,-0.0021654163,-0.03464666,-0.020429183,-0.020795712,-0.028955812,-0.02968887,0.011381698,0.005454534,0.006472135,-0.010880132,0.0302676,-0.038389117,-0.037328113,0.026563726,0.006221352,-0.015577493,0.01958038,0.03237032,-0.00038823165,0.058297444,0.00026178508,-0.06790437,-0.01236554,-0.023940148,-0.017718796,0.054246332,0.020236274,-0.026312944,-0.07137675,-0.021683099,0.0026332233,0.037540313,-0.030344766,0.053127453,0.012828524,0.038755648,-0.015587139,-0.030846331,0.063969,0.013735202,0.029997526,0.011651772,-0.0019049876,0.050542455,-0.026197197,0.047996044,-0.0022642827,-0.00053984695,0.018712284,0.0028430133,0.023207089,0.013387963,0.013214344,-0.02419093,0.04247881,-0.010774031,0.031039242,0.027508985,-0.045565374,0.012481286,-0.052625887,-0.0073305853,-0.018567601,-0.047841713,-0.027335366,0.005806595,0.01605977,-0.03101995,0.013937757,-0.03329629,-0.03269827,-0.037926134,0.0051555233,0.012085821,-0.0024668383,0.022551196,0.026988128,0.00851216,0.02912943,-0.017950289,-0.02720033,-0.0030311006,-0.0034916734,0.016860345,-0.0062695793,0.0026669826,-0.04286463,0.003040746,-0.017236521,0.012587386,-0.05613685,0.029630996,-0.016416652,0.015519621,-0.0005497939,0.033276998,-0.010899423,0.0036484129,-0.027354658,0.013387963,0.015780048,0.003091385,-0.055480957,-0.033759274]
48	ff10b83f-5cab-4c9e-9969-d7f9c690c34a	2f5d38eb-2c00-4d41-88d2-18e2ad56f7fc	主诉：怀孕，身体乏力	现病史：患者自述怀孕，感觉身体乏力，未提及具体症状发展过程	未详细说明	未详细说明	\N	建议进行孕期常规检查	\N	f	待医生问诊后确定	[0.013175762,0.014352514,-0.05077395,-0.029804617,-0.023110634,-0.060998186,0.01762234,0.013243281,0.016127288,-0.026177905,-0.017853834,-0.015683595,-0.046298433,0.04394493,0.0090716,-0.008020239,0.0026211664,-0.017535532,-0.029920362,0.022879142,-0.0054063066,0.013040725,0.023284255,-0.015162737,-0.0356305,0.024171641,-0.027142456,-0.00062936934,0.07581368,0.001888108,0.023342127,-0.023747237,0.023052761,-0.04054971,0.0015686005,-0.03848557,0.006732564,-0.021085078,-0.029225886,0.046221267,0.018220363,-0.017699504,0.021779554,-0.018008161,0.017593404,-0.036923,-0.021798845,-0.01131418,-0.0034000413,-0.016146578,0.028820775,-0.034936026,0.022416158,-0.021721682,0.019628607,0.020757131,-0.002963582,-0.04247881,-0.038890682,-0.021065786,-0.020525638,0.0001133347,0.019088458,-0.022281121,-0.00084277615,0.062271394,0.03329629,-0.018345755,-0.029881781,-0.053320363,-0.00088497525,0.0063612117,-0.021605935,0.0010881338,-0.049153503,0.03269827,-0.0014383863,-0.040086728,0.011564963,0.018123908,0.026177905,0.039855234,0.022377577,0.011478153,-0.017998517,-0.0024210222,-0.02741253,-0.005907873,-0.047725968,-0.03844699,-0.016416652,0.043867767,-0.046337016,-0.011564963,-0.03862061,-0.0011435954,-0.023072053,-0.034299422,0.025348391,-0.009399546,0.022281121,-0.016889283,0.012674196,-0.0032336563,-0.00018642956,-0.0016566158,0.001168312,-0.012114757,0.030229019,-0.014497197,0.022416158,-0.004193384,0.042324483,0.009129472,0.009544229,-0.0167446,-0.026100742,-0.014014921,-0.00020632343,-0.031039242,0.0468,0.022551196,0.002893652,-0.021162242,-0.035842706,0.031232152,0.042710304,0.024248805,-0.027528277,0.028087717,0.00571014,-0.025425557,-0.05389909,-0.033566363,0.004429699,-0.05104402,0.03555334,0.01760305,-0.034338005,0.008787056,-0.043134708,0.07353734,0.0005922944,-0.02475037,-0.008951031,-0.05208574,0.04147568,-0.0013214344,0.03676867,0.025541302,-0.0521629,0.0020749897,-0.00034753967,0.03372069,0.01103446,0.03802259,0.012423413,0.017834542,-0.04645276,0.034010056,0.07249563,-0.0067373863,-0.04259456,-0.0041258656,-0.030364055,-0.0017000206,0.00126115,0.0038799052,-0.020236274,0.057602968,0.041938663,-0.052240066,0.024133058,-0.032254577,0.016599918,0.019368177,0.077588454,0.029611707,-0.0049047405,-0.036247816,-0.017525885,0.033431325,0.031675845,-0.040781204,-0.007803215,-0.0054448885,-0.004241612,-0.0201784,1.0757001e-05,0.011391344,0.003211954,-0.03595845,0.0021521538,0.022589777,0.07037362,0.003424155,0.012973207,-0.012886398,0.010320692,-0.00013036505,0.07064369,0.032215994,0.020602804,-0.024981864,-0.018393982,0.00023149216,-0.035611212,-0.07411607,0.008719538,-0.040704038,0.030306183,0.03578483,0.006423908,0.0076392414,-0.028608574,0.012114757,-0.022184666,-0.07376884,-0.019262077,0.0057487222,-0.022744106,0.008328895,0.034878153,-0.06068953,-0.017757379,0.044793732,-0.0045864386,0.0364986,0.001972506,-0.030904204,-0.008362655,0.050465293,0.0044200537,-0.0006757883,0.07596801,0.0027007419,-0.004608141,-0.0009832388,0.0010230265,0.010426793,-0.0026452802,-0.029148722,0.029071558,0.024943281,0.0023245672,-0.040858366,0.013397609,0.040858366,-0.016638499,0.002483718,0.039855234,0.006939942,-0.018220363,-0.0076247733,0.00024038412,0.008946207,-0.003945012,-0.01217263,-0.003699052,0.0029732275,-0.02889794,0.025657048,0.014005276,0.033064798,0.00046780708,-0.044948064,-0.0321967,-0.012375185,0.0031613149,0.037848968,-0.0023583265,0.0060670236,0.0352061,0.024268094,0.0029081204,-0.0007342642,-0.0055606347,0.0040342333,0.03364353,-0.027894806,-0.027026711,0.016204452,-0.0033952184,-0.011690354,-0.00050819764,0.00338075,0.0457197,-0.0382155,-0.0048106965,-0.04811179,-0.009110182,-0.009992745,0.05231723,0.012828524,0.02451888,0.02664089,0.03840841,-0.17577972,-0.0044538127,-0.008695425,-0.009303091,-0.02756686,0.013841302,-0.012664551,-0.0034603255,-0.049192086,-0.021991756,0.024113767,-0.034936026,0.03140577,0.02741253,-0.027894806,0.011912201,-0.030190436,-0.016310552,-0.0134169,-0.02056422,-0.035611212,-0.010513603,0.055249464,0.016648145,-0.05594394,0.004231966,0.036324978,-0.017738087,-0.01360981,-0.020660676,-0.0302676,0.034936026,-0.019696126,0.01762234,0.02436455,0.031058533,0.030132564,0.017747732,-0.022474032,0.023998022,-0.009471888,0.048227534,-0.01380272,0.03748244,0.0074704452,-0.02552201,0.013966694,-0.024268094,-0.015828276,-0.015963314,0.022377577,-0.024615334,0.002278751,-0.020872876,-0.048266117,0.0034338005,-0.006771146,0.0102435285,0.030113272,0.031039242,-0.029727452,-0.09784402,-0.001253916,0.036132067,-0.031945918,-0.031540807,-0.05440066,0.0063226297,-0.00598986,0.011304534,0.0098962905,0.024480296,0.016368425,-0.015963314,0.024576752,0.021760264,-0.032447483,-0.017178647,0.0006317807,-0.11628623,-0.05096686,0.0038268548,-0.017574113,0.01541352,-0.005039777,-0.018963067,0.010272465,0.034473043,0.0086279055,0.24831393,-0.0027320897,-0.044253584,-0.010185655,0.026293652,-0.023207089,-0.02037131,0.05798879,0.050889693,-0.04375202,-0.044639405,0.0127127785,0.012191921,-0.026139325,0.0014130668,0.025059028,-0.035649795,-0.02419093,0.07218698,-0.013387963,0.0457197,-0.02149019,0.0048034624,-0.019889034,-0.0007939458,-0.044022094,0.009158409,0.03809975,-0.004552679,0.009500824,-0.041977245,0.01066793,0.05482506,-0.014284995,-0.0124716405,0.028377082,0.030325474,0.04205441,-0.014535779,0.029746743,0.034338005,-0.016281616,-0.0116035445,0.0065300083,-0.009553875,0.005575103,-0.013523,0.00037647618,0.0367108,-0.028492827,0.016532399,-0.007099093,-0.05189283,-0.010214591,-0.015895795,-0.012896042,-0.046529926,-0.0071424977,-0.020969331,0.0729972,0.04166859,0.037578896,-0.08418599,-0.01197972,0.032486066,0.033952184,-0.09089926,0.0033301113,0.012982853,0.008979967,0.049192086,-0.009095713,-0.020892167,-0.029920362,0.02966958,-0.024171641,-0.005531698,0.0015251958,0.024615334,0.034550205,-0.01122737,0.017641632,-0.040048145,-0.015596785,0.03171443,0.0055268756,0.04514097,0.014159604,-0.005025309,0.014564715,-0.01285746,0.008594147,-0.031444352,-0.013117889,-0.018702637,-0.02756686,-0.01161319,-0.044060677,-0.02779835,0.0049819043,-0.018316818,-0.040588293,0.007943075,0.0015698062,-0.042555977,0.025927123,-0.009626216,-0.0048155193,-0.013175762,0.016696373,-0.047648802,0.012355895,-0.008275845,-0.0017048434,-0.02986249,-0.024596043,-0.024673207,0.039893817,0.041977245,0.037231658,-0.04375202,0.036112778,-0.031502225,0.075080626,-0.025637757,-0.013281863,0.007996125,0.0043115416,0.013523,0.044292167,-0.008767766,-0.015963314,-0.08171673,-0.0056426213,0.04220874,0.018094972,0.021625226,0.014207832,0.014294641,0.07210981,-0.02567634,0.0026525145,-0.013156472,0.053706184,-0.014188541,0.0108704865,0.008970321,-0.02548343,-0.012375185,-0.0031154987,0.038543444,0.024596043,0.050195217,-0.062078483,0.0024403133,-0.034318715,-0.016706018,-0.059609234,-0.03250536,-0.036228523,0.0010338777,-0.021181533,0.02451888,0.08665524,0.030730585,0.018664056,0.010339984,-0.017053256,0.027084583,-0.024325969,-0.00011084798,-0.016898928,-0.07195548,-0.084263146,0.019464632,0.016792828,-0.010735449,-0.0057053175,-0.0068965373,0.016947156,0.0251169,0.03536043,0.053050287,0.05196999,0.0058644684,-0.0098962905,-0.024808243,-0.01189291,-0.0074656224,-0.041784335,0.040819786,0.08572926,0.014429678,0.009196991,0.06296587,0.06871459,0.04452366,-0.0060477327,-0.018027453,-0.018500082,0.021200825,0.013127535,-0.0052760923,0.013580874,0.02756686,-0.010359274,-0.044485077,0.046529926,0.0026959192,-0.0031516694,-0.019262077,-0.007875556,0.030209728,-0.0020822238,-0.029013684,-0.009544229,-0.0013467539,0.008820816,-0.00071437034,-0.0058885817,0.023245672,-0.0033445796,0.040626876,-0.01236554,-0.0031806058,0.044948064,-0.031540807,0.0043308325,0.04888343,0.03883281,-0.0036001855,0.013725556,-0.05042671,-0.037463147,0.00937061,-0.050118055,0.008734006,0.03119357,-0.037135202,-0.019194558,-0.029264469,-0.049346413,-0.01768986,-0.007668178,0.022512613,0.021181533,-0.015249547,-0.0020520815,0.03539901,0.051275514,0.025136191,0.017805606,0.0022486087,-0.052973125,-0.0017651278,0.036189944,-0.038138334,-0.017506596,0.0071569663,0.039893817,-0.014053504,0.046761416,0.029264469,0.02436455,-0.022879142,-0.08380017,-0.002108749,0.033971474,-0.008555565,-0.057294313,-0.033373453,-0.0126452595,-0.0012026741,0.0030431575,0.012269084,-0.01236554,-0.012336603,0.04791888,0.019696126,-0.023920856,0.025386974,0.019223494,0.013773784,0.017178647,-0.005358079,-0.034608077,0.042363066,0.021818137,-0.023843693,0.009741962,-0.0053098514,0.0032529472,-0.011150206,0.037135202,-0.011381698,0.029785326,0.014873371,0.0070074606,-0.030981367,0.025078317,-0.03578483,0.037848968,-0.018210717,0.035534047,0.002905709,0.038524155,0.020911459,0.012635614,0.039122175,0.027065292,0.010725804,-0.06802011,-0.00851216,-0.0050590686,0.018789448,-0.0002525917,0.009573165,0.004870981,0.009052308,0.03422226,-0.012230502,-0.032466777,-0.041552845,-0.023650782,-0.0016674671,-0.031154986,-0.00028333676,0.021914592,-0.039855234,-0.03651789,-0.035669085,0.042363066,-0.02284056,-0.022281121,0.0060380874,-0.03578483,0.02739324,-0.019030586,0.029476669,0.004897506,0.0022184665,0.008492868,0.057757296,-0.035649795,-0.010532893,-0.0068579554,0.016368425,0.03119357,0.014815498,0.022107502,-0.0090281945,0.013822012,-0.014342869,-0.015972959,0.0040607583,0.033006925,0.0056233304,0.003142024,0.06300445,-0.03140577,-0.01562572,0.011835037,-0.007398104,-0.013725556,0.027894806,0.012191921,0.007943075,0.039855234,0.016484171,0.0020689613,0.0024017312,0.010446084,-0.0020834296,-0.035842706,0.001427535,0.04853619,-0.04054971,0.0059753917,-0.004096929,-0.0011990571,0.0100023905,-0.03543759,0.0011261129,-0.008237263,0.026853092,0.035842706,-0.009008903,0.0008035913,0.04398351,0.014130668,0.0065444764,-0.020081945,-0.029052267,-0.0039667147,-0.15579423,0.0010121753,-0.025251936,-0.049384996,-0.030846331,-0.005806595,0.00359054,-0.014776916,-0.024248805,-0.031810883,0.0052857376,-0.00053261284,-0.025039736,-0.020718548,0.02037131,0.0231878,-0.0027706719,0.011825391,0.025946414,0.036074195,-0.026332233,-0.015770404,0.01629126,0.036787964,-0.009023372,-0.010272465,0.027914098,0.020815004,-0.046954326,0.016522754,-0.025965706,-0.000936217,0.015702885,0.065550864,0.012105111,-0.012269084,0.022242539,-0.03806117,0.011748227,0.013995631,-0.014217477,0.040279638,0.054130584,0.047996044,-0.013320445,0.0014829967,0.025174772,0.0072437758,-0.029573124,-0.007335408,-0.023998022,0.017699504,-0.07646958,0.0011056162,-0.01064864,-0.00718108,-0.008989613,-0.010484666,0.03273685,0.045758285,0.016677082,-0.04375202,-0.033276998,-0.025213355,-0.040819786,-0.016792828,-0.06639967,0.04564254,0.0053725475,0.018133553,-0.059840724,-0.0126452595,0.00096937345,-0.039893817,-0.0056812037,0.02874361,0.083260015,-0.040086728,-0.059223413,0.0050735367,-0.02777906,0.034202967,0.055635285,-0.011343116,0.0023305956,0.0047697034,0.03483957,0.015481039,-0.014516488,0.021779554,-0.060187962,-0.019348888,0.036730092,-0.03271756,-0.0076344186,-0.0085218055,-0.028627865,-0.060458038,-0.019098103,-0.05536521,0.01777667,0.003354225,-0.012230502,-0.013928112,-0.064084746,0.023515746,-0.026968837,0.0067807916,0.0018362633,0.011073042,0.026853092,0.003942601,-0.039450124,0.04413784,-0.022146083,0.008946207,-0.008444642,-0.015268837,-0.066746905,0.01227873,-0.009558697,-0.020834295,-0.033392746,-0.022281121,0.015866859,-0.018210717,0.04510239,0.0032625927,-0.00965033,0.016628854,0.018538665,-0.08256554,-0.0039932397,0.020988623,0.024499588,0.004441756,-0.0133397365,0.04699291,-0.033392746,-0.00012659728,-0.0021654163,-0.03464666,-0.020429183,-0.020795712,-0.028955812,-0.02968887,0.011381698,0.005454534,0.006472135,-0.010880132,0.0302676,-0.038389117,-0.037328113,0.026563726,0.006221352,-0.015577493,0.01958038,0.03237032,-0.00038823165,0.058297444,0.00026178508,-0.06790437,-0.01236554,-0.023940148,-0.017718796,0.054246332,0.020236274,-0.026312944,-0.07137675,-0.021683099,0.0026332233,0.037540313,-0.030344766,0.053127453,0.012828524,0.038755648,-0.015587139,-0.030846331,0.063969,0.013735202,0.029997526,0.011651772,-0.0019049876,0.050542455,-0.026197197,0.047996044,-0.0022642827,-0.00053984695,0.018712284,0.0028430133,0.023207089,0.013387963,0.013214344,-0.02419093,0.04247881,-0.010774031,0.031039242,0.027508985,-0.045565374,0.012481286,-0.052625887,-0.0073305853,-0.018567601,-0.047841713,-0.027335366,0.005806595,0.01605977,-0.03101995,0.013937757,-0.03329629,-0.03269827,-0.037926134,0.0051555233,0.012085821,-0.0024668383,0.022551196,0.026988128,0.00851216,0.02912943,-0.017950289,-0.02720033,-0.0030311006,-0.0034916734,0.016860345,-0.0062695793,0.0026669826,-0.04286463,0.003040746,-0.017236521,0.012587386,-0.05613685,0.029630996,-0.016416652,0.015519621,-0.0005497939,0.033276998,-0.010899423,0.0036484129,-0.027354658,0.013387963,0.015780048,0.003091385,-0.055480957,-0.033759274]
49	56c670d3-5e69-4296-818f-5996fc5fcba8	50cf0ba7-41f3-45b5-88ca-d25bf2fdf69d	初诊，患者诉头晕	怀孕了，要做孕期常规检查，感觉身体乏力	无	未详细说明	神志清	注意休息	短暂性脑缺血发作	t	阿司匹林肠溶片	[0.0021309697,0.015898362,-0.018709067,-0.022099301,-0.041107792,-0.049298443,0.033342127,0.019066442,0.026851423,-0.03085016,-0.03142969,-0.032472838,-0.032878507,0.039716925,0.026155991,0.0041001546,-0.011474637,-0.00795401,-0.040219184,0.01391831,0.007920204,0.018477257,0.029807013,-0.0016057731,-0.046555348,0.006316846,-0.03222171,0.021539092,0.076806664,0.015569963,0.050921116,-0.014420567,-0.0014765868,-0.0427691,0.004269183,-0.058377698,-0.0033057192,-0.0073455065,-0.029382026,0.028435465,0.04311682,0.011300779,0.022949275,0.008108551,0.032588743,-0.022041349,0.0019981612,-0.03206717,-0.019143714,-0.017540354,0.0241856,-0.01217007,0.07325223,-0.0036486061,-0.010489441,-0.005573119,-0.023335626,-0.041223697,-0.008084403,-0.018100563,-0.03434664,0.019578358,0.00015665343,-0.005838736,0.015212587,0.05965266,0.03307168,-0.029130897,-0.016033584,-0.053896025,0.00085118046,-0.005186768,-0.024649221,-0.013947287,-0.028242288,0.039311256,0.036780655,-0.0734454,0.00045969783,0.028725227,0.030251317,0.011146238,-0.007838105,-0.0014681354,-0.012614374,0.009185505,-0.019974368,-0.02043799,-0.028570687,-0.02163568,-0.012112117,0.030483127,-0.065486565,-0.037263595,0.0027286068,0.0010093431,-0.001733752,-0.0027430952,0.027740031,-0.010566711,0.013020043,0.016081877,0.028937722,-0.004438212,-2.6769174e-05,0.00787674,0.0060319114,0.0045661908,0.053548306,0.0050998386,0.0031391054,0.032646693,0.041069157,0.018738044,0.005906347,-0.030135412,-0.02283337,-0.023509484,-0.036085222,-0.04280774,0.02544124,0.027411634,0.012817209,-0.02377993,-0.042189576,0.010209336,0.016497206,0.020862976,-0.006085035,0.030096775,-0.0009284508,-0.020727754,-0.027237775,-0.058570877,-0.01598529,-0.02321972,0.012044505,0.03817152,-0.020322084,-0.016188124,-0.0025740664,0.05679366,0.0006918105,-0.01700912,0.013367759,-0.035911366,0.03229898,0.022717463,0.038403332,-0.018554527,-0.026291214,-2.8014251e-06,0.027855938,0.028280923,0.029459296,0.027488904,0.011648496,-0.03316827,-0.028995674,0.03809425,-0.00270446,-0.016555158,-0.0046096556,-0.018622138,-0.023161767,0.0003087793,0.0044816765,0.018322716,-0.03500344,0.027469587,0.03635567,-0.05161655,0.06282074,-0.016294371,0.020264132,0.019066442,0.05095975,0.012054164,-0.009948549,-0.02745027,-0.0195687,-0.02012891,0.054282375,0.026136674,-0.004392333,0.006495533,-0.0007757212,-0.009489757,0.015415422,0.018641457,0.0004243829,-0.03005814,0.003658265,0.056600485,0.050302956,-0.030502444,0.0051094973,-0.027817301,-0.016545499,0.035621602,0.035409108,0.019694263,0.0019148543,-0.006983302,-0.014372272,-0.0055151666,-0.021133423,-0.058725417,-0.010962722,-0.053471036,0.0209982,0.014797259,-0.010132066,0.027624127,-0.032762602,-0.014024557,-0.032105803,-0.040373724,0.011600201,-0.027585492,-0.037089735,0.014343296,0.030560397,-0.028338877,0.0052398914,0.0026465072,0.0011107604,0.039794195,0.03330349,-0.03753404,-0.020669801,0.032356933,0.013889333,-0.026387801,0.062163945,-0.009325557,0.012025188,0.0136865,0.01694151,0.008321044,0.015705185,-0.0053944318,0.058493607,0.01415978,0.014391591,-0.019356206,0.00027436987,-0.007823616,-0.0062057697,-0.009682933,0.038210157,0.0063989456,-0.02005164,-0.031081973,-0.018322716,0.013329124,0.0058580535,0.0020295524,-0.019616993,0.0060802056,0.00644241,0.027102552,0.029845648,0.038461283,0.012363246,-0.052814238,0.032569423,-0.01742445,0.01607222,0.024745809,0.024707174,-0.03747609,0.0013944872,0.026735518,0.0018762191,0.024359457,-0.0054185786,0.02965247,0.028860452,-0.010566711,-0.038519237,-0.010528076,0.0052060853,0.014642719,0.02839683,-0.024224235,0.016960828,-0.065022945,0.005751807,-0.009122723,-0.0101513835,0.010711594,0.05385739,-0.020090275,0.005592437,0.062163945,0.0483712,-0.17772165,-0.038461283,0.008499731,-0.02401174,-0.010064455,0.022157254,0.011909283,-0.005655219,-0.01718298,-0.013831381,0.05130747,-0.021886809,0.022640193,0.010209336,-0.038866952,0.003093226,0.0037548528,0.0050225686,0.022466335,-0.0048004165,-0.030579714,0.015202928,0.024958301,-0.021017518,-0.06367072,-0.012855844,0.056484576,0.016912533,-0.013831381,-0.0118803065,-0.06676152,0.008311385,-0.01742445,0.010402512,0.03426937,0.04253729,0.0076062935,0.013657522,-0.01893122,0.0027865595,-0.0005273093,0.06726378,-0.025344653,0.050689306,0.0024750638,0.015927337,0.022543605,-0.023026545,-0.018882927,0.026040087,-0.0019776362,-0.01987778,-0.014130803,-0.017192638,-0.034385275,0.0019510747,0.0053654555,0.009721568,-0.0041653514,0.01185133,-0.035679553,-0.099601395,-0.009397998,0.040373724,-0.048293926,-0.021732267,-0.02148114,-0.017318202,-0.015579621,0.000950183,-0.015444398,-0.031217195,0.011938259,-0.014497837,0.022331113,0.0013099728,0.019491429,-0.0002730116,0.007364824,-0.105551206,-0.05146201,0.006553486,-0.025170796,-0.005041886,-0.0008970597,-0.022215206,0.008209968,0.010846816,0.020341402,0.23799248,-0.028242288,-0.04574401,-0.0138796745,0.008137527,-0.029845648,-0.027508222,0.06529339,0.025943497,-0.02687074,-0.044237237,0.020689119,-0.006258893,0.01734718,-0.007403459,0.026677566,-0.020302767,-0.03732155,0.076613486,-0.036123857,0.047328047,-0.028899087,0.025228748,-0.019385183,-0.016555158,-0.023760613,0.01519327,0.04500994,-0.017897729,0.010412171,-0.070740946,-0.023239039,0.040141914,-0.04230548,0.0060898643,0.0008300519,0.0108661335,0.0138024045,-0.046478078,-0.000757611,0.040219184,-0.004749708,-0.008393484,0.023741296,-0.03793971,0.022524288,-0.027373,-0.018651115,0.030908113,-0.029285438,0.008451438,-0.005360626,-0.046787158,-0.012981407,-0.031120608,-0.041455507,-0.04072144,0.026252579,-0.020032322,0.08136561,0.021268645,0.044082697,-0.08569275,0.0018870853,-0.0061188405,0.021732267,-0.07495218,-0.027701396,0.052891508,0.025499193,0.05497781,-0.00667905,-0.02696733,-0.007669076,0.049684793,-0.024668539,-0.01264335,0.038673777,0.022756098,0.017810801,-0.021345915,0.0084562665,-0.054282375,-0.032414883,0.028821817,0.02998087,0.071590915,0.049298443,-0.011522931,0.004160522,-0.036703385,0.010991698,-0.030328587,0.0027092893,-0.03921467,0.0033998925,-0.01987778,-0.060464,0.003634118,0.010701935,-0.06061854,-0.027160505,-0.002856586,5.942417e-05,0.0011403403,0.013174583,-0.021828854,0.011020674,-0.052505158,0.04230548,-0.060502633,-0.011329755,-0.006814273,-0.023490166,-0.023992423,-0.007461412,-0.02107547,0.024649221,0.04844847,0.044816766,-0.015898362,0.0060415706,-0.019307911,0.06846147,0.026233261,-0.00644241,0.023760613,-0.0069736433,0.011561566,0.009552539,0.0024183185,-0.021094788,-0.058802687,-0.02115274,0.04643944,0.018815314,0.00524955,0.018670432,0.042575926,0.08182923,-0.00493081,0.012208705,-0.0038103908,0.034887534,0.00059250614,0.0057469774,0.009113064,-0.017366497,0.0009942512,-0.011464979,0.0256151,0.03150696,0.04334863,-0.0448554,-0.011078627,-0.05752773,-0.020341402,-0.04462359,-0.014768283,-0.033593256,-0.00021279512,-0.0070412545,0.06262757,0.054861903,0.02696733,0.05049613,0.028010478,-0.03942716,0.010141725,0.0044720178,-0.005577949,0.001765143,-0.061043523,-0.047212142,0.0045203115,-0.00429333,-0.013705817,0.029729743,-0.0025426752,-0.00038514409,0.004643461,0.031603545,0.035872728,0.059382215,0.015241563,0.014150121,-0.015280198,-0.011271803,0.00715716,-0.04253729,0.01463306,0.11567362,0.001928135,-0.0052930145,0.027971843,0.01710571,0.03865446,0.025499193,-0.006664562,0.0010256423,0.0069301785,-0.01599495,-0.005152962,0.03164218,0.041494142,-0.005066033,-0.020399354,0.013377418,0.027334362,0.02696733,-0.0017108124,-0.012324611,-0.001837584,-0.009175846,-0.05679366,-0.023876518,-0.00707989,-9.3569484e-05,-0.012131435,-0.020553896,-0.017588649,-0.031796724,0.030656986,-0.018313058,0.0016757993,0.04875755,-0.019336889,-0.025421923,0.023470849,0.053702846,-0.010450806,-0.008258262,-0.029285438,-0.03015473,-0.011426344,-0.0534324,0.03442391,0.00025369404,-0.008422461,-0.038364697,-0.024533315,-0.030096775,-0.01367684,0.029807013,-0.005877371,0.036471575,-0.008562514,-0.013000726,0.04748259,0.0462849,0.00314152,0.023296991,-0.0009894219,-0.056986835,-0.008465925,0.03699315,-0.023451531,0.007046084,-0.009127553,-0.011542249,-0.023296991,0.057373185,0.03413415,0.019993685,-0.03347735,-0.11860988,-0.0050080805,0.019443136,-0.0068529085,-0.029053627,-0.008678419,0.01415978,-0.0011270596,0.026426436,-0.0049597863,-0.02283337,-0.010470124,0.041532777,0.037167005,-0.019665288,0.00437543,0.0020295524,0.009451122,0.03666475,0.032434203,-0.036297716,0.04087598,0.03919535,-0.023200402,0.016970485,-0.016815946,0.0068046143,-0.016033584,0.05146201,-0.00094475,0.02005164,0.0056262426,0.04280774,-0.034095515,0.009035794,-0.046555348,-7.81758e-05,-0.011300779,0.010672958,-0.0032622549,0.0241856,0.017781824,-0.00023075442,-0.021345915,0.029729743,-0.023316309,-0.08515185,0.005510337,-0.00477144,0.006152646,-0.010518418,0.0033057192,-0.03092743,0.01463306,0.053471036,0.0076497584,-0.026909376,-0.025576465,-0.0035737506,-0.05065067,-0.041841857,0.0044116504,0.010132066,-0.006592121,-0.03046381,-0.04620763,0.025151478,-0.023509484,-0.03500344,0.0038538554,-0.0030087116,-0.0068673966,-0.0039456137,0.04246002,-0.05115293,-0.010373536,-0.02712187,0.06691606,-0.03515798,-0.02712187,0.049762063,-0.015087023,0.032279663,0.025634417,-0.006727344,-0.007867081,0.050225686,-0.031043336,-0.017540354,0.014043874,0.06529339,-0.018873267,0.025788957,0.058184523,-0.016429594,-0.012401881,0.032839872,0.01002582,-0.012768915,0.02314245,0.030000187,0.01734718,0.057218645,0.03967829,0.013145607,0.0010322827,-0.027875256,-0.026445754,-0.054514185,0.009528392,0.040605534,-0.011590542,-0.0031849844,0.002341048,-0.010721252,0.009238629,0.01534781,0.029864965,-0.018651115,0.04875755,-0.02449468,-0.044275872,0.002450917,0.017472742,0.011223509,0.012904137,0.0049501276,-0.022022031,-0.00676115,-0.14364547,-0.026445754,-0.019819828,-0.027527539,-0.017694894,-0.0010914428,-0.0031753257,-0.008263091,-0.02036072,-0.029710425,-0.009055112,-0.008011962,-0.022157254,-0.020476626,-0.00074251916,0.022234524,0.00027587905,0.010257631,0.009397998,0.035756823,-0.0138796745,0.016960828,0.016555158,0.025402606,-0.01718298,-0.015289857,-0.0050563742,0.004476847,-0.040953252,0.02449468,-0.02822297,-0.038461283,0.016323347,0.058957227,0.034790944,-0.0104991,0.01726991,-0.036374986,0.02712187,0.00930624,-0.019172689,0.05575051,0.017598307,0.0133581,-0.04898936,-0.0017844606,0.031159243,0.0022951688,0.019761875,-0.009243458,-0.025460558,0.018042611,-0.0419964,-0.03714769,-0.0061188405,-0.035215933,-0.033593256,-0.03699315,0.028165018,0.0017639357,0.0020138568,-0.02712187,-0.035756823,-0.06815239,-0.011175215,0.0018061929,-0.04087598,0.03191263,-0.009494586,0.002056114,-0.05161655,-0.016400618,0.011252485,-0.038441967,-0.017482402,0.008552855,0.07468173,-0.04825529,-0.05868678,-0.007229601,-0.054668725,0.009282093,0.026426436,-0.022466335,0.00029293285,0.007949181,0.042575926,0.026059404,-0.0024110742,0.0072247717,-0.08677453,-0.003745194,0.032279663,-0.009016477,0.0017422035,-0.022678828,-0.00803128,-0.0108274985,-0.025731005,-0.04574401,0.018313058,-0.03921467,0.026503708,-0.034578454,-0.052080173,-0.0041508633,-0.027237775,0.023277674,0.014381932,0.012942772,0.011667813,-0.02306518,-0.04597582,0.04311682,-0.011078627,0.019974368,0.022852687,0.019597676,-0.049839333,0.009644297,-0.03697383,-0.052852873,-0.03450118,-0.025383288,0.00540892,-0.051346105,0.055248253,0.010730911,-0.01542508,0.027083235,0.026291214,-0.06336163,0.003882832,0.049182534,0.050612036,0.041494142,-0.0241856,0.0044164797,-0.021094788,0.015116,0.034868214,-0.030811526,-0.016275054,-0.031275146,-0.029439978,-0.02138455,0.020669801,-0.0042885006,0.0035375303,-0.007886399,0.019674946,-0.031526275,-0.037360184,0.08677453,-0.01630403,-0.028976357,-0.0015285028,0.00763527,-0.01129112,0.023084497,-0.009378681,-0.058648147,-0.045705374,-0.021751584,-0.009967866,0.06467523,-0.003356428,-0.0093593635,-0.043387264,0.0036727532,-0.008953694,0.051191565,-0.035563648,0.022447018,0.02265951,0.042421386,-0.026310531,-0.026194626,0.07244089,0.015550645,0.05072794,0.01837101,-0.0068818848,0.04620763,-0.011513272,0.008132697,0.022794735,0.024282187,0.03538979,-0.025402606,0.021597045,-0.015859725,0.03500344,0.008900571,0.019916415,0.003069079,0.011571225,0.021519775,-0.009238629,0.035544332,-0.0019583188,-0.019414159,0.014391591,-0.06262757,-0.03411483,0.008147186,0.014536472,-0.026774153,0.0033757456,-0.017588649,0.0018955367,-0.026735518,0.0012797891,-0.0059594708,-0.019027807,-0.041223697,0.038519237,-0.014623402,0.028261606,0.014536472,0.00094957935,-0.006012594,-0.008939206,-0.014381932,-0.0119962115,0.052157443,-0.03515798,0.01852555,-0.009079258,0.047907576,-0.022215206,0.017327862,-0.006331334,-0.005162621,0.028493417,0.0057759536,-0.047907576,0.023316309,-0.031796724,0.027025282,0.00022471769,-0.004725561,-0.027102552,-0.04620763]
50	61507c3c-55e3-4b2e-ac21-3923c8850daa	5ed3c049-4490-43a6-8b12-3fd64eb6163d	初诊，患者诉头晕	怀孕了，要做孕期常规检查，感觉身体乏力	无	未详细说明	神志清	注意休息	短暂性脑缺血发作	t	阿司匹林肠溶片	[0.0021309697,0.015898362,-0.018709067,-0.022099301,-0.041107792,-0.049298443,0.033342127,0.019066442,0.026851423,-0.03085016,-0.03142969,-0.032472838,-0.032878507,0.039716925,0.026155991,0.0041001546,-0.011474637,-0.00795401,-0.040219184,0.01391831,0.007920204,0.018477257,0.029807013,-0.0016057731,-0.046555348,0.006316846,-0.03222171,0.021539092,0.076806664,0.015569963,0.050921116,-0.014420567,-0.0014765868,-0.0427691,0.004269183,-0.058377698,-0.0033057192,-0.0073455065,-0.029382026,0.028435465,0.04311682,0.011300779,0.022949275,0.008108551,0.032588743,-0.022041349,0.0019981612,-0.03206717,-0.019143714,-0.017540354,0.0241856,-0.01217007,0.07325223,-0.0036486061,-0.010489441,-0.005573119,-0.023335626,-0.041223697,-0.008084403,-0.018100563,-0.03434664,0.019578358,0.00015665343,-0.005838736,0.015212587,0.05965266,0.03307168,-0.029130897,-0.016033584,-0.053896025,0.00085118046,-0.005186768,-0.024649221,-0.013947287,-0.028242288,0.039311256,0.036780655,-0.0734454,0.00045969783,0.028725227,0.030251317,0.011146238,-0.007838105,-0.0014681354,-0.012614374,0.009185505,-0.019974368,-0.02043799,-0.028570687,-0.02163568,-0.012112117,0.030483127,-0.065486565,-0.037263595,0.0027286068,0.0010093431,-0.001733752,-0.0027430952,0.027740031,-0.010566711,0.013020043,0.016081877,0.028937722,-0.004438212,-2.6769174e-05,0.00787674,0.0060319114,0.0045661908,0.053548306,0.0050998386,0.0031391054,0.032646693,0.041069157,0.018738044,0.005906347,-0.030135412,-0.02283337,-0.023509484,-0.036085222,-0.04280774,0.02544124,0.027411634,0.012817209,-0.02377993,-0.042189576,0.010209336,0.016497206,0.020862976,-0.006085035,0.030096775,-0.0009284508,-0.020727754,-0.027237775,-0.058570877,-0.01598529,-0.02321972,0.012044505,0.03817152,-0.020322084,-0.016188124,-0.0025740664,0.05679366,0.0006918105,-0.01700912,0.013367759,-0.035911366,0.03229898,0.022717463,0.038403332,-0.018554527,-0.026291214,-2.8014251e-06,0.027855938,0.028280923,0.029459296,0.027488904,0.011648496,-0.03316827,-0.028995674,0.03809425,-0.00270446,-0.016555158,-0.0046096556,-0.018622138,-0.023161767,0.0003087793,0.0044816765,0.018322716,-0.03500344,0.027469587,0.03635567,-0.05161655,0.06282074,-0.016294371,0.020264132,0.019066442,0.05095975,0.012054164,-0.009948549,-0.02745027,-0.0195687,-0.02012891,0.054282375,0.026136674,-0.004392333,0.006495533,-0.0007757212,-0.009489757,0.015415422,0.018641457,0.0004243829,-0.03005814,0.003658265,0.056600485,0.050302956,-0.030502444,0.0051094973,-0.027817301,-0.016545499,0.035621602,0.035409108,0.019694263,0.0019148543,-0.006983302,-0.014372272,-0.0055151666,-0.021133423,-0.058725417,-0.010962722,-0.053471036,0.0209982,0.014797259,-0.010132066,0.027624127,-0.032762602,-0.014024557,-0.032105803,-0.040373724,0.011600201,-0.027585492,-0.037089735,0.014343296,0.030560397,-0.028338877,0.0052398914,0.0026465072,0.0011107604,0.039794195,0.03330349,-0.03753404,-0.020669801,0.032356933,0.013889333,-0.026387801,0.062163945,-0.009325557,0.012025188,0.0136865,0.01694151,0.008321044,0.015705185,-0.0053944318,0.058493607,0.01415978,0.014391591,-0.019356206,0.00027436987,-0.007823616,-0.0062057697,-0.009682933,0.038210157,0.0063989456,-0.02005164,-0.031081973,-0.018322716,0.013329124,0.0058580535,0.0020295524,-0.019616993,0.0060802056,0.00644241,0.027102552,0.029845648,0.038461283,0.012363246,-0.052814238,0.032569423,-0.01742445,0.01607222,0.024745809,0.024707174,-0.03747609,0.0013944872,0.026735518,0.0018762191,0.024359457,-0.0054185786,0.02965247,0.028860452,-0.010566711,-0.038519237,-0.010528076,0.0052060853,0.014642719,0.02839683,-0.024224235,0.016960828,-0.065022945,0.005751807,-0.009122723,-0.0101513835,0.010711594,0.05385739,-0.020090275,0.005592437,0.062163945,0.0483712,-0.17772165,-0.038461283,0.008499731,-0.02401174,-0.010064455,0.022157254,0.011909283,-0.005655219,-0.01718298,-0.013831381,0.05130747,-0.021886809,0.022640193,0.010209336,-0.038866952,0.003093226,0.0037548528,0.0050225686,0.022466335,-0.0048004165,-0.030579714,0.015202928,0.024958301,-0.021017518,-0.06367072,-0.012855844,0.056484576,0.016912533,-0.013831381,-0.0118803065,-0.06676152,0.008311385,-0.01742445,0.010402512,0.03426937,0.04253729,0.0076062935,0.013657522,-0.01893122,0.0027865595,-0.0005273093,0.06726378,-0.025344653,0.050689306,0.0024750638,0.015927337,0.022543605,-0.023026545,-0.018882927,0.026040087,-0.0019776362,-0.01987778,-0.014130803,-0.017192638,-0.034385275,0.0019510747,0.0053654555,0.009721568,-0.0041653514,0.01185133,-0.035679553,-0.099601395,-0.009397998,0.040373724,-0.048293926,-0.021732267,-0.02148114,-0.017318202,-0.015579621,0.000950183,-0.015444398,-0.031217195,0.011938259,-0.014497837,0.022331113,0.0013099728,0.019491429,-0.0002730116,0.007364824,-0.105551206,-0.05146201,0.006553486,-0.025170796,-0.005041886,-0.0008970597,-0.022215206,0.008209968,0.010846816,0.020341402,0.23799248,-0.028242288,-0.04574401,-0.0138796745,0.008137527,-0.029845648,-0.027508222,0.06529339,0.025943497,-0.02687074,-0.044237237,0.020689119,-0.006258893,0.01734718,-0.007403459,0.026677566,-0.020302767,-0.03732155,0.076613486,-0.036123857,0.047328047,-0.028899087,0.025228748,-0.019385183,-0.016555158,-0.023760613,0.01519327,0.04500994,-0.017897729,0.010412171,-0.070740946,-0.023239039,0.040141914,-0.04230548,0.0060898643,0.0008300519,0.0108661335,0.0138024045,-0.046478078,-0.000757611,0.040219184,-0.004749708,-0.008393484,0.023741296,-0.03793971,0.022524288,-0.027373,-0.018651115,0.030908113,-0.029285438,0.008451438,-0.005360626,-0.046787158,-0.012981407,-0.031120608,-0.041455507,-0.04072144,0.026252579,-0.020032322,0.08136561,0.021268645,0.044082697,-0.08569275,0.0018870853,-0.0061188405,0.021732267,-0.07495218,-0.027701396,0.052891508,0.025499193,0.05497781,-0.00667905,-0.02696733,-0.007669076,0.049684793,-0.024668539,-0.01264335,0.038673777,0.022756098,0.017810801,-0.021345915,0.0084562665,-0.054282375,-0.032414883,0.028821817,0.02998087,0.071590915,0.049298443,-0.011522931,0.004160522,-0.036703385,0.010991698,-0.030328587,0.0027092893,-0.03921467,0.0033998925,-0.01987778,-0.060464,0.003634118,0.010701935,-0.06061854,-0.027160505,-0.002856586,5.942417e-05,0.0011403403,0.013174583,-0.021828854,0.011020674,-0.052505158,0.04230548,-0.060502633,-0.011329755,-0.006814273,-0.023490166,-0.023992423,-0.007461412,-0.02107547,0.024649221,0.04844847,0.044816766,-0.015898362,0.0060415706,-0.019307911,0.06846147,0.026233261,-0.00644241,0.023760613,-0.0069736433,0.011561566,0.009552539,0.0024183185,-0.021094788,-0.058802687,-0.02115274,0.04643944,0.018815314,0.00524955,0.018670432,0.042575926,0.08182923,-0.00493081,0.012208705,-0.0038103908,0.034887534,0.00059250614,0.0057469774,0.009113064,-0.017366497,0.0009942512,-0.011464979,0.0256151,0.03150696,0.04334863,-0.0448554,-0.011078627,-0.05752773,-0.020341402,-0.04462359,-0.014768283,-0.033593256,-0.00021279512,-0.0070412545,0.06262757,0.054861903,0.02696733,0.05049613,0.028010478,-0.03942716,0.010141725,0.0044720178,-0.005577949,0.001765143,-0.061043523,-0.047212142,0.0045203115,-0.00429333,-0.013705817,0.029729743,-0.0025426752,-0.00038514409,0.004643461,0.031603545,0.035872728,0.059382215,0.015241563,0.014150121,-0.015280198,-0.011271803,0.00715716,-0.04253729,0.01463306,0.11567362,0.001928135,-0.0052930145,0.027971843,0.01710571,0.03865446,0.025499193,-0.006664562,0.0010256423,0.0069301785,-0.01599495,-0.005152962,0.03164218,0.041494142,-0.005066033,-0.020399354,0.013377418,0.027334362,0.02696733,-0.0017108124,-0.012324611,-0.001837584,-0.009175846,-0.05679366,-0.023876518,-0.00707989,-9.3569484e-05,-0.012131435,-0.020553896,-0.017588649,-0.031796724,0.030656986,-0.018313058,0.0016757993,0.04875755,-0.019336889,-0.025421923,0.023470849,0.053702846,-0.010450806,-0.008258262,-0.029285438,-0.03015473,-0.011426344,-0.0534324,0.03442391,0.00025369404,-0.008422461,-0.038364697,-0.024533315,-0.030096775,-0.01367684,0.029807013,-0.005877371,0.036471575,-0.008562514,-0.013000726,0.04748259,0.0462849,0.00314152,0.023296991,-0.0009894219,-0.056986835,-0.008465925,0.03699315,-0.023451531,0.007046084,-0.009127553,-0.011542249,-0.023296991,0.057373185,0.03413415,0.019993685,-0.03347735,-0.11860988,-0.0050080805,0.019443136,-0.0068529085,-0.029053627,-0.008678419,0.01415978,-0.0011270596,0.026426436,-0.0049597863,-0.02283337,-0.010470124,0.041532777,0.037167005,-0.019665288,0.00437543,0.0020295524,0.009451122,0.03666475,0.032434203,-0.036297716,0.04087598,0.03919535,-0.023200402,0.016970485,-0.016815946,0.0068046143,-0.016033584,0.05146201,-0.00094475,0.02005164,0.0056262426,0.04280774,-0.034095515,0.009035794,-0.046555348,-7.81758e-05,-0.011300779,0.010672958,-0.0032622549,0.0241856,0.017781824,-0.00023075442,-0.021345915,0.029729743,-0.023316309,-0.08515185,0.005510337,-0.00477144,0.006152646,-0.010518418,0.0033057192,-0.03092743,0.01463306,0.053471036,0.0076497584,-0.026909376,-0.025576465,-0.0035737506,-0.05065067,-0.041841857,0.0044116504,0.010132066,-0.006592121,-0.03046381,-0.04620763,0.025151478,-0.023509484,-0.03500344,0.0038538554,-0.0030087116,-0.0068673966,-0.0039456137,0.04246002,-0.05115293,-0.010373536,-0.02712187,0.06691606,-0.03515798,-0.02712187,0.049762063,-0.015087023,0.032279663,0.025634417,-0.006727344,-0.007867081,0.050225686,-0.031043336,-0.017540354,0.014043874,0.06529339,-0.018873267,0.025788957,0.058184523,-0.016429594,-0.012401881,0.032839872,0.01002582,-0.012768915,0.02314245,0.030000187,0.01734718,0.057218645,0.03967829,0.013145607,0.0010322827,-0.027875256,-0.026445754,-0.054514185,0.009528392,0.040605534,-0.011590542,-0.0031849844,0.002341048,-0.010721252,0.009238629,0.01534781,0.029864965,-0.018651115,0.04875755,-0.02449468,-0.044275872,0.002450917,0.017472742,0.011223509,0.012904137,0.0049501276,-0.022022031,-0.00676115,-0.14364547,-0.026445754,-0.019819828,-0.027527539,-0.017694894,-0.0010914428,-0.0031753257,-0.008263091,-0.02036072,-0.029710425,-0.009055112,-0.008011962,-0.022157254,-0.020476626,-0.00074251916,0.022234524,0.00027587905,0.010257631,0.009397998,0.035756823,-0.0138796745,0.016960828,0.016555158,0.025402606,-0.01718298,-0.015289857,-0.0050563742,0.004476847,-0.040953252,0.02449468,-0.02822297,-0.038461283,0.016323347,0.058957227,0.034790944,-0.0104991,0.01726991,-0.036374986,0.02712187,0.00930624,-0.019172689,0.05575051,0.017598307,0.0133581,-0.04898936,-0.0017844606,0.031159243,0.0022951688,0.019761875,-0.009243458,-0.025460558,0.018042611,-0.0419964,-0.03714769,-0.0061188405,-0.035215933,-0.033593256,-0.03699315,0.028165018,0.0017639357,0.0020138568,-0.02712187,-0.035756823,-0.06815239,-0.011175215,0.0018061929,-0.04087598,0.03191263,-0.009494586,0.002056114,-0.05161655,-0.016400618,0.011252485,-0.038441967,-0.017482402,0.008552855,0.07468173,-0.04825529,-0.05868678,-0.007229601,-0.054668725,0.009282093,0.026426436,-0.022466335,0.00029293285,0.007949181,0.042575926,0.026059404,-0.0024110742,0.0072247717,-0.08677453,-0.003745194,0.032279663,-0.009016477,0.0017422035,-0.022678828,-0.00803128,-0.0108274985,-0.025731005,-0.04574401,0.018313058,-0.03921467,0.026503708,-0.034578454,-0.052080173,-0.0041508633,-0.027237775,0.023277674,0.014381932,0.012942772,0.011667813,-0.02306518,-0.04597582,0.04311682,-0.011078627,0.019974368,0.022852687,0.019597676,-0.049839333,0.009644297,-0.03697383,-0.052852873,-0.03450118,-0.025383288,0.00540892,-0.051346105,0.055248253,0.010730911,-0.01542508,0.027083235,0.026291214,-0.06336163,0.003882832,0.049182534,0.050612036,0.041494142,-0.0241856,0.0044164797,-0.021094788,0.015116,0.034868214,-0.030811526,-0.016275054,-0.031275146,-0.029439978,-0.02138455,0.020669801,-0.0042885006,0.0035375303,-0.007886399,0.019674946,-0.031526275,-0.037360184,0.08677453,-0.01630403,-0.028976357,-0.0015285028,0.00763527,-0.01129112,0.023084497,-0.009378681,-0.058648147,-0.045705374,-0.021751584,-0.009967866,0.06467523,-0.003356428,-0.0093593635,-0.043387264,0.0036727532,-0.008953694,0.051191565,-0.035563648,0.022447018,0.02265951,0.042421386,-0.026310531,-0.026194626,0.07244089,0.015550645,0.05072794,0.01837101,-0.0068818848,0.04620763,-0.011513272,0.008132697,0.022794735,0.024282187,0.03538979,-0.025402606,0.021597045,-0.015859725,0.03500344,0.008900571,0.019916415,0.003069079,0.011571225,0.021519775,-0.009238629,0.035544332,-0.0019583188,-0.019414159,0.014391591,-0.06262757,-0.03411483,0.008147186,0.014536472,-0.026774153,0.0033757456,-0.017588649,0.0018955367,-0.026735518,0.0012797891,-0.0059594708,-0.019027807,-0.041223697,0.038519237,-0.014623402,0.028261606,0.014536472,0.00094957935,-0.006012594,-0.008939206,-0.014381932,-0.0119962115,0.052157443,-0.03515798,0.01852555,-0.009079258,0.047907576,-0.022215206,0.017327862,-0.006331334,-0.005162621,0.028493417,0.0057759536,-0.047907576,0.023316309,-0.031796724,0.027025282,0.00022471769,-0.004725561,-0.027102552,-0.04620763]
51	f4ddc3c9-324e-42e0-b768-df31748a255a	160604cf-f9ea-45e4-be24-f7be46614801	主诉：孕期常规检查，身体乏力	现病史：患者自述怀孕，感觉身体乏力，未提及具体持续时间及其他症状	未详细说明	未详细说明	\N	待医生问诊后补充	\N	f	待医生问诊后确定	[0.013175762,0.014352514,-0.05077395,-0.029804617,-0.023110634,-0.060998186,0.01762234,0.013243281,0.016127288,-0.026177905,-0.017853834,-0.015683595,-0.046298433,0.04394493,0.0090716,-0.008020239,0.0026211664,-0.017535532,-0.029920362,0.022879142,-0.0054063066,0.013040725,0.023284255,-0.015162737,-0.0356305,0.024171641,-0.027142456,-0.00062936934,0.07581368,0.001888108,0.023342127,-0.023747237,0.023052761,-0.04054971,0.0015686005,-0.03848557,0.006732564,-0.021085078,-0.029225886,0.046221267,0.018220363,-0.017699504,0.021779554,-0.018008161,0.017593404,-0.036923,-0.021798845,-0.01131418,-0.0034000413,-0.016146578,0.028820775,-0.034936026,0.022416158,-0.021721682,0.019628607,0.020757131,-0.002963582,-0.04247881,-0.038890682,-0.021065786,-0.020525638,0.0001133347,0.019088458,-0.022281121,-0.00084277615,0.062271394,0.03329629,-0.018345755,-0.029881781,-0.053320363,-0.00088497525,0.0063612117,-0.021605935,0.0010881338,-0.049153503,0.03269827,-0.0014383863,-0.040086728,0.011564963,0.018123908,0.026177905,0.039855234,0.022377577,0.011478153,-0.017998517,-0.0024210222,-0.02741253,-0.005907873,-0.047725968,-0.03844699,-0.016416652,0.043867767,-0.046337016,-0.011564963,-0.03862061,-0.0011435954,-0.023072053,-0.034299422,0.025348391,-0.009399546,0.022281121,-0.016889283,0.012674196,-0.0032336563,-0.00018642956,-0.0016566158,0.001168312,-0.012114757,0.030229019,-0.014497197,0.022416158,-0.004193384,0.042324483,0.009129472,0.009544229,-0.0167446,-0.026100742,-0.014014921,-0.00020632343,-0.031039242,0.0468,0.022551196,0.002893652,-0.021162242,-0.035842706,0.031232152,0.042710304,0.024248805,-0.027528277,0.028087717,0.00571014,-0.025425557,-0.05389909,-0.033566363,0.004429699,-0.05104402,0.03555334,0.01760305,-0.034338005,0.008787056,-0.043134708,0.07353734,0.0005922944,-0.02475037,-0.008951031,-0.05208574,0.04147568,-0.0013214344,0.03676867,0.025541302,-0.0521629,0.0020749897,-0.00034753967,0.03372069,0.01103446,0.03802259,0.012423413,0.017834542,-0.04645276,0.034010056,0.07249563,-0.0067373863,-0.04259456,-0.0041258656,-0.030364055,-0.0017000206,0.00126115,0.0038799052,-0.020236274,0.057602968,0.041938663,-0.052240066,0.024133058,-0.032254577,0.016599918,0.019368177,0.077588454,0.029611707,-0.0049047405,-0.036247816,-0.017525885,0.033431325,0.031675845,-0.040781204,-0.007803215,-0.0054448885,-0.004241612,-0.0201784,1.0757001e-05,0.011391344,0.003211954,-0.03595845,0.0021521538,0.022589777,0.07037362,0.003424155,0.012973207,-0.012886398,0.010320692,-0.00013036505,0.07064369,0.032215994,0.020602804,-0.024981864,-0.018393982,0.00023149216,-0.035611212,-0.07411607,0.008719538,-0.040704038,0.030306183,0.03578483,0.006423908,0.0076392414,-0.028608574,0.012114757,-0.022184666,-0.07376884,-0.019262077,0.0057487222,-0.022744106,0.008328895,0.034878153,-0.06068953,-0.017757379,0.044793732,-0.0045864386,0.0364986,0.001972506,-0.030904204,-0.008362655,0.050465293,0.0044200537,-0.0006757883,0.07596801,0.0027007419,-0.004608141,-0.0009832388,0.0010230265,0.010426793,-0.0026452802,-0.029148722,0.029071558,0.024943281,0.0023245672,-0.040858366,0.013397609,0.040858366,-0.016638499,0.002483718,0.039855234,0.006939942,-0.018220363,-0.0076247733,0.00024038412,0.008946207,-0.003945012,-0.01217263,-0.003699052,0.0029732275,-0.02889794,0.025657048,0.014005276,0.033064798,0.00046780708,-0.044948064,-0.0321967,-0.012375185,0.0031613149,0.037848968,-0.0023583265,0.0060670236,0.0352061,0.024268094,0.0029081204,-0.0007342642,-0.0055606347,0.0040342333,0.03364353,-0.027894806,-0.027026711,0.016204452,-0.0033952184,-0.011690354,-0.00050819764,0.00338075,0.0457197,-0.0382155,-0.0048106965,-0.04811179,-0.009110182,-0.009992745,0.05231723,0.012828524,0.02451888,0.02664089,0.03840841,-0.17577972,-0.0044538127,-0.008695425,-0.009303091,-0.02756686,0.013841302,-0.012664551,-0.0034603255,-0.049192086,-0.021991756,0.024113767,-0.034936026,0.03140577,0.02741253,-0.027894806,0.011912201,-0.030190436,-0.016310552,-0.0134169,-0.02056422,-0.035611212,-0.010513603,0.055249464,0.016648145,-0.05594394,0.004231966,0.036324978,-0.017738087,-0.01360981,-0.020660676,-0.0302676,0.034936026,-0.019696126,0.01762234,0.02436455,0.031058533,0.030132564,0.017747732,-0.022474032,0.023998022,-0.009471888,0.048227534,-0.01380272,0.03748244,0.0074704452,-0.02552201,0.013966694,-0.024268094,-0.015828276,-0.015963314,0.022377577,-0.024615334,0.002278751,-0.020872876,-0.048266117,0.0034338005,-0.006771146,0.0102435285,0.030113272,0.031039242,-0.029727452,-0.09784402,-0.001253916,0.036132067,-0.031945918,-0.031540807,-0.05440066,0.0063226297,-0.00598986,0.011304534,0.0098962905,0.024480296,0.016368425,-0.015963314,0.024576752,0.021760264,-0.032447483,-0.017178647,0.0006317807,-0.11628623,-0.05096686,0.0038268548,-0.017574113,0.01541352,-0.005039777,-0.018963067,0.010272465,0.034473043,0.0086279055,0.24831393,-0.0027320897,-0.044253584,-0.010185655,0.026293652,-0.023207089,-0.02037131,0.05798879,0.050889693,-0.04375202,-0.044639405,0.0127127785,0.012191921,-0.026139325,0.0014130668,0.025059028,-0.035649795,-0.02419093,0.07218698,-0.013387963,0.0457197,-0.02149019,0.0048034624,-0.019889034,-0.0007939458,-0.044022094,0.009158409,0.03809975,-0.004552679,0.009500824,-0.041977245,0.01066793,0.05482506,-0.014284995,-0.0124716405,0.028377082,0.030325474,0.04205441,-0.014535779,0.029746743,0.034338005,-0.016281616,-0.0116035445,0.0065300083,-0.009553875,0.005575103,-0.013523,0.00037647618,0.0367108,-0.028492827,0.016532399,-0.007099093,-0.05189283,-0.010214591,-0.015895795,-0.012896042,-0.046529926,-0.0071424977,-0.020969331,0.0729972,0.04166859,0.037578896,-0.08418599,-0.01197972,0.032486066,0.033952184,-0.09089926,0.0033301113,0.012982853,0.008979967,0.049192086,-0.009095713,-0.020892167,-0.029920362,0.02966958,-0.024171641,-0.005531698,0.0015251958,0.024615334,0.034550205,-0.01122737,0.017641632,-0.040048145,-0.015596785,0.03171443,0.0055268756,0.04514097,0.014159604,-0.005025309,0.014564715,-0.01285746,0.008594147,-0.031444352,-0.013117889,-0.018702637,-0.02756686,-0.01161319,-0.044060677,-0.02779835,0.0049819043,-0.018316818,-0.040588293,0.007943075,0.0015698062,-0.042555977,0.025927123,-0.009626216,-0.0048155193,-0.013175762,0.016696373,-0.047648802,0.012355895,-0.008275845,-0.0017048434,-0.02986249,-0.024596043,-0.024673207,0.039893817,0.041977245,0.037231658,-0.04375202,0.036112778,-0.031502225,0.075080626,-0.025637757,-0.013281863,0.007996125,0.0043115416,0.013523,0.044292167,-0.008767766,-0.015963314,-0.08171673,-0.0056426213,0.04220874,0.018094972,0.021625226,0.014207832,0.014294641,0.07210981,-0.02567634,0.0026525145,-0.013156472,0.053706184,-0.014188541,0.0108704865,0.008970321,-0.02548343,-0.012375185,-0.0031154987,0.038543444,0.024596043,0.050195217,-0.062078483,0.0024403133,-0.034318715,-0.016706018,-0.059609234,-0.03250536,-0.036228523,0.0010338777,-0.021181533,0.02451888,0.08665524,0.030730585,0.018664056,0.010339984,-0.017053256,0.027084583,-0.024325969,-0.00011084798,-0.016898928,-0.07195548,-0.084263146,0.019464632,0.016792828,-0.010735449,-0.0057053175,-0.0068965373,0.016947156,0.0251169,0.03536043,0.053050287,0.05196999,0.0058644684,-0.0098962905,-0.024808243,-0.01189291,-0.0074656224,-0.041784335,0.040819786,0.08572926,0.014429678,0.009196991,0.06296587,0.06871459,0.04452366,-0.0060477327,-0.018027453,-0.018500082,0.021200825,0.013127535,-0.0052760923,0.013580874,0.02756686,-0.010359274,-0.044485077,0.046529926,0.0026959192,-0.0031516694,-0.019262077,-0.007875556,0.030209728,-0.0020822238,-0.029013684,-0.009544229,-0.0013467539,0.008820816,-0.00071437034,-0.0058885817,0.023245672,-0.0033445796,0.040626876,-0.01236554,-0.0031806058,0.044948064,-0.031540807,0.0043308325,0.04888343,0.03883281,-0.0036001855,0.013725556,-0.05042671,-0.037463147,0.00937061,-0.050118055,0.008734006,0.03119357,-0.037135202,-0.019194558,-0.029264469,-0.049346413,-0.01768986,-0.007668178,0.022512613,0.021181533,-0.015249547,-0.0020520815,0.03539901,0.051275514,0.025136191,0.017805606,0.0022486087,-0.052973125,-0.0017651278,0.036189944,-0.038138334,-0.017506596,0.0071569663,0.039893817,-0.014053504,0.046761416,0.029264469,0.02436455,-0.022879142,-0.08380017,-0.002108749,0.033971474,-0.008555565,-0.057294313,-0.033373453,-0.0126452595,-0.0012026741,0.0030431575,0.012269084,-0.01236554,-0.012336603,0.04791888,0.019696126,-0.023920856,0.025386974,0.019223494,0.013773784,0.017178647,-0.005358079,-0.034608077,0.042363066,0.021818137,-0.023843693,0.009741962,-0.0053098514,0.0032529472,-0.011150206,0.037135202,-0.011381698,0.029785326,0.014873371,0.0070074606,-0.030981367,0.025078317,-0.03578483,0.037848968,-0.018210717,0.035534047,0.002905709,0.038524155,0.020911459,0.012635614,0.039122175,0.027065292,0.010725804,-0.06802011,-0.00851216,-0.0050590686,0.018789448,-0.0002525917,0.009573165,0.004870981,0.009052308,0.03422226,-0.012230502,-0.032466777,-0.041552845,-0.023650782,-0.0016674671,-0.031154986,-0.00028333676,0.021914592,-0.039855234,-0.03651789,-0.035669085,0.042363066,-0.02284056,-0.022281121,0.0060380874,-0.03578483,0.02739324,-0.019030586,0.029476669,0.004897506,0.0022184665,0.008492868,0.057757296,-0.035649795,-0.010532893,-0.0068579554,0.016368425,0.03119357,0.014815498,0.022107502,-0.0090281945,0.013822012,-0.014342869,-0.015972959,0.0040607583,0.033006925,0.0056233304,0.003142024,0.06300445,-0.03140577,-0.01562572,0.011835037,-0.007398104,-0.013725556,0.027894806,0.012191921,0.007943075,0.039855234,0.016484171,0.0020689613,0.0024017312,0.010446084,-0.0020834296,-0.035842706,0.001427535,0.04853619,-0.04054971,0.0059753917,-0.004096929,-0.0011990571,0.0100023905,-0.03543759,0.0011261129,-0.008237263,0.026853092,0.035842706,-0.009008903,0.0008035913,0.04398351,0.014130668,0.0065444764,-0.020081945,-0.029052267,-0.0039667147,-0.15579423,0.0010121753,-0.025251936,-0.049384996,-0.030846331,-0.005806595,0.00359054,-0.014776916,-0.024248805,-0.031810883,0.0052857376,-0.00053261284,-0.025039736,-0.020718548,0.02037131,0.0231878,-0.0027706719,0.011825391,0.025946414,0.036074195,-0.026332233,-0.015770404,0.01629126,0.036787964,-0.009023372,-0.010272465,0.027914098,0.020815004,-0.046954326,0.016522754,-0.025965706,-0.000936217,0.015702885,0.065550864,0.012105111,-0.012269084,0.022242539,-0.03806117,0.011748227,0.013995631,-0.014217477,0.040279638,0.054130584,0.047996044,-0.013320445,0.0014829967,0.025174772,0.0072437758,-0.029573124,-0.007335408,-0.023998022,0.017699504,-0.07646958,0.0011056162,-0.01064864,-0.00718108,-0.008989613,-0.010484666,0.03273685,0.045758285,0.016677082,-0.04375202,-0.033276998,-0.025213355,-0.040819786,-0.016792828,-0.06639967,0.04564254,0.0053725475,0.018133553,-0.059840724,-0.0126452595,0.00096937345,-0.039893817,-0.0056812037,0.02874361,0.083260015,-0.040086728,-0.059223413,0.0050735367,-0.02777906,0.034202967,0.055635285,-0.011343116,0.0023305956,0.0047697034,0.03483957,0.015481039,-0.014516488,0.021779554,-0.060187962,-0.019348888,0.036730092,-0.03271756,-0.0076344186,-0.0085218055,-0.028627865,-0.060458038,-0.019098103,-0.05536521,0.01777667,0.003354225,-0.012230502,-0.013928112,-0.064084746,0.023515746,-0.026968837,0.0067807916,0.0018362633,0.011073042,0.026853092,0.003942601,-0.039450124,0.04413784,-0.022146083,0.008946207,-0.008444642,-0.015268837,-0.066746905,0.01227873,-0.009558697,-0.020834295,-0.033392746,-0.022281121,0.015866859,-0.018210717,0.04510239,0.0032625927,-0.00965033,0.016628854,0.018538665,-0.08256554,-0.0039932397,0.020988623,0.024499588,0.004441756,-0.0133397365,0.04699291,-0.033392746,-0.00012659728,-0.0021654163,-0.03464666,-0.020429183,-0.020795712,-0.028955812,-0.02968887,0.011381698,0.005454534,0.006472135,-0.010880132,0.0302676,-0.038389117,-0.037328113,0.026563726,0.006221352,-0.015577493,0.01958038,0.03237032,-0.00038823165,0.058297444,0.00026178508,-0.06790437,-0.01236554,-0.023940148,-0.017718796,0.054246332,0.020236274,-0.026312944,-0.07137675,-0.021683099,0.0026332233,0.037540313,-0.030344766,0.053127453,0.012828524,0.038755648,-0.015587139,-0.030846331,0.063969,0.013735202,0.029997526,0.011651772,-0.0019049876,0.050542455,-0.026197197,0.047996044,-0.0022642827,-0.00053984695,0.018712284,0.0028430133,0.023207089,0.013387963,0.013214344,-0.02419093,0.04247881,-0.010774031,0.031039242,0.027508985,-0.045565374,0.012481286,-0.052625887,-0.0073305853,-0.018567601,-0.047841713,-0.027335366,0.005806595,0.01605977,-0.03101995,0.013937757,-0.03329629,-0.03269827,-0.037926134,0.0051555233,0.012085821,-0.0024668383,0.022551196,0.026988128,0.00851216,0.02912943,-0.017950289,-0.02720033,-0.0030311006,-0.0034916734,0.016860345,-0.0062695793,0.0026669826,-0.04286463,0.003040746,-0.017236521,0.012587386,-0.05613685,0.029630996,-0.016416652,0.015519621,-0.0005497939,0.033276998,-0.010899423,0.0036484129,-0.027354658,0.013387963,0.015780048,0.003091385,-0.055480957,-0.033759274]
52	2c8522ec-5489-421d-b2eb-e9c7d70a6adf	45cd4007-3bf2-4814-8007-ae8116680208	初诊，患者诉头晕	怀孕了，要做孕期常规检查，感觉身体乏力	无	未详细说明	神志清	注意休息	短暂性脑缺血发作	t	阿司匹林肠溶片	[0.0021309697,0.015898362,-0.018709067,-0.022099301,-0.041107792,-0.049298443,0.033342127,0.019066442,0.026851423,-0.03085016,-0.03142969,-0.032472838,-0.032878507,0.039716925,0.026155991,0.0041001546,-0.011474637,-0.00795401,-0.040219184,0.01391831,0.007920204,0.018477257,0.029807013,-0.0016057731,-0.046555348,0.006316846,-0.03222171,0.021539092,0.076806664,0.015569963,0.050921116,-0.014420567,-0.0014765868,-0.0427691,0.004269183,-0.058377698,-0.0033057192,-0.0073455065,-0.029382026,0.028435465,0.04311682,0.011300779,0.022949275,0.008108551,0.032588743,-0.022041349,0.0019981612,-0.03206717,-0.019143714,-0.017540354,0.0241856,-0.01217007,0.07325223,-0.0036486061,-0.010489441,-0.005573119,-0.023335626,-0.041223697,-0.008084403,-0.018100563,-0.03434664,0.019578358,0.00015665343,-0.005838736,0.015212587,0.05965266,0.03307168,-0.029130897,-0.016033584,-0.053896025,0.00085118046,-0.005186768,-0.024649221,-0.013947287,-0.028242288,0.039311256,0.036780655,-0.0734454,0.00045969783,0.028725227,0.030251317,0.011146238,-0.007838105,-0.0014681354,-0.012614374,0.009185505,-0.019974368,-0.02043799,-0.028570687,-0.02163568,-0.012112117,0.030483127,-0.065486565,-0.037263595,0.0027286068,0.0010093431,-0.001733752,-0.0027430952,0.027740031,-0.010566711,0.013020043,0.016081877,0.028937722,-0.004438212,-2.6769174e-05,0.00787674,0.0060319114,0.0045661908,0.053548306,0.0050998386,0.0031391054,0.032646693,0.041069157,0.018738044,0.005906347,-0.030135412,-0.02283337,-0.023509484,-0.036085222,-0.04280774,0.02544124,0.027411634,0.012817209,-0.02377993,-0.042189576,0.010209336,0.016497206,0.020862976,-0.006085035,0.030096775,-0.0009284508,-0.020727754,-0.027237775,-0.058570877,-0.01598529,-0.02321972,0.012044505,0.03817152,-0.020322084,-0.016188124,-0.0025740664,0.05679366,0.0006918105,-0.01700912,0.013367759,-0.035911366,0.03229898,0.022717463,0.038403332,-0.018554527,-0.026291214,-2.8014251e-06,0.027855938,0.028280923,0.029459296,0.027488904,0.011648496,-0.03316827,-0.028995674,0.03809425,-0.00270446,-0.016555158,-0.0046096556,-0.018622138,-0.023161767,0.0003087793,0.0044816765,0.018322716,-0.03500344,0.027469587,0.03635567,-0.05161655,0.06282074,-0.016294371,0.020264132,0.019066442,0.05095975,0.012054164,-0.009948549,-0.02745027,-0.0195687,-0.02012891,0.054282375,0.026136674,-0.004392333,0.006495533,-0.0007757212,-0.009489757,0.015415422,0.018641457,0.0004243829,-0.03005814,0.003658265,0.056600485,0.050302956,-0.030502444,0.0051094973,-0.027817301,-0.016545499,0.035621602,0.035409108,0.019694263,0.0019148543,-0.006983302,-0.014372272,-0.0055151666,-0.021133423,-0.058725417,-0.010962722,-0.053471036,0.0209982,0.014797259,-0.010132066,0.027624127,-0.032762602,-0.014024557,-0.032105803,-0.040373724,0.011600201,-0.027585492,-0.037089735,0.014343296,0.030560397,-0.028338877,0.0052398914,0.0026465072,0.0011107604,0.039794195,0.03330349,-0.03753404,-0.020669801,0.032356933,0.013889333,-0.026387801,0.062163945,-0.009325557,0.012025188,0.0136865,0.01694151,0.008321044,0.015705185,-0.0053944318,0.058493607,0.01415978,0.014391591,-0.019356206,0.00027436987,-0.007823616,-0.0062057697,-0.009682933,0.038210157,0.0063989456,-0.02005164,-0.031081973,-0.018322716,0.013329124,0.0058580535,0.0020295524,-0.019616993,0.0060802056,0.00644241,0.027102552,0.029845648,0.038461283,0.012363246,-0.052814238,0.032569423,-0.01742445,0.01607222,0.024745809,0.024707174,-0.03747609,0.0013944872,0.026735518,0.0018762191,0.024359457,-0.0054185786,0.02965247,0.028860452,-0.010566711,-0.038519237,-0.010528076,0.0052060853,0.014642719,0.02839683,-0.024224235,0.016960828,-0.065022945,0.005751807,-0.009122723,-0.0101513835,0.010711594,0.05385739,-0.020090275,0.005592437,0.062163945,0.0483712,-0.17772165,-0.038461283,0.008499731,-0.02401174,-0.010064455,0.022157254,0.011909283,-0.005655219,-0.01718298,-0.013831381,0.05130747,-0.021886809,0.022640193,0.010209336,-0.038866952,0.003093226,0.0037548528,0.0050225686,0.022466335,-0.0048004165,-0.030579714,0.015202928,0.024958301,-0.021017518,-0.06367072,-0.012855844,0.056484576,0.016912533,-0.013831381,-0.0118803065,-0.06676152,0.008311385,-0.01742445,0.010402512,0.03426937,0.04253729,0.0076062935,0.013657522,-0.01893122,0.0027865595,-0.0005273093,0.06726378,-0.025344653,0.050689306,0.0024750638,0.015927337,0.022543605,-0.023026545,-0.018882927,0.026040087,-0.0019776362,-0.01987778,-0.014130803,-0.017192638,-0.034385275,0.0019510747,0.0053654555,0.009721568,-0.0041653514,0.01185133,-0.035679553,-0.099601395,-0.009397998,0.040373724,-0.048293926,-0.021732267,-0.02148114,-0.017318202,-0.015579621,0.000950183,-0.015444398,-0.031217195,0.011938259,-0.014497837,0.022331113,0.0013099728,0.019491429,-0.0002730116,0.007364824,-0.105551206,-0.05146201,0.006553486,-0.025170796,-0.005041886,-0.0008970597,-0.022215206,0.008209968,0.010846816,0.020341402,0.23799248,-0.028242288,-0.04574401,-0.0138796745,0.008137527,-0.029845648,-0.027508222,0.06529339,0.025943497,-0.02687074,-0.044237237,0.020689119,-0.006258893,0.01734718,-0.007403459,0.026677566,-0.020302767,-0.03732155,0.076613486,-0.036123857,0.047328047,-0.028899087,0.025228748,-0.019385183,-0.016555158,-0.023760613,0.01519327,0.04500994,-0.017897729,0.010412171,-0.070740946,-0.023239039,0.040141914,-0.04230548,0.0060898643,0.0008300519,0.0108661335,0.0138024045,-0.046478078,-0.000757611,0.040219184,-0.004749708,-0.008393484,0.023741296,-0.03793971,0.022524288,-0.027373,-0.018651115,0.030908113,-0.029285438,0.008451438,-0.005360626,-0.046787158,-0.012981407,-0.031120608,-0.041455507,-0.04072144,0.026252579,-0.020032322,0.08136561,0.021268645,0.044082697,-0.08569275,0.0018870853,-0.0061188405,0.021732267,-0.07495218,-0.027701396,0.052891508,0.025499193,0.05497781,-0.00667905,-0.02696733,-0.007669076,0.049684793,-0.024668539,-0.01264335,0.038673777,0.022756098,0.017810801,-0.021345915,0.0084562665,-0.054282375,-0.032414883,0.028821817,0.02998087,0.071590915,0.049298443,-0.011522931,0.004160522,-0.036703385,0.010991698,-0.030328587,0.0027092893,-0.03921467,0.0033998925,-0.01987778,-0.060464,0.003634118,0.010701935,-0.06061854,-0.027160505,-0.002856586,5.942417e-05,0.0011403403,0.013174583,-0.021828854,0.011020674,-0.052505158,0.04230548,-0.060502633,-0.011329755,-0.006814273,-0.023490166,-0.023992423,-0.007461412,-0.02107547,0.024649221,0.04844847,0.044816766,-0.015898362,0.0060415706,-0.019307911,0.06846147,0.026233261,-0.00644241,0.023760613,-0.0069736433,0.011561566,0.009552539,0.0024183185,-0.021094788,-0.058802687,-0.02115274,0.04643944,0.018815314,0.00524955,0.018670432,0.042575926,0.08182923,-0.00493081,0.012208705,-0.0038103908,0.034887534,0.00059250614,0.0057469774,0.009113064,-0.017366497,0.0009942512,-0.011464979,0.0256151,0.03150696,0.04334863,-0.0448554,-0.011078627,-0.05752773,-0.020341402,-0.04462359,-0.014768283,-0.033593256,-0.00021279512,-0.0070412545,0.06262757,0.054861903,0.02696733,0.05049613,0.028010478,-0.03942716,0.010141725,0.0044720178,-0.005577949,0.001765143,-0.061043523,-0.047212142,0.0045203115,-0.00429333,-0.013705817,0.029729743,-0.0025426752,-0.00038514409,0.004643461,0.031603545,0.035872728,0.059382215,0.015241563,0.014150121,-0.015280198,-0.011271803,0.00715716,-0.04253729,0.01463306,0.11567362,0.001928135,-0.0052930145,0.027971843,0.01710571,0.03865446,0.025499193,-0.006664562,0.0010256423,0.0069301785,-0.01599495,-0.005152962,0.03164218,0.041494142,-0.005066033,-0.020399354,0.013377418,0.027334362,0.02696733,-0.0017108124,-0.012324611,-0.001837584,-0.009175846,-0.05679366,-0.023876518,-0.00707989,-9.3569484e-05,-0.012131435,-0.020553896,-0.017588649,-0.031796724,0.030656986,-0.018313058,0.0016757993,0.04875755,-0.019336889,-0.025421923,0.023470849,0.053702846,-0.010450806,-0.008258262,-0.029285438,-0.03015473,-0.011426344,-0.0534324,0.03442391,0.00025369404,-0.008422461,-0.038364697,-0.024533315,-0.030096775,-0.01367684,0.029807013,-0.005877371,0.036471575,-0.008562514,-0.013000726,0.04748259,0.0462849,0.00314152,0.023296991,-0.0009894219,-0.056986835,-0.008465925,0.03699315,-0.023451531,0.007046084,-0.009127553,-0.011542249,-0.023296991,0.057373185,0.03413415,0.019993685,-0.03347735,-0.11860988,-0.0050080805,0.019443136,-0.0068529085,-0.029053627,-0.008678419,0.01415978,-0.0011270596,0.026426436,-0.0049597863,-0.02283337,-0.010470124,0.041532777,0.037167005,-0.019665288,0.00437543,0.0020295524,0.009451122,0.03666475,0.032434203,-0.036297716,0.04087598,0.03919535,-0.023200402,0.016970485,-0.016815946,0.0068046143,-0.016033584,0.05146201,-0.00094475,0.02005164,0.0056262426,0.04280774,-0.034095515,0.009035794,-0.046555348,-7.81758e-05,-0.011300779,0.010672958,-0.0032622549,0.0241856,0.017781824,-0.00023075442,-0.021345915,0.029729743,-0.023316309,-0.08515185,0.005510337,-0.00477144,0.006152646,-0.010518418,0.0033057192,-0.03092743,0.01463306,0.053471036,0.0076497584,-0.026909376,-0.025576465,-0.0035737506,-0.05065067,-0.041841857,0.0044116504,0.010132066,-0.006592121,-0.03046381,-0.04620763,0.025151478,-0.023509484,-0.03500344,0.0038538554,-0.0030087116,-0.0068673966,-0.0039456137,0.04246002,-0.05115293,-0.010373536,-0.02712187,0.06691606,-0.03515798,-0.02712187,0.049762063,-0.015087023,0.032279663,0.025634417,-0.006727344,-0.007867081,0.050225686,-0.031043336,-0.017540354,0.014043874,0.06529339,-0.018873267,0.025788957,0.058184523,-0.016429594,-0.012401881,0.032839872,0.01002582,-0.012768915,0.02314245,0.030000187,0.01734718,0.057218645,0.03967829,0.013145607,0.0010322827,-0.027875256,-0.026445754,-0.054514185,0.009528392,0.040605534,-0.011590542,-0.0031849844,0.002341048,-0.010721252,0.009238629,0.01534781,0.029864965,-0.018651115,0.04875755,-0.02449468,-0.044275872,0.002450917,0.017472742,0.011223509,0.012904137,0.0049501276,-0.022022031,-0.00676115,-0.14364547,-0.026445754,-0.019819828,-0.027527539,-0.017694894,-0.0010914428,-0.0031753257,-0.008263091,-0.02036072,-0.029710425,-0.009055112,-0.008011962,-0.022157254,-0.020476626,-0.00074251916,0.022234524,0.00027587905,0.010257631,0.009397998,0.035756823,-0.0138796745,0.016960828,0.016555158,0.025402606,-0.01718298,-0.015289857,-0.0050563742,0.004476847,-0.040953252,0.02449468,-0.02822297,-0.038461283,0.016323347,0.058957227,0.034790944,-0.0104991,0.01726991,-0.036374986,0.02712187,0.00930624,-0.019172689,0.05575051,0.017598307,0.0133581,-0.04898936,-0.0017844606,0.031159243,0.0022951688,0.019761875,-0.009243458,-0.025460558,0.018042611,-0.0419964,-0.03714769,-0.0061188405,-0.035215933,-0.033593256,-0.03699315,0.028165018,0.0017639357,0.0020138568,-0.02712187,-0.035756823,-0.06815239,-0.011175215,0.0018061929,-0.04087598,0.03191263,-0.009494586,0.002056114,-0.05161655,-0.016400618,0.011252485,-0.038441967,-0.017482402,0.008552855,0.07468173,-0.04825529,-0.05868678,-0.007229601,-0.054668725,0.009282093,0.026426436,-0.022466335,0.00029293285,0.007949181,0.042575926,0.026059404,-0.0024110742,0.0072247717,-0.08677453,-0.003745194,0.032279663,-0.009016477,0.0017422035,-0.022678828,-0.00803128,-0.0108274985,-0.025731005,-0.04574401,0.018313058,-0.03921467,0.026503708,-0.034578454,-0.052080173,-0.0041508633,-0.027237775,0.023277674,0.014381932,0.012942772,0.011667813,-0.02306518,-0.04597582,0.04311682,-0.011078627,0.019974368,0.022852687,0.019597676,-0.049839333,0.009644297,-0.03697383,-0.052852873,-0.03450118,-0.025383288,0.00540892,-0.051346105,0.055248253,0.010730911,-0.01542508,0.027083235,0.026291214,-0.06336163,0.003882832,0.049182534,0.050612036,0.041494142,-0.0241856,0.0044164797,-0.021094788,0.015116,0.034868214,-0.030811526,-0.016275054,-0.031275146,-0.029439978,-0.02138455,0.020669801,-0.0042885006,0.0035375303,-0.007886399,0.019674946,-0.031526275,-0.037360184,0.08677453,-0.01630403,-0.028976357,-0.0015285028,0.00763527,-0.01129112,0.023084497,-0.009378681,-0.058648147,-0.045705374,-0.021751584,-0.009967866,0.06467523,-0.003356428,-0.0093593635,-0.043387264,0.0036727532,-0.008953694,0.051191565,-0.035563648,0.022447018,0.02265951,0.042421386,-0.026310531,-0.026194626,0.07244089,0.015550645,0.05072794,0.01837101,-0.0068818848,0.04620763,-0.011513272,0.008132697,0.022794735,0.024282187,0.03538979,-0.025402606,0.021597045,-0.015859725,0.03500344,0.008900571,0.019916415,0.003069079,0.011571225,0.021519775,-0.009238629,0.035544332,-0.0019583188,-0.019414159,0.014391591,-0.06262757,-0.03411483,0.008147186,0.014536472,-0.026774153,0.0033757456,-0.017588649,0.0018955367,-0.026735518,0.0012797891,-0.0059594708,-0.019027807,-0.041223697,0.038519237,-0.014623402,0.028261606,0.014536472,0.00094957935,-0.006012594,-0.008939206,-0.014381932,-0.0119962115,0.052157443,-0.03515798,0.01852555,-0.009079258,0.047907576,-0.022215206,0.017327862,-0.006331334,-0.005162621,0.028493417,0.0057759536,-0.047907576,0.023316309,-0.031796724,0.027025282,0.00022471769,-0.004725561,-0.027102552,-0.04620763]
\.


--
-- Data for Name: medical_record_disease; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.medical_record_disease (id, medical_record_id, disease_id, is_primary) FROM stdin;
1	25	1	t
2	27	1	t
3	37	2	t
4	37	7	f
5	37	1	f
6	38	2	t
7	38	7	f
8	38	1	f
9	39	5	t
10	39	6	f
11	39	10	f
12	42	2	t
13	42	3	f
14	42	7	f
15	49	7	t
16	49	4	f
17	49	1	f
18	50	7	t
19	50	4	f
20	50	1	f
21	52	7	t
22	52	4	f
23	52	1	f
\.


--
-- Data for Name: medical_technology; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.medical_technology (id, uuid, tech_code, tech_name, tech_type, price, delmark) FROM stdin;
1	77777777-7777-7777-7777-777777777777	MRI-001	脑部MRI	检查	600.00	1
\.


--
-- Data for Name: outbox_event; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.outbox_event (id, uuid, topic, payload, status, created_at, retry_count) FROM stdin;
1	cf2861fe-728d-4175-93e0-3cd60a01391c	register:paid	{"register_uuid": "0364b9d4-9efb-4ab9-804c-8388ad31811c", "symptoms": "我最近检查出来长了脑肿瘤，医生说可能需要进行脑肿瘤切除手术，请帮我挂一个外科的专家号。"}	sent	2026-05-23 20:30:33.70727	0
2	fae6cb99-3f43-4e5b-adb5-a623a42caf88	billing.payment.success.medical	{"register_uuid": "0364b9d4-9efb-4ab9-804c-8388ad31811c", "items": [{"type": "检查", "id": "4ff2118b-6429-4cab-a484-de04b9f348c5"}, {"type": "药品", "id": "9b4dbc50-447c-4e78-afad-8145e7fb3625"}]}	sent	2026-05-23 20:30:38.05691	0
3	dbbb4adb-767e-43bf-9776-9fc69bf8dfe7	billing.payment.success.pharmacy	{"register_uuid": "0364b9d4-9efb-4ab9-804c-8388ad31811c", "items": [{"type": "检查", "id": "4ff2118b-6429-4cab-a484-de04b9f348c5"}, {"type": "药品", "id": "9b4dbc50-447c-4e78-afad-8145e7fb3625"}]}	sent	2026-05-23 20:30:38.057014	0
4	773d2b7f-6222-4973-b3f0-f2b45e24b62b	register:paid	{"register_uuid": "225278d5-74e1-4ea1-9dde-e7da16aee09f", "symptoms": "我最近检查出来长了脑肿瘤，医生说可能需要进行脑肿瘤切除手术，请帮我挂一个外科的专家号。"}	sent	2026-05-23 20:43:34.752759	0
5	f09e19f0-c21b-429b-a111-383587cc908c	billing.payment.success.medical	{"register_uuid": "225278d5-74e1-4ea1-9dde-e7da16aee09f", "items": [{"type": "检查", "id": "2b7cb6d8-e5f7-4bac-86c0-75db7eb2b226"}, {"type": "药品", "id": "cf6874bf-4302-4fba-be5c-010964035dfe"}]}	sent	2026-05-23 20:43:36.912942	0
6	788514cc-e4ad-4a56-b64b-6b6d0c850714	billing.payment.success.pharmacy	{"register_uuid": "225278d5-74e1-4ea1-9dde-e7da16aee09f", "items": [{"type": "检查", "id": "2b7cb6d8-e5f7-4bac-86c0-75db7eb2b226"}, {"type": "药品", "id": "cf6874bf-4302-4fba-be5c-010964035dfe"}]}	sent	2026-05-23 20:43:36.913043	0
7	00eb7c16-14f6-44b4-88a1-c58718582ebe	register:paid	{"register_uuid": "17038ffe-7621-47df-9f9a-13cd4fbe41d5", "symptoms": "腿折了，骨头刺穿了皮肤"}	sent	2026-05-23 21:51:34.044222	0
8	fc2d64d8-9eb1-4de1-b222-36a7eea5abdc	register:paid	{"register_uuid": "3610f304-a74c-41d3-8cdb-0ddfbc7b45dd", "symptoms": "患者: 医生，我最近总是感觉头晕，而且右半边身体有点麻木。AI助手: 请问这种症状持续多长时间了？另外您之前对什么药物或食物有过敏反应吗?患者:                                                  大概有三四天了吧。我以前打青霉素过敏过，其他没啥。AI助手: 好的，是否有恶心想吐的感觉?患者: 早上起床的时候会有一点想吐。"}	sent	2026-05-24 10:27:57.953071	0
9	a498e10a-adfa-4ef8-a843-899153e73dad	register:paid	{"register_uuid": "505c8fd6-c8a8-439c-90ec-9a02f13a84fd", "symptoms": "我最近检查出来长了脑肿瘤，医生说可能需要进行脑肿瘤切除手术，请帮我挂一个外科的专家号。"}	sent	2026-05-24 12:19:03.857782	0
10	06e17644-ba2b-4b9c-aae9-c204121d6743	billing.payment.success.medical	{"register_uuid": "505c8fd6-c8a8-439c-90ec-9a02f13a84fd", "items": [{"type": "检查", "id": "0ce2d612-725f-4ba1-adf2-9653b1916db7"}, {"type": "药品", "id": "7bc5aac2-f08e-4863-b5df-53fee2943dfc"}]}	sent	2026-05-24 12:19:11.382734	0
11	c1be9de7-8d4e-4a78-8358-6523f9ba4f60	billing.payment.success.pharmacy	{"register_uuid": "505c8fd6-c8a8-439c-90ec-9a02f13a84fd", "items": [{"type": "检查", "id": "0ce2d612-725f-4ba1-adf2-9653b1916db7"}, {"type": "药品", "id": "7bc5aac2-f08e-4863-b5df-53fee2943dfc"}]}	sent	2026-05-24 12:19:11.382826	0
12	80dee487-d3ab-40aa-b5d2-1118318ad4b7	register:paid	{"register_uuid": "40cc2c9f-432b-40c8-a659-511360b769b4", "symptoms": "我最近检查出来长了脑肿瘤，医生说可能需要进行脑肿瘤切除手术，请帮我挂一个外科的专家号。"}	sent	2026-05-24 12:22:12.390987	0
13	04cad134-3f09-4854-b98c-76432865688f	billing.payment.success.medical	{"register_uuid": "40cc2c9f-432b-40c8-a659-511360b769b4", "items": [{"type": "检查", "id": "9e95cd87-0b8c-432d-ae4e-f9bb44a3aac3"}, {"type": "药品", "id": "a038a1cc-948c-49d6-8a67-eee687584aec"}]}	sent	2026-05-24 12:22:15.45044	0
14	ff3b3cce-e9a5-4290-a2b5-1034912f70cd	billing.payment.success.pharmacy	{"register_uuid": "40cc2c9f-432b-40c8-a659-511360b769b4", "items": [{"type": "检查", "id": "9e95cd87-0b8c-432d-ae4e-f9bb44a3aac3"}, {"type": "药品", "id": "a038a1cc-948c-49d6-8a67-eee687584aec"}]}	sent	2026-05-24 12:22:15.45052	0
15	d3c068f6-e877-4e30-8e3d-90259189a8b7	register:paid	{"register_uuid": "ecf81d0b-caa0-4d26-8847-241a83677776", "symptoms": "头痛发热"}	sent	2026-05-27 11:54:00.621158	0
16	e874b60e-5f1f-4567-a7c3-16d53a447d6c	medical.record.confirmed	{"register_uuid": "ecf81d0b-caa0-4d26-8847-241a83677776", "visit_state": 3}	sent	2026-05-27 11:55:13.661971	0
17	63e6cada-c60b-4cf9-a867-24556989a6f9	register:paid	{"register_uuid": "770bf3f4-921e-46be-94b3-c3aea0d3fb36", "symptoms": "发烧"}	sent	2026-05-27 18:24:21.788493	0
18	069cc9e3-4bfb-4857-bb16-3649a2ca8212	register:paid	{"register_uuid": "58d7aa50-693c-4040-affd-0650ece6f4d0", "symptoms": null}	sent	2026-05-27 20:19:53.724221	0
19	5da50dfc-46b8-42c0-b0bf-8d5480ce38c8	register:paid	{"register_uuid": "98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a", "symptoms": "头晕、心慌、恶心、心跳快，持续几天"}	sent	2026-05-27 20:52:18.168665	0
20	ffbee053-593c-472a-a957-89732dd0f240	billing.payment.success.medical	{"register_uuid": "98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a", "items": [{"type": "检查", "id": "bc9f1e8f-ca5a-4f2f-9cdc-6e082d0c1000"}]}	sent	2026-05-27 21:23:26.652543	0
21	d219cb9b-1326-4f52-8971-8ab54d29a257	billing.payment.success.pharmacy	{"register_uuid": "98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a", "items": [{"type": "检查", "id": "bc9f1e8f-ca5a-4f2f-9cdc-6e082d0c1000"}]}	sent	2026-05-27 21:23:26.65265	0
22	60a07067-824a-4a09-969b-7e06b9ffd276	medical.record.confirmed	{"register_uuid": "98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a", "visit_state": 3}	sent	2026-05-27 21:25:05.439533	0
23	fa96237b-0e4c-4338-ae46-70ad92ec5c44	billing.payment.success.medical	{"register_uuid": "98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a", "items": [{"type": "药品", "id": "77ee6aa3-6c0d-40f9-8f65-7bf586c624fa"}]}	sent	2026-05-27 21:27:13.124878	0
24	450e7ab0-ec61-4b1d-9677-6b88a8579277	billing.payment.success.pharmacy	{"register_uuid": "98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a", "items": [{"type": "药品", "id": "77ee6aa3-6c0d-40f9-8f65-7bf586c624fa"}]}	sent	2026-05-27 21:27:13.124985	0
25	d60cf0eb-8d15-4301-a2b4-910a1ee8bf71	register:paid	{"register_uuid": "758cc9fb-f779-4c68-9523-6a4726430a40", "symptoms": "头痛，眩晕，恶心"}	sent	2026-05-28 12:11:08.776751	0
26	8d9d7fcf-8805-4717-8204-13c32c137c6d	register:paid	{"register_uuid": "b134b961-246a-4d7a-94b3-960fa773f114", "symptoms": "头痛发烧伴心悸心慌三天，有慢性心脏病史"}	sent	2026-05-28 12:13:20.09756	0
27	d3a8a94a-6580-47ce-bdab-d1e33658d486	employee_vector_sync	{"employee_uuid": "67fe32fb-91d9-447f-a2da-ee6baa7ebb3d", "expertise": "\\u5168\\u79d1\\u6d4b\\u8bd5"}	sent	2026-05-28 20:31:18.371529	0
28	4fb4e0c0-b229-4d7d-9931-e1580d693b70	employee_vector_sync	{"employee_uuid": "310f297e-d179-4e33-ad71-26ea827175b2", "expertise": "\\u5168\\u79d1\\u6d4b\\u8bd5"}	sent	2026-05-28 20:32:41.291395	0
29	a9129a5c-34e2-4edd-834d-ad88f4011c17	employee_vector_sync	{"employee_uuid": "f26799d5-06e5-4d8e-bc48-464ef26b9325", "expertise": "\\u5168\\u79d1\\u6d4b\\u8bd5"}	sent	2026-05-28 20:33:27.97116	0
30	64450567-2571-4f4b-b297-b891bab165bf	register:paid	{"register_uuid": "7ca95a34-5096-4c20-85bf-1ac6be1dd105", "symptoms": "[{\\"role\\":\\"user\\",\\"content\\":\\"怀孕了，要做孕期常规检查，感觉身体乏力\\"},{\\"role\\":\\"ai\\"}]"}	sent	2026-05-28 20:49:39.573469	0
31	d40137ca-c796-44d7-b7d4-adeb357ae9c7	register:paid	{"register_uuid": "518376ad-a7d7-4221-8495-2d74d90973c0", "symptoms": "[{\\"role\\":\\"user\\",\\"content\\":\\"怀孕了，要做孕期常规检查，感觉身体乏力\\"},{\\"role\\":\\"ai\\"}]"}	sent	2026-05-28 20:51:34.114691	0
32	ef4c9db1-f400-4a4b-858b-9b29079cbb09	register:paid	{"register_uuid": "c6dc2419-8255-4b00-9d9b-56a94ad9feaa", "symptoms": "[{\\"role\\":\\"user\\",\\"content\\":\\"怀孕了，要做孕期常规检查，感觉身体乏力\\"},{\\"role\\":\\"ai\\"}]"}	sent	2026-05-28 20:52:58.17568	0
33	169a201d-dd21-4469-a938-6ef00da6ae5c	billing.payment.success.medical	{"register_uuid": "c6dc2419-8255-4b00-9d9b-56a94ad9feaa", "items": [{"type": "检查", "id": "5ef6498f-ccb8-4d19-bfe0-242cfcafdf80"}]}	sent	2026-05-28 20:53:05.92326	0
34	851c97d9-a268-4a10-8d8e-de7f83f5222b	billing.payment.success.pharmacy	{"register_uuid": "c6dc2419-8255-4b00-9d9b-56a94ad9feaa", "items": [{"type": "检查", "id": "5ef6498f-ccb8-4d19-bfe0-242cfcafdf80"}]}	sent	2026-05-28 20:53:05.923361	0
35	9b1213c9-db99-4958-a770-90457f2c2fb3	register:paid	{"register_uuid": "2f5d38eb-2c00-4d41-88d2-18e2ad56f7fc", "symptoms": "[{\\"role\\":\\"user\\",\\"content\\":\\"怀孕了，要做孕期常规检查，感觉身体乏力\\"},{\\"role\\":\\"ai\\"}]"}	sent	2026-05-28 20:54:09.671406	0
36	bf200886-90d4-458e-91c0-021f8b1c4e02	billing.payment.success.medical	{"register_uuid": "2f5d38eb-2c00-4d41-88d2-18e2ad56f7fc", "items": [{"type": "检查", "id": "901a5b13-8d6d-4197-abb9-3ac99ec56e62"}]}	sent	2026-05-28 20:54:14.761834	0
37	6d6bf37b-a494-4d84-b601-1499d4c2dc58	billing.payment.success.pharmacy	{"register_uuid": "2f5d38eb-2c00-4d41-88d2-18e2ad56f7fc", "items": [{"type": "检查", "id": "901a5b13-8d6d-4197-abb9-3ac99ec56e62"}]}	sent	2026-05-28 20:54:14.761922	0
39	c5c5513f-cca8-4030-8fb4-e2f9a1fbf0bb	billing.payment.success.medical	{"register_uuid": "50cf0ba7-41f3-45b5-88ca-d25bf2fdf69d", "items": [{"type": "检查", "id": "54b7cccf-9123-4a66-ac6a-0bb88f739fd0"}]}	sent	2026-05-28 20:55:34.875862	0
40	4cc368ff-01dc-4999-a1d1-b56d0113e764	billing.payment.success.pharmacy	{"register_uuid": "50cf0ba7-41f3-45b5-88ca-d25bf2fdf69d", "items": [{"type": "检查", "id": "54b7cccf-9123-4a66-ac6a-0bb88f739fd0"}]}	sent	2026-05-28 20:55:34.875965	0
42	9af37d3b-1ed2-4a5c-bce9-b8c2c0dae820	register:paid	{"register_uuid": "5ed3c049-4490-43a6-8b12-3fd64eb6163d", "symptoms": "[{\\"role\\":\\"user\\",\\"content\\":\\"怀孕了，要做孕期常规检查，感觉身体乏力\\"},{\\"role\\":\\"ai\\"}]"}	sent	2026-05-28 20:56:23.546733	0
43	9656aa05-11fa-4b1f-bdbe-84dc298e0b7a	billing.payment.success.medical	{"register_uuid": "5ed3c049-4490-43a6-8b12-3fd64eb6163d", "items": [{"type": "检查", "id": "b72601b8-ba3a-4dab-a9e5-7b3cf9605b59"}]}	sent	2026-05-28 20:56:29.597234	0
44	32b35f2e-69c5-4d0a-b8a4-7046aa47c596	billing.payment.success.pharmacy	{"register_uuid": "5ed3c049-4490-43a6-8b12-3fd64eb6163d", "items": [{"type": "检查", "id": "b72601b8-ba3a-4dab-a9e5-7b3cf9605b59"}]}	sent	2026-05-28 20:56:29.597323	0
38	fe5cca9d-00a3-4c47-a947-a0887bfd27d2	register:paid	{"register_uuid": "50cf0ba7-41f3-45b5-88ca-d25bf2fdf69d", "symptoms": "[{\\"role\\":\\"user\\",\\"content\\":\\"怀孕了，要做孕期常规检查，感觉身体乏力\\"},{\\"role\\":\\"ai\\"}]"}	sent	2026-05-28 20:55:27.137114	0
41	38ce1ea4-ce5c-4dd9-9dfc-f61bb0865612	medical.record.confirmed	{"register_uuid": "50cf0ba7-41f3-45b5-88ca-d25bf2fdf69d", "visit_state": 3}	sent	2026-05-28 20:55:37.584133	0
45	99464e1c-a12d-4e9e-b87c-9e81d8ae81c7	medical.record.confirmed	{"register_uuid": "5ed3c049-4490-43a6-8b12-3fd64eb6163d", "visit_state": 3}	sent	2026-05-28 20:56:32.502805	0
46	909e6402-6cd0-4223-ad6b-38c0f2ee4ff9	register:paid	{"register_uuid": "160604cf-f9ea-45e4-be24-f7be46614801", "symptoms": "[{\\"role\\":\\"user\\",\\"content\\":\\"怀孕了，要做孕期常规检查，感觉身体乏力\\"},{\\"role\\":\\"ai\\"}]"}	sent	2026-05-28 20:58:43.520027	0
47	0abe09e1-2c48-4d6d-bc14-66bc6a52f576	register:paid	{"register_uuid": "45cd4007-3bf2-4814-8007-ae8116680208", "symptoms": "[{\\"role\\":\\"user\\",\\"content\\":\\"怀孕了，要做孕期常规检查，感觉身体乏力\\"},{\\"role\\":\\"ai\\"}]"}	sent	2026-05-28 21:02:56.840203	0
48	23fb8461-51a2-46d7-ac35-01f4a435623d	billing.payment.success.medical	{"register_uuid": "45cd4007-3bf2-4814-8007-ae8116680208", "items": [{"type": "检查", "id": "2cc59f6d-8bb5-498f-a71a-dab37ea3f636"}]}	sent	2026-05-28 21:03:04.192758	0
49	9d855ee1-171d-4dba-ac9d-dbeae051f518	billing.payment.success.pharmacy	{"register_uuid": "45cd4007-3bf2-4814-8007-ae8116680208", "items": [{"type": "检查", "id": "2cc59f6d-8bb5-498f-a71a-dab37ea3f636"}]}	sent	2026-05-28 21:03:04.192857	0
50	4ec0668a-6dcc-421e-a17a-e6f4f1fc152e	medical.record.confirmed	{"register_uuid": "45cd4007-3bf2-4814-8007-ae8116680208", "visit_state": 3}	sent	2026-05-28 21:03:06.919202	0
51	9f8aefde-ff77-4585-bf5d-62ce0011c2f6	billing.payment.success.medical	{"register_uuid": "45cd4007-3bf2-4814-8007-ae8116680208", "items": [{"type": "药品", "id": "d4b76a4e-f090-4321-b89d-9b18e584a428"}]}	sent	2026-05-28 21:03:07.231257	0
52	5ea6ea0a-9e19-4a58-8291-4766db4580a2	billing.payment.success.pharmacy	{"register_uuid": "45cd4007-3bf2-4814-8007-ae8116680208", "items": [{"type": "药品", "id": "d4b76a4e-f090-4321-b89d-9b18e584a428"}]}	sent	2026-05-28 21:03:07.231362	0
\.


--
-- Data for Name: outpatient_bill; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.outpatient_bill (id, uuid, register_uuid, bill_code, total_amount, settle_category_uuid, pay_method, pay_time, transaction_id, bill_state) FROM stdin;
1	20c6cf73-abfd-45ef-aeb3-08bde4b61a51	3df51db8-498b-4ccb-951e-c909547147eb	FP202605231114102974	637.00	22222222-2222-2222-2222-222222222222	微信	2026-05-23 11:14:10.830943	WX20260523111410542160	已收费
6	72aabb2b-9aef-401b-8bb4-996077bb16d6	522575f5-810e-4ee4-8290-467c6f401f3b	FP202605231718136883	637.00	22222222-2222-2222-2222-222222222222	微信	2026-05-23 17:18:13.267367	WX20260523171813524476	已收费
9	351fc244-b175-4503-bde9-537628196b1c	505c8fd6-c8a8-439c-90ec-9a02f13a84fd	FP202605241219113159	637.00	22222222-2222-2222-2222-222222222222	微信	2026-05-24 12:19:11.379742	WX20260524121911398698	已收费
10	ba70fb7d-437a-4999-af78-8b0c923e2bb7	40cc2c9f-432b-40c8-a659-511360b769b4	FP202605241222153216	637.00	22222222-2222-2222-2222-222222222222	微信	2026-05-24 12:22:15.448486	WX20260524122215184175	已收费
11	85fd546b-b757-412c-bafb-d415599b6fea	98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a	FP202605272123267892	600.00	22222222-2222-2222-2222-222222222222	微信	2026-05-27 21:23:26.647195	WX20260527212326437399	已收费
12	dfdf7afc-f6e6-497b-ae1c-55064dc851f1	98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a	FP202605272127139175	20.00	22222222-2222-2222-2222-222222222222	微信	2026-05-27 21:27:13.122864	WX20260527212713305880	已收费
13	8f92e67c-69a0-46f9-97a4-ef3854f1d23d	c6dc2419-8255-4b00-9d9b-56a94ad9feaa	FP202605282053057727	600.00	22222222-2222-2222-2222-222222222222	微信	2026-05-28 20:53:05.917619	WX20260528205305518877	已收费
14	56052729-2b9d-44d8-aabd-48b550e3c3f4	2f5d38eb-2c00-4d41-88d2-18e2ad56f7fc	FP202605282054149065	600.00	22222222-2222-2222-2222-222222222222	微信	2026-05-28 20:54:14.760358	WX20260528205414511290	已收费
15	6cac0a9b-2f06-40eb-804b-500b5ce278c4	50cf0ba7-41f3-45b5-88ca-d25bf2fdf69d	FP202605282055347838	600.00	22222222-2222-2222-2222-222222222222	微信	2026-05-28 20:55:34.872682	WX20260528205534286155	已收费
16	a7d48741-5f69-4449-aca6-fb72b4a1a9c6	5ed3c049-4490-43a6-8b12-3fd64eb6163d	FP202605282056299920	600.00	22222222-2222-2222-2222-222222222222	微信	2026-05-28 20:56:29.595937	WX20260528205629660740	已收费
17	3251b337-0ce7-4e03-84d1-007cfedec277	45cd4007-3bf2-4814-8007-ae8116680208	FP202605282103044996	600.00	22222222-2222-2222-2222-222222222222	微信	2026-05-28 21:03:04.189872	WX20260528210304797286	已收费
18	9bcf2120-8e7b-4720-ac1d-fdfe0c9270ca	45cd4007-3bf2-4814-8007-ae8116680208	FP202605282103079238	20.00	22222222-2222-2222-2222-222222222222	微信	2026-05-28 21:03:07.230297	WX20260528210307760263	已收费
\.


--
-- Data for Name: outpatient_bill_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.outpatient_bill_detail (id, uuid, bill_id, item_type, item_source_id, amount) FROM stdin;
1	371326be-6575-4da9-a455-3c30e1250c16	1	检查	a98cf3ef-a1d8-43d2-9f07-05578daafff8	600.00
2	77a12d07-228a-4876-8d66-3cdbe944e023	1	药品	c3c91cd4-20a4-41fc-80d1-370a3785dcae	37.00
10	8a334e21-ceba-43ca-bd8d-4007201c7980	6	检查	173c7818-3fac-49e0-bcc9-91b81bb1af05	600.00
11	8cde0983-4fc5-4bb8-8921-934ca9afcbc1	6	药品	28e2139a-a991-48c3-8674-ebb9f0675ff5	37.00
16	cf784abb-e6c4-4080-a370-e36433fe772c	9	检查	0ce2d612-725f-4ba1-adf2-9653b1916db7	600.00
17	e469d265-7cbe-446a-8a3c-314f88d10271	9	药品	7bc5aac2-f08e-4863-b5df-53fee2943dfc	37.00
18	eed910de-6cf5-4b70-ae1e-e59fc6e32fbf	10	检查	9e95cd87-0b8c-432d-ae4e-f9bb44a3aac3	600.00
19	f4bdefa7-04a3-4756-8ed7-9d63e5552a4e	10	药品	a038a1cc-948c-49d6-8a67-eee687584aec	37.00
20	9e1bdb34-b454-4a7f-b49c-a7dec7684fca	11	检查	bc9f1e8f-ca5a-4f2f-9cdc-6e082d0c1000	600.00
21	dc378326-16d9-4e34-a0f6-75b8dae43c1a	12	药品	77ee6aa3-6c0d-40f9-8f65-7bf586c624fa	20.00
22	2baf7e87-20c6-4d75-ae02-2629d7de66b8	13	检查	5ef6498f-ccb8-4d19-bfe0-242cfcafdf80	600.00
23	1571d149-eae5-4a10-9f7f-60d197fb96bc	14	检查	901a5b13-8d6d-4197-abb9-3ac99ec56e62	600.00
24	29b6f723-c154-4653-afcf-d7528bfbe46d	15	检查	54b7cccf-9123-4a66-ac6a-0bb88f739fd0	600.00
25	a594eae6-d9de-42e8-9aa1-c7f073e2f88e	16	检查	b72601b8-ba3a-4dab-a9e5-7b3cf9605b59	600.00
26	062b6edc-a4ec-4757-9256-e0fba86d6284	17	检查	2cc59f6d-8bb5-498f-a71a-dab37ea3f636	600.00
27	9ad7f353-257e-437d-878e-8cc4b22b946f	18	药品	d4b76a4e-f090-4321-b89d-9b18e584a428	20.00
\.


--
-- Data for Name: patient; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.patient (id, uuid, case_number, real_name, gender, card_number, birthdate, home_address, created_at) FROM stdin;
1	218e05bd-d1af-4541-b9fc-1d26e356c75c	BLH202605231104023455	王小明	男	310101E98F5D6F2EA0	1995-08-20	北京市海淀区中关村南大街88号	2026-05-23 11:04:02.400626
2	cad164d3-3cd7-4cec-b01d-69b425e00637	BLH202605231108101155	王小明	男	310101EF19E45CD831	1995-08-20	北京市海淀区中关村南大街88号	2026-05-23 11:08:10.111768
3	e2599bbe-715e-49e3-8ed5-cfa00ffdd1f3	BLH202605231108477785	王小明	男	310101869CDFAB9BE5	1995-08-20	北京市海淀区中关村南大街88号	2026-05-23 11:08:47.933423
5	046a6bda-2757-4436-a44f-4c0a79c8cb73	BLH202605231109568334	张三	男	31010104970281EB1B	1990-03-15	上海市浦东新区	2026-05-23 11:09:56.732453
6	be3eb376-fa8b-4ddf-9b95-e832aec5eb2b	BLH202605231111157594	张三	男	310101D51EA6D3E1E1	1990-03-15	上海市浦东新区	2026-05-23 11:11:15.105072
7	32efe695-39f7-4668-8fda-ea44f85758eb	BLH202605231111583815	张三	男	310101919D730E1F42	1990-03-15	上海市浦东新区	2026-05-23 11:11:58.797939
8	af802f09-6470-4270-9759-8729343165bc	BLH202605231114059443	张三	男	310101FF4A30AB6466	1990-03-15	上海市浦东新区	2026-05-23 11:14:05.986153
12	843d21a2-558c-47c0-9ee1-ec1ae1b2e513	BLH202605231401391922	王小明	男	3101016F7EF1200148	1995-08-20	北京市海淀区中关村南大街88号	2026-05-23 14:01:39.115213
15	4233576c-03c3-4966-a4db-0639f77b9d7b	BLH202605231449572341	逆向测试者	男	3101013CA0CF5DAFD7	1990-01-01	\N	2026-05-23 14:49:57.175928
16	357755dd-cd06-42c7-91f2-c6c82c64f3f5	BLH202605231450285427	逆向测试者	男	3101016E1BA247316F	1990-01-01	\N	2026-05-23 14:50:28.129824
17	7b6077da-6ca9-4e0c-b18a-8bd377d95c3a	BLH202605231452315902	逆向测试者	男	3101016216ADF2A2F1	1990-01-01	\N	2026-05-23 14:52:31.741398
18	ba9971d1-7827-4a7c-8709-970054158eed	BLH202605231453287461	逆向测试者	男	310101D6109B00F15D	1990-01-01	\N	2026-05-23 14:53:28.763037
19	c9e9eef8-469c-4b8f-a4cc-849589f1542a	BLH202605231454314574	逆向测试者	男	3101018D358C8DFB0F	1990-01-01	\N	2026-05-23 14:54:31.498253
20	0bb45ada-ae7c-472e-9702-0e4cae71baf6	BLH202605231455403728	逆向测试者	男	310101193FE908C6B2	1990-01-01	\N	2026-05-23 14:55:40.233551
21	8c7ebd9c-9876-4c77-be6c-2bfe70811b77	BLH202605231458419578	逆向测试者	男	310101ABD46E6014CD	1990-01-01	\N	2026-05-23 14:58:41.128917
22	2dc53e02-7473-47e4-9cda-593a53dafd9d	BLH202605231459013473	逆向测试者	男	31010163981165798C	1990-01-01	\N	2026-05-23 14:59:01.057676
53	13c7f8d9-dbfb-4259-8c04-1f5990a5676f	BLH202605282052526727	测试王总	男	E2E1779972772253	1990-01-01	\N	2026-05-28 20:52:52.345684
99	99999999-9999-9999-9999-999999999999	CHAOS001	破坏王	男	110105199001011234	1990-01-01	\N	\N
24	504c4de4-a4aa-4f5d-a791-36f856c73258	BLH202605231713292154	张三	男	31010187CAB73B9FFA	1990-03-15	上海市浦东新区	2026-05-23 17:13:29.162477
25	8f9461f8-1c0b-4414-97b6-4d53534b35b0	BLH202605231716072397	张三	男	3101017D6E31806895	1990-03-15	上海市浦东新区	2026-05-23 17:16:07.121416
26	e674a0d4-2caf-4968-a5ab-b13bd2fffc84	BLH202605231718024216	张三	男	3101012F76002D4ACE	1990-03-15	上海市浦东新区	2026-05-23 17:18:02.865287
29	1d3ca710-a4e6-4b77-8de7-cf1157dc0239	BLH202605232046134395	李四	男	310101199003158828	1990-03-25	上海市	2026-05-23 20:46:13.287796
30	14e8bf30-8947-4e59-9759-cd311e84a7f3	BLH202605241218518543	张三	男	31010116ECBEDC24D6	1990-03-15	上海市浦东新区	2026-05-24 12:18:51.493968
31	d42bb67a-03c3-4acc-bb86-cf5e725856a5	BLH202605241221552510	张三	男	310101F330C4225FA7	1990-03-15	上海市浦东新区	2026-05-24 12:21:55.493474
32	c1b4a2cf-a990-4b42-8333-05e549caa421	BLH202605271153083171	Test User	男	T999999999	1990-01-01	Test Street	2026-05-27 11:53:08.69004
33	5c17a1fc-da84-48ce-b497-8ff8225cfb78	BLH202605272019133164	张三	男	110105198001011234	1980-01-01	\N	2026-05-27 20:19:13.370654
34	d58eb022-42bb-4534-9a2e-0ab26c7c6d9b	BLH202605272049169643	王大锤	男	110105199001019999	1990-01-01	\N	2026-05-27 20:49:16.024459
35	3204d9ee-1cff-4c22-bed0-e93eb4b427a2	BLH202605281147342229	测试	男	123456789012345678	1990-01-01	\N	2026-05-28 11:47:34.488252
36	b0233cfd-9ff7-4e91-aa19-f39da6703ea7	BLH202605281150435536	王五	男	110105199001011123	1990-01-01	北京市朝阳区	2026-05-28 11:50:43.285577
37	04bfa69f-4b69-4ce9-b002-405caa86db48	BLH202605281210336394	王五	男	110105199001014567	1990-01-02	北京市朝阳区	2026-05-28 12:10:33.004153
38	386b00c6-e1b0-4834-98a3-e603c316fee1	BLH202605281212178257	王刘	男	110105199001012456	1990-01-01	北京市朝阳区	2026-05-28 12:12:17.644726
39	87f1b978-bee8-4cf7-97d0-6113d912dea1	BLH202605282031189306	张三 (E2E Test)	男	CARD_cb927bde	1990-01-01	\N	2026-05-28 20:31:18.430348
40	6933bcd1-b636-4657-9a21-3fea79a12a0c	BLH202605282032411202	张三 (E2E Test)	男	CARD_f21da1e3	1990-01-01	\N	2026-05-28 20:32:41.32287
41	dc722835-38b8-4ed0-bba1-d3716d5d3094	BLH202605282033276619	张三 (E2E Test)	男	CARD_a1f88461	1990-01-01	\N	2026-05-28 20:33:28.000453
42	896ddbb9-b763-4d12-978b-8bfb8dec7277	BLH202605282041078959	测试王总	男	E2E1779972066885	1990-01-01	\N	2026-05-28 20:41:07.042264
43	a4f48a6c-90ab-4030-bc37-59dc3b3368f8	BLH202605282041285184	测试王总	男	E2E1779972088059	1990-01-01	\N	2026-05-28 20:41:28.150374
44	4832658c-d351-4e8f-a29b-ebc4183b17ca	BLH202605282042013031	测试王总	男	E2E1779972121942	1990-01-01	\N	2026-05-28 20:42:01.991573
45	e11f2e9c-07a3-41f3-8867-d90347c79477	BLH202605282043069894	测试王总	男	E2E1779972186471	1990-01-01	\N	2026-05-28 20:43:06.544623
46	4b5f6cfc-6966-4c89-91b2-63be7163d9e2	BLH202605282044298128	测试王总	男	E2E1779972269038	1990-01-01	\N	2026-05-28 20:44:29.093874
47	3bd525f5-e3d1-4636-a274-d53ac2e5661f	BLH202605282045193751	测试王总	男	E2E1779972319483	1990-01-01	\N	2026-05-28 20:45:19.551308
48	adaf1d47-ff72-45d4-84a3-97431a2b2053	BLH202605282046325709	测试王总	男	E2E1779972392572	1990-01-01	\N	2026-05-28 20:46:32.641762
49	70042d44-9878-45a4-ace1-f7d325227b32	BLH202605282047231362	测试王总	男	E2E1779972443159	1990-01-01	\N	2026-05-28 20:47:23.221924
50	fac59b17-307c-40e6-89d1-f180745c830d	BLH202605282048528958	测试王总	男	E2E1779972532659	1990-01-01	\N	2026-05-28 20:48:52.718354
51	45c967e4-466d-4665-aff0-1d7f7342ca27	BLH202605282049342036	测试王总	男	E2E1779972574030	1990-01-01	\N	2026-05-28 20:49:34.093018
52	b846a860-d15d-4282-a116-09f276654de6	BLH202605282051283745	测试王总	男	E2E1779972688078	1990-01-01	\N	2026-05-28 20:51:28.152769
54	b59e4ff1-0edf-4460-b1cc-7df771fe2298	BLH202605282053583466	测试王总	男	E2E1779972838799	1990-01-01	\N	2026-05-28 20:53:58.873001
55	d0afdf5b-3e84-47df-868e-05eb5a815d3a	BLH202605282055232918	测试王总	男	E2E1779972923560	1990-01-01	\N	2026-05-28 20:55:23.620373
56	22d6ca13-586f-491c-95fb-503930f2ddfb	BLH202605282056196742	测试王总	男	E2E1779972979361	1990-01-01	\N	2026-05-28 20:56:19.447885
57	44056803-97ce-4a19-abe9-eb62a1a513b2	BLH202605282058398189	测试王总	男	E2E1779973118992	1990-01-01	\N	2026-05-28 20:58:39.140831
58	d5f5b4d1-852c-4747-b41f-52f2639350ca	BLH202605282102495610	测试王总	男	E2E1779973369127	1990-01-01	\N	2026-05-28 21:02:49.244255
\.


--
-- Data for Name: patient_feedback; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.patient_feedback (id, uuid, register_uuid, doctor_uuid, content, is_processed, created_at) FROM stdin;
1	32fd0608-bb32-4139-8d2e-50a196fc7645	3a91916c-7ba0-4ebd-bbf1-024b67e30b97	5ca2828e-90ed-46b3-8476-f60b81019aa5	医生非常耐心，解答详细，非常感谢！	t	2026-05-24 11:38:18.637953
2	71bcee00-105a-4304-b52f-21e0581858a5	3a91916c-7ba0-4ebd-bbf1-024b67e30b97	5ca2828e-90ed-46b3-8476-f60b81019aa5	医术高超，服务态度很好，赞一个！真的是太棒了，妙手回春。	t	2026-05-24 11:38:18.637953
\.


--
-- Data for Name: prescription; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.prescription (id, uuid, register_uuid, prescription_code, creation_time, is_ai_recommended, drug_state) FROM stdin;
1	a5758162-cb3f-4943-b446-a7030ef42c65	b5b44f78-352b-43d4-b28e-670047981745	CF202605231111234060	2026-05-23 11:11:23.849946	t	开立
2	628e7a3a-bc90-46eb-9dd4-060e7ec4819e	59fb6156-4035-4275-a9bc-29625d3fdc10	CF202605231112023561	2026-05-23 11:12:02.997601	t	开立
3	fd282669-cb34-4bc6-82c5-9ad56be10a44	3df51db8-498b-4ccb-951e-c909547147eb	CF202605231114109617	2026-05-23 11:14:10.623339	t	已发药
10	4438a07f-d627-4770-8479-ce06c81b12f4	522575f5-810e-4ee4-8290-467c6f401f3b	CF202605231718132123	2026-05-23 17:18:13.050353	t	已发药
13	25595d23-4ac8-4398-bae0-baa3bc60a7a5	505c8fd6-c8a8-439c-90ec-9a02f13a84fd	CF202605241219118015	2026-05-24 12:19:11.214522	t	已缴费
14	2d0a1bb4-3603-4b03-82a0-f81f9476e402	40cc2c9f-432b-40c8-a659-511360b769b4	CF202605241222159280	2026-05-24 12:22:15.300924	t	已发药
15	d98fe43a-bd95-4ad8-8546-4c76eaecb6ab	98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a	CF202605272126436050	2026-05-27 21:26:43.10844	t	已退费
16	63baa5ec-80a2-4bbc-97ab-7d67e1e239ad	5ed3c049-4490-43a6-8b12-3fd64eb6163d	CF202605282056323151	2026-05-28 20:56:32.616849	t	开立
17	b4f8c0ed-0346-4002-b446-e82997a71d5f	45cd4007-3bf2-4814-8007-ae8116680208	CF202605282103075186	2026-05-28 21:03:07.025695	t	已缴费
\.


--
-- Data for Name: prescription_item; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.prescription_item (id, uuid, prescription_id, drug_id, drug_usage, drug_number) FROM stdin;
1	3563962e-eaa6-4feb-aacb-50ca1dea3b5a	1	3	口服，每日2次，每次1粒	2
2	146eefe3-1d33-4893-8d1b-bb263c4a1b74	2	3	口服，每日2次，每次1粒	2
3	c3c91cd4-20a4-41fc-80d1-370a3785dcae	3	3	口服，每日2次，每次1粒	2
10	28e2139a-a991-48c3-8674-ebb9f0675ff5	10	3	口服，每日2次，每次1粒	2
13	7bc5aac2-f08e-4863-b5df-53fee2943dfc	13	3	口服，每日2次，每次1粒	2
14	a038a1cc-948c-49d6-8a67-eee687584aec	14	3	口服，每日2次，每次1粒	2
15	77ee6aa3-6c0d-40f9-8f65-7bf586c624fa	15	1	一天三次，饭后服用	2
16	194dce0e-205f-4753-bde9-63201d5c31e3	16	1	口服 每日三次 每次一片	2
17	d4b76a4e-f090-4321-b89d-9b18e584a428	17	1	口服 每日三次 每次一片	2
\.


--
-- Data for Name: regist_level; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.regist_level (id, uuid, regist_code, regist_name, regist_fee, delmark) FROM stdin;
1	44444444-4444-4444-4444-444444444444	ZJH	专家门诊	50.00	1
2	6d2d53e9-27c4-44ad-bfcc-9d5ff2bc3d7e	PTM	普通门诊	20.00	1
3	545abab7-8c8a-419c-a969-d61d29c50784	TJM	特需门诊	100.00	1
\.


--
-- Data for Name: register; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.register (id, uuid, patient_id, visit_date, noon, dept_uuid, employee_uuid, scheduling_actual_id, settle_category_uuid, regist_method, regist_money, is_emergency, visit_state, symptoms, scheduling_time_slot_id) FROM stdin;
57	306dfe45-8504-464f-95d5-50815db8c3e2	50	2026-05-28 20:49:01.816551	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	0	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	305
49	40cc2c9f-432b-40c8-a659-511360b769b4	31	2026-05-24 12:22:12.369695	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	9	22222222-2222-2222-2222-222222222222	微信	50.00	f	3	我最近检查出来长了脑肿瘤，医生说可能需要进行脑肿瘤切除手术，请帮我挂一个外科的专家号。	\N
50	ecf81d0b-caa0-4d26-8847-241a83677776	32	2026-05-27 11:54:00.612763	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	1	22222222-2222-2222-2222-222222222222	现场	50.00	f	3	头痛发热	\N
41	3a91916c-7ba0-4ebd-bbf1-024b67e30b97	26	2026-05-23 20:52:37.043797	全天	c35a9ac0-38a1-4165-bca2-621bb889d562	a48c2085-a9dc-4486-ae89-09dc24564330	8	22222222-2222-2222-2222-222222222222	支付宝	100.00	f	1	\N	\N
42	8887291d-1477-4583-9c35-666e4cf9633c	26	2026-05-23 21:00:20.566188	全天	c35a9ac0-38a1-4165-bca2-621bb889d562	a48c2085-a9dc-4486-ae89-09dc24564330	8	22222222-2222-2222-2222-222222222222	支付宝	100.00	f	1	\N	\N
13	c09ba832-b2f5-4ea6-b381-fbd813dee939	99	2026-05-23 14:13:32.590752	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	1	22222222-2222-2222-2222-222222222222	微信	50.00	f	0	\N	\N
14	9f91073a-1d21-4423-9e7f-1c3a643296c7	99	2026-05-23 14:13:32.634575	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	1	22222222-2222-2222-2222-222222222222	微信	50.00	f	0	\N	\N
12	25dcae83-1fc8-40a7-881c-dac05935bed0	99	2026-05-23 14:13:32.539206	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	1	22222222-2222-2222-2222-222222222222	微信	50.00	f	4	\N	\N
43	4a3bfd40-17d6-4c8f-a9da-61d218fbb089	29	2026-05-23 21:29:08.651153	全天	40504a01-c105-401d-8acf-8c9c9ac3663a	87ee7a64-f696-417c-bc89-7697dfca10f0	6	22222222-2222-2222-2222-222222222222	微信	20.00	f	0	\N	\N
44	f53d35f8-0c77-4eb9-a027-97083e934a7a	29	2026-05-23 21:33:43.181311	全天	40504a01-c105-401d-8acf-8c9c9ac3663a	87ee7a64-f696-417c-bc89-7697dfca10f0	6	22222222-2222-2222-2222-222222222222	微信	20.00	t	2	昨天开始一直头疼，今天早上还吐了两次	\N
45	ce8e2fcd-fe8d-4ee5-a022-ebf5ec2c44c4	2	2026-05-23 21:47:19.17429	全天	40504a01-c105-401d-8acf-8c9c9ac3663a	87ee7a64-f696-417c-bc89-7697dfca10f0	6	22222222-2222-2222-2222-222222222222	微信	20.00	f	0	\N	\N
34	0b6733de-9fbd-48fc-a5e8-486a89264ef0	99	2026-05-23 15:21:17.674866	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	1	22222222-2222-2222-2222-222222222222	微信	50.00	f	0	\N	\N
46	17038ffe-7621-47df-9f9a-13cd4fbe41d5	5	2026-05-23 21:50:28.377937	全天	40504a01-c105-401d-8acf-8c9c9ac3663a	87ee7a64-f696-417c-bc89-7697dfca10f0	6	22222222-2222-2222-2222-222222222222	支付宝	20.00	t	4	腿折了，骨头刺穿了皮肤	\N
33	0d3225c5-f692-4787-96c7-d93d0754d3ba	99	2026-05-23 15:21:17.625915	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	1	22222222-2222-2222-2222-222222222222	微信	50.00	f	4	\N	\N
32	86cbe7b9-0d68-4db4-b1ef-b084fb4ceab7	99	2026-05-23 15:21:17.429584	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	1	22222222-2222-2222-2222-222222222222	微信	50.00	f	1	\N	\N
37	db98c1cc-f7f3-482a-a1c3-d9dbcc651496	99	2026-05-23 16:01:06.643843	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	1	22222222-2222-2222-2222-222222222222	微信	50.00	f	0	\N	\N
36	0e5091ae-ff55-46fb-b55a-162deffc3974	99	2026-05-23 16:01:06.590407	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	1	22222222-2222-2222-2222-222222222222	微信	50.00	f	4	\N	\N
35	3ccf28cf-8189-4886-8a04-27a2d37bb00d	99	2026-05-23 16:01:06.474935	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	1	22222222-2222-2222-2222-222222222222	微信	50.00	f	1	\N	\N
47	3610f304-a74c-41d3-8cdb-0ddfbc7b45dd	29	2026-05-24 10:26:24.27278	上午	a4d3af24-e83b-4a84-8094-f6d6f31b9b3a	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	9	22222222-2222-2222-2222-222222222222	微信	50.00	f	1	患者: 医生，我最近总是感觉头晕，而且右半边身体有点麻木。AI助手: 请问这种症状持续多长时间了？另外您之前对什么药物或食物有过敏反应吗?患者:                                                  大概有三四天了吧。我以前打青霉素过敏过，其他没啥。AI助手: 好的，是否有恶心想吐的感觉?患者: 早上起床的时候会有一点想吐。	\N
38	522575f5-810e-4ee4-8290-467c6f401f3b	26	2026-05-23 17:18:12.136588	下午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	4	22222222-2222-2222-2222-222222222222	微信	50.00	f	3	\N	\N
60	c6dc2419-8255-4b00-9d9b-56a94ad9feaa	53	2026-05-28 20:52:58.15649	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	2	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	308
48	505c8fd6-c8a8-439c-90ec-9a02f13a84fd	30	2026-05-24 12:19:03.828612	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	9	22222222-2222-2222-2222-222222222222	微信	50.00	f	2	我最近检查出来长了脑肿瘤，医生说可能需要进行脑肿瘤切除手术，请帮我挂一个外科的专家号。	\N
58	7ca95a34-5096-4c20-85bf-1ac6be1dd105	51	2026-05-28 20:49:39.553132	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	2	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	306
52	58d7aa50-693c-4040-affd-0650ece6f4d0	33	2026-05-27 20:19:41.50813	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	23	22222222-2222-2222-2222-222222222222	微信	50.00	f	4	\N	286
53	98e0ddc2-7f4f-4f47-b55b-3e70e4ec666a	34	2026-05-27 20:52:07.623254	上午	a4d3af24-e83b-4a84-8094-f6d6f31b9b3a	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	15	22222222-2222-2222-2222-222222222222	微信	50.00	f	3	头晕、心慌、恶心、心跳快，持续几天	1
59	518376ad-a7d7-4221-8495-2d74d90973c0	52	2026-05-28 20:51:34.092993	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	2	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	307
51	770bf3f4-921e-46be-94b3-c3aea0d3fb36	1	2026-05-28 10:48:45.100992	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	1	发烧	304
54	758cc9fb-f779-4c68-9523-6a4726430a40	37	2026-05-28 12:11:08.772519	上午	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	23	22222222-2222-2222-2222-222222222222	APP	50.00	f	1	头痛，眩晕，恶心	286
55	b134b961-246a-4d7a-94b3-960fa773f114	38	2026-05-28 12:13:20.096241	下午	a4d3af24-e83b-4a84-8094-f6d6f31b9b3a	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	16	22222222-2222-2222-2222-222222222222	APP	50.00	f	1	头痛发烧伴心悸心慌三天，有慢性心脏病史	32
56	a87a53df-727d-4c8f-9ae2-ac2204171f0f	49	2026-05-28 20:47:28.228527	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	0	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	304
63	5ed3c049-4490-43a6-8b12-3fd64eb6163d	56	2026-05-28 20:56:23.52812	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	3	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	311
61	2f5d38eb-2c00-4d41-88d2-18e2ad56f7fc	54	2026-05-28 20:54:09.64507	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	2	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	309
62	50cf0ba7-41f3-45b5-88ca-d25bf2fdf69d	55	2026-05-28 20:55:27.116888	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	3	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	310
64	160604cf-f9ea-45e4-be24-f7be46614801	57	2026-05-28 20:58:43.495931	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	2	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	312
65	45cd4007-3bf2-4814-8007-ae8116680208	58	2026-05-28 21:02:56.816263	上午	0d019506-05b0-49ef-9cb8-6cec08d0d1ae	5ca2828e-90ed-46b3-8476-f60b81019aa5	24	22222222-2222-2222-2222-222222222222	微信	50.00	f	3	[{"role":"user","content":"怀孕了，要做孕期常规检查，感觉身体乏力"},{"role":"ai"}]	313
\.


--
-- Data for Name: schedule_disruption; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schedule_disruption (id, uuid, patient_id, register_id, original_employee_uuid, original_time_range, original_schedule_date, original_noon, message, status, created_at) FROM stdin;
1	f42483a6-4a79-419e-bbf5-63fd34c7ed1c	33	52	11111111-1111-1111-1111-111111111111	08:00-08:10	2026-06-01	上午	您预约的 2026-06-01 08:00-08:10 时段因故停诊，请尽快退号或改签	resolved	2026-05-27 20:22:32.849476
2	0e9eea02-2ddb-4bc2-942b-59b75e4f9653	34	53	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	08:00-08:08	2026-05-28	上午	您预约的 2026-05-28 上午 门诊因故取消，请尽快退号或改签	unread	2026-05-27 21:56:42.588922
\.


--
-- Data for Name: scheduling_actual; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scheduling_actual (id, uuid, employee_uuid, schedule_date, noon, regist_quota, registered_count, clinic_room_uuid) FROM stdin;
24	95bd0baa-e5fe-4ee9-a480-647919adea6b	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-01	上午	20	10	66666666-6666-6666-6666-666666666666
15	329d01bc-f9e3-4113-9eab-18e3a7398fa1	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-05-28	上午	1	1	\N
23	15e803ca-571f-4129-b035-026a7d7db17e	11111111-1111-1111-1111-111111111111	2026-06-01	上午	1	1	\N
16	3f2a456e-2da4-439d-8503-fc7f3a08ae70	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-05-28	下午	30	1	\N
25	479228c4-c609-4e4c-83db-2b4ea17f113d	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-05-30	上午	20	0	\N
26	bb8274d7-810d-49bc-82c5-90a54ef3a662	11111111-1111-1111-1111-111111111111	2026-05-28	下午	30	0	\N
27	d5d0ce22-3331-4f86-8054-825d58cd5882	f26799d5-06e5-4d8e-bc48-464ef26b9325	2026-05-28	上午	50	0	\N
28	f388e955-0ea3-43f2-ad45-b47baf32af2f	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-05-29	上午	30	0	\N
29	4bdaeb10-6405-4da7-8ed3-f19e5604db29	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-05-29	下午	30	0	\N
30	d9e00f93-6a26-46c4-9b44-34a020880c74	a48c2085-a9dc-4486-ae89-09dc24564330	2026-05-29	上午	30	0	\N
31	29f79f23-ef9f-4fd7-aeed-3c4e2cdf4811	a48c2085-a9dc-4486-ae89-09dc24564330	2026-05-29	下午	30	0	\N
32	5e79e440-f782-4dc2-ac95-92bb0bfb3112	11111111-1111-1111-1111-111111111111	2026-05-29	上午	30	0	\N
33	ac6c15f0-c826-4eb3-b614-8b6f4ae2965e	11111111-1111-1111-1111-111111111111	2026-05-29	下午	30	0	\N
34	00b1fe25-4421-4d17-ad3c-be4dd61b8415	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-05-29	上午	30	0	\N
35	41ddd757-75e8-4048-b357-196f63f61e8e	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-05-29	下午	30	0	\N
36	ab4062c2-4eae-4be6-981a-a35bbfcdd8e1	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-01	上午	30	0	\N
37	4c93860a-2d93-407e-8a91-6adfeb2a5a8d	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-01	下午	30	0	\N
38	a0ab1a89-ed7f-4298-acd9-cfc900fb1590	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-01	上午	30	0	\N
39	21cdba77-10ae-4f5a-b256-384265f7ab88	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-01	下午	30	0	\N
40	2a3e6c9d-e96d-48da-929f-68741ab5ad1c	11111111-1111-1111-1111-111111111111	2026-06-01	下午	30	0	\N
5	85915df2-ebe5-4f67-bcc0-0d4467e6efa9	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-05-23	全天	50	0	\N
41	f4acd49f-e7f0-4361-a2f2-9201dede1501	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-01	下午	30	0	\N
7	18cfbd69-7ca2-4b8f-9b9a-6bdaaef01376	a48c2085-a9dc-4486-ae89-09dc24564330	2026-05-23	全天	50	0	\N
42	8862df71-cc36-4fad-806d-a2301ad73917	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-02	上午	30	0	\N
43	da765e07-cc0e-4527-b3fd-26cec27777a3	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-02	下午	30	0	\N
44	ecdc3446-6ab1-4b99-a50b-78bdd584298f	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-02	上午	30	0	\N
45	4cda1f9a-83ab-4df7-b86a-e49f825fc858	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-02	下午	30	0	\N
46	9ddc4c0c-a896-4a25-9e54-115b48458abc	11111111-1111-1111-1111-111111111111	2026-06-02	上午	30	0	\N
47	44f51855-e48b-438d-a7c8-8f722a8a52c0	11111111-1111-1111-1111-111111111111	2026-06-02	下午	30	0	\N
8	132bf987-5f20-4e72-ae80-16ba7469d19b	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-05-23	全天	50	2	\N
48	b328d38c-c12d-41e3-8267-ccfcc4ea8d0b	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-02	上午	30	0	\N
49	d418b28c-b2a8-44f0-9256-87ad4b2000d5	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-02	下午	30	0	\N
50	cdc9b492-a428-4b76-9189-1b7abc85d582	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-03	上午	30	0	\N
51	aa6f2aea-b186-431e-84ea-9ac6908d023f	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-03	下午	30	0	\N
6	bd4663ea-82f2-42cf-bcf2-ede0c93d8026	87ee7a64-f696-417c-bc89-7697dfca10f0	2026-05-23	全天	50	3	\N
52	c3d4e030-93d1-409e-90d9-c14e7c572b6f	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-03	上午	30	0	\N
53	ba204183-9eee-4c67-8fa5-85ca96b6194c	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-03	下午	30	0	\N
11	baf9bfb1-8e97-48da-b05c-18b8bd856cbb	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-05-24	上午	50	0	\N
54	e6eda6ed-92ff-426c-8480-c90b1022b43f	11111111-1111-1111-1111-111111111111	2026-06-03	上午	30	0	\N
55	571e9396-07fc-4af6-ab4c-f51a0e6b91c1	11111111-1111-1111-1111-111111111111	2026-06-03	下午	30	0	\N
56	8e55ad41-7ad3-4d63-b567-734d447acb56	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-03	上午	30	0	\N
58	f128e27c-3585-41a9-86d0-86a3d0bd88c5	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-04	上午	30	0	\N
14	616f01b0-05e1-4a51-8090-8bd7086257ad	a48c2085-a9dc-4486-ae89-09dc24564330	2026-05-27	上午	15	0	\N
59	4014e905-2a44-4370-ad10-2a827ba7de3e	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-04	下午	30	0	\N
4	8a053101-614b-4181-84ec-13dbbe0c13b7	11111111-1111-1111-1111-111111111111	2026-05-27	下午	2	1	\N
9	7f461790-a00f-4ecd-9fec-045b98c415cb	11111111-1111-1111-1111-111111111111	2026-05-27	上午	30	1	\N
1	33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	2026-05-27	上午	3	3	\N
17	fb2ca69e-28df-4836-b999-e09969015769	11111111-1111-1111-1111-111111111111	2026-05-28	上午	30	0	\N
21	fb4cb80d-68f2-4e62-aeaf-42f8f9ec0567	a48c2085-a9dc-4486-ae89-09dc24564330	2026-05-28	上午	30	0	\N
22	8f56d8b4-78fe-4b9b-a85a-4fe445722129	a48c2085-a9dc-4486-ae89-09dc24564330	2026-05-28	下午	30	0	\N
60	2e146e65-4335-47a6-ba7a-c2909f44657e	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-04	上午	30	0	\N
19	d5c9782a-ad64-4805-a31c-519d28aaea59	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-05-28	上午	30	0	\N
12	11c72fb0-b172-43c8-bae5-82ca41459892	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-05-27	上午	20	0	\N
20	dabe1de3-862e-4ea1-a655-f2556d192443	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-05-28	下午	25	0	\N
61	07cde252-89ce-4cbc-949d-f9757d071143	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-04	下午	30	0	\N
62	751c105b-685e-41bf-8128-a4c41eeeca9b	11111111-1111-1111-1111-111111111111	2026-06-04	上午	30	0	\N
63	b4c806e1-3ba8-4ca3-acb4-d843be941122	11111111-1111-1111-1111-111111111111	2026-06-04	下午	30	0	\N
64	38cd4e8c-087d-41dc-963a-8d96cc6ae98f	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-04	上午	30	0	\N
65	31fe175f-a8c3-4604-bd38-fd32cb5a86b7	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-04	下午	30	0	\N
66	2b98ae0f-4c04-4c49-b385-3297a021392b	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-05	上午	30	0	\N
67	e7bb4233-dc06-467e-b552-9b81732240e6	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	2026-06-05	下午	30	0	\N
68	0a18c0af-8c1c-466b-9b95-32dfa22ddb02	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-05	上午	30	0	\N
69	743aa505-82ad-4709-aaaa-3b494b4c6d1c	a48c2085-a9dc-4486-ae89-09dc24564330	2026-06-05	下午	30	0	\N
70	3b19381b-5f40-4003-b8c9-674b62a396d8	11111111-1111-1111-1111-111111111111	2026-06-05	上午	30	0	\N
71	0f4e6266-d307-4f4d-b2f9-356455917ff3	11111111-1111-1111-1111-111111111111	2026-06-05	下午	30	0	\N
72	644d38f9-ea1a-4bb0-af2f-236c155d2700	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-05	上午	30	0	\N
73	b38e5a05-a940-4e6e-b832-34e2e93f2590	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-05	下午	30	0	\N
57	58e85caa-1e31-47fb-8330-635eec294a1a	5ca2828e-90ed-46b3-8476-f60b81019aa5	2026-06-03	下午	10	0	\N
\.


--
-- Data for Name: scheduling_application; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scheduling_application (id, uuid, employee_uuid, prompt, status, reject_reason, created_at, processed_at) FROM stdin;
1	1770051b-3db7-4be2-a324-72aedfd8e7cb	11111111-1111-1111-1111-111111111111	下周一上午我要调休，停诊半天	approved	\N	2026-05-26 13:32:23.468378	\N
2	f3d841b8-1962-40e4-8386-fdcf0ad0c0bd	5ca2828e-90ed-46b3-8476-f60b81019aa5	医生要求明天上午增加15个门诊号源，申请临时加号。	approved	\N	2026-05-26 13:59:32.616618	\N
5	96d4bb5c-82a7-4978-b944-1328ea709286	a48c2085-a9dc-4486-ae89-09dc24564330	申请明天（即下一个工作日）增加15个门诊号源，请管理员审核批准。	approved	\N	2026-05-26 23:21:17.563201	\N
6	78366b0b-5468-439e-9193-8442d4edb33b	5ca2828e-90ed-46b3-8476-f60b81019aa5	申请将2026年5月27日上午的门诊排班限额从15人调整为20人。	approved	\N	2026-05-27 18:37:04.354456	\N
7	1c30faec-59ea-46cf-92f3-0e15b72454f0	5ca2828e-90ed-46b3-8476-f60b81019aa5	申请将2026年5月28日（星期四）下午的门诊排班限额从30人调整为25人。	approved	\N	2026-05-27 18:41:01.262092	\N
9	e4f3177b-e33a-497e-8471-5f3e987f89e3	11111111-1111-1111-1111-111111111111	申请于2026年5月28日（星期四）下午停诊，请管理员审批。	approved	\N	2026-05-27 21:37:05.414762	\N
10	7cc0cb46-b100-475a-b88e-33913a8a682d	5ca2828e-90ed-46b3-8476-f60b81019aa5	申请在2026年5月29日（星期五）上午增加一个门诊排班，限额20个号源。	pending	\N	2026-05-28 12:43:33.96134	\N
11	36acf6dd-b062-4c49-a9de-62becd2b3831	5ca2828e-90ed-46b3-8476-f60b81019aa5	申请于2026年5月30日（星期六）上午，在B栋2楼妇科一诊室，为代班医生增加20个门诊号源。	approved	\N	2026-05-28 12:45:01.76959	\N
12	45c117e6-c49a-41a9-88cf-5c580c229de1	5ca2828e-90ed-46b3-8476-f60b81019aa5	下周三下午门诊限额调整到10个	approved	\N	2026-05-28 20:49:39.992276	\N
13	412e23f5-8818-494f-a2bd-cb5a5b80578c	5ca2828e-90ed-46b3-8476-f60b81019aa5	下周三下午门诊限额调整到10个	approved	\N	2026-05-28 20:51:34.456272	\N
14	c38be115-8962-4cc3-915c-b1cf45612842	5ca2828e-90ed-46b3-8476-f60b81019aa5	下周三下午门诊限额调整到10个	approved	\N	2026-05-28 20:52:58.551449	\N
15	696db5e7-d3e8-4fed-9dfd-eabc3d7f4239	5ca2828e-90ed-46b3-8476-f60b81019aa5	下周三下午门诊限额调整到10个	approved	\N	2026-05-28 20:54:10.078681	\N
16	6333071a-9500-48ae-a91a-335c852379c2	5ca2828e-90ed-46b3-8476-f60b81019aa5	下周三下午门诊限额调整到10个	approved	\N	2026-05-28 20:55:27.465609	\N
17	41e63e3c-134d-45ff-a078-9c878663bbde	5ca2828e-90ed-46b3-8476-f60b81019aa5	下周三下午门诊限额调整到10个	approved	\N	2026-05-28 20:56:24.151739	\N
18	59d77b44-674a-40f7-b1c5-e85fc5b1eeb3	5ca2828e-90ed-46b3-8476-f60b81019aa5	下周三下午门诊限额调整到10个	approved	\N	2026-05-28 20:58:43.954025	\N
19	2ca18c9e-ef3b-454b-b3a0-f072b8e687c7	5ca2828e-90ed-46b3-8476-f60b81019aa5	下周三下午门诊限额调整到10个	approved	\N	2026-05-28 21:02:57.242461	\N
\.


--
-- Data for Name: scheduling_rule; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scheduling_rule (id, uuid, employee_uuid, rule_name, week_rule, llm_text_rule, regist_quota, delmark, clinic_room_uuid) FROM stdin;
2	5824ade6-84dc-44d0-b1b4-7114026f3a8b	6ea26ab6-f69d-4eac-8c0e-a1c23c22780e	张心医的AI规则	1,2,3,4,5	明天上午排班号源增加10个	30	1	\N
4	c3abcf81-3c4d-425a-a512-7e2a0e54e69a	a48c2085-a9dc-4486-ae89-09dc24564330	赵儿医的AI规则	1,2,3,4,5	明天（2026-05-27）上午增加15个门诊号源	30	1	\N
1	5fcd1037-a395-44a1-aa47-555c762e302a	11111111-1111-1111-1111-111111111111	李医生的AI规则	1,2,3,4,5	2026年5月28日下午停诊	30	1	\N
3	7ce0275c-64bb-42d8-924d-6ba6fe4b6351	5ca2828e-90ed-46b3-8476-f60b81019aa5	孙妇医的AI规则	1,2,3,4,5	下周三下午门诊限额调整为10个	30	1	\N
\.


--
-- Data for Name: scheduling_time_slot; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scheduling_time_slot (id, uuid, scheduling_actual_id, time_range, is_booked) FROM stdin;
314	e5f08607-6370-4a9a-a4d5-864fde50adf7	24	09:40-09:50	f
315	7bc5d7d5-20d5-47a9-9ecc-0b8b8b1881c8	24	09:50-10:00	f
316	a0d712db-f29a-4fd8-8287-4a7ff4debde6	24	10:00-10:10	f
317	5f449358-b050-472a-93d2-a782351e697d	24	10:10-10:20	f
318	37c1d810-743a-463a-aa93-8b705ef8b380	24	10:20-10:30	f
319	77c7a7a6-f1fc-4a7b-a262-563bd0831c4f	24	10:30-10:40	f
320	db329ef5-2994-454e-819f-994c66fc2c9b	24	10:40-10:50	f
321	e97a397d-eb0e-49ee-ac2a-3dec923afa7c	24	10:50-11:00	f
322	ac0e77d6-d816-416c-8660-f3b314ce329d	24	11:00-11:10	f
323	d35c57cd-1a37-483c-9aec-547b108a5745	24	11:10-11:20	f
32	1a82c36b-deba-46c5-82e8-018d123dc12a	16	13:08-13:16	t
416	7ef7ab7b-4b52-46ce-9428-e37a62f06d1a	27	15:00-15:10	f
417	3e6a2439-c501-441d-9d2f-bd5cd3fcd657	27	15:10-15:20	f
418	acf2cc0e-e0da-41e1-b465-ff64ab8e3549	27	15:20-15:30	f
419	20bcc08f-ef85-46b7-8f0a-705872e14d3f	27	15:30-15:40	f
420	227c5e1c-5023-4334-b5c8-c2d4f04fca6d	27	15:40-15:50	f
421	593e9792-27d3-49cc-bea7-d744b35d35d0	27	15:50-16:00	f
422	be740d5a-d607-4a0b-b8e7-b8a8d0bee1e2	27	16:00-16:10	f
423	b7421b95-7a9e-4645-b79a-20db9ed73d0e	27	16:10-16:20	f
31	7b62d88d-2a37-4bfd-b121-54f11fb14c02	16	13:00-13:08	f
33	fbaeb56c-15c1-4a6b-800c-1ecc5c2231a6	16	13:16-13:24	f
34	f7df548e-ef91-47c2-9979-f7473f588e4c	16	13:24-13:32	f
35	acb0cea8-d181-4a57-8204-1499ff494811	16	13:32-13:40	f
36	6615e430-b872-4fae-93f0-6dd7357a1dd2	16	13:40-13:48	f
37	a4d7e2ad-3654-4712-9c3e-33c47976405e	16	13:48-13:56	f
38	37d422d6-4edd-4dc7-bf8a-f5e0e8a3b06d	16	13:56-14:04	f
39	0a209584-fe23-483e-a4d1-0dc5c08d370a	16	14:04-14:12	f
40	4b3025fd-bd3f-4fa9-9da2-233526aa8080	16	14:12-14:20	f
41	c2fcabf5-866c-4cad-b8f3-4cb719873cb6	16	14:20-14:28	f
42	bd2d51ae-0b76-4171-ab4a-cae622f33fd7	16	14:28-14:36	f
43	1f69f6b4-64ff-4ad8-ac1c-4a2f03c503e9	16	14:36-14:44	f
44	aec8d580-65d6-4581-87ef-48149b31757e	16	14:44-14:52	f
45	ee4a91ca-6a0b-4540-9647-d98a95cce7df	16	14:52-15:00	f
46	b0058f81-8e61-44f2-8feb-9419961ed18c	16	15:00-15:08	f
47	1ccf6a9b-92a6-4c4a-a36d-60b6a4da3fa7	16	15:08-15:16	f
48	f1b78ae4-f1b8-459b-b965-abf6359b3b81	16	15:16-15:24	f
49	def65f3e-b3be-4c8d-8db9-ebc688b18f45	16	15:24-15:32	f
50	9a463c79-7447-423b-840e-5ba489abd6af	16	15:32-15:40	f
51	09933075-acf7-4eb4-aa65-87cd8ee79f61	16	15:40-15:48	f
52	4896a975-56f0-4b6f-9f00-c724358819f9	16	15:48-15:56	f
53	37088715-f3d2-4a9f-91c9-35549ee74a57	16	15:56-16:04	f
54	ce4804c7-086e-41af-9b8f-7bb6599db603	16	16:04-16:12	f
55	061427f8-6709-494d-adb3-2dce6a34aa4b	16	16:12-16:20	f
56	23578a40-ff29-4bf8-97a5-5368aadb13ce	16	16:20-16:28	f
57	6abd7077-9fa9-4474-bca6-35f9d81309d3	16	16:28-16:36	f
58	d54ea537-e0c7-4813-a2f3-91e909aa504b	16	16:36-16:44	f
59	3e7f8f49-d02b-49ec-8cb7-f12639fc2d45	16	16:44-16:52	f
60	a389145f-b28a-4b4b-8997-fe5a128b17d4	16	16:52-17:00	f
61	0695e5f3-c1a3-4cb8-ba16-db0fe1424d66	17	08:00-08:08	f
62	e4462789-ac29-44af-b8f3-4d0a0cdf7aea	17	08:08-08:16	f
63	75dd7970-94c0-427d-89be-fe50d5f9305c	17	08:16-08:24	f
64	6e736a11-1ebe-4a45-b3b0-0fc24c7e0ddc	17	08:24-08:32	f
65	951ab9eb-5d53-4544-a238-493af5304643	17	08:32-08:40	f
66	636b8591-468b-4f8b-9f7a-b3f6361d44ca	17	08:40-08:48	f
67	2c1a6e42-f91f-44e0-b06e-b3774ba7978a	17	08:48-08:56	f
68	b3e20687-8c12-4843-8ef7-9660f98f460d	17	08:56-09:04	f
69	dfa38157-a1e5-49ea-9b24-89362dc4a295	17	09:04-09:12	f
70	d8b510eb-3f46-469f-94ed-1f72eba11cbf	17	09:12-09:20	f
71	8602666b-e2e2-4661-9da2-629b4a158f84	17	09:20-09:28	f
72	cb22f7d8-ef6c-499b-9175-f1d9e9be3262	17	09:28-09:36	f
73	7fe46407-567e-479d-bf4a-2e36fc50e928	17	09:36-09:44	f
74	e1e1466e-9817-45b2-993b-c010c384469b	17	09:44-09:52	f
75	ed629865-cd83-44ff-832b-ab5cfb51e06b	17	09:52-10:00	f
76	f7db16a8-3e9a-496b-a44b-bd44d88db4bb	17	10:00-10:08	f
77	8cea78f7-4ff4-4f18-8008-5586b3f217ef	17	10:08-10:16	f
78	8e5fc4c0-2751-4879-87f8-8728444abcf7	17	10:16-10:24	f
79	46b4a7cc-4b25-4dec-bc1a-53078b2234a9	17	10:24-10:32	f
80	c14867f3-e182-4e9d-ab97-b44001cbd6e7	17	10:32-10:40	f
81	02213fed-1b76-4d40-9774-769206508ec4	17	10:40-10:48	f
82	f5151eb5-9a34-4514-9c96-727602de65ef	17	10:48-10:56	f
83	e028df63-4d11-4030-803b-923c3a87ffbb	17	10:56-11:04	f
84	6057692e-853f-4d9d-8604-ebfa7e34563d	17	11:04-11:12	f
85	065f22ea-a35e-427b-9895-5a4455daf2b3	17	11:12-11:20	f
86	a86ff5cb-1903-4ee4-ab3f-c7e24272b28f	17	11:20-11:28	f
87	344fec41-6387-4be3-8d00-8c0ee74ee8a7	17	11:28-11:36	f
88	9f74018d-0d70-4106-be41-eba965489013	17	11:36-11:44	f
89	ff1dc1a7-7f85-475f-b3b3-6d9acabe12b8	17	11:44-11:52	f
90	879df235-200f-4c4a-8069-16396ff827e1	17	11:52-12:00	f
435	116662dc-c11d-4a43-b31d-fd1aaff12734	28	09:28-09:36	f
436	4c01ea22-8423-4077-84b3-1816920f46ef	28	09:36-09:44	f
437	93bc1ba0-d1a5-4e36-8a0a-bb4932167279	28	09:44-09:52	f
438	fed1b4ac-4a5b-4213-ba7e-aebea2cf8915	28	09:52-10:00	f
439	b1afe642-a297-438e-a053-a770e0820dee	28	10:00-10:08	f
440	8ecf3d6f-673c-413b-9f90-0dd032ac1ecb	28	10:08-10:16	f
441	63713bbb-43eb-4efa-a9ff-c3f18bbbcf1a	28	10:16-10:24	f
442	93882652-07cd-43aa-adb2-9b3b0f6fcbf9	28	10:24-10:32	f
443	bed2bea3-6cf4-41f2-a49f-907d11c5bded	28	10:32-10:40	f
444	82721843-6bd8-41f6-bc03-db029185a4b0	28	10:40-10:48	f
445	3e2fc84c-ada6-44fe-bde7-98f74abe973d	28	10:48-10:56	f
446	2fe53861-b63e-4c7d-939a-31c76dd84ced	28	10:56-11:04	f
447	a90d42d1-1a5f-4d95-b21e-39c0d7005b74	28	11:04-11:12	f
448	199e7422-3264-46fd-8f5b-9122f1b5982b	28	11:12-11:20	f
449	cf4341a4-c4af-4c34-964d-febab71f2797	28	11:20-11:28	f
450	5ea01c74-062a-4660-9426-082c37d71e36	28	11:28-11:36	f
451	16202009-beb1-4f93-8a74-31d166a61f15	28	11:36-11:44	f
452	ad177066-9155-4d4d-96c0-1451b4adff60	28	11:44-11:52	f
453	a6dfb135-2ec8-4fd0-9a80-9e7a15efbd13	28	11:52-12:00	f
454	ae6b2bb1-8275-442c-8be9-63402e54524e	29	13:00-13:08	f
455	1114b854-4c1d-44dd-9a86-408ef6c5a761	29	13:08-13:16	f
456	d9f396e1-d0e7-4c1e-8f51-29b3906ddbd2	29	13:16-13:24	f
457	f94c77c7-cde3-4884-b66f-5c525c19d01b	29	13:24-13:32	f
458	02f8e345-87a8-45e5-bccf-1939fd53537b	29	13:32-13:40	f
459	3eb36f8d-48d6-4431-bf0a-13b08d2d90cf	29	13:40-13:48	f
460	d457f622-6a2e-470b-b5fc-bb22730a6c79	29	13:48-13:56	f
461	62673159-8ef4-4f17-98a0-2de21174afdb	29	13:56-14:04	f
462	744d7937-1916-44fd-979a-da293212aa71	29	14:04-14:12	f
463	9ea2273b-7e41-45b6-8cab-a972ea37ae76	29	14:12-14:20	f
464	f00d0347-143e-42b9-a2e0-b7eff0ad9a2b	29	14:20-14:28	f
1	9aea165d-e812-421b-bfd4-cb42096a3b7c	15	08:00-08:08	t
304	d58c1070-19bf-4d2f-9681-7b6ece0d048b	24	08:00-08:10	t
306	23bc7091-65b3-4f02-9917-645c7f21f353	24	08:20-08:30	t
307	ec6d253f-383a-47cb-8e8f-1c8a7f0b26de	24	08:30-08:40	t
308	25d19de8-720b-43e1-807e-af5e5c4d612a	24	08:40-08:50	t
309	6b4478ca-76be-40af-bbfb-49ba5d148d39	24	08:50-09:00	t
310	fcdbb6ad-bfbd-4676-9c9f-b3c93b6f7cb4	24	09:00-09:10	t
311	2c76c3eb-a777-45df-97e3-a1f7c22e5b17	24	09:10-09:20	t
312	86791e1f-52ce-40d1-885d-04f63d17792d	24	09:20-09:30	t
313	5c15f33c-c755-477c-a546-422914fa780e	24	09:30-09:40	t
324	2d5cd2b1-84fa-482c-aee7-932b352d7c98	25	08:00-08:10	f
122	0cef5144-fd1b-4db5-a64d-6a35ecb1cb3e	19	08:08-08:16	f
123	0ce347f2-361e-49e3-9e74-c2788050c9d6	19	08:16-08:24	f
124	d67c1216-beac-4137-8721-f08f22775449	19	08:24-08:32	f
125	b72ecb7c-a44c-45df-a56c-e21f7a02be30	19	08:32-08:40	f
126	a9b49038-abd2-4737-83bd-78914e44a344	19	08:40-08:48	f
127	58a69932-663c-4d7f-b13d-10ddf4dfb9b7	19	08:48-08:56	f
128	ea515c68-c33a-4c2d-8407-678a94688e26	19	08:56-09:04	f
129	a477e7d1-c8bf-4c2a-8f8e-8bfd42aef42f	19	09:04-09:12	f
130	b86dcba4-849c-45b7-a13d-142628fea2fa	19	09:12-09:20	f
131	1921c29f-ffc8-495b-af7a-af63c41e065c	19	09:20-09:28	f
132	34e8f18f-2846-4fff-b7cc-a860160168d1	19	09:28-09:36	f
133	381181c9-9ddc-441f-88d4-4938387b939e	19	09:36-09:44	f
134	c04bdcfe-df34-4c08-ae43-9615f660a477	19	09:44-09:52	f
135	8ccb037a-8dcf-461e-ac56-1a3f207772bc	19	09:52-10:00	f
136	059a607f-cd80-46be-8938-9cd0aeaa8a3e	19	10:00-10:08	f
137	8ceb311c-429e-4cb7-b302-df55e399a07b	19	10:08-10:16	f
138	6abde1b2-1b3d-433d-aa08-e1b57080aa53	19	10:16-10:24	f
139	093ab48b-f1bd-4bd8-b17e-d98179424d82	19	10:24-10:32	f
140	a756bcff-65fc-4996-90ec-ec8201907d82	19	10:32-10:40	f
141	aff6110e-23f0-4b70-855e-53d5b9c6ecec	19	10:40-10:48	f
142	5441e680-41f8-4940-99b1-675b209dc6af	19	10:48-10:56	f
143	549c1a5a-7490-4eb5-ba4e-93602804a8ed	19	10:56-11:04	f
144	57131572-eb44-4538-a4e4-4c35503c302c	19	11:04-11:12	f
145	40f782de-d1e5-41a7-a38d-75ee362f244f	19	11:12-11:20	f
146	bdb8b718-733b-47c8-bcd9-3569f15fd77d	19	11:20-11:28	f
147	d98fe22b-8e41-43ba-b69f-0c67780dd56d	19	11:28-11:36	f
148	cde1e76c-b410-4c61-a2c1-5a6148a0d79d	19	11:36-11:44	f
149	66240a85-5441-4cb7-8656-a8720539e7a5	19	11:44-11:52	f
150	249e47f3-3ac1-4088-965f-53614f9d65fa	19	11:52-12:00	f
325	b7d6e4af-8a59-4318-9d02-6eb8cbf4a4da	25	08:10-08:20	f
326	1ead6207-705a-42ee-885e-00217a3e3234	25	08:20-08:30	f
327	dfe312ff-7cef-4162-a6e2-87ae533b1bc9	25	08:30-08:40	f
328	4d07b682-8b7e-4de7-9fda-fd1ee499073e	25	08:40-08:50	f
329	54b0a895-2c7d-47f5-9fd2-cc8196b62ddb	25	08:50-09:00	f
330	86387f7f-b296-402b-a377-22c2e6d07a6e	25	09:00-09:10	f
331	89e8d1f5-bc3c-49f3-a6ee-eb76f090c7e4	25	09:10-09:20	f
332	5d2ed6f9-51e6-40f4-bde8-e16a6113ccc1	25	09:20-09:30	f
333	af45202c-d8ac-4815-bbae-3b44bac1ff0e	25	09:30-09:40	f
334	cf43e680-1aa5-40dd-9764-90eb6755b17b	25	09:40-09:50	f
335	2f1b4b20-4843-4f34-92a0-656c0b126cc6	25	09:50-10:00	f
336	956eaac3-0108-48bb-a016-052a1f140aef	25	10:00-10:10	f
337	8c76d23a-c002-4659-8c17-63bdc17634fd	25	10:10-10:20	f
338	f369bb70-ebd2-44d7-ad71-bcaa8da7a485	25	10:20-10:30	f
339	66cde7fa-9c95-44e6-a994-125174ad4495	25	10:30-10:40	f
340	04512e68-e68b-4948-be1b-b63d6fb48d4d	25	10:40-10:50	f
341	ac943f8b-6578-463e-add6-c74f4a6376cc	25	10:50-11:00	f
342	dfcc847e-ffb2-44ed-94a5-5781b590b260	25	11:00-11:10	f
343	fa992f67-6471-4579-8c1a-98c0a1f60883	25	11:10-11:20	f
424	07ec027e-d8fe-43ae-8ed4-ea60c83f25c7	28	08:00-08:08	f
425	f8d9f27f-af65-4cc2-bbe7-9ad0d802ee7c	28	08:08-08:16	f
426	ea86df9f-5f84-4021-9716-4cc84bf31c24	28	08:16-08:24	f
427	4c719890-6bec-46df-a5af-264da022f6b2	28	08:24-08:32	f
428	2d2e5569-e0f7-4474-bde4-1327a60769bf	28	08:32-08:40	f
429	6d6882f0-e9ca-4d3f-b7e6-ba81ec801cf3	28	08:40-08:48	f
430	ab6f5d21-4f85-4d95-873f-83ced9ab4ef3	28	08:48-08:56	f
431	02c75b5b-f272-4618-84dd-08a0be884094	28	08:56-09:04	f
432	3d174ac0-7e3a-48d9-a74f-30f07eb81f39	28	09:04-09:12	f
433	272b6f2e-0abd-4746-b50c-49be2c00cc3a	28	09:12-09:20	f
434	89a39507-2aca-46ba-b5b9-af2763a9c27c	28	09:20-09:28	f
181	e8339baf-4a25-4a4a-a965-05aea4627c8d	21	08:00-08:08	f
182	75bcb915-4658-4d79-8a18-1100490ce942	21	08:08-08:16	f
183	45c27ba7-5d53-4580-a9a5-22e70e6f3c62	21	08:16-08:24	f
184	fe86a371-56f2-4b4f-9a79-23e9ff046601	21	08:24-08:32	f
185	81e6b036-741d-495d-b0a3-56b54eb332d5	21	08:32-08:40	f
186	7764cf07-2a3f-4db1-8e56-802783c17f1d	21	08:40-08:48	f
187	16bbeeb4-f205-4953-ad28-071c01a7b910	21	08:48-08:56	f
188	846fd161-812e-4c97-81a1-6a80a82d1d6f	21	08:56-09:04	f
189	91511b26-b9f4-441e-a749-3409cd318cfd	21	09:04-09:12	f
190	e008defd-aedf-490c-99d3-b5b03a33cd97	21	09:12-09:20	f
191	2fdcf486-8380-4c46-9682-7016ab792bb7	21	09:20-09:28	f
192	f0178f8e-a268-490f-aedb-ade8925d1ab6	21	09:28-09:36	f
193	b6620b7b-38cb-4df6-8c4c-a9964de3a882	21	09:36-09:44	f
194	5014de37-0043-42be-be2c-53d6c7764a27	21	09:44-09:52	f
195	644bb0ce-1794-4a00-b3c3-575aabb2ac8d	21	09:52-10:00	f
196	0939cd86-c355-47ac-872b-2bbb8ad4826e	21	10:00-10:08	f
197	74564508-b28a-4eb2-9e2c-e5aa59f3c706	21	10:08-10:16	f
198	4eea5cd3-dd26-4fdd-80c2-195a934a1701	21	10:16-10:24	f
199	8e96d096-297a-4809-ba94-cb07a0da57e1	21	10:24-10:32	f
200	ade3bef5-eb10-44c4-ba5a-3683067a1171	21	10:32-10:40	f
201	62fdc248-b5e0-468e-847c-99f592687aa7	21	10:40-10:48	f
202	c5ea181b-fac8-47f6-9825-eb6ee9e51afe	21	10:48-10:56	f
203	e61c66af-a40d-4940-9e79-feac36439aea	21	10:56-11:04	f
204	6f19d287-94f6-4f2d-8aa3-b7e5d7ccca1f	21	11:04-11:12	f
205	f6ff5510-422c-44e1-aeb6-3f3359f3b592	21	11:12-11:20	f
206	d73e6d78-fa46-4fa3-b6e0-63f114f9caa2	21	11:20-11:28	f
207	08468717-581d-4cd3-94e2-407233536537	21	11:28-11:36	f
208	6197deb3-e483-40bd-9366-c1ba85cefec0	21	11:36-11:44	f
209	fab3e144-66f6-41cf-9810-811948950066	21	11:44-11:52	f
210	47a5a2db-3821-4f60-a668-58f68dd0892d	21	11:52-12:00	f
211	b7b8fa4a-a044-460f-8230-ea41980fb303	22	13:00-13:08	f
212	6bea57ef-7a15-4e07-84a1-3eac5e601521	22	13:08-13:16	f
213	3e4d66b3-75dd-4aaa-b82a-f0866d00f6bb	22	13:16-13:24	f
214	47e312a6-286f-40a3-85e5-1f8c54f64207	22	13:24-13:32	f
215	3df76215-413f-494f-916d-55364953745e	22	13:32-13:40	f
216	90e99d03-6fa3-4310-857d-51f2f1edb340	22	13:40-13:48	f
217	b3f18303-c7fe-4b51-9b8f-501ac8d08308	22	13:48-13:56	f
218	620c5b03-55ef-4d9c-8ac5-846575001005	22	13:56-14:04	f
219	5e4523e6-3ad6-498d-b8dd-058f47e69849	22	14:04-14:12	f
220	bdb453a8-c396-4866-be18-040dac54adc8	22	14:12-14:20	f
221	b20f5fcd-728c-49cb-ab5a-25b892c1c768	22	14:20-14:28	f
222	adf6df24-d9c1-4430-a3c0-2eda7b0df3c0	22	14:28-14:36	f
223	0f727cc9-6eba-4752-83bd-b33d2796fd19	22	14:36-14:44	f
224	a551953b-12d4-4366-99f5-e8aea23729f8	22	14:44-14:52	f
225	7c2f903e-4044-4f4a-8cd4-1a8ae3d41388	22	14:52-15:00	f
226	e2b8f72a-66a7-4b23-b145-24c31cdbd9b5	22	15:00-15:08	f
227	0c4ae62a-d80b-4986-9d2a-4f953f39d6e3	22	15:08-15:16	f
228	00c4e44c-2ad3-42b8-b315-8785397c74d6	22	15:16-15:24	f
229	9af79d51-4b2d-4c47-8ad8-ea36965d41f8	22	15:24-15:32	f
230	eb19bf8b-d384-4713-b49c-8ea51fe04a48	22	15:32-15:40	f
231	2afa37a6-6cc5-4bee-b83f-8d563b346991	22	15:40-15:48	f
232	ef8ba1d1-2cfa-4484-8ce3-7f47b2e4cb9c	22	15:48-15:56	f
233	fa3041c3-6f16-4e02-ba82-7774f6fc29a2	22	15:56-16:04	f
234	6ef916a2-7408-44ad-a481-c3d1d63d0db1	22	16:04-16:12	f
235	a6e90e1d-3655-463c-aa33-9e31da6f7ab3	22	16:12-16:20	f
236	ff7c6a7e-e20f-4e5c-bee4-c9e6e7233553	22	16:20-16:28	f
237	c4663554-c25e-4743-91a8-d602ae96c18e	22	16:28-16:36	f
238	b4de1c8c-67c3-4eb5-9c78-0c76fd66af84	22	16:36-16:44	f
239	7312ff9d-b3a3-46e4-a03f-6344982fc8a8	22	16:44-16:52	f
240	63ac0036-34af-434f-a63a-bac95a9e11f2	22	16:52-17:00	f
121	68cc60c8-59e9-4474-a8e0-067bfa0af66f	19	08:00-08:08	f
241	d0c511da-35f7-463c-b364-2115da162f17	12	08:00-08:12	f
242	f40d3e30-fc2b-4e1f-b2c0-c5d9bd12ee3b	12	08:12-08:24	f
243	aebeddcd-bec2-4223-990e-94baa3ca1e16	12	08:24-08:36	f
244	21e51b6b-f591-4a21-bc34-63844eb9e326	12	08:36-08:48	f
245	8932404a-6508-491b-a5c5-8fb47f7bac27	12	08:48-09:00	f
246	30bfb0e6-4b76-4166-bd57-aea6c2125ca7	12	09:00-09:12	f
247	8f84af3f-1c8e-44cc-ab14-12593dd6f7d3	12	09:12-09:24	f
248	bad6e4f5-9077-4088-bc99-df733b03fb54	12	09:24-09:36	f
249	5a76c55a-e096-41d9-b9b2-c6b1fb799d9a	12	09:36-09:48	f
250	8d33cad6-a725-4077-9bd7-5b01d97fb469	12	09:48-10:00	f
251	ad9fee80-10b1-41bc-819f-1cdff68ad928	12	10:00-10:12	f
252	3fb5f9dd-9adc-4a03-87a2-9a8b71bdf0e0	12	10:12-10:24	f
253	a041fd64-f8ed-4ceb-b97f-3049a79098bb	12	10:24-10:36	f
254	d4c05e8f-1594-458d-9a72-30a7e3add84f	12	10:36-10:48	f
255	5caf63d4-8dba-4974-8ec1-716f09bb5546	12	10:48-11:00	f
256	663240f0-06a9-4a00-865a-c94e2a8acf77	12	11:00-11:12	f
257	220e93b3-6d4f-4e47-98fe-e21664af0968	12	11:12-11:24	f
258	f63e8f09-b103-4322-aa80-71e8c9cc9604	12	11:24-11:36	f
259	547784ed-b711-4abe-aae2-cedf12175d56	12	11:36-11:48	f
260	e2499b49-6f88-4072-9517-3fe801308a8b	12	11:48-12:00	f
261	6323f204-0bab-44f7-810e-251a0442a40b	20	13:00-13:09	f
262	c8858e11-9bd3-470e-88a0-dd38ea2f4b8c	20	13:09-13:19	f
263	1cb2b2e6-e80c-4bd2-9197-f58dc0fdd13d	20	13:19-13:28	f
264	98d4de07-475f-4d88-97ae-00a486f85628	20	13:28-13:38	f
265	6cb4034f-6796-49b7-b6d9-63e510c91ba6	20	13:38-13:48	f
266	93a2f22c-4266-4530-8dcd-b0af8dcc852b	20	13:48-13:57	f
267	af9454c7-92a2-4400-894f-2535e2b8b79b	20	13:57-14:07	f
268	49a0480b-a3c5-431e-a49a-102ab7490e9b	20	14:07-14:16	f
269	8c93a01f-d227-4e18-918a-d20b0116e007	20	14:16-14:26	f
270	0944949b-acf2-47bc-b1b6-e41e8c2aa7a2	20	14:26-14:36	f
271	5539c1a4-7680-4a3f-8d32-087d4757c8a7	20	14:36-14:45	f
272	6f91e91c-c2bc-40c1-8e5b-c6bb0b9921aa	20	14:45-14:55	f
273	d3c9d987-8e8c-43c8-bf37-9b36928b9362	20	14:55-15:04	f
274	d17bc254-3c95-48dc-ae49-37f586bc2e0a	20	15:04-15:14	f
275	c66d95bc-77f6-4232-bcad-054d816e2468	20	15:14-15:24	f
276	981cf785-caff-4d93-b62a-d8f0a291f6ff	20	15:24-15:33	f
277	2c9a049c-28d1-48e4-bdfe-cc568f86f4f2	20	15:33-15:43	f
278	c9f5e4fd-0488-4fa8-ba12-4a858310de79	20	15:43-15:52	f
279	e1f04005-1be5-4ad3-9f95-b2e506c71288	20	15:52-16:02	f
280	4225ec62-246d-4ce7-a3aa-d664f2b970ae	20	16:02-16:12	f
281	7923d4c7-61e0-4b14-ab0a-98759995c030	20	16:12-16:21	f
282	9b677963-bd09-40f5-b8db-7db09c0b2812	20	16:21-16:31	f
283	06e4bad3-19f5-4c6d-bef8-7c7a444b7a04	20	16:31-16:40	f
284	7fbe79a9-284a-4cbc-a67f-b2c4f7fcc604	20	16:40-16:50	f
285	4232451d-805f-4eb4-ac47-cbbaaebad0c3	20	16:50-17:00	f
286	47e56b8e-bda6-4753-9b1d-7c8232a9254c	23	08:00-08:10	t
344	89d211fb-9d10-45a0-b685-9eabb5001d5d	26	13:00-13:08	f
345	b1b9376c-03db-442c-a0bb-a1aa265c79b4	26	13:08-13:16	f
346	0171fa5b-a3a0-45d0-bb3c-acf79a927146	26	13:16-13:24	f
347	338b1848-2f56-4062-834e-df8eb8dd9080	26	13:24-13:32	f
348	0b65b277-3d48-407a-a87a-15851ad1a9f6	26	13:32-13:40	f
349	3d49c7bb-0da5-4336-b490-54c75fad5780	26	13:40-13:48	f
350	089ba55c-7dc7-47b1-aea7-010bf93d0067	26	13:48-13:56	f
351	be694beb-8dd4-4cdc-bcad-0195b4dac977	26	13:56-14:04	f
352	c0f8a033-2bc8-46c9-9ee5-c3908936d138	26	14:04-14:12	f
353	865ba51f-8ed6-4114-be35-adacbb350134	26	14:12-14:20	f
354	190ff13e-c030-4003-968c-b45bb0b1eba9	26	14:20-14:28	f
355	717d8dc1-7ed1-4e6c-8e2c-b530ae330af7	26	14:28-14:36	f
356	390bf485-0255-454f-baf7-9a3d8053fe1c	26	14:36-14:44	f
357	2e87697a-a7c5-45f5-9a42-8bf6cb112bef	26	14:44-14:52	f
358	f0693564-7184-47ad-9c92-511324a88d84	26	14:52-15:00	f
359	1081f30c-55b5-4d9f-b459-74cecc58a915	26	15:00-15:08	f
360	e8082fe6-d018-4812-998f-ba487dacf59c	26	15:08-15:16	f
361	c6fc9070-4e34-445c-95dc-ec88a9ce15a6	26	15:16-15:24	f
362	3226a19a-4ee2-4c21-9d54-99f9cf30e65e	26	15:24-15:32	f
363	f1105a88-74fb-4443-8912-ffa90e3e2f6a	26	15:32-15:40	f
364	335fd3b8-25fe-4050-a038-8226722c7fd7	26	15:40-15:48	f
365	6e325da6-d469-42e9-b9a9-8aa9ec95d0d0	26	15:48-15:56	f
366	98d8ab38-df5d-42c6-8799-aa0c1df67aa7	26	15:56-16:04	f
367	a44789f3-95b6-4c07-a4fb-dab67af93cd7	26	16:04-16:12	f
368	ee356383-8035-4356-a1dc-8110f0d04bb6	26	16:12-16:20	f
369	476038f7-4f6e-4340-a4f7-34015df3adb1	26	16:20-16:28	f
370	195999bf-1a99-4915-aa39-8f37272c00d3	26	16:28-16:36	f
371	90ca63e2-39d4-4e58-85a5-7683ed8602bf	26	16:36-16:44	f
372	2f6ef33a-99c4-4604-9559-5216ed751dc2	26	16:44-16:52	f
373	10f910ad-0db0-4edb-840e-b631b7685511	26	16:52-17:00	f
374	4c632f4f-180b-472f-8bd9-033c4ba90345	27	08:00-08:10	f
375	21c2c49f-ddf8-465b-8131-a07f7032c138	27	08:10-08:20	f
376	c47795ca-dde2-4ee6-bc60-fad5534fe822	27	08:20-08:30	f
377	a01bf7ee-8ba4-45e1-b9f9-3255b3b80e7d	27	08:30-08:40	f
378	e25bc579-8a82-4a9b-80fc-ad3b74740841	27	08:40-08:50	f
379	2bc7b3fd-2a7e-4fbf-95ac-3bc395f23cee	27	08:50-09:00	f
380	fe0ae863-f198-48fc-bfdb-d52950403a73	27	09:00-09:10	f
381	238295e4-e084-4fcd-8ad2-e9a4cfe820b3	27	09:10-09:20	f
382	2215a93b-0345-433f-832d-1e0e7e1da53f	27	09:20-09:30	f
383	4a1c77a2-fd6e-4942-b262-a9faa2252e76	27	09:30-09:40	f
384	0e262387-0e30-4df1-9aa8-b7381e6e8f74	27	09:40-09:50	f
385	2b1d9a87-5d5e-4b6f-9972-d23d375816e6	27	09:50-10:00	f
386	40ee7d10-e2fb-4c91-a9c3-8b00550371a0	27	10:00-10:10	f
387	6e14df0f-ef52-4143-a846-b0aba6e23c49	27	10:10-10:20	f
388	4bb37368-015b-42fd-9259-657b0ef10d5b	27	10:20-10:30	f
389	a4080c0c-340e-4a29-afea-cb00c92ff6ef	27	10:30-10:40	f
390	dce503da-885d-47e5-ba2f-d8661acd1dff	27	10:40-10:50	f
391	0ad753d1-e127-41b4-a2ef-15642bf051b5	27	10:50-11:00	f
392	b6302a60-5172-46ed-9a17-e9f061093e79	27	11:00-11:10	f
393	54dd1419-ac74-46ba-8855-e0f89e06a2fb	27	11:10-11:20	f
394	d1ab72da-9f03-4c33-859d-b90df54f3022	27	11:20-11:30	f
395	72927754-8e8c-44f2-a144-e2006d0724da	27	11:30-11:40	f
396	8946ca03-8420-4945-ad9b-e1548dfb91d0	27	11:40-11:50	f
397	9f30ccc1-3742-4bdb-b645-a7a876523262	27	11:50-12:00	f
398	520ad351-4037-4064-9d64-f613f90d30b1	27	12:00-12:10	f
399	38a755b9-a591-4548-975a-1bdb07fdc6c6	27	12:10-12:20	f
400	e20b37f7-0ec3-4240-bd50-77140353c68e	27	12:20-12:30	f
401	6067cef8-8624-46a5-8ee5-b3f82da24ce2	27	12:30-12:40	f
402	3460f5ba-8d31-4297-aa0d-64533fdfb442	27	12:40-12:50	f
403	b87193f0-6cde-47f1-9ae3-66cc5be2a830	27	12:50-13:00	f
404	af3c4bc1-f827-4b63-8d9f-2659cb5541bf	27	13:00-13:10	f
405	d80a5745-d1ab-4925-b7a5-a45582daeca4	27	13:10-13:20	f
406	81108db6-0e5f-44ef-ac13-0c4d028ab0b9	27	13:20-13:30	f
407	bbd6e175-6c2f-46e4-9b2b-000be76f6e9e	27	13:30-13:40	f
408	af4fdcfe-13aa-452a-8d51-9b4b96899877	27	13:40-13:50	f
409	ee104aa3-656f-47aa-8bae-ab66a1a8c616	27	13:50-14:00	f
410	3fa3ab94-fd50-447d-bf8f-b2659e736a5d	27	14:00-14:10	f
411	ec82a3ab-773f-435d-bf1d-bc3ebea624a5	27	14:10-14:20	f
412	a474ea9c-111f-426a-bbf7-495775980532	27	14:20-14:30	f
413	73ebdd39-aa6b-48a6-bbce-0da1f9c32d73	27	14:30-14:40	f
414	90354a6d-071a-4a8e-bdf3-f0bb7038a89f	27	14:40-14:50	f
415	ec6a5c92-aecc-41cb-ab80-fd6a6d0a65bd	27	14:50-15:00	f
465	c1a7a318-c5e1-482e-ae0a-59bf480f9cfe	29	14:28-14:36	f
466	40959c60-2f1d-4f6f-9870-e31decc133ee	29	14:36-14:44	f
467	899ea582-060f-4298-8de6-033dfbb86a64	29	14:44-14:52	f
468	12537d2b-0e39-4905-8403-ef839b9601c8	29	14:52-15:00	f
469	2c1cbd98-577e-41ee-a188-532d7de9f5a0	29	15:00-15:08	f
470	35ce4731-1064-42af-9020-628c391532f1	29	15:08-15:16	f
471	9f59f361-6543-47a2-ada5-ff7dc46cbc5e	29	15:16-15:24	f
472	6cdb2587-160b-4af3-9942-fe5ef171e1db	29	15:24-15:32	f
473	2345c962-1073-4c5a-8263-e60db4a26758	29	15:32-15:40	f
474	45d5b188-78f2-43db-afee-931e2f68e7c3	29	15:40-15:48	f
475	444824d3-eec0-4d98-8dff-8ba0a6e32d5e	29	15:48-15:56	f
476	162a0467-57d9-471a-84a8-3eafa4d324ed	29	15:56-16:04	f
477	a0a44502-e6a0-4ec2-9e10-b8f173818918	29	16:04-16:12	f
478	090f5dd6-514b-49dd-9521-86dd9b92f7c8	29	16:12-16:20	f
479	e8d477ae-69e6-4bf0-92a1-a3fdaa4733bb	29	16:20-16:28	f
480	5c88f6f2-23a4-4c43-af4a-35b267c33d26	29	16:28-16:36	f
481	e7faf5c0-6170-4e3b-bf7f-d9d17eb851c3	29	16:36-16:44	f
482	7bc2aee0-db70-4661-87d5-5d126b49331b	29	16:44-16:52	f
483	a61937d9-c9bd-4e20-84b7-a8687ce7bf7b	29	16:52-17:00	f
484	1b7390bf-c59e-4e05-bf77-2bdbbec51e80	30	08:00-08:08	f
485	959b4cf8-a1b5-405c-8077-589e2a85e34f	30	08:08-08:16	f
486	32f8e57c-7e08-41f0-b2f1-e9685f9851fc	30	08:16-08:24	f
487	4b19c790-854a-4610-bb49-27ac97271cb7	30	08:24-08:32	f
488	d4779f55-3021-4dd0-9d4a-fdac14e15ac8	30	08:32-08:40	f
489	7bd42006-1f7b-46d8-ae1a-6411f726b175	30	08:40-08:48	f
490	71d80d08-3ae4-4c27-baf3-835b79c2ca96	30	08:48-08:56	f
491	f969888f-c0bf-4f41-b181-0b9b9dab0669	30	08:56-09:04	f
492	5bee8a46-9f1e-427a-a647-c26a24673c15	30	09:04-09:12	f
493	c81d8fcc-db76-439b-9941-18a8ee934436	30	09:12-09:20	f
494	20cbcea8-62bf-45e1-b149-2d26066af20f	30	09:20-09:28	f
495	d826262a-3ab3-4302-bda9-ccb882374db9	30	09:28-09:36	f
496	c8a4fb17-5e29-4743-aaed-1c9758456a14	30	09:36-09:44	f
497	b3f0ce31-3f03-4d00-b172-d4f0f1b63527	30	09:44-09:52	f
498	e58962ad-1fa4-41a1-8d5e-430a19cbd581	30	09:52-10:00	f
499	560257fe-6449-46fc-b2c2-9ae62718716d	30	10:00-10:08	f
500	0638c186-7125-474f-9506-c24ca6faa02f	30	10:08-10:16	f
501	fd8865c4-a8e2-4469-967b-590d247ddbcc	30	10:16-10:24	f
502	1720ea79-8f28-4528-89d3-3a996d84d058	30	10:24-10:32	f
503	9a90a2c5-d60e-4593-b4e6-fd9d5356994f	30	10:32-10:40	f
504	7dca4b4d-6079-4d35-a374-b4fffd0ca802	30	10:40-10:48	f
505	3343185b-314e-4f98-a7a0-f1abba44bbb4	30	10:48-10:56	f
506	1db957cc-e85a-49d0-95d4-09bb25af16c1	30	10:56-11:04	f
507	f6ff7715-23c8-4c6e-95e9-4b8cdb0d2048	30	11:04-11:12	f
508	9561f1a1-a89d-4022-8d79-7aeabbe69cb0	30	11:12-11:20	f
509	e2be623d-613d-4ba2-8295-d8df7f885b27	30	11:20-11:28	f
510	cf0701b2-45c7-454c-980d-bc26de53c9b1	30	11:28-11:36	f
511	16e681a1-53c7-4bf6-9600-43627e46317f	30	11:36-11:44	f
512	62e7157f-7c4a-4258-9dee-8354977d19b7	30	11:44-11:52	f
513	06e17a4a-071a-45cb-bf99-76bd2d80675c	30	11:52-12:00	f
514	cfe1dfdd-4d5b-4af8-b3b7-8859ac121a84	31	13:00-13:08	f
515	121ecf8c-b0f7-4fd1-b7f1-577322c2cfc8	31	13:08-13:16	f
516	53a7c77d-b69c-4fca-b518-2de1600cc816	31	13:16-13:24	f
517	73b14c09-01a5-4788-895b-919fed4ef6c4	31	13:24-13:32	f
518	7ac87a48-b862-4a57-a908-eee9368c8e84	31	13:32-13:40	f
519	403c70d0-3345-477a-8946-2c8bbf8de8dd	31	13:40-13:48	f
520	2d0c91cf-3c17-418a-9c22-8533bbc74e9b	31	13:48-13:56	f
521	07ece6e0-4cf5-4be7-ae57-eececa5db155	31	13:56-14:04	f
522	37c5c5e0-a82e-4738-ac87-22e45080955a	31	14:04-14:12	f
523	28b2b725-99a4-477f-a883-7b98ab45fc41	31	14:12-14:20	f
524	6dbfc529-0c7d-4910-8da9-707ec8d0f495	31	14:20-14:28	f
525	bb6671db-5a47-4b11-b726-150fa29f5aed	31	14:28-14:36	f
526	a042a821-5668-4f59-9eb5-0bac2db5b85b	31	14:36-14:44	f
527	9b621da5-48a8-4c4d-952d-346d3ae9a3f7	31	14:44-14:52	f
528	c0505a4f-2b4c-416a-a25b-8c1d003ececc	31	14:52-15:00	f
529	160d0e8d-a50c-4cd8-bdf8-2a2c3cd31cdf	31	15:00-15:08	f
530	d8e264b6-9040-44d8-b4e0-f538f3ecb113	31	15:08-15:16	f
531	0ce22ad0-2f1c-46e1-946f-3795f357566f	31	15:16-15:24	f
532	dd61ebc3-2e17-47f4-995b-fb61dc8598f0	31	15:24-15:32	f
533	4fee9458-a4f7-4f43-8d1d-e1aa5dfc90e5	31	15:32-15:40	f
534	3a6cc58b-2562-4491-a9cd-2678977d2532	31	15:40-15:48	f
535	34565c79-c97d-431d-baf7-1fd6f7d0b030	31	15:48-15:56	f
536	943611c3-088f-46e3-9e96-4130d2f9d6b4	31	15:56-16:04	f
537	13522387-7b0d-4a91-bba0-23e9995c1203	31	16:04-16:12	f
538	fe2dddaf-31eb-4c9f-8527-3e6efef946fa	31	16:12-16:20	f
539	2ecbfb34-36fc-4d6b-8d42-4d6cf321c87c	31	16:20-16:28	f
540	42643067-442e-4d65-9204-caeec6f58006	31	16:28-16:36	f
541	cfb43dc8-453b-4fcc-8792-e2306881922c	31	16:36-16:44	f
542	7e0167bd-7207-4d36-829d-d23374843f3b	31	16:44-16:52	f
543	3ca66aeb-ac59-49b5-8548-b7098f871e85	31	16:52-17:00	f
544	f700134c-7fb2-485e-b892-5ec4871e6976	32	08:00-08:08	f
545	15fea15f-9ca0-43f8-8e78-1b56205fd2d3	32	08:08-08:16	f
546	77768446-a43d-40ff-9e5f-d077b0d6f0ec	32	08:16-08:24	f
547	c80730f0-dbd2-4928-a8d0-2d08c61220ed	32	08:24-08:32	f
548	2c92c395-1311-4cd4-a9db-a854469653fa	32	08:32-08:40	f
549	03fade16-3083-47d6-94dc-cba31933acaf	32	08:40-08:48	f
550	1bdd82af-24f5-4288-ab65-e91b9038f3e4	32	08:48-08:56	f
551	7f507110-81e1-4ebf-8206-990f7dd2a187	32	08:56-09:04	f
552	fd748c32-b858-45fb-84f2-17138cbf293c	32	09:04-09:12	f
553	ca1da0c5-e8c7-4d91-987f-01ff37c555de	32	09:12-09:20	f
554	3cb6747c-7a2f-464c-80c1-38a6fd564262	32	09:20-09:28	f
555	f4dcdc76-909d-4fa1-959f-e630ac89b20b	32	09:28-09:36	f
556	93f1c807-20db-4cd5-89f7-00b7ff3812dd	32	09:36-09:44	f
557	3e50b9f8-4de8-460d-b51b-fcc7bcabe060	32	09:44-09:52	f
558	9e2625f8-9d4c-42ec-9551-f7a897fe38a0	32	09:52-10:00	f
559	a460ccd4-09b3-4dd9-abe1-7dcd8feaa555	32	10:00-10:08	f
560	53718776-2068-453b-837f-c988f72ebb73	32	10:08-10:16	f
561	d8d63fb3-09c0-4891-b702-0c1fca903bf7	32	10:16-10:24	f
562	e403ffda-4279-4939-a76f-cd575e54571f	32	10:24-10:32	f
563	ba1ea07b-0c93-4b9c-a9cc-8074d84d14fa	32	10:32-10:40	f
564	b72a915e-f4b6-4d51-be64-bf62b345424f	32	10:40-10:48	f
565	7ab5d5b7-64a4-421f-abf0-4425379caf65	32	10:48-10:56	f
566	d0bea902-26d3-4f9b-b3a6-14125ae3eac6	32	10:56-11:04	f
567	77f7c566-a2f6-4ef7-afed-71aea7b8db1f	32	11:04-11:12	f
568	73311fb6-c5c7-4486-8e7d-f99d0d3d741e	32	11:12-11:20	f
569	e16583aa-8a8b-4865-aef3-755cdc34c270	32	11:20-11:28	f
570	5c0583be-6d4b-4aa3-a2c4-c400339740e4	32	11:28-11:36	f
571	6f5eae53-5cdf-4541-9b6d-09ec466dfee3	32	11:36-11:44	f
572	b309114d-52e7-4027-af1c-7cd8702b52f7	32	11:44-11:52	f
573	862a61d7-9034-44e9-84aa-38fa23c05e69	32	11:52-12:00	f
574	e3361653-b083-4403-be6a-adbcf87f2124	33	13:00-13:08	f
575	4a6e2712-4102-4096-b406-1e84771c00c7	33	13:08-13:16	f
576	4f0f5f2d-5175-47d1-ac25-4c47ce0ecadb	33	13:16-13:24	f
577	6320311a-2571-4be4-977c-5212e1e9dc58	33	13:24-13:32	f
578	c77c1773-f384-457f-92f0-acb8d91aa5f4	33	13:32-13:40	f
579	4f56aa80-e184-4390-9f7a-212eba44c407	33	13:40-13:48	f
580	17a77e69-8c05-4d75-bbf8-0ea22dc92afd	33	13:48-13:56	f
581	eca5b8d8-0f13-408c-9270-bedb2a5807c7	33	13:56-14:04	f
582	546423d9-a2d5-4ad3-aed3-0dafb6becf5e	33	14:04-14:12	f
583	b248ac59-3b1d-433a-b129-e6a689a38a60	33	14:12-14:20	f
584	3e80e623-9c88-42d6-b0ca-66b9deb46a70	33	14:20-14:28	f
585	58c9af4b-972d-4fdd-b27f-8b8857a4c0b3	33	14:28-14:36	f
586	af549731-2885-42f7-a976-71e5c26d6ab9	33	14:36-14:44	f
587	50847f7d-daf0-4f20-a665-0ee7178926d7	33	14:44-14:52	f
588	6015b844-ccc2-4648-93ce-dab837a3f9af	33	14:52-15:00	f
589	3b316ea3-77bb-46c5-8078-d786f8572119	33	15:00-15:08	f
590	aaa7de41-9b3e-441d-af22-ee8dd2e4b475	33	15:08-15:16	f
591	64981116-cf95-47bc-9de5-8ac948b9bf51	33	15:16-15:24	f
592	4d7dfcbb-505e-45ba-a30f-12d9b65715ef	33	15:24-15:32	f
593	9b0f5cb4-c458-46d1-9d07-a801552ddec9	33	15:32-15:40	f
594	a035d740-dcce-4592-864f-8c9e53e2ac8a	33	15:40-15:48	f
595	ff4a0ee5-8802-446c-8709-d5222f55195f	33	15:48-15:56	f
596	194cf077-7c11-4d04-9970-e276ac3b37fa	33	15:56-16:04	f
597	c10c0c77-ac38-4dfe-8289-c13da86cc381	33	16:04-16:12	f
598	ff7d4a71-fb6f-4273-a5c5-4cee4b669449	33	16:12-16:20	f
599	2d592c01-8d69-4272-b8d8-717e1ae47d38	33	16:20-16:28	f
600	a9884a68-fcad-4361-ac46-541ee2ae4527	33	16:28-16:36	f
601	d011338d-3afd-4873-8fb8-64764565b005	33	16:36-16:44	f
602	72f3ca9d-974f-4715-ad9b-05cc0a2ad566	33	16:44-16:52	f
603	2283397f-c900-45de-b9a1-529f416ac615	33	16:52-17:00	f
604	96b507be-a6ab-406b-bf6f-309f12101aca	34	08:00-08:08	f
605	5661380a-f4d4-4fdd-9625-a5cbe99ee974	34	08:08-08:16	f
606	293f4c08-2c0a-4e75-9a5e-bc656b1db951	34	08:16-08:24	f
607	fa5b6c26-2f5c-4f0c-bea8-5a973e76b7de	34	08:24-08:32	f
608	ac94a8cc-1b17-4fc8-a9ab-099ea1c2dfd1	34	08:32-08:40	f
609	65301756-d65e-4c58-8508-dff21dd3931c	34	08:40-08:48	f
610	80ddc1a2-fa1a-49cc-8d35-e2857bfc625d	34	08:48-08:56	f
611	c1ae5ad5-161c-47d7-8d6e-fc461258adc4	34	08:56-09:04	f
612	093685a7-7c33-403e-88f8-5e1d7cb3f485	34	09:04-09:12	f
613	d97906c9-ebf5-45ac-bde9-98c56cd94904	34	09:12-09:20	f
614	9d22c499-3252-452f-9a6f-30f2e5ad7a30	34	09:20-09:28	f
615	d7ec191d-15f8-425a-934d-e21edaa6006b	34	09:28-09:36	f
616	c37fb53b-5136-4608-a908-bf9cdb772b00	34	09:36-09:44	f
617	ef5acaa0-e31a-4100-ab49-36c69269edcc	34	09:44-09:52	f
618	1ce83f06-b525-430f-bcbc-706c90f2896c	34	09:52-10:00	f
619	236b7686-f9ce-4fc9-b13a-0fc2caa4c56a	34	10:00-10:08	f
620	0061d918-3fc5-4487-b12a-70bedfc62146	34	10:08-10:16	f
621	f9c9df01-cb34-43ec-9bd0-e200674e5a49	34	10:16-10:24	f
622	fb497c67-c867-474f-8a6c-eaa3ab6f3836	34	10:24-10:32	f
623	0f2f91f6-a5ec-47c2-bb4d-34f1c94bd91d	34	10:32-10:40	f
624	b953ebcf-c8ad-4bc8-8fa7-b8bbfbc4ac89	34	10:40-10:48	f
625	2cc37163-9e8f-437f-899f-2bdc27ab3f19	34	10:48-10:56	f
626	c37244c0-0a3e-4887-80fb-b34b0d2125b5	34	10:56-11:04	f
627	1b09bf98-632e-4b7b-a926-7aded0df9202	34	11:04-11:12	f
628	007270f3-87f3-4be9-833d-3b33751ae384	34	11:12-11:20	f
629	2e1620a4-1895-458c-a698-4cfaf7dea217	34	11:20-11:28	f
630	02318e3e-261c-41da-99b8-70aff9dbaa69	34	11:28-11:36	f
631	d0ec5cfe-d997-455c-ba04-74187c994639	34	11:36-11:44	f
632	f00d8611-7781-4527-b6d3-791479ebba84	34	11:44-11:52	f
633	6c594757-d26d-423c-9c80-8b6f0f801a3f	34	11:52-12:00	f
634	1a1611eb-4e10-4cea-952d-4c56c92529b4	35	13:00-13:08	f
635	ae23963b-2067-400d-a41a-e602d1609ea4	35	13:08-13:16	f
636	124ce18b-bce3-4c1a-a417-67b2869249cf	35	13:16-13:24	f
637	3f5aa119-4b55-437e-8b00-aedf2554d27b	35	13:24-13:32	f
638	7e5a58f2-97e9-4ed1-ad1e-62c3a14cb03d	35	13:32-13:40	f
639	0558cb89-37d3-4015-a569-273e2a4f576f	35	13:40-13:48	f
640	b8a57adc-5543-4652-a64e-b14b6169640f	35	13:48-13:56	f
641	d2b78619-38fc-4616-89b6-fe0c0eb0fcf1	35	13:56-14:04	f
642	220e98cb-9c15-4f33-b6e4-79db89b4b87a	35	14:04-14:12	f
643	3890939a-ea64-4a0f-9ef6-6b0b1d4ce2e6	35	14:12-14:20	f
644	9ef34a47-8d20-491f-b600-a7857e22fc12	35	14:20-14:28	f
645	fecc842f-326b-4e16-9c00-5d1c02664cb5	35	14:28-14:36	f
646	e07329fe-41e8-4669-9902-47ac69efa2d9	35	14:36-14:44	f
647	1f2c4cc7-4473-4849-b4ea-e8e1c0d147ae	35	14:44-14:52	f
648	16daf7e6-3e8d-4d2b-b292-35613f60d8fe	35	14:52-15:00	f
649	44bed579-1075-4aac-983b-8e23a58c28f4	35	15:00-15:08	f
650	f5198603-aeab-4237-84a0-104b173a6edf	35	15:08-15:16	f
651	4657877c-c34e-4999-937d-71bdc8168281	35	15:16-15:24	f
652	eaa38ba6-0bb1-46f3-b9cc-f41eab57d62b	35	15:24-15:32	f
653	ac8938d3-a7e9-4235-85d0-b0a02cd505b1	35	15:32-15:40	f
654	07dff2f3-69f4-4edc-820a-b4f6c3847d63	35	15:40-15:48	f
655	51a6e1f2-2780-4362-adaf-c4c01cb16012	35	15:48-15:56	f
656	d3769b39-02b4-41e4-8a83-9c8fa3c3739e	35	15:56-16:04	f
657	9bca06d1-2a5c-4f5b-a070-c6fd85b69f0d	35	16:04-16:12	f
658	44b0381b-cd81-4adb-880d-73f6a9b04f92	35	16:12-16:20	f
659	3a66f3e8-98ac-46a2-82f8-62fbd29d5115	35	16:20-16:28	f
660	9ef62f68-e685-47cd-aa2c-decf482d9d62	35	16:28-16:36	f
661	de537895-75b6-4acb-a3ce-317fb52b8cb6	35	16:36-16:44	f
662	1d211237-9273-434c-a598-743e1bffed73	35	16:44-16:52	f
663	34a36b81-bc60-428b-b7bf-27a74338d7e0	35	16:52-17:00	f
664	3f72b766-3d53-4709-9cf0-c78eabca62ea	36	08:00-08:08	f
665	95788fac-dfef-4594-b284-b7bb715af5f6	36	08:08-08:16	f
666	f987dde9-91b3-40c5-8aba-ace501e34ee8	36	08:16-08:24	f
667	56032cd3-1e89-41fd-8e8f-f1af9591c345	36	08:24-08:32	f
668	c2759b01-6200-4930-988b-30653c17b65f	36	08:32-08:40	f
669	678f6732-cc34-41bd-ad24-8073a6017a72	36	08:40-08:48	f
670	3ef8820a-149b-4087-a046-e514b80595ba	36	08:48-08:56	f
671	82b2d068-7ecc-465a-a2c3-71ee67080379	36	08:56-09:04	f
672	863f5a54-d2fc-40dc-8c3c-51c46ef9d948	36	09:04-09:12	f
673	e08acca6-c600-4770-8776-9b571814716b	36	09:12-09:20	f
674	b62b68e4-1c76-45f8-9264-ab882e0c1051	36	09:20-09:28	f
675	e039fd7f-a714-4f3a-9fa1-ab4509307bf5	36	09:28-09:36	f
676	5dcb1d9c-cfb3-40ff-a810-c403bbc83fa0	36	09:36-09:44	f
677	bf5ad82a-34ba-4555-b615-809bb9ed6c9b	36	09:44-09:52	f
678	2674dc98-e36a-470b-88a0-cf51cc873c36	36	09:52-10:00	f
679	9fcf0f67-d699-439c-845c-a1c78af74ad8	36	10:00-10:08	f
680	fac22113-d767-46fd-80d7-68706fd99f71	36	10:08-10:16	f
681	9d40c8eb-522e-4ccf-a6cc-0d61929a8e05	36	10:16-10:24	f
682	6633eca0-1e39-4dfc-9757-6dd859112f37	36	10:24-10:32	f
683	9827a2be-eee1-413d-b578-2234649990b3	36	10:32-10:40	f
684	f3e10448-44da-4563-9c5f-2fb4af10346d	36	10:40-10:48	f
685	8ab5a74b-4c57-4d22-9f21-3000303e89c2	36	10:48-10:56	f
686	e3e0bd8c-e382-4e85-8c1a-38c4c22d8bbb	36	10:56-11:04	f
687	e18ceaae-c752-496c-8d7f-910bbde12a3e	36	11:04-11:12	f
688	9d7a4e4b-d5ec-42ec-af31-10e67322b476	36	11:12-11:20	f
689	d1d2dbdb-07b3-4705-97e1-ad472fddad73	36	11:20-11:28	f
690	7e702126-aa11-4f43-be20-41431aa06f38	36	11:28-11:36	f
691	eb763f77-49f0-4ceb-82e6-994ccbedb2f8	36	11:36-11:44	f
692	147de8f0-7cbe-4d66-b6e3-a1eec0bc4658	36	11:44-11:52	f
693	37d6e988-adb9-4925-ab73-eaa7033d5045	36	11:52-12:00	f
694	15259756-a9b7-42de-8d68-b93ec0c46715	37	13:00-13:08	f
695	86bff957-d2a9-458b-94b9-c1942d5dc582	37	13:08-13:16	f
696	56f223f5-a190-487f-b3c6-75ce4eff8e22	37	13:16-13:24	f
697	88bfc3cc-c819-49ac-b320-864e03455e5d	37	13:24-13:32	f
698	e08c174f-9495-406e-9424-061753c97fc0	37	13:32-13:40	f
699	6d26d120-d4a5-413e-8ee9-c99d738bc92e	37	13:40-13:48	f
700	2daf4cab-57a9-489a-a3bd-1164b78bce74	37	13:48-13:56	f
701	90658d05-788a-4fb8-9813-dbcfa3b69fe6	37	13:56-14:04	f
702	72bcd885-d863-4015-9e26-a12940efb66e	37	14:04-14:12	f
703	224f586b-43b7-4432-94ab-8a162540797e	37	14:12-14:20	f
704	a8bc108e-d66b-40f1-b2af-acbedff8dcba	37	14:20-14:28	f
705	6f9bbf9d-683c-4a97-8c05-67097124ae30	37	14:28-14:36	f
706	283582d2-bf89-4a3c-b140-29f1a158fb52	37	14:36-14:44	f
707	19840ca8-1088-4e2a-b2ed-03fa94d6c8fe	37	14:44-14:52	f
708	8df9d802-244e-41ba-b11b-f51bf9b68342	37	14:52-15:00	f
709	982e9f50-72c5-493d-8e4f-735716da5383	37	15:00-15:08	f
710	ea9fe07a-e6d1-4131-a6f0-300fc4aba130	37	15:08-15:16	f
711	da0e9048-dc95-45cc-b95b-13951b83d8d8	37	15:16-15:24	f
712	64925741-0697-4949-b609-834a4a2c76de	37	15:24-15:32	f
713	d2d3921d-d629-49c1-8cdd-1c79444ada65	37	15:32-15:40	f
714	8dbd7d65-ad8b-448c-afa3-4b075daa6251	37	15:40-15:48	f
715	467bfa54-080e-44ed-a939-f47222759c4d	37	15:48-15:56	f
716	818ba5bc-b6b6-411d-a807-c43bed261a6b	37	15:56-16:04	f
717	04e91f70-5a31-4db9-8513-d724c6cde441	37	16:04-16:12	f
718	03c09460-aa92-428a-80b8-b8a11711b970	37	16:12-16:20	f
719	6bddc5cd-8dce-4eaf-a672-0e4177a359fd	37	16:20-16:28	f
720	7e42f72c-3b4c-4ed1-8d71-4cc700e25552	37	16:28-16:36	f
721	50b6bb96-017a-4663-b494-e3d1c2bb5f4c	37	16:36-16:44	f
722	df95cb1b-2847-4921-aee1-e0cff31ff505	37	16:44-16:52	f
723	c0f1b0ee-b8cd-40f3-b53c-f4c119182904	37	16:52-17:00	f
724	3acb4e5d-183e-4748-b0b7-b1d16f8b893d	38	08:00-08:08	f
725	cb25a9fc-b45d-474b-954c-34c3f402bef0	38	08:08-08:16	f
726	81cbe509-8f0c-4bf1-bd91-91fcc78afdf2	38	08:16-08:24	f
727	9af95290-5c7f-4a16-848d-420700bb6b3c	38	08:24-08:32	f
728	f7a81a6a-17b1-419b-8538-b0a0bfe15c3e	38	08:32-08:40	f
729	2e4aab14-0965-47ea-be69-7ea5abb8a5c5	38	08:40-08:48	f
730	f8c12055-4916-4cca-b9b9-230ec330735c	38	08:48-08:56	f
731	0cb8af8a-536a-40bb-9964-9d5357d83958	38	08:56-09:04	f
732	f189c5c2-8c72-4d31-9135-5bcdb9016059	38	09:04-09:12	f
733	6acab325-0d05-4f57-80e9-3f2900132bdd	38	09:12-09:20	f
734	d2ad4a87-94e1-4cc8-a571-a845d860b233	38	09:20-09:28	f
735	01f8d166-8081-42ce-b099-27d4b1ec1177	38	09:28-09:36	f
736	1e194a8f-0907-4f5c-88b5-3ab3d16c5de9	38	09:36-09:44	f
737	3bcafc1e-f59f-46fe-ba89-d791d82edb24	38	09:44-09:52	f
738	d6cc7675-61e6-4913-9959-259a7e5e8ddc	38	09:52-10:00	f
739	2d1f0412-14e8-4d39-854d-f44c29bcec31	38	10:00-10:08	f
740	60c09f1e-c1c8-4654-87af-63b3db07bc00	38	10:08-10:16	f
741	cc46c0ea-9561-4b83-8c90-851e9148c886	38	10:16-10:24	f
742	703ec3f3-a6c8-479c-9f87-4f56f01e40e6	38	10:24-10:32	f
743	6f22dde1-f53c-4c84-a3ed-e7b718547bab	38	10:32-10:40	f
744	f8327d1d-2122-4ea8-9b6e-02be05c79e00	38	10:40-10:48	f
745	561da5f2-0ed9-483b-b784-6cc2d6e61f72	38	10:48-10:56	f
746	b528f677-483e-492b-85d7-f9c2ff86a1a1	38	10:56-11:04	f
747	35ce617b-2345-4474-a41b-1fc99a278850	38	11:04-11:12	f
748	5a2d9988-3b54-4f44-88ac-266dec80ec4c	38	11:12-11:20	f
749	82bdb3fa-ff25-43e5-b9de-64ff7a821bc3	38	11:20-11:28	f
750	6a5b1052-a648-44de-9d8f-12cb17f35bdc	38	11:28-11:36	f
751	a0a922b2-5928-49e2-99cb-d5d5595f817b	38	11:36-11:44	f
752	125db42b-5fce-4bb3-8a5c-5b010b6805f9	38	11:44-11:52	f
753	05ed1924-4344-4d4e-906b-0272d73ff999	38	11:52-12:00	f
754	a1a224cf-b83c-4165-ac9c-62fc6bdbcd40	39	13:00-13:08	f
755	ba750ccb-0799-4e0f-bd02-37decf04aff5	39	13:08-13:16	f
756	58c906d6-0f13-4385-9b94-d15c3ba85efe	39	13:16-13:24	f
757	a5b1fafc-c6f2-409c-823f-47d91cd87fb8	39	13:24-13:32	f
758	d6d03cc6-ee1a-4942-9f6b-82b86c88663b	39	13:32-13:40	f
759	ddebba5f-9c36-41d9-8e4b-09369170c0e5	39	13:40-13:48	f
760	ce01314d-9e3c-48bc-8857-4cf73bd3212f	39	13:48-13:56	f
761	1c860d59-28f7-47b8-a150-a8cd67ef830b	39	13:56-14:04	f
762	6d1a0f88-7c92-480d-a589-bc2cdac113cc	39	14:04-14:12	f
763	fc826e33-d1e4-4fb6-bca7-e5d60215a5a5	39	14:12-14:20	f
764	7f4e9e2c-bea2-477c-936e-a140b64ec26f	39	14:20-14:28	f
765	5fbe2297-51cd-4edc-aa39-227492207418	39	14:28-14:36	f
766	4b776f3e-3a00-446e-8197-07b1a2332c67	39	14:36-14:44	f
767	b347d944-058d-40fa-b77f-a2892e66eeb6	39	14:44-14:52	f
768	86fefc8a-b58f-454c-a8cc-066f1e730ca3	39	14:52-15:00	f
769	d29c4f46-9856-4894-9196-0064b46dddd4	39	15:00-15:08	f
770	1ddfb149-e4fd-4fe8-87fb-945badfdbf8c	39	15:08-15:16	f
771	b0f0c64c-f26b-4a04-bd4e-6945133c6084	39	15:16-15:24	f
772	53242896-bee2-46f4-8ac9-ac8104a793b0	39	15:24-15:32	f
773	cc48ac1b-21f6-44e1-93a3-d94ce903f27b	39	15:32-15:40	f
774	1a4c27d4-bb37-41cf-b350-036f96a661a8	39	15:40-15:48	f
775	ac7309d3-4c7a-4eff-9d97-1a83bb9fadb0	39	15:48-15:56	f
776	6f9580e2-2929-495b-9d0b-17bd089998c6	39	15:56-16:04	f
777	38195883-81ad-47b3-94cc-83fe3dbff4e1	39	16:04-16:12	f
778	0ff076e2-ca37-474e-b6b8-8bfd327a6f37	39	16:12-16:20	f
779	b599404d-7d19-41a0-8d23-6248408b2fd8	39	16:20-16:28	f
780	94335b2b-7ed0-4276-9d31-ebec797eed80	39	16:28-16:36	f
781	965bb33b-96a4-4aeb-b34e-bbc876e2e3a4	39	16:36-16:44	f
782	7b8d9100-6067-4564-9946-12722d1b3991	39	16:44-16:52	f
783	d5804a01-975a-4c61-9d63-990dbe206671	39	16:52-17:00	f
784	90ed6fdb-9a61-49f6-b0bb-8aea9804264a	40	13:00-13:08	f
785	b4c09fc9-46d9-4191-82ad-e9feddbdec98	40	13:08-13:16	f
786	1e192afd-a07e-42dd-a8b5-714c293e6d96	40	13:16-13:24	f
787	35cc034b-3c77-45a9-9b42-ea2ef83af763	40	13:24-13:32	f
788	62600aa6-1234-4cfc-aef9-ee95751d97b6	40	13:32-13:40	f
789	4a551ee1-361b-4637-970e-a3826c1bbfcb	40	13:40-13:48	f
790	f0f2bfdd-a88c-45fa-9d74-10b12cf79a95	40	13:48-13:56	f
791	ce647d33-45cc-4dbe-87c6-0ae19b15b237	40	13:56-14:04	f
792	33ef2037-ed06-4ab6-8e2c-580cddc06d88	40	14:04-14:12	f
793	b0d2bee1-1727-43b5-acfb-99626205f7da	40	14:12-14:20	f
794	cd8ecbdb-abd0-491f-a436-8173a0b664a6	40	14:20-14:28	f
795	5597f3c5-84e8-4d02-a9e5-3566b9698beb	40	14:28-14:36	f
796	c11675d4-ade7-4ac9-aa2c-37e554453d17	40	14:36-14:44	f
797	cae81a7c-3885-4646-837a-a3f601c7d239	40	14:44-14:52	f
798	b6ac5671-7885-4443-a0cd-21f4f406f5d4	40	14:52-15:00	f
799	413fc0e5-9b07-4969-8fba-df6baaef48dc	40	15:00-15:08	f
800	5b4662ae-5717-4f05-8d1d-04ea08c1499c	40	15:08-15:16	f
801	72948cf8-6982-4867-b776-97246c4f3d67	40	15:16-15:24	f
802	a3066012-7f7e-4e18-8481-bf113450b98e	40	15:24-15:32	f
803	54c223e7-d799-4e9c-9a16-f7a8be1e7df1	40	15:32-15:40	f
804	b6c92bcc-c943-4357-9f55-c9aba9440212	40	15:40-15:48	f
805	40f8ec3c-394f-4b3e-9425-a93bbcaf5835	40	15:48-15:56	f
806	6d39b47d-280f-4827-9723-d99075e24150	40	15:56-16:04	f
807	4d9a40b0-1720-436e-99c0-b58096c591a7	40	16:04-16:12	f
808	74625333-e119-40b3-a8bd-0e67ad26d07c	40	16:12-16:20	f
809	cfb64c1a-1f9b-4213-9af0-945b668c3e24	40	16:20-16:28	f
810	2bd1b511-5bc5-4fb7-807a-38a724e7716d	40	16:28-16:36	f
811	47b645ea-419a-4ba5-81bb-e5b363f369b0	40	16:36-16:44	f
812	61d44e37-988f-41eb-bde2-44e1070950e7	40	16:44-16:52	f
813	8e18f822-4175-43e6-bb84-2ee6cc84cc2b	40	16:52-17:00	f
814	dd6f1674-6beb-4258-a10a-d938fc06e8fc	41	13:00-13:08	f
815	992f49a7-be10-4d78-812a-75a8d8317a80	41	13:08-13:16	f
816	bd9450f4-861e-40b9-b353-d434fbc2c2af	41	13:16-13:24	f
817	7c0ede60-84c0-4ff3-9766-46916242ab83	41	13:24-13:32	f
818	972f777d-02f0-4d88-a0c3-16978d933e9a	41	13:32-13:40	f
819	64ad81f6-a991-42a2-ad2b-d5670dbd6bcc	41	13:40-13:48	f
820	e3cd387c-79c3-40b6-ac61-600777f91451	41	13:48-13:56	f
821	4235125c-aaf0-4bac-b5ac-1d5d82608ca2	41	13:56-14:04	f
822	5de28a61-3fdd-4c7b-9adf-a7608ba0d467	41	14:04-14:12	f
823	aafd35ec-dd2d-41b5-a656-2236d8859ccf	41	14:12-14:20	f
824	f3992eec-39f9-47b1-bf4b-7b5db7540439	41	14:20-14:28	f
825	11a9122c-409c-4d7d-b8fb-d39ef71324be	41	14:28-14:36	f
826	23007913-dcce-415b-a3a5-28a4548d1cd2	41	14:36-14:44	f
827	b8ed485a-7ecf-40ec-8365-0bfc1608ad65	41	14:44-14:52	f
828	67e8aabf-4d0c-4008-b56f-9cec57d3b7d8	41	14:52-15:00	f
829	429857bf-0866-4571-9420-415455966ea1	41	15:00-15:08	f
830	dee29ccd-552a-4e22-80f9-cf9890c6d8fc	41	15:08-15:16	f
831	f735f02b-2974-4c91-8077-86df4c314270	41	15:16-15:24	f
832	9a4542c7-b940-4da3-9819-36891aea0836	41	15:24-15:32	f
833	2ed3e72d-9ad8-44a8-9347-5d55478afc0e	41	15:32-15:40	f
834	12b71d2a-8d7d-440c-b318-d1a915db82da	41	15:40-15:48	f
835	2d977093-82c4-49e1-8f78-7dd2e9e84855	41	15:48-15:56	f
836	a67404d8-f924-4297-8c9a-1c40527d807c	41	15:56-16:04	f
837	bcb52bee-533a-428d-84e4-30f5421dba50	41	16:04-16:12	f
838	f82848c0-ac6c-4558-b500-d7112155c402	41	16:12-16:20	f
839	6d11c6d6-b0d0-489c-a57d-2524439f18b5	41	16:20-16:28	f
840	025ee639-2559-4e83-9f2c-b7fa46788b95	41	16:28-16:36	f
841	fe726792-24f2-4c18-a0a8-f47e78066d8d	41	16:36-16:44	f
842	b8225332-70aa-493a-8604-3abf19df7da7	41	16:44-16:52	f
843	86968dfe-511d-45c7-bcec-51eea3208d79	41	16:52-17:00	f
844	68f08a9e-3504-423a-9575-344dcd94a617	42	08:00-08:08	f
845	0cb3946d-553a-437b-884f-8d02011706d9	42	08:08-08:16	f
846	0a82c2e5-ea76-4774-8925-1b6a59da7718	42	08:16-08:24	f
847	5c187961-bbba-4e1b-9eae-8d22074f53ba	42	08:24-08:32	f
848	1c049e0d-8db2-4e1b-80bc-33ce3e61944d	42	08:32-08:40	f
849	ef29f96f-0fbf-49d0-a056-543d85b328e8	42	08:40-08:48	f
850	3f5a88d1-2744-4288-ad12-3405c93819e0	42	08:48-08:56	f
851	9fc3a728-77c8-4a45-a2e6-352741eca2a8	42	08:56-09:04	f
852	e560d835-8446-41aa-9c3c-6bc0171bfa92	42	09:04-09:12	f
853	6abfbe2b-1425-45f2-8810-f599f2422035	42	09:12-09:20	f
854	47dad7d3-db2d-4871-8469-3029fcbd8372	42	09:20-09:28	f
855	df1c8f2c-603c-4c79-87cf-429c42d988f9	42	09:28-09:36	f
856	8b66b82c-5d53-42d6-b04d-9dce8410401e	42	09:36-09:44	f
857	2eb38e97-66c9-4748-87b7-eddb502650b8	42	09:44-09:52	f
858	810ea05f-42d8-4b03-ad63-a922f8275e8d	42	09:52-10:00	f
859	1d473d58-1ef5-492d-88e6-57bb66136591	42	10:00-10:08	f
860	e89772e2-bfa8-4df6-9337-d1f0bfa2f386	42	10:08-10:16	f
861	6b13923a-0390-4ae5-9f28-31f345f71000	42	10:16-10:24	f
862	69171324-d39f-417f-858a-9257ea2617c5	42	10:24-10:32	f
863	77afe2f0-50aa-41cd-aa55-976cc219b5e6	42	10:32-10:40	f
864	e2ad0b26-c584-4483-b035-9fc18fd9e3aa	42	10:40-10:48	f
865	59cb3db5-2e23-4dad-abed-abfc2e4f461d	42	10:48-10:56	f
866	d51b0762-04f5-455e-a118-4b7c2c1ef631	42	10:56-11:04	f
867	8b495870-6d62-4f05-b065-a9427049ec2b	42	11:04-11:12	f
868	1f716847-aa3b-44c6-90d5-92dcd170d23d	42	11:12-11:20	f
869	db179c4a-de86-4d16-b36e-18bbeb8161ba	42	11:20-11:28	f
870	977a5c9c-9814-42ca-a000-7d7e927b3610	42	11:28-11:36	f
871	3ef73f85-0139-4bae-9e42-a678c2c963c5	42	11:36-11:44	f
872	c30d721e-bf9d-421c-bea1-7756f7771f91	42	11:44-11:52	f
873	248548eb-be32-4ca7-99dc-c1ab9e2a81a7	42	11:52-12:00	f
874	99466081-ab6a-41c5-b0d3-eb3c8ac19541	43	13:00-13:08	f
875	30790a27-6a2f-434f-b77b-0ecb8bab2ae3	43	13:08-13:16	f
876	b049becf-dc6a-43bc-8b54-27e54b898949	43	13:16-13:24	f
877	1c69ed4a-4a0d-4345-98b1-a6d70eb3ca95	43	13:24-13:32	f
878	49508f1d-d7f1-4e15-aa36-75cb5390d95c	43	13:32-13:40	f
879	bd4f011f-95b9-4328-9a1e-d11ee123c7b0	43	13:40-13:48	f
880	0f9de07a-8472-4bed-8e55-e53ac9de8a6e	43	13:48-13:56	f
881	32a1fa1c-8ca5-4e3c-85f0-4b5d9560ea8f	43	13:56-14:04	f
882	b959a442-b911-49f8-9e6c-412402dec015	43	14:04-14:12	f
883	d9c7f93a-8392-462d-9065-75e7f002fd9a	43	14:12-14:20	f
884	ae373e6f-ff19-432b-abbb-93651d643a6a	43	14:20-14:28	f
885	52f534e2-1bbf-4083-8540-f48430eb3fc4	43	14:28-14:36	f
886	2993cbd9-00a2-4962-94f5-9e71aaa5f1be	43	14:36-14:44	f
887	fd2dfd0e-05a3-4246-b1bd-fd256525118b	43	14:44-14:52	f
888	0c8debb5-8127-423a-a15a-556212608f16	43	14:52-15:00	f
889	6320ba55-b48d-47b6-aa9c-18b277e61e62	43	15:00-15:08	f
890	beffdecc-35ac-4cf7-b1bc-1797bbc0d012	43	15:08-15:16	f
891	9b38f931-d0c2-447b-80db-ca02b05811ad	43	15:16-15:24	f
892	787bdc95-b1e5-4016-b590-2a74172c5c2b	43	15:24-15:32	f
893	f5870cd9-9b2a-4854-8b57-46ec7d8a71c5	43	15:32-15:40	f
894	6014bf31-8dcf-458c-9718-852d2bc2ed0d	43	15:40-15:48	f
895	f9c7481c-cdd8-45b9-93d0-068756e14ed2	43	15:48-15:56	f
896	1e344784-0762-4fc9-96f6-1e9074afe986	43	15:56-16:04	f
897	c2a40d85-35a9-49db-b581-c24982d0ce01	43	16:04-16:12	f
898	e4a5b9e2-51db-4f05-a5e3-8e4780340f36	43	16:12-16:20	f
899	8791e495-3c7f-4aa9-b72a-ff079ed9b7db	43	16:20-16:28	f
900	b271c7e6-575e-4b29-8271-e8d20afdfddb	43	16:28-16:36	f
901	bc72674b-404e-43b2-9d0e-9827970b15a8	43	16:36-16:44	f
902	b70b04c1-f4c0-484f-9909-c202a5c76e53	43	16:44-16:52	f
903	a85f9fe1-9772-4853-a738-cc7d345cf80d	43	16:52-17:00	f
904	10a52214-53ab-4f07-a2ed-c3a7ac285aa0	44	08:00-08:08	f
905	dce6e73d-b7a4-44e5-bd75-549f2420231e	44	08:08-08:16	f
906	82a41320-c58c-40bf-86e6-519dc7fa7d1b	44	08:16-08:24	f
907	3231b168-9242-4f13-9600-6e2f3699e57e	44	08:24-08:32	f
908	0464951f-8cb6-4ec3-8ac6-0c1d907428da	44	08:32-08:40	f
909	ec7a8acb-af11-4c81-a4d2-ca49206b2e12	44	08:40-08:48	f
910	9736d966-4a7c-4f17-9e89-451994ba0987	44	08:48-08:56	f
911	072b9634-b789-4475-abbf-2a1d39ef3c46	44	08:56-09:04	f
912	492a1d21-652c-46fa-822a-8df7e2d3090d	44	09:04-09:12	f
913	d3574a79-ee37-4704-a47a-15ea86b9e287	44	09:12-09:20	f
914	4ec6a8e5-8297-499f-8808-5f4dffbaf6a2	44	09:20-09:28	f
915	29907a75-a958-45bb-8946-f457823fc761	44	09:28-09:36	f
916	bb0dfb4b-f990-486a-8a32-9485d6b9906b	44	09:36-09:44	f
917	76efb8ba-10d0-4705-9f3e-9e0b9c86dcb1	44	09:44-09:52	f
918	c5ed90de-71fc-4fd6-859a-8b14d4dfaf97	44	09:52-10:00	f
919	8a969ce7-a662-4a36-8e13-55c6f4ec2ad0	44	10:00-10:08	f
920	3b0adf79-778f-4ebb-a28a-c34e64baeb5c	44	10:08-10:16	f
921	74c816d7-ac64-44e3-badb-30e5d5106b7b	44	10:16-10:24	f
922	06202be0-eb77-40e6-b9e1-168b3f3eff04	44	10:24-10:32	f
923	6782bd20-7511-4768-8b9b-8048f7ba943b	44	10:32-10:40	f
924	3d02eb2c-6332-4e03-95cc-798ac58cd46d	44	10:40-10:48	f
925	ee3678f6-ae15-416d-b5ab-389fb28b76a3	44	10:48-10:56	f
926	e00d4319-d43b-459d-a274-04b56244df86	44	10:56-11:04	f
927	8ec36fd7-663a-4137-9b01-b4ea6feedbc8	44	11:04-11:12	f
928	159d07bf-174b-4a8b-87c2-c98ce7066e2c	44	11:12-11:20	f
929	2b44f4c2-2de8-433f-a0ad-5c56b706bbf9	44	11:20-11:28	f
930	4b1e510b-6232-4b7a-a1b8-bc83c2378af8	44	11:28-11:36	f
931	b7e7ce58-9df0-42db-b172-419c90cd6e5e	44	11:36-11:44	f
932	39509434-076f-4f0e-a9fd-eb64268c4b33	44	11:44-11:52	f
933	2e3f13f2-a9c8-4553-bfe7-f2c3795f3ed1	44	11:52-12:00	f
934	f510c0e0-9f9b-414e-b84c-d30e37336f5a	45	13:00-13:08	f
935	6681a125-2bea-456e-97e2-e2ede13af358	45	13:08-13:16	f
936	479b423c-2e42-42a1-b3b5-35d587e513b1	45	13:16-13:24	f
937	4449245a-53b4-444e-a69f-64531e573bfa	45	13:24-13:32	f
938	27ae9f81-9f76-4a74-97f2-69242b551bdd	45	13:32-13:40	f
939	f68e13a8-36d4-4ad8-872f-2962fb4e88e5	45	13:40-13:48	f
940	37b1839f-1de0-42c4-a3fe-f3275589f3a4	45	13:48-13:56	f
941	08ffcef4-85f5-4cf0-b967-b404cdf55ce1	45	13:56-14:04	f
942	7145d1fe-73bf-48a5-b977-fd33916f4f63	45	14:04-14:12	f
943	37cb3974-3951-48f3-88e4-e66273b440f4	45	14:12-14:20	f
944	51a96155-949c-4a15-bcaa-809182aa416a	45	14:20-14:28	f
945	cfdd034f-2205-43fd-9dc8-d3d46df3b4df	45	14:28-14:36	f
946	71f0a710-0096-46e5-a82d-d6e233a46cf9	45	14:36-14:44	f
947	1f425d5d-c894-4175-b478-0c164c388647	45	14:44-14:52	f
948	44106b7d-ac44-45cc-8576-b024b7efc27e	45	14:52-15:00	f
949	53ecb119-e396-444c-b947-081b8932a67d	45	15:00-15:08	f
950	da345806-014e-464c-8217-91b4ef98552b	45	15:08-15:16	f
951	e7e62cf4-6826-4441-ba3a-f2ed611be09c	45	15:16-15:24	f
952	a201c64a-248b-4712-a49a-d9f6f0d67093	45	15:24-15:32	f
953	630660e2-0afd-4fbf-a708-57053beb7cd0	45	15:32-15:40	f
954	b2a391eb-f1b7-4fde-aaa0-ea79a87ebcea	45	15:40-15:48	f
955	2a7272d5-f328-4c18-b8b0-83a0d6e72056	45	15:48-15:56	f
956	ab78ce46-f6be-4553-bbdd-95098b776d2d	45	15:56-16:04	f
957	401b6c0e-0efb-4f16-a458-5e03847d3afb	45	16:04-16:12	f
958	6630e1df-4567-464f-8d9d-3d6cadf86f13	45	16:12-16:20	f
959	135231c4-9795-4671-8225-6bdad02f1509	45	16:20-16:28	f
960	4a5130cd-3e5d-43a8-abe3-e00157d890d1	45	16:28-16:36	f
961	7cd0613a-154d-48a2-a2a1-0a2c0bc7cbef	45	16:36-16:44	f
962	8043526e-ea1b-4862-90af-a38b66b3d063	45	16:44-16:52	f
963	97c011ac-976d-4070-81bc-ef2ff9781799	45	16:52-17:00	f
964	8aadfd04-acde-4d2d-9ed6-98f8e99333dd	46	08:00-08:08	f
965	3ad97ac8-3b9f-4975-852e-b9927d207b9e	46	08:08-08:16	f
966	cf16c99f-cc33-4a66-9a29-42e6133a2c54	46	08:16-08:24	f
967	34867421-7869-4317-88c7-24b29bc21f6c	46	08:24-08:32	f
968	81e9e73a-8ee5-44cb-ae9b-a8577be0d67f	46	08:32-08:40	f
969	29132b95-bea3-4d83-93fd-a08d6f378d41	46	08:40-08:48	f
970	0b774889-e323-4451-bdcf-4889b1f51ee4	46	08:48-08:56	f
971	972a0547-f1da-477b-8bd2-da186ef84fcd	46	08:56-09:04	f
972	82dbaac5-ab20-42a0-ae41-a3c45b7a7b63	46	09:04-09:12	f
973	5adf0798-6d09-4f5b-8d88-d27ff9fa0aff	46	09:12-09:20	f
974	5732f201-2721-4a3a-b23c-d57828ef80dd	46	09:20-09:28	f
975	93ba11d2-35a5-431e-8fdd-93ed8863cd90	46	09:28-09:36	f
976	553bfd3d-242c-42f1-b85d-2620a86c8387	46	09:36-09:44	f
977	8f679dd9-d104-48be-b414-d000989bd1b1	46	09:44-09:52	f
978	5fdef6eb-e37b-4a45-849c-ec9227a22e0f	46	09:52-10:00	f
979	9269441c-6075-4853-99c0-0fca3c0b29a2	46	10:00-10:08	f
980	15d5746e-883d-4157-ba74-f5204684df4c	46	10:08-10:16	f
981	d0dc435f-444f-4f16-aca4-8777bde91f99	46	10:16-10:24	f
982	1dfa1902-f83f-4f7b-88e3-a68dc77570e1	46	10:24-10:32	f
983	75a84ff9-da32-4375-898e-5a32bf28ec71	46	10:32-10:40	f
984	6fa3f635-69b6-4c72-af29-1f106a2c25b7	46	10:40-10:48	f
985	3c6cfe40-5935-4e7c-8b61-5bbfc2d69488	46	10:48-10:56	f
986	05d4b826-82c6-4f87-bafd-73449d04fbd0	46	10:56-11:04	f
987	1c418299-8d1e-42a2-ba25-a6139a47ad4c	46	11:04-11:12	f
988	37226ce0-a91b-49ad-90b6-8ccae981f050	46	11:12-11:20	f
989	50182cb6-7ca7-48ab-b3bf-6e5bbedd1105	46	11:20-11:28	f
990	2e77fb88-322c-4938-bb05-10e791fd0371	46	11:28-11:36	f
991	1a6d5b78-9488-4b9b-ac5e-7330d4ffd201	46	11:36-11:44	f
992	a9157890-666d-4cf3-949d-e567fd0fc51f	46	11:44-11:52	f
993	3277bf98-9e74-4582-8623-aac28294f8f9	46	11:52-12:00	f
994	ff0a66b6-e8b4-4f85-9b19-a57b8e9e54dd	47	13:00-13:08	f
995	ae691eed-1368-4abb-8310-1fd8e7fa5597	47	13:08-13:16	f
996	7e5e3743-a408-439d-a5d7-4f423d5bafcc	47	13:16-13:24	f
997	39200ec6-1388-420a-a65d-94a8548181ec	47	13:24-13:32	f
998	09cf9132-7f33-41c3-afd6-fa63fb5a3a26	47	13:32-13:40	f
999	a783b302-f66c-4183-8eea-c1fd415426ee	47	13:40-13:48	f
1000	233b182b-b9b5-48c5-ad7a-9880310ae0de	47	13:48-13:56	f
1001	f3089172-97a2-48e3-8887-1baf49314e2e	47	13:56-14:04	f
1002	30686a25-9c1c-4806-b475-8126703b4b11	47	14:04-14:12	f
1003	6e6ae45a-a8d0-4b0a-9828-b6b3647c8bde	47	14:12-14:20	f
1004	de5a2286-2fce-4a8c-80d6-02e56edf8b57	47	14:20-14:28	f
1005	7968d458-5d3d-485d-b6f3-ab1f3494f74e	47	14:28-14:36	f
1006	c1ed710f-3211-4635-b503-2165e54e0243	47	14:36-14:44	f
1007	ba5e0000-bd64-4cf3-b2e0-49efa952f432	47	14:44-14:52	f
1008	25607778-9139-4f0b-a9f9-fc5fd5d63cac	47	14:52-15:00	f
1009	0a8cde56-11af-4f35-b449-984b8a7ca861	47	15:00-15:08	f
1010	4118a034-f245-496d-bd1d-66b681a13c6a	47	15:08-15:16	f
1011	3afb3e58-6ead-4ae1-8a63-40f8b4bc2ec2	47	15:16-15:24	f
1012	c6ad47e0-9a88-44c2-a4aa-91bf2949287d	47	15:24-15:32	f
1013	c9765bcd-1064-4524-970b-1d7322c398c3	47	15:32-15:40	f
1014	4b792ed4-5b57-449c-bb02-655b213b6b10	47	15:40-15:48	f
1015	bbff99f1-a84a-485d-be44-27774f9499dd	47	15:48-15:56	f
1016	7e97215f-7e53-49ea-afe8-4a72aec37430	47	15:56-16:04	f
1017	1986d126-76f7-470e-a9c7-cd2143183c9a	47	16:04-16:12	f
1018	b41b2d01-eba8-4fe9-bc5b-a04bb07036c8	47	16:12-16:20	f
1019	74674332-bffd-4e38-9e51-4d32abc30144	47	16:20-16:28	f
1020	db7a46b6-530a-4d8b-8efc-a7b521b21104	47	16:28-16:36	f
1021	ced80b0c-8eb1-4bfa-ae8d-126ab77d5f05	47	16:36-16:44	f
1022	173fb8ea-b9ce-4c55-9072-7034a3bd22c2	47	16:44-16:52	f
1023	b287e7b4-3510-4891-86a7-b9421c4fc423	47	16:52-17:00	f
1024	4c607b69-ad8f-4782-b245-0070bac6bcca	48	08:00-08:08	f
1025	c169eef9-a5ad-49b2-9c0e-385ac1194a3e	48	08:08-08:16	f
1026	87c194dc-20f7-440d-8d09-fd77beb91897	48	08:16-08:24	f
1027	bd11eb8d-4a58-45c6-aa4f-d344735ae936	48	08:24-08:32	f
1028	87b8b73a-8aa6-4ea4-87a8-7e9e66f6cf4a	48	08:32-08:40	f
1029	3b8fac98-8917-4419-9fa3-b9365acd034b	48	08:40-08:48	f
1030	79b04ad4-9d6b-446b-9333-f27cfbe4fa51	48	08:48-08:56	f
1031	24c8ecec-8315-4087-b9c1-cac91069adff	48	08:56-09:04	f
1032	71e29cb9-db3a-4379-b45d-c554403728cc	48	09:04-09:12	f
1033	a44f6fad-397f-4102-ba6d-64a3e05f8674	48	09:12-09:20	f
1034	4f7aa486-b038-4c4e-9f64-838f63d0ff39	48	09:20-09:28	f
1035	b6d9bc4a-becb-4e57-a94f-43e7f27f349d	48	09:28-09:36	f
1036	d28bc337-de78-46c2-9e99-b92abf96748a	48	09:36-09:44	f
1037	9cfd5b1a-19ba-4902-80d5-c19e07308ee0	48	09:44-09:52	f
1038	f3555465-6c9a-4da1-a120-77888f33c2dc	48	09:52-10:00	f
1039	4dd01ef9-5eaa-430d-b914-57473763d441	48	10:00-10:08	f
1040	0c9d8ed6-39c8-4500-a8ef-8a74b33d6e59	48	10:08-10:16	f
1041	0bfed745-4fa2-4278-8238-e05e120019c4	48	10:16-10:24	f
1042	9834f7aa-5f38-4e64-82ee-1e8898c1a049	48	10:24-10:32	f
1043	e8b27634-e6bd-497b-bea7-342802f0b6d1	48	10:32-10:40	f
1044	e31a71cf-eb79-4fc2-881d-d36db2c0948d	48	10:40-10:48	f
1045	cd7ede69-d288-42c7-b54e-1761dda87045	48	10:48-10:56	f
1046	90533c60-37b9-46fc-a5d9-42196b898131	48	10:56-11:04	f
1047	40a9f223-78e6-40fe-9bfe-164f7b84f50f	48	11:04-11:12	f
1048	7c2eeb29-0a3e-40d7-bd2e-d0bb4cce6cea	48	11:12-11:20	f
1049	19b021bd-1347-4313-bbb3-81a50157c9f2	48	11:20-11:28	f
1050	083350fe-9a8c-4561-8318-fc0fce73e711	48	11:28-11:36	f
1051	dbc47a3a-e3e7-4c98-95f6-6cc2515d3208	48	11:36-11:44	f
1052	2fd312c7-6bb7-4002-aa1e-c9369fa45102	48	11:44-11:52	f
1053	0033cc1b-78a2-4824-9bd3-6aecaf40276f	48	11:52-12:00	f
1054	7e371042-0065-4a3a-9b92-b29360a23110	49	13:00-13:08	f
1055	c78b324b-cfb2-47c3-8032-e7c9d9987ca9	49	13:08-13:16	f
1056	31bcf5eb-57f2-4c7c-8fcd-c6549eda44a7	49	13:16-13:24	f
1057	f4089b19-0e97-455a-99b9-a3b8e76006c6	49	13:24-13:32	f
1058	9d9fafc2-14f2-4494-8467-860d936a6e39	49	13:32-13:40	f
1059	a020793c-e210-405c-8061-96fcad6c8495	49	13:40-13:48	f
1060	ab978c49-c860-4bc6-aea9-e81253395ff4	49	13:48-13:56	f
1061	452bb58c-5416-4d2f-bc34-6c9992742f80	49	13:56-14:04	f
1062	700ef77c-484f-4896-86bb-2ae243086fbb	49	14:04-14:12	f
1063	5128c5ac-a138-4739-a64d-083223aa3cfa	49	14:12-14:20	f
1064	98e92a76-1234-4e25-b0ea-9fd74e9765c4	49	14:20-14:28	f
1065	34c1d5e3-1c42-4553-b262-21895f1db6de	49	14:28-14:36	f
1066	06012d67-1442-464e-9b42-2c1659525efd	49	14:36-14:44	f
1067	4d70cc9c-6904-4c82-b508-b294eb4a5526	49	14:44-14:52	f
1068	c84faf07-ec59-45a3-b64e-96fc4af94079	49	14:52-15:00	f
1069	9e970cde-2d57-4b0a-8fb8-1595c8940943	49	15:00-15:08	f
1070	eeca42d4-d84b-4988-84a3-569b38415b5e	49	15:08-15:16	f
1071	f0907bf7-8ea2-418e-ad54-e9714bb4a57d	49	15:16-15:24	f
1072	9a77d533-2287-47d6-a27e-0dfcbf42b29f	49	15:24-15:32	f
1073	193b9967-798b-4a9d-b6ac-ef33a5a46c32	49	15:32-15:40	f
1074	365b2665-8810-49a9-932e-f88c4b6512f9	49	15:40-15:48	f
1075	14dd4f9c-1129-4321-9b56-9df5d8932390	49	15:48-15:56	f
1076	5f251180-049d-4d15-9d7c-6410e52bbbcd	49	15:56-16:04	f
1077	5ae00585-d855-4523-b731-968ec9a8cf2e	49	16:04-16:12	f
1078	ccee3bd6-fea8-4587-9f13-5ec6f072c59b	49	16:12-16:20	f
1079	07e5a777-ecec-4caa-9a9e-480d94f4b35b	49	16:20-16:28	f
1080	c500411e-9269-416f-a306-9282cf343290	49	16:28-16:36	f
1081	1c472855-72d2-4cbe-82e9-08671e800c01	49	16:36-16:44	f
1082	8f4ceb00-bd5a-4be8-83b3-354134e39353	49	16:44-16:52	f
1083	a816ed83-5f8e-421b-80bc-79bc1fee8238	49	16:52-17:00	f
1084	b1d5fec2-0bbf-4ded-8d1f-9e4a9e0108f6	50	08:00-08:08	f
1085	d4b55c8d-d03f-4e7c-84a6-ace980147b1e	50	08:08-08:16	f
1086	80faedda-efb4-4579-b500-5880546e8341	50	08:16-08:24	f
1087	da21ee4f-f4af-4e6b-9e0c-5354e211a748	50	08:24-08:32	f
1088	392a93f4-51e4-4a0f-be3b-66f97ecab5e3	50	08:32-08:40	f
1089	f7317030-a612-41dd-b4e7-5090c4d078b3	50	08:40-08:48	f
1090	fad55296-36d1-4a40-8004-d72afcba4b3a	50	08:48-08:56	f
1091	c1848b84-f584-47ab-8003-7e39f94f6c9c	50	08:56-09:04	f
1092	d4261f57-694d-455e-b1dd-4f0fefb15459	50	09:04-09:12	f
1093	960c97bc-a619-4be8-bc0a-50d515237b1a	50	09:12-09:20	f
1094	69b32d96-a314-4f03-88cf-17aacb30475b	50	09:20-09:28	f
1095	22ce5dd4-a27e-4270-8c88-69804d3f9323	50	09:28-09:36	f
1096	73af0be6-a438-47d1-828d-a383a912acf1	50	09:36-09:44	f
1097	03c26cb2-66bc-4325-87c2-c7a26deb0e0a	50	09:44-09:52	f
1098	e4eab3d2-9a23-4397-bdca-5a4c96679c29	50	09:52-10:00	f
1099	1cf0f105-9d13-4eda-bbb7-20ba13d707af	50	10:00-10:08	f
1100	e936c706-ca0d-4a9d-a6e2-eefc7978d844	50	10:08-10:16	f
1101	23acb999-464c-4354-9841-04269802b14d	50	10:16-10:24	f
1102	fd7e2a85-5a6b-4835-b1bd-7beaa766d258	50	10:24-10:32	f
1103	296d980c-209c-4bc7-ae68-8a948b7266b1	50	10:32-10:40	f
1104	21ab8a9e-4bbb-4f93-84f9-0a72935523c8	50	10:40-10:48	f
1105	66724db5-95da-4f81-9dfc-f2eae4bdd0c2	50	10:48-10:56	f
1106	ffe4815a-a5fc-4794-8c4e-1576417d97f3	50	10:56-11:04	f
1107	75a0855d-9eb5-4534-b228-5e0f644d2f4c	50	11:04-11:12	f
1108	2b3eca56-01c9-4519-a6b3-b520bc180c7f	50	11:12-11:20	f
1109	6c86b2ac-9fb9-4af6-8fb8-6c6ac1ca5b17	50	11:20-11:28	f
1110	1fcbdac2-ca89-4a5f-9eb7-3bd701753b30	50	11:28-11:36	f
1111	e068fdcd-22f6-4bca-9834-4de53c46fc95	50	11:36-11:44	f
1112	bb5c5c4b-8f25-4faf-8ce4-b0bad79df3ed	50	11:44-11:52	f
1113	b03366d9-5847-412c-b6b8-4af97f0434f4	50	11:52-12:00	f
1114	998a76cd-d4b5-4736-b876-e0af6e76cd8f	51	13:00-13:08	f
1115	ef6f16d0-58c9-4f38-9ae8-b6603cc411bb	51	13:08-13:16	f
1116	8cd7a27b-edb1-4c80-9ff2-4fe2761af340	51	13:16-13:24	f
1117	893e8481-47c0-4299-bc91-4febaca16131	51	13:24-13:32	f
1118	5e74e14a-6b54-4807-b868-6c717b30c893	51	13:32-13:40	f
1119	b141b104-3d16-41d6-b509-68912d50ee6e	51	13:40-13:48	f
1120	e10e8744-cfcb-40f7-9007-6b3c594ef1a6	51	13:48-13:56	f
1121	4a79a1ce-5ff7-483c-be00-e017f9bf7989	51	13:56-14:04	f
1122	b43b36ef-1d05-4ca0-b37c-9a041a4627f1	51	14:04-14:12	f
1123	ae84c0a6-ad09-44af-9fcf-21f13bbaff39	51	14:12-14:20	f
1124	e59f3174-ed22-4c64-8300-14821426fb04	51	14:20-14:28	f
1125	22fe3f37-0fe1-49cf-9ae6-d51ab6d831b2	51	14:28-14:36	f
1126	a0eb637b-67f0-4e5f-b674-1f1bbc17c0c4	51	14:36-14:44	f
1127	5a93914b-0086-4ee7-8a84-94b1807de231	51	14:44-14:52	f
1128	3912ab56-c16b-4234-8985-e112c3c3d2b5	51	14:52-15:00	f
1129	0cd71e79-610b-42a8-a8bd-822c7a14adff	51	15:00-15:08	f
1130	f7a4ebd1-d577-4770-907b-cb91bc33928c	51	15:08-15:16	f
1131	05ae5453-0e5b-4770-9f6c-e7c3a25d85b3	51	15:16-15:24	f
1132	4529762b-79e3-4bf7-940e-b38e496b9237	51	15:24-15:32	f
1133	140ecb9d-6b85-4f93-a950-60fd6ce99e39	51	15:32-15:40	f
1134	09135b56-0398-470b-a7e4-0a0d6fc05c91	51	15:40-15:48	f
1135	ef26fb6b-db2b-4469-b2e3-df805710d465	51	15:48-15:56	f
1136	5373e093-b6ff-43f7-95d6-ac1c01d6d148	51	15:56-16:04	f
1137	0a7de52b-2d58-4080-b97c-8f2dcf7d5126	51	16:04-16:12	f
1138	3568cdfb-8489-4868-b303-be2df48b8725	51	16:12-16:20	f
1139	a41d193e-2d9e-493a-983c-0dcdc035c1ef	51	16:20-16:28	f
1140	8fce9ce4-b2ee-4fc2-bc7e-a903476dfbda	51	16:28-16:36	f
1141	88ad86e5-7c62-43e6-b5c0-259e11c39802	51	16:36-16:44	f
1142	1fb5bebc-43ae-4ef0-9f1f-2a08a159a562	51	16:44-16:52	f
1143	3a155366-f465-4900-94bb-abc2eaf41d42	51	16:52-17:00	f
1144	c9a2c1cf-aba0-4fb8-8517-bfba49417bfd	52	08:00-08:08	f
1145	3922ea09-c1d5-439d-a8ed-deebda7ae37e	52	08:08-08:16	f
1146	6d891ee9-032b-4453-ad36-24979d1ae847	52	08:16-08:24	f
1147	ce4b4349-76d8-4eb2-9622-ca36ac6ce46f	52	08:24-08:32	f
1148	80059ec1-6ebf-4afe-a908-1b61975460e3	52	08:32-08:40	f
1149	bebe69ff-7316-48d8-beac-5f0b4c93e3cb	52	08:40-08:48	f
1150	ad601d4c-993d-40fe-852a-8a00b0dd5125	52	08:48-08:56	f
1151	b13d0418-2aad-42f2-af46-37ac975dc8df	52	08:56-09:04	f
1152	20d57659-a0ef-49a2-b51d-f87fcc175e21	52	09:04-09:12	f
1153	cf206ea6-e6e9-4f7c-a9b0-15e6983e3b09	52	09:12-09:20	f
1154	7ec95efe-26f3-4b82-92cf-a5163a4950db	52	09:20-09:28	f
1155	b44fedd4-aa19-4402-952b-3a52c6d048d5	52	09:28-09:36	f
1156	c1a737f5-ccd1-40c3-aee1-68a17cd780dd	52	09:36-09:44	f
1157	797ba227-1aa3-4346-86f0-a611603d2b60	52	09:44-09:52	f
1158	39240553-e7a8-4324-a00d-b5b2315ae4da	52	09:52-10:00	f
1159	2527c4ad-1868-4437-a84f-cba1025c2067	52	10:00-10:08	f
1160	e4ed2738-0aca-454b-a739-9076e6b2b480	52	10:08-10:16	f
1161	71ed99e1-f104-4166-bfbf-167d5f5844a1	52	10:16-10:24	f
1162	30cfb28a-0f98-4c52-b89f-5bbac883a6b9	52	10:24-10:32	f
1163	3188212c-d4a6-4e85-aee4-c335fabac826	52	10:32-10:40	f
1164	4c807142-37f6-44b6-b6d1-43a1e438d2ed	52	10:40-10:48	f
1165	98ac4e52-1d2b-4daa-b599-3f23829180b5	52	10:48-10:56	f
1166	d06e6d4c-4843-4af0-b403-083a148fe616	52	10:56-11:04	f
1167	b434d585-5a09-4b65-a93b-676dfaff5382	52	11:04-11:12	f
1168	bf8d4468-aab3-476d-837f-4601b80d7677	52	11:12-11:20	f
1169	6e12b6d1-572a-455b-999a-10b99cc1f324	52	11:20-11:28	f
1170	f33a0dfe-2fe3-4876-8116-077367b001be	52	11:28-11:36	f
1171	12348a04-41f0-4cea-99df-a426974033c8	52	11:36-11:44	f
1172	fa2e7771-8da2-42eb-a7ee-cf9df39964b4	52	11:44-11:52	f
1173	fc5bd9f7-0881-49cf-b686-48e0142d3cf2	52	11:52-12:00	f
1174	57ab90fc-f381-4578-9bc2-84fa51722559	53	13:00-13:08	f
1175	040e7f32-bbe9-46ff-b1fc-ce992ee91dc3	53	13:08-13:16	f
1176	3ba3d44a-33ee-45ed-8086-caa37f93704a	53	13:16-13:24	f
1177	f73b88c8-6852-46ab-8f97-92de440b2f03	53	13:24-13:32	f
1178	ec34f6c1-a1d8-45ac-8586-de3b1e3b4cdd	53	13:32-13:40	f
1179	9d15b7b9-a969-4ab0-9af0-4659f663b9e0	53	13:40-13:48	f
1180	32686924-4272-4a66-8530-77c8610ab272	53	13:48-13:56	f
1181	8fa2d67e-dd8d-4197-95fe-e278133322cd	53	13:56-14:04	f
1182	37d84d60-a394-4360-ba92-9a1e5e04e662	53	14:04-14:12	f
1183	9a4ef8ae-ffee-432a-ae3a-be8420d76593	53	14:12-14:20	f
1184	1e412072-e6dd-4368-b131-db89d60278f2	53	14:20-14:28	f
1185	fdaf6f6c-2c3e-43c6-bc8a-3a084335bd40	53	14:28-14:36	f
1186	ae11afaa-4198-4e99-abe6-68008ed5aedc	53	14:36-14:44	f
1187	d486065e-0ce3-459c-aa70-03d1f75177f4	53	14:44-14:52	f
1188	ccbc89c3-959f-4eb9-8f9c-370a6ab5e52c	53	14:52-15:00	f
1189	7e9d4b55-314d-4ba1-81b5-2f7940aef3b5	53	15:00-15:08	f
1190	f4711d11-c536-48aa-969c-e016c6daec99	53	15:08-15:16	f
1191	bfaa7ea5-707c-417b-84c7-b3565a0ab188	53	15:16-15:24	f
1192	42962af3-be8d-4075-88f7-cb610f7ba1b0	53	15:24-15:32	f
1193	729d913d-6802-45f4-a70d-7abd64da2242	53	15:32-15:40	f
1194	d46141db-0c79-4a64-b946-ac274d5c9c39	53	15:40-15:48	f
1195	412d5944-765e-481d-9093-9c068731f57a	53	15:48-15:56	f
1196	f27cdba7-4f5e-4383-a490-e9e87d1690cb	53	15:56-16:04	f
1197	4095567b-fb70-489a-82da-6a4602b9afb0	53	16:04-16:12	f
1198	58d60681-8cc9-4e1b-a60e-7a7f3d77927f	53	16:12-16:20	f
1199	a398f868-8483-43dd-9681-ca3a70484a53	53	16:20-16:28	f
1200	290f66c5-340a-42a7-8af9-3385c67f1d32	53	16:28-16:36	f
1201	0eab59e8-cc9d-45aa-8daf-f9b360c46ff7	53	16:36-16:44	f
1202	2f133581-1e1f-4921-baeb-a70c4c72d0d4	53	16:44-16:52	f
1203	aa90ccfe-eedf-4450-a9cf-e88212697ac5	53	16:52-17:00	f
1204	ca7ace6e-56bd-4589-a15d-785dc5b03327	54	08:00-08:08	f
1205	fbfcd9ea-7a32-44cf-8bc6-905cf8306b4f	54	08:08-08:16	f
1206	500363fa-8434-441f-a717-8e7432030010	54	08:16-08:24	f
1207	4373c12c-44d2-43a2-b0f4-d6ffa78e1ccf	54	08:24-08:32	f
1208	71369cfe-d962-4b46-9942-2bdb6f4d518f	54	08:32-08:40	f
1209	d21a58d2-a9c7-49fc-8dd8-042f9de29f08	54	08:40-08:48	f
1210	966ad7b1-d30b-472a-b470-169cfe4f7d8b	54	08:48-08:56	f
1211	14bceecc-87a0-44d3-b557-b4033e5833af	54	08:56-09:04	f
1212	6d9add80-a367-4273-a32a-4e883c4bbce9	54	09:04-09:12	f
1213	f17992be-eecc-484a-bfdc-cc63a59045a3	54	09:12-09:20	f
1214	6aa14d6a-4de9-4315-b2e7-58f80d0ed299	54	09:20-09:28	f
1215	2302ebf8-8522-4321-bf2e-8a4f5f896da1	54	09:28-09:36	f
1216	9c1cba31-0a30-4c34-bdb0-42e7ede2e0a8	54	09:36-09:44	f
1217	ee9d8bed-7b28-41b1-b22c-6c5719374ae9	54	09:44-09:52	f
1218	e6d402f7-5cbb-4930-b075-cb1082a3ee01	54	09:52-10:00	f
1219	a004669a-3703-4265-94f7-53dd4f009b5d	54	10:00-10:08	f
1220	8c435f8b-64e7-4d41-8e91-c010a92e7cdd	54	10:08-10:16	f
1221	b2fc358e-9daa-4dc1-b5cf-28c263495a26	54	10:16-10:24	f
1222	6ac55fdb-6f1f-4303-adf1-c86a826056f1	54	10:24-10:32	f
1223	fa510c56-4869-4d8a-b462-b90665d5c405	54	10:32-10:40	f
1224	013d9c0b-da56-4ce0-8eca-4870eb708074	54	10:40-10:48	f
1225	cac7937e-26e7-43db-9a9d-fcb63cd0492b	54	10:48-10:56	f
1226	431fbdc6-7023-4608-999f-cc63db47f98b	54	10:56-11:04	f
1227	4d2fa54e-aed8-47c4-8e1a-7ce4d95e1b96	54	11:04-11:12	f
1228	ad7bc366-454a-47d1-8532-464d62d8f837	54	11:12-11:20	f
1229	48d21254-f9fa-4b85-a885-3be386608333	54	11:20-11:28	f
1230	6d1971de-7812-4572-9b84-f88766786e8b	54	11:28-11:36	f
1231	732b2a70-f4cc-45f0-b411-106bbc50bebd	54	11:36-11:44	f
1232	28e659a2-fc24-47dc-b487-55f0291e738f	54	11:44-11:52	f
1233	823dc4d2-0441-4a0b-b569-e042f3f81213	54	11:52-12:00	f
1234	2dec73c4-9601-435d-b206-2beccb324f2e	55	13:00-13:08	f
1235	4d79a840-85a2-4117-b0c4-3600ea9141d8	55	13:08-13:16	f
1236	6335f4a8-ab93-47bc-893b-b32c4d04ce3a	55	13:16-13:24	f
1237	bbebbe68-40dc-40d6-9909-6bcab0669ba7	55	13:24-13:32	f
1238	f40b7798-0b7f-48c1-8e38-5e11d30b56ad	55	13:32-13:40	f
1239	4955e6cc-157b-4282-a5ad-096b54d25f95	55	13:40-13:48	f
1240	ab08e06a-ce58-4869-a578-842d6e733cf8	55	13:48-13:56	f
1241	ff8b2b39-1d64-4046-8f33-27512d10daa9	55	13:56-14:04	f
1242	6586b0a3-4e27-45fa-8aeb-7b21df9f67d5	55	14:04-14:12	f
1243	d1346ef2-4268-4373-91a6-548a43732e09	55	14:12-14:20	f
1244	54c512b6-315f-4a81-91ec-caf6a5fa0c1d	55	14:20-14:28	f
1245	107531b2-38b7-4cbb-a82f-a4d27b5b6bb3	55	14:28-14:36	f
1246	548bde4d-380f-4c71-b619-fb73a38c5a50	55	14:36-14:44	f
1247	da8d48e0-c6ed-4975-872a-b7fa6bb78c9b	55	14:44-14:52	f
1248	b019ab36-4495-464c-94c8-2410a4b0f90a	55	14:52-15:00	f
1249	79dfd3f1-bd04-40d2-9a4a-541f999be8dd	55	15:00-15:08	f
1250	42b74792-3878-422e-a5f9-fb1300f3d8fb	55	15:08-15:16	f
1251	b1c7741a-1306-462c-babe-51b79fbcf7a2	55	15:16-15:24	f
1252	4515d4ac-9602-4b30-bee3-9d72f4f44731	55	15:24-15:32	f
1253	a7051bf2-5a8a-45ad-af0f-e7c180966ce3	55	15:32-15:40	f
1254	92ca5938-eccf-45c7-85c8-e334edd82c3f	55	15:40-15:48	f
1255	fdd0fecd-2f7a-4990-b72d-327c9afadd8c	55	15:48-15:56	f
1256	0383ff6b-57c2-42b0-9419-beaf9ac39ef9	55	15:56-16:04	f
1257	967a5d9a-7f11-4daa-bdff-73cc7cd775f4	55	16:04-16:12	f
1258	4d8cd1fa-4299-41ba-8c5a-9ddad97c68e1	55	16:12-16:20	f
1259	323a7109-c63e-4eca-a993-58bd5eda8191	55	16:20-16:28	f
1260	1e1d6371-3f67-42f7-b3bc-93cddd9f1595	55	16:28-16:36	f
1261	d133a503-38b2-41b7-a97b-10821167a47f	55	16:36-16:44	f
1262	2f3dbfb6-95c2-4c25-bba7-54de3ef5fefe	55	16:44-16:52	f
1263	93bf8a0f-c8f7-493a-8ef7-d9a208642519	55	16:52-17:00	f
1264	b6c0ec52-f51a-46a5-8269-dccd3c845661	56	08:00-08:08	f
1265	07e8ad1e-d005-4d08-ba82-f2fff2ed090b	56	08:08-08:16	f
1266	31a151c3-03b2-484b-bcf0-c7dbf1d254a8	56	08:16-08:24	f
1267	27799dc4-7010-4cc3-be30-bbf8ae82e196	56	08:24-08:32	f
1268	de316e61-d4dc-481f-9e7a-38fccf0bc5a2	56	08:32-08:40	f
1269	8955bb61-e86c-4010-80ec-8cd8f9585de9	56	08:40-08:48	f
1270	f84bd2b0-c33a-4bf6-b572-e783a3068cbc	56	08:48-08:56	f
1271	40044570-f5bf-4a22-991e-d86f2015c924	56	08:56-09:04	f
1272	c6c35814-01af-48f8-9f95-dc9a2cd5d073	56	09:04-09:12	f
1273	36313ade-df92-45c6-bdb4-5dfa45246078	56	09:12-09:20	f
1274	004483c4-6496-42d8-a0ed-50eb77cb6595	56	09:20-09:28	f
1275	7fa1803b-dfe8-4e27-a1c3-a62dbe050ed3	56	09:28-09:36	f
1276	07356f2d-2af1-42e0-a4de-d81a604a601f	56	09:36-09:44	f
1277	7127ca7f-32cf-4f2c-9d49-2e8eade36bdf	56	09:44-09:52	f
1278	2c62f3fe-0215-4f69-b842-0ed57f1c3770	56	09:52-10:00	f
1279	00fe8b3c-0c71-426f-a7f4-33f80a6b7f6f	56	10:00-10:08	f
1280	2c7c8bc7-1114-4f64-b5a1-ad42d817ad9e	56	10:08-10:16	f
1281	7595e972-681c-4c55-8adf-8e247443e753	56	10:16-10:24	f
1282	97b4327c-0a91-42db-87f0-00dbd574ee70	56	10:24-10:32	f
1283	7cf92ae1-531d-4215-adb3-f2d0d1b79d9c	56	10:32-10:40	f
1284	61171209-b10b-41b7-8c3b-99c1482b13e4	56	10:40-10:48	f
1285	7b543097-56f0-4e37-8f18-a33864beea03	56	10:48-10:56	f
1286	ce511fd9-99f2-4789-b9c7-9cdfb8b5df8b	56	10:56-11:04	f
1287	29b3f1c9-ad56-403d-bd7d-1eaa1ea8e407	56	11:04-11:12	f
1288	e3fb65a1-813d-43e5-99cf-7291ad156fbc	56	11:12-11:20	f
1289	243892b3-f3af-4b18-b99c-6c51c78d6fad	56	11:20-11:28	f
1290	6f8e81a7-8f31-449f-9c76-f561dd877755	56	11:28-11:36	f
1291	e585cb96-20e1-43f0-8d34-5369badf6481	56	11:36-11:44	f
1292	9faf3abf-985d-410d-8e5b-8540cf2775a9	56	11:44-11:52	f
1293	cb3c937b-604b-44c7-908e-8d18d6928933	56	11:52-12:00	f
1294	005216a1-8d48-41fe-b80b-bc75b0d9cfbb	57	13:00-13:08	f
1295	2318384a-8d38-4096-b241-143e29f5a59c	57	13:08-13:16	f
1296	020214e8-520f-4d60-8451-899f4ff3b492	57	13:16-13:24	f
1297	e6165c89-eeec-4992-b1c1-56431e55b234	57	13:24-13:32	f
1298	49aee9aa-6941-4f3f-86fb-20ee91faac9e	57	13:32-13:40	f
1299	a15e3e30-89ab-43d0-be57-937d98e2ee7e	57	13:40-13:48	f
1300	a81a2127-78c1-4d9d-9a73-735079ed082f	57	13:48-13:56	f
1301	1dcfced4-c458-40e2-a4f2-ee6f02b09299	57	13:56-14:04	f
1302	8fe92214-2c8b-4359-913d-a4b8a9bf2123	57	14:04-14:12	f
1303	d6a1160a-837e-4402-bddd-2ea9e7af75de	57	14:12-14:20	f
1324	c760cff4-57b2-4103-8919-5fd77d645e1a	58	08:00-08:08	f
1325	e5e82d07-7ef0-48eb-a693-8ac87aa11a56	58	08:08-08:16	f
1326	352024d6-15eb-4369-bab9-dc1332ba7235	58	08:16-08:24	f
1327	f25c0106-23a8-4eee-a3cd-c1c1da102b94	58	08:24-08:32	f
1328	5472be22-bdea-42cc-9de5-cb4a3b2d5c0a	58	08:32-08:40	f
1329	d8bcd75a-a616-422c-8e26-5aa28de0bbda	58	08:40-08:48	f
1330	34593644-8856-4ea7-8cfc-ecbf12a78b6b	58	08:48-08:56	f
1331	93260751-418c-452c-a620-8eb014fa9693	58	08:56-09:04	f
1332	5ba69a98-4604-4430-bc34-7d1a0fd6ec6b	58	09:04-09:12	f
1333	35acf72f-ea3a-477c-af74-3c1f6113c05b	58	09:12-09:20	f
1334	0815425a-ca7c-4393-a025-918649d22215	58	09:20-09:28	f
1335	bfb090ce-3999-4465-b254-5ca083816545	58	09:28-09:36	f
1336	b4e7a6c1-3290-4161-b73c-47570c0bf50f	58	09:36-09:44	f
1337	60c6d482-fef2-4de5-ab1f-b04cc25685ef	58	09:44-09:52	f
1338	a599ad2f-9db5-4fe1-b6c2-77504f3cfe0e	58	09:52-10:00	f
1339	94e1d88a-4a7b-42c4-a6f5-d147c1570b44	58	10:00-10:08	f
1340	215c932c-dc89-4771-b635-e83e1e32d680	58	10:08-10:16	f
1341	81e99b95-95bf-425b-9dae-65ca694ef0b9	58	10:16-10:24	f
1342	7790582f-e7aa-4a37-851c-a1d625882da2	58	10:24-10:32	f
1343	b237bb8d-76cf-4364-b3cf-bf97ada08cec	58	10:32-10:40	f
1344	bda7a926-da72-4260-9400-3bef702dcd21	58	10:40-10:48	f
1345	91372847-8f86-4c09-b5eb-38739cf46ece	58	10:48-10:56	f
1346	a5cd2541-4fc9-4327-abf7-1d0c0e84e7bf	58	10:56-11:04	f
1347	3186f398-91df-4cfe-895b-8eb26e248eae	58	11:04-11:12	f
1348	d2fbbb10-7505-4f50-8036-a1f0bc43ef3f	58	11:12-11:20	f
1349	236a9ec5-7d08-42ab-a2e3-8993755e4073	58	11:20-11:28	f
1350	82a07870-082e-4757-a0d4-e99f659fcb42	58	11:28-11:36	f
1351	142c06bd-3058-4da5-bd5e-e74f6362d1b4	58	11:36-11:44	f
1352	acf3c777-bc23-48b1-a62a-599e784e55f1	58	11:44-11:52	f
1353	efe5c701-9a35-4a50-9b48-263cfccd9f27	58	11:52-12:00	f
1354	a9bc0d21-0672-44aa-b233-990bbd978260	59	13:00-13:08	f
1355	f3ae3538-0d33-4dc6-b4ad-01542e755f12	59	13:08-13:16	f
1356	b616e16f-b434-428d-b346-c781a30269b3	59	13:16-13:24	f
1357	9d07d8d8-db79-4aa8-a49b-30bbdf315db0	59	13:24-13:32	f
1358	e06a49d6-011e-45ea-bc66-1256f160b45b	59	13:32-13:40	f
1359	804b1767-fbb9-442e-a0c5-55e0dad0c984	59	13:40-13:48	f
1360	00a8f46a-961b-4348-ad4b-a990ecdd1379	59	13:48-13:56	f
1361	1ae157ab-9de0-4bea-ba97-e1b017b4e4b5	59	13:56-14:04	f
1362	d352a19f-3909-4b7d-9cb0-71b6dacf344b	59	14:04-14:12	f
1363	7aa0ee56-533c-49a1-9322-d1229cbfbde0	59	14:12-14:20	f
1364	b08ebc27-40e2-4d5b-9352-120fed2f9a06	59	14:20-14:28	f
1365	0f7fc859-4819-4e7b-962e-74c4c2a9f93e	59	14:28-14:36	f
1366	2ca8250c-3bd7-4080-bc0d-12c04f5a70d2	59	14:36-14:44	f
1367	47878c68-f797-49df-b5d3-69ee4b4ca65b	59	14:44-14:52	f
1368	8bfc5af7-9232-4487-8aca-52ec9169291e	59	14:52-15:00	f
1369	ef1ee68b-b0fc-4b4a-8dc8-e33d18fb2844	59	15:00-15:08	f
1370	759e8cf8-b1c5-467a-8be6-93666ea91247	59	15:08-15:16	f
1371	729a75b3-dbf5-4e97-9ab0-daffb3be8dfb	59	15:16-15:24	f
1372	1f85cc99-7020-483c-b144-e789f79233f1	59	15:24-15:32	f
1373	4150ae80-1373-43db-8bd5-3a088cc55bc7	59	15:32-15:40	f
1374	e0a0dd6a-2081-4ef7-a1d1-393777f33cf1	59	15:40-15:48	f
1375	9c5271ea-a711-4297-8b75-03d7056f2c79	59	15:48-15:56	f
1376	9b4683e9-3b8d-4e86-ac37-05d166187c1d	59	15:56-16:04	f
1377	939a9b3b-28d0-430b-bcd7-27bb5299912a	59	16:04-16:12	f
1378	8c3967a4-f1ac-42a5-b53d-946e1355a5a8	59	16:12-16:20	f
1379	22925883-3abe-47cc-bba7-cb426e0c3666	59	16:20-16:28	f
1380	b869944f-e875-4357-8ed4-20affcb754ae	59	16:28-16:36	f
1381	8d965879-ef4e-4141-8ff1-928a419dff10	59	16:36-16:44	f
1382	9972e798-af87-47af-a4b1-552f48ad9998	59	16:44-16:52	f
1383	4dfcca76-fb85-4506-b1e3-7a86b5cb259c	59	16:52-17:00	f
1384	39ccffb0-632b-4f02-a60a-7add1c14030d	60	08:00-08:08	f
1385	34585c30-31ed-4b36-8e10-4e8e555160cb	60	08:08-08:16	f
1386	4ee791f8-e082-4c46-ae03-c132ab690f7d	60	08:16-08:24	f
1387	dbd433e4-18b5-4a19-a705-5c7b9c98e1a1	60	08:24-08:32	f
1388	c444a631-9197-4b39-b1a9-b2624f6ad468	60	08:32-08:40	f
1389	29853e5c-dbe2-4955-8ce5-3c61481b3d87	60	08:40-08:48	f
1390	31a56339-a33b-4313-b01a-6c3842a995a9	60	08:48-08:56	f
1391	f4050088-3b65-4232-abe4-20e4ee907879	60	08:56-09:04	f
1392	f30383b3-041c-4093-8949-af7bd0f72881	60	09:04-09:12	f
1393	fc19a824-8020-41f4-991f-a193a784a639	60	09:12-09:20	f
1394	4e33df2a-d860-4a13-9f60-f0b983a22858	60	09:20-09:28	f
1395	c0280514-48a3-4949-bd41-4294bae9c993	60	09:28-09:36	f
1396	91856f97-5bc0-4cdb-aae0-66d2fa863712	60	09:36-09:44	f
1397	956ed73b-3f40-4a48-8387-d3945d5b64fb	60	09:44-09:52	f
1398	9766544c-3746-4b62-8917-bfa9f9165b6b	60	09:52-10:00	f
1399	b3d3c096-83a6-4af7-b67f-815bb411d59e	60	10:00-10:08	f
1400	498bd0c7-bb2d-4ac5-9938-3e5317161d49	60	10:08-10:16	f
1401	2d168527-bd98-488d-861f-8534c16dc41c	60	10:16-10:24	f
1402	66808601-35ad-41e6-b13f-d627e1c94c22	60	10:24-10:32	f
1403	ce561129-bc9d-4c05-9ce3-ce3045c102e5	60	10:32-10:40	f
1404	844e91ac-4305-4404-9d0c-9bf9ea51504b	60	10:40-10:48	f
1405	769dc2c9-d924-4e7e-afc1-fecff25678cd	60	10:48-10:56	f
1406	636ee0d3-358e-413f-a109-6cf709f49ed8	60	10:56-11:04	f
1407	aaec2e23-98b2-4254-b5f1-dfc778a73fe4	60	11:04-11:12	f
1408	aa3f3d5f-1844-4584-9359-64b3d97ecbf2	60	11:12-11:20	f
1409	03e3562b-2a33-424d-80de-233252a4aefa	60	11:20-11:28	f
1410	43a5c4d0-a4b9-47d8-b6ea-6cfa5e15e1a2	60	11:28-11:36	f
1411	75b74a8b-8e23-4ff7-93ac-ae0d6fdfc454	60	11:36-11:44	f
1412	bc73ab85-7c61-40b0-b581-8091a80954bc	60	11:44-11:52	f
1413	b80878e2-e314-43d1-85fe-4de354ff4afc	60	11:52-12:00	f
1414	2f6035d8-4b01-4422-9025-65bc74ad53d6	61	13:00-13:08	f
1415	ae7240d9-6d68-42cd-ae11-c3c5615ca4f6	61	13:08-13:16	f
1416	ae0c1aac-e4d5-481b-9f15-203fdd5272cc	61	13:16-13:24	f
1417	59a39e5f-0359-41cf-ad86-cb3709daa90f	61	13:24-13:32	f
1418	d41f47df-410b-40d7-a2ff-50b2eac51c40	61	13:32-13:40	f
1419	1a573fdb-a3bd-43ef-b61d-7a5033bf3735	61	13:40-13:48	f
1420	c35317a2-8932-4466-8237-6b36af7b37d6	61	13:48-13:56	f
1421	597cdcc7-ce4b-4bc7-b469-c0187eb55f1b	61	13:56-14:04	f
1422	55154a2d-0c47-461e-ac6f-04335086b985	61	14:04-14:12	f
1423	592b2508-145e-4d3a-8235-e645c3edb320	61	14:12-14:20	f
1424	7f8bace8-f137-4867-a13a-5d3f61bbfb49	61	14:20-14:28	f
1425	dda28f94-69b1-4ab6-942e-818f000737c2	61	14:28-14:36	f
1426	f68bc1e2-ab17-41e0-bdf4-7900024626f4	61	14:36-14:44	f
1427	30cc301c-8afa-465f-9da7-6823fe10ccd4	61	14:44-14:52	f
1428	da57d631-1919-4c5c-832b-13a90955411b	61	14:52-15:00	f
1429	25504dd8-9eb7-443b-bd8a-eddede317e35	61	15:00-15:08	f
1430	0024f1de-4d84-4c25-b05e-a085eb6e68bd	61	15:08-15:16	f
1431	7bec6950-ac1e-4abd-87f7-0ef030809ba1	61	15:16-15:24	f
1432	bec80b56-2279-458d-b9b8-113d3abd5ec5	61	15:24-15:32	f
1433	19c9da3e-8d2d-4bf3-9ecc-496adff3ba4f	61	15:32-15:40	f
1434	71434cbc-2376-4717-94c4-3b1e1f0c2295	61	15:40-15:48	f
1435	36967d7a-0ff0-449b-8345-e847e9c0b502	61	15:48-15:56	f
1436	1c294c24-db0d-4a25-85c2-c523c99811a6	61	15:56-16:04	f
1437	f5bf9684-643b-4c77-8193-080d2180bd4f	61	16:04-16:12	f
1438	c87b3461-7f6d-4331-bf20-006302428e01	61	16:12-16:20	f
1439	509e1dfb-e2f3-47f6-a039-91cb449875ec	61	16:20-16:28	f
1440	5a499105-ff86-49da-bc38-4c81f45795de	61	16:28-16:36	f
1441	64d53b29-9cac-4ccf-9653-51c591f78043	61	16:36-16:44	f
1442	feecfef1-95fd-4398-aae5-f4d81bef8ec8	61	16:44-16:52	f
1443	c48cae64-5e49-4a4c-95ce-391adc7e3e0d	61	16:52-17:00	f
1444	f9b4e026-60c6-4da6-bd6b-4e2be01f1e55	62	08:00-08:08	f
1445	67bddbde-75de-4edf-b05b-145ee5a0090e	62	08:08-08:16	f
1446	cf4892a3-2edc-4b58-b060-06c21c00595c	62	08:16-08:24	f
1447	f522cc80-0f4e-4667-837b-c1eec19671f3	62	08:24-08:32	f
1448	e320313d-e4f0-49b3-a661-544a8d26f40a	62	08:32-08:40	f
1449	e0a58e9b-b11c-481a-b5d0-22ae0b4c5f0e	62	08:40-08:48	f
1450	1a76c914-e314-4e93-9a95-41ec09351586	62	08:48-08:56	f
1451	0e4e9654-a8e7-4ae8-be36-bb4591814733	62	08:56-09:04	f
1452	0a9b547f-8e95-4d6c-bd49-ff77ffca5823	62	09:04-09:12	f
1453	90597df3-845c-47b8-8d3a-d722c3dd44a5	62	09:12-09:20	f
1454	823b52f8-dd9f-4d8c-95a5-5e45fd586064	62	09:20-09:28	f
1455	eba94a76-7d14-4b93-acb8-3bdd3d390c65	62	09:28-09:36	f
1456	4695ef04-e162-4f8c-924a-d0a06223e464	62	09:36-09:44	f
1457	d561e109-750d-4513-8d33-00a7368adcf7	62	09:44-09:52	f
1458	28d32555-9603-41af-8ad6-a02442b34930	62	09:52-10:00	f
1459	75133cbe-ef1b-408f-9938-77a7b6680c18	62	10:00-10:08	f
1460	0f99a1ab-b5e7-48c5-89e8-032cbc6b66fe	62	10:08-10:16	f
1461	1a455568-60a6-4664-932e-9ac618f758c8	62	10:16-10:24	f
1462	373c33f2-7995-43f7-8195-1f3d2d36e1dd	62	10:24-10:32	f
1463	afbccce9-ea1a-40e2-8963-c1611286ab45	62	10:32-10:40	f
1464	a8fb4f5f-3c9a-424b-9bc4-b6aee0269055	62	10:40-10:48	f
1465	83c9d578-b787-44e4-ad00-3ab8d10ac821	62	10:48-10:56	f
1466	185e0b0d-a047-486f-bb27-f84e138d5801	62	10:56-11:04	f
1467	9c1f9404-046e-466a-af82-aba7f01d1d31	62	11:04-11:12	f
1468	256e654b-53b6-4548-8364-6a51b5719b26	62	11:12-11:20	f
1469	58dd83fa-ef71-4563-9ec5-f28c538389d5	62	11:20-11:28	f
1470	ec9dcef8-264c-441c-9c93-c310d78cad27	62	11:28-11:36	f
1471	fdc7a3f5-319f-44ab-b7a4-4ba62ea95616	62	11:36-11:44	f
1472	5aef89e7-6fb8-4733-831f-4f75c1f552b9	62	11:44-11:52	f
1473	5c8dff4e-a029-4381-8409-703edef77637	62	11:52-12:00	f
1474	6f308698-c5c8-4659-94dc-1483c0113e18	63	13:00-13:08	f
1475	aaa23121-5224-41ee-b622-4f5f27a106c3	63	13:08-13:16	f
1476	6046a4f6-86c0-4ca1-9fe2-4acf1a8b43b0	63	13:16-13:24	f
1477	cab3f28b-3706-441e-ba28-b8811a669520	63	13:24-13:32	f
1478	72144c39-2cf2-483b-8df2-a52af80d60f4	63	13:32-13:40	f
1479	8f32d576-d687-45a9-b391-2123ac295b85	63	13:40-13:48	f
1480	77b5db42-c254-4d79-8909-b1d85db59b73	63	13:48-13:56	f
1481	9a805da1-37a8-4fd4-bb2a-3ef4f21c1e60	63	13:56-14:04	f
1482	17dd96df-9f1b-40a7-b3e6-ccc413fa0da6	63	14:04-14:12	f
1483	06c145c9-024e-41d0-b4e2-e80c923f1563	63	14:12-14:20	f
1484	f8ceea15-d76c-4332-a76e-3e5fabf79aff	63	14:20-14:28	f
1485	f103591f-71f3-494a-86c7-e33c0961a607	63	14:28-14:36	f
1486	fef85b3a-3561-4f9f-acd3-4bf9d7d320e6	63	14:36-14:44	f
1487	1a469592-429e-490a-855e-62f41aaff0b0	63	14:44-14:52	f
1488	43a92912-63ba-4b16-9109-ac6bb5658b0b	63	14:52-15:00	f
1489	760768d7-e3ee-4676-a67d-072b6ac0a926	63	15:00-15:08	f
1490	6219e177-91f8-4c04-b27e-f82c8b2e3e4c	63	15:08-15:16	f
1491	af9b7552-5d45-47ed-afba-578bf39fb9a8	63	15:16-15:24	f
1492	ffb45094-fe9f-4460-9851-d6aace5fb2fe	63	15:24-15:32	f
1493	6dd556e5-f0c1-48fd-9590-0adc4491d4a3	63	15:32-15:40	f
1494	f16b1a81-cae9-4a6c-a155-96f01885a109	63	15:40-15:48	f
1495	76f160d4-b0b4-415e-8044-4cc1fa3aa506	63	15:48-15:56	f
1496	8da5400f-7140-4264-8f54-dba49f8bc780	63	15:56-16:04	f
1497	5893aaad-c8e8-4efa-8171-282fb7c676ea	63	16:04-16:12	f
1498	72532345-a85b-4a12-87d0-3b9dbf477aa6	63	16:12-16:20	f
1499	9c4190e0-cc7a-4095-929b-a7a78ff3d03a	63	16:20-16:28	f
1500	e12a807a-3e76-488a-9ea0-688df0a18ce5	63	16:28-16:36	f
1501	55f1b8f5-a933-4657-ae35-10b1a7ce2ee7	63	16:36-16:44	f
1502	67718ecc-6751-49da-a9f0-088957486203	63	16:44-16:52	f
1503	39ded8cc-b21f-4f52-8b85-c9aa2c3e748d	63	16:52-17:00	f
1504	9301d48f-657b-4cef-a33d-406188118888	64	08:00-08:08	f
1505	e7beb2ac-da00-4c38-97b8-4b03e69d07ee	64	08:08-08:16	f
1506	37cf35e4-5efe-40e5-b589-e33ab4796757	64	08:16-08:24	f
1507	2970b81d-9b8e-421d-b41d-26a3bc708453	64	08:24-08:32	f
1508	e8c37ebf-d1cd-419f-ae1f-7cbd0a8925aa	64	08:32-08:40	f
1509	2de76019-064e-4ba3-8f9f-b97a7f43002a	64	08:40-08:48	f
1510	32b19a42-5c7c-4232-9972-f5a3ceb9efda	64	08:48-08:56	f
1511	f18bb7b7-e0f0-4a64-a61f-7084b1df2eda	64	08:56-09:04	f
1512	80fb971d-6a1f-414d-aa99-687daf391a4e	64	09:04-09:12	f
1513	0fd6e210-bf62-44d7-a707-752a384ade3a	64	09:12-09:20	f
1514	599954cd-4dab-4aea-8a5a-52a6f37d6291	64	09:20-09:28	f
1515	a22ea577-bff6-47d5-8929-6ecea3150edd	64	09:28-09:36	f
1516	ad53fc51-da3b-48cd-be61-37699903d0fa	64	09:36-09:44	f
1517	77585f45-2a32-4366-8eb6-0303820de074	64	09:44-09:52	f
1518	3aa1dafc-e532-4677-83a4-2e028ed296b8	64	09:52-10:00	f
1519	b24b7772-867b-4f59-b47b-3d1034bdb886	64	10:00-10:08	f
1520	ee9bf43f-8da6-4ea5-a0c4-a8f38f463443	64	10:08-10:16	f
1521	f38987cd-6b81-450c-8202-54a51e20523b	64	10:16-10:24	f
1522	f22420f1-7cfd-4e8e-9668-36c7f3cfa7cc	64	10:24-10:32	f
1523	3487335e-980b-42d7-b33f-b5225ac8442c	64	10:32-10:40	f
1524	ec301eaa-ed6c-4e23-a529-75ed974d434c	64	10:40-10:48	f
1525	290a04d7-2776-4b90-8b58-0b20a9202a62	64	10:48-10:56	f
1526	4efe3340-c58d-430c-b566-e00635beb0d7	64	10:56-11:04	f
1527	19369cf9-743d-4b99-adbe-37fb84ecc98d	64	11:04-11:12	f
1528	97d2f44e-9056-4e85-9fd4-162b8a5aa32e	64	11:12-11:20	f
1529	859040d4-1f8f-41ac-893d-7d307e6cb2ca	64	11:20-11:28	f
1530	cf43dc1c-a39a-42f9-b60a-9b32ec45dca0	64	11:28-11:36	f
1531	7279518f-03f4-45cc-bb43-8d9420985182	64	11:36-11:44	f
1532	a70d8d71-eef0-4bc3-8dea-ea72a046f7df	64	11:44-11:52	f
1533	72ef534c-2bf7-4076-8cfb-df94491b0f65	64	11:52-12:00	f
1534	7db80738-3ccf-4998-bffe-cd37b1825884	65	13:00-13:08	f
1535	0e1b5234-27d3-47d1-afc7-e833996e376c	65	13:08-13:16	f
1536	690a8ff9-3228-43b4-a755-77fa81640807	65	13:16-13:24	f
1537	48b9af53-604a-4d2b-8c5c-c29c3aa2ec92	65	13:24-13:32	f
1538	b1a21e01-ad83-41c3-9cb9-43815f63bd78	65	13:32-13:40	f
1539	ab81a7a7-a652-4895-83a0-2d974ad2c93b	65	13:40-13:48	f
1540	39ffa8a8-825c-4fe0-ae6c-8a82e4d17693	65	13:48-13:56	f
1541	5f426a27-45e5-411d-9629-5ee43749acd4	65	13:56-14:04	f
1542	75f5562c-37a7-430a-bed6-115ed896baf2	65	14:04-14:12	f
1543	42d23b56-e246-442c-8604-bc06a714aa3c	65	14:12-14:20	f
1544	67fdc8e5-b01c-486a-91c6-83ef39723486	65	14:20-14:28	f
1545	2be78523-84bc-4568-a639-6caed319e4a8	65	14:28-14:36	f
1546	3cd672b8-7b5c-4110-91fa-447a20ad755c	65	14:36-14:44	f
1547	6c8bf0f3-ce1e-4a12-880c-5a99c1250401	65	14:44-14:52	f
1548	858fb9c3-5963-4ce9-9397-b7d541d5dce3	65	14:52-15:00	f
1549	2009b47a-baae-4798-94a4-e5883b64858a	65	15:00-15:08	f
1550	986ec305-5b86-467e-9e21-97304e5daded	65	15:08-15:16	f
1551	3a92ea50-1e5e-4237-bb60-52454c9bac9d	65	15:16-15:24	f
1552	65cc2889-91db-45ed-87f6-da372273f27a	65	15:24-15:32	f
1553	c4f540c1-d0d3-4601-8494-42fa82a7554f	65	15:32-15:40	f
1554	9aac7838-8a41-4e53-a68e-86a6f1daa4d9	65	15:40-15:48	f
1555	b461e7f2-cc21-4386-8cc5-f05290d55b6f	65	15:48-15:56	f
1556	7e52d3cf-a995-4f76-9a7f-4ca9ec6db302	65	15:56-16:04	f
1557	d9e38301-3c9c-4981-8985-aa9a3c737372	65	16:04-16:12	f
1558	e8ea6843-5834-4275-a29a-6505414aeefd	65	16:12-16:20	f
1559	fb6395a8-8c1f-484b-b530-be5ff87959c8	65	16:20-16:28	f
1560	78e03c8a-1953-4485-b39a-be9abcdb95df	65	16:28-16:36	f
1561	ec802b76-6fae-4fc4-b3d8-886603b86344	65	16:36-16:44	f
1562	fcf645c0-5ba7-49d5-bf7e-966e4b675c97	65	16:44-16:52	f
1563	d184f67e-cbc2-4f71-af6c-88dd52c82c04	65	16:52-17:00	f
1564	6305d5f9-680f-4cf5-9520-3f62021fdd9b	66	08:00-08:08	f
1565	efee13fc-8f04-4b2b-9d17-d86304a5e537	66	08:08-08:16	f
1566	66aab5a4-bce5-4d67-b0e3-4348156735d1	66	08:16-08:24	f
1567	2ef38111-3664-42d9-8c7c-1ad469f4e636	66	08:24-08:32	f
1568	521406db-17d0-4fd0-a108-4456f08c5b79	66	08:32-08:40	f
1569	3ec5e195-da94-46b0-b1f9-22e0646bdc4c	66	08:40-08:48	f
1570	dcb0bf87-267d-4800-ab4f-ecc7843dbbbf	66	08:48-08:56	f
1571	76a614cd-3ebd-4f63-8692-13fd0a8690cc	66	08:56-09:04	f
1572	4f1b6007-9dec-44df-be1a-8a466c7c6823	66	09:04-09:12	f
1573	ca3ab1ae-ee94-47cc-88a8-32c139407012	66	09:12-09:20	f
1574	74ebf865-ab63-4040-929b-28dbec663d08	66	09:20-09:28	f
1575	27121567-dac6-417d-80b3-033b106a77cd	66	09:28-09:36	f
1576	ad21c633-f7eb-4830-a9a6-986aa6e772c9	66	09:36-09:44	f
1577	993eab74-93f0-4006-9a58-f58af67d50b0	66	09:44-09:52	f
1578	2ca03461-3dcf-4572-b16b-470e591c1e0e	66	09:52-10:00	f
1579	5906c31b-aa84-44a3-8417-2d874a24a2f1	66	10:00-10:08	f
1580	013f7050-f298-41b7-b134-f31b29e79479	66	10:08-10:16	f
1581	b3be1bf7-1caa-4db0-8b35-d555240ed19f	66	10:16-10:24	f
1582	1666458e-97d6-4fa2-8cca-64904612f21c	66	10:24-10:32	f
1583	f1194a55-4341-4438-879c-aa8247cf0256	66	10:32-10:40	f
1584	a890726a-a587-4895-8db5-ba3ec36f4b7b	66	10:40-10:48	f
1585	f6c48368-9bbc-4b2f-a355-eb9256108436	66	10:48-10:56	f
1586	12b975f7-ae4f-49bb-87db-6b9bd68a725b	66	10:56-11:04	f
1587	dae39f14-5e5f-4290-aa7e-26aa5d7f2fbf	66	11:04-11:12	f
1588	0548ecd2-47fe-4c07-bc27-353a6ac7efa0	66	11:12-11:20	f
1589	a7f28b12-1d45-4797-9f85-9fb0c8994b7f	66	11:20-11:28	f
1590	c1cae85f-73e9-48ce-8e30-6700429f1028	66	11:28-11:36	f
1591	fdfa9617-8300-44c9-ac34-862b99ccadcd	66	11:36-11:44	f
1592	93d876e1-2fe6-4d18-b9df-2e109fbbe575	66	11:44-11:52	f
1593	7d6feb96-1835-4190-ab38-ac28a681642d	66	11:52-12:00	f
1594	b2f041a0-315f-40d9-9ce5-b9bad1e3673b	67	13:00-13:08	f
1595	38f3a0e3-6ffc-455a-8551-40e807d3ac25	67	13:08-13:16	f
1596	5f9104c6-a378-4640-9742-6c8d29be63de	67	13:16-13:24	f
1597	533fccae-011f-46c7-b409-36ad07834ecd	67	13:24-13:32	f
1598	7810f85f-2c17-4bb0-b9b3-c3c8bba50e96	67	13:32-13:40	f
1599	355283e4-10d4-4d39-a7cf-ec9ce7fe047f	67	13:40-13:48	f
1600	e56fcfb5-1aec-4bee-b6c4-e21cf1cfc15e	67	13:48-13:56	f
1601	634d2732-1c78-47f3-964e-ed8b15ffd31a	67	13:56-14:04	f
1602	789cb75b-cd86-4ad2-864b-0f2a4b5053c3	67	14:04-14:12	f
1603	ab57edf5-ac7b-47f2-bf22-cbecf2e70760	67	14:12-14:20	f
1604	fd54717e-7bc5-4e3d-b86e-191e30584e21	67	14:20-14:28	f
1605	8ac511c3-1b27-46b2-bea5-5d2e77ca4a10	67	14:28-14:36	f
1606	cd0fb7f3-ad28-4d34-9f48-7394ef0ebc67	67	14:36-14:44	f
1607	ebfdf62e-81c1-4ef5-aa32-814763b6e110	67	14:44-14:52	f
1608	f10bc065-8248-4e93-8592-ae4f99282920	67	14:52-15:00	f
1609	0c5f8a40-4628-4cae-866f-0f0da6925dcf	67	15:00-15:08	f
1610	c24fcef8-f1b3-4584-b79d-0a968e3731c2	67	15:08-15:16	f
1611	7af8c6b6-eb4e-475f-af28-387d912ae9b3	67	15:16-15:24	f
1612	61271d05-01b8-403e-969b-e22226fa362d	67	15:24-15:32	f
1613	0dbb61f9-213b-4147-8714-24d9997a9260	67	15:32-15:40	f
1614	3b3b3746-13ff-461b-8bd5-48e3a0adb613	67	15:40-15:48	f
1615	1e64b12c-0f22-4da5-95d6-29e99e99b6af	67	15:48-15:56	f
1616	adf3848e-21c8-42e5-9249-71c9330b226b	67	15:56-16:04	f
1617	642cfc4f-cbf1-411c-9bb4-671fdf1eddd5	67	16:04-16:12	f
1618	72c516c5-6bec-4121-a092-b6994a4dbe0b	67	16:12-16:20	f
1619	474780f7-898e-4659-9adf-2ce4a9e9d46c	67	16:20-16:28	f
1620	ca6e0214-6c75-43fd-b88a-3ee1c205b742	67	16:28-16:36	f
1621	61497ad1-6868-4459-9df6-207d87709253	67	16:36-16:44	f
1622	10926471-61a5-4192-a461-07b8a1d65046	67	16:44-16:52	f
1623	70f5b54a-e5d8-43c4-8d67-69023587b2a6	67	16:52-17:00	f
1624	8d7af0e5-d91b-48fd-8d8f-a3d32d2c2f33	68	08:00-08:08	f
1625	b42f208a-90f6-41ed-b579-dc436698f364	68	08:08-08:16	f
1626	fee6390b-01cb-4b2f-92a0-4b4621ab2124	68	08:16-08:24	f
1627	67fcff12-0306-4c95-bfee-998038e00725	68	08:24-08:32	f
1628	ca81fe44-2acf-4673-9e87-d51675844f81	68	08:32-08:40	f
1629	4925bb8d-e6c3-47ad-8f57-6d83211c51c7	68	08:40-08:48	f
1630	7b32f33c-2592-4e93-bd6d-79d55fe25f53	68	08:48-08:56	f
1631	db796658-170b-4652-8f4e-dde5d9a9760d	68	08:56-09:04	f
1632	8ac00ff3-bfbf-42c7-a2b7-e56dc21c42a5	68	09:04-09:12	f
1633	49b9ade1-416a-4462-b1b9-df33b80dc1a4	68	09:12-09:20	f
1634	2f0201d0-84e6-47f7-a846-fdb230acb403	68	09:20-09:28	f
1635	347d558b-2068-460e-81e9-a59555acf3bd	68	09:28-09:36	f
1636	599bc83c-aa74-4322-87c2-faae15cc8c63	68	09:36-09:44	f
1637	12a13a33-1f74-46d8-8a0f-abe23d7d369e	68	09:44-09:52	f
1638	a9bc1e43-e934-4589-be14-5a6201981af0	68	09:52-10:00	f
1639	bc51a29b-aa1e-4647-bfe7-f85abe6cdf3b	68	10:00-10:08	f
1640	bd6c5037-dbb0-4043-ae8a-87bccb7f81c1	68	10:08-10:16	f
1641	affa44ed-6300-43c0-a611-aecee3375c39	68	10:16-10:24	f
1642	89d06d2e-e19c-48cc-b0f3-a982c1278ebb	68	10:24-10:32	f
1643	0b23ec7f-e3da-4720-b1f7-80d790dc648a	68	10:32-10:40	f
1644	250c50d6-6b13-4210-8ad6-a5443880da43	68	10:40-10:48	f
1645	41ecf3e4-1a70-45d8-bd2a-659bd0842c50	68	10:48-10:56	f
1646	3dd8292a-12c4-4ec3-958b-22939d9ffb8e	68	10:56-11:04	f
1647	57f2f401-4620-4d70-b94e-30098ea29ddf	68	11:04-11:12	f
1648	2ef7f7b1-3dce-49b0-8dea-25693fd86723	68	11:12-11:20	f
1649	ddfd0df5-679c-4766-9bd0-1b4d2fb0b982	68	11:20-11:28	f
1650	e36d674e-2432-4349-af0a-8bbbbf0d8118	68	11:28-11:36	f
1651	d5153213-3388-4135-aa0a-b0d1ac8421dd	68	11:36-11:44	f
1652	6afe46bb-11d5-458a-80fc-f5cb4dd76c4e	68	11:44-11:52	f
1653	ac1a213d-966f-46ef-86fe-dfe2ea4778f5	68	11:52-12:00	f
1654	c1a16180-cea2-49ba-a121-3d16778b8ec8	69	13:00-13:08	f
1655	b2b07ebb-80f7-42c3-ad65-e29b5f856015	69	13:08-13:16	f
1656	3c4273b9-7b41-4b2f-8e0e-cbd17396fab3	69	13:16-13:24	f
1657	cc2c9cf1-09fa-485f-bae8-ecf30cd5e7e7	69	13:24-13:32	f
1658	2ef167e4-063b-4edd-99e7-64e55c73f93d	69	13:32-13:40	f
1659	ae0b16a9-d62e-47f0-aa8f-e8acaa24b683	69	13:40-13:48	f
1660	ae5dfd0f-e2c3-41b2-a08f-23af35336ef9	69	13:48-13:56	f
1661	5c4702df-1e4f-4667-bded-7050f188ae42	69	13:56-14:04	f
1662	3ab53dd1-2742-4a50-9866-a09b3a4c7961	69	14:04-14:12	f
1663	4ffd38f0-6f2f-4eba-8fec-de3db0b508a2	69	14:12-14:20	f
1664	e1cb2674-a5f1-463a-bab4-a8b73ecc49b0	69	14:20-14:28	f
1665	8481b878-5652-4c9c-bfb4-1a0a7f7ea37e	69	14:28-14:36	f
1666	ca2c6cc6-7cbb-46b6-942a-f439a6124593	69	14:36-14:44	f
1667	e4d4919d-1df5-43cc-ad51-a8957ad1efb1	69	14:44-14:52	f
1668	7244f50c-238d-4321-a2f1-12a8c04f94bd	69	14:52-15:00	f
1669	63b6b8e9-0cf1-4b97-a78f-6718ee1a4ae8	69	15:00-15:08	f
1670	e6265a81-071b-4462-8811-e2763bd8e4f9	69	15:08-15:16	f
1671	f1c58de4-41fe-4f13-88b4-a7a6028a481c	69	15:16-15:24	f
1672	acbd7887-db18-4b2d-9d51-50b4c8d77619	69	15:24-15:32	f
1673	77b88823-ae9e-452d-af87-9280146cc00d	69	15:32-15:40	f
1674	6502e7e0-1f57-401b-9603-8c6f1aab10fb	69	15:40-15:48	f
1675	3fd22a07-2108-4543-bb9e-6c8e0c55b07e	69	15:48-15:56	f
1676	fae6e4e0-0916-4071-8763-82ce334757fd	69	15:56-16:04	f
1677	e426a9bc-9ce0-47c3-9062-ab6dad98a18a	69	16:04-16:12	f
1678	fb4a123f-9123-4f79-97bb-072b923f7b5b	69	16:12-16:20	f
1679	dc5ffeae-bf4b-42cd-8bfe-364dd6154f96	69	16:20-16:28	f
1680	b42cbfaf-2f10-4817-b848-4674d3522d1e	69	16:28-16:36	f
1681	1fef631d-6b67-4ff5-88e3-7b441cc37241	69	16:36-16:44	f
1682	106ce333-ad92-498f-81c1-17ed35a357e6	69	16:44-16:52	f
1683	ba9fd097-d1cb-424c-b089-33ff7a032e25	69	16:52-17:00	f
1684	15039958-0f43-4a28-8392-bf8d85581581	70	08:00-08:08	f
1685	5b3016a2-9a76-4149-9273-dcd1a3c95df6	70	08:08-08:16	f
1686	06640b05-6fb7-4cd1-9766-7b5112809894	70	08:16-08:24	f
1687	20254e65-89ba-4c10-bdbc-d9b5fb47994d	70	08:24-08:32	f
1688	9d6861d0-b5f6-4d0d-a84e-0fd78fb232de	70	08:32-08:40	f
1689	92108567-e351-41d6-90b2-76d8b42d9895	70	08:40-08:48	f
1690	9b73d7a4-6287-45f3-bc06-085502ecc7b1	70	08:48-08:56	f
1691	833d80a6-1916-4716-a490-61d66e398c3d	70	08:56-09:04	f
1692	35e801af-4661-468f-84d1-9a28964e76b3	70	09:04-09:12	f
1693	63b9d95a-0ce0-4116-9512-fb52b0ccf149	70	09:12-09:20	f
1694	e24b890c-427e-4d66-a625-8dea2a3084d9	70	09:20-09:28	f
1695	5e6a2b46-81a9-40bc-a147-cff8a07d3b8b	70	09:28-09:36	f
1696	82133dae-2c6f-47af-8fbe-9e96d363184f	70	09:36-09:44	f
1697	9600bbd5-4234-4724-9dcf-28ddac4b5d4d	70	09:44-09:52	f
1698	169a3466-cde0-471a-9013-11818b0bc8f5	70	09:52-10:00	f
1699	5c59b72c-858a-42d2-a4e8-3248a8b619af	70	10:00-10:08	f
1700	7277789d-3281-4710-bc80-df9422d4618f	70	10:08-10:16	f
1701	46f4976d-d8be-4e53-94da-219eae68161e	70	10:16-10:24	f
1702	c531a986-4b83-449b-934c-911045eb50a8	70	10:24-10:32	f
1703	4aa30ba0-edb9-4566-89fa-3fb5c475031f	70	10:32-10:40	f
1704	ab07df75-93ac-4b78-89e9-ea473fa51759	70	10:40-10:48	f
1705	b6937054-e924-4331-948d-3174a7d015d5	70	10:48-10:56	f
1706	a1e56e8c-5f4c-4c07-b11f-b0318ad06f53	70	10:56-11:04	f
1707	3203c964-2c17-4b4b-97bd-d7f513304701	70	11:04-11:12	f
1708	ac1b5e62-103b-4740-b5c4-1ef6c5c9a424	70	11:12-11:20	f
1709	be60319d-8f71-4df5-aa49-cbff0b0c27d5	70	11:20-11:28	f
1710	defd6b27-6599-461c-80d5-145ba1210744	70	11:28-11:36	f
1711	b1410d94-7c15-4bb3-a158-d4c6e9fed98c	70	11:36-11:44	f
1712	eac2b5d9-b3e9-49e2-9f6e-396699d194af	70	11:44-11:52	f
1713	5610fcff-6d8d-4a0f-a994-86858d272762	70	11:52-12:00	f
1714	a8d0c89d-5ab2-4dbd-99f2-d4b4bc1eea8c	71	13:00-13:08	f
1715	bbeb829f-046c-48be-85e8-8c093d33cc29	71	13:08-13:16	f
1716	47c8c030-111c-4bdd-b1a0-5bdd9dc1c21a	71	13:16-13:24	f
1717	1bec9156-75ee-4822-aed6-ec393e1311df	71	13:24-13:32	f
1718	d80b0358-075f-4b8b-bda7-22f8734134bb	71	13:32-13:40	f
1719	316ff9e1-1c8f-4810-81cb-67d032b152a7	71	13:40-13:48	f
1720	a5a5d386-7e8d-4d8c-a0d6-bfc47d50ae0e	71	13:48-13:56	f
1721	423a69ff-96e7-4843-9a88-20536b5e3306	71	13:56-14:04	f
1722	1bdf15c7-454f-4a57-a2e2-a697740cceb6	71	14:04-14:12	f
1723	251a0172-3db8-40b6-b7e3-fe0ae87e67a1	71	14:12-14:20	f
1724	7fc12731-a8ba-4156-bf6e-14fb169fe4cf	71	14:20-14:28	f
1725	cbcc3a48-8889-4008-bbe3-c77e8ff069c7	71	14:28-14:36	f
1726	f9a3c55f-cb40-4cb4-ad6c-10e81095d556	71	14:36-14:44	f
1727	52739ed3-6a16-4720-ad72-3df44a2d582e	71	14:44-14:52	f
1728	44d5634a-b8c1-4b89-bd46-b7e466ba8539	71	14:52-15:00	f
1729	2f0b8693-b11b-41ec-a3f9-8f1a680b6ebf	71	15:00-15:08	f
1730	aa1d48ed-e068-4ce7-a3db-c33035b3183a	71	15:08-15:16	f
1731	282bd333-d591-4bb3-8cf8-98452c1c9590	71	15:16-15:24	f
1732	c2c0b985-adfb-474a-a094-494bbfb35dc4	71	15:24-15:32	f
1733	a6cdffb9-51d6-40dd-a7a1-18f10dfee59e	71	15:32-15:40	f
1734	44d5a452-29a2-4d45-8056-50e6c8257b0a	71	15:40-15:48	f
1735	ec06f1ae-f90a-45bc-ac72-57c2410933cc	71	15:48-15:56	f
1736	8df75b56-ddaf-46e8-bd08-f10f52766ba9	71	15:56-16:04	f
1737	4c578b83-a16e-402d-b866-c82cf98ffd29	71	16:04-16:12	f
1738	3396cbf5-30b7-49f8-8e5b-6719cbb67629	71	16:12-16:20	f
1739	37a10f72-5002-4c33-a4fc-e473312a89aa	71	16:20-16:28	f
1740	def70904-f031-4a1d-9eb2-3c1a221ca576	71	16:28-16:36	f
1741	5f2d6840-9f70-43be-a5a0-3248d21b390b	71	16:36-16:44	f
1742	355b8f57-a222-48d4-8a19-e56552c5be4f	71	16:44-16:52	f
1743	89ba59b7-3682-48a2-8084-e9f66100d41f	71	16:52-17:00	f
1744	e3926a28-cdc9-41ef-a687-99c38a20ff80	72	08:00-08:08	f
1745	c8dddae7-ee91-463e-b2a0-145bd73cc9ae	72	08:08-08:16	f
1746	2ebe1f5d-dc91-4780-a830-7eb2b766efd6	72	08:16-08:24	f
1747	8dbe1620-9e16-41aa-ad43-ef5d523ef1b9	72	08:24-08:32	f
1748	7d389596-9a63-49aa-8ddd-86eef02c55c9	72	08:32-08:40	f
1749	bd195c7c-e95d-4a28-9692-05221fb21362	72	08:40-08:48	f
1750	543a25a1-ed8a-42f5-a5e3-ab51d3d646bf	72	08:48-08:56	f
1751	93d9a88c-4f83-4c06-8b9e-731921f7d41b	72	08:56-09:04	f
1752	d82c199f-781c-4b66-84ee-667ca39990fb	72	09:04-09:12	f
1753	2c7b6bee-b2ec-47e3-92be-a746cbcca4c6	72	09:12-09:20	f
1754	9e3cbce2-7bb0-4d40-9e7a-d491c84d9b6f	72	09:20-09:28	f
1755	c910f0d6-93be-4bc5-9903-28d7410b522d	72	09:28-09:36	f
1756	4f530f1a-fcda-4791-a270-6a5e29fa4da9	72	09:36-09:44	f
1757	1cc02449-7da8-4af9-a7e0-4954ba00f28c	72	09:44-09:52	f
1758	2a645799-7e7d-461f-99a8-afe0493bf88a	72	09:52-10:00	f
1759	115341d2-41aa-4f17-8e0d-0410c6847b01	72	10:00-10:08	f
1760	98e94432-d9b7-4ed5-b543-f6a1dcbdba14	72	10:08-10:16	f
1761	49fe079b-99d7-4dbd-80f7-7a99d427f18d	72	10:16-10:24	f
1762	35ba2874-8d24-43a0-83fb-db023498b8d7	72	10:24-10:32	f
1763	15f69106-943a-4021-a6d0-71fb48289f73	72	10:32-10:40	f
1764	cccedacb-9163-4010-89a1-7f651192d2aa	72	10:40-10:48	f
1765	afed0ead-b9b2-4de8-ac0a-c528deee5e49	72	10:48-10:56	f
1766	f6bf6408-030d-4565-b23b-b31dea2dc05d	72	10:56-11:04	f
1767	782642e2-26fe-41d0-bd01-bcc79002c1c5	72	11:04-11:12	f
1768	351e8cbc-867d-4ae0-9ec0-0bdb8b3d684d	72	11:12-11:20	f
1769	ed75f412-bc23-450e-a4df-1e8e8161b33a	72	11:20-11:28	f
1770	b0680208-06ad-4e29-81ea-25f714a59bb1	72	11:28-11:36	f
1771	62591f98-eeee-4f61-bff1-268ffc194ba9	72	11:36-11:44	f
1772	4408ba61-5859-438d-abc3-929c32103432	72	11:44-11:52	f
1773	5e8bf9db-2ea7-4a46-9785-8e6cc05f5a53	72	11:52-12:00	f
1774	1a9184da-abb2-4b15-b544-5f34f6cf6a26	73	13:00-13:08	f
1775	73b225cd-4070-4422-81f7-1ff5e0070196	73	13:08-13:16	f
1776	4a8224b5-b9b3-4895-915e-d294ea77587b	73	13:16-13:24	f
1777	f307dd9e-bf2d-4c35-b5ff-5def2f1b0b21	73	13:24-13:32	f
1778	6d5683d4-ac53-4cd8-8d2a-980d01e7c856	73	13:32-13:40	f
1779	6f11a98b-28ad-4709-9a69-ea10dfb4fde7	73	13:40-13:48	f
1780	8849e4c0-03c8-4f5d-a4b9-694c9f2bddb5	73	13:48-13:56	f
1781	f12fd025-a834-4a14-8e6c-3a234949f570	73	13:56-14:04	f
1782	22602b84-43cf-46ab-9cf5-1b8049faa00a	73	14:04-14:12	f
1783	e9137db4-0d59-4fe0-8614-f5c8b650433f	73	14:12-14:20	f
1784	f6ba802e-78f5-4bb1-99a0-0a233e8bd828	73	14:20-14:28	f
1785	e63256db-d05e-480a-8b54-39b06d62a51c	73	14:28-14:36	f
1786	050012f7-e315-43f8-8554-4aabc6da82d6	73	14:36-14:44	f
1787	1fee62a9-0948-4104-9a73-c40e475b6e8d	73	14:44-14:52	f
1788	730ed376-c4e9-4f64-b673-e05756326308	73	14:52-15:00	f
1789	de280cbf-1cc8-4e0e-9259-532b4bda539c	73	15:00-15:08	f
1790	d6f0bced-9ef9-45e0-81c8-2b3da9ead678	73	15:08-15:16	f
1791	5830af41-2b10-40cc-a53f-839b467bf522	73	15:16-15:24	f
1792	14457295-0f78-4535-b0be-aa5eaaeb0179	73	15:24-15:32	f
1793	bf728ae2-afe0-4c22-b4ec-e30eb0195733	73	15:32-15:40	f
1794	3e2700b5-2626-4566-9aa9-0b70fdc5ee47	73	15:40-15:48	f
1795	4ef58478-014a-4c4a-ae57-da32ed4f04fa	73	15:48-15:56	f
1796	90b22696-8ffd-49cf-9a55-c0d7abc7378c	73	15:56-16:04	f
1797	80886f57-930a-48b8-b804-7426ec826ac8	73	16:04-16:12	f
1798	fa56998d-1359-45bb-ae19-8870d649c795	73	16:12-16:20	f
1799	fd42c692-ae06-4a6a-9bd4-6b6659051668	73	16:20-16:28	f
1800	3605c384-0fb7-43ad-9026-354b68c08614	73	16:28-16:36	f
1801	9f5648f0-1b17-4560-adb8-efddf13b8a40	73	16:36-16:44	f
1802	633628be-b072-4926-a967-645af9ac9926	73	16:44-16:52	f
1803	7bb15b19-ff54-4503-b3dd-84b696ddcc3a	73	16:52-17:00	f
305	6f2efb60-d975-452a-aebe-efe366fcf49f	24	08:10-08:20	t
\.


--
-- Data for Name: settle_category; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.settle_category (id, uuid, settle_code, settle_name, delmark) FROM stdin;
1	22222222-2222-2222-2222-222222222222	ZF	自费	1
\.


--
-- Name: check_request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.check_request_id_seq', 24, true);


--
-- Name: clinic_room_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clinic_room_id_seq', 2, true);


--
-- Name: department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.department_id_seq', 1, true);


--
-- Name: disease_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.disease_id_seq', 12, true);


--
-- Name: disposal_request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.disposal_request_id_seq', 1, false);


--
-- Name: drug_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.drug_info_id_seq', 1, false);


--
-- Name: employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.employee_id_seq', 10, true);


--
-- Name: inspection_request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.inspection_request_id_seq', 1, false);


--
-- Name: medical_record_disease_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.medical_record_disease_id_seq', 23, true);


--
-- Name: medical_record_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.medical_record_id_seq', 52, true);


--
-- Name: medical_technology_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.medical_technology_id_seq', 1, false);


--
-- Name: outbox_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.outbox_event_id_seq', 52, true);


--
-- Name: outpatient_bill_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.outpatient_bill_detail_id_seq', 27, true);


--
-- Name: outpatient_bill_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.outpatient_bill_id_seq', 18, true);


--
-- Name: patient_feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.patient_feedback_id_seq', 2, true);


--
-- Name: patient_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.patient_id_seq', 58, true);


--
-- Name: prescription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.prescription_id_seq', 17, true);


--
-- Name: prescription_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.prescription_item_id_seq', 17, true);


--
-- Name: regist_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.regist_level_id_seq', 1, false);


--
-- Name: register_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.register_id_seq', 65, true);


--
-- Name: schedule_disruption_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.schedule_disruption_id_seq', 2, true);


--
-- Name: scheduling_actual_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scheduling_actual_id_seq', 73, true);


--
-- Name: scheduling_application_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scheduling_application_id_seq', 19, true);


--
-- Name: scheduling_rule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scheduling_rule_id_seq', 4, true);


--
-- Name: scheduling_time_slot_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scheduling_time_slot_id_seq', 1803, true);


--
-- Name: settle_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.settle_category_id_seq', 1, false);


--
-- Name: check_request check_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.check_request
    ADD CONSTRAINT check_request_pkey PRIMARY KEY (id);


--
-- Name: clinic_room clinic_room_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_room
    ADD CONSTRAINT clinic_room_pkey PRIMARY KEY (id);


--
-- Name: clinic_room clinic_room_uuid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_room
    ADD CONSTRAINT clinic_room_uuid_key UNIQUE (uuid);


--
-- Name: department department_dept_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_dept_code_key UNIQUE (dept_code);


--
-- Name: department department_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (id);


--
-- Name: disease disease_disease_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disease
    ADD CONSTRAINT disease_disease_code_key UNIQUE (disease_code);


--
-- Name: disease disease_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disease
    ADD CONSTRAINT disease_pkey PRIMARY KEY (id);


--
-- Name: disposal_request disposal_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disposal_request
    ADD CONSTRAINT disposal_request_pkey PRIMARY KEY (id);


--
-- Name: drug_info drug_info_drug_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_info
    ADD CONSTRAINT drug_info_drug_code_key UNIQUE (drug_code);


--
-- Name: drug_info drug_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_info
    ADD CONSTRAINT drug_info_pkey PRIMARY KEY (id);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (id);


--
-- Name: inspection_request inspection_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_request
    ADD CONSTRAINT inspection_request_pkey PRIMARY KEY (id);


--
-- Name: medical_record_disease medical_record_disease_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_record_disease
    ADD CONSTRAINT medical_record_disease_pkey PRIMARY KEY (id);


--
-- Name: medical_record medical_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_record
    ADD CONSTRAINT medical_record_pkey PRIMARY KEY (id);


--
-- Name: medical_record medical_record_register_uuid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_record
    ADD CONSTRAINT medical_record_register_uuid_key UNIQUE (register_uuid);


--
-- Name: medical_technology medical_technology_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_technology
    ADD CONSTRAINT medical_technology_pkey PRIMARY KEY (id);


--
-- Name: medical_technology medical_technology_tech_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_technology
    ADD CONSTRAINT medical_technology_tech_code_key UNIQUE (tech_code);


--
-- Name: outbox_event outbox_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_event
    ADD CONSTRAINT outbox_event_pkey PRIMARY KEY (id);


--
-- Name: outbox_event outbox_event_uuid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_event
    ADD CONSTRAINT outbox_event_uuid_key UNIQUE (uuid);


--
-- Name: outpatient_bill outpatient_bill_bill_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outpatient_bill
    ADD CONSTRAINT outpatient_bill_bill_code_key UNIQUE (bill_code);


--
-- Name: outpatient_bill_detail outpatient_bill_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outpatient_bill_detail
    ADD CONSTRAINT outpatient_bill_detail_pkey PRIMARY KEY (id);


--
-- Name: outpatient_bill outpatient_bill_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outpatient_bill
    ADD CONSTRAINT outpatient_bill_pkey PRIMARY KEY (id);


--
-- Name: patient patient_card_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_card_number_key UNIQUE (card_number);


--
-- Name: patient patient_case_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_case_number_key UNIQUE (case_number);


--
-- Name: patient_feedback patient_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_feedback
    ADD CONSTRAINT patient_feedback_pkey PRIMARY KEY (id);


--
-- Name: patient_feedback patient_feedback_uuid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_feedback
    ADD CONSTRAINT patient_feedback_uuid_key UNIQUE (uuid);


--
-- Name: patient patient_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_pkey PRIMARY KEY (id);


--
-- Name: prescription_item prescription_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription_item
    ADD CONSTRAINT prescription_item_pkey PRIMARY KEY (id);


--
-- Name: prescription prescription_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription
    ADD CONSTRAINT prescription_pkey PRIMARY KEY (id);


--
-- Name: prescription prescription_prescription_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription
    ADD CONSTRAINT prescription_prescription_code_key UNIQUE (prescription_code);


--
-- Name: regist_level regist_level_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regist_level
    ADD CONSTRAINT regist_level_pkey PRIMARY KEY (id);


--
-- Name: regist_level regist_level_regist_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regist_level
    ADD CONSTRAINT regist_level_regist_code_key UNIQUE (regist_code);


--
-- Name: register register_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.register
    ADD CONSTRAINT register_pkey PRIMARY KEY (id);


--
-- Name: schedule_disruption schedule_disruption_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_disruption
    ADD CONSTRAINT schedule_disruption_pkey PRIMARY KEY (id);


--
-- Name: scheduling_actual scheduling_actual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_actual
    ADD CONSTRAINT scheduling_actual_pkey PRIMARY KEY (id);


--
-- Name: scheduling_application scheduling_application_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_application
    ADD CONSTRAINT scheduling_application_pkey PRIMARY KEY (id);


--
-- Name: scheduling_rule scheduling_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_rule
    ADD CONSTRAINT scheduling_rule_pkey PRIMARY KEY (id);


--
-- Name: scheduling_time_slot scheduling_time_slot_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_time_slot
    ADD CONSTRAINT scheduling_time_slot_pkey PRIMARY KEY (id);


--
-- Name: scheduling_time_slot scheduling_time_slot_uuid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_time_slot
    ADD CONSTRAINT scheduling_time_slot_uuid_key UNIQUE (uuid);


--
-- Name: settle_category settle_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settle_category
    ADD CONSTRAINT settle_category_pkey PRIMARY KEY (id);


--
-- Name: settle_category settle_category_settle_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settle_category
    ADD CONSTRAINT settle_category_settle_code_key UNIQUE (settle_code);


--
-- Name: ix_check_request_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_check_request_uuid ON public.check_request USING btree (uuid);


--
-- Name: ix_department_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_department_uuid ON public.department USING btree (uuid);


--
-- Name: ix_disposal_request_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_disposal_request_uuid ON public.disposal_request USING btree (uuid);


--
-- Name: ix_drug_info_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_drug_info_uuid ON public.drug_info USING btree (uuid);


--
-- Name: ix_employee_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_employee_uuid ON public.employee USING btree (uuid);


--
-- Name: ix_inspection_request_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_inspection_request_uuid ON public.inspection_request USING btree (uuid);


--
-- Name: ix_medical_record_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_medical_record_uuid ON public.medical_record USING btree (uuid);


--
-- Name: ix_medical_technology_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_medical_technology_uuid ON public.medical_technology USING btree (uuid);


--
-- Name: ix_outbox_event_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_outbox_event_status ON public.outbox_event USING btree (status);


--
-- Name: ix_outbox_event_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_outbox_event_uuid ON public.outbox_event USING btree (uuid);


--
-- Name: ix_outpatient_bill_detail_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_outpatient_bill_detail_uuid ON public.outpatient_bill_detail USING btree (uuid);


--
-- Name: ix_outpatient_bill_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_outpatient_bill_uuid ON public.outpatient_bill USING btree (uuid);


--
-- Name: ix_patient_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_patient_uuid ON public.patient USING btree (uuid);


--
-- Name: ix_prescription_item_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_prescription_item_uuid ON public.prescription_item USING btree (uuid);


--
-- Name: ix_prescription_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_prescription_uuid ON public.prescription USING btree (uuid);


--
-- Name: ix_regist_level_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_regist_level_uuid ON public.regist_level USING btree (uuid);


--
-- Name: ix_register_dept_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_register_dept_uuid ON public.register USING btree (dept_uuid);


--
-- Name: ix_register_employee_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_register_employee_uuid ON public.register USING btree (employee_uuid);


--
-- Name: ix_register_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_register_uuid ON public.register USING btree (uuid);


--
-- Name: ix_schedule_disruption_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_schedule_disruption_patient_id ON public.schedule_disruption USING btree (patient_id);


--
-- Name: ix_schedule_disruption_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_schedule_disruption_status ON public.schedule_disruption USING btree (status);


--
-- Name: ix_schedule_disruption_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_schedule_disruption_uuid ON public.schedule_disruption USING btree (uuid);


--
-- Name: ix_scheduling_actual_employee_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scheduling_actual_employee_uuid ON public.scheduling_actual USING btree (employee_uuid);


--
-- Name: ix_scheduling_actual_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_scheduling_actual_uuid ON public.scheduling_actual USING btree (uuid);


--
-- Name: ix_scheduling_application_employee_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scheduling_application_employee_uuid ON public.scheduling_application USING btree (employee_uuid);


--
-- Name: ix_scheduling_application_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scheduling_application_status ON public.scheduling_application USING btree (status);


--
-- Name: ix_scheduling_application_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_scheduling_application_uuid ON public.scheduling_application USING btree (uuid);


--
-- Name: ix_scheduling_rule_employee_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scheduling_rule_employee_uuid ON public.scheduling_rule USING btree (employee_uuid);


--
-- Name: ix_scheduling_rule_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_scheduling_rule_uuid ON public.scheduling_rule USING btree (uuid);


--
-- Name: ix_scheduling_time_slot_scheduling_actual_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scheduling_time_slot_scheduling_actual_id ON public.scheduling_time_slot USING btree (scheduling_actual_id);


--
-- Name: ix_scheduling_time_slot_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_scheduling_time_slot_uuid ON public.scheduling_time_slot USING btree (uuid);


--
-- Name: ix_settle_category_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_settle_category_uuid ON public.settle_category USING btree (uuid);


--
-- Name: check_request check_request_medical_technology_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.check_request
    ADD CONSTRAINT check_request_medical_technology_id_fkey FOREIGN KEY (medical_technology_id) REFERENCES public.medical_technology(id);


--
-- Name: disposal_request disposal_request_medical_technology_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disposal_request
    ADD CONSTRAINT disposal_request_medical_technology_id_fkey FOREIGN KEY (medical_technology_id) REFERENCES public.medical_technology(id);


--
-- Name: employee employee_dept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES public.department(id);


--
-- Name: employee employee_regist_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_regist_level_id_fkey FOREIGN KEY (regist_level_id) REFERENCES public.regist_level(id);


--
-- Name: inspection_request inspection_request_medical_technology_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_request
    ADD CONSTRAINT inspection_request_medical_technology_id_fkey FOREIGN KEY (medical_technology_id) REFERENCES public.medical_technology(id);


--
-- Name: medical_record_disease medical_record_disease_disease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_record_disease
    ADD CONSTRAINT medical_record_disease_disease_id_fkey FOREIGN KEY (disease_id) REFERENCES public.disease(id);


--
-- Name: medical_record_disease medical_record_disease_medical_record_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_record_disease
    ADD CONSTRAINT medical_record_disease_medical_record_id_fkey FOREIGN KEY (medical_record_id) REFERENCES public.medical_record(id);


--
-- Name: outpatient_bill_detail outpatient_bill_detail_bill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outpatient_bill_detail
    ADD CONSTRAINT outpatient_bill_detail_bill_id_fkey FOREIGN KEY (bill_id) REFERENCES public.outpatient_bill(id);


--
-- Name: prescription_item prescription_item_drug_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription_item
    ADD CONSTRAINT prescription_item_drug_id_fkey FOREIGN KEY (drug_id) REFERENCES public.drug_info(id);


--
-- Name: prescription_item prescription_item_prescription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription_item
    ADD CONSTRAINT prescription_item_prescription_id_fkey FOREIGN KEY (prescription_id) REFERENCES public.prescription(id);


--
-- Name: register register_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.register
    ADD CONSTRAINT register_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- Name: register register_scheduling_actual_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.register
    ADD CONSTRAINT register_scheduling_actual_id_fkey FOREIGN KEY (scheduling_actual_id) REFERENCES public.scheduling_actual(id);


--
-- Name: register register_scheduling_time_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.register
    ADD CONSTRAINT register_scheduling_time_slot_id_fkey FOREIGN KEY (scheduling_time_slot_id) REFERENCES public.scheduling_time_slot(id);


--
-- Name: schedule_disruption schedule_disruption_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_disruption
    ADD CONSTRAINT schedule_disruption_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- Name: schedule_disruption schedule_disruption_register_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_disruption
    ADD CONSTRAINT schedule_disruption_register_id_fkey FOREIGN KEY (register_id) REFERENCES public.register(id);


--
-- Name: scheduling_time_slot scheduling_time_slot_scheduling_actual_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduling_time_slot
    ADD CONSTRAINT scheduling_time_slot_scheduling_actual_id_fkey FOREIGN KEY (scheduling_actual_id) REFERENCES public.scheduling_actual(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict yEaNPETiPDZ4818lVqyhHkV2S9FpJgwq4TSrfaJDBMWNXqDJOmWFeNieBFfz5kC

