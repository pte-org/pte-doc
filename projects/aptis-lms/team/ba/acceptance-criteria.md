# Acceptance Criteria — APTIS LMS

## Acceptance Criteria

### US-001 — authenticate users via email and password, scoping the login context to the tenant identified b

**Scenario: Happy path / specified behavior**

- **Given** a user navigates to `{slug}.aptis-lms.vn/login` and enters their email and password
- **When** the login form is submitted
- **Then** if the credentials match a user account whose `tenant_id` matches the resolved tenant, the system issues a JWT access token and a refresh token and redirects the user to their role-appropriate home screen
- **And** if the credentials are invalid or the user account belongs to a different tenant, the system returns HTTP 401 with body `{"code":"INVALID_CREDENTIALS","message":"Invalid email or password"}`
- **And** the system does not reveal whether the email exists (unified error message prevents enumeration)
- **And** five consecutive failed attempts from the same IP within 10 minutes trigger a 429 rate-limit response

**Scenario: Authorization or validation rejection**

- **Given** the credentials, token, tenant context, or permission is invalid
- **When** the protected operation is requested
- **Then** the system returns HTTP 401 or 403 as appropriate and discloses no account or cross-tenant information
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a token or reset link reaches its exact expiry boundary
- **When** the token is presented
- **Then** the system treats expired credentials as invalid and requires a fresh authentication or recovery flow
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** User submits the login form with email and password
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-002 — issue a short-lived JWT access token (TTL ≤ 15 minutes) and a long-lived rotating refresh token

**Scenario: Happy path / specified behavior**

- **Given** a user's access token has expired and the client holds a valid refresh token
- **When** the client sends `POST /api/v1/auth/refresh` with the refresh token in the request body
- **Then** the system issues a new access token (TTL = 15 minutes) and a new refresh token (TTL = 7 days from issuance)
- **And** the old refresh token is immediately invalidated; any subsequent use of the old refresh token returns HTTP 401
- **And** the access token payload contains: `user_id`, `tenant_id`, `roles[]`, `exp`
- **And** if the refresh token is expired or invalid, the system returns HTTP 401 and the client redirects the user to the login screen

**Scenario: Authorization or validation rejection**

- **Given** the credentials, token, tenant context, or permission is invalid
- **When** the protected operation is requested
- **Then** the system returns HTTP 401 or 403 as appropriate and discloses no account or cross-tenant information
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a token or reset link reaches its exact expiry boundary
- **When** the token is presented
- **Then** the system treats expired credentials as invalid and requires a fresh authentication or recovery flow
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Access token expiry; client sends POST /api/v1/auth/refresh with valid refresh token
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-003 — resolve the tenant context from the `Host` header subdomain of every incoming request and scope

**Scenario: Happy path / specified behavior**

- **Given** a request arrives with `Host: hanoi-english.aptis-lms.vn`
- **When** the API gateway processes the request
- **Then** the system extracts slug `hanoi-english`, looks up the corresponding `tenant_id` in the cache (TTL = 5 minutes), and attaches `tenant_id` to the request context
- **And** all subsequent database queries in the request lifecycle include `WHERE tenant_id = {resolved_id}`
- **And** if the slug does not resolve to any tenant, the system returns HTTP 404 with `{"code":"TENANT_NOT_FOUND","message":"Tenant not found"}`
- **And** requests to `admin.aptis-lms.vn` bypass tenant resolution and route to Vendor Portal handlers with no `tenant_id` constraint

**Scenario: Authorization or validation rejection**

- **Given** the credentials, token, tenant context, or permission is invalid
- **When** the protected operation is requested
- **Then** the system returns HTTP 401 or 403 as appropriate and discloses no account or cross-tenant information
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a token or reset link reaches its exact expiry boundary
- **When** the token is presented
- **Then** the system treats expired credentials as invalid and requires a fresh authentication or recovery flow
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Any HTTP or WebSocket request arrives at the platform
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-004 — support assigning multiple roles simultaneously to a single Tenant-side user

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin assigns roles `Teacher` and `Exam Coordinator` to user U
- **When** user U logs in and attempts actions
- **Then** user U can perform all actions permitted by either the Teacher role or the Exam Coordinator role (union of permissions)
- **And** removing the `Teacher` role from user U immediately revokes Teacher-exclusive permissions on U's next authenticated request, while Exam Coordinator permissions remain
- **And** a user with no roles assigned receives HTTP 403 on any protected endpoint
- **And** Vendor-side roles (Super Admin, Content Manager, Support Staff, Sales Team) cannot be assigned to Tenant users and vice versa

**Scenario: Authorization or validation rejection**

- **Given** the credentials, token, tenant context, or permission is invalid
- **When** the protected operation is requested
- **Then** the system returns HTTP 401 or 403 as appropriate and discloses no account or cross-tenant information
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a token or reset link reaches its exact expiry boundary
- **When** the token is presented
- **Then** the system treats expired credentials as invalid and requires a fresh authentication or recovery flow
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Tenant Admin saves a role assignment change for a user
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-005 — provide a password reset flow via email for all registered users

**Scenario: Happy path / specified behavior**

- **Given** a user navigates to the forgot-password page on their respective portal
- **When** the user submits a valid email address
- **Then** if the email matches a user in the current scope (tenant or Vendor Portal), the system enqueues a password-reset email containing a unique single-use token link valid for 60 minutes
- **And** if the email does not match any user, the system responds with the same success message (preventing email enumeration)
- **And** when the user clicks the reset link and submits a new password, the system updates the password hash, invalidates the token, and invalidates all active refresh tokens for that user
- **And** using the same reset link a second time returns HTTP 400 with `{"code":"TOKEN_USED","message":"This reset link has already been used"}`

**Scenario: Authorization or validation rejection**

- **Given** the credentials, token, tenant context, or permission is invalid
- **When** the protected operation is requested
- **Then** the system returns HTTP 401 or 403 as appropriate and discloses no account or cross-tenant information
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a token or reset link reaches its exact expiry boundary
- **When** the token is presented
- **Then** the system treats expired credentials as invalid and requires a fresh authentication or recovery flow
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** User submits their email on the forgot-password page
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-006 — force students who log in for the first time using a bulk-generated password to change their pa

**Scenario: Happy path / specified behavior**

- **Given** a student account was auto-created with a generated password and `force_password_change = true`
- **When** the student logs in for the first time
- **Then** the system intercepts the authenticated session and redirects to the change-password screen before issuing the final access token
- **And** the student cannot access any exam session, results screen, or profile page until the new password is saved
- **And** after the password is changed, `account.password_changed_at` is set and the `force_password_change` flag is cleared for this account
- **And** subsequent logins by the same student proceed to the normal home screen without the forced change intercept

**Scenario: Authorization or validation rejection**

- **Given** the credentials, token, tenant context, or permission is invalid
- **When** the protected operation is requested
- **Then** the system returns HTTP 401 or 403 as appropriate and discloses no account or cross-tenant information
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a token or reset link reaches its exact expiry boundary
- **When** the token is presented
- **Then** the system treats expired credentials as invalid and requires a fresh authentication or recovery flow
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student completes first successful login
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-007 — invalidate a user's refresh token upon logout

**Scenario: Happy path / specified behavior**

- **Given** a logged-in user clicks Logout
- **When** the logout request is processed (`POST /api/v1/auth/logout`)
- **Then** the server invalidates the current refresh token; any subsequent use of that token returns HTTP 401
- **And** the client clears all locally stored tokens (access token and refresh token)
- **And** the user is redirected to the login page
- **And** for Super Admin force-logout: all refresh tokens associated with the target user are invalidated within 1 minute, regardless of device or browser

**Scenario: Authorization or validation rejection**

- **Given** the credentials, token, tenant context, or permission is invalid
- **When** the protected operation is requested
- **Then** the system returns HTTP 401 or 403 as appropriate and discloses no account or cross-tenant information
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a token or reset link reaches its exact expiry boundary
- **When** the token is presented
- **Then** the system treats expired credentials as invalid and requires a fresh authentication or recovery flow
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** User clicks Logout; Super Admin uses force-logout action on a user record
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-008 — allow unauthenticated users to access the trial landing page and trial exam without creating an

**Scenario: Happy path / specified behavior**

- **Given** an unauthenticated user navigates to the trial URL
- **When** the user clicks "Start Trial"
- **Then** the system creates an anonymous session record (no `user_id`, no `tenant_id`) and issues an anonymous session token valid for 2 hours or until trial submission, whichever comes first
- **And** the anonymous session grants access only to the trial exam flow (FR-88–FR-92); any attempt to access tenant or registered-user endpoints returns HTTP 403
- **And** anonymous session data is purged after the retention period (FR-92)
- **And** no persistent user account is created unless the Guest explicitly submits a lead capture form (FR-91)

**Scenario: Authorization or validation rejection**

- **Given** the credentials, token, tenant context, or permission is invalid
- **When** the protected operation is requested
- **Then** the system returns HTTP 401 or 403 as appropriate and discloses no account or cross-tenant information
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a token or reset link reaches its exact expiry boundary
- **When** the token is presented
- **Then** the system treats expired credentials as invalid and requires a fresh authentication or recovery flow
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** User navigates to the public trial URL and starts the trial exam
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-009 — allow Content Managers to create, read, update, and delete questions in the APTIS question bank

**Scenario: Happy path / specified behavior**

- **Given** a Content Manager opens the question editor in the Vendor Portal
- **When** the Content Manager fills in all required fields (skill, part, question_type, content) and saves
- **Then** the system creates a question record with status `draft` and assigns a unique question ID
- **And** the question appears in the question bank browser filterable by skill, part, difficulty, topic tag, and status
- **And** attempting to save a question of type MCQ without an `answer_key` returns a validation error: `"answer_key is required for auto-score question types"`
- **And** questions linked to at least one completed exam session are version-controlled on edit (FR-14); deletion is blocked with message: `"This question has been used in completed sessions and cannot be deleted"`

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager submits the question creation or update form
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a required content field, asset constraint, or publishability rule is at its minimum boundary
- **When** Content Manager submits the question creation or update form
- **Then** the system validates the complete item or template atomically and reports field-level errors without partial publication
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager submits the question creation or update form
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-010 — allow Content Managers to upload audio files (MP3, WAV) for Listening questions and deliver the

**Scenario: Happy path / specified behavior**

- **Given** a Content Manager is editing a Listening question and selects an MP3 or WAV file (≤ 100 MB)
- **When** the upload completes
- **Then** the file is stored in Cloud Storage and a CDN URL is generated and linked to the question record
- **And** the question stores `max_play_count` (configurable; default: 1 per APTIS standard per part)
- **And** the Content Manager can preview audio playback in the question editor before saving
- **And** audio upload progress is shown in real time; upload failures display a retry button with an error message
- **And** unsupported file formats (e.g., FLAC, OGG) are rejected at upload with: `"Unsupported audio format. Accepted: MP3, WAV"`

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager selects an audio file in the question editor and uploads it
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a required content field, asset constraint, or publishability rule is at its minimum boundary
- **When** Content Manager selects an audio file in the question editor and uploads it
- **Then** the system validates the complete item or template atomically and reports field-level errors without partial publication
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager selects an audio file in the question editor and uploads it
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-011 — allow Content Managers to upload image files (JPEG, PNG, ≤ 10 MB) and associate them with Speak

**Scenario: Happy path / specified behavior**

- **Given** a Content Manager is editing a Speaking Part B question and uploads a JPEG or PNG image
- **When** the upload completes
- **Then** the image is stored in Cloud Storage, a URL is linked to the question, and a thumbnail preview renders in the editor
- **And** for Speaking Part D (compare images), the question record stores exactly two image URLs (`image_1`, `image_2`); saving with only one image returns: `"Part D questions require exactly 2 images"`
- **And** images exceeding 10 MB are rejected at upload with: `"Image exceeds the 10 MB size limit"`
- **And** the exam client renders images responsively within the speaking interface (FR-23)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager selects an image file in the question editor
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a required content field, asset constraint, or publishability rule is at its minimum boundary
- **When** Content Manager selects an image file in the question editor
- **Then** the system validates the complete item or template atomically and reports field-level errors without partial publication
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager selects an image file in the question editor
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-012 — allow Content Managers to create named exam templates by selecting questions per skill and part

**Scenario: Happy path / specified behavior**

- **Given** a Content Manager opens the exam template builder
- **When** the Content Manager selects questions for each skill/part and clicks Save
- **Then** the template is saved with a name, description, and a mapping of `{skill → {part → [question_ids]}}`
- **And** attempting to publish a template missing any required part (Reading A/B/C/D, Writing A/B/C, Listening A/B/C/D, Speaking A/B/C/D/E) returns a validation error listing all missing parts
- **And** auto-fill mode selects questions randomly from the bank matching the specified criteria (skill, part, difficulty, count) and can be re-rolled by the Content Manager before saving
- **And** exam sessions created from this template use the selected question set with optional per-attempt shuffle (BR-14)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager saves an exam template
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a required content field, asset constraint, or publishability rule is at its minimum boundary
- **When** Content Manager saves an exam template
- **Then** the system validates the complete item or template atomically and reports field-level errors without partial publication
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager saves an exam template
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-013 — provide a preview mode allowing Content Managers to experience a question or full exam template

**Scenario: Happy path / specified behavior**

- **Given** a Content Manager clicks "Preview" on a published or draft question or template
- **When** the preview launches
- **Then** the system renders the question or template in an exam-like read-only interface with functional audio playback, image display, timer countdown (simulated), and navigation
- **And** no `exam_attempt`, `exam_state`, or `exam_answers` records are created during preview
- **And** play-count limits on Listening audio are simulated (audio is disabled after max plays)
- **And** the Content Manager can exit preview at any time and return to the editor; unsaved edits are preserved
- **And** a visible "PREVIEW MODE" banner distinguishes the preview from a real exam session

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager clicks "Preview" on a question or exam template
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a required content field, asset constraint, or publishability rule is at its minimum boundary
- **When** Content Manager clicks "Preview" on a question or exam template
- **Then** the system validates the complete item or template atomically and reports field-level errors without partial publication
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager clicks "Preview" on a question or exam template
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-014 — preserve the version of every question used in a completed exam session

**Scenario: Happy path / specified behavior**

- **Given** question Q (version v1) has been used in a completed exam session
- **When** a Content Manager edits and saves question Q
- **Then** the system creates question version Q-v2 marked as `is_current = true`; Q-v1 is marked `is_current = false` and `is_immutable = true`
- **And** all existing exam sessions and answer records retain a reference to Q-v1; new exam templates created after the edit reference Q-v2
- **And** attempting to edit Q-v1 directly returns HTTP 409: `"This question version is linked to completed sessions and cannot be modified"`
- **And** the question bank browser displays the current version by default; a "Version History" control shows all versions with edit timestamps

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager edits and saves a question that has prior session usage
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a required content field, asset constraint, or publishability rule is at its minimum boundary
- **When** Content Manager edits and saves a question that has prior session usage
- **Then** the system validates the complete item or template atomically and reports field-level errors without partial publication
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager edits and saves a question that has prior session usage
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-015 — allow Content Managers to import questions in bulk from CSV or Excel files conforming to the pr

**Scenario: Happy path / specified behavior**

- **Given** a Content Manager uploads a CSV or Excel file (≤ 50 MB) on the bulk import screen
- **When** the system parses the file
- **Then** the system displays a preview table of all parsed rows with a valid/error indicator per row
- **And** invalid rows are highlighted with specific error messages (e.g., `"Row 12: answer_key is required for MCQ question type"`, `"Row 5: invalid skill value 'Grammer' — expected Reading|Writing|Listening|Speaking"`)
- **And** the Content Manager can choose to import valid rows only (skipping invalid) or cancel the entire import
- **And** after a confirmed import, successfully created questions appear in the question bank with status `draft`; a summary shows: N questions created, M rows skipped (with reasons)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager uploads a file on the bulk import screen
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a required content field, asset constraint, or publishability rule is at its minimum boundary
- **When** Content Manager uploads a file on the bulk import screen
- **Then** the system validates the complete item or template atomically and reports field-level errors without partial publication
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager uploads a file on the bulk import screen
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-016 — compute and display per-question item analysis statistics for Content Managers, aggregated glob

**Scenario: Happy path / specified behavior**

- **Given** a Content Manager opens the item analysis view
- **When** the Content Manager selects a question with ≥ 10 response records
- **Then** the system displays: `correct_rate (%)`, `wrong_rate per distractor option (MCQ)`, `skip_rate (%)`, `avg_time_spent (seconds)`, `p_value`, `discrimination_index`
- **And** the system automatically flags: questions with `p_value < 0.3` as "Too Hard"; `p_value > 0.9` as "Too Easy"; `discrimination_index < 0.2` as "Poor Discriminator"; `discrimination_index < 0` as "Review Required"
- **And** questions with fewer than 10 responses show a notice: "Insufficient data for statistical analysis (N = {count})" with no flag applied
- **And** statistics are recomputed nightly from the exam_answers table

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager opens the item analysis view and selects a question or views the flagged list
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a required content field, asset constraint, or publishability rule is at its minimum boundary
- **When** Content Manager opens the item analysis view and selects a question or views the flagged list
- **Then** the system validates the complete item or template atomically and reports field-level errors without partial publication
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager opens the item analysis view and selects a question or views the flagged list
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-017 — verify student eligibility before launching an exam session

**Scenario: Happy path / specified behavior**

- **Given** a student clicks "Enter" on an assigned exam session
- **When** the system processes the launch request
- **Then** if the student is enrolled, the session window is open (`current_time` between `session.start_time` and `session.end_time`), and no prior attempt exists: an `exam_attempt` record is created with `status = in_progress` and the student proceeds to pre-exam checks (FR-18)
- **And** if the session window has not opened yet: the student sees the scheduled start time and a countdown
- **And** if the session window has closed: the student sees `"This exam session has ended"`
- **And** if the student has an existing `in_progress` attempt: the student is offered the resume flow (FR-106) instead of creating a new attempt
- **And** if the student has a `submitted` attempt and no retake has been approved: the student sees `"You have already submitted this exam"` with a View Results button

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student clicks to enter an exam session from their My Exams list
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student clicks to enter an exam session from their My Exams list
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-018 — run three sequential pre-exam checks before the student begins the first skill: microphone dete

**Scenario: Happy path / specified behavior**

- **Given** a student has passed eligibility and is on the pre-exam checks screen
- **When** the student proceeds through each check step
- **Then** Check 1 (Microphone): system requests microphone permission via platform API; records 3 seconds of audio; plays back the recording; student clicks Pass or Retry; if microphone is unavailable, student sees troubleshooting instructions and the option to signal the proctor (FR-110)
- **And** Check 2 (Fullscreen): system requests fullscreen mode; "Enter Exam" button is disabled until fullscreen is confirmed active; if fullscreen is denied, the student sees instructions and cannot proceed
- **And** Check 3 (Instructions): displays per-skill time limits and what to expect; student clicks "I understand — Begin" to acknowledge
- **And** only after all three checks pass does the system start the exam timer (FR-19) and render the first skill interface

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student is on the pre-exam checks screen and proceeds through each check
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student is on the pre-exam checks screen and proceeds through each check
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-019 — maintain authoritative exam part timers on the server

**Scenario: Happy path / specified behavior**

- **Given** a student is in an active exam part and the server has recorded `part_start_time`
- **When** `server_time - part_start_time ≥ part_duration`
- **Then** the server records `part_end_time`, persists all answers submitted up to that moment, and marks the part as `completed` in `exam_state`
- **And** any answer submission requests received after `time_remaining = 0` return HTTP 409 with `{"code":"PART_CLOSED","message":"Time for this part has expired"}`
- **And** the client displays the remaining time synchronized from the server (polled every 10 seconds); client clock drift does not affect the server-side expiry
- **And** when the client next syncs (poll or push), it transitions to the part-transition screen (FR-24)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Server-computed `time_remaining` for the current part reaches zero
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Server-computed `time_remaining` for the current part reaches zero
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-020 — render each Reading part with its correct interaction type: Part A (sentence matching), Part B 

**Scenario: Happy path / specified behavior**

- **Given** a student is in Reading Part C (MCQ with scrollable passage)
- **When** the student selects an MCQ radio button
- **Then** the system immediately persists the answer to the server (FR-105) and marks the question dot in the navigation panel with a checkmark
- **And** the student can navigate freely between questions within the current Reading part; previously selected answers are restored from the server state on navigation
- **And** the student cannot navigate back to a completed Reading part
- **And** question order within each part is shuffled per the attempt seed (FR-93); the same shuffled order is restored on resume (FR-106)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student navigates to or answers a question in a Reading part
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student navigates to or answers a question in a Reading part
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-021 — render Writing parts with appropriate text input areas and display a live word count

**Scenario: Happy path / specified behavior**

- **Given** a student is in Writing Part C (essay) with a configured word range (e.g., 150–180 words)
- **When** the student types in the textarea
- **Then** the live word count updates in real time (on each keystroke) displayed below the textarea
- **And** when count is below 80% of the minimum target: indicator color is grey; when count is within the valid range: indicator is green; when count exceeds the maximum: indicator is red
- **And** the student can still submit a response that is over the maximum (no hard block); over-length is visible to the teacher during review
- **And** Writing text is debounce-saved to the server every 1 second after the last keystroke (FR-105)
- **And** Part A renders 5 individual sentence-level text fields; Part B renders a single textarea for an email/message response

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student types in a Writing textarea
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student types in a Writing textarea
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-022 — auto-play Listening audio

**Scenario: Happy path / specified behavior**

- **Given** a student navigates to a Listening Part B question with `max_play_count = 1`
- **When** the question renders
- **Then** the audio begins playing automatically; the player shows a read-only progress bar (seek control is not present or is disabled)
- **And** a play-count indicator shows "Play 1 of 1"; after the audio finishes, the Play button is disabled and the indicator shows "0 plays remaining"
- **And** the student can answer MCQ or form-fill questions at any time during or after audio playback
- **And** if the CDN audio request fails (HTTP 5xx or timeout), the system retries up to 3 times with a 2-second delay; if all retries fail, an error message is displayed and the Exam Coordinator is notified via the live monitor (FR-39)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student enters a Listening question with an associated audio asset
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student enters a Listening question with an associated audio asset
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-023 — implement a five-stage Speaking sequence per part: instruction/image display, preparation count

**Scenario: Happy path / specified behavior**

- **Given** a student is in Speaking Part A and the preparation timer has ended
- **When** the recording phase begins
- **Then** the system starts recording via the platform microphone API; a live waveform visualization renders in real time showing audio amplitude
- **And** when the server-authoritative recording time limit is reached (FR-19 logic), recording stops automatically; the student cannot extend recording time client-side
- **And** audio is buffered locally (IndexedDB for web, platform file system for desktop) and uploaded to Cloud Storage (FR-108); the student sees an upload progress bar
- **And** upon successful upload, the student is automatically advanced to the next Speaking part
- **And** if the upload fails, the local buffer is retained and marked `pending_upload`; the student continues to the next part without blocking

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student enters a Speaking part after the preparation timer ends
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student enters a Speaking part after the preparation timer ends
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-024 — display a transition screen between exam parts showing the completed part, the next part, time 

**Scenario: Happy path / specified behavior**

- **Given** a student has completed Reading Part A
- **When** the system transitions to Reading Part B
- **Then** a transition screen displays: "Reading Part A complete. Reading Part B begins in [N] seconds" with a countdown timer
- **And** after the countdown reaches zero, the next part begins automatically; the student cannot trigger early start
- **And** a "Back" button is absent from the transition screen; browser back navigation is intercepted (FR-99)
- **And** the student's overall exam progress is shown (e.g., "Reading 1/4 parts complete")

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Part completion event
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Part completion event
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-025 — sequence exam skills in the order defined by the exam template (default: Reading → Listening → 

**Scenario: Happy path / specified behavior**

- **Given** a student has completed all four Reading parts
- **When** the system transitions to the Listening skill
- **Then** an inter-skill break screen displays the break duration countdown; the Listening timer does not start until the countdown reaches zero
- **And** the student cannot skip the break or start the next skill early
- **And** if `break_duration = 0` for the template, the transition proceeds immediately without a break screen
- **And** all four skills must be completed in the template-defined order; the exam cannot be submitted until all skills are reached (except for force-submit FR-41 or timer expiry FR-19)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student completes the final part of a skill
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student completes the final part of a skill
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-026 — finalize the exam attempt

**Scenario: Happy path / specified behavior**

- **Given** a student completes the final Speaking part
- **When** the submission is processed
- **Then** the system sets `exam_attempt.status = submitted` and `exam_attempt.submitted_at = current_server_time`
- **And** all persisted answers at the time of submission are finalized; no further answer writes are accepted (HTTP 409)
- **And** the auto-scoring pipeline is triggered for Reading and Listening (FR-27)
- **And** the AI scoring pipeline is queued for Writing and Speaking (FR-30, FR-31)
- **And** the student is redirected to the results screen: Reading and Listening bands display within 2 minutes (FR-29); Writing and Speaking show "Awaiting teacher review"

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student completes the final skill; or session window closes with an in-progress attempt
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the authoritative part timer reaches exactly zero
- **When** the student submits or changes an answer
- **Then** the server closes the part, rejects late writes with HTTP 409, and preserves all previously acknowledged answers
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student completes the final skill; or session window closes with an in-progress attempt
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-027 — automatically compute scores for Reading and Listening immediately after exam submission by com

**Scenario: Happy path / specified behavior**

- **Given** an exam attempt has been submitted with Reading and Listening answers
- **When** the auto-scoring job runs (within 2 minutes of submission)
- **Then** for each Reading and Listening answer: the system compares `student_answer` against `question.answer_key`; records `is_correct (0 or 1)` in `exam_answers`
- **And** computes `raw_score` per part as the sum of correct answers
- **And** triggers band calculation (FR-28) upon completion
- **And** the job is idempotent: re-running it on an already-scored attempt does not change scores

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Exam submission event (FR-26)
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-028 — convert raw scores for Reading and Listening into APTIS band levels (A1, A2, B1, B2, C) using t

**Scenario: Happy path / specified behavior**

- **Given** Reading raw_score = 18
- **When** band calculation runs against the configured band mapping table (e.g., Reading 18–22 → B1)
- **Then** `attempt_results.reading_band = "B1"` and `attempt_results.reading_score = 18`
- **And** if the raw score falls in a range not covered by any mapping entry, the system flags `reading_band = "MAPPING_ERROR"` and creates an alert for Vendor review
- **And** band calculation results are stored in the `attempt_results` table with a `scored_at` timestamp
- **And** band results are immediately available to the student results screen (FR-29)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Auto-scoring job completion
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-029 — make Reading and Listening band results available to the student within 2 minutes of exam submi

**Scenario: Happy path / specified behavior**

- **Given** auto-scoring and band calculation for Reading and Listening have completed
- **When** the student views the results screen
- **Then** Reading and Listening bands and scores are displayed within 2 minutes of the submission timestamp
- **And** `attempt_results.status_reading = "available"` and `attempt_results.status_listening = "available"` are set
- **And** the system sends an email notification to the student (FR-83: trigger "Reading/Listening results available")

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Band calculation job completion
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-030 — submit each Speaking audio recording to the configured STT API and store the resulting transcri

**Scenario: Happy path / specified behavior**

- **Given** a submitted exam attempt contains Speaking audio for Parts A–E
- **When** the AI scoring pipeline job runs
- **Then** for each Speaking part audio file, the system calls the configured STT API with the Cloud Storage audio URL
- **And** the returned transcript text is stored in `speaking_transcripts` with the corresponding `attempt_id` and `part`
- **And** if the STT API call fails, the system retries up to 3 times with exponential backoff (delays: 5s, 15s, 45s)
- **And** if all 3 retries fail, `speaking_transcripts.status = "STT_FAILED"` is set for that part and the assigned Teacher is alerted to review the audio recording manually
- **And** the pipeline proceeds to FR-31 for all parts where transcription succeeded

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** AI scoring pipeline job, queued by FR-26
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-031 — submit Writing text responses and Speaking transcripts to the configured LLM API with APTIS rub

**Scenario: Happy path / specified behavior**

- **Given** Writing Part C text and Speaking Part B transcript are available for an attempt
- **When** the LLM scoring job runs
- **Then** for each Writing and Speaking part, the system constructs a prompt containing: student response, APTIS rubric criteria for that part, and scoring instructions; sends the prompt to the LLM API
- **And** the LLM response `{"criterion_scores": {...}, "band_estimate": "B1", "feedback_narrative": "..."}` is stored in `ai_score_drafts` with `status = draft`
- **And** `attempt_results.status_writing` and `attempt_results.status_speaking` remain `pending_review`; the student's results screen shows "Awaiting teacher review"
- **And** the system notifies the assigned Teacher via email (FR-83: trigger "Writing/Speaking pending review")
- **And** the LLM provider can be switched via configuration change with no code change required (SI-05 provider-switch requirement)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** AI scoring pipeline job; follows FR-30 for Speaking
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-032 — present Teachers with a queue of Writing and Speaking submissions pending human review, sorted 

**Scenario: Happy path / specified behavior**

- **Given** AI draft scores exist for Writing/Speaking submissions from students in the Teacher's assigned classes
- **When** the Teacher opens the scoring queue
- **Then** the system displays all pending items scoped to the Teacher's classes, sorted by `submitted_at` ascending (oldest first)
- **And** each queue item shows: student name, attempt date, skill, part, student response (text for Writing; transcript for Speaking), AI draft score per rubric criterion, AI band estimate, AI feedback narrative
- **And** a count badge on the navigation icon shows the total number of pending items
- **And** the Teacher can click any item to open the review screen (FR-33)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Teacher opens the scoring queue
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-033 — allow Teachers to confirm AI draft scores as-is or override individual criterion scores and fee

**Scenario: Happy path / specified behavior**

- **Given** a Teacher is reviewing an AI draft score with criterion scores and feedback narrative
- **When** the Teacher (optionally edits criterion scores or feedback) and clicks Confirm
- **Then** the system creates a `final_scores` record with: `confirmed_by = teacher_id`, `confirmed_at = now()`, `final_score_per_criterion`, `final_band`, `final_feedback_narrative`
- **And** `attempt_results.status_writing` or `attempt_results.status_speaking` is set to `available`
- **And** the student receives an email notification (FR-83: "Writing/Speaking results available")
- **And** the confirmed item is removed from the Teacher's pending queue
- **And** navigating away from the review screen without clicking Confirm triggers a "Leave without saving?" dialog (the score is NOT auto-saved on navigation)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Teacher clicks Confirm on the score review screen
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-034 — display a personal results dashboard for each student showing all past attempts with per-skill 

**Scenario: Happy path / specified behavior**

- **Given** a student navigates to their results section
- **When** the results page loads
- **Then** the system displays a list of all attempts sorted by `submitted_at` descending, with columns: Date, Exam Session Name, Reading Band, Listening Band, Writing Band, Speaking Band
- **And** skills not yet scored show "Pending" in the relevant column
- **And** clicking an attempt row opens the attempt detail screen (FR-54 part breakdown)
- **And** a progression chart (FR-53) is displayed above the list if the student has ≥ 2 scored attempts

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student navigates to their results section
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-035 — display a four-skill band profile summary (Reading, Writing, Listening, Speaking bands) for any

**Scenario: Happy path / specified behavior**

- **Given** all four skills of an attempt have `status = available` in `attempt_results`
- **When** the attempt summary is viewed
- **Then** the system shows four panels (one per skill), each displaying: skill name, band level (A1/A2/B1/B2/C) prominently, and a short CEFR descriptor (e.g., "B1 — Can understand the main points of clear standard input on familiar matters")
- **And** the disclaimer is displayed: "This score is a simulation result and does not constitute an official APTIS result from British Council" (DC-11)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student or Teacher opens the attempt summary screen
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-036 — display the teacher-confirmed feedback narrative for Writing and Speaking to the student, acces

**Scenario: Happy path / specified behavior**

- **Given** the Teacher has confirmed scores for Writing Part C and Speaking Parts A–E
- **When** the student views the attempt detail
- **Then** the system displays the feedback narrative for each confirmed part, including: rubric criterion scores, overall band, and narrative text (as entered/edited by the Teacher)
- **And** parts where feedback has not yet been confirmed show: "Results pending teacher review"
- **And** the feedback is displayed in the language it was written (Vietnamese or English) without translation

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student views an attempt detail that includes confirmed Writing/Speaking results
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** an external scoring response is missing, malformed, or outside valid band values
- **When** the scoring job processes the response
- **Then** the result remains non-student-visible, is flagged for human review, and no invalid final score is published
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** STT or LLM remains unavailable after all retries
- **When** the retry budget is exhausted
- **Then** the submission enters priority manual review and the student continues to see a pending result rather than an erroneous score
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-037 — allow Teachers and Exam Coordinators to create exam sessions by specifying a session name, exam

**Scenario: Happy path / specified behavior**

- **Given** a Teacher opens the create exam session form
- **When** the form is submitted with all required fields
- **Then** the system creates an `exam_session` record with `status = scheduled`; the selected students are linked as eligible participants
- **And** anti-cheat configuration is stored: `shuffle_enabled`, `warning_threshold`, `terminate_threshold`
- **And** the session is visible on eligible students' My Exams list but cannot be entered until `session.start_time`
- **And** a notification email is queued immediately for all participants (FR-38)
- **And** `session.start_time` must be in the future; `session.end_time` must be after `session.start_time`; validation returns HTTP 422 for invalid datetime ranges

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Teacher or Exam Coordinator submits the create session form
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the session window, participant scope, or intervention value is exactly at an allowed limit
- **When** Teacher or Exam Coordinator submits the create session form
- **Then** the system applies the configured rule consistently and records any intervention with actor, reason, and timestamp
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Teacher or Exam Coordinator submits the create session form
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-038 — automatically send email notifications to all enrolled students

**Scenario: Happy path / specified behavior**

- **Given** an exam session is saved with eligible participants
- **When** the session is created
- **Then** email notifications are immediately enqueued for all participants containing: session name, date/time, duration, portal link
- **And** scheduled jobs fire at exactly T−24h and T−1h (±5 minutes tolerance) to send reminder emails
- **And** if a student is added to the session after creation, they receive the creation notification immediately; the T−24h/T−1h reminders apply to all current participants at the time of sending
- **And** each notification attempt is logged in `notification_log` (FR-87)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Session creation (immediate); scheduled job at T−24h and T−1h
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the session window, participant scope, or intervention value is exactly at an allowed limit
- **When** Session creation (immediate); scheduled job at T−24h and T−1h
- **Then** the system applies the configured rule consistently and records any intervention with actor, reason, and timestamp
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Session creation (immediate); scheduled job at T−24h and T−1h
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-039 — provide Exam Coordinators with a real-time dashboard showing per-student status during an activ

**Scenario: Happy path / specified behavior**

- **Given** an Exam Coordinator opens the live monitor dashboard for an active session
- **When** the dashboard loads and during its lifetime
- **Then** the system establishes a WebSocket (or SSE fallback) connection and pushes real-time events: `student.started`, `student.progress`, `student.disconnected`, `student.reconnected`, `student.submitted`, `student.violation`
- **And** the dashboard table has one row per enrolled student showing: name, status (Not Started / In Progress [current skill – part] / Disconnected [N min ago] / Submitted), violation count badge, time remaining
- **And** Disconnected students are highlighted in amber; students terminated by violation threshold are highlighted in red
- **And** the table updates without page reload; the coordinator does not need to manually refresh

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Coordinator opens the live monitor dashboard
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the session window, participant scope, or intervention value is exactly at an allowed limit
- **When** Coordinator opens the live monitor dashboard
- **Then** the system applies the configured rule consistently and records any intervention with actor, reason, and timestamp
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Coordinator opens the live monitor dashboard
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-040 — allow Exam Coordinators to extend the remaining time for a specific student's attempt

**Scenario: Happy path / specified behavior**

- **Given** an Exam Coordinator identifies a student needing extra time
- **When** the Coordinator enters extension_minutes and a non-empty reason and confirms
- **Then** the server updates the student's `part_end_time` (and `session_end_time` if within the current part) by adding the extension
- **And** the student's client reflects the updated `time_remaining` on the next sync (≤ 10 seconds)
- **And** the event is logged in `exam_events`: `{coordinator_id, student_id, session_id, extension_minutes, reason, timestamp}`
- **And** submitting an extension form with an empty reason field is rejected: `"Reason is required"`

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Coordinator submits a time extension form for a student
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the session window, participant scope, or intervention value is exactly at an allowed limit
- **When** Coordinator submits a time extension form for a student
- **Then** the system applies the configured rule consistently and records any intervention with actor, reason, and timestamp
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Coordinator submits a time extension form for a student
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-041 — allow Exam Coordinators to force-submit a student's exam attempt, finalizing it with all curren

**Scenario: Happy path / specified behavior**

- **Given** an Exam Coordinator confirms force-submit for student S with a non-empty reason
- **When** the force-submit is processed
- **Then** the server sets `exam_attempt.status = submitted`, `submitted_at = now()`, `force_submitted_by = coordinator_id`, `force_submit_reason = reason`
- **And** the scoring pipeline is triggered identically to FR-26
- **And** if the student is mid-Speaking recording, the system cuts the recording at the current position and uploads the partial audio flagged as `partial_recording = true` (FR-109)
- **And** submitting without a reason returns HTTP 422: `"reason is required for force submit"`

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Coordinator confirms force-submit for a student with a reason
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the session window, participant scope, or intervention value is exactly at an allowed limit
- **When** Coordinator confirms force-submit for a student with a reason
- **Then** the system applies the configured rule consistently and records any intervention with actor, reason, and timestamp
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Coordinator confirms force-submit for a student with a reason
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-042 — allow Exam Coordinators to close an exam session before its scheduled end

**Scenario: Happy path / specified behavior**

- **Given** a Coordinator confirms close session with grace_period = 5 minutes and a reason
- **When** the close is initiated
- **Then** `session.status` is set to `closing`; all enrolled students who are `in_progress` receive an in-exam banner: "Session closing in 5 minutes — please submit your exam now"
- **And** after the grace period, all remaining `in_progress` attempts are force-submitted (FR-41 logic) with `force_submit_reason = "Session closed early by coordinator"`
- **And** `session.status` is set to `closed`
- **And** students who had already submitted are unaffected

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Coordinator confirms "Close Session Early" with a reason and grace period
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the session window, participant scope, or intervention value is exactly at an allowed limit
- **When** Coordinator confirms "Close Session Early" with a reason and grace period
- **Then** the system applies the configured rule consistently and records any intervention with actor, reason, and timestamp
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Coordinator confirms "Close Session Early" with a reason and grace period
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-043 — allow Teachers and Exam Coordinators to approve retake requests for students, creating a new ex

**Scenario: Happy path / specified behavior**

- **Given** a Coordinator approves a retake for student S on session X
- **When** the approval is processed
- **Then** a new `exam_attempt` record is created for student S on session X with `status = not_started` and `attempt_number = 2`
- **And** the retake is logged: `{requester_id, approver_id, attempt_number, reason, timestamp}`
- **And** the original attempt (attempt_number = 1) is preserved and unchanged
- **And** the student can now enter the session again (subject to the session window being open)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Teacher or Coordinator approves a retake for a student
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the session window, participant scope, or intervention value is exactly at an allowed limit
- **When** Teacher or Coordinator approves a retake for a student
- **Then** the system applies the configured rule consistently and records any intervention with actor, reason, and timestamp
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Teacher or Coordinator approves a retake for a student
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-044 — allow Tenant Admins to create courses with a name, description, start date, and end date

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin opens the course creation form
- **When** the form is submitted with name, description, start_date, and end_date
- **Then** a course record is created with: `status = scheduled` (before start_date), `active` (between dates), or `ended` (after end_date)
- **And** exam sessions can only be created within an `active` course
- **And** students whose course enrollment has ended cannot start new attempts within that course; attempting to enter a session in an ended course returns HTTP 403: `"This course has ended"`
- **And** `end_date` must be after `start_date`; validation returns HTTP 422 otherwise

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Tenant Admin submits the course creation form
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** seat usage equals the licensed seat count
- **When** Tenant Admin submits the course creation form
- **Then** the system blocks any operation that would consume another seat while preserving existing enrollments and history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Tenant Admin submits the course creation form
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-045 — allow Tenant Admins to create named groups (classes) within a course and assign Teachers to spe

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin creates group "Class 10A" in course C and assigns Teacher T
- **When** Teacher T logs in
- **Then** Teacher T's student list, scoring queue, and analytics views show only students enrolled in "Class 10A"
- **And** Teacher T cannot view or manage students in groups not assigned to them
- **And** Tenant Admin and Viewer roles can see all groups across all courses in their tenant

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Tenant Admin creates a group and assigns a Teacher
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** seat usage equals the licensed seat count
- **When** Tenant Admin creates a group and assigns a Teacher
- **Then** the system blocks any operation that would consume another seat while preserving existing enrollments and history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Tenant Admin creates a group and assigns a Teacher
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-046 — allow Tenant Admins and Teachers to add individual students to a course group by email

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin enters an email address on the enrollment form for a class
- **When** the enrollment is submitted
- **Then** if the email matches an existing student in the tenant: the student is enrolled in the class (if not already enrolled)
- **And** if the email does not exist: the system creates a new student account with an auto-generated password and enrolls it; an account-created email is sent to the student (FR-83)
- **And** if `seats_used ≥ seat_count`: the enrollment is rejected with `"Seat quota reached. Please contact your account manager to upgrade your license."` and no account is created

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Admin or Teacher submits the single-student enrollment form
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** seat usage equals the licensed seat count
- **When** Admin or Teacher submits the single-student enrollment form
- **Then** the system blocks any operation that would consume another seat while preserving existing enrollments and history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Admin or Teacher submits the single-student enrollment form
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-047 — allow Tenant Admins to bulk-import student rosters from CSV or Excel files, auto-creating accou

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin uploads a CSV file with columns: `full_name`, `email`
- **When** the system parses the file
- **Then** a preview table is shown with per-row validation: required fields present, email format valid, no duplicate email within the tenant
- **And** the Tenant Admin confirms import; the system creates accounts for all valid new-email rows and enrolls them; duplicate emails in the tenant are enrolled without creating new accounts
- **And** a summary is shown: "N accounts created, M already existed (enrolled), K rows skipped (with reasons)"
- **And** if the import would exceed `seat_count`, the system processes only as many rows as seats remain, reports which rows were skipped due to quota, and stops when quota is reached

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Tenant Admin uploads a file and confirms the import
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** seat usage equals the licensed seat count
- **When** Tenant Admin uploads a file and confirms the import
- **Then** the system blocks any operation that would consume another seat while preserving existing enrollments and history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Tenant Admin uploads a file and confirms the import
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-048 — generate a downloadable Excel credential file immediately after bulk student creation

**Scenario: Happy path / specified behavior**

- **Given** a bulk import has just completed
- **When** the Tenant Admin clicks Export Credentials
- **Then** the system generates an Excel file with columns: STT, Họ và tên, Email/Username, Mật khẩu, Lớp
- **And** plaintext passwords are included only for accounts created within the last 24 hours
- **And** accounts older than 24 hours show "••••••••" in the password column
- **And** before the download starts, a warning is shown: "Save this file securely. Passwords will not be shown again after 24 hours."
- **And** the download begins immediately without a separate confirmation dialog

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Tenant Admin clicks "Export Credentials"
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** seat usage equals the licensed seat count
- **When** Tenant Admin clicks "Export Credentials"
- **Then** the system blocks any operation that would consume another seat while preserving existing enrollments and history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Tenant Admin clicks "Export Credentials"
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-049 — display a student profile page accessible to authorized staff, showing personal information, en

**Scenario: Happy path / specified behavior**

- **Given** a Teacher clicks on student S who is in one of their assigned classes
- **When** the student profile page loads
- **Then** the system displays: student name, email, account status (active/suspended), enrolled classes, list of exam attempts (date, session name, status, bands per skill), and a band progression summary
- **And** a Teacher cannot access a profile for a student not in their assigned classes (HTTP 403)
- **And** Tenant Admin can view any student profile within the tenant

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Staff clicks a student's name anywhere in the portal
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** seat usage equals the licensed seat count
- **When** Staff clicks a student's name anywhere in the portal
- **Then** the system blocks any operation that would consume another seat while preserving existing enrollments and history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Staff clicks a student's name anywhere in the portal
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-050 — allow Tenant Admins and Teachers to unenroll a student from a course group

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin confirms unenrollment of student S from class C
- **When** the unenrollment is processed
- **Then** the student is removed from class C enrollment; the student can no longer access exam sessions in that course
- **And** `seats_used` decrements by 1 immediately
- **And** historical exam attempt records for student S in course C are preserved and remain visible to Tenant Admins and Teachers
- **And** if the student is currently `in_progress` on an active exam in that course, the unenrollment is blocked with: "Cannot unenroll a student with an active exam attempt. Please wait until the exam is complete."

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Admin or Teacher confirms the unenroll action
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** seat usage equals the licensed seat count
- **When** Admin or Teacher confirms the unenroll action
- **Then** the system blocks any operation that would consume another seat while preserving existing enrollments and history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Admin or Teacher confirms the unenroll action
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-051 — track real-time seat usage per tenant against the license quota and reject new enrollments

**Scenario: Happy path / specified behavior**

- **Given** a tenant has `seat_count = 100` and `seats_used = 100`
- **When** a Tenant Admin attempts to enroll a new student
- **Then** the system rejects the enrollment with HTTP 409: `"Seat quota reached (100 of 100 seats used). Please contact your account manager to upgrade your license."`
- **And** no account is created and no enrollment record is written
- **And** `seats_used` is decremented atomically on unenrollment (FR-50); the next enrollment attempt immediately succeeds if a seat was freed
- **And** the Tenant Admin dashboard always shows the current `seats_used / seat_count` in real time

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Any enrollment action (FR-46, FR-47)
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** seat usage equals the licensed seat count
- **When** Any enrollment action (FR-46, FR-47)
- **Then** the system blocks any operation that would consume another seat while preserving existing enrollments and history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Any enrollment action (FR-46, FR-47)
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-052 — display a chronological list of all exam attempts for a logged-in student, showing per-attempt 

**Scenario: Happy path / specified behavior**

- **Given** a student has 3 submitted exam attempts
- **When** the student opens the results section
- **Then** the system displays all attempts sorted by `submitted_at` descending with columns: Date, Exam Session, Reading Band, Listening Band, Writing Band, Speaking Band
- **And** skills pending teacher review show "Pending" in the band column
- **And** clicking a row opens the attempt detail (FR-54)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student navigates to their results section
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Student navigates to their results section
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student navigates to their results section
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-053 — display a band progression line chart for students with ≥ 2 scored attempts, showing one line p

**Scenario: Happy path / specified behavior**

- **Given** a student has 4 scored attempts across 3 months
- **When** the progression chart renders
- **Then** the chart shows 4 lines (Reading, Listening, Writing, Speaking) with x-axis = attempt date, y-axis = band (A1 to C on ordinal scale)
- **And** hovering over a data point shows the exact band and date
- **And** if a skill has only 1 data point, it renders as a single point (not a line)
- **And** attempts where Writing or Speaking are still pending are excluded from those skills' lines

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student opens the results section
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Student opens the results section
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student opens the results section
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-054 — display a per-attempt skill breakdown showing per-part scores for each skill

**Scenario: Happy path / specified behavior**

- **Given** a student opens an attempt detail
- **When** the skill breakdown section loads
- **Then** for Reading and Listening: each part shows correct count (e.g., "Part A: 4/5"), total raw score, and band
- **And** for Writing: word count per part, and band (displayed after teacher confirms)
- **And** for Speaking: per-part band (after teacher confirms)
- **And** parts with the lowest scores are visually indicated (e.g., highlighted row or lowest-score badge)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student or Teacher opens an attempt detail screen
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Student or Teacher opens an attempt detail screen
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student or Teacher opens an attempt detail screen
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-055 — compute and display a strengths and weaknesses summary for students with ≥ 2 scored attempts, i

**Scenario: Happy path / specified behavior**

- **Given** a student has 3 scored attempts
- **When** the strengths/weaknesses panel renders
- **Then** the system computes average score per part across all scored attempts
- **And** parts with average below the configured threshold are listed as "Areas to improve"
- **And** parts consistently above threshold are listed as "Strengths"
- **And** the summary updates automatically when new scored results become available

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student views their results section
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Student views their results section
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student views their results section
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-056 — display the teacher-confirmed feedback narrative for Writing and Speaking to the student from t

**Scenario: Happy path / specified behavior**

- **Given** a Teacher has confirmed scores for Writing Part C
- **When** the student opens that attempt detail
- **Then** the feedback narrative for Writing Part C is displayed: rubric criterion scores, overall band, narrative text
- **And** Speaking parts where the Teacher has not yet confirmed show "Results pending teacher review"
- **And** the feedback language is displayed as written (no translation applied)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student opens the attempt detail
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Student opens the attempt detail
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Student opens the attempt detail
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-057 — display a class-level analytics dashboard for Teachers showing average band per skill and band 

**Scenario: Happy path / specified behavior**

- **Given** a Teacher selects class "10A" and session "Mock Exam 1"
- **When** the class analytics page loads
- **Then** the system displays: average band per skill (label + numeric average), number of students who completed vs. not started, and band distribution count per skill (how many students at each band level)
- **And** data is scoped to the selected class and session
- **And** the Teacher can navigate between sessions to compare results

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Teacher opens class analytics and selects a session
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Teacher opens class analytics and selects a session
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Teacher opens class analytics and selects a session
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-058 — display a ranked student list within a class for a selected exam session, ordered by total scor

**Scenario: Happy path / specified behavior**

- **Given** a Teacher views class analytics for a session with 30 scored students
- **When** the ranking table renders
- **Then** the system displays: Rank, Student Name, Reading Band, Listening Band, Writing Band, Speaking Band, Total Score; sorted by total score descending by default
- **And** the Teacher can click any column header to re-sort
- **And** students with pending Writing/Speaking scores are ranked by available skills only, with "Pending" in unscored columns

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Teacher requests the student ranking table
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Teacher requests the student ranking table
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Teacher requests the student ranking table
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-059 — highlight students whose band in any skill falls below the configured threshold for a session, 

**Scenario: Happy path / specified behavior**

- **Given** the weak student threshold is configured at B1
- **When** the weak student alerts panel loads for a session
- **Then** the system lists all students with at least one skill band below B1: Student Name, skill(s) with low band, band value
- **And** the list can be exported to Excel
- **And** the threshold is configurable per tenant by Tenant Admin (default: B1)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Teacher or Tenant Admin views class analytics
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Teacher or Tenant Admin views class analytics
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Teacher or Tenant Admin views class analytics
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-060 — compute and display the change in average band per skill between the first and most recent scor

**Scenario: Happy path / specified behavior**

- **Given** a class has scored sessions in January and March
- **When** the before/after comparison renders
- **Then** the system shows: `avg_band_first_session` and `avg_band_latest_session` per skill, and a delta with indicator: ↑ (improved), ↓ (regressed), = (no change)
- **And** delta is expressed as number of band levels changed (e.g., "+1 band: A2 → B1")
- **And** if Writing or Speaking are still partially pending, only confirmed scores are included in the averages

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Teacher views the before/after comparison panel
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Teacher views the before/after comparison panel
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Teacher views the before/after comparison panel
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-061 — display a score distribution histogram for a selected class, session, and skill, with bars per 

**Scenario: Happy path / specified behavior**

- **Given** a Teacher selects class "10A", session "Mock Exam 1", skill "Reading"
- **When** the histogram renders
- **Then** a bar chart appears with x-axis = band level (A1, A2, B1, B2, C) and y-axis = number of students per band
- **And** bars are color-coded (e.g., A1 = red, A2 = orange, B1 = yellow, B2 = light green, C = green)
- **And** the chart can be downloaded as PNG

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Teacher selects class, session, and skill; histogram panel renders
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Teacher selects class, session, and skill; histogram panel renders
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Teacher selects class, session, and skill; histogram panel renders
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-062 — provide Tenant Admins and Viewers with a KPI overview dashboard showing total active courses, e

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin opens the dashboard
- **When** the dashboard loads
- **Then** the system displays KPI cards: total active courses, total enrolled students (vs. `seat_count`), total exam sessions this month, overall completion rate (submitted / total eligible), license status with color indicator, upcoming sessions in the next 7 days
- **And** the dashboard loads within 3 seconds (NFR performance target)
- **And** Viewers see identical data with no create/edit controls

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** User navigates to the dashboard
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** User navigates to the dashboard
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** User navigates to the dashboard
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-063 — display school-wide band distribution charts showing the proportion of students at each APTIS b

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin opens the analytics section
- **When** the band distribution chart renders
- **Then** the system renders a chart per skill showing proportion of students at each band (A1–C) based on each student's most recent scored attempt for that skill
- **And** charts are filterable by course and time period
- **And** clicking a band segment drills down to show which classes/courses contribute to that band group

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Tenant Admin or Viewer opens the analytics section
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Tenant Admin or Viewer opens the analytics section
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Tenant Admin or Viewer opens the analytics section
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-064 — display a summary table of all courses within the tenant showing enrollment count, session coun

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin opens the courses analytics section
- **When** the table loads
- **Then** the system displays per course: name, enrollment count, exam sessions count, average completion rate, average band per skill
- **And** the table is sortable by any column
- **And** clicking a course row opens a course-level detail view

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Tenant Admin opens the courses analytics section
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Tenant Admin opens the courses analytics section
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Tenant Admin opens the courses analytics section
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-065 — display the current seat usage as a color-coded progress bar on the Tenant Admin dashboard, wit

**Scenario: Happy path / specified behavior**

- **Given** a tenant has `seat_count = 200` and `seats_used = 185`
- **When** the license usage section renders
- **Then** the progress bar shows 92.5% and is colored red
- **And** below the bar: exact count label ("185 of 200 seats used") and the license expiry date
- **And** a "Contact Sales" link is visible when ≥ 90% used or expiry is within 30 days
- **And** the progress bar updates in real time on enrollment/unenrollment without page reload

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Tenant Admin views the dashboard
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Tenant Admin views the dashboard
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Tenant Admin views the dashboard
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-066 — allow Tenant Admins, Viewers, and Teachers (scoped to their classes) to export analytics report

**Scenario: Happy path / specified behavior**

- **Given** a Tenant Admin is viewing a class report with 300 student rows (paginated to 50 per page)
- **When** the Tenant Admin clicks Export Excel
- **Then** the system generates an Excel file containing all 300 rows (not just the displayed 50)
- **And** the file includes: report title, date generated, tenant name, scope (class/course/school), and all displayed columns
- **And** the file downloads immediately to the browser
- **And** Teacher exports are scoped to their assigned classes only; cross-class data is excluded
- **And** [Conditional] PDF export of the same data is available if enabled for v1

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** User clicks Export
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** User clicks Export
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** User clicks Export
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-067 — compute and display per-question item analysis statistics (correct_rate, wrong_rate per distrac

**Scenario: Happy path / specified behavior**

- **Given** a Content Manager selects question Q with 50 responses
- **When** the statistics panel loads
- **Then** the system displays: `correct_rate (%)`, `wrong_rate per distractor` (for MCQ questions), `skip_rate (%)`, `avg_time_spent (seconds)`
- **And** statistics are aggregated from all tenants globally (cross-tenant aggregate; no individual tenant data exposed)
- **And** statistics are recomputed nightly from the `exam_answers` table

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager opens the item analysis view and selects a question
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Content Manager opens the item analysis view and selects a question
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager opens the item analysis view and selects a question
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-068 — compute the difficulty index (p-value) per question and automatically flag questions with p-val

**Scenario: Happy path / specified behavior**

- **Given** question Q has 50 responses, of which 12 are correct
- **When** the item analysis page loads
- **Then** the system computes and displays `p_value = 12/50 = 0.24`, shown as "24%"
- **And** the question is flagged "Too Hard" (p < 0.3)
- **And** questions with p < 10 responses display: "Insufficient data for analysis (N = {count})" with no flag applied

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Nightly item analysis job; Content Manager opens item analysis
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Nightly item analysis job; Content Manager opens item analysis
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Nightly item analysis job; Content Manager opens item analysis
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-069 — compute the point-biserial discrimination index per question and flag questions with index < 0

**Scenario: Happy path / specified behavior**

- **Given** question Q has a computed point-biserial correlation of −0.05
- **When** the item analysis page loads
- **Then** the system displays `discrimination_index = -0.05` and flags the question as "Review Required — answers correctly to this question correlate with lower overall score"
- **And** questions with index between 0 and 0.19 are flagged "Poor Discriminator"
- **And** questions with index ≥ 0.2 show no flag

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Nightly item analysis job
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Nightly item analysis job
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Nightly item analysis job
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-070 — provide Content Managers with a consolidated flagged questions list showing all questions with 

**Scenario: Happy path / specified behavior**

- **Given** 12 questions are flagged across different skills
- **When** the Content Manager opens Flagged Questions
- **Then** all 12 flagged questions are listed with columns: Question ID/preview, Skill, Part, p-value, Discrimination Index, Flag Types
- **And** the list is filterable by skill, part, and flag type
- **And** clicking a question opens the question editor (FR-09) and item analysis panel (FR-67) side by side
- **And** a Content Manager can mark a flag as "acknowledged" to track which questions have been reviewed

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Content Manager opens the Flagged Questions section
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the selected scope has zero or one qualifying scored attempt
- **When** Content Manager opens the Flagged Questions section
- **Then** the system renders a valid empty or insufficient-data state without fabricating statistics
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Content Manager opens the Flagged Questions section
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-071 — allow Super Admins to create, activate, suspend, reactivate, and decommission tenant accounts

**Scenario: Happy path / specified behavior**

- **Given** a Super Admin suspends tenant "hanoi-english"
- **When** the status change is confirmed
- **Then** `tenant.status = suspended`; all users at `hanoi-english.aptis-lms.vn` receive HTTP 403 on protected endpoints with message: "Your organization's account has been suspended. Please contact your account manager."
- **And** `tenant.status` changes are logged in `audit_log`: `{actor_id, action, tenant_id, old_status, new_status, timestamp}`
- **And** decommissioned tenants have data preserved but all logins blocked; `status = decommissioned` cannot be reverted by tenant-side users
- **And** the typed-confirmation dialog (UI-01) is required for Suspend and Decommission: "Type the tenant slug to confirm"

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Super Admin changes a tenant's status
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a tenant is suspended, decommissioned, or has no active license
- **When** Super Admin changes a tenant's status
- **Then** the system enforces the defined access mode and preserves immutable lifecycle history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Super Admin changes a tenant's status
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-072 — allow Super Admins to configure per-tenant settings including timezone, display name, and optio

**Scenario: Happy path / specified behavior**

- **Given** a Super Admin sets tenant display name to "Trung tâm Anh ngữ Hà Nội" and timezone to "Asia/Ho_Chi_Minh"
- **When** the configuration is saved
- **Then** the Tenant Portal header immediately shows the updated display name and logo (if provided)
- **And** all datetime displays within the tenant portal use "Asia/Ho_Chi_Minh" timezone
- **And** changes take effect on the tenant portal within 30 seconds without requiring a page reload or re-login by tenant users

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Super Admin saves tenant configuration
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a tenant is suspended, decommissioned, or has no active license
- **When** Super Admin saves tenant configuration
- **Then** the system enforces the defined access mode and preserves immutable lifecycle history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Super Admin saves tenant configuration
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-073 — allow Sales Team members to create seat-based licenses for tenants and to extend expiry dates o

**Scenario: Happy path / specified behavior**

- **Given** a Sales Team member creates a license for tenant T with `seat_count = 150` and `expiry_date = 2027-06-30`
- **When** the license is saved
- **Then** a license record is created: `{tenant_id, seat_count, expiry_date, created_by, created_at}`
- **And** the tenant's effective quota becomes 150 seats immediately
- **And** if the tenant previously had no active license: `tenant.status` transitions from `pending` to `active`
- **And** all license changes (create, extend, adjust) are appended to `license_history` (FR-81)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Sales Team member saves a license creation or modification
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a tenant is suspended, decommissioned, or has no active license
- **When** Sales Team member saves a license creation or modification
- **Then** the system enforces the defined access mode and preserves immutable lifecycle history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Sales Team member saves a license creation or modification
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-074 — send automated email alerts to Tenant Admins and Sales Team

**Scenario: Happy path / specified behavior**

- **Given** tenant T has `seat_count = 100` and `seats_used` increases to 80
- **When** the daily alert job runs
- **Then** an email alert is sent to the Tenant Admin: "Your organization is using 80% of its licensed seats (80/100). Contact your account manager to add more seats."
- **And** when `seats_used` reaches 90: email sent to Tenant Admin AND Sales Team
- **And** when `days_until_expiry ≤ 30`: email sent to Tenant Admin and Sales Team; when `days_until_expiry ≤ 7`: another alert sent
- **And** each threshold alert is sent exactly once per threshold crossing; if `seats_used` fluctuates around 80%, the 80% alert is not re-sent until it drops below 75% and crosses 80% again

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Daily scheduled job checks all tenant thresholds
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a tenant is suspended, decommissioned, or has no active license
- **When** Daily scheduled job checks all tenant thresholds
- **Then** the system enforces the defined access mode and preserves immutable lifecycle history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Daily scheduled job checks all tenant thresholds
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-075 — allow Super Admins and Support Staff to view usage statistics per tenant including seats used, 

**Scenario: Happy path / specified behavior**

- **Given** a Support Staff opens the tenant detail for "hanoi-english"
- **When** the page loads
- **Then** the system displays: tenant name, slug, status, license (seats, expiry), `seats_used / seat_count`, total exam sessions (all-time and current month), total student attempts (all-time), last activity (most recent login from any user in the tenant)
- **And** all data is read-only for Support Staff; no create/edit/delete controls are visible
- **And** Super Admins see the same data plus administrative action buttons (suspend, configure, etc.)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** User opens a tenant detail page
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a tenant is suspended, decommissioned, or has no active license
- **When** User opens a tenant detail page
- **Then** the system enforces the defined access mode and preserves immutable lifecycle history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** User opens a tenant detail page
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-076 — allow Support Staff to enter a read-only impersonation view of any tenant portal

**Scenario: Happy path / specified behavior**

- **Given** a Support Staff clicks "View as Tenant Admin" for tenant T
- **When** the impersonation view opens
- **Then** an `impersonation_log` entry is created with: `support_staff_id, tenant_id, start_time`
- **And** the Support Staff sees the Tenant Portal as a Tenant Admin would; all write controls (buttons, forms) are hidden or disabled with tooltip "Read-only view"
- **And** a persistent orange banner reads: "Viewing [Tenant Name] — Read Only | Exit"
- **And** clicking Exit closes the impersonation view and logs `end_time`
- **And** impersonation does not create a real Tenant Admin JWT token; all requests carry an impersonation context flag

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Support Staff clicks "View as Tenant Admin" on a tenant detail page
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a tenant is suspended, decommissioned, or has no active license
- **When** Support Staff clicks "View as Tenant Admin" on a tenant detail page
- **Then** the system enforces the defined access mode and preserves immutable lifecycle history
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Support Staff clicks "View as Tenant Admin" on a tenant detail page
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-077 — display a sortable, searchable customer list for Sales Team members showing tenant name, contac

**Scenario: Happy path / specified behavior**

- **Given** a Sales Team member opens the Sales Portal
- **When** the customer list loads
- **Then** the system displays all tenants in a table: Name, Contact Email, License Status (color-coded), Seats Used/Total, Expiry Date
- **And** color coding: green = active with > 30 days remaining, yellow = expiring within 30 days, red = expired
- **And** the list is sortable by any column and searchable by tenant name or contact email
- **And** clicking a tenant row opens the tenant detail with license history and action buttons

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Sales Team member opens the Sales Portal
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a requested seat reduction equals or falls below current usage
- **When** Sales Team member opens the Sales Portal
- **Then** the system accepts equality, rejects values below usage, and records successful changes immutably
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Sales Team member opens the Sales Portal
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-078 — allow Sales Team members to create a new license for a tenant with a seat count and expiry date

**Scenario: Happy path / specified behavior**

- **Given** a Sales Team member selects tenant T and enters `seat_count = 200`, `expiry_date = 2027-12-31`
- **When** the form is submitted
- **Then** the license is created and `tenant.effective_seat_count = 200` immediately
- **And** if the tenant had no prior active license, the tenant transitions to `active` status
- **And** an email confirmation is sent to the Tenant Admin (FR-83: "License activated")
- **And** `seat_count < 1` or `expiry_date ≤ today` are rejected with HTTP 422 validation errors

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Sales member submits the create license form
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a requested seat reduction equals or falls below current usage
- **When** Sales member submits the create license form
- **Then** the system accepts equality, rejects values below usage, and records successful changes immutably
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Sales member submits the create license form
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-079 — allow Sales Team members to extend the expiry date of an existing license

**Scenario: Happy path / specified behavior**

- **Given** tenant T has an expired license (status = expired) and a Sales member sets `new_expiry_date = 2027-06-30`
- **When** the renewal is confirmed
- **Then** `license.expiry_date` is updated; `tenant.status` returns to `active`
- **And** the license history shows the previous expiry and the new expiry (FR-81)
- **And** an email confirmation is sent to the Tenant Admin (FR-83: "License renewed")
- **And** `new_expiry_date ≤ today` is rejected with HTTP 422

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Sales member enters a new expiry date and confirms
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a requested seat reduction equals or falls below current usage
- **When** Sales member enters a new expiry date and confirms
- **Then** the system accepts equality, rejects values below usage, and records successful changes immutably
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Sales member enters a new expiry date and confirms
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-080 — allow Sales Team members to increase or decrease the seat count on a tenant's current license

**Scenario: Happy path / specified behavior**

- **Given** tenant T has `seats_used = 95` and a Sales member attempts to set `seat_count = 80`
- **When** the adjustment is submitted
- **Then** the system rejects with HTTP 422: `"Cannot reduce seats below current usage (95 seats in use). Please unenroll students first or set a higher count."`
- **And** if `new_seat_count ≥ seats_used`: `license.seat_count` updates immediately; tenant dashboard reflects the new quota
- **And** the change is appended to license history (FR-81)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Sales member submits a seat count adjustment
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a requested seat reduction equals or falls below current usage
- **When** Sales member submits a seat count adjustment
- **Then** the system accepts equality, rejects values below usage, and records successful changes immutably
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Sales member submits a seat count adjustment
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-081 — maintain an immutable history of all license changes per tenant

**Scenario: Happy path / specified behavior**

- **Given** a license is created and then extended twice
- **When** a Sales Team member or Super Admin opens the tenant's license history
- **Then** the system displays all 3 records in reverse chronological order: license ID, created_by, created_at, seat_count, expiry_date, last_modified_by, last_modified_at, status (active/expired/superseded)
- **And** no delete control is visible for any license record regardless of user role
- **And** each record is expandable to show full audit detail

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** License change event
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a requested seat reduction equals or falls below current usage
- **When** License change event
- **Then** the system accepts equality, rejects values below usage, and records successful changes immutably
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** License change event
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-082 — display a prioritized expiry alert panel on the Sales Portal dashboard listing tenants expiring

**Scenario: Happy path / specified behavior**

- **Given** 5 tenants have licenses expiring in the next 30 days
- **When** the expiry alert panel loads
- **Then** all 5 tenants are listed sorted by `days_until_expiry` ascending
- **And** columns: Tenant Name, Expiry Date, Days Remaining, Seats Used/Total, Contact Email, Renew (button)
- **And** expired tenants (days = 0) appear at the top with red status
- **And** clicking "Renew" opens the renewal form (FR-79) pre-populated for that tenant

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Dashboard load
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** a requested seat reduction equals or falls below current usage
- **When** Dashboard load
- **Then** the system accepts equality, rejects values below usage, and records successful changes immutably
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Dashboard load
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-083 — send email notifications for all defined trigger events using the configured template for each 

**Scenario: Happy path / specified behavior**

- **Given** a student's Reading/Listening results become available
- **When** the scoring job completes (FR-29)
- **Then** an email notification is enqueued for the student with template `RESULT_AVAILABLE`, rendered in the tenant's configured language
- **And** on successful send: `notification_log.delivery_status = sent`
- **And** on failure: retry once after 5 minutes; if second attempt fails: `delivery_status = failed` and alert surfaced to Super Admin monitoring
- **And** the email service provider is called via REST API (SI-02); the provider can be switched via configuration change

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Any of the defined trigger events (see table below)
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the provider rejects delivery or returns a transient error
- **When** the notification job executes
- **Then** the system retries according to policy, records the provider outcome, and does not duplicate a successful notification
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the same trigger is delivered more than once by the event source
- **When** workers process duplicate jobs
- **Then** idempotency prevents duplicate user-visible notification while all processing attempts remain auditable
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-084 — send push notifications to students on Flutter Mobile (iOS/Android) for student-facing trigger 

**Scenario: Happy path / specified behavior**

- **Given** a student has a registered FCM device token and a session is published
- **When** the notification job fires
- **Then** the system sends an FCM notification with title, body, and a deep link to the relevant screen
- **And** if FCM returns a token-not-registered error, the stale token is removed from the database immediately
- **And** push notifications are sent in addition to (not instead of) email notifications
- **Note:** This FR is Conditional — requires Flutter Mobile to be in platform scope (OI-01)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Same student-facing triggers as FR-83
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the provider rejects delivery or returns a transient error
- **When** the notification job executes
- **Then** the system retries according to policy, records the provider outcome, and does not duplicate a successful notification
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the same trigger is delivered more than once by the event source
- **When** workers process duplicate jobs
- **Then** idempotency prevents duplicate user-visible notification while all processing attempts remain auditable
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-085 — allow Super Admins to view and edit email templates for all notification types

**Scenario: Happy path / specified behavior**

- **Given** a Super Admin opens the template for `RESULT_AVAILABLE`
- **When** the Super Admin edits the subject and body and saves
- **Then** a new template version is created; the previous version is preserved for rollback
- **And** variable placeholders (e.g., `{{student_name}}`, `{{session_name}}`, `{{session_date}}`) are highlighted in the editor and previewed with sample data
- **And** both Vietnamese and English versions are editable independently via a language selector
- **And** the template used for each tenant is determined by the tenant's configured language (FR-72)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Super Admin opens the email template manager and edits a template
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the provider rejects delivery or returns a transient error
- **When** the notification job executes
- **Then** the system retries according to policy, records the provider outcome, and does not duplicate a successful notification
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the same trigger is delivered more than once by the event source
- **When** workers process duplicate jobs
- **Then** idempotency prevents duplicate user-visible notification while all processing attempts remain auditable
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-086 — allow Tenant-side users to opt out of non-critical notification types

**Scenario: Happy path / specified behavior**

- **Given** a student opens notification preferences and disables "Exam reminders"
- **When** the T−24h and T−1h notification jobs run for that student
- **Then** the email is not sent to that student (preference respected)
- **And** `score_available`, `account_created`, and `license_expiry` notifications cannot be disabled; the toggle for these types is absent or locked
- **And** preferences are saved per user, not per device

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** User toggles notification preferences in their profile
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the provider rejects delivery or returns a transient error
- **When** the notification job executes
- **Then** the system retries according to policy, records the provider outcome, and does not duplicate a successful notification
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the same trigger is delivered more than once by the event source
- **When** workers process duplicate jobs
- **Then** idempotency prevents duplicate user-visible notification while all processing attempts remain auditable
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-087 — log every notification attempt with recipient, type, trigger, sent timestamp, delivery status, 

**Scenario: Happy path / specified behavior**

- **Given** an email notification is sent and the provider returns a bounce webhook
- **When** the webhook is processed
- **Then** `notification_log.delivery_status = bounced` is recorded; `user.email_bounced = true` is set on the recipient account
- **And** future notification sends to a `email_bounced = true` account are flagged for review before sending
- **And** the notification log record contains: `recipient_id`, `notification_type`, `event_trigger`, `sent_at`, `delivery_status`, `provider_response`
- **And** Super Admins can view failed and bounced notifications in a monitoring view

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Email service API response (success, failure, bounce)
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the provider rejects delivery or returns a transient error
- **When** the notification job executes
- **Then** the system retries according to policy, records the provider outcome, and does not duplicate a successful notification
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the same trigger is delivered more than once by the event source
- **When** workers process duplicate jobs
- **Then** idempotency prevents duplicate user-visible notification while all processing attempts remain auditable
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-088 — provide a publicly accessible trial landing page (no login required) with a platform descriptio

**Scenario: Happy path / specified behavior**

- **Given** an unauthenticated user navigates to the trial URL
- **When** the page loads
- **Then** the system renders: platform description, list of skills and parts available in the trial, estimated duration, disclaimer ("Đây là bài thi thử mô phỏng, không phải kỳ thi APTIS chính thức của British Council"), and a "Bắt đầu thi thử" CTA button
- **And** the page loads within 3 seconds on a 10 Mbps connection
- **And** no login, email entry, or account creation is required to view the page or start the trial

**Scenario: Authorization or validation rejection**

- **Given** the anonymous token is missing, expired, or outside the trial scope
- **When** the guest requests protected or persistent tenant data
- **Then** the system rejects the request and creates no tenant-scoped data
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the anonymous session reaches its expiry or purge boundary
- **When** Unauthenticated user navigates to the public trial URL
- **Then** the system denies further trial access or purges eligible data without deleting consented lead data under a different policy
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Unauthenticated user navigates to the public trial URL
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-089 — provide a limited practice exam for Guest users using a fixed Vendor-configured sample question

**Scenario: Happy path / specified behavior**

- **Given** a Guest clicks "Start Trial"
- **When** the trial exam begins
- **Then** the system creates an anonymous session (FR-08) and loads the configured trial question set
- **And** the trial uses the same interface as FR-20–FR-23 (Reading, Writing, Listening, Speaking as configured in the trial scope)
- **And** all timer, audio, and recording features function identically to the registered exam
- **And** the trial question set is not drawn from any tenant's question bank

**Scenario: Authorization or validation rejection**

- **Given** the anonymous token is missing, expired, or outside the trial scope
- **When** the guest requests protected or persistent tenant data
- **Then** the system rejects the request and creates no tenant-scoped data
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the anonymous session reaches its expiry or purge boundary
- **When** Guest clicks "Start Trial"
- **Then** the system denies further trial access or purges eligible data without deleting consented lead data under a different policy
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Guest clicks "Start Trial"
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-090 — display a simplified result summary to the Guest after trial completion showing estimated bands

**Scenario: Happy path / specified behavior**

- **Given** a Guest completes the trial exam
- **When** the results are computed (auto-score only; no AI scoring for trial unless configured)
- **Then** the results screen displays: estimated band per skill attempted, disclaimer: "Đây là kết quả thi thử mô phỏng — không phải điểm APTIS chính thức", and a prominent CTA: "Muốn triển khai cho trường hoặc trung tâm của bạn? Liên hệ ngay"
- **And** results are displayed only for the current anonymous session; they are not persisted after session expiry (FR-92)

**Scenario: Authorization or validation rejection**

- **Given** the anonymous token is missing, expired, or outside the trial scope
- **When** the guest requests protected or persistent tenant data
- **Then** the system rejects the request and creates no tenant-scoped data
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the anonymous session reaches its expiry or purge boundary
- **When** Trial exam submission
- **Then** the system denies further trial access or purges eligible data without deleting consented lead data under a different policy
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Trial exam submission
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-091 — prompt Guest users to optionally provide contact information after trial results

**Scenario: Happy path / specified behavior**

- **Given** a Guest is viewing trial results
- **When** the optional lead capture prompt is displayed
- **Then** the prompt asks for name and email with an explicit consent checkbox: "Tôi đồng ý được liên hệ lại về dịch vụ APTIS LMS"
- **And** if the Guest provides info and checks consent: a lead record is created (name, email, consent_timestamp, trial_result_summary) and the Sales Team is alerted
- **And** if the Guest declines or closes the prompt without providing info: no data is stored
- **And** the consent checkbox is unchecked by default; pre-checking it is not permitted

**Scenario: Authorization or validation rejection**

- **Given** the anonymous token is missing, expired, or outside the trial scope
- **When** the guest requests protected or persistent tenant data
- **Then** the system rejects the request and creates no tenant-scoped data
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the anonymous session reaches its expiry or purge boundary
- **When** Lead capture prompt renders after result display
- **Then** the system denies further trial access or purges eligible data without deleting consented lead data under a different policy
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Lead capture prompt renders after result display
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-092 — automatically purge all Guest/Trial session data (anonymous session, trial answers, trial resul

**Scenario: Happy path / specified behavior**

- **Given** an anonymous trial session was created at timestamp T and `current_time - T > retention_days`
- **When** the daily purge job runs
- **Then** the system deletes: `anonymous_session`, associated `trial_exam_answers`, `trial_result` records
- **And** lead records captured via FR-91 follow a separate (longer) retention policy defined by Sales
- **And** the purge job logs to `audit_log`: `{job_name, run_at, records_deleted_count}` (no PII in log)
- **And** if the retention period is not yet configured (OI-07 open), the purge job runs but does not delete any records; it logs: "Purge skipped — retention_days not configured"

**Scenario: Authorization or validation rejection**

- **Given** the anonymous token is missing, expired, or outside the trial scope
- **When** the guest requests protected or persistent tenant data
- **Then** the system rejects the request and creates no tenant-scoped data
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the anonymous session reaches its expiry or purge boundary
- **When** Daily scheduled purge job
- **Then** the system denies further trial access or purges eligible data without deleting consented lead data under a different policy
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** a transient dependency failure or concurrent duplicate request occurs
- **When** Daily scheduled purge job
- **Then** the operation is idempotent or safely rejected, no duplicate record is produced, and the user receives an actionable error
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-093 — randomize the order of questions within each exam part for every new attempt using a unique see

**Scenario: Happy path / specified behavior**

- **Given** two students start the same exam session simultaneously
- **When** their attempts are initialized
- **Then** each attempt receives a unique random seed; question order within each part is shuffled using that seed
- **And** the seed is stored in `exam_attempt.shuffle_seed`
- **And** when a student resumes after disconnect (FR-106), the same seed restores the same question order — the student sees identical ordering to before the disconnect
- **And** every student in the same session has an astronomically low probability of receiving the same question order

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Exam attempt initialization
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-094 — randomize the order of MCQ answer options for each attempt using the same shuffle seed as quest

**Scenario: Happy path / specified behavior**

- **Given** a MCQ question has answer options [A, B, C, D]
- **When** it is rendered to a student's attempt
- **Then** the options are shuffled using the attempt seed; the student sees options in a different order (e.g., [C, A, D, B])
- **And** auto-scoring (FR-27) matches by answer content (the text of the correct option), not by the original option letter position
- **And** the shuffled order is consistent for the same student across resume sessions (same seed applied)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** MCQ question is rendered to the student
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-095 — require students to enter fullscreen mode before beginning the exam

**Scenario: Happy path / specified behavior**

- **Given** a student is on the pre-exam screen
- **When** the student clicks "Enter Exam"
- **Then** the system requests fullscreen mode via the platform API; the exam does not start until fullscreen is confirmed active
- **And** if the user denies fullscreen: the "Enter Exam" button is disabled; instructions to enable fullscreen are displayed
- **And** if the student exits fullscreen mid-exam (fullscreenchange event): a violation event is logged with `violation_type = fullscreen_exit` (FR-101); violation threshold logic applies (FR-100)
- **And** on Flutter Desktop: fullscreen is enforced at the OS window level; on Flutter Web: browser fullscreen API is used

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student attempts to enter exam; fullscreen exit detected mid-exam
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-096 — detect

**Scenario: Happy path / specified behavior**

- **Given** a student is in an active exam and switches to another browser tab
- **When** the `visibilitychange` event fires
- **Then** the system logs a `violation_event`: `{attempt_id, violation_type = "tab_switch", timestamp, cumulative_count}`
- **And** `violation_count` is incremented
- **And** if `violation_count = warning_threshold`: an overlay warning is shown to the student (FR-100)
- **And** if `violation_count = terminate_threshold`: the exam is auto-submitted (FR-100)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Browser/app `visibilitychange` event fires with `document.hidden = true`; or window blur event
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-097 — detect OS-level focus loss on Flutter Desktop (Alt-Tab, window minimize) and log it as a `focus

**Scenario: Happy path / specified behavior**

- **Given** a student is in a Flutter Desktop exam and Alt-Tabs to another application
- **When** the Flutter app loses OS-level window focus
- **Then** the system logs a `violation_event`: `{attempt_id, violation_type = "focus_loss", timestamp, cumulative_count}`
- **And** the same `violation_count` used in FR-96 is incremented; threshold logic (FR-100) applies identically
- **And** on Flutter Web: document visibility API detects the equivalent event

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Flutter `AppLifecycleState.inactive` or window focus lost event
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-098 — silently block copy (Ctrl+C), paste (Ctrl+V), and right-click context menu actions within all e

**Scenario: Happy path / specified behavior**

- **Given** a student is in a Reading passage and attempts Ctrl+C
- **When** the keyboard event fires
- **Then** the event is intercepted and cancelled; the clipboard is not modified; no warning is shown to the student
- **And** right-click within exam content areas opens no context menu
- **And** Writing textareas (FR-21) accept normal keyboard typing; Ctrl+V is blocked within Writing inputs
- **And** blocking does not apply to exam navigation buttons, the timer display, or non-content UI areas

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student attempts a blocked action within exam content area
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-099 — intercept browser back button, address bar navigation, F5/Ctrl+R refresh, and window close duri

**Scenario: Happy path / specified behavior**

- **Given** a student is in an active exam
- **When** the student presses the browser back button
- **Then** the back navigation is intercepted; an in-app message displays "You cannot navigate back during the exam"; the exam remains on the current question
- **And** window close / address bar navigation triggers the browser's `beforeunload` dialog: "Are you sure you want to leave? Your progress will be saved."
- **And** if the student confirms leave (or the browser crashes): the resume flow (FR-106) restores all saved answers on next visit
- **And** F5/Ctrl+R refresh is intercepted where the platform supports it; if a reload occurs, resume flow handles recovery

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student attempts a navigation action in the browser
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-100 — enforce configurable violation thresholds per exam session: displaying an in-exam warning

**Scenario: Happy path / specified behavior**

- **Given** an exam session has `warning_threshold = W` and `terminate_threshold = T`
- **When** a student's `violation_count` reaches W
- **Then** an overlay warning is displayed: "Warning: You have left the exam [W] time(s). If you leave [T−W] more time(s), your exam will be automatically submitted."
- **And** when `violation_count` reaches T: the system force-submits the attempt (FR-26 flow), marks `exam_attempt.terminated_by_violation = true`, and notifies the Exam Coordinator via the live monitor (FR-39)
- **And** thresholds cannot be modified after the session has started (first attempt created)
- **And** default values: `warning_threshold` and `terminate_threshold` are configurable system-wide defaults set by Super Admin [TBD: values pending OI-04 resolution]

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Violation count reaches a threshold value
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-101 — maintain an immutable log of all anti-cheat violation events per attempt, storing violation typ

**Scenario: Happy path / specified behavior**

- **Given** a student triggers a tab_switch violation
- **When** the violation is processed
- **Then** a `violation_event` record is created: `{id, exam_attempt_id, violation_type (tab_switch | focus_loss | fullscreen_exit | copy_paste_attempt), timestamp, cumulative_count_at_time}`
- **And** no delete endpoint exists for `violation_events` regardless of the caller's role
- **And** Super Admin purge of violation records follows data retention policy only (batch purge with OI-07 retention rules), not individual record deletion
- **And** violation events are visible to Exam Coordinators in the live monitor (FR-39) and in the post-session integrity report (FR-103)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Violation event detection
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-102 — request OS-level window locking on Flutter Desktop to prevent students from switching to other 

**Scenario: Happy path / specified behavior**

- **Given** a student starts an exam on Flutter Desktop (Windows)
- **When** the exam begins
- **Then** the system requests always-on-top window mode and attempts to disable taskbar access via available Windows APIs
- **And** on macOS: the system requests full-screen mode that disables Mission Control where the API permits
- **And** if OS-level lock cannot be established (insufficient permissions): the system logs `kiosk_mode_unavailable = true` on the attempt and falls back to detection-based violation logging (FR-96, FR-97)
- **And** the student is shown a notice before the exam if kiosk mode failed to activate: "Kiosk mode could not be enabled. Your exam activity will still be monitored."
- **Note:** This FR is Conditional — requires Flutter Desktop to be in platform scope (OI-01)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Exam begins (FR-18 completes)
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-103 — generate a per-session integrity report accessible to Exam Coordinators and Tenant Admins after

**Scenario: Happy path / specified behavior**

- **Given** an exam session is closed with 30 students
- **When** a Coordinator opens the session integrity report
- **Then** the system displays a table: Student Name, Total Violations, Tab Switch Count, Focus Loss Count, Fullscreen Exit Count, Outcome (No violations / Warning level / Terminated by system)
- **And** students auto-terminated by violation threshold are visually highlighted in red
- **And** the report is exportable to Excel; all rows are included regardless of table pagination
- **And** the report is available immediately after session close with no additional computation step required

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Coordinator or Tenant Admin opens the session integrity report
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** the cumulative violation count reaches exactly the warning or termination threshold
- **When** the violation is persisted
- **Then** the system performs the corresponding warning or submission action once and keeps the event immutable
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the client refreshes or loses focus during an active attempt
- **When** the exam reconnects
- **Then** the attempt resumes deterministically, applicable violations are logged once, and the shuffle order remains unchanged
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-104 — track exam part timers exclusively on the server

**Scenario: Happy path / specified behavior**

- **Given** a student is in Reading Part C with 8 minutes of part_duration
- **When** the client polls for `time_remaining`
- **Then** the server returns: `part_duration_seconds - (current_server_time - part_start_time)` in seconds
- **And** the client renders this value; if client clock shows a different value, the server value overrides
- **And** when `time_remaining ≤ 0` on the server: the server closes the part (FR-19) and rejects further answer submissions with HTTP 409
- **And** client manipulation of the displayed timer (e.g., via browser devtools) does not affect the server-side computation

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Part start; client sync poll every 10 seconds
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** connectivity is lost immediately before or after a client write acknowledgement
- **When** the client reconnects and reconciles state
- **Then** the server-authoritative state wins, acknowledged data is retained, and unacknowledged data is retried without overwriting newer data
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the browser or app crashes while an answer or Speaking upload is in flight
- **When** the student reopens the client within the exam window
- **Then** the system restores acknowledged answers and authoritative time, then resumes or flags pending media for explicit review
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-105 — persist every student answer to the server immediately upon entry

**Scenario: Happy path / specified behavior**

- **Given** a student selects a MCQ radio button in Reading Part A
- **When** the selection event fires
- **Then** the client immediately sends `PATCH /api/v1/exam/attempts/{attempt_id}/answers` with `{question_id, answer_value}`
- **And** the server updates `exam_state` for that question; returns HTTP 200 on success
- **And** on network failure: the client retries up to 3 times (delays: 1s, 2s, 4s); answers are held in client memory during retries
- **And** a visual indicator shows "Saved" (checkmark) on success or "Saving…" during retry
- **And** the exam submission (FR-26) is a finalization call; it does not transfer data not yet persisted, it only changes `attempt.status`

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student selects an MCQ option; student pauses typing in a text field (1-second debounce)
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** connectivity is lost immediately before or after a client write acknowledgement
- **When** the client reconnects and reconciles state
- **Then** the server-authoritative state wins, acknowledged data is retained, and unacknowledged data is retried without overwriting newer data
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the browser or app crashes while an answer or Speaking upload is in flight
- **When** the student reopens the client within the exam window
- **Then** the system restores acknowledged answers and authoritative time, then resumes or flags pending media for explicit review
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-106 — allow a student who disconnected during an exam to resume from exactly the last saved state, in

**Scenario: Happy path / specified behavior**

- **Given** a student disconnected during Reading Part C with 12 answers saved
- **When** the student reopens the app and logs in
- **Then** the system detects the `in_progress` attempt and shows: "You have an active exam. Resume from where you left off?" with a Resume button
- **And** clicking Resume: the client fetches `exam_state` (all 12 saved answers), current part, current question index, and `time_remaining` from the server
- **And** the exam resumes displaying the student's saved answers and the correct remaining time (time that elapsed during disconnect is counted by the server)
- **And** if the exam session window expired during the disconnect: the attempt is auto-submitted with all saved answers and `force_submitted_on_session_close = true`

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student opens the exam app and logs in after disconnection
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** connectivity is lost immediately before or after a client write acknowledgement
- **When** the client reconnects and reconciles state
- **Then** the server-authoritative state wins, acknowledged data is retained, and unacknowledged data is retried without overwriting newer data
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the browser or app crashes while an answer or Speaking upload is in flight
- **When** the student reopens the client within the exam window
- **Then** the system restores acknowledged answers and authoritative time, then resumes or flags pending media for explicit review
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-107 — detect network connectivity loss during an exam and display a persistent non-blocking indicator

**Scenario: Happy path / specified behavior**

- **Given** a student loses network connectivity during Writing Part B
- **When** the network goes offline
- **Then** the system displays a persistent banner: "Connection lost — your progress is being saved locally. Reconnecting…" with a spinner
- **And** the student can continue typing in the Writing textarea; keystrokes are buffered in client memory
- **And** when the network is restored: all buffered answers are flushed to the server (FR-105 retry flow); the offline banner is replaced with a brief "Connected" confirmation
- **And** if the offline duration exceeds 5 minutes: a more prominent warning is shown: "You have been offline for 5 minutes. Please notify your proctor."

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Network connectivity lost event
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** connectivity is lost immediately before or after a client write acknowledgement
- **When** the client reconnects and reconciles state
- **Then** the server-authoritative state wins, acknowledged data is retained, and unacknowledged data is retried without overwriting newer data
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the browser or app crashes while an answer or Speaking upload is in flight
- **When** the student reopens the client within the exam window
- **Then** the system restores acknowledged answers and authoritative time, then resumes or flags pending media for explicit review
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-108 — record Speaking audio into a local buffer and upload to Cloud Storage during or immediately aft

**Scenario: Happy path / specified behavior**

- **Given** a student is recording Speaking Part B
- **When** the recording is in progress
- **Then** audio data is written to the local buffer (IndexedDB for Flutter Web; platform file system for Flutter Desktop) in real time
- **And** the system attempts progressive chunk upload to Cloud Storage during recording; remaining buffer is uploaded when recording stops
- **And** on upload failure: the system retries with exponential backoff (delays: 5s, 10s, 30s, 1 min, 2 min)
- **And** if all retries fail: the local buffer is preserved and marked `pending_upload = true`; the student advances to the next Speaking part without interruption
- **And** the Exam Coordinator is notified via the live monitor (FR-39) that audio for this student is pending upload

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Speaking recording starts (FR-23)
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** connectivity is lost immediately before or after a client write acknowledgement
- **When** the client reconnects and reconciles state
- **Then** the server-authoritative state wins, acknowledged data is retained, and unacknowledged data is retried without overwriting newer data
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the browser or app crashes while an answer or Speaking upload is in flight
- **When** the student reopens the client within the exam window
- **Then** the system restores acknowledged answers and authoritative time, then resumes or flags pending media for explicit review
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-109 — preserve and upload partial Speaking recordings

**Scenario: Happy path / specified behavior**

- **Given** a student's Speaking Part C recording was interrupted after 20 seconds of a 40-second recording window
- **When** the student reconnects
- **Then** the partial audio buffer (20 seconds) is uploaded to Cloud Storage with metadata `partial_recording = true` and `interruption_reason`
- **And** the `exam_state` marks Speaking Part C as `partially_recorded`
- **And** the AI scoring pipeline (FR-30) processes the partial audio with an annotation: "Partial recording — {N} seconds of {M} seconds recorded"
- **And** the Teacher's review queue (FR-32) shows a "Partial Recording" indicator for affected parts
- **And** partial recordings are not silently discarded; the Teacher is required to review and may assign a manual score

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student reconnects; partial buffer is detected
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** connectivity is lost immediately before or after a client write acknowledgement
- **When** the client reconnects and reconciles state
- **Then** the server-authoritative state wins, acknowledged data is retained, and unacknowledged data is retried without overwriting newer data
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the browser or app crashes while an answer or Speaking upload is in flight
- **When** the student reopens the client within the exam window
- **Then** the system restores acknowledged answers and authoritative time, then resumes or flags pending media for explicit review
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-110 — detect microphone failure at the start of the Speaking skill and present the student with troub

**Scenario: Happy path / specified behavior**

- **Given** a student reaches Speaking Part A and microphone permission is denied by the browser
- **When** the system attempts to access the microphone
- **Then** the system displays a troubleshooting screen with: specific error message (e.g., "Microphone access was denied"), step-by-step platform-specific instructions to enable permission, and a "Retry" button
- **And** clicking Retry re-requests microphone permission; if granted, the exam continues normally
- **And** if all retries fail: the student is presented with two options: (A) "Signal Proctor" — sends an alert to the Exam Coordinator in the live monitor (FR-39) with status "Microphone Error — student needs assistance"; (B) "Skip Speaking" — marks Speaking as `skipped_due_to_device_error`, the Teacher is notified
- **And** the exam does not auto-terminate due to microphone failure; the attempt remains `in_progress` pending proctor intervention

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Microphone access request fails (permission denied, device not found, device error)
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** connectivity is lost immediately before or after a client write acknowledgement
- **When** the client reconnects and reconciles state
- **Then** the server-authoritative state wins, acknowledged data is retained, and unacknowledged data is retried without overwriting newer data
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the browser or app crashes while an answer or Speaking upload is in flight
- **When** the student reopens the client within the exam window
- **Then** the system restores acknowledged answers and authoritative time, then resumes or flags pending media for explicit review
- **And** no unauthorized, duplicate, or partially committed business state remains

### US-111 — allow a student to fully recover their exam session after a browser crash or app force-close, r

**Scenario: Happy path / specified behavior**

- **Given** a student's browser force-closed during Writing Part B with 8 answers saved
- **When** the student reopens the browser within the exam session window and logs in
- **Then** the system detects the `in_progress` attempt and automatically triggers the resume flow (FR-106)
- **And** all 8 previously saved answers are restored from the server-side `exam_state`
- **And** the Speaking audio local buffer (FR-108) is checked; any buffered audio that was not yet uploaded before the crash is uploaded on reconnection
- **And** if the session window expired during the crash: the attempt is auto-submitted with all persisted data and flagged `force_submitted_on_crash = true` for Coordinator review
- **And** the student receives no punitive consequence for a demonstrably technical failure (crash) as distinct from intentional navigation away (FR-99)

**Scenario: Authorization or validation rejection**

- **Given** the requester lacks the required role or belongs to another tenant
- **When** Student relaunches the browser/app after a crash
- **Then** the system returns HTTP 403 and commits no state change
- **And** the rejected request produces an auditable, actionable response without leaking sensitive information

**Scenario: Boundary condition**

- **Given** connectivity is lost immediately before or after a client write acknowledgement
- **When** the client reconnects and reconciles state
- **Then** the server-authoritative state wins, acknowledged data is retained, and unacknowledged data is retried without overwriting newer data
- **And** the response remains deterministic at the exact boundary

**Scenario: Concurrency, dependency failure, or recovery edge case**

- **Given** the browser or app crashes while an answer or Speaking upload is in flight
- **When** the student reopens the client within the exam window
- **Then** the system restores acknowledged answers and authoritative time, then resumes or flags pending media for explicit review
- **And** no unauthorized, duplicate, or partially committed business state remains
