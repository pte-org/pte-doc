# Practice VPS deployment readiness

Date: 2026-10-21 (Asia/Bangkok)

Status: implementation and pre-deployment checks complete; publication to main and production rollout pending.

## Prepared changes

- API Compose adds a private `web-practice` service with a 512 MB runtime limit and HTTP healthcheck.
- Build uses the practice repository's npm lockfile and embeds `https://pte-practice.duckdns.org` as its public API origin.
- Nginx forwards practice `/api/v1/` requests to the existing backend and other requests to practice. HTTP redirects to HTTPS once the certificate is installed.
- Both shared-stack deployment workflows synchronize the practice main branch.
- Practice has its own push-to-main/manual-dispatch workflow with five jobs: lint, unit tests, production build, VPS deploy, and public verification. Lint/test/build run in parallel; deployment requires all three to pass.
- All three workflows bootstrap the shared API `deploy/production.sh` under the same VPS lock, retaining clean-main and fast-forward-only safeguards.
- Existing lint errors were corrected through typed ProductMark props and external-store subscriptions for saved locale/theme preferences; no lint rules were disabled.
- Certificate setup waits for Nginx readiness, checks SAN coverage and expiry inside the certificate volume, and expands the shared certificate to tenant/admin/practice when needed.
- Nginx resolves the practice upstream at request time; practice startup does not gate the existing tenant/admin edge.
- Practice Docker context excludes environment files, Git data, dependencies, and local build outputs.

## Verified

- DNS A record: `pte-practice.duckdns.org` resolves to `217.142.185.74`.
- Practice production build passed locally with the hosted API origin.
- Practice Docker production build passed on the VPS from practice main commit `1319b0758e376cced7c9016e7e4cec5b28a33426`.
- Temporary non-root container returned HTTP 200 for `/`, `/sign-in`, `/practice-tests`, `/progress`, and `/study-pack`.
- HTTPS and bootstrap Nginx templates passed `nginx -t` in isolated containers, including when the practice upstream was absent.
- Merged Compose configuration validated with `.env.example`.
- Workflow YAML and Bash syntax checks passed.
- Practice unit tests: 8 files, 22 tests passed.
- Practice lint: zero errors, six existing warnings.
- Browser smoke on the local production build: saved Vietnamese locale and dark theme were restored on reload, with translated sign-in text. Saved English/light preferences were also restored.
- `npm audit --omit=dev`: zero reported vulnerabilities.
- Independent source review: two startup findings addressed; no remaining blocking findings in the updated fixes.

## Existing issues and boundaries

- Six lint warnings remain in unrelated catalog/home/session/shell files (unused imports and existing hook dependencies).
- The practice repository's `production` environment lookup returned HTTP 404. Its environment and four SSH deployment secrets must be configured before production execution.
- Dependency installation reports development-dependency vulnerabilities; the production-only audit was clean.
- The practice repository has been cloned on the VPS. No production routing or certificate changes have been applied yet.
- No application authentication, email OTP, scoring, or exam-submission flow has been tested on the new public domain.
- Deployment source changes remain uncommitted. Publish them to main before running the canonical shared-stack workflow, so future deploys preserve the practice service and routing.

## Rollout

1. Configure the practice repository's `production` environment with `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_PRIVATE_KEY`, and `DEPLOY_KNOWN_HOSTS` through secure GitHub settings.
2. Publish API shared deployment support to API main first. Publish the web workflow update and practice changes (including its workflow) to their main branches; the practice main push automatically starts CI/CD.
3. Confirm all three web services and backend are healthy after the shared-stack deployment.
4. Confirm the certificate covers tenant/admin/practice and HTTP redirects to HTTPS.
5. Verify all three public portals and `/api/v1/student/practice/catalog` (unauthenticated request must return HTTP 401).
