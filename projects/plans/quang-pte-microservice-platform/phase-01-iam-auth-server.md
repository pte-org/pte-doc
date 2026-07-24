# Phase 1: iam — Auth Server

## Requirements

The single auth server (all other services are resource servers). Owns users, credentials, roles, tenant membership, and JWT signing. Issues RS256 JWTs carrying `userId`, `tenantId`, and `roles`; exposes JWKS for local validation everywhere else. Provides CRUD for the actor types the platform needs (host, proctor, student), and holds the tenant registry (tenant identity read from the token, not from a runtime call to admin).

## Design Constraints

- `com.pte.iam`, DB `iam`, uniform layered layout.
- JWT asymmetric (RS256 or EdDSA); private key from env/Vault, never in source. Short access-token TTL + refresh token.
- Tenant identity embedded as a JWT claim so the data plane never calls iam/admin per request (ADR-002).
- Password hashing Argon2/BCrypt; credentials never logged.
- Roles: `PLATFORM_ADMIN, PLATFORM_AUTHOR, HOST_ADMIN, HOST_AUTHOR, PROCTOR, STUDENT` (in `domain/enums/Role`).
- User creation is tenant-scoped except platform roles; RLS on tenant-scoped tables.
- Swappable to Keycloak later without changing the token contract (claims shape frozen here).

## Steps

1. Entities (`domain/`): `User` (extends BaseEntity, tenantId nullable for platform users), `Credential` (hashed secret), `Role` enum, `TenantMembership` (user↔tenant↔role), `RefreshToken`. Flyway `V1__iam.sql`.
2. `TokenService`: sign access JWT (claims userId/tenantId/roles), issue/rotate refresh tokens, expose JWKS (`JwksController`).
3. `AuthController`: `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`. `@Valid` request DTOs; `ApiResponse<T>`.
4. `UserService` (+ `UserProvisioningHelper` if >5 methods): create host/proctor/student, list/get within tenant, suspend. Tenant-scoped queries + RLS.
5. `UserController`: role-guarded endpoints (method security on roles). Host can create proctor+student **within own tenant only**; admin can create host + set tenant.
6. `security/`: resource-server config for iam's own protected endpoints; role-based method security.
7. `messaging/outbox` + `publisher`: emit `UserCreated`, `UserSuspended`.
8. Tests: token sign/verify + JWKS; login happy/invalid; tenant-scoped user creation rejects cross-tenant; role guard rejects student creating users.

## Success Criteria

- Login returns a valid RS256 JWT whose claims (userId/tenantId/roles) verify against the JWKS endpoint.
- A resource server (gateway) validates the token locally via JWKS with no call back to iam.
- Host-scoped user creation cannot create a user in another tenant (403 / not found), verified by test.
- `UserCreated` lands on the outbox table in the same TX as the user insert.

## Quality and Testing State

- Quality gate: not evaluated.
- Testing: not started.

## Risks

- **HIGH: Auth correctness.** Hand-rolled auth is the easiest place to get security wrong. *Mitigation:* freeze claim contract, keep logic minimal, plan Keycloak swap; security-review before Phase 9.
- **MEDIUM: Key management.** *Mitigation:* keys from env now, Vault later; rotation via JWKS multi-key.
