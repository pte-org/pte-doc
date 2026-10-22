"""Generate the PTE Org end-to-end test scenario workbook.

The workbook is intentionally source-derived: API controller mappings, Next.js
pages and Flutter screen names are scanned from the checked-out repositories,
then joined with the business-flow cases below. It contains no credentials or
environment secrets.
"""

from __future__ import annotations

import re
import zipfile
from datetime import date
from pathlib import Path
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "pte-doc" / "plans" / "reports" / "261021-pte-org-comprehensive-test-scenarios.xlsx"


def xml_text(value: object) -> str:
    text = "" if value is None else str(value)
    return escape(text, {"\"": "&quot;", "'": "&apos;"})


def col_letter(number: int) -> str:
    result = ""
    while number:
        number, remainder = divmod(number - 1, 26)
        result = chr(65 + remainder) + result
    return result


def normalize_path(path: str) -> str:
    return path.replace("\\", "/")


def route_from_page(path: Path, root: Path) -> str:
    relative = path.relative_to(root).parent.parts
    route_parts: list[str] = []
    for part in relative:
        if part.startswith("(") and part.endswith(")"):
            continue
        if part == "page.tsx":
            continue
        if part.startswith("[") and part.endswith("]"):
            route_parts.append("{" + part[1:-1] + "}")
        else:
            route_parts.append(part)
    return "/" + "/".join(route_parts)


def scan_routes() -> list[list[str]]:
    rows: list[list[str]] = []
    roots = [
        (ROOT / "pte-web/apps/tenant-web/app", "tenant-web"),
        (ROOT / "pte-web/apps/vendor-web/app", "vendor-web"),
        (ROOT / "pte-practice/app", "pte-practice"),
    ]
    for root, application in roots:
        for page in sorted(root.rglob("page.tsx")):
            rows.append(
                [
                    application,
                    route_from_page(page, root),
                    normalize_path(str(page.relative_to(ROOT))),
                    "UI route inventory; pair with role and authorization cases",
                ]
            )
    return rows


def scan_flutter_screens() -> list[list[str]]:
    rows: list[list[str]] = []
    root = ROOT / "pte-app/lib"
    pattern = re.compile(r"class\s+(\w+(?:Page|Screen))")
    for path in sorted(root.rglob("*.dart")):
        content = path.read_text(encoding="utf-8", errors="ignore")
        names = sorted(set(match.group(1) for match in pattern.finditer(content)))
        if names:
            rows.append(
                [
                    "pte-app",
                    ", ".join(names),
                    normalize_path(str(path.relative_to(ROOT))),
                    "Desktop screen inventory; validate window, device and delivery policy",
                ]
            )
    return rows


def scan_api_endpoints() -> list[list[str]]:
    rows: list[list[str]] = []
    root = ROOT / "pte-api/app/src/main/java/com/pte"
    constants: dict[str, str] = {}
    for constants_file in root.rglob("*Constants.java"):
        constants_content = constants_file.read_text(encoding="utf-8", errors="ignore")
        for constant in re.finditer(r'public\s+static\s+final\s+String\s+(\w+)\s*=\s*"([^"]+)"', constants_content):
            constants[constant.group(1)] = constant.group(2)

    class_mapping = re.compile(r"@RequestMapping\(([^)]*)\)")
    method_mapping = re.compile(r"@(GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping)(?:\((.*?)\))?")
    quoted = re.compile(r'\"([^\"]*)\"')
    for path in sorted(root.rglob("*Controller.java")):
        content = path.read_text(encoding="utf-8", errors="ignore")
        normalized = re.sub(r"\s+", " ", content)
        base_match = class_mapping.search(normalized)
        base_token = base_match.group(1).strip() if base_match else ""
        base_values = quoted.findall(base_token)
        if base_values:
            base = base_values[0]
        else:
            base = constants.get(base_token.split(".")[-1], "(constant or method-level path)")
        for mapping in method_mapping.finditer(normalized):
            raw = mapping.group(2) or ""
            paths = [value for value in quoted.findall(raw) if value.startswith("/")]
            if not paths:
                token_match = re.search(r"([A-Za-z_]\w*\.[A-Za-z_]\w*)", raw)
                paths = [constants.get(token_match.group(1).split(".")[-1], "")] if token_match else [""]
            for suffix in paths:
                if base.startswith("("):
                    endpoint = base
                else:
                    endpoint = (base.rstrip("/") + "/" + suffix.lstrip("/")) if suffix else base
                rows.append(
                    [
                        mapping.group(1).replace("Mapping", "").upper(),
                        endpoint,
                        path.stem,
                        normalize_path(str(path.relative_to(ROOT))),
                        "Verify authentication, authorization, validation, response envelope, audit and idempotency where applicable",
                    ]
                )
    return rows


HEADERS = [
    "Case ID",
    "Priority",
    "Module",
    "Actor",
    "Screen / API",
    "Domain / App",
    "How to enter",
    "Preconditions / test data",
    "Steps",
    "Happy case",
    "Unhappy case",
    "Expected result / pass criteria",
    "Secondary criteria",
    "Permission / tenant boundary",
    "Audit / notification / integration",
    "Execution status",
    "Actual result",
    "Evidence link / screenshot",
    "Defect ID",
    "Notes",
]


def case(
    case_id: str,
    priority: str,
    module: str,
    actor: str,
    screen: str,
    domain: str,
    entry: str,
    preconditions: str,
    steps: str,
    happy: str,
    unhappy: str,
    expected: str,
    secondary: str,
    permission: str,
    audit: str,
    status: str = "Not run",
) -> list[str]:
    return [
        case_id,
        priority,
        module,
        actor,
        screen,
        domain,
        entry,
        preconditions,
        steps,
        happy,
        unhappy,
        expected,
        secondary,
        permission,
        audit,
        status,
        "",
        "",
        "",
        "",
    ]


def build_cases() -> list[list[str]]:
    rows: list[list[str]] = []
    common_api = "API via same-origin /api/v1"

    def add(*args: str, **kwargs: str) -> None:
        if len(args) != 15:
            raise ValueError(f"Expected 15 test-case fields, got {len(args)}: {args[:3]}")
        rows.append(case(*args, **kwargs))

    # Public onboarding and identity.
    identity = [
        ("TC-ID-001", "P0", "Identity / onboarding", "Applicant", "Organization registration", "tenant-web", "/register", "Clean browser; unique organization, tax code, admin email", "Open register; fill required organization and first-admin fields; submit", "Valid application is accepted and confirmation is shown", "Required field, invalid email/tax code, duplicate email/tax code, oversized input", "Application is stored once; no password or token appears in URL/log; clear validation is shown", "Keyboard order, labels, locale, refresh and duplicate submit", "Public endpoint only; applicant cannot access tenant workspace before approval", "Application audit/event and notification delivery status",),
        ("TC-ID-002", "P0", "Identity / onboarding", "Platform Admin", "Application review", "vendor-web", "/admin/applications", "Pending application exists", "Login; open application; inspect details; approve", "Organization and first Host are created; status becomes approved", "Approve twice, missing required data, unauthorized role", "Second approval is idempotent or rejected safely; no duplicate tenant/user", "Audit includes actor, application and transition; notification is visible", "Only Platform Admin can approve", "Audit + applicant/Host notification",),
        ("TC-ID-003", "P0", "Identity / onboarding", "Platform Admin", "Application review", "vendor-web", "/admin/applications/{id}", "Pending application exists", "Open application; reject with reason", "Status becomes rejected and reason is visible", "Blank reason, already approved, unknown ID", "No workspace is activated; rejection is terminal according to lifecycle", "Reason is sanitized; notification failure does not rollback state", "Only Platform Admin", "Audit + rejection notification",),
        ("TC-ID-004", "P0", "Identity / auth", "Host", "Login", "tenant-web", "/login", "Approved Host account", "Enter valid credentials; submit; refresh page", "Host dashboard loads and session survives permitted refresh", "Wrong password, locked/suspended user, wrong organization option", "No token in URL; generic safe error; no cross-tenant login", "Rate limit after repeated failure; accessible error", "Role HOST_ADMIN and tenant checked", "Login success/failure audit as configured",),
        ("TC-ID-005", "P0", "Identity / auth", "Platform Admin", "Login", "vendor-web", "/login", "Platform Admin account", "Login with valid and invalid credentials", "Admin dashboard loads only with valid account", "Host/Student credentials, invalid password, expired token", "Forbidden roles cannot enter admin routes; 401/403 handled consistently", "No sensitive values in UI or logs", "PLATFORM_ADMIN required", "Auth audit and rate-limit behavior",),
        ("TC-ID-006", "P0", "Identity / auth", "Student", "Exam login", "pte-app", "Launch desktop app", "Eligible exam session ID; student credentials", "Enter username, password and session ID; log in", "Correct session opens the assigned exam", "Blank/invalid/expired session ID, wrong credentials, non-enrolled student", "Login cannot proceed without session ID; safe error; no unrelated exam data", "Windowed login allowed; exam policy applied only after entry", "Student and session ownership enforced", "Login/attempt audit",),
        ("TC-ID-007", "P1", "Identity / auth", "Any user", "Change password", "tenant-web/vendor-web", "/change-password", "Authenticated account", "Enter current password and valid new password; submit; re-login", "Password changes and old password is rejected", "Wrong current password, weak/mismatched new password", "No partial update; clear validation", "Password not echoed or logged; session policy honored", "Own account or admin reset flow only", "Password change audit/notification",),
        ("TC-ID-008", "P1", "Identity / auth", "Platform Admin", "Reset password", "vendor-web", "/admin/platform-users", "Target user exists", "Open user; request reset; use generated/send path", "Reset flow succeeds once", "Suspended/nonexistent user, replay reset", "No account enumeration; token expiry and one-time use", "Notification failure is visible without corrupting account", "Admin can reset; tenant cannot reset platform users", "Audit + credential notification",),
        ("TC-ID-009", "P0", "Identity / auth", "Any user", "Logout / refresh", common_api, "/api/v1/auth/logout and refresh", "Authenticated token pair", "Logout; reuse access token; refresh before and after expiry", "Logout invalidates appropriate session; refresh rotates/renews", "Replay refresh, malformed token, expired refresh", "401 response uses standard envelope; no stale access", "Multi-tab/session behavior", "Token subject and role validated", "Auth audit",),
        ("TC-ID-010", "P0", "Security / tenancy", "Host", "Cross-tenant access", "tenant-web", "Directly open another tenant public ID", "Two organizations and users", "Change IDs in URL/API request; compare response", "Own records only are returned", "Other tenant student/exam/report IDs", "403/404 without data leak; no count/name leak", "Browser back/cache does not reveal restricted data", "Organization boundary enforced server-side", "Denied access audit where configured",),
        ("TC-ID-011", "P1", "Identity / profile", "Host", "Organization profile and branding", "tenant-web", "/host/profile", "Active organization; image/logo file", "Edit profile, branding and save; reload in another tab", "Changes persist and render in tenant shell", "Invalid file type/size, suspended org, duplicate update", "Atomic validation; current values retained on failure", "Image preview, responsive UI, cache invalidation", "Own organization only", "Profile/branding audit",),
        ("TC-ID-012", "P1", "Identity / directory", "Platform Admin", "Platform user management", "vendor-web", "/admin/platform-users", "Admin and user fixtures", "Create, view, edit role, suspend/reactivate, restore", "Lifecycle transitions are reflected in lists and login access", "Duplicate email, invalid role transition, delete active user", "No orphan roles; suspended user denied immediately", "Pagination/filter/export if present", "PLATFORM_ADMIN only", "User/role audit + notification",),
    ]
    for item in identity:
        add(*item)
    
    # Vendor/platform content, scoring and commercial flows.
    catalog_cases = [
        ("TC-ADM-001", "P0", "Question bank", "Platform Author", "Question list", "vendor-web", "/admin/questions", "Published/draft questions with text, image and audio", "Filter by skill, status, difficulty; search; open detail", "Correct paginated list and filters", "Unknown code, empty result, invalid page", "No stale count; pagination and filters agree", "Media thumbnail/audio control; no raw storage secret", "Author sees allowed content only", "Read audit if configured",),
        ("TC-ADM-002", "P0", "Question bank", "Platform Author", "Create question", "vendor-web", "/admin/questions/new", "Active task type; valid answer schema", "Create text-only question; create image/audio question; save draft", "Draft stores revision and answer payload", "Missing title/prompt/answer, invalid media, unsupported task schema", "Validation prevents incomplete draft; no orphan media", "Preview matches exam renderer; autosave/reload if supported", "Author can draft; Host cannot use unpublished content", "Draft creation audit",),
        ("TC-ADM-003", "P0", "Question bank", "Platform Author", "Edit question", "vendor-web", "/admin/questions/{id}/edit", "Draft and published question fixtures", "Edit draft; edit published question; save", "Draft updates in place; published edit creates new revision", "Edit locked revision, invalid answer, concurrent update", "Published exam keeps original revision; optimistic conflict is clear", "Cancel returns without data loss; media replacement cleanup", "Platform Author/Admin only", "Revision/edit audit",),
        ("TC-ADM-004", "P0", "Question bank", "Platform Admin", "Question approval and publication", "vendor-web", "/admin/questions/{id}", "Draft submitted for approval", "Submit; approve/reject; publish/archive/unarchive", "Lifecycle follows valid transition and list updates", "Approve incomplete media, publish rejected/draft, duplicate action", "Invalid transition rejected; question cannot enter active bank", "Reason required on rejection; notification status", "Author submits; Admin approves/publishes", "Approval/publication audit + notification",),
        ("TC-ADM-005", "P1", "Question bank / media", "Platform Author", "Cloudinary media upload", "vendor-web", "Create/edit question media field", "Signed upload config; image/audio file", "Request signed upload; upload; complete; preview", "Media object is linked and preview works", "Expired signature, duplicate complete, bad MIME/size, missing asset", "No question publish with incomplete media; retry is safe", "Audio seek/playback; image dimensions; accessibility alt text", "Signed upload only; no public unsigned mutation", "Media upload/complete audit and error status",),
        ("TC-ADM-006", "P0", "Task type catalog", "Platform Admin", "Task type list/create/edit", "vendor-web", "/admin/question-types", "Released screen contracts; unique key", "Create unique key; select section/screen/version; edit draft", "Catalog item and runtime contract are visible", "Duplicate key, invalid format, unsupported version", "Server validates uniqueness and contract compatibility", "Published-template lock warning; available-for-new-questions flag", "Admin/Author permission; lock after published template", "Task type audit/notification",),
        ("TC-ADM-007", "P0", "Score template", "Platform Author", "Score template lifecycle", "vendor-web", "/admin/score-template", "Task types and scoring methods", "Create draft; add items/weights/timing; submit; approve; activate; retire", "Only valid active template can be selected for exam", "Duplicate item, invalid weight/count, activate incomplete/rejected", "Feasibility errors are actionable; activation is atomic", "Version is immutable once used; copy/clone behavior", "Author drafts; Admin approves/activates", "Lifecycle audit + notification",),
        ("TC-ADM-008", "P0", "Exam template", "Platform Admin", "Exam template lifecycle", "vendor-web", "/admin/exam-template", "Task type catalog and question bank", "Create template; add four skills/task counts; edit; publish", "Published template has deterministic item contract", "Missing skill/task, no eligible questions, edit after publish", "Readiness blocks invalid template; lock warning appears", "Question count per task; runtime capability compatibility", "Platform Admin only", "Template audit",),
        ("TC-ADM-009", "P1", "Task type catalog", "Platform Admin", "Capability/availability", common_api, "/api/v1/task-types/capabilities and availability", "Mixed released/deprecated contracts", "Load capabilities; filter availability for new question/template", "Only released compatible contracts are selectable", "Stale/deprecated version or missing runtime", "Unavailable contract cannot be selected or silently substituted", "Response envelope and cache freshness", "Admin-only configuration", "Catalog read audit if required",),
        ("TC-ADM-010", "P1", "Platform dashboard", "Platform Admin", "Admin dashboard", "vendor-web", "/admin", "Organizations, revenue, questions, applications", "Open dashboard; change date range; refresh", "Sections load correct counts and partial failure is isolated", "One backend section fails or unauthorized", "Useful empty/error state; no whole-page crash", "Performance target and loading skeleton", "Platform Admin only", "Dashboard read metrics",),
        ("TC-ADM-011", "P1", "Audit", "Platform Admin", "Platform audit log", "vendor-web", "/admin/audit-log", "Audit records across tenants", "Filter by actor/action/date/target; open detail", "Records and filters match source action", "Invalid date/range, unauthorized tenant query", "Sensitive payload is masked; pagination stable", "UTC display/local conversion", "Platform audit immutable/read-only", "Audit review evidence",),
        ("TC-ADM-012", "P1", "Announcements / notifications", "Platform Admin", "Announcement management", "vendor-web", "/admin/announcements", "Audience with active/inactive users", "Create draft; audience preview; publish; retry delivery", "Published announcement reaches intended inbox", "Empty audience, duplicate publish, provider failure", "No duplicate delivery; failure state retryable", "Real-time unread count; deep link", "Admin scope; audience rules enforced", "Notification log + delivery audit",),
        ("TC-ADM-013", "P1", "Notifications", "Any user", "Notification inbox/detail", "tenant-web/vendor-web", "/notifications", "Unread and read notifications", "Open inbox; open detail; mark read/all; refresh", "Unread count and read state synchronize", "Unknown notification, forbidden recipient, realtime disconnect", "No cross-user notification; optimistic update reconciles", "Realtime event, polling/reconnect behavior", "Recipient ownership", "Notification audit/log",),
        ("TC-ADM-014", "P1", "Support", "Host", "Support ticket", "tenant-web", "/host/support-tickets", "Active org; ticket category", "Create ticket; add note; close; reopen if allowed", "Ticket status and notes persist", "Blank/oversized message, closed ticket mutation, wrong ticket ID", "No data loss; status transition rules enforced", "Sanitize HTML; attachment rules", "Own organization only", "Ticket audit + notification",),
    ]
    for item in catalog_cases:
        add(*item)

    commercial_cases = [
        ("TC-BIL-001", "P0", "Billing", "Platform Admin", "Plan catalog", "vendor-web", "/admin/plans", "Plan draft and active plan", "Create/edit/activate/archive plan; inspect public selection", "Only active purchasable plan is selectable", "Negative price, duplicate code, archive used plan", "Validation and lifecycle rules hold; existing subscription unaffected", "Currency/format/time window; idempotent activation", "Platform Admin only", "Plan audit",),
        ("TC-BIL-002", "P0", "Billing", "Host", "Checkout/order", "tenant-web", "/host/checkout", "Active organization; available plan", "Select plan; create order; follow pending/return path", "Order ID and pending status are shown", "Unavailable plan, duplicate submit, expired session", "No duplicate order on retry; browser return not treated as payment proof", "Totals, currency, timeout, back navigation", "Own organization billing", "Order audit + payment notification",),
        ("TC-BIL-003", "P0", "Billing", "PayOS", "Payment callback", common_api, "/api/v1/webhooks/payos", "Valid signed callback fixture", "Send valid callback twice; send invalid signature/status", "One callback activates one entitlement", "Bad signature, unknown order, duplicate callback", "Unauthorized callbacks rejected; duplicate is idempotent", "No secret in response/log; transaction atomic", "Webhook service auth/signature", "Payment callback audit",),
        ("TC-BIL-004", "P0", "Billing", "Host", "Redeem license", "tenant-web", "/host/redeem-license", "Unused valid code", "Redeem code; refresh subscription/quota", "Exactly one redemption activates entitlement", "Wrong/expired/already redeemed code; double click", "No partial quota/subscription; clear reason", "Code masked after redemption; timezone/date", "Own organization only", "Redemption audit + notification",),
        ("TC-BIL-005", "P0", "Billing", "Platform Admin", "License code management", "vendor-web", "/admin/license-codes", "Plan and generated code", "Issue; list; lookup; reveal; revoke preview; revoke", "Code lifecycle and subscription impact are correct", "Reveal unauthorized, revoke active code without confirmation, replay", "Confirmation and impact preview required; no destructive surprise", "Clipboard masking; pagination", "Admin only", "License/revocation audit + notification",),
        ("TC-BIL-006", "P1", "Billing", "Host", "Subscription/quota", "tenant-web", "/host/billing and /host/quota", "Active/expired subscription variants", "View subscription, license key, quota transactions and usage", "Usage and remaining quota match source data", "Expired/revoked subscription; inaccessible organization", "Grace/blocked behavior explicit; no negative quota", "Currency/time display", "Organization scope", "Quota transaction audit",),
    ]
    for item in commercial_cases:
        add(*item)

    host_cases = [
        ("TC-HOST-001", "P0", "Host dashboard", "Host", "Host dashboard", "tenant-web", "/host/dashboard", "Active organization with data", "Open dashboard; refresh; change period", "Operational sections show correct counts and links", "Partial API failure, suspended organization", "Useful loading/error/empty states; no cross-tenant data", "Time zone, performance, navigation", "HOST_ADMIN and organization scope", "Read metrics/audit",),
        ("TC-HOST-002", "P0", "Student roster", "Host", "Student list/search", "tenant-web", "/host/students", "Students across statuses/classes", "Search, filter, paginate, open student detail", "Results/counts match filters and selected organization", "No-result, invalid page, another tenant ID", "Stable pagination and no unauthorized data", "Debounce, URL state, accessibility", "Host own organization", "Read audit if configured",),
        ("TC-HOST-003", "P0", "Student roster", "Host", "Create student", "tenant-web", "/host/students", "Available quota; unique student email", "Create student; send/generate credentials; login as student", "Student belongs to org and can authenticate", "Duplicate email, quota exceeded, invalid fields", "No user/role orphan; no partial create", "Credential masking and notification failure handling", "Host own org", "Student creation + credential audit/notification",),
        ("TC-HOST-004", "P0", "Student roster", "Host", "Bulk import preview/confirm", "tenant-web", "/host/roster", "CSV/XLSX with valid, duplicate, malformed rows", "Upload; inspect preview errors; confirm valid rows", "Only valid rows import; duplicates are reported", "Wrong headers, oversize file, quota overflow, duplicate confirm", "Preview is non-mutating; confirm idempotent/atomic per contract", "Encoding, row number errors, downloadable report", "Org quota/ownership enforced", "Import audit + notifications",),
        ("TC-HOST-005", "P1", "Student detail", "Host", "Student detail/profile", "tenant-web", "/host/students/{id}", "Existing student", "Edit profile; suspend/reactivate; reset credentials", "Changes persist and login status follows lifecycle", "Forbidden field, other org, invalid state transition", "Server rejects invalid transition; no stale UI", "Optimistic concurrency and audit visibility", "Host own org", "Profile/status audit + notification",),
        ("TC-HOST-006", "P0", "Programs", "Host", "Program list/create/edit", "tenant-web", "/host/programs", "Active organization", "Create/edit/activate/deactivate/archive program; dashboard", "Program lifecycle and counts update", "Duplicate code, archive with active class, invalid dates", "Transition rules and class dependencies enforced", "Search/pagination/empty state", "Own org only", "Program audit",),
        ("TC-HOST-007", "P0", "Classes", "Host", "Class list/create/edit", "tenant-web", "/host/classes", "Program fixture", "Create/edit/activate/suspend/archive class", "Class is visible under correct program", "Duplicate class code, invalid program, archived class update", "No orphan class; clear conflict", "Member count and filters", "Own org only", "Class audit",),
        ("TC-HOST-008", "P0", "Enrollment", "Host", "Class membership", "tenant-web", "/host/programs/{id}/classes/{id}", "Students and class", "Add one/bulk student; remove; transfer; merge/split", "Membership changes and counts are correct", "Duplicate membership, cross-org student, merge conflict", "No silent duplicate; transfer/removal explicit and auditable", "Concurrency and confirmation", "Org ownership and active class rules", "Membership audit + notification",),
        ("TC-HOST-009", "P1", "Exam staff", "Host", "Exam staff list/profile", "tenant-web", "/host/exam-staff", "Proctor/examiner accounts", "Create/update staff profile; activate/deactivate; view assignments", "Staff appears with correct role and availability", "Duplicate email, invalid role, unauthorized staff", "Role profile consistent; no assignment leak", "Search/pagination", "Own org; Host only", "Staff audit + notification",),
        ("TC-HOST-010", "P0", "Exam setup", "Host", "Create exam wizard", "tenant-web", "/host/exams", "Active template, package/license, students", "Open wizard; choose template, mode, skills, retries, policy, schedule", "Review summary reflects selected configuration", "Missing template/license/audience, invalid schedule, incompatible runtime", "Generate button disabled with actionable reason; no hidden default", "Practice/Mock/Official rules; timer; anti-cheat flag", "Host own org and entitlements", "Draft creation audit",),
        ("TC-HOST-011", "P0", "Exam setup", "Host", "Audience sources", "tenant-web", "/host/exams/new", "Student/class/program sources with overlap", "Add/remove sources; preview deduped audience", "Unique eligible students and exclusion reasons are shown", "Empty source, duplicate source, inactive student, overlap", "No silent enrollment; preview matches final generation", "Horizontal scroll/responsive modal; count accuracy", "Own org only", "Audience audit",),
        ("TC-HOST-012", "P0", "Exam setup", "Host", "Exam preflight", "tenant-web", "/host/exams/{id}", "Draft with one or more invalid conditions", "Run preflight; fix each issue; rerun", "All checks pass only when questions, license, capacity, schedule and runtime are valid", "Missing bank questions, expired package, capacity, conflict, incompatible task", "No publish until mandatory checks pass", "Reason codes stable; retry safe", "Host exam scope", "Preflight audit",),
        ("TC-HOST-013", "P0", "Exam generation", "Host", "Generate and publish", "tenant-web", "/host/exams/{id}", "Preflight-ready draft", "Generate; poll status; publish", "Snapshot, seed/form and content are fixed; session ID appears", "Duplicate generate, generation failure, publish before ready", "Idempotent result; no partial session; clear retry path", "Progress and refresh/reopen behavior", "Host own exam", "Generation/publication audit + notification",),
        ("TC-HOST-014", "P0", "Exam lifecycle", "Host", "Exam detail/open/close/cancel", "tenant-web", "/host/exams/{id}", "Published exam in each lifecycle state", "Open; close; cancel; inspect session status", "Allowed transitions update student eligibility", "Open draft, close unopened, cancel after attempt, duplicate action", "Illegal transitions rejected and audited", "Confirmation dialogs; timestamps UTC/local", "Host exam ownership", "Lifecycle audit + student notification",),
        ("TC-HOST-015", "P0", "Exam configuration", "Host", "Policy / retries / anti-cheat", "tenant-web", "/host/exams/{id}", "Practice, Mock, Official variants", "Set timer, retry count, skills, anti-cheat warning/audit flag; save", "Runtime receives exactly selected policy", "Invalid retry, changing locked policy, missing required skill", "Server is authoritative; no policy drift in snapshot", "Practice allows navigation as configured; official restrictions stay strict", "Host exam scope", "Policy change audit",),
        ("TC-HOST-016", "P0", "Enrollment", "Host", "Exam enrollment", "tenant-web", "/host/exams/{id}", "Published exam and eligible students", "Enroll one, bulk, class/program; remove where allowed", "Student sees correct exam/session", "Over capacity, overlap, duplicate, wrong org", "Deduplication and rejection reasons visible", "Idempotency and count", "Host exam/org scope", "Enrollment audit + notification",),
        ("TC-HOST-017", "P0", "Proctor assignment", "Host", "Assign proctor", "tenant-web", "/host/exams/{id}", "Active proctor and published exam", "Assign; update; remove; inspect proctor session list", "Assigned proctor sees only assigned exam", "Unassigned proctor access, duplicate assignment, closed exam", "Permission enforced server-side", "Realtime refresh and audit trail", "Assignment boundary", "Assignment audit + notification",),
        ("TC-HOST-018", "P0", "Examiner assignment", "Host", "Assign examiner", "tenant-web", "/host/exams/{id}", "Published exam with subjective answers", "Preview roster; commit assignment; confirm batch", "Examiner queue contains only assigned attempts", "Empty pool, invalid attempt, duplicate commit, cross-org examiner", "Assignment is idempotent and auditable", "Queue/status refresh", "Exam and examiner assignment boundary", "Assignment audit + notification",),
        ("TC-HOST-019", "P0", "Report publication", "Host", "Score review and publication", "tenant-web", "/host/exams/{id}", "Completed attempt with automated/examiner scores", "Review score sources; select source; finalize cohort; preflight; publish", "Report publishes only when all required scores and sources are complete", "Missing score, invalid source, repeat publish, wrong exam", "No partial report; published result is immutable/traceable", "Source selection history and score provenance", "Host owns exam; Examiner cannot publish", "Review/publication audit + notification",),
        ("TC-HOST-020", "P0", "Report viewing", "Student", "Student results", "tenant-web", "/student/results", "Published report and unpublished report", "Open results before and after Host publication", "Only published own report is visible", "Another student/report ID, unpublished or revoked report", "403/404 and no score leak", "Report formatting, 10-90 values, skill totals", "Student owns report", "Publication event/notification",),
    ]
    for item in host_cases:
        add(*item)

    # Proctor and Examiner workspaces.
    staff_cases = [
        ("TC-STAFF-001", "P0", "Proctoring", "Proctor", "Proctor dashboard", "tenant-web", "/proctor", "Assigned active exam", "Open dashboard; inspect sessions/availability", "Only assigned sessions and current status are visible", "No assignment, closed exam, other org", "Access denied or empty state; no leak", "Realtime refresh and stale indicator", "PROCTOR + assignment", "Read audit/notification",),
        ("TC-STAFF-002", "P0", "Proctoring", "Proctor", "Attendance", "tenant-web", "/proctor/attendance/{id}", "Published exam and enrolled student", "Mark present/absent/late; correct identity; view receipt/history", "Attendance and receipt state persist", "Invalid transition, duplicate request, wrong student", "Atomic result; history visible", "Confirmation, UTC/local timestamp", "Assigned exam only", "Attendance audit + notification",),
        ("TC-STAFF-003", "P0", "Proctoring", "Proctor", "Monitoring", "tenant-web", "/proctor/sessions/{id}", "Student attempt in progress", "Open monitoring; refresh; inspect attempt status", "Current status/heartbeat is accurate", "Stale heartbeat, disconnected student, unassigned exam", "Stale state labeled; no false active status", "Polling/realtime reconnect", "Assigned exam only", "Monitoring audit",),
        ("TC-STAFF-004", "P0", "Proctoring", "Proctor", "Incident create/detail", "tenant-web", "/proctor/incidents/{id}", "Attempt and incident policy", "Record violation; add evidence/note; change status", "Incident appears in host audit and student policy behavior", "Blank reason, invalid status transition, duplicate incident", "Practice warning/audit does not auto-invalidate; strict policy follows contract", "Sanitize notes; evidence access", "Assigned exam only", "Incident audit + notification",),
        ("TC-STAFF-005", "P1", "Proctoring", "Host", "Violation/security audit", "tenant-web", "/host/audit-log or exam detail", "Violation events exist", "Filter by exam/student/time; open history", "Audit entries are complete and ordered", "Cross-org query, missing event, malformed page", "Sensitive data masked; immutable history", "UTC and correlation ID", "Host own organization", "Audit review",),
        ("TC-STAFF-006", "P0", "Examiner", "Examiner", "Examiner work queue", "tenant-web", "/examiner/work", "Assigned attempts", "Open queue; filter status; open attempt", "Only assigned work appears with correct statuses", "No assignments, other attempt ID, finalized item", "Forbidden access; stable queue state", "Pagination and refresh", "EXAMINER + assignment", "Queue read audit",),
        ("TC-STAFF-007", "P0", "Examiner", "Examiner", "Exam scoring", "tenant-web", "/examiner/work/{session}/{attempt}", "Assigned attempt with subjective answer", "Start; score answer; save draft; finalize", "Draft score persists; finalized score enters Host review", "Out-of-range score, missing rubric, double finalize, wrong answer", "Validation and finalization lock are enforced", "Guidelines/history visible; no accidental publish", "Assigned attempt only; no publication authority", "Scoring audit + notification",),
        ("TC-STAFF-008", "P1", "Examiner", "Examiner", "Issues and history", "tenant-web", "/examiner/work/{session}/{attempt}", "Scored attempt", "Create issue; inspect history/guidelines; resolve via Host", "Issue lifecycle and history are traceable", "Unauthorized resolve, malformed issue, duplicate resolution", "No mutation by read-only history", "No answer leakage across assignments", "Assignment + role", "Issue audit + notification",),
        ("TC-STAFF-009", "P0", "Scoring review", "Host", "Score source selection", "tenant-web", "/host/exams/{id}", "Automated and examiner score candidates", "Preview sources; apply per answer/section/cohort; inspect audit", "Chosen valid source becomes effective", "Choose missing/invalid source, repeat apply, wrong cohort", "Publication gate reflects selection completeness", "Reason/provenance retained", "Host only and exam scope", "Source-selection audit",),
    ]
    for item in staff_cases:
        add(*item)

    # Desktop exam delivery policy and every task type in the current product direction.
    app_cases = [
        ("TC-APP-001", "P0", "Exam delivery", "Student", "Login/session resolution", "pte-app", "Desktop launch", "Eligible session and valid credentials", "Login with session ID; inspect resolved candidate/exam", "Correct exam opens; wrong session is rejected", "Blank/expired/other student session", "Session is mandatory for delivery; no unrelated exam appears", "Login window may be windowed; secure secret handling", "Student/session ownership", "Attempt-start audit",),
        ("TC-APP-002", "P0", "Device check", "Student", "Test Mic and Sound", "pte-app", "After login for speaking/listening", "Microphone and speakers available/unavailable variants", "Record/play mic; play sound; pass each check", "Both readiness indicators pass and Continue is enabled", "Permission denied, no device, playback failure", "Actionable error; retry works; no task before required checks", "Window/fullscreen policy and common button style", "Attempt policy", "Device-check audit if configured",),
        ("TC-APP-003", "P0", "Exam integrity", "Student", "Exam window/lockdown", "pte-app", "Start exam with anti-cheat enabled", "Practice anti-cheat flag on/off; Windows machine", "Start protected attempt; try Alt+Tab, clipboard, resize, close", "Configured warning/audit behavior occurs; normal answer flow continues", "Shortcut/resize/close attempt; OS permission failure", "Demo policy warns and records; strict policy blocks according to contract; Finish requires submit confirmation", "Fullscreen after device check where required; login remains windowed", "Policy fixed in attempt", "Violation/lockdown audit + host notification if enabled",),
        ("TC-APP-004", "P0", "Exam delivery", "Student", "Navigation and timer", "pte-app", "Open practice and official attempts", "Practice with previous/next; official strict sequence", "Answer; next; previous where allowed; observe timer", "Practice navigation works; official restrictions remain", "Expired timer, disabled previous, repeated next", "Autosave/no lost answer; transition state clear", "Timer pause/resume and finish visibility", "Attempt owner", "Navigation/security audit as configured",),
        ("TC-APP-005", "P0", "Exam delivery", "Student", "Save and submit", "pte-app", "Active attempt with answers", "Online/offline network variants", "Save answer; disconnect; reconnect; submit; confirm finish", "Local-first answer survives and server receives once", "Duplicate submit, failed upload, missing required audio", "Retryable status; no duplicate final attempt; confirmation before finish", "Submit button/accessibility; response media binding", "Attempt owner and server state", "Answer/submit audit + scoring event",),
        ("TC-APP-006", "P1", "Exam delivery", "Student", "Report", "pte-app", "Published report", "Host has published result", "Open report; navigate skill details; logout/relogin", "Own report loads with correct scores", "Unpublished report, other attempt, revoked session", "No score leak; clear unavailable state", "10-90 score formatting and traceability", "Student owns report", "Report view audit",),
    ]
    for item in app_cases:
        add(*item)

    task_types = [
        ("Personal Introduction", "Speaking"),
        ("Read Aloud", "Speaking"),
        ("Repeat Sentence", "Speaking"),
        ("Describe Image", "Speaking"),
        ("Retell Lecture", "Speaking"),
        ("Answer Short Question", "Speaking"),
        ("Summarize Group Discussion", "Speaking"),
        ("Respond to a Situation", "Speaking"),
        ("Summarize Written Text", "Writing"),
        ("Write Essay", "Writing"),
        ("Read and Write: Fill in the Blanks", "Reading"),
        ("Multiple-choice, Choose Multiple Answers (Reading)", "Reading"),
        ("Re-order Paragraphs", "Reading"),
        ("Fill in the Blanks (Reading)", "Reading"),
        ("Multiple-choice, Choose Single Answer (Reading)", "Reading"),
        ("Summarize Written Text / task renderer contract", "Writing"),
        ("Multiple-choice, Choose Multiple Answers (Listening)", "Listening"),
        ("Fill in the Blanks (Listening)", "Listening"),
        ("Highlight Correct Summary", "Listening"),
        ("Select Missing Word", "Listening"),
        ("Highlight Incorrect Words", "Listening"),
        ("Write from Dictation", "Listening"),
        ("Summarize Spoken Text", "Listening"),
    ]
    for index, (task, skill) in enumerate(task_types, 1):
        add(
            f"TC-APP-TASK-{index:02d}",
            "P0",
            "Exam task renderer",
            "Student",
            task,
            "pte-app",
            "Start an exam containing one item of this task type",
            f"Published question with released runtime contract; skill={skill}; media/answer fixture",
            "Open item; follow preparation timer; interact with all controls; save; advance; reopen if practice",
            f"{task} renders the expected prompt/control and accepts a valid response",
            "Missing media, malformed payload, unsupported contract, timeout, invalid answer",
            "No crash or blank screen; response schema is saved/scored; unsupported type has explicit safe screen",
            "Timer, keyboard/focus, audio/image loading, responsive layout, localization",
            "Only current attempt item accessible",
            "Answer/media/scoring events; violations if policy applies",
            status="Not run",
        )

    # Standalone practice web and API.
    practice_cases = [
        ("TC-PRAC-001", "P0", "Practice auth", "Student", "Practice sign-in", "pte-practice.duckdns.org", "/sign-in", "Practice email auth enabled; mailbox/test challenge", "Enter email; request OTP; verify valid code", "Session token is issued and student home loads", "Invalid/expired/replayed OTP, blank email, rate limit", "No token in URL; generic error; challenge one-time and rate-limited", "Locale/theme persistence and refresh", "STUDENT only after verify", "Auth audit + email delivery status",),
        ("TC-PRAC-002", "P0", "Practice catalog", "Student", "Practice tests", "pte-practice.duckdns.org", "/practice-tests", "Authenticated student; active catalog", "Load catalog; inspect skills/task types; open preflight", "Only available content and capabilities are shown", "Unauthenticated, disabled task type, no entitlement", "401/403 or empty state; no catalog leak", "Loading/error/empty states; filters", "Student-scoped", "Catalog/preflight audit",),
        ("TC-PRAC-003", "P0", "Practice entitlement", "Student", "Practice access", "pte-practice.duckdns.org", "/practice-tests", "Active, expired and strict-entitlement users", "Open catalog; request entitlement with/without organization", "Allowed student can start; blocked student gets clear reason", "Expired subscription, wrong org, missing entitlement", "Fail closed; no bypass via direct API", "Reason code and retry path", "Student + organization entitlement", "Entitlement read audit",),
        ("TC-PRAC-004", "P0", "Practice session", "Student", "Practice preflight", "pte-practice.duckdns.org", "/practice-tests", "Selected skill/task and available questions", "Choose target; run preflight; start session", "Counts and compatibility pass; session is created once", "No questions, invalid target, unavailable contract", "Actionable preflight; no partial session", "Idempotency key and refresh behavior", "Student own session", "Preflight/session audit",),
        ("TC-PRAC-005", "P0", "Practice session", "Student", "Practice session", "pte-practice.duckdns.org", "/practice-tests/session", "Created practice session", "Begin; answer; skip; heartbeat; save-and-exit; resume", "Answer state and progress persist", "Wrong item ID, duplicate action, stale session, network loss", "Server validates ownership; retry is safe; no answer loss", "Timer, previous/next, progress and media", "Student own session", "Session operation audit",),
        ("TC-PRAC-006", "P1", "Practice progress", "Student", "Progress", "pte-practice.duckdns.org", "/progress", "Completed and in-progress practice sessions", "Open progress; filter/view history", "Only own progress and correct aggregates appear", "Other student ID/direct API, empty history", "No leak; useful empty state", "Date/time, score status and loading", "Student-scoped", "Progress read audit",),
        ("TC-PRAC-007", "P1", "Study pack", "Student", "Study pack", "pte-practice.duckdns.org", "/study-pack", "Authenticated student", "Open study pack; load content/media; refresh", "Content loads and links work", "Missing content/media/provider failure", "No crash; fallback and retry", "Accessibility and locale/theme", "Student-scoped", "Read metrics",),
        ("TC-PRAC-008", "P1", "Practice integrity", "Student", "Practice violation warning", "pte-practice.duckdns.org / pte-app", "Launch practice anti-cheat scenario", "Practice configured with anti-cheat warning/audit", "Trigger supported violation; continue; inspect host audit", "Warning appears and audit is recorded without auto-invalidating attempt", "Duplicate/offline violation, strict flag mismatch", "No silent loss; no unexpected force-submit in demo policy", "Reconnect deduplication and timestamp", "Attempt policy fixed", "Violation audit + host notification",),
        ("TC-PRAC-009", "P1", "Practice UI shell", "Student", "Theme and locale", "pte-practice.duckdns.org", "/sign-in or home", "Browser local storage enabled", "Switch locale/theme; reload and open a second tab", "Preference persists and accessible labels translate", "Corrupt storage, unsupported locale", "Safe fallback to default; no hydration mismatch", "Keyboard, contrast and responsive layout", "Public UI only", "No sensitive data stored",),
    ]
    for item in practice_cases:
        add(*item)

    # Cross-cutting integrations and non-functional checks.
    cross_cases = [
        ("TC-X-001", "P0", "API contract", "Any actor", "Error envelope", common_api, "Trigger validation/401/403/404/409/422/500 responses", "Local or staging API; correlation ID enabled", "Call representative endpoints with malformed and unauthorized requests", "Consistent status, machine code, message and correlation ID", "HTML error, stack trace, secret/token leak, inconsistent envelope", "Client maps errors without relying on raw backend text", "Content type, CORS, cache headers", "Role/tenant context never bypassed", "Error/audit logs contain safe identifiers only",),
        ("TC-X-002", "P0", "Notification delivery", "System", "Realtime notification", "tenant-web/vendor-web", "Keep inbox open; trigger supported event in another role", "WebSocket/SSE or polling configured; two users", "Create event; observe unread badge; open detail; mark read", "New notification appears once and read state syncs", "Disconnect/reconnect, delivery provider failure, duplicate event", "Business action succeeds independently; notification retry/status visible", "Multi-tab and ordering", "Recipient/tenant scope", "Notification log and audit",),
        ("TC-X-003", "P0", "AI scoring", "System", "Automated scoring status", common_api, "Completed eligible answer; provider stub success/failure", "AI provider abstraction configured", "Submit answer; wait success; force failure; retry/fallback examiner", "Score status and provenance update asynchronously", "Timeout, malformed provider response, duplicate callback", "No duplicate score/report; failure remains retryable", "Correlation/idempotency and queue visibility", "Attempt/organization scope", "Scoring audit",),
        ("TC-X-004", "P0", "Media integration", "System", "Audio/image delivery", "pte-app / vendor-web", "Question with Cloudinary object", "Signed upload and download path", "Upload, complete, preview, deliver to app; expire/retry URL", "Media renders/plays and refreshes URL", "Missing object, expired signature, unsupported type", "Question/exam remains traceable; no public secret", "Latency, cache and offline fallback", "Signed media access", "Media audit",),
        ("TC-X-005", "P1", "Rate limiting", "Any actor", "Login and sensitive action limits", common_api, "Open sensitive endpoint under normal and abusive rates", "Rate limiter enabled", "Repeat login/reset/webhook/submit requests above threshold", "Allowed normal rate succeeds", "Threshold returns controlled 429 and later recovers", "No account lockout bypass through alternate path", "Retry-After/correlation ID", "Keyed by safe account/source", "Security audit/metrics",),
        ("TC-X-006", "P1", "Observability", "Operator", "Health/readiness", "VPS/public domains", "/actuator/health and public root routes", "Stack running", "Check backend health, web portals, practice route and logs", "Healthy services and public routes return expected status", "One optional service unavailable", "Core portal remains diagnosable; no false healthy state", "Container restart/healthcheck", "No credentials in logs", "Operational metrics",),
        ("TC-X-007", "P1", "Deployment", "Release owner", "CI/CD workflow", "GitHub Actions", "Push to main on each repository", "Repository production env secrets configured", "Run lint/test/build/deploy/verify; inspect job dependencies", "Deployment runs only after gates and public checks pass", "Missing secret, dirty VPS checkout, concurrent deploy, failed build", "Failure stops before mutation or rolls back safely; shared lock works", "Artifact/log redaction and timeout", "SSH known-host verification", "Deployment audit",),
        ("TC-X-008", "P1", "Accessibility", "Any user", "All web forms/tables/modals", "tenant-web/vendor-web/pte-practice", "Open representative routes", "Keyboard and screen-reader test tools", "Navigate without mouse; inspect labels/focus/errors/contrast", "All critical controls reachable and announced", "Focus trap failure, unlabeled field, low contrast, clipped modal", "WCAG-oriented evidence captured", "Responsive 320px/desktop", "Role-independent UI only", "No audit",),
        ("TC-X-009", "P1", "Data integrity", "System", "Idempotent mutations", common_api, "Create/generate/publish/submit/payment callbacks", "Idempotency key/retry-capable client", "Repeat same request concurrently and sequentially", "One business outcome and one audit event where required", "Double enrollment, double payment, duplicate answer/report", "Unique constraints/state machine prevent duplication", "Race/concurrency timing", "Ownership checked on every retry", "Idempotency audit",),
        ("TC-X-010", "P1", "Performance", "Operator", "Exam generation and answer burst", "API/VPS", "Representative 500-student audience and answer burst test data", "Load tool and isolated test environment", "Run preflight/generation and concurrent answer saves", "Response/error budgets meet agreed baseline", "Timeout, queue backlog, dropped answer", "No lost answer; useful progress/failure state", "CPU/RAM/DB/queue telemetry", "Test data isolated", "Performance report",),
    ]
    for item in cross_cases:
        add(*item)

    # Fix the intentional compact identity rows to have useful text in every required column.
    for row in rows:
        if not row[11]:
            row[11] = "Operation succeeds exactly once; invalid input is rejected clearly with no partial state"
        if not row[12]:
            row[12] = "Responsive/accessibility behavior, retry/idempotency and UTC/local time handling"
    return rows


def module_rows() -> list[list[str]]:
    modules = [
        ("identity", "Auth, roles, profiles, credentials, roster import", "All portals + API + pte-app", "TC-ID-001..012", "P0"),
        ("tenancy", "Organization lifecycle, branding, suspension, quota", "vendor-web + tenant-web + API", "TC-ID-002, TC-ID-011, TC-HOST-001", "P0"),
        ("enrollment", "Programs, classes, membership, lecturer assignments", "tenant-web + API", "TC-HOST-006..008", "P0"),
        ("itembank", "Questions, revisions, task types, media readiness", "vendor-web + API", "TC-ADM-001..006", "P0"),
        ("media", "Signed upload, completion, preview and delivery", "vendor-web + pte-app + API", "TC-ADM-005, TC-X-004", "P0"),
        ("scoretemplate", "Scoring template lifecycle and feasibility", "vendor-web + API", "TC-ADM-007", "P0"),
        ("assessment", "Blueprint/snapshot and fixed exam contract", "vendor-web + API", "TC-ADM-008, TC-HOST-012..013", "P0"),
        ("billing", "Plans, orders, PayOS, licenses, subscriptions", "vendor-web + tenant-web + API", "TC-BIL-001..006", "P0"),
        ("session", "Exam draft, audience, generation, schedule, lifecycle", "tenant-web + API", "TC-HOST-010..016", "P0"),
        ("attempt", "Preflight, next task, navigation, answer save/submit", "pte-app + API", "TC-APP-001..006", "P0"),
        ("proctoring", "Attendance, monitoring, incidents, security audit", "tenant-web + pte-app + API", "TC-STAFF-001..005, TC-PRAC-008", "P0"),
        ("examstaff", "Staff workspace and assignment visibility", "tenant-web + API", "TC-HOST-009, TC-STAFF-006", "P0"),
        ("scoring", "Examiner assignment/work and Host source selection", "tenant-web + API", "TC-HOST-018..019, TC-STAFF-006..009", "P0"),
        ("reporting", "Aggregation, publication and student report", "tenant-web + pte-app + API", "TC-HOST-019..020, TC-APP-006", "P0"),
        ("practice", "Practice auth/catalog/entitlement/session/progress", "pte-practice + API", "TC-PRAC-001..009", "P0"),
        ("notification", "Inbox, announcements, realtime and delivery logs", "tenant-web/vendor-web + API", "TC-ADM-012..013, TC-X-002", "P1"),
        ("support", "Host/admin tickets and notes", "tenant-web/vendor-web + API", "TC-ADM-014", "P1"),
        ("overview", "Admin/Host/Student dashboards", "tenant-web/vendor-web + API", "TC-ADM-010, TC-HOST-001", "P1"),
        ("audit/shared", "Audit, error envelope, idempotency, rate limit", "All channels + API", "TC-ADM-011, TC-X-001, TC-X-005, TC-X-009", "P0"),
    ]
    return [list(row) for row in modules]


def data_rows() -> list[list[str]]:
    return [
        ["Account set", "Platform Admin, Platform Author, Host A, Host B, Proctor A, Examiner A, Student A/B", "Create in local/staging only; never put credentials in workbook", "Needed for role and tenant isolation"],
        ["Organization set", "Active, pending, rejected and suspended organizations", "Use unique generated codes/emails", "Onboarding, suspension and access tests"],
        ["Question set", "At least 2 valid questions per task type; text/image/audio variants; draft/published/rejected", "Use seed files/local question bank", "Renderer, media, publication and exam generation"],
        ["Template set", "Full four-skill template; one item per task type; invalid and retired versions", "Template must use released runtime contracts", "Preflight and snapshot immutability"],
        ["Exam set", "Practice with timer/navigation/retry/anti-cheat warning; Mock; Official strict", "Use separate schedule windows and licenses", "Delivery policy comparison"],
        ["Staff set", "Assigned/unassigned proctor and examiner; two exams/two organizations", "Keep assignments explicit", "Staff access boundary"],
        ["Billing set", "Active/expired/revoked code, pending/paid/canceled order, quota exhaustion", "PayOS can be stubbed in local", "Payment and capacity gate"],
        ["Failure fixtures", "Expired media URL, provider timeout, duplicate callback, disconnected browser/app", "Use mocks or controlled network tooling", "Retry and idempotency"],
        ["Evidence", "Screenshot, URL, request/correlation ID, response status, audit ID", "Mask personal data and secrets", "Reproducible defect triage"],
    ]


def environment_rows() -> list[list[str]]:
    return [
        ["Local API", "http://localhost:8091", "Backend/actuator via Docker", "Use .env.local; no production data"],
        ["Local tenant web", "http://localhost:3000", "Organization portal: Host/Proctor/Examiner/Student web", "Start from pte-web workspace"],
        ["Local vendor web", "http://localhost:3001", "Platform Admin/Author portal", "Start from pte-web workspace"],
        ["Local practice", "http://localhost:3014", "Standalone student practice web", "Use pte-practice npm scripts"],
        ["Desktop exam client", "pte-app Windows desktop", "Student exam delivery, device check, lockdown", "Use local API/session fixture"],
        ["Production tenant", "https://pte-tenant.duckdns.org", "Hosted organization portal", "Read-only smoke unless explicit test window"],
        ["Production vendor", "https://pte-admin.duckdns.org", "Hosted platform admin portal", "Read-only smoke unless explicit test window"],
        ["Production practice", "https://pte-practice.duckdns.org", "Hosted practice web", "Public route verified; business flow needs test account"],
        ["API public edge", "Same-origin /api/v1", "Nginx to modular monolith", "Do not expose internal port or secrets"],
        ["CI/CD", "GitHub Actions", "Validation, deploy and public verification", "Production environment secrets are not in workbook"],
    ]


def make_sheet_xml(rows: list[list[object]], widths: list[int], freeze: str = "A2", filter_end: str | None = None) -> str:
    max_cols = max((len(row) for row in rows), default=1)
    last_col = col_letter(max_cols)
    last_row = len(rows)
    parts = [
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
        f'<dimension ref="A1:{last_col}{last_row}"/>',
        '<sheetViews><sheetView workbookViewId="0">',
        f'<pane ySplit="1" topLeftCell="{freeze}" activePane="bottomLeft" state="frozen"/>' if freeze else "",
        '<selection pane="bottomLeft" activeCell="A2" sqref="A2"/>',
        '</sheetView></sheetViews>',
        '<sheetFormatPr defaultRowHeight="18"/>',
        '<cols>',
    ]
    for index, width in enumerate(widths, 1):
        parts.append(f'<col min="{index}" max="{index}" width="{width}" customWidth="1"/>')
    parts.append('</cols><sheetData>')
    for row_index, row in enumerate(rows, 1):
        parts.append(f'<row r="{row_index}">')
        for col_index, value in enumerate(row, 1):
            ref = f"{col_letter(col_index)}{row_index}"
            style = 1 if row_index == 1 else (2 if col_index in (1, 2, 16) else 0)
            if isinstance(value, tuple) and value[0] == "formula":
                parts.append(f'<c r="{ref}" s="{style}"><f>{xml_text(value[1])}</f><v>0</v></c>')
            else:
                parts.append(f'<c r="{ref}" s="{style}" t="inlineStr"><is><t xml:space="preserve">{xml_text(value)}</t></is></c>')
        parts.append('</row>')
    parts.append('</sheetData>')
    if filter_end:
        parts.append(f'<autoFilter ref="A1:{filter_end}{last_row}"/>')
    parts.append('</worksheet>')
    return "".join(parts)


def build_workbook() -> None:
    cases = build_cases()
    api_rows = scan_api_endpoints()
    route_rows = scan_routes()
    flutter_rows = scan_flutter_screens()
    modules = module_rows()
    data = data_rows()
    environments = environment_rows()

    summary = [
        ["PTE Org comprehensive test workbook", "Prepared 2026-10-21", "Source review + executable test scenario baseline"],
        ["Scope", "Registration → organization approval → content/template → billing → exam → pte-app → proctor/examiner → scoring → report publication → practice", ""],
        ["How to use", "Execute P0 first, then P1; fill Execution status, Actual result, Evidence and Defect ID in Test Cases", ""],
        ["Test cases", ("formula", "COUNTA('Test Cases'!A2:A1000)"), "Business and cross-cutting cases"],
        ["P0 cases", ("formula", 'COUNTIF(\'Test Cases\'!B2:B1000,"P0")'), "Release-blocking path"],
        ["Passed", ("formula", 'COUNTIF(\'Test Cases\'!P2:P1000,"Passed")'), "Update status only after evidence is attached"],
        ["Failed / blocked", ("formula", 'COUNTIF(\'Test Cases\'!P2:P1000,"Failed")+COUNTIF(\'Test Cases\'!P2:P1000,"Blocked")'), "Investigate before release claim"],
        ["API endpoint inventory", ("formula", "COUNTA('API Endpoint Coverage'!A2:A1000)"), "Automatically extracted from controller mappings"],
        ["UI route inventory", ("formula", "COUNTA('UI Route Coverage'!A2:A1000)"), "Automatically extracted from Next.js pages"],
        ["Flutter screen inventory", ("formula", "COUNTA('Flutter Screen Coverage'!A2:A1000)"), "Automatically extracted from Dart screen/page classes"],
        ["Evidence boundary", "This workbook is a test plan and source-derived coverage review. It does not claim that every case has been executed.", ""],
        ["No secrets", "No passwords, private keys, access tokens or .env values are included.", ""],
    ]

    test_rows = [HEADERS] + cases
    api_headers = ["HTTP", "Endpoint", "Controller", "Source file", "Coverage expectation"]
    route_headers = ["Application", "Route", "Source page", "Coverage expectation"]
    flutter_headers = ["Application", "Screen classes", "Source file", "Coverage expectation"]
    module_headers = ["Backend/module", "Scope", "Channels", "Mapped cases", "Minimum priority"]
    data_headers = ["Fixture group", "Required data", "Preparation rule", "Used for"]
    environment_headers = ["Environment", "Base URL / channel", "Purpose", "Safety note"]
    defect_headers = ["Defect ID", "Case ID", "Severity", "Summary", "Reproduction", "Expected", "Actual", "Status", "Owner", "Evidence"]
    defect_rows = [defect_headers, ["BUG-", "TC-", "P0/P1/P2/P3", "", "", "", "", "Open", "", ""]]
    verification_headers = ["Check", "Target", "Observed status", "Evidence", "Boundary"]
    verification_rows = [
        verification_headers,
        ["Workbook archive/XML", "261021-pte-org-comprehensive-test-scenarios.xlsx", "PASS", "ZIP integrity and core XML parsed successfully", "File-format validation only"],
        ["Public practice home", "https://pte-practice.duckdns.org/", "PASS / HTTP 200", "Read-only request on 2026-10-21", "Route availability, not authenticated business flow"],
        ["Public practice sign-in", "https://pte-practice.duckdns.org/sign-in", "PASS / HTTP 200", "Read-only request on 2026-10-21", "Screen availability only"],
        ["Public tenant portal", "https://pte-tenant.duckdns.org/", "PASS / HTTP 200", "Read-only request on 2026-10-21", "Screen availability only"],
        ["Public vendor portal", "https://pte-admin.duckdns.org/", "PASS / HTTP 200", "Read-only request on 2026-10-21", "Screen availability only"],
        ["Backend public health route", "https://pte-tenant.duckdns.org/actuator/health", "PASS / HTTP 200", "Read-only request on 2026-10-21", "Health route only; no authenticated business operation"],
        ["Practice API authentication gate", "https://pte-practice.duckdns.org/api/v1/student/practice/catalog", "PASS / HTTP 401", "Unauthenticated read-only request on 2026-10-21", "Confirms protected route; valid student flow still needs execution"],
    ]

    sheets = [
        ("Read me", summary, [30, 80, 55], "A1", None),
        ("Test Cases", test_rows, [18, 10, 24, 18, 28, 25, 34, 45, 54, 45, 48, 55, 50, 43, 43, 18, 35, 35, 15, 30], "A2", "T"),
        ("Module Coverage", [module_headers] + modules, [22, 55, 42, 35, 16], "A2", "E"),
        ("API Endpoint Coverage", [api_headers] + api_rows, [10, 52, 32, 70, 72], "A2", "E"),
        ("UI Route Coverage", [route_headers] + route_rows, [18, 40, 75, 62], "A2", "D"),
        ("Flutter Screen Coverage", [flutter_headers] + flutter_rows, [18, 48, 78, 66], "A2", "D"),
        ("Test Data Matrix", [data_headers] + data, [25, 72, 55, 50], "A2", "D"),
        ("Environment Matrix", [environment_headers] + environments, [24, 45, 60, 68], "A2", "D"),
        ("Defect Log", defect_rows, [18, 18, 14, 45, 60, 45, 45, 18, 22, 40], "A2", "J"),
        ("Verification Log", verification_rows, [28, 62, 20, 62, 58], "A2", "E"),
    ]

    content_types = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
""" + "\n".join(
        f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        for i in range(1, len(sheets) + 1)
    ) + "</Types>"

    workbook = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<fileVersion appName="xl"/>
<sheets>
""" + "\n".join(
        f'<sheet name="{xml_text(name)}" sheetId="{i}" r:id="rId{i}"/>' for i, (name, *_rest) in enumerate(sheets, 1)
    ) + """
</sheets>
<calcPr calcMode="auto" fullCalcOnLoad="1" forceFullCalc="1"/>
</workbook>"""

    workbook_rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
""" + "\n".join(
        f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>'
        for i in range(1, len(sheets) + 1)
    ) + "</Relationships>"

    styles = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2"><font><sz val="10"/><name val="Aptos"/></font><font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Aptos"/></font></fonts>
<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF1F4E78"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="0" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="0" fillId="0" borderId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf></cellXfs>
</styleSheet>"""

    root_rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>"""

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(OUTPUT, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("[Content_Types].xml", content_types)
        archive.writestr("_rels/.rels", root_rels)
        archive.writestr("xl/workbook.xml", workbook)
        archive.writestr("xl/_rels/workbook.xml.rels", workbook_rels)
        archive.writestr("xl/styles.xml", styles)
        for index, (_name, rows, widths, freeze, filter_end) in enumerate(sheets, 1):
            archive.writestr(
                f"xl/worksheets/sheet{index}.xml",
                make_sheet_xml(rows, widths, freeze, filter_end),
            )

    print(f"Created {OUTPUT}")
    print(f"Test cases: {len(cases)}")
    print(f"API endpoints: {len(api_rows)}")
    print(f"UI routes: {len(route_rows)}")
    print(f"Flutter screen files: {len(flutter_rows)}")
    print(f"Modules: {len(modules)}")


if __name__ == "__main__":
    build_workbook()
