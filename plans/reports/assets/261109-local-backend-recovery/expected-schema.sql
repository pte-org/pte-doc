--
-- PostgreSQL database dump
--


-- Dumped from database version 17.11 (Debian 17.11-1.pgdg13+2)
-- Dumped by pg_dump version 17.11 (Debian 17.11-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: questions_pool_immutable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.questions_pool_immutable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN IF NEW.pool IS DISTINCT FROM OLD.pool THEN RAISE EXCEPTION 'questions.pool is immutable (question %)', OLD.public_id; END IF; RETURN NEW; END; $$;


--
-- Name: retain_question_publication_history(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.retain_question_publication_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN IF NEW.status = 'APPROVED' OR (TG_OP = 'UPDATE' AND OLD.ever_published IS TRUE) THEN NEW.ever_published := TRUE; END IF; RETURN NEW; END; $$;


--
-- Name: scoring_rubric_activation_audits_insert_only(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.scoring_rubric_activation_audits_insert_only() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'scoring_rubric_activation_audits is insert-only (% rejected)', TG_OP
        USING ERRCODE = 'check_violation';
END;
$$;


--
-- Name: scoring_rubric_versions_guard_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.scoring_rubric_versions_guard_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.status IN ('ACTIVE', 'RETIRED') THEN
        RAISE EXCEPTION 'scoring_rubric_versions %: % row cannot be deleted', OLD.public_id, OLD.status
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN OLD;
END;
$$;


--
-- Name: scoring_rubric_versions_guard_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.scoring_rubric_versions_guard_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.status IN ('ACTIVE', 'RETIRED') THEN
        IF OLD.status = 'ACTIVE' AND NEW.status = 'RETIRED'
           AND (to_jsonb(NEW) - 'status' - 'retired_at' - 'updated_at' - 'lock_version')
               = (to_jsonb(OLD) - 'status' - 'retired_at' - 'updated_at' - 'lock_version') THEN
            RETURN NEW;
        END IF;
        RAISE EXCEPTION 'scoring_rubric_versions %: % row is immutable (only ACTIVE -> RETIRED is allowed)',
            OLD.public_id, OLD.status USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.status = 'RETIRED' THEN
        RAISE EXCEPTION 'scoring_rubric_versions %: only an ACTIVE version can be retired', OLD.public_id
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_prompt_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_prompt_versions (
    id bigint NOT NULL,
    public_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    kind character varying(16) NOT NULL,
    prompt_key character varying(64) NOT NULL,
    version_no integer NOT NULL,
    status character varying(16) NOT NULL,
    content jsonb NOT NULL,
    content_hash character varying(64) NOT NULL,
    author_user_public_id uuid,
    updated_by_user_public_id uuid,
    approver_user_public_id uuid,
    rejection_reason character varying(1000),
    submitted_at timestamp with time zone,
    decided_at timestamp with time zone,
    activated_at timestamp with time zone,
    retired_at timestamp with time zone,
    lock_version bigint DEFAULT 0 NOT NULL,
    test_passed boolean,
    tested_content_hash character varying(64),
    test_note character varying(500),
    tested_by_user_public_id uuid,
    tested_at timestamp with time zone,
    CONSTRAINT ai_prompt_versions_kind_check CHECK (((kind)::text = ANY ((ARRAY['GENERATOR'::character varying, 'REVIEWER'::character varying, 'SCORER'::character varying, 'SHARED'::character varying, 'CHATBOT'::character varying])::text[]))),
    CONSTRAINT ai_prompt_versions_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'PENDING'::character varying, 'ACTIVE'::character varying, 'REJECTED'::character varying, 'RETIRED'::character varying])::text[]))),
    CONSTRAINT ai_prompt_versions_version_no_check CHECK ((version_no >= 1))
);


--
-- Name: COLUMN ai_prompt_versions.content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ai_prompt_versions.content IS 'PromptContent JSON: title, intro blocks, sections of blocks (TEXT, LIST, CODE, LEVELS)';


--
-- Name: COLUMN ai_prompt_versions.content_hash; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ai_prompt_versions.content_hash IS 'SHA-256 of the canonical content JSON; a prompt test is valid only for the hash it ran on';


--
-- Name: ai_prompt_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_prompt_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_prompt_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ai_prompt_versions_id_seq OWNED BY public.ai_prompt_versions.id;


--
-- Name: answer_evaluations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.answer_evaluations (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    answer_public_id uuid NOT NULL,
    attempt_public_id uuid NOT NULL,
    lock_version bigint NOT NULL,
    score integer,
    scored_at timestamp(6) with time zone,
    session_public_id uuid NOT NULL,
    source character varying(16) NOT NULL,
    tenant_id uuid NOT NULL,
    ai_dispatched_at timestamp(6) with time zone,
    ai_model character varying(160),
    ai_provider character varying(64),
    ai_provider_category character varying(16),
    ai_provider_version character varying(100),
    criteria_scores_json text,
    detail_json text,
    dispatch_token bigint,
    exam_definition_public_id uuid,
    failure_reason character varying(40),
    fallback boolean,
    feedback text,
    item_public_id uuid,
    scoring_method character varying(16),
    section character varying(255),
    status character varying(16),
    task_type character varying(255),
    teacher_score integer,
    teacher_scored_at timestamp(6) with time zone,
    transcript text,
    assignment_id bigint,
    comment character varying(2000),
    decision_kind character varying(32),
    draft_version bigint,
    examiner_public_id uuid,
    expected_review_version character varying(128),
    request_fingerprint character varying(128),
    request_public_id uuid,
    reviewed_ai_score integer,
    reviewed_ai_version character varying(128),
    saved_at timestamp(6) with time zone,
    examiner_status character varying(16),
    submitted_at timestamp(6) with time zone,
    carried_over_from_examiner_public_id uuid,
    rubric_version_public_id uuid,
    trait_scores_json text,
    CONSTRAINT answer_evaluations_ai_provider_category_check CHECK (((ai_provider_category)::text = ANY (ARRAY[('REAL'::character varying)::text, ('STUB'::character varying)::text]))),
    CONSTRAINT answer_evaluations_check CHECK ((((source)::text <> 'AI'::text) OR ((dispatch_token IS NOT NULL) AND (fallback IS NOT NULL)))),
    CONSTRAINT answer_evaluations_check1 CHECK ((((source)::text <> 'EXAMINER'::text) OR (draft_version IS NOT NULL))),
    CONSTRAINT answer_evaluations_decision_kind_check CHECK (((decision_kind)::text = ANY (ARRAY[('CONFIRM_AI'::character varying)::text, ('MANUAL'::character varying)::text, ('LEGACY_IMPORTED'::character varying)::text]))),
    CONSTRAINT answer_evaluations_examiner_status_check CHECK (((examiner_status)::text = ANY (ARRAY[('DRAFT'::character varying)::text, ('SUBMITTED'::character varying)::text]))),
    CONSTRAINT answer_evaluations_failure_reason_check CHECK (((failure_reason)::text = ANY (ARRAY[('PROVIDER_RATE_LIMITED'::character varying)::text, ('PROVIDER_UNAVAILABLE'::character varying)::text, ('PROVIDER_TIMEOUT'::character varying)::text, ('PROVIDER_NETWORK_ERROR'::character varying)::text, ('PROVIDER_AUTH_FAILED'::character varying)::text, ('PROVIDER_BAD_REQUEST'::character varying)::text, ('PROVIDER_RESPONSE_INVALID'::character varying)::text, ('PROVIDER_CONTENT_BLOCKED'::character varying)::text, ('AUDIO_UNSUPPORTED'::character varying)::text, ('AUDIO_TOO_LONG'::character varying)::text, ('INTERNAL_ERROR'::character varying)::text]))),
    CONSTRAINT answer_evaluations_scoring_method_check CHECK (((scoring_method)::text = ANY (ARRAY[('AI_SPEECH'::character varying)::text, ('AI_TEXT'::character varying)::text, ('OBJECTIVE'::character varying)::text, ('UNSCORED'::character varying)::text]))),
    CONSTRAINT answer_evaluations_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('AI_SCORING'::character varying)::text, ('SCORING_FAILED'::character varying)::text, ('SCORED'::character varying)::text])))
);


--
-- Name: COLUMN answer_evaluations.trait_scores_json; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.answer_evaluations.trait_scores_json IS 'Examiner Pearson traits: scale=PEARSON_V1, rubricVersion, traits; null for legacy total-only scores';


--
-- Name: answer_evaluations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.answer_evaluations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.answer_evaluations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: attempt_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attempt_answers (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    confidence character varying(16),
    expired boolean NOT NULL,
    item_order_index integer NOT NULL,
    item_public_id uuid NOT NULL,
    payload text,
    selected_evaluation_public_id uuid,
    selected_score_source character varying(16),
    selected_score_source_at timestamp(6) with time zone,
    selected_score_source_by uuid,
    status character varying(255) NOT NULL,
    attempt_id bigint NOT NULL,
    CONSTRAINT attempt_answers_confidence_check CHECK (((confidence)::text = ANY (ARRAY[('LOW'::character varying)::text, ('MEDIUM'::character varying)::text, ('HIGH'::character varying)::text]))),
    CONSTRAINT attempt_answers_status_check CHECK (((status)::text = ANY (ARRAY[('SUBMITTED'::character varying)::text, ('SCORED'::character varying)::text])))
);


--
-- Name: attempt_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.attempt_answers ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.attempt_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    action character varying(255) NOT NULL,
    actor_role character varying(255),
    actor_user_id uuid NOT NULL,
    after_state jsonb,
    aggregate_id character varying(255) NOT NULL,
    aggregate_type character varying(255) NOT NULL,
    before_state jsonb,
    request_public_id uuid,
    resource_code character varying(255),
    resource_name character varying(255),
    summary character varying(500) NOT NULL,
    tenant_id uuid
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: blueprint_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blueprint_items (
    blueprint_id bigint NOT NULL,
    order_index integer NOT NULL,
    question_public_id uuid NOT NULL,
    section character varying(255) NOT NULL,
    CONSTRAINT blueprint_items_section_check CHECK (((section)::text = ANY (ARRAY[('LISTENING'::character varying)::text, ('SPEAKING'::character varying)::text, ('READING'::character varying)::text, ('WRITING'::character varying)::text])))
);


--
-- Name: chat_usage; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_usage (
    id bigint NOT NULL,
    student_id uuid NOT NULL,
    usage_date date NOT NULL,
    used integer DEFAULT 0 NOT NULL,
    CONSTRAINT chat_usage_used_check CHECK ((used >= 0))
);


--
-- Name: chat_usage_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_usage_daily (
    usage_date date NOT NULL,
    model character varying(64) NOT NULL,
    messages integer DEFAULT 0 NOT NULL,
    ok integer DEFAULT 0 NOT NULL,
    refused integer DEFAULT 0 NOT NULL,
    failed integer DEFAULT 0 NOT NULL,
    tokens_in bigint DEFAULT 0 NOT NULL,
    tokens_out bigint DEFAULT 0 NOT NULL,
    tokens_thinking bigint DEFAULT 0 NOT NULL,
    cost_usd numeric(14,6) DEFAULT 0 NOT NULL,
    failed_timeout integer DEFAULT 0 NOT NULL,
    failed_rate_limited integer DEFAULT 0 NOT NULL,
    failed_auth integer DEFAULT 0 NOT NULL,
    failed_unavailable integer DEFAULT 0 NOT NULL,
    failed_truncated integer DEFAULT 0 NOT NULL,
    failed_other integer DEFAULT 0 NOT NULL,
    CONSTRAINT chat_usage_daily_cost_usd_check CHECK ((cost_usd >= (0)::numeric)),
    CONSTRAINT chat_usage_daily_failed_auth_check CHECK ((failed_auth >= 0)),
    CONSTRAINT chat_usage_daily_failed_check CHECK ((failed >= 0)),
    CONSTRAINT chat_usage_daily_failed_other_check CHECK ((failed_other >= 0)),
    CONSTRAINT chat_usage_daily_failed_rate_limited_check CHECK ((failed_rate_limited >= 0)),
    CONSTRAINT chat_usage_daily_failed_timeout_check CHECK ((failed_timeout >= 0)),
    CONSTRAINT chat_usage_daily_failed_truncated_check CHECK ((failed_truncated >= 0)),
    CONSTRAINT chat_usage_daily_failed_unavailable_check CHECK ((failed_unavailable >= 0)),
    CONSTRAINT chat_usage_daily_messages_check CHECK ((messages >= 0)),
    CONSTRAINT chat_usage_daily_ok_check CHECK ((ok >= 0)),
    CONSTRAINT chat_usage_daily_refused_check CHECK ((refused >= 0)),
    CONSTRAINT chat_usage_daily_tokens_in_check CHECK ((tokens_in >= 0)),
    CONSTRAINT chat_usage_daily_tokens_out_check CHECK ((tokens_out >= 0)),
    CONSTRAINT chat_usage_daily_tokens_thinking_check CHECK ((tokens_thinking >= 0))
);


--
-- Name: chat_usage_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.chat_usage ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.chat_usage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: class_students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.class_students (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    organization_id uuid NOT NULL,
    student_public_id uuid NOT NULL,
    class_id bigint NOT NULL
);


--
-- Name: class_students_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.class_students ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.class_students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: classes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classes (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    name character varying(255) NOT NULL,
    organization_id uuid NOT NULL,
    status character varying(255) NOT NULL,
    program_id bigint NOT NULL,
    CONSTRAINT classes_status_check CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('INACTIVE'::character varying)::text, ('SUSPENDED'::character varying)::text])))
);


--
-- Name: classes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.classes ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_attempts (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    active_section character varying(255),
    answer_integrity_level character varying(255) NOT NULL,
    attempt_number integer NOT NULL,
    capability_fingerprint character varying(2048),
    current_order_index integer DEFAULT 0 NOT NULL,
    device_check_passed_at timestamp(6) with time zone,
    device_check_required boolean NOT NULL,
    exam_definition_public_id uuid NOT NULL,
    exam_definition_version integer,
    exam_end_time timestamp(6) with time zone,
    exam_mode character varying(16) NOT NULL,
    exam_version_public_id uuid NOT NULL,
    grading_excluded boolean NOT NULL,
    grading_exclusion_reason character varying(500),
    last_play_allowed boolean,
    last_play_request_id character varying(255),
    last_seen_at timestamp(6) with time zone,
    lockdown_mode character varying(20),
    max_retries_per_student integer DEFAULT 0 NOT NULL,
    play_count integer DEFAULT 0 NOT NULL,
    proctor_required boolean NOT NULL,
    replay_policy_limit integer,
    replay_policy_type character varying(255) NOT NULL,
    section_started_at timestamp(6) with time zone,
    session_public_id uuid NOT NULL,
    started_at timestamp(6) with time zone,
    status character varying(255) NOT NULL,
    student_public_id uuid NOT NULL,
    submitted_at timestamp(6) with time zone,
    tenant_id uuid NOT NULL,
    version bigint,
    CONSTRAINT exam_attempts_status_check CHECK (((status)::text = ANY (ARRAY[('CREATED'::character varying)::text, ('IN_PROGRESS'::character varying)::text, ('SUBMITTED'::character varying)::text])))
);


--
-- Name: exam_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_attempts ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_blueprints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_blueprints (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    author_user_public_id uuid,
    name character varying(255) NOT NULL,
    rejection_reason character varying(255),
    status character varying(255) NOT NULL,
    tenant_id uuid,
    version bigint NOT NULL,
    CONSTRAINT exam_blueprints_status_check CHECK (((status)::text = ANY (ARRAY[('DRAFT'::character varying)::text, ('PENDING_APPROVAL'::character varying)::text, ('PUBLISHED'::character varying)::text])))
);


--
-- Name: exam_blueprints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_blueprints ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_blueprints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_definition_cefr_targets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_definition_cefr_targets (
    exam_definition_id bigint NOT NULL,
    level character varying(2) NOT NULL,
    percent integer NOT NULL,
    CONSTRAINT exam_definition_cefr_targets_level_check CHECK (((level)::text = ANY ((ARRAY['A1'::character varying, 'A2'::character varying, 'B1'::character varying, 'B2'::character varying, 'C1'::character varying, 'C2'::character varying])::text[]))),
    CONSTRAINT exam_definition_cefr_targets_percent_check CHECK (((percent > 0) AND (percent <= 100)))
);


--
-- Name: exam_definition_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_definition_items (
    exam_definition_id bigint NOT NULL,
    listening_weight numeric(5,2) NOT NULL,
    max_count integer NOT NULL,
    min_count integer NOT NULL,
    overall_weight numeric(5,2) NOT NULL,
    prep_seconds integer NOT NULL,
    reading_weight numeric(5,2) NOT NULL,
    response_seconds integer NOT NULL,
    runtime_answer_schema_version integer,
    runtime_authoring_contract_key character varying(96),
    runtime_authoring_contract_version integer,
    runtime_behavior_key character varying(64),
    runtime_contract_version integer,
    runtime_min_app_version character varying(32),
    runtime_profile_key character varying(96),
    runtime_profile_status character varying(16),
    runtime_profile_version integer,
    runtime_renderer_key character varying(96),
    runtime_required_client_capabilities character varying(512),
    runtime_scoring_mode character varying(16),
    runtime_scoring_profile_key character varying(64),
    runtime_scoring_profile_version integer,
    runtime_screen_key character varying(96),
    scoring_method character varying(255) NOT NULL,
    section character varying(255) NOT NULL,
    sequence integer NOT NULL,
    speaking_weight numeric(5,2) NOT NULL,
    task_type character varying(255),
    task_type_key character varying(64) NOT NULL,
    writing_weight numeric(5,2) NOT NULL,
    CONSTRAINT exam_definition_items_scoring_method_check CHECK (((scoring_method)::text = ANY (ARRAY[('AI_SPEECH'::character varying)::text, ('AI_TEXT'::character varying)::text, ('OBJECTIVE'::character varying)::text, ('UNSCORED'::character varying)::text])))
);


--
-- Name: exam_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_definitions (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    author_user_public_id uuid,
    code character varying(255) NOT NULL,
    lock_version bigint NOT NULL,
    name character varying(255) NOT NULL,
    rejection_reason character varying(1000),
    status character varying(255) NOT NULL,
    template_policy character varying(16) NOT NULL,
    version integer NOT NULL,
    tenant_id uuid,
    base_definition_public_id uuid,
    sw_min_seconds integer,
    sw_max_seconds integer,
    reading_min_seconds integer,
    reading_max_seconds integer,
    listening_min_seconds integer,
    listening_max_seconds integer,
    total_max_seconds integer,
    rubric_version_public_id uuid,
    CONSTRAINT exam_definitions_status_check CHECK (((status)::text = ANY (ARRAY[('DRAFT'::character varying)::text, ('PENDING_APPROVAL'::character varying)::text, ('ACTIVE'::character varying)::text, ('RETIRED'::character varying)::text]))),
    CONSTRAINT exam_definitions_template_policy_check CHECK (((template_policy)::text = ANY (ARRAY[('STANDARD_PTE'::character varying)::text, ('CUSTOM'::character varying)::text]))),
    CONSTRAINT exam_definitions_time_frame_check CHECK ((((sw_min_seconds IS NULL) AND (sw_max_seconds IS NULL) AND (reading_min_seconds IS NULL) AND (reading_max_seconds IS NULL) AND (listening_min_seconds IS NULL) AND (listening_max_seconds IS NULL) AND (total_max_seconds IS NULL)) OR ((sw_min_seconds > 0) AND (sw_max_seconds >= sw_min_seconds) AND (reading_min_seconds > 0) AND (reading_max_seconds >= reading_min_seconds) AND (listening_min_seconds > 0) AND (listening_max_seconds >= listening_min_seconds) AND (total_max_seconds >= ((sw_min_seconds + reading_min_seconds) + listening_min_seconds)))))
);


--
-- Name: exam_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_definitions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_incidents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_incidents (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    attempt_public_id uuid,
    client_event_id character varying(128),
    client_occurred_at timestamp(6) with time zone,
    current_owner_name character varying(255),
    current_owner_role character varying(32) NOT NULL,
    description text,
    detected_at timestamp(6) with time zone NOT NULL,
    origin character varying(16) NOT NULL,
    reporter_name character varying(255),
    reporter_public_id uuid,
    reporter_role character varying(32),
    resolution_summary text,
    session_public_id uuid NOT NULL,
    severity character varying(32) NOT NULL,
    status character varying(32) NOT NULL,
    student_public_id uuid,
    tenant_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    type character varying(64) NOT NULL,
    CONSTRAINT exam_incidents_origin_check CHECK (((origin)::text = ANY (ARRAY[('AUTO'::character varying)::text, ('PROCTOR_FLAG'::character varying)::text, ('REPORTED'::character varying)::text])))
);


--
-- Name: exam_incidents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_incidents ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_incidents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_registrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_registrations (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    attendance_status character varying(32) NOT NULL,
    attendance_version bigint NOT NULL,
    identity_note character varying(1000),
    identity_status character varying(32) NOT NULL,
    last_action_at timestamp(6) with time zone,
    last_actor_public_id uuid,
    last_actor_role character varying(32),
    last_reason_or_note character varying(1000),
    license_key character varying(64) NOT NULL,
    prior_session_name character varying(255),
    prior_session_public_id uuid,
    prior_status character varying(16),
    published_at timestamp(6) with time zone,
    reason character varying(32),
    source_summary character varying(1000),
    status character varying(16) NOT NULL,
    student_public_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    session_id bigint NOT NULL,
    CONSTRAINT exam_registrations_attendance_status_check CHECK (((attendance_status)::text = ANY (ARRAY[('UNMARKED'::character varying)::text, ('PRESENT'::character varying)::text, ('ABSENT'::character varying)::text, ('LATE'::character varying)::text]))),
    CONSTRAINT exam_registrations_identity_status_check CHECK (((identity_status)::text = ANY (ARRAY[('UNVERIFIED'::character varying)::text, ('VERIFIED'::character varying)::text, ('FAILED'::character varying)::text]))),
    CONSTRAINT exam_registrations_reason_check CHECK (((reason)::text = ANY (ARRAY[('DUPLICATE_SOURCE'::character varying)::text, ('ALREADY_ASSIGNED'::character varying)::text, ('ALREADY_STARTED'::character varying)::text, ('SCHEDULE_OVERLAP'::character varying)::text, ('OUTSIDE_TENANT'::character varying)::text, ('CAPACITY_EXCEEDED'::character varying)::text]))),
    CONSTRAINT exam_registrations_status_check CHECK (((status)::text = ANY (ARRAY[('CANDIDATE'::character varying)::text, ('ELIGIBLE'::character varying)::text, ('EXCLUDED'::character varying)::text, ('ENROLLED'::character varying)::text])))
);


--
-- Name: exam_registrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_registrations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_registrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_results (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    attempt_public_id uuid NOT NULL,
    listening_score integer,
    overall_score integer,
    publication_cohort_size integer,
    publication_public_id uuid,
    published boolean NOT NULL,
    published_at timestamp(6) with time zone,
    published_by_public_id uuid,
    reading_score integer,
    report_snapshot_json text,
    session_public_id uuid NOT NULL,
    snapshot_public_id uuid,
    speaking_score integer,
    student_public_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    writing_score integer
);


--
-- Name: exam_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_results ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_session_audience_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_session_audience_sources (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    created_by uuid,
    source_public_id uuid NOT NULL,
    source_type character varying(16) NOT NULL,
    tenant_id uuid NOT NULL,
    session_id bigint NOT NULL,
    CONSTRAINT exam_session_audience_sources_source_type_check CHECK (((source_type)::text = ANY (ARRAY[('STUDENT'::character varying)::text, ('CLASS'::character varying)::text, ('PROGRAM'::character varying)::text])))
);


--
-- Name: exam_session_audience_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_session_audience_sources ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_session_audience_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_session_cefr_targets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_session_cefr_targets (
    session_id bigint NOT NULL,
    level character varying(2) NOT NULL,
    percent integer NOT NULL,
    CONSTRAINT exam_session_cefr_targets_level_check CHECK (((level)::text = ANY ((ARRAY['A1'::character varying, 'A2'::character varying, 'B1'::character varying, 'B2'::character varying, 'C1'::character varying, 'C2'::character varying])::text[]))),
    CONSTRAINT exam_session_cefr_targets_percent_check CHECK (((percent > 0) AND (percent <= 100)))
);


--
-- Name: exam_session_proctors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_session_proctors (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    proctor_public_id uuid NOT NULL,
    role character varying(255),
    tenant_id uuid NOT NULL,
    session_id bigint NOT NULL,
    CONSTRAINT exam_session_proctors_role_check CHECK (((role)::text = ANY (ARRAY[('LEAD_PROCTOR'::character varying)::text, ('ASSISTANT_PROCTOR'::character varying)::text])))
);


--
-- Name: exam_session_proctors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_session_proctors ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_session_proctors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_session_selected_skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_session_selected_skills (
    session_id bigint NOT NULL,
    skill character varying(16) NOT NULL
);


--
-- Name: exam_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_sessions (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    capacity integer NOT NULL,
    closes_at timestamp(6) with time zone NOT NULL,
    draft_version bigint NOT NULL,
    exam_definition_public_id uuid,
    exam_definition_version integer,
    exam_mode character varying(16),
    exam_version_public_id uuid,
    grading_completed_at timestamp(6) with time zone,
    grading_frozen_at timestamp(6) with time zone,
    grading_frozen_by_public_id uuid,
    grading_marking_mode character varying(24),
    grading_preview_version character varying(128),
    grading_status character varying(16),
    license_key character varying(64) NOT NULL,
    max_retries_per_student integer NOT NULL,
    name character varying(255) NOT NULL,
    opens_at timestamp(6) with time zone NOT NULL,
    answer_integrity_level character varying(255),
    device_check_required boolean,
    lockdown_mode character varying(255),
    proctor_required boolean,
    replay_policy_limit integer,
    replay_policy_type character varying(255),
    publication_locked_at timestamp(6) with time zone,
    publication_public_id uuid,
    reuse_policy character varying(40),
    series_key character varying(128),
    session_code character varying(24) NOT NULL,
    status character varying(255) NOT NULL,
    subscription_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    avoid_repeated_questions boolean DEFAULT false NOT NULL,
    CONSTRAINT exam_sessions_answer_integrity_level_check CHECK (((answer_integrity_level)::text = ANY (ARRAY[('STANDARD'::character varying)::text, ('STRICT'::character varying)::text]))),
    CONSTRAINT exam_sessions_exam_mode_check CHECK (((exam_mode)::text = 'OFFICIAL_EXAM'::text)),
    CONSTRAINT exam_sessions_grading_status_check CHECK (((grading_status)::text = ANY (ARRAY[('FROZEN'::character varying)::text, ('COMPLETED'::character varying)::text]))),
    CONSTRAINT exam_sessions_lockdown_mode_check CHECK (((lockdown_mode)::text = ANY (ARRAY[('NONE'::character varying)::text, ('STANDARD'::character varying)::text, ('STRICT'::character varying)::text]))),
    CONSTRAINT exam_sessions_replay_policy_type_check CHECK (((replay_policy_type)::text = ANY (ARRAY[('UNLIMITED'::character varying)::text, ('LIMITED'::character varying)::text]))),
    CONSTRAINT exam_sessions_reuse_policy_check CHECK (((reuse_policy)::text = ANY (ARRAY[('ALLOW'::character varying)::text, ('EXCLUDE_STARTED_IN_SERIES'::character varying)::text, ('EXCLUDE_ASSIGNED_IN_SERIES'::character varying)::text, ('BLOCK_ON_SCHEDULE_OVERLAP'::character varying)::text]))),
    CONSTRAINT exam_sessions_status_check CHECK (((status)::text = ANY (ARRAY[('DRAFT'::character varying)::text, ('READY'::character varying)::text, ('SCHEDULED'::character varying)::text, ('OPEN'::character varying)::text, ('CLOSED'::character varying)::text, ('CANCELLED'::character varying)::text])))
);


--
-- Name: exam_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_sessions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exam_version_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_version_items (
    exam_version_id bigint NOT NULL,
    audio_prompt_ref uuid,
    correct_answer_text text,
    image_prompt_ref uuid,
    max_word_count integer,
    min_word_count integer,
    options_json text,
    order_index integer NOT NULL,
    prompt_text text,
    pte_task_type character varying(255),
    public_id uuid NOT NULL,
    reference_answer_text text,
    runtime_answer_schema_version integer,
    runtime_authoring_contract_key character varying(96),
    runtime_authoring_contract_version integer,
    runtime_behavior_key character varying(64),
    runtime_contract_version integer,
    runtime_mapping_status character varying(32),
    runtime_mapping_version character varying(32),
    runtime_min_supported_app_version character varying(32),
    runtime_profile_key character varying(96),
    runtime_profile_status character varying(16),
    runtime_profile_version integer,
    runtime_renderer_key character varying(96),
    runtime_required_client_capabilities character varying(512),
    runtime_scoring_configuration_digest character varying(128),
    runtime_scoring_implementation_version character varying(96),
    runtime_scoring_mode character varying(16),
    runtime_scoring_profile_key character varying(64),
    runtime_scoring_profile_version integer,
    runtime_screen_key character varying(96),
    section character varying(255) NOT NULL,
    source_question_public_id uuid NOT NULL,
    task_type_code character varying(64),
    task_type_display_name character varying(128),
    task_type_key character varying(64) NOT NULL,
    title character varying(255) NOT NULL,
    CONSTRAINT exam_version_items_pte_task_type_check CHECK (((pte_task_type)::text = ANY (ARRAY[('PERSONAL_INTRODUCTION'::character varying)::text, ('READ_ALOUD'::character varying)::text, ('REPEAT_SENTENCE'::character varying)::text, ('DESCRIBE_IMAGE'::character varying)::text, ('RE_TELL_LECTURE'::character varying)::text, ('ANSWER_SHORT_QUESTION'::character varying)::text, ('RESPOND_TO_A_SITUATION'::character varying)::text, ('SUMMARIZE_GROUP_DISCUSSION'::character varying)::text, ('SUMMARIZE_WRITTEN_TEXT'::character varying)::text, ('WRITE_ESSAY'::character varying)::text, ('MC_READING_SINGLE'::character varying)::text, ('MC_READING_MULTIPLE'::character varying)::text, ('RE_ORDER_PARAGRAPHS'::character varying)::text, ('FILL_IN_THE_BLANKS_DRAG_AND_DROP'::character varying)::text, ('FILL_IN_THE_BLANKS_DROPDOWN'::character varying)::text, ('SUMMARIZE_SPOKEN_TEXT'::character varying)::text, ('MC_LISTENING_SINGLE'::character varying)::text, ('MC_LISTENING_MULTIPLE'::character varying)::text, ('FILL_IN_THE_BLANKS_TYPE_IN'::character varying)::text, ('HIGHLIGHT_CORRECT_SUMMARY'::character varying)::text, ('SELECT_MISSING_WORD'::character varying)::text, ('HIGHLIGHT_INCORRECT_WORDS'::character varying)::text, ('WRITE_FROM_DICTATION'::character varying)::text]))),
    CONSTRAINT exam_version_items_section_check CHECK (((section)::text = ANY (ARRAY[('LISTENING'::character varying)::text, ('SPEAKING'::character varying)::text, ('READING'::character varying)::text, ('WRITING'::character varying)::text])))
);


--
-- Name: exam_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_versions (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    exam_definition_public_id uuid NOT NULL,
    exam_definition_version integer NOT NULL,
    generation_algorithm_version character varying(32),
    generation_seed bigint,
    name character varying(255) NOT NULL,
    pool_policy_fingerprint character varying(128),
    source_blueprint_public_id uuid NOT NULL,
    tenant_id uuid,
    version integer NOT NULL,
    assembly_report text
);


--
-- Name: exam_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exam_versions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.exam_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: generation_usage_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generation_usage_daily (
    usage_date date NOT NULL,
    role character varying(16) NOT NULL,
    model character varying(64) NOT NULL,
    calls integer DEFAULT 0 NOT NULL,
    tokens_in bigint DEFAULT 0 NOT NULL,
    tokens_out bigint DEFAULT 0 NOT NULL,
    CONSTRAINT generation_usage_daily_calls_check CHECK ((calls >= 0)),
    CONSTRAINT generation_usage_daily_tokens_in_check CHECK ((tokens_in >= 0)),
    CONSTRAINT generation_usage_daily_tokens_out_check CHECK ((tokens_out >= 0))
);


--
-- Name: grading_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grading_assignments (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    assigned_at timestamp(6) with time zone NOT NULL,
    assigned_by_public_id uuid NOT NULL,
    attempt_public_id uuid NOT NULL,
    eligible_answer_count integer NOT NULL,
    examiner_public_id uuid NOT NULL,
    finalized_at timestamp(6) with time zone,
    session_public_id uuid NOT NULL,
    started_at timestamp(6) with time zone,
    status character varying(16) NOT NULL,
    tenant_id uuid NOT NULL,
    work_version bigint NOT NULL,
    CONSTRAINT grading_assignments_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('IN_PROGRESS'::character varying)::text, ('COMPLETED'::character varying)::text])))
);


--
-- Name: grading_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.grading_assignments ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.grading_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: grading_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grading_issues (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    answer_public_id uuid,
    assignment_id bigint NOT NULL,
    description character varying(2000) NOT NULL,
    reported_at timestamp(6) with time zone NOT NULL,
    reported_by uuid NOT NULL,
    resolution character varying(2000),
    resolved_at timestamp(6) with time zone,
    resolved_by uuid,
    status character varying(255) NOT NULL,
    tenant_id uuid NOT NULL,
    type character varying(255) NOT NULL,
    CONSTRAINT grading_issues_status_check CHECK (((status)::text = ANY (ARRAY[('OPEN'::character varying)::text, ('RESOLVED'::character varying)::text]))),
    CONSTRAINT grading_issues_type_check CHECK (((type)::text = ANY (ARRAY[('AUDIO_UNAVAILABLE'::character varying)::text, ('MEDIA_UNAVAILABLE'::character varying)::text, ('RESPONSE_DATA'::character varying)::text, ('OTHER'::character varying)::text])))
);


--
-- Name: grading_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.grading_issues ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.grading_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: idempotency_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.idempotency_keys (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    completed boolean NOT NULL,
    expires_at timestamp(6) with time zone NOT NULL,
    idempotency_key character varying(128) NOT NULL,
    organization_id uuid NOT NULL,
    request_hash character varying(128) NOT NULL,
    result jsonb,
    scope character varying(32) NOT NULL,
    CONSTRAINT idempotency_keys_scope_check CHECK (((scope)::text = ANY (ARRAY[('ATTENDANCE'::character varying)::text, ('EXAMINER_COMMAND'::character varying)::text, ('SCORE_SELECTION'::character varying)::text, ('LICENSE_ISSUE'::character varying)::text, ('PRACTICE_SESSION_OP'::character varying)::text])))
);


--
-- Name: idempotency_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.idempotency_keys ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.idempotency_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: organization_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_members (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    organization_id uuid NOT NULL,
    status character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    CONSTRAINT organization_members_status_check CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('SUSPENDED'::character varying)::text])))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    class_name character varying(255),
    credential_hash character varying(255),
    date_of_birth date,
    email character varying(255),
    full_name character varying(255),
    must_change_password boolean NOT NULL,
    phone character varying(255),
    status character varying(255) NOT NULL,
    student_code character varying(255),
    username character varying(255) NOT NULL,
    CONSTRAINT users_status_check CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('SUSPENDED'::character varying)::text])))
);


--
-- Name: identity_staff_student_search_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.identity_staff_student_search_view AS
 SELECT om.organization_id AS tenant_id,
    u.public_id AS student_public_id,
    COALESCE(NULLIF(TRIM(BOTH FROM u.full_name), ''::text), (u.username)::text, (u.email)::text) AS display_name,
    u.email
   FROM (public.users u
     JOIN public.organization_members om ON (((om.user_id = u.id) AND (om.deleted = false))))
  WHERE (u.deleted = false);


--
-- Name: organization_member_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_member_roles (
    member_id bigint NOT NULL,
    role character varying(255) NOT NULL,
    CONSTRAINT organization_member_roles_role_check CHECK (((role)::text = ANY (ARRAY[('PLATFORM_ADMIN'::character varying)::text, ('PLATFORM_MANAGER'::character varying)::text, ('ACADEMIC_MANAGER'::character varying)::text, ('ACADEMIC_STAFF'::character varying)::text, ('PLATFORM_AUTHOR'::character varying)::text, ('HOST_ADMIN'::character varying)::text, ('PROCTOR'::character varying)::text, ('EXAMINER'::character varying)::text, ('STUDENT'::character varying)::text])))
);


--
-- Name: identity_student_directory; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.identity_student_directory AS
 SELECT u.id,
    u.public_id,
    u.email,
    u.full_name,
    u.student_code,
    u.phone,
    om.status,
    om.created_at,
    om.organization_id AS tenant_id,
    u.deleted,
    u.username,
    u.must_change_password
   FROM ((public.users u
     JOIN public.organization_members om ON (((om.user_id = u.id) AND (om.deleted = false))))
     JOIN public.organization_member_roles omr ON (((omr.member_id = om.id) AND ((omr.role)::text = 'STUDENT'::text))));


--
-- Name: license_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.license_codes (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    code character varying(32) NOT NULL,
    code_expires_at timestamp(6) with time zone,
    issued_at timestamp(6) with time zone NOT NULL,
    issued_by uuid NOT NULL,
    plan_id uuid NOT NULL,
    redeemed_at timestamp(6) with time zone,
    redeemed_by_tenant_id uuid,
    revoke_reason character varying(255),
    status character varying(16) NOT NULL,
    subscription_id uuid,
    bound_tenant_id uuid,
    requested_starts_at timestamp(6) with time zone,
    contract_reference character varying(64),
    note character varying(500),
    CONSTRAINT license_codes_status_check CHECK (((status)::text = ANY (ARRAY[('ISSUED'::character varying)::text, ('REDEEMED'::character varying)::text, ('REVOKED'::character varying)::text, ('EXPIRED'::character varying)::text])))
);


--
-- Name: license_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.license_codes ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.license_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: media_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_objects (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    asset_id character varying(255),
    audio_prompt boolean DEFAULT false NOT NULL,
    cloudinary_delivery_type character varying(24) NOT NULL,
    cloudinary_public_id character varying(255),
    cloudinary_resource_type character varying(255),
    content_type character varying(255) NOT NULL,
    duration_seconds integer,
    owner_public_id uuid NOT NULL,
    practice_item_public_id uuid,
    practice_session_public_id uuid,
    purpose character varying(64),
    secure_url text,
    size_bytes bigint,
    status character varying(255) NOT NULL,
    storage_key character varying(255) NOT NULL,
    tenant_id uuid,
    CONSTRAINT media_objects_cloudinary_delivery_type_check CHECK (((cloudinary_delivery_type)::text = ANY (ARRAY[('UPLOAD'::character varying)::text, ('AUTHENTICATED'::character varying)::text]))),
    CONSTRAINT media_objects_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING_UPLOAD'::character varying)::text, ('UPLOADED'::character varying)::text])))
);


--
-- Name: media_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.media_objects ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.media_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_announcements (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    public_id uuid DEFAULT gen_random_uuid() NOT NULL,
    updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    affected_from timestamp(6) with time zone,
    affected_until timestamp(6) with time zone,
    author_user_public_id uuid NOT NULL,
    body character varying(5000) NOT NULL,
    category character varying(32) NOT NULL,
    correction_of_public_id uuid,
    importance character varying(16) NOT NULL,
    published_at timestamp(6) with time zone,
    published_content_public_id uuid,
    title character varying(150) NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    CONSTRAINT notification_announcements_category_check CHECK (((category)::text = ANY (ARRAY[('SYSTEM_NOTICE'::character varying)::text, ('MAINTENANCE'::character varying)::text, ('SESSION'::character varying)::text, ('APPLICATION'::character varying)::text, ('BILLING'::character varying)::text, ('SUPPORT'::character varying)::text]))),
    CONSTRAINT notification_announcements_importance_check CHECK (((importance)::text = ANY (ARRAY[('INFO'::character varying)::text, ('IMPORTANT'::character varying)::text])))
);


--
-- Name: notification_announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notification_announcements ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notification_announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_inbox_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_inbox_snapshots (
    id bigint NOT NULL,
    public_id uuid DEFAULT gen_random_uuid() NOT NULL,
    recipient_user_public_id uuid NOT NULL,
    tenant_id uuid,
    upper_sequence bigint NOT NULL,
    read_revision bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT notification_inbox_snapshots_check CHECK ((expires_at > created_at)),
    CONSTRAINT notification_inbox_snapshots_read_revision_check CHECK ((read_revision >= 0)),
    CONSTRAINT notification_inbox_snapshots_upper_sequence_check CHECK ((upper_sequence >= 0))
);


--
-- Name: notification_inbox_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notification_inbox_snapshots ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notification_inbox_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_logs (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    body character varying(255) NOT NULL,
    dedupe_key character varying(255),
    notification_type character varying(255) NOT NULL,
    recipient_email character varying(255) NOT NULL,
    recipient_user_public_id uuid,
    sent_at timestamp(6) with time zone,
    status character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    tenant_id uuid,
    CONSTRAINT notification_logs_notification_type_check CHECK (((notification_type)::text = ANY ((ARRAY['STUDENT_ENROLLED'::character varying, 'ATTEMPT_PUBLISHED'::character varying, 'VIOLATION_DETECTED'::character varying, 'SESSION_CANCELLED'::character varying, 'STUDENT_ENROLLMENT_CONFLICT'::character varying, 'TENANT_APPLICATION_SUBMITTED'::character varying, 'TENANT_APPLICATION_APPROVED'::character varying, 'TENANT_APPLICATION_REJECTED'::character varying, 'USER_CREDENTIALS_SENT'::character varying, 'PRACTICE_EMAIL_CHALLENGE'::character varying, 'PASSWORD_RESET_LINK_SENT'::character varying])::text[]))),
    CONSTRAINT notification_logs_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('SENT'::character varying)::text, ('FAILED'::character varying)::text])))
);


--
-- Name: notification_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notification_logs ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notification_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_recipient_streams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_recipient_streams (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    public_id uuid DEFAULT gen_random_uuid() NOT NULL,
    updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_sequence bigint DEFAULT 0 NOT NULL,
    read_revision bigint DEFAULT 0 NOT NULL,
    recipient_user_public_id uuid NOT NULL,
    tenant_id uuid
);


--
-- Name: notification_recipient_streams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notification_recipient_streams ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notification_recipient_streams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_recipients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_recipients (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    public_id uuid DEFAULT gen_random_uuid() NOT NULL,
    updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    claim_token uuid,
    completed_at timestamp(6) with time zone,
    content_public_id uuid NOT NULL,
    delivered_at timestamp(6) with time zone,
    last_failure_code character varying(64),
    lease_until timestamp(6) with time zone,
    next_attempt_at timestamp(6) with time zone NOT NULL,
    read_at timestamp(6) with time zone,
    recipient_user_public_id uuid NOT NULL,
    sequence_no bigint,
    status character varying(16) DEFAULT 'PENDING'::character varying NOT NULL,
    tenant_id uuid,
    CONSTRAINT notification_recipients_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('PROCESSING'::character varying)::text, ('DELIVERED'::character varying)::text, ('FAILED'::character varying)::text, ('SUPPRESSED'::character varying)::text])))
);


--
-- Name: notification_recipients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notification_recipients ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notification_recipients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    public_id uuid DEFAULT gen_random_uuid() NOT NULL,
    updated_at timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    body character varying(5000) NOT NULL,
    category character varying(32) NOT NULL,
    event_key character varying(255) NOT NULL,
    importance character varying(16) NOT NULL,
    notification_type character varying(48) NOT NULL,
    payload_hash character varying(64) NOT NULL,
    schema_version integer NOT NULL,
    target_public_id uuid NOT NULL,
    target_type character varying(32) NOT NULL,
    title character varying(150) NOT NULL,
    CONSTRAINT notifications_category_check CHECK (((category)::text = ANY (ARRAY[('SYSTEM_NOTICE'::character varying)::text, ('MAINTENANCE'::character varying)::text, ('SESSION'::character varying)::text, ('APPLICATION'::character varying)::text, ('BILLING'::character varying)::text, ('SUPPORT'::character varying)::text]))),
    CONSTRAINT notifications_importance_check CHECK (((importance)::text = ANY (ARRAY[('INFO'::character varying)::text, ('IMPORTANT'::character varying)::text]))),
    CONSTRAINT notifications_notification_type_check CHECK (((notification_type)::text = ANY ((ARRAY['APPLICATION_SUBMITTED'::character varying, 'PLATFORM_ANNOUNCEMENT'::character varying, 'SESSION_CLOSING_SOON'::character varying, 'SESSION_GRADING_COMPLETED'::character varying, 'SESSION_PREVIEW_READY'::character varying, 'COMMERCIAL_OUTCOME_CONFIRMED'::character varying, 'ORDER_EXPIRED'::character varying, 'SUBSCRIPTION_REVOKED'::character varying, 'SUPPORT_TICKET_SUBMITTED'::character varying, 'SUPPORT_TICKET_NOTE_ADDED'::character varying, 'SUPPORT_TICKET_STATUS_CHANGED'::character varying])::text[]))),
    CONSTRAINT notifications_target_type_check CHECK (((target_type)::text = ANY (ARRAY[('APPLICATION'::character varying)::text, ('ANNOUNCEMENT'::character varying)::text, ('SESSION'::character varying)::text, ('ORDER'::character varying)::text, ('SUBSCRIPTION'::character varying)::text, ('QUOTA'::character varying)::text, ('SUPPORT_TICKET'::character varying)::text])))
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notifications ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: order_code_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_code_seq
    START WITH 1000000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_payments (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    processed boolean NOT NULL,
    raw_payload text NOT NULL,
    received_at timestamp(6) with time zone NOT NULL,
    order_id bigint NOT NULL
);


--
-- Name: order_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.order_payments ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.order_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    amount numeric(19,2) NOT NULL,
    currency character varying(3) NOT NULL,
    order_code bigint NOT NULL,
    paid_at timestamp(6) with time zone,
    payment_link_url character varying(512),
    plan_id uuid NOT NULL,
    status character varying(16) NOT NULL,
    tenant_id uuid NOT NULL,
    CONSTRAINT orders_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('PAID'::character varying)::text, ('CANCELLED'::character varying)::text, ('EXPIRED'::character varying)::text])))
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.orders ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: organization_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.organization_members ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.organization_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: organization_quota_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_quota_grants (
    organization_id bigint NOT NULL,
    actor_user_id uuid NOT NULL,
    amount integer NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    note character varying(255),
    package_name character varying(255) NOT NULL,
    public_id uuid NOT NULL,
    "position" integer NOT NULL
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    address character varying(255),
    code character varying(255) NOT NULL,
    contact_email character varying(255),
    contact_phone character varying(255),
    facility_type character varying(255) NOT NULL,
    logo_url character varying(255),
    name character varying(255) NOT NULL,
    organization_type character varying(255) NOT NULL,
    package_name character varying(255) NOT NULL,
    primary_color character varying(255),
    province_code character varying(16),
    province_name character varying(255),
    reject_reason character varying(500),
    reviewed_at timestamp(6) with time zone,
    reviewed_by uuid,
    status character varying(255) NOT NULL,
    student_limit integer NOT NULL,
    suspended_until timestamp(6) with time zone,
    tax_code character varying(64),
    version bigint,
    ward_code character varying(16),
    ward_name character varying(255),
    CONSTRAINT organizations_facility_type_check CHECK (((facility_type)::text = ANY (ARRAY[('MAIN'::character varying)::text, ('BRANCH'::character varying)::text, ('TEST_CENTER'::character varying)::text]))),
    CONSTRAINT organizations_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('ACTIVE'::character varying)::text, ('REJECTED'::character varying)::text, ('SUSPENDED'::character varying)::text])))
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.organizations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    expires_at timestamp(6) with time zone NOT NULL,
    token_hash character varying(255) NOT NULL,
    used_at timestamp(6) with time zone,
    user_id bigint NOT NULL
);


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.password_reset_tokens ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.password_reset_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: platform_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_settings (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    description character varying(255),
    setting_key character varying(100) NOT NULL,
    value character varying(255) NOT NULL
);


--
-- Name: platform_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.platform_settings ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.platform_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: practice_mock_test_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.practice_mock_test_items (
    id bigint NOT NULL,
    mock_test_id bigint NOT NULL,
    question_public_id uuid NOT NULL,
    task_code character varying(64) NOT NULL,
    section character varying(32) NOT NULL,
    order_index integer NOT NULL
);


--
-- Name: practice_mock_test_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.practice_mock_test_items ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.practice_mock_test_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: practice_mock_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.practice_mock_tests (
    id bigint NOT NULL,
    public_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    sequence_no integer NOT NULL,
    title character varying(128) NOT NULL,
    seed bigint NOT NULL,
    template_public_id uuid,
    template_version integer,
    status character varying(16) NOT NULL,
    item_count integer NOT NULL,
    estimated_minutes integer NOT NULL,
    version bigint,
    CONSTRAINT ck_practice_mock_tests_status CHECK (((status)::text = ANY ((ARRAY['PUBLISHED'::character varying, 'HIDDEN'::character varying])::text[])))
);


--
-- Name: practice_mock_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.practice_mock_tests ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.practice_mock_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: practice_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.practice_responses (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    ai_detail_json text,
    ai_feedback text,
    ai_model character varying(160),
    ai_provider character varying(64),
    ai_provider_version character varying(100),
    ai_result_hash character varying(64),
    ai_score integer,
    ai_score_status character varying(32),
    ai_scored_at timestamp(6) with time zone,
    ai_sub_scores_json text,
    ai_transcript text,
    answer_schema_version integer,
    answered_at timestamp(6) with time zone,
    audio_prompt_ref uuid,
    confidence character varying(16),
    contract_version integer,
    correct_answer_text text,
    display_name character varying(128) NOT NULL,
    image_prompt_ref uuid,
    max_word_count integer,
    min_word_count integer,
    objective_evaluated_at timestamp(6) with time zone,
    objective_options_json text,
    objective_score integer,
    options_json text,
    order_index integer NOT NULL,
    practice_session_id bigint NOT NULL,
    prompt_text text,
    reference_answer_text text,
    renderer_key character varying(128) NOT NULL,
    saved_payload text,
    scoring_attempts integer NOT NULL,
    scoring_dispatch_token uuid,
    scoring_dispatched_at timestamp(6) with time zone,
    scoring_failure_code character varying(32),
    scoring_redispatch_count integer NOT NULL,
    scoring_requested_at timestamp(6) with time zone,
    scoring_status character varying(16) NOT NULL,
    section character varying(32) NOT NULL,
    skipped_at timestamp(6) with time zone,
    source_question_public_id uuid,
    status character varying(16) NOT NULL,
    task_code character varying(64) NOT NULL,
    version bigint,
    pre_listen_seconds integer,
    pre_record_seconds integer,
    response_seconds integer,
    CONSTRAINT practice_responses_confidence_check CHECK (((confidence)::text = ANY (ARRAY[('LOW'::character varying)::text, ('MEDIUM'::character varying)::text, ('HIGH'::character varying)::text]))),
    CONSTRAINT practice_responses_scoring_status_check CHECK (((scoring_status)::text = ANY (ARRAY[('NONE'::character varying)::text, ('SCORING'::character varying)::text, ('SCORED'::character varying)::text, ('FAILED'::character varying)::text]))),
    CONSTRAINT practice_responses_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('ANSWERED'::character varying)::text, ('SKIPPED'::character varying)::text])))
);


--
-- Name: practice_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.practice_responses ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.practice_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: practice_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.practice_sessions (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    catalog_version character varying(32) NOT NULL,
    client_capabilities text,
    completed_at timestamp(6) with time zone,
    deadline_at timestamp(6) with time zone,
    discarded_at timestamp(6) with time zone,
    last_activity_at timestamp(6) with time zone,
    product_code character varying(64) NOT NULL,
    selected_task_types text,
    source_type character varying(16) NOT NULL,
    start_idempotency_key character varying(128) NOT NULL,
    start_request_hash character varying(64) NOT NULL,
    started_at timestamp(6) with time zone,
    status character varying(16) NOT NULL,
    student_public_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    time_limit_seconds integer DEFAULT 0 NOT NULL,
    title character varying(128) NOT NULL,
    version bigint,
    timing_mode character varying(16),
    question_count integer,
    kind character varying(16),
    skill_code character varying(16),
    mock_test_id bigint,
    CONSTRAINT ck_practice_sessions_kind CHECK (((kind IS NULL) OR ((kind)::text = ANY ((ARRAY['TASK'::character varying, 'SKILL'::character varying, 'MOCK_TEST'::character varying])::text[])))),
    CONSTRAINT ck_practice_sessions_question_count CHECK (((question_count IS NULL) OR ((question_count >= 1) AND ((question_count <= 50) OR ((kind)::text = 'MOCK_TEST'::text))))),
    CONSTRAINT ck_practice_sessions_timing_mode CHECK (((timing_mode IS NULL) OR ((timing_mode)::text = ANY ((ARRAY['TIMED'::character varying, 'UNTIMED'::character varying])::text[])))),
    CONSTRAINT practice_sessions_source_type_check CHECK (((source_type)::text = 'PRACTICE'::text)),
    CONSTRAINT practice_sessions_status_check CHECK (((status)::text = ANY (ARRAY[('OVERVIEW'::character varying)::text, ('IN_PROGRESS'::character varying)::text, ('COMPLETED'::character varying)::text, ('DISCARDED'::character varying)::text, ('EXPIRED'::character varying)::text])))
);


--
-- Name: practice_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.practice_sessions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.practice_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: practice_student_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.practice_student_profiles (
    id bigint NOT NULL,
    public_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    student_public_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    exam_date date,
    version bigint
);


--
-- Name: practice_student_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.practice_student_profiles ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.practice_student_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: programs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programs (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    description character varying(255),
    end_date date,
    name character varying(255) NOT NULL,
    start_date date,
    status character varying(255) NOT NULL,
    organization_id bigint NOT NULL,
    CONSTRAINT programs_status_check CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('INACTIVE'::character varying)::text, ('SUSPENDED'::character varying)::text])))
);


--
-- Name: programs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.programs ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.programs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: question_generation_job_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_generation_job_items (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    item_index integer NOT NULL,
    stage character varying(24) NOT NULL,
    question_public_id uuid,
    failure_code character varying(64),
    failure_note character varying(300),
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT question_generation_job_items_stage_check CHECK (((stage)::text = ANY ((ARRAY['QUEUED'::character varying, 'GENERATING'::character varying, 'VALIDATING'::character varying, 'REVIEWING'::character varying, 'RENDERING_MEDIA'::character varying, 'READY'::character varying, 'SAVED'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: question_generation_job_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_generation_job_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_generation_job_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_generation_job_items_id_seq OWNED BY public.question_generation_job_items.id;


--
-- Name: question_generation_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_generation_jobs (
    id bigint NOT NULL,
    public_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    requested_by_user_public_id uuid NOT NULL,
    task_type_key character varying(64) NOT NULL,
    cefr_level character varying(2) NOT NULL,
    pool character varying(16) NOT NULL,
    topic_hint character varying(200),
    requested_count integer NOT NULL,
    status character varying(16) NOT NULL,
    succeeded_count integer DEFAULT 0 NOT NULL,
    failed_count integer DEFAULT 0 NOT NULL,
    worker_id character varying(64),
    lease_until timestamp with time zone,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    failure_code character varying(64),
    save_questions boolean DEFAULT true NOT NULL,
    CONSTRAINT question_generation_jobs_requested_count_check CHECK (((requested_count >= 1) AND (requested_count <= 10))),
    CONSTRAINT question_generation_jobs_status_check CHECK (((status)::text = ANY ((ARRAY['QUEUED'::character varying, 'RUNNING'::character varying, 'CANCELLING'::character varying, 'COMPLETED'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: question_generation_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_generation_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_generation_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_generation_jobs_id_seq OWNED BY public.question_generation_jobs.id;


--
-- Name: question_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_options (
    question_id bigint NOT NULL,
    blank_index integer,
    correct boolean NOT NULL,
    correct_gap_index integer,
    order_index integer NOT NULL,
    public_id uuid NOT NULL,
    text text NOT NULL
);


--
-- Name: question_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_types (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    active boolean NOT NULL,
    author_user_public_id uuid,
    authoring_contract_key character varying(96),
    authoring_contract_version integer,
    code character varying(64) NOT NULL,
    display_name character varying(128) NOT NULL,
    display_order integer NOT NULL,
    first_published_at timestamp(6) with time zone,
    lifecycle_status character varying(16) NOT NULL,
    normalized_display_name character varying(128) NOT NULL,
    requires_audio_prompt boolean NOT NULL,
    requires_correct_answer boolean NOT NULL,
    requires_image_prompt boolean NOT NULL,
    requires_options boolean NOT NULL,
    requires_prompt_text boolean NOT NULL,
    requires_reference_answer boolean NOT NULL,
    requires_single_correct_option boolean NOT NULL,
    requires_word_count boolean NOT NULL,
    runtime_answer_schema_version integer,
    runtime_behavior_key character varying(64),
    runtime_locked_at timestamp(6) with time zone,
    runtime_min_app_version character varying(32),
    runtime_profile_key character varying(96),
    runtime_profile_version integer,
    runtime_renderer_key character varying(96),
    runtime_required_capabilities text[] NOT NULL,
    runtime_scoring_mode character varying(16),
    runtime_scoring_profile_key character varying(64),
    runtime_scoring_profile_version integer,
    scored boolean NOT NULL,
    screen_key character varying(96),
    section character varying(16) NOT NULL,
    short_name character varying(32) NOT NULL,
    task_type_key character varying(64) NOT NULL,
    uses_option_order_as_correct_position boolean NOT NULL,
    instruction character varying(500),
    stimulus_before_timer boolean DEFAULT false NOT NULL,
    stimulus_estimate_seconds integer DEFAULT 0 NOT NULL,
    CONSTRAINT question_types_section_check CHECK (((section)::text = ANY (ARRAY[('LISTENING'::character varying)::text, ('SPEAKING'::character varying)::text, ('READING'::character varying)::text, ('WRITING'::character varying)::text]))),
    CONSTRAINT question_types_stimulus_estimate_check CHECK ((stimulus_estimate_seconds >= 0))
);


--
-- Name: question_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.question_types ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.question_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questions (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    audio_prompt_ref uuid,
    author_user_public_id uuid,
    availability_flags_explicit boolean NOT NULL,
    available_for_exam boolean NOT NULL,
    available_for_practice boolean NOT NULL,
    correct_answer_text text,
    is_current boolean NOT NULL,
    ever_published boolean,
    image_prompt_ref uuid,
    max_word_count integer,
    min_word_count integer,
    pool character varying(16) NOT NULL,
    prompt_text text,
    pte_task_type character varying(255),
    reference_answer_text text,
    rejection_reason character varying(500),
    revision_group_public_id uuid NOT NULL,
    revision_number integer NOT NULL,
    status character varying(255) NOT NULL,
    supersedes_public_id uuid,
    task_type_key character varying(64) NOT NULL,
    task_type_section character varying(16) NOT NULL,
    tenant_id uuid,
    version bigint NOT NULL,
    cefr_level character varying(2),
    generation_meta jsonb,
    content_hash character varying(64),
    generation_job_public_id uuid,
    generation_item_index integer,
    CONSTRAINT questions_cefr_level_check CHECK (((cefr_level IS NULL) OR ((cefr_level)::text = ANY ((ARRAY['A1'::character varying, 'A2'::character varying, 'B1'::character varying, 'B2'::character varying, 'C1'::character varying, 'C2'::character varying])::text[])))),
    CONSTRAINT questions_pool_check CHECK (((pool)::text = ANY (ARRAY[('EXAM'::character varying)::text, ('PRACTICE'::character varying)::text]))),
    CONSTRAINT questions_pte_task_type_check CHECK (((pte_task_type)::text = ANY (ARRAY[('PERSONAL_INTRODUCTION'::character varying)::text, ('READ_ALOUD'::character varying)::text, ('REPEAT_SENTENCE'::character varying)::text, ('DESCRIBE_IMAGE'::character varying)::text, ('RE_TELL_LECTURE'::character varying)::text, ('ANSWER_SHORT_QUESTION'::character varying)::text, ('RESPOND_TO_A_SITUATION'::character varying)::text, ('SUMMARIZE_GROUP_DISCUSSION'::character varying)::text, ('SUMMARIZE_WRITTEN_TEXT'::character varying)::text, ('WRITE_ESSAY'::character varying)::text, ('MC_READING_SINGLE'::character varying)::text, ('MC_READING_MULTIPLE'::character varying)::text, ('RE_ORDER_PARAGRAPHS'::character varying)::text, ('FILL_IN_THE_BLANKS_DRAG_AND_DROP'::character varying)::text, ('FILL_IN_THE_BLANKS_DROPDOWN'::character varying)::text, ('SUMMARIZE_SPOKEN_TEXT'::character varying)::text, ('MC_LISTENING_SINGLE'::character varying)::text, ('MC_LISTENING_MULTIPLE'::character varying)::text, ('FILL_IN_THE_BLANKS_TYPE_IN'::character varying)::text, ('HIGHLIGHT_CORRECT_SUMMARY'::character varying)::text, ('SELECT_MISSING_WORD'::character varying)::text, ('HIGHLIGHT_INCORRECT_WORDS'::character varying)::text, ('WRITE_FROM_DICTATION'::character varying)::text]))),
    CONSTRAINT questions_status_check CHECK (((status)::text = ANY (ARRAY[('DRAFT'::character varying)::text, ('PENDING_APPROVAL'::character varying)::text, ('APPROVED'::character varying)::text, ('ARCHIVED'::character varying)::text])))
);


--
-- Name: COLUMN questions.generation_meta; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.questions.generation_meta IS 'AI provenance and review sheet; null for hand-written questions';


--
-- Name: COLUMN questions.content_hash; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.questions.content_hash IS 'SHA-256 of the normalized stimulus text; set for AI-generated questions only';


--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.questions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_tokens (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    expires_at timestamp(6) with time zone NOT NULL,
    organization_id uuid,
    revoked boolean NOT NULL,
    token_hash character varying(255) NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.refresh_tokens ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: scoring_rubric_activation_audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scoring_rubric_activation_audits (
    id bigint NOT NULL,
    public_id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version_public_id uuid NOT NULL,
    previous_active_public_id uuid,
    actor_user_public_id uuid NOT NULL,
    activated_at timestamp(6) with time zone NOT NULL,
    diff_summary text,
    reason character varying(1000)
);


--
-- Name: scoring_rubric_activation_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.scoring_rubric_activation_audits ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.scoring_rubric_activation_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: scoring_rubric_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scoring_rubric_versions (
    id bigint NOT NULL,
    public_id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    version_no integer NOT NULL,
    status character varying(16) NOT NULL,
    parameters jsonb NOT NULL,
    catalog_version integer NOT NULL,
    author_user_public_id uuid,
    approver_user_public_id uuid,
    rejection_reason character varying(1000),
    submitted_at timestamp(6) with time zone,
    decided_at timestamp(6) with time zone,
    activated_at timestamp(6) with time zone,
    retired_at timestamp(6) with time zone,
    updated_by_user_public_id uuid,
    CONSTRAINT scoring_rubric_versions_catalog_version_check CHECK ((catalog_version >= 1)),
    CONSTRAINT scoring_rubric_versions_parameters_object_check CHECK ((jsonb_typeof(parameters) = 'object'::text)),
    CONSTRAINT scoring_rubric_versions_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'PENDING'::character varying, 'ACTIVE'::character varying, 'REJECTED'::character varying, 'RETIRED'::character varying])::text[]))),
    CONSTRAINT scoring_rubric_versions_version_no_check CHECK ((version_no >= 1))
);


--
-- Name: scoring_rubric_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.scoring_rubric_versions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.scoring_rubric_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: service_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_plans (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    currency character varying(3) NOT NULL,
    description character varying(255),
    duration_days integer,
    extra_student_slots integer,
    max_students_per_session integer,
    name character varying(255) NOT NULL,
    price numeric(19,2) NOT NULL,
    status character varying(32) NOT NULL,
    type character varying(32) NOT NULL,
    version bigint NOT NULL,
    CONSTRAINT service_plans_status_check CHECK (((status)::text = ANY (ARRAY[('DRAFT'::character varying)::text, ('ACTIVE'::character varying)::text, ('ARCHIVED'::character varying)::text]))),
    CONSTRAINT service_plans_type_check CHECK (((type)::text = ANY (ARRAY[('EXAM_PACKAGE'::character varying)::text, ('STUDENT_CAPACITY'::character varying)::text])))
);


--
-- Name: service_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.service_plans ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.service_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    activation_source character varying(16) NOT NULL,
    expires_at timestamp(6) with time zone NOT NULL,
    license_key character varying(32) NOT NULL,
    max_students_per_session integer NOT NULL,
    plan_id uuid NOT NULL,
    starts_at timestamp(6) with time zone NOT NULL,
    status character varying(16) NOT NULL,
    tenant_id uuid NOT NULL,
    CONSTRAINT subscriptions_activation_source_check CHECK (((activation_source)::text = ANY (ARRAY[('PAYMENT'::character varying)::text, ('LICENSE_CODE'::character varying)::text]))),
    CONSTRAINT subscriptions_status_check CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('EXPIRED'::character varying)::text, ('CANCELLED'::character varying)::text])))
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: support_ticket; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_ticket (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    category character varying(255) NOT NULL,
    description character varying(2000) NOT NULL,
    entity_id character varying(36),
    entity_type character varying(32),
    status character varying(255) NOT NULL,
    submitter_user_public_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    version bigint NOT NULL,
    CONSTRAINT support_ticket_category_check CHECK (((category)::text = ANY (ARRAY[('BUG'::character varying)::text, ('CONTENT_COMPLAINT'::character varying)::text, ('GENERAL_FEEDBACK'::character varying)::text]))),
    CONSTRAINT support_ticket_entity_type_check CHECK (((entity_type)::text = ANY (ARRAY[('EXAM_SESSION'::character varying)::text, ('EXAM_ATTEMPT'::character varying)::text, ('QUESTION'::character varying)::text]))),
    CONSTRAINT support_ticket_status_check CHECK (((status)::text = ANY (ARRAY[('OPEN'::character varying)::text, ('IN_PROGRESS'::character varying)::text, ('RESOLVED'::character varying)::text, ('CLOSED'::character varying)::text])))
);


--
-- Name: support_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.support_ticket ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.support_ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: support_ticket_note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_ticket_note (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    deleted boolean NOT NULL,
    public_id uuid NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    admin_public_id uuid NOT NULL,
    content text NOT NULL,
    ticket_id bigint NOT NULL,
    ticket_public_id uuid NOT NULL
);


--
-- Name: support_ticket_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.support_ticket_note ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.support_ticket_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    user_id bigint NOT NULL,
    role character varying(255) NOT NULL,
    CONSTRAINT user_roles_role_check CHECK (((role)::text = ANY (ARRAY[('PLATFORM_ADMIN'::character varying)::text, ('PLATFORM_MANAGER'::character varying)::text, ('ACADEMIC_MANAGER'::character varying)::text, ('ACADEMIC_STAFF'::character varying)::text, ('PLATFORM_AUTHOR'::character varying)::text, ('HOST_ADMIN'::character varying)::text, ('PROCTOR'::character varying)::text, ('EXAMINER'::character varying)::text, ('STUDENT'::character varying)::text])))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.users ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ai_prompt_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_prompt_versions ALTER COLUMN id SET DEFAULT nextval('public.ai_prompt_versions_id_seq'::regclass);


--
-- Name: question_generation_job_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_generation_job_items ALTER COLUMN id SET DEFAULT nextval('public.question_generation_job_items_id_seq'::regclass);


--
-- Name: question_generation_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_generation_jobs ALTER COLUMN id SET DEFAULT nextval('public.question_generation_jobs_id_seq'::regclass);


--
-- Name: ai_prompt_versions ai_prompt_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_prompt_versions
    ADD CONSTRAINT ai_prompt_versions_pkey PRIMARY KEY (id);


--
-- Name: ai_prompt_versions ai_prompt_versions_public_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_prompt_versions
    ADD CONSTRAINT ai_prompt_versions_public_id_key UNIQUE (public_id);


--
-- Name: answer_evaluations answer_evaluations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answer_evaluations
    ADD CONSTRAINT answer_evaluations_pkey PRIMARY KEY (id);


--
-- Name: attempt_answers attempt_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attempt_answers
    ADD CONSTRAINT attempt_answers_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: chat_usage_daily chat_usage_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_usage_daily
    ADD CONSTRAINT chat_usage_daily_pkey PRIMARY KEY (usage_date, model);


--
-- Name: chat_usage chat_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_usage
    ADD CONSTRAINT chat_usage_pkey PRIMARY KEY (id);


--
-- Name: class_students class_students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_students
    ADD CONSTRAINT class_students_pkey PRIMARY KEY (id);


--
-- Name: classes classes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id);


--
-- Name: exam_attempts exam_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT exam_attempts_pkey PRIMARY KEY (id);


--
-- Name: exam_blueprints exam_blueprints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_blueprints
    ADD CONSTRAINT exam_blueprints_pkey PRIMARY KEY (id);


--
-- Name: exam_definition_cefr_targets exam_definition_cefr_targets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_definition_cefr_targets
    ADD CONSTRAINT exam_definition_cefr_targets_pkey PRIMARY KEY (exam_definition_id, level);


--
-- Name: exam_definitions exam_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_definitions
    ADD CONSTRAINT exam_definitions_pkey PRIMARY KEY (id);


--
-- Name: exam_incidents exam_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_incidents
    ADD CONSTRAINT exam_incidents_pkey PRIMARY KEY (id);


--
-- Name: exam_registrations exam_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_registrations
    ADD CONSTRAINT exam_registrations_pkey PRIMARY KEY (id);


--
-- Name: exam_results exam_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT exam_results_pkey PRIMARY KEY (id);


--
-- Name: exam_session_audience_sources exam_session_audience_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_audience_sources
    ADD CONSTRAINT exam_session_audience_sources_pkey PRIMARY KEY (id);


--
-- Name: exam_session_cefr_targets exam_session_cefr_targets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_cefr_targets
    ADD CONSTRAINT exam_session_cefr_targets_pkey PRIMARY KEY (session_id, level);


--
-- Name: exam_session_proctors exam_session_proctors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_proctors
    ADD CONSTRAINT exam_session_proctors_pkey PRIMARY KEY (id);


--
-- Name: exam_sessions exam_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_sessions
    ADD CONSTRAINT exam_sessions_pkey PRIMARY KEY (id);


--
-- Name: exam_versions exam_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_versions
    ADD CONSTRAINT exam_versions_pkey PRIMARY KEY (id);


--
-- Name: generation_usage_daily generation_usage_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_usage_daily
    ADD CONSTRAINT generation_usage_daily_pkey PRIMARY KEY (usage_date, role, model);


--
-- Name: grading_assignments grading_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_assignments
    ADD CONSTRAINT grading_assignments_pkey PRIMARY KEY (id);


--
-- Name: grading_issues grading_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_issues
    ADD CONSTRAINT grading_issues_pkey PRIMARY KEY (id);


--
-- Name: idempotency_keys idempotency_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idempotency_keys
    ADD CONSTRAINT idempotency_keys_pkey PRIMARY KEY (id);


--
-- Name: license_codes license_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.license_codes
    ADD CONSTRAINT license_codes_pkey PRIMARY KEY (id);


--
-- Name: media_objects media_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_objects
    ADD CONSTRAINT media_objects_pkey PRIMARY KEY (id);


--
-- Name: exam_sessions no_overlap_per_subscription; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_sessions
    ADD CONSTRAINT no_overlap_per_subscription EXCLUDE USING gist (subscription_id WITH =, tstzrange(opens_at, closes_at) WITH &&) WHERE (((status)::text = ANY (ARRAY[('SCHEDULED'::character varying)::text, ('OPEN'::character varying)::text])));


--
-- Name: notification_announcements notification_announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_announcements
    ADD CONSTRAINT notification_announcements_pkey PRIMARY KEY (id);


--
-- Name: notification_inbox_snapshots notification_inbox_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_inbox_snapshots
    ADD CONSTRAINT notification_inbox_snapshots_pkey PRIMARY KEY (id);


--
-- Name: notification_inbox_snapshots notification_inbox_snapshots_public_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_inbox_snapshots
    ADD CONSTRAINT notification_inbox_snapshots_public_id_key UNIQUE (public_id);


--
-- Name: notification_logs notification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT notification_logs_pkey PRIMARY KEY (id);


--
-- Name: notification_recipient_streams notification_recipient_streams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_recipient_streams
    ADD CONSTRAINT notification_recipient_streams_pkey PRIMARY KEY (id);


--
-- Name: notification_recipients notification_recipients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_recipients
    ADD CONSTRAINT notification_recipients_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: order_payments order_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_payments
    ADD CONSTRAINT order_payments_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: organization_member_roles organization_member_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_member_roles
    ADD CONSTRAINT organization_member_roles_pkey PRIMARY KEY (member_id, role);


--
-- Name: organization_members organization_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT organization_members_pkey PRIMARY KEY (id);


--
-- Name: organization_quota_grants organization_quota_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_quota_grants
    ADD CONSTRAINT organization_quota_grants_pkey PRIMARY KEY (organization_id, "position");


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: platform_settings platform_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_settings
    ADD CONSTRAINT platform_settings_pkey PRIMARY KEY (id);


--
-- Name: practice_mock_test_items practice_mock_test_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_mock_test_items
    ADD CONSTRAINT practice_mock_test_items_pkey PRIMARY KEY (id);


--
-- Name: practice_mock_tests practice_mock_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_mock_tests
    ADD CONSTRAINT practice_mock_tests_pkey PRIMARY KEY (id);


--
-- Name: practice_mock_tests practice_mock_tests_public_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_mock_tests
    ADD CONSTRAINT practice_mock_tests_public_id_key UNIQUE (public_id);


--
-- Name: practice_responses practice_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_responses
    ADD CONSTRAINT practice_responses_pkey PRIMARY KEY (id);


--
-- Name: practice_sessions practice_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_sessions
    ADD CONSTRAINT practice_sessions_pkey PRIMARY KEY (id);


--
-- Name: practice_student_profiles practice_student_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_student_profiles
    ADD CONSTRAINT practice_student_profiles_pkey PRIMARY KEY (id);


--
-- Name: practice_student_profiles practice_student_profiles_public_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_student_profiles
    ADD CONSTRAINT practice_student_profiles_public_id_key UNIQUE (public_id);


--
-- Name: practice_student_profiles practice_student_profiles_student_public_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_student_profiles
    ADD CONSTRAINT practice_student_profiles_student_public_id_key UNIQUE (student_public_id);


--
-- Name: programs programs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_pkey PRIMARY KEY (id);


--
-- Name: question_generation_job_items question_generation_job_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_generation_job_items
    ADD CONSTRAINT question_generation_job_items_pkey PRIMARY KEY (id);


--
-- Name: question_generation_jobs question_generation_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_generation_jobs
    ADD CONSTRAINT question_generation_jobs_pkey PRIMARY KEY (id);


--
-- Name: question_generation_jobs question_generation_jobs_public_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_generation_jobs
    ADD CONSTRAINT question_generation_jobs_public_id_key UNIQUE (public_id);


--
-- Name: question_types question_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_types
    ADD CONSTRAINT question_types_pkey PRIMARY KEY (id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: scoring_rubric_activation_audits scoring_rubric_activation_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scoring_rubric_activation_audits
    ADD CONSTRAINT scoring_rubric_activation_audits_pkey PRIMARY KEY (id);


--
-- Name: scoring_rubric_versions scoring_rubric_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scoring_rubric_versions
    ADD CONSTRAINT scoring_rubric_versions_pkey PRIMARY KEY (id);


--
-- Name: service_plans service_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_plans
    ADD CONSTRAINT service_plans_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: support_ticket_note support_ticket_note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_ticket_note
    ADD CONSTRAINT support_ticket_note_pkey PRIMARY KEY (id);


--
-- Name: support_ticket support_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_ticket
    ADD CONSTRAINT support_ticket_pkey PRIMARY KEY (id);


--
-- Name: grading_assignments uk1dpmruu4adqiu45x8b65jcqnm; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_assignments
    ADD CONSTRAINT uk1dpmruu4adqiu45x8b65jcqnm UNIQUE (public_id);


--
-- Name: exam_session_audience_sources uk1f90uh80yobangwc9rn7lqd9y; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_audience_sources
    ADD CONSTRAINT uk1f90uh80yobangwc9rn7lqd9y UNIQUE (session_id, source_type, source_public_id);


--
-- Name: classes uk1h8bkaw5ivv071qsgqc7p8ff6; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT uk1h8bkaw5ivv071qsgqc7p8ff6 UNIQUE (public_id);


--
-- Name: subscriptions uk2041p5xdeitm6ospkov13883l; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT uk2041p5xdeitm6ospkov13883l UNIQUE (public_id);


--
-- Name: exam_registrations uk2lc0n4q73bjwv9q07tkwvtu1f; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_registrations
    ADD CONSTRAINT uk2lc0n4q73bjwv9q07tkwvtu1f UNIQUE (session_id, student_public_id);


--
-- Name: class_students uk3sq8lcv0rk8fq8q3jss5mepp0; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_students
    ADD CONSTRAINT uk3sq8lcv0rk8fq8q3jss5mepp0 UNIQUE (student_public_id);


--
-- Name: exam_sessions uk3tjdbcds6ie1udrie7dguyliv; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_sessions
    ADD CONSTRAINT uk3tjdbcds6ie1udrie7dguyliv UNIQUE (public_id);


--
-- Name: notification_recipient_streams uk4g0be6d25ic2bs38taufnp5gu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_recipient_streams
    ADD CONSTRAINT uk4g0be6d25ic2bs38taufnp5gu UNIQUE (public_id);


--
-- Name: exam_incidents uk4ydv9bw6l74russpu07i6niue; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_incidents
    ADD CONSTRAINT uk4ydv9bw6l74russpu07i6niue UNIQUE (public_id);


--
-- Name: questions uk6cg9cf79leuopy266yko1gq0k; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT uk6cg9cf79leuopy266yko1gq0k UNIQUE (public_id);


--
-- Name: exam_registrations uk6ndulkeoght1sulpyq4pr6f83; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_registrations
    ADD CONSTRAINT uk6ndulkeoght1sulpyq4pr6f83 UNIQUE (public_id);


--
-- Name: exam_blueprints uk7pvrmmywonbvtaanaw2jkpom9; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_blueprints
    ADD CONSTRAINT uk7pvrmmywonbvtaanaw2jkpom9 UNIQUE (public_id);


--
-- Name: exam_results uk8metffdrqh23fwkk7w7k94a9w; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT uk8metffdrqh23fwkk7w7k94a9w UNIQUE (attempt_public_id);


--
-- Name: subscriptions uk8mgbs54pnp8dtrykh882rfolu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT uk8mgbs54pnp8dtrykh882rfolu UNIQUE (license_key);


--
-- Name: exam_sessions uk9cr8ybvsog57xbnokge7k20rd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_sessions
    ADD CONSTRAINT uk9cr8ybvsog57xbnokge7k20rd UNIQUE (session_code);


--
-- Name: exam_results uk9hr1a3cb03cg63pb580iteb6b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT uk9hr1a3cb03cg63pb580iteb6b UNIQUE (public_id);


--
-- Name: exam_versions uk9qs4wydf8q25dhp3xucxvb3e8; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_versions
    ADD CONSTRAINT uk9qs4wydf8q25dhp3xucxvb3e8 UNIQUE (public_id);


--
-- Name: ai_prompt_versions uk_ai_prompt_versions_key_version; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_prompt_versions
    ADD CONSTRAINT uk_ai_prompt_versions_key_version UNIQUE (kind, prompt_key, version_no);


--
-- Name: exam_attempts uk_exam_attempt_session_student_number; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT uk_exam_attempt_session_student_number UNIQUE (session_public_id, student_public_id, attempt_number);


--
-- Name: exam_incidents uk_exam_incidents_attempt_client; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_incidents
    ADD CONSTRAINT uk_exam_incidents_attempt_client UNIQUE (attempt_public_id, client_event_id);


--
-- Name: exam_session_selected_skills uk_exam_session_selected_skills_session_skill; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_selected_skills
    ADD CONSTRAINT uk_exam_session_selected_skills_session_skill PRIMARY KEY (session_id, skill);


--
-- Name: license_codes uk_license_codes_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.license_codes
    ADD CONSTRAINT uk_license_codes_code UNIQUE (code);


--
-- Name: organization_members uk_organization_members_user_org; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT uk_organization_members_user_org UNIQUE (user_id, organization_id);


--
-- Name: password_reset_tokens uk_password_reset_tokens_public_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT uk_password_reset_tokens_public_id UNIQUE (public_id);


--
-- Name: password_reset_tokens uk_password_reset_tokens_token_hash; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT uk_password_reset_tokens_token_hash UNIQUE (token_hash);


--
-- Name: practice_mock_test_items uk_practice_mock_test_items_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_mock_test_items
    ADD CONSTRAINT uk_practice_mock_test_items_order UNIQUE (mock_test_id, order_index);


--
-- Name: practice_mock_tests uk_practice_mock_tests_sequence; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_mock_tests
    ADD CONSTRAINT uk_practice_mock_tests_sequence UNIQUE (sequence_no);


--
-- Name: practice_responses uk_practice_session_item_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_responses
    ADD CONSTRAINT uk_practice_session_item_order UNIQUE (practice_session_id, order_index);


--
-- Name: question_generation_job_items uk_qgen_job_items_job_index; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_generation_job_items
    ADD CONSTRAINT uk_qgen_job_items_job_index UNIQUE (job_id, item_index);


--
-- Name: users uk_users_username; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk_users_username UNIQUE (username);


--
-- Name: platform_settings ukayks1ajfa52rvppxmhanlyvht; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_settings
    ADD CONSTRAINT ukayks1ajfa52rvppxmhanlyvht UNIQUE (setting_key);


--
-- Name: platform_settings ukb8hix0jirwfdlxwp8w88svf31; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_settings
    ADD CONSTRAINT ukb8hix0jirwfdlxwp8w88svf31 UNIQUE (public_id);


--
-- Name: organizations ukbtawla3qrg7o64o7iyrors66t; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT ukbtawla3qrg7o64o7iyrors66t UNIQUE (public_id);


--
-- Name: notification_announcements ukc5ymrw8n2vtkap7oahvi8p0c4; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_announcements
    ADD CONSTRAINT ukc5ymrw8n2vtkap7oahvi8p0c4 UNIQUE (public_id);


--
-- Name: audit_logs ukcw6h8py7jx6jf1d4j3mjkrg47; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT ukcw6h8py7jx6jf1d4j3mjkrg47 UNIQUE (public_id);


--
-- Name: orders ukdhk2umg8ijjkg4njg6891trit; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT ukdhk2umg8ijjkg4njg6891trit UNIQUE (order_code);


--
-- Name: notification_recipients ukepbyoyjjkuhdeud3d7apfk2yk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_recipients
    ADD CONSTRAINT ukepbyoyjjkuhdeud3d7apfk2yk UNIQUE (public_id);


--
-- Name: orders ukex38j08vd23s81275ht75bsjy; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT ukex38j08vd23s81275ht75bsjy UNIQUE (public_id);


--
-- Name: class_students ukf7g9d43yfijro4rl3surbo8eu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_students
    ADD CONSTRAINT ukf7g9d43yfijro4rl3surbo8eu UNIQUE (public_id);


--
-- Name: license_codes ukfbtrbv53y5vid8h67xx2l3h7p; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.license_codes
    ADD CONSTRAINT ukfbtrbv53y5vid8h67xx2l3h7p UNIQUE (public_id);


--
-- Name: refresh_tokens ukfjyl14ew64f36fsck3mxw3ytk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT ukfjyl14ew64f36fsck3mxw3ytk UNIQUE (public_id);


--
-- Name: organization_members ukg2f99lx5g6ivgs2njftc5novr; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT ukg2f99lx5g6ivgs2njftc5novr UNIQUE (public_id);


--
-- Name: support_ticket_note ukgoo0o6tfv8xvg4sw2jo2lx7pu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_ticket_note
    ADD CONSTRAINT ukgoo0o6tfv8xvg4sw2jo2lx7pu UNIQUE (public_id);


--
-- Name: grading_issues ukhperj0ipe4iwop7l1jbgblh58; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_issues
    ADD CONSTRAINT ukhperj0ipe4iwop7l1jbgblh58 UNIQUE (public_id);


--
-- Name: question_types ukhpx76up1radqai3c75gak8pky; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_types
    ADD CONSTRAINT ukhpx76up1radqai3c75gak8pky UNIQUE (code);


--
-- Name: media_objects uki6yyhlj18u2l7guivr9agbqwu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_objects
    ADD CONSTRAINT uki6yyhlj18u2l7guivr9agbqwu UNIQUE (public_id);


--
-- Name: exam_session_proctors ukjly1w94em7secn2mndwum9638; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_proctors
    ADD CONSTRAINT ukjly1w94em7secn2mndwum9638 UNIQUE (public_id);


--
-- Name: attempt_answers ukjpn6c5oaqsw68m2fmv0ybkh4v; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attempt_answers
    ADD CONSTRAINT ukjpn6c5oaqsw68m2fmv0ybkh4v UNIQUE (attempt_id, item_public_id);


--
-- Name: license_codes ukjvdbgd6j1b75xgld9ftvq2c1b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.license_codes
    ADD CONSTRAINT ukjvdbgd6j1b75xgld9ftvq2c1b UNIQUE (subscription_id);


--
-- Name: practice_sessions ukkant2uwac1vuprox309gclmf5; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_sessions
    ADD CONSTRAINT ukkant2uwac1vuprox309gclmf5 UNIQUE (public_id);


--
-- Name: service_plans ukl1ebtro5huo3ehlkj47cbm4xq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_plans
    ADD CONSTRAINT ukl1ebtro5huo3ehlkj47cbm4xq UNIQUE (public_id);


--
-- Name: question_types uklbwcoqlo2iil9m1lbsu9j09k4; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_types
    ADD CONSTRAINT uklbwcoqlo2iil9m1lbsu9j09k4 UNIQUE (task_type_key);


--
-- Name: programs uklpgtrtmoynkr3lgmbrlwgoklm; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT uklpgtrtmoynkr3lgmbrlwgoklm UNIQUE (public_id);


--
-- Name: question_types ukm48cdjuwmom8qgwxtrid7h4vc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_types
    ADD CONSTRAINT ukm48cdjuwmom8qgwxtrid7h4vc UNIQUE (normalized_display_name);


--
-- Name: order_payments ukm7om7g2ayci4qxb9p5p9ey3ov; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_payments
    ADD CONSTRAINT ukm7om7g2ayci4qxb9p5p9ey3ov UNIQUE (public_id);


--
-- Name: answer_evaluations ukndp3s60bbcp1n8q4t6hinkmwc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answer_evaluations
    ADD CONSTRAINT ukndp3s60bbcp1n8q4t6hinkmwc UNIQUE (public_id);


--
-- Name: exam_definitions uknsmu2owth44lwe3ldnrlq8eim; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_definitions
    ADD CONSTRAINT uknsmu2owth44lwe3ldnrlq8eim UNIQUE (public_id);


--
-- Name: refresh_tokens uko2mlirhldriil2y7krapq4frt; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT uko2mlirhldriil2y7krapq4frt UNIQUE (token_hash);


--
-- Name: question_types uko9tkex46oi5b61tiaokweyouc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_types
    ADD CONSTRAINT uko9tkex46oi5b61tiaokweyouc UNIQUE (public_id);


--
-- Name: exam_session_audience_sources ukoew2jtwv8asr5q46a59m5wi; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_audience_sources
    ADD CONSTRAINT ukoew2jtwv8asr5q46a59m5wi UNIQUE (public_id);


--
-- Name: exam_attempts ukpglsrv8vet42hyoycn7btukik; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT ukpglsrv8vet42hyoycn7btukik UNIQUE (public_id);


--
-- Name: exam_session_proctors ukptgp3oxkdto0ft39c7q5tyjww; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_proctors
    ADD CONSTRAINT ukptgp3oxkdto0ft39c7q5tyjww UNIQUE (session_id, proctor_public_id);


--
-- Name: notifications ukqwcfwkb22prkvpgl4uyya4c8h; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT ukqwcfwkb22prkvpgl4uyya4c8h UNIQUE (public_id);


--
-- Name: support_ticket ukr9np3im0f012bhsei8d9xlwm0; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_ticket
    ADD CONSTRAINT ukr9np3im0f012bhsei8d9xlwm0 UNIQUE (public_id);


--
-- Name: idempotency_keys ukrali6fl0y7rlh1gvscmi3pvob; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idempotency_keys
    ADD CONSTRAINT ukrali6fl0y7rlh1gvscmi3pvob UNIQUE (public_id);


--
-- Name: practice_responses ukrts01no1fex4joapw84ihexei; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_responses
    ADD CONSTRAINT ukrts01no1fex4joapw84ihexei UNIQUE (public_id);


--
-- Name: users uks24bux761rbgowsl7a4b386ba; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uks24bux761rbgowsl7a4b386ba UNIQUE (public_id);


--
-- Name: media_objects uksgtiuvowouiejtm2pocmjhuvq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_objects
    ADD CONSTRAINT uksgtiuvowouiejtm2pocmjhuvq UNIQUE (storage_key);


--
-- Name: attempt_answers uksrjrnngjt09r3g400omfrokyk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attempt_answers
    ADD CONSTRAINT uksrjrnngjt09r3g400omfrokyk UNIQUE (public_id);


--
-- Name: notification_logs ukssdf0qqt48b68lwni92nws8h6; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT ukssdf0qqt48b68lwni92nws8h6 UNIQUE (public_id);


--
-- Name: answer_evaluations uq_answer_evaluation_source; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answer_evaluations
    ADD CONSTRAINT uq_answer_evaluation_source UNIQUE (answer_public_id, source);


--
-- Name: chat_usage uq_chat_usage_student_date; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_usage
    ADD CONSTRAINT uq_chat_usage_student_date UNIQUE (student_id, usage_date);


--
-- Name: grading_assignments uq_grading_assignment_session_attempt; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_assignments
    ADD CONSTRAINT uq_grading_assignment_session_attempt UNIQUE (session_public_id, attempt_public_id);


--
-- Name: idempotency_keys uq_idempotency_scope_key_org; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idempotency_keys
    ADD CONSTRAINT uq_idempotency_scope_key_org UNIQUE (scope, idempotency_key, organization_id);


--
-- Name: notification_recipients uq_notification_recipient_content; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_recipients
    ADD CONSTRAINT uq_notification_recipient_content UNIQUE (content_public_id, recipient_user_public_id);


--
-- Name: notification_recipients uq_notification_recipient_sequence; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_recipients
    ADD CONSTRAINT uq_notification_recipient_sequence UNIQUE (recipient_user_public_id, sequence_no);


--
-- Name: scoring_rubric_activation_audits uq_scoring_rubric_activation_audits_public_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scoring_rubric_activation_audits
    ADD CONSTRAINT uq_scoring_rubric_activation_audits_public_id UNIQUE (public_id);


--
-- Name: scoring_rubric_versions uq_scoring_rubric_versions_public_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scoring_rubric_versions
    ADD CONSTRAINT uq_scoring_rubric_versions_public_id UNIQUE (public_id);


--
-- Name: scoring_rubric_versions uq_scoring_rubric_versions_version_no; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scoring_rubric_versions
    ADD CONSTRAINT uq_scoring_rubric_versions_version_no UNIQUE (version_no);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_answer_evaluations_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_answer_evaluations_attempt ON public.answer_evaluations USING btree (tenant_id, attempt_public_id);


--
-- Name: idx_answer_evaluations_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_answer_evaluations_session ON public.answer_evaluations USING btree (tenant_id, session_public_id);


--
-- Name: idx_answers_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_answers_attempt ON public.attempt_answers USING btree (attempt_id);


--
-- Name: idx_attempts_student_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attempts_student_status ON public.exam_attempts USING btree (student_public_id, status);


--
-- Name: idx_attempts_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attempts_tenant ON public.exam_attempts USING btree (tenant_id);


--
-- Name: idx_audit_logs_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_tenant ON public.audit_logs USING btree (tenant_id);


--
-- Name: idx_audit_logs_tenant_aggregate_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_tenant_aggregate_type ON public.audit_logs USING btree (tenant_id, aggregate_type);


--
-- Name: idx_blueprints_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_blueprints_tenant ON public.exam_blueprints USING btree (tenant_id);


--
-- Name: idx_class_students_class; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_class_students_class ON public.class_students USING btree (class_id);


--
-- Name: idx_classes_organization; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_classes_organization ON public.classes USING btree (organization_id);


--
-- Name: idx_classes_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_classes_program ON public.classes USING btree (program_id);


--
-- Name: idx_exam_definitions_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_definitions_code ON public.exam_definitions USING btree (code);


--
-- Name: idx_exam_definitions_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_definitions_tenant ON public.exam_definitions USING btree (tenant_id) WHERE (tenant_id IS NOT NULL);


--
-- Name: idx_exam_incidents_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_incidents_attempt ON public.exam_incidents USING btree (attempt_public_id, detected_at);


--
-- Name: idx_exam_incidents_session_origin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_incidents_session_origin ON public.exam_incidents USING btree (tenant_id, session_public_id, origin, detected_at);


--
-- Name: idx_exam_registrations_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_registrations_session ON public.exam_registrations USING btree (session_id);


--
-- Name: idx_exam_registrations_student; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_registrations_student ON public.exam_registrations USING btree (tenant_id, student_public_id);


--
-- Name: idx_exam_results_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_results_session ON public.exam_results USING btree (session_public_id);


--
-- Name: idx_exam_results_student_tenant_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_results_student_tenant_published ON public.exam_results USING btree (student_public_id, tenant_id, published, published_at);


--
-- Name: idx_exam_session_proctors_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_session_proctors_session ON public.exam_session_proctors USING btree (session_id);


--
-- Name: idx_exam_versions_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exam_versions_tenant ON public.exam_versions USING btree (tenant_id);


--
-- Name: idx_grading_assignment_examiner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grading_assignment_examiner ON public.grading_assignments USING btree (tenant_id, session_public_id, examiner_public_id);


--
-- Name: idx_grading_assignment_owner_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grading_assignment_owner_status ON public.grading_assignments USING btree (tenant_id, examiner_public_id, status);


--
-- Name: idx_grading_issues_assignment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_grading_issues_assignment ON public.grading_issues USING btree (tenant_id, assignment_id, status);


--
-- Name: idx_idempotency_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_idempotency_expires_at ON public.idempotency_keys USING btree (expires_at);


--
-- Name: idx_inbox_snapshot_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inbox_snapshot_owner ON public.notification_inbox_snapshots USING btree (recipient_user_public_id, tenant_id, expires_at);


--
-- Name: idx_license_codes_bound_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_license_codes_bound_tenant ON public.license_codes USING btree (bound_tenant_id);


--
-- Name: idx_license_codes_status_expiry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_license_codes_status_expiry ON public.license_codes USING btree (status, code_expires_at);


--
-- Name: idx_media_objects_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_media_objects_owner ON public.media_objects USING btree (owner_public_id);


--
-- Name: idx_notification_logs_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_logs_tenant ON public.notification_logs USING btree (tenant_id);


--
-- Name: idx_notification_recipient_claim; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_recipient_claim ON public.notification_recipients USING btree (status, next_attempt_at);


--
-- Name: idx_notification_recipient_content_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_recipient_content_status ON public.notification_recipients USING btree (content_public_id, status);


--
-- Name: idx_notification_recipient_lease; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_recipient_lease ON public.notification_recipients USING btree (status, lease_until);


--
-- Name: idx_options_question; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_options_question ON public.question_options USING btree (question_id);


--
-- Name: idx_order_payments_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_order_payments_order ON public.order_payments USING btree (order_id);


--
-- Name: idx_order_payments_received_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_order_payments_received_at ON public.order_payments USING btree (received_at);


--
-- Name: idx_orders_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_status_created ON public.orders USING btree (status, created_at);


--
-- Name: idx_orders_tenant_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_tenant_created ON public.orders USING btree (tenant_id, created_at);


--
-- Name: idx_organization_members_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organization_members_org ON public.organization_members USING btree (organization_id);


--
-- Name: idx_organizations_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_status ON public.organizations USING btree (status);


--
-- Name: idx_password_reset_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_user ON public.password_reset_tokens USING btree (user_id);


--
-- Name: idx_practice_responses_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_practice_responses_session ON public.practice_responses USING btree (practice_session_id);


--
-- Name: idx_practice_responses_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_practice_responses_status ON public.practice_responses USING btree (practice_session_id, status);


--
-- Name: idx_practice_sessions_student; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_practice_sessions_student ON public.practice_sessions USING btree (student_public_id);


--
-- Name: idx_practice_sessions_student_mock_test; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_practice_sessions_student_mock_test ON public.practice_sessions USING btree (student_public_id, mock_test_id, status);


--
-- Name: idx_practice_sessions_tenant_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_practice_sessions_tenant_status ON public.practice_sessions USING btree (tenant_id, status);


--
-- Name: idx_practice_student_profiles_student; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_practice_student_profiles_student ON public.practice_student_profiles USING btree (student_public_id) WHERE (deleted = false);


--
-- Name: idx_programs_organization; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_programs_organization ON public.programs USING btree (organization_id);


--
-- Name: idx_question_types_active_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_question_types_active_order ON public.question_types USING btree (active, display_order);


--
-- Name: idx_questions_cefr_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_questions_cefr_level ON public.questions USING btree (task_type_key, cefr_level);


--
-- Name: idx_questions_task_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_questions_task_type ON public.questions USING btree (pte_task_type);


--
-- Name: idx_questions_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_questions_tenant ON public.questions USING btree (tenant_id);


--
-- Name: idx_refresh_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_user ON public.refresh_tokens USING btree (user_id);


--
-- Name: idx_rubric_activation_audits_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rubric_activation_audits_version ON public.scoring_rubric_activation_audits USING btree (version_public_id);


--
-- Name: idx_sessions_subscription; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_subscription ON public.exam_sessions USING btree (subscription_id);


--
-- Name: idx_sessions_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_tenant ON public.exam_sessions USING btree (tenant_id);


--
-- Name: idx_subscriptions_tenant_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_tenant_status ON public.subscriptions USING btree (tenant_id, status);


--
-- Name: idx_support_ticket_note_ticket_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_ticket_note_ticket_created ON public.support_ticket_note USING btree (ticket_id, created_at);


--
-- Name: idx_support_ticket_tenant_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_ticket_tenant_status_created ON public.support_ticket USING btree (tenant_id, status, created_at);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: ix_ai_prompt_versions_key_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ai_prompt_versions_key_status ON public.ai_prompt_versions USING btree (kind, prompt_key, status);


--
-- Name: ix_qgen_jobs_requester_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_qgen_jobs_requester_created ON public.question_generation_jobs USING btree (requested_by_user_public_id, created_at DESC);


--
-- Name: ix_qgen_jobs_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_qgen_jobs_status_created ON public.question_generation_jobs USING btree (status, created_at);


--
-- Name: ix_questions_task_type_content_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_questions_task_type_content_hash ON public.questions USING btree (task_type_key, content_hash);


--
-- Name: uk_ai_prompt_versions_one_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_ai_prompt_versions_one_active ON public.ai_prompt_versions USING btree (kind, prompt_key) WHERE (((status)::text = 'ACTIVE'::text) AND (deleted = false));


--
-- Name: uk_ai_prompt_versions_one_open; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_ai_prompt_versions_one_open ON public.ai_prompt_versions USING btree (kind, prompt_key) WHERE (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'PENDING'::character varying])::text[])) AND (deleted = false));


--
-- Name: uk_practice_sessions_active_mock_test; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_practice_sessions_active_mock_test ON public.practice_sessions USING btree (student_public_id, mock_test_id) WHERE ((mock_test_id IS NOT NULL) AND (deleted = false) AND ((status)::text = ANY ((ARRAY['OVERVIEW'::character varying, 'IN_PROGRESS'::character varying])::text[])));


--
-- Name: uk_qgen_jobs_one_active_per_requester; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_qgen_jobs_one_active_per_requester ON public.question_generation_jobs USING btree (requested_by_user_public_id) WHERE ((status)::text = ANY ((ARRAY['QUEUED'::character varying, 'RUNNING'::character varying, 'CANCELLING'::character varying])::text[]));


--
-- Name: uk_questions_generation_slot; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_questions_generation_slot ON public.questions USING btree (generation_job_public_id, generation_item_index) WHERE (generation_job_public_id IS NOT NULL);


--
-- Name: uq_exam_definition_items_task_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_exam_definition_items_task_key ON public.exam_definition_items USING btree (exam_definition_id, task_type_key);


--
-- Name: uq_examiner_score_receipt; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_examiner_score_receipt ON public.answer_evaluations USING btree (tenant_id, examiner_public_id, request_public_id) WHERE (request_public_id IS NOT NULL);


--
-- Name: uq_notification_logs_dedupe_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_notification_logs_dedupe_key ON public.notification_logs USING btree (dedupe_key) WHERE (dedupe_key IS NOT NULL);


--
-- Name: uq_notification_recipient_streams_recipient; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_notification_recipient_streams_recipient ON public.notification_recipient_streams USING btree (recipient_user_public_id);


--
-- Name: uq_notifications_event_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_notifications_event_key ON public.notifications USING btree (event_key);


--
-- Name: uq_org_code_live; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_org_code_live ON public.organizations USING btree (code) WHERE ((status)::text <> 'REJECTED'::text);


--
-- Name: uq_org_name_live; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_org_name_live ON public.organizations USING btree (name) WHERE ((status)::text <> 'REJECTED'::text);


--
-- Name: uq_org_tax_code_approved; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_org_tax_code_approved ON public.organizations USING btree (tax_code) WHERE ((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('SUSPENDED'::character varying)::text]));


--
-- Name: uq_questions_active_revision_per_source; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_questions_active_revision_per_source ON public.questions USING btree (supersedes_public_id) WHERE (((status)::text = ANY (ARRAY[('DRAFT'::character varying)::text, ('PENDING_APPROVAL'::character varying)::text])) AND (deleted = false));


--
-- Name: uq_questions_current_revision_group; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_questions_current_revision_group ON public.questions USING btree (revision_group_public_id) WHERE ((is_current = true) AND (deleted = false));


--
-- Name: ux_exam_definitions_single_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_exam_definitions_single_active ON public.exam_definitions USING btree (status) WHERE (((status)::text = 'ACTIVE'::text) AND (tenant_id IS NULL));


--
-- Name: ux_orders_pending_tenant_plan; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_orders_pending_tenant_plan ON public.orders USING btree (tenant_id, plan_id) WHERE (((status)::text = 'PENDING'::text) AND (deleted = false));


--
-- Name: ux_scoring_rubric_versions_single_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_scoring_rubric_versions_single_active ON public.scoring_rubric_versions USING btree (status) WHERE ((status)::text = 'ACTIVE'::text);


--
-- Name: questions question_publication_history; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER question_publication_history BEFORE INSERT OR UPDATE ON public.questions FOR EACH ROW EXECUTE FUNCTION public.retain_question_publication_history();


--
-- Name: questions trg_questions_pool_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_questions_pool_immutable BEFORE UPDATE OF pool ON public.questions FOR EACH ROW EXECUTE FUNCTION public.questions_pool_immutable();


--
-- Name: scoring_rubric_activation_audits trg_scoring_rubric_activation_audits_no_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_scoring_rubric_activation_audits_no_truncate BEFORE TRUNCATE ON public.scoring_rubric_activation_audits FOR EACH STATEMENT EXECUTE FUNCTION public.scoring_rubric_activation_audits_insert_only();


--
-- Name: scoring_rubric_activation_audits trg_scoring_rubric_activation_audits_no_update_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_scoring_rubric_activation_audits_no_update_delete BEFORE DELETE OR UPDATE ON public.scoring_rubric_activation_audits FOR EACH ROW EXECUTE FUNCTION public.scoring_rubric_activation_audits_insert_only();


--
-- Name: scoring_rubric_versions trg_scoring_rubric_versions_guard_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_scoring_rubric_versions_guard_delete BEFORE DELETE ON public.scoring_rubric_versions FOR EACH ROW EXECUTE FUNCTION public.scoring_rubric_versions_guard_delete();


--
-- Name: scoring_rubric_versions trg_scoring_rubric_versions_guard_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_scoring_rubric_versions_guard_update BEFORE UPDATE ON public.scoring_rubric_versions FOR EACH ROW EXECUTE FUNCTION public.scoring_rubric_versions_guard_update();


--
-- Name: exam_definition_cefr_targets exam_definition_cefr_targets_exam_definition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_definition_cefr_targets
    ADD CONSTRAINT exam_definition_cefr_targets_exam_definition_id_fkey FOREIGN KEY (exam_definition_id) REFERENCES public.exam_definitions(id);


--
-- Name: exam_session_cefr_targets exam_session_cefr_targets_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_cefr_targets
    ADD CONSTRAINT exam_session_cefr_targets_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.exam_sessions(id);


--
-- Name: order_payments fk3s9vxneb3dk3plhpv9s213so0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_payments
    ADD CONSTRAINT fk3s9vxneb3dk3plhpv9s213so0 FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: organization_members fk67edx4b35ogkpk3ghbhwand9i; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT fk67edx4b35ogkpk3ghbhwand9i FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: programs fk6wv6vmoflbi93uqx2qunpb4m9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT fk6wv6vmoflbi93uqx2qunpb4m9 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: scoring_rubric_activation_audits fk_rubric_activation_audits_previous; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scoring_rubric_activation_audits
    ADD CONSTRAINT fk_rubric_activation_audits_previous FOREIGN KEY (previous_active_public_id) REFERENCES public.scoring_rubric_versions(public_id);


--
-- Name: scoring_rubric_activation_audits fk_rubric_activation_audits_version; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scoring_rubric_activation_audits
    ADD CONSTRAINT fk_rubric_activation_audits_version FOREIGN KEY (version_public_id) REFERENCES public.scoring_rubric_versions(public_id);


--
-- Name: organization_quota_grants fkawjewse05evwostvbjxxmligi; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_quota_grants
    ADD CONSTRAINT fkawjewse05evwostvbjxxmligi FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: exam_session_proctors fkb134yfa0nk00r7wm14xxclsg2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_proctors
    ADD CONSTRAINT fkb134yfa0nk00r7wm14xxclsg2 FOREIGN KEY (session_id) REFERENCES public.exam_sessions(id);


--
-- Name: organization_member_roles fkcjj06io8x3suddrd34lkd6luc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_member_roles
    ADD CONSTRAINT fkcjj06io8x3suddrd34lkd6luc FOREIGN KEY (member_id) REFERENCES public.organization_members(id);


--
-- Name: exam_registrations fkfmv9g64s3dtm5yksy6vvfsvvy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_registrations
    ADD CONSTRAINT fkfmv9g64s3dtm5yksy6vvfsvvy FOREIGN KEY (session_id) REFERENCES public.exam_sessions(id);


--
-- Name: user_roles fkhfh9dx7w3ubf1co1vdev94g3f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fkhfh9dx7w3ubf1co1vdev94g3f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: class_students fkjuh9br5vimkw71ko8qyswp3ci; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_students
    ADD CONSTRAINT fkjuh9br5vimkw71ko8qyswp3ci FOREIGN KEY (class_id) REFERENCES public.classes(id);


--
-- Name: exam_session_selected_skills fklhn096g6hrhumxyrtgv5b8yfh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_selected_skills
    ADD CONSTRAINT fklhn096g6hrhumxyrtgv5b8yfh FOREIGN KEY (session_id) REFERENCES public.exam_sessions(id);


--
-- Name: attempt_answers fko5l8lds50jeasb0ko4m15bsti; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attempt_answers
    ADD CONSTRAINT fko5l8lds50jeasb0ko4m15bsti FOREIGN KEY (attempt_id) REFERENCES public.exam_attempts(id);


--
-- Name: exam_session_audience_sources fkptdjmdo6lydcqcvadpc9w726f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_session_audience_sources
    ADD CONSTRAINT fkptdjmdo6lydcqcvadpc9w726f FOREIGN KEY (session_id) REFERENCES public.exam_sessions(id);


--
-- Name: exam_definition_items fkrj8coylmqvd31rt93wwqiax4h; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_definition_items
    ADD CONSTRAINT fkrj8coylmqvd31rt93wwqiax4h FOREIGN KEY (exam_definition_id) REFERENCES public.exam_definitions(id);


--
-- Name: question_options fksb9v00wdrgc9qojtjkv7e1gkp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_options
    ADD CONSTRAINT fksb9v00wdrgc9qojtjkv7e1gkp FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: exam_version_items fkt0m693b16aso2pcpx6mbeaj5g; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_version_items
    ADD CONSTRAINT fkt0m693b16aso2pcpx6mbeaj5g FOREIGN KEY (exam_version_id) REFERENCES public.exam_versions(id);


--
-- Name: blueprint_items fktg26265cv4om59xe0mtxnd61x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blueprint_items
    ADD CONSTRAINT fktg26265cv4om59xe0mtxnd61x FOREIGN KEY (blueprint_id) REFERENCES public.exam_blueprints(id);


--
-- Name: classes fkthmk4awc7ft3lg8ud2behicfs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT fkthmk4awc7ft3lg8ud2behicfs FOREIGN KEY (program_id) REFERENCES public.programs(id);


--
-- Name: notification_inbox_snapshots notification_inbox_snapshots_recipient_user_public_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_inbox_snapshots
    ADD CONSTRAINT notification_inbox_snapshots_recipient_user_public_id_fkey FOREIGN KEY (recipient_user_public_id) REFERENCES public.users(public_id);


--
-- Name: password_reset_tokens password_reset_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: practice_mock_test_items practice_mock_test_items_mock_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_mock_test_items
    ADD CONSTRAINT practice_mock_test_items_mock_test_id_fkey FOREIGN KEY (mock_test_id) REFERENCES public.practice_mock_tests(id);


--
-- Name: practice_sessions practice_sessions_mock_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.practice_sessions
    ADD CONSTRAINT practice_sessions_mock_test_id_fkey FOREIGN KEY (mock_test_id) REFERENCES public.practice_mock_tests(id);


--
-- Name: question_generation_job_items question_generation_job_items_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_generation_job_items
    ADD CONSTRAINT question_generation_job_items_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.question_generation_jobs(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

