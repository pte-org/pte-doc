# Phase 4: iam — LECTURER + PROGRAM_COORDINATOR Roles + Cross-Service `@PreAuthorize` Audit

## Requirements

Adds `LECTURER` and `PROGRAM_COORDINATOR` as first-class `Role` enum values
("Lecturer is just like a Proctor" — a genuine new role, not folded into an
existing one), lets a Host create accounts with these roles, and — because
this enum is consumed by `@PreAuthorize` expressions across every service
in the repo — performs a real, reviewed audit of all 26
`@PreAuthorize`-bearing controllers to confirm nothing breaks.

Maps to: `plan.md` Decision 2; Research Summary items 6, 7.

## Design Constraints

- **This phase's own audit is necessarily partial, and that's expected —
  not a gap to paper over.** This phase is sequenced early (Phase 4 of 13);
  Phase 5's `LecturerAssignmentController`/`ProgramCoordinatorAssignmentController`
  and Phases 12/13's new controllers don't exist yet when this phase's
  audit runs, so they cannot be reviewed here. **Phase 13 (the last phase)
  is responsible for a final, consolidated re-audit** covering every
  `@PreAuthorize`-bearing file added by Phases 2/3/5/12/13 on top of this
  phase's original 26 — see Phase 13's own Design Constraints/Steps for the
  exact mechanics. This phase's own scope is: the original 26 files, the
  2 new enum values, and `HOST_ASSIGNABLE_ROLES`. Do not treat this
  phase's Success Criteria as "the audit is done" — it's the first,
  necessary pass, not the complete one.
- **This phase does not build any Lecturer/Coordinator-facing portal or new
  read access.** Per the feature spec, these roles exist so a Host can
  *assign* them to a Class/Program (Phase 5) — nothing in v1 requires a
  Lecturer or Coordinator to log in and see anything new themselves. The
  audit's job is confirming **no unintended widening**, not granting new
  access; any controller that should explicitly start allowing
  `LECTURER`/`PROGRAM_COORDINATOR` is only touched if this plan's own
  later phases need it (none currently do).
- `ResourceServerJwt.rolesConverter()`/`AccessTokenIssuer` are fully
  generic (Research Summary item 7) — adding 2 enum values needs no change
  there. Confirm this by reading both files again during the audit (don't
  just trust last session's research note without re-verifying against the
  current file state).
- The audit must be a real per-file review, not a mechanical find/replace —
  for each of the 26 files, read its actual `@PreAuthorize` expression(s)
  and classify: (a) explicit `hasRole`/`hasAnyRole` allow-list — safe by
  construction, no new role can be silently granted; (b) any
  exclusion-style check (`!hasRole(...)`) — would need explicit review
  since a new role could unintentionally pass a negative check; (c)
  anything else unusual. Record the classification for all 26 files in
  this phase's own Success Criteria checklist (not just "reviewed, all
  fine").
- `UserProvisioningHelper.HOST_ASSIGNABLE_ROLES` widening is the one real
  functional change in this phase — a `HOST_ADMIN` can now create
  `LECTURER`/`PROGRAM_COORDINATOR` accounts via the existing
  `POST /users` / `POST /users/bulk`, no new endpoint needed.
- FE: `packages/ui/src/hooks/sessionStorage.ts`'s `SessionRole` union gets
  the 2 new literals — `RequireAuth`/`DashboardChrome`'s `allowedRoles` is
  already array-based (Research Summary item 8), no other FE rework
  required by this phase itself.
- `ddl-auto: update` — the `roles` claim/`user_roles` collection table
  needs no schema change (it's an `@ElementCollection` of a Java enum
  stored as `EnumType.STRING`, which just accepts new string values).

## Steps

1. `services/iam/src/main/java/com/pte/iam/domain/enums/Role.java` — add
   `LECTURER`, `PROGRAM_COORDINATOR`.
2. `services/iam/src/main/java/com/pte/iam/service/UserProvisioningHelper.java`
   — widen `HOST_ASSIGNABLE_ROLES` to
   `EnumSet.of(Role.HOST_AUTHOR, Role.PROCTOR, Role.STUDENT, Role.LECTURER, Role.PROGRAM_COORDINATOR)`.
3. Audit pass — read and classify all 26 files found via
   `grep -r "@PreAuthorize" services/*/src/main/java pte-common/src/main/java`
   (list from this plan's own research: `ScoringReviewController`,
   `SessionController`, `ProctorAssignmentController`, `EnrollmentController`,
   `InternalMediaController`, `UserController`, `AttemptController`,
   `TenantController`, `OrganizationController`, `InternalSnapshotController`,
   `InternalExportController` [scoring], `InternalSessionController`,
   `InternalRebuildController`, `RebuildController`, `ReportController`,
   `ProctorRoleRequiredException`, `ProctorStompController`,
   `ViolationAuditController`, `ProctorSessionController`,
   `NotificationLogController`, `TimerController`,
   `InternalExportController` [exam-delivery], `SnapshotController`,
   `QuestionController`, `BlueprintController`, `ResourceServerJwt`). This
   is the *original 26 only* — Phases 2/3/5/12/13's own new controllers are
   explicitly out of this phase's scope (see Design Constraints); do not
   attempt to review not-yet-existing files here, and do not skip Phase
   13's later consolidated pass on the assumption this step already
   covered them.
4. Document the classification result inline in this phase file's Success
   Criteria (see below) — this is the actual audit deliverable, not a
   separate report file.
5. `packages/ui/src/hooks/sessionStorage.ts` — add `"LECTURER" | "PROGRAM_COORDINATOR"`
   to `SessionRole`.
6. Tests: extend `UserProvisioningHelperTest.java` (new, if none exists —
   check first) or the relevant existing test file covering
   `resolveAndAuthorizeRoles` — a `HOST_ADMIN` caller can now be granted
   `LECTURER`/`PROGRAM_COORDINATOR`; a `PLATFORM_ADMIN` caller is unaffected
   (already unrestricted).
7. `tsc --noEmit` on `@pte/ui` and `tenant-web` to confirm the widened
   union compiles cleanly everywhere it's consumed.

## Success Criteria

- [ ] All 26 of this phase's original `@PreAuthorize`-bearing files (see
      Step 3's list) are individually reviewed and classified; the
      classification is recorded in this file (append a table/list here
      once done) — zero files skipped, zero files marked "assumed fine"
      without being opened. (Files added by later phases are explicitly
      Phase 13's responsibility, not this phase's — see Design
      Constraints.)
- [ ] Zero controllers found with an exclusion-style (`!hasRole`) check
      that would unintentionally admit `LECTURER`/`PROGRAM_COORDINATOR` —
      or, if one is found, it's fixed and documented here, not silently
      left.
- [ ] A `HOST_ADMIN` can successfully create a `LECTURER` and a
      `PROGRAM_COORDINATOR` account via the existing `POST /users`.
- [ ] `mvn -pl services/iam test` passes.
- [ ] `pnpm --filter tenant-web build` and `pnpm --filter @pte/ui lint`
      both stay clean after the `SessionRole` widening.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after
  implementing this phase).
- Testing: not started.

## Risks

- The audit's value depends entirely on it being done thoroughly (Steps
  3-4) — the JWT/authority-mapping plumbing being generic (Research
  Summary item 7) is necessary but not sufficient proof nothing breaks;
  quality review for this phase should specifically re-verify a sample of
  the 26 files were actually opened and reasoned about, not just listed.
- This phase's audit is deliberately incomplete by construction (it can't
  see Phases 5/12/13's controllers) — the real completeness guarantee for
  the whole plan comes from Phase 13's consolidated re-audit, not from
  this phase alone. If Phase 13 is ever dropped/skipped, this residual gap
  must be called out explicitly, not silently absorbed.
