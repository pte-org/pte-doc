# Specification: Practice skill scope and all-mode retry configuration

**Status:** Draft for plan handoff  
**Priority:** P1 demo-critical

## Problem statement

The canonical host exam workflow has exam modes, but a generated exam always includes all sections from its selected template. Hosts cannot create a focused Practice exam through the canonical workflow, and cannot configure how many times an enrolled student may retry any exam.

## Goals

- Let a host select one or more skills for a Practice exam from sections represented by the selected active template.
- Let a host configure the number of retries allowed per student for every exam mode.
- Persist the chosen skill scope on the draft and return it through the host API.
- Persist the retry count on the draft/session and enforce it server-side for Practice, Mock Test, and Official Exam.
- Apply the same scope to template/question-bank readiness checks and the generated immutable snapshot.
- Keep student attempt, submit, scoring, and host review paths working with a subset of skills and multiple independent attempts.
- Preserve existing behavior for old API clients and sessions; keep skill selection limited to Practice.

## Non-goals

- Creating new exam modes or changing the current Practice/Mock/Official policy presets.
- Selecting individual task types or changing template structure, question counts, timing, or scoring rules.
- Untimed exams, immediate per-answer feedback, reopening/resubmitting the same attempt, or changing other mode policy presets beyond the per-session retry count.
- Changing licensing, audience eligibility, schedule-overlap, examiner assignment, score-source selection, or report publication rules.
- Client-side removal of tasks from an already generated snapshot.

## User stories

- **P1 — Focused Practice:** As a host, I can choose one or more available skills when creating a Practice exam so students only receive questions for those skills.
- **P1 — Exam retries:** As a host, I can set the number of retries per student on any exam mode so students can retry only as many times as allowed.
- **P1 — Accurate readiness:** As a host, I see preflight warnings only for requirements in the selected scope; an empty question pool in an unselected skill does not block a Practice exam.
- **P1 — Consistent attempt:** As a student, I can open, complete, submit, and retry an exam within the host-configured limit in `pte-app`; as a host, I can see each submitted attempt and its answers in the existing exam workflow.
- **P1 — Safe compatibility:** As an existing API consumer, omitting the new scope field continues to mean the full template scope; existing Mock/Official exams continue to use the full template.

## Acceptance criteria

1. The host wizard exposes Practice skill selection and a retry-count setting from `0` to `9` for every exam mode. Skill choices are limited to sections present in the selected template; at least one skill is required. Skill selection defaults to all template sections, and retries default to `0`.
2. `selectedSkills` and `maxRetriesPerStudent` are transported through create/patch draft requests and the session response, and are durably associated with the draft before generation.
3. A create request that omits `selectedSkills` resolves to all sections declared by the pinned template. A patch that omits the field preserves existing scope, except changing template or changing from Practice to Mock/Official resets scope to the new/full template. A patch omitting `maxRetriesPerStudent` preserves the current value across all modes. Existing full-template and zero-retry behavior is covered by regression tests.
4. For Mock Test (`MOCK_TEST`) and Official Exam (`REAL_EXAM`), a partial skill scope is rejected by the API; the host UI presents the full-template scope. The retry-count setting remains available for `PRACTICE`, `MOCK_TEST`, and `REAL_EXAM`.
5. Preflight evaluates requirements and available question stock only for selected skills. It reports missing/insufficient selected requirements before generation and does not report shortages from excluded sections.
6. Deterministic generation produces snapshots containing only selected sections. Template-defined timing/scoring/counts and deterministic/idempotent generation semantics remain unchanged. Any implicit Speaking item is included only when Speaking is selected and existing template policy calls for it.
7. After publish/open, the student app receives the generated snapshot tasks without client-side filtering. The student can resume one in-progress attempt, submit it, and start a new independent attempt only while under the configured total limit. Attempt responses expose the attempt number and remaining/retry availability so the app does not maintain an authoritative client-side counter. Each accepted attempt gets a fresh copy of the template-defined timers and the same generated form.
8. The host can distinguish submitted work in any mode by attempt and inspect its answers in the existing host workflow. The demo does not require closing the exam or publishing student-facing reports.
9. Template-defined timing, replay policy, device/proctor/lockdown defaults remain unchanged. Every mode uses the configured retry count; old clients and existing sessions default to zero retries (one total attempt).

Existing persisted sessions are not rewritten by the migration. Historical sessions without a template/scope retain their current snapshot as the source of truth; the new response field may be omitted for those rows or derived from that snapshot if an existing public query can provide it safely.

For compatibility, a pre-existing DRAFT that has a pinned template but no skill-scope rows resolves to the full scope of that template. A missing retry count resolves to `0`. If a partial Practice draft changes to Mock/Official without explicitly supplying a subset, its scope resets to full; a retry count above `0` remains valid in every mode.

Retry semantics: `maxRetriesPerStudent` counts retries after the initial attempt, from `0` to `9`; total allowed attempts are `1 + maxRetriesPerStudent`. Every `SUBMITTED` attempt consumes one total attempt, including time-expiry submission. A `CREATED` or `IN_PROGRESS` attempt is resumed and does not consume another slot. A later attempt creates a new record against the same immutable generated form; it never reopens or overwrites a submitted attempt. The range is enforced consistently by UI, API, and database constraints. Default `0` preserves current behavior. Every persisted `attemptNumber` is non-null and positive.

## Design constraints

- The generated snapshot is authoritative for attempt delivery, scoring, and reporting.
- Reuse public module service boundaries; keep section filtering in the assessment generation/readiness contract rather than duplicating it in session orchestration.
- Keep the existing draft → audience → preflight → generate → publish → open workflow. Do not re-enable the legacy skills-only endpoint.
- Preserve tenant ownership, subscription and capacity checks, template version pinning, audience rules, idempotency, and immutable generated forms.
- Enforce quota and attempt sequencing under the existing session-row lock; never rely on a client-side counter. Preserve a single resumable in-progress attempt per student/session.
- User-facing validation must be actionable; machine codes must not surface raw in the host UI.

## Validation evidence expected

- Backend tests prove scope/retry-count persistence and validation in all modes, scope-aware preflight, generated snapshot contents, retry allowance, and concurrent-start safety.
- Host tests/type-check prove mode-aware selection, at-least-one validation, review summary, and API payload mapping.
- App checks prove partial-skill attempt completion/submit and allowed-retry/limit-reached UX; keep timer behavior unchanged.
- Authenticated local walkthrough: host creates a one-skill Practice exam with a configured limit → one student is assigned → host preflights/generates/publishes/opens → student takes and submits in `pte-app` → host verifies the submitted attempt and answers. Do not require report publication.
