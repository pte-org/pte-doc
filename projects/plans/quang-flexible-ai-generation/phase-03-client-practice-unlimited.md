# Phase 3: api-client + practice chat unlimited UI

## Goal
Client types/requests carry the new quota fields (`remaining`, `unlimited`, `scope`, `maxItemsPerBatch`) and presets;
pte-practice hides the chat quota notice/badge and client checks when unlimited.

## Stories covered
P1 "quotas disable-able" UI part (FR-05); data for FR-03.

## Files (verify exact paths with Glob)
Change
- `pte-web/packages/api-client/**/requests/generation.ts` — `GenerationQuota { usedToday, dailyLimit, remaining: number | null, unlimited, scope: 'USER' | 'GLOBAL' | null, maxItemsPerBatch }`; `getGenerationPresets()`; `GenerationPreset`; index export
- `pte-web/apps/pte-practice/features/chat/contracts.ts` — quota `remaining/limit: number | null`, `resetAt: string | null`, `unlimited`
- `pte-web/apps/pte-practice/features/chat/chat-quota.ts` — `isQuotaUnlimited`, blocked = false when unlimited; uses `remaining` only
- `pte-web/apps/pte-practice/features/chat/useChatQuota.ts`, `ChatQuotaNotice.tsx` (render null), `ChatComposer.tsx` (no client block), `ChatToggleButton.tsx` (no remaining badge); SSE quota event handling tolerates nulls

## Steps
1. Extend types; missing `unlimited` → false (older servers keep today's UI).
2. One selector in `chat-quota.ts`; components consume it.
3. Export presets request; monorepo typecheck.

## Design Constraints
- Preflight: pte-practice is a separate repo; was on quang/feat/maintain-v3 (clean) → created quang/feat/chat-unlimited-quota; api-client fields optional for older servers.
- No new hardcoded strings; components ≤ 150 lines; pure logic in `chat-quota.ts`.
- TanStack Query keys unchanged; `@pte/api-client` is the only HTTP layer.

## Quality and Testing State
- quality: skipped_by_user; decision: user_confirmed_skip [quality: skipped_by_user; decision: user_confirmed_skip]
- testing: passed — pte-practice 116 files / 860 tests (chat-quota unlimited + regression, ChatQuotaNotice, contract fixture unlimitedQuota), api-client 43 files / 766 tests (generationPresets.test.ts)

## Tests (`tests/unit`)
- `chat-quota.test.ts`: unlimited → never blocked; nulls handled; **regression** limit 20, remaining 0 → blocked.
- `ChatQuotaNotice` test: unlimited → nothing; limited → remaining shown.

## Acceptance criteria
- `unlimited: true` → no notice/badge, sending never blocked client-side; limited behaviour unchanged.

## Risks
- Other consumers of the changed types → whole-monorepo typecheck.
