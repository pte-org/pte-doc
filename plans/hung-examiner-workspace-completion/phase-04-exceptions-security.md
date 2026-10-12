# Phase 4 — Exceptions, resources and security

Status: COMPLETED. Q3 published completion/history and Q4 Host-resolved issues confirmed. Stories E06–E09. Fast mode execution.

## Tasks

- [x] Add bounded owner-scoped grading-history projection/controller using immutable workflow events and legacy final metadata. Filter/paginate on server with stable timestamp+ID ordering; explicit assignment/student-privacy policy. Never expose generic tenant audit listing to Examiner.
- [x] History/receipt reads validate current active Examiner identity, tenant and assignment before receipt lookup; publication scope per Q3. Separate original committed event/receipt from live mutable snapshot. Revoked access receives no current grading data.
- [x] Add pinned grading-guidelines projection based on attempt snapshot scoreTemplatePublicId/version and verified profile/rules. Minimal authorized context only; no administrator template access or fetching current active template as historical truth. Clearly explain absent criterion rubric for scalar branch.
- [x] Add thin /examiner/grading-history and /examiner/grading-guidelines routes, feature views and @pte/api-client contracts. Add Resources menu only when real projections are available; preserve workspace active states.
- [x] Q4 confirmed issue lifecycle: additive grading_issue entity/repo with work/answer scope, type, bounded description, creator, createdAt, OPEN/RESOLVED, blocking classification and Host resolver/reason/time. Extend assigned Examiner flag/list and Host resolve commands with backend permissions and append events.
- [x] Issue creation/Host resolve/finalize use session -> work locking; finalization rechecks unresolved blocking issues in same transaction. No issue transition to Completed; no reopen of immutable score. UI distinguishes operational issue from progress state.
- [x] Keep new issue workflow assignment-scoped. Current /api/v1/support-tickets is HOST_ADMIN only; do not grant generic Host tickets to Examiner or repurpose support as grading-history/issue ownership.
- [x] Do not add Review Requests/Reopened menu unless separately approved review/revision/publication workflow exists. Unsupported review/regrade requests are recorded as dependency/proposal, not fabricated implemented functionality.
- [x] Centralize safe localized error classification in feature constants/messages. Handle401/403/404/409/validation/network independently; no raw exception text. Preserve drafts/known successes; expose retry for failed source only.
- [x] Audit initial loading, refreshing, stale-success + refresh-failure, success-empty and partial-error across overview/priority/queue/detail/history/guidelines. Priority failure cannot become an empty list; count error cannot become0.
- [x] Verify role, active membership, tenant, attempt assignment, answer ownership and immutable/mutable permissions on all start/save/finalize/history/guidelines/flag/receipt routes; host resolution needs host tenant/session scope. Frontend route checks are supplementary.
- [x] Prevent PII/model secrets/media URLs in audit and bulk logs; reuse authorized media facade and expiry refresh. Add hostile ID/query/page/size and cross-owner checks.
- [x] Q3 published Completed uses isolated read-only query DTO and mutation denial; do not remove current publication guard from reusable mutable detail service. Overview/Completed counts include these finalized published assignments; Pending/In Progress remain unpublished.

## Checks and acceptance

Backend IDOR matrix tests every new endpoint for unauthenticated, wrong role, inactive owner, wrong tenant, unassigned attempt, wrong answer and revoked assignment. History pagination consistency; receipt replay disclosure after revocation; Host issue resolve/finalize race; blocking issue prevents finalize, resolved issue permits remaining validation. UI error matrix and Resources route/navigation tests. Reopen/multi-rater tests marked unsupported/out-of-scope with reason rather than skipped success.

## Design Constraints

No broad support/audit role grants. Issue orthogonal to progress/publication. No mutable published scores and no unauthorized reopening. Owner-scoped bounded records, read-only historical projection, server-approved workflow dependencies.

## Quality and Testing State

Quality: not evaluated. Testing: not started. Required security/integration/error/resource tests planned. Optional TDD/ck:quality: not selected. Q3/Q4 confirmed; published finalized read-only projections and Host-resolved issues required.
