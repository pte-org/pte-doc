# Phase 7: Backend Payload Parsing & Scoring Engine (Answer Submission)

## Requirements

Implement scoring for the 4 new payload formats defined in this plan, and document them in `SubmitAnswerRequest`'s contract comment. Nothing in this phase blocks any Frontend phase — it can proceed independently once the payload conventions (established in Phase 2-6) are stable.

Maps to: PTE task types `MC_READING_MULTIPLE`, `RE_ORDER_PARAGRAPHS`, `FILL_BLANKS_READING`, `FILL_BLANKS_READING_WRITING`.

## Design Constraints

- Read the `scoring` service's existing evaluator interface/pattern for `MC_READING_SINGLE`/`WRITE_ESSAY` **first**, before writing any of the 4 new evaluators — they must match its established shape, not introduce a parallel convention.
- `MC_READING_MULTIPLE`: parse the comma-joined selected `orderIndex` set, compare against the correct set, apply PTE-standard negative marking (+1 per correct selection, -1 per incorrect selection, **floored at 0** — a single question's score is never negative, even if every selection is wrong).
- `RE_ORDER_PARAGRAPHS`: parse the chosen sequence, score by correct **adjacent pairs** (PTE-standard partial credit — 1 point per correctly-adjacent pair in the student's sequence, not an all-or-nothing exact-match check).
- `FILL_BLANKS_READING` / `FILL_BLANKS_READING_WRITING`: parse the positional payload, correctly handling an empty entry at **any** position (start, middle, or trailing) as "unanswered, 0 points for that gap" — the trailing-empty-entry convention from Frontend Phase 5/6 means a naive `split(',')` without careful bounds handling will silently misparse a trailing-blank case; this evaluator's parsing logic is effectively the backend mirror of Frontend Phase 5 Step 7's regression test and must be verified against the same worked example (`"2,0,"` = 3 positions, not 2).
- `SubmitAnswerRequest.java`'s doc comment must be updated to document all 4 new formats with the same worked-example style already used for the existing 3 types (`MC_READING_SINGLE`/`WRITE_ESSAY`/`READ_ALOUD`).

## Steps

1. Read the `scoring` service's directory structure and existing evaluator(s) for `MC_READING_SINGLE`/`WRITE_ESSAY` to confirm the interface/pattern this phase must match (class naming, dispatch mechanism, how a task's correct-answer data is looked up).
2. Update `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/request/SubmitAnswerRequest.java`'s doc comment to cover all 4 new payload formats.
3. Implement the `MC_READING_MULTIPLE` evaluator per the Design Constraints above.
4. Implement the `RE_ORDER_PARAGRAPHS` evaluator (adjacent-pair scoring) per the Design Constraints above.
5. Implement the shared `FILL_BLANKS_READING`/`FILL_BLANKS_READING_WRITING` positional-payload evaluator (two entry points, one parsing implementation) per the Design Constraints above.
6. Test: `MC_READING_MULTIPLE` — all-correct, all-incorrect (floors at 0, not negative), partial-correct, empty-selection cases.
7. Test: `RE_ORDER_PARAGRAPHS` — fully-correct sequence, fully-reversed sequence, partially-correct-adjacent-pairs case with a hand-verified expected point count.
8. Test: fill-blanks evaluator — leading-empty, middle-empty, and **trailing-empty** entries each parse to the correct number of positions and correct per-gap correctness, mirroring the frontend's `"2,0,"` worked example exactly.

## Success Criteria

- [ ] All 4 new evaluators follow the `scoring` service's existing interface/pattern, not a parallel convention.
- [ ] `MC_READING_MULTIPLE` negative marking never produces a below-zero score for a single question.
- [ ] `RE_ORDER_PARAGRAPHS` awards partial credit correctly for a partially-correct sequence, verified against a hand-computed expected value.
- [ ] The fill-blanks evaluator correctly parses a trailing empty entry as an unanswered final gap, not a shorter answer array.
- [ ] `SubmitAnswerRequest`'s doc comment documents all 8 payload conventions now in use (the original 3 + these 4 new + verify none was missed).
- [ ] The `scoring` service's module test suite passes with no regression to the 3 existing evaluators.

## Quality and Testing State

- Quality gate: not started.
- Testing: not started.

## Risks

- **HIGH**: the trailing-empty-entry parsing case (Design Constraint on fill-blanks, Step 8's test) is the same failure class flagged as HIGH risk on the frontend side (Phase 5) — a backend implementation that does `payload.split(",")` without accounting for Java's default `split` behavior of dropping trailing empty strings would silently misparse `"2,0,"` as a 2-element array instead of 3, misaligning every gap index after the first empty one. Use `split(",", -1)` (or equivalent explicit-limit form) to preserve trailing empty entries — call this out in code review as the one line most likely to hide a subtle scoring bug.
