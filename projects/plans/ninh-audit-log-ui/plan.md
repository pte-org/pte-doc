# Host audit log UI (tenant-web /host/audit-log)

Status: done (frontend only)

Backend facts: audit_logs keeps a stable `action` code, `resource_name/code`, a fixed English `summary` (<=500 chars) and before/after JSON that the API does not return. No structured metadata for the summary, so the web maps action + the sentence shape (utils/auditSummary.ts); unknown sentences are shown as stored.

- Action column: all known actions translated (VI/EN) + a colour dot (create green, update blue, close grey).
- Summary column: localized (exam state change, audience sources 1 source/n sources, class/program wording from the org's own labels, ticket events); repeats of the resource name show an em dash; no sort arrow.
- Actor: nil actor id (scheduler) shows a "System" badge instead of "Unknown".
- Resource: two lines for every type (name / type · code); support ticket shows #ID, class/program names are lifted from the summary; exams and tickets link to their pages (classes cannot: the log has no program id).
- Time: two lines, 4-digit year, seconds kept, tabular-nums. Search placeholder shortened.
- Bug fixed: the Class filter sent "StudentClass" but the backend writes "TrainingClass".
- Admin portal (vendor-web /admin/audit-log) now uses the same logic. The mapper moved to @pte/api-client (src/audit: labels, summary rules, describeAuditEntry, formatAuditTime); each app only adds its columns hook and links (tenant: exam, ticket; admin: ticket, tenant, application, question).
- Added admin-specific wording: application review, license grant (contract + start date, no ids), question draft/publish, host score template. "(0 already in)" is hidden when nobody was skipped.
- Decided not to do: structured metadata in the backend; links for class/program (the log has no program id).
- "Unknown actor" in the admin log: the seed account seed.admin@test.local has no full name in the DB, so the platform user directory returned a null name. UserDirectoryEntryResponse.from(user) now falls back to the username (platform and host directories). A host admin of another organization is not in the platform directory, so it can still read "Unknown" in the admin log.
