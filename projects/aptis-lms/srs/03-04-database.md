# SRS §3.4 — Database Requirements
## APTIS LMS
**Version:** 1.0 | **Date:** 2026-06-16 | **Status:** DRAFT

---

## 3.4.1 Entity Definitions

All tables in the tenant-scoped portion of the schema include `tenant_id UUID NOT NULL REFERENCES tenants(id)`. Every database query in the Backend API must include `WHERE tenant_id = {resolved_id}` (or schema-level equivalent) as enforced by the middleware (FR-03, DC-02).

---

### tenants

Root record for each school or training center (B2B customer).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| slug | VARCHAR(64) | UNIQUE NOT NULL | URL-safe subdomain identifier; immutable after first activation |
| display_name | VARCHAR(255) | NOT NULL | Human-readable organization name |
| contact_email | VARCHAR(255) | NOT NULL | Primary contact for system notifications |
| status | ENUM | NOT NULL | `pending / active / suspended / decommissioned` |
| timezone | VARCHAR(64) | NOT NULL DEFAULT 'Asia/Ho_Chi_Minh' | IANA timezone string |
| logo_url | VARCHAR(512) | | Optional CDN URL for tenant portal branding |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |

**Business rule:** `slug` must be globally unique across all tenants. Once set and activated, `slug` is immutable (changing it would break subdomain routing and all bookmarked links for tenant users).

---

### licenses

Seat-based licenses granted by the Sales Team to tenants (FR-73).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| seat_count | INTEGER | NOT NULL CHECK (seat_count ≥ 1) | Maximum active student accounts |
| expiry_date | DATE | NOT NULL | License validity end date |
| created_by | UUID | FK → users NOT NULL | Sales Team user who created this license |
| created_at | TIMESTAMP | NOT NULL | |
| last_modified_by | UUID | FK → users | |
| last_modified_at | TIMESTAMP | | |
| status | ENUM | NOT NULL | `active / expired / superseded` |

**Derivation:** The tenant's effective quota is `seat_count` from the most recent license where `status = active AND expiry_date >= CURRENT_DATE`. Records are never deleted (immutable audit log per FR-81).

---

### users

All user accounts across Vendor and Tenant sides. Vendor-side users have `tenant_id = NULL`.

| Column | Type | Constraints | PII | Notes |
|--------|------|-------------|-----|-------|
| id | UUID | PK | | |
| tenant_id | UUID | FK → tenants | | NULL for Vendor-side users (Super Admin, Content Manager, Support Staff, Sales Team) |
| email | VARCHAR(255) | NOT NULL | PII | Unique per `tenant_id` (or globally for vendor users); used as login credential |
| password_hash | VARCHAR(255) | NOT NULL | Credential | bcrypt hash with cost factor ≥ 12 (NFR-12); never logged or exported |
| full_name | VARCHAR(255) | NOT NULL | PII | |
| status | ENUM | NOT NULL | | `active / suspended / deactivated` |
| email_bounced | BOOLEAN | NOT NULL DEFAULT false | | Set true on delivery bounce (FR-87); gates future email sends |
| force_password_change | BOOLEAN | NOT NULL DEFAULT false | | True for bulk-created accounts; triggers FR-06 flow |
| created_at | TIMESTAMP | NOT NULL | | |
| last_login_at | TIMESTAMP | | | Updated on every successful authentication |

**PII handling:** `email` and `full_name` are encrypted at rest via database-level encryption. Neither field appears in application log output. `password_hash` is never returned via API.

---

### user_roles

RBAC role assignments — one row per role granted to a user (FR-04).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| user_id | UUID | FK → users NOT NULL | |
| role | ENUM | NOT NULL | `super_admin / content_manager / support_staff / sales / tenant_admin / teacher / exam_coordinator / viewer / student / guest` |
| tenant_id | UUID | FK → tenants | NULL for vendor-side roles |
| assigned_by | UUID | FK → users NOT NULL | |
| assigned_at | TIMESTAMP | NOT NULL | |
| revoked_at | TIMESTAMP | | NULL = role is currently active |

**Permission computation:** Effective permissions = union of all `user_roles` rows for the user where `revoked_at IS NULL`. Vendor-side roles (`super_admin`, `content_manager`, `support_staff`, `sales`) must always have `tenant_id = NULL`; tenant-side roles must have a non-NULL `tenant_id`.

---

### refresh_tokens

Server-side refresh token store — required to support token revocation (FR-02, FR-07, NFR-13).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| user_id | UUID | FK → users NOT NULL | |
| token_hash | VARCHAR(255) | NOT NULL | bcrypt hash of the raw token value |
| issued_at | TIMESTAMP | NOT NULL | |
| expires_at | TIMESTAMP | NOT NULL | TTL = 7 days from `issued_at` |
| revoked_at | TIMESTAMP | | NULL = token is valid |
| replaced_by | UUID | FK → refresh_tokens | Set when this token is rotated (FR-02) |

**Implementation:** A pure stateless JWT refresh token cannot be revoked. This table provides the revocation capability required by FR-07 (force-logout). On each token rotation (FR-02), the old row's `revoked_at` is set and `replaced_by` points to the new row.

---

### courses

Time-bounded learning containers within a tenant (FR-44).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| name | VARCHAR(255) | NOT NULL | |
| description | TEXT | | |
| start_date | DATE | NOT NULL | |
| end_date | DATE | NOT NULL CHECK (end_date > start_date) | |
| status | ENUM | NOT NULL | `scheduled / active / ended` (computed from dates) |
| created_by | UUID | FK → users NOT NULL | |
| created_at | TIMESTAMP | NOT NULL | |

---

### groups

Named sub-divisions of a course managed by assigned Teachers (FR-45).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| course_id | UUID | FK → courses NOT NULL | |
| name | VARCHAR(255) | NOT NULL | e.g., "Class 10A Morning" |
| created_by | UUID | FK → users NOT NULL | |
| created_at | TIMESTAMP | NOT NULL | |

---

### group_teachers

Assignment of Teacher users to Groups (FR-45).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| group_id | UUID | FK → groups NOT NULL | |
| teacher_user_id | UUID | FK → users NOT NULL | Must have `teacher` role in the same tenant |
| assigned_by | UUID | FK → users NOT NULL | |
| assigned_at | TIMESTAMP | NOT NULL | |
| **PRIMARY KEY** | (group_id, teacher_user_id) | | Composite PK prevents duplicate assignments |

---

### enrollments

Student membership in a course group — drives seat count and exam eligibility (FR-46, FR-47, FR-50, FR-51).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| student_user_id | UUID | FK → users NOT NULL | |
| group_id | UUID | FK → groups NOT NULL | |
| course_id | UUID | FK → courses NOT NULL | Denormalized from group for query efficiency |
| enrolled_at | TIMESTAMP | NOT NULL | |
| enrolled_by | UUID | FK → users NOT NULL | |
| unenrolled_at | TIMESTAMP | | NULL = currently enrolled |
| seat_counted | BOOLEAN | NOT NULL DEFAULT true | True = this enrollment counts toward `seats_used` |

**Seat computation:** `seats_used = COUNT(*) FROM enrollments WHERE tenant_id = X AND unenrolled_at IS NULL AND seat_counted = true`.

Historical records are preserved when `unenrolled_at` is set (not deleted), so past exam records remain linked.

---

### questions

Individual question items in the APTIS question bank — Vendor-managed (FR-09, FR-14).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| version | INTEGER | NOT NULL DEFAULT 1 | Increments on edit after use in a completed session |
| parent_id | UUID | FK → questions | NULL for v1; versions 2+ point to v1 |
| is_current | BOOLEAN | NOT NULL DEFAULT true | Only one version per parent chain has `is_current = true` |
| is_immutable | BOOLEAN | NOT NULL DEFAULT false | Set true when linked to a completed session |
| skill | ENUM | NOT NULL | `reading / writing / listening / speaking` |
| part | VARCHAR(4) | NOT NULL | `A / B / C / D / E` |
| question_type | ENUM | NOT NULL | `mcq / matching / gap_fill / short_answer / essay / speaking_prompt` |
| content | JSONB | NOT NULL | Question text, options, image references |
| answer_key | JSONB | | Required for `mcq / matching / gap_fill`; NULL for human-scored types |
| rubric_criteria | JSONB | | Required for `essay / speaking_prompt` |
| max_play_count | INTEGER | | Listening only; NULL for other skills |
| audio_asset_id | UUID | FK → assets | |
| image_asset_ids | UUID[] | | For Speaking Part B (1 image) and Part D (2 images) |
| difficulty_tag | ENUM | NOT NULL | `easy / medium / hard` |
| topic_tags | TEXT[] | NOT NULL DEFAULT '{}' | |
| status | ENUM | NOT NULL DEFAULT 'draft' | `draft / active / archived` |
| created_by | UUID | FK → users NOT NULL | Content Manager |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |

---

### assets

Files managed in the system: audio, images, speaking recordings, report exports (SI-01).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| asset_type | ENUM | NOT NULL | `audio_listening / image_speaking / audio_recording / report_export` |
| storage_key | VARCHAR(1024) | NOT NULL | Cloud Storage object key (S3/GCS path) |
| cdn_url | VARCHAR(1024) | | CDN-fronted URL for delivery; NULL for private assets |
| filename | VARCHAR(255) | NOT NULL | Original filename |
| size_bytes | BIGINT | NOT NULL | |
| mime_type | VARCHAR(128) | NOT NULL | |
| uploaded_by | UUID | FK → users | NULL for system-generated assets |
| tenant_id | UUID | FK → tenants | NULL for Vendor-managed assets |
| created_at | TIMESTAMP | NOT NULL | |
| expires_at | TIMESTAMP | | NULL = permanent; set for temporary export files |

---

### exam_templates

Named, reusable question sets organized by skill and part — Vendor-managed (FR-12).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| name | VARCHAR(255) | NOT NULL | |
| description | TEXT | | |
| skill_sequence | JSONB | NOT NULL | Ordered list of skills and inter-skill break durations |
| questions | JSONB | NOT NULL | Map: `{skill: {part: [question_ids]}}` |
| shuffle_enabled | BOOLEAN | NOT NULL DEFAULT true | Per BR-14 |
| created_by | UUID | FK → users NOT NULL | Content Manager |
| status | ENUM | NOT NULL DEFAULT 'draft' | `draft / published / archived` |
| created_at | TIMESTAMP | NOT NULL | |

**Completeness constraint:** A template cannot be set to `published` unless `questions` contains entries for all required parts: Reading (A, B, C, D), Writing (A, B, C), Listening (A, B, C, D), Speaking (A, B, C, D, E). This validation is enforced at the application layer (FR-12).

---

### exam_sessions

Scheduled exam deployments created by Teachers or Exam Coordinators (FR-37).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| tenant_id | UUID | FK → tenants NOT NULL | |
| course_id | UUID | FK → courses NOT NULL | |
| group_id | UUID | FK → groups | NULL if participants were individually selected |
| template_id | UUID | FK → exam_templates NOT NULL | |
| name | VARCHAR(255) | NOT NULL | |
| start_time | TIMESTAMP | NOT NULL | Session window opens |
| end_time | TIMESTAMP | NOT NULL CHECK (end_time > start_time) | Session window closes |
| status | ENUM | NOT NULL DEFAULT 'scheduled' | `scheduled / active / closing / closed` |
| anticheating_config | JSONB | NOT NULL | `{shuffle: bool, warning_threshold: int, terminate_threshold: int}` |
| created_by | UUID | FK → users NOT NULL | |
| created_at | TIMESTAMP | NOT NULL | |
| closed_by | UUID | FK → users | NULL = auto-closed by timer |
| closed_at | TIMESTAMP | | NULL until session closes |

---

### session_participants

Students eligible for a specific exam session (FR-37).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| session_id | UUID | FK → exam_sessions NOT NULL | |
| student_user_id | UUID | FK → users NOT NULL | |
| added_by | UUID | FK → users NOT NULL | |
| added_at | TIMESTAMP | NOT NULL | |
| **PRIMARY KEY** | (session_id, student_user_id) | | |

---

### exam_attempts

One student's single execution of an exam session (FR-17, FR-26).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| session_id | UUID | FK → exam_sessions NOT NULL | |
| student_user_id | UUID | FK → users NOT NULL | |
| tenant_id | UUID | FK → tenants NOT NULL | Denormalized for query scoping |
| attempt_number | INTEGER | NOT NULL DEFAULT 1 | 1 for first; 2+ for retakes (FR-43) |
| status | ENUM | NOT NULL DEFAULT 'not_started' | `not_started / in_progress / submitted / force_submitted` |
| shuffle_seed | BIGINT | | Random seed for question/answer shuffle (FR-93); set at attempt creation |
| started_at | TIMESTAMP | | Set when status → in_progress |
| submitted_at | TIMESTAMP | | Set when status → submitted or force_submitted |
| force_submitted_by | UUID | FK → users | NULL if student-submitted |
| force_submit_reason | TEXT | | Required when force_submitted_by is set |
| force_submitted_on_crash | BOOLEAN | NOT NULL DEFAULT false | FR-111 flag |
| terminated_by_violation | BOOLEAN | NOT NULL DEFAULT false | FR-100 flag |
| current_skill | ENUM | | `reading / writing / listening / speaking`; NULL if not started |
| current_part | VARCHAR(4) | | Current part in progress |
| created_at | TIMESTAMP | NOT NULL | |

---

### exam_state

Per-question answer record for an in-progress attempt — replaces batch submission (FR-105, DC-05).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| question_id | UUID | FK → questions NOT NULL | |
| answer_value | JSONB | | Student's answer in question-type-specific format |
| saved_at | TIMESTAMP | NOT NULL | Server timestamp of last save; client timestamp is not trusted |
| is_skipped | BOOLEAN | NOT NULL DEFAULT false | True if student explicitly skipped |
| **PRIMARY KEY** | (attempt_id, question_id) | | Upserted on each PATCH; one row per question per attempt |

**Implementation note:** This table is the highest-write-frequency table in the system. Every MCQ selection and text input generates an upsert here (FR-105). It requires optimal indexing on `(attempt_id)` and the write path must meet NFR-06 latency targets.

---

### part_timers

Server-side timer state per attempt per part — enforces DC-04 (server-authoritative timer).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| skill | ENUM | NOT NULL | |
| part | VARCHAR(4) | NOT NULL | |
| part_duration_seconds | INTEGER | NOT NULL | From `exam_template.skill_sequence` |
| started_at | TIMESTAMP | NOT NULL | Server time when part began (FR-19) |
| extended_by_seconds | INTEGER | NOT NULL DEFAULT 0 | Cumulative coordinator time extensions (FR-40) |
| completed_at | TIMESTAMP | | NULL while part is in progress |
| **PRIMARY KEY** | (attempt_id, skill, part) | | |

**Timer formula:** `time_remaining = part_duration_seconds + extended_by_seconds − (CURRENT_TIMESTAMP − started_at)`. When `time_remaining ≤ 0` the server closes the part (FR-19) and sets `completed_at`.

---

### attempt_results

Final scored results per skill per attempt (FR-27, FR-28, FR-33).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| skill | ENUM | NOT NULL | |
| raw_score | DECIMAL(6,2) | | For auto-scored skills |
| band | ENUM | | `A1 / A2 / B1 / B2 / C / pending / mapping_error / not_attempted` |
| status | ENUM | NOT NULL DEFAULT 'pending' | `pending / available / skipped` |
| scored_by | ENUM | | `auto / human` |
| scored_at | TIMESTAMP | | |
| final_score_per_criterion | JSONB | | For Writing/Speaking: `{criterion_name: score}` |
| final_feedback_narrative | TEXT | PII | Teacher-confirmed feedback (FR-33) |
| confirmed_by | UUID | FK → users | Teacher who confirmed the score |
| confirmed_at | TIMESTAMP | | |

---

### ai_score_drafts

AI-generated draft scores for Writing and Speaking — not student-visible until confirmed (FR-31, BR-13).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| skill | ENUM | NOT NULL | `writing / speaking` |
| part | VARCHAR(4) | NOT NULL | |
| draft_score_per_criterion | JSONB | | LLM output: `{criterion: score}` |
| draft_band_estimate | ENUM | | A1–C |
| draft_feedback_narrative | TEXT | | LLM-generated feedback text |
| stt_transcript | TEXT | PII | Speaking only; output from STT API (FR-30) |
| stt_status | ENUM | | `pending / completed / failed` |
| llm_status | ENUM | | `pending / completed / failed` |
| created_at | TIMESTAMP | NOT NULL | |

**Access control:** `draft_score_per_criterion`, `draft_band_estimate`, and `draft_feedback_narrative` must never be returned in any API response to student-role JWT tokens. They are only accessible to Teacher, Exam Coordinator, and Tenant Admin roles (BR-13).

---

### speaking_recordings

Speaking audio file references per attempt per part (FR-23, FR-108, FR-109).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| part | VARCHAR(4) | NOT NULL | A / B / C / D / E |
| asset_id | UUID | FK → assets NOT NULL | Points to the uploaded file in Cloud Storage |
| duration_seconds | DECIMAL(6,2) | | |
| is_partial | BOOLEAN | NOT NULL DEFAULT false | True if recording was interrupted (FR-109) |
| upload_status | ENUM | NOT NULL DEFAULT 'pending' | `pending / uploaded / failed` |
| local_buffer_cleared | BOOLEAN | NOT NULL DEFAULT false | Set true when client confirms local buffer cleared after upload |
| created_at | TIMESTAMP | NOT NULL | |

---

### violation_events

Immutable anti-cheat violation log — no application-layer DELETE or UPDATE permitted (FR-101, DC-10).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| attempt_id | UUID | FK → exam_attempts NOT NULL | |
| violation_type | ENUM | NOT NULL | `tab_switch / focus_loss / fullscreen_exit / copy_paste_attempt` |
| occurred_at | TIMESTAMP | NOT NULL | |
| cumulative_count | INTEGER | NOT NULL | Violation count at the moment this event was logged |
| action_taken | ENUM | NOT NULL | `none / warned / terminated` |

**Immutability enforcement:** The Backend API must not expose any DELETE or UPDATE endpoint for this table. Super Admin batch purge (per NFR-10/NFR-11 retention policy) is the only permitted deletion path, executed as a scheduled job, not an ad-hoc API call.

---

### exam_events

Audit log of all Coordinator and Teacher interventions during exam sessions (FR-40, FR-41, FR-42, FR-43).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| session_id | UUID | FK → exam_sessions NOT NULL | |
| attempt_id | UUID | FK → exam_attempts | NULL for session-level events (e.g., session closed) |
| event_type | ENUM | NOT NULL | `time_extended / force_submitted / session_closed / retake_approved / retake_created` |
| actor_user_id | UUID | FK → users NOT NULL | Coordinator or Teacher who performed the action |
| reason | TEXT | NOT NULL | Mandatory reason field; empty string rejected at API layer |
| metadata | JSONB | | Additional context (e.g., `{"extension_minutes": 5}`) |
| created_at | TIMESTAMP | NOT NULL | |

---

### notification_log

Record of every notification attempt sent by the system (FR-87).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| recipient_user_id | UUID | FK → users | NULL for Guest/anonymous recipients |
| notification_type | ENUM | NOT NULL | `exam_published / result_available / review_pending / seat_warning / license_expiry / account_created / score_confirmed / review_sla / license_renewed` |
| channel | ENUM | NOT NULL | `email / push` |
| sent_at | TIMESTAMP | NOT NULL | |
| delivery_status | ENUM | NOT NULL | `sent / failed / bounced` |
| provider_response | JSONB | | Raw API response from email/push provider |
| retry_count | INTEGER | NOT NULL DEFAULT 0 | |

---

### impersonation_log

Audit log of Support Staff impersonation sessions (FR-76).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PK | |
| support_user_id | UUID | FK → users NOT NULL | Support Staff member |
| tenant_id | UUID | FK → tenants NOT NULL | Target tenant |
| started_at | TIMESTAMP | NOT NULL | |
| ended_at | TIMESTAMP | | NULL if session is still active |

**Retention:** Permanent — impersonation logs are not subject to automated purge. They constitute a privileged-access audit trail.

---

## 3.4.2 Data Volume Estimates

Estimates based on 50 tenants at v1 launch, average 1,000 students per tenant, 2 exam sessions per week per tenant over 12 months.

| Entity | Estimated rows (12 months) | Storage driver |
|--------|-----------------------------|----------------|
| tenants | ~50 | Negligible |
| licenses | ~150 | Negligible |
| users | ~50,000 | Low |
| user_roles | ~60,000 | Low |
| refresh_tokens | ~200,000 | Low (purged on expiry) |
| courses | ~500 | Negligible |
| groups | ~2,000 | Negligible |
| enrollments | ~200,000 | Low |
| questions | ~5,000 | Low |
| assets (Vendor audio/images) | ~5,000 | Metadata low; files in Cloud Storage |
| exam_templates | ~50 | Negligible |
| exam_sessions | ~5,000 | Low |
| session_participants | ~150,000 | Low |
| exam_attempts | ~150,000 | Low |
| **exam_state** | **~15,000,000** | **High — primary DB hotspot** |
| part_timers | ~2,400,000 | Medium (16 parts × 150k attempts) |
| attempt_results | ~600,000 | Low (4 skills × 150k attempts) |
| ai_score_drafts | ~900,000 | Medium (Writing: 3 parts + Speaking: 5 parts × 150k) |
| speaking_recordings | ~750,000 | Metadata low; audio files in Cloud Storage (~5–15 MB each) |
| violation_events | ~500,000 | Low–medium (varies by cohort behavior) |
| exam_events | ~50,000 | Low |
| notification_log | ~3,000,000 | Medium |
| impersonation_log | ~1,000 | Negligible |

**Largest table by row count:** `exam_state` (~15M rows). This table requires a composite index on `(attempt_id, question_id)` and optionally a covering index for the resume-fetch query (`SELECT * FROM exam_state WHERE attempt_id = ?`).

**Largest storage footprint:** Speaking audio recordings in Cloud Storage. At 5–15 MB per student attempt × 150,000 attempts = 750 GB–2.25 TB per year. Retention policy (NFR-11, OI-07) is the primary lever for controlling this cost.

---

## 3.4.3 PII Fields

| Entity | Column | PII Classification | Handling Requirements |
|--------|--------|-------------------|----------------------|
| users | email | PII — direct identifier | Encrypted at rest; never logged in plaintext; unique per tenant |
| users | full_name | PII — direct identifier | Encrypted at rest; not returned in list endpoints without authorization |
| users | password_hash | Credential | bcrypt only; never returned via any API endpoint |
| speaking_recordings | (audio file in Cloud Storage) | PII — biometric proxy (voice) | Restricted presigned URL access; retention per NFR-11; purge per OI-07 |
| ai_score_drafts | stt_transcript | PII — speech content | Database-level access restricted to Teacher/system roles; retained per NFR-11 |
| attempt_results | final_feedback_narrative | PII — educational record | Student-accessible post-confirmation; retained per NFR-10 |
| notification_log | recipient_user_id | PII — indirect | Retained per OI-07; not logged in purge audit |

**Vietnamese NĐ 13/2023/NĐ-CP:** Applicability is TBD (OI-07). If applicable, the system must: (a) obtain consent for data collection, (b) maintain a data processing register, (c) implement right-to-deletion workflows, (d) potentially store data on servers in Vietnam. These obligations must be confirmed by Legal before architecture finalization.

---

## 3.4.4 Data Retention and Purge Policy

| Data Category | Retention Target | Purge Mechanism | Notes |
|---------------|-----------------|-----------------|-------|
| Exam answer records (`exam_state`) | `[TBD — OI-07]` | Scheduled purge job | Cascade-delete with parent attempt |
| Attempt results and feedback | `[TBD — OI-07]` | Scheduled purge job | May trigger right-to-deletion flow |
| Speaking audio files (Cloud Storage) | `[TBD — OI-07]` | Cloud Storage lifecycle policy | Primary cost driver; minimize retention |
| STT transcripts (`ai_score_drafts.stt_transcript`) | `[TBD — OI-07]` | Cascade with attempt purge | Biometric proxy data; short retention preferred |
| AI draft scores (`ai_score_drafts`) | `[TBD — OI-07]` | Scheduled purge job | Post-confirmation, draft may be purgeable |
| Violation events | `[TBD — OI-07]` | Scheduled purge job | Minimum: session + 1 year for integrity appeals |
| Notification log | `[TBD — OI-07]` | Scheduled purge job | No PII in purge audit log |
| Guest/Trial session data | `[TBD — OI-07]` | Guest purge job (FR-92) | Short retention; 7–30 days suggested |
| Refresh tokens (expired/revoked) | 90 days post-expiry | Scheduled cleanup job | Needed for token rotation chain audit |
| Impersonation log | **Permanent** | No automatic purge | Privileged-access audit trail |
| License history | **Permanent** | No automatic purge | Financial audit trail |

**Purge job requirements:** All scheduled purge jobs must: (1) log the count of purged records (no PII in the purge log entry), (2) be idempotent (safe to re-run), (3) complete within a defined maintenance window (OR-OPS-04), and (4) be monitored with alerts if the job fails or runs longer than expected.
