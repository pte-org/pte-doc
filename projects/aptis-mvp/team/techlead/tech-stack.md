# Technology Stack — APTIS MVP (Host-Driven Exam Distribution)

> **⚠ Versions realigned per ADR-005 (2026-06-21).** The MVP is built inside the production
> `aptis-lms` repos, so the **repo is authoritative**, not the version cells below: **NestJS 11,
> Node ≥22.12, Prisma 7, PostgreSQL 17, Next.js 16, React 19, Tailwind 4.** Redis/BullMQ are
> installed but **unused** in MVP (synchronous path). **Add** `exceljs` (aptis-be) and decide the
> aptis-web server-state approach (TanStack Query vs server actions). See `mvp-slice-mapping.md` §4.

## Frontend
| Layer | Selected | Version | Rationale |
|---|---|---|---|
| Framework | Next.js | 14.x (App Router) | Routing, SSR/CSR, and API-proxy conventions built in — no boilerplate to hand-build in week 1; web-only per Out of Scope (no Flutter needed for MVP) |
| State management | TanStack Query (React Query) | 5.x | Server-state caching/invalidation for REST calls with minimal setup; no global client-state store needed at this scope |
| Styling | Tailwind CSS | 3.x | Fast UI assembly for 4 generalists without a design system to build from scratch |
| Build tool | Next.js built-in (Turbopack/webpack) | bundled | Zero extra build config needed |

## Backend
| Layer | Selected | Version | Rationale |
|---|---|---|---|
| Runtime | Node.js | 20 LTS | Matches the existing `aptis-lms` stack; team already has Node/TS familiarity |
| Framework | NestJS | 10.x | Built-in DI, modules, and Guards give auth/RBAC structure for free instead of hand-rolling it — critical for a 7-day timeline |
| ORM / Query builder | Prisma | 5.x | Schema-first migrations let 4 devs iterate on the data model same-day; generated types reduce integration bugs between modules |
| Auth library | `@nestjs/jwt` + Passport-JWT strategy | latest stable | Stateless JWT issuance/verification with minimal config; bcrypt for credential hashing (BR-001) |

## Database
| Layer | Selected | Version | Rationale |
|---|---|---|---|
| Primary DB | PostgreSQL | 15 | Strong relational constraints map directly onto BR-004 (uniqueness), BR-005 (scoping queries), BR-006/BR-009 (referential guards) |
| Cache | None | — | No read-heavy or expensive computation in this MVP's scope to justify cache infra in week 1 |
| Search | None | — | No search/filter requirement beyond simple name search (US-015), servable by a plain `ILIKE` query |

## Infrastructure
| Layer | Selected | Rationale |
|---|---|---|
| Hosting | Managed PaaS (e.g., Railway/Render) — one API service, one Web service, one managed Postgres | Fastest path to a running pilot deployment with no DevOps setup time spent in week 1 |
| CI/CD | GitHub Actions — lint + test on PR only, no auto-deploy | Catches regressions without spending setup time on deployment automation that won't pay back in a 1-week build |
| Container | Docker (single `Dockerfile` per service, `docker-compose` for local dev) | Consistent local/prod parity without per-developer environment drift |

## Rejected Alternatives
| Alternative | Layer | Reason rejected |
|---|---|---|
| Angular | Frontend | Steeper learning curve and more boilerplate for 4 full-stack generalists in a 7-day build |
| Plain React + Vite | Frontend | Would require hand-building routing/SSR conventions Next.js already provides — costs time the MVP doesn't have |
| Express | Backend | Lacks built-in DI/module/Guard structure; auth/RBAC scaffolding would need to be hand-built, too slow for week 1 |
| FastAPI / Django | Backend | Different language from the rest of the `aptis-lms` codebase; switching stacks adds onboarding cost with no offsetting benefit at this scope |
| TypeORM | ORM | More decorator boilerplate and slower migration iteration than Prisma's schema-first workflow |
| MongoDB | Database | The relational integrity BR-004/BR-005/BR-006/BR-009 need (uniqueness, FK referential blocks) would have to be re-implemented in application code — more error-prone under a 1-week deadline |
| MySQL | Database | PostgreSQL is already the standard across the broader `aptis-lms` project; reusing it avoids introducing new ops knowledge for no benefit |
