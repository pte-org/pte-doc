# Phase 3: Bulk Import (Excel/ZIP) for Flat MCQ

## Requirements

Implement a synchronous POST endpoint that accepts an Excel file (.xlsx) and an optional ZIP archive of audio files and bulk-imports flat MCQ questions (Reading/Listening) in one operation. Validate all rows in a transaction before committing any; return per-row error details in the response so the user can fix failures and retry. Scoped to Host tenants only (Vendor uses one-by-one authoring).

Maps to: **P1 Story #3 | FR-02**

## Design Constraints

- Must perform all validation in a read-pass before any database writes; entire import must succeed or entirely fail (all-or-nothing transaction semantics).
- Must not implement async job or polling pattern; response must include success/failure details synchronously (accept <5s latency as acceptable per spec for <100KB files).
- Must reject questions that are not flat MCQ (reject Writing/Speaking/complex question types).
- Excel schema must be well-defined and validated against; import must report which columns are required vs. optional.
- Audio files referenced in Excel rows must exist in the ZIP; missing files must be reported as row errors (not silent no-audio fallback).

## Steps

1. Define Excel schema (columns: question_text, skill_type, correct_answer, distractor_1, distractor_2, distractor_3, audio_filename [optional], question_notes [optional]) and document it in a public schema guide.

2. Implement Excel parser that reads .xlsx, extracts rows, and maps each row to a Question DTO, detecting column headers automatically or validating against expected positions.

3. Implement ZIP file handler that extracts and catalogs audio filenames, keyed by filename; validate that all referenced audio files are present in the ZIP (build a lookup map).

4. In a pre-commit validation phase (before any writes), validate each row: required fields present, skill_type is Reading or Listening only, correct_answer is one of the distractors list, audio_filename (if provided) exists in ZIP catalog.

5. Collect all row-level errors (row index, field, error message) in a list; if errors exist, return 400 Bad Request with error array and do not proceed to writes.

6. If all rows are valid, upload all referenced audio files via `CloudinaryServiceImpl` **first, outside the database transaction** (uploads are not transactional against Postgres regardless — no point pretending otherwise), collecting the resulting CDN URLs/Asset metadata per row; if any upload fails, abort before opening the database transaction and return 400 Bad Request with the row index and "upload failed: <reason>" (distinct from a validation error). Only once all uploads succeed, open a single database transaction and create all Question + Asset records together (all-or-nothing at the DB level).

7. On transaction commit success, return 200 OK with counts (imported_count, skipped_count, error_details [empty array]).

8. Test end-to-end: upload Excel with 10 valid rows + 2 invalid rows, verify 10 are imported, 2 errors are reported, no partial state exists.

## Success Criteria

- Import endpoint accepts Excel + ZIP, validates all rows against schema without writing to DB.
- Invalid rows are reported with row index and error reason (e.g., "missing correct_answer", "audio_filename not in ZIP").
- Valid rows are all imported in a single transaction (all succeed or all roll back).
- Imported questions are scoped to the authenticated Host tenant and immediately visible in the question list.
- Audio files from ZIP are uploaded via CloudinaryServiceImpl and linked to questions.

## Quality and Testing State

- Quality gate: **approved** (report: `quality/phase-03-bulk-import-excel-zip-quality-report.json`, receipt issued 2026-07-15). Two MEDIUM findings fixed before approval: Asset creation now goes through `AssetOperations` instead of duplicating entity-construction logic directly; audio MIME type is now validated per-row against the same whitelist Phase 2 uses.
- Testing: not started — skipped by user for Phase 3 (policy: unit tests required only for Phase 6-9)

## Session Notes

- New `QuestionActorResolver` component extracted from `QuestionService` (Phase 1/2) to share actor/tenant resolution with the new import flow — avoids duplicating that business rule.
- `QuestionImportWriter` is a separate `@Service` bean (not a private method) so its `@Transactional` boundary is honored by Spring's proxy; it now delegates Asset creation to `AssetOperations` (shares the same transaction via default REQUIRED propagation) rather than touching `AssetRepository` directly.
- Reused the existing `EasyExcel` dependency (already used by IAM's student-roster import) rather than adding Apache POI; deliberately created questionbank-owned `QuestionImportValidationException`/`QuestionImportRowError` types instead of reusing IAM's student-import exception types, to keep module ownership boundaries clean.
- ZIP handling streams entries with a cumulative-uncompressed-byte cap (not just a compressed-file-size check) to defend against zip bombs.
- Column list from the phase's Excel schema is used as specified; `difficulty_level` is not a column — every imported question defaults to `DifficultyLevel.B1` since the entity requires a non-null value.
- Build Gate: PASS.

## Risks

- **Excel parsing brittleness**: If a column header is slightly misspelled (e.g., "correct answer" vs. "correct_answer"), the parser will silently skip it and treat that column as empty. Mitigation: implement strict header validation with explicit error messages listing expected columns; allow user to map columns via UI if strict mode fails.
- **Transaction rollback semantics**: If row 500 out of 1000 fails validation, the response will report failure, but rows 1-499 may already be partially committed if transaction isn't properly isolated. Mitigation: use database-level transaction with isolation level SERIALIZABLE for import operation; test rollback scenario with multi-row failure.
- **ZIP bomb / oversized files**: If user uploads a huge ZIP (e.g., 1 GB), memory exhaustion can occur during extraction. Mitigation: enforce max ZIP size limit (e.g., 100 MB) at the endpoint; stream-process ZIP entries instead of loading entire archive into memory.
- **Audio upload failure mid-import**: resolved by Step 6's ordering — all uploads complete (or the whole import aborts) before the database transaction opens, and the error response explicitly distinguishes "upload failed" from "validation failed" so the user isn't confused about which phase failed.
