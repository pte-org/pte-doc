# Phase 3: Web — show the exam code

Repo: pte-web (`d:\FPT\9thSemester\pte\pte-web`, pnpm + turborepo). Depends on Phase 1 being available from the API.

## Requirements
Hosts see and copy the exam code (not the UUID) on the session detail page, and see it in the sessions list, with all wording changed from "session ID" to "exam code".

## Steps
1. Add `sessionCode?: string` (optional, so the web works if it deploys before the API) to the session response type in `packages/api-client` (`src/types/scheduling/index.ts`, `SessionResponse`), and update any fixtures or mocks of that type so typecheck passes.
2. Add `sessionCode` to tenant-web's own `ExamSession` view type (`apps/tenant-web/features/exams/types/index.ts`) and map it in `sessionResponseToExamSession` (`apps/tenant-web/features/exams/api/index.ts`) as `response.sessionCode ?? response.publicId`, so the UI always has a value to show. The component reads `session.id`, so the UUID stays as `id` for routing/API calls.
3. Change `SessionDetailView.tsx` (~line 132) to show and copy `session.sessionCode` instead of `session.id`; keep the copy-state logic keyed on the value copied.
4. Reword the constants in `apps/tenant-web/features/exams/constants/index.ts` (lines ~265-269: SESSION_ID_SECTION, SESSION_ID_HELPER, COPY_SESSION_ID, SESSION_ID_COPIED, SESSION_ID_COPY_FAILED) to "Exam code" language; keep the constant names unless a rename is trivial.
5. Add a small "Code" column to the sessions list table `SessionTable.tsx` (+ the header in the table-headers constants), monospace and compact.
6. Audit other tenant-web files that reference `sessionId`/`sessionPublicId` (about 22, e.g. `ExamPreviewModal`, `ProctorAssignmentSection`, `AssignProctorModal`, `StudentRosterTable`): for each, check whether the UUID is rendered as visible text, not just used in API calls, keys, or routes. Switch any human-visible UUID to the code only when the code is already available on that screen; otherwise record it in the Execution Log as out of scope. Don't add new fetches for this.
7. Run lint and typecheck for the workspace and fix findings.

## Files to Create or Modify (relative to `pte-web/`)

| File | Action |
|---|---|
| `packages/api-client/src/types/scheduling/index.ts` | Modify — `sessionCode?: string` on `SessionResponse` |
| `apps/tenant-web/features/exams/types/index.ts` | Modify — `sessionCode` on `ExamSession` |
| `apps/tenant-web/features/exams/api/index.ts` | Modify — map `sessionCode` |
| `apps/tenant-web/features/exams/components/SessionDetailView.tsx` | Modify — show/copy code |
| `apps/tenant-web/features/exams/components/SessionTable.tsx` | Modify — code column |
| `apps/tenant-web/features/exams/constants/index.ts` | Modify — wording + table header |

Suggested wording: section "Exam code"; helper "Share this code with students so they can open this exam in the PTE app."; button "Copy code"; "Exam code copied."; "Could not copy the exam code. Select the code and copy it manually."

## Success Criteria
- From `d:\FPT\9thSemester\pte\pte-web`: `pnpm install` (if needed), `pnpm turbo run lint` passes, and `pnpm --filter tenant-web exec tsc --noEmit` passes (tenant-web has only a `lint` script at planning time; confirm the typecheck script name in `turbo.json`/package.json before running and use it if present).
- Detail page shows e.g. `FPT-261010-K7QM`, and the copy button writes that value to the clipboard.
- Sessions list shows the code column without breaking layout on narrow widths.

## Tests
- Run any existing tests for the exams feature if a test runner is configured (check `package.json` / `turbo.json`; none found for tenant-web at planning time). If none exist, verification is lint + typecheck plus manual browser check against the Phase 1 API.

## Risks
- Other consumers of `SessionResponse` (vendor-web or other packages): the field is optional, so they keep compiling; grep `SessionResponse` across `apps/` and `packages/` anyway to confirm.
- Backend not yet deployed: `sessionCode` is `undefined` and the mapper falls back to the UUID, so the page still works.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- None from the Phase 3 changes. The checks did show some failures and warnings that were already there:
  - `@pte/api-client` vitest: 4 failures in `src/requests/endpoints.test.ts`. The cause is the `SUPPORT_TICKET_ENDPOINTS.admin*` paths, which contain the `admin` segment the test treats as retired.
  - Lint: 1 tenant-web warning (`'E' is defined but never used` in `supportTickets/components/CreateTicketModal.tsx`) and 2 vendor-web `<img>` warnings.

### Root Cause
- The failures and warnings come from the earlier support-ticket work and are unrelated to `sessionCode`. This phase only adds an optional field to the `SessionResponse` type, which vitest does not exercise at runtime.

### Resolution
- Left the existing failures and warnings untouched.
- Implemented steps 1–5:
  - `SessionResponse.sessionCode?: string` in api-client.
  - `ExamSession.sessionCode: string`, mapped as `response.sessionCode ?? response.publicId`.
  - The detail view shows and copies `session.sessionCode`. The copy state is keyed on the code, and the state and handler were renamed to `sessionCode*`.
  - The constants were renamed to `SESSION_CODE_SECTION`, `SESSION_CODE_HELPER`, `COPY_SESSION_CODE`, `SESSION_CODE_COPIED` and `SESSION_CODE_COPY_FAILED`, with the suggested wording. They are used only by `SessionDetailView`.
  - New `EXAM_TABLE_HEADERS.CODE` ("Code") and a nowrap `<code>` column right after the exam name in `SessionTable`. The table is already inside `overflow-x-auto`.
- Step 6 audit of UUIDs shown as visible text in tenant-web. Both cases are out of scope because their API responses carry no `sessionCode`, and the plan says not to add fetches:
  - `features/reports/StudentReportsView.tsx:40`: "Session {report.sessionPublicId}" on the student reports page.
  - `features/examiner/ExaminerWorkView.tsx:43`: "#{shortId(item.sessionPublicId)}" on examiner work items.
  - Every other `sessionPublicId` or `session.id` reference is used only for API calls, React keys or routes.
- vendor-web does not consume `SessionResponse` (grep), so it needs no change.

### Test Results After Fix
- Run from `d:\FPT\9thSemester\pte\pte-web`:
  - `pnpm --filter tenant-web exec tsc --noEmit -p .`: exit 0.
  - `pnpm --filter @pte/api-client exec tsc --noEmit`: exit 0.
  - `pnpm --filter vendor-web exec tsc --noEmit -p .`: exit 0.
  - `pnpm turbo run lint`: 2/2 tasks successful with 0 errors. The only warnings are the existing ones listed above.
  - `pnpm --filter @pte/api-client test`: 339/343 pass. The 4 failures are the support-ticket endpoint tests listed above, not this phase.
- tenant-web has no test runner.
- The browser check is still pending. The `web-tenant` container was built before this phase, so it needs a compose rebuild.
