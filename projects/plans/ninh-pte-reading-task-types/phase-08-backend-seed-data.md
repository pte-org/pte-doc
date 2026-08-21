# Phase 8: Backend Seed Data & Fixtures

## Requirements

Insert realistic database rows for each of the 4 new task types, so a Flutter client pointed at a local/dev backend receives real structured data end-to-end — critically including a fully-populated `blankGroups` example for `FILL_BLANKS_READING_WRITING` (the one type with no other verification path once Phase 1/7 are also in place) and a shuffled-paragraph example for `RE_ORDER_PARAGRAPHS`.

Maps to: PTE task types `MC_READING_MULTIPLE`, `RE_ORDER_PARAGRAPHS`, `FILL_BLANKS_READING`, `FILL_BLANKS_READING_WRITING`.

## Design Constraints

- Follow whichever seed-data mechanism (Flyway migration vs. seeder script) the `authoring`/`exam-delivery` service's existing migration convention already uses — do not introduce a new seeding mechanism for just these 4 rows.
- Each seeded task must be realistic enough to exercise the full round trip meaningfully: a `FILL_BLANKS_READING_WRITING` row needs at least 2 gaps, each with a distinct multi-option `blankGroups` entry (not a single-option trivial case); a `RE_ORDER_PARAGRAPHS` row needs at least 3 paragraphs in a genuinely shuffled (not accidentally-already-correct) order.
- This seed data exists for local/dev end-to-end verification, not as a substitute for the Frontend's own dev fixtures (`ninh-pte-reading-task-types` Phase 2) — the two serve different purposes (Frontend fixtures: fast offline iteration/widget tests; this seed data: real full-stack round-trip confirmation) and neither replaces the other.

## Steps

1. Read the `authoring`/`exam-delivery` service's existing Flyway migration files (or seeder script convention) to confirm the exact mechanism and file-naming pattern already in use for task/option seed data.
2. Write one migration/seed script inserting at least one complete task row per new type: `MC_READING_MULTIPLE` (passage + 4-5 options, 2+ correct), `RE_ORDER_PARAGRAPHS` (3+ shuffled paragraphs), `FILL_BLANKS_READING` (passage with 2+ gap markers + a word bank with more words than gaps), `FILL_BLANKS_READING_WRITING` (passage with 2+ gap markers, each with its own distinct `blankGroups` option list).
3. Run the migration/seed locally and confirm each row is retrievable via the `exam-delivery` `next-task`/attempt-start endpoint, returning the shape Phase 1 defines (spot-check the raw JSON response for each type).
4. Test: a mapper/integration-level test (or manual `curl`/Postman check, whichever this service's existing convention uses for seed-data verification) confirming each new seeded task serializes with the expected `blankGroups`/`options` shape for its type.

## Success Criteria

- [ ] At least one realistic, non-trivial seed row exists for each of the 4 new task types.
- [ ] The `FILL_BLANKS_READING_WRITING` seed row has genuinely distinct option lists per gap, not the same list duplicated.
- [ ] The `RE_ORDER_PARAGRAPHS` seed row's stored order is genuinely shuffled relative to the correct order.
- [ ] A local backend serving this seed data, queried by the Frontend's `ReadingTaskPreviewScreen`-equivalent flow (or a real attempt), renders each new screen correctly against real data — not just the Phase 2 dev fixtures.

## Quality and Testing State

- Quality gate: not started.
- Testing: not started.

## Risks

- **LOW**: seed data quality directly determines how meaningful the plan's final full-stack verification step is — a trivial or accidentally-correct-order seed row would make Phase 4/6's screens look correct even if a real reordering/distinct-option-list bug exists. Keep the seeded examples non-trivial per the Design Constraints above, not just "any row that satisfies the schema."
