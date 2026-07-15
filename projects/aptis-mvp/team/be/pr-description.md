# PR: iam auth core — APTIS MVP (TASK-003)

## Summary
Implements the authentication core for the `iam` bounded context inside the real `aptis-be`
monorepo (per ADR-005), in full DDD layering (domain / application / infrastructure / presentation)
conforming to `aptis-be/RULE.md`. Covers the three actor logins — Admin (US-001), Host (US-006),
Student (US-011) — plus the reusable building blocks every other context depends on: bcrypt hashing
(BR-001), a cryptographic credential generator (BR-002), stateless JWT issuance, an RBAC guard, and
the tenant-scoped repository base that enforces BR-005.

## Changes
### New files — iam context
- `libs/modules/iam/src/domain/role.ts` — Role enum (ADMIN/HOST/STUDENT)
- `libs/modules/iam/src/domain/auth.types.ts` — AuthClaims, AuthSession (refresh-shaped), AuthenticatedUser, TenantContext
- `libs/modules/iam/src/domain/account.ts` — Account identity aggregate
- `libs/modules/iam/src/domain/ports/hasher.port.ts` · `generator.port.ts` · `token-service.ts` · `account-repository.ts` — ports
- `libs/modules/iam/src/application/authenticate.use-case.ts` — login use case (generic-failure, no existence leak)
- `libs/modules/iam/src/application/issuer.service.ts` — `CredentialIssuer` public contract (hash+generate) for tenancy/exam-operations
- `libs/modules/iam/src/application/authenticate.use-case.spec.ts` — 4 unit tests (fake ports)
- `libs/modules/iam/src/infrastructure/bcrypt-hasher.adapter.ts` · `crypto-generator.adapter.ts` · `jwt-token.service.ts` · `prisma-account.repository.ts` · `tenant-scoped.repository.ts`
- `libs/modules/iam/src/presentation/` — `jwt.strategy.ts`, `jwt-auth.guard.ts`, `roles.decorator.ts`, `roles.guard.ts`, `current-user.decorator.ts`, `dto/login.dto.ts`, `auth.controller.ts`

### New files — shared foundation
- `libs/common/src/errors/app-error.ts` · `domain-exception.filter.ts` · `index.ts` — typed error taxonomy + stable `{code,message,details,requestId}` mapper
- `libs/platform/database/src/prisma.service.ts` · `prisma.module.ts` · `index.ts` — global Prisma client
- `prisma/schema.prisma` — IAM identity slice (Admin, Host, Student); full model is TASK-002
- `jest.config.js` — ts-jest + path-alias mapping (repo had no jest/eslint config — TASK-001 gap)

### Modified files
- `libs/modules/iam/src/iam.module.ts` — wires ports→adapters, JwtModule, JwtStrategy, RolesGuard, global filter
- `libs/modules/iam/src/index.ts` — public API (guards, decorators, Role, CredentialIssuer, TenantScopedRepository)
- `libs/common/src/index.ts` — export `./errors`
- `libs/platform/config/src/validate-environment.ts` — add `JWT_ACCESS_TTL` (default 15m), `BCRYPT_COST` (default 12)
- `apps/api/src/api.module.ts` — import global `PrismaModule`
- `tsconfig.json` — add `@platform/database` path alias

## API Endpoints
| Method | Path | Description | Auth required |
|---|---|---|---|
| POST | /api/v1/auth/admin/login | Admin login → access token (US-001) | No |
| POST | /api/v1/auth/host/login | Host login → access token, scoped to org (US-006) | No |
| POST | /api/v1/auth/student/login | Student login → access token (US-011) | No |

Guards/decorators exported for other contexts: `JwtAuthGuard`, `RolesGuard` + `@Roles()`, `@CurrentUser()`, `@CurrentTenant()`.

## Database Changes
- New tables (IAM slice): `admin`, `host`, `student` (+ unique/index constraints for BR-004/BR-005).
- Migrations: NOT created here — `prisma migrate` needs the Prisma 7 `prisma.config.ts` (TASK-002).

## Environment Variables Required
All read via the existing validated config (`validate-environment.ts`); no hardcoded secrets (BR-010):
`DATABASE_URL`, `REDIS_URL`, `JWT_ACCESS_SECRET` (≥32), `JWT_REFRESH_SECRET` (≥32),
`JWT_ACCESS_TTL` (default `15m`), `BCRYPT_COST` (default `12`), `PORT`, `NODE_ENV`.

## Testing Notes
Verification status (run against the actual installed toolchain):
- ✅ `npx tsc --noEmit -p tsconfig.json` → **0 errors** (whole project, incl. this module + spec)
- ✅ `npx jest .../authenticate.use-case.spec.ts` → **4/4 pass** (valid login; unknown identifier no-leak + no token; wrong credential; deactivated account rejected)
- ✅ `npx prisma generate` → client generated (v7.8.0)
- ⚠️ `eslint` NOT run — repo has **no `eslint.config.mjs`** (ESLint 9 flat config missing → TASK-001).
- Setup to run locally: `npm install` → `npx prisma generate` → `npx jest`.

### Deferred (by ADR-005 / foundation — NOT bugs)
- **Prisma 7 runtime connection**: in Prisma 7 the datasource `url` moved out of `schema.prisma`; the runtime needs `prisma.config.ts` + a driver adapter (`@prisma/adapter-pg`) passed to the PrismaClient constructor → **TASK-002**.
- **Refresh-token rotation**: token port is already refresh-shaped (`AuthSession.refreshToken?`); rotation added in **TASK-029** with no caller changes.
- **PostgreSQL RLS**: app-layer host scoping is in place via `TenantScopedRepository`; DB RLS in **TASK-028**.
- **ESLint flat config + fuller jest/coverage setup**: **TASK-001 / TASK-025**.
