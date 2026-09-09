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

- [ ] Merging Class A and B into Class C results in every A/B student now
      having a `ClassMembership` pointing at C, with A and B's own
      lifecycle status unchanged (not auto-archived).
- [ ] Splitting Class C into C and a new Class D correctly partitions the
      roster — every selected student is in D, every unselected student
      remains in C, no student ends up in both or neither.
- [ ] Both operations reject a source/target Class belonging to a
      different tenant.
- [ ] `mvn -pl services/admin test` passes; `pnpm --filter tenant-web lint`/`build`
      clean.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

## Risks

- `DataTable` selection support is a genuine unknown at plan-writing time —
  Step 1 resolves it before any dependent UI code is written, not after.
- "Merge doesn't auto-archive" is this plan's own reasonable-but-unconfirmed
  interpretation — flagged for the user to confirm during quality review.
