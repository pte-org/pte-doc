# Archive lifecycle cleanup — local handoff

Date: 2026-10-05. Uncommitted, not deployed. Phases 01–04 implemented; phase 05 checks executed but not complete. Full backend regression fails on 11 pre-existing cases; release readiness is not approved.

## Behavior changes

- Plan DRAFT: Delete draft only when unused, with no order/subscription/license reference in any state. Soft delete retains DB row and audit; no restore UI. Repeat authorized deletion returns 204 without a second audit.
- Plan ACTIVE: Archive means retirement from new purchases/issuance, not cancellation of subscriptions. Outstanding ISSUED codes without expiry or with future expiry block Archive and entitlement edits. ACTIVE plan family/type cannot change; create another plan instead. Metadata/price edits remain under existing validation.
- Plan ARCHIVED: read-only. No historical rows rewritten or bulk cleanup.
- Question new never-published original DRAFT: Delete draft replaces Archive. Revision-linked drafts and restored/published/unknown history cannot be deleted. PENDING_APPROVAL has neither Archive nor Delete.
- Question APPROVED or known published-history DRAFT: Archive remains. Published snapshots and media are retained. Existing restore/revision restrictions remain.
- Tenant Program/Class: user-facing Archive becomes Remove. Existing routes, soft-delete behavior and child/membership guards remain unchanged. No broad UI redesign.
- Confirmation remains open on error, displays the server message, disables dismissal/submission while pending, and refetches capabilities after conflicts. Missing server capabilities fail closed.

## Migration and rollout (instructions only — not executed on live environments)

1. Validate and resolve the full regression gate and run authenticated browser/API smoke checks before deployment.
2. Apply backend migration V77 with backend release before or atomically with the web release. `ever_published` is nullable: legacy APPROVED becomes true; legacy DRAFT/ARCHIVED remain unknown. New drafts are explicitly false.
3. PostgreSQL trigger preserves publication history monotonically, including old application writers that only know `status`. Do not default unknown legacy data to false.
4. New DELETE endpoints return empty 204; normal reads hide tombstones; history paths retain their data. Refresh old browser tabs after rollout. An old UI attempting to archive a new draft now receives a controlled conflict.
5. Do not bulk delete old drafts, media, orders, licenses or subscriptions. Unknown-history cleanup requires separate evidence/approval.

## Rollback

- UI rollback: keep V77, tombstones and audit intact. No undelete or reverse migration.
- Do not roll back the backend to a version that ignores tombstones/guards: an older backend could show removed drafts or allow previously blocked actions. Prefer a forward fix or explicit compatible rollback build retaining these protections.
- Keep the monotonic DB trigger. Do not drop the provenance column or reset published history.
- No production rollback or deployment has been authorized or performed.

## Known boundaries

- UI browser checks use mocked authentication/API fixtures; they are not live JWT authorization E2E.
- Question concurrency evidence covers delete/submit and stale version writes, not all publish/revision interleavings.
- Program/Class backend semantics and races were not redesigned.
- PostgreSQL test container and clean-HEAD worktree are isolated temporary fixtures, not development/production data.
