# Plan: Flexible AI question generation popup
Status: ✅ Implemented (code uncommitted) — was: 📝 Draft (rev 2: user decisions U1–U3 + red-team fixes applied)
Date: 2026-11-18
Mode: Hard (docs only)

Spec: [spec.md](spec.md) · Brainstorm: [261118 report](../../../plans/reports/261118-flexible-ai-generation-brainstorm.md)
Builds on [quang-batch-question-generation](../quang-batch-question-generation/plan.md) — still uncommitted on branch `quang/feat/batch-question-generation` in pte-api and pte-web; commit/merge it first.
API code root: `pte-api/app/src/main/java/com/pte/itembank/internal/generation` (below: `generation/`).

## Overview
One centered popup (`GenerationDialog`, `@pte/ui` `Modal size="full"`) replaces `GenerationDrawer`. The author ticks any
task types across 4 skills, sets count/CEFR/topics/imageKind per type, or applies a preset ("Full 1 đề" = active exam
template `maxCount`, per-skill presets, ×N multiplier). Submit mode is decided by
`resolveSubmitMode(selection, origin, currentTaskType)` (U1). Quotas: `0` = unlimited, enabled **only by env/settings**
on the deployment (U2) — code defaults unchanged. UIs hide quota notices when the server says `unlimited`.

```
QuestionEditorView ─┐                  ┌─ origin=editor AND 1 type × 1 item AND type == currentTaskType
                    │                  │     → POST /question-generation/jobs (saveQuestions=false) → preview fills form (unchanged)
BatchListView ──────┼─ GenerationDialog┤
                    │  GET task-types, presets, quota{unlimited, remaining, scope, maxItemsPerBatch}
                    │                  └─ else → (editor dirty? confirm) → POST /question-generation/batches → router.push(ai-batches/{id})
```

## User decisions (binding)
| # | Decision |
|---|---|
| U1 | Editor origin: any types may be ticked. Exactly 1 type × 1 item **and** type == editor's current task type → existing single preview flow (`saveQuestions=false`, fills form). Anything else → batch; if the editor form is dirty, confirm before navigating away. Batch-list origin → always batch (even 1×1). |
| U2 | Unlimited via env/settings only. Code defaults stay (user/day 100, day 300, batch 50, chat 20, `QUESTION_GEN_BATCH_ENABLED=false`). **No V54 migration.** Phase 6 runbook gives exact `.env` lines and SQL (set + restore) for `platform_settings` — settings override env. |
| U3 | Full scope: presets endpoint, per-skill presets, ×N multiplier, delete drawer + batch-create code. |

## Decisions (binding)
| # | Decision | Rejected alternative → reason |
|---|---|---|
| D1 | `0` = unlimited for `ITEMS_PER_USER_PER_DAY`, `ITEMS_PER_DAY`, `ITEMS_PER_BATCH` (setting + env) and chat `daily-limit` (env only). `isUnlimited` is strictly `== 0`; negatives / unparsable stored values are invalid → fall back to the code default (today's behaviour) | Negative/null sentinel → breaks bounds and settings UI |
| D2 | **Single choke point** (H1): new `generation/job/GenerationQuotaGuard` (`requireWithin(caller, count)`, `snapshot(caller)`) used by `QuestionGenerationJobService.checkCaps` (:151) and `QuestionGenerationBatchService.requireQuota` (:141) and by the quota query | Two copies of the 0-rule → drift |
| D3 | `ITEMS_PER_BATCH=0` → effective cap `BatchGenerationConstants.MAX_ITEMS_PER_BATCH_HARD_LIMIT` (500); effective value exposed in the quota response (H3) | No cap → one typo floods the sequential worker |
| D4 | `GenerationQuotaResponse(usedToday, dailyLimit, remaining:Integer?, unlimited, scope:USER\|GLOBAL?, maxItemsPerBatch)`; `remaining`/`scope` computed on the server from the tighter non-zero limit, null when unlimited. FE uses `remaining`, never `dailyLimit - usedToday` (H2) | FE arithmetic → wrong when the global limit binds |
| D5 | Chat: limit 0 skips the limit check only; the `chat_usage` counter keeps counting (it feeds `used` in the snapshot; reporting uses separate `chat_usage_daily` via `ChatUsageRecorder`). `ChatQuotaSnapshot.remaining/limit` become nullable `Integer`, `resetAt` nullable, new `unlimited` (M1/M2/M3) | Skip counting → `used` meaningless, refund edge cases |
| D6 | Presets read lives in **assessment** (`ExamDefinitionService` already depends on `ItembankService`; itembank → assessment = cycle). `GenerationAccessPolicy.AUTHOR_ROLES` is in `itembank.internal…job` and cannot be imported → assessment defines its own role list from `SecurityRoles` (same 4 roles) with a test asserting equality via reflection-free constant comparison in an itembank test (H4) | Import itembank internal → Modulith violation |
| D7 | Selection → batch rows 1:1; FE never splits (`BatchSplitter` splits rows into ≤10 children) | Duplicate rule |
| D8 | `/ai-batches/new` redirects to `/ai-batches?create=1` (opens popup); `BatchCreateView`, `useBatchForm` deleted (U3) | Two forms drift |
| D9 | Dialog handles `GENERATION_BATCH_DISABLED` (multi-select disabled + notice) and `GENERATION_JOB_ALREADY_RUNNING` (notice + link to the running batch, H6) | Raw error toast |
| D10 | Presets that would exceed the effective batch cap are refused with an explicit message (no silent clamp) (H5); presets query 403/404 → presets hidden silently | Silent clamp → author doesn't know counts changed |

### Coding standards (binding)
- **pte-api** (`pte-api/docs/CODING_STANDARDS_API.md`): file ≤ 300 lines; service ≤ 5 public methods (`ExamDefinitionService` already has 9 public methods incl. 2 constructors → **do not add**; new `GenerationPresetQueryService`); time via injected `Clock`; no hardcoded strings/numbers (`QuestionGenerationConstants`, `BatchGenerationConstants`, chat/assessment constants); `ApiResponse<T>`; `DomainException` subclasses; record DTOs; `@Transactional(readOnly = true)` for queries; `ModuleStructureTest`, `PackageDensityTest` (assessment packages too), `SourceFileSizeTest` pass, allowlists never grow.
- **pte-web** (`pte-web/docs/CODING_STANDARDS_WEB.md`): file ≤ 300 lines, component ≤ 150 lines (pre-split `_GenerationDialog*.tsx`); strings in feature constants/i18n (no hardcoded English, L3), no hardcoded colors; `@pte/ui` as shipped; server state via `@pte/api-client` + TanStack Query hooks in `api.ts` (staleTime ≥ 5 min for task types/presets); pure logic in `utils/`; tests under `tests/unit` (retained `__tests__` moved there in phase 5).

## Scope change (user)
Batch list screen, `/ai-batches/new` and the sidebar entry removed; the editor popup is the only entry point; batch detail page kept (U1 batch-list origin no longer exists). Contract and runbook: [fe-contract-and-runbook.md](fe-contract-and-runbook.md).

## Phases
| # | Phase | Repo | Goal | Depends | Status |
|---|---|---|---|---|---|
| 1 | [Quota 0 = unlimited](phase-01-api-quota-unlimited.md) | pte-api (+ vendor-web settings check) | Guard, 0-rule, quota response, AI overview, chat | batch plan committed | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 2 | [Presets endpoint](phase-02-api-presets-endpoint.md) | pte-api | Author-readable active-template presets | – (parallel with 1) | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 3 | [api-client + practice chat](phase-03-client-practice-unlimited.md) | pte-web (api-client, pte-practice) | New quota fields + presets; chat hides quota when unlimited | 1, 2 | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 4 | [GenerationDialog](phase-04-web-generation-dialog.md) | pte-web (vendor-web) | Modal, grid, presets, summary/ETA, submit modes | 3 | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 5 | [Integrate + remove drawer](phase-05-web-integrate-remove-drawer.md) | pte-web (vendor-web) | Editor + list entry, dirty confirm, `/new` redirect, deletions, test moves | 4 | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |
| 6 | [Docs, contract, runbook](phase-06-docs-contract.md) | pte-doc, pte-api docs | Contract; `.env` + SQL enable/rollback | 1–5 | [x] [quality: skipped_by_user; decision: user_confirmed_skip] |

## Risks
| Risk | Impact | Mitigation |
|---|---|---|
| Batch work uncommitted in both repos | Line refs move | Commit batch branch before phase 1; re-verify |
| Abuse / cost when unlimited (M4) | Runaway provider calls if model becomes paid or an account is compromised | Backstops stay: `CALLS_PER_ITEM` (setting default 40), `CONCURRENT_JOBS` (3), hard cap 500/batch, one open saving batch per user, author roles only; re-enable limits via runbook |
| Settings override env | Operator sets env to 0 but seeded rows (100/300/50) still bind | Runbook SQL updates `platform_settings` too |
| Chat limit is env-only | Changing it needs redeploy/restart | Documented in runbook (B2) |
| `ChatQuotaSnapshot` int → Integer | NPE / contract break | All touchpoints listed in phase 1; `api-contract-v1.json` updated |
| Modulith cycle / internal import for presets | Build break | D6; `ModuleStructureTest` |
| Single-flow regression | Editor preview breaks | `resolveSubmitMode` tests + existing editor tests |

## Open questions (recommended default in bold)
- Q1: `QUESTION_GEN_BATCH_ENABLED=false` in code — dialog with multi-select on a deployment without the flag? → **Dialog still opens; multi-select disabled with notice on `GENERATION_BATCH_DISABLED`; single editor flow works.** Deployment sets `true` via runbook.
- Q2: Multiplier ×N for per-skill presets too? → **Full preset only** (spec P2).
- Q3: `ITEMS_PER_JOB` accepts 0? → **No** (single path stays 1..10).
