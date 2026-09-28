# Phase 02 — Tenant Web Policy Setting, Review, and Detail

**Depends on:** Phase 1  
**Enables:** host configuration and release walkthroughs  
**Stories:** P1 Practice configuration; P1 Official strictness; P2 policy visibility

## Objective

Expose a clear Practice-only anti-cheat checkbox in the tenant Create Exam
workflow, map that boolean to the canonical `lockdownMode` request field, and
show the persisted policy in the review and exam detail surfaces.

## Exact files/packages likely to change

- `pte-web/packages/api-client/src/types/scheduling/index.ts`
- `pte-web/packages/api-client/src/requests/scheduling/examOrchestration.ts`
- `pte-web/apps/tenant-web/features/exams/types/index.ts`
- `pte-web/apps/tenant-web/features/exams/api/index.ts`
- `pte-web/apps/tenant-web/features/exams/constants/index.ts`
- `pte-web/apps/tenant-web/features/exams/utils/validateCreateExamWorkflow.ts`
- `pte-web/apps/tenant-web/features/exams/components/CreateExamWizard.tsx`
- `pte-web/apps/tenant-web/features/exams/components/SessionDetailView.tsx`
- existing API-client/component test files if the repository has a matching
  test location; otherwise add a focused test beside the existing scheduling
  request tests without changing unrelated UI.

## Implementation steps

1. Extend shared scheduling types with the existing `LockdownMode` union and
   add it to canonical draft create/patch request types and `SessionResponse`
   policy mapping. Keep nullable handling explicit for legacy responses.
2. Update the exam orchestration request helper to serialize `lockdownMode`.
   The tenant feature's `CreateExamWorkflowInput` keeps a boolean
   `practiceAntiCheatEnabled` for form ergonomics and derives the enum at the
   API boundary.
3. Initialize the checkbox to off for Practice. When the host changes to
   Official, clear/ignore the boolean and derive `STRICT`; when switching back
   to Practice, restore the safe unchecked default unless the current draft
   explicitly has a valid Practice policy.
4. Render the checkbox only when `examMode === "PRACTICE"`. Label it in plain
   language, explain that it enables fullscreen and existing desktop checks,
   and explicitly state that violations warn/audit without auto-submitting in
   Practice.
5. Add a review row that says exactly one of `Practice — unrestricted`,
   `Practice — controlled desktop`, or `Official — strict`. Derive the row from
   the same enum that is sent, not from a duplicated label-only boolean.
6. Map the returned `SessionResponse.policy.lockdownMode` into
   `SessionDetailView`. The detail screen must show the persisted server value,
   including the policy received after publish/open, and should not report the
   local form value after the request completes.
7. Add validation/error handling for a server-side policy mismatch. The UI may
   prevent the normal mismatch, but it must surface a backend validation error
   instead of claiming the exam was created with the requested setting.
8. Keep the existing skill-selection and retry controls unchanged. The new
   checkbox must not alter selected skills, retry count, timer, form mode, or
   template generation.

## Request and response contract

The form state is intentionally not persisted as a second boolean:

```text
practiceAntiCheatEnabled: false -> request.lockdownMode = "NONE"
practiceAntiCheatEnabled: true  -> request.lockdownMode = "STANDARD"
examMode: OFFICIAL_EXAM         -> request.lockdownMode = "STRICT"
```

The request is sent on the canonical draft create/update path, not the legacy
session endpoint. Detail consumes `SessionResponse.policy.lockdownMode`.

## Dependencies and handoff

- Phase 1 must define the enum serialization and validation behavior first.
- Phase 3 may add host security-audit data later, but this phase only displays
  the policy and does not redesign an audit screen.
- Phase 5 uses this UI to create the three release verification scenarios.

## Acceptance criteria

- [x] Practice displays an anti-cheat checkbox; Official does not display a
  Practice control.
- [x] Unchecked Practice submits `lockdownMode: "NONE"`.
- [x] Checked Practice submits `lockdownMode: "STANDARD"`.
- [x] Official submits/resolves `lockdownMode: "STRICT"` regardless of any
  stale local checkbox state.
- [x] Review and detail show the selected/persisted policy using distinct labels.
- [x] A server rejection is visible and does not insert a false success state.
- [x] Existing skills, retries, timer, template, audience and generation fields
  retain their previous values and behavior.
- [x] Legacy detail responses with a null policy are rendered using the
  documented compatibility label, never as controlled enforcement.

**Status:** Complete after hard-checkpoint confirmation.

## Design Constraints

- **Preflight:** The shared client already has the `LockdownMode` union for the
  legacy session request, but draft request types, `SessionResponse.policy`,
  tenant form state, and detail mapping do not yet carry the canonical policy;
  this phase adds those links without changing the legacy request path.
- The browser maps a boolean to the canonical enum; it does not add a database
  field or create a new policy vocabulary.
- `STRICT` is not a Practice option and is not selectable in the UI.
- Server response is authoritative after create/publish/detail refresh.
- Use the existing tenant-web controls, labels, validation and API-client
  conventions; do not redesign the exam wizard.
- Accessibility: the checkbox needs a visible label, helper text association,
  keyboard operation, focus state, and a clear review label.
- Do not alter exam mode, skill scope, retries, timer, navigation, scoring or
  report publication behavior.

## Quality and Testing State

**Quality:** approved; no blocking findings. Report: `quality/phase-02-tenant-web-policy-setting-and-detail-quality-report.json`. Receipt: `quality/phase-02-tenant-web-policy-setting-and-detail-receipt.json`.  
**Testing:** passed; API-client suite 324/324, shared/API and tenant typechecks passed, and tenant production build passed. Tenant lint remains a documented pre-existing baseline failure. Report: `tests/phase-02-tenant-web-policy-setting-and-detail-test-report.json`.

Required verification after implementation:

- API-client serialization tests for `NONE`, `STANDARD`, and `STRICT`.
- Wizard interaction tests for mode switching, checkbox visibility, review text,
  and server validation errors.
- Detail mapping test proving the display uses response policy.
- Browser walkthrough with an authenticated host for Practice unchecked,
  Practice checked, and Official.
- Run the repository's focused web lint/typecheck/test commands; do not claim
  a full web suite unless it was actually run.
