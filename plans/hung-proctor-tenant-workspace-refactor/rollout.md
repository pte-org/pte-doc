# Proctor Tenant Workspace Refactor — Rollout and Operations Guide

Date: 2026-10-11
Branch/Workspace: hung-proctor-tenant-workspace-refactor

## 1. Feature Flag Configuration

The proctor tenant workspace UI is controlled by the environment variable:

```bash
NEXT_PUBLIC_PROCTOR_UI_ENABLED=true # or false (default)
```

### Default State
- **Default value**: `false` (or undefined).
- **Behavior when disabled**:
  - Direct visits to `/proctor/sessions` redirect to `/proctor/unavailable`.
  - Proctor navigation items for live monitoring are hidden from the sidebar.
  - Multi-role users see only their active non-proctor workspaces (`HOST_ADMIN`, `EXAMINER`, `STUDENT`).
  - PROCTOR-only users land on the authenticated "Khu vực Giám thị chưa khả dụng" (Workspace Unavailable) view.

### Local Opt-in
To enable locally for development or validation:
1. Create or edit `apps/tenant-web/.env.local`:
   ```bash
   NEXT_PUBLIC_PROCTOR_UI_ENABLED=true
   ```
2. Restart the Next.js development server (`pnpm.cmd --filter tenant-web dev`).

---

## 2. Phased Rollout Strategy

### Stage 1: Canary / Internal Pilot
- **Scope**: Single test tenant with ~100 enrolled students and 1–3 proctors.
- **Verification Targets**:
  - Real-time STOMP connection stability over `/ws`.
  - Heartbeat and status snapshot polling intervals (3–5 seconds).
  - Correct execution of force-submit and violation logging under concurrent activity.

### Stage 2: Staged Tenant Enablement
- Enable flag tenant-by-tenant or cluster-by-cluster via deployment environment configuration.
- Observe backend telemetry:
  - Database connection pool utilization during snapshot queries.
  - WebSocket session counts in `ProctorConnectionRegistry`.

### Stage 3: General Availability (GA)
- Toggle default to `true` across production environments once pilot performance and authorization logs are confirmed clean.

---

## 3. Rollback Procedure

If unexpected behavior or stability issues occur:
1. **Immediate UI Gating**:
   - Set `NEXT_PUBLIC_PROCTOR_UI_ENABLED=false` in the target environment.
   - All proctor traffic will immediately fallback to the unavailable state without throwing 404 or creating redirect loops.
2. **Backend Compatibility**:
   - All database changes (the Flyway view `session_monitoring_enrollment_membership`) and REST/STOMP controllers are strictly additive.
   - Disabling the frontend flag does not require database rollback or API downtime.
