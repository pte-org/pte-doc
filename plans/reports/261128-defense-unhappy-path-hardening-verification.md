# Verification: Defense 1.1 unhappy-path hardening

**Date:** 2026-11-28
**Plan:** `pte-doc/projects/plans/phat-defense-unhappy-path-hardening/plan.md` (phases 01–07 implemented, phase 08 partly)
**Brainstorm:** `pte-doc/plans/reports/261127-defense-unhappy-path-brainstorm.md`
**Mode:** TDD per phase (RED tests prepared first, then implementation); quality gate skipped by the user.
**Not committed, not deployed.**

## 1. What changed

| Phase | Area | Result | Migration |
|---|---|---|---|
| 01 | Temp-password gate (non-Student roles only), no self-approval incl. Platform Admin, rubric activates only from PENDING; web refreshes the token after the first password change | Done | – |
| 02 | Exam template approval mark (`approved_at/approved_by`, cleared on edit, required to activate; RETIRED re-activation needs the mark); PUBLISH runs submit checks incl. CEFR; option/blank counts for hand-written questions; Host template cannot raise counts or timing | Done | V61 |
| 03 | Inactive class rejects assign/transfer/merge; order TTL as setting `order_pending_ttl_minutes` (1440) + expiry cron every 5 min; Host cancels a PENDING order (tenant-web button); bulk Proctor/Examiner API; tax-code normalisation | Done (bulk staff: API only) | V62 |
| 04 | Server answer deadline = exam end + `exam_answer_grace_seconds` (120); late save 409 `ATTEMPT_DEADLINE_PASSED` + one `LATE_SYNC_REJECTED` incident; submit still accepted; overdue sweeper; publish blocker `OBJECTIVE_NOT_SCORED` with detailed list in tenant-web; re-assigning a class to a scheduled exam → 409 `CLASS_ALREADY_ASSIGNED`; never-started attempts kept with `NOT_STARTED`; incident status CHECK (NOT VALID); pte-app server clock (monotonic, 2 s resync tolerance) and monotonic Alt+Tab debounce | Done | V63 |
| 05 | Four AI switches as platform settings (`ai_question_generation_enabled`, `ai_exam_scoring_enabled`, `ai_practice_scoring_enabled`, `ai_chat_enabled`, default true) + practice rate limit / max retries; disabled AI fails retryably; `AI_RUBRIC_SCORER_UNAVAILABLE` is retryable; vendor-web toggles + warning banner | Done | V64 |
| 06 | Practice deadline (24 h, mock = length + 30 min) + expiry sweeper (null deadlines untouched); progress counts only COMPLETED; locked org cannot finish/discard/sign uploads and does not re-dispatch AI; lock reason shown in pte-practice | Done | – |
| 07 | Audit rows for PayOS paid / paid-after-close (system actor), host cancel, license redeem/revoke, single/bulk Student and staff creation, reactivate, rubric submit/reject/activate, result publication | Done | – |

## 2. Automated checks (2026-11-28, local)

| Check | Command | Result |
|---|---|---|
| Backend full suite | `.\mvnw.cmd -pl app clean test` | 6062 run, 5 failures, 1 error, 103 skipped — all 6 pre-existing (see §3) |
| tenant-web | `tsc --noEmit`, `vitest run` | 0 type errors; 138/138 files |
| vendor-web | `tsc --noEmit`, `vitest run` | 0 type errors; 132/132 files |
| api-client | `vitest run` | 48/48 files |
| pte-practice | `tsc --noEmit`, `vitest run` | 0 type errors; 127/128 files (1 pre-existing) |
| pte-app | `flutter test`, `flutter analyze` | 908 passed; 14 analyzer issues, all pre-existing in two widget test files |

Always build pte-api with `clean`: the VS Code Java language server writes stale classes into `target/` and can hide compile errors.

## 3. Failures that were already there (not touched by this plan)

- `BillingOverviewQueriesTest` (3) and `AdminDashboardControllerTest` (1): tests expect a 30-day "expiring soon" window, the committed constant `BillingOverviewService.EXPIRING_SOON_DAYS` is 7.
- `ModuleStructureTest`: `proctoring → session.domain.enums.AttendanceStatus` (commit 2930fe63) and `support → itembank :: response` (790253db).
- `SourceFileSizeTest`: `BrandedEmailTemplate.java` (306) and `ExamPublishService.java` (322), both committed before this plan.
- pte-practice `button-palette.test.ts` (palette drift against pte-web tokens); pte-app analyzer issues in `app_routes_test.dart`, `app_shell_test.dart`.

## 4. Not checked yet (needs the operator)

1. **Prod env (read-only SSH):** whether `PRACTICE_WEB_ENABLED`, `PRACTICE_STRICT_ENTITLEMENT_ENABLED`, `QUESTION_GEN_ENABLED`, `CHAT_AI_ENABLED` are on and which scoring provider is used; whether `.env` pins `BILLING_ORDER_EXPIRATION_CRON` to hourly. The AI switches can only narrow what env enables.
2. **Prod data before V63 validates:** `SELECT DISTINCT status FROM exam_incidents;` then `ALTER TABLE exam_incidents VALIDATE CONSTRAINT check_exam_incidents_valid_status;`.
3. **Attack checklist and the 13 demo scenarios** on the demo environment after deploy (`attack-checklist.md` in the plan folder).
4. **Demo accounts on prod:** two Academic Managers (self-approval is now refused for everyone), one Academic Staff; no demo staff account left with a temporary password except the one used to show F-20.
5. **After the demo:** turn the four AI switches back on, reset `order_pending_ttl_minutes` to 1440.
6. **BM04 v1.2 wording:** F-13 / DS-03a "scored when the Host starts scoring"; DS-01b (a Repeat Sentence draft without audio cannot be saved); DS-04a (student presses "Chấm điểm"); DS-02a one vs both students; §8.1 automated total 107 + 4 NFR = 111; F-11 device check covers microphone and speaker only.
7. UI checks are left to the user (no browser automation).

## 5. Residual risks

- Practice progress totals are computed from the latest 100 sessions; a student with more is under-counted.
- Bulk staff creation has no UI (API `POST /api/v1/users/bulk-staff` only).
- Exam answers can still be rewritten for earlier items (3-6, deliberately out of scope); one attempt is not bound to one device; device check does not cover network/screen.
- A suspended staff member's access token stays valid up to 15 minutes.
