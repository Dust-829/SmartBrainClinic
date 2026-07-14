--
-- PostgreSQL database dump
--

\restrict t67c8VfR4chJfUebtIBPQuBnwbz98ppw6blpd2Wa1jKoc7y1HJGHreyiZoYlo3A

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


\unrestrict t67c8VfR4chJfUebtIBPQuBnwbz98ppw6blpd2Wa1jKoc7y1HJGHreyiZoYlo3A
\connect his_db
\restrict t67c8VfR4chJfUebtIBPQuBnwbz98ppw6blpd2Wa1jKoc7y1HJGHreyiZoYlo3A

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
    slot_duration_minutes integer NOT NULL,
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
    slot_duration_minutes integer NOT NULL,
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

\unrestrict t67c8VfR4chJfUebtIBPQuBnwbz98ppw6blpd2Wa1jKoc7y1HJGHreyiZoYlo3A

