# Phase 1: Quota 0 = unlimited (generation + chat)

## Goal
Value `0` (set by env or platform setting) disables `ITEMS_PER_USER_PER_DAY`, `ITEMS_PER_DAY`, `ITEMS_PER_BATCH` and the
chat daily limit, through one guard per module. Responses report `unlimited`, server-computed `remaining`, binding
`scope`, effective `maxItemsPerBatch`. **Code defaults unchanged** (100/300/50, chat 20, batch flag false); no migration.

## Stories covered
P1 "quotas disable-able" (FR-04, FR-05, FR-07).

## Files
Root `G = pte-api/app/src/main/java/com/pte/itembank/internal/generation`.

Create
- `G/job/GenerationQuotaGuard.java` — `requireWithin(CurrentUser caller, int count)`, `snapshot(CurrentUser caller)` (≤ 5 public methods; `Clock` last ctor param)
- `G/domain/QuotaScope.java` — enum `USER, GLOBAL` (or in `dto/` per package density)

Change
- `pte-api/app/src/main/java/com/pte/billing/QuestionGenerationLimit.java` — min 0 for `ITEMS_PER_BATCH` (:11), `ITEMS_PER_USER_PER_DAY` (:13), `ITEMS_PER_DAY` (:15); `ITEMS_PER_JOB`, `CONCURRENT_JOBS` stay ≥ 1. `PlatformSettingCatalog` (:65) passes `limit.minimum()` → settings API reports min 0
- `G/config/QuestionGenerationProperties.java` — `@Min(0)` on the three limits (~:96–103); defaults unchanged
- `G/config/QuestionGenerationPropertiesValidator.java` — same bounds if duplicated
- `G/config/GenerationLimits.java` — `isUnlimited(int)` strictly `== 0`; stored setting < 0 or unparsable → log + fall back to properties default; `effectiveMaxItemsPerBatch()` (0 → 500)
- `G/job/QuestionGenerationJobService.java` — `checkCaps` (:151) delegates quota part to the guard (concurrency check stays)
- `G/batch/QuestionGenerationBatchService.java` — `requireQuota` (:141) replaced by guard call (:73)
- `G/batch/BatchRequestValidator.java` (~:63–81) — `maxPerBatch` from `effectiveMaxItemsPerBatch()`
- `G/dto/GenerationQuotaResponse.java` — `record(long usedToday, int dailyLimit, Integer remaining, boolean unlimited, QuotaScope scope, int maxItemsPerBatch)`
- Constructor callers (M8, verified): `G/job/QuestionGenerationQueryService.java`, test `app/src/test/java/com/pte/itembank/internal/generation/controller/QuestionGenerationControllerTest.java` — query service now returns `guard.snapshot(caller)`
- `G/dto/AiStatusResponse.java` (`Limits`, :13) + `G/job/AiOverviewService.java` — `Limits` gains `boolean userDailyUnlimited, globalDailyUnlimited, batchUnlimited` and `effectiveMaxItemsPerBatch` (shown on the AI overview page, `AiAdminController`)
- Chat (B2, env only — `ChatAiProperties` from `chat.ai.daily-limit: ${CHAT_AI_DAILY_LIMIT:20}`, application.yml :78):
  - `pte-api/app/src/main/java/com/pte/chat/internal/config/ChatAiPropertiesValidator.java` (:55 `requireAtLeastOne`, :105) — `daily-limit` uses new `requireNonNegative`
  - `.../chat/internal/config/ChatAiProperties.java` (:31) — javadoc: 0 = unlimited, restart required
  - `.../chat/internal/service/quota/ChatQuotaService.java` (:44–72) — when limit 0: still `repository.consume` (counter `chat_usage.used` keeps counting; only `ChatQuotaRepository` reads it; reporting is `chat_usage_daily` via `ChatUsageRecorder`, untouched — M3) but never reject; refund unchanged
  - `.../chat/internal/service/quota/ChatQuotaRepository.java` — consume variant without the limit guard (or pass `Integer.MAX_VALUE` via a constant)
  - `.../chat/internal/service/quota/ChatQuotaSnapshot.java` — `int used, Integer remaining, Integer limit, Instant resetAt (nullable), boolean unlimited`
  - Touchpoints of the snapshot (M1/M2, verified): `chat/internal/controller/ChatController.java` (:45 SSE/reply quota payload, :49–51 `GET quota` → `ChatQuotaResponse`), `ChatQuotaResponse` DTO (+ `unlimited`), `chat/internal/service/ChatReply.java`, `chat/internal/service/ChatService.java`, `chat/internal/exception/ChatQuotaExceededException.java` (error payload built only when limited)
  - Tests: `app/src/test/java/com/pte/chat/internal/controller/ChatApiContractTest.java`, `ChatControllerTest.java`, `chat/internal/exception/ChatExceptionsTest.java`, `chat/internal/service/ChatServiceFailureTest.java`, contract fixture `app/src/test/resources/chat/api-contract-v1.json`
- vendor-web settings form (M7): `pte-web/apps/vendor-web/features/commercialization/components/PlatformSettingRow.tsx:27` uses `min={setting.minimum ?? undefined}` from the API (verified) → 0 enterable once the enum min is 0; check its client-side zod/validation helper for a hardcoded `>= 1` and fix if present

## Steps
1. Bounds: enum mins, `@Min(0)`, `PlatformSettingService` (:180) already validates `value >= definition.minimum()`.
2. `GenerationLimits` parsing rules (strict 0, negative/garbage → default + warn log).
3. `GenerationQuotaGuard`: compute user and global usage; binding scope = the non-zero limit with smallest remaining; `requireWithin` throws today's `*_LIMIT_REACHED` codes unchanged.
4. Rewire job service, batch service, validator, query service; response record + callers.
5. AI overview `Limits` fields.
6. Chat: validator + its tests **in the same step** (B2); service, repository, snapshot nullability, all touchpoints, contract fixture.
7. Settings form check (M7).

## Design Constraints
- Preflight: pte-api branch quang/feat/batch-question-generation (uncommitted batch work built on, line refs re-verified); chat must not import billing/itembank; no migration.
- One rule per module (`GenerationLimits.isUnlimited`, chat constant `UNLIMITED = 0`); chat must not import billing/itembank.
- Guard ≤ 5 public methods; `QuestionGenerationJobService`/`QuestionGenerationBatchService` public counts unchanged; files ≤ 300.
- `ApiResponse<T>`; error codes unchanged; additive JSON fields; nullable fields documented (phase 6).
- `Clock` injected; `@Transactional(readOnly = true)` for snapshot.

## Quality and Testing State
- quality: skipped_by_user; decision: user_confirmed_skip [quality: skipped_by_user; decision: user_confirmed_skip]
- testing: passed — new GenerationLimitsTest, GenerationQuotaGuardTest, BillingSettingsServiceTest/PlatformSettingServiceTest cases, BatchRequestValidatorTest/QuestionGenerationBatchServiceTest regressions, AiAdminServicesTest flags, Chat validator/quota/contract/DTO-shape tests; targeted run 1609 tests green after fixing ChatDtoShapeTest

## Tests
- `GenerationLimitsTest`: 0 → unlimited; −1 stored → default 100; `"abc"` stored → default; batch 0 → 500.
- `GenerationQuotaGuardTest`: all 0 → 70 ok, `remaining` null; user 5 → 6 rejected (**regression**); user 100 / global 10 → scope GLOBAL, remaining from global; global 0 + user 5 → scope USER.
- `QuestionGenerationJobServiceTest` / `QuestionGenerationBatchServiceTest`: delegate to guard; **regression** `ITEMS_PER_USER_PER_DAY=5` rejects a 6-item batch.
- `BatchRequestValidatorTest`: batch 0 → 500 ok, 501 rejected; batch 50 → 51 rejected (**regression**).
- `QuestionGenerationControllerTest`: quota JSON has `remaining`, `unlimited`, `scope`, `maxItemsPerBatch`.
- `AiOverviewServiceTest`: unlimited flags.
- Chat: `ChatAiPropertiesValidatorTest` 0 valid / −1 invalid; `ChatQuotaServiceTest` limit 0 → 50 consumes ok and `used`=50, **regression** limit 20 → 21st rejected; `ChatApiContractTest` + fixture, `ChatControllerTest` (unlimited quota + SSE payload), `ChatExceptionsTest`, `ChatServiceFailureTest`.
- Settings: `PlatformSettingServiceTest` 0 accepted, −1 rejected for the three keys.
- Architecture tests.

## Acceptance criteria
- With env/settings 0: 70-item batch + 50 chat messages succeed; quota endpoints `unlimited: true`.
- With code defaults: behaviour, codes and limits identical to today.
- Vendor-web settings form accepts 0 for the three keys.

## Risks
- Nullable snapshot fields break a consumer not listed → grep `ChatQuotaSnapshot`/`ChatQuotaResponse` again at implementation.
- Global vs user binding confusion → `scope` field + runbook.
