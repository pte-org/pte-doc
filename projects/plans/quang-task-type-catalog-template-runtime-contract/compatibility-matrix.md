# Runtime Contract Compatibility Matrix

Date: 2026-09-22
Scope: `pte-api` V48, `pte-web` vendor-web/API client, and `pte-app` runtime
registry. This is a source-level rollout matrix; it does not imply a deployed
release.

## Wire and storage compatibility

| Surface | Legacy contract | Additive contract | Policy during compatibility window |
|---|---|---|---|
| Catalog endpoint | `/api/v1/question-types`, existing request/response fields | Optional runtime/profile/readiness fields and task-type aliases in the client | Keep the path, table and old client functions. New writes use canonical PTE codes. |
| Task response | `taskType` | `taskTypeCode` plus nullable `runtime` | New app prefers the additive fields and falls back to the single legacy alias mapper. |
| Template item | String task type, count/order/timing/weight | Pinned runtime/profile fields | Server re-derives the profile from the allowlist; client values never define executable behavior. |
| Snapshot item | Frozen question/task payload | Frozen renderer, behavior, schema, scoring and capability provenance | Delivery reads the snapshot/pinned item only; it does not join the mutable catalog. |
| Attempt preflight | No preflight call in older clients | `POST /api/v1/attempts/preflight` with bounded capability manifest | Missing manifests are grandfathered only for legacy snapshots while the flag is enabled. |
| Attempt start | Existing `POST /api/v1/attempts` body | Optional capability manifest and authoritative compatibility check | The server repeats the check before creating or resuming an attempt. |

## Canonical code aliases

| Legacy read value | Canonical write/read value | Mapping version | New persistence |
|---|---|---|---|
| `FILL_BLANKS_READING_WRITING` | `FILL_IN_THE_BLANKS_DROPDOWN` | `LEGACY_PTE_V1` | Canonical only |
| `FILL_BLANKS_READING` | `FILL_IN_THE_BLANKS_DRAG_AND_DROP` | `LEGACY_PTE_V1` | Canonical only |
| `FILL_BLANKS_LISTENING` | `FILL_IN_THE_BLANKS_TYPE_IN` | `LEGACY_PTE_V1` | Canonical only |

Unknown aliases are reported and blocked. They are never guessed from a
display label or from the current catalog.

## Minimum compatible source baselines verified locally

| Component | Minimum baseline used for this verification | Result |
|---|---|---|
| Backend | Flyway V48 plus the working-tree runtime/profile/snapshot changes | Compile passed; focused 52 and full 774 backend tests passed; local app healthy. |
| API client/vendor-web | Working-tree additive adapter and readiness UX; Next.js 16.2.9 | API-client 269 tests, typecheck and vendor-web build passed; lint passed with one unrelated existing `<img>` warning. |
| pte-app | Working-tree task registry, dual-read task view and capability manifest | `flutter analyze` clean; full Flutter suite 553 passed. |

No commit, tag or deployment identifier is assigned by this verification.

## Lifecycle and role matrix

| Operation | Platform Author | Platform Admin | Tenant/Host | Student app |
|---|---:|---:|---:|---:|
| Read standard catalog | Yes | Yes | No mutation; consume only where exposed | Receives pinned runtime only |
| Create/edit draft template | Yes | Yes | No | No |
| Submit template for approval | Yes | Yes | No | No |
| Activate/retire template | No | Yes | No | No |
| Change runtime renderer/scoring behavior | No | No through data entry | No | Requires coordinated BE + app release |
| Start incompatible snapshot | N/A | N/A | N/A | Block before start; show update/configuration guidance |

The role rows are backed by existing server authorization and lifecycle tests;
an authenticated browser walkthrough is still pending approved local test
credentials.

## Rollout order and removal conditions

1. Release the pte-app dual-read registry and capability manifest.
2. Release BE V48 additive readers/migrations and keep `taskType`.
3. Verify V44 idempotent catalog backfill and runtime profile readiness.
4. Release snapshot/template pinning, then vendor-web terminology/readiness UX.
5. Keep `ATTEMPT_ALLOW_LEGACY_MISSING_MANIFEST=true` until compatibility and
   unsupported-preflight telemetry is acceptable; set it to `false` to enforce
   manifests for every new-runtime snapshot.
6. Remove legacy aliases only after all supported app versions and historical
   snapshots are inventoried, no legacy reads remain, and a breaking-release
   decision is approved. This plan does not remove them.
