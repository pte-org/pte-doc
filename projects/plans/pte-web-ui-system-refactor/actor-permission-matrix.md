# Phase 01 actor and permission matrix

**Status:** PASS (source-grounded); local credentials are not recorded here.

| Actor | Vendor navigation | Tenant navigation | Protected action boundary | Current denied behavior to preserve |
|---|---|---|---|---|
| `PLATFORM_ADMIN` | `/admin/*` | Not a tenant role by default | Tenant lifecycle, licensing, announcements, authoring | Existing `RequireAuth`/role gate |
| `HOST_ADMIN` | Vendor host entry where allowed | `/host/*` | Tenant operations, billing, audit, support | Existing `RequireAuth`/role gate |
| `EXAMINER` | None | `/examiner/work` | Assigned scoring/work queue only | Existing role gate |
| `PROCTOR` | None | Session/proctor surfaces exposed by current navigation | Proctor assignment/session actions only | Existing role gate |
| `STUDENT` | None | `/student/results` | Own results/student actions only | Existing role gate |
| Anonymous | Public/auth routes | Public/auth routes | No dashboard/API action | Existing login redirect/forbidden behavior |

Implementation rule: migration may change presentation state only. Each changed
route must retain the existing `allowedRoles`/`requiredRoles` values, visible
navigation filtering, callbacks, and current redirect/forbidden result.
