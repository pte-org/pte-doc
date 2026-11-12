# Phase 5: Verification

## pte-api

- `.\mvnw.cmd -pl app -DskipTests compile`.
- Focused tests from phases 1–3.
- The full `app` suite, reporting failures that already existed separately.
- Ratchets stay green, with empty allowlists:
  - `RubricScoreSingleSourceTest`;
  - the 300-line, package-density and `Clock` ratchets.
- `ApiInventoryExportTest` is updated.
- Rebuild the local `app` container. Apply any new migration by hand, because the local profile is `local-schema`.
- Live check against the gateway: one real RA and one DI scored through the new endpoint, and the stored feedback inspected. Never print the key.

## pte-practice

- `npx tsc --noEmit`, scoped eslint and `npm run test:unit`.

## Manual (user)

- TASK Read Aloud: submit, then "Chấm điểm", then the feedback is shown. Re-record, and the button comes back.
- SKILL Speaking: one item scored and one left unscored. The summary shows "Chưa chấm" for the second.
- Mock test: submit, then "Chấm điểm", then the full report with per-item feedback.
- Exam scoring is unchanged (Azure).
