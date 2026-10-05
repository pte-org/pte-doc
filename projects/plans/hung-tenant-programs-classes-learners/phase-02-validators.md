# Phase 2 — Form Validators + TypedConfirmInput Primitive

**Status**: completed (2026-10-04)
**Surface**: `validateCreateProgram`, `CreateProgramModal`, new
`validateClassName`, new `validateAddStudentInput`, `ImportOrAssignModal`,
`packages/api-client/src/client/errorMessage.ts`, new
`packages/ui/src/components/TypedConfirmInput.tsx`
**ACs covered**: AC7, AC8, AC9, AC11
**Stories**: S6, S7, S8, S11
**Risk**: low — isolated utilities, easy unit tests
**Quality**: skipped_by_user; decision: user_confirmed_skip
**Testing**: not started — user declined tests (chose "code only, no tests")
**Build Gate**: PASS — `pnpm --filter tenant-web build` (TypeScript OK);
`eslint features/classes features/programs` → 0 problems.
  (`@pte/ui` has no `build` script — it is consumed as TS source by `tenant-web`.)

**Preflight (ck-cook Step 1, 2026-10-04)** — repo `pte-web` @ `hung/feat/classes-entry`:
- **Repository conventions**: validators are pure functions in `features/*/utils/`
  returning an `Errors` object; error copy lives in `constants/index.ts` as
  `XXX_ERRORS`; types live in `features/*/types/index.ts`; modal-local form state is
  `useState<{form, errors}>`.
- **Boundaries**: `packages/ui` gains one new exported primitive; `api-client` is
  untouched (see task 2.5 below).
- **Applicable rules**: no hardcoded strings; file ≤300 lines; no `any`.
- **Allowed exceptions**: none.
- **Plan-vs-code drift**:
  1. **Task 2.3 could not use `useEffect` as written.** The repo runs
     `react-hooks/set-state-in-effect` as an **error**, and the pre-existing
     `CreateExamWizard.tsx` already fails it. Implemented as *derived* state
     (`dateError` computed from `form.startDate`/`form.endDate`) gated on a `submitted`
     flag, which satisfies P5's requirement (error appears the moment `startDate` moves
     past `endDate`) without an effect. No auto-clear, per spec risk mitigation.
  2. **Task 2.5 is a no-op.** `CLASS_NAME_ALREADY_USED` already exists in
     `USER_FACING_ERROR_MESSAGES` with exactly the planned copy
     ("A class with this name already exists in this program."). Adding
     `DUPLICATE_CLASS_NAME` would have been a duplicate key. The generic
     `KIND_FALLBACKS.conflict` message already covers an unknown 409 code, so Q1's
     unknown backend code degrades gracefully. No consumer code needed.
  3. **Task 2.1 named three modals; only two match.** `CreateClassModal` and
     `EditClassModal` had the inline `!name.trim()` branch. `SplitClassModal` does not
     collect a class name (it only picks a subset of students), so there was nothing to
     migrate.
  4. **Phase 1's inline typed-confirm was migrated to the shared primitive in this
     phase** rather than deferred. `TypedConfirmInput` now exists in `packages/ui`, and
     `NonActiveTargetConfirm` wraps it; the match rule (`isTypedConfirmValid`, exact and
     case-sensitive) is exported from `@pte/ui` and is the single owner of that rule.

**Files written (Phase 2)**:
- Created: `features/classes/utils/validateClassName.ts`,
  `features/classes/utils/validateAddStudentInput.ts`,
  `packages/ui/src/components/TypedConfirmInput.tsx`
- Modified: `features/classes/components/CreateClassModal.tsx`,
  `features/classes/components/EditClassModal.tsx`,
  `features/classes/components/ImportOrAssignModal.tsx`,
  `features/classes/components/NonActiveTargetConfirm.tsx`,
  `features/classes/components/TransferStudentModal.tsx`,
  `features/classes/components/MergeClassesModal.tsx`,
  `features/classes/types/index.ts`,
  `features/programs/utils/validateCreateProgram.ts`,
  `features/programs/components/CreateProgramModal.tsx`,
  `features/programs/constants/index.ts`,
  `packages/ui/src/components/index.ts`

---

## Design Constraints

- **Unit-testable**: every validator is a pure function returning
  `string | undefined` (per-field) or an `Errors` object. **No React hooks
  inside validators**.
- **`useEffect` for P5** is the only React-side change in this phase; it
  watches `form.startDate` and runs a targeted sub-check on `endDate`
  without auto-clearing. Per spec risk mitigation.
- **TypedConfirmInput** is a controlled `Input` + `onValidChange(boolean)`
  callback. Used in Phase 1's transfer/merge modals (replace the inline
  typed-confirm with this primitive in a follow-up commit).
- **`DUPLICATE_CLASS_NAME` added to `USER_FACING_ERROR_MESSAGES`** — if
  backend emits a different code (Q1 in spec), fall back to existing
  `CLASS_NAME_ALREADY_USED` or generic message. The frontend is
  best-effort.
- **No `apps/tenant-web/` callers of TypedConfirmInput** in this phase —
  only the primitive itself. Phase 1's migration is a follow-up.

## Quality and Testing State

- **Quality**: not evaluated
- **Testing**: not started

---

## Tests to Write First (`--tdd`)

1. **`validateClassName`**:
   - `""` → "Name is required"
   - `"   "` → "Name is required"
   - `"12A1"` → `undefined`
2. **`validateCreateProgram`** (loosened):
   - Both `null` → no date errors
   - Same date → no date errors
   - `startDate > endDate` → "End date must be on or after start date"
   - Only `startDate` set → no error
   - Only `endDate` set → "Start date is required if end date is set"
3. **`validateAddStudentInput`** (mirrors `validateCreateLecturer`):
   - `email` empty → "Email is required"
   - `email` invalid → "Enter a valid email"
   - `fullName` empty → "Full name is required"
   - `studentCode`, `phone`, `dateOfBirth` empty → `undefined`
4. **`TypedConfirmInput`**:
   - Empty input → `onValidChange(false)`
   - Whitespace-only → `onValidChange(false)`
   - Exact match (case-sensitive) → `onValidChange(true)`
   - Mismatch → `onValidChange(false)`

## Tasks (in order)

### 2.1 — `validateClassName` (C2/C17 prep)

**New file**: `apps/tenant-web/features/classes/utils/validateClassName.ts`

```ts
export function validateClassName(name: string, label: string): string | undefined {
  if (!name.trim()) return CREATE_CLASS_ERRORS.nameRequired(label);
  return undefined;
}
```

Replace inline checks in `CreateClassModal.tsx:42`,
`EditClassModal.tsx`, and `SplitClassModal.tsx` (same pattern in all
three) with `const nameError = validateClassName(name, classLabel);`.

### 2.2 — `validateCreateProgram` loosening (P2, P4)

**File**: `apps/tenant-web/features/programs/utils/validateCreateProgram.ts`

Two changes:
1. Line 20: change `<=` to `<` so same-day is allowed.
2. Wrap both date-required checks in `if (input.startDate)` /
   `if (input.endDate)` so both-null is not an error.

Add unit test cases for: same-day, both-null, only start, only end, end
before start.

### 2.3 — `CreateProgramModal` re-validate on `startDate` change (P5)

**File**: `apps/tenant-web/features/programs/components/CreateProgramModal.tsx`

Add `useEffect(() => { /* targeted re-check on endDate */ }, [form.startDate])`.
Logic: if `form.endDate && new Date(form.endDate) < new Date(form.startDate)`,
set `errors.endDate = CREATE_PROGRAM_ERRORS.endDateBeforeStartDate`.

**No auto-clear** — show error, let user correct.

Test: change startDate to a date after endDate in the rendered form →
endDate field shows error.

### 2.4 — `validateAddStudentInput` (C31, S11)

**New file**: `apps/tenant-web/features/classes/utils/validateAddStudentInput.ts`

Mirrors `validateCreateLecturer.ts`:
- `email` required + pattern (reuse `EMAIL_PATTERN` from
  `validateCreateLecturer.ts`)
- `fullName` required (trim)
- other fields optional

**New types**: `AddStudentErrors` exported from
`apps/tenant-web/features/classes/types/index.ts`.

Wire into `ImportOrAssignModal.tsx`'s Add Individually tab:
`handleSubmit` calls `validateAddStudentInput(form);` first, sets field
errors if any, only fires the mutation when clean.

### 2.5 — `USER_FACING_ERROR_MESSAGES` addition (S8, AC9)

**File**: `packages/api-client/src/client/errorMessage.ts`

Add:
```ts
DUPLICATE_CLASS_NAME: "A class with this name already exists in this program.",
```

If backend emits `CLASS_NAME_ALREADY_USED` (line 75 already exists) the
existing entry covers it. **No new consumer code** — all three modals
render `errorMessage(mutation.error)` through `<Alert>` and pick up the
new entry automatically.

### 2.6 — `TypedConfirmInput` primitive

**New file**: `packages/ui/src/components/TypedConfirmInput.tsx`

```ts
export interface TypedConfirmInputProps {
  expectedValue: string;
  label: string;
  placeholder?: string;
  onValidChange: (valid: boolean) => void;
  disabled?: boolean;
}
```

Implementation: controlled `<Input>` with `type="text"`, lowercase
trim, `onValidChange={input === expectedValue}`. Render label as
`Type <expectedValue> to confirm`.

Match exact string (case-sensitive) per spec risk note.

### 2.7 — Verify

Run in repo root + each package:
- `pnpm lint`
- `pnpm typecheck`
- `pnpm --filter @pte/ui test` (TypedConfirmInput)
- `pnpm --filter tenant-web test` (validators)
- `pnpm build`

Manual:
- Create Program with same date → succeeds.
- Create Program with both dates empty → succeeds.
- Change startDate after endDate → endDate shows error.
- Add Student with empty email → field error.
- Add Student with valid email + name → submits.
- Trigger 409 on duplicate class name → "A class with this name already
  exists in this program." (requires backend support or mocked).

## Sub-tasks checklist

- [x] 2.1 — `validateClassName` + 2 modal migrations (SplitClassModal N/A)
- [x] 2.2 — `validateCreateProgram` loosening (tests skipped by user)
- [x] 2.3 — `CreateProgramModal` re-validation (derived, not `useEffect` — see Preflight)
- [x] 2.4 — `validateAddStudentInput` + types + modal wiring
- [x] 2.5 — no-op: `CLASS_NAME_ALREADY_USED` already present (see Preflight)
- [x] 2.6 — `TypedConfirmInput` primitive + Phase 1 migration to it
- [x] 2.7 — Lint / typecheck / build (tests skipped by user)

## Follow-up (not this phase)

- Replace inline typed-confirm in `TransferStudentModal` and
  `MergeClassesModal` (added in Phase 1) with `<TypedConfirmInput .../>`.