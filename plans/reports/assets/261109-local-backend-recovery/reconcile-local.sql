BEGIN;

SET LOCAL lock_timeout='5s';

SELECT pg_advisory_xact_lock(hashtext('pte-local-backend-recovery'));

CREATE SCHEMA local_recovery_261109;

CREATE INDEX idx_exam_definitions_tenant ON public.exam_definitions USING btree (tenant_id) WHERE (tenant_id IS NOT NULL);

CREATE INDEX ix_ai_prompt_versions_key_status ON public.ai_prompt_versions USING btree (kind, prompt_key, status);

CREATE UNIQUE INDEX uk_ai_prompt_versions_one_active ON public.ai_prompt_versions USING btree (kind, prompt_key) WHERE (((status)::text = 'ACTIVE'::text) AND (deleted = false));

CREATE UNIQUE INDEX uk_ai_prompt_versions_one_open ON public.ai_prompt_versions USING btree (kind, prompt_key) WHERE (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'PENDING'::character varying])::text[])) AND (deleted = false));

DROP INDEX public.ux_exam_definitions_single_active;

CREATE UNIQUE INDEX ux_exam_definitions_single_active ON public.exam_definitions USING btree (status) WHERE (((status)::text = 'ACTIVE'::text) AND (tenant_id IS NULL));

ALTER TABLE public.ai_prompt_versions ADD CONSTRAINT ai_prompt_versions_version_no_check CHECK ((version_no >= 1));

ALTER TABLE public.ai_prompt_versions ADD CONSTRAINT ai_prompt_versions_kind_check CHECK (((kind)::text = ANY ((ARRAY['GENERATOR'::character varying, 'REVIEWER'::character varying, 'SCORER'::character varying, 'SHARED'::character varying, 'CHATBOT'::character varying])::text[])));

ALTER TABLE ONLY public.ai_prompt_versions
    ADD CONSTRAINT uk_ai_prompt_versions_key_version UNIQUE (kind, prompt_key, version_no);

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);

ALTER TABLE public.notification_logs DROP CONSTRAINT notification_logs_notification_type_check;

ALTER TABLE public.notification_logs ADD CONSTRAINT notification_logs_notification_type_check CHECK (((notification_type)::text = ANY ((ARRAY['STUDENT_ENROLLED'::character varying, 'ATTEMPT_PUBLISHED'::character varying, 'VIOLATION_DETECTED'::character varying, 'SESSION_CANCELLED'::character varying, 'STUDENT_ENROLLMENT_CONFLICT'::character varying, 'TENANT_APPLICATION_SUBMITTED'::character varying, 'TENANT_APPLICATION_APPROVED'::character varying, 'TENANT_APPLICATION_REJECTED'::character varying, 'USER_CREDENTIALS_SENT'::character varying, 'PRACTICE_EMAIL_CHALLENGE'::character varying, 'PASSWORD_RESET_LINK_SENT'::character varying])::text[])));

ALTER TABLE public.ai_prompt_versions ALTER COLUMN deleted SET DEFAULT false, ALTER COLUMN lock_version SET DEFAULT 0;

COMMENT ON COLUMN public.ai_prompt_versions.content IS 'PromptContent JSON: title, intro blocks, sections of blocks (TEXT, LIST, CODE, LEVELS)';

COMMENT ON COLUMN public.ai_prompt_versions.content_hash IS 'SHA-256 of the canonical content JSON; a prompt test is valid only for the hash it ran on';

INSERT INTO chat_usage_daily (usage_date, model, messages, ok, refused, failed, tokens_in, tokens_out,
                              tokens_thinking, cost_usd)
SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date,
       coalesce(model, 'unknown'),
       count(*),
       count(*) FILTER (WHERE status = 'OK'),
       count(*) FILTER (WHERE status = 'REFUSED'),
       count(*) FILTER (WHERE status = 'FAILED'),
       coalesce(sum(tokens_in), 0),
       coalesce(sum(tokens_out), 0),
       coalesce(sum(tokens_thinking), 0),
       round((coalesce(sum(tokens_in), 0) * 0.10
              + (coalesce(sum(tokens_out), 0) + coalesce(sum(tokens_thinking), 0)) * 0.40) / 1000000, 6)
FROM chat_message
WHERE deleted = false
GROUP BY 1, 2;



UPDATE chat_usage_daily SET failed_other=failed WHERE usage_date IN (SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date FROM chat_message) AND failed_timeout+failed_rate_limited+failed_auth+failed_unavailable+failed_truncated+failed_other=0;

ALTER TABLE public.chat_message SET SCHEMA local_recovery_261109;

ALTER TABLE public.chat_session SET SCHEMA local_recovery_261109;

ALTER TABLE public.chat_consent SET SCHEMA local_recovery_261109;

ALTER TABLE public.chat_answer_cache SET SCHEMA local_recovery_261109;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'16','examiner reassignment carry over','SQL','V16__examiner_reassignment_carry_over.sql',-1163605956,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'17','host exam templates','SQL','V17__host_exam_templates.sql',1402792873,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'18','attempt student status index','SQL','V18__attempt_student_status_index.sql',-2142295429,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'19','password reset tokens','SQL','V19__password_reset_tokens.sql',-316124540,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'20','chat usage daily and drop chat content','SQL','V20__chat_usage_daily_and_drop_chat_content.sql',-877743313,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'21','chat usage daily failure reasons','SQL','V21__chat_usage_daily_failure_reasons.sql',1503872037,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'22','drop question title','SQL','V22__drop_question_title.sql',-1950919819,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'23','drop question visibility','SQL','V23__drop_question_visibility.sql',1355969961,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'24','correct standard exam template','SQL','V24__correct_standard_exam_template.sql',1183509148,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'25','exam time frame','SQL','V25__exam_time_frame.sql',570615532,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'26','task type stimulus','SQL','V26__task_type_stimulus.sql',1983978287,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'27','exam assembly report','SQL','V27__exam_assembly_report.sql',-898218507,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'28','question cefr level','SQL','V28__question_cefr_level.sql',1059838932,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'29','exam definition cefr targets','SQL','V29__exam_definition_cefr_targets.sql',-576166679,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'30','exam session cefr targets','SQL','V30__exam_session_cefr_targets.sql',991142062,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'31','exam session avoid repeats','SQL','V31__exam_session_avoid_repeats.sql',780488525,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'32','scoring rubric versions','SQL','V32__scoring_rubric_versions.sql',1138932395,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'33','examiner trait scores','SQL','V33__examiner_trait_scores.sql',508304171,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'34','question generation jobs','SQL','V34__question_generation_jobs.sql',1570967830,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'35','rubric activation reason','SQL','V35__rubric_activation_reason.sql',1092634631,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'36','ai prompt versions','SQL','V36__ai_prompt_versions.sql',-252379103,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'37','ai prompt version tests','SQL','V37__ai_prompt_version_tests.sql',42437324,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'38','ai prompt kind chatbot','SQL','V38__ai_prompt_kind_chatbot.sql',1042493017,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'39','generation usage daily','SQL','V39__generation_usage_daily.sql',714790812,current_user,0,true FROM flyway_schema_history;

INSERT INTO flyway_schema_history(installed_rank,version,description,type,script,checksum,installed_by,execution_time,success) SELECT coalesce(max(installed_rank),0)+1,'40','generation preview jobs','SQL','V40__generation_preview_jobs.sql',1940452287,current_user,0,true FROM flyway_schema_history;

COMMIT;