# Phase 7: Notification & Violation Audit

## Requirements

Build read-only Host operational views for notification delivery records and
immutable per-session violation audit events, with tenant-safe selection,
loading/empty/failure/retry behavior, and no mutation capability.

Maps to: **P1 Story #8 (operational audit) | FR-16, FR-18**

## Design Constraints

- Create a standalone `host_audit` feature; audit models and BLoCs do not live in
  scheduling or scoring.
- Consume existing
  `GET /api/notification/notifications` and
  `GET /api/proctor/exam-sessions/{sessionPublicId}/violations`.
- Audit views are read-only. Do not add resend/delete/edit/acknowledge actions
  unless a later approved spec and backend contract require them.
- Render backend public IDs, notification type/status/email/subject/sent time,
  and violation attempt/type/detail/sequence/hash/detected time without deriving
  or altering integrity fields.
- Session selection passes only a session public ID; backend tenant/assignment
  checks remain authoritative.
- No client-side fake pagination/filter API is added. Local display filters are
  permitted only when clearly labeled and when they do not imply a server query.
- Timestamps are parsed deterministically and displayed using one shared
  formatting policy; malformed timestamps surface a mapping failure rather than
  silently becoming the current time.

## Steps

1. Re-check notification and violation controllers, response DTOs, role
   annotations, tenant/assignment policies, ordering, and timestamp formats.
2. Define immutable notification log and violation audit domain entities plus
   strict JSON models and mapping tests.
3. Define `HostAuditRepository` with notification-list and
   session-violation-list queries; implement gateway data repository and error
   tests.
4. Build separate notification and violation BLoCs with initial/loading/empty/
   loaded/failure/retry states.
5. Add a shared audit timestamp formatter only if both views use it; otherwise
   keep formatting inside focused widgets to avoid premature abstraction.
6. Build notification log page/cards with delivery status, type, recipient,
   subject, and sent time.
7. Build session violation page/cards with attempt, violation type, detail,
   sequence/hash, and detected time; integrity/hash fields are selectable/copyable
   but never editable.
8. Integrate both pages into Host navigation and pass session public ID through
   typed navigation from session detail.
9. Add mapping, repository, BLoC, and widget tests for loaded/empty/failure/
   retry, malformed fields, ordering, and read-only UI.
10. Run all Host regressions, analysis, full Flutter suite, and bounded runtime
    notification/violation reads for authorized and inaccessible sessions.

## Success Criteria

- [ ] Notification view renders authoritative recipient/type/subject/status/time
      with loading, empty, retryable failure, and success states.
- [ ] Violation view renders authoritative attempt/type/detail/sequence/hash/time
      for the selected accessible session.
- [ ] Neither view exposes mutation actions or alters integrity fields.
- [ ] Inaccessible tenant/session data is not rendered and does not trigger
      false logout.
- [ ] Timestamp/malformed-response behavior is deterministic and tested.
- [ ] Phase-7 tests, all prior regressions, analysis, and full suite pass;
      runtime access evidence is recorded.

## Quality and Testing State

- Quality gate: not run. Planned report:
  `quality/phase-07-notification-and-violation-audit-quality-report.json`.
- Testing: not run. Planned evidence:
  `tests/phase-07-notification-and-violation-audit-test-report.json`.

## Risks

- **MEDIUM:** Notification and violation lists may grow without backend
  pagination. Mitigation: use lazy Flutter rendering for Milestone 1 and record
  measured/runtime volume before proposing backend pagination.
- **MEDIUM:** Violation access policy may be proctor-assignment-centric rather
  than general Host visibility. Mitigation: re-check controller/service policy
  and test both authorized and inaccessible session cases.
- **LOW:** Displaying raw hashes can clutter normal operations. Mitigation: keep
  integrity detail secondary/copyable while preserving exact backend value.
