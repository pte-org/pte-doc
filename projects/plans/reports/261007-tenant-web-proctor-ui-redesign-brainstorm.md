# Brainstorm: Tenant-Web Proctor UI Redesign

**Date:** 2026-10-07
**Author:** hung
**Slug:** `tenant-web-proctor-ui-redesign`
**Skill:** `ck-brainstorm`
**Mode:** Strict (no implementation in this turn)

## Context

User request (paraphrased, in order received):

1. "Examiner đã có màn hình implement riêng chưa?" — verification question,
   answered YES (phase 03 shipped `ExaminerWorkView.tsx`).
2. "Thiết kế và implement giao diện riêng cho role Proctor (vẫn sử dụng tenant
   web nhưng phân quyền)" — original task statement.
3. "Phân tích lại mấy phần cũ tôi xoá rồi" — context update: previous proctor
   UI work (commit `ec1bba5` on `origin/ninh/feat/proctor-workspace-ui`) was
   discarded by the user; redesign must be done from scratch, but **driven by
   what the backend currently supports**, not by what the previous UI exposed.

This brainstorm therefore takes the existing backend surface (package
`com.pte.proctoring` + adjacent REST/STOMP endpoints) as the source of truth
and proposes a UI that exposes them faithfully, with no invented capabilities.

## Backend surface — what exists today (verified by reading source)

Package `com.pte.proctoring` (36 files):

| Capability | Transport | Endpoint / Destination | Role | Source |
|---|---|---|---|---|
| Open proctor session | STOMP | `@MessageMapping("/sessions/{sessionPublicId}/open")` → reply `/user/queue/proctor-session` | PROCTOR | `ProctorStompController.open` |
| Issue command | STOMP | `@MessageMapping("/proctor-sessions/{id}/commands")` body `IssueCommandRequest{attemptPublicId, commandType}` | PROCTOR | `ProctorStompController.issueCommand` |
| Flag violation | STOMP | `@MessageMapping("/proctor-sessions/{id}/violations")` body `FlagViolationRequest` | PROCTOR | `ProctorStompController.flagViolation` |
| Live broadcast | STOMP topic | `/topic/proctor-session/{sessionPublicId}` | any sub | `ViolationService` `messagingTemplate.convertAndSend(...)` |
| Close session | REST | `POST /api/v1/proctor-sessions/{id}/close` | PROCTOR | `ProctorSessionController.close` |
| List violations (session-scoped) | REST | `GET /api/v1/exam-sessions/{id}/violations` | PROCTOR, HOST_ADMIN | `ViolationAuditController.listViolations` |
| Security audit log | REST | `GET /api/v1/exam-sessions/{id}/security-audit?limit&cursor` (cursor-paginated) | PROCTOR, HOST_ADMIN | `ViolationAuditController.listSecurityAudit` |
| Per-user error queue | STOMP | `/user/queue/errors` (auto) | any | `ProctorStompController` `@MessageExceptionHandler` |

Enum `ProctorCommandType`: only `FORCE_SUBMIT` exists today.

Enum `ProctorSessionStatus`: `ACTIVE`, `ENDED`.

`WebSocketConfig`: endpoint `/ws`, broker prefixes `/topic`, `/queue`,
application prefix `/app`. Plain STOMP, **no SockJS fallback** — the proctor
console is a "controlled client" per the source comment.

`StompAuthChannelInterceptor`: JWT auth on CONNECT is the primary defense.
`@PreAuthorize` does NOT enforce on `@MessageMapping` — `currentUser()`
helper in `ProctorStompController` enforces `PROCTOR` role explicitly.

### Adjacent endpoints that a proctor UI will reach for but may not exist

| Want | Endpoint | Status |
|---|---|---|
| List exam-sessions assigned to current proctor | none | ❌ — must come from outside source (link from host, or deduped from active STOMP topics) |
| List live attempts in session | none in `proctoring` | ❓ — must reuse `exam-assignments` API or a session-scoped endpoint not yet verified |
| Session preview (name, exam title, duration) | `GET /api/v1/sessions/{publicId}` exists (`SessionController` @PreAuthorize HOST_ADMIN) | ⚠️ **HOST_ADMIN-only** — proctor cannot read it today |
| Proctoree's profile (`User` lookup) | covered by auth context | ✅ JWT carries it |

→ The redesign must accept that **the proctor UI does not have a "list of my
sessions" REST endpoint** and either (a) derive from external sources or (b)
add a new endpoint to the backend. The redesign proposes option (a) for MVP
and flags option (b) as a follow-up.

### Adjacent frontend packages

| Package | Has STOMP/WS helper? | Has `proctorAssignments` types? |
|---|---|---|
| `packages/api-client` | **No** (`grep -E "websocket|stomp" packages` → 0 matches) | ✅ `requests/scheduling/proctorAssignments.ts` (HOST_ADMIN surface) |
| `packages/ui` | n/a | n/a |

→ A new STOMP client wrapper will need to be added in
`packages/api-client/src/realtime/` (or a sibling dir) and shared by proctor
(and potentially future live-monitoring features).

## Existing-Code Fit

- Shared `DashboardChrome` already exists in `apps/tenant-web/features/auth/components/`.
- Shared role-aware navigation `buildHostNav / buildStudentNav / buildExaminerNav`
  pattern exists in `apps/tenant-web/lib/navigation.tsx`. `PROCTOR_NAV_TEXT`
  is NOT defined yet (`navigationConstants.ts` lacks it).
- Role list in `apps/tenant-web/features/auth/constants.ts` includes
  `PROCTOR` (per prior conversation and the deleted UI's constants) — must
  verify before implementation.
- `Role.PROCTOR` exists on the backend (`UserProvisioningHelper` already
  provisions PROCTOR alongside EXAMINER, STUDENT).

## Ideas Explored

### Idea A — Minimal surface: live-monitoring for one session at a time

- `/proctor/sessions/[publicId]` page that opens a STOMP session, subscribes
  to `/topic/proctor-session/{publicId}`, and shows live attempts + actions.
- No `/proctor/sessions` index. Pro enters the page via a deep link from the
  host or from a notification.
- `/proctor/audit-log/[publicId]` for post-hoc review (uses REST endpoints).
- **Pros:** smallest backend assumption; one endpoint = one screen = easiest
  to test; reuses the same STOMP lifecycle the previous UI used.
- **Cons:** no landing/dashboard; proctor can't see "what should I monitor
  next" without leaving the app.

### Idea B — Dashboard + sessions list + per-session monitoring

- `/proctor` dashboard (recent sessions, alerts).
- `/proctor/sessions` index (list of sessions the proctor is or was
  assigned to).
- `/proctor/sessions/[publicId]` live monitoring (same STOMP as Idea A).
- `/proctor/audit-log/[publicId]` post-hoc review.
- `/proctor/profile` (read-only).
- **Pros:** parity with the host/classes/students route shape; lets a proctor
  see status without a deep link.
- **Cons:** **requires a new backend endpoint** "list exam-sessions where
  I'm assigned as proctor". Currently doesn't exist. Either backend adds it
  (out of scope for a frontend plan) or UI uses a workaround (e.g. each
  session ID is given via a deep link from the host UI and persisted in
  localStorage). This is non-trivial.

### Idea C — Reuse the previous UI's exact shape, minus deprecated parts

- 1:1 port of `ec1bba5`'s file layout (5 routes + 18 components + nav +
  constants) but:
  - drop anything tied to a backend capability that no longer exists,
  - re-validate against current backend source,
  - re-verify feature/examiner and feature/auth imports still resolve.
- **Pros:** lowest design risk; past commit is the most "tried and true" shape
  the team has already reviewed.
- **Cons:** carries forward any of its drift; doesn't re-question route layout;
  scope creep from "redesign" (user said redesign, not port).

### Idea D — Read-only audit view (P2-only MVP)

- Just `/proctor/audit-log/[publicId]` using `GET /exam-sessions/{id}/security-audit`.
- No live monitoring in MVP.
- **Pros:** fully backend-supported today; smallest possible scope.
- **Cons:** does not satisfy "role Proctor has its own UI" expectation — the
  role's primary function (live monitoring + force-submit) is missing.

## User's Direction (revised after user challenge)

User originally selected **Idea B** (dashboard + sessions list + live
monitoring + audit log + profile). Plan v1 was written around Idea B.

In a follow-up turn the user observed: *"sao phần trước của examiner
đâu có đụng vào backend đâu"* — pointing out that examiner phase03 was
shipped as a UI-only workstream because the backend was already ready.
The same pattern applies to proctor: the backend has everything needed
for a deep-link UI; the gap in v1 was that Idea B's dashboard assumed
a "list my sessions" REST endpoint that does not exist.

The pivot drops the dashboard and sessions list, keeping only:

- `/proctor` (index redirect to `/proctor/profile`) — mirrors `/examiner`
- `/proctor/sessions/[publicId]` (live monitoring, REST polling)
- `/proctor/audit-log/[publicId]` (audit log, REST)
- `/proctor/profile` (P1 read-only)

**Entry pattern:** host UI deep-links the proctor into
`/proctor/sessions/{publicId}` after assigning them via
`ProctorAssignmentController`. Backend authorization is enforced by
`ProctorSessionService.open()` (returns 403 for non-assigned callers).

**Backend workstream removed.** Total plan v2 is **UI-only**, mirroring
examiner.

In a third turn the user asked: *"hãy lên lại spec với plan làm sao
cho an toàn nhất cho code base không bị hỏng"*. This is the
**safety-constrained revision (v3)**.

## Safety concerns driving v3

The deleted proctor UI (`origin/ninh/feat/proctor-workspace-ui`,
commit `ec1bba5`) was:

- **40 files in one PR** (15 routes + 18 components + nav + auth).
- **Big-bang merge**: no flag, all-or-nothing.
- **Touched `lib/navigation*` files** — files currently being edited by
  other branches.
- **Added new package implicitly** (planned STOMP, never actually
  shipped — the deleted branch used REST polling at 3s).
- **Decomposed too aggressively**: 18 components for what was
  effectively 3 logical regions.

Plan v3 introduces 6 hard safety constraints (the contract):

- **S1** — pillar-first (≤ 8 new files + ≤ 3 edits per PR; 5 PRs total)
- **S2** — feature flag `NEXT_PUBLIC_PROCTOR_UI_ENABLED`, default OFF
- **S3** — mirror examiner pattern; ≤ 6 components total
- **S4** — add-only under `features/proctor/` + `app/(dashboard)/proctor/`
  (no `lib/navigation*` or `features/auth/constants.ts` edits until Phase 05)
- **S5** — zero new external packages in Phase 01-03 (REST polling first;
  STOMP deferred to Phase 06 / P2 separate plan)
- **S6** — `lib/navigation*` edits land in Phase 05 last (avoid
  collision with other branches editing same files)

The **live monitoring uses REST polling at 3s**, exactly as the deleted
branch did. STOMP is a P2 follow-up. This is **not a downgrade** — it's
the actual shipped approach.

## Narrowed Direction (revised)

- **P1 (must ship, gated)**: backend additions (FR-01, FR-02) + frontend
  routes + STOMP integration + audit view + live monitoring.
- **P2 (nice-to-have)**: profile view with optional change password.
- **P3 (out of scope)**: video feed, device profiling, "list my sessions"
  v2 with filters, attempt-by-attempt live status beyond what STOMP frames
  expose, force-submit variants beyond `FORCE_SUBMIT`.

**Explicit non-goals** for this redesign:
- Force-submit beyond `FORCE_SUBMIT` (backend enum has only one value).
- WebSocket reconnect/replay resilience beyond `@stomp/stompjs` defaults.
- Video feed, device profiling — previous UI deferred these; not in backend.
- Polling fallback for live monitoring — STOMP is the only transport
  (`WebSocketConfig` registers only `/ws`, no SockJS).

## Open Questions

These are flagged for the plan phase, not blockers:

1. `[NEEDS CLARIFICATION]` Where does a proctor learn the `sessionPublicId`
   from? Today the previous UI was reached by host links. If the host UI
   doesn't deep-link to `/proctor/sessions/{id}`, the redesign must surface
   it (e.g. dashboard shows sessions where `Role.PROCTOR` is in the assigned
   roster). **Resolution: ask in `/ck:plan` after spec review.**
2. `[NEEDS CLARIFICATION]` Should the proctor UI show the `AttemptStatus`
   timeline for sessions they don't own? Backend `ProctorSessionService`
   scopes by `proctorPublicId`, so today the answer is **no**. Spec marks
   this as a hard rule.
3. `[NEEDS CLARIFICATION]` Is `forceSubmitAttemptPublicId` the right field
   on `IssueCommandRequest`? Verified yes from `IssueCommandRequest.java`.

## Risks

1. **STOMP auth drift.** `StompAuthChannelInterceptor` requires JWT in the
   STOMP CONNECT headers. The frontend must use the same JWT used for REST
   or `ProctorRoleRequiredException` will fire on every command. The spec
   mandates reusing the auth store's token, not re-fetching.
2. **`@MessageExceptionHandler` errors land on `/user/queue/errors`.** The
   UI must subscribe to that queue and surface errors (do not silently drop
   `ProctorSessionNotActiveException`, `ProctorRoleRequiredException`,
   `ProctorSessionNotFoundException`).
3. **No SockJS fallback.** Source comment says proctor console is a
   "controlled client". This means the UI **must** be a modern browser
   supporting native WebSocket + STOMP. Adding `@stomp/stompjs` (or hand-
   rolled) must not regress older routes.
4. **Cursor-paginated audit log.** Cursor is opaque; spec must not assume
   integer pagination or `next_page_token` body parameters.
5. **Wasted work risk.** The previous UI (`ec1bba5`) had a lot of logic. The
   spec must explicitly call out which components survive the rename and
   which are discarded to avoid silent regressions.