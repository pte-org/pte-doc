# Phase 08 Output - Rollout and Rollback Runbook

## Forward order

1. Run the `pte-api` compile, practice/media/module-boundary tests and the full
   app test suite against a fresh database fixture.
2. Apply additive migration `V85__practice_response_media_binding.sql` through
   the normal Flyway startup path. Do not delete practice or media rows.
3. Deploy the API with `practice.web.enabled=false` while checking migration,
   health and logs for secrets, raw responses or signed URLs.
4. Enable the student web/API flag for an internal student cohort. Verify
   entitlement, locked deep-link denial, one recording upload and history after
   entitlement revoke.
5. Expand the cohort only after the API/media error rate, upload timeout rate,
   stale-session conflicts and Progress read latency are within the existing
   operational thresholds.

## Rollback

- Disable `practice.web.enabled` and, if used by the deployment, the strict
  entitlement flag. Existing practice rows and uploaded media remain intact.
- Do not run `DROP`, `DELETE`, `docker compose down -v` or a migration rewind as
  a first response.
- If the media binding schema needs repair, ship a forward migration and keep
  the old columns readable. The safe retry is to refresh the entitlement or
  session, not to detach a recording from its student/item boundary.
- Re-enable only after a fresh API health check, module-boundary test and a
  locked/unlocked smoke journey pass.

## Privacy and evidence checks

- No OTP, access token, answer text, audio bytes, signed Cloudinary URL or API
  secret may appear in logs, screenshots or test artifacts.
- Local compile/build and a mocked route are not production evidence. Public
  deployment, browser permission and Cloudinary checks remain environment-gated.
