# Research A: Dedicated platform-user lifecycle resource

## Verdict

Recommended.

## Findings

- The backend already has a dedicated tenantless platform-user controller and
  service boundary.
- The frontend already has a matching API-client namespace, query key and action
  surface.
- Extending the existing namespace keeps tenant scope, role allowlist, target
  protection and audit behavior in one place.
- Profile, password and archive operations require identity-specific validation and
  should not be hidden inside the tenant-user contract.

## Tradeoff

This adds several explicit endpoints and focused tests, but keeps the security
boundary readable and avoids widening existing tenant APIs.

## Recommendation

Preserve existing list/create/role/suspend/reactivate routes. Add profile update,
platform password reset and reversible archive/restore. Keep `PLATFORM_ADMIN`
management-only and protect self/admin targets.
