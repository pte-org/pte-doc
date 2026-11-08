# Runtime configuration audit (pte-api)

Date: 2026-11-08. Scope: every value the backend reads from configuration, how it reaches the `app` container,
and the numeric limits, timeouts and schedules still written in Java code.

## 1. Findings fixed

| # | Finding | Effect before | Fix |
|---|---|---|---|
| 1 | The `app` service has no `env_file`; only variables listed under `environment:` in `docker-compose.services.yml` reach it. 47 variables read by `application.yml` were not listed. | Setting them in `.env` did nothing (e.g. `NOTIFICATION_INBOX_*`, `REDEEM_RATE_LIMIT_PER_SECOND`, `BILLING_*_CRON`, `PASSWORD_RESET_*`, `PAYOS_*_TIMEOUT_MS`, `MAIL_SMTP_*_TIMEOUT_MS`, `SCORING_AI_*` tuning, `VIETNAM_LOCATION_*`). | All of them are now passed through, each with the same default as `application.yml`, so an unset variable changes nothing. |
| 2 | `application.yml` declared `media.cloudinary.*` but `CloudinaryMediaService` read `cloudinary.*`. | The YAML block was dead; Cloudinary worked only because Spring maps `CLOUDINARY_*` environment variables to `cloudinary.*`. | The service reads `media.cloudinary.*`. |
| 3 | `CloudinaryGeneratedUploader.REQUEST_TIMEOUT_MS` was declared and never used. | Misleading constant. | Removed. |
| 4 | `.env.example` listed about half of the variables, several commented out. | No single checklist for a deployment. | `.env.example` lists every variable Compose reads (167), grouped, uncommented, with defaults. |

## 2. Values moved from Java code to configuration

Each value keeps its old number as the default (constant in code, `@Value("${key:default}")`), so behaviour is
unchanged until a variable is set.

| Area | Property | Environment variable | Default |
|---|---|---|---|
| Sign-in lock | `app.security.login.failure-limit`, `.window` | `LOGIN_FAILURE_LIMIT`, `LOGIN_LOCK_WINDOW` | 5, 15m |
| Password reset throttle | `app.password-reset.throttle.email-limit`, `.ip-limit`, `.window` | `PASSWORD_RESET_EMAIL_LIMIT`, `PASSWORD_RESET_IP_LIMIT`, `PASSWORD_RESET_THROTTLE_WINDOW` | 3, 10, 15m |
| Password reset mail pool | `app.password-reset.mail.max-threads`, `.queue-capacity` | `PASSWORD_RESET_MAIL_MAX_THREADS`, `PASSWORD_RESET_MAIL_QUEUE_CAPACITY` | 4, 200 |
| Exam content cache | `attempt.content-cache.ttl`, `.lock-ttl` | `ATTEMPT_CONTENT_CACHE_TTL`, `ATTEMPT_CONTENT_CACHE_LOCK_TTL` | 24h, 10s |
| Attempt media links | `attempt.media-url.grace-seconds`, `.reload-margin-seconds` | `ATTEMPT_MEDIA_URL_GRACE_SECONDS`, `ATTEMPT_MEDIA_URL_RELOAD_MARGIN_SECONDS` | 60, 600 |
| Signed media link life | `media.cloudinary.signature-ttl-seconds` | `CLOUDINARY_SIGNATURE_TTL_SECONDS` | 900 |
| License revoke preview | `billing.license-code.revoke-preview-ttl` | `BILLING_LICENSE_REVOKE_PREVIEW_TTL` | 5m |
| AI scoring retries | `scoring.ai.retry-max-attempts`, `.breaker-threshold` | `SCORING_AI_RETRY_MAX_ATTEMPTS`, `SCORING_AI_BREAKER_THRESHOLD` | 3, 5 |
| Generation live view | `itembank.generation.live.*` | `QUESTION_GEN_LIVE_STREAM_TIMEOUT_MS`, `QUESTION_GEN_LIVE_HEARTBEAT_MS`, `QUESTION_GEN_LIVE_FINISHED_RETENTION_MS`, `QUESTION_GEN_LIVE_IDLE_RETENTION_MS` | 1800000, 15000, 600000, 1800000 |
| E-mail send retry | `notification.email.retry.*` | `NOTIFICATION_EMAIL_RETRY_MAX_ATTEMPTS`, `..._INITIAL_INTERVAL_MS`, `..._MAX_INTERVAL_MS` | 3, 2000, 10000 |
| Practice entitlement | `practice.entitlement.refresh-seconds` | `PRACTICE_ENTITLEMENT_REFRESH_SECONDS` | 300 |
| Idempotency purge | `shared.idempotency.purge-cron` | `IDEMPOTENCY_PURGE_CRON` | `0 15 3 * * *` |
| AI scoring text model | `scoring.ai.text-vendor`, `scoring.ai.gateway.*` | `SCORING_AI_TEXT_VENDOR` (gateway values default to `QUESTION_GEN_*`) | gemini |

## 3. Values deliberately kept in code

A scan of `static final` numeric constants named like a limit, timeout, size or window found 261. Those kept in
code are product rules or contracts, not deployment settings:

- **PTE task and rubric rules**: word counts (SWT 5-75, WE 200-300), trait maxima, option and blank counts,
  paragraph counts, audio length per task. Changing them changes the exam, not the deployment.
- **Validation lengths that mirror database columns or API contracts**: name/description/reason lengths, key
  lengths, JSON byte caps, prompt editor limits.
- **API page sizes** (`DEFAULT_SIZE`/`MAX_SIZE` = 20/100 and similar): part of each endpoint's contract.
- **Upload size limits** (`MediaConstants` 25 MB / 25 MB / 10 MB): enforced in a `@Max` request annotation and
  mirrored by the web clients; the roster import limits (10 MB, 10 000 rows) are part of
  `docs/HOST_STUDENT_IMPORT_FLOW.md`.
- **Binary format offsets and algorithm parameters**: WAV header offsets, audio chunking frames, RSA key size.
- **Retention periods for audit and idempotency records**: data-retention policy, reviewed with the data model.
- **Dashboard cache lifetimes** (`OverviewConstants`, 30-60 s): freshness of on-screen figures only.
- **Per-module media link lifetimes** (examiner 900 s, scoring review 3600 s, session preview 300 s, practice
  900 s): every one is capped by `CLOUDINARY_SIGNATURE_TTL_SECONDS`, so that variable governs them.

## 4. Environment files

- `.env.example`: complete template; secrets are `__REQUIRED__` placeholders.
- `.env.local` and `.env` (not committed): every missing variable appended with its default; the three
  re-activated lines in `.env` (`BILLING_LICENSE_CODE_EXPIRATION_CRON`, `RATE_LIMIT_PER_SECOND`,
  `REDEEM_RATE_LIMIT_PER_SECOND`) uncommented in place; existing values untouched. Choices made while filling:
  `SCORING_AI_TEXT_VENDOR=gateway`, `CHAT_AI_PRICE_*=0` (the Capstone gateway does not bill per token),
  `.env` keeps `QUESTION_GEN_ENABLED=false` as before.
- `TASK_TYPES_CUSTOM_TEMPLATE_ACTIVATION_ENABLED` exists only in `.env.local` and is read by nothing.

## 5. Verification

- `docker compose ... config -q` passes for the local and the hosted file sets.
- `./mvnw -pl app test-compile` passes; the changed classes' tests and the architecture ratchets pass (28 suites,
  155 tests). Full-suite result: see the session report.
