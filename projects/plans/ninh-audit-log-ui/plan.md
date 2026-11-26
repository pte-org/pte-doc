# Host audit log UI (tenant-web /host/audit-log)

Status: done (frontend only)

Backend facts: audit_logs keeps a stable `action` code, `resource_name/code`, a fixed English `summary` (<=500 chars) and before/after JSON that the API does not return. No structured metadata for the summary, so the web maps action + the sentence shape (utils/auditSummary.ts); unknown sentences are shown as stored.

- Action column: all known actions translated (VI/EN) + a colour dot (create green, update blue, close grey).
- Summary column: localized (exam state change, audience sources 1 source/n sources, class/program wording from the org's own labels, ticket events); repeats of the resource name show an em dash; no sort arrow.
- Actor: nil actor id (scheduler) shows a "System" badge instead of "Unknown".
- Resource: two lines for every type (name / type · code); support ticket shows #ID, class/program names are lifted from the summary; exams and tickets link to their pages (classes cannot: the log has no program id).
- Time: two lines, 4-digit year, seconds kept, tabular-nums. Search placeholder shortened.
- Bug fixed: the Class filter sent "StudentClass" but the backend writes "TrainingClass".
- Not done: translating the log in the admin portal (vendor-web), structured metadata in the backend.
