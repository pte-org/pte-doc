# Requirements — APTIS LMS

## Executive Summary

APTIS LMS is a multi-tenant B2B2C SaaS platform for Vietnamese schools and training centers to administer high-fidelity APTIS practice examinations. It combines Vendor content and license operations, Tenant learner and exam management, and a resilient Flutter exam client, with AI-assisted but human-confirmed Writing and Speaking scoring.

## Problem Statement

Schools and training centers lack a single platform that faithfully simulates the four-skill APTIS exam, manages large learner cohorts and exam sessions, and turns results into actionable individual, class, tenant, and item-level analytics. Without it, exam operations are fragmented, Speaking/Writing review is slow, and network or device incidents create unacceptable risks of lost student work.

## Requirements

REQ-001: The system shall authenticate users via email and password, scoping the login context to the tenant identified by the current request subdomain, and reject credentials that do not belong to that tenant. **Source:** FR-01 (Authentication & Access).
REQ-002: The system shall issue a short-lived JWT access token (TTL ≤ 15 minutes) and a long-lived rotating refresh token (TTL ≤ 7 days) on successful authentication; the system shall issue a new access token and invalidate the old refresh token when a valid refresh token is presented. **Source:** FR-02 (Authentication & Access).
REQ-003: The system shall resolve the tenant context from the `Host` header subdomain of every incoming request and scope all data operations exclusively to that tenant's `tenant_id`; requests to `admin.aptis-lms.vn` shall route to the Vendor Portal with no tenant scoping. **Source:** FR-03 (Authentication & Access).
REQ-004: The system shall support assigning multiple roles simultaneously to a single Tenant-side user; the user's effective permissions shall be the union of all assigned roles' permission sets; adding or removing a role shall take effect on the user's next authenticated request. **Source:** FR-04 (Authentication & Access).
REQ-005: The system shall provide a password reset flow via email for all registered users; the reset link shall be time-limited to 1 hour, single-use, and scoped to the user's portal domain. **Source:** FR-05 (Authentication & Access).
REQ-006: The system shall force students who log in for the first time using a bulk-generated password to change their password before accessing any other screen, when the tenant has `force_password_change` enabled. **Source:** FR-06 (Authentication & Access).
REQ-007: The system shall invalidate a user's refresh token upon logout; a Super Admin shall be able to force-invalidate all active sessions of any user across all devices. **Source:** FR-07 (Authentication & Access).
REQ-008: The system shall allow unauthenticated users to access the trial landing page and trial exam without creating an account, issuing a short-lived anonymous session token valid for the trial duration only. **Source:** FR-08 (Authentication & Access).
REQ-009: The system shall allow Content Managers to create, read, update, and delete questions in the APTIS question bank; each question record shall store skill, part, question_type, content, answer_key (auto-score types), rubric_criteria (human-score types), difficulty_tag, and topic_tags. **Source:** FR-09 (Question Bank Management).
REQ-010: The system shall allow Content Managers to upload audio files (MP3, WAV) for Listening questions and deliver them to exam clients via CDN with per-part play-count limits. **Source:** FR-10 (Question Bank Management).
REQ-011: The system shall allow Content Managers to upload image files (JPEG, PNG, ≤ 10 MB) and associate them with Speaking Part B (single image) and Part D (image pair) questions. **Source:** FR-11 (Question Bank Management).
REQ-012: The system shall allow Content Managers to create named exam templates by selecting questions per skill and part, or by specifying auto-fill criteria; a template shall be publishable only when all required skills and parts are covered. **Source:** FR-12 (Question Bank Management).
REQ-013: The system shall provide a preview mode allowing Content Managers to experience a question or full exam template as a student would, including audio playback, image rendering, and timer display, without creating any exam attempt record. **Source:** FR-13 (Question Bank Management).
REQ-014: The system shall preserve the version of every question used in a completed exam session; editing such a question shall create a new version (current) while leaving the original version (immutable) linked to prior sessions. **Source:** FR-14 (Question Bank Management).
REQ-015: The system shall allow Content Managers to import questions in bulk from CSV or Excel files conforming to the prescribed import template; the system shall validate each row independently and report errors per row before committing any data. **Source:** FR-15 (Question Bank Management).
REQ-016: The system shall compute and display per-question item analysis statistics for Content Managers, aggregated globally across all tenants, and automatically flag questions with statistically outlier difficulty or discrimination indices. **Source:** FR-16 (Question Bank Management).
REQ-017: The system shall verify student eligibility before launching an exam session; eligibility requires that the student is enrolled, the session window is open, and no completed attempt exists for this session by this student. **Source:** FR-17 (Exam Simulation).
REQ-018: The system shall run three sequential pre-exam checks before the student begins the first skill: microphone detection and test recording, fullscreen mode activation, and per-skill instruction acknowledgment; all three must pass before the exam starts. **Source:** FR-18 (Exam Simulation).
REQ-019: The system shall maintain authoritative exam part timers on the server; when `time_remaining` reaches zero, the server shall close the current part and advance the student to the next part regardless of client state; no client-side action is required to trigger the advance. **Source:** FR-19 (Exam Simulation).
REQ-020: The system shall render each Reading part with its correct interaction type: Part A (sentence matching), Part B (gap-fill with dropdown), Part C (MCQ with scrollable passage), Part D (short-answer text input with passage); student answers shall be persisted per question as entered. **Source:** FR-20 (Exam Simulation).
REQ-021: The system shall render Writing parts with appropriate text input areas and display a live word count; the word count indicator shall change color based on proximity to the configured minimum and maximum word limits. **Source:** FR-21 (Exam Simulation).
REQ-022: The system shall auto-play Listening audio when a student enters each Listening question; the student shall not be able to seek, rewind, or replay beyond the configured `max_play_count`; questions shall be answerable simultaneously with audio playback. **Source:** FR-22 (Exam Simulation).
REQ-023: The system shall implement a five-stage Speaking sequence per part: instruction/image display, preparation countdown, recording with live waveform, auto-stop at recording time limit, and upload with progress indicator; audio shall be buffered locally and uploaded to Cloud Storage. **Source:** FR-23 (Exam Simulation).
REQ-024: The system shall display a transition screen between exam parts showing the completed part, the next part, time allowed for the next part, and a countdown to auto-advance; back navigation to the completed part is blocked. **Source:** FR-24 (Exam Simulation).
REQ-025: The system shall sequence exam skills in the order defined by the exam template (default: Reading → Listening → Writing → Speaking); between-skill breaks shall be configurable per template; the next skill timer shall not start until the break countdown expires. **Source:** FR-25 (Exam Simulation).
REQ-026: The system shall finalize the exam attempt when all skills are completed or when the session window closes; finalization shall persist all remaining answers, set `attempt.status = submitted`, and trigger the scoring pipeline. **Source:** FR-26 (Exam Simulation).
REQ-027: The system shall automatically compute scores for Reading and Listening immediately after exam submission by comparing each student answer against the stored answer key. **Source:** FR-27 (Scoring).
REQ-028: The system shall convert raw scores for Reading and Listening into APTIS band levels (A1, A2, B1, B2, C) using the Vendor-configured band mapping table; out-of-range scores shall be flagged as `MAPPING_ERROR`. **Source:** FR-28 (Scoring).
REQ-029: The system shall make Reading and Listening band results available to the student within 2 minutes of exam submission completion. **Source:** FR-29 (Scoring).
REQ-030: The system shall submit each Speaking audio recording to the configured STT API and store the resulting transcript per part; on permanent API failure after 3 retries, the part shall be flagged `STT_FAILED` for manual teacher review. **Source:** FR-30 (Scoring).
REQ-031: The system shall submit Writing text responses and Speaking transcripts to the configured LLM API with APTIS rubric prompts; the resulting draft score shall be stored with `status = draft` and shall not be visible to the student until a teacher confirms it. **Source:** FR-31 (Scoring).
REQ-032: The system shall present Teachers with a queue of Writing and Speaking submissions pending human review, sorted by submission time (oldest first), showing student response, AI draft scores, and feedback narrative. **Source:** FR-32 (Scoring).
REQ-033: The system shall allow Teachers to confirm AI draft scores as-is or override individual criterion scores and feedback narrative; upon confirmation, scores shall be finalized and made available to the student. **Source:** FR-33 (Scoring).
REQ-034: The system shall display a personal results dashboard for each student showing all past attempts with per-skill bands, a progression chart, and a part-level breakdown for each completed attempt. **Source:** FR-34 (Scoring).
REQ-035: The system shall display a four-skill band profile summary (Reading, Writing, Listening, Speaking bands) for any fully scored attempt, with each band shown alongside a CEFR-aligned descriptor. **Source:** FR-35 (Scoring).
REQ-036: The system shall display the teacher-confirmed feedback narrative for Writing and Speaking to the student, accessible from the attempt detail screen, after the score is finalized. **Source:** FR-36 (Scoring).
REQ-037: The system shall allow Teachers and Exam Coordinators to create exam sessions by specifying a session name, exam template, participant scope, open/close datetime window, and anti-cheat configuration. **Source:** FR-37 (Exam Scheduling & Deployment).
REQ-038: The system shall automatically send email notifications to all enrolled students when an exam session is created and at T−24h and T−1h before the session opens. **Source:** FR-38 (Exam Scheduling & Deployment).
REQ-039: The system shall provide Exam Coordinators with a real-time dashboard showing per-student status during an active exam session, updated via WebSocket or SSE without page reload. **Source:** FR-39 (Exam Scheduling & Deployment).
REQ-040: The system shall allow Exam Coordinators to extend the remaining time for a specific student's attempt; the extension must be logged with a mandatory reason field. **Source:** FR-40 (Exam Scheduling & Deployment).
REQ-041: The system shall allow Exam Coordinators to force-submit a student's exam attempt, finalizing it with all currently persisted answers, with a mandatory reason that is logged. **Source:** FR-41 (Exam Scheduling & Deployment).
REQ-042: The system shall allow Exam Coordinators to close an exam session before its scheduled end; active students shall receive a grace-period warning before their attempts are force-submitted. **Source:** FR-42 (Exam Scheduling & Deployment).
REQ-043: The system shall allow Teachers and Exam Coordinators to approve retake requests for students, creating a new exam attempt for the approved student. **Source:** FR-43 (Exam Scheduling & Deployment).
REQ-044: The system shall allow Tenant Admins to create courses with a name, description, start date, and end date; students may participate in exam sessions only within a course's active date window. **Source:** FR-44 (Learner Management).
REQ-045: The system shall allow Tenant Admins to create named groups (classes) within a course and assign Teachers to specific groups; Teachers shall be able to view and manage only students in their assigned groups. **Source:** FR-45 (Learner Management).
REQ-046: The system shall allow Tenant Admins and Teachers to add individual students to a course group by email; if the email does not exist, the system shall create a new student account with an auto-generated password; enrollment shall be blocked at seat quota limit. **Source:** FR-46 (Learner Management).
REQ-047: The system shall allow Tenant Admins to bulk-import student rosters from CSV or Excel files, auto-creating accounts for new students, validating each row independently, and enforcing seat quota. **Source:** FR-47 (Learner Management).
REQ-048: The system shall generate a downloadable Excel credential file immediately after bulk student creation; the file shall include plaintext passwords only when exported within 24 hours of account creation; subsequent exports shall mask passwords. **Source:** FR-48 (Learner Management).
REQ-049: The system shall display a student profile page accessible to authorized staff, showing personal information, enrolled courses/classes, exam attempt history, and performance summary. **Source:** FR-49 (Learner Management).
REQ-050: The system shall allow Tenant Admins and Teachers to unenroll a student from a course group; unenrollment shall not delete the student's account or their historical exam records, and shall free one seat. **Source:** FR-50 (Learner Management).
REQ-051: The system shall track real-time seat usage per tenant against the license quota and reject new enrollments when `seats_used ≥ seat_count`. **Source:** FR-51 (Learner Management).
REQ-052: The system shall display a chronological list of all exam attempts for a logged-in student, showing per-attempt date, session name, and per-skill band results or "Pending" for unscored skills. **Source:** FR-52 (Analytics & Reporting).
REQ-053: The system shall display a band progression line chart for students with ≥ 2 scored attempts, showing one line per skill across all attempt dates. **Source:** FR-53 (Analytics & Reporting).
REQ-054: The system shall display a per-attempt skill breakdown showing per-part scores for each skill when a student or Teacher views a specific attempt. **Source:** FR-54 (Analytics & Reporting).
REQ-055: The system shall compute and display a strengths and weaknesses summary for students with ≥ 2 scored attempts, identifying consistently weak and strong parts across all attempts. **Source:** FR-55 (Analytics & Reporting).
REQ-056: The system shall display the teacher-confirmed feedback narrative for Writing and Speaking to the student from the attempt detail screen, after finalization; unconfirmed parts shall show a pending placeholder. **Source:** FR-56 (Analytics & Reporting).
REQ-057: The system shall display a class-level analytics dashboard for Teachers showing average band per skill and band distribution for a selected class and exam session. **Source:** FR-57 (Analytics & Reporting).
REQ-058: The system shall display a ranked student list within a class for a selected exam session, ordered by total score, with columns for each skill band; the table shall be sortable by any column. **Source:** FR-58 (Analytics & Reporting).
REQ-059: The system shall highlight students whose band in any skill falls below the configured threshold for a session, in a "weak student alerts" panel accessible to Teachers and Tenant Admins. **Source:** FR-59 (Analytics & Reporting).
REQ-060: The system shall compute and display the change in average band per skill between the first and most recent scored session for a class, showing improvement or regression with a directional indicator. **Source:** FR-60 (Analytics & Reporting).
REQ-061: The system shall display a score distribution histogram for a selected class, session, and skill, with bars per band level colored by band. **Source:** FR-61 (Analytics & Reporting).
REQ-062: The system shall provide Tenant Admins and Viewers with a KPI overview dashboard showing total active courses, enrolled students vs. quota, session counts, completion rate, license status, and upcoming sessions. **Source:** FR-62 (Analytics & Reporting).
REQ-063: The system shall display school-wide band distribution charts showing the proportion of students at each APTIS band for each skill, aggregated across all sessions and courses within the tenant. **Source:** FR-63 (Analytics & Reporting).
REQ-064: The system shall display a summary table of all courses within the tenant showing enrollment count, session count, completion rate, and average band per skill. **Source:** FR-64 (Analytics & Reporting).
REQ-065: The system shall display the current seat usage as a color-coded progress bar on the Tenant Admin dashboard, with thresholds at 70% (green), 80–89% (yellow), and ≥90% (red). **Source:** FR-65 (Analytics & Reporting).
REQ-066: The system shall allow Tenant Admins, Viewers, and Teachers (scoped to their classes) to export analytics reports as Excel files; all rows (not just the visible page) shall be included; PDF export is Conditional for v1. **Source:** FR-66 (Analytics & Reporting).
REQ-067: The system shall compute and display per-question item analysis statistics (correct_rate, wrong_rate per distractor, skip_rate, avg_time_spent) for Content Managers, aggregated globally across all tenants. **Source:** FR-67 (Analytics & Reporting).
REQ-068: The system shall compute the difficulty index (p-value) per question and automatically flag questions with p-value < 0.3 (Too Hard) or p-value > 0.9 (Too Easy). **Source:** FR-68 (Analytics & Reporting).
REQ-069: The system shall compute the point-biserial discrimination index per question and flag questions with index < 0.2 (Poor Discriminator) or index < 0 (Review Required). **Source:** FR-69 (Analytics & Reporting).
REQ-070: The system shall provide Content Managers with a consolidated flagged questions list showing all questions with active item analysis flags, filterable by skill, part, and flag type. **Source:** FR-70 (Analytics & Reporting).
REQ-071: The system shall allow Super Admins to create, activate, suspend, reactivate, and decommission tenant accounts; all status changes shall be logged with timestamp and actor; suspended tenants' users shall receive HTTP 403 on all authenticated requests. **Source:** FR-71 (Vendor Management).
REQ-072: The system shall allow Super Admins to configure per-tenant settings including timezone, display name, and optional logo URL; changes shall take effect immediately without requiring users to re-login. **Source:** FR-72 (Vendor Management).
REQ-073: The system shall allow Sales Team members to create seat-based licenses for tenants and to extend expiry dates or adjust seat counts on existing licenses; all changes shall be logged. **Source:** FR-73 (Vendor Management).
REQ-074: The system shall send automated email alerts to Tenant Admins and Sales Team when seat usage reaches 80%, 90%, and when the license expires in 30 days and 7 days; alerts shall be idempotent (not repeated for the same threshold crossing). **Source:** FR-74 (Vendor Management).
REQ-075: The system shall allow Super Admins and Support Staff to view usage statistics per tenant including seats used, exam session counts, student attempt counts, last activity timestamp, and license status; Support Staff access is read-only. **Source:** FR-75 (Vendor Management).
REQ-076: The system shall allow Support Staff to enter a read-only impersonation view of any tenant portal; all write actions shall be disabled; every impersonation session shall be logged with start time, end time, Support Staff ID, and tenant ID. **Source:** FR-76 (Vendor Management).
REQ-077: The system shall display a sortable, searchable customer list for Sales Team members showing tenant name, contact email, license status, seats used/total, and expiry date. **Source:** FR-77 (Sales Portal).
REQ-078: The system shall allow Sales Team members to create a new license for a tenant with a seat count and expiry date; the license shall activate immediately on save. **Source:** FR-78 (Sales Portal).
REQ-079: The system shall allow Sales Team members to extend the expiry date of an existing license; extending an expired license shall reactivate the tenant from read-only mode. **Source:** FR-79 (Sales Portal).
REQ-080: The system shall allow Sales Team members to increase or decrease the seat count on a tenant's current license; decreasing below current usage shall be blocked. **Source:** FR-80 (Sales Portal).
REQ-081: The system shall maintain an immutable history of all license changes per tenant; no license history record shall be deletable by any user role. **Source:** FR-81 (Sales Portal).
REQ-082: The system shall display a prioritized expiry alert panel on the Sales Portal dashboard listing tenants expiring within 30 days, sorted ascending by days remaining. **Source:** FR-82 (Sales Portal).
REQ-083: The system shall send email notifications for all defined trigger events using the configured template for each event type and the tenant's configured language; failed sends shall be retried once after 5 minutes. **Source:** FR-83 (Notifications).
REQ-084: The system shall send push notifications to students on Flutter Mobile (iOS/Android) for student-facing trigger events (session published, T−24h, T−1h, score available), in addition to email; stale device tokens shall be removed on delivery failure. **Source:** FR-84 (Notifications).
REQ-085: The system shall allow Super Admins to view and edit email templates for all notification types; templates shall support variable substitution and Vietnamese/English language versions; edits shall be versioned with rollback capability. **Source:** FR-85 (Notifications).
REQ-086: The system shall allow Tenant-side users to opt out of non-critical notification types; critical notifications (account created, score available, license expiry) shall not be opt-outable. **Source:** FR-86 (Notifications).
REQ-087: The system shall log every notification attempt with recipient, type, trigger, sent timestamp, delivery status, and provider response; bounced emails shall flag the recipient account. **Source:** FR-87 (Notifications).
REQ-088: The system shall provide a publicly accessible trial landing page (no login required) with a platform description, trial scope summary, a disclaimer, and a "Start Trial" call-to-action that loads in under 3 seconds on standard broadband. **Source:** FR-88 (Guest & Trial).
REQ-089: The system shall provide a limited practice exam for Guest users using a fixed Vendor-configured sample question set; the trial uses the same exam interface as the registered exam. **Source:** FR-89 (Guest & Trial).
REQ-090: The system shall display a simplified result summary to the Guest after trial completion showing estimated bands for scored skills, a disclaimer, and a "Contact Sales" call-to-action. **Source:** FR-90 (Guest & Trial).
REQ-091: The system may prompt Guest users to optionally provide contact information after trial results; the prompt shall require explicit consent for follow-up; declining shall store no data. **Source:** FR-91 (Guest & Trial).
REQ-092: The system shall automatically purge all Guest/Trial session data (anonymous session, trial answers, trial result) after a configurable retention period via a daily scheduled job; purge shall be logged with record count but no PII. **Source:** FR-92 (Guest & Trial).
REQ-093: The system shall randomize the order of questions within each exam part for every new attempt using a unique seed stored with the attempt, ensuring the same order is restored on resume. **Source:** FR-93 (Exam Integrity).
REQ-094: The system shall randomize the order of MCQ answer options for each attempt using the same shuffle seed as question order; auto-scoring shall match against answer content, not option position. **Source:** FR-94 (Exam Integrity).
REQ-095: The system shall require students to enter fullscreen mode before beginning the exam; the exam shall not start until fullscreen is confirmed active; exiting fullscreen during the exam shall trigger a violation event. **Source:** FR-95 (Exam Integrity).
REQ-096: The system shall detect when a student switches to a different browser tab or minimizes the exam window during an active exam and log each occurrence as a violation event; violation count shall accumulate toward the configured thresholds. **Source:** FR-96 (Exam Integrity).
REQ-097: The system shall detect OS-level focus loss on Flutter Desktop (Alt-Tab, window minimize) and log it as a `focus_loss` violation event contributing to the same violation counter as tab switching. **Source:** FR-97 (Exam Integrity).
REQ-098: The system shall silently block copy (Ctrl+C), paste (Ctrl+V), and right-click context menu actions within all exam content areas; text selection in reading passages shall be disabled; writing inputs shall allow typing but block clipboard paste. **Source:** FR-98 (Exam Integrity).
REQ-099: The system shall intercept browser back button, address bar navigation, F5/Ctrl+R refresh, and window close during an active exam; a warning dialog shall appear for navigation-away attempts; page reload shall trigger the resume flow (FR-106). **Source:** FR-99 (Exam Integrity).
REQ-100: The system shall enforce configurable violation thresholds per exam session: displaying an in-exam warning when `violation_count` reaches `warning_threshold`, and auto-submitting the attempt when `violation_count` reaches `terminate_threshold`. **Source:** FR-100 (Exam Integrity).
REQ-101: The system shall maintain an immutable log of all anti-cheat violation events per attempt, storing violation type, timestamp, and cumulative count at the time of each event; no user role shall be able to delete violation records. **Source:** FR-101 (Exam Integrity).
REQ-102: The system shall request OS-level window locking on Flutter Desktop to prevent students from switching to other applications during the exam; where OS-level lock is unavailable, the system shall fall back to detection-based violation logging. **Source:** FR-102 (Exam Integrity).
REQ-103: The system shall generate a per-session integrity report accessible to Exam Coordinators and Tenant Admins after a session closes, listing all students with violation counts, types, and outcome; the report shall be exportable to Excel. **Source:** FR-103 (Exam Integrity).
REQ-104: The system shall track exam part timers exclusively on the server; the client shall synchronize displayed time from the server every 10 seconds; client-side clock manipulation shall not affect the server-side timer or part expiry. **Source:** FR-104 (Exam Continuity).
REQ-105: The system shall persist every student answer to the server immediately upon entry; batch submission at exam end shall not be used as the primary persistence mechanism; unsaved answers shall be retried up to 3 times on network error. **Source:** FR-105 (Exam Continuity).
REQ-106: The system shall allow a student who disconnected during an exam to resume from exactly the last saved state, including current part, question position, all previously saved answers, and the remaining server-authoritative time. **Source:** FR-106 (Exam Continuity).
REQ-107: The system shall detect network connectivity loss during an exam and display a persistent non-blocking indicator; the student shall be able to continue answering questions with answers buffered locally; buffered answers shall be flushed to the server on reconnection. **Source:** FR-107 (Exam Continuity).
REQ-108: The system shall record Speaking audio into a local buffer and upload to Cloud Storage during or immediately after recording; on upload failure, the local buffer shall be retained and retried with exponential backoff without blocking the student from continuing. **Source:** FR-108 (Exam Continuity).
REQ-109: The system shall preserve and upload partial Speaking recordings when recording is interrupted mid-way; partial recordings shall be flagged for manual teacher review and not auto-discarded. **Source:** FR-109 (Exam Continuity).
REQ-110: The system shall detect microphone failure at the start of the Speaking skill and present the student with troubleshooting steps and retry capability; the exam shall not auto-terminate due to microphone failure; the student shall be able to signal the proctor. **Source:** FR-110 (Exam Continuity).
REQ-111: The system shall allow a student to fully recover their exam session after a browser crash or app force-close, restoring all previously saved answers and resuming with the server-authoritative timer; Speaking audio buffered locally before the crash shall be uploaded on reconnection. **Source:** FR-111 (Exam Continuity).

## Actors

| Actor | Role | Technical Proficiency | Frequency of Use | Data Access |
|---|---|---|---|---|
| Super Admin | Global Vendor administrator | Expert | Daily | Admin — global |
| Content Manager | APTIS content and template manager | Intermediate | Regular | Write — global content |
| Support Staff | Tenant support and read-only impersonation | Basic–Intermediate | Daily | Read — cross-tenant support |
| Sales Team | Tenant and license manager | Basic | Weekly | Write — tenants/licenses; no exam data |
| Tenant Admin | School or center administrator | Basic–Intermediate | Daily/Weekly | Admin — own tenant |
| Teacher | Class manager and human score reviewer | Basic | Daily/Weekly | Write — assigned groups |
| Exam Coordinator | Exam deployment and incident operator | Intermediate | During sessions | Write — exam operations |
| Viewer | School reporting stakeholder | Non-technical | Weekly | Read — own tenant |
| Student | Registered exam taker | Basic | Per schedule | Write/read — own records |
| Guest | Anonymous trial taker | Non-technical | Occasional | Limited — trial only |
| Background Workers | Scoring, notification, purge and analytics jobs | System | Continuous/Scheduled | Service-scoped |
| Cloud Storage/CDN | Media storage and delivery | External system | Continuous | Object read/write via adapter |
| Email/Push Provider | Outbound notification delivery | External system | Event-driven | Outbound only |
| STT/LLM Providers | AI transcription and draft scoring | External system | Event-driven | Outbound request/response |

## In Scope

- Authentication & Access (01–08): FR-01 through FR-08.
- Question Bank Management (09–16): FR-09 through FR-16.
- Exam Simulation (17–26): FR-17 through FR-26.
- Scoring (27–36): FR-27 through FR-36.
- Exam Scheduling & Deployment (37–43): FR-37 through FR-43.
- Learner Management (44–51): FR-44 through FR-51.
- Analytics & Reporting (52–70): FR-52 through FR-70.
- Vendor Management (71–76): FR-71 through FR-76.
- Sales Portal (77–82): FR-77 through FR-82.
- Notifications (83–87): FR-83 through FR-87.
- Guest & Trial (88–92): FR-88 through FR-92.
- Exam Integrity (93–103): FR-93 through FR-103.
- Exam Continuity (104–111): FR-104 through FR-111.

## Out of Scope

- Automated payment, invoicing, subscription billing, and payment gateway integration (deferred to v2).
- Video proctoring and camera-based monitoring (deferred to v3).
- Issuance of official APTIS or British Council certificates (never in scope without authorization).
- External LMS integrations such as Moodle, Canvas, and Google Classroom (deferred to v2).
- Tenant-authored question banks and an inter-tenant content marketplace (deferred).
- Separate native clients outside the mandated Flutter codebase.

## Assumptions

1. Assumption 1: Students have a compatible device, audio output, network access, and a working microphone — Risk if wrong: Speaking cannot be completed without coordinator intervention.
2. Assumption 2: The APTIS four-skill and sixteen-part structure remains stable for v1 — Risk if wrong: content, templates, timing, and UI require coordinated migration.
3. Assumption 3: Tenants provide enough Teachers to review Writing and Speaking — Risk if wrong: student results remain pending indefinitely.
4. Assumption 4: Vendor owns and maintains all v1 question content — Risk if wrong: tenant content ownership and schema isolation require redesign.
5. Assumption 5: Exam venues have enough intermittent connectivity to eventually synchronize answers and audio — Risk if wrong: local buffers may be lost on power failure.
6. Assumption 6: Payments remain external to the platform — Risk if wrong: billing, financial compliance, and reconciliation become new bounded contexts.
7. Assumption 7: One immutable subdomain slug maps to one tenant — Risk if wrong: tenant resolution and certificates require redesign.
8. Assumption 8: Content Managers provide pedagogically valid questions and band mappings — Risk if wrong: technically valid but educationally incorrect scores may be published.
9. Assumption 9: Audio recording consent is covered contractually unless Legal requires in-app consent — Risk if wrong: release is blocked by privacy compliance work.
10. Assumption 10: Data retention and residency will be resolved by Legal before production architecture freeze — Risk if wrong: storage region, purge jobs, and costs cannot be finalized.

## Conflicts Detected

1. `plan/00-overview.md` reports 106 Essential and 5 Conditional FRs; `srs/00-master-index.md` reports 104 Essential and 7 Conditional; the actual 111 FR headings contain 103 Essential and 8 Conditional. The generated stories preserve the individual FR headings until Product resolves the summary mismatch.
2. FR-08 is `[Essential]` in `srs/03-02-functional-requirements.md` but listed as Conditional in `srs/00-master-index.md`; its intended release status requires explicit Product confirmation.
3. `_context/features.md` contains shifted FR ranges for several clusters; the individual FR headings and IDs in `srs/03-02-functional-requirements.md` are used for traceability.
4. Plan operational text refers to Speaking audio CDN pre-caching where the intended pre-warm target is Listening audio; the final SRS operational requirement takes precedence.
5. Data retention, AI provider, platform split, SLA, anti-cheat defaults, and several NFR targets remain formally open; they are requirements risks, not implementation defaults.

## Flags from Previous Agents

No flags detected. Document-level inconsistencies and open decisions are recorded under Conflicts Detected and in the source SRS Appendix B.
