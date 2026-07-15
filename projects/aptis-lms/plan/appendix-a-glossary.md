# Plan File Appendix A — Glossary (SRS Appendix A)
Project: APTIS LMS  
Date: 2026-06-16

---

All domain, technical, and system-specific terms used in this SRS. Listed alphabetically.

---

**AI Scoring**
The automated process of evaluating student Writing and Speaking responses using third-party AI APIs (STT for audio transcription, LLM for rubric-based scoring). AI scoring produces a draft that must be reviewed and confirmed by a Teacher before being shown to the student.

**Attempt**
A single student's execution of an exam session. One attempt = one student completing (or attempting to complete) all parts of an exam session. By default, each student may have only one attempt per session (BR-06). A retake creates a second attempt (attempt_number=2).

**APTIS**
Assessment of Professional English. A standardized English language proficiency test developed and administered by British Council. APTIS tests four skills: Reading, Writing, Listening, and Speaking. Results are reported as CEFR-aligned bands (A1 to C).

**Band**
The APTIS/CEFR proficiency level assigned to a student's performance in a skill. Bands: A1 (Beginner), A2 (Elementary), B1 (Intermediate), B2 (Upper Intermediate), C (Advanced). Bands are derived from raw scores using a band mapping table.

**Band Mapping Table**
A configuration table maintained by the Vendor Content Manager that maps ranges of raw scores to APTIS bands per skill. Example: Reading raw score 18–22 = B1.

**Business Rule (BR)**
A policy or constraint specific to the business domain that the system must enforce. Business rules are numbered BR-01 through BR-15 in this SRS.

**CDN**
Content Delivery Network. A geographically distributed network of servers that deliver content (audio files, images) to users with low latency. Used for Listening audio delivery to exam clients.

**CEFR**
Common European Framework of Reference for Languages. An international standard for describing language ability. Levels: A1, A2 (Basic), B1, B2 (Independent), C1, C2 (Proficient). APTIS bands align to A1–C.

**Content Manager**
A Vendor-side user role responsible for creating and managing the APTIS question bank, exam templates, and reviewing item analysis. Does not manage tenants or licenses.

**Course**
A time-bounded container within a Tenant that groups students into a learning period. A course has a start_date and end_date; students can only participate in exam sessions while the course is active.

**Discrimination Index**
A statistical measure of how well a question differentiates between high-performing and low-performing students. Computed as the point-biserial correlation between per-question correctness (0/1) and total exam score. A question with a low discrimination index (< 0.2) does not meaningfully distinguish strong from weak students and should be reviewed.

**Difficulty Index (p-value)**
The proportion of students who answered a question correctly: p = correct_responses / total_responses. A question with p < 0.3 is considered too hard; p > 0.9 is too easy. Items at extreme values are flagged for content review.

**Exam Client**
The Flutter cross-platform application used by students to take APTIS practice exams. Runs on Flutter Web, Flutter Desktop (Windows/macOS), and optionally Flutter Mobile (iOS/Android).

**Exam Coordinator**
A Tenant-side user role responsible for deploying exam sessions, monitoring live exams, and handling exam-time incidents (time extensions, force submissions, retake approvals).

**Exam Session**
A scheduled instance of an exam, created by a Teacher or Exam Coordinator. An exam session specifies: which exam template to use, which students are eligible, the open/close datetime window, and anti-cheat configuration. Multiple students take the same session simultaneously.

**Exam State**
The server-side record of a student's in-progress answers during an exam attempt. Updated after every answer the student submits (per-answer persistence — FR-105). Enables resume after disconnect.

**Exam Template**
A named, reusable set of questions organized by skill and part, created by a Content Manager. Exam sessions are created from templates.

**Flutter**
An open-source UI SDK by Google for building natively compiled applications for Web, Desktop (Windows, macOS, Linux), and Mobile (iOS, Android) from a single Dart codebase. The mandated client framework for APTIS LMS (DC-01).

**Force Submit**
An action by an Exam Coordinator to finalize a student's exam attempt before the student has submitted voluntarily (FR-41). The attempt is marked force_submitted; all persisted answers at that point become the final submission.

**FR**
Functional Requirement. A requirement that specifies a behavior the system must perform. FRs are numbered FR-01 through FR-111 in this SRS.

**Group (Class)**
A named sub-division of a course. Students are enrolled in groups; Teachers are assigned to groups and can only view/manage students in their assigned groups.

**Guest (Trial Taker)**
An unauthenticated user who accesses the trial exam without a registered account. Guest sessions are anonymous and ephemeral; data is purged after retention period (FR-92).

**Human Review Queue**
The interface used by Teachers and Exam Coordinators to view AI draft scores for Writing and Speaking and confirm or override them (FR-32).

**Item Analysis**
Statistical analysis of individual exam questions to evaluate their quality. Key metrics: difficulty index (p-value) and discrimination index. Used by Content Managers to identify and improve problematic questions.

**JWT**
JSON Web Token. A compact, self-contained token format used for authentication. In APTIS LMS: access tokens (short-lived, ~15 min) contain user_id, tenant_id, and roles[]. Refresh tokens (long-lived, ~7 days) enable token renewal.

**Kiosk Mode**
A restricted operating mode in which the Flutter Desktop app prevents students from switching to other applications or windows during an exam. Implemented using OS-level window management APIs where platform capability permits (FR-102).

**License**
A seat-based access grant issued by the Vendor Sales Team to a Tenant. A license specifies: seat_count (max students) and expiry_date. Tenants without a valid active license enter read-only mode (BR-10).

**LLM**
Large Language Model. An AI model capable of understanding and generating text. Used in APTIS LMS to evaluate student Writing and Speaking transcripts against the APTIS rubric. Provider TBD (OI-02).

**Multi-tenant**
A software architecture where a single instance of the application serves multiple independent tenants (customers), each with isolated data. APTIS LMS uses subdomain-based multi-tenancy.

**NFR**
Non-Functional Requirement. A quality attribute or constraint on system behavior rather than a specific function. NFRs are numbered NFR-01 through NFR-X in this SRS.

**Part**
A sub-section of a skill in the APTIS exam. Reading: Parts A, B, C, D. Writing: Parts A, B, C. Listening: Parts A, B, C, D. Speaking: Parts A, B, C, D, E.

**PDPA (Vietnam)**
Personal Data Protection — refers to Nghị định 13/2023/NĐ-CP, Vietnam's decree on personal data protection. Applicability to APTIS LMS is TBD (OI-07).

**Point-biserial Correlation**
A statistical measure used for the discrimination index. Correlates the binary variable (question correct/incorrect) with the continuous variable (total exam score). Values range from -1 to 1; values < 0.2 indicate poor discrimination.

**Quota (Seat Quota)**
The maximum number of active student accounts permitted in a tenant, defined by the license's seat_count. Tracked in real time; enrollment is blocked at 100% (BR-05).

**RBAC**
Role-Based Access Control. The permission model in APTIS LMS where users are granted roles that define their access rights. Tenant-side users can hold multiple roles simultaneously (BR-01).

**Resume**
The ability for a student to continue an in-progress exam after disconnection, from the exact question they were on, with all previously saved answers restored and the server-authoritative timer continuing (FR-106).

**Retake**
A second (or subsequent) attempt on an exam session, permitted only when explicitly approved by a Teacher or Exam Coordinator (BR-07, FR-43).

**Rubric**
The scoring criteria used to evaluate APTIS Writing and Speaking responses. Each part has specific criteria (e.g., grammar, vocabulary, coherence, task completion) with point values. The rubric is used by both the AI scoring system and the human reviewer.

**Sales Team**
A Vendor-side user role responsible for managing tenant customer relationships and manually creating/renewing licenses. Sales Team members have no access to exam or student data.

**Seat**
One unit of a tenant's license quota. One seat = one active student account. Unenrolling a student releases their seat.

**Scoring SLA**
The service level agreement for how long a student must wait for Writing and Speaking results after exam submission. Includes: AI pipeline time (async, ~15 min estimated) + teacher review time (TBD — OI-03).

**Slug**
A URL-safe string identifier for a tenant. Used as the subdomain prefix: `{slug}.aptis-lms.vn`. Example: `hanoi-english` → `hanoi-english.aptis-lms.vn`. Slugs are unique across the platform and immutable once set.

**Speaking Transcript**
The text output of the STT API applied to a student's Speaking audio recording. The transcript is used as input for LLM-based scoring and is shown to Teachers during manual review.

**STT**
Speech-to-Text. An AI service that converts spoken audio recordings to text transcripts. Used for APTIS Speaking skill scoring. Provider TBD (OI-02).

**Super Admin**
The Vendor-side user role with global admin access to all system data and configuration. Can create/manage tenants, view all data, and perform emergency interventions.

**Tenant**
A school or training center that has purchased an APTIS LMS license. Each tenant operates in an isolated namespace (subdomain, data) and is managed by their Tenant Admin.

**Tenant Admin**
A user role within a Tenant with full administrative privileges scoped to that tenant. Manages users, courses, groups, and licenses within the tenant. Cannot access other tenants' data.

**Timer (Server-authoritative)**
The exam timer that runs on the server, not the client. The server computes time_remaining = part_duration - (now - part_start_time). The client displays the server-provided value. The client cannot manipulate the timer (DC-04).

**Violation Event**
An anti-cheat event logged when a student performs an integrity-suspicious action: tab switching, focus loss, fullscreen exit, or copy-paste attempt. Violation events are immutable (DC-10) and contribute to a per-attempt violation count (FR-101).

**Violation Threshold**
Configurable per exam session: warning_threshold (number of violations → display warning) and terminate_threshold (number of violations → auto-submit exam). Set by Teacher/Coordinator during session creation (FR-100). Default values TBD (OI-04).
