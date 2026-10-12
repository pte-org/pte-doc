# Phase 06: Quality and handoff

**Status:** Skipped by explicit user request; manual UI review remains pending
**Surface:** `pte-api`, `pte-web`, `pte-doc`
**Depends on:** Phases 01–05
**Outcome:** Verified implementation handoff, not deployment

## Goal

Run the agreed focused test/build and quality gates; record what is proven and what remains outside the validation boundary; then hand off the implementation and manual UI checklist without claiming production readiness beyond the evidence.

## Work items

1. Run focused backend unit/API contract tests for the new endpoints.
2. Run API-client and frontend component tests for requests, mutation invalidation, tabs, forms, score states, and history.
3. Run tenant-web lint, `tsc --noEmit`, build, and `git diff --check`.
4. Hand off the manual UI checklist to the user for roster-to-new-tab navigation, account-first tab order, profile edit, suspend/reactivate, credential generation, overview states, history filters/pagination, forbidden/not-found, responsive layout, and light/dark themes.
5. Use focused request/component checks to verify bounded requests and absence of per-row report fan-out where practical.
6. Run independent `ck:quality` review on changed source and address blocker/high findings before completion.
7. Review the final diff for accidental edits to unrelated user worktree changes.
8. Update the plan status and record exact commands, results, timestamps, and validation limitations.

## Design Constraints

- A passing typecheck/build is not browser or production proof.
- A focused test/build is not proof of deployed PostgreSQL, HTTP authorization, browser behavior, or release behavior unless those environments were actually exercised.
- Do not reset, discard, or overwrite unrelated worktree changes.
- Do not commit, push, deploy, or mutate production data as part of this phase unless separately requested.
- Record failed or skipped checks honestly with the reason and impact.

## Quality and Testing State

This phase was not run as a quality/test gate because the user requested code-only execution. Build/typecheck evidence and limitations are recorded in the master plan; manual UI review belongs to the user. Quality approval remains separate from implementation and was not granted.

## Handoff checklist

- [ ] Contract decisions from Phase 01 are reflected in code and docs.
- [ ] Backend authorization and tenant isolation are tested.
- [ ] Backend queries are bounded and no N+1/per-row report fan-out remains.
- [ ] Profile update allowlist and secret-handling behavior are tested.
- [ ] New-tab route and account-first tabs are manually reviewed by the user.
- [ ] Overview score semantics and unavailable states are manually reviewed by the user.
- [ ] History date/status filters and pagination are manually reviewed by the user.
- [ ] Tenant-web lint/typecheck/build pass or exceptions are recorded.
- [ ] `ck:quality` returns an acceptable result with findings addressed.
- [ ] Final diff and unrelated worktree changes are reviewed.

## Acceptance criteria

- The handoff report separates implemented, focused-tested, quality-reviewed, manually UI-reviewed, and unverified claims.
- Any remaining open decision is visible and blocks release rather than being silently assumed.
- The plan status is updated only after the required evidence exists.
