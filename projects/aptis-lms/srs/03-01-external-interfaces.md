# SRS §3.1 — External Interface Requirements
## APTIS LMS
**Version:** 1.0 | **Date:** 2026-06-16 | **Status:** DRAFT

---

## 3.1.1 User Interfaces

### UI-01: Vendor Portal — Admin Dashboard
**Actor:** Super Admin | **Platform:** Flutter Web

The Admin Dashboard presents a global system overview with:
- Tenant list table: name, slug, status (active/suspended/expiring/expired), license seats (used/total), expiry date, last activity. Sortable by all columns; searchable by name or slug.
- Color-coded status: green = active >30 days, yellow = expiring ≤30 days, red = expired or suspended.
- Per-tenant action buttons: View Details, Suspend, Reactivate (with confirmation dialog for destructive actions).
- System health panel: API error rate, queue depth (AI scoring), recent failed notifications.

**UI requirements:** Data tables paginate at 50 rows. Destructive actions (Suspend, Decommission) require a typed-confirmation dialog ("Type the tenant name to confirm"). All timestamps displayed in the operator's browser timezone unless otherwise configured.

---

### UI-02: Vendor Portal — Content Management
**Actor:** Content Manager | **Platform:** Flutter Web

A CMS-style interface for managing the APTIS question bank:
- **Question browser:** filter by skill (Reading/Writing/Listening/Speaking), part (A–E), difficulty, topic tag, status (draft/active/archived). Full-text search in question content.
- **Question editor:** rich-text body with formatting support; audio upload with waveform preview (Listening); image upload with preview (Speaking Part B/D); answer key field (auto-score types); rubric criteria editor (human-score types); difficulty/topic tag pickers.
- **Exam template builder:** select questions per part or auto-fill by criteria; validates completeness (all required parts present).
- **Preview mode:** renders the question or template in an exam-like read-only view with functional audio playback and image display.
- **Item analysis view:** table with p-value, discrimination index, flag status; flagged questions list; drill-down to per-question statistics.
- **Bulk import:** drag-and-drop file upload (CSV/Excel); preview table before import; per-row error report after import.

**UI requirements:** Audio upload shows upload progress and duration. Question editor autosaves drafts every 30 seconds. Preview mode does not create exam records.

---

### UI-03: Vendor Portal — Support Dashboard
**Actor:** Support Staff | **Platform:** Flutter Web

- Tenant search by name, slug, or contact email.
- Tenant detail view: same data as Admin Dashboard tenant detail but all write controls hidden.
- Impersonation entry: "View as Tenant Admin" button opens Tenant Portal in read-only impersonation mode with a persistent orange banner: "Viewing [Tenant Name] — Read Only | Exit".
- All write actions in impersonation mode are disabled (buttons hidden or disabled with tooltip "Read-only view").

---

### UI-04: Sales Portal
**Actor:** Sales Team | **Platform:** Flutter Web

- Customer list: name, contact, license status (color-coded), seats_used/seat_count, expiry date, "Renew" quick-action button.
- Expiry alert panel on dashboard: tenants expiring in next 30 days, sorted ascending by days remaining.
- License form: tenant dropdown, seat count (integer), expiry date picker. Validation: seat_count ≥ 1, expiry_date > today.
- License history per tenant: reverse-chronological list of all licenses with full audit fields.

---

### UI-05: Tenant Portal — Admin View
**Actor:** Tenant Admin | **Platform:** Flutter Web

- **Dashboard:** License usage progress bar (green/yellow/red thresholds), upcoming sessions card, active courses count, enrolled students count vs. quota, recent activity feed.
- **User management:** table of all Tenant users with roles; add/edit/deactivate; multi-role assignment via checkbox list.
- **Course management:** create/edit course (name, description, date range); create/edit groups within course; assign teachers to groups.
- **Learner management:** student list per class with enrollment actions; CSV import flow; bulk credential export button (with one-time plaintext password warning).
- **Analytics:** all analytics views (§UI-07a through §UI-07d) accessible.
- **Exam sessions:** list of all sessions with status, completion rate, and action buttons.

**UI requirements:** CSV import shows row count, error count, and per-row errors. Bulk export triggers immediate download. License usage bar displays exact count and expiry date below the bar.

---

### UI-06: Tenant Portal — Teacher View
**Actor:** Teacher / Instructor | **Platform:** Flutter Web

- **My classes:** list of classes assigned to this teacher; click to enter class detail.
- **Class detail:** student list, exam session history, class average band per skill, group analytics.
- **Create exam session:** form with: name, template selector, participant scope (whole class or individual students), date/time window, anti-cheat configuration (shuffle toggle, warning and termination thresholds).
- **Scoring queue:** list of Writing/Speaking submissions pending review; count badge on nav icon. Sorted by submitted_at ascending (oldest first).
- **Score review screen:** left panel — student response (text for Writing; transcript + audio player for Speaking); right panel — AI draft scores per criterion, editable score fields, AI feedback narrative (editable), Confirm button. Confirm is explicitly required — no auto-save on navigation.
- **Class analytics:** class score overview, student ranking, before/after comparison, score distribution histogram, weak student alerts; all scoped to teacher's classes.

**UI requirements:** Audio player in score review shows waveform and duration. Transcript displayed in a scrollable fixed-height panel alongside the audio. Unsaved changes in score review prompt a "Leave without saving?" dialog on navigation.

---

### UI-07: Tenant Portal — Exam Coordinator View
**Actor:** Exam Coordinator | **Platform:** Flutter Web (or Flutter Desktop for dedicated monitoring)

- **Live monitor dashboard:** auto-updating table (WebSocket/SSE) with one row per enrolled student:
  - Status: Not Started / In Progress [Reading Part A] / Disconnected [last seen X min ago] / Submitted.
  - Violation count badge (red if ≥ warning_threshold).
  - Expand row: current question index, time remaining, violation log.
- **Per-student intervention panel:** [Extend Time (minutes + reason)] [Force Submit (reason)] [Reset Attempt (reason)] [View Violations].
- **Session controls:** [Close Session Early (grace period + reason)].
- **Integrity report:** available after session closes; shows all students with violation counts and types.

**UI requirements:** Disconnected students highlighted in amber. Students terminated by violation threshold highlighted in red. All intervention forms require a reason field (cannot submit empty). Table updates without page reload.

---

### UI-08: Tenant Portal — Viewer / Report Only
**Actor:** Viewer | **Platform:** Flutter Web

- Read-only access to all analytics views visible to Tenant Admin.
- No create/edit/delete controls visible.
- Export button (Excel/PDF) prominently placed.
- No access to user management, course management, or exam session creation.

---

### UI-09: Exam Client — Student Exam Interface
**Actor:** Student | **Platform:** Flutter Desktop (Windows/macOS), Flutter Web, Flutter Mobile (TBD — OI-01)

**Screen sequence:**
1. **Login:** tenant-branded (logo + display name), email + password, forgot password link.
2. **My Exams:** list of assigned sessions — upcoming (with countdown), active (Enter button), completed (View Results button).
3. **Pre-exam checks:**
   - Microphone test: request permission → 3-second record → playback → Pass/Retry.
   - Fullscreen prompt: "Enter fullscreen to begin the exam."
   - Per-skill instructions: time allowed, what to expect, "I understand — Begin" button.
4. **Reading interface:** scrollable passage (left); questions (right); navigation panel (question dots); MCQ radio buttons / matching dropdowns / gap-fill inputs; answered questions marked with checkmark in nav panel.
5. **Writing interface:** prompt (top); textarea (bottom) with live word count, word limit indicator changing colour at 90% of minimum/maximum.
6. **Listening interface:** read-only audio progress bar (no seek); play count indicator ("Play 1 of 1"); questions display simultaneously with audio.
7. **Speaking interface:** instruction/image display → preparation timer countdown → recording indicator with waveform → auto-stop → upload progress bar → next part.
8. **Part transition:** "Part X complete — Part Y starts in [countdown]s"; no back navigation.
9. **Results screen:** band per skill (immediate for Reading/Listening; "Awaiting teacher review" for Writing/Speaking); disclaimer text.
10. **Result detail:** per-skill breakdown by part, AI feedback (once confirmed), band descriptor card.

**UI requirements:** Timer is always prominently visible (large font, top-right). Offline indicator replaces timer area with "Reconnecting..." animation when network is lost. Writing word count colour: grey < 80% min, green in range, red > max. Speaking waveform uses real-time amplitude visualization.

---

### UI-10: Trial / Guest Landing Page
**Actor:** Guest | **Platform:** Flutter Web (public, no login)

- Hero section: "Luyện thi APTIS ngay hôm nay" with brief system description.
- Trial scope display: what skills/parts are available and estimated duration.
- Disclaimer: "Đây là bài thi thử mô phỏng, không phải kỳ thi APTIS chính thức của British Council."
- "Bắt đầu thi thử" CTA button.
- Post-trial: results with estimated band, disclaimer, "Liên hệ để triển khai cho trường của bạn" CTA with contact link.

---

## 3.1.2 Hardware Interfaces

### HW-01: Microphone
Required for Speaking skill. The Exam Client shall request microphone access via the platform's audio API (Web Audio API for Flutter Web; device microphone API for Flutter Desktop/Mobile). Minimum specification: mono capture, 16 kHz sample rate. The system shall test microphone availability during pre-exam checks (FR-18) and handle failure gracefully (FR-110).

### HW-02: Audio Output
Required for Listening skill. Standard device audio output (speakers or headphones). No special hardware interface; the system uses the platform audio API. Students should use headphones to avoid audio leakage in group exam settings.

### HW-03: Display
Minimum resolution for Exam Client: 1024×768 (desktop). Recommended: ≥1280×720 for comfortable exam layout. Fullscreen mode (FR-95) requires the display to support the platform's fullscreen API.

### HW-04: Network Interface
Minimum stable broadband connection required for audio streaming (Listening delivery) and audio upload (Speaking). The system's Exam Continuity features (F-13) handle brief disconnections but cannot recover from sustained total loss.

---

## 3.1.3 Software Interfaces

### SI-01: Cloud Object Storage (S3 / GCS)
- **Purpose:** Persistent storage for Speaking audio recordings, Listening audio files, question images, CSV imports, generated Excel/PDF exports.
- **Direction:** Read + Write (Backend API); Read via presigned URL or CDN (Exam Client for Listening audio).
- **Protocol:** HTTPS via provider SDK (AWS SDK or Google Cloud Storage SDK).
- **Audio delivery:** CDN-fronted for low-latency Listening playback; Listening audio must begin playing within the latency budget defined in NFR-08.
- **Speaking upload:** Client uploads via presigned URL (preferred) or Backend API proxy (fallback). Presigned URLs expire within the exam session window.

### SI-02: Email Service (SendGrid / AWS SES — TBD)
- **Direction:** Outbound from Backend async job queue.
- **Protocol:** REST API (provider-specific).
- **Content:** HTML templates with variable substitution; Vietnamese and English versions.
- **Delivery tracking:** Provider webhooks update `notification_log.delivery_status` to sent/bounced/failed.

### SI-03: Firebase Cloud Messaging (Push Notifications)
- **Conditional:** Only if Flutter Mobile is in platform scope (OI-01).
- **Direction:** Outbound from Backend.
- **Protocol:** FCM HTTP v1 API.
- **Token management:** Device tokens registered on first mobile app launch; stale tokens (app uninstalled) removed on delivery failure.

### SI-04: STT API — Speech-to-Text (TBD — OI-02)
- **Candidates:** OpenAI Whisper API, Google Cloud Speech-to-Text, Azure Cognitive Services.
- **Direction:** Outbound from AI Scoring async job.
- **Input:** Audio file URL in Cloud Storage.
- **Output:** Transcript text per Speaking part.
- **Language:** English (APTIS is an English test; no Vietnamese STT needed for exam content).
- **Error handling:** Retry up to 3 times; on permanent failure flag transcript as STT_FAILED.

### SI-05: LLM API — AI Scoring (TBD — OI-02)
- **Candidates:** Claude API (Anthropic), OpenAI GPT-4, Google Gemini.
- **Direction:** Outbound from AI Scoring async job.
- **Input:** Student response text + APTIS rubric prompt + part-specific instructions.
- **Output:** JSON — `{criterion_scores: {}, band_estimate: "B1", feedback_narrative: "..."}`.
- **Prompt design:** APTIS rubric prompts per skill/part are a required implementation deliverable (not in SRS scope but must be planned).
- **Provider switch:** Must be possible via configuration change, not code change.

### SI-06: Flutter Platform SDKs
The following Flutter packages (or equivalents) are required:
- Microphone recording: `record` or `flutter_sound`
- Local audio buffer (Speaking): `IndexedDB` (web) or platform file system (desktop/mobile)
- WebSocket client: `web_socket_channel`
- File picker (CSV import): `file_picker`
- Local storage (offline exam state buffer): `shared_preferences` or `hive`
- Fullscreen control: `flutter_fullscreen` or platform channel

---

## 3.1.4 Communication Interfaces

### CI-01: REST API
- **Protocol:** HTTPS (TLS 1.2 minimum; TLS 1.3 preferred)
- **Format:** JSON (application/json) for all request and response bodies
- **Authentication:** `Authorization: Bearer {access_token}` header on all protected endpoints
- **Versioning:** URL path versioning: `/api/v1/...`
- **Tenant resolution:** Resolved from request subdomain by API gateway middleware before routing to handlers
- **Error response schema:** `{ "code": "TENANT_QUOTA_EXCEEDED", "message": "...", "details": [...] }`
- **Rate limiting:** Authentication endpoints: 10 requests/minute per IP. Exam state write: 120 requests/minute per attempt_id.

### CI-02: WebSocket / Server-Sent Events
- **Purpose:** Real-time exam monitoring for Exam Coordinators (FR-39)
- **Protocol:** WebSocket (preferred); SSE as fallback
- **Authentication:** JWT passed in the WebSocket connection URL query parameter or upgrade header
- **Server events pushed to Coordinator client:**
  - `student.started` — student begins the exam
  - `student.progress` — current skill and part updated
  - `student.disconnected` — client lost connection (no heartbeat received for N seconds)
  - `student.reconnected` — client reconnected
  - `student.submitted` — attempt finalized
  - `student.violation` — violation event logged (type, cumulative count)
- **Client heartbeat:** Exam Client sends a heartbeat every 15 seconds; server marks student as disconnected if no heartbeat received for 45 seconds
- **Reconnect:** Coordinator and Student clients implement exponential backoff reconnect (1s, 2s, 4s, 8s, max 30s)

### CI-03: File Upload
- **Presigned URL flow (primary):** Backend generates presigned upload URL → Client uploads directly to Cloud Storage → Client notifies Backend of completion → Backend verifies and creates `assets` record
- **Proxy flow (fallback):** Client uploads to Backend API → Backend streams to Cloud Storage
- **Accepted formats:** Audio: MP3, WAV, WebM (browser recording); Images: JPEG, PNG; Imports: CSV, XLSX
- **Size limits:** Speaking audio per part: TBD (OI-05/07); Listening audio: no per-file limit (Vendor-managed); Images: ≤10MB; CSV/XLSX imports: ≤50MB

### CI-04: Subdomain Multi-tenant Routing
- **DNS:** Wildcard CNAME: `*.aptis-lms.vn` → load balancer / CDN edge
- **SSL:** Wildcard certificate covering `*.aptis-lms.vn` and `aptis-lms.vn`
- **API gateway:** Extracts slug from Host header → looks up tenant_id in cache (Redis/in-memory) → attaches to request context
- **Cache TTL for slug→tenant_id mapping:** 5 minutes (low mutation frequency; new tenants activate within one cache cycle)
- **Unknown slug handling:** Returns HTTP 404 with message "Tenant not found"
