# Plan File 03-02 — Functional Requirements (SRS §3.2)
Project: APTIS LMS  
Date: 2026-06-16

FR numbering: sequential FR-01 → FR-111 (no resets between clusters)
Format: FR-NN [Priority] | Requirement (shall) | Given/When/Then stubs

---

## Cluster F-01: Authentication & Access (FR-01 – FR-08)

---

**FR-01 [Essential]: User Login**
Requirement: The system shall authenticate users via email and password, scoping the login context to the tenant identified by the current subdomain.
Given: A user navigates to `{slug}.aptis-lms.vn/login` and enters email + password
When: The user submits the login form
Then: If credentials match a user belonging to that tenant, the system issues a JWT access token and refresh token and redirects to the user's home screen; if credentials are invalid or user does not belong to that tenant, the system returns a 401 error with message "Invalid credentials"

---

**FR-02 [Essential]: JWT Token Issuance and Refresh**
Requirement: The system shall issue a short-lived access token (≤ 15 minutes) and a long-lived rotating refresh token (≤ 7 days) upon successful authentication; the system shall issue a new access token when the client presents a valid refresh token.
Given: A user has successfully logged in
When: The access token expires and the client sends a refresh request with a valid refresh token
Then: The system issues a new access token and a new refresh token (rotating); the old refresh token is invalidated

---

**FR-03 [Essential]: Multi-tenant Subdomain Routing**
Requirement: The system shall resolve the tenant context from the subdomain of every incoming request and scope all data operations to that tenant's namespace.
Given: A request arrives at `{slug}.aptis-lms.vn`
When: The backend processes the request
Then: The system resolves `slug` to a `tenant_id`, attaches it to the request context, and ensures all database queries include a `WHERE tenant_id = {resolved_id}` constraint (or schema-level equivalent); requests arriving at `admin.aptis-lms.vn` are routed to the Vendor Portal with no tenant scoping

---

**FR-04 [Essential]: RBAC Multi-role per User**
Requirement: The system shall support assigning multiple roles simultaneously to a single Tenant-side user; the effective permissions of that user shall be the union of all assigned roles' permissions.
Given: A Tenant Admin assigns roles Teacher and Exam Coordinator to user U
When: User U logs in and performs actions
Then: User U can perform all actions permitted by either the Teacher role or the Exam Coordinator role; removing one role immediately revokes permissions exclusive to that role while keeping permissions from remaining roles

---

**FR-05 [Essential]: Forgot Password Flow**
Requirement: The system shall provide a password reset flow via email for all registered users (Vendor and Tenant side).
Given: A user has forgotten their password and navigates to the forgot-password page on their respective portal
When: The user submits their email address
Then: If the email matches a user in the current scope (tenant or vendor), the system sends a time-limited password reset link (≤ 1 hour validity) to that email; the user can set a new password using the link; the link is single-use and invalidated after use or expiry

---

**FR-06 [Essential]: Forced Password Change on First Login**
Requirement: When a Tenant Admin configures a course to require password change on first login, the system shall force students who log in for the first time (using a bulk-generated password) to set a new password before accessing any other screen.
Given: A student account was created via bulk generation and the tenant has "force password change" enabled
When: The student logs in for the first time
Then: The system intercepts the session and redirects to a change-password screen; the student cannot access exam or any other page until the new password is set; subsequent logins proceed normally

---

**FR-07 [Essential]: Session Management and Logout**
Requirement: The system shall invalidate the user's refresh token upon logout; the system shall allow a Super Admin to force-invalidate all active sessions of any user.
Given: A logged-in user clicks Logout
When: The logout action is submitted
Then: The server-side refresh token is invalidated; any subsequent use of that refresh token returns 401; the client clears stored tokens; for Super Admin force-logout: all refresh tokens for the target user are invalidated immediately

---

**FR-08 [Essential]: Guest Anonymous Access**
Requirement: The system shall allow unauthenticated users to access the trial landing page and trial exam without creating an account; the system shall issue a short-lived anonymous session token for trial sessions only.
Given: An unauthenticated user navigates to the public trial URL
When: The user starts the trial exam
Then: The system creates an anonymous session (no persistent user record) and allows access only to the trial exam flow (FR-88 – FR-92); anonymous sessions expire after the trial is complete or after 2 hours of inactivity; no Tenant or registered-user data is accessible via anonymous session

---

## Cluster F-02: APTIS Question Bank Management (FR-09 – FR-16)

---

**FR-09 [Essential]: Question CRUD**
Requirement: The system shall allow Content Managers to create, read, update, and delete questions; each question shall store: skill (Reading/Writing/Listening/Speaking), part (A–E per skill), question_type (MCQ/matching/gap-fill/short-answer/essay/speaking-prompt), content (text/HTML), answer_key (for auto-score types), rubric_criteria (for human-score types), difficulty_tag, topic_tags[].
Given: A Content Manager is logged in to the Vendor Portal
When: The Content Manager creates a new question
Then: The system saves the question with all required fields; the question appears in the question bank browser filtered by skill/part; questions used in completed exam sessions remain immutable (version copy is preserved — see FR-14)

---

**FR-10 [Essential]: Audio Asset Management for Listening**
Requirement: The system shall allow Content Managers to upload audio files (MP3, WAV) and associate them with Listening questions; the system shall deliver audio via CDN to exam clients with configurable play-count limits per part.
Given: A Content Manager uploads an audio file for a Listening Part B question
When: The upload completes
Then: The file is stored in Cloud Storage and linked to the question record; the question stores `max_play_count` (default per APTIS standard: Part A=1, Part B=1 per conversation, Part C=1, Part D=1 per monologue); the CDN URL is generated for delivery; the Content Manager can preview playback in the question editor

---

**FR-11 [Essential]: Image Asset Management for Speaking**
Requirement: The system shall allow Content Managers to upload image files (JPEG, PNG) and associate them with Speaking Part B (describe image) and Part D (compare images) questions.
Given: A Content Manager uploads an image for a Speaking Part B question
When: The upload completes
Then: The image is stored in Cloud Storage and linked to the question; the image is responsive-rendered in the Exam Client; images for Part D are stored as a pair (image_1, image_2) on the same question record

---

**FR-12 [Essential]: Exam Template Builder**
Requirement: The system shall allow Content Managers to create exam templates by selecting specific questions per part or by specifying auto-select criteria (skill, part, difficulty, count); a template must include questions for all four skills and all relevant parts to constitute a complete APTIS simulation.
Given: A Content Manager opens the exam template builder
When: The Content Manager selects questions per part and saves the template
Then: The template is saved with a name, description, and a mapping of {skill → {part → [question_ids]}}; exam sessions created from this template use these question sets (with optional shuffle per session — BR-14); incomplete templates (missing required parts) cannot be published

---

**FR-13 [Essential]: Content Manager Preview Mode**
Requirement: The system shall provide a preview mode where Content Managers can experience a question or full exam template as a student would, including audio playback, image rendering, timer display, and all UI elements, without creating an actual exam attempt.
Given: A Content Manager clicks "Preview" on a question or exam template
When: The preview launches
Then: The system renders the question/template in an exam-like interface (read-only, no scoring); audio plays with play-count limits simulated; the preview does not create any exam_attempt or exam_state record; the Content Manager can exit preview at any time

---

**FR-14 [Essential]: Question Version Control**
Requirement: The system shall preserve the version of questions used in any exam session; editing a question after it has been used in at least one completed exam session shall create a new version, leaving prior sessions' answer records linked to the original version.
Given: A question Q has been used in a completed exam session
When: A Content Manager edits and saves question Q
Then: The system creates version Q-v2 and marks it as current; all existing exam sessions retain a reference to Q-v1; new exam templates created after the edit use Q-v2; Q-v1 is immutable and cannot be further edited; the question bank browser shows the current version by default with version history accessible

---

**FR-15 [Essential]: Bulk Question Import**
Requirement: The system shall allow Content Managers to import questions in bulk from a CSV or Excel file following a prescribed template; the system shall validate each row and report errors row-by-row.
Given: A Content Manager uploads a CSV/Excel file with question data
When: The system processes the file
Then: The system displays a preview table of parsed rows; rows with validation errors are highlighted with specific error messages (e.g., "Missing answer_key for MCQ question at row 12"); the Content Manager can proceed to import only valid rows or cancel; successfully imported questions appear in the question bank

---

**FR-16 [Essential]: Item Analysis View**
Requirement: The system shall provide Content Managers with per-question statistics aggregated across all tenants: correct_rate (%), wrong_rate per distractor (MCQ), skip_rate (%), average_time_spent, difficulty_index (p-value), discrimination_index (point-biserial correlation), and a "flagged" indicator for outlier questions.
Given: A Content Manager opens the item analysis view
When: The Content Manager selects a question or views the flagged questions list
Then: The system displays computed statistics for that question based on all completed exam sessions globally; questions are flagged automatically when: p-value < 0.3 (too hard) or p-value > 0.9 (too easy) or discrimination_index < 0.2 (poor discriminator); Content Managers can filter by flag status

---

## Cluster F-03: Exam Simulation — Full Mode (FR-17 – FR-26)

---

**FR-17 [Essential]: Exam Launch and Eligibility Check**
Requirement: The system shall verify student eligibility before launching an exam session; eligibility requires: student is enrolled in the course, the exam session window is currently open (current_time between session.start_time and session.end_time), and the student has no completed attempt for this session.
Given: A student clicks to enter an assigned exam session
When: The system processes the launch request
Then: If eligible, an exam_attempt record is created with status=in_progress and the student enters the pre-exam check screen (FR-18); if the session window is not open, the system shows the scheduled start time; if the student has an existing attempt, the system offers resume (FR-106); if ineligible for any other reason, the system shows a clear error message

---

**FR-18 [Essential]: Pre-exam Checks**
Requirement: The system shall run three pre-exam checks before the student begins the first skill: (1) microphone detection test, (2) fullscreen mode activation, (3) display of per-skill instructions; all three must pass before the exam starts.
Given: A student has passed eligibility check and is on the pre-exam screen
When: The student proceeds through pre-exam checks
Then: (1) Microphone: system requests microphone permission and plays back a 3-second test recording; if microphone not found, student sees instructions and a retry button; student can signal proctor if microphone fails (FR-111); (2) Fullscreen: system requests fullscreen mode; student cannot proceed without entering fullscreen; (3) Instructions: display time limits, what to expect per skill; student clicks "I'm ready" to start

---

**FR-19 [Essential]: Server-side Timer per Part**
Requirement: The system shall maintain authoritative exam timers on the server; when a student begins a part, the server records start_time; the client displays time_remaining = (part_duration - (now - start_time)); when time_remaining reaches zero, the server automatically advances the student to the next part regardless of client state.
Given: A student is in an active exam part
When: The server-computed time_remaining for that part reaches zero
Then: The server records part_end_time, persists all answers submitted up to that point, and marks the part as completed; the client, on its next sync or on receiving a server push, transitions to the part transition screen; answers submitted after time_remaining=0 are rejected with a 409 error

---

**FR-20 [Essential]: Reading Exam Interface**
Requirement: The system shall render Reading parts with appropriate interaction types: Part A (matching — dropdown or drag-drop), Part B (gap fill — dropdown or text input), Part C (MCQ with scrollable long text passage), Part D (short-answer text input with passage).
Given: A student is in the Reading skill
When: The student navigates between questions in a part
Then: The system preserves all entered answers client-side (optimistic) and persists them server-side (FR-105); the student can navigate freely between questions within the current part; the student cannot navigate back to a previous part; the question order is shuffled per BR-14

---

**FR-21 [Essential]: Writing Exam Interface**
Requirement: The system shall render Writing parts with text input areas; Part A (5 sentence-level prompts with individual text fields), Part B (email/message scenario with one textarea), Part C (essay prompt with one large textarea); all Writing inputs shall display a live word count and indicate if under or over the target word range.
Given: A student is in the Writing skill
When: The student types in any Writing textarea
Then: The live word count updates in real time; when count is below 80% of minimum word target, indicator is shown in grey; when count is in range, indicator is green; when count exceeds maximum, indicator turns red (student can still submit); all text is auto-saved to server per FR-105

---

**FR-22 [Essential]: Listening Exam Interface**
Requirement: The system shall auto-play Listening audio when the student enters each Listening question; the student shall not be able to rewind, fast-forward, or replay beyond the max_play_count configured per part; the system shall display questions simultaneously with audio playback.
Given: A student enters a Listening part question
When: The audio begins playing automatically
Then: The audio player shows a read-only progress bar (no seek control); a play-count indicator shows remaining plays (e.g., "Play 1 of 1"); when max_play_count is reached, the play button is disabled; answers (MCQ, form-fill) are interactable throughout the audio and after; the student advances manually after audio ends or is auto-advanced after a timeout

---

**FR-23 [Essential]: Speaking Exam Interface**
Requirement: The system shall implement a five-stage Speaking sequence per part: (1) instruction/image display, (2) preparation timer countdown, (3) recording timer with visual waveform, (4) auto-stop at recording time limit, (5) upload progress and confirmation; the audio recording shall be buffered locally and uploaded to Cloud Storage.
Given: A student is in a Speaking part
When: The preparation timer ends
Then: The recording starts automatically (or on student click, per APTIS standard); a waveform visualization shows live audio input; when recording time limit is reached (server-authoritative), recording stops automatically; the system initiates upload to Cloud Storage; if upload fails, local buffer is retained (FR-108); the student sees upload progress bar and confirmation; the student advances to the next Speaking part

---

**FR-24 [Essential]: Part Transition Screens**
Requirement: The system shall display a transition screen between each exam part, indicating which part was completed, which part is next, the time allowed for the next part, and a countdown to auto-advance; the student cannot return to a completed part from the transition screen.
Given: A student completes all questions in a part (or time expires)
When: The system transitions between parts
Then: A transition screen displays: "Part [X] complete. Preparing Part [Y]... [countdown] seconds"; after the countdown, the next part begins automatically; the back button is disabled; the student's position in the overall exam (Reading → Listening → Writing → Speaking) is shown as a progress indicator

---

**FR-25 [Essential]: Skill Sequencing and Breaks**
Requirement: The system shall sequence skills in the order defined by the exam template (default: Reading → Listening → Writing → Speaking); breaks between skills shall be configurable per template (default duration: per APTIS standard); during breaks, the timer for the next skill does not start until the break countdown ends.
Given: A student completes the last part of one skill (e.g., Reading)
When: The system transitions to the next skill (e.g., Listening)
Then: A between-skill screen is displayed with the break duration countdown; the student cannot start the next skill early; after the break, the next skill begins automatically with its own part sequence

---

**FR-26 [Essential]: Exam Submission**
Requirement: The system shall finalize the exam attempt when all skills are completed or when the overall exam time window closes; finalization persists all remaining answers, marks attempt status as submitted, and triggers the scoring pipeline.
Given: A student completes the last part of the last skill
When: The student is on the post-exam screen or the session window closes
Then: The system marks exam_attempt.status = submitted and exam_attempt.submitted_at = current_time; all answers are persisted; the auto-scoring pipeline is triggered for Reading and Listening (FR-27); the AI scoring pipeline is queued for Writing and Speaking (FR-30, FR-31); the student is redirected to the results screen showing: Reading/Listening results when available (≤ 2 min), Writing/Speaking status as "Awaiting teacher review"

---

## Cluster F-04: Scoring System (FR-27 – FR-36)

---

**FR-27 [Essential]: Auto-score Reading and Listening**
Requirement: The system shall automatically compute scores for Reading and Listening immediately after exam submission by comparing student answers against the answer keys stored in the question bank.
Given: An exam attempt has status=submitted and contains Reading and Listening answers
When: The auto-scoring job runs (triggered by FR-26)
Then: For each question in Reading and Listening: compare student_answer with answer_key; record correct (1) or incorrect (0); compute raw_score per part (sum of correct answers); store per-question correctness in exam_answers table; trigger band calculation (FR-28)

---

**FR-28 [Essential]: Band Calculation**
Requirement: The system shall convert raw scores for Reading and Listening into APTIS band levels (A1, A2, B1, B2, C) using the band mapping table configured by the Vendor; band calculation is per skill.
Given: Raw scores for Reading and Listening are computed (FR-27)
When: Band calculation runs
Then: For each skill with a raw score, look up the band mapping table (skill × raw_score_range → band); store skill_band (A1–C) and skill_score in the attempt_results table; if raw_score falls in a range not covered by the mapping table, flag as "MAPPING_ERROR" for Vendor review [NEEDS USER INPUT: confirm band mapping table format and edge cases]

---

**FR-29 [Essential]: Instant Result Availability for Reading and Listening**
Requirement: The system shall make Reading and Listening results available to the student within 2 minutes of exam submission.
Given: Auto-scoring (FR-27) and band calculation (FR-28) have completed
Then: The attempt_results record is updated with status=available for Reading and Listening; the student's results screen shows the band and score; the system sends a notification email (FR-83 trigger: "exam results available")

---

**FR-30 [Essential]: Speaking Audio Transcription (STT)**
Requirement: The system shall submit Speaking audio recordings to the configured STT API and store the resulting transcript per Speaking part; transcription is performed asynchronously after exam submission.
Given: An exam attempt contains Speaking audio recordings uploaded to Cloud Storage
When: The AI scoring pipeline job runs
Then: For each Speaking part audio file: the system calls the STT API with the audio file URL; stores the transcript text in speaking_transcripts table with part reference; if STT API fails: retry up to 3 times with exponential backoff; if all retries fail: mark transcript as "STT_FAILED" and alert the assigned Teacher to review audio manually; proceed to FR-31 with available transcripts

---

**FR-31 [Essential]: AI Scoring Draft for Writing and Speaking**
Requirement: The system shall submit student Writing responses (text) and Speaking transcripts (from FR-30) to the configured LLM API with APTIS rubric prompts; the LLM response shall be stored as a draft score that is NOT visible to the student until confirmed by a teacher (BR-13).
Given: Writing text responses are available and/or Speaking transcripts are available (from FR-30)
When: The LLM scoring job runs
Then: For each Writing part and each Speaking part: the system constructs a prompt containing: student response, APTIS rubric criteria for that part, and scoring instructions; sends to LLM API; receives: score_per_criterion (object), band_estimate (A1–C), feedback_narrative (text); stores all fields in ai_score_drafts table with status=draft; does NOT update attempt_results yet; notifies assigned Teacher via email that a review is pending (FR-83 trigger)

---

**FR-32 [Essential]: Human Review Queue for Writing and Speaking**
Requirement: The system shall present Teachers and Exam Coordinators with a queue of pending Writing and Speaking submissions requiring review; each queue item shall display the student response, AI draft score, rubric criteria, and feedback narrative.
Given: AI draft scores exist for Writing/Speaking submissions (status=draft)
When: A Teacher opens the scoring queue
Then: The system displays all pending items for the Teacher's classes, sorted by submission time (oldest first); each item shows: student name, attempt date, skill and part, student's written/transcribed response, AI-generated score per criterion, AI band estimate, AI feedback narrative; the Teacher can click any item to enter the review screen

---

**FR-33 [Essential]: Score Confirmation and Override**
Requirement: The system shall allow Teachers to confirm AI draft scores as-is or override individual criterion scores and feedback narrative; upon confirmation, scores are finalized and made available to the student.
Given: A Teacher is reviewing an AI draft score for a Writing or Speaking submission
When: The Teacher clicks Confirm (with or without edits)
Then: The system creates a final_scores record with: confirmed_by (teacher_id), confirmed_at, final_score_per_criterion, final_band, final_feedback_narrative (teacher-edited or AI-original); updates attempt_results.status = available for Writing and Speaking; notifies the student via email (FR-83 trigger: "Speaking/Writing results available"); the student can now view final scores and feedback

---

**FR-34 [Essential]: Student Results Dashboard**
Requirement: The system shall display a personal results dashboard for each student showing all past exam attempts, per-skill bands, progression over time, and part-level breakdown.
Given: A student accesses their results section
When: The results page loads
Then: The system displays: list of all attempts (date, exam name, status); for each completed attempt: skill bands (A1–C) per skill, per-part scores with correct/total count (Reading/Listening), word count and band (Writing), transcript excerpt and band (Speaking); progression chart (line chart): band per skill across attempts; strengths/weaknesses summary: which parts have consistently low scores

---

**FR-35 [Essential]: APTIS Band Profile Display**
Requirement: The system shall display a four-skill band profile summary (Reading/Writing/Listening/Speaking individual bands) on the results screen for any fully-scored attempt, styled consistently with how APTIS results are typically presented.
Given: All four skills of an attempt are scored (auto-scored or teacher-confirmed)
When: A student or Teacher views the attempt summary
Then: The system shows a 4-panel summary: one panel per skill, each showing the skill name, band level (A1/A2/B1/B2/C) prominently, and a brief description of what that band means (loaded from a static reference table per CEFR/APTIS descriptor)

---

**FR-36 [Essential]: Feedback Narrative Display**
Requirement: The system shall display the teacher-confirmed feedback narrative for Writing and Speaking to the student after the score is finalized; the feedback shall be human-readable and specific to the student's response.
Given: A Teacher has confirmed the score and feedback for a Writing or Speaking submission
When: A student views their attempt results
Then: The system displays the feedback narrative for Writing Part C and all Speaking parts; the narrative includes: what was done well, what needs improvement, specific examples from the student's response where possible (from AI + teacher edit); feedback is displayed in the language the teacher wrote in (Vietnamese or English, as entered)

---

## Cluster F-05: Exam Scheduling & Deployment (FR-37 – FR-43)

---

**FR-37 [Essential]: Create Exam Session**
Requirement: The system shall allow Teachers and Exam Coordinators to create exam sessions by specifying: session name, exam template, participant list (class or individual students), session open/close datetime window, and anti-cheat configuration.
Given: A Teacher or Exam Coordinator is on the create exam session form
When: The form is submitted with all required fields
Then: The system creates an exam_session record with status=scheduled; links selected students as eligible participants; stores anti-cheat config (shuffle_enabled, warning_threshold, terminate_threshold); the session is visible on the student's exam list but cannot be entered until the open datetime; a notification email is queued for all participants (FR-83)

---

**FR-38 [Essential]: Session Publication and Student Notification**
Requirement: The system shall automatically notify all enrolled students when an exam session is created and again 24 hours and 1 hour before the session opens.
Given: An exam session has been created (FR-37)
When: The session is saved (immediate notification) and at T-24h and T-1h before session.start_time
Then: Email notifications are sent to all eligible participants containing: session name, date and time, duration, link to enter the exam; the system logs notification send status (FR-87); failed sends are retried once

---

**FR-39 [Essential]: Live Exam Monitor Dashboard**
Requirement: The system shall provide Exam Coordinators with a real-time dashboard showing the status of every enrolled student during an active exam session, updated via WebSocket/SSE.
Given: An exam session is in progress (current_time is within the session window)
When: An Exam Coordinator views the live monitor dashboard
Then: The system displays a table with one row per enrolled student showing: name, status (Not Started / In Progress [current skill - part] / Disconnected [time since last seen] / Submitted), violation_count, and time_remaining; the table updates in real time without page refresh; Disconnected students are visually highlighted; the Coordinator can click any row to see the student's detailed state

---

**FR-40 [Essential]: Time Extension by Coordinator**
Requirement: The system shall allow Exam Coordinators to extend the remaining time for a specific student's exam attempt; the extension must be logged with a reason.
Given: An exam session is in progress and a student has been identified as needing time extension
When: The Coordinator enters an extension amount (minutes) and a reason, then confirms
Then: The server updates the student's part_end_time (and session_end_time if needed) by adding the extension; the student's client reflects the updated time_remaining on the next sync; the extension event is logged in exam_events with: coordinator_id, student_id, session_id, extension_minutes, reason, timestamp

---

**FR-41 [Essential]: Force Submit by Coordinator**
Requirement: The system shall allow Exam Coordinators to force-submit a student's exam attempt, finalizing the attempt with whatever answers have been recorded at that point.
Given: A student's attempt needs to be closed (e.g., session is ending, student is unresponsive)
When: The Coordinator confirms force-submit for a specific student with a reason
Then: The server sets exam_attempt.status = submitted, exam_attempt.submitted_at = now(), and exam_attempt.force_submitted_by = coordinator_id; the scoring pipeline is triggered as normal; the reason is logged; any in-progress Speaking recording is cut at the current position and uploaded (or flagged for manual review if upload is not possible)

---

**FR-42 [Essential]: Manual Session Close**
Requirement: The system shall allow Exam Coordinators to close an exam session before its scheduled end time; students currently active in the session shall not be immediately terminated but shall be given a configurable grace period to submit.
Given: An Exam Coordinator clicks "Close Session Early"
When: The Coordinator confirms with a reason
Then: The session.status is set to closing; all enrolled students who have not yet submitted receive a notification ("Session closing in X minutes — please submit now") either via in-exam banner or push; after the grace period, any remaining in-progress attempts are force-submitted (FR-41 logic); session.status is set to closed

---

**FR-43 [Essential]: Retake Approval**
Requirement: The system shall allow Exam Coordinators and Teachers to approve retake requests for students who need an additional attempt on an exam session; approval creates a new attempt for the student.
Given: A student or Coordinator initiates a retake request for student S on session X
When: The Coordinator or Teacher approves the retake
Then: The system creates a new exam_attempt record for student S on session X with status=not_started; the retake is logged with: requester_id, approver_id, reason, timestamp; the student can now enter the session again (subject to session window being open); the original attempt is preserved and marked as attempt_number=1, retake as attempt_number=2

---

## Cluster F-06: Learner Management (FR-44 – FR-51)

---

**FR-44 [Essential]: Course Creation**
Requirement: The system shall allow Tenant Admins to create courses with a name, description, start date, and end date; students enrolled in a course can only participate in exam sessions within that course's active date window.
Given: A Tenant Admin opens the course creation form
When: The form is submitted
Then: A course record is created with status=scheduled (before start_date), active (between dates), or ended (after end_date); Teachers and Exam Coordinators are assignable to courses; exam sessions are scoped to a course; students whose course enrollment has ended cannot start new exam attempts within that course

---

**FR-45 [Essential]: Group and Class Management**
Requirement: The system shall allow Tenant Admins to create named groups (classes) within a course and assign Teachers to specific groups; Teachers can only view and manage students in their assigned groups.
Given: A Tenant Admin creates a group within a course and assigns Teacher T
When: Teacher T logs in
Then: Teacher T sees only the groups assigned to them; their analytics views, scoring queues, and student lists are filtered to their assigned groups; Tenant Admin and Viewer/Report Only roles see all groups in all courses

---

**FR-46 [Essential]: Manual Student Enrollment**
Requirement: The system shall allow Tenant Admins and Teachers to add individual students to a course group by email address (if the student account already exists) or by filling in name and email to create a new account simultaneously.
Given: A Tenant Admin or Teacher opens the enrollment form for a class
When: An existing email is entered
Then: The system finds the existing student account and enrolls it in the class (if not already enrolled); if the email does not exist, the system creates a new student account with an auto-generated password and enrolls it; if seat quota is at 100%, enrollment is rejected with a clear message (BR-05)

---

**FR-47 [Essential]: CSV Bulk Import of Students**
Requirement: The system shall allow Tenant Admins to import student rosters from CSV or Excel files; the system shall auto-generate accounts for new students and enroll them into a specified class; the system shall report errors per row.
Given: A Tenant Admin uploads a CSV/Excel file with columns: full_name, email (or username), [optional: class_name]
When: The system parses and validates the file
Then: The system displays a preview table of all rows; rows are validated for: required fields present, email format valid, email not duplicate within tenant; the Tenant Admin confirms import; the system creates accounts for all valid rows (skipping duplicates), auto-generates passwords, enrolls students in the specified class; a summary is shown: N accounts created, M already existed (enrolled), K errors (with row numbers and reasons); seat quota is checked before import (BR-05)

---

**FR-48 [Essential]: Bulk Account Generation and Excel Export**
Requirement: The system shall allow Tenant Admins to export a roster Excel file containing generated account credentials immediately after bulk creation; the file shall include: student name, email/username, and plaintext password (one-time only); subsequent exports shall not re-include the password.
Given: A bulk import or bulk account generation has completed (FR-47)
When: The Tenant Admin clicks Export Credentials
Then: The system generates an Excel file with columns: STT (row number), Họ và tên (full name), Email/Username, Mật khẩu (password — plaintext, included only when exported within 24 hours of account creation), Lớp (class name); the file is downloaded to the browser; subsequent exports of the same accounts show "••••••••" in the password column; the Tenant Admin is shown a warning: "Save this file securely. Passwords will not be shown again after 24 hours."

---

**FR-49 [Essential]: Student Profile View**
Requirement: The system shall display a student profile page accessible to Teachers (within their class) and Tenant Admins (all students), showing: personal information, enrolled courses/classes, exam attempt history, and performance summary.
Given: A Teacher or Tenant Admin clicks on a student name
When: The student profile page loads
Then: The system displays: student name, email, account status (active/suspended), enrolled classes, list of exam attempts (date, session name, status, bands), and a summary chart of band progression; the Teacher view is restricted to students in their assigned classes; no viewing of cross-tenant data is possible

---

**FR-50 [Essential]: Student Unenrollment**
Requirement: The system shall allow Tenant Admins and Teachers to remove a student from a course group; unenrollment shall not delete the student's account or historical exam records.
Given: A Tenant Admin or Teacher selects a student and clicks Unenroll
When: The action is confirmed
Then: The student is removed from the class enrollment; the student can no longer access exam sessions in that course; the student's historical attempt records for that course are preserved and remain visible to Teachers and Tenant Admins; the seat count decreases by 1 (making room for a new enrollment)

---

**FR-51 [Essential]: Real-time Seat Usage Tracking**
Requirement: The system shall track the number of active student accounts within a tenant against the seat quota in real time; the system shall prevent new enrollments when seats_used ≥ seat_count.
Given: A Tenant Admin attempts to enroll a new student when seats_used = seat_count
When: The enrollment request is processed
Then: The system rejects the enrollment with the message: "Seat quota reached ({seat_count} of {seat_count} seats used). Please contact your account manager to upgrade your license."; the system does NOT silently enroll; seats_used is decremented when a student is unenrolled (FR-50); Tenant Admin dashboard always shows current seats_used / seat_count

---

## Cluster F-07: Analytics & Reporting (FR-52 – FR-70)

---

**FR-52 [Essential]: Student Score History**
Requirement: The system shall display a chronological list of all exam attempts for a logged-in student, showing per-attempt: date, session name, and per-skill band results (or "Pending" if not yet scored).
Given: A student navigates to their results section
When: The page loads
Then: The system displays all attempts sorted by date (most recent first) with columns: Date, Exam Session, Reading Band, Listening Band, Writing Band, Speaking Band; rows with pending results show "Pending" in the relevant skill columns; clicking a row opens the attempt detail (FR-34)

---

**FR-53 [Essential]: Band Progression Chart**
Requirement: The system shall display a line chart showing the student's band per skill across all scored attempts, enabling visual tracking of improvement over time.
Given: A student has at least 2 completed and fully scored attempts
When: The progression chart is displayed
Then: The chart shows 4 lines (one per skill) with x-axis = attempt date, y-axis = band (A1 to C on ordinal scale); data points are clickable to show the attempt detail; if a skill has only 1 data point, it is shown as a point, not a line; the chart is interactive (hover shows exact band and date)

---

**FR-54 [Essential]: Per-attempt Skill Breakdown**
Requirement: The system shall display a detailed breakdown of scores per part for each skill within a specific attempt.
Given: A student or Teacher views a specific attempt
When: The skill breakdown section is expanded
Then: For Reading/Listening: per-part correct count (e.g., "Part A: 4/5"), total raw score, band; for Writing: word count per part, band (after teacher confirms); for Speaking: per-part band (after teacher confirms); parts with the lowest scores are visually highlighted; the overall skill band is prominently displayed

---

**FR-55 [Essential]: Strengths and Weaknesses Summary**
Requirement: The system shall compute and display a summary of a student's consistently weak and strong areas across all attempts, highlighting parts where performance is below or above average.
Given: A student has at least 2 scored attempts
When: The student views the strengths/weaknesses panel
Then: The system computes average score per part across all attempts; parts with average below the tenant-configured threshold are shown as "Areas to improve"; parts consistently above threshold are shown as "Strengths"; the summary is updated every time new scored results are added

---

**FR-56 [Essential]: Teacher Feedback Access for Students**
Requirement: The system shall display the teacher-confirmed feedback narrative for Writing and Speaking to the student, accessible from the attempt detail screen, after the score has been finalized.
Given: A Teacher has confirmed the score for Writing/Speaking (FR-33) and the attempt_results status is available
When: A student views the attempt detail
Then: The system displays the feedback narrative for each Writing and Speaking part where feedback was provided; the feedback includes: part name, criterion scores, overall band, and narrative text; if feedback is not yet confirmed, a "Results pending teacher review" placeholder is shown instead

---

**FR-57 [Essential]: Class Score Overview for Teachers**
Requirement: The system shall display a class-level analytics dashboard for Teachers showing the average band per skill across all students in the class for each exam session.
Given: A Teacher selects a class and an exam session
When: The class analytics page loads
Then: The system displays: average band per skill (as band label + numeric average), number of students who completed vs. not started, band distribution count per skill (how many students at each band level); data is scoped to the selected class and session; the Teacher can compare across multiple sessions

---

**FR-58 [Essential]: Student Ranking within Class**
Requirement: The system shall display a ranked list of students in a class ordered by total score (or configurable metric) for a selected exam session.
Given: A Teacher views the class analytics for a session
When: The ranking table is requested
Then: The system displays students ranked by: overall score (sum of skill scores or average band), with columns: Rank, Student Name, Reading Band, Listening Band, Writing Band, Speaking Band, Total Score; the Teacher can sort by any column; [NEEDS USER INPUT: should student names be anonymizable? — OI-04 adjacent concern]

---

**FR-59 [Essential]: Weak Student Alert**
Requirement: The system shall highlight students whose band in any skill falls below a configurable threshold for the selected session; the list is accessible to Teachers and Tenant Admins.
Given: A Teacher or Tenant Admin views class analytics
When: The weak student alerts panel is displayed
Then: The system lists students whose band in at least one skill is below the configured threshold (default: B1 [NEEDS USER INPUT: confirm default threshold]); each row shows: student name, skill(s) with low band, band value; the list can be exported to Excel

---

**FR-60 [Essential]: Before/After Comparison**
Requirement: The system shall compute and display the change in average band per skill between the first and most recent exam session for a class, showing improvement (or regression) over time.
Given: A Teacher selects a class that has at least 2 completed exam sessions
When: The before/after comparison is displayed
Then: The system computes: avg_band_first_session and avg_band_latest_session per skill; displays the delta with a directional indicator (↑ improved, ↓ regressed, = no change); delta is shown as number of band levels changed (e.g., +1 band = improved from A2 to B1)

---

**FR-61 [Essential]: Score Distribution Histogram**
Requirement: The system shall display a histogram of score distribution for a class across a selected skill for a selected session.
Given: A Teacher selects a class, session, and skill
When: The histogram is displayed
Then: The system renders a bar chart with x-axis = band level (A1, A2, B1, B2, C) and y-axis = number of students; bars are color-coded by band; the histogram is downloadable as PNG

---

**FR-62 [Essential]: Tenant Admin KPI Dashboard**
Requirement: The system shall provide Tenant Admins and Viewers with an overview dashboard showing key performance indicators for the entire tenant.
Given: A Tenant Admin or Viewer navigates to the dashboard
When: The dashboard loads
Then: The system displays: total active courses (count), total enrolled students (count, vs. seat_count quota), total exam sessions this month, overall completion rate (submitted / total eligible), license status (seats_used / seat_count with color indicator), upcoming sessions (next 7 days)

---

**FR-63 [Essential]: Band Distribution Chart for Tenant**
Requirement: The system shall display school-wide band distribution charts showing how students are distributed across APTIS bands for each skill, aggregated across all sessions and courses within the tenant.
Given: A Tenant Admin or Viewer accesses the analytics section
When: The band distribution chart is displayed
Then: The system renders a pie or bar chart per skill: proportion of students at each band (A1–C) based on their most recent scored attempt; charts are filterable by course and time period; the Tenant Admin can drill down to see which class/course contributes to each band group

---

**FR-64 [Essential]: Course Activity Overview**
Requirement: The system shall display a summary table of all courses within the tenant showing: course name, enrollment count, sessions count, completion rate, and average band per skill.
Given: A Tenant Admin accesses the courses analytics section
When: The table loads
Then: The system computes per course: number of enrolled students, number of exam sessions created, average completion rate, average band for each of the 4 skills (across all sessions in the course); the table is sortable by any column; clicking a course drills into course-level detail

---

**FR-65 [Essential]: License Usage Dashboard Indicator**
Requirement: The system shall display the current seat usage as a visual progress bar on the Tenant Admin dashboard, with color thresholds matching the quota alert rules.
Given: A Tenant Admin views the dashboard
When: The license usage section renders
Then: A progress bar shows seats_used / seat_count; color: green when < 70% used, yellow when 70–89% used, red when ≥ 90% used; below the bar: exact count label ("150 of 200 seats used") and expiry date; a "Contact Sales" link appears when ≥ 90% or when expiry is within 30 days

---

**FR-66 [Essential]: Report Export**
Requirement: The system shall allow Tenant Admins, Viewers, and Teachers (for their classes) to export analytics reports as Excel files; PDF export is Conditional for v1.
Given: A user is on any analytics view (class, course, school-wide)
When: The user clicks Export
Then: The system generates an Excel file containing all data currently displayed in the table/chart (with all rows, not just the visible page); the file is downloaded immediately; exported data respects the user's scope (Teacher: only their class data); [Conditional] PDF export of the same data; the export includes: report title, date generated, tenant name, scope (class/course/school), and all data columns

---

**FR-67 [Essential]: Item Analysis — Question Statistics**
Requirement: The system shall compute and display per-question statistics for Content Managers: correct_rate, wrong_rate per distractor option (MCQ), skip_rate, and average_time_spent.
Given: A Content Manager opens the item analysis view and selects a question
When: The statistics panel loads
Then: The system aggregates across all completed attempts globally: count of times this question appeared, correct_rate (%), wrong_rate per distractor (%), skip_rate (%), average_time_spent (seconds); data is updated after each scored session is completed

---

**FR-68 [Essential]: Difficulty Index Calculation**
Requirement: The system shall compute the difficulty index (p-value) per question and display it in the item analysis view; questions with p-value < 0.3 or > 0.9 shall be automatically flagged.
Given: A question has been used in at least 10 completed attempts (minimum sample for statistical validity)
When: The item analysis page loads
Then: The system computes p-value = (number of correct responses) / (total responses); displays p-value as percentage; flags the question as "Too Hard" (p < 0.3) or "Too Easy" (p > 0.9); unflagged questions show no flag indicator

---

**FR-69 [Essential]: Discrimination Index Calculation**
Requirement: The system shall compute the point-biserial discrimination index per question and display it; questions with discrimination index < 0.2 shall be flagged.
Given: A question has been used in at least 10 completed attempts
When: The item analysis page loads
Then: The system computes point-biserial correlation between per-question correctness (0/1) and total exam score; displays value between -1 and 1; flags the question as "Poor Discriminator" (< 0.2); negative discrimination (< 0) is flagged as "Review Required — answers correctly to this question correlate with lower overall score"

---

**FR-70 [Essential]: Flagged Questions List**
Requirement: The system shall provide Content Managers with a consolidated list of all questions flagged by item analysis (FR-68, FR-69), filterable by skill, part, and flag type.
Given: A Content Manager opens the "Flagged Questions" section
When: The list loads
Then: The system displays all questions with at least one active flag; columns: question ID/preview, skill, part, p-value, discrimination_index, flag types (Too Hard / Too Easy / Poor Discriminator / Review Required); clicking a question opens the full question editor (FR-09) and item analysis panel (FR-67) side by side; Content Manager can mark a flag as "acknowledged" (question will be reviewed next iteration)

---

## Cluster F-08: Vendor Management (FR-71 – FR-76)

---

**FR-71 [Essential]: Tenant Lifecycle Management**
Requirement: The system shall allow Super Admins to create, activate, suspend, reactivate, and decommission tenant accounts; suspended tenants cannot log in but their data is preserved.
Given: A Super Admin accesses the tenant management section
When: The Super Admin creates a new tenant or changes a tenant's status
Then: Create: system creates tenant record with slug, subdomain, contact email, and status=pending (not yet active); Activate: status=active, subdomain begins routing; Suspend: status=suspended, all Tenant users receive a 403 response with a message (configurable); Reactivate: status=active, access restored; Decommission: status=decommissioned (data preserved, no logins, contact Super Admin to restore); all status changes are logged with timestamp and actor

---

**FR-72 [Essential]: Tenant Configuration**
Requirement: The system shall allow Super Admins to configure per-tenant settings: timezone, display name, and optionally a logo URL for tenant portal branding.
Given: A Super Admin edits tenant settings
When: The settings are saved
Then: The tenant portal header shows the configured display name and logo (if provided); all datetime displays within the tenant portal use the configured timezone; configuration changes take effect immediately without requiring re-login

---

**FR-73 [Essential]: License Management (Create, Extend, Adjust)**
Requirement: The system shall allow Sales Team members to create seat-based licenses for tenants, extend expiry dates, and adjust seat counts; licenses are associated with a tenant and have a seat_count and expiry_date.
Given: A Sales Team member opens the license form for a tenant
When: The license is saved
Then: The license record is created with: tenant_id, seat_count, expiry_date, created_by (sales user), created_at; the tenant's effective quota = most recent active license's seat_count; if a tenant has no active license, tenant is in read-only mode (BR-10); extending: updates expiry_date on current license; adjusting seats: updates seat_count; all changes are logged

---

**FR-74 [Essential]: Automated License and Quota Alerts**
Requirement: The system shall send automated email alerts to Tenant Admins and Sales Team when: tenant seat usage reaches 80%, reaches 90%, license expires in 30 days, and license expires in 7 days.
Given: Any of the threshold conditions are met
When: The system's scheduled job checks thresholds (runs at least daily)
Then: For 80% seat usage: email sent to Tenant Admin; for 90% seat usage: email sent to Tenant Admin + Sales Team; for 30-day expiry: email to Tenant Admin + Sales Team; for 7-day expiry: email to Tenant Admin + Sales Team; alerts are not repeated if already sent for the same threshold crossing (idempotent); alert status logged per tenant per threshold

---

**FR-75 [Essential]: Tenant Usage Monitoring**
Requirement: The system shall allow Super Admins and Support Staff to view usage statistics per tenant: seats_used, total exam sessions (all time and this month), total student attempts, last_activity timestamp, and license status.
Given: A Super Admin or Support Staff opens a tenant detail page
When: The page loads
Then: The system displays: tenant name, slug, status, license (seats, expiry), seats_used / seat_count, total exam sessions (all-time and current month), total student attempts (all-time), last activity (most recent login timestamp from any user in the tenant); all data is read-only for Support Staff

---

**FR-76 [Conditional]: Support Staff Read-only Tenant Impersonation**
Requirement: The system shall allow Support Staff to enter a read-only impersonation view of any tenant's portal, logging every impersonation session with the Support Staff user ID, tenant ID, start time, and end time.
Given: A Support Staff member opens a tenant detail and clicks "View as Tenant Admin"
When: The impersonation view launches
Then: The system creates an impersonation_log entry; the Support Staff sees the Tenant Portal as a Tenant Admin would, but all write actions (buttons) are disabled or hidden; a persistent banner reads "Viewing as [Tenant Name] — Read Only | [Exit Impersonation]"; clicking Exit closes the impersonation view and logs the end time; impersonation does not create a real Tenant Admin session token

---

## Cluster F-09: Sales Team Portal (FR-77 – FR-82)

---

**FR-77 [Essential]: Customer (Tenant) List**
Requirement: The system shall display a sortable, filterable list of all tenants for Sales Team members, showing: tenant name, contact email, license status (active/expiring/expired), seats_used/seat_count, and expiry date.
Given: A Sales Team member opens the Sales Portal
When: The customer list loads
Then: The system displays all tenants in a table; color-coded license status: green = active with > 30 days, yellow = expiring within 30 days, red = expired; sortable by: name, expiry date, seat usage %; search by tenant name or contact email; clicking a tenant opens the tenant detail view

---

**FR-78 [Essential]: Create New License**
Requirement: The system shall allow Sales Team members to create a license for a tenant by specifying seat count and expiry date; the license activates immediately upon save.
Given: A Sales Team member selects a tenant and opens the create license form
When: The form is submitted with seat_count and expiry_date
Then: The license record is created and the tenant's quota updates immediately; if the tenant previously had no active license, their status changes from read-only to active; the Sales Team member sees a confirmation with the new license details; an email notification is sent to the Tenant Admin confirming license activation

---

**FR-79 [Essential]: Renew or Extend License**
Requirement: The system shall allow Sales Team members to extend the expiry date of an existing active or recently expired license; extending an expired license re-activates the tenant from read-only mode.
Given: A Sales Team member opens a tenant with an active or expired license
When: The Sales member enters a new expiry_date and confirms
Then: The license record is updated with the new expiry_date; if previously expired: tenant status returns to active; the license history shows the previous expiry and the new expiry; an email notification is sent to the Tenant Admin confirming the renewal

---

**FR-80 [Essential]: Adjust Seat Quota**
Requirement: The system shall allow Sales Team members to increase or decrease the seat count on a tenant's current license; decreasing seat count below seats_used is blocked.
Given: A Sales Team member enters a new seat_count
When: The adjustment is submitted
Then: If new seat_count < seats_used: the system rejects the change with: "Cannot reduce seats below current usage ({seats_used} seats in use). Please unenroll students first or set a higher count."; if valid: license.seat_count is updated immediately; the Tenant Admin dashboard reflects the new quota; the change is logged in license history

---

**FR-81 [Essential]: License History per Tenant**
Requirement: The system shall maintain a complete history of all license changes for each tenant, showing: license ID, created_by, created_at, seat_count, expiry_date, last_modified_by, last_modified_at, and status (active/expired/superseded).
Given: A Sales Team member or Super Admin opens a tenant's license history
When: The history page loads
Then: The system displays all license records for that tenant in reverse chronological order; each row is expandable to show full audit details; no license record can be deleted (immutable audit log)

---

**FR-82 [Essential]: Expiry Alert View for Sales**
Requirement: The system shall display a prioritized list of tenants with licenses expiring within the next 30 days on the Sales Portal dashboard.
Given: A Sales Team member opens the Sales Portal
When: The expiry alerts panel loads
Then: The system displays tenants sorted by days_until_expiry ascending; columns: tenant name, expiry date, days remaining, seats_used/seat_count, contact email; a "Renew" button per row pre-populates the renewal form (FR-79) for that tenant; expired tenants (0 days remaining) appear at the top with red status

---

## Cluster F-10: Notification System (FR-83 – FR-87)

---

**FR-83 [Essential]: Email Notifications — All Triggers**
Requirement: The system shall send email notifications for all defined trigger events; each email shall use the configured template for the event type and the tenant's configured language.
Given: Any of the following events occurs:
- Exam session published → enrolled students
- Exam session T-24h before start → enrolled students
- Exam session T-1h before start → enrolled students
- Auto-score complete (Reading/Listening) → student
- Writing/Speaking pending review → assigned Teacher/Coordinator
- Writing/Speaking score confirmed → student
- Review SLA approaching [TBD — OI-03] → Teacher/Coordinator
- Seat quota 80% → Tenant Admin
- Seat quota 90% → Tenant Admin + Sales Team
- License expiry 30 days → Tenant Admin + Sales Team
- License expiry 7 days → Tenant Admin + Sales Team
- Account created (bulk) → student (email with temporary password)
When: The event trigger fires
Then: The system enqueues an email job; the job calls the email service API with: recipient address, template ID, and template variables; on success: logs delivery_status=sent; on failure: retries once after 5 minutes; if second attempt fails: logs delivery_status=failed and alerts Super Admin monitoring

---

**FR-84 [Conditional]: Push Notifications (Flutter Mobile)**
Requirement: The system shall send push notifications to students on Flutter mobile (iOS/Android) for: exam session published, exam starting soon (T-24h and T-1h), and score available events; push notifications are in addition to (not replacing) email.
Given: A student has the Flutter mobile app installed and has granted push notification permission
When: A trigger event fires (same triggers as FR-83 for student-facing events)
Then: The system sends a push notification via Firebase Cloud Messaging to the student's registered device token; notification includes: title, body, and a deep link to the relevant exam or result screen; if the device token is no longer valid (uninstalled app), the system removes the stale token from the database
Note: This FR is Conditional — only required if Flutter Mobile is included in platform targets (OI-01)

---

**FR-85 [Essential]: Email Template Management**
Requirement: The system shall allow Super Admins to view and edit email templates for all notification types; templates shall support variable substitution and Vietnamese/English versions.
Given: A Super Admin opens the email template manager
When: The Super Admin selects a template type and edits it
Then: The template editor shows: subject line, HTML body with variable placeholders (e.g., {{student_name}}, {{session_name}}, {{session_date}}), language selector (Vietnamese / English); preview with sample data; save creates a new version of the template; the previous version is preserved for rollback; [NEEDS USER INPUT: which language is default per tenant — OI-06 adjacent]

---

**FR-86 [Essential]: Notification Preferences**
Requirement: The system shall allow Tenant-side users to opt out of specific non-critical notification types; critical notifications (account created, score available, license expiry) cannot be opted out.
Given: A user opens their notification preferences
When: The user toggles notification types
Then: The system saves the user's preferences; subsequent notifications check preferences before sending; if a user has opted out of "Exam reminder" emails, the T-24h and T-1h reminders are not sent to that user; critical notifications (score_available, account_created, license_expiry) cannot be disabled and are always sent regardless of preferences

---

**FR-87 [Essential]: Notification Delivery Logging**
Requirement: The system shall log every notification attempt with: recipient, notification_type, event_trigger, sent_at, delivery_status (sent/failed/bounced), and provider response.
Given: Any notification is sent or attempted
When: The email/push service returns a response
Then: The system creates a notification_log entry with all fields; failed notifications are visible to Super Admin in a monitoring view; bounced emails trigger a flag on the user account (email_bounced=true) so future sends can be skipped or flagged; delivery logs are retained for [TBD — OI-07] days

---

## Cluster F-11: Guest / Trial Flow (FR-88 – FR-92) — Conditional

---

**FR-88 [Conditional]: Trial Landing Page**
Requirement: The system shall provide a publicly accessible landing page (no login required) that introduces the APTIS LMS platform and offers a "Start Free Trial" call-to-action.
Given: An unauthenticated user navigates to the trial URL
When: The page loads
Then: The system renders the landing page with: platform description, list of skills available in the trial, estimated trial duration, and a "Start Trial" button; the page is accessible without any login or email entry; the page must load within 3 seconds on a standard broadband connection

---

**FR-89 [Conditional]: Trial Exam**
Requirement: The system shall provide a limited practice exam for Guest users using a fixed sample question set; the scope of the trial exam (which skills, how many questions) is configurable by the Super Admin.
Given: A Guest user clicks Start Trial
When: The trial exam begins
Then: The system creates an anonymous session (FR-08); the trial exam uses the configured sample question set (not pulled from tenant question banks); the trial uses the same exam interface as the registered exam (FR-20 to FR-25) but with reduced scope; timer and audio function as in the real exam; upon completion, the trial is finalized and the Guest is redirected to the trial results screen (FR-90); [NEEDS USER INPUT: trial scope — which skills, how many questions per part — OI-06]

---

**FR-90 [Conditional]: Trial Result Display**
Requirement: The system shall display a simplified result summary to the Guest upon trial exam completion, including an estimated band for scored skills and a call-to-action to contact Sales.
Given: A Guest has completed the trial exam
When: The results are computed (auto-score only for trial — no Speaking/Writing AI scoring in trial unless configured)
Then: The system displays: estimated band per skill attempted (with disclaimer "This is a sample result — not an official APTIS score"), a brief explanation of what each band means, and a prominent CTA: "Muốn triển khai cho trường hoặc trung tâm của bạn? Liên hệ ngay" (with a link or contact form); the results are displayed for the current session only and not persisted after session expiry

---

**FR-91 [Conditional]: Lead Capture (Optional)**
Requirement: The system may optionally prompt Guest users to provide their contact information after viewing trial results; this prompt is non-mandatory and must include explicit consent for follow-up.
Given: A Guest has viewed trial results (FR-90)
When: The optional lead capture prompt is displayed
Then: The prompt asks for: name and email address; includes explicit checkbox: "Tôi đồng ý được liên hệ lại về dịch vụ APTIS LMS"; if the Guest provides info and checks consent: the system records the lead (name, email, consent_timestamp, trial_result_summary) and alerts the Sales Team; if the Guest declines or closes the prompt: no data is stored; [NEEDS USER INPUT: is lead capture required for v1? — OI-06]

---

**FR-92 [Conditional]: Guest Data Purge**
Requirement: The system shall automatically purge all data associated with Guest/Trial sessions (anonymous session record, trial answers, trial result) after a configurable retention period.
Given: A Guest trial session was created at timestamp T
When: The scheduled purge job runs and (current_time - T) > retention_days
Then: The system deletes: anonymous_session record, associated trial_exam_answers, trial_result record; if a lead was captured (FR-91), the lead record follows a separate retention policy; [NEEDS USER INPUT: retention_days value — OI-07]; the purge job runs daily; purge is logged in audit_log with count of purged records (no PII in log)

---

## Cluster F-12: Exam Integrity / Anti-cheat (FR-93 – FR-103)

---

**FR-93 [Essential]: Question Order Randomization**
Requirement: The system shall randomize the order of questions within each part for every exam attempt; the randomization seed shall be stored with the attempt so that the same order is restored on resume.
Given: A student begins an exam attempt
When: The attempt is initialized
Then: The system generates a unique random seed for the attempt; uses the seed to shuffle question order within each part; stores the seed in the exam_attempt record; when the student resumes after disconnect (FR-106), the same seed restores the same question order; every student in the same session sees a different question order (with overwhelming probability)

---

**FR-94 [Essential]: MCQ Answer Option Randomization**
Requirement: The system shall randomize the order of answer options for all MCQ questions in each attempt, using the same seed as question order (FR-93).
Given: An exam attempt is initialized
When: MCQ questions are rendered to the student
Then: Answer options A/B/C/D are shuffled per question per attempt; the correct answer option is mapped to its shuffled position correctly (auto-scoring still matches against the content of the correct answer, not its original position letter); the shuffled order is deterministic given the same seed (for resume consistency)

---

**FR-95 [Essential]: Fullscreen Enforcement Before Exam Start**
Requirement: The system shall require the student to enter fullscreen mode before beginning the exam; the system shall not allow the exam to start if fullscreen is not active.
Given: A student has passed eligibility check (FR-17) and pre-exam checks are displayed (FR-18)
When: The student clicks "Enter Exam"
Then: The system requests fullscreen mode via the browser/platform fullscreen API; if the user grants fullscreen: the exam begins; if the user denies or cannot enter fullscreen: the system displays instructions and does not advance; on Flutter Desktop: fullscreen is enforced at the window level; on Flutter Web: uses browser fullscreen API; exiting fullscreen mid-exam triggers a violation event (FR-96)

---

**FR-96 [Essential]: Tab and Window Switch Detection**
Requirement: The system shall detect when a student switches to a different browser tab or minimizes the exam window during an exam, logging each occurrence as a violation event.
Given: A student is in an active exam attempt
When: The browser/app detects a focus loss event (visibilitychange=hidden, window blur, tab switch)
Then: The system logs a violation_event: {attempt_id, violation_type="tab_switch", timestamp, violation_count}; violation_count is incremented; if violation_count reaches warning_threshold: display in-exam warning overlay ("You have switched away from the exam N times. Further violations may result in automatic submission."); if violation_count reaches terminate_threshold: the system auto-submits the attempt (same as FR-26 submit flow)

---

**FR-97 [Essential]: Focus Loss Detection**
Requirement: The system shall detect when the exam window loses OS-level focus (e.g., student Alt-Tabs to another application on Desktop) and log it as a violation event distinct from tab switching.
Given: A student is in an active exam on Flutter Desktop
When: The Flutter app loses window focus (window_focus_change event = false)
Then: The system logs a violation_event: {attempt_id, violation_type="focus_loss", timestamp}; this contributes to the same violation_count as tab switching (FR-96); Flutter Web focus loss is detected via the document visibility API; violation threshold logic applies identically

---

**FR-98 [Essential]: Copy-Paste and Right-Click Blocking**
Requirement: The system shall disable copy (Ctrl+C), paste (Ctrl+V), and context menu (right-click) within all exam content areas to prevent content copying or external paste assistance.
Given: A student is in an active exam attempt
When: The student attempts to copy text (Ctrl+C), paste text (Ctrl+V), or right-click within the exam content area
Then: The action is intercepted and cancelled; no system alert is shown to the student (silent blocking); text selection within exam reading passages is disabled; writing inputs (FR-21) allow normal typing but block paste from clipboard; this does not apply to the Speaking waveform or navigation buttons

---

**FR-99 [Essential]: Browser Navigation Blocking**
Requirement: The system shall block or intercept browser/app navigation actions during an active exam: browser Back button, address bar entry, F5/Ctrl+R refresh, and window close.
Given: A student is in an active exam
When: The student attempts any browser navigation action
Then: Back button: intercepted, no navigation occurs, an in-app warning shows "You cannot go back during the exam"; address bar / navigation away: browser beforeunload event triggers warning dialog; F5/Ctrl+R refresh: intercepted where possible; if a page reload does occur (e.g., browser crash): exam state is recovered from server on reload (FR-106 — resume logic); window close: triggers beforeunload dialog "Are you sure you want to leave? Your progress will be saved."

---

**FR-100 [Essential]: Violation Threshold Enforcement**
Requirement: The system shall enforce configurable warning and termination thresholds for anti-cheat violations; thresholds are set per exam session during session creation and cannot be changed after the session begins.
Given: An exam session has configured warning_threshold (W) and terminate_threshold (T)
When: A student's violation_count reaches W
Then: An overlay warning is displayed to the student: "Warning: You have been detected leaving the exam [W] time(s). If you leave [T-W] more time(s), your exam will be automatically submitted."; when violation_count reaches T: the system force-submits the attempt (FR-26 flow), locks the session for that student, and notifies the Exam Coordinator; [NEEDS USER INPUT: default values for W and T — OI-04]

---

**FR-101 [Essential]: Violation Event Logging**
Requirement: The system shall maintain an immutable log of all anti-cheat violation events per attempt, storing: violation_type, timestamp, and cumulative count at the time of each event.
Given: Any violation event is detected (FR-96, FR-97, FR-95 exit)
When: The violation event is processed
Then: The system creates a violation_event record: {id, exam_attempt_id, violation_type (tab_switch/focus_loss/fullscreen_exit/copy_paste_attempt), timestamp, cumulative_count_at_time}; violation_events are immutable (cannot be deleted by Teachers or Coordinators); Super Admin can purge records per data retention policy (OI-07); violation_events are visible to Exam Coordinators in the live monitor (FR-39) and in the post-session integrity report (FR-103)

---

**FR-102 [Conditional]: Kiosk Mode on Flutter Desktop**
Requirement: The system shall request OS-level window locking on Flutter Desktop platforms to prevent students from switching to other applications during the exam; the level of enforcement depends on platform capabilities.
Given: A student launches the Exam Client on Flutter Desktop (Windows or macOS)
When: The exam is in progress
Then: On Windows: the system requests always-on-top window mode and disables taskbar access where API permits; on macOS: the system requests full-screen mode that disables Mission Control and Expose where API permits; if OS-level lock fails (insufficient permissions): fall back to detection-based violation logging (FR-96, FR-97) and log that kiosk enforcement was unavailable; the student is informed before the exam if kiosk mode failed to activate

---

**FR-103 [Essential]: Post-session Integrity Report**
Requirement: The system shall generate a per-session integrity report accessible to Exam Coordinators and Tenant Admins after a session completes, listing all students with their violation counts and types.
Given: An exam session has been closed (all attempts submitted or session ended)
When: A Coordinator or Tenant Admin opens the session's integrity report
Then: The system displays a table: Student Name, Total Violations, Violation Breakdown (tab_switch count, focus_loss count, fullscreen_exit count), Status (no violations / warning level / terminated by system); students who were auto-terminated by violation threshold are highlighted; the report is exportable to Excel; the report can be used as supporting documentation for academic integrity decisions

---

## Cluster F-13: Exam Continuity — Cross-cutting (FR-104 – FR-111)

---

**FR-104 [Essential]: Server-authoritative Timer Implementation**
Requirement: The system shall track exam part timers exclusively on the server; the client shall display a countdown synchronized with the server value; client-side time cannot extend, reset, or pause the server timer.
Given: A student begins an exam part at server time T_start
When: The client requests time_remaining
Then: The server returns: part_duration - (current_server_time - T_start); the client renders this value; the client requests an updated time_remaining every 10 seconds to stay in sync; if the client's local clock drifts from server time, the server value overrides; when server determines time_remaining ≤ 0: the server closes the part and rejects any further answers for that part (HTTP 409); the client syncs on next poll or on server push and transitions to the next part

---

**FR-105 [Essential]: Per-answer Server-side Persistence**
Requirement: The system shall persist every student answer to the server database immediately when the student selects or types a response, before the student navigates to the next question; batch submission at end of exam is not used.
Given: A student selects an MCQ answer or changes text in a Writing field
When: The answer is entered (on selection for MCQ; on debounced input for text, e.g., 1s after typing stops)
Then: The system sends a PATCH request to the exam state endpoint: {attempt_id, question_id, answer_value}; the server updates the exam_state record for that question; on success: client marks the question as saved (visual indicator); on failure (network error): client retries up to 3 times; answers not yet saved are held in client memory until successfully acknowledged; the final "submit" action (FR-26) is a finalization call, not a data transfer

---

**FR-106 [Essential]: Resume After Disconnect**
Requirement: The system shall allow a student who disconnected during an exam to resume from exactly where they left off, including the current question position, all previously saved answers, and the remaining server-side time.
Given: A student lost connection during an active exam attempt and reconnects
When: The student reopens the exam app and logs in
Then: The system detects an in-progress attempt (exam_attempt.status = in_progress); the student is shown: "You have an active exam. Resume from where you left off?" with a Resume button; clicking Resume: the client fetches exam_state (all saved answers), current part, current question index, and time_remaining from server; the exam resumes with the correct state; the time that elapsed during the disconnect is included in the server-authoritative elapsed time; if the exam window has expired during the disconnect, the attempt is auto-submitted with saved answers

---

**FR-107 [Essential]: Offline Indicator and Graceful Network Handling**
Requirement: The system shall detect network connectivity loss and display a persistent non-blocking indicator; the student shall be able to continue answering questions (answers buffered) for a limited time while offline.
Given: A student loses network connectivity during an exam
When: The network goes offline
Then: The system displays a persistent banner: "Connection lost — your progress is being saved locally. Reconnecting..." with a spinner; the student can continue to answer questions (answers buffered in client memory); when connection is restored, all buffered answers are flushed to the server (FR-105 resume flow); the offline banner disappears and shows a brief "Connected" message; if offline duration exceeds [TBD: configurable threshold, suggested 5 minutes], a more prominent warning is shown

---

**FR-108 [Essential]: Speaking Audio Local Buffer**
Requirement: The system shall record Speaking audio into a local buffer (device memory or IndexedDB for web) and upload to Cloud Storage either progressively during recording or immediately after the part ends; if upload fails, the local buffer is retained for retry.
Given: A student is recording a Speaking part response
When: The recording is in progress or has just completed
Then: Audio data is written to local buffer in real time; during recording: the system attempts progressive upload in chunks if network is available; after recording stops: any remaining buffer is uploaded; if the upload attempt fails: the system retries with exponential backoff (retry delays: 5s, 10s, 30s, 1min, 2min); if all retries fail: the local buffer is preserved and marked as pending_upload; the exam does not fail or block the student from continuing; the Exam Coordinator is notified that audio for this student's Speaking is pending

---

**FR-109 [Essential]: Speaking Partial Recording Recovery**
Requirement: The system shall preserve and submit partial Speaking recordings when a recording is interrupted mid-way; partial recordings shall be uploaded and flagged for teacher manual review rather than being discarded.
Given: A Speaking recording starts and is interrupted (network disconnect, app crash, user closes app)
When: The system encounters an incomplete recording
Then: The partial audio (however many seconds recorded before interruption) is preserved in local buffer; on reconnect: the partial audio is uploaded to Cloud Storage with metadata flag partial_recording=true; the exam_state marks that Speaking part as partially_recorded; the scoring pipeline (FR-30) processes the partial audio with an annotation; the Teacher's review queue (FR-32) shows "Partial Recording" indicator for affected Speaking parts; Teacher reviews with this context

---

**FR-110 [Essential]: Microphone Failure Handling During Speaking**
Requirement: The system shall detect microphone failure at the start of the Speaking skill and present the student with clear options; the student shall not be silently penalized for a technical device failure.
Given: A student reaches the Speaking skill and the system attempts to access the microphone
When: Microphone detection fails (permission denied, device not found, device error)
Then: The system displays a troubleshooting screen with: specific error message, step-by-step instructions to enable microphone permissions (per platform), a "Retry" button to test again; if retry succeeds: proceed normally; if all retries fail: the student is presented with options: (A) Signal proctor/coordinator — sends an alert to the Exam Coordinator in the live monitor (FR-39) with status "Microphone Error"; (B) Skip Speaking — creates a skip_recorded event, marks Speaking as skipped; the Teacher is notified of the skip and the reason; the exam is not auto-terminated by microphone failure alone

---

**FR-111 [Essential]: Browser/App Crash and Restart Recovery**
Requirement: The system shall allow a student to recover their exam session after a browser crash or app force-close, restoring all previously saved answers and the current server-authoritative time.
Given: A student's browser crashes or the Flutter app force-closes during an active exam
When: The student reopens the browser/app within the exam session window
Then: The student lands on the login page (or auto-logs in if session token persists); the system detects the in-progress attempt; the resume flow (FR-106) is triggered automatically; all answers saved before the crash (FR-105) are restored; the Speaking audio local buffer (FR-108) is checked — if partial audio was buffered but not uploaded: upload proceeds on reconnect; if the session window has expired during the crash: the attempt is auto-submitted with all saved data and marked as force_submitted_on_crash=true for Coordinator review
