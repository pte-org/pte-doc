# Pre-deploy environment audit: API, Web, Practice

Date: 2026-11-10, Asia/Bangkok. Read-only source, local environment, and VPS environment comparison. No environment values, credentials, or private keys are included here. No server configuration was modified, no workflow was started, and no deployment was performed.

## Result

Do not deploy the new API with the currently inspected VPS environment unchanged: chat is enabled there, but neither the new shared AI gateway URL/key nor their legacy question-generation fallbacks are populated. Current source binds chat provider credentials to question-generation LLM properties and validates enabled chat at startup. This is a source-derived startup blocker, not an observed failed deployment of the new image.

Local `.env` contains all variable names in `.env.example`; hosted Compose configuration renders successfully. The VPS environment has substantially fewer explicitly configured variables. Most missing tuning variables have Compose/application defaults; missing names alone do not mean a broken deployment.

## Required decisions and settings

| Group | Local state | VPS state | Required action before feature rollout |
| --- | --- | --- | --- |
| `AI_GATEWAY_BASE_URL`, `AI_GATEWAY_API_KEY`, `AI_GATEWAY_MODEL` | Populated | Missing, legacy question-generation fallbacks also absent | Synchronize these settings before deploying the enabled-chat API. Provider validity/reachability was not tested. |
| `SCORING_AI_PROVIDER` | `azure-gemini` | `azure-gemini` | Existing selection agrees. |
| `SCORING_AI_TEXT_VENDOR` | `gateway` | Missing; current Compose defaults to `gemini` | Set to `gateway` to use the intended shared provider for text scoring. Retain production Azure credentials. |
| `QUESTION_GEN_ENABLED` | `false` | Missing; defaults to `false` | Set explicitly to `true` only if AI question generation is intended in this release. Copying local env as-is leaves this feature disabled. |
| `QUESTION_GEN_STUB` | `false` | Missing; defaults to `false` | Retain non-stub production behavior. |
| `KOKORO_BASE_URL`, `KOKORO_API_KEY` | Empty | Missing | Supply both for question-generation speech synthesis. Current Kokoro client refuses synthesis if either is blank. Text generation does not establish audio readiness. |
| `QUESTION_GEN_VISION_CHECK` | `true` | Missing; defaults to `false` | Choose explicitly if vision review should run. |
| `NOTIFICATION_INBOX_ENABLED` | `false` | Missing; defaults to `false` | Set to `true` if inbox delivery worker should run. This flag controls delivery processing; email settings are independent. |
| `PRACTICE_WEB_ENABLED`, `PRACTICE_STRICT_ENTITLEMENT_ENABLED`, `CHAT_AI_ENABLED`, `NEXT_PUBLIC_CHAT_ENABLED` | Enabled | Enabled | Preserve alignment between backend access and Practice build-time chat flag. |

## Hosted routing and frontend settings

- Hosted Compose derives `CORS_ALLOWED_ORIGINS` from all three production domains, overriding the local localhost list.
- Hosted Compose also derives `APP_WEB_TENANT_URL` and `APP_WEB_ADMIN_URL`, used in password-reset links.
- Tenant, vendor, and Practice API base URLs are passed as Docker build arguments. Local frontend `.env.local` files point to local endpoints, but the web Docker context excludes these files; build arguments define hosted endpoints.
- Practice `NEXT_PUBLIC_CHAT_ENABLED` is a build-time argument; changing it requires rebuilding the Practice image.
- No additional frontend provider secret was found necessary: AI credentials belong to the backend environment.

## Preserve production-specific values

`APP_DB_USER` and `CLOUDINARY_SUBMISSION_FOLDER` differ between local and VPS. Preserve these production values unless deliberately migrating them. Do not replace the entire VPS `.env` with the local file. Preserve database credentials, cryptographic keys, hosted domain settings, SMTP/payment settings, and existing production integrations.

The obsolete `PROCTOR_WS_ALLOWED_ORIGINS` local setting has no reference in the inspected current production source/Compose files. It does not configure current proctor behavior.

## Verification boundary

- Inspected current `application.yml`, Compose layers, Dockerfiles, provider validation, Kokoro synthesis guard, notification worker condition, frontend environment references, and build workflows.
- `docker compose --env-file .env -f docker-compose.yml -f docker-compose.services.yml -f docker-compose.deploy.yml config --format json` succeeded locally; expanded secrets were captured in-process and not printed.
- VPS `.env` permission was `600`. Read-only comparison emitted names and presence/difference metadata, not secret values.
- Local shared AI and Azure settings are populated; population does not prove credentials are accepted or services are reachable from the VPS.
- No provider request, email, payment, startup rehearsal, schema-migration rehearsal, or end-to-end feature test was performed.

Next step: synchronize a reviewed subset of new backend settings while preserving production-specific values, resolve Kokoro/feature-enable choices, validate the resulting hosted Compose configuration, then deploy and inspect startup health.
