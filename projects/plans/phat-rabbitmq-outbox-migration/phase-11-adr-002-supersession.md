# Phase 11: ADR-002 Supersession — Document the RabbitMQ-Only Architecture

## Requirements

`ADR-002-communication-and-exam-submission-saga.md` currently describes Kafka+Debezium as the event backbone and Kafka-based replay as reporting's rebuild mechanism — both now inaccurate after Phases 1–10. This phase rewrites those sections to describe the implemented architecture (RabbitMQ-only backbone, polling-outbox-relay mechanism, sync-pull rebuild), while explicitly preserving the parts of ADR-002 that are still accurate: the host-gated scoring lifecycle and the saga state model, neither of which this migration touches.

## Design Constraints

- Do not silently rewrite ADR-002 in place with no trace of the prior decision — mark the document as superseded-in-part, dated, with a clear pointer to this migration plan as the reason, following whatever supersession convention the rest of `pte-doc/projects/architecture/` already uses (check sibling ADRs for the convention before inventing one).
- Preserve verbatim (or near-verbatim, only updating cross-references) ADR-002's "Scoring lifecycle — HOST-GATED, không tự động" section and its state model diagram — this migration changes transport, not the saga's business semantics.
- Preserve the "Kafka vs RabbitMQ — vai tách bạch" (role separation) table's underlying principle (event backbone vs. work queue are different concerns) even though Kafka itself is gone — reframe it as "outbox-relay-over-RabbitMQ vs. work-queue-over-RabbitMQ" since both now run on the same broker technology but remain functionally distinct (exchanges/queues never shared between the two purposes, per Phase 6's explicit separation constraint).
- Replace every reference to Debezium/CDC/WAL-tailing with the polling-outbox-relay mechanism (`AbstractOutboxRelay`, SKIP LOCKED, publisher confirms) — link to `personal-docs/rabbitmq_pollingoutbox.md` for the detailed rationale rather than re-deriving it inline.
- Replace the "reporting rebuilds via Kafka replay" implication with the Phase 9 sync-pull mechanism.
- Update the "Cross-cutting bắt buộc" section: replace "Schema versioning (Avro + Schema Registry / Protobuf)" with whatever this migration actually shipped (plain JSON payloads, unchanged from Milestone 1's already-deferred-Avro decision — confirm this is still accurate, don't assume); replace the ShedLock cross-reference with a pointer to this migration's explicit SKIP-LOCKED-not-ShedLock decision for the relay specifically (ShedLock may still be correct for OTHER scheduled jobs in the platform — do not overcorrect to "never use ShedLock").
- Update the Consequences section: eventual consistency and idempotency requirements are unchanged; the "schema registry — chi phí cố định của distributed, không tùy chọn" framing changes since Schema Registry is gone — describe what replaces that tradeoff (simpler ops, smaller team footprint, explicitly named as this session's original motivation).

## Files to touch

- `pte-doc/projects/architecture/ADR-002-communication-and-exam-submission-saga.md` (edit — supersede communication/backbone sections, preserve saga sections)
- Any sibling ADR or index file in `pte-doc/projects/architecture/` that lists/links ADR-002, if the repo's convention requires updating a table of contents or status field there too (check before assuming none exists)

## Steps

1. Read every sibling ADR in `pte-doc/projects/architecture/` to identify this repo's existing supersession convention (a `Superseded-by:` header, a strikethrough section, a new ADR number entirely) before editing — do not invent a new convention if one already exists.
2. Rewrite the "Communication matrix" and "Kafka vs RabbitMQ" sections to reflect RabbitMQ-only, outbox-relay-vs-work-queue framing.
3. Replace the outbox/CDC mechanism description (Debezium/WAL) with the polling-outbox-relay mechanism, linking to `personal-docs/rabbitmq_pollingoutbox.md` rather than duplicating its content.
4. Replace the implicit Kafka-replay rebuild reference (if present) with Phase 9's sync-pull mechanism, linking to that phase file.
5. Update "Cross-cutting bắt buộc" (idempotency, schema versioning, ShedLock note) to match what actually shipped across Phases 1–10.
6. Leave the "Scoring lifecycle — HOST-GATED" section and its state-machine diagram untouched except for any direct Kafka/Debezium terminology inside it (verify there is none — re-read that section specifically for hidden Kafka references before declaring it untouched).
7. Add a dated note (matching this repo's convention from Step 1) pointing to this migration plan directory as the source of the rewrite, so a future reader can trace why the document changed.

## Success Criteria

- ADR-002 (or its superseding document, per Step 1's convention) contains no remaining reference to Kafka, Debezium, or Schema Registry as active infrastructure — only as historical context where explicitly marked superseded.
- The host-gated scoring lifecycle and saga state model sections are unchanged in substance, verified by a diff review against the pre-migration version.
- The document links to `personal-docs/rabbitmq_pollingoutbox.md` and to this migration plan directory rather than re-explaining either inline.
- Any other document in the repo that references ADR-002's Kafka/Debezium framing (searched for, not assumed absent) is either updated or flagged for a follow-up if out of this phase's scope.

## Testing

Documentation phase — "testing" here means review, not automated tests:

- A reviewer (or the requesting user) reads the rewritten sections against the actual Phases 1–10 implementation and confirms no factual drift (e.g. exchange-naming convention described matches what was actually built).
- Grep the rest of `pte-doc/` and `pte-api/` for stray references to "Debezium", "Schema Registry", or "Kafka" as if still active, to catch any doc or comment this phase missed.

## Risks

- LOW: Documentation-only phase, no runtime risk — the primary risk is drift between what was written here and what Phases 1–10 actually shipped if this phase is done before those phases stabilize. Mitigation: explicitly ordered last in `plan.md`.
- LOW: Overcorrecting the ShedLock guidance platform-wide (Design Constraints above) — mitigation: explicitly scoped the ADR update to the outbox relay's specific decision, not a blanket "never use ShedLock" rule.
