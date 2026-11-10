# VPS environment synchronization and deployment blockers

Date: 2026-11-10, Asia/Bangkok.

## Environment update

On the user's request, synchronized 112 new nonempty, Compose-referenced settings from local API `.env` into the VPS environment. Existing production values, including database user/credentials, keys, domains, mail/payment settings and Cloudinary folder, were preserved. Files were atomically replaced after Compose validation, retaining permission 600. No secret values were printed or written to this report.

External backups:

- `/home/ubuntu/pte-env-backups/pte-api-before-env-update-20261110T145053Z.env`
- `/home/ubuntu/pte-env-backups/pte-api-before-env-resync-20261110T145533Z.env`

After the user edited local env again, resynchronized `QUESTION_GEN_ENABLED=true`. Shared AI gateway URL/key/model and Kokoro URL/key are populated. Text scoring uses `gateway`; inbox worker remains disabled, matching local configuration. The first newly created app container received the gateway/Kokoro settings; the later question-generation enable change requires the next app recreation to take effect.

The update occurred while the existing deployment was building images. Atomic file replacement preserved a valid complete env file for subsequent Compose calls; no deployment command or second container recreation was started concurrently by this repair.

## API/Web deployment blocker

API run https://github.com/pte-org/pte-api/actions/runs/42837298301 and Web run https://github.com/pte-org/pte-web/actions/runs/42837242094 built images, but deployment failed because the app did not become healthy. App logs show Flyway V11 checksum mismatch.

V11 was changed after it was applied: three table references gained `public.` prefixes. All other historical migrations through V15 match the earlier production source. The DB records V11 checksum `2143057531`; the changed source computes `1416312199`.

Restored V11 source to its exact historical Git blob `9005f17d68fcc79ccd510abd6e2d66710f0506a6`, restoring checksum `2143057531`. Independent review approved. Minimal compilation and diff checks passed. No database deletion, Flyway repair, or checksum-row modification was performed. User-owned edits to `docker-compose.services.yml` were preserved.

The restored migration must be published and deployed before the app can pass startup validation. Current backend health is not claimed successful.

## Practice CI blocker

Practice run https://github.com/pte-org/pte-practice/actions/runs/42837263647 failed unit-test collection because `button-palette.test.ts` read sibling `pte-web` CSS absent from the single-repo runner. Deferred reads to `beforeAll` and skipped the optional comparison when the sibling fixture is absent; existing palette assertions remain unchanged.

Verification: full local suite 793 passed; isolated checkout simulation 788 passed and five expected skips. Original code reproduced ENOENT in that isolated context. TypeScript, scoped ESLint, test placement and diff checks passed. Main agent reran the focused palette test successfully; independent review approved. The other sibling test dependency, chat contract, is already guarded.

Practice's failed workflow needs corrected source on main before it can pass. No workflow rerun can correct the missing-file bug in the existing commit.

## Remaining verification

Publish the two reviewed source fixes, then run the canonical deployment with the updated VPS env. Verify migration upgrade, app health, Nginx routing and public endpoints. External AI/TTS requests and complete user journeys were not tested during environment synchronization.

## Follow-up: rollout verified

After the user published the fixes, API run [42840589733](https://github.com/pte-org/pte-api/actions/runs/42840589733) completed successfully at main `1d88a81fa1389f22c169c7f476782f11c1240370`. Practice run [42841318569](https://github.com/pte-org/pte-practice/actions/runs/42841318569) passed lint, unit tests, build, deploy and public verification at main `33404a06b5532d469a790c0cc092b99b28a3e5c0`. On the user's explicit request to check or rerun all three repos, reran failed jobs of Web run [42837242094](https://github.com/pte-org/pte-web/actions/runs/42837242094); it concluded success at `faf6d9d08c274c1df6bd750263935120d3c183c8`.

The app and Practice containers are healthy; tenant/vendor are running. Backend internal health is UP. Production Flyway history reached V41 with success=true. Runtime app settings confirm chat and question generation enabled, text scoring vendor `gateway`, and nonempty shared gateway plus Kokoro URL/key settings. Secret values were not printed. All three public portal roots and tenant actuator health returned HTTP 200 after workflow completion.

The previous startup blocker is resolved. Real external AI/TTS calls and complete authenticated user journeys remain outside this deployment verification.
