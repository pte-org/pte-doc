# Practice CI and stale Nginx upstream repair

## Causes and corrections

Practice workflow run 41106293606 failed during unit-test collection. `describe.skipIf` skips test execution, but still collects the suite callback, which eagerly read a sibling backend contract absent from a single-repository Actions checkout. The contract fixture is now read in `beforeAll`, with the same typed contract and seven assertions. A workspace containing the API still runs all contract checks; a standalone checkout skips them without an ENOENT failure.

API deploy run 41114373713 initially applied V15 and started healthy containers but failed public verification. Nginx retained upstream addresses from previous containers: its API upstream pointed at the new tenant container, while its vendor upstream pointed at the new API container. Internal backend health remained UP.

The authorized live repair took the shared deployment lock, ran `nginx -t`, and gracefully reloaded Nginx. No container rebuild, database edit, or secret change was needed. The source deployment script now validates and gracefully reloads Nginx after all containers pass health checks, including when the certificate helper exits early because existing certificates remain valid. Configuration/reload failures abort deployment.

## Verification

- Practice full unit suite: 78 files, 736 tests passed.
- Backend contract available: seven contract tests passed.
- Mocked missing backend contract: seven skipped, exit zero; no real repository or fixture was moved.
- Practice scoped ESLint and TypeScript checks passed. No build was rerun for this test-only change.
- Bash syntax checks for deployment and regression scripts passed.
- Isolated deployment harness: normal valid-certificate path, unhealthy timeout, invalid Nginx configuration, invalid Compose configuration, and reload failure all passed. It asserts health-before-validation-before-reload ordering and failure propagation without touching production.
- Independent review reported no remaining concrete introduced findings in either change.
- Public admin, tenant, and practice roots plus tenant actuator health returned HTTP 200 after the live reload.
- Public admin login HTML checksum matched the vendor container; public tenant login checksum matched the tenant container.
- Latest production Flyway version: 15, success=true.
- Reran only failed public verification in API workflow: attempt 2 concluded success. Web workflow concluded success on attempt 1.

Workflow evidence:

- API: https://github.com/pte-org/pte-api/actions/runs/41114373713
- Web: https://github.com/pte-org/pte-web/actions/runs/41114362621
- Previous failed Practice run: https://github.com/pte-org/pte-practice/actions/runs/41106293606

The persistent deployment-script correction and Practice test correction are local source changes pending push/merge. The earlier Practice workflow remains failed until corrected code reaches its workflow. No full student exam, payment, or AI conversation journey was executed in this repair.
