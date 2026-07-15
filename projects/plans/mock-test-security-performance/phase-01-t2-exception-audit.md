# Phase 1 (Track 2): Exception-Handling Consistency Audit

**Track:** 2 — Resilience & Auto-Recovery
**Covers:** supporting NFR (Availability) · groundwork for FR-06
**Depends on:** nothing — can start immediately

---

## Design Constraints

- This is an audit-and-fix phase, not a rewrite. Existing patterns are reasonable (`GlobalExceptionHandler` + `ApiResponse<T>` + `ErrorCode` enum on API; BLoC error states on mobile; `error.tsx` boundaries on web) — the goal is consistency and closing gaps, not replacing the architecture.
- Focus specifically on exam-delivery-adjacent code paths first (highest risk during a live exam), not a blanket repo-wide pass.
- Every caught exception must either be handled meaningfully (user-facing message + recovery path) or explicitly re-thrown/logged — no silent swallowing (`catch (e) {}` / empty catch blocks).

## Files to Touch

- `aptis-api/src/main/java/com/aptis/common/exception/GlobalExceptionHandler.java` — verify all exam-delivery-related exceptions are mapped (including new ones from Track 1: `ExamTimeExpiredException`, `SessionConflictException`).
- `aptis-api/src/main/java/com/aptis/modules/examdelivery/**` — grep for unhandled/broad `catch (Exception e)` blocks, silent swallows.
- `aptis-app/lib/features/exam_delivery/**` — grep for unhandled Future/async errors, BLoC states that don't surface errors to UI.
- `aptis-web/apps/*/features/examoperations/**` — verify error boundaries and TanStack Query error handling are present for exam-related data fetches.

## Implementation Steps

1. Grep all 3 codebases for broad/empty catch blocks and unhandled promise/future rejections in exam-delivery-adjacent code.
2. Produce a findings list (file:line + issue), prioritized by risk (data loss > silent failure > cosmetic).
3. Fix each finding: either add proper handling+logging, or a specific narrower catch with a clear reason.
4. Verify `GlobalExceptionHandler` maps every custom exception type used in `examdelivery` (including the new ones introduced by Track 1).
5. Document the finalized error-handling pattern briefly (where new exceptions should be added, how they map to `ErrorCode`) so Track 1/3/4 owners follow it consistently for their new exceptions.

## Acceptance Criteria

- [ ] No silent-swallow catch blocks remain in exam-delivery code paths across all 3 codebases (verified by grep + manual review).
- [ ] All custom exceptions introduced by this plan (Track 1's `ExamTimeExpiredException`, `SessionConflictException`, etc.) are mapped in `GlobalExceptionHandler` with appropriate HTTP status + `ErrorCode`.
- [ ] Findings list documented for team reference.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
