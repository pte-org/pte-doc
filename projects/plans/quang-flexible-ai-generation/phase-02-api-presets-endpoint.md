# Phase 2: Presets endpoint (author-readable active template)

## Goal
`GET /api/v1/question-generation/presets` returns `[{taskType, section, maxCount}]` from the active exam template for
platform author roles, without opening `/exam-definitions/active` (HOST_ADMIN only).

## Stories covered
P1 "Full 1 đề" + per-skill presets (FR-03); data for P2 multiplier.

## Files
Create (assessment module — `ExamDefinitionService` depends on `ItembankService`, so itembank must not import assessment)
- `pte-api/app/src/main/java/com/pte/assessment/internal/controller/GenerationPresetController.java`
- `pte-api/app/src/main/java/com/pte/assessment/dto/GenerationPresetResponse.java` — record `(String taskType, String section, int maxCount)`
- `pte-api/app/src/main/java/com/pte/assessment/internal/service/GenerationPresetQueryService.java` — one public method `listActivePresets()`, `@Transactional(readOnly = true)`, calls `ExamDefinitionService.findActive()` (:73). `ExamDefinitionService` already has 9 public members → nothing added there (M8)

Change
- assessment constants (`assessment/internal/constant/…`) — `GENERATION_PRESETS_PATH`, `GENERATION_PRESET_ROLES` built from `SecurityRoles` (PLATFORM_ADMIN, ACADEMIC_MANAGER, ACADEMIC_STAFF, PLATFORM_AUTHOR). `GenerationAccessPolicy.AUTHOR_ROLES` lives in `itembank/internal/generation/job/GenerationAccessPolicy.java:20` (internal) and must not be imported (H4)

## Steps
1. Check `ModuleStructureTest` allowed deps and `PackageDensityTest` for `assessment/internal/controller`, `service`, `dto` (≤ 15 direct classes) (M8).
2. Map active definition items → presets: one row per taskType with `maxCount` (same taskType twice → max); skip `maxCount < 1`; order by section, then template order.
3. No active template → empty list.
4. Security (H4): `@PreAuthorize` with `GENERATION_PRESET_ROLES`; tenant-scoped callers (caller has tenant) → 403 via the same check generation uses (platform bank only). Verify `identity/internal/config/SecurityConfig.java` (:75 `PUBLIC_PATHS`) does not permit `/api/v1/question-generation/**`; endpoint must require authentication.
5. Guard test in itembank asserting `GenerationAccessPolicy.AUTHOR_ROLES` equals the assessment list (compares public `SecurityRoles` values from both sides; assessment constant is public API or duplicated literal list in test).

## Design Constraints
- Preflight: assessment owns the endpoint (no itembank→assessment import); ExamDefinitionService unchanged (9 public members); PackageDensity/ModuleStructure checked by tests.
- Thin controller, `ApiResponse<List<GenerationPresetResponse>>`; record DTO, never the entity.
- URL under `/question-generation` but owned by assessment — WHY comment (module cycle).
- Files ≤ 300 lines; no hardcoded strings.

## Quality and Testing State
- quality: skipped_by_user; decision: user_confirmed_skip [quality: skipped_by_user; decision: user_confirmed_skip]
- testing: passed — GenerationPresetQueryServiceTest (4), GenerationPresetControllerTest (method-security proxy, 4 author roles 200, 4 learner/tenant roles 403, anonymous never reaches the service), SecurityConfigGenerationPresetsPathTest (path not public → 401 from chain), GenerationPresetRolesTest, ApiInventoryExportTest updated; architecture tests green

## Tests
- `GenerationPresetQueryServiceTest`: fixture template → exact taskType/maxCount list (spec success criterion); no active → empty; duplicate taskType rule.
- `GenerationPresetControllerTest` with the **real security filter chain** (`@SpringBootTest`/`@AutoConfigureMockMvc` or `@WebMvcTest` importing `SecurityConfig`): 4 author roles 200; learner 403; tenant admin 403; anonymous 401.
- Role-list equality test; `ModuleStructureTest`, `PackageDensityTest` green.

## Acceptance criteria
- Authors get presets equal to the active template; others denied; no new module cycle.

## Risks
- Role lists drift → equality test.
- Template taskType unsupported by generation → FE filters by `/task-types`.
