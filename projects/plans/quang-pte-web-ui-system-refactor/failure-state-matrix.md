# Failure and recovery state matrix

**Status:** PASS (ownership mapped; runtime interaction checks deferred to the
post-cook validation run).

| State | Current owner | Expected presentation | Required action/evidence |
|---|---|---|---|
| Loading | Feature query/common loading state | Skeleton/loading state | Remains reachable on first load |
| Empty | Feature view | Empty state with existing CTA | CTA keeps existing callback |
| Validation | Feature form validator | Field/error alert | Existing validator and payload unchanged |
| Unauthorized/forbidden | Auth gate/route owner | Existing redirect/forbidden result | No common provider redirect change |
| Not found | Feature query | Existing error/empty result | Retry/back action unchanged |
| Network/timeout | API client/feature | Existing error state and retry | Retry callback unchanged |
| Version conflict | Plan/catalog owner | Conflict alert and reload/keep action | Expected-version guard retained |
| Stale assignment preview | Exam assignment owner | Stale preview warning/refresh path | Preview guard retained |
| Duplicate/idempotent request | License/recovery owner | Existing recovery/idempotency result | No new reveal/security flow |
| Placeholder student data | Student/user-management owner | Existing placeholder-safe display | No credential/data ownership change |
