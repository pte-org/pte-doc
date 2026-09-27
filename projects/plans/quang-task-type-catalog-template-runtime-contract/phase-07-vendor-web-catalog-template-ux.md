# Phase 7: Vendor-Web Catalog, Template UX, and Friendly Errors

## Objective

Make vendor-web describe the real capability accurately: Platform users choose
supported PTE task types and configure template versions; they do not invent a
new runtime interaction from a form. Preserve the old API through a client
adapter and centralize user-facing messages.

## Files

- `pte-web/apps/vendor-web/features/questiontemplate/`
- `pte-web/apps/vendor-web/features/scoretemplate/`
- `pte-web/apps/vendor-web/features/**/constants.ts` for owning messages
- `pte-web/packages/api-client/src/requests/questiontype/`
- `pte-web/packages/api-client/src/types/questiontype/`
- focused component, API-client and browser smoke tests

## Implementation steps

1. Add a feature-owned constants module for catalog/template labels, empty
   states, confirmations, alerts and API-error fallbacks. TSX must call these
   constants rather than embedding repeated user-facing strings.
2. Introduce task-type/catalog naming in API-client and vendor-web types/services
   while keeping `/api/v1/question-types`, old request functions and old query
   keys available during migration. Add optional runtime/profile/readiness
   fields without making old callers require them.
3. Update the Question Type screens/modal to “Task Type Catalog” / “Task Type”:
   - choose only server-supported standard codes;
   - explain that a new interaction/scoring behavior requires a platform release;
   - preserve role-allowed presentation/lifecycle actions;
   - use friendly, constant-backed error/confirmation messages.
4. Update `ScoreTemplateEditorView` to use persisted active catalog rows and
   server readiness:
   - retain section-first filtering;
   - distinguish no active catalog rows, all active rows already used and an
     incompatible runtime profile;
   - show actionable diagnostics before submit/activate;
   - never bypass server activation validation.
5. Map catalog/template, profile, retired-task and capability errors to
   non-technical copy. Keep machine codes available for telemetry and logic but
   do not render them as the primary message.
6. Preserve Platform Author/Admin route and permission semantics. Invalidate
   old and new query keys during the adapter window, then document deprecation
   rather than removing compatibility opportunistically.

## Acceptance criteria

- Admin/Author sees Task Type Catalog language and understands the
  standard-code-only boundary.
- The template dropdown is populated after backfill and gives an actionable
  explanation in each empty/incompatible state.
- Client-side manipulation cannot bypass server profile/activation validation.
- Changed TSX files use feature constants for all user-visible messages,
  alerts, confirmations and error fallbacks.
- Old API-client callers compile and existing routes/role checks work.
- Raw machine codes such as `EXAM_REQUIRES_APP_UPDATE` are not primary UI copy.

## Design Constraints

- Do not rename the BE endpoint/table in this phase.
- The browser is not the source of truth for supported tasks, capabilities or
  activation rules.
- Preserve the current visual/layout structure; this phase is semantic and
  contract UX, not an unrelated redesign.
- Keep constants near the owning feature, not in a giant unrelated global file.
- Preserve tenant isolation and query cache behavior.

## Quality and Testing State

Status: implemented and verified on 2026-09-22. Vendor-web now presents the
standard PTE task-type catalog, keeps the old question-type API/query contract
through additive aliases, filters new template rows by active runtime
readiness, and maps catalog/template/profile failures to feature-owned friendly
copy. Platform Author/Admin visibility and activation permissions remain
unchanged; the server remains the final validation authority.

The editor distinguishes an empty active catalog, a section whose active rows
are already used, and rows whose explicit runtime profile is not usable. It
keeps legacy responses without runtime metadata selectable during the additive
compatibility window, while blocking activation when a selected row is missing
or has an incompatible profile.

Automated evidence is recorded in:

- `tests/phase-07-vendor-web-catalog-template-ux-test-report.json`
- `quality/phase-07-vendor-web-catalog-template-ux-quality-report.json`
- `quality/phase-07-vendor-web-catalog-template-ux-receipt.json`

The vendor-web package has no dedicated component-test runner in its package
configuration. Its changed TSX was type-checked by the production Next build,
linted, and reviewed with static assertions for constant-backed copy and raw
machine-code suppression. Authenticated browser smoke remains deferred until a
local authenticated account/dev-server flow is available; it is rechecked in
Phase 8.

Required before phase completion:

- API-client type/serialization and adapter/query-key tests.
- Component tests for catalog, dropdown, readiness, role and friendly-error
  states; assertion that raw machine codes are not rendered.
- Authenticated browser smoke flow: catalog → draft → task selection → submit
  and the activation permission boundary.
- Run configured TypeScript/typecheck, lint and vendor-web build commands.
- Mandatory `ck:quality --gate` receipt covering UX correctness, constants,
  permissions, API compatibility and stale-query behavior.
