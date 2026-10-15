# Plan: Tenant Exam UI decomposition

**Spec:** [spec.md](spec.md)
**Mode:** Hard
**Test:** default (TDD not enabled)
**Scope:** `pte-web` presentation layer only
**Status:** Phase 04 in progress; Phases 01–03 completed after hard-mode human confirmation

## Scope challenge

- **Exists?** Yes. The detail screen, create wizard, shared Tabs/Stepper, and all
  related API hooks already exist. The work is decomposition and presentation
  composition, not a new Exam capability.
- **Minimum:** Add task-oriented tab composition and a clearer create wizard while
  reusing every existing query, mutation, validation rule, modal, and role boundary.
- **Complexity:** Hard — several feature components, retained tab state, theme/locale
  safety, and Host/Examiner separation must be preserved.
- **No API change:** No backend, database, API-client, scoring, authentication, or
  session lifecycle changes are included.

## Invariants

1. `SessionDetailView` remains the owner of session lifecycle mutations and error
   handling; tab components receive the existing session ID/status and callbacks.
2. Existing query keys, hooks, status guards, preflight checks, invalidation behavior,
   and modal entry points remain unchanged.
3. Student submissions remain separate from Examiner assignment/scoring workflow.
4. Examiner blind marking remains on `/examiner/work`; Host detail only presents
   assignment/progress and navigation context.
5. The current audience validation rule remains. Moving the Audience UI does not make
   an audience optional.
6. The global dashboard shell and logo remain unchanged.
7. New shared UI uses semantic light/dark tokens and existing locale contracts; no new
   feature-specific light-only color palette is introduced.

## Phase map

| Phase | Outcome | Main ownership |
|---|---|---|
| 01 | Common tab/wizard presentation contract and state-preserving loading behavior | `packages/ui` + small tenant adapter |
| 02 | Six-tab Exam detail composition | `apps/tenant-web/features/exams` |
| 03 | Four-step Create Exam wizard layout | `apps/tenant-web/features/exams` |
| 04 | Static, type, build, accessibility, and browser handoff verification | `pte-web` verification only |

## Dependency order

```text
P01 common presentation/state contract
  └─ P02 Session detail tabs
       └─ P03 Create Exam wizard layout
            └─ P04 verification and handoff
```

P02 may reuse the existing `Tabs` and `TabPanel` without waiting for a new generic
component if the Phase 01 audit finds they are sufficient. Do not create a domain
component in `packages/ui` merely to avoid a small feature composition.

## Quality and testing strategy

- No automated UI test suite is assumed to exist for tenant-web.
- Every phase records its own typecheck/lint/build impact and keeps the required
  commands explicit.
- The final phase must include a real browser smoke pass for Host Exam detail, each tab,
  the create wizard, light/dark mode, and Vietnamese/English labels where the local
  environment supports it. A static build alone must not be reported as browser proof.
- Run `git diff --check` and preserve unrelated worktree changes before handoff.

## Plan risks

- Conditional unmounting can reset table filters and answer detail state. Use a visited
  tab registry or equivalent state-preserving strategy and verify tab return behavior.
- Rendering every tab immediately can recreate the original long-load problem. Mount
  inactive tab content lazily on first visit and retain it afterward.
- Updating the URL for tab state can accidentally trigger a full route navigation. Use
  client-side history/query synchronization and verify no global loading flash.
- A full-screen dialog may be visually larger without changing route semantics. Do not
  introduce a new route or draft API in this plan.

## Handoff checkpoint

Before running `/ck:cook`, confirm:

1. Whether the approved tab label should be `Examiner` or the Vietnamese `Phân công
   Examiner`.
2. Whether the create wizard should be a full-screen dialog on the existing `/host/exams`
   route (recommended) or a new route (not included by default).
3. Whether the final browser check can use the current local seeded Exam/session data.

## Ready to cook

```text
/ck:cook --hard pte-doc/projects/plans/quang-tenant-exam-ui-decomposition/plan.md
```
