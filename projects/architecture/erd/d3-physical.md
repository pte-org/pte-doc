# D3 – Physical schema

> Sinh bởi `gen_erd.py` từ `V1__baseline.sql`. Không sửa tay. Generator hiện chỉ đọc V1, chưa áp dụng migration V2+.

Tổng: 52 bảng. Kiểu cột ghi nguyên văn PostgreSQL. `PK` / `FK` / `UK` lấy từ constraint.

## Mục lục

- **tenancy, identity, enrollment**: [`organizations`](#organizations), [`organization_quota_grants`](#organization_quota_grants), [`users`](#users), [`user_roles`](#user_roles), [`organization_members`](#organization_members), [`organization_member_roles`](#organization_member_roles), [`refresh_tokens`](#refresh_tokens), [`programs`](#programs), [`classes`](#classes), [`class_students`](#class_students), [`class_lecturers`](#class_lecturers)
- **itembank, assessment, media**: [`question_types`](#question_types), [`questions`](#questions), [`question_options`](#question_options), [`exam_blueprints`](#exam_blueprints), [`blueprint_items`](#blueprint_items), [`exam_definitions`](#exam_definitions), [`exam_definition_items`](#exam_definition_items), [`exam_versions`](#exam_versions), [`exam_version_items`](#exam_version_items), [`media_objects`](#media_objects)
- **session, attempt, proctoring**: [`exam_sessions`](#exam_sessions), [`exam_session_selected_skills`](#exam_session_selected_skills), [`exam_session_audience_sources`](#exam_session_audience_sources), [`exam_session_proctors`](#exam_session_proctors), [`exam_registrations`](#exam_registrations), [`exam_attempts`](#exam_attempts), [`attempt_answers`](#attempt_answers), [`exam_incidents`](#exam_incidents)
- **scoring, reporting**: [`answer_evaluations`](#answer_evaluations), [`grading_assignments`](#grading_assignments), [`grading_issues`](#grading_issues), [`exam_results`](#exam_results)
- **practice**: [`practice_sessions`](#practice_sessions), [`practice_responses`](#practice_responses), [`otp_challenges`](#otp_challenges)
- **billing**: [`service_plans`](#service_plans), [`orders`](#orders), [`order_payments`](#order_payments), [`subscriptions`](#subscriptions), [`license_codes`](#license_codes), [`platform_settings`](#platform_settings)
- **notification, support, shared**: [`notifications`](#notifications), [`notification_recipients`](#notification_recipients), [`notification_recipient_streams`](#notification_recipient_streams), [`notification_inbox_snapshots`](#notification_inbox_snapshots), [`notification_announcements`](#notification_announcements), [`notification_logs`](#notification_logs), [`support_ticket`](#support_ticket), [`support_ticket_note`](#support_ticket_note), [`audit_logs`](#audit_logs), [`idempotency_keys`](#idempotency_keys)

## tenancy, identity, enrollment

### organizations

[V1 dòng 1067](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1067)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `address` | character varying(255) | có |  |
| `code` | character varying(255) |  |  |
| `contact_email` | character varying(255) | có |  |
| `contact_phone` | character varying(255) | có |  |
| `facility_type` | character varying(255) |  | CHECK: MAIN, BRANCH, TEST_CENTER |
| `logo_url` | character varying(255) | có |  |
| `name` | character varying(255) |  |  |
| `organization_type` | character varying(255) |  |  |
| `package_name` | character varying(255) |  |  |
| `primary_color` | character varying(255) | có |  |
| `province_code` | character varying(16) | có |  |
| `province_name` | character varying(255) | có |  |
| `reject_reason` | character varying(500) | có |  |
| `reviewed_at` | timestamp(6) with time zone | có |  |
| `reviewed_by` | uuid | có | ref → `users` (logic) |
| `status` | character varying(255) |  | CHECK: PENDING, ACTIVE, REJECTED, SUSPENDED |
| `student_limit` | integer |  |  |
| `suspended_until` | timestamp(6) with time zone | có |  |
| `tax_code` | character varying(64) | có |  |
| `version` | bigint | có |  |
| `ward_code` | character varying(16) | có |  |
| `ward_name` | character varying(255) | có |  |

Index: `idx_organizations_status` (status); `uq_org_code_live` (unique) (code) WHERE ((status)::text <> 'REJECTED'::text); `uq_org_name_live` (unique) (name) WHERE ((status)::text <> 'REJECTED'::text); `uq_org_tax_code_approved` (unique) (tax_code) WHERE ((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'SUSPENDED'::character varying])::text[]))

### organization_quota_grants

[V1 dòng 1056](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1056)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `organization_id` | bigint |  | PK; FK → `organizations` |
| `actor_user_id` | uuid |  | ref → `users` (logic) |
| `amount` | integer |  |  |
| `created_at` | timestamp(6) with time zone |  |  |
| `note` | character varying(255) | có |  |
| `package_name` | character varying(255) |  |  |
| `public_id` | uuid |  |  |
| `position` | integer |  | PK |

### users

[V1 dòng 722](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L722)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `class_name` | character varying(255) | có |  |
| `credential_hash` | character varying(255) | có |  |
| `date_of_birth` | date | có |  |
| `email` | character varying(255) | có |  |
| `full_name` | character varying(255) | có |  |
| `must_change_password` | boolean |  |  |
| `phone` | character varying(255) | có |  |
| `status` | character varying(255) |  | CHECK: ACTIVE, SUSPENDED |
| `student_code` | character varying(255) | có |  |
| `username` | character varying(255) |  | UK |

Index: `idx_users_email` (email)

### user_roles

[V1 dòng 1513](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1513)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `user_id` | bigint |  | PK; FK → `users` |
| `role` | character varying(255) |  | PK; CHECK: PLATFORM_ADMIN, PLATFORM_MANAGER, ACADEMIC_MANAGER, ACADEMIC_STAFF, PLATFORM_AUTHOR, HOST_ADMIN, PROCTOR, EXAMINER, STUDENT |

### organization_members

[V1 dòng 710](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L710)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `organization_id` | uuid |  | ref → `organizations` (logic) |
| `status` | character varying(255) |  | CHECK: ACTIVE, SUSPENDED |
| `user_id` | bigint |  | FK → `users` |

Unique nhiều cột: (user_id, organization_id)

Index: `idx_organization_members_org` (organization_id)

### organization_member_roles

[V1 dòng 750](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L750)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `member_id` | bigint |  | PK; FK → `organization_members` |
| `role` | character varying(255) |  | PK; CHECK: PLATFORM_ADMIN, PLATFORM_MANAGER, ACADEMIC_MANAGER, ACADEMIC_STAFF, PLATFORM_AUTHOR, HOST_ADMIN, PROCTOR, EXAMINER, STUDENT |

### refresh_tokens

[V1 dòng 1386](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1386)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `expires_at` | timestamp(6) with time zone |  |  |
| `organization_id` | uuid | có | ref → `organizations` (logic) |
| `revoked` | boolean |  |  |
| `token_hash` | character varying(255) |  | UK |
| `user_id` | bigint |  | ref → `users` (logic) |

Index: `idx_refresh_user` (user_id)

### programs

[V1 dòng 1252](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1252)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `description` | character varying(255) | có |  |
| `end_date` | date | có |  |
| `name` | character varying(255) |  |  |
| `start_date` | date | có |  |
| `status` | character varying(255) |  | CHECK: ACTIVE, INACTIVE, SUSPENDED |
| `organization_id` | bigint |  | FK → `organizations` |

Index: `idx_programs_organization` (organization_id)

### classes

[V1 dòng 187](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L187)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `name` | character varying(255) |  |  |
| `organization_id` | uuid |  | ref → `organizations` (logic) |
| `status` | character varying(255) |  | CHECK: ACTIVE, INACTIVE, SUSPENDED |
| `program_id` | bigint |  | FK → `programs` |

Index: `idx_classes_organization` (organization_id); `idx_classes_program` (program_id)

### class_students

[V1 dòng 167](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L167)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `organization_id` | uuid |  | ref → `organizations` (logic) |
| `student_public_id` | uuid |  | ref → `users` (logic); UK |
| `class_id` | bigint |  | FK → `classes` |

Index: `idx_class_students_class` (class_id)

### class_lecturers

[V1 dòng 147](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L147)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `assignee_public_id` | uuid |  | ref → `users` (logic) |
| `organization_id` | uuid |  | ref → `organizations` (logic) |
| `class_id` | bigint |  | FK → `classes` |

Unique nhiều cột: (class_id, assignee_public_id)

Index: `idx_class_lecturers_class` (class_id)

## itembank, assessment, media

### question_types

[V1 dòng 1286](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1286)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `active` | boolean |  |  |
| `author_user_public_id` | uuid | có | ref → `users` (logic) |
| `authoring_contract_key` | character varying(96) | có |  |
| `authoring_contract_version` | integer | có |  |
| `code` | character varying(64) |  | UK |
| `display_name` | character varying(128) |  |  |
| `display_order` | integer |  |  |
| `first_published_at` | timestamp(6) with time zone | có |  |
| `lifecycle_status` | character varying(16) |  |  |
| `normalized_display_name` | character varying(128) |  | UK |
| `requires_audio_prompt` | boolean |  |  |
| `requires_correct_answer` | boolean |  |  |
| `requires_image_prompt` | boolean |  |  |
| `requires_options` | boolean |  |  |
| `requires_prompt_text` | boolean |  |  |
| `requires_reference_answer` | boolean |  |  |
| `requires_single_correct_option` | boolean |  |  |
| `requires_word_count` | boolean |  |  |
| `runtime_answer_schema_version` | integer | có |  |
| `runtime_behavior_key` | character varying(64) | có |  |
| `runtime_locked_at` | timestamp(6) with time zone | có |  |
| `runtime_min_app_version` | character varying(32) | có |  |
| `runtime_profile_key` | character varying(96) | có |  |
| `runtime_profile_version` | integer | có |  |
| `runtime_renderer_key` | character varying(96) | có |  |
| `runtime_required_capabilities` | text[] |  |  |
| `runtime_scoring_mode` | character varying(16) | có |  |
| `runtime_scoring_profile_key` | character varying(64) | có |  |
| `runtime_scoring_profile_version` | integer | có |  |
| `scored` | boolean |  |  |
| `screen_key` | character varying(96) | có |  |
| `section` | character varying(16) |  | CHECK: LISTENING, SPEAKING, READING, WRITING |
| `short_name` | character varying(32) |  |  |
| `task_type_key` | character varying(64) |  | UK |
| `uses_option_order_as_correct_position` | boolean |  |  |

Index: `idx_question_types_active_order` (active, display_order)

### questions

[V1 dòng 1339](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1339)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `audio_prompt_ref` | uuid | có |  |
| `author_user_public_id` | uuid | có | ref → `users` (logic) |
| `availability_flags_explicit` | boolean |  |  |
| `available_for_exam` | boolean |  |  |
| `available_for_practice` | boolean |  |  |
| `correct_answer_text` | text | có |  |
| `is_current` | boolean |  |  |
| `ever_published` | boolean | có |  |
| `image_prompt_ref` | uuid | có |  |
| `max_word_count` | integer | có |  |
| `min_word_count` | integer | có |  |
| `pool` | character varying(16) |  | CHECK: EXAM, PRACTICE |
| `prompt_text` | text | có |  |
| `pte_task_type` | character varying(255) | có | CHECK: PERSONAL_INTRODUCTION, READ_ALOUD, REPEAT_SENTENCE, DESCRIBE_IMAGE, RE_TELL_LECTURE, ANSWER_SHORT_QUESTION, RESPOND_TO_A_SITUATION, SUMMARIZE_GROUP_DISCUSSION, SUMMARIZE_WRITTEN_TEXT, WRITE_ESSAY, MC_READING_SINGLE, MC_READING_MULTIPLE, RE_ORDER_PARAGRAPHS, FILL_IN_THE_BLANKS_DRAG_AND_DROP, FILL_IN_THE_BLANKS_DROPDOWN, SUMMARIZE_SPOKEN_TEXT, MC_LISTENING_SINGLE, MC_LISTENING_MULTIPLE, FILL_IN_THE_BLANKS_TYPE_IN, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD, HIGHLIGHT_INCORRECT_WORDS, WRITE_FROM_DICTATION |
| `reference_answer_text` | text | có |  |
| `rejection_reason` | character varying(500) | có |  |
| `revision_group_public_id` | uuid |  |  |
| `revision_number` | integer |  |  |
| `status` | character varying(255) |  | CHECK: DRAFT, PENDING_APPROVAL, APPROVED, ARCHIVED |
| `supersedes_public_id` | uuid | có | ref → `questions` (logic) |
| `task_type_key` | character varying(64) |  |  |
| `task_type_section` | character varying(16) |  |  |
| `tenant_id` | uuid | có | ref → `organizations` (logic) |
| `title` | character varying(255) |  |  |
| `version` | bigint |  |  |
| `visibility` | character varying(255) |  |  |

CHECK khác: `CONSTRAINT questions_visibility_check CHECK (((visibility)::text = 'SHARED'::text))`

Index: `idx_questions_task_type` (pte_task_type); `idx_questions_tenant` (tenant_id); `idx_questions_visibility` (visibility); `uq_questions_active_revision_per_source` (unique) (supersedes_public_id) WHERE (((status)::text = ANY (ARRAY[('DRAFT'::character varying)::text, ('PENDING_APPROVAL'::character varying)::text])) AND (deleted = false)); `uq_questions_current_revision_group` (unique) (revision_group_public_id) WHERE ((is_current = true) AND (deleted = false))

### question_options

[V1 dòng 1276](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1276)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `question_id` | bigint |  | FK → `questions` |
| `blank_index` | integer | có |  |
| `correct` | boolean |  |  |
| `correct_gap_index` | integer | có |  |
| `order_index` | integer |  |  |
| `public_id` | uuid |  |  |
| `text` | text |  |  |

Index: `idx_options_question` (question_id)

### exam_blueprints

[V1 dòng 258](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L258)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `author_user_public_id` | uuid | có | ref → `users` (logic) |
| `name` | character varying(255) |  |  |
| `rejection_reason` | character varying(255) | có |  |
| `status` | character varying(255) |  | CHECK: DRAFT, PENDING_APPROVAL, PUBLISHED |
| `tenant_id` | uuid | có | ref → `organizations` (logic) |
| `version` | bigint |  |  |

Index: `idx_blueprints_tenant` (tenant_id)

### blueprint_items

[V1 dòng 139](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L139)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `blueprint_id` | bigint |  | FK → `exam_blueprints` |
| `order_index` | integer |  |  |
| `question_public_id` | uuid |  | ref → `questions` (logic) |
| `section` | character varying(255) |  | CHECK: LISTENING, SPEAKING, READING, WRITING |

### exam_definitions

[V1 dòng 316](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L316)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `author_user_public_id` | uuid | có | ref → `users` (logic) |
| `code` | character varying(255) |  |  |
| `lock_version` | bigint |  |  |
| `name` | character varying(255) |  |  |
| `rejection_reason` | character varying(1000) | có |  |
| `status` | character varying(255) |  | CHECK: DRAFT, PENDING_APPROVAL, ACTIVE, RETIRED |
| `template_policy` | character varying(16) |  | CHECK: STANDARD_PTE, CUSTOM |
| `version` | integer |  |  |

Index: `idx_exam_definitions_code` (code); `ux_exam_definitions_single_active` (unique) (status) WHERE ((status)::text = 'ACTIVE'::text)

### exam_definition_items

[V1 dòng 282](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L282)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `exam_definition_id` | bigint |  | FK → `exam_definitions` |
| `listening_weight` | numeric(5,2) |  |  |
| `max_count` | integer |  |  |
| `min_count` | integer |  |  |
| `overall_weight` | numeric(5,2) |  |  |
| `prep_seconds` | integer |  |  |
| `reading_weight` | numeric(5,2) |  |  |
| `response_seconds` | integer |  |  |
| `runtime_answer_schema_version` | integer | có |  |
| `runtime_authoring_contract_key` | character varying(96) | có |  |
| `runtime_authoring_contract_version` | integer | có |  |
| `runtime_behavior_key` | character varying(64) | có |  |
| `runtime_contract_version` | integer | có |  |
| `runtime_min_app_version` | character varying(32) | có |  |
| `runtime_profile_key` | character varying(96) | có |  |
| `runtime_profile_status` | character varying(16) | có |  |
| `runtime_profile_version` | integer | có |  |
| `runtime_renderer_key` | character varying(96) | có |  |
| `runtime_required_client_capabilities` | character varying(512) | có |  |
| `runtime_scoring_mode` | character varying(16) | có |  |
| `runtime_scoring_profile_key` | character varying(64) | có |  |
| `runtime_scoring_profile_version` | integer | có |  |
| `runtime_screen_key` | character varying(96) | có |  |
| `scoring_method` | character varying(255) |  | CHECK: AI_SPEECH, AI_TEXT, OBJECTIVE, UNSCORED |
| `section` | character varying(255) |  |  |
| `sequence` | integer |  |  |
| `speaking_weight` | numeric(5,2) |  |  |
| `task_type` | character varying(255) | có |  |
| `task_type_key` | character varying(64) |  |  |
| `writing_weight` | numeric(5,2) |  |  |

### exam_versions

[V1 dòng 600](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L600)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `exam_definition_public_id` | uuid |  | ref → `exam_definitions` (logic) |
| `exam_definition_version` | integer |  |  |
| `generation_algorithm_version` | character varying(32) | có |  |
| `generation_seed` | bigint | có |  |
| `name` | character varying(255) |  |  |
| `pool_policy_fingerprint` | character varying(128) | có |  |
| `source_blueprint_public_id` | uuid |  | ref → `exam_blueprints` (logic) |
| `tenant_id` | uuid | có | ref → `organizations` (logic) |
| `version` | integer |  |  |

Index: `idx_exam_versions_tenant` (tenant_id)

### exam_version_items

[V1 dòng 558](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L558)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `exam_version_id` | bigint |  | FK → `exam_versions` |
| `audio_prompt_ref` | uuid | có |  |
| `correct_answer_text` | text | có |  |
| `image_prompt_ref` | uuid | có |  |
| `max_word_count` | integer | có |  |
| `min_word_count` | integer | có |  |
| `options_json` | text | có |  |
| `order_index` | integer |  |  |
| `prompt_text` | text | có |  |
| `pte_task_type` | character varying(255) | có | CHECK: PERSONAL_INTRODUCTION, READ_ALOUD, REPEAT_SENTENCE, DESCRIBE_IMAGE, RE_TELL_LECTURE, ANSWER_SHORT_QUESTION, RESPOND_TO_A_SITUATION, SUMMARIZE_GROUP_DISCUSSION, SUMMARIZE_WRITTEN_TEXT, WRITE_ESSAY, MC_READING_SINGLE, MC_READING_MULTIPLE, RE_ORDER_PARAGRAPHS, FILL_IN_THE_BLANKS_DRAG_AND_DROP, FILL_IN_THE_BLANKS_DROPDOWN, SUMMARIZE_SPOKEN_TEXT, MC_LISTENING_SINGLE, MC_LISTENING_MULTIPLE, FILL_IN_THE_BLANKS_TYPE_IN, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD, HIGHLIGHT_INCORRECT_WORDS, WRITE_FROM_DICTATION |
| `public_id` | uuid |  |  |
| `reference_answer_text` | text | có |  |
| `runtime_answer_schema_version` | integer | có |  |
| `runtime_authoring_contract_key` | character varying(96) | có |  |
| `runtime_authoring_contract_version` | integer | có |  |
| `runtime_behavior_key` | character varying(64) | có |  |
| `runtime_contract_version` | integer | có |  |
| `runtime_mapping_status` | character varying(32) | có |  |
| `runtime_mapping_version` | character varying(32) | có |  |
| `runtime_min_supported_app_version` | character varying(32) | có |  |
| `runtime_profile_key` | character varying(96) | có |  |
| `runtime_profile_status` | character varying(16) | có |  |
| `runtime_profile_version` | integer | có |  |
| `runtime_renderer_key` | character varying(96) | có |  |
| `runtime_required_client_capabilities` | character varying(512) | có |  |
| `runtime_scoring_configuration_digest` | character varying(128) | có |  |
| `runtime_scoring_implementation_version` | character varying(96) | có |  |
| `runtime_scoring_mode` | character varying(16) | có |  |
| `runtime_scoring_profile_key` | character varying(64) | có |  |
| `runtime_scoring_profile_version` | integer | có |  |
| `runtime_screen_key` | character varying(96) | có |  |
| `section` | character varying(255) |  | CHECK: LISTENING, SPEAKING, READING, WRITING |
| `source_question_public_id` | uuid |  | ref → `questions` (logic) |
| `task_type_code` | character varying(64) | có |  |
| `task_type_display_name` | character varying(128) | có |  |
| `task_type_key` | character varying(64) |  |  |
| `title` | character varying(255) |  |  |

### media_objects

[V1 dòng 801](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L801)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `asset_id` | character varying(255) | có |  |
| `audio_prompt` | boolean | có | DEFAULT false NOT NULL |
| `cloudinary_delivery_type` | character varying(24) |  | CHECK: UPLOAD, AUTHENTICATED |
| `cloudinary_public_id` | character varying(255) | có |  |
| `cloudinary_resource_type` | character varying(255) | có |  |
| `content_type` | character varying(255) |  |  |
| `duration_seconds` | integer | có |  |
| `owner_public_id` | uuid |  | ref → `users` (logic) |
| `practice_item_public_id` | uuid | có | ref → `practice_responses` (logic) |
| `practice_session_public_id` | uuid | có | ref → `practice_sessions` (logic) |
| `purpose` | character varying(64) | có |  |
| `secure_url` | text | có |  |
| `size_bytes` | bigint | có |  |
| `status` | character varying(255) |  | CHECK: PENDING_UPLOAD, UPLOADED |
| `storage_key` | character varying(255) |  | UK |
| `tenant_id` | uuid | có | ref → `organizations` (logic) |

Index: `idx_media_objects_owner` (owner_public_id)

## session, attempt, proctoring

### exam_sessions

[V1 dòng 503](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L503)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `capacity` | integer |  |  |
| `closes_at` | timestamp(6) with time zone |  |  |
| `draft_version` | bigint |  |  |
| `exam_definition_public_id` | uuid | có | ref → `exam_definitions` (logic) |
| `exam_definition_version` | integer | có |  |
| `exam_mode` | character varying(16) | có |  |
| `exam_version_public_id` | uuid | có | ref → `exam_versions` (logic) |
| `grading_completed_at` | timestamp(6) with time zone | có |  |
| `grading_frozen_at` | timestamp(6) with time zone | có |  |
| `grading_frozen_by_public_id` | uuid | có | ref → `users` (logic) |
| `grading_marking_mode` | character varying(24) | có |  |
| `grading_preview_version` | character varying(128) | có |  |
| `grading_status` | character varying(16) | có | CHECK: FROZEN, COMPLETED |
| `license_key` | character varying(64) |  |  |
| `max_retries_per_student` | integer |  |  |
| `name` | character varying(255) |  |  |
| `opens_at` | timestamp(6) with time zone |  |  |
| `answer_integrity_level` | character varying(255) | có | CHECK: STANDARD, STRICT |
| `device_check_required` | boolean | có |  |
| `lockdown_mode` | character varying(255) | có | CHECK: NONE, STANDARD, STRICT |
| `proctor_required` | boolean | có |  |
| `replay_policy_limit` | integer | có |  |
| `replay_policy_type` | character varying(255) | có | CHECK: UNLIMITED, LIMITED |
| `publication_locked_at` | timestamp(6) with time zone | có |  |
| `publication_public_id` | uuid | có |  |
| `reuse_policy` | character varying(40) | có | CHECK: ALLOW, EXCLUDE_STARTED_IN_SERIES, EXCLUDE_ASSIGNED_IN_SERIES, BLOCK_ON_SCHEDULE_OVERLAP |
| `series_key` | character varying(128) | có |  |
| `session_code` | character varying(24) |  | UK |
| `status` | character varying(255) |  | CHECK: DRAFT, READY, SCHEDULED, OPEN, CLOSED, CANCELLED |
| `subscription_id` | uuid |  | ref → `subscriptions` (logic) |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |

Exclusion: `no_overlap_per_subscription: EXCLUDE USING gist (subscription_id WITH =, tstzrange(opens_at, closes_at) WITH &&) WHERE (((status)::text = ANY (ARRAY[('SCHEDULED'::character varying)::text, ('OPEN'::character varying)::text])))`

CHECK khác: `CONSTRAINT exam_sessions_exam_mode_check CHECK (((exam_mode)::text = 'OFFICIAL_EXAM'::text))`

Index: `idx_sessions_subscription` (subscription_id); `idx_sessions_tenant` (tenant_id)

### exam_session_selected_skills

[V1 dòng 498](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L498)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `session_id` | bigint |  | PK; FK → `exam_sessions` |
| `skill` | character varying(16) |  | PK |

### exam_session_audience_sources

[V1 dòng 453](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L453)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `created_by` | uuid | có | ref → `users` (logic) |
| `source_public_id` | uuid |  |  |
| `source_type` | character varying(16) |  | CHECK: STUDENT, CLASS, PROGRAM |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `session_id` | bigint |  | FK → `exam_sessions` |

Unique nhiều cột: (session_id, source_type, source_public_id)

### exam_session_proctors

[V1 dòng 476](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L476)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `proctor_public_id` | uuid |  | ref → `users` (logic) |
| `role` | character varying(255) | có | CHECK: LEAD_PROCTOR, ASSISTANT_PROCTOR |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `session_id` | bigint |  | FK → `exam_sessions` |

Unique nhiều cột: (session_id, proctor_public_id)

Index: `idx_exam_session_proctors_session` (session_id)

### exam_registrations

[V1 dòng 380](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L380)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `attendance_status` | character varying(32) |  | CHECK: UNMARKED, PRESENT, ABSENT, LATE |
| `attendance_version` | bigint |  |  |
| `identity_note` | character varying(1000) | có |  |
| `identity_status` | character varying(32) |  | CHECK: UNVERIFIED, VERIFIED, FAILED |
| `last_action_at` | timestamp(6) with time zone | có |  |
| `last_actor_public_id` | uuid | có | ref → `users` (logic) |
| `last_actor_role` | character varying(32) | có |  |
| `last_reason_or_note` | character varying(1000) | có |  |
| `license_key` | character varying(64) |  |  |
| `prior_session_name` | character varying(255) | có |  |
| `prior_session_public_id` | uuid | có | ref → `exam_sessions` (logic) |
| `prior_status` | character varying(16) | có |  |
| `published_at` | timestamp(6) with time zone | có |  |
| `reason` | character varying(32) | có | CHECK: DUPLICATE_SOURCE, ALREADY_ASSIGNED, ALREADY_STARTED, SCHEDULE_OVERLAP, OUTSIDE_TENANT, CAPACITY_EXCEEDED |
| `source_summary` | character varying(1000) | có |  |
| `status` | character varying(16) |  | CHECK: CANDIDATE, ELIGIBLE, EXCLUDED, ENROLLED |
| `student_public_id` | uuid |  | ref → `users` (logic) |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `session_id` | bigint |  | FK → `exam_sessions` |

Unique nhiều cột: (session_id, student_public_id)

Index: `idx_exam_registrations_session` (session_id); `idx_exam_registrations_student` (tenant_id, student_public_id)

### exam_attempts

[V1 dòng 209](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L209)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `active_section` | character varying(255) | có |  |
| `answer_integrity_level` | character varying(255) |  |  |
| `attempt_number` | integer |  |  |
| `capability_fingerprint` | character varying(2048) | có |  |
| `current_order_index` | integer | có | DEFAULT 0 NOT NULL |
| `device_check_passed_at` | timestamp(6) with time zone | có |  |
| `device_check_required` | boolean |  |  |
| `exam_definition_public_id` | uuid |  | ref → `exam_definitions` (logic) |
| `exam_definition_version` | integer | có |  |
| `exam_end_time` | timestamp(6) with time zone | có |  |
| `exam_mode` | character varying(16) |  |  |
| `exam_version_public_id` | uuid |  | ref → `exam_versions` (logic) |
| `grading_excluded` | boolean |  |  |
| `grading_exclusion_reason` | character varying(500) | có |  |
| `last_play_allowed` | boolean | có |  |
| `last_play_request_id` | character varying(255) | có |  |
| `last_seen_at` | timestamp(6) with time zone | có |  |
| `lockdown_mode` | character varying(20) | có |  |
| `max_retries_per_student` | integer | có | DEFAULT 0 NOT NULL |
| `play_count` | integer | có | DEFAULT 0 NOT NULL |
| `proctor_required` | boolean |  |  |
| `replay_policy_limit` | integer | có |  |
| `replay_policy_type` | character varying(255) |  |  |
| `section_started_at` | timestamp(6) with time zone | có |  |
| `session_public_id` | uuid |  | ref → `exam_sessions` (logic) |
| `started_at` | timestamp(6) with time zone | có |  |
| `status` | character varying(255) |  | CHECK: CREATED, IN_PROGRESS, SUBMITTED |
| `student_public_id` | uuid |  | ref → `users` (logic) |
| `submitted_at` | timestamp(6) with time zone | có |  |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `version` | bigint | có |  |

Unique nhiều cột: (session_public_id, student_public_id, attempt_number)

Index: `idx_attempts_tenant` (tenant_id)

### attempt_answers

[V1 dòng 80](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L80)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `confidence` | character varying(16) | có | CHECK: LOW, MEDIUM, HIGH |
| `expired` | boolean |  |  |
| `item_order_index` | integer |  |  |
| `item_public_id` | uuid |  | ref → `exam_version_items` (logic) |
| `payload` | text | có |  |
| `selected_evaluation_public_id` | uuid | có | ref → `answer_evaluations` (logic) |
| `selected_score_source` | character varying(16) | có |  |
| `selected_score_source_at` | timestamp(6) with time zone | có |  |
| `selected_score_source_by` | uuid | có | ref → `users` (logic) |
| `status` | character varying(255) |  | CHECK: SUBMITTED, SCORED |
| `attempt_id` | bigint |  | FK → `exam_attempts` |

Unique nhiều cột: (attempt_id, item_public_id)

Index: `idx_answers_attempt` (attempt_id)

### exam_incidents

[V1 dòng 343](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L343)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `attempt_public_id` | uuid | có | ref → `exam_attempts` (logic) |
| `client_event_id` | character varying(128) | có |  |
| `client_occurred_at` | timestamp(6) with time zone | có |  |
| `current_owner_name` | character varying(255) | có |  |
| `current_owner_role` | character varying(32) |  |  |
| `description` | text | có |  |
| `detected_at` | timestamp(6) with time zone |  |  |
| `origin` | character varying(16) |  | CHECK: AUTO, PROCTOR_FLAG, REPORTED |
| `reporter_name` | character varying(255) | có |  |
| `reporter_public_id` | uuid | có | ref → `users` (logic) |
| `reporter_role` | character varying(32) | có |  |
| `resolution_summary` | text | có |  |
| `session_public_id` | uuid |  | ref → `exam_sessions` (logic) |
| `severity` | character varying(32) |  |  |
| `status` | character varying(32) |  |  |
| `student_public_id` | uuid | có | ref → `users` (logic) |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `title` | character varying(255) |  |  |
| `type` | character varying(64) |  |  |

Unique nhiều cột: (attempt_public_id, client_event_id)

Index: `idx_exam_incidents_attempt` (attempt_public_id, detected_at); `idx_exam_incidents_session_origin` (tenant_id, session_public_id, origin, detected_at)

## scoring, reporting

### answer_evaluations

[V1 dòng 14](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L14)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `answer_public_id` | uuid |  | ref → `attempt_answers` (logic) |
| `attempt_public_id` | uuid |  | ref → `exam_attempts` (logic) |
| `lock_version` | bigint |  |  |
| `score` | integer | có |  |
| `scored_at` | timestamp(6) with time zone | có |  |
| `session_public_id` | uuid |  | ref → `exam_sessions` (logic) |
| `source` | character varying(16) |  |  |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `ai_dispatched_at` | timestamp(6) with time zone | có |  |
| `ai_model` | character varying(160) | có |  |
| `ai_provider` | character varying(64) | có |  |
| `ai_provider_category` | character varying(16) | có | CHECK: REAL, STUB |
| `ai_provider_version` | character varying(100) | có |  |
| `criteria_scores_json` | text | có |  |
| `detail_json` | text | có |  |
| `dispatch_token` | bigint | có |  |
| `exam_definition_public_id` | uuid | có | ref → `exam_definitions` (logic) |
| `failure_reason` | character varying(40) | có | CHECK: PROVIDER_RATE_LIMITED, PROVIDER_UNAVAILABLE, PROVIDER_TIMEOUT, PROVIDER_NETWORK_ERROR, PROVIDER_AUTH_FAILED, PROVIDER_BAD_REQUEST, PROVIDER_RESPONSE_INVALID, PROVIDER_CONTENT_BLOCKED, AUDIO_UNSUPPORTED, AUDIO_TOO_LONG, INTERNAL_ERROR |
| `fallback` | boolean | có |  |
| `feedback` | text | có |  |
| `item_public_id` | uuid | có | ref → `exam_version_items` (logic) |
| `scoring_method` | character varying(16) | có | CHECK: AI_SPEECH, AI_TEXT, OBJECTIVE, UNSCORED |
| `section` | character varying(255) | có |  |
| `status` | character varying(16) | có | CHECK: PENDING, AI_SCORING, SCORING_FAILED, SCORED |
| `task_type` | character varying(255) | có |  |
| `teacher_score` | integer | có |  |
| `teacher_scored_at` | timestamp(6) with time zone | có |  |
| `transcript` | text | có |  |
| `assignment_id` | bigint | có | ref → `grading_assignments` (logic) |
| `comment` | character varying(2000) | có |  |
| `decision_kind` | character varying(32) | có | CHECK: CONFIRM_AI, MANUAL, LEGACY_IMPORTED |
| `draft_version` | bigint | có |  |
| `examiner_public_id` | uuid | có | ref → `users` (logic) |
| `expected_review_version` | character varying(128) | có |  |
| `request_fingerprint` | character varying(128) | có |  |
| `request_public_id` | uuid | có |  |
| `reviewed_ai_score` | integer | có |  |
| `reviewed_ai_version` | character varying(128) | có |  |
| `saved_at` | timestamp(6) with time zone | có |  |
| `examiner_status` | character varying(16) | có | CHECK: DRAFT, SUBMITTED |
| `submitted_at` | timestamp(6) with time zone | có |  |

Unique nhiều cột: (answer_public_id, source)

CHECK khác: `CONSTRAINT answer_evaluations_check CHECK ((((source)::text <> 'AI'::text) OR ((dispatch_token IS NOT NULL) AND (fallback IS NOT NULL))))`; `CONSTRAINT answer_evaluations_check1 CHECK ((((source)::text <> 'EXAMINER'::text) OR (draft_version IS NOT NULL)))`

Index: `idx_answer_evaluations_attempt` (tenant_id, attempt_public_id); `idx_answer_evaluations_session` (tenant_id, session_public_id); `uq_examiner_score_receipt` (unique) (tenant_id, examiner_public_id, request_public_id) WHERE (request_public_id IS NOT NULL)

### grading_assignments

[V1 dòng 626](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L626)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `assigned_at` | timestamp(6) with time zone |  |  |
| `assigned_by_public_id` | uuid |  | ref → `users` (logic) |
| `attempt_public_id` | uuid |  | ref → `exam_attempts` (logic) |
| `eligible_answer_count` | integer |  |  |
| `examiner_public_id` | uuid |  | ref → `users` (logic) |
| `finalized_at` | timestamp(6) with time zone | có |  |
| `session_public_id` | uuid |  | ref → `exam_sessions` (logic) |
| `started_at` | timestamp(6) with time zone | có |  |
| `status` | character varying(16) |  | CHECK: PENDING, IN_PROGRESS, COMPLETED |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `work_version` | bigint |  |  |

Unique nhiều cột: (session_public_id, attempt_public_id)

Index: `idx_grading_assignment_examiner` (tenant_id, session_public_id, examiner_public_id); `idx_grading_assignment_owner_status` (tenant_id, examiner_public_id, status)

### grading_issues

[V1 dòng 655](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L655)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `answer_public_id` | uuid | có | ref → `attempt_answers` (logic) |
| `assignment_id` | bigint |  | ref → `grading_assignments` (logic) |
| `description` | character varying(2000) |  |  |
| `reported_at` | timestamp(6) with time zone |  |  |
| `reported_by` | uuid |  | ref → `users` (logic) |
| `resolution` | character varying(2000) | có |  |
| `resolved_at` | timestamp(6) with time zone | có |  |
| `resolved_by` | uuid | có | ref → `users` (logic) |
| `status` | character varying(255) |  | CHECK: OPEN, RESOLVED |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `type` | character varying(255) |  | CHECK: AUDIO_UNAVAILABLE, MEDIA_UNAVAILABLE, RESPONSE_DATA, OTHER |

Index: `idx_grading_issues_assignment` (tenant_id, assignment_id, status)

### exam_results

[V1 dòng 420](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L420)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `attempt_public_id` | uuid |  | ref → `exam_attempts` (logic); UK |
| `listening_score` | integer | có |  |
| `overall_score` | integer | có |  |
| `publication_cohort_size` | integer | có |  |
| `publication_public_id` | uuid | có |  |
| `published` | boolean |  |  |
| `published_at` | timestamp(6) with time zone | có |  |
| `published_by_public_id` | uuid | có | ref → `users` (logic) |
| `reading_score` | integer | có |  |
| `report_snapshot_json` | text | có |  |
| `session_public_id` | uuid |  | ref → `exam_sessions` (logic) |
| `snapshot_public_id` | uuid | có |  |
| `speaking_score` | integer | có |  |
| `student_public_id` | uuid |  | ref → `users` (logic) |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `writing_score` | integer | có |  |

Index: `idx_exam_results_session` (session_public_id); `idx_exam_results_student_tenant_published` (student_public_id, tenant_id, published, published_at)

## practice

### practice_sessions

[V1 dòng 1214](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1214)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `catalog_version` | character varying(32) |  |  |
| `client_capabilities` | text | có |  |
| `completed_at` | timestamp(6) with time zone | có |  |
| `deadline_at` | timestamp(6) with time zone | có |  |
| `discarded_at` | timestamp(6) with time zone | có |  |
| `identity_public_id` | uuid |  |  |
| `last_activity_at` | timestamp(6) with time zone | có |  |
| `product_code` | character varying(64) |  |  |
| `selected_task_types` | text | có |  |
| `source_type` | character varying(16) |  |  |
| `start_idempotency_key` | character varying(128) |  |  |
| `start_request_hash` | character varying(64) |  |  |
| `started_at` | timestamp(6) with time zone | có |  |
| `status` | character varying(16) |  | CHECK: OVERVIEW, IN_PROGRESS, COMPLETED, DISCARDED, EXPIRED |
| `student_public_id` | uuid |  | ref → `users` (logic) |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `time_limit_seconds` | integer |  |  |
| `title` | character varying(128) |  |  |
| `version` | bigint | có |  |

CHECK khác: `CONSTRAINT practice_sessions_source_type_check CHECK (((source_type)::text = 'PRACTICE'::text))`

Index: `idx_practice_sessions_student` (student_public_id); `idx_practice_sessions_tenant_status` (tenant_id, status)

### practice_responses

[V1 dòng 1150](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1150)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `ai_detail_json` | text | có |  |
| `ai_feedback` | text | có |  |
| `ai_model` | character varying(160) | có |  |
| `ai_provider` | character varying(64) | có |  |
| `ai_provider_version` | character varying(100) | có |  |
| `ai_result_hash` | character varying(64) | có |  |
| `ai_score` | integer | có |  |
| `ai_score_status` | character varying(32) | có |  |
| `ai_scored_at` | timestamp(6) with time zone | có |  |
| `ai_sub_scores_json` | text | có |  |
| `ai_transcript` | text | có |  |
| `answer_schema_version` | integer | có |  |
| `answered_at` | timestamp(6) with time zone | có |  |
| `audio_prompt_ref` | uuid | có |  |
| `confidence` | character varying(16) | có | CHECK: LOW, MEDIUM, HIGH |
| `contract_version` | integer | có |  |
| `correct_answer_text` | text | có |  |
| `display_name` | character varying(128) |  |  |
| `image_prompt_ref` | uuid | có |  |
| `max_word_count` | integer | có |  |
| `min_word_count` | integer | có |  |
| `objective_evaluated_at` | timestamp(6) with time zone | có |  |
| `objective_options_json` | text | có |  |
| `objective_score` | integer | có |  |
| `options_json` | text | có |  |
| `order_index` | integer |  |  |
| `practice_session_id` | bigint |  | ref → `practice_sessions` (logic) |
| `prompt_text` | text | có |  |
| `reference_answer_text` | text | có |  |
| `renderer_key` | character varying(128) |  |  |
| `saved_payload` | text | có |  |
| `scoring_attempts` | integer |  |  |
| `scoring_dispatch_token` | uuid | có |  |
| `scoring_dispatched_at` | timestamp(6) with time zone | có |  |
| `scoring_failure_code` | character varying(32) | có |  |
| `scoring_redispatch_count` | integer |  |  |
| `scoring_requested_at` | timestamp(6) with time zone | có |  |
| `scoring_status` | character varying(16) |  | CHECK: NONE, SCORING, SCORED, FAILED |
| `section` | character varying(32) |  |  |
| `skipped_at` | timestamp(6) with time zone | có |  |
| `source_question_public_id` | uuid | có | ref → `questions` (logic) |
| `status` | character varying(16) |  | CHECK: PENDING, ANSWERED, SKIPPED |
| `task_code` | character varying(64) |  |  |
| `version` | bigint | có |  |

Unique nhiều cột: (practice_session_id, order_index)

Index: `idx_practice_responses_session` (practice_session_id); `idx_practice_responses_status` (practice_session_id, status)

### otp_challenges

[V1 dòng 1108](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1108)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `code_hash` | character varying(255) |  |  |
| `consumed_at` | timestamp(6) with time zone | có |  |
| `expires_at` | timestamp(6) with time zone |  |  |
| `failed_attempts` | integer |  |  |
| `identity_id` | bigint |  |  |

Index: `idx_otp_challenges_identity_created` (identity_id, created_at)

## billing

### service_plans

[V1 dòng 1408](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1408)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `currency` | character varying(3) |  |  |
| `description` | character varying(255) | có |  |
| `duration_days` | integer | có |  |
| `extra_student_slots` | integer | có |  |
| `max_students_per_session` | integer | có |  |
| `name` | character varying(255) |  |  |
| `price` | numeric(19,2) |  |  |
| `status` | character varying(32) |  | CHECK: DRAFT, ACTIVE, ARCHIVED |
| `type` | character varying(32) |  | CHECK: EXAM_PACKAGE, STUDENT_CAPACITY |
| `version` | bigint |  |  |

### orders

[V1 dòng 1021](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1021)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `amount` | numeric(19,2) |  |  |
| `currency` | character varying(3) |  |  |
| `order_code` | bigint |  | UK |
| `paid_at` | timestamp(6) with time zone | có |  |
| `payment_link_url` | character varying(512) | có |  |
| `plan_id` | uuid |  | ref → `service_plans` (logic) |
| `status` | character varying(16) |  | CHECK: PENDING, PAID, CANCELLED, EXPIRED |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |

Index: `idx_orders_status_created` (status, created_at); `idx_orders_tenant_created` (tenant_id, created_at); `ux_orders_pending_tenant_plan` (unique) (tenant_id, plan_id) WHERE (((status)::text = 'PENDING'::text) AND (deleted = false))

### order_payments

[V1 dòng 1000](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1000)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `processed` | boolean |  |  |
| `raw_payload` | text |  |  |
| `received_at` | timestamp(6) with time zone |  |  |
| `order_id` | bigint |  | FK → `orders` |

Index: `idx_order_payments_order` (order_id); `idx_order_payments_received_at` (received_at)

### subscriptions

[V1 dòng 1437](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1437)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `activation_source` | character varying(16) |  | CHECK: PAYMENT, LICENSE_CODE |
| `expires_at` | timestamp(6) with time zone |  |  |
| `license_key` | character varying(32) |  | UK |
| `max_students_per_session` | integer |  |  |
| `plan_id` | uuid |  | ref → `service_plans` (logic) |
| `starts_at` | timestamp(6) with time zone |  |  |
| `status` | character varying(16) |  | CHECK: ACTIVE, EXPIRED, CANCELLED |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |

Index: `idx_subscriptions_tenant_status` (tenant_id, status)

### license_codes

[V1 dòng 773](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L773)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `code` | character varying(32) |  | UK |
| `code_expires_at` | timestamp(6) with time zone | có |  |
| `issued_at` | timestamp(6) with time zone |  |  |
| `issued_by` | uuid |  | ref → `users` (logic) |
| `plan_id` | uuid |  | ref → `service_plans` (logic) |
| `redeemed_at` | timestamp(6) with time zone | có |  |
| `redeemed_by_tenant_id` | uuid | có | ref → `organizations` (logic) |
| `revoke_reason` | character varying(255) | có |  |
| `status` | character varying(16) |  | CHECK: ISSUED, REDEEMED, REVOKED, EXPIRED |
| `subscription_id` | uuid | có | ref → `subscriptions` (logic); UK |

Index: `idx_license_codes_status_expiry` (status, code_expires_at)

### platform_settings

[V1 dòng 1130](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1130)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `description` | character varying(255) | có |  |
| `setting_key` | character varying(100) |  | UK |
| `value` | character varying(255) |  |  |

## notification, support, shared

### notifications

[V1 dòng 969](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L969)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone | có | DEFAULT CURRENT_TIMESTAMP NOT NULL |
| `deleted` | boolean | có | DEFAULT false NOT NULL |
| `public_id` | uuid | có | UK; DEFAULT gen_random_uuid() NOT NULL |
| `updated_at` | timestamp(6) with time zone | có | DEFAULT CURRENT_TIMESTAMP NOT NULL |
| `body` | character varying(5000) |  |  |
| `category` | character varying(32) |  | CHECK: SYSTEM_NOTICE, MAINTENANCE, SESSION, APPLICATION, BILLING, SUPPORT |
| `event_key` | character varying(255) |  |  |
| `importance` | character varying(16) |  | CHECK: INFO, IMPORTANT |
| `notification_type` | character varying(48) |  | CHECK: APPLICATION_SUBMITTED, PLATFORM_ANNOUNCEMENT, SESSION_CLOSING_SOON, SESSION_GRADING_COMPLETED, COMMERCIAL_OUTCOME_CONFIRMED, ORDER_EXPIRED, SUBSCRIPTION_REVOKED, SUPPORT_TICKET_SUBMITTED, SUPPORT_TICKET_NOTE_ADDED, SUPPORT_TICKET_STATUS_CHANGED |
| `payload_hash` | character varying(64) |  |  |
| `schema_version` | integer |  |  |
| `target_public_id` | uuid |  |  |
| `target_type` | character varying(32) |  | CHECK: APPLICATION, ANNOUNCEMENT, SESSION, ORDER, SUBSCRIPTION, QUOTA, SUPPORT_TICKET |
| `title` | character varying(150) |  |  |

Index: `uq_notifications_event_key` (unique) (event_key)

### notification_recipients

[V1 dòng 938](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L938)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone | có | DEFAULT CURRENT_TIMESTAMP NOT NULL |
| `deleted` | boolean | có | DEFAULT false NOT NULL |
| `public_id` | uuid | có | UK; DEFAULT gen_random_uuid() NOT NULL |
| `updated_at` | timestamp(6) with time zone | có | DEFAULT CURRENT_TIMESTAMP NOT NULL |
| `attempts` | integer | có | DEFAULT 0 NOT NULL |
| `claim_token` | uuid | có |  |
| `completed_at` | timestamp(6) with time zone | có |  |
| `content_public_id` | uuid |  | ref → `notifications` (logic) |
| `delivered_at` | timestamp(6) with time zone | có |  |
| `last_failure_code` | character varying(64) | có |  |
| `lease_until` | timestamp(6) with time zone | có |  |
| `next_attempt_at` | timestamp(6) with time zone |  |  |
| `read_at` | timestamp(6) with time zone | có |  |
| `recipient_user_public_id` | uuid |  | ref → `users` (logic) |
| `sequence_no` | bigint | có |  |
| `status` | character varying(16) | có | CHECK: PENDING, PROCESSING, DELIVERED, FAILED, SUPPRESSED; DEFAULT 'PENDING'::character varying NOT NULL |
| `tenant_id` | uuid | có | ref → `organizations` (logic) |

Unique nhiều cột: (content_public_id, recipient_user_public_id); (recipient_user_public_id, sequence_no)

Index: `idx_notification_recipient_claim` (status, next_attempt_at); `idx_notification_recipient_lease` (status, lease_until); `idx_notification_recipient_content_status` (content_public_id, status)

### notification_recipient_streams

[V1 dòng 917](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L917)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone | có | DEFAULT CURRENT_TIMESTAMP NOT NULL |
| `deleted` | boolean | có | DEFAULT false NOT NULL |
| `public_id` | uuid | có | UK; DEFAULT gen_random_uuid() NOT NULL |
| `updated_at` | timestamp(6) with time zone | có | DEFAULT CURRENT_TIMESTAMP NOT NULL |
| `last_sequence` | bigint | có | DEFAULT 0 NOT NULL |
| `read_revision` | bigint | có | DEFAULT 0 NOT NULL |
| `recipient_user_public_id` | uuid |  | ref → `users` (logic) |
| `tenant_id` | uuid | có | ref → `organizations` (logic) |

Index: `uq_notification_recipient_streams_recipient` (unique) (recipient_user_public_id)

### notification_inbox_snapshots

[V1 dòng 866](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L866)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `public_id` | uuid | có | UK; DEFAULT gen_random_uuid() NOT NULL |
| `recipient_user_public_id` | uuid |  | FK → `users` |
| `tenant_id` | uuid | có | ref → `organizations` (logic) |
| `upper_sequence` | bigint |  |  |
| `read_revision` | bigint |  |  |
| `created_at` | timestamp with time zone | có | DEFAULT CURRENT_TIMESTAMP NOT NULL |
| `expires_at` | timestamp with time zone |  |  |

CHECK khác: `CONSTRAINT notification_inbox_snapshots_check CHECK ((expires_at > created_at))`; `CONSTRAINT notification_inbox_snapshots_read_revision_check CHECK ((read_revision >= 0))`; `CONSTRAINT notification_inbox_snapshots_upper_sequence_check CHECK ((upper_sequence >= 0))`

Index: `idx_inbox_snapshot_owner` (recipient_user_public_id, tenant_id, expires_at)

### notification_announcements

[V1 dòng 836](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L836)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone | có | DEFAULT CURRENT_TIMESTAMP NOT NULL |
| `deleted` | boolean | có | DEFAULT false NOT NULL |
| `public_id` | uuid | có | UK; DEFAULT gen_random_uuid() NOT NULL |
| `updated_at` | timestamp(6) with time zone | có | DEFAULT CURRENT_TIMESTAMP NOT NULL |
| `affected_from` | timestamp(6) with time zone | có |  |
| `affected_until` | timestamp(6) with time zone | có |  |
| `author_user_public_id` | uuid |  | ref → `users` (logic) |
| `body` | character varying(5000) |  |  |
| `category` | character varying(32) |  | CHECK: SYSTEM_NOTICE, MAINTENANCE, SESSION, APPLICATION, BILLING, SUPPORT |
| `correction_of_public_id` | uuid | có | ref → `notification_announcements` (logic) |
| `importance` | character varying(16) |  | CHECK: INFO, IMPORTANT |
| `published_at` | timestamp(6) with time zone | có |  |
| `published_content_public_id` | uuid | có | ref → `notifications` (logic) |
| `title` | character varying(150) |  |  |
| `version` | bigint | có | DEFAULT 0 NOT NULL |

### notification_logs

[V1 dòng 889](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L889)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `body` | character varying(255) |  |  |
| `dedupe_key` | character varying(255) | có |  |
| `notification_type` | character varying(255) |  | CHECK: STUDENT_ENROLLED, ATTEMPT_PUBLISHED, VIOLATION_DETECTED, SESSION_CANCELLED, STUDENT_ENROLLMENT_CONFLICT, TENANT_APPLICATION_SUBMITTED, TENANT_APPLICATION_APPROVED, TENANT_APPLICATION_REJECTED, USER_CREDENTIALS_SENT, PRACTICE_EMAIL_CHALLENGE |
| `recipient_email` | character varying(255) |  |  |
| `recipient_user_public_id` | uuid | có | ref → `users` (logic) |
| `sent_at` | timestamp(6) with time zone | có |  |
| `status` | character varying(255) |  | CHECK: PENDING, SENT, FAILED |
| `subject` | character varying(255) |  |  |
| `tenant_id` | uuid | có | ref → `organizations` (logic) |

Index: `idx_notification_logs_tenant` (tenant_id); `uq_notification_logs_dedupe_key` (unique) (dedupe_key) WHERE (dedupe_key IS NOT NULL)

### support_ticket

[V1 dòng 1464](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1464)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `category` | character varying(255) |  | CHECK: BUG, CONTENT_COMPLAINT, GENERAL_FEEDBACK |
| `description` | character varying(2000) |  |  |
| `entity_id` | character varying(36) | có |  |
| `entity_type` | character varying(32) | có | CHECK: EXAM_SESSION, EXAM_ATTEMPT, QUESTION |
| `status` | character varying(255) |  | CHECK: OPEN, IN_PROGRESS, RESOLVED, CLOSED |
| `submitter_user_public_id` | uuid |  | ref → `users` (logic) |
| `tenant_id` | uuid |  | ref → `organizations` (logic) |
| `version` | bigint |  |  |

Index: `idx_support_ticket_tenant_status_created` (tenant_id, status, created_at)

### support_ticket_note

[V1 dòng 1492](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L1492)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `admin_public_id` | uuid |  | ref → `users` (logic) |
| `content` | text |  |  |
| `ticket_id` | bigint |  | ref → `support_ticket` (logic) |
| `ticket_public_id` | uuid |  | ref → `support_ticket` (logic) |

Index: `idx_support_ticket_note_ticket_created` (ticket_id, created_at)

### audit_logs

[V1 dòng 110](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L110)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `action` | character varying(255) |  |  |
| `actor_role` | character varying(255) | có |  |
| `actor_user_id` | uuid |  | ref → `users` (logic) |
| `after_state` | jsonb | có |  |
| `aggregate_id` | character varying(255) |  |  |
| `aggregate_type` | character varying(255) |  |  |
| `before_state` | jsonb | có |  |
| `request_public_id` | uuid | có |  |
| `resource_code` | character varying(255) | có |  |
| `resource_name` | character varying(255) | có |  |
| `summary` | character varying(500) |  |  |
| `tenant_id` | uuid | có | ref → `organizations` (logic) |

Index: `idx_audit_logs_tenant` (tenant_id); `idx_audit_logs_tenant_aggregate_type` (tenant_id, aggregate_type)

### idempotency_keys

[V1 dòng 685](../../../../pte-api/app/src/main/resources/db/migration/V1__baseline.sql#L685)

| Cột | Kiểu | Null | Ràng buộc |
|---|---|---|---|
| `id` | bigint |  | PK |
| `created_at` | timestamp(6) with time zone |  |  |
| `deleted` | boolean |  |  |
| `public_id` | uuid |  | UK |
| `updated_at` | timestamp(6) with time zone |  |  |
| `completed` | boolean |  |  |
| `expires_at` | timestamp(6) with time zone |  |  |
| `idempotency_key` | character varying(128) |  |  |
| `organization_id` | uuid |  | ref → `organizations` (logic) |
| `request_hash` | character varying(128) |  |  |
| `result` | jsonb | có |  |
| `scope` | character varying(32) |  | CHECK: ATTENDANCE, EXAMINER_COMMAND, SCORE_SELECTION, LICENSE_ISSUE, PRACTICE_SESSION_OP |

Unique nhiều cột: (scope, idempotency_key, organization_id)

Index: `idx_idempotency_expires_at` (expires_at)
