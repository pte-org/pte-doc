# Phase 8 Design: Authorized Live Proctor Console

Status: Approved
Date: 2026-07-28
Created by: Hung (Member 3)
Review scope: Flutter live console, STOMP authorization, and assigned-session
discovery

## Purpose

Complete the optional live proctor console without exposing session events
across tenants or granting Host users proctor command privileges. The design
extends the existing proctor STOMP flow instead of replacing its gateway route,
outbox integration, or session model.

## Role Policy

| Role | Discover sessions | Subscribe to live topic | Send commands | Flag violations |
| --- | --- | --- | --- | --- |
| `PROCTOR` | Own assigned sessions only | Assigned active sessions only | Yes | Yes |
| `HOST_ADMIN` | Existing tenant session list | Active sessions in own tenant | No | No |
| `HOST_AUTHOR` | Existing authoring/scheduling access only | No | No | No |

Backend authorization is authoritative. Flutter visibility is only a usability
gate and must not substitute for server checks.

## Backend Architecture

### STOMP boundary

Extend the existing inbound-channel interceptor and delegate destination checks
to a focused subscription authorization service:

1. `CONNECT` authenticates the bearer JWT and attaches `StompPrincipal`, as it
   does today.
2. `SUBSCRIBE /topic/proctor-sessions/{sessionPublicId}` parses the scheduling
   session identifier and authorizes it against the authenticated principal.
3. A `PROCTOR` is allowed only when an active `ProctorSession` exists for the
   same user, tenant, and scheduling session.
4. A `HOST_ADMIN` is allowed only when an active proctor session exists for the
   same tenant and scheduling session.
5. `HOST_AUTHOR` and all other roles are denied.
6. Client `SEND` frames targeting `/topic/**` or broker `/queue/**`
   destinations are rejected. Commands must use the existing `/app/**`
   controller destinations, whose services retain ownership and active-session
   checks.
7. User-scoped response/error queues remain private to the authenticated STOMP
   principal.

Missing sessions, inactive sessions, wrong tenants, and missing assignments
produce the same subscription-forbidden response so the authorization boundary
does not reveal whether another tenant's session exists.

### Assigned-session discovery

Add:

```http
GET /api/scheduling/proctor-assignments/me
```

The scheduling service derives `proctorPublicId` and `tenantId` exclusively from
the JWT context. It accepts no caller-supplied user or tenant override and
returns only sessions assigned to the authenticated `PROCTOR`. Other roles are
forbidden. The first-slice response is a non-pageable list in ascending
`opensAt`, then `publicId`, order and contains only:

- `assignmentPublicId`
- `sessionPublicId`
- `name`
- `opensAt`
- `closesAt`
- `status`

The existing Host session list remains the discovery source for `HOST_ADMIN`.
No new Host-specific list endpoint is added.

### REST recovery authorization

The existing violation audit remains available to Host audit roles under its
current tenant boundary. For live recovery, a `PROCTOR` may read violations
only when the proctor service has an active owned `ProctorSession` for the
requested scheduling session; tenant membership alone is not sufficient. This
uses the proctor service's local ownership record and does not add another
synchronous scheduling call.

No IAM, gateway-route, Kafka-topic, event-delivery, or database-schema change is
part of this design.

## Live Event Contract

The current topic publishes unrelated raw request/response shapes. Replace
those live payloads with a typed envelope:

```json
{
  "eventId": "uuid",
  "eventType": "COMMAND_ACCEPTED",
  "sessionPublicId": "uuid",
  "occurredAt": "2026-07-28T10:00:00Z",
  "data": {
    "attemptPublicId": "uuid",
    "commandType": "EXTEND_TIME",
    "extraSeconds": 300
  }
}
```

Initial event types are:

- `COMMAND_ACCEPTED`
- `VIOLATION_DETECTED`

`COMMAND_ACCEPTED` means the command passed validation and was written to the
outbox. It does not claim that exam-delivery applied the command. Violation
events use the persisted violation public ID as their stable event ID; accepted
commands receive a generated event ID for live-stream deduplication.

The Kafka/outbox contracts remain unchanged. The envelope applies only to the
STOMP presentation channel.

## Flutter Architecture

Create a standalone `live_proctor` feature with the established feature-first
boundaries:

- `data`: assigned-session REST data source, STOMP adapter, repository
  implementation, and wire-model mapping.
- `domain`: immutable session/event/connection types, repository interface, and
  explicit console capability (`controller` or `readOnly`).
- `presentation`: feature module, sealed BLoC events, immutable per-case states,
  Proctor workspace, and shared live-console page.

The root auth gate sends `PROCTOR` to the Proctor workspace.
`HOST_ADMIN` enters the read-only console from scheduling session detail.
`HOST_AUTHOR` receives no live-console navigation.

Scheduling passes only `sessionPublicId` and console capability into a
feature-owned live-proctor entry page. It does not construct or import the
feature's BLoC, repository, or transport implementation.

The controller console exposes `FORCE_SUBMIT`, `EXTEND_TIME`, and manual
violation flagging already supported by the backend. `FORCE_SUBMIT` and
`EXTEND_TIME` require explicit confirmation, are single-flight, and are never
automatically retried. The read-only console renders the same verified event
stream without mutation controls.

## Connection and Recovery Flow

### Proctor

1. Load the authenticated proctor's assigned sessions.
2. Connect to the gateway WebSocket endpoint with the current bearer token.
3. Subscribe to the private proctor-session response and error queues.
4. Send the existing session-open application command.
5. Receive the owned `proctorSessionPublicId`.
6. Subscribe to the scheduling-session topic.
7. Enable controller actions only after the owned proctor session is active.

### Host administrator

1. Open Live Monitoring from an existing scheduling session detail.
2. Connect with the current bearer token.
3. Subscribe to the scheduling-session topic.
4. Render live events without exposing command or violation mutations.

### Reconnect

Reconnect delays are 1, 2, 4, 8, and 15 seconds. After five failed attempts the
BLoC enters a stable failure state with explicit retry.

After reconnect, the client subscribes and buffers new events, loads the
authoritative violation REST snapshot, merges snapshot and buffer by event ID,
then publishes the restored view state. Command acceptance events are
ephemeral; the client never reconstructs them as completed commands.

Logout, page disposal, or explicit disconnect cancels the subscription,
transport, reconnect timer, and buffer. Every reconnect authenticates and
authorizes again. Authorization revocation takes effect for new/reconnected
subscriptions; this milestone does not add server-driven eviction of an already
authorized subscription.

## Error Handling

- Invalid or expired JWT: terminate the connection and return to the shared auth
  flow.
- Unauthorized topic: `STOMP_SUBSCRIPTION_FORBIDDEN`.
- Host command attempt: `STOMP_COMMAND_FORBIDDEN`.
- Direct broker-destination send: reject without broadcasting.
- Command validation/domain error: deliver through the private error queue,
  preserve user input, and do not retry automatically.
- Network failure: enter bounded reconnect; after exhaustion, show manual retry.
- Unknown event type: ignore safely and retain the connection while recording
  the mapping failure for diagnostics.

## Verification Strategy

### Backend

- Valid and invalid JWT connection tests.
- Allowed and denied subscription cases for assigned `PROCTOR`, same-tenant
  `HOST_ADMIN`, `HOST_AUTHOR`, wrong tenant, missing assignment, inactive
  session, and unknown session.
- Direct broker send and Host command denial.
- Typed envelope contract tests for command acceptance and violations.
- Assigned-session query role, tenant, and caller-identity tests.
- Proctor REST violation access limited by assignment.

### Flutter

- Auth routing and role-specific navigation tests.
- Assigned-session repository and workspace states.
- Event-envelope mapping and unknown-event handling.
- Connection, bounded backoff, manual retry, logout, and disposal tests.
- Subscribe-buffer-snapshot-merge ordering and deduplication tests.
- Read-only versus controller widget behavior.
- Confirmation, single-flight, validation, and failure preservation for
  commands and violation mutation.
- Full Host and Member 2 regressions, `flutter analyze`, and full Flutter suite.

### Runtime acceptance

Through the gateway, demonstrate:

1. An assigned `PROCTOR` connects, opens, subscribes, and sends an accepted
   command.
2. A same-tenant `HOST_ADMIN` receives the event but cannot send a command.
3. `HOST_AUTHOR`, wrong-tenant, and unassigned subscriptions are denied.
4. A real violation appears in both authorized consoles and the REST snapshot.
5. Network interruption reconnects and restores the snapshot without duplicate
   events.
6. The Windows Flutter client completes the same flow.

If the required stack is unavailable, source may be reported as implemented,
but Phase 8 remains `IMPLEMENTED_AWAITING_RUNTIME_VERIFICATION` rather than
complete.

## Out of Scope

- Video, audio, screen sharing, chat, and automated violation detection.
- Host-author live access.
- Host-admin commands.
- Automatic retry of mutations.
- Kafka/outbox contract changes.
- Database-schema changes.
- Server-driven eviction when assignment or role is revoked during an existing
  authorized subscription.
