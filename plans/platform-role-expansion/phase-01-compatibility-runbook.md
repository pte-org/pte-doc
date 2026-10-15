# Phase 1 compatibility runbook

## Canonical role contract

The canonical platform roles are `PLATFORM_ADMIN`, `PLATFORM_MANAGER`,
`ACADEMIC_MANAGER`, and `ACADEMIC_STAFF`. `HOST_ADMIN`, `PROCTOR`,
`EXAMINER`, and `STUDENT` remain tenant-scoped. `PLATFORM_AUTHOR` remains a
deprecated database/JVM alias during the compatibility window.

The compatibility mapping is one-way:

```text
PLATFORM_AUTHOR -> ACADEMIC_STAFF
```

New access tokens emit `ACADEMIC_STAFF`. Resource-server claims and the
current-user context normalize a legacy claim before authorization checks. The
web session boundary applies the same mapping so an existing local session is
not stranded on the old role name.

## Deployment order

1. Apply `V86__platform_role_catalog.sql` to a database that already contains
   `V35__identity_role_taxonomy.sql`.
2. Deploy the backend containing the expanded enum and canonicalization logic.
3. Deploy the web contract that accepts canonical platform roles and normalizes
   legacy sessions.
4. Verify legacy author login, canonical token issuance, and direct authorization
   checks before creating accounts with the new roles.

The migration is additive for the compatibility window: it preserves existing
`PLATFORM_AUTHOR` rows and does not backfill or delete audit history. Do not
remove the alias until the Phase 6 inventory confirms that no account or
unexpired token depends on it.

## Rollback boundary

Rollback means reverting the application release while leaving the additive
role constraint in place. Do not roll back by editing an applied Flyway file or
by deleting the new role values from `user_roles`. If new-role accounts were
created, restore the application and database from the release-compatible
backup or complete the forward migration; an old binary must not be pointed at
rows containing enum values it cannot deserialize.

## Verification checklist

- Existing `PLATFORM_AUTHOR` account can authenticate.
- A newly issued token contains `ACADEMIC_STAFF`, not a second authoring
  capability.
- A legacy `PLATFORM_AUTHOR` claim is accepted as `ACADEMIC_STAFF` by the
  resource server/current-user boundary.
- Platform roles have `tenant_id = null`; tenant roles remain tenant-bound.
- Mixed platform/tenant role sets are rejected by provisioning policy.
- No password, token, or other credential is stored in this plan or seed data.
