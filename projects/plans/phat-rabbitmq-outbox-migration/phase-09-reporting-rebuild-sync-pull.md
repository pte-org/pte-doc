# Phase 9: Reporting Read-Model Rebuild — Sync Pull Replaces Kafka Replay

## Requirements

Correction (plan-reviewer finding, ACCEPTED — see `plan.md` Overview): reporting has never had a working rebuild/replay trigger in code — its consumers (`AttemptIngestConsumer`, `AnswerScoredConsumer`, `PublishConsumer`) only ever ran steady-state, single consumer group. Kafka's retention made a from-scratch rebuild theoretically possible, but nothing in reporting ever exercised it. This phase is not replacing a working feature — it is building reporting's first-ever rebuild capability, needed because once Kafka is gone (Phase 10), a from-scratch reconstruction of a lost/corrupted read model has no other path. The mechanism: an internal-only synchronous REST pull — the 6 producing services reporting's projections are sourced from (exam-delivery, scoring, scheduling, iam, authoring, proctor) each expose a paginated `/internal/**` export endpoint, and a new rebuild trigger in reporting calls all 6 on demand.

## Design Constraints

- Reuse the existing `/internal/**` + shared-key `InternalApiKeyFilter` (`pte-common`) pattern already established for service-to-service calls (Milestone 1 Phase 5, retrofitted into authoring/scheduling, exam-delivery's own gate) on a separate `SecurityFilterChain` ahead of the JWT chain — do not invent a new auth mechanism for these 6 endpoints.
- Pagination/cursor contract (confirmed by user, see `plan.md` Research Summary): monotonic `(updatedAt, publicId)` keyset cursor, `GET /internal/{resource}/export?since={cursor}&limit=`. All 6 services implement the identical shape so reporting's rebuild client code is uniform, not 6 bespoke integrations.
- Every export query is tenant-scoped — no endpoint may return another tenant's rows on a single page, even internally. Two distinct trigger identities, two distinct scoping rules (plan-reviewer finding, ACCEPTED — the single-JWT-forwarding rule below cannot cover the bootstrap case, so both must be specified explicitly):
  - **Operator-invoked, single-tenant recovery**: reporting passes the tenant context explicitly, resolved from the triggering host's own validated JWT (existing internal-call identity-forwarding rule) — never a blanket cross-tenant export in this path.
  - **New-instance full bootstrap** (empty reporting DB, no single tenant's JWT is driving this — it's a system/operator action spanning every tenant): authenticated with a distinct internal service-identity credential (same `InternalApiKeyFilter` shared-key mechanism, but a separate scope/claim than the per-tenant-forwarding calls) explicitly authorized to enumerate all tenants. The 6 export endpoints accept an optional "all tenants" mode ONLY when called with this bootstrap credential — the per-tenant-JWT-forwarding calls above can never use it. Reporting itself must enumerate the tenant list for this mode (e.g. from its own already-known tenant registry, or an iam export) rather than an unscoped `SELECT *` on the producing service.
- This endpoint is REBUILD-only, triggered rarely (a new reporting instance bootstrapping, or an operator-invoked recovery) — it does not replace the steady-state event-driven ingestion from Phases 3–7; those consumers remain the normal path.
- Reporting's rebuild trigger becomes: for each of the 6 services, page through the export endpoint from the beginning, re-derive the same projection updates its normal consumers would have applied, until each service reports no more pages.

## Files to touch

- `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/controller/` — new internal export controller (`AttemptSubmitted`/`AnswerSubmitted`-equivalent data)
- `pte-api/services/scoring/src/main/java/com/pte/scoring/controller/` — new internal export controller (`AnswerScored`-equivalent data)
- `pte-api/services/scheduling/src/main/java/com/pte/scheduling/controller/` — new internal export controller (`PublishRequested`/session state-equivalent data)
- `pte-api/services/iam/src/main/java/com/pte/iam/controller/` — new internal export controller (if reporting's projection needs iam-sourced data; confirm scope against reporting's actual projection fields before building)
- `pte-api/services/authoring/src/main/java/com/pte/authoring/controller/` — new internal export controller (if needed — confirm scope, reporting carries its own copy of `task-skill-mapping.json` already and may not need a live authoring pull)
- `pte-api/services/proctor/src/main/java/com/pte/proctor/controller/` — new internal export controller (if needed — confirm scope against what reporting's projection actually consumes from proctor today)
- `pte-api/services/reporting/src/main/java/com/pte/reporting/` — new rebuild orchestration (client calls to all 6, replacing the Kafka-replay-based rebuild trigger)

## Steps

1. Cursor contract confirmed (plan.md Research Summary): monotonic `(updatedAt, publicId)` keyset, `GET /internal/{resource}/export?since={cursor}&limit=`, identical shape across all 6 services — implement directly, no further confirmation needed.
2. Confirm, per producing service, exactly which fields reporting's projection actually needs (cross-check against `AttemptReport`/`AnswerProjection`'s existing columns from Milestone 1 Phase 8) — do not export a service's full aggregate if reporting only ever consumed a subset via events.
3. Implement the identical-shaped paginated export endpoint per service, behind the existing `/internal/**` + `InternalApiKeyFilter` gate, tenant-scoped.
4. Build reporting's rebuild orchestration: sequentially (or per-service in parallel, implementer's choice) page through each of the 6 endpoints from the start, applying the same upsert logic the steady-state consumers use (reuse that logic directly, don't duplicate it).
5. Build the rebuild trigger from scratch (an internal/ops-facing endpoint or startup flag — implementer's choice, no prior equivalent exists to match) to call the new orchestration. Support both trigger identities from Design Constraints: single-tenant (per-tenant JWT forwarded) and full-bootstrap (internal service-identity credential, all-tenant enumeration).
6. Verify a full rebuild against a populated dataset produces the same `AttemptReport`/`AnswerProjection` state as steady-state event consumption would have.

## Success Criteria

- Each of the 6 producing services exposes a working, tenant-scoped, `/internal/**`-gated paginated export endpoint.
- Triggering reporting's rebuild against a populated multi-tenant dataset reconstructs a read model identical to what steady-state consumption already produced, with no cross-tenant leakage.
- The rebuild endpoints are unreachable without the internal shared-key credential (verified by a direct call without it returning unauthorized).
- No endpoint here is reachable from outside the internal network boundary / gateway's public routes.
- The full-bootstrap (all-tenant) credential is rejected by any code path other than the explicit bootstrap orchestration — a per-tenant-JWT-forwarding call can never widen into an all-tenant export by supplying the bootstrap credential instead.

## Testing

Normal testing expectations, not TDD-first, not skipped:

- Per producing service: integration test that the export endpoint paginates correctly (multiple pages, correct cursor advancement, no duplicate/missing rows) and is tenant-scoped (a different tenant's data never appears).
- Auth test: the endpoint rejects calls missing or with an invalid internal shared-key.
- Bootstrap-credential scope test: a per-tenant-forwarding call cannot escalate to all-tenant mode; the all-tenant mode is reachable only via the distinct bootstrap credential.
- reporting: an end-to-end rebuild test against a seeded multi-tenant dataset, asserting the rebuilt projection matches a known-good baseline (e.g. produced by steady-state consumption in a prior test run).
- Full reactor build stays green.

## Risks

- HIGH: New internal API surface reachable across 6 services is a real attack surface if the internal-network/shared-key boundary is misconfigured — treat with the same rigor as any authenticated endpoint, not as an afterthought because it's "internal-only". Mitigation: reuse the proven `InternalApiKeyFilter` pattern exactly, explicit auth test per endpoint (Testing above).
- MEDIUM: Fan-out to 6 services for one feature is the largest single-phase blast radius in this plan if the cursor contract is wrong and must be redone. Mitigation: Step 1 explicitly confirms the contract before any implementation starts.
- LOW: Some of the 6 listed services (iam, authoring, proctor) may turn out not to be needed once reporting's actual projection fields are cross-checked (Step 2) — acceptable scope reduction, not a defect if fewer than 6 endpoints end up necessary.
