# Technology Stack — APTIS LMS

## Frontend

| Layer | Selected | Version | Rationale |
|---|---|---|---|
| Framework | Flutter / Dart | Project-pinned stable | Mandatory DC-01; shared Web/Desktop code |
| State management | Riverpod | Project-pinned | Testable dependency graph and platform-neutral state |
| Networking | Dio + WebSocket adapter | Project-pinned | Interceptors, retries, cancellation, typed API adapters |
| Localization | Flutter intl / ARB | Project-pinned | Vietnamese primary and English secondary |

## Backend

| Layer | Selected | Version | Rationale |
|---|---|---|---|
| Runtime | Node.js LTS | 22.x | Meets NestJS 11 and Prisma 7 runtime requirements; available in current toolchain |
| Framework | NestJS | 11.1.x | Strong module boundaries, DI, validation, WebSocket and worker integration |
| Language | TypeScript | 5.9.x | Stable NestJS-compatible compiler baseline; strict mode enabled |
| Persistence adapter | Prisma ORM | 7.8.x | Typed migrations/client while domain repositories isolate generated types |
| Queue | BullMQ | 5.x | Redis-backed retries, delayed jobs, concurrency and dead-letter workflows |
| Auth | Passport JWT + application session service | NestJS 11 compatible | Explicit guards plus server-side refresh-token rotation |
| Validation | class-validator/class-transformer at HTTP boundary; domain value objects internally | Current compatible | Separates transport validation from invariants |
| Logging/tracing | nestjs-pino + OpenTelemetry | Current compatible | Structured correlated logs and cross-process traces |
| API contract | OpenAPI/Swagger | NestJS 11 compatible | Flutter client generation and contract testing |

## Database

| Layer | Selected | Version | Rationale |
|---|---|---|---|
| Primary DB | PostgreSQL | 17+ managed | ACID, JSONB, indexing, partitioning and row-level security |
| Cache/queue/pub-sub | Redis | 7+ | BullMQ, rate limiting, distributed locks and WebSocket fan-out |
| Search | PostgreSQL full-text initially | Built-in | Avoids an unnecessary search cluster for v1 question search |
| Media | Private object storage + CDN | Provider adapter | Large binary media stays outside the relational database |

## Infrastructure

| Layer | Selected | Rationale |
|---|---|---|
| Packaging | Docker multi-stage image | Same artifact deploys as API or Worker |
| Local environment | Docker Compose | Repeatable PostgreSQL/Redis development services |
| Hosting | Managed container platform, provider TBD after OI-07 | Independent API/Worker scaling without premature Kubernetes commitment |
| CI/CD | GitHub Actions | Lint, unit, integration, build, migration validation and image publishing |
| Secrets | Cloud secret manager / workload identity | No secrets in source, image, logs or environment templates |

## Rejected Alternatives

| Alternative | Layer | Reason rejected |
|---|---|---|
| Microservices per bounded context | Architecture | Too much distributed consistency and operations cost before real scaling evidence |
| Single-process API including AI jobs | Architecture | AI/provider backlog could starve critical exam writes and live monitoring |
| MongoDB | Database | Relational integrity, transactions, reporting joins and tenant constraints dominate |
| Schema-per-tenant | Multi-tenancy | Operational migration cost grows with tenant count; tenant column + RLS is simpler |
| TypeORM entities as domain entities | Persistence | Couples domain invariants to ORM decorators and persistence lifecycle |
| Kafka at launch | Messaging | BullMQ covers expected v1 load with lower operating complexity; event contracts preserve migration path |
| Custom ML models | AI | Explicitly prohibited by DC-06 and unsupported by v1 data/timeline |
