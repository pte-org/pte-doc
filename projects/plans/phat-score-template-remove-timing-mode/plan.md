# Plan: Remove `timingMode` from ScoreTemplate module

Status: 🟢 Done
Date: 2026-09-19
Mode: Fast

## Overview

`timingMode` (`FIXED`/`RECOMMENDED`) on `ScoreTemplateItem` is dead structural weight: it is never copied into `PinnedItem`/`PinnedItemView` and no runtime logic (timer, validator, scoring) reads it. This plan removes the field end-to-end — entity, DTOs, mapper, admin service, migration, tests, and the two vendor-web consumers — as pure cleanup with no behavior change.

## Phases

- [x] Phase 1: Remove `timingMode` (backend + migration + tests + vendor-web) — delete the enum/field/DTO/mapper/service references, drop the DB column via a new migration, update all affected tests, and strip the TIMING column/field from vendor-web.

Single phase: the backend change and the frontend change are tightly coupled (frontend types just mirror the response DTO) and small enough (10 backend files + 3 frontend files) that splitting into two phases would only add sequencing overhead without reducing risk — there's no need to ship the backend contract change ahead of the frontend removal since both are one commit-sized cleanup.

## Research Summary

N/A (Fast mode). Footprint was pre-verified by the requester before this plan was written:
- Backend: `TimingMode.java` enum, `ScoreTemplateItem.timingMode` field, `ScoreTemplateItemRequest.timingMode`, `ScoreTemplateItemResponse.timingMode`, one mapper line, two `ScoreTemplateAdminService` call sites (clone-copy + create/update parse), confirmed via grep (10 backend files total including 3 tests).
- Frontend: 3 files under `pte-web` confirmed via grep (`api-client` type, vendor-web feature type, vendor-web table component) — no separate create/edit form field exists beyond these.
- DB: column is `timing_mode` on `score_template_items`, confirmed present in `V14__score_template.sql` (original table creation) and nowhere else in the schema.
- Latest migration confirmed as `V38__student_roster_account_metadata.sql` at plan-writing time — new migration will be `V39__drop_score_template_timing_mode.sql`.

## Dependencies

None — no other module or external service depends on `timingMode`.

## Risks

- MEDIUM: Another migration lands between plan-writing and implementation, making `V39` collide with a new `V38`-successor — mitigation: re-check `pte-api/app/src/main/resources/db/migration/` for the actual latest `V*` file immediately before creating the new migration file, and renumber if `V39` is already taken.
- LOW: Column name assumed as `timing_mode` (snake_case of `timingMode`) does not exactly match what Hibernate derived — mitigation: the plan already cross-checked `V14__score_template.sql` directly and confirmed `timing_mode` is the literal column name, so this is verified rather than assumed; re-confirm only if `ddl-auto: validate` fails after the drop.
- LOW: `parseEnum` generic helper in `ScoreTemplateAdminService` is shared with `ScoringMethod` — mitigation: remove only the `TimingMode` call site/import, keep the helper method intact (verified only two call sites exist: `TimingMode` and `ScoringMethod`).
- LOW: `ScoreTemplateSeedMigrationTest` may assert per-row `timing_mode` values from the 22-row seed table — mitigation: treat this test file as needing a full read before editing, not just a line-number removal, since removing a column shifts per-row assertion indices/tuples.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-09-19 22:30
**Phase in progress:** phase-01-remove-timing-mode (complete)
**Status:** Done — backend + frontend cleanup verified, all tests green.

### Decisions made this session
- `ScoreTemplateSeedMigrationTest` needed NO changes: it parses raw SQL text of the immutable `V14__score_template.sql` via regex/string literals, with no compile dependency on the `TimingMode` Java enum — only its local record field happens to share the name `timingMode`.
- Found 4 EXTRA test files outside the `scoretemplate` module that the plan didn't list, because they construct `ScoreTemplateItemResponse` positionally (no named `timingMode` field to grep for): `ExamGenerationServiceTest`, `SnapshotPinServiceTest` (attempt), `ScoreAggregationServiceTest` (reporting), `ScoringMethodResolverTest` (scoring). Fixed all 4 by dropping the now-unused `"FIXED"`/positional arg.
- V38 was re-confirmed still latest immediately before creating `V39__drop_score_template_timing_mode.sql`.

### Next immediate action
None — phase complete. Ready for Step 5 (finalize/commit) pending user go-ahead on committing (per standing instruction: never commit without being asked each time).
