# Phase 12: admin + tenant-web — Class Merge/Split

## Requirements

Lets a Host bulk-move every student from one or more Classes into another
("merge"), or split one Class's roster into two Classes ("split"). Builds
directly on Phase 3's transfer primitive (update-the-membership-row-in-place),
just applied in bulk.

Maps to: `plan.md` Decision 4 (Class merge/split); Research Summary item 3
(transfer-in-place pattern), `plan.md` Risks (DataTable row-selection
unknown).

## Design Constraints

- **First step of this phase is a real check, not an assumption**: confirm
  whether `@pte/ui`'s `DataTable` component already supports multi-row
  selection (checkboxes + a "selected count" affordance). If it doesn't,
  add the minimal version needed (a `selectable`/`onSelectionChange` prop)
  rather than building a parallel one-off selection UI inside this
  feature's own components — this is a shared component, other future
  features will want the same capability.
- **Merge does not auto-archive the source Class(es)** — it only moves
  `ClassMembership` rows; the now-empty source Class remains as-is
  (Active/Inactive per its own status), and the Host can archive it
  separately via the existing Phase 2/7 archive action if desired. This is
  a deliberate choice (don't implicitly delete/hide structure the Host
  didn't explicitly ask to remove) — flag it to the user as a confirmable
  assumption, not a silent design call, since "merge" could reasonably be
  read as implying archival.
- **Split creates a genuinely new `StudentClass`** under the same `Program`
  as the source (not a different Program — splitting shouldn't relocate a
  cohort across the academic hierarchy), then transfers the selected subset
  of students into it. Reuses `ClassService.transfer(...)` internally in a
  loop (or a new `bulkTransfer(...)` method if looping individual
  `transfer()` calls would be N separate outbox events for what's
  conceptually one Host action — pick whichever keeps ADR-002's "one event
  per meaningful state change" spirit without over-engineering a
  batch-event-payload format; a `StudentClassSplitEvent` carrying the full
  list of moved `studentPublicId`s alongside N individual
  `StudentTransferredClassEvent`s is a reasonable middle ground).
- Same tenant-scope validation as every other Phase 2/3/5 endpoint —
  merge/split targets must all belong to the caller's own tenant, verified
  server-side, not just filtered client-side.
- No hardcoded strings in JSX; labels for "Merge"/"Split" actions are
  label-invariant (not affected by the Phase 6 org-type dictionary — these
  are action names, not Program/Class nouns).

## Steps

1. Research/verify: read `@pte/ui`'s `DataTable` source
   (`packages/ui/src/components/DataTable.tsx` or wherever it actually
   lives — locate it first) for existing selection support; document the
   finding at the top of this phase's implementation notes before writing
   any merge/split-specific code.
2. `services/admin`: `service/ClassService.java` — `mergeClasses(targetClassPublicId,
   sourceClassPublicIds, caller)` (bulk-updates every source's
   `ClassMembership` rows' FK to the target, in one transaction, one outbox
   event per moved student plus a single summary event); `splitClass(sourceClassPublicId,
   newClassName, studentPublicIdsToMove, caller)` (creates the new
   `StudentClass` under the same `Program`, then moves the specified
   subset).
3. `constant/AdminConstants.java` — `EVENT_CLASSES_MERGED`,
   `EVENT_CLASS_SPLIT`; matching event records.
4. `controller/ClassController.java` — `POST .../classes/{targetId}/merge`
   (body: `sourceClassPublicIds`), `POST .../classes/{sourceId}/split`
   (body: `newClassName`, `studentPublicIds`).
5. Tests: `ClassServiceTest.java` — merge moves every source student to
   the target (verified count before/after), source Class(es) remain
   un-archived and otherwise untouched; split creates a new Class with
   exactly the specified subset, leaves the remainder in the original
   Class; both reject cross-tenant targets.
6. `tenant-web`: `features/classes/components/{MergeClassesModal,SplitClassModal}.tsx`
   using the (possibly newly-extended) `DataTable` selection capability;
   wired into the Class detail/roster view from Phase 7/8.
7. `tsc --noEmit`, `eslint`, `next build`; `mvn -pl services/admin test`.

## Success Criteria

- [x] Merging Class A and B into Class C results in every A/B student now
      having a `ClassMembership` pointing at C, with A and B's own
      lifecycle status unchanged (not auto-archived).
- [x] Splitting Class C into C and a new Class D correctly partitions the
      roster — every selected student is in D, every unselected student
      remains in C, no student ends up in both or neither.
- [x] Both operations reject a source/target Class belonging to a
      different tenant.
- [x] `mvn -pl services/admin test` passes; `pnpm --filter tenant-web lint`/`build`
      clean.

## Quality and Testing State

- Quality gate: APPROVED, 0 findings on first pass. Reviewer independently
  verified: (1) merge's per-source `findOwned` call genuinely enforces
  same-Program/Organization/tenant for every participant, and a
  cross-tenant source throws before any membership row is touched;
  (2) the self-merge skip (`continue`) sits before the tenant-check and
  doesn't short-circuit validation of later, distinct source ids in the
  same list; (3) `splitClass` attaches the new Class to
  `sourceClass.getProgram()` (never a caller-supplied value — no such
  field even exists on the request DTO); (4) both methods are
  `@Transactional` with unchecked `DomainException`s, so a duplicate-name
  or cross-tenant rejection can never leave a partially-moved roster or an
  orphaned new Class; (5) `DataTable`'s new selection props are correctly
  additive/optional (verified against `SessionTable.tsx`, a pre-existing
  call site, still rendering unaffected) and the controlled-component
  pattern is followed correctly (no internal state in `DataTable` itself);
  (6) `ClassesSection`'s selection self-heals against a mid-selection
  refetch (a stale id just drops out, submit disables rather than sending
  garbage) and `ClassRosterTable` correctly keys by `membership.publicId`
  but sends `student.publicId` to the split API — the two different ids
  are not conflated; (7) `MergeClassesModal`'s target-radio recomputation
  has no stale-closure risk (fresh closures every render, plus
  `key`-forced remount on reopen). One test-coverage note (not a code
  defect) flagged for `ck:test`: no existing test mixes a valid and a
  cross-tenant source in the same multi-item merge list — correctness
  there holds by construction, just not directly exercised.
- Testing:
  - Backend: `mvn -pl services/admin -am test` — BUILD SUCCESS, 102/102
    (was 95 before this phase; 7 new tests in `ClassServiceTest.java`:
    merge moves every student across 2 sources + writes 1 event per moved
    student plus 1 summary event, merge rejects a cross-tenant source,
    merge rejects a cross-tenant target, merge silently no-ops a
    source-equals-target entry, split creates the new Class and moves only
    the selected subset, split rejects a duplicate name within the
    Program, split rejects a cross-tenant source).
  - Frontend: `pnpm --filter tenant-web lint` (clean), `pnpm --filter tenant-web build`
    (clean, same 6 routes — no new route needed, both flows are wired into
    existing Program/Class detail views), `pnpm --filter @pte/api-client typecheck`
    (clean), `pnpm --filter @pte/ui typecheck` (clean — `DataTable`'s new
    selection props are additive/optional, so every existing call site
    compiles unchanged).
- **Step 1 finding (required before any merge/split-specific UI code was
  written)**: read `packages/ui/src/components/DataTable.tsx` in full —
  confirmed it had NO multi-row selection support (no `selectable`/
  `onSelectionChange` prop, no checkbox column, nothing). Added the
  minimal version per the Design Constraint: `selectable`,
  `selectedKeys`/`onSelectionChange` (controlled, same pattern as every
  other input in `@pte/ui`), plus `selectAllLabel`/`selectRowLabel` for
  accessible per-checkbox `aria-label`s. All new props are optional and
  additive — every pre-existing `DataTable` call site across the app
  (verified via `pnpm --filter tenant-web build` — no other call site
  needed updating) compiles and renders identically with them omitted.
- **"Merge doesn't auto-archive" — confirmed with the user directly**
  (via AskUserQuestion) before implementing, not left as an unconfirmed
  assumption: the user chose "Không tự động archive" (no auto-archive),
  matching the plan's own default interpretation. Implemented exactly as
  specified — `mergeClasses` only updates `ClassMembership` rows.
- **Design decisions made during implementation, not fully specified by
  the phase's literal Steps**:
  - Merge's UI groups class-selection and target-selection into one flow:
    the Host checks 2+ Classes in the (now-selectable) `ClassesSection`
    table, then `MergeClassesModal` asks "merge into which one?" as a
    radio choice among exactly the checked Classes — the rest become
    `sourceClassPublicIds` automatically. This avoids a second, separate
    "pick a target" dropdown outside the selected set, which would let a
    Host pick a target that wasn't part of their original selection (a
    confusing state the Steps didn't call for).
  - Both `mergeClasses` and `splitClass` scope every participant Class via
    `findOwned(organizationPublicId, programPublicId, classPublicId,
    caller)` — the SAME `programPublicId` as the request path for every
    source/target. This means merge is restricted to Classes within one
    Program (never cross-Program), which the Steps didn't explicitly
    forbid but is consistent with the URL nesting
    (`.../programs/{programPublicId}/classes/{id}/merge`) and avoids the
    pedagogically-odd case of merging a Khối 11 Class into a Khối 12
    Class. Split was already explicitly required to stay within the same
    Program by the Design Constraints.
  - A `sourceClassPublicIds` entry equal to the target is silently
    skipped (no-op for that entry) rather than rejected — a Host could
    plausibly leave the target checked among their selection by habit;
    erroring on it would be needless friction for something with an
    obvious, safe interpretation.
  - `splitClass` silently ignores any `studentPublicId` in the request
    that isn't actually a member of the source Class (the repository
    query only returns real matches — nothing to filter or error on)
    rather than validating the input list against the roster first,
    mirroring `bulkAssign`'s existing forgiving-subset convention rather
    than inventing a new stricter validation style for this one endpoint.
  - Followed the Design Constraints' suggested event shape exactly: one
    `StudentTransferredClass` event per moved student (reusing the
    existing Phase 3 event type, not inventing a new one) plus one
    `ClassesMerged`/`ClassSplit` summary event per call.

## Risks

- `DataTable` selection support is a genuine unknown at plan-writing time —
  Step 1 resolves it before any dependent UI code is written, not after.
  Resolved: it did not exist; added minimally (see Quality and Testing
  State above).
- "Merge doesn't auto-archive" is this plan's own reasonable-but-unconfirmed
  interpretation — flagged for the user to confirm during quality review.
  Resolved: confirmed directly with the user before implementation (see
  Quality and Testing State above), not deferred to the quality gate.
