# Phase 01 — URL builder utility + constants

**Files touched:**
- `apps/tenant-web/features/classes/utils/assignStudentsUrl.ts` — CREATE
- `apps/tenant-web/features/studentSearch/constants/index.ts` — EDIT (add `ASSIGN_DEEPLINK_TEXT`)

**Spec FRs:** FR-02, FR-09
**User stories:** P1 (navigate to pre-filled Students page)
**Tests:** skipped by user. **Quality gate:** skipped by user (`--checks-all-phases` applied). `--no-tests --no-quality`

**Build gate:** PASS (tsc --noEmit clean, eslint clean on both files).
**Quality:** skipped_by_user; decision: user_confirmed_skip
**Testing:** not_started; user declined

**Preflight:** Repository conventions confirmed — `features/classes/utils/` uses pure functions without React imports (see `validateCreateLecturer.ts`). `features/studentSearch/constants/index.ts` uses `as const` exports with template function pattern (e.g. `MANAGE_STUDENTS_TEXT.accountsCreated(count)`). New utility file matches these conventions; new constant export follows existing template-function pattern. No cross-feature re-exports needed (each feature owns its own utils/constants).

---

## Design Constraints

### File structure

**New file: `features/classes/utils/assignStudentsUrl.ts`**

Place alongside the existing `validateCreateLecturer.ts` in `features/classes/utils/`. The function is a pure utility — no hooks, no React.

```ts
// apps/tenant-web/features/classes/utils/assignStudentsUrl.ts

export interface AssignStudentsContext {
  organizationPublicId: string;
  programPublicId: string;
  classPublicId: string;
}

/**
 * Builds the deeplink URL for the Assign Students flow.
 *
 * Produces: /host/students?organizationPublicId={o}&programPublicId={p}&classPublicId={c}&modal=add
 *
 * @param basePath  Always "/host/students" — provided explicitly for clarity.
 * @param ctx       The three required IDs.
 * @returns         Full search-param URL string.
 */
export function buildAssignStudentsUrl(
  basePath: "/host/students",
  ctx: AssignStudentsContext,
): string {
  const params = new URLSearchParams({
    organizationPublicId: ctx.organizationPublicId,
    programPublicId: ctx.programPublicId,
    classPublicId: ctx.classPublicId,
    modal: "add",
  });
  return `${basePath}?${params.toString()}`;
}
```

**Rules:**
- Do NOT use `router.push(buildAssignStudentsUrl(...))` inside this file — keep it as a pure string builder.
- The `modal=add` param signals to `StudentSearchView` that it should auto-open the modal. Phase 03 reads this param.
- Export `AssignStudentsContext` type — it is reused as the shape of the `onAssignStudents` callback in Phase 02.

### Constants additions

**Edit: `features/studentSearch/constants/index.ts`**

Add a new export at the bottom:

```ts
export const ASSIGN_DEEPLINK_TEXT = {
  backToClass: (name: string) => `← Back to ${name}`,
  lockedFilterBanner: (name: string) =>
    `Showing students for ${name}. Clear filter to add to other classes.`,
  clearFilter: "Clear filter",
  classBlocked: (status: string, name: string) =>
    `Class ${name} is ${status}. Activate it from the Program detail before assigning students.`,
} as const;
```

**Rules:**
- All strings are templates — no hardcoded user-facing text in components.
- `status` in `classBlocked` is the raw `ClassResponse.status` value (e.g. `"INACTIVE"`, `"SUSPENDED"`).
- `name` is the class display name fetched from the class metadata.

### Edge cases

- **Empty string IDs:** The function does NOT guard against empty strings. Callers in Phase 02 always pass non-empty values. If an empty `organizationPublicId` is passed, the resulting URL would have an empty param value — this is a caller error, not a utility error.
- **Special characters in IDs:** `URLSearchParams` handles encoding automatically.

### Dependencies

- No new dependencies. Uses only native `URLSearchParams` and TypeScript.
- No API calls, no React hooks.

---

## Quality and Testing State

### What to verify after cooking Phase 01

1. **`buildAssignStudentsUrl` output shape:**
   ```ts
   const url = buildAssignStudentsUrl("/host/students", {
     organizationPublicId: "org-abc",
     programPublicId: "prog-123",
     classPublicId: "cls-456",
   });
   expect(url).toBe(
     "/host/students?organizationPublicId=org-abc&programPublicId=prog-123&classPublicId=cls-456&modal=add"
   );
   ```
   (Unit test, no server, no DB.)

2. **`ASSIGN_DEEPLINK_TEXT` exports are present and are template functions:**
   ```ts
   expect(typeof ASSIGN_DEEPLINK_TEXT.backToClass).toBe("function");
   expect(ASSIGN_DEEPLINK_TEXT.backToClass("P.304")).toBe("← Back to P.304");
   expect(ASSIGN_DEEPLINK_TEXT.classBlocked("SUSPENDED", "P.304")).toContain("SUSPENDED");
   ```

3. **TypeScript compilation:** `tsc --noEmit` passes on the new file.

4. **No regressions:** existing constant exports in `studentSearch/constants/index.ts` are unchanged (grep for `export const` count before/after).

### Cook pipeline checks (default, no TDD)

| Check | Command | Expected |
|-------|---------|----------|
| TypeScript | `pnpm --filter tenant-web exec tsc --noEmit` | No errors |
| ESLint | `pnpm --filter tenant-web exec eslint features/classes/utils/assignStudentsUrl.ts features/studentSearch/constants/index.ts` | No errors |
| Test (if `--tdd`) | Vitest unit tests above | All pass |
