# Phase 3: Feedback contract

## Goal

One scoring call returns the score and the feedback. The practice API exposes the feedback in a stable shape.

## Feedback content (model JSON, validated)

- `traits[]`: `{ trait, band, max, reason }`. The reason is one sentence in Vietnamese.
- `transcript`: what the student said (speaking only).
- `wordMarks[]` (RA, RS only): `{ word, mark: OMITTED | SUBSTITUTED | INSERTED, heard? }`, against the reference text.
- `tips[]`: one or two concrete, actionable tips in Vietnamese.

## Work

- Extend the scorers' schema with these fields:
  - the gateway audio scorers from phase 1;
  - the existing writing scorers, which already return feedback text. Map that text to the same shape so speaking and writing share one contract.
- Store the feedback in the existing evaluation detail JSON. No new table.
  - If a column change is needed, add a new migration `V46+`. Never edit an applied one.
- `PracticeItemResponse` (or the item detail DTO) gains a `feedback` object. It is present when the item is `SCORED`.
- `@pte/api-client` is not involved; pte-practice owns its own types.

## Tests

- Parser accepts a valid feedback object.
- Parser drops unknown fields and rejects a wrong band.
- The DTO maps stored detail to `feedback`.
- An item scored before this change, with no feedback in its detail, returns `feedback = null` without failing.
