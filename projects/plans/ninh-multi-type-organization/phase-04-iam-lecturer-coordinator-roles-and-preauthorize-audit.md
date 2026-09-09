# Phase 4: iam — LECTURER + PROGRAM_COORDINATOR Roles + Cross-Service `@PreAuthorize` Audit

## Requirements

Adds `LECTURER` and `PROGRAM_COORDINATOR` as first-class `Role` enum values
("Lecturer is just like a Proctor" — a genuine new role, not folded into an
existing one), lets a Host create accounts with these roles, and — because
this enum is consumed by `@PreAuthorize` expressions across every service
in the repo — performs a real, reviewed audit of all `@PreAuthorize`-bearing
controllers to confirm nothing breaks (26 named at plan-writing time; 31
by the time this phase actually executed — see the audit table's
correction note).

Maps to: `plan.md` Decision 2; Research Summary items 6, 7.

## Design Constraints

- **This phase's own audit is necessarily partial, and that's expected —
  not a gap to paper over.** This phase is sequenced early (Phase 4 of 13);
  Phase 5's `LecturerAssignmentController`/`ProgramCoordinatorAssignmentController`
  and Phases 12/13's new controllers don't exist yet when this phase's
  audit runs, so they cannot be reviewed here. **Phase 13 (the last phase)
  is responsible for a final, consolidated re-audit** covering every
  `@PreAuthorize`-bearing file added by Phases 5/12/13 on top of this
  phase's 31 (Phases 2/3's files are already absorbed into this phase's own
  audit table, rows 27-31 — see its correction note; Phase 13 must still
  independently re-grep rather than trust "31" as a given baseline, per
  this file's Risks section) — see Phase 13's own Design Constraints/Steps
  for the exact mechanics. This phase's own scope is: the 31 files, the
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

- [x] All `@PreAuthorize`-bearing files that actually existed in the repo
      when this phase executed are individually reviewed and classified;
      the classification is recorded in this file — zero files skipped,
      zero files marked "assumed fine" without being opened. This turned
      out to be 31, not the 26 originally listed in Step 3 (that list was
      a plan-writing-time snapshot; Phases 2/3, already implemented and
      committed by the time this phase ran, had added 5 more — see the
      audit table's correction note and rows 27-31). Files from phases not
      yet implemented at all (5/12/13) remain Phase 13's responsibility.
- [x] Zero controllers found with an exclusion-style (`!hasRole`) check
      that would unintentionally admit `LECTURER`/`PROGRAM_COORDINATOR` —
      or, if one is found, it's fixed and documented here, not silently
      left.
- [x] A `HOST_ADMIN` can successfully create a `LECTURER` and a
      `PROGRAM_COORDINATOR` account via the existing `POST /users`.
- [x] `mvn -pl services/iam test` passes.
- [x] `pnpm --filter tenant-web build` stays clean after the `SessionRole`
      widening. (`pnpm --filter @pte/ui lint` as originally written in
      Step 7 does not exist — `packages/ui/package.json` only defines a
      `typecheck` script, no `lint` script; ran
      `pnpm --filter @pte/ui typecheck` instead, which is the actual
      equivalent check and passes clean. Documented here rather than
      silently skipped.)

### Audit table (Step 3/4 — original 26 files)

All 26 read in full. Classification legend: **(a)** explicit
`hasRole`/`hasAnyRole` allow-list, safe by construction — a new enum value
is never implicitly granted; **(b)** exclusion-style check; **(c)**
something else.

**Correction (post-quality-gate):** the Step 3 grep that produced this
26-file list was run against the plan-writing-time snapshot of the repo,
not re-run against the tree as it actually stood when this phase executed.
By execution time, Phases 2 and 3 (both already implemented and committed
earlier in this same plan) had added 5 more `@PreAuthorize`-bearing
controllers that the original list never named — the Design Constraints'
carve-out only names Phase 5/12/13 as "don't exist yet," which correctly
implies Phases 1-3's controllers (already built by the time Phase 4 runs)
were always in scope, not excluded. The quality gate caught this
undercount; all 5 are added below (rows 27-31) rather than left
unaudited. Total is **31 files**, not 26.

| # | File | Service | Expression(s) | Class |
|---|------|---------|----------------|-------|
| 1 | `ScoringReviewController` | scoring | `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')` | (a) |
| 2 | `SessionController` | scheduling | class: `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`; 2 methods: `hasRole('HOST_ADMIN')` | (a) |
| 3 | `ProctorAssignmentController` | scheduling | `hasRole('HOST_ADMIN')` | (a) |
| 4 | `EnrollmentController` | scheduling | class: `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`; 1 method: `hasRole('HOST_ADMIN')` | (a) |
| 5 | `InternalMediaController` | media | `hasRole('INTERNAL_SERVICE')` | (a) |
| 6 | `UserController` | iam | class: `hasAnyRole('PLATFORM_ADMIN','HOST_ADMIN')`; 1 method: `hasRole('PLATFORM_ADMIN')`; `resetPassword` has no method override — delegated to `UserService#resetPassword`'s `HOST_RESETTABLE_ROLES.containsAll(...)` check (also an allow-list, currently `{STUDENT, PROCTOR}` — a Host still cannot reset a Lecturer/Coordinator's password; that's an existing restriction, not a regression, and out of this plan's scope to widen) | (a) |
| 7 | `AttemptController` | exam-delivery | `hasRole('STUDENT')` | (a) |
| 8 | `TenantController` | admin | `hasRole('PLATFORM_ADMIN')` | (a) |
| 9 | `OrganizationController` | admin | `hasRole('PLATFORM_ADMIN')` | (a) |
| 10 | `InternalSnapshotController` | authoring | `hasRole('INTERNAL_SERVICE')` | (a) |
| 11 | `InternalExportController` | scoring | `hasRole('INTERNAL_SERVICE')` | (a) |
| 12 | `InternalSessionController` | scheduling | `hasRole('INTERNAL_SERVICE')` | (a) |
| 13 | `InternalRebuildController` | reporting | `hasRole('INTERNAL_SERVICE_BOOTSTRAP')` | (a) |
| 14 | `RebuildController` | reporting | `hasRole('HOST_ADMIN')` | (a) |
| 15 | `ReportController` | reporting | `hasAnyRole('STUDENT','HOST_ADMIN','HOST_AUTHOR','PLATFORM_ADMIN','PLATFORM_AUTHOR')` | (a) |
| 16 | `ProctorRoleRequiredException` | proctor | Not a check site — the exception type thrown by #17's manual check; listed for completeness | (c), no-op |
| 17 | `ProctorStompController` | proctor | `@PreAuthorize` doesn't enforce on `@MessageMapping`; manual check `if (!currentUser.hasRole("PROCTOR")) throw ...` in one shared `currentUser(Principal)` helper every handler routes through. Syntactically a negation, but semantically a single-role allow-list (reject unless exactly `PROCTOR`) — functionally identical to `hasRole('PROCTOR')`, not a "reject on some other condition" pattern. `LECTURER`/`PROGRAM_COORDINATOR` still fail this check. Confirmed via repo-wide grep for `!.*hasRole` — this is the only such site in the entire codebase. | (b)-shaped, (a)-safe |
| 18 | `ViolationAuditController` | proctor | `hasAnyRole('PROCTOR','HOST_ADMIN','HOST_AUTHOR')` | (a) |
| 19 | `ProctorSessionController` | proctor | `hasRole('PROCTOR')` | (a) |
| 20 | `NotificationLogController` | notification | `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')` | (a) |
| 21 | `TimerController` | exam-delivery | `hasRole('STUDENT')` | (a) |
| 22 | `InternalExportController` | exam-delivery | `hasRole('INTERNAL_SERVICE')` | (a) |
| 23 | `SnapshotController` | authoring | `hasAnyRole('PLATFORM_ADMIN','PLATFORM_AUTHOR','HOST_ADMIN','HOST_AUTHOR')` | (a) |
| 24 | `QuestionController` | authoring | `hasAnyRole('PLATFORM_ADMIN','PLATFORM_AUTHOR','HOST_ADMIN','HOST_AUTHOR')` | (a) |
| 25 | `BlueprintController` | authoring | `hasAnyRole('PLATFORM_ADMIN','PLATFORM_AUTHOR','HOST_ADMIN','HOST_AUTHOR')` | (a) |
| 26 | `ResourceServerJwt` | pte-common | Not a check site — maps the JWT `roles` claim to `ROLE_*` authorities generically (`setAuthoritiesClaimName`/`setAuthorityPrefix`, no hardcoded role list). Re-read in full this session (not trusted from prior research note) — confirmed unchanged and still fully role-agnostic. `AccessTokenIssuer.java` (iam) also re-read: `user.getRoles().stream().map(Role::name).toList()` — also fully generic, no switch/hardcoded list. | (c), confirmed generic |
| 27 | `ClassController` | admin (Phase 3) | `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`, no method-level overrides | (a) |
| 28 | `ClassMembershipController` | admin (Phase 3) | `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')` | (a) |
| 29 | `HostOrganizationController` | admin (Phase 2) | `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')` | (a) |
| 30 | `ProgramController` | admin (Phase 2) | `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')`, no method-level overrides | (a) |
| 31 | `StudentEnrollmentController` | scheduling (Phase 3) | `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')` | (a) |

**Result: zero files in category (b)** (a true exclusion-style check that
would unintentionally admit a new role), across all 31. File #17's manual
check is syntactically negated but semantically an allow-list of one,
confirmed by a repo-wide `grep` for any other `!.*hasRole` pattern in
`services/*/src/main/java` and `pte-common/src/main/java` — no other hits.
No fix was needed anywhere.

## Quality and Testing State

- Quality gate: APPROVED after fix (1 HIGH found + fixed — QUAL-001: the
  audit's file list/count (26) was a plan-writing-time snapshot, not
  re-verified against the tree as it stood when this phase actually
  executed; Phases 2/3, already committed by then, had added 5 more
  `@PreAuthorize` controllers that were never named or classified. Closed
  by re-running the grep, adding rows 27-31 to the audit table, and
  correcting every "26" reference in this file to 31 — all 5 turned out to
  be the same safe `hasAnyRole('HOST_ADMIN','HOST_AUTHOR')` allow-list
  pattern as the original 26, so no unintended widening actually existed,
  but the audit's completeness claim needed to be honest about what it
  actually covered).
- Testing: done — `UserProvisioningHelperTest` (new, 8 tests — no test of
  this class existed before; `UserServiceTest` mocks it out entirely, so
  `resolveAndAuthorizeRoles`'s actual `HOST_ASSIGNABLE_ROLES` allow-list
  logic was previously untested by anything). `mvn -pl services/iam -am
  test` — BUILD SUCCESS, 34/34. `pnpm --filter @pte/ui typecheck` — clean.
  `pnpm --filter tenant-web build` — clean (TypeScript + Turbopack build
  both succeed).

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
- **Realized risk, now fixed**: this phase's own file list (Step 3) was
  written once at plan-creation time and then trusted verbatim during
  execution instead of being re-derived — by execution time Phases 2/3 had
  already added 5 more `@PreAuthorize` files that the stale list didn't
  name (see the audit table's correction note, rows 27-31). **Phase 13
  must independently re-run its own `grep -r "@PreAuthorize"` against the
  tree at that time rather than trusting this phase's "31" as a given
  baseline** — the same staleness failure mode could recur if any phase
  between now and Phase 13 adds more `@PreAuthorize` sites.
