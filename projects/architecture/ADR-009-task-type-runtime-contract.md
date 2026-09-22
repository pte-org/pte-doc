# ADR-009: Versioned Task-Type Runtime Contract

**Date:** 2026-09-22
**Status:** Accepted
**Scope:** `pte-api`, `pte-web`, `pte-app`

## Context

The platform already had a PTE task-type catalog, score templates, generated
snapshots and Flutter task screens. The catalog is backed by the enum-defined
standard PTE vocabulary, while the client dispatcher contains the actual
interaction implementations. Treating a catalog label as an arbitrary new
question type would allow a persisted row to claim behavior that no backend
scorer or app renderer can execute.

The V40 migration also renamed three fill-in-the-blanks codes while older data
and clients may still send the legacy names. A published exam must not change
because the mutable catalog or a later template activation changes.

## Decision

1. `PteTaskType` remains the MVP vocabulary authority. The database catalog and
   `/api/v1/question-types` endpoint remain compatibility surfaces, but new
   writes use canonical codes and only the three approved legacy aliases are
   read through `LEGACY_PTE_V1`.
2. Each standard task type resolves to a versioned, allowlisted runtime profile
   containing behavior, renderer, answer-schema, scoring and capability keys.
   Database values select a known profile; they cannot name a Java/Dart class,
   script or executable scoring formula.
3. Template activation stores the resolved runtime/profile pins. Snapshot
   publication copies the complete runtime provenance into immutable snapshot
   items. Attempt delivery reads that pinned data and never resolves behavior
   from the live catalog.
4. `taskTypeCode` and the nested `runtime` object are additive API fields.
   Existing `taskType` remains present during the compatibility window. The
   pte-app prefers the additive fields and falls back through one alias mapper.
5. Capability preflight is non-mutating; attempt start repeats the authoritative
   check. Unsupported renderer/schema or missing capability blocks before start
   and cannot silently advance to another task.
6. Platform Author can create/edit/submit drafts; Platform Admin activates or
   retires versions. An active or retired version is corrected by cloning a new
   draft rather than editing in place.
7. Strict manifest enforcement is enabled by changing
   `ATTEMPT_ALLOW_LEGACY_MISSING_MANIFEST` to `false` only after the dual-read
   app release and compatibility telemetry review.

## Migration and rollout

The verified migration head is V48. V44 seeds the 23 standard catalog rows;
V45 adds runtime profiles/template pins; V46 adds platform audit support; V47
adds snapshot capability provenance; V48 adds attempt template-version
provenance. All migrations are forward-only and additive for shared data.

Release order is pte-app dual-read support, BE migrations/readers, template and
snapshot pinning, vendor-web UX, then strict enforcement. Rollback disables the
flag first and retains columns/readers/snapshot data; it does not delete volumes
or reverse applied migrations.

## Consequences

Configuration-only changes to an existing profile can be represented by a new
template/version without a pte-app deployment. A genuinely new interaction,
answer schema, capability or scoring algorithm requires coordinated BE and
pte-app code plus a new immutable profile version. This is deliberate: it keeps
runtime behavior executable and reviewable instead of turning the database into
an untrusted plugin system.

The compatibility adapter and legacy fields remain until supported-client and
historical-snapshot inventory proves they are unused and a breaking release is
approved. The current local verification proves migrations, source contracts
and automated cross-repo checks; authenticated browser walkthrough remains an
operator handoff step requiring approved credentials.
