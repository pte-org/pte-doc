# Phase 05: Host corrections and delivery review

Status pending; dependencies01–04. P1 Host correction; P2 history. FR04,06–12.

## Design Constraints

Host uses own tenant authority, not Proctor impersonation. CLOSED attendance correction only administrative metadata; no exam reopen/start/score/cohort/report changes. Avoid permission reuse from another role's cached response.

## Files and steps

- [x] Extend features/exams/components/ExamDetailTabs.tsx tab union/allowlist/items/panel for attendance and add focused AttendanceTab component using Host API hooks. Existing host/exams/[publicId] route and ?tab=attendance back/forward behavior retained.
- [x] Share domain-neutral roster/status/history components where sensible; role-specific capability and actions remain explicit. Host always supplies reason for correction, including reset. Historical removed-enrollment events remain readable with safe labels; no phantom current-roster rows or edits resurrect membership.
- [x] Both role APIs have equivalent versions/canonical statuses/summary logic and own actor cache keys; denied/current-session-state responses mapped to localized UI. Closed Proctor roster remains readable with disabled changes, Host CLOSED correction enabled only via Host surface.
- [x] Review final source against attendance no-side-effects constraint: start entitlement, attempt lifecycle, STOMP, grading/publication and feature flags unchanged. Verify EnrollmentService locking edits are minimal and preserve authorization/deletion behavior.
- [x] Planned checks under current preference: backend Maven -pl app -am -DskipTests compile; API-client typecheck; tenant direct tsc --noEmit --incremental false, scoped lint and tenant build. Avoid pnpm implicit dependency repair during verification; if frozen lockfile is inconsistent report it and use direct installed tools without claiming reproducible CI install.
- [x] Final code-review independent if agents available; otherwise record direct review and its limits, never label it independent. Record commands/exits, incremental vs clean compile, migration/native-query/runtime unverified. No tests/E2E/quality invocation under prior skip preference.
- [x] Delivery notes state co-release of attendance schema/backend/client, next migration number, no historic attendance auto-backfill, feature flag unchanged, rollback boundary and enrollment-generation handling. No deploy, live SQL, automatic commit/push or data repair in scope.

## Acceptance evidence

Host-only CLOSED correction with required reason/audit; read-only Proctor; preserved published grade snapshots; history retained after reset/unenroll; no duplicate audit for exact retry; one active sidebar item; canonical wire DTOs; baseline role navigation preserved.

## Quality and Testing State

Quality not evaluated; testing not started; prior skip. Compile/lint/typecheck/build planned only; not performed in planning. Runtime/race/schema validity cannot be inferred from passing build.
