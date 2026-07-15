# Glossary — APTIS LMS

Authoritative copy of SRS Appendix A. All domain, technical, and system-specific terms. Listed alphabetically.

---

**AI Scoring** — The automated process of evaluating student Writing and Speaking responses using third-party AI APIs: STT (Speech-to-Text) for audio transcription and LLM (Large Language Model) for rubric-based scoring. AI scoring produces a draft score (stored in `ai_score_drafts`) that must be reviewed and confirmed by a Teacher before becoming visible to the student (BR-13). See FR-30, FR-31.

**Anonymous Session** — A short-lived server-side session record created for Guest users who access the trial exam without a registered account. Anonymous sessions have no `user_id` and expire after 2 hours or on trial submission. All data from an anonymous session is purged after the configured retention period. See FR-08, FR-92.

**APTIS** — Assessment of Professional English. A standardized English language proficiency test developed and administered by British Council. APTIS tests four skills: Reading, Writing, Listening, and Speaking. Results are reported as CEFR-aligned bands (A1 to C). APTIS LMS is a practice simulation platform and is not affiliated with or authorized by British Council. See DC-11, OR-LGL-01.

**Attempt** — A single student's execution of one exam session. One attempt encompasses a student completing (or partially completing) all skills and parts of an exam session. Each student is permitted one attempt per session by default (BR-06); retakes create a second attempt (`attempt_number = 2`) and require explicit approval (FR-43). See `exam_attempts` entity.

**Band** — The APTIS/CEFR proficiency level assigned to a student's performance in a skill. Band values: A1 (Beginner), A2 (Elementary), B1 (Intermediate), B2 (Upper Intermediate), C (Advanced). Bands are derived from raw scores using the Vendor-configured Band Mapping Table (FR-28). For Writing and Speaking, band is assigned by the Teacher during score confirmation (FR-33).

**Band Mapping Table** — A configuration table maintained by the Vendor Content Manager mapping ranges of raw scores to APTIS bands per skill. Example: Reading raw score 18–22 = B1. The table is the only authoritative source of band derivation (Assumption A-10). Errors in the table result in `MAPPING_ERROR` flags (FR-28).

**BR (Business Rule)** — A policy or constraint specific to the business domain that the system must enforce. Business rules are numbered BR-01 through BR-15 and are detailed in §3.2 and spec.md.

**CDN (Content Delivery Network)** — A geographically distributed network of servers delivering content (audio files, images) to users with low latency. Used for Listening audio delivery to exam clients (SI-01). CDN edge nodes must be located in Vietnam or Southeast Asia to meet the latency target (NFR-08).

**CEFR (Common European Framework of Reference for Languages)** — An international standard for describing language ability. Levels: A1, A2 (Basic User), B1, B2 (Independent User), C1, C2 (Proficient User). APTIS bands align to A1–C (C maps to C1/C2 combined in APTIS).

**Content Manager** — A Vendor-side user role responsible for creating and managing the APTIS question bank, exam templates, audio and image assets, and reviewing item analysis statistics. Content Managers cannot manage tenants, licenses, or student data.

**Course** — A time-bounded container within a tenant that groups students into a learning period. A course has a `start_date` and `end_date`; exam sessions are scoped to an active course; students can only participate in exam sessions while the course is active. See FR-44, `courses` entity.

**DC (Design Constraint)** — A non-negotiable restriction on system design imposed by technology mandates, security requirements, or stakeholder decisions. Design constraints are numbered DC-01 through DC-12 and documented in §3.5.

**Discrimination Index** — A statistical measure of how well a question distinguishes between high-performing and low-performing students. Computed as the point-biserial correlation between per-question correctness (0/1) and total exam score. Values range from −1 to 1. Questions with index < 0.2 are flagged as "Poor Discriminator"; questions with index < 0 are flagged as "Review Required." See FR-69.

**Difficulty Index (p-value)** — The proportion of students who answered a question correctly: `p = correct_responses / total_responses`. A question with `p < 0.3` is "Too Hard"; `p > 0.9` is "Too Easy." Both extremes are flagged for Content Manager review. See FR-68.

**Exam Client** — The Flutter cross-platform application used by students to take APTIS practice exams. Runs on Flutter Web, Flutter Desktop (Windows/macOS), and optionally Flutter Mobile (iOS/Android — OI-01). One of three portals in the APTIS LMS platform.

**Exam Coordinator** — A Tenant-side user role responsible for deploying exam sessions, monitoring live exams via the real-time dashboard (FR-39), and handling exam-time incidents (time extensions FR-40, force submissions FR-41, retakes FR-43).

**Exam Session** — A scheduled instance of an exam created by a Teacher or Exam Coordinator. Specifies the exam template, eligible students, the open/close datetime window, and anti-cheat configuration. Multiple students take the same session simultaneously. See FR-37, `exam_sessions` entity.

**Exam State** — The server-side per-question answer record for an in-progress attempt. Updated on every student answer submission (FR-105). Enables resume after disconnection (FR-106) and crash recovery (FR-111). See `exam_state` entity.

**Exam Template** — A named, reusable set of questions organized by skill and part, created by a Content Manager. Exam sessions are always created from a published template. A template must cover all 4 skills and all required parts to be publishable (FR-12). See `exam_templates` entity.

**FCM (Firebase Cloud Messaging)** — Google's push notification service. Used for student push notifications on Flutter Mobile (SI-03, FR-84). Conditional on Flutter Mobile being in platform scope (OI-01).

**Force Submit** — An action by an Exam Coordinator to finalize a student's exam attempt before the student submits voluntarily. The attempt is marked `force_submitted`; all persisted answers at that point become the final submission. See FR-41.

**FR (Functional Requirement)** — A requirement that specifies a behavior the system must perform. FRs are numbered FR-01 through FR-111 in this SRS and documented in §3.2.

**Group (Class)** — A named sub-division of a course. Students are enrolled in groups; Teachers are assigned to groups and can only manage and view students in their assigned groups. See FR-45, `groups` entity.

**Guest (Trial Taker)** — An unauthenticated user who accesses the trial exam without a registered account. Guest sessions use anonymous sessions (FR-08) and are ephemeral; all data is purged after the retention period (FR-92). See F-11.

**Human Review Queue** — The interface used by Teachers to view AI draft scores for Writing and Speaking submissions and confirm or override them. See FR-32, UI-06.

**Item Analysis** — Statistical analysis of individual exam questions to evaluate pedagogical quality. Key metrics: difficulty index (p-value, FR-68) and discrimination index (FR-69). Used by Content Managers to identify and improve problematic questions. See F-07, FR-67–FR-70.

**JWT (JSON Web Token)** — A compact, self-contained token format used for authentication. In APTIS LMS: access tokens (short-lived, ≤ 15 minutes) contain `user_id`, `tenant_id`, and `roles[]`. Refresh tokens (long-lived, ≤ 7 days) enable token renewal. Access tokens are stateless; refresh tokens are stored server-side for revocability. See FR-02, NFR-13.

**Kiosk Mode** — A restricted operating mode in which the Flutter Desktop Exam Client prevents students from switching to other applications or windows during an exam. Implemented using OS-level window management APIs where platform capability permits. See FR-102 (Conditional).

**License** — A seat-based access grant issued by the Vendor Sales Team to a tenant. Specifies `seat_count` (maximum student accounts) and `expiry_date`. Tenants without a valid active license are in read-only mode (BR-10). See FR-73, `licenses` entity.

**LLM (Large Language Model)** — An AI model used to evaluate student Writing and Speaking transcripts against the APTIS rubric and produce draft scores and feedback narratives. Provider TBD (OI-02). See SI-05, FR-31.

**Multi-tenant** — A software architecture where a single instance of the application serves multiple independent tenants (customers) with isolated data. APTIS LMS uses subdomain-based multi-tenancy (`{slug}.aptis-lms.vn`) enforced at API gateway and database layers. See DC-02.

**NFR (Non-functional Requirement)** — A quality attribute or constraint on system behavior rather than a specific function. NFRs are numbered NFR-01 through NFR-14 in this SRS and documented in §3.3.

**OI (Open Item)** — A TBD item requiring resolution before the corresponding SRS section can be finalized. Open items are numbered OI-01 through OI-08 and tracked in Appendix B.

**Part** — A sub-section of a skill in the APTIS exam. Reading: Parts A, B, C, D. Writing: Parts A, B, C. Listening: Parts A, B, C, D. Speaking: Parts A, B, C, D, E. Total: 16 parts across 4 skills.

**PITR (Point-in-Time Recovery)** — A database backup strategy allowing restoration to any point within the backup retention window. Required for APTIS LMS database (OR-OPS-03).

**Point-biserial Correlation** — A statistical measure correlating a binary variable (question correct = 1, incorrect = 0) with a continuous variable (total exam score). Used as the discrimination index for item analysis. Range: −1 to 1.

**Quota (Seat Quota)** — The maximum number of active student accounts permitted in a tenant at one time, defined by the current license's `seat_count`. Enrollment is blocked when `seats_used ≥ seat_count` (BR-05). See FR-51.

**RBAC (Role-Based Access Control)** — The permission model where users are granted roles defining their access rights. Tenant-side users can hold multiple roles simultaneously (BR-01); effective permissions are the union of all assigned roles. See DC-09, FR-04.

**Resume** — The ability for a student to continue an in-progress exam after disconnection from exactly the last server-acknowledged question and answer state, with the server-authoritative timer continuing. See FR-106.

**Retake** — A second or subsequent attempt on an exam session, permitted only when explicitly approved by a Teacher or Exam Coordinator (BR-07, FR-43). Retakes create a new `exam_attempt` record with `attempt_number ≥ 2`.

**Rubric** — The scoring criteria used to evaluate APTIS Writing and Speaking responses. Each part has specific criteria (grammar, vocabulary, coherence, task completion) with point values. Used by both the AI scoring system (FR-31) and the Teacher during human review (FR-33).

**Sales Team** — A Vendor-side user role responsible for managing tenant customer relationships and creating/renewing licenses via the Sales Portal. Sales Team members have no access to exam or student data. See F-09.

**Seat** — One unit of a tenant's license quota. One seat = one currently enrolled, active student account. Unenrolling a student releases one seat (FR-50).

**Scoring SLA** — The agreed maximum time from exam submission to teacher-confirmed score availability. Includes AI pipeline time (target: ≤ 15 minutes, NFR-09 TBD) plus teacher review time (TBD — OI-03).

**Slug** — A URL-safe string identifier for a tenant, used as the subdomain prefix: `{slug}.aptis-lms.vn`. Slugs are globally unique, immutable once a tenant is activated, and lowercase alphanumeric with hyphens only.

**Speaking Transcript** — The text output of the STT API applied to a student's Speaking audio recording. The primary input for LLM-based scoring (FR-31) and shown to Teachers during score review (FR-32). Transcripts are PII. See `ai_score_drafts.stt_transcript`.

**SSE (Server-Sent Events)** — A one-way server-to-client push protocol over HTTP. Used as a fallback for WebSocket for the live exam monitor dashboard (FR-39, CI-02).

**STT (Speech-to-Text)** — An AI service that converts spoken audio recordings to text transcripts. Used for APTIS Speaking skill scoring. Provider TBD (OI-02). See SI-04, FR-30.

**Super Admin** — The Vendor-side user role with global administrative access to all system data and configuration. Can create/manage tenants, view all data, force-logout users, and perform emergency interventions. Highest-privilege role in the system.

**Tenant** — A school or training center that has purchased an APTIS LMS license and operates their own isolated namespace within the platform. Each tenant has its own subdomain, its own user base, and strictly isolated data. All tenant-scoped data includes `tenant_id` in every database record.

**Tenant Admin** — A user role within a tenant with full administrative privileges scoped to that tenant only. Manages users, courses, groups, license visibility, and analytics within the tenant. Cannot access other tenants' data or Vendor Portal functions.

**Timer (Server-authoritative)** — The exam timer that runs on the server, not the client. The server computes `time_remaining = part_duration + extensions − (now − part_start_time)`. Client-side manipulation does not affect the server timer. See DC-04, FR-104, `part_timers` entity.

**Vendor Portal** — The Flutter Web application used by Vendor-side staff to manage all tenants, content, and licenses. Accessible at `admin.aptis-lms.vn` with no tenant scoping.

**Violation Event** — An anti-cheat event logged when a student performs an integrity-suspicious action during an exam: tab switching, OS-level focus loss, fullscreen exit, or copy-paste attempt. Violation events are immutable at the application layer (DC-10). See FR-101, `violation_events` entity.

**Violation Threshold** — Configurable per exam session: `warning_threshold` (violation count triggering a warning overlay) and `terminate_threshold` (violation count triggering auto-submit and session lock). Set during session creation (FR-37). Default values TBD (OI-04).

**WebSocket** — A full-duplex communication protocol over TCP, used for the real-time exam monitor dashboard (FR-39, CI-02). WebSocket is the primary protocol; SSE is the fallback.
