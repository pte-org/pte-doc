# Plan File 03-01 — External Interface Requirements (SRS §3.1)
Project: APTIS LMS  
Date: 2026-06-16

---

## §3.1.1 User Interfaces

**What to write in SRS:** Description of each major UI surface — not wireframes, but screen-level specifications.

### UI-01: Vendor Portal — Admin Dashboard
- **Actor:** Super Admin
- **Platform:** Flutter Web (browser)
- **Key screens:**
  - Dashboard: tenant list with status (active/suspended/expiring), system health indicators
  - Tenant detail: usage stats, license info, action buttons (suspend/reactivate)
  - License management: create/edit license form (tenant_id, seat_count, expiry_date)
  - User management: Vendor-side users (Content Manager, Support Staff, Sales)
- **UI requirements:**
  - Data tables must support sorting and filtering
  - Tenant suspension requires confirmation dialog ("This will block all Tenant users. Confirm?")
  - All destructive actions require confirmation

### UI-02: Vendor Portal — Content Management
- **Actor:** Content Manager
- **Platform:** Flutter Web
- **Key screens:**
  - Question bank browser: filter by skill, part, difficulty, topic; search by keyword
  - Question editor: rich text input, file upload for audio (MP3/WAV) and images (JPEG/PNG), answer key fields, rubric fields, difficulty/topic tag selector
  - Exam template builder: drag-and-drop or select question per part, auto-select by criteria
  - Preview mode: render exam as student would see it (read-only)
  - Item analysis view: table of questions with p-value, discrimination index, flag status; click to view full stats
- **UI requirements:**
  - Audio upload: show waveform preview after upload
  - Question editor must support Vietnamese and English text
  - Bulk import: CSV/Excel upload with preview table and error report

### UI-03: Vendor Portal — Support Dashboard
- **Actor:** Support Staff
- **Platform:** Flutter Web
- **Key screens:**
  - Tenant overview (read-only): same as Admin Dashboard but no write actions
  - Tenant lookup: search tenant by name/slug, view usage, view recent exam sessions
  - Impersonation entry: click "View as Tenant Admin" → read-only Tenant Portal view
- **UI requirements:**
  - All impersonation sessions display a persistent banner: "Viewing as [Tenant Admin] — Read Only"
  - No write buttons visible in impersonation mode

### UI-04: Sales Portal
- **Actor:** Sales Team
- **Platform:** Flutter Web
- **Key screens:**
  - Customer list: table with columns (name, contact, license status, seats_used/total, expiry, last activity). Color-code: green=active, yellow=expiring in 30d, red=expired.
  - License form: create/edit license (tenant selector, seat count, expiry date)
  - License history per tenant: list of all licenses (created_by, created_at, seats, expiry, status)
  - Expiry alerts panel: tenants expiring in next 30 days, sorted by days remaining
- **UI requirements:**
  - One-click "Renew" from customer list (pre-populates form with current seats, extends expiry 1 year)
  - No access to exam data, student data, or question bank

### UI-05: Tenant Portal — Admin View
- **Actor:** Tenant Admin
- **Platform:** Flutter Web
- **Key screens:**
  - Dashboard: active courses, enrolled students, upcoming exam sessions, license usage bar, recent activity
  - User management: list all Tenant users with roles; add/edit/deactivate; assign multiple roles
  - Course management: create/edit courses (name, start/end date); manage groups/classes within course
  - Learner management: student list per class, enrollment, CSV import, bulk export Excel
  - Exam sessions: list all sessions (upcoming, active, completed) with status and completion rates
  - Reports: access to all analytics views (student, class, school-wide, export)
- **UI requirements:**
  - CSV import: preview table before confirm; show row-level errors after import
  - Bulk export Excel: button triggers download; password column included (one-time only)
  - License usage: progress bar showing seats_used/seat_count with color thresholds (green < 70%, yellow 70–90%, red ≥ 90%)

### UI-06: Tenant Portal — Teacher View
- **Actor:** Teacher / Instructor
- **Platform:** Flutter Web
- **Key screens:**
  - My classes: list of classes assigned to this teacher
  - Class detail: student list, exam session history, average band per skill
  - Create exam session: select exam template, select class/students, set time window, configure anti-cheat settings
  - Scoring queue: list of Writing/Speaking submissions awaiting review (student name, submitted_at, skill, AI draft score)
  - Score review: student response (text or audio player), AI draft score and feedback, editable score fields per criterion, confirm button
  - Class analytics: all reporting views for teacher's classes
- **UI requirements:**
  - Scoring queue: display count badge on nav icon
  - Score review: audio player for Speaking with waveform; transcript from STT displayed alongside
  - Confirm score requires explicit button click (no auto-save)

### UI-07: Tenant Portal — Exam Coordinator View
- **Actor:** Exam Coordinator
- **Platform:** Flutter Web (or Flutter Desktop for dedicated monitoring station)
- **Key screens:**
  - Live monitor dashboard: real-time list of enrolled students with status (Not Started / In Progress — shows current skill / Disconnected / Submitted). Auto-refresh via WebSocket.
  - Student detail panel: click student → see current question index, time remaining, violation count
  - Intervention panel: per student: [Extend Time (N minutes)] [Force Submit] [Reset Attempt (+ reason)] [View Violations]
  - Session management: open/close session manually
- **UI requirements:**
  - Disconnected students highlighted in orange; show time since last seen
  - Violation counts shown as badge on each student row; click to expand violation log
  - All interventions require confirmation + reason entry

### UI-08: Tenant Portal — Viewer / Report Only
- **Actor:** Viewer / Report Only
- **Platform:** Flutter Web
- **Key screens:**
  - School dashboard (same as Tenant Admin analytics view, read-only)
  - Class reports (read-only)
  - Export button (generate Excel/PDF reports)
- **UI requirements:**
  - No create/edit/delete UI elements visible
  - Export button prominently placed

### UI-09: Exam Client — Student Exam Interface
- **Actor:** Student (Registered)
- **Platform:** Flutter Desktop (Windows/macOS), Flutter Web, Flutter Mobile (iOS/Android) — [TBD — OI-01]
- **Key screens:**
  - Login screen (tenant-scoped, branded with tenant logo if configured)
  - My exams: list of assigned exam sessions (upcoming, active, completed)
  - Pre-exam checks: microphone test screen, fullscreen prompt, instruction screen per skill
  - Reading interface: scrollable passage + question panel, MCQ radio buttons, matching dropdowns, gap-fill inputs
  - Writing interface: prompt display + textarea with live word count and limit indicator
  - Listening interface: auto-playing audio, progress indicator, questions (no rewind)
  - Speaking interface: image/prompt display → preparation timer → recording timer → waveform visualizer → upload progress
  - Part transition screen: "Part N complete. Next part starts in 30 seconds."
  - Results screen: band per skill (available for Reading/Listening immediately; Writing/Speaking shows "Awaiting review")
  - Result detail: per-skill breakdown by part, AI feedback (after teacher confirms)
- **UI requirements:**
  - Timer: always visible, prominent countdown per part
  - Offline indicator: persistent banner when network lost
  - Fullscreen: required before exam start; exit fullscreen mid-exam triggers violation
  - Speaking waveform: real-time audio visualization during recording
  - Writing word count: color change at 90% and at limit
  - All exam UI text in Vietnamese (primary) with English option [TBD — OI-06 for language scope]

### UI-10: Trial / Guest Landing Page
- **Actor:** Guest / Trial Taker
- **Platform:** Flutter Web (public-facing)
- **Key screens:**
  - Landing: explanation of trial, what to expect, "Start Trial" CTA
  - Trial exam: subset of exam skills/parts (config: [TBD — OI-06])
  - Trial results: basic band estimate, explanatory text, sales CTA
- **UI requirements:**
  - No login required
  - Load time critical: must be fast-loading (trial is marketing-facing)
  - CTA after results: "Liên hệ để triển khai cho trường của bạn" → link/form

---

## §3.1.2 Hardware Interfaces

**What to write in SRS:**

### HW-01: Microphone
- Required for Speaking skill in Exam Client
- Platform: any standard Web Audio API or Flutter microphone plugin-compatible device
- Minimum: mono audio capture, 16kHz sample rate (sufficient for STT)
- System must detect microphone presence before Speaking part begins (FR-18)
- System must handle microphone disconnect gracefully (FR-111: Microphone Fail Handling)

### HW-02: Audio Output (Speakers/Headphones)
- Required for Listening skill
- Standard: any device audio output
- No special hardware requirement; system uses platform audio API

### HW-03: Display
- Minimum resolution: 1024×768 (desktop), 375×667 (mobile if applicable)
- Exam Client recommended: ≥ 1280×720 for comfortable exam experience
- Fullscreen capability required for kiosk mode (FR-95)

### HW-04: Network
- Minimum: stable broadband connection for audio streaming (Listening) and audio upload (Speaking)
- Exam Continuity features handle brief disconnections (seconds to minutes)
- Sustained complete network loss cannot be recovered without reconnection

---

## §3.1.3 Software Interfaces

**What to write in SRS:**

### SI-01: Cloud Object Storage (S3 / GCS)
- **Purpose:** Store Speaking audio recordings, Listening audio files, question images, CSV exports, generated Excel reports
- **Direction:** Read + Write from Backend API; Read (via pre-signed URL or CDN) from Exam Client
- **Protocol:** HTTPS / SDK (AWS S3 SDK or Google Cloud Storage SDK)
- **Audio upload:** Exam Client uploads directly to presigned URL or via Backend API proxy (TechLead to decide)
- **Audio delivery:** CDN-fronted for low-latency Listening playback

### SI-02: Email Delivery Service
- **Provider:** [TBD — TechLead: SendGrid / AWS SES / other]
- **Direction:** Outbound from Backend (triggers from system events)
- **Protocol:** REST API / SMTP
- **Templates:** HTML email templates, support Vietnamese + English
- **Bounces/failures:** Must log delivery status per notification send

### SI-03: Firebase Cloud Messaging (Push Notifications)
- **Purpose:** Push notifications to Flutter Mobile (if mobile platform is included — OI-01)
- **Direction:** Outbound from Backend
- **Protocol:** FCM HTTP v1 API
- **Dependency:** Only required if Flutter Mobile is a target platform

### SI-04: STT API — Speech-to-Text
- **Provider:** [TBD — OI-02: OpenAI Whisper API / Google Cloud Speech-to-Text / Azure Cognitive]
- **Direction:** Outbound from AI Scoring Service (async background job)
- **Input:** Audio file (MP3/WAV/WebM) from Cloud Storage
- **Output:** Transcript text per Speaking part
- **Language support:** English (APTIS is an English test)
- **Note:** Vietnamese language support not needed for STT (Speaking responses are in English)

### SI-05: LLM API — AI Scoring
- **Provider:** [TBD — OI-02: Claude API (Anthropic) / OpenAI GPT-4 / Google Gemini]
- **Direction:** Outbound from AI Scoring Service (async background job)
- **Input:** Student response text + APTIS rubric + part-specific prompt
- **Output:** Score per criterion + overall band estimate + narrative feedback
- **Prompt design:** TechLead to design rubric prompts for each skill/part
- **Response format:** Structured JSON (scores, band, feedback text) for database storage

### SI-06: Flutter Platform SDKs
- **microphone_access:** flutter_sound or record package — for Speaking recording
- **file_picker:** For CSV import (Tenant Portal)
- **url_launcher:** For notification deep links
- **web_socket_channel:** For live exam monitoring WebSocket
- **local_storage / IndexedDB (Web):** For Speaking audio local buffer (F-13)

---

## §3.1.4 Communication Interfaces

**What to write in SRS:**

### CI-01: REST API
- **Protocol:** HTTPS (TLS 1.2+)
- **Format:** JSON request/response bodies
- **Auth:** Bearer JWT in Authorization header
- **Base URL:** `api.{tenant-slug}.aptis-lms.vn/v1/` or `api.aptis-lms.vn/v1/` with X-Tenant header (TechLead to decide routing strategy)
- **Versioning:** URL path versioning (/v1/, /v2/)
- **Error format:** Consistent error response: `{ "code": "...", "message": "...", "details": [...] }`
- **Rate limiting:** [TBD — TechLead to define per endpoint type]

### CI-02: WebSocket / Server-Sent Events
- **Purpose:** Live exam monitoring (Exam Coordinator sees real-time student status updates)
- **Protocol:** WebSocket (preferred) or SSE
- **Events from server:** `student.started`, `student.progress` (current skill/question), `student.disconnected`, `student.submitted`, `student.violation`
- **Authentication:** Same JWT as REST API (passed in connection handshake)
- **Reconnect:** Client must auto-reconnect on disconnect with exponential backoff

### CI-03: File Upload
- **Method 1 (preferred):** Backend generates presigned URL → Client uploads directly to Cloud Storage → Backend receives upload-complete notification
- **Method 2 (fallback):** Client uploads to Backend API → Backend streams to Cloud Storage
- **Max file sizes:** Audio [TBD — OI-05/07], Images ≤ 10MB, CSV ≤ 50MB
- **Accepted audio formats:** MP3, WAV, WebM (browser recording format)

### CI-04: Subdomain-based Multi-tenant Routing
- **Pattern:** `{slug}.aptis-lms.vn` → resolve tenant_id from slug → scope all requests
- **Vendor Portal:** `admin.aptis-lms.vn` → no tenant scoping
- **DNS:** Wildcard CNAME `*.aptis-lms.vn` → load balancer / CDN
- **HTTPS:** Wildcard SSL certificate covering `*.aptis-lms.vn`
