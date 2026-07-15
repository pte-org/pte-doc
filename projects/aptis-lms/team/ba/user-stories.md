# User Stories — APTIS LMS

## User Stories

### US-001

**As a** Any registered user (all roles), **I want to** authenticate users via email and password, scoping the login context to the tenant identified by the current request subdomain, and reject credentials that do not belong to that tenant. **so that** access the correct portal securely without crossing tenant boundaries.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-01 → REQ-001

### US-002

**As a** Any authenticated user (client-initiated); Authentication service, **I want to** issue a short-lived JWT access token (TTL ≤ 15 minutes) and a long-lived rotating refresh token (TTL ≤ 7 days) on successful authentication; then issue a new access token and invalidate the old refresh token when a valid refresh token is presented. **so that** access the correct portal securely without crossing tenant boundaries.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-02 → REQ-002

### US-003

**As a** API Gateway middleware (automated), **I want to** resolve the tenant context from the `Host` header subdomain of every incoming request and scope all data operations exclusively to that tenant's `tenant_id`; requests to `admin.aptis-lms.vn` shall route to the Vendor Portal with no tenant scoping. **so that** access the correct portal securely without crossing tenant boundaries.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-03 → REQ-003

### US-004

**As a** Tenant Admin, **I want to** support assigning multiple roles simultaneously to a single Tenant-side user; the user's effective permissions shall be the union of all assigned roles' permission sets; adding or removing a role shall take effect on the user's next authenticated request. **so that** access the correct portal securely without crossing tenant boundaries.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-04 → REQ-004

### US-005

**As a** Any registered user (all roles), **I want to** provide a password reset flow via email for all registered users; the reset link shall be time-limited to 1 hour, single-use, and scoped to the user's portal domain. **so that** access the correct portal securely without crossing tenant boundaries.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-05 → REQ-005

### US-006

**As a** Student, **I want to** force students who log in for the first time using a bulk-generated password to change their password before accessing any other screen, when the tenant has `force_password_change` enabled. **so that** access the correct portal securely without crossing tenant boundaries.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-06 → REQ-006

### US-007

**As a** Any authenticated user (self-logout); Super Admin (force-logout), **I want to** invalidate a user's refresh token upon logout; a Super Admin shall be able to force-invalidate all active sessions of any user across all devices. **so that** access the correct portal securely without crossing tenant boundaries.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-07 → REQ-007

### US-008

**As a** Guest (Trial Taker), **I want to** allow unauthenticated users to access the trial landing page and trial exam without creating an account, issuing a short-lived anonymous session token valid for the trial duration only. **so that** access the correct portal securely without crossing tenant boundaries.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-08 → REQ-008

### US-009

**As a** Content Manager, **I want to** allow Content Managers to create, read, update, and delete questions in the APTIS question bank; each question record shall store skill, part, question_type, content, answer_key (auto-score types), rubric_criteria (human-score types), difficulty_tag, and topic_tags. **so that** maintain reliable, reusable APTIS assessment content.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-09 → REQ-009

### US-010

**As a** Content Manager, **I want to** allow Content Managers to upload audio files (MP3, WAV) for Listening questions and deliver them to exam clients via CDN with per-part play-count limits. **so that** maintain reliable, reusable APTIS assessment content.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-10 → REQ-010

### US-011

**As a** Content Manager, **I want to** allow Content Managers to upload image files (JPEG, PNG, ≤ 10 MB) and associate them with Speaking Part B (single image) and Part D (image pair) questions. **so that** maintain reliable, reusable APTIS assessment content.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-11 → REQ-011

### US-012

**As a** Content Manager, **I want to** allow Content Managers to create named exam templates by selecting questions per skill and part, or by specifying auto-fill criteria; a template shall be publishable only when all required skills and parts are covered. **so that** maintain reliable, reusable APTIS assessment content.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-12 → REQ-012

### US-013

**As a** Content Manager, **I want to** provide a preview mode allowing Content Managers to experience a question or full exam template as a student would, including audio playback, image rendering, and timer display, without creating any exam attempt record. **so that** maintain reliable, reusable APTIS assessment content.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-13 → REQ-013

### US-014

**As a** Content Manager (edit trigger); system (automatic versioning), **I want to** preserve the version of every question used in a completed exam session; editing such a question shall create a new version (current) while leaving the original version (immutable) linked to prior sessions. **so that** maintain reliable, reusable APTIS assessment content.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-14 → REQ-014

### US-015

**As a** Content Manager, **I want to** allow Content Managers to import questions in bulk from CSV or Excel files conforming to the prescribed import template; then validate each row independently and report errors per row before committing any data. **so that** maintain reliable, reusable APTIS assessment content.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-15 → REQ-015

### US-016

**As a** Content Manager, **I want to** compute and display per-question item analysis statistics for Content Managers, aggregated globally across all tenants, and automatically flag questions with statistically outlier difficulty or discrimination indices. **so that** maintain reliable, reusable APTIS assessment content.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-16 → REQ-016

### US-017

**As a** Student, **I want to** verify student eligibility before launching an exam session; eligibility requires that the student is enrolled, the session window is open, and no completed attempt exists for this session by this student. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-17 → REQ-017

### US-018

**As a** Student, **I want to** run three sequential pre-exam checks before the student begins the first skill: microphone detection and test recording, fullscreen mode activation, and per-skill instruction acknowledgment; all three must pass before the exam starts. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-18 → REQ-018

### US-019

**As a** System (automated timer enforcement), **I want to** maintain authoritative exam part timers on the server; when `time_remaining` reaches zero, the server shall close the current part and advance the student to the next part regardless of client state; no client-side action is required to trigger the advance. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-19 → REQ-019

### US-020

**As a** Student, **I want to** render each Reading part with its correct interaction type: Part A (sentence matching), Part B (gap-fill with dropdown), Part C (MCQ with scrollable passage), Part D (short-answer text input with passage); student answers shall be persisted per question as entered. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-20 → REQ-020

### US-021

**As a** Student, **I want to** render Writing parts with appropriate text input areas and display a live word count; the word count indicator shall change color based on proximity to the configured minimum and maximum word limits. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-21 → REQ-021

### US-022

**As a** Student, **I want to** auto-play Listening audio when a student enters each Listening question; the student shall not be able to seek, rewind, or replay beyond the configured `max_play_count`; questions shall be answerable simultaneously with audio playback. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-22 → REQ-022

### US-023

**As a** Student, **I want to** implement a five-stage Speaking sequence per part: instruction/image display, preparation countdown, recording with live waveform, auto-stop at recording time limit, and upload with progress indicator; audio shall be buffered locally and uploaded to Cloud Storage. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-23 → REQ-023

### US-024

**As a** Student, **I want to** display a transition screen between exam parts showing the completed part, the next part, time allowed for the next part, and a countdown to auto-advance; back navigation to the completed part is blocked. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-24 → REQ-024

### US-025

**As a** Student (passive); System (timer enforcement), **I want to** sequence exam skills in the order defined by the exam template (default: Reading → Listening → Writing → Speaking); between-skill breaks shall be configurable per template; the next skill timer shall not start until the break countdown expires. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-25 → REQ-025

### US-026

**As a** Student (natural completion); System (automatic on session close or timer expiry), **I want to** finalize the exam attempt when all skills are completed or when the session window closes; finalization shall persist all remaining answers, set `attempt.status = submitted`, and trigger the scoring pipeline. **so that** complete a faithful and time-controlled APTIS practice exam.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-26 → REQ-026

### US-027

**As a** System (automated scoring job), **I want to** automatically compute scores for Reading and Listening immediately after exam submission by comparing each student answer against the stored answer key. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-27 → REQ-027

### US-028

**As a** System (automated), **I want to** convert raw scores for Reading and Listening into APTIS band levels (A1, A2, B1, B2, C) using the Vendor-configured band mapping table; out-of-range scores shall be flagged as `MAPPING_ERROR`. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-28 → REQ-028

### US-029

**As a** System (automated); Student (consumer), **I want to** make Reading and Listening band results available to the student within 2 minutes of exam submission completion. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-29 → REQ-029

### US-030

**As a** System (AI scoring pipeline), **I want to** submit each Speaking audio recording to the configured STT API and store the resulting transcript per part; on permanent API failure after 3 retries, the part shall be flagged `STT_FAILED` for manual teacher review. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-30 → REQ-030

### US-031

**As a** System (AI scoring pipeline), **I want to** submit Writing text responses and Speaking transcripts to the configured LLM API with APTIS rubric prompts; the resulting draft score shall be stored with `status = draft` and shall not be visible to the student until a teacher confirms it. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-31 → REQ-031

### US-032

**As a** Teacher, **I want to** present Teachers with a queue of Writing and Speaking submissions pending human review, sorted by submission time (oldest first), showing student response, AI draft scores, and feedback narrative. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-32 → REQ-032

### US-033

**As a** Teacher, **I want to** allow Teachers to confirm AI draft scores as-is or override individual criterion scores and feedback narrative; upon confirmation, scores shall be finalized and made available to the student. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-33 → REQ-033

### US-034

**As a** Student, **I want to** display a personal results dashboard for each student showing all past attempts with per-skill bands, a progression chart, and a part-level breakdown for each completed attempt. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-34 → REQ-034

### US-035

**As a** Student; Teacher (when viewing a student's attempt), **I want to** display a four-skill band profile summary (Reading, Writing, Listening, Speaking bands) for any fully scored attempt, with each band shown alongside a CEFR-aligned descriptor. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-35 → REQ-035

### US-036

**As a** Student, **I want to** display the teacher-confirmed feedback narrative for Writing and Speaking to the student, accessible from the attempt detail screen, after the score is finalized. **so that** receive accurate, reviewable results and actionable feedback.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-36 → REQ-036

### US-037

**As a** Teacher; Exam Coordinator, **I want to** allow Teachers and Exam Coordinators to create exam sessions by specifying a session name, exam template, participant scope, open/close datetime window, and anti-cheat configuration. **so that** run scheduled exams safely and intervene when incidents occur.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-37 → REQ-037

### US-038

**As a** System (notification scheduler), **I want to** automatically send email notifications to all enrolled students when an exam session is created and at T−24h and T−1h before the session opens. **so that** run scheduled exams safely and intervene when incidents occur.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-38 → REQ-038

### US-039

**As a** Exam Coordinator, **I want to** provide Exam Coordinators with a real-time dashboard showing per-student status during an active exam session, updated via WebSocket or SSE without page reload. **so that** run scheduled exams safely and intervene when incidents occur.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-39 → REQ-039

### US-040

**As a** Exam Coordinator, **I want to** allow Exam Coordinators to extend the remaining time for a specific student's attempt; the extension must be logged with a mandatory reason field. **so that** run scheduled exams safely and intervene when incidents occur.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-40 → REQ-040

### US-041

**As a** Exam Coordinator, **I want to** allow Exam Coordinators to force-submit a student's exam attempt, finalizing it with all currently persisted answers, with a mandatory reason that is logged. **so that** run scheduled exams safely and intervene when incidents occur.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-41 → REQ-041

### US-042

**As a** Exam Coordinator, **I want to** allow Exam Coordinators to close an exam session before its scheduled end; active students shall receive a grace-period warning before their attempts are force-submitted. **so that** run scheduled exams safely and intervene when incidents occur.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-42 → REQ-042

### US-043

**As a** Teacher; Exam Coordinator, **I want to** allow Teachers and Exam Coordinators to approve retake requests for students, creating a new exam attempt for the approved student. **so that** run scheduled exams safely and intervene when incidents occur.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-43 → REQ-043

### US-044

**As a** Tenant Admin, **I want to** allow Tenant Admins to create courses with a name, description, start date, and end date; students may participate in exam sessions only within a course's active date window. **so that** manage cohorts efficiently while respecting license quotas.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-44 → REQ-044

### US-045

**As a** Tenant Admin, **I want to** allow Tenant Admins to create named groups (classes) within a course and assign Teachers to specific groups; Teachers shall be able to view and manage only students in their assigned groups. **so that** manage cohorts efficiently while respecting license quotas.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-45 → REQ-045

### US-046

**As a** Tenant Admin; Teacher, **I want to** allow Tenant Admins and Teachers to add individual students to a course group by email; if the email does not exist, the system shall create a new student account with an auto-generated password; enrollment shall be blocked at seat quota limit. **so that** manage cohorts efficiently while respecting license quotas.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-46 → REQ-046

### US-047

**As a** Tenant Admin, **I want to** allow Tenant Admins to bulk-import student rosters from CSV or Excel files, auto-creating accounts for new students, validating each row independently, and enforcing seat quota. **so that** manage cohorts efficiently while respecting license quotas.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-47 → REQ-047

### US-048

**As a** Tenant Admin, **I want to** generate a downloadable Excel credential file immediately after bulk student creation; the file shall include plaintext passwords only when exported within 24 hours of account creation; subsequent exports shall mask passwords. **so that** manage cohorts efficiently while respecting license quotas.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-48 → REQ-048

### US-049

**As a** Teacher (students in their classes); Tenant Admin (all students), **I want to** display a student profile page accessible to authorized staff, showing personal information, enrolled courses/classes, exam attempt history, and performance summary. **so that** manage cohorts efficiently while respecting license quotas.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-49 → REQ-049

### US-050

**As a** Tenant Admin; Teacher, **I want to** allow Tenant Admins and Teachers to unenroll a student from a course group; unenrollment shall not delete the student's account or their historical exam records, and shall free one seat. **so that** manage cohorts efficiently while respecting license quotas.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-50 → REQ-050

### US-051

**As a** System (automated enforcement); Tenant Admin (enrollment trigger), **I want to** track real-time seat usage per tenant against the license quota and reject new enrollments when `seats_used ≥ seat_count`. **so that** manage cohorts efficiently while respecting license quotas.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-51 → REQ-051

### US-052

**As a** Student, **I want to** display a chronological list of all exam attempts for a logged-in student, showing per-attempt date, session name, and per-skill band results or "Pending" for unscored skills. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-52 → REQ-052

### US-053

**As a** Student, **I want to** display a band progression line chart for students with ≥ 2 scored attempts, showing one line per skill across all attempt dates. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-53 → REQ-053

### US-054

**As a** Student; Teacher, **I want to** display a per-attempt skill breakdown showing per-part scores for each skill when a student or Teacher views a specific attempt. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-54 → REQ-054

### US-055

**As a** Student, **I want to** compute and display a strengths and weaknesses summary for students with ≥ 2 scored attempts, identifying consistently weak and strong parts across all attempts. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-55 → REQ-055

### US-056

**As a** Student, **I want to** display the teacher-confirmed feedback narrative for Writing and Speaking to the student from the attempt detail screen, after finalization; unconfirmed parts shall show a pending placeholder. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-56 → REQ-056

### US-057

**As a** Teacher, **I want to** display a class-level analytics dashboard for Teachers showing average band per skill and band distribution for a selected class and exam session. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-57 → REQ-057

### US-058

**As a** Teacher, **I want to** display a ranked student list within a class for a selected exam session, ordered by total score, with columns for each skill band; the table shall be sortable by any column. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-58 → REQ-058

### US-059

**As a** Teacher; Tenant Admin, **I want to** highlight students whose band in any skill falls below the configured threshold for a session, in a "weak student alerts" panel accessible to Teachers and Tenant Admins. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-59 → REQ-059

### US-060

**As a** Teacher, **I want to** compute and display the change in average band per skill between the first and most recent scored session for a class, showing improvement or regression with a directional indicator. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-60 → REQ-060

### US-061

**As a** Teacher, **I want to** display a score distribution histogram for a selected class, session, and skill, with bars per band level colored by band. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-61 → REQ-061

### US-062

**As a** Tenant Admin; Viewer, **I want to** provide Tenant Admins and Viewers with a KPI overview dashboard showing total active courses, enrolled students vs. quota, session counts, completion rate, license status, and upcoming sessions. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-62 → REQ-062

### US-063

**As a** Tenant Admin; Viewer, **I want to** display school-wide band distribution charts showing the proportion of students at each APTIS band for each skill, aggregated across all sessions and courses within the tenant. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-63 → REQ-063

### US-064

**As a** Tenant Admin, **I want to** display a summary table of all courses within the tenant showing enrollment count, session count, completion rate, and average band per skill. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-64 → REQ-064

### US-065

**As a** Tenant Admin, **I want to** display the current seat usage as a color-coded progress bar on the Tenant Admin dashboard, with thresholds at 70% (green), 80–89% (yellow), and ≥90% (red). **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-65 → REQ-065

### US-066

**As a** Tenant Admin; Viewer; Teacher, **I want to** allow Tenant Admins, Viewers, and Teachers (scoped to their classes) to export analytics reports as Excel files; all rows (not just the visible page) shall be included; PDF export is Conditional for v1. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-66 → REQ-066

### US-067

**As a** Content Manager, **I want to** compute and display per-question item analysis statistics (correct_rate, wrong_rate per distractor, skip_rate, avg_time_spent) for Content Managers, aggregated globally across all tenants. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-67 → REQ-067

### US-068

**As a** System (automated computation); Content Manager (consumer), **I want to** compute the difficulty index (p-value) per question and automatically flag questions with p-value < 0.3 (Too Hard) or p-value > 0.9 (Too Easy). **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-68 → REQ-068

### US-069

**As a** System (automated computation); Content Manager (consumer), **I want to** compute the point-biserial discrimination index per question and flag questions with index < 0.2 (Poor Discriminator) or index < 0 (Review Required). **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-69 → REQ-069

### US-070

**As a** Content Manager, **I want to** provide Content Managers with a consolidated flagged questions list showing all questions with active item analysis flags, filterable by skill, part, and flag type. **so that** understand performance and make evidence-based teaching decisions.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-70 → REQ-070

### US-071

**As a** Super Admin, **I want to** allow Super Admins to create, activate, suspend, reactivate, and decommission tenant accounts; all status changes shall be logged with timestamp and actor; suspended tenants' users shall receive HTTP 403 on all authenticated requests. **so that** operate tenants and licenses safely across the platform.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-71 → REQ-071

### US-072

**As a** Super Admin, **I want to** allow Super Admins to configure per-tenant settings including timezone, display name, and optional logo URL; changes shall take effect immediately without requiring users to re-login. **so that** operate tenants and licenses safely across the platform.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-72 → REQ-072

### US-073

**As a** Sales Team, **I want to** allow Sales Team members to create seat-based licenses for tenants and to extend expiry dates or adjust seat counts on existing licenses; all changes shall be logged. **so that** operate tenants and licenses safely across the platform.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-73 → REQ-073

### US-074

**As a** System (scheduled alert job), **I want to** send automated email alerts to Tenant Admins and Sales Team when seat usage reaches 80%, 90%, and when the license expires in 30 days and 7 days; alerts shall be idempotent (not repeated for the same threshold crossing). **so that** operate tenants and licenses safely across the platform.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-74 → REQ-074

### US-075

**As a** Super Admin; Support Staff, **I want to** allow Super Admins and Support Staff to view usage statistics per tenant including seats used, exam session counts, student attempt counts, last activity timestamp, and license status; Support Staff access is read-only. **so that** operate tenants and licenses safely across the platform.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-75 → REQ-075

### US-076

**As a** Support Staff, **I want to** allow Support Staff to enter a read-only impersonation view of any tenant portal; all write actions shall be disabled; every impersonation session shall be logged with start time, end time, Support Staff ID, and tenant ID. **so that** operate tenants and licenses safely across the platform.
**Priority:** Conditional
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-76 → REQ-076

### US-077

**As a** Sales Team, **I want to** display a sortable, searchable customer list for Sales Team members showing tenant name, contact email, license status, seats used/total, and expiry date. **so that** manage customer licenses without accessing educational data.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-77 → REQ-077

### US-078

**As a** Sales Team, **I want to** allow Sales Team members to create a new license for a tenant with a seat count and expiry date; the license shall activate immediately on save. **so that** manage customer licenses without accessing educational data.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-78 → REQ-078

### US-079

**As a** Sales Team, **I want to** allow Sales Team members to extend the expiry date of an existing license; extending an expired license shall reactivate the tenant from read-only mode. **so that** manage customer licenses without accessing educational data.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-79 → REQ-079

### US-080

**As a** Sales Team, **I want to** allow Sales Team members to increase or decrease the seat count on a tenant's current license; decreasing below current usage shall be blocked. **so that** manage customer licenses without accessing educational data.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-80 → REQ-080

### US-081

**As a** System (automated on every license change); Sales Team; Super Admin (read-only), **I want to** maintain an immutable history of all license changes per tenant; no license history record shall be deletable by any user role. **so that** manage customer licenses without accessing educational data.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-81 → REQ-081

### US-082

**As a** Sales Team, **I want to** display a prioritized expiry alert panel on the Sales Portal dashboard listing tenants expiring within 30 days, sorted ascending by days remaining. **so that** manage customer licenses without accessing educational data.
**Priority:** Essential
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-82 → REQ-082

### US-083

**As a** System (notification job), **I want to** send email notifications for all defined trigger events using the configured template for each event type and the tenant's configured language; failed sends shall be retried once after 5 minutes. **so that** receive timely operational and result updates.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-83 → REQ-083

### US-084

**As a** System (FCM notification job), **I want to** send push notifications to students on Flutter Mobile (iOS/Android) for student-facing trigger events (session published, T−24h, T−1h, score available), in addition to email; stale device tokens shall be removed on delivery failure. **so that** receive timely operational and result updates.
**Priority:** Conditional
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-84 → REQ-084

### US-085

**As a** Super Admin, **I want to** allow Super Admins to view and edit email templates for all notification types; templates shall support variable substitution and Vietnamese/English language versions; edits shall be versioned with rollback capability. **so that** receive timely operational and result updates.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-85 → REQ-085

### US-086

**As a** Any Tenant-side user, **I want to** allow Tenant-side users to opt out of non-critical notification types; critical notifications (account created, score available, license expiry) shall not be opt-outable. **so that** receive timely operational and result updates.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-86 → REQ-086

### US-087

**As a** System (notification service), **I want to** log every notification attempt with recipient, type, trigger, sent timestamp, delivery status, and provider response; bounced emails shall flag the recipient account. **so that** receive timely operational and result updates.
**Priority:** Essential
**Effort:** L (5pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-87 → REQ-087

### US-088

**As a** Guest (Trial Taker), **I want to** provide a publicly accessible trial landing page (no login required) with a platform description, trial scope summary, a disclaimer, and a "Start Trial" call-to-action that loads in under 3 seconds on standard broadband. **so that** evaluate the platform with minimal friction and explicit consent.
**Priority:** Conditional
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-88 → REQ-088

### US-089

**As a** Guest (Trial Taker), **I want to** provide a limited practice exam for Guest users using a fixed Vendor-configured sample question set; the trial uses the same exam interface as the registered exam. **so that** evaluate the platform with minimal friction and explicit consent.
**Priority:** Conditional
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-89 → REQ-089

### US-090

**As a** Guest (Trial Taker), **I want to** display a simplified result summary to the Guest after trial completion showing estimated bands for scored skills, a disclaimer, and a "Contact Sales" call-to-action. **so that** evaluate the platform with minimal friction and explicit consent.
**Priority:** Conditional
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-90 → REQ-090

### US-091

**As a** Guest (Trial Taker), **I want to** prompt Guest users to optionally provide contact information after trial results; the prompt shall require explicit consent for follow-up; declining shall store no data. **so that** evaluate the platform with minimal friction and explicit consent.
**Priority:** Conditional
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-91 → REQ-091

### US-092

**As a** System (scheduled purge job), **I want to** automatically purge all Guest/Trial session data (anonymous session, trial answers, trial result) after a configurable retention period via a daily scheduled job; purge shall be logged with record count but no PII. **so that** evaluate the platform with minimal friction and explicit consent.
**Priority:** Conditional
**Effort:** M (3pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-92 → REQ-092

### US-093

**As a** System (attempt initialization), **I want to** randomize the order of questions within each exam part for every new attempt using a unique seed stored with the attempt, ensuring the same order is restored on resume. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-93 → REQ-093

### US-094

**As a** System (attempt initialization), **I want to** randomize the order of MCQ answer options for each attempt using the same shuffle seed as question order; auto-scoring shall match against answer content, not option position. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-94 → REQ-094

### US-095

**As a** Student, **I want to** require students to enter fullscreen mode before beginning the exam; the exam shall not start until fullscreen is confirmed active; exiting fullscreen during the exam shall trigger a violation event. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-95 → REQ-095

### US-096

**As a** Student (inadvertent or deliberate action); System (detection), **I want to** detect when a student switches to a different browser tab or minimizes the exam window during an active exam and log each occurrence as a violation event; violation count shall accumulate toward the configured thresholds. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-96 → REQ-096

### US-097

**As a** Student; System (detection), **I want to** detect OS-level focus loss on Flutter Desktop (Alt-Tab, window minimize) and log it as a `focus_loss` violation event contributing to the same violation counter as tab switching. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-97 → REQ-097

### US-098

**As a** Student, **I want to** silently block copy (Ctrl+C), paste (Ctrl+V), and right-click context menu actions within all exam content areas; text selection in reading passages shall be disabled; writing inputs shall allow typing but block clipboard paste. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-98 → REQ-098

### US-099

**As a** Student, **I want to** intercept browser back button, address bar navigation, F5/Ctrl+R refresh, and window close during an active exam; a warning dialog shall appear for navigation-away attempts; page reload shall trigger the resume flow (FR-106). **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-99 → REQ-099

### US-100

**As a** System (automated enforcement), **I want to** enforce configurable violation thresholds per exam session: displaying an in-exam warning when `violation_count` reaches `warning_threshold`, and auto-submitting the attempt when `violation_count` reaches `terminate_threshold`. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-100 → REQ-100

### US-101

**As a** System (automated logging), **I want to** maintain an immutable log of all anti-cheat violation events per attempt, storing violation type, timestamp, and cumulative count at the time of each event; no user role shall be able to delete violation records. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-101 → REQ-101

### US-102

**As a** System (OS-level control); Student, **I want to** request OS-level window locking on Flutter Desktop to prevent students from switching to other applications during the exam; where OS-level lock is unavailable, the system shall fall back to detection-based violation logging. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Conditional
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-102 → REQ-102

### US-103

**As a** Exam Coordinator; Tenant Admin, **I want to** generate a per-session integrity report accessible to Exam Coordinators and Tenant Admins after a session closes, listing all students with violation counts, types, and outcome; the report shall be exportable to Excel. **so that** preserve the integrity and auditability of exam attempts.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-103 → REQ-103

### US-104

**As a** System (server-side timer); Student (display consumer), **I want to** track exam part timers exclusively on the server; the client shall synchronize displayed time from the server every 10 seconds; client-side clock manipulation shall not affect the server-side timer or part expiry. **so that** avoid losing exam progress during network or device failures.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-104 → REQ-104

### US-105

**As a** Student, **I want to** persist every student answer to the server immediately upon entry; batch submission at exam end shall not be used as the primary persistence mechanism; unsaved answers shall be retried up to 3 times on network error. **so that** avoid losing exam progress during network or device failures.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-105 → REQ-105

### US-106

**As a** Student, **I want to** allow a student who disconnected during an exam to resume from exactly the last saved state, including current part, question position, all previously saved answers, and the remaining server-authoritative time. **so that** avoid losing exam progress during network or device failures.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-106 → REQ-106

### US-107

**As a** Student, **I want to** detect network connectivity loss during an exam and display a persistent non-blocking indicator; the student shall be able to continue answering questions with answers buffered locally; buffered answers shall be flushed to the server on reconnection. **so that** avoid losing exam progress during network or device failures.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-107 → REQ-107

### US-108

**As a** Student, **I want to** record Speaking audio into a local buffer and upload to Cloud Storage during or immediately after recording; on upload failure, the local buffer shall be retained and retried with exponential backoff without blocking the student from continuing. **so that** avoid losing exam progress during network or device failures.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-108 → REQ-108

### US-109

**As a** System (on interruption detection), **I want to** preserve and upload partial Speaking recordings when recording is interrupted mid-way; partial recordings shall be flagged for manual teacher review and not auto-discarded. **so that** avoid losing exam progress during network or device failures.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-109 → REQ-109

### US-110

**As a** Student, **I want to** detect microphone failure at the start of the Speaking skill and present the student with troubleshooting steps and retry capability; the exam shall not auto-terminate due to microphone failure; the student shall be able to signal the proctor. **so that** avoid losing exam progress during network or device failures.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-110 → REQ-110

### US-111

**As a** Student, **I want to** allow a student to fully recover their exam session after a browser crash or app force-close, restoring all previously saved answers and resuming with the server-authoritative timer; Speaking audio buffered locally before the crash shall be uploaded on reconnection. **so that** avoid losing exam progress during network or device failures.
**Priority:** Essential
**Effort:** XL (8pt)
**Acceptance:** → acceptance-criteria.md
**Traceability:** FR-111 → REQ-111

## Story ID Index

| ID | Title | Priority | Effort | Actor |
|---|---|---|---|---|
| US-001 | authenticate users via email and password, scoping the login context to the tenant identified b | Essential | M (3pt) | Any registered user (all roles) |
| US-002 | issue a short-lived JWT access token (TTL ≤ 15 minutes) and a long-lived rotating refresh token | Essential | M (3pt) | Any authenticated user (client-initiated); Authentication service |
| US-003 | resolve the tenant context from the `Host` header subdomain of every incoming request and scope | Essential | M (3pt) | API Gateway middleware (automated) |
| US-004 | support assigning multiple roles simultaneously to a single Tenant-side user | Essential | M (3pt) | Tenant Admin |
| US-005 | provide a password reset flow via email for all registered users | Essential | M (3pt) | Any registered user (all roles) |
| US-006 | force students who log in for the first time using a bulk-generated password to change their pa | Essential | M (3pt) | Student |
| US-007 | invalidate a user's refresh token upon logout | Essential | M (3pt) | Any authenticated user (self-logout); Super Admin (force-logout) |
| US-008 | allow unauthenticated users to access the trial landing page and trial exam without creating an | Essential | M (3pt) | Guest (Trial Taker) |
| US-009 | allow Content Managers to create, read, update, and delete questions in the APTIS question bank | Essential | L (5pt) | Content Manager |
| US-010 | allow Content Managers to upload audio files (MP3, WAV) for Listening questions and deliver the | Essential | L (5pt) | Content Manager |
| US-011 | allow Content Managers to upload image files (JPEG, PNG, ≤ 10 MB) and associate them with Speak | Essential | L (5pt) | Content Manager |
| US-012 | allow Content Managers to create named exam templates by selecting questions per skill and part | Essential | L (5pt) | Content Manager |
| US-013 | provide a preview mode allowing Content Managers to experience a question or full exam template | Essential | L (5pt) | Content Manager |
| US-014 | preserve the version of every question used in a completed exam session | Essential | L (5pt) | Content Manager (edit trigger); system (automatic versioning) |
| US-015 | allow Content Managers to import questions in bulk from CSV or Excel files conforming to the pr | Essential | L (5pt) | Content Manager |
| US-016 | compute and display per-question item analysis statistics for Content Managers, aggregated glob | Essential | L (5pt) | Content Manager |
| US-017 | verify student eligibility before launching an exam session | Essential | XL (8pt) | Student |
| US-018 | run three sequential pre-exam checks before the student begins the first skill: microphone dete | Essential | XL (8pt) | Student |
| US-019 | maintain authoritative exam part timers on the server | Essential | XL (8pt) | System (automated timer enforcement) |
| US-020 | render each Reading part with its correct interaction type: Part A (sentence matching), Part B  | Essential | XL (8pt) | Student |
| US-021 | render Writing parts with appropriate text input areas and display a live word count | Essential | XL (8pt) | Student |
| US-022 | auto-play Listening audio | Essential | XL (8pt) | Student |
| US-023 | implement a five-stage Speaking sequence per part: instruction/image display, preparation count | Essential | XL (8pt) | Student |
| US-024 | display a transition screen between exam parts showing the completed part, the next part, time  | Essential | XL (8pt) | Student |
| US-025 | sequence exam skills in the order defined by the exam template (default: Reading → Listening →  | Essential | XL (8pt) | Student (passive); System (timer enforcement) |
| US-026 | finalize the exam attempt | Essential | XL (8pt) | Student (natural completion); System (automatic on session close or timer expiry) |
| US-027 | automatically compute scores for Reading and Listening immediately after exam submission by com | Essential | XL (8pt) | System (automated scoring job) |
| US-028 | convert raw scores for Reading and Listening into APTIS band levels (A1, A2, B1, B2, C) using t | Essential | XL (8pt) | System (automated) |
| US-029 | make Reading and Listening band results available to the student within 2 minutes of exam submi | Essential | XL (8pt) | System (automated); Student (consumer) |
| US-030 | submit each Speaking audio recording to the configured STT API and store the resulting transcri | Essential | XL (8pt) | System (AI scoring pipeline) |
| US-031 | submit Writing text responses and Speaking transcripts to the configured LLM API with APTIS rub | Essential | XL (8pt) | System (AI scoring pipeline) |
| US-032 | present Teachers with a queue of Writing and Speaking submissions pending human review, sorted  | Essential | XL (8pt) | Teacher |
| US-033 | allow Teachers to confirm AI draft scores as-is or override individual criterion scores and fee | Essential | XL (8pt) | Teacher |
| US-034 | display a personal results dashboard for each student showing all past attempts with per-skill  | Essential | XL (8pt) | Student |
| US-035 | display a four-skill band profile summary (Reading, Writing, Listening, Speaking bands) for any | Essential | XL (8pt) | Student; Teacher (when viewing a student's attempt) |
| US-036 | display the teacher-confirmed feedback narrative for Writing and Speaking to the student, acces | Essential | XL (8pt) | Student |
| US-037 | allow Teachers and Exam Coordinators to create exam sessions by specifying a session name, exam | Essential | L (5pt) | Teacher; Exam Coordinator |
| US-038 | automatically send email notifications to all enrolled students | Essential | L (5pt) | System (notification scheduler) |
| US-039 | provide Exam Coordinators with a real-time dashboard showing per-student status during an activ | Essential | L (5pt) | Exam Coordinator |
| US-040 | allow Exam Coordinators to extend the remaining time for a specific student's attempt | Essential | L (5pt) | Exam Coordinator |
| US-041 | allow Exam Coordinators to force-submit a student's exam attempt, finalizing it with all curren | Essential | L (5pt) | Exam Coordinator |
| US-042 | allow Exam Coordinators to close an exam session before its scheduled end | Essential | L (5pt) | Exam Coordinator |
| US-043 | allow Teachers and Exam Coordinators to approve retake requests for students, creating a new ex | Essential | L (5pt) | Teacher; Exam Coordinator |
| US-044 | allow Tenant Admins to create courses with a name, description, start date, and end date | Essential | M (3pt) | Tenant Admin |
| US-045 | allow Tenant Admins to create named groups (classes) within a course and assign Teachers to spe | Essential | M (3pt) | Tenant Admin |
| US-046 | allow Tenant Admins and Teachers to add individual students to a course group by email | Essential | M (3pt) | Tenant Admin; Teacher |
| US-047 | allow Tenant Admins to bulk-import student rosters from CSV or Excel files, auto-creating accou | Essential | M (3pt) | Tenant Admin |
| US-048 | generate a downloadable Excel credential file immediately after bulk student creation | Essential | M (3pt) | Tenant Admin |
| US-049 | display a student profile page accessible to authorized staff, showing personal information, en | Essential | M (3pt) | Teacher (students in their classes); Tenant Admin (all students) |
| US-050 | allow Tenant Admins and Teachers to unenroll a student from a course group | Essential | M (3pt) | Tenant Admin; Teacher |
| US-051 | track real-time seat usage per tenant against the license quota and reject new enrollments | Essential | M (3pt) | System (automated enforcement); Tenant Admin (enrollment trigger) |
| US-052 | display a chronological list of all exam attempts for a logged-in student, showing per-attempt  | Essential | L (5pt) | Student |
| US-053 | display a band progression line chart for students with ≥ 2 scored attempts, showing one line p | Essential | L (5pt) | Student |
| US-054 | display a per-attempt skill breakdown showing per-part scores for each skill | Essential | L (5pt) | Student; Teacher |
| US-055 | compute and display a strengths and weaknesses summary for students with ≥ 2 scored attempts, i | Essential | L (5pt) | Student |
| US-056 | display the teacher-confirmed feedback narrative for Writing and Speaking to the student from t | Essential | L (5pt) | Student |
| US-057 | display a class-level analytics dashboard for Teachers showing average band per skill and band  | Essential | L (5pt) | Teacher |
| US-058 | display a ranked student list within a class for a selected exam session, ordered by total scor | Essential | L (5pt) | Teacher |
| US-059 | highlight students whose band in any skill falls below the configured threshold for a session,  | Essential | L (5pt) | Teacher; Tenant Admin |
| US-060 | compute and display the change in average band per skill between the first and most recent scor | Essential | L (5pt) | Teacher |
| US-061 | display a score distribution histogram for a selected class, session, and skill, with bars per  | Essential | L (5pt) | Teacher |
| US-062 | provide Tenant Admins and Viewers with a KPI overview dashboard showing total active courses, e | Essential | L (5pt) | Tenant Admin; Viewer |
| US-063 | display school-wide band distribution charts showing the proportion of students at each APTIS b | Essential | L (5pt) | Tenant Admin; Viewer |
| US-064 | display a summary table of all courses within the tenant showing enrollment count, session coun | Essential | L (5pt) | Tenant Admin |
| US-065 | display the current seat usage as a color-coded progress bar on the Tenant Admin dashboard, wit | Essential | L (5pt) | Tenant Admin |
| US-066 | allow Tenant Admins, Viewers, and Teachers (scoped to their classes) to export analytics report | Essential | L (5pt) | Tenant Admin; Viewer; Teacher |
| US-067 | compute and display per-question item analysis statistics (correct_rate, wrong_rate per distrac | Essential | L (5pt) | Content Manager |
| US-068 | compute the difficulty index (p-value) per question and automatically flag questions with p-val | Essential | L (5pt) | System (automated computation); Content Manager (consumer) |
| US-069 | compute the point-biserial discrimination index per question and flag questions with index < 0 | Essential | L (5pt) | System (automated computation); Content Manager (consumer) |
| US-070 | provide Content Managers with a consolidated flagged questions list showing all questions with  | Essential | L (5pt) | Content Manager |
| US-071 | allow Super Admins to create, activate, suspend, reactivate, and decommission tenant accounts | Essential | M (3pt) | Super Admin |
| US-072 | allow Super Admins to configure per-tenant settings including timezone, display name, and optio | Essential | M (3pt) | Super Admin |
| US-073 | allow Sales Team members to create seat-based licenses for tenants and to extend expiry dates o | Essential | M (3pt) | Sales Team |
| US-074 | send automated email alerts to Tenant Admins and Sales Team | Essential | M (3pt) | System (scheduled alert job) |
| US-075 | allow Super Admins and Support Staff to view usage statistics per tenant including seats used,  | Essential | M (3pt) | Super Admin; Support Staff |
| US-076 | allow Support Staff to enter a read-only impersonation view of any tenant portal | Conditional | M (3pt) | Support Staff |
| US-077 | display a sortable, searchable customer list for Sales Team members showing tenant name, contac | Essential | M (3pt) | Sales Team |
| US-078 | allow Sales Team members to create a new license for a tenant with a seat count and expiry date | Essential | M (3pt) | Sales Team |
| US-079 | allow Sales Team members to extend the expiry date of an existing license | Essential | M (3pt) | Sales Team |
| US-080 | allow Sales Team members to increase or decrease the seat count on a tenant's current license | Essential | M (3pt) | Sales Team |
| US-081 | maintain an immutable history of all license changes per tenant | Essential | M (3pt) | System (automated on every license change); Sales Team; Super Admin (read-only) |
| US-082 | display a prioritized expiry alert panel on the Sales Portal dashboard listing tenants expiring | Essential | M (3pt) | Sales Team |
| US-083 | send email notifications for all defined trigger events using the configured template for each  | Essential | L (5pt) | System (notification job) |
| US-084 | send push notifications to students on Flutter Mobile (iOS/Android) for student-facing trigger  | Conditional | L (5pt) | System (FCM notification job) |
| US-085 | allow Super Admins to view and edit email templates for all notification types | Essential | L (5pt) | Super Admin |
| US-086 | allow Tenant-side users to opt out of non-critical notification types | Essential | L (5pt) | Any Tenant-side user |
| US-087 | log every notification attempt with recipient, type, trigger, sent timestamp, delivery status,  | Essential | L (5pt) | System (notification service) |
| US-088 | provide a publicly accessible trial landing page (no login required) with a platform descriptio | Conditional | M (3pt) | Guest (Trial Taker) |
| US-089 | provide a limited practice exam for Guest users using a fixed Vendor-configured sample question | Conditional | M (3pt) | Guest (Trial Taker) |
| US-090 | display a simplified result summary to the Guest after trial completion showing estimated bands | Conditional | M (3pt) | Guest (Trial Taker) |
| US-091 | prompt Guest users to optionally provide contact information after trial results | Conditional | M (3pt) | Guest (Trial Taker) |
| US-092 | automatically purge all Guest/Trial session data (anonymous session, trial answers, trial resul | Conditional | M (3pt) | System (scheduled purge job) |
| US-093 | randomize the order of questions within each exam part for every new attempt using a unique see | Essential | XL (8pt) | System (attempt initialization) |
| US-094 | randomize the order of MCQ answer options for each attempt using the same shuffle seed as quest | Essential | XL (8pt) | System (attempt initialization) |
| US-095 | require students to enter fullscreen mode before beginning the exam | Essential | XL (8pt) | Student |
| US-096 | detect | Essential | XL (8pt) | Student (inadvertent or deliberate action); System (detection) |
| US-097 | detect OS-level focus loss on Flutter Desktop (Alt-Tab, window minimize) and log it as a `focus | Essential | XL (8pt) | Student; System (detection) |
| US-098 | silently block copy (Ctrl+C), paste (Ctrl+V), and right-click context menu actions within all e | Essential | XL (8pt) | Student |
| US-099 | intercept browser back button, address bar navigation, F5/Ctrl+R refresh, and window close duri | Essential | XL (8pt) | Student |
| US-100 | enforce configurable violation thresholds per exam session: displaying an in-exam warning | Essential | XL (8pt) | System (automated enforcement) |
| US-101 | maintain an immutable log of all anti-cheat violation events per attempt, storing violation typ | Essential | XL (8pt) | System (automated logging) |
| US-102 | request OS-level window locking on Flutter Desktop to prevent students from switching to other  | Conditional | XL (8pt) | System (OS-level control); Student |
| US-103 | generate a per-session integrity report accessible to Exam Coordinators and Tenant Admins after | Essential | XL (8pt) | Exam Coordinator; Tenant Admin |
| US-104 | track exam part timers exclusively on the server | Essential | XL (8pt) | System (server-side timer); Student (display consumer) |
| US-105 | persist every student answer to the server immediately upon entry | Essential | XL (8pt) | Student |
| US-106 | allow a student who disconnected during an exam to resume from exactly the last saved state, in | Essential | XL (8pt) | Student |
| US-107 | detect network connectivity loss during an exam and display a persistent non-blocking indicator | Essential | XL (8pt) | Student |
| US-108 | record Speaking audio into a local buffer and upload to Cloud Storage during or immediately aft | Essential | XL (8pt) | Student |
| US-109 | preserve and upload partial Speaking recordings | Essential | XL (8pt) | System (on interruption detection) |
| US-110 | detect microphone failure at the start of the Speaking skill and present the student with troub | Essential | XL (8pt) | Student |
| US-111 | allow a student to fully recover their exam session after a browser crash or app force-close, r | Essential | XL (8pt) | Student |
