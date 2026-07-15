# Plan File 03-04 — Database Requirements (SRS §3.4)
Project: APTIS LMS  
Date: 2026-06-16

---

## §3.4.1 Core Entities

### Entity: tenants
Purpose: Root record for each school/training center (B2B customer).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| slug | VARCHAR(64) | Unique, URL-safe, used as subdomain |
| display_name | VARCHAR(255) | Human-readable name |
| contact_email | VARCHAR(255) | Primary contact for notifications |
| status | ENUM | pending / active / suspended / decommissioned |
| timezone | VARCHAR(64) | e.g., "Asia/Ho_Chi_Minh" |
| logo_url | VARCHAR(512) | Optional CDN URL for tenant branding |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

Multi-tenant note: Every tenant-scoped entity must include `tenant_id UUID NOT NULL REFERENCES tenants(id)`.

---

### Entity: licenses
Purpose: Seat-based licenses granted by Sales to tenants.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| tenant_id | UUID | FK → tenants |
| seat_count | INTEGER | Maximum active student accounts |
| expiry_date | DATE | License validity end date |
| created_by | UUID | FK → users (Sales user) |
| created_at | TIMESTAMP | |
| last_modified_by | UUID | FK → users |
| last_modified_at | TIMESTAMP | |
| status | ENUM | active / expired / superseded |

Active license = most recent license for tenant where status=active AND expiry_date >= today.

---

### Entity: users
Purpose: All user accounts across Vendor and Tenant sides.

| Column | Type | PII | Notes |
|---|---|---|---|
| id | UUID | | PK |
| tenant_id | UUID | | FK → tenants; NULL for Vendor-side users |
| email | VARCHAR(255) | PII | Unique per tenant |
| password_hash | VARCHAR(255) | | bcrypt hash, cost ≥ 12; never stored plaintext |
| full_name | VARCHAR(255) | PII | |
| status | ENUM | | active / suspended / deactivated |
| email_bounced | BOOLEAN | | True if email delivery has bounced |
| force_password_change | BOOLEAN | | True if generated account; requires change on first login |
| created_at | TIMESTAMP | | |
| last_login_at | TIMESTAMP | | |

---

### Entity: user_roles
Purpose: RBAC role assignments — one row per role granted to a user.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| user_id | UUID | FK → users |
| role | ENUM | super_admin / content_manager / support_staff / sales / tenant_admin / teacher / exam_coordinator / viewer / student / guest |
| tenant_id | UUID | FK → tenants (NULL for vendor roles) |
| assigned_by | UUID | FK → users |
| assigned_at | TIMESTAMP | |
| revoked_at | TIMESTAMP | NULL = still active |

Effective permissions = union of all non-revoked user_roles for a user.

---

### Entity: refresh_tokens
Purpose: Server-side refresh token store (enables revocation).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| user_id | UUID | FK → users |
| token_hash | VARCHAR(255) | bcrypt hash of the raw token |
| issued_at | TIMESTAMP | |
| expires_at | TIMESTAMP | |
| revoked_at | TIMESTAMP | NULL = still valid |
| replaced_by | UUID | FK → refresh_tokens (for rotation chain) |

---

### Entity: courses
Purpose: Courses within a tenant (time-bounded learning containers).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| tenant_id | UUID | FK → tenants |
| name | VARCHAR(255) | |
| description | TEXT | |
| start_date | DATE | |
| end_date | DATE | |
| status | ENUM | scheduled / active / ended |
| created_by | UUID | FK → users |
| created_at | TIMESTAMP | |

---

### Entity: groups (Classes)
Purpose: Sub-divisions of a course, managed by Teachers.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| tenant_id | UUID | FK → tenants |
| course_id | UUID | FK → courses |
| name | VARCHAR(255) | e.g., "Class A - Morning", "Group 3B" |
| created_by | UUID | FK → users |
| created_at | TIMESTAMP | |

---

### Entity: group_teachers
Purpose: Assignment of Teachers to Groups.

| Column | Type | Notes |
|---|---|---|
| group_id | UUID | FK → groups |
| teacher_user_id | UUID | FK → users |
| assigned_by | UUID | FK → users |
| assigned_at | TIMESTAMP | |
| PRIMARY KEY | (group_id, teacher_user_id) | |

---

### Entity: enrollments
Purpose: Student membership in a course group.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| tenant_id | UUID | FK → tenants |
| student_user_id | UUID | FK → users |
| group_id | UUID | FK → groups |
| course_id | UUID | FK → courses |
| enrolled_at | TIMESTAMP | |
| enrolled_by | UUID | FK → users |
| unenrolled_at | TIMESTAMP | NULL = still enrolled |
| seat_counted | BOOLEAN | True = counted in tenant seat usage |

seats_used = COUNT(enrollments WHERE tenant_id=X AND unenrolled_at IS NULL AND seat_counted=TRUE)

---

### Entity: questions
Purpose: Individual question items in the APTIS question bank.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| version | INTEGER | Increments on edit after use in completed session |
| parent_id | UUID | FK → questions (NULL for v1; subsequent versions point to original) |
| skill | ENUM | reading / writing / listening / speaking |
| part | VARCHAR(4) | A / B / C / D / E |
| question_type | ENUM | mcq / matching / gap_fill / short_answer / essay / speaking_prompt |
| content | JSONB | Question content (text, options, image references, etc.) |
| answer_key | JSONB | For auto-scored types: correct answer(s) |
| rubric_criteria | JSONB | For human-scored types: scoring rubric |
| max_play_count | INTEGER | Listening only; NULL for other skills |
| audio_asset_id | UUID | FK → assets; NULL if no audio |
| image_asset_ids | UUID[] | FK → assets[]; for Speaking Part B/D |
| difficulty_tag | ENUM | easy / medium / hard |
| topic_tags | TEXT[] | Array of topic strings |
| status | ENUM | draft / active / archived |
| created_by | UUID | FK → users |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

---

### Entity: assets
Purpose: Files uploaded and managed in the system (audio, images, exports).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| asset_type | ENUM | audio_listening / image_speaking / audio_recording / report_export |
| storage_key | VARCHAR(1024) | Cloud Storage object key (S3/GCS path) |
| cdn_url | VARCHAR(1024) | CDN-fronted URL for delivery |
| filename | VARCHAR(255) | Original filename |
| size_bytes | BIGINT | |
| mime_type | VARCHAR(128) | |
| uploaded_by | UUID | FK → users (NULL for system-generated) |
| tenant_id | UUID | FK → tenants (NULL for Vendor assets) |
| created_at | TIMESTAMP | |
| expires_at | TIMESTAMP | NULL = permanent; set for temp exports |

---

### Entity: exam_templates
Purpose: Named sets of questions organized by skill and part.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| name | VARCHAR(255) | |
| description | TEXT | |
| skill_sequence | JSONB | Ordered list of skills and inter-skill breaks |
| questions | JSONB | Map: {skill: {part: [question_ids]}} |
| shuffle_enabled | BOOLEAN | Default true per BR-14 |
| created_by | UUID | FK → users (Content Manager) |
| status | ENUM | draft / published / archived |
| created_at | TIMESTAMP | |

---

### Entity: exam_sessions
Purpose: Scheduled exam deployments created by Teachers/Coordinators.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| tenant_id | UUID | FK → tenants |
| course_id | UUID | FK → courses |
| group_id | UUID | FK → groups (NULL if participants individually selected) |
| template_id | UUID | FK → exam_templates |
| name | VARCHAR(255) | |
| start_time | TIMESTAMP | Session window opens |
| end_time | TIMESTAMP | Session window closes |
| status | ENUM | scheduled / active / closing / closed |
| anticheating_config | JSONB | {shuffle: bool, warning_threshold: int, terminate_threshold: int} |
| created_by | UUID | FK → users |
| created_at | TIMESTAMP | |
| closed_by | UUID | FK → users; NULL = auto-closed |
| closed_at | TIMESTAMP | |

---

### Entity: session_participants
Purpose: Students eligible for a specific exam session.

| Column | Type | Notes |
|---|---|---|
| session_id | UUID | FK → exam_sessions |
| student_user_id | UUID | FK → users |
| added_by | UUID | FK → users |
| added_at | TIMESTAMP | |
| PRIMARY KEY | (session_id, student_user_id) | |

---

### Entity: exam_attempts
Purpose: One student's execution of one exam session.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| session_id | UUID | FK → exam_sessions |
| student_user_id | UUID | FK → users |
| tenant_id | UUID | FK → tenants |
| attempt_number | INTEGER | 1 for first attempt, 2 for retake |
| status | ENUM | not_started / in_progress / submitted / force_submitted |
| shuffle_seed | BIGINT | Random seed for question/answer order (BR-14) |
| started_at | TIMESTAMP | |
| submitted_at | TIMESTAMP | NULL until finalized |
| force_submitted_by | UUID | FK → users; NULL if student-submitted |
| force_submitted_on_crash | BOOLEAN | FR-111 flag |
| current_skill | ENUM | reading / writing / listening / speaking; NULL if not started |
| current_part | VARCHAR(4) | |
| created_at | TIMESTAMP | |

---

### Entity: exam_state
Purpose: Per-question answer state for an in-progress attempt (replaces batch submit).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| attempt_id | UUID | FK → exam_attempts |
| question_id | UUID | FK → questions |
| answer_value | JSONB | Student's answer in question-type-specific format |
| saved_at | TIMESTAMP | Server timestamp when answer was last saved |
| is_skipped | BOOLEAN | True if student explicitly skipped |
| PRIMARY KEY | (attempt_id, question_id) | Upsert on each save |

---

### Entity: part_timers
Purpose: Server-side timer state per attempt per part.

| Column | Type | Notes |
|---|---|---|
| attempt_id | UUID | FK → exam_attempts |
| skill | ENUM | |
| part | VARCHAR(4) | |
| part_duration_seconds | INTEGER | From template configuration |
| started_at | TIMESTAMP | Server time when part began |
| extended_by_seconds | INTEGER | Sum of coordinator-granted extensions (FR-40) |
| completed_at | TIMESTAMP | NULL if still in progress |
| PRIMARY KEY | (attempt_id, skill, part) | |

time_remaining = part_duration_seconds + extended_by_seconds - (NOW() - started_at)

---

### Entity: attempt_results
Purpose: Final scored results per skill per attempt.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| attempt_id | UUID | FK → exam_attempts |
| skill | ENUM | |
| raw_score | DECIMAL | Sum of correct answers (auto-scored skills) |
| band | ENUM | A1 / A2 / B1 / B2 / C / pending / not_attempted |
| status | ENUM | pending / available / skipped |
| scored_by | ENUM | auto / human |
| scored_at | TIMESTAMP | |
| final_score_per_criterion | JSONB | For Writing/Speaking: {criterion: score} |
| final_feedback_narrative | TEXT | Teacher-confirmed feedback |
| confirmed_by | UUID | FK → users (Teacher) |
| confirmed_at | TIMESTAMP | |

---

### Entity: ai_score_drafts
Purpose: AI-generated draft scores for Writing and Speaking (not student-visible until confirmed).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| attempt_id | UUID | FK → exam_attempts |
| skill | ENUM | writing / speaking |
| part | VARCHAR(4) | |
| draft_score_per_criterion | JSONB | |
| draft_band_estimate | ENUM | A1–C |
| draft_feedback_narrative | TEXT | |
| stt_transcript | TEXT | Speaking only; from STT API |
| stt_status | ENUM | pending / completed / failed |
| llm_status | ENUM | pending / completed / failed |
| created_at | TIMESTAMP | |

---

### Entity: speaking_recordings
Purpose: Speaking audio file references per attempt per part.

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| attempt_id | UUID | FK → exam_attempts |
| part | VARCHAR(4) | A / B / C / D / E |
| asset_id | UUID | FK → assets |
| duration_seconds | DECIMAL | |
| is_partial | BOOLEAN | True if recording was interrupted (FR-109) |
| upload_status | ENUM | pending / uploaded / failed |
| local_buffer_cleared | BOOLEAN | True when local buffer confirmed uploaded |
| created_at | TIMESTAMP | |

---

### Entity: violation_events
Purpose: Immutable anti-cheat violation log (FR-101).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| attempt_id | UUID | FK → exam_attempts |
| violation_type | ENUM | tab_switch / focus_loss / fullscreen_exit / copy_paste_attempt |
| occurred_at | TIMESTAMP | |
| cumulative_count | INTEGER | Count at time of event |
| action_taken | ENUM | none / warned / terminated |

No DELETE or UPDATE on this table by any application role.

---

### Entity: exam_events
Purpose: Audit log of all coordinator interventions during exam sessions (FR-40, FR-41, FR-42, FR-43).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| session_id | UUID | FK → exam_sessions |
| attempt_id | UUID | FK → exam_attempts; NULL for session-level events |
| event_type | ENUM | time_extended / force_submitted / session_closed / retake_approved / retake_created |
| actor_user_id | UUID | FK → users (Coordinator/Teacher) |
| reason | TEXT | Required for all events |
| metadata | JSONB | e.g., {extension_minutes: 5} |
| created_at | TIMESTAMP | |

---

### Entity: notification_log
Purpose: Record of all notification sends (FR-87).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| recipient_user_id | UUID | FK → users; NULL for Guest |
| notification_type | ENUM | exam_published / result_available / review_pending / seat_warning / license_expiry / account_created / etc. |
| channel | ENUM | email / push |
| sent_at | TIMESTAMP | |
| delivery_status | ENUM | sent / failed / bounced |
| provider_response | JSONB | API response from email/push provider |
| retry_count | INTEGER | |

---

### Entity: impersonation_log
Purpose: Audit log of Support Staff impersonation sessions (FR-76).

| Column | Type | Notes |
|---|---|---|
| id | UUID | PK |
| support_user_id | UUID | FK → users |
| tenant_id | UUID | FK → tenants |
| started_at | TIMESTAMP | |
| ended_at | TIMESTAMP | NULL if still active |

---

## §3.4.2 Data Volumes (Estimates)

| Entity | Expected volume (12 months, 50 tenants) | Notes |
|---|---|---|
| tenants | ~50 | Low volume |
| users | ~50,000 | ~1000 students per tenant |
| enrollments | ~200,000 | Students in multiple courses |
| questions | ~5,000 | Vendor-managed content |
| exam_sessions | ~5,000 | ~2 sessions/week/tenant avg |
| exam_attempts | ~150,000 | ~30 students per session |
| exam_state | ~15,000,000 | ~100 answers per attempt |
| speaking_recordings | ~750,000 | 5 parts × 150,000 attempts |
| violation_events | ~500,000 | Varies widely by cohort |
| notification_log | ~3,000,000 | Multiple emails per event |

Largest tables by row count: exam_state, notification_log  
Largest tables by storage: speaking_recordings (references to audio files in Cloud Storage)

---

## §3.4.3 PII Fields Summary

| Entity | PII Field(s) | Classification | Handling |
|---|---|---|---|
| users | email, full_name | PII — identifying | Encrypted at rest (DB encryption); no plaintext in logs |
| users | password_hash | Credential | bcrypt only; never logged |
| speaking_recordings | (audio file) | PII — biometric proxy | Stored in Cloud Storage with restricted access; retention per OI-07 |
| ai_score_drafts | stt_transcript | PII — speech content | Stored in DB; access restricted to Teacher + system |
| attempt_results | final_feedback_narrative | PII — educational record | Student-facing; Teacher-written; retained per NFR-10 |
| notification_log | recipient_user_id | PII — indirect | Retain per OI-07 |

---

## §3.4.4 Retention and Purge

| Data Type | Retention Target | Purge Mechanism |
|---|---|---|
| Exam answer records (exam_state) | [TBD — OI-07] | Scheduled purge job |
| Speaking audio recordings (Cloud Storage) | [TBD — OI-07] | Cloud Storage lifecycle policy |
| STT transcripts | [TBD — OI-07] | Cascade with attempt purge |
| Violation events | [TBD — OI-07] | Scheduled purge job |
| notification_log | [TBD — OI-07] | Scheduled purge job |
| Guest/Trial data | [TBD — OI-07] | Guest purge job (FR-92) |
| Impersonation log | Permanent (audit) | No automatic purge |
| License history | Permanent (audit) | No automatic purge |

All purge jobs must: log count of purged records (no PII in purge log), be idempotent, and complete within a defined maintenance window.
