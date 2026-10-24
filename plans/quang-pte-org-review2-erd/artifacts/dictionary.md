# Dictionary ERD

Ngày: 2026-10-23. Logical detail thể hiện storage bounds từ source; logical reference không chứng minh row đích tồn tại. Thuộc tính theo bộ field thiết yếu đã chọn; inventory giữ toàn bộ metadata. Mermaid nguồn được giữ local và không commit.

## Entity

### ENT-AttemptAnswer — AttemptAnswer (AttemptAnswer)

Bảng `attempt_answers`; module `attempt`; status current-source. [AttemptAnswer.java:27](../../../../pte-api/app/src/main/java/com/pte/attempt/domain/AttemptAnswer.java#L27); [V9__attempt.sql:83](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L83).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| attempt_id | BIGINT | False | FK |
| pinned_item_id | BIGINT | False | FK |
| payload | TEXT | True | - |
| status | VARCHAR(16) | False | - |
| expired | BOOLEAN | False | - |

### ENT-AttemptHeartbeat — AttemptHeartbeat (AttemptHeartbeat)

Bảng `attempt_heartbeats`; module `attempt`; status current-source. [AttemptHeartbeat.java:34](../../../../pte-api/app/src/main/java/com/pte/attempt/domain/AttemptHeartbeat.java#L34); [V9__attempt.sql:99](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L99).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| attempt_id | BIGINT | True | UK, FK |
| last_seen_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-AttemptReport — AttemptReport (AttemptReport)

Bảng `attempt_reports`; module `reporting`; status current-source. [AttemptReport.java:23](../../../../pte-api/app/src/main/java/com/pte/reporting/domain/AttemptReport.java#L23); [V13__reporting.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V13__reporting.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| attempt_public_id | UUID | False | UK |
| session_public_id | UUID | False | - |
| student_public_id | UUID | False | - |
| tenant_id | UUID | False | - |
| published | BOOLEAN | False | - |
| published_at | TIMESTAMP WITH TIME ZONE | True | - |
| snapshot_public_id | UUID | True | - |
| report_snapshot_json | TEXT | True | - |
| publication_public_id | UUID | True | - |
| published_by_public_id | UUID | True | - |

### ENT-AttemptSecurityEvent — AttemptSecurityEvent (AttemptSecurityEvent)

Bảng `attempt_security_events`; module `attempt`; status current-source. [AttemptSecurityEvent.java:24](../../../../pte-api/app/src/main/java/com/pte/attempt/domain/AttemptSecurityEvent.java#L24); [V70__attempt_security_events.sql:4](../../../../pte-api/app/src/main/resources/db/migration/V70__attempt_security_events.sql#L4).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| attempt_id | BIGINT | False | FK |
| client_event_id | VARCHAR(128) | False | - |
| violation_type | VARCHAR(64) | False | - |
| severity | VARCHAR(16) | False | - |
| detail | TEXT | True | - |
| detected_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-AuditLog — AuditLog (AuditLog)

Bảng `audit_logs`; module `shared`; status current-source. [AuditLog.java:15](../../../../pte-api/app/src/main/java/com/pte/shared/audit/domain/AuditLog.java#L15); [V3__tenancy.sql:58](../../../../pte-api/app/src/main/resources/db/migration/V3__tenancy.sql#L58).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | True | - |
| actor_user_id | UUID | False | - |
| aggregate_type | VARCHAR(255) | False | - |
| aggregate_id | VARCHAR(255) | False | - |
| action | VARCHAR(255) | False | - |
| summary | VARCHAR(500) | False | - |
| created_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-BlueprintItem — BlueprintItem (BlueprintItem)

Bảng `blueprint_items`; module `assessment`; status current-source. [BlueprintItem.java:25](../../../../pte-api/app/src/main/java/com/pte/assessment/domain/BlueprintItem.java#L25); [V7__assessment.sql:19](../../../../pte-api/app/src/main/resources/db/migration/V7__assessment.sql#L19).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| blueprint_id | BIGINT | False | FK |
| question_public_id | UUID | False | - |
| section | VARCHAR(16) | False | - |
| order_index | INTEGER | False | - |

### ENT-ClassMembership — ClassMembership (ClassMembership)

Bảng `class_memberships`; module `enrollment`; status current-source. [ClassMembership.java:29](../../../../pte-api/app/src/main/java/com/pte/enrollment/domain/ClassMembership.java#L29); [V4__enrollment.sql:55](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L55).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| student_class_id | BIGINT | False | FK |
| student_public_id | UUID | False | UK |
| tenant_id | UUID | False | - |

### ENT-Enrollment — Enrollment (Enrollment)

Bảng `enrollments`; module `session`; status current-source. [Enrollment.java:27](../../../../pte-api/app/src/main/java/com/pte/session/domain/Enrollment.java#L27); [V8__session.sql:51](../../../../pte-api/app/src/main/resources/db/migration/V8__session.sql#L51).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_id | BIGINT | False | FK |
| student_public_id | UUID | False | - |
| tenant_id | UUID | False | - |
| license_key | VARCHAR(64) | False | - |

### ENT-ExamAttempt — ExamAttempt (ExamAttempt)

Bảng `exam_attempts`; module `attempt`; status current-source. [ExamAttempt.java:40](../../../../pte-api/app/src/main/java/com/pte/attempt/domain/ExamAttempt.java#L40); [V9__attempt.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L7).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_public_id | UUID | False | - |
| student_public_id | UUID | False | - |
| attempt_number | INTEGER | False | - |
| tenant_id | UUID | False | - |
| status | VARCHAR(16) | False | - |
| started_at | TIMESTAMP WITH TIME ZONE | True | - |
| submitted_at | TIMESTAMP WITH TIME ZONE | True | - |
| exam_end_time | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-ExamAudienceMember — ExamAudienceMember (ExamAudienceMember)

Bảng `exam_audience_members`; module `session`; status current-source. [ExamAudienceMember.java:22](../../../../pte-api/app/src/main/java/com/pte/session/domain/ExamAudienceMember.java#L22); [V42__exam_orchestration_core.sql:37](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L37).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_id | BIGINT | False | FK |
| student_public_id | UUID | False | - |
| tenant_id | UUID | False | - |
| status | VARCHAR(16) | False | - |
| reason | VARCHAR(32) | True | - |
| prior_session_public_id | UUID | True | - |

### ENT-ExamAudienceSource — ExamAudienceSource (ExamAudienceSource)

Bảng `exam_audience_sources`; module `session`; status current-source. [ExamAudienceSource.java:20](../../../../pte-api/app/src/main/java/com/pte/session/domain/ExamAudienceSource.java#L20); [V42__exam_orchestration_core.sql:21](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L21).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_id | BIGINT | False | FK |
| source_type | VARCHAR(16) | False | - |
| source_public_id | UUID | False | - |
| tenant_id | UUID | False | - |

### ENT-ExamBlueprint — ExamBlueprint (ExamBlueprint)

Bảng `exam_blueprints`; module `assessment`; status current-source. [ExamBlueprint.java:28](../../../../pte-api/app/src/main/java/com/pte/assessment/domain/ExamBlueprint.java#L28); [V7__assessment.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V7__assessment.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| name | VARCHAR(255) | False | - |
| tenant_id | UUID | True | - |
| status | VARCHAR(16) | False | - |
| version | BIGINT | False | - |

### ENT-ExamForm — ExamForm (ExamForm)

Bảng `exam_forms`; module `session`; status current-source. [ExamForm.java:15](../../../../pte-api/app/src/main/java/com/pte/session/domain/ExamForm.java#L15); [V42__exam_orchestration_core.sql:79](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L79).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_id | BIGINT | False | FK |
| snapshot_public_id | UUID | False | - |
| form_index | INTEGER | False | - |
| form_seed | BIGINT | False | - |
| algorithm_version | VARCHAR(32) | False | - |

### ENT-ExamGenerationJob — ExamGenerationJob (ExamGenerationJob)

Bảng `exam_generation_jobs`; module `session`; status current-source. [ExamGenerationJob.java:20](../../../../pte-api/app/src/main/java/com/pte/session/domain/ExamGenerationJob.java#L20); [V42__exam_orchestration_core.sql:59](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L59).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_id | BIGINT | False | FK |
| idempotency_key | VARCHAR(128) | False | - |
| tenant_id | UUID | False | - |
| status | VARCHAR(16) | False | - |
| forms_total | INTEGER | False | - |
| forms_completed | INTEGER | False | - |
| last_error | TEXT | True | - |

### ENT-ExamSessionIncidentHistory — ExamSessionIncidentHistory (ExamSessionIncidentHistory)

Bảng `exam_session_incident_history`; module `proctoring`; status current-source. [ExamSessionIncidentHistory.java:14](../../../../pte-api/app/src/main/java/com/pte/proctoring/domain/ExamSessionIncidentHistory.java#L14); [V111__proctor_identity_and_incidents.sql:64](../../../../pte-api/app/src/main/resources/db/migration/V111__proctor_identity_and_incidents.sql#L64).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| incident_id | BIGINT | False | FK |
| action | VARCHAR(64) | False | - |
| from_status | VARCHAR(32) | True | - |
| to_status | VARCHAR(32) | False | - |
| notes | TEXT | True | - |
| created_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-ExamSessionIncident — ExamSessionIncident (ExamSessionIncident)

Bảng `exam_session_incidents`; module `proctoring`; status current-source. [ExamSessionIncident.java:14](../../../../pte-api/app/src/main/java/com/pte/proctoring/domain/ExamSessionIncident.java#L14); [V111__proctor_identity_and_incidents.sql:35](../../../../pte-api/app/src/main/resources/db/migration/V111__proctor_identity_and_incidents.sql#L35).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_public_id | UUID | False | - |
| title | VARCHAR(255) | False | - |
| category | VARCHAR(64) | False | - |
| severity | VARCHAR(32) | False | - |
| status | VARCHAR(32) | False | - |
| reporter_role | VARCHAR(32) | False | - |
| current_owner_role | VARCHAR(32) | False | - |
| resolution_summary | TEXT | True | - |

### TABLE-exam_session_selected_skills — exam_session_selected_skills (exam_session_selected_skills)

Bảng `exam_session_selected_skills`; module `collection/JDBC`; status current-source. [V65__exam_scope_retry_and_attempt_numbering.sql:8](../../../../pte-api/app/src/main/resources/db/migration/V65__exam_scope_retry_and_attempt_numbering.sql#L8); [V65__exam_scope_retry_and_attempt_numbering.sql:8](../../../../pte-api/app/src/main/resources/db/migration/V65__exam_scope_retry_and_attempt_numbering.sql#L8).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| session_id | BIGINT | False | FK |
| skill | VARCHAR(16) | False | - |

### ENT-ExamSession — ExamSession (ExamSession)

Bảng `exam_sessions`; module `session`; status current-source. [ExamSession.java:41](../../../../pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java#L41); [V8__session.sql:12](../../../../pte-api/app/src/main/resources/db/migration/V8__session.sql#L12).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| snapshot_public_id | UUID | True | - |
| subscription_id | UUID | False | - |
| template_public_id | UUID | True | - |
| session_code | VARCHAR(24) | False | - |
| name | VARCHAR(255) | False | - |
| tenant_id | UUID | False | - |
| status | VARCHAR(16) | False | - |
| opens_at | TIMESTAMP WITH TIME ZONE | False | - |
| closes_at | TIMESTAMP WITH TIME ZONE | False | - |
| capacity | INTEGER | False | - |
| exam_mode | VARCHAR(16) | True | - |
| form_mode | VARCHAR(32) | True | - |
| max_retries_per_student | INTEGER | False | - |

### ENT-ExamSnapshot — ExamSnapshot (ExamSnapshot)

Bảng `exam_snapshots`; module `assessment`; status current-source. [ExamSnapshot.java:27](../../../../pte-api/app/src/main/java/com/pte/assessment/domain/ExamSnapshot.java#L27); [V7__assessment.sql:33](../../../../pte-api/app/src/main/resources/db/migration/V7__assessment.sql#L33).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| source_blueprint_public_id | UUID | False | - |
| name | VARCHAR(255) | False | - |
| version | INTEGER | False | - |
| tenant_id | UUID | True | - |
| score_template_public_id | UUID | False | - |
| score_template_version | INTEGER | False | - |

### ENT-ExaminerAnswerDraft — ExaminerAnswerDraft (ExaminerAnswerDraft)

Bảng `examiner_answer_drafts`; module `scoring`; status current-source. [ExaminerAnswerDraft.java:19](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAnswerDraft.java#L19); [V110__examiner_workflow_and_drafts.sql:26](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L26).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| work_id | BIGINT | False | FK |
| answer_public_id | UUID | False | - |
| score | INTEGER | True | - |
| comment | VARCHAR(2000) | True | - |
| decision_kind | VARCHAR(32) | True | - |
| saved_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-ExaminerAnswerScore — ExaminerAnswerScore (ExaminerAnswerScore)

Bảng `examiner_answer_scores`; module `scoring`; status current-source. [ExaminerAnswerScore.java:23](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAnswerScore.java#L23); [V58__examiner_scoring_foundation.sql:71](../../../../pte-api/app/src/main/resources/db/migration/V58__examiner_scoring_foundation.sql#L71).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| answer_public_id | UUID | False | FK |
| attempt_public_id | UUID | False | FK |
| session_public_id | UUID | False | FK |
| tenant_id | UUID | False | FK |
| examiner_public_id | UUID | False | FK |
| score | INTEGER | False | - |
| status | VARCHAR(16) | False | - |
| decision_kind | VARCHAR(32) | True | - |
| submitted_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-ExaminerAssignmentBatch — ExaminerAssignmentBatch (ExaminerAssignmentBatch)

Bảng `examiner_assignment_batches`; module `scoring`; status current-source. [ExaminerAssignmentBatch.java:21](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAssignmentBatch.java#L21); [V58__examiner_scoring_foundation.sql:30](../../../../pte-api/app/src/main/resources/db/migration/V58__examiner_scoring_foundation.sql#L30).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| session_public_id | UUID | False | - |
| mode | VARCHAR(16) | False | - |
| status | VARCHAR(16) | False | - |
| created_by_public_id | UUID | False | - |
| committed_at | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-ExaminerAttemptAssignment — ExaminerAttemptAssignment (ExaminerAttemptAssignment)

Bảng `examiner_attempt_assignments`; module `scoring`; status current-source. [ExaminerAttemptAssignment.java:19](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAttemptAssignment.java#L19); [V58__examiner_scoring_foundation.sql:51](../../../../pte-api/app/src/main/resources/db/migration/V58__examiner_scoring_foundation.sql#L51).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| batch_public_id | UUID | False | FK |
| tenant_id | UUID | False | FK |
| session_public_id | UUID | False | FK |
| attempt_public_id | UUID | False | - |
| examiner_public_id | UUID | False | - |
| assigned_by_public_id | UUID | False | - |
| assigned_at | TIMESTAMP WITH TIME ZONE | False | - |
| eligible_answer_count | INTEGER | False | - |

### ENT-ExaminerGradingCommand — ExaminerGradingCommand (ExaminerGradingCommand)

Bảng `examiner_grading_commands`; module `scoring`; status current-source. [ExaminerGradingCommand.java:19](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerGradingCommand.java#L19); [V110__examiner_workflow_and_drafts.sql:65](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L65).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| examiner_public_id | UUID | False | - |
| assignment_public_id | UUID | False | - |
| request_public_id | UUID | False | - |
| operation | VARCHAR(32) | False | - |
| created_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-ExaminerGradingEvent — ExaminerGradingEvent (ExaminerGradingEvent)

Bảng `examiner_grading_events`; module `scoring`; status current-source. [ExaminerGradingEvent.java:23](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerGradingEvent.java#L23); [V110__examiner_workflow_and_drafts.sql:49](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L49).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| work_id | BIGINT | False | FK |
| operation | VARCHAR(32) | False | - |
| work_version | BIGINT | False | - |
| occurred_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-ExaminerGradingIssue — ExaminerGradingIssue (ExaminerGradingIssue)

Bảng `examiner_grading_issues`; module `scoring`; status current-source. [ExaminerGradingIssue.java:19](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerGradingIssue.java#L19); [V110__examiner_workflow_and_drafts.sql:82](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L82).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| work_id | BIGINT | False | FK |
| type | VARCHAR(32) | False | - |
| description | VARCHAR(2000) | False | - |
| status | VARCHAR(32) | False | - |
| reported_at | TIMESTAMP WITH TIME ZONE | False | - |
| resolved_at | TIMESTAMP WITH TIME ZONE | True | - |
| resolution | VARCHAR(2000) | True | - |

### ENT-ExaminerGradingWork — ExaminerGradingWork (ExaminerGradingWork)

Bảng `examiner_grading_work`; module `scoring`; status current-source. [ExaminerGradingWork.java:19](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerGradingWork.java#L19); [V110__examiner_workflow_and_drafts.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L3).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| assignment_public_id | UUID | False | FK |
| status | VARCHAR(32) | False | - |
| started_at | TIMESTAMP WITH TIME ZONE | True | - |
| finalized_at | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-FormAssignment — FormAssignment (FormAssignment)

Bảng `form_assignments`; module `session`; status current-source. [FormAssignment.java:17](../../../../pte-api/app/src/main/java/com/pte/session/domain/FormAssignment.java#L17); [V42__exam_orchestration_core.sql:94](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L94).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_id | BIGINT | False | FK |
| form_id | BIGINT | False | FK |
| student_public_id | UUID | False | - |

### ENT-LecturerAssignment — LecturerAssignment (LecturerAssignment)

Bảng `lecturer_assignments`; module `enrollment`; status current-source. [LecturerAssignment.java:26](../../../../pte-api/app/src/main/java/com/pte/enrollment/domain/LecturerAssignment.java#L26); [V4__enrollment.sql:69](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L69).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| student_class_id | BIGINT | False | FK |
| assignee_public_id | UUID | False | - |
| tenant_id | UUID | False | - |

### ENT-LicenseCode — LicenseCode (LicenseCode)

Bảng `license_codes`; module `billing`; status current-source. [LicenseCode.java:18](../../../../pte-api/app/src/main/java/com/pte/billing/domain/LicenseCode.java#L18); [V25__billing_license_code.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V25__billing_license_code.sql#L5).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| plan_id | UUID | False | - |
| redeemed_by_tenant_id | UUID | True | - |
| subscription_id | UUID | True | UK |
| code | VARCHAR(32) | False | UK |
| status | VARCHAR(16) | False | - |
| issued_at | TIMESTAMP WITH TIME ZONE | False | - |
| code_expires_at | TIMESTAMP WITH TIME ZONE | True | - |
| redeemed_at | TIMESTAMP WITH TIME ZONE | True | - |
| revoke_reason | VARCHAR(255) | True | - |

### ENT-LicenseIssueIntent — LicenseIssueIntent (LicenseIssueIntent)

Bảng `license_issue_intents`; module `billing`; status current-source. [LicenseIssueIntent.java:13](../../../../pte-api/app/src/main/java/com/pte/billing/domain/LicenseIssueIntent.java#L13); [V79__license_issue_intents.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V79__license_issue_intents.sql#L1).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGSERIAL | False | PK |
| public_id | UUID | False | UK |
| actor_public_id | UUID | False | - |
| operation | VARCHAR(64) | False | - |
| idempotency_key | UUID | False | - |
| license_code_public_id | UUID | False | FK |

### ENT-LoginHash — LoginHash (LoginHash)

Bảng `login_hashes`; module `identity`; status current-source. [LoginHash.java:16](../../../../pte-api/app/src/main/java/com/pte/identity/internal/domain/LoginHash.java#L16); [V2__identity.sql:45](../../../../pte-api/app/src/main/resources/db/migration/V2__identity.sql#L45).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| user_id | BIGINT | False | UK |
| hash | VARCHAR(255) | False | - |

### ENT-MediaObject — MediaObject (MediaObject)

Bảng `media_objects`; module `media`; status current-source. [MediaObject.java:23](../../../../pte-api/app/src/main/java/com/pte/media/domain/MediaObject.java#L23); [V5__media.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V5__media.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| practice_session_public_id | UUID | True | - |
| practice_item_public_id | UUID | True | - |
| owner_public_id | UUID | False | - |
| content_type | VARCHAR(255) | False | - |
| storage_key | VARCHAR(255) | False | UK |
| status | VARCHAR(32) | False | - |
| size_bytes | BIGINT | True | - |
| duration_seconds | INTEGER | True | - |
| purpose | VARCHAR(64) | True | - |

### ENT-InboxAnnouncement — InboxAnnouncement (InboxAnnouncement)

Bảng `notification_inbox_announcements`; module `notification`; status current-source. [InboxAnnouncement.java:18](../../../../pte-api/app/src/main/java/com/pte/notification/domain/InboxAnnouncement.java#L18); [V72__notification_inbox_foundation.sql:21](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L21).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| author_user_public_id | UUID | False | FK |
| published_content_public_id | UUID | True | UK, FK |
| correction_of_public_id | UUID | True | FK |
| title | VARCHAR(150) | False | - |
| body | VARCHAR(5000) | False | - |
| category | VARCHAR(32) | False | - |
| importance | VARCHAR(16) | False | - |
| affected_from | TIMESTAMPTZ | True | - |
| affected_until | TIMESTAMPTZ | True | - |
| published_at | TIMESTAMPTZ | True | - |

### ENT-InboxContent — InboxContent (InboxContent)

Bảng `notification_inbox_contents`; module `notification`; status current-source. [InboxContent.java:18](../../../../pte-api/app/src/main/java/com/pte/notification/domain/InboxContent.java#L18); [V72__notification_inbox_foundation.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L3).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| notification_type | VARCHAR(48) | False | - |
| category | VARCHAR(32) | False | - |
| importance | VARCHAR(16) | False | - |
| title | VARCHAR(150) | False | - |
| body | VARCHAR(5000) | False | - |
| target_type | VARCHAR(32) | False | - |
| target_public_id | UUID | False | - |

### ENT-InboxDeliveryIntent — InboxDeliveryIntent (InboxDeliveryIntent)

Bảng `notification_inbox_deliveries`; module `notification`; status current-source. [InboxDeliveryIntent.java:16](../../../../pte-api/app/src/main/java/com/pte/notification/domain/InboxDeliveryIntent.java#L16); [V72__notification_inbox_foundation.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L42).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| content_public_id | UUID | False | FK |
| recipient_user_public_id | UUID | False | FK |
| tenant_id | UUID | True | FK |
| status | VARCHAR(16) | False | - |
| attempts | INTEGER | False | - |
| next_attempt_at | TIMESTAMPTZ | False | - |
| completed_at | TIMESTAMPTZ | True | - |
| last_failure_code | VARCHAR(64) | True | - |

### ENT-InboxItem — InboxItem (InboxItem)

Bảng `notification_inbox_items`; module `notification`; status current-source. [InboxItem.java:13](../../../../pte-api/app/src/main/java/com/pte/notification/domain/InboxItem.java#L13); [V72__notification_inbox_foundation.sql:78](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L78).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| delivery_public_id | UUID | False | UK, FK |
| content_public_id | UUID | False | FK |
| recipient_user_public_id | UUID | False | FK |
| tenant_id | UUID | True | FK |
| sequence_no | BIGINT | False | - |
| delivered_at | TIMESTAMPTZ | False | - |
| read_at | TIMESTAMPTZ | True | - |

### TABLE-notification_inbox_snapshots — notification_inbox_snapshots (notification_inbox_snapshots)

Bảng `notification_inbox_snapshots`; module `collection/JDBC`; status current-source. [V73__notification_inbox_snapshots.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V73__notification_inbox_snapshots.sql#L3); [V73__notification_inbox_snapshots.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V73__notification_inbox_snapshots.sql#L3).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| recipient_user_public_id | UUID | False | FK |
| tenant_id | UUID | True | FK |
| upper_sequence | BIGINT | False | - |
| read_revision | BIGINT | False | - |
| expires_at | TIMESTAMPTZ | False | - |

### ENT-InboxRecipientStream — InboxRecipientStream (InboxRecipientStream)

Bảng `notification_inbox_streams`; module `notification`; status current-source. [InboxRecipientStream.java:12](../../../../pte-api/app/src/main/java/com/pte/notification/domain/InboxRecipientStream.java#L12); [V72__notification_inbox_foundation.sql:66](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L66).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| recipient_user_public_id | UUID | False | UK, FK |
| tenant_id | UUID | True | FK |
| last_sequence | BIGINT | False | - |
| read_revision | BIGINT | False | - |

### ENT-NotificationLog — NotificationLog (NotificationLog)

Bảng `notification_logs`; module `notification`; status current-source. [NotificationLog.java:20](../../../../pte-api/app/src/main/java/com/pte/notification/domain/NotificationLog.java#L20); [V12__notification.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V12__notification.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| recipient_user_public_id | UUID | True | - |
| recipient_email | VARCHAR(255) | False | - |
| notification_type | VARCHAR(32) | False | - |
| subject | VARCHAR(255) | False | - |
| status | VARCHAR(16) | False | - |
| sent_at | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-Order — Order (Order)

Bảng `orders`; module `billing`; status current-source. [Order.java:19](../../../../pte-api/app/src/main/java/com/pte/billing/domain/Order.java#L19); [V24__billing_order_payment.sql:13](../../../../pte-api/app/src/main/resources/db/migration/V24__billing_order_payment.sql#L13).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| plan_id | UUID | False | - |
| order_code | BIGINT | False | UK |
| amount | NUMERIC(19, 2) | False | - |
| currency | VARCHAR(3) | False | - |
| status | VARCHAR(16) | False | - |
| paid_at | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-Organization — Organization (Organization)

Bảng `organizations`; module `tenancy`; status current-source. [Organization.java:25](../../../../pte-api/app/src/main/java/com/pte/tenancy/domain/Organization.java#L25); [V3__tenancy.sql:27](../../../../pte-api/app/src/main/resources/db/migration/V3__tenancy.sql#L27).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | BIGINT | False | FK |
| name | VARCHAR(255) | False | - |
| address | VARCHAR(255) | True | - |
| facility_type | VARCHAR(32) | False | - |
| status | VARCHAR(32) | False | - |

### ENT-PaymentTransaction — PaymentTransaction (PaymentTransaction)

Bảng `payment_transactions`; module `billing`; status current-source. [PaymentTransaction.java:14](../../../../pte-api/app/src/main/java/com/pte/billing/domain/PaymentTransaction.java#L14); [V24__billing_order_payment.sql:41](../../../../pte-api/app/src/main/resources/db/migration/V24__billing_order_payment.sql#L41).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| order_code | BIGINT | True | - |
| signature_valid | BOOLEAN | False | - |
| received_at | TIMESTAMP WITH TIME ZONE | False | - |
| processed | BOOLEAN | False | - |

### ENT-PinnedExamSnapshot — PinnedExamSnapshot (PinnedExamSnapshot)

Bảng `pinned_exam_snapshots`; module `attempt`; status current-source. [PinnedExamSnapshot.java:28](../../../../pte-api/app/src/main/java/com/pte/attempt/domain/PinnedExamSnapshot.java#L28); [V9__attempt.sql:33](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L33).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| attempt_id | BIGINT | True | UK, FK |
| source_snapshot_public_id | UUID | False | - |
| source_session_public_id | UUID | False | - |
| tenant_id | UUID | False | - |
| score_template_public_id | UUID | False | - |
| score_template_version | INTEGER | True | - |
| exam_mode | VARCHAR(16) | False | - |

### ENT-PinnedItem — PinnedItem (PinnedItem)

Bảng `pinned_items`; module `attempt`; status current-source. [PinnedItem.java:25](../../../../pte-api/app/src/main/java/com/pte/attempt/domain/PinnedItem.java#L25); [V9__attempt.sql:51](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L51).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| pinned_snapshot_id | BIGINT | False | FK |
| task_type_key | VARCHAR(64) | False | FK |
| section | VARCHAR(16) | False | - |
| order_index | INTEGER | False | - |
| title | VARCHAR(255) | False | - |
| prompt_text | TEXT | True | - |
| correct_answer_text | TEXT | True | - |
| options_json | TEXT | True | - |
| prep_seconds | INTEGER | False | - |
| response_seconds | INTEGER | False | - |

### ENT-Plan — Plan (Plan)

Bảng `plans`; module `billing`; status current-source. [Plan.java:25](../../../../pte-api/app/src/main/java/com/pte/billing/domain/Plan.java#L25); [V22__billing_plan_catalog.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V22__billing_plan_catalog.sql#L7).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| name | VARCHAR(255) | False | - |
| type | VARCHAR(32) | False | - |
| price | NUMERIC(19, 2) | False | - |
| currency | VARCHAR(3) | False | - |
| duration_days | INTEGER | True | - |
| max_students_per_session | INTEGER | True | - |
| status | VARCHAR(32) | False | - |

### ENT-PlatformSetting — PlatformSetting (PlatformSetting)

Bảng `platform_settings`; module `billing`; status current-source. [PlatformSetting.java:16](../../../../pte-api/app/src/main/java/com/pte/billing/domain/PlatformSetting.java#L16); [V22__billing_plan_catalog.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V22__billing_plan_catalog.sql#L42).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| setting_key | VARCHAR(100) | False | UK |
| value | VARCHAR(255) | False | - |
| description | VARCHAR(255) | True | - |

### ENT-PracticeEmailChallenge — PracticeEmailChallenge (PracticeEmailChallenge)

Bảng `practice_email_challenges`; module `practice`; status current-source. [PracticeEmailChallenge.java:16](../../../../pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeEmailChallenge.java#L16); [V82__practice_identity_and_entitlement.sql:41](../../../../pte-api/app/src/main/resources/db/migration/V82__practice_identity_and_entitlement.sql#L41).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| identity_id | BIGINT | False | FK |
| code_hash | VARCHAR(255) | False | - |
| expires_at | TIMESTAMP WITH TIME ZONE | False | - |
| consumed_at | TIMESTAMP WITH TIME ZONE | True | - |
| failed_attempts | INTEGER | False | - |

### ENT-PracticeExplanationJob — PracticeExplanationJob (PracticeExplanationJob)

Bảng `practice_explanation_jobs`; module `practice`; status current-source. [PracticeExplanationJob.java:20](../../../../pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeExplanationJob.java#L20); [V120__practice_explanation_durable_jobs.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V120__practice_explanation_durable_jobs.sql#L7).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGSERIAL | False | PK |
| public_id | UUID | False | UK |
| explanation_id | BIGINT | False | FK |
| status | VARCHAR(16) | False | - |
| attempt_count | INTEGER | False | - |
| next_attempt_at | TIMESTAMPTZ | False | - |
| last_failure_code | VARCHAR(64) | True | - |
| idempotency_key | VARCHAR(128) | True | - |

### ENT-PracticeExplanationOutbox — PracticeExplanationOutbox (PracticeExplanationOutbox)

Bảng `practice_explanation_outbox`; module `practice`; status current-source. [PracticeExplanationOutbox.java:15](../../../../pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeExplanationOutbox.java#L15); [V120__practice_explanation_durable_jobs.sql:37](../../../../pte-api/app/src/main/resources/db/migration/V120__practice_explanation_durable_jobs.sql#L37).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGSERIAL | False | PK |
| public_id | UUID | False | UK |
| job_id | BIGINT | False | FK |
| attempts | INTEGER | False | - |
| next_attempt_at | TIMESTAMPTZ | False | - |
| published_at | TIMESTAMPTZ | True | - |
| last_failure_code | VARCHAR(64) | True | - |

### ENT-PracticeExplanation — PracticeExplanation (PracticeExplanation)

Bảng `practice_explanations`; module `practice`; status current-source. [PracticeExplanation.java:20](../../../../pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeExplanation.java#L20); [V119__practice_explanation_snapshots.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V119__practice_explanation_snapshots.sql#L1).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGSERIAL | False | PK |
| public_id | UUID | False | UK |
| practice_session_item_id | BIGINT | False | FK |
| language | VARCHAR(5) | False | - |
| generation_sequence | INTEGER | False | - |
| status | VARCHAR(16) | False | - |
| summary | TEXT | True | - |
| strengths_json | TEXT | True | - |
| improvements_json | TEXT | True | - |
| rubric_feedback_json | TEXT | True | - |
| generated_at | TIMESTAMPTZ | True | - |
| failure_code | VARCHAR(64) | True | - |

### ENT-PracticeIdentity — PracticeIdentity (PracticeIdentity)

Bảng `practice_identities`; module `identity`; status current-source. [PracticeIdentity.java:18](../../../../pte-api/app/src/main/java/com/pte/identity/internal/domain/PracticeIdentity.java#L18); [V82__practice_identity_and_entitlement.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V82__practice_identity_and_entitlement.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| shell_user_id | BIGINT | True | FK |
| normalized_email_hash | VARCHAR(64) | False | UK |
| status | VARCHAR(16) | False | - |
| verified_at | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-PracticeIdentityMembership — PracticeIdentityMembership (PracticeIdentityMembership)

Bảng `practice_identity_memberships`; module `identity`; status current-source. [PracticeIdentityMembership.java:19](../../../../pte-api/app/src/main/java/com/pte/identity/internal/domain/PracticeIdentityMembership.java#L19); [V82__practice_identity_and_entitlement.sql:21](../../../../pte-api/app/src/main/resources/db/migration/V82__practice_identity_and_entitlement.sql#L21).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| identity_id | BIGINT | False | FK |
| user_public_id | UUID | False | - |
| status | VARCHAR(16) | False | - |
| linked_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-PracticeSessionAttemptLink — PracticeSessionAttemptLink (PracticeSessionAttemptLink)

Bảng `practice_session_attempts`; module `practice`; status current-source. [PracticeSessionAttemptLink.java:23](../../../../pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeSessionAttemptLink.java#L23); [V83__practice_catalog_and_session_boundary.sql:39](../../../../pte-api/app/src/main/resources/db/migration/V83__practice_catalog_and_session_boundary.sql#L39).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| practice_session_id | BIGINT | False | FK |
| exam_attempt_public_id | UUID | False | - |
| source_type | VARCHAR(16) | False | - |

### ENT-PracticeSessionItem — PracticeSessionItem (PracticeSessionItem)

Bảng `practice_session_items`; module `practice`; status current-source. [PracticeSessionItem.java:27](../../../../pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeSessionItem.java#L27); [V84__practice_session_items_and_activity.sql:8](../../../../pte-api/app/src/main/resources/db/migration/V84__practice_session_items_and_activity.sql#L8).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| practice_session_id | BIGINT | False | FK |
| order_index | INTEGER | False | - |
| source_question_public_id | UUID | True | - |
| rubric_revision_public_id | UUID | True | - |
| task_code | VARCHAR(64) | False | - |
| section | VARCHAR(32) | False | - |
| status | VARCHAR(16) | False | - |
| saved_payload | TEXT | True | - |
| answered_at | TIMESTAMP WITH TIME ZONE | True | - |
| skipped_at | TIMESTAMP WITH TIME ZONE | True | - |
| objective_score | INTEGER | True | - |
| ai_score | INTEGER | True | - |
| ai_score_status | VARCHAR(32) | True | - |

### ENT-PracticeSessionOperation — PracticeSessionOperation (PracticeSessionOperation)

Bảng `practice_session_operations`; module `practice`; status current-source. [PracticeSessionOperation.java:17](../../../../pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeSessionOperation.java#L17); [V83__practice_catalog_and_session_boundary.sql:58](../../../../pte-api/app/src/main/resources/db/migration/V83__practice_catalog_and_session_boundary.sql#L58).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| practice_session_id | BIGINT | False | FK |
| operation_type | VARCHAR(16) | False | - |
| idempotency_key | VARCHAR(128) | False | - |

### ENT-PracticeSession — PracticeSession (PracticeSession)

Bảng `practice_sessions`; module `practice`; status current-source. [PracticeSession.java:25](../../../../pte-api/app/src/main/java/com/pte/practice/internal/domain/PracticeSession.java#L25); [V83__practice_catalog_and_session_boundary.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V83__practice_catalog_and_session_boundary.sql#L5).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| student_public_id | UUID | False | - |
| identity_public_id | UUID | False | - |
| start_idempotency_key | VARCHAR(128) | False | - |
| product_code | VARCHAR(64) | False | - |
| title | VARCHAR(128) | False | - |
| time_limit_seconds | INTEGER | False | - |
| selected_task_types | TEXT | True | - |
| source_type | VARCHAR(16) | False | - |
| status | VARCHAR(16) | False | - |
| started_at | TIMESTAMP WITH TIME ZONE | True | - |
| deadline_at | TIMESTAMP WITH TIME ZONE | True | - |
| completed_at | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-ProctorAssignment — ProctorAssignment (ProctorAssignment)

Bảng `proctor_assignments`; module `session`; status current-source. [ProctorAssignment.java:22](../../../../pte-api/app/src/main/java/com/pte/session/domain/ProctorAssignment.java#L22); [V8__session.sql:65](../../../../pte-api/app/src/main/resources/db/migration/V8__session.sql#L65).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_id | BIGINT | False | FK |
| proctor_public_id | UUID | False | - |
| tenant_id | UUID | False | - |
| role | VARCHAR(32) | True | - |

### ENT-ProctorSession — ProctorSession (ProctorSession)

Bảng `proctor_sessions`; module `proctoring`; status current-source. [ProctorSession.java:26](../../../../pte-api/app/src/main/java/com/pte/proctoring/domain/ProctorSession.java#L26); [V11__proctoring.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V11__proctoring.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_public_id | UUID | False | - |
| status | VARCHAR(16) | False | - |
| opened_at | TIMESTAMP WITH TIME ZONE | False | - |
| closed_at | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-Program — Program (Program)

Bảng `programs`; module `enrollment`; status current-source. [Program.java:28](../../../../pte-api/app/src/main/java/com/pte/enrollment/domain/Program.java#L28); [V4__enrollment.sql:26](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L26).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| organization_id | BIGINT | False | FK |
| name | VARCHAR(255) | False | - |
| start_date | DATE | True | - |
| end_date | DATE | True | - |
| status | VARCHAR(32) | False | - |

### ENT-QuestionOption — QuestionOption (QuestionOption)

Bảng `question_options`; module `itembank`; status current-source. [QuestionOption.java:25](../../../../pte-api/app/src/main/java/com/pte/itembank/domain/QuestionOption.java#L25); [V6__itembank.sql:30](../../../../pte-api/app/src/main/resources/db/migration/V6__itembank.sql#L30).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| question_id | BIGINT | False | FK |
| text | TEXT | False | - |
| correct | BOOLEAN | False | - |
| order_index | INTEGER | False | - |
| blank_index | INTEGER | True | - |
| correct_gap_index | INTEGER | True | - |

### ENT-QuestionTypeDefinition — QuestionTypeDefinition (QuestionTypeDefinition)

Bảng `question_types`; module `itembank`; status current-source. [QuestionTypeDefinition.java:25](../../../../pte-api/app/src/main/java/com/pte/itembank/domain/QuestionTypeDefinition.java#L25); [V37__question_type_catalog.sql:4](../../../../pte-api/app/src/main/resources/db/migration/V37__question_type_catalog.sql#L4).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| code | VARCHAR(64) | False | UK |
| task_type_key | VARCHAR(64) | False | - |
| normalized_display_name | VARCHAR(128) | False | - |
| screen_key | VARCHAR(96) | True | - |
| runtime_profile_version | INTEGER | True | - |
| display_name | VARCHAR(128) | False | - |
| section | VARCHAR(16) | False | - |
| scored | BOOLEAN | False | - |
| active | BOOLEAN | False | - |
| lifecycle_status | VARCHAR(16) | False | - |

### ENT-Question — Question (Question)

Bảng `questions`; module `itembank`; status current-source. [Question.java:32](../../../../pte-api/app/src/main/java/com/pte/itembank/domain/Question.java#L32); [V6__itembank.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V6__itembank.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| pte_task_type | VARCHAR(64) | True | FK |
| audio_prompt_ref | UUID | True | - |
| image_prompt_ref | UUID | True | - |
| task_type_key | VARCHAR(64) | False | FK |
| title | VARCHAR(255) | False | - |
| prompt_text | TEXT | True | - |
| reference_answer_text | TEXT | True | - |
| correct_answer_text | TEXT | True | - |
| task_type_section | VARCHAR(16) | False | - |
| tenant_id | UUID | True | - |
| author_user_public_id | UUID | True | - |
| visibility | VARCHAR(16) | False | - |
| status | VARCHAR(16) | False | - |
| revision_number | INTEGER | False | - |
| is_current | BOOLEAN | False | - |
| available_for_practice | BOOLEAN | False | - |
| available_for_exam | BOOLEAN | False | - |

### ENT-QuotaTransaction — QuotaTransaction (QuotaTransaction)

Bảng `quota_transactions`; module `tenancy`; status current-source. [QuotaTransaction.java:31](../../../../pte-api/app/src/main/java/com/pte/tenancy/domain/QuotaTransaction.java#L31); [V3__tenancy.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V3__tenancy.sql#L42).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | BIGINT | False | FK |
| actor_user_id | UUID | False | - |
| package_name | VARCHAR(255) | False | - |
| amount | INTEGER | False | - |
| action_type | VARCHAR(32) | False | - |
| created_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-RefreshToken — RefreshToken (RefreshToken)

Bảng `refresh_tokens`; module `identity`; status current-source. [RefreshToken.java:19](../../../../pte-api/app/src/main/java/com/pte/identity/internal/domain/RefreshToken.java#L19); [V2__identity.sql:55](../../../../pte-api/app/src/main/resources/db/migration/V2__identity.sql#L55).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| user_id | BIGINT | False | - |
| token_hash | VARCHAR(255) | False | UK |
| expires_at | TIMESTAMP WITH TIME ZONE | False | - |
| revoked | BOOLEAN | False | - |

### ENT-RubricCriterion — RubricCriterion (RubricCriterion)

Bảng `rubric_criteria`; module `rubric`; status current-source. [RubricCriterion.java:21](../../../../pte-api/app/src/main/java/com/pte/rubric/domain/RubricCriterion.java#L21); [V122__academic_rubric_revisions.sql:30](../../../../pte-api/app/src/main/resources/db/migration/V122__academic_rubric_revisions.sql#L30).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGSERIAL | False | PK |
| public_id | UUID | False | UK |
| revision_id | BIGINT | False | FK |
| criterion_id | VARCHAR(64) | False | - |
| sequence | INTEGER | False | - |
| required | BOOLEAN | False | - |
| applicability | VARCHAR(32) | False | - |

### ENT-RubricCriterionLevel — RubricCriterionLevel (RubricCriterionLevel)

Bảng `rubric_criterion_levels`; module `rubric`; status current-source. [RubricCriterionLevel.java:14](../../../../pte-api/app/src/main/java/com/pte/rubric/domain/RubricCriterionLevel.java#L14); [V122__academic_rubric_revisions.sql:45](../../../../pte-api/app/src/main/resources/db/migration/V122__academic_rubric_revisions.sql#L45).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGSERIAL | False | PK |
| public_id | UUID | False | UK |
| criterion_id | BIGINT | False | FK |
| level_key | VARCHAR(32) | False | - |
| level_order | INTEGER | False | - |
| label_en | VARCHAR(128) | False | - |
| descriptor | TEXT | False | - |

### ENT-RubricRevision — RubricRevision (RubricRevision)

Bảng `rubric_revisions`; module `rubric`; status current-source. [RubricRevision.java:28](../../../../pte-api/app/src/main/java/com/pte/rubric/domain/RubricRevision.java#L28); [V122__academic_rubric_revisions.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V122__academic_rubric_revisions.sql#L1).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGSERIAL | False | PK |
| public_id | UUID | False | UK |
| rubric_key | VARCHAR(128) | False | - |
| task_type_key | VARCHAR(64) | False | - |
| version | INTEGER | False | - |
| name | VARCHAR(255) | False | - |
| channel | VARCHAR(16) | False | - |
| status | VARCHAR(24) | False | - |
| submitted_at | TIMESTAMPTZ | True | - |
| published_at | TIMESTAMPTZ | True | - |
| retired_at | TIMESTAMPTZ | True | - |

### ENT-ScoreSourceAudit — ScoreSourceAudit (ScoreSourceAudit)

Bảng `score_source_audits`; module `scoring`; status current-source. [ScoreSourceAudit.java:22](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ScoreSourceAudit.java#L22); [V58__examiner_scoring_foundation.sql:93](../../../../pte-api/app/src/main/resources/db/migration/V58__examiner_scoring_foundation.sql#L93).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| session_public_id | UUID | False | - |
| request_public_id | UUID | True | - |
| scope | VARCHAR(16) | False | - |
| scope_value | VARCHAR(128) | True | - |
| selected_source | VARCHAR(16) | False | - |
| affected_answer_count | INTEGER | False | - |
| occurred_at | TIMESTAMP WITH TIME ZONE | False | - |

### ENT-ScoreTemplateItem — ScoreTemplateItem (ScoreTemplateItem)

Bảng `score_template_items`; module `scoretemplate`; status current-source. [ScoreTemplateItem.java:40](../../../../pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplateItem.java#L40); [V14__score_template.sql:33](../../../../pte-api/app/src/main/resources/db/migration/V14__score_template.sql#L33).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| template_id | BIGINT | False | FK |
| task_type_key | VARCHAR(64) | False | - |
| section | VARCHAR(16) | False | - |
| sequence | INTEGER | False | - |
| min_count | INTEGER | False | - |
| max_count | INTEGER | False | - |
| prep_seconds | INTEGER | False | - |
| response_seconds | INTEGER | False | - |
| scoring_method | VARCHAR(16) | False | - |
| overall_weight | NUMERIC(5, 2) | False | - |
| speaking_weight | NUMERIC(5, 2) | False | - |
| writing_weight | NUMERIC(5, 2) | False | - |
| reading_weight | NUMERIC(5, 2) | False | - |
| listening_weight | NUMERIC(5, 2) | False | - |

### ENT-ScoreTemplate — ScoreTemplate (ScoreTemplate)

Bảng `score_templates`; module `scoretemplate`; status current-source. [ScoreTemplate.java:35](../../../../pte-api/app/src/main/java/com/pte/scoretemplate/domain/ScoreTemplate.java#L35); [V14__score_template.sql:9](../../../../pte-api/app/src/main/resources/db/migration/V14__score_template.sql#L9).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| code | VARCHAR(64) | False | - |
| version | INTEGER | False | - |
| name | VARCHAR(255) | False | - |
| status | VARCHAR(16) | False | - |
| template_policy | VARCHAR(16) | False | - |
| author_user_public_id | UUID | True | - |

### ENT-ScoringAnswerAiDetail — ScoringAnswerAiDetail (ScoringAnswerAiDetail)

Bảng `scoring_answer_ai_details`; module `scoring`; status current-source. [ScoringAnswerAiDetail.java:21](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ScoringAnswerAiDetail.java#L21); [V113__ai_scoring_dispatch_and_detail.sql:10](../../../../pte-api/app/src/main/resources/db/migration/V113__ai_scoring_dispatch_and_detail.sql#L10).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| answer_public_id | UUID | False | - |
| criteria_scores_json | TEXT | True | - |
| feedback | TEXT | True | - |
| transcript | TEXT | True | - |
| fallback | BOOLEAN | False | - |
| failure_reason | VARCHAR(40) | True | - |

### ENT-ScoringAnswer — ScoringAnswer (ScoringAnswer)

Bảng `scoring_answers`; module `scoring`; status current-source. [ScoringAnswer.java:33](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ScoringAnswer.java#L33); [V10__scoring.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V10__scoring.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| answer_public_id | UUID | False | UK, FK |
| attempt_public_id | UUID | False | FK |
| session_public_id | UUID | False | FK |
| tenant_id | UUID | False | FK |
| selected_examiner_score_public_id | UUID | True | FK |
| pinned_item_public_id | UUID | False | - |
| score_template_public_id | UUID | False | - |
| task_type | VARCHAR(64) | False | - |
| status | VARCHAR(16) | False | - |
| raw_score | INTEGER | True | - |
| scored_at | TIMESTAMP WITH TIME ZONE | True | - |
| teacher_score | INTEGER | True | - |
| selected_score_source | VARCHAR(16) | True | - |
| selected_score_source_at | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-ScoringSessionState — ScoringSessionState (ScoringSessionState)

Bảng `scoring_session_states`; module `scoring`; status current-source. [ScoringSessionState.java:18](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/ScoringSessionState.java#L18); [V58__examiner_scoring_foundation.sql:115](../../../../pte-api/app/src/main/resources/db/migration/V58__examiner_scoring_foundation.sql#L115).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| session_public_id | UUID | False | - |
| publication_public_id | UUID | True | - |
| publication_locked_at | TIMESTAMP WITH TIME ZONE | True | - |

### ENT-SessionAttendanceCommand — SessionAttendanceCommand (SessionAttendanceCommand)

Bảng `session_attendance_commands`; module `session`; status current-source. [SessionAttendanceCommand.java:22](../../../../pte-api/app/src/main/java/com/pte/session/domain/SessionAttendanceCommand.java#L22); [V109__session_attendance_and_roster.sql:34](../../../../pte-api/app/src/main/resources/db/migration/V109__session_attendance_and_roster.sql#L34).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| session_id | BIGINT | False | FK |
| actor_public_id | UUID | False | - |
| request_public_id | UUID | False | - |
| enrollment_public_id | UUID | False | - |
| previous_status | VARCHAR(32) | False | - |
| new_status | VARCHAR(32) | False | - |
| server_action_at | TIMESTAMP WITH TIME ZONE | False | - |
| changed | BOOLEAN | False | - |

### ENT-SessionAttendance — SessionAttendance (SessionAttendance)

Bảng `session_attendances`; module `session`; status current-source. [SessionAttendance.java:22](../../../../pte-api/app/src/main/java/com/pte/session/domain/SessionAttendance.java#L22); [V109__session_attendance_and_roster.sql:12](../../../../pte-api/app/src/main/resources/db/migration/V109__session_attendance_and_roster.sql#L12).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_id | BIGINT | False | FK |
| student_public_id | UUID | False | - |
| status | VARCHAR(32) | False | - |
| identity_status | VARCHAR(32) | False | - |
| last_action_at | TIMESTAMP WITH TIME ZONE | False | - |
| identity_note | VARCHAR(1000) | True | - |

### ENT-SessionClassAssignment — SessionClassAssignment (SessionClassAssignment)

Bảng `session_class_assignments`; module `session`; status current-source. [SessionClassAssignment.java:25](../../../../pte-api/app/src/main/java/com/pte/session/domain/SessionClassAssignment.java#L25); [V20__session_class_assignment.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V20__session_class_assignment.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| session_id | BIGINT | False | FK |
| class_public_id | UUID | False | - |
| tenant_id | UUID | False | - |

### ENT-GradingCohortMember — GradingCohortMember (GradingCohortMember)

Bảng `session_grading_cohort_members`; module `scoring`; status current-source. [GradingCohortMember.java:17](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/GradingCohortMember.java#L17); [V75__session_grading_cohort.sql:28](../../../../pte-api/app/src/main/resources/db/migration/V75__session_grading_cohort.sql#L28).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| cohort_public_id | UUID | False | FK |
| attempt_public_id | UUID | False | - |
| attempt_status_snapshot | VARCHAR(16) | False | - |
| excluded | BOOLEAN | False | - |
| disposition_reason | VARCHAR(500) | True | - |

### ENT-GradingCohort — GradingCohort (GradingCohort)

Bảng `session_grading_cohorts`; module `scoring`; status current-source. [GradingCohort.java:23](../../../../pte-api/app/src/main/java/com/pte/scoring/domain/GradingCohort.java#L23); [V75__session_grading_cohort.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V75__session_grading_cohort.sql#L3).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| session_public_id | UUID | False | - |
| marking_mode | VARCHAR(24) | False | - |
| status | VARCHAR(16) | False | - |
| cohort_version | BIGINT | False | - |
| frozen_at | TIMESTAMPTZ | False | - |
| completed_at | TIMESTAMPTZ | True | - |

### ENT-SessionIdentityVerificationCommand — SessionIdentityVerificationCommand (SessionIdentityVerificationCommand)

Bảng `session_identity_verification_commands`; module `session`; status current-source. [SessionIdentityVerificationCommand.java:19](../../../../pte-api/app/src/main/java/com/pte/session/domain/SessionIdentityVerificationCommand.java#L19); [V111__proctor_identity_and_incidents.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V111__proctor_identity_and_incidents.sql#L7).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| session_id | BIGINT | False | FK |
| actor_public_id | UUID | False | - |
| request_public_id | UUID | False | - |
| enrollment_public_id | UUID | False | - |
| previous_status | VARCHAR(32) | False | - |
| new_status | VARCHAR(32) | False | - |
| note | VARCHAR(1000) | True | - |
| server_action_at | TIMESTAMP WITH TIME ZONE | False | - |
| changed | BOOLEAN | False | - |

### ENT-SnapshotItem — SnapshotItem (SnapshotItem)

Bảng `snapshot_items`; module `assessment`; status current-source. [SnapshotItem.java:29](../../../../pte-api/app/src/main/java/com/pte/assessment/domain/SnapshotItem.java#L29); [V7__assessment.sql:47](../../../../pte-api/app/src/main/resources/db/migration/V7__assessment.sql#L47).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| snapshot_id | BIGINT | False | FK |
| source_question_public_id | UUID | False | - |
| task_type_key | VARCHAR(64) | False | FK |
| section | VARCHAR(16) | False | - |
| order_index | INTEGER | False | - |
| title | VARCHAR(255) | False | - |
| prompt_text | TEXT | True | - |
| correct_answer_text | TEXT | True | - |
| options_json | TEXT | True | - |

### ENT-StudentClass — StudentClass (StudentClass)

Bảng `student_classes`; module `enrollment`; status current-source. [StudentClass.java:23](../../../../pte-api/app/src/main/java/com/pte/enrollment/domain/StudentClass.java#L23); [V4__enrollment.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L42).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| program_id | BIGINT | False | FK |
| name | VARCHAR(255) | False | - |
| status | VARCHAR(32) | False | - |

### ENT-Subscription — Subscription (Subscription)

Bảng `subscriptions`; module `billing`; status current-source. [Subscription.java:26](../../../../pte-api/app/src/main/java/com/pte/billing/domain/Subscription.java#L26); [V23__billing_subscription.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V23__billing_subscription.sql#L5).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | False | - |
| plan_id | UUID | False | - |
| license_key | VARCHAR(32) | False | UK |
| starts_at | TIMESTAMP WITH TIME ZONE | False | - |
| expires_at | TIMESTAMP WITH TIME ZONE | False | - |
| max_students_per_session | INTEGER | False | - |
| status | VARCHAR(16) | False | - |
| activation_source | VARCHAR(16) | False | - |

### ENT-SupportTicket — SupportTicket (SupportTicket)

Bảng `support_ticket`; module `support`; status current-source. [SupportTicket.java:21](../../../../pte-api/app/src/main/java/com/pte/support/domain/SupportTicket.java#L21); [V71__support_ticket.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V71__support_ticket.sql#L1).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGSERIAL | False | PK |
| public_id | UUID | False | UK |
| submitter_user_public_id | UUID | False | - |
| category | VARCHAR(32) | False | - |
| description | VARCHAR(2000) | False | - |
| status | VARCHAR(20) | False | - |
| entity_type | VARCHAR(32) | True | - |
| entity_id | VARCHAR(36) | True | - |

### ENT-SupportTicketNote — SupportTicketNote (SupportTicketNote)

Bảng `support_ticket_note`; module `support`; status current-source. [SupportTicketNote.java:14](../../../../pte-api/app/src/main/java/com/pte/support/domain/SupportTicketNote.java#L14); [V71__support_ticket.sql:29](../../../../pte-api/app/src/main/resources/db/migration/V71__support_ticket.sql#L29).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGSERIAL | False | PK |
| public_id | UUID | False | UK |
| ticket_id | BIGINT | False | FK |
| content | TEXT | False | - |
| created_at | TIMESTAMPTZ | False | - |

### ENT-TaskRuntimeContract — TaskRuntimeContract (TaskRuntimeContract)

Bảng `task_runtime_contracts`; module `itembank`; status current-source. [TaskRuntimeContract.java:16](../../../../pte-api/app/src/main/java/com/pte/itembank/domain/TaskRuntimeContract.java#L16); [V50__task_runtime_capability_registry.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V50__task_runtime_capability_registry.sql#L3).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| screen_key | VARCHAR(96) | False | - |
| contract_version | INTEGER | False | - |
| profile_key | VARCHAR(96) | False | - |
| profile_version | INTEGER | False | - |
| answer_schema_version | INTEGER | False | - |
| scoring_mode | VARCHAR(16) | False | - |
| min_supported_app_version | VARCHAR(32) | True | - |
| status | VARCHAR(16) | False | - |

### ENT-TaskRuntimeProfile — TaskRuntimeProfile (TaskRuntimeProfile)

Bảng `task_runtime_profiles`; module `itembank`; status current-source. [TaskRuntimeProfile.java:17](../../../../pte-api/app/src/main/java/com/pte/itembank/domain/TaskRuntimeProfile.java#L17); [V45__task_runtime_profiles_and_template_pins.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V45__task_runtime_profiles_and_template_pins.sql#L3).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| task_type_code | VARCHAR(64) | False | - |
| profile_version | INTEGER | False | - |
| profile_key | VARCHAR(96) | False | - |
| behavior_key | VARCHAR(64) | False | - |
| renderer_key | VARCHAR(96) | False | - |
| answer_schema_version | INTEGER | False | - |
| scoring_profile_key | VARCHAR(64) | False | - |
| scoring_profile_version | INTEGER | False | - |
| status | VARCHAR(16) | False | - |

### ENT-TaskTypePublicationUsage — TaskTypePublicationUsage (TaskTypePublicationUsage)

Bảng `task_type_publication_usage`; module `itembank`; status current-source. [TaskTypePublicationUsage.java:17](../../../../pte-api/app/src/main/java/com/pte/itembank/domain/TaskTypePublicationUsage.java#L17); [V53__task_type_publication_usage.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V53__task_type_publication_usage.sql#L3).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| task_type_key | VARCHAR(64) | False | - |
| template_version_public_id | UUID | False | - |
| template_public_id | UUID | False | - |
| published_at | TIMESTAMP WITH TIME ZONE | False | - |
| actor_public_id | UUID | True | - |

### ENT-TenantApplication — TenantApplication (TenantApplication)

Bảng `tenant_applications`; module `billing`; status current-source. [TenantApplication.java:22](../../../../pte-api/app/src/main/java/com/pte/billing/domain/TenantApplication.java#L22); [V21__billing_tenant_application.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V21__billing_tenant_application.sql#L5).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| org_name | VARCHAR(255) | False | - |
| org_type | VARCHAR(255) | False | - |
| contact_email | VARCHAR(255) | False | - |
| contact_phone | VARCHAR(255) | True | - |
| status | VARCHAR(32) | False | - |
| reviewed_by | UUID | True | - |
| reviewed_at | TIMESTAMP WITH TIME ZONE | True | - |
| reject_reason | VARCHAR(500) | True | - |

### ENT-Tenant — Tenant (Tenant)

Bảng `tenants`; module `tenancy`; status current-source. [Tenant.java:29](../../../../pte-api/app/src/main/java/com/pte/tenancy/domain/Tenant.java#L29); [V3__tenancy.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V3__tenancy.sql#L6).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| code | VARCHAR(32) | False | UK |
| name | VARCHAR(255) | False | UK |
| organization_type | VARCHAR(255) | False | - |
| status | VARCHAR(32) | False | - |
| student_limit | INTEGER | False | - |
| suspended_until | TIMESTAMP WITH TIME ZONE | True | - |

### TABLE-user_roles — user_roles (user_roles)

Bảng `user_roles`; module `collection/JDBC`; status current-source. [V2__identity.sql:40](../../../../pte-api/app/src/main/resources/db/migration/V2__identity.sql#L40); [V2__identity.sql:40](../../../../pte-api/app/src/main/resources/db/migration/V2__identity.sql#L40).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| user_id | BIGINT | False | FK |
| role | VARCHAR(32) | False | - |

### ENT-User — User (User)

Bảng `users`; module `identity`; status current-source. [User.java:28](../../../../pte-api/app/src/main/java/com/pte/identity/domain/User.java#L28); [V2__identity.sql:9](../../../../pte-api/app/src/main/resources/db/migration/V2__identity.sql#L9).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| tenant_id | UUID | True | - |
| username | VARCHAR(255) | False | - |
| email | VARCHAR(255) | True | - |
| full_name | VARCHAR(255) | True | - |
| student_code | VARCHAR(255) | True | - |
| status | VARCHAR(32) | False | - |

### ENT-ViolationEvent — ViolationEvent (ViolationEvent)

Bảng `violation_events`; module `proctoring`; status current-source. [ViolationEvent.java:28](../../../../pte-api/app/src/main/java/com/pte/proctoring/domain/ViolationEvent.java#L28); [V11__proctoring.sql:25](../../../../pte-api/app/src/main/resources/db/migration/V11__proctoring.sql#L25).

| Thuộc tính | Kiểu storage | Nullable | Key được chứng minh |
|---|---|---|---|
| id | BIGINT | False | PK |
| public_id | UUID | False | UK |
| proctor_session_id | BIGINT | False | FK |
| violation_type | VARCHAR(32) | False | - |
| detail | TEXT | True | - |
| detected_at | TIMESTAMP WITH TIME ZONE | False | - |

## Relationship (đọc hai chiều)

### REL-005E2CBE — subscriptions / license_codes

Một Subscription có 0..1 LicenseCode. Một LicenseCode tham chiếu 0..1 Subscription được giải quyết theo nguồn.

Link: uuid-logical-reference; `subscription_id` -> `public_id`; status current-source. Trang: 04-billing.

Nguồn: [V25__billing_license_code.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V25__billing_license_code.sql#L5).

### REL-015A4C3C — question_types / task_runtime_profiles

Một QuestionTypeDefinition có 0..n TaskRuntimeProfile. Một TaskRuntimeProfile tham chiếu 0..1 QuestionTypeDefinition được giải quyết theo nguồn.

Link: business-key-logical-reference; `task_type_code` -> `code`; status current-source. Trang: 13-media-runtime.

Nguồn: [V45__task_runtime_profiles_and_template_pins.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V45__task_runtime_profiles_and_template_pins.sql#L3).

### REL-041A322D — exam_attempts / pinned_exam_snapshots

Một ExamAttempt có 0..1 PinnedExamSnapshot. Một PinnedExamSnapshot tham chiếu 0..1 ExamAttempt được giải quyết theo nguồn.

Link: physical-FK; `attempt_id` -> `id`; status current-source. Trang: 06-exam-delivery.

Nguồn: [V9__attempt.sql:33](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L33).

### REL-04B981C8 — users / practice_identity_memberships

Một User có 0..n PracticeIdentityMembership. Một PracticeIdentityMembership tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `user_public_id` -> `public_id`; status current-source. Trang: 10-practice.

Nguồn: [V82__practice_identity_and_entitlement.sql:21](../../../../pte-api/app/src/main/resources/db/migration/V82__practice_identity_and_entitlement.sql#L21).

### REL-06306153 — questions / blueprint_items

Một Question có 0..n BlueprintItem. Một BlueprintItem tham chiếu 0..1 Question được giải quyết theo nguồn.

Link: uuid-logical-reference; `question_public_id` -> `public_id`; status current-source. Trang: 02-content-assessment.

Nguồn: [V7__assessment.sql:19](../../../../pte-api/app/src/main/resources/db/migration/V7__assessment.sql#L19).

### REL-0D1EC53E — examiner_assignment_batches / examiner_attempt_assignments

Một ExaminerAssignmentBatch có 0..n ExaminerAttemptAssignment. Một ExaminerAttemptAssignment tham chiếu 1..1 ExaminerAssignmentBatch được giải quyết theo nguồn.

Link: physical-FK; `batch_public_id,tenant_id,session_public_id` -> `public_id,tenant_id,session_public_id`; status current-source. Trang: 07-examiner-grading.

Nguồn: [V59__enforce_examiner_scoring_references.sql:12](../../../../pte-api/app/src/main/resources/db/migration/V59__enforce_examiner_scoring_references.sql#L12).

### REL-0D9BCEAC — questions / question_options

Một Question có 0..n QuestionOption. Một QuestionOption tham chiếu 1..1 Question được giải quyết theo nguồn.

Link: physical-FK; `question_id` -> `id`; status current-source. Trang: 02-content-assessment.

Nguồn: [V6__itembank.sql:30](../../../../pte-api/app/src/main/resources/db/migration/V6__itembank.sql#L30).

### REL-134974ED — users / support_ticket

Một User có 0..n SupportTicket. Một SupportTicket tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `submitter_user_public_id` -> `public_id`; status current-source. Trang: 16-support-grading-receipts.

Nguồn: [V71__support_ticket.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V71__support_ticket.sql#L1).

### REL-141873E0 — exam_attempts / examiner_attempt_assignments

Một ExamAttempt có 0..n ExaminerAttemptAssignment. Một ExaminerAttemptAssignment tham chiếu 0..1 ExamAttempt được giải quyết theo nguồn.

Link: uuid-logical-reference; `attempt_public_id` -> `public_id`; status current-source. Trang: 07-examiner-grading.

Nguồn: [V58__examiner_scoring_foundation.sql:51](../../../../pte-api/app/src/main/resources/db/migration/V58__examiner_scoring_foundation.sql#L51).

### REL-145F45C0 — rubric_revisions / rubric_criteria

Một RubricRevision có 0..n RubricCriterion. Một RubricCriterion tham chiếu 1..1 RubricRevision được giải quyết theo nguồn.

Link: physical-FK; `revision_id` -> `id`; status current-source. Trang: 03-template-rubric.

Nguồn: [V122__academic_rubric_revisions.sql:30](../../../../pte-api/app/src/main/resources/db/migration/V122__academic_rubric_revisions.sql#L30).

### REL-17B6A212 — examiner_attempt_assignments / examiner_grading_commands

Một ExaminerAttemptAssignment có 0..n ExaminerGradingCommand. Một ExaminerGradingCommand tham chiếu 0..1 ExaminerAttemptAssignment được giải quyết theo nguồn.

Link: uuid-logical-reference; `assignment_public_id` -> `public_id`; status current-source. Trang: 16-support-grading-receipts.

Nguồn: [V110__examiner_workflow_and_drafts.sql:65](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L65).

### REL-1AD2B578 — attempt_answers / scoring_answers

Một AttemptAnswer có 0..1 ScoringAnswer. Một ScoringAnswer tham chiếu 0..1 AttemptAnswer được giải quyết theo nguồn.

Link: uuid-logical-reference; `answer_public_id` -> `public_id`; status current-source. Trang: 08-scoring-reporting.

Nguồn: [V10__scoring.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V10__scoring.sql#L6).

### REL-1F6E5AB1 — exam_sessions / exam_generation_jobs

Một ExamSession có 0..n ExamGenerationJob. Một ExamGenerationJob tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V42__exam_orchestration_core.sql:59](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L59).

### REL-2286506A — plans / subscriptions

Một Plan có 0..n Subscription. Một Subscription tham chiếu 0..1 Plan được giải quyết theo nguồn.

Link: uuid-logical-reference; `plan_id` -> `public_id`; status current-source. Trang: 04-billing.

Nguồn: [V23__billing_subscription.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V23__billing_subscription.sql#L5).

### REL-239724C2 — users / user_roles

Một User có 0..n user_roles. Một user_roles tham chiếu 1..1 User được giải quyết theo nguồn.

Link: physical-FK; `user_id` -> `id`; status current-source. Trang: 11-authentication.

Nguồn: [V2__identity.sql:40](../../../../pte-api/app/src/main/resources/db/migration/V2__identity.sql#L40).

### REL-2449BEC9 — pinned_exam_snapshots / pinned_items

Một PinnedExamSnapshot có 0..n PinnedItem. Một PinnedItem tham chiếu 1..1 PinnedExamSnapshot được giải quyết theo nguồn.

Link: physical-FK; `pinned_snapshot_id` -> `id`; status current-source. Trang: 06-exam-delivery.

Nguồn: [V9__attempt.sql:51](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L51).

### REL-246ACE3E — exam_sessions / exam_session_incidents

Một ExamSession có 0..n ExamSessionIncident. Một ExamSessionIncident tham chiếu 0..1 ExamSession được giải quyết theo nguồn.

Link: uuid-logical-reference; `session_public_id` -> `public_id`; status current-source. Trang: 09-proctoring.

Nguồn: [V111__proctor_identity_and_incidents.sql:35](../../../../pte-api/app/src/main/resources/db/migration/V111__proctor_identity_and_incidents.sql#L35).

### REL-24D1F3C2 — organizations / programs

Một Organization có 0..n Program. Một Program tham chiếu 1..1 Organization được giải quyết theo nguồn.

Link: physical-FK; `organization_id` -> `id`; status current-source. Trang: 01-identity-organization.

Nguồn: [V4__enrollment.sql:26](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L26).

### REL-24E4E1A2 — users / notification_inbox_announcements

Một User có 0..n InboxAnnouncement. Một InboxAnnouncement tham chiếu 1..1 User được giải quyết theo nguồn.

Link: physical-FK; `author_user_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:21](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L21).

### REL-25294ADF — practice_explanation_jobs / practice_explanation_outbox

Một PracticeExplanationJob có 0..n PracticeExplanationOutbox. Một PracticeExplanationOutbox tham chiếu 1..1 PracticeExplanationJob được giải quyết theo nguồn.

Link: physical-FK; `job_id` -> `id`; status current-source. Trang: 17-practice-jobs.

Nguồn: [V120__practice_explanation_durable_jobs.sql:37](../../../../pte-api/app/src/main/resources/db/migration/V120__practice_explanation_durable_jobs.sql#L37).

### REL-262D62BC — task_runtime_contracts / question_types

Một TaskRuntimeContract có 0..n QuestionTypeDefinition. Một QuestionTypeDefinition tham chiếu 0..1 TaskRuntimeContract được giải quyết theo nguồn.

Link: business-key-logical-reference; `screen_key,runtime_profile_version` -> `screen_key,contract_version`; status current-source. Trang: 13-media-runtime.

Nguồn: [V49__dynamic_task_type_identity.sql:2](../../../../pte-api/app/src/main/resources/db/migration/V49__dynamic_task_type_identity.sql#L2); [V49__dynamic_task_type_identity.sql:2](../../../../pte-api/app/src/main/resources/db/migration/V49__dynamic_task_type_identity.sql#L2); [QuestionTypeService.java:560](../../../../pte-api/app/src/main/java/com/pte/itembank/QuestionTypeService.java#L560); [TaskRuntimeContractService.java:60](../../../../pte-api/app/src/main/java/com/pte/itembank/TaskRuntimeContractService.java#L60).

### REL-28110202 — tenants / quota_transactions

Một Tenant có 0..n QuotaTransaction. Một QuotaTransaction tham chiếu 1..1 Tenant được giải quyết theo nguồn.

Link: physical-FK; `tenant_id` -> `id`; status current-source. Trang: 12-tenancy-billing-audit.

Nguồn: [V3__tenancy.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V3__tenancy.sql#L42).

### REL-283AC7DD — tenants / notification_inbox_streams

Một Tenant có 0..n InboxRecipientStream. Một InboxRecipientStream tham chiếu 0..1 Tenant được giải quyết theo nguồn.

Link: physical-FK; `tenant_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:66](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L66).

### REL-2C55CBDE — users / examiner_grading_commands

Một User có 0..n ExaminerGradingCommand. Một ExaminerGradingCommand tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `examiner_public_id` -> `public_id`; status current-source. Trang: 16-support-grading-receipts.

Nguồn: [V110__examiner_workflow_and_drafts.sql:65](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L65).

### REL-2D0D94DA — plans / orders

Một Plan có 0..n Order. Một Order tham chiếu 0..1 Plan được giải quyết theo nguồn.

Link: uuid-logical-reference; `plan_id` -> `public_id`; status current-source. Trang: 04-billing.

Nguồn: [V24__billing_order_payment.sql:13](../../../../pte-api/app/src/main/resources/db/migration/V24__billing_order_payment.sql#L13).

### REL-2DAF7144 — exam_sessions / proctor_sessions

Một ExamSession có 0..n ProctorSession. Một ProctorSession tham chiếu 0..1 ExamSession được giải quyết theo nguồn.

Link: uuid-logical-reference; `session_public_id` -> `public_id`; status current-source. Trang: 09-proctoring.

Nguồn: [V11__proctoring.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V11__proctoring.sql#L6).

### REL-2DD7C946 — license_codes / license_issue_intents

Một LicenseCode có 0..n LicenseIssueIntent. Một LicenseIssueIntent tham chiếu 1..1 LicenseCode được giải quyết theo nguồn.

Link: physical-FK; `license_code_public_id` -> `public_id`; status current-source. Trang: 12-tenancy-billing-audit.

Nguồn: [V79__license_issue_intents.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V79__license_issue_intents.sql#L1).

### REL-32107030 — question_types / pinned_items

Một QuestionTypeDefinition có 0..n PinnedItem. Một PinnedItem tham chiếu 0..1 QuestionTypeDefinition được giải quyết theo nguồn.

Link: physical-FK; `task_type_key` -> `task_type_key`; status current-source. Trang: dictionary-only.

Nguồn: [V51__question_task_type_key_dual_identity.sql:58](../../../../pte-api/app/src/main/resources/db/migration/V51__question_task_type_key_dual_identity.sql#L58).

### REL-322A7BCD — examiner_attempt_assignments / examiner_grading_work

Một ExaminerAttemptAssignment có 0..n ExaminerGradingWork. Một ExaminerGradingWork tham chiếu 1..1 ExaminerAttemptAssignment được giải quyết theo nguồn.

Link: physical-FK; `assignment_public_id` -> `public_id`; status current-source. Trang: 07-examiner-grading, 16-support-grading-receipts.

Nguồn: [V110__examiner_workflow_and_drafts.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L3).

### REL-35BDE713 — tenants / organizations

Một Tenant có 0..1 Organization. Một Organization tham chiếu 1..1 Tenant được giải quyết theo nguồn.

Link: physical-FK; `tenant_id` -> `id`; status current-source. Trang: 01-identity-organization.

Nguồn: [V3__tenancy.sql:27](../../../../pte-api/app/src/main/resources/db/migration/V3__tenancy.sql#L27).

### REL-35E69F7B — users / session_attendance_commands

Một User có 0..n SessionAttendanceCommand. Một SessionAttendanceCommand tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `actor_public_id` -> `public_id`; status current-source. Trang: 14-session-controls.

Nguồn: [V109__session_attendance_and_roster.sql:34](../../../../pte-api/app/src/main/resources/db/migration/V109__session_attendance_and_roster.sql#L34).

### REL-36975512 — practice_identities / practice_identity_memberships

Một PracticeIdentity có 0..n PracticeIdentityMembership. Một PracticeIdentityMembership tham chiếu 1..1 PracticeIdentity được giải quyết theo nguồn.

Link: physical-FK; `identity_id` -> `id`; status current-source. Trang: 10-practice.

Nguồn: [V82__practice_identity_and_entitlement.sql:21](../../../../pte-api/app/src/main/resources/db/migration/V82__practice_identity_and_entitlement.sql#L21).

### REL-36ACDDBE — exam_sessions / exam_audience_sources

Một ExamSession có 0..n ExamAudienceSource. Một ExamAudienceSource tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V42__exam_orchestration_core.sql:21](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L21).

### REL-39FE8986 — question_types / questions

Một QuestionTypeDefinition có 0..n Question. Một Question tham chiếu 0..1 QuestionTypeDefinition được giải quyết theo nguồn.

Link: physical-FK; `pte_task_type` -> `code`; status current-source. Trang: dictionary-only.

Nguồn: [V44__seed_standard_task_type_catalog.sql:129](../../../../pte-api/app/src/main/resources/db/migration/V44__seed_standard_task_type_catalog.sql#L129).

### REL-3D201D26 — exam_sessions / session_class_assignments

Một ExamSession có 0..n SessionClassAssignment. Một SessionClassAssignment tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V20__session_class_assignment.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V20__session_class_assignment.sql#L6).

### REL-3E862CDD — users / quota_transactions

Một User có 0..n QuotaTransaction. Một QuotaTransaction tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `actor_user_id` -> `public_id`; status current-source. Trang: 12-tenancy-billing-audit.

Nguồn: [V3__tenancy.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V3__tenancy.sql#L42).

### REL-4026290A — question_types / rubric_revisions

Một QuestionTypeDefinition có 0..n RubricRevision. Một RubricRevision tham chiếu 0..1 QuestionTypeDefinition được giải quyết theo nguồn.

Link: business-key-logical-reference; `task_type_key` -> `task_type_key`; status current-source. Trang: 03-template-rubric.

Nguồn: [V122__academic_rubric_revisions.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V122__academic_rubric_revisions.sql#L1).

### REL-41519569 — exam_sessions / score_source_audits

Một ExamSession có 0..n ScoreSourceAudit. Một ScoreSourceAudit tham chiếu 0..1 ExamSession được giải quyết theo nguồn.

Link: uuid-logical-reference; `session_public_id` -> `public_id`; status current-source. Trang: 08-scoring-reporting.

Nguồn: [V58__examiner_scoring_foundation.sql:93](../../../../pte-api/app/src/main/resources/db/migration/V58__examiner_scoring_foundation.sql#L93).

### REL-433B42E8 — exam_forms / form_assignments

Một ExamForm có 0..n FormAssignment. Một FormAssignment tham chiếu 1..1 ExamForm được giải quyết theo nguồn.

Link: physical-FK; `form_id` -> `id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V42__exam_orchestration_core.sql:94](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L94).

### REL-43657F1A — exam_snapshots / exam_forms

Một ExamSnapshot có 0..n ExamForm. Một ExamForm tham chiếu 0..1 ExamSnapshot được giải quyết theo nguồn.

Link: uuid-logical-reference; `snapshot_public_id` -> `public_id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V42__exam_orchestration_core.sql:79](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L79).

### REL-43D54A5F — notification_inbox_contents / notification_inbox_items

Một InboxContent có 0..n InboxItem. Một InboxItem tham chiếu 1..1 InboxContent được giải quyết theo nguồn.

Link: physical-FK; `content_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:78](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L78).

### REL-4806F219 — users / audit_logs

Một User có 0..n AuditLog. Một AuditLog tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `actor_user_id` -> `public_id`; status current-source. Trang: 12-tenancy-billing-audit.

Nguồn: [V3__tenancy.sql:58](../../../../pte-api/app/src/main/resources/db/migration/V3__tenancy.sql#L58).

### REL-481F66AA — examiner_grading_work / examiner_grading_events

Một ExaminerGradingWork có 0..n ExaminerGradingEvent. Một ExaminerGradingEvent tham chiếu 1..1 ExaminerGradingWork được giải quyết theo nguồn.

Link: physical-FK; `work_id` -> `id`; status current-source. Trang: 16-support-grading-receipts.

Nguồn: [V110__examiner_workflow_and_drafts.sql:49](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L49).

### REL-4BFBB1F2 — student_classes / class_memberships

Một StudentClass có 0..n ClassMembership. Một ClassMembership tham chiếu 1..1 StudentClass được giải quyết theo nguồn.

Link: physical-FK; `student_class_id` -> `id`; status current-source. Trang: 01-identity-organization.

Nguồn: [V4__enrollment.sql:55](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L55).

### REL-4E0812BE — exam_sessions / exam_session_selected_skills

Một ExamSession có 0..n exam_session_selected_skills. Một exam_session_selected_skills tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 14-session-controls.

Nguồn: [V65__exam_scope_retry_and_attempt_numbering.sql:8](../../../../pte-api/app/src/main/resources/db/migration/V65__exam_scope_retry_and_attempt_numbering.sql#L8).

### REL-508BBBD6 — exam_attempts / practice_session_attempts

Một ExamAttempt có 0..n PracticeSessionAttemptLink. Một PracticeSessionAttemptLink tham chiếu 0..1 ExamAttempt được giải quyết theo nguồn.

Link: uuid-logical-reference; `exam_attempt_public_id` -> `public_id`; status current-source. Trang: 10-practice.

Nguồn: [V83__practice_catalog_and_session_boundary.sql:39](../../../../pte-api/app/src/main/resources/db/migration/V83__practice_catalog_and_session_boundary.sql#L39).

### REL-5247CBC6 — enrollments / session_identity_verification_commands

Một Enrollment có 0..n SessionIdentityVerificationCommand. Một SessionIdentityVerificationCommand tham chiếu 0..1 Enrollment được giải quyết theo nguồn.

Link: uuid-logical-reference; `enrollment_public_id` -> `public_id`; status current-source. Trang: 14-session-controls.

Nguồn: [V111__proctor_identity_and_incidents.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V111__proctor_identity_and_incidents.sql#L7).

### REL-529E31C2 — users / session_attendances

Một User có 0..n SessionAttendance. Một SessionAttendance tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `student_public_id` -> `public_id`; status current-source. Trang: 09-proctoring.

Nguồn: [V109__session_attendance_and_roster.sql:12](../../../../pte-api/app/src/main/resources/db/migration/V109__session_attendance_and_roster.sql#L12).

### REL-5672086F — practice_sessions / practice_session_items

Một PracticeSession có 0..n PracticeSessionItem. Một PracticeSessionItem tham chiếu 1..1 PracticeSession được giải quyết theo nguồn.

Link: physical-FK; `practice_session_id` -> `id`; status current-source. Trang: 10-practice, 13-media-runtime, 17-practice-jobs.

Nguồn: [V84__practice_session_items_and_activity.sql:8](../../../../pte-api/app/src/main/resources/db/migration/V84__practice_session_items_and_activity.sql#L8).

### REL-5883EDB3 — users / lecturer_assignments

Một User có 0..n LecturerAssignment. Một LecturerAssignment tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `assignee_public_id` -> `public_id`; status current-source. Trang: 01-identity-organization.

Nguồn: [V4__enrollment.sql:69](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L69).

### REL-58A32EC9 — plans / license_codes

Một Plan có 0..n LicenseCode. Một LicenseCode tham chiếu 0..1 Plan được giải quyết theo nguồn.

Link: uuid-logical-reference; `plan_id` -> `public_id`; status current-source. Trang: 04-billing.

Nguồn: [V25__billing_license_code.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V25__billing_license_code.sql#L5).

### REL-591E2A11 — users / examiner_attempt_assignments

Một User có 0..n ExaminerAttemptAssignment. Một ExaminerAttemptAssignment tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `examiner_public_id` -> `public_id`; status current-source. Trang: 07-examiner-grading, 16-support-grading-receipts.

Nguồn: [V58__examiner_scoring_foundation.sql:51](../../../../pte-api/app/src/main/resources/db/migration/V58__examiner_scoring_foundation.sql#L51).

### REL-59A79E1F — users / notification_inbox_deliveries

Một User có 0..n InboxDeliveryIntent. Một InboxDeliveryIntent tham chiếu 1..1 User được giải quyết theo nguồn.

Link: physical-FK; `recipient_user_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L42).

### REL-59EDFB5D — users / license_issue_intents

Một User có 0..n LicenseIssueIntent. Một LicenseIssueIntent tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `actor_public_id` -> `public_id`; status current-source. Trang: 12-tenancy-billing-audit.

Nguồn: [V79__license_issue_intents.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V79__license_issue_intents.sql#L1).

### REL-5BDEF290 — programs / student_classes

Một Program có 0..n StudentClass. Một StudentClass tham chiếu 1..1 Program được giải quyết theo nguồn.

Link: physical-FK; `program_id` -> `id`; status current-source. Trang: 01-identity-organization.

Nguồn: [V4__enrollment.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L42).

### REL-5BF81437 — exam_snapshots / exam_sessions

Một ExamSnapshot có 0..n ExamSession. Một ExamSession tham chiếu 0..1 ExamSnapshot được giải quyết theo nguồn.

Link: uuid-logical-reference; `snapshot_public_id` -> `public_id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V8__session.sql:12](../../../../pte-api/app/src/main/resources/db/migration/V8__session.sql#L12).

### REL-5DFB9F9E — exam_blueprints / exam_snapshots

Một ExamBlueprint có 0..n ExamSnapshot. Một ExamSnapshot tham chiếu 0..1 ExamBlueprint được giải quyết theo nguồn.

Link: uuid-logical-reference; `source_blueprint_public_id` -> `public_id`; status current-source. Trang: 02-content-assessment.

Nguồn: [V7__assessment.sql:33](../../../../pte-api/app/src/main/resources/db/migration/V7__assessment.sql#L33).

### REL-62BF684A — users / notification_inbox_streams

Một User có 0..1 InboxRecipientStream. Một InboxRecipientStream tham chiếu 1..1 User được giải quyết theo nguồn.

Link: physical-FK; `recipient_user_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:66](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L66).

### REL-63506D22 — exam_attempts / scoring_answers

Một ExamAttempt có 0..n ScoringAnswer. Một ScoringAnswer tham chiếu 0..1 ExamAttempt được giải quyết theo nguồn.

Link: uuid-logical-reference; `attempt_public_id` -> `public_id`; status current-source. Trang: 08-scoring-reporting.

Nguồn: [V10__scoring.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V10__scoring.sql#L6).

### REL-6446E600 — exam_sessions / session_identity_verification_commands

Một ExamSession có 0..n SessionIdentityVerificationCommand. Một SessionIdentityVerificationCommand tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 14-session-controls.

Nguồn: [V111__proctor_identity_and_incidents.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V111__proctor_identity_and_incidents.sql#L7).

### REL-64DC20FE — notification_inbox_contents / notification_inbox_announcements

Một InboxContent có 0..1 InboxAnnouncement. Một InboxAnnouncement tham chiếu 0..1 InboxContent được giải quyết theo nguồn.

Link: physical-FK; `published_content_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:21](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L21).

### REL-6593540B — exam_attempts / attempt_security_events

Một ExamAttempt có 0..n AttemptSecurityEvent. Một AttemptSecurityEvent tham chiếu 1..1 ExamAttempt được giải quyết theo nguồn.

Link: physical-FK; `attempt_id` -> `id`; status current-source. Trang: 14-session-controls.

Nguồn: [V70__attempt_security_events.sql:4](../../../../pte-api/app/src/main/resources/db/migration/V70__attempt_security_events.sql#L4).

### REL-65C10DE0 — exam_attempts / attempt_heartbeats

Một ExamAttempt có 0..1 AttemptHeartbeat. Một AttemptHeartbeat tham chiếu 0..1 ExamAttempt được giải quyết theo nguồn.

Link: physical-FK; `attempt_id` -> `id`; status current-source. Trang: 14-session-controls.

Nguồn: [V9__attempt.sql:99](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L99).

### REL-69A08B63 — practice_identities / practice_email_challenges

Một PracticeIdentity có 0..n PracticeEmailChallenge. Một PracticeEmailChallenge tham chiếu 1..1 PracticeIdentity được giải quyết theo nguồn.

Link: physical-FK; `identity_id` -> `id`; status current-source. Trang: 11-authentication.

Nguồn: [V82__practice_identity_and_entitlement.sql:41](../../../../pte-api/app/src/main/resources/db/migration/V82__practice_identity_and_entitlement.sql#L41).

### REL-6B252353 — practice_sessions / practice_session_operations

Một PracticeSession có 0..n PracticeSessionOperation. Một PracticeSessionOperation tham chiếu 1..1 PracticeSession được giải quyết theo nguồn.

Link: physical-FK; `practice_session_id` -> `id`; status current-source. Trang: 17-practice-jobs.

Nguồn: [V83__practice_catalog_and_session_boundary.sql:58](../../../../pte-api/app/src/main/resources/db/migration/V83__practice_catalog_and_session_boundary.sql#L58).

### REL-702382C5 — examiner_grading_work / examiner_answer_drafts

Một ExaminerGradingWork có 0..n ExaminerAnswerDraft. Một ExaminerAnswerDraft tham chiếu 1..1 ExaminerGradingWork được giải quyết theo nguồn.

Link: physical-FK; `work_id` -> `id`; status current-source. Trang: 07-examiner-grading.

Nguồn: [V110__examiner_workflow_and_drafts.sql:26](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L26).

### REL-71585599 — practice_session_items / media_objects

Một PracticeSessionItem có 0..n MediaObject. Một MediaObject tham chiếu 0..1 PracticeSessionItem được giải quyết theo nguồn.

Link: uuid-logical-reference; `practice_item_public_id` -> `public_id`; status current-source. Trang: 13-media-runtime.

Nguồn: [V85__practice_response_media_binding.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V85__practice_response_media_binding.sql#L5).

### REL-7290217F — exam_snapshots / pinned_exam_snapshots

Một ExamSnapshot có 0..n PinnedExamSnapshot. Một PinnedExamSnapshot tham chiếu 0..1 ExamSnapshot được giải quyết theo nguồn.

Link: uuid-logical-reference; `source_snapshot_public_id` -> `public_id`; status current-source. Trang: dictionary-only.

Nguồn: [V9__attempt.sql:33](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L33).

### REL-7371AB5B — examiner_answer_scores / scoring_answers

Một ExaminerAnswerScore có 0..1 ScoringAnswer. Một ScoringAnswer tham chiếu 0..1 ExaminerAnswerScore được giải quyết theo nguồn.

Link: physical-FK; `selected_examiner_score_public_id,answer_public_id,tenant_id,session_public_id,attempt_public_id` -> `public_id,answer_public_id,tenant_id,session_public_id,attempt_public_id`; status current-source. Trang: 08-scoring-reporting.

Nguồn: [V59__enforce_examiner_scoring_references.sql:34](../../../../pte-api/app/src/main/resources/db/migration/V59__enforce_examiner_scoring_references.sql#L34).

### REL-737D6B76 — media_objects / questions

Một MediaObject có 0..n Question. Một Question tham chiếu 0..1 MediaObject được giải quyết theo nguồn.

Link: uuid-logical-reference; `audio_prompt_ref` -> `public_id`; status current-source. Trang: 13-media-runtime.

Nguồn: [V6__itembank.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V6__itembank.sql#L6).

### REL-7405D308 — users / practice_identities

Một User có 0..n PracticeIdentity. Một PracticeIdentity tham chiếu 0..1 User được giải quyết theo nguồn.

Link: physical-FK; `shell_user_id` -> `id`; status current-source. Trang: 10-practice, 11-authentication.

Nguồn: [V82__practice_identity_and_entitlement.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V82__practice_identity_and_entitlement.sql#L6).

### REL-7679F862 — notification_inbox_deliveries / notification_inbox_items

Một InboxDeliveryIntent có 0..1 InboxItem. Một InboxItem tham chiếu 1..1 InboxDeliveryIntent được giải quyết theo nguồn.

Link: physical-FK; `delivery_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:78](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L78).

### REL-7A0C7A32 — tenants / notification_inbox_snapshots

Một Tenant có 0..n notification_inbox_snapshots. Một notification_inbox_snapshots tham chiếu 0..1 Tenant được giải quyết theo nguồn.

Link: physical-FK; `tenant_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V73__notification_inbox_snapshots.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V73__notification_inbox_snapshots.sql#L3).

### REL-7A976F78 — users / exam_attempts

Một User có 0..n ExamAttempt. Một ExamAttempt tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `student_public_id` -> `public_id`; status current-source. Trang: 06-exam-delivery, 07-examiner-grading, 10-practice, 14-session-controls.

Nguồn: [V9__attempt.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L7).

### REL-7DA4518E — exam_snapshots / snapshot_items

Một ExamSnapshot có 0..n SnapshotItem. Một SnapshotItem tham chiếu 1..1 ExamSnapshot được giải quyết theo nguồn.

Link: physical-FK; `snapshot_id` -> `id`; status current-source. Trang: 02-content-assessment.

Nguồn: [V7__assessment.sql:47](../../../../pte-api/app/src/main/resources/db/migration/V7__assessment.sql#L47).

### REL-7F85733B — practice_session_items / practice_explanations

Một PracticeSessionItem có 0..n PracticeExplanation. Một PracticeExplanation tham chiếu 1..1 PracticeSessionItem được giải quyết theo nguồn.

Link: physical-FK; `practice_session_item_id` -> `id`; status current-source. Trang: 10-practice, 17-practice-jobs.

Nguồn: [V119__practice_explanation_snapshots.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V119__practice_explanation_snapshots.sql#L1).

### REL-857FB932 — practice_sessions / media_objects

Một PracticeSession có 0..n MediaObject. Một MediaObject tham chiếu 0..1 PracticeSession được giải quyết theo nguồn.

Link: uuid-logical-reference; `practice_session_public_id` -> `public_id`; status current-source. Trang: 13-media-runtime.

Nguồn: [V85__practice_response_media_binding.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V85__practice_response_media_binding.sql#L5).

### REL-87B88168 — exam_sessions / scoring_session_states

Một ExamSession có 0..n ScoringSessionState. Một ScoringSessionState tham chiếu 0..1 ExamSession được giải quyết theo nguồn.

Link: uuid-logical-reference; `session_public_id` -> `public_id`; status current-source. Trang: 08-scoring-reporting.

Nguồn: [V58__examiner_scoring_foundation.sql:115](../../../../pte-api/app/src/main/resources/db/migration/V58__examiner_scoring_foundation.sql#L115).

### REL-891C3716 — support_ticket / support_ticket_note

Một SupportTicket có 0..n SupportTicketNote. Một SupportTicketNote tham chiếu 1..1 SupportTicket được giải quyết theo nguồn.

Link: physical-FK; `ticket_id` -> `id`; status current-source. Trang: 16-support-grading-receipts.

Nguồn: [V71__support_ticket.sql:29](../../../../pte-api/app/src/main/resources/db/migration/V71__support_ticket.sql#L29).

### REL-89806D98 — score_templates / score_template_items

Một ScoreTemplate có 0..n ScoreTemplateItem. Một ScoreTemplateItem tham chiếu 1..1 ScoreTemplate được giải quyết theo nguồn.

Link: physical-FK; `template_id` -> `id`; status current-source. Trang: 03-template-rubric.

Nguồn: [V14__score_template.sql:33](../../../../pte-api/app/src/main/resources/db/migration/V14__score_template.sql#L33).

### REL-8AD38A15 — practice_explanations / practice_explanation_jobs

Một PracticeExplanation có 0..1 PracticeExplanationJob. Một PracticeExplanationJob tham chiếu 1..1 PracticeExplanation được giải quyết theo nguồn.

Link: physical-FK; `explanation_id` -> `id`; status current-source. Trang: 17-practice-jobs.

Nguồn: [V120__practice_explanation_durable_jobs.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V120__practice_explanation_durable_jobs.sql#L7).

### REL-8D0C4CE8 — question_types / score_template_items

Một QuestionTypeDefinition có 0..n ScoreTemplateItem. Một ScoreTemplateItem tham chiếu 0..1 QuestionTypeDefinition được giải quyết theo nguồn.

Link: business-key-logical-reference; `task_type_key` -> `task_type_key`; status current-source. Trang: 03-template-rubric.

Nguồn: [V52__template_policy_and_contract_columns.sql:4](../../../../pte-api/app/src/main/resources/db/migration/V52__template_policy_and_contract_columns.sql#L4).

### REL-8F347276 — examiner_attempt_assignments / examiner_answer_scores

Một ExaminerAttemptAssignment có 0..n ExaminerAnswerScore. Một ExaminerAnswerScore tham chiếu 1..1 ExaminerAttemptAssignment được giải quyết theo nguồn.

Link: physical-FK; `tenant_id,session_public_id,attempt_public_id,examiner_public_id` -> `tenant_id,session_public_id,attempt_public_id,examiner_public_id`; status current-source. Trang: dictionary-only.

Nguồn: [V59__enforce_examiner_scoring_references.sql:24](../../../../pte-api/app/src/main/resources/db/migration/V59__enforce_examiner_scoring_references.sql#L24).

### REL-911B6A80 — tenants / notification_inbox_items

Một Tenant có 0..n InboxItem. Một InboxItem tham chiếu 0..1 Tenant được giải quyết theo nguồn.

Link: physical-FK; `tenant_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:78](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L78).

### REL-91A023C5 — notification_inbox_contents / notification_inbox_deliveries

Một InboxContent có 0..n InboxDeliveryIntent. Một InboxDeliveryIntent tham chiếu 1..1 InboxContent được giải quyết theo nguồn.

Link: physical-FK; `content_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L42).

### REL-921E243A — subscriptions / exam_sessions

Một Subscription có 0..n ExamSession. Một ExamSession tham chiếu 0..1 Subscription được giải quyết theo nguồn.

Link: uuid-logical-reference; `subscription_id` -> `public_id`; status current-source. Trang: dictionary-only.

Nguồn: [V27__session_subscription.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V27__session_subscription.sql#L6).

### REL-99DBF3ED — exam_session_incidents / exam_session_incident_history

Một ExamSessionIncident có 0..n ExamSessionIncidentHistory. Một ExamSessionIncidentHistory tham chiếu 1..1 ExamSessionIncident được giải quyết theo nguồn.

Link: physical-FK; `incident_id` -> `id`; status current-source. Trang: 09-proctoring.

Nguồn: [V111__proctor_identity_and_incidents.sql:64](../../../../pte-api/app/src/main/resources/db/migration/V111__proctor_identity_and_incidents.sql#L64).

### REL-99F7AA25 — tenants / audit_logs

Một Tenant có 0..n AuditLog. Một AuditLog tham chiếu 0..1 Tenant được giải quyết theo nguồn.

Link: uuid-logical-reference; `tenant_id` -> `public_id`; status current-source. Trang: 12-tenancy-billing-audit.

Nguồn: [V3__tenancy.sql:58](../../../../pte-api/app/src/main/resources/db/migration/V3__tenancy.sql#L58).

### REL-9A2DA89F — users / notification_logs

Một User có 0..n NotificationLog. Một NotificationLog tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `recipient_user_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V12__notification.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V12__notification.sql#L6).

### REL-9A42D978 — questions / snapshot_items

Một Question có 0..n SnapshotItem. Một SnapshotItem tham chiếu 0..1 Question được giải quyết theo nguồn.

Link: uuid-logical-reference; `source_question_public_id` -> `public_id`; status current-source. Trang: 02-content-assessment.

Nguồn: [V7__assessment.sql:47](../../../../pte-api/app/src/main/resources/db/migration/V7__assessment.sql#L47).

### REL-9D9038F6 — questions / practice_session_items

Một Question có 0..n PracticeSessionItem. Một PracticeSessionItem tham chiếu 0..1 Question được giải quyết theo nguồn.

Link: uuid-logical-reference; `source_question_public_id` -> `public_id`; status current-source. Trang: 13-media-runtime.

Nguồn: [V102__practice_question_content.sql:4](../../../../pte-api/app/src/main/resources/db/migration/V102__practice_question_content.sql#L4).

### REL-9DFA695B — users / session_identity_verification_commands

Một User có 0..n SessionIdentityVerificationCommand. Một SessionIdentityVerificationCommand tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `actor_public_id` -> `public_id`; status current-source. Trang: 14-session-controls.

Nguồn: [V111__proctor_identity_and_incidents.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V111__proctor_identity_and_incidents.sql#L7).

### REL-9E11DA14 — users / practice_sessions

Một User có 0..n PracticeSession. Một PracticeSession tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `student_public_id` -> `public_id`; status current-source. Trang: 10-practice, 17-practice-jobs.

Nguồn: [V83__practice_catalog_and_session_boundary.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V83__practice_catalog_and_session_boundary.sql#L5).

### REL-9F5244CC — media_objects / questions

Một MediaObject có 0..n Question. Một Question tham chiếu 0..1 MediaObject được giải quyết theo nguồn.

Link: uuid-logical-reference; `image_prompt_ref` -> `public_id`; status current-source. Trang: 13-media-runtime.

Nguồn: [V6__itembank.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V6__itembank.sql#L6).

### REL-A49D8D66 — tenants / subscriptions

Một Tenant có 0..n Subscription. Một Subscription tham chiếu 0..1 Tenant được giải quyết theo nguồn.

Link: uuid-logical-reference; `tenant_id` -> `public_id`; status current-source. Trang: 04-billing.

Nguồn: [V23__billing_subscription.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V23__billing_subscription.sql#L5).

### REL-A4A2B326 — exam_sessions / proctor_assignments

Một ExamSession có 0..n ProctorAssignment. Một ProctorAssignment tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V8__session.sql:65](../../../../pte-api/app/src/main/resources/db/migration/V8__session.sql#L65).

### REL-A70ABFC9 — scoring_answers / scoring_answer_ai_details

Một ScoringAnswer có 0..1 ScoringAnswerAiDetail. Một ScoringAnswerAiDetail tham chiếu 0..1 ScoringAnswer được giải quyết theo nguồn.

Link: uuid-logical-reference; `answer_public_id` -> `answer_public_id`; status current-source. Trang: 08-scoring-reporting.

Nguồn: [V113__ai_scoring_dispatch_and_detail.sql:10](../../../../pte-api/app/src/main/resources/db/migration/V113__ai_scoring_dispatch_and_detail.sql#L10).

### REL-A7E0D1C9 — users / class_memberships

Một User có 0..1 ClassMembership. Một ClassMembership tham chiếu 0..1 User được giải quyết theo nguồn.

Link: uuid-logical-reference; `student_public_id` -> `public_id`; status current-source. Trang: 01-identity-organization.

Nguồn: [V4__enrollment.sql:55](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L55).

### REL-A8EDC357 — question_types / snapshot_items

Một QuestionTypeDefinition có 0..n SnapshotItem. Một SnapshotItem tham chiếu 0..1 QuestionTypeDefinition được giải quyết theo nguồn.

Link: physical-FK; `task_type_key` -> `task_type_key`; status current-source. Trang: 02-content-assessment.

Nguồn: [V51__question_task_type_key_dual_identity.sql:55](../../../../pte-api/app/src/main/resources/db/migration/V51__question_task_type_key_dual_identity.sql#L55).

### REL-A8F585E3 — exam_blueprints / blueprint_items

Một ExamBlueprint có 0..n BlueprintItem. Một BlueprintItem tham chiếu 1..1 ExamBlueprint được giải quyết theo nguồn.

Link: physical-FK; `blueprint_id` -> `id`; status current-source. Trang: 02-content-assessment.

Nguồn: [V7__assessment.sql:19](../../../../pte-api/app/src/main/resources/db/migration/V7__assessment.sql#L19).

### REL-AB909372 — proctor_sessions / violation_events

Một ProctorSession có 0..n ViolationEvent. Một ViolationEvent tham chiếu 1..1 ProctorSession được giải quyết theo nguồn.

Link: physical-FK; `proctor_session_id` -> `id`; status current-source. Trang: 09-proctoring.

Nguồn: [V11__proctoring.sql:25](../../../../pte-api/app/src/main/resources/db/migration/V11__proctoring.sql#L25).

### REL-AF84AD68 — exam_attempts / session_grading_cohort_members

Một ExamAttempt có 0..n GradingCohortMember. Một GradingCohortMember tham chiếu 0..1 ExamAttempt được giải quyết theo nguồn.

Link: uuid-logical-reference; `attempt_public_id` -> `public_id`; status current-source. Trang: 07-examiner-grading.

Nguồn: [V75__session_grading_cohort.sql:28](../../../../pte-api/app/src/main/resources/db/migration/V75__session_grading_cohort.sql#L28).

### REL-B4832265 — score_templates / exam_sessions

Một ScoreTemplate có 0..n ExamSession. Một ExamSession tham chiếu 0..1 ScoreTemplate được giải quyết theo nguồn.

Link: uuid-logical-reference; `template_public_id` -> `public_id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V42__exam_orchestration_core.sql:1](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L1).

### REL-B6339EAC — session_grading_cohorts / session_grading_cohort_members

Một GradingCohort có 0..n GradingCohortMember. Một GradingCohortMember tham chiếu 1..1 GradingCohort được giải quyết theo nguồn.

Link: physical-FK; `cohort_public_id` -> `public_id`; status current-source. Trang: 07-examiner-grading.

Nguồn: [V75__session_grading_cohort.sql:28](../../../../pte-api/app/src/main/resources/db/migration/V75__session_grading_cohort.sql#L28).

### REL-B6D15CD4 — users / refresh_tokens

Một User có 0..n RefreshToken. Một RefreshToken tham chiếu 0..1 User được giải quyết theo nguồn.

Link: id-logical-reference; `user_id` -> `id`; status current-source. Trang: 11-authentication.

Nguồn: [V2__identity.sql:55](../../../../pte-api/app/src/main/resources/db/migration/V2__identity.sql#L55).

### REL-BB8240A0 — exam_sessions / exam_forms

Một ExamSession có 0..n ExamForm. Một ExamForm tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V42__exam_orchestration_core.sql:79](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L79).

### REL-BCA8EB98 — exam_sessions / exam_audience_members

Một ExamSession có 0..n ExamAudienceMember. Một ExamAudienceMember tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V42__exam_orchestration_core.sql:37](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L37).

### REL-BDE744B1 — orders / payment_transactions

Một Order có 0..n PaymentTransaction. Một PaymentTransaction tham chiếu 0..1 Order được giải quyết theo nguồn.

Link: business-key-logical-reference; `order_code` -> `order_code`; status current-source. Trang: 04-billing.

Nguồn: [V24__billing_order_payment.sql:41](../../../../pte-api/app/src/main/resources/db/migration/V24__billing_order_payment.sql#L41).

### REL-C06603BB — rubric_revisions / practice_session_items

Một RubricRevision có 0..n PracticeSessionItem. Một PracticeSessionItem tham chiếu 0..1 RubricRevision được giải quyết theo nguồn.

Link: uuid-logical-reference; `rubric_revision_public_id` -> `public_id`; status current-source. Trang: 10-practice.

Nguồn: [V122__academic_rubric_revisions.sql:72](../../../../pte-api/app/src/main/resources/db/migration/V122__academic_rubric_revisions.sql#L72).

### REL-C2AD5C63 — scoring_answers / examiner_answer_scores

Một ScoringAnswer có 0..1 ExaminerAnswerScore. Một ExaminerAnswerScore tham chiếu 1..1 ScoringAnswer được giải quyết theo nguồn.

Link: physical-FK; `answer_public_id,tenant_id,session_public_id,attempt_public_id` -> `answer_public_id,tenant_id,session_public_id,attempt_public_id`; status current-source. Trang: 08-scoring-reporting.

Nguồn: [V59__enforce_examiner_scoring_references.sql:24](../../../../pte-api/app/src/main/resources/db/migration/V59__enforce_examiner_scoring_references.sql#L24).

### REL-C51F7ADA — enrollments / session_attendance_commands

Một Enrollment có 0..n SessionAttendanceCommand. Một SessionAttendanceCommand tham chiếu 0..1 Enrollment được giải quyết theo nguồn.

Link: uuid-logical-reference; `enrollment_public_id` -> `public_id`; status current-source. Trang: 14-session-controls.

Nguồn: [V109__session_attendance_and_roster.sql:34](../../../../pte-api/app/src/main/resources/db/migration/V109__session_attendance_and_roster.sql#L34).

### REL-CB79216B — score_templates / task_type_publication_usage

Một ScoreTemplate có 0..n TaskTypePublicationUsage. Một TaskTypePublicationUsage tham chiếu 0..1 ScoreTemplate được giải quyết theo nguồn.

Link: uuid-logical-reference; `template_version_public_id` -> `public_id`; status current-source. Trang: 13-media-runtime.

Nguồn: [V53__task_type_publication_usage.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V53__task_type_publication_usage.sql#L3).

### REL-CCDDE3B4 — exam_sessions / form_assignments

Một ExamSession có 0..n FormAssignment. Một FormAssignment tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 05-exam-setup.

Nguồn: [V42__exam_orchestration_core.sql:94](../../../../pte-api/app/src/main/resources/db/migration/V42__exam_orchestration_core.sql#L94).

### REL-CD96BEF6 — users / notification_inbox_snapshots

Một User có 0..n notification_inbox_snapshots. Một notification_inbox_snapshots tham chiếu 1..1 User được giải quyết theo nguồn.

Link: physical-FK; `recipient_user_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V73__notification_inbox_snapshots.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V73__notification_inbox_snapshots.sql#L3).

### REL-D02D4510 — exam_attempts / attempt_answers

Một ExamAttempt có 0..n AttemptAnswer. Một AttemptAnswer tham chiếu 1..1 ExamAttempt được giải quyết theo nguồn.

Link: physical-FK; `attempt_id` -> `id`; status current-source. Trang: 06-exam-delivery, 08-scoring-reporting.

Nguồn: [V9__attempt.sql:83](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L83).

### REL-D0DD9755 — tenants / users

Một Tenant có 0..n User. Một User tham chiếu 0..1 Tenant được giải quyết theo nguồn.

Link: uuid-logical-reference; `tenant_id` -> `public_id`; status current-source. Trang: 01-identity-organization, 12-tenancy-billing-audit, 15-notification-inbox.

Nguồn: [V2__identity.sql:9](../../../../pte-api/app/src/main/resources/db/migration/V2__identity.sql#L9).

### REL-D2CC9017 — question_types / questions

Một QuestionTypeDefinition có 0..n Question. Một Question tham chiếu 0..1 QuestionTypeDefinition được giải quyết theo nguồn.

Link: physical-FK; `task_type_key` -> `task_type_key`; status current-source. Trang: 02-content-assessment, 13-media-runtime.

Nguồn: [V51__question_task_type_key_dual_identity.sql:52](../../../../pte-api/app/src/main/resources/db/migration/V51__question_task_type_key_dual_identity.sql#L52).

### REL-D37F2680 — rubric_criteria / rubric_criterion_levels

Một RubricCriterion có 0..n RubricCriterionLevel. Một RubricCriterionLevel tham chiếu 1..1 RubricCriterion được giải quyết theo nguồn.

Link: physical-FK; `criterion_id` -> `id`; status current-source. Trang: 03-template-rubric.

Nguồn: [V122__academic_rubric_revisions.sql:45](../../../../pte-api/app/src/main/resources/db/migration/V122__academic_rubric_revisions.sql#L45).

### REL-D5F77C0F — tenants / license_codes

Một Tenant có 0..n LicenseCode. Một LicenseCode tham chiếu 0..1 Tenant được giải quyết theo nguồn.

Link: uuid-logical-reference; `redeemed_by_tenant_id` -> `public_id`; status current-source. Trang: 04-billing, 12-tenancy-billing-audit.

Nguồn: [V25__billing_license_code.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V25__billing_license_code.sql#L5).

### REL-D895DD73 — tenants / notification_inbox_deliveries

Một Tenant có 0..n InboxDeliveryIntent. Một InboxDeliveryIntent tham chiếu 0..1 Tenant được giải quyết theo nguồn.

Link: physical-FK; `tenant_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:42](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L42).

### REL-D8C3DC44 — practice_sessions / practice_session_attempts

Một PracticeSession có 0..n PracticeSessionAttemptLink. Một PracticeSessionAttemptLink tham chiếu 1..1 PracticeSession được giải quyết theo nguồn.

Link: physical-FK; `practice_session_id` -> `id`; status current-source. Trang: 10-practice.

Nguồn: [V83__practice_catalog_and_session_boundary.sql:39](../../../../pte-api/app/src/main/resources/db/migration/V83__practice_catalog_and_session_boundary.sql#L39).

### REL-DC6AD25C — exam_sessions / enrollments

Một ExamSession có 0..n Enrollment. Một Enrollment tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 05-exam-setup, 14-session-controls.

Nguồn: [V8__session.sql:51](../../../../pte-api/app/src/main/resources/db/migration/V8__session.sql#L51).

### REL-E375809C — practice_identities / practice_sessions

Một PracticeIdentity có 0..n PracticeSession. Một PracticeSession tham chiếu 0..1 PracticeIdentity được giải quyết theo nguồn.

Link: uuid-logical-reference; `identity_public_id` -> `public_id`; status current-source. Trang: 10-practice.

Nguồn: [V83__practice_catalog_and_session_boundary.sql:5](../../../../pte-api/app/src/main/resources/db/migration/V83__practice_catalog_and_session_boundary.sql#L5).

### REL-E5413C5D — notification_inbox_streams / notification_inbox_items

Một InboxRecipientStream có 0..n InboxItem. Một InboxItem tham chiếu 1..1 InboxRecipientStream được giải quyết theo nguồn.

Link: physical-FK; `recipient_user_public_id` -> `recipient_user_public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:78](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L78).

### REL-E5865990 — users / login_hashes

Một User có 0..1 LoginHash. Một LoginHash tham chiếu 0..1 User được giải quyết theo nguồn.

Link: id-logical-reference; `user_id` -> `id`; status current-source. Trang: 11-authentication.

Nguồn: [V2__identity.sql:45](../../../../pte-api/app/src/main/resources/db/migration/V2__identity.sql#L45).

### REL-E7E0682B — exam_sessions / session_attendance_commands

Một ExamSession có 0..n SessionAttendanceCommand. Một SessionAttendanceCommand tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 14-session-controls.

Nguồn: [V109__session_attendance_and_roster.sql:34](../../../../pte-api/app/src/main/resources/db/migration/V109__session_attendance_and_roster.sql#L34).

### REL-EBF8FB78 — examiner_grading_work / examiner_grading_issues

Một ExaminerGradingWork có 0..n ExaminerGradingIssue. Một ExaminerGradingIssue tham chiếu 1..1 ExaminerGradingWork được giải quyết theo nguồn.

Link: physical-FK; `work_id` -> `id`; status current-source. Trang: 07-examiner-grading.

Nguồn: [V110__examiner_workflow_and_drafts.sql:82](../../../../pte-api/app/src/main/resources/db/migration/V110__examiner_workflow_and_drafts.sql#L82).

### REL-F2C0C63D — notification_inbox_announcements / notification_inbox_announcements

Một InboxAnnouncement có 0..n InboxAnnouncement. Một InboxAnnouncement tham chiếu 0..1 InboxAnnouncement được giải quyết theo nguồn.

Link: physical-FK; `correction_of_public_id` -> `public_id`; status current-source. Trang: 15-notification-inbox.

Nguồn: [V72__notification_inbox_foundation.sql:21](../../../../pte-api/app/src/main/resources/db/migration/V72__notification_inbox_foundation.sql#L21).

### REL-F3CA282B — exam_sessions / session_attendances

Một ExamSession có 0..n SessionAttendance. Một SessionAttendance tham chiếu 1..1 ExamSession được giải quyết theo nguồn.

Link: physical-FK; `session_id` -> `id`; status current-source. Trang: 09-proctoring.

Nguồn: [V109__session_attendance_and_roster.sql:12](../../../../pte-api/app/src/main/resources/db/migration/V109__session_attendance_and_roster.sql#L12).

### REL-F3D1CB59 — question_types / task_type_publication_usage

Một QuestionTypeDefinition có 0..n TaskTypePublicationUsage. Một TaskTypePublicationUsage tham chiếu 0..1 QuestionTypeDefinition được giải quyết theo nguồn.

Link: business-key-logical-reference; `task_type_key` -> `task_type_key`; status current-source. Trang: 13-media-runtime.

Nguồn: [V53__task_type_publication_usage.sql:3](../../../../pte-api/app/src/main/resources/db/migration/V53__task_type_publication_usage.sql#L3).

### REL-F6B3D600 — exam_sessions / exam_attempts

Một ExamSession có 0..n ExamAttempt. Một ExamAttempt tham chiếu 0..1 ExamSession được giải quyết theo nguồn.

Link: uuid-logical-reference; `session_public_id` -> `public_id`; status current-source. Trang: 06-exam-delivery, 08-scoring-reporting, 14-session-controls.

Nguồn: [V9__attempt.sql:7](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L7).

### REL-F6C4AE37 — exam_attempts / attempt_reports

Một ExamAttempt có 0..1 AttemptReport. Một AttemptReport tham chiếu 0..1 ExamAttempt được giải quyết theo nguồn.

Link: uuid-logical-reference; `attempt_public_id` -> `public_id`; status current-source. Trang: 08-scoring-reporting.

Nguồn: [V13__reporting.sql:6](../../../../pte-api/app/src/main/resources/db/migration/V13__reporting.sql#L6).

### REL-F7FADFC7 — tenants / orders

Một Tenant có 0..n Order. Một Order tham chiếu 0..1 Tenant được giải quyết theo nguồn.

Link: uuid-logical-reference; `tenant_id` -> `public_id`; status current-source. Trang: 04-billing.

Nguồn: [V24__billing_order_payment.sql:13](../../../../pte-api/app/src/main/resources/db/migration/V24__billing_order_payment.sql#L13).

### REL-F9125C3D — student_classes / lecturer_assignments

Một StudentClass có 0..n LecturerAssignment. Một LecturerAssignment tham chiếu 1..1 StudentClass được giải quyết theo nguồn.

Link: physical-FK; `student_class_id` -> `id`; status current-source. Trang: 01-identity-organization.

Nguồn: [V4__enrollment.sql:69](../../../../pte-api/app/src/main/resources/db/migration/V4__enrollment.sql#L69).

### REL-F97143D6 — pinned_items / attempt_answers

Một PinnedItem có 0..n AttemptAnswer. Một AttemptAnswer tham chiếu 1..1 PinnedItem được giải quyết theo nguồn.

Link: physical-FK; `pinned_item_id` -> `id`; status current-source. Trang: 06-exam-delivery.

Nguồn: [V9__attempt.sql:83](../../../../pte-api/app/src/main/resources/db/migration/V9__attempt.sql#L83).

## Conceptual core

Organization = tenants + organizations; các entity core còn lại ánh xạ class cùng tên. Không đánh dấu public_id là database PK. Mỗi core relation dẫn tới REL trong relationships.json; Question/Snapshot dùng đường qua SnapshotItem.

## Value objects và projections

Role và status là enum/collection; ExamPolicy là embedded fields; options_json, rubric_snapshot_json, report_snapshot_json là payload/snapshot. Không tự sinh bảng riêng. Audit và audience source có discriminator nên không là một FK đa đích.
