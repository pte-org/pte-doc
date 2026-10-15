# Spec: Examiner UI Coverage (incremental on phase 03)

**Date:** 2026-10-07
**Author:** hung
**Slug:** `hung-examiner-ui-coverage`
**Status:** Draft (post-brainstorm, pre-plan)
**Brainstorm:** [reports/261007-hung-examiner-ui-coverage-brainstorm.md](reports/261007-hung-examiner-ui-coverage-brainstorm.md)
**Builds on:** [quang-examiner-assignment-score-selection/phase-03-examiner-workflow.md](../quang-examiner-assignment-score-selection/phase-03-examiner-workflow.md) (shipped)

---

## Vấn đề thực tế (sau khi verify code)

Sau khi đọc `ExaminerWorkView.tsx` (370 dòng), `api.ts`, `constants.ts` và
`@/lib/errorPageConstants.ts`, nhiều thứ tưởng thiếu **đã có sẵn**:

| Concern | Trạng thái |
|---|---|
| Status filter `?status=` | ✅ **Wired** — `useExaminerQueue(status, page)` đã truyền `status` vào queryKey + `listExaminerWork(apiClient, { status, page, size: 20 })`. Select ở header đã onChange + reset page về 0. |
| Empty state cho attempt detail (NO_ANSWERS) | ✅ **Có** — `query.data?.answers.length === 0` → render `T.NO_ANSWERS` ở `ExaminerWorkView.tsx:258-260`. |
| Queue error + retry | ✅ **Có** — `queue.isError` → render `T.QUEUE_ERROR` + refetch button (`ExaminerWorkView.tsx:307-318`). |
| Attempt detail error + retry | ✅ **Có** — `query.isError` → render `T.DETAIL_ERROR` + refetch (`ExaminerWorkView.tsx:246-256`). |
| Loading inline | ✅ **Có** — `LOADING_QUEUE`, `LOADING_DETAIL` strings. |
| Constants coverage | ✅ **Đủ** — không cần thêm string nào. |
| `/examiner` index route | ❌ **Thiếu** — không có `app/(dashboard)/examiner/page.tsx`. |
| `app/(dashboard)/examiner/loading.tsx` | ❌ **Thiếu** — không có segment-level loading. |
| `app/(dashboard)/examiner/work/loading.tsx` | ❌ **Thiếu** — không có route-level loading. |
| `app/(dashboard)/examiner/work/error.tsx` | ❌ **Thiếu** — không có route-level error boundary. |

**Cập nhật scope:** Công việc thực sự chỉ là **4 file mới** (3 boundary +
1 index redirect). Không động vào `ExaminerWorkView` (đã đúng spec).

---

## User Stories

<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = out of scope -->

### P1 — Route boundaries (những gì thực sự thiếu)

- **[P1]** As an EXAMINER, when I navigate to `/examiner`, I land on the
  marking work queue (matching the existing login redirect target). No 404.
  - Accepted when: `GET /examiner` returns 200 (or 307 → `/examiner/work`).
  - Implementation: Next.js `redirect("/examiner/work")` in a server page
    component, no client-side check needed.

- **[P1]** As an EXAMINER, when I navigate to `/examiner/work`, I see a
  skeleton during the first network request instead of a blank screen.
  - Accepted when: `app/(dashboard)/examiner/work/loading.tsx` exists and
    reuses `Skeleton` from `@pte/ui` with the same shape as
    `app/(dashboard)/host/classes/loading.tsx`.

- **[P1]** As an EXAMINER, if the work queue request fails at the route
  level (route render error, not handled by inline `queue.isError`), I see
  a styled error state with a "Retry" action consistent with
  `host/classes/error.tsx`.
  - Accepted when: `app/(dashboard)/examiner/work/error.tsx` exists, uses
    `Button` from `@pte/ui` + `ERROR_PAGE_TEXT.EXAMINER_DESCRIPTION` từ
    `@/lib/errorPageConstants` (extend constant nếu thiếu), và có Retry
    button gọi `reset()`.

- **[P1]** As a Navigation, the `(dashboard)/examiner/loading.tsx` shows
  the same skeleton as the work sub-route when navigating between
  dashboard siblings. This is the segment-level boundary.
  - Accepted when: `app/(dashboard)/examiner/loading.tsx` exists.

### P1 — Reuse + non-regression

- **[P1]** All new code uses `@pte/ui` primitives (`Skeleton`, `Button`)
  + existing constants (`ERROR_PAGE_TEXT` in `@/lib/errorPageConstants`).
  No bespoke copies.
  - Accepted when: `grep` cho `Skeleton\|Button` trong các file mới chỉ
    match `@pte/ui` imports.

- **[P1]** No new strings hardcoded in JSX. New copy goes into
  `apps/tenant-web/lib/errorPageConstants.ts` (extend, don't fork).
  - Accepted when: New files có 0 string literals trong JSX (trừ prop
    names) ngoài những gì đã có sẵn trong `ERROR_PAGE_TEXT`.

- **[P1]** No `any` type. No `// @ts-ignore`.
  - Accepted when: `pnpm --filter tenant-web typecheck` passes.

### P1 — Extend `errorPageConstants` (1 entry mới)

- **[P1]** Add `ERROR_PAGE_TEXT.EXAMINER_DESCRIPTION` =
  `"We could not load your marking work. Please try again."`
  - Accepted when: Constant exists, `error.tsx` sử dụng đúng key.

### P3 — Out of scope (verified đã có hoặc backend không support)

- Status filter wiring — **đã có sẵn** (xem audit ở trên). Không sửa.
- Empty state cho attempt detail — **đã có sẵn** (`T.NO_ANSWERS`).
- Queue/detail inline error + retry — **đã có sẵn**.
- Move attempt detail to its own route — defer to a future plan.
- Examiner profile / account mgmt (no backend).
- Examiner analytics (no backend).
- Bulk score submission (immutable by design).
- Real-time push for new work (no backend).
- Multi-role fallback UX (strict).
- Host-side assignment / source-selection UIs.
- PROCTOR role UX.
- Theming changes.

---

## Functional Requirements

### FR-01: Tạo `apps/tenant-web/app/(dashboard)/examiner/page.tsx`

Server component, gọi Next.js `redirect()` ngay tại top-level:

```tsx
import { redirect } from "next/navigation";

export default function ExaminerIndexPage(): never {
  redirect("/examiner/work");
}
```

Lý do dùng `redirect()` thay vì client redirect: không cần render
anything, không có flash of empty content, không cần `"use client"`.
Destination (`/examiner/work`) đã enforce `allowedRoles={["EXAMINER"]}`
trong `DashboardChrome`, nên role check an toàn ở upstream.

### FR-02: Tạo `apps/tenant-web/app/(dashboard)/examiner/loading.tsx`

Segment-level loading. Pattern copy từ `host/classes/loading.tsx`:

```tsx
import type { ReactElement } from "react";
import { Skeleton } from "@pte/ui";

export default function Loading(): ReactElement {
  return (
    <div className="space-y-4 p-8">
      <Skeleton className="h-8 w-64" />
      <Skeleton className="h-40 w-full" />
    </div>
  );
}
```

### FR-03: Tạo `apps/tenant-web/app/(dashboard)/examiner/work/loading.tsx`

Route-level loading cho `/examiner/work`. Cùng pattern như FR-02.

### FR-04: Tạo `apps/tenant-web/app/(dashboard)/examiner/work/error.tsx`

Route-level error boundary. Pattern copy từ `host/classes/error.tsx`:

```tsx
"use client";

import type { ReactElement } from "react";
import { Button } from "@pte/ui";
import { ERROR_PAGE_TEXT as TEXT } from "@/lib/errorPageConstants";

interface ErrorProps {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function ExaminerWorkError({ reset }: ErrorProps): ReactElement {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-8 text-center">
      <h1 className="text-xl font-semibold text-gray-900">{TEXT.PAGE_TITLE}</h1>
      <p className="max-w-md text-sm text-gray-600">{TEXT.EXAMINER_DESCRIPTION}</p>
      <Button onClick={reset}>{TEXT.RETRY}</Button>
    </div>
  );
}
```

Note: route-level `error.tsx` chỉ trigger khi error bubble lên segment
boundary. Inline errors từ TanStack Query (`queue.isError`,
`query.isError`) đã có sẵn retry UX ở trong `ExaminerWorkView`. Hai
layer này complementary, không conflict.

### FR-05: Extend `apps/tenant-web/lib/errorPageConstants.ts`

Thêm 1 entry mới vào object `ERROR_PAGE_TEXT`:

```ts
EXAMINER_DESCRIPTION: "We could not load your marking work. Please try again.",
```

Vị trí: append alphabetically (giữa `EXAM_DESCRIPTION` và
`PROGRAM_DESCRIPTION`). Constant này dùng lại được cho cả `/examiner/`
segment-level error nếu sau này thêm.

### FR-06: Forbidden patterns (auto-reject trong code review)

- Inline string trong JSX (trừ prop names).
- Inline style.
- `any` type.
- `// @ts-ignore`.
- `fetch()` trong component (route này chỉ là page-level, không gọi API).
- Sửa `ExaminerWorkView.tsx`, `api.ts`, `constants.ts`, `navigation.tsx`,
  `LoginView.tsx`, `page.tsx` của `/examiner/work/` — phase 03 đã pass
  quality gate, không động vào.

### FR-07: Files to create (4 files mới + 1 edit)

| Path | Type | LOC estimate |
|---|---|---|
| `apps/tenant-web/app/(dashboard)/examiner/page.tsx` | new | 5 |
| `apps/tenant-web/app/(dashboard)/examiner/loading.tsx` | new | 12 |
| `apps/tenant-web/app/(dashboard)/examiner/work/loading.tsx` | new | 12 |
| `apps/tenant-web/app/(dashboard)/examiner/work/error.tsx` | new | 22 |
| `apps/tenant-web/lib/errorPageConstants.ts` | edit (+1 line) | 12 → 13 |

**Tổng:** 4 file mới + 1 file edit. ~63 dòng. Không file nào > 25 dòng.

---

## Non-Functional Requirements

- **Performance**: Loading skeleton render ≤ 1 frame. `redirect()` ở
  `/examiner` page phải synchronous (Next.js static redirect, không
  waterfall).
- **Accessibility**:
  - `error.tsx` action button `aria-label="Retry"` (qua `ERROR_PAGE_TEXT.RETRY`
    label, đã có ở pattern `host/classes/error.tsx`).
- **Consistency**: Trigger style, error/loading shape giống
  `app/(dashboard)/host/classes/{loading,error}.tsx` (cùng monorepo,
  cùng role-conditional layout).
- **File size**: mỗi file mới ≤ 25 dòng (trừ auto-generated). Spec
  không động vào `ExaminerWorkView.tsx` nên không lo vượt 300.
- **Build**: `pnpm --filter tenant-web build` PASS.
- **Typecheck**: `pnpm --filter tenant-web typecheck` PASS.
- **Lint**: ESLint 0 errors, không tăng warnings so với trước khi sửa.

---

## Success Criteria

- [ ] `GET /examiner` returns 200 (render redirect, không 404).
- [ ] `GET /examiner/work` render `Skeleton` placeholder trong khi
  fetch lần đầu (boundary-level).
- [ ] Nếu route `/examiner/work` bubble error lên segment boundary,
  render `error.tsx` với `ERROR_PAGE_TEXT.EXAMINER_DESCRIPTION` +
  `ERROR_PAGE_TEXT.RETRY` button.
- [ ] Inline errors từ TanStack Query vẫn hoạt động như phase 03
  (queue error + detail error với refetch button).
- [ ] Phase 03 manual smoke (queue → attempt detail → score submit) vẫn
  pass.
- [ ] PLATFORM_ADMIN, HOST_ADMIN, STUDENT, PROCTOR flows không bị ảnh
  hưởng.
- [ ] `pnpm --filter tenant-web build` PASS.
- [ ] `pnpm --filter tenant-web typecheck` PASS.
- [ ] `pnpm --filter tenant-web lint` không tăng warnings.

---

## Out of Scope

- Examiner profile page.
- Examiner stats / dashboard overview.
- Bulk score submission.
- Real-time notifications.
- Move detail sang sub-route.
- Status filter re-wiring (đã có sẵn).
- Empty state cho attempt detail (đã có sẵn).
- HOST_ADMIN assignment/source-selection UI (workstream của Quang, phase 02/04).
- PROCTOR UX (workstream riêng).
- Multi-role fallback.
- Theming.

---

## Assumptions

- Phase 03 chất lượng cao đã pass quality gate, không cần re-review logic
  chính.
- `@pte/ui` đã có `Skeleton`, `Button` (verified từ
  `packages/ui/src/components/index.ts`).
- `LoginView` đã có branch `roles.includes("EXAMINER") &&
  !roles.includes("HOST_ADMIN")` → redirect `/examiner/work` (không cần sửa).
- `DashboardChrome` pattern `allowedRoles={["EXAMINER"]}` là canonical;
  áp dụng cho cả `/examiner` (nếu sau này thêm content thật).
- `errorPageConstants.ts` là canonical nơi extend; không fork constants.

---

## Open Items for `/ck:plan`

- **Mode:** Fast (1 phase, 4 file mới + 1 edit, không có Hard risk).
- **Phase:** Single phase `phase-01-route-boundaries.md`.
- **Quality gate:** Có thể chạy `ck:quality --gate` (architectural impact
  nhỏ nhưng non-trivial — recommend yes).
- **Tests:** E2E Playwright ngoài scope; manual smoke đủ (theo pattern
  `host/classes/{loading,error}.tsx` đã có).

---

## Open Items for `/ck:plan`

- **Mode:** Fast (1 phase, 4 file mới + 1 edit, không Hard risk).
- **Phase file:** `phase-01-route-boundaries.md`.
- **Test strategy:** Manual smoke theo pattern `host/classes/{loading,error}.tsx`.
- **Quality gate:** Recommend `ck:quality --gate` yes (architectural consistency
  là non-trivial).

---

## Cross-References

- **Backend (shipped):** `pte-api/app/src/main/java/com/pte/scoring/internal/controller/ExaminerWorkController.java`
- **API client (shipped):** `pte-web/packages/api-client/src/requests/scoring/examiner.ts`
- **Phase 03 spec:** `pte-doc/projects/plans/quang-examiner-assignment-score-selection/phase-03-examiner-workflow.md`
- **Phase 03 quality report:** `pte-doc/projects/plans/quang-examiner-assignment-score-selection/quality/phase-03-examiner-workflow-quality-report.json`
- **Phase 03 test report:** `pte-doc/projects/plans/quang-examiner-assignment-score-selection/tests/phase-03-examiner-workflow-test-report.json`
- **Reference boundary patterns:**
  - `pte-web/apps/tenant-web/app/(dashboard)/host/classes/loading.tsx`
  - `pte-web/apps/tenant-web/app/(dashboard)/host/classes/error.tsx`
- **Existing constants:**
  - `pte-web/apps/tenant-web/lib/errorPageConstants.ts` (extend với `EXAMINER_DESCRIPTION`)
  - `pte-web/apps/tenant-web/features/examiner/constants.ts` (KHÔNG động vào — phase 03 đã đủ)
- **Existing files (KHÔNG động vào):**
  - `pte-web/apps/tenant-web/app/(dashboard)/examiner/work/page.tsx`
  - `pte-web/apps/tenant-web/features/examiner/ExaminerWorkView.tsx`
  - `pte-web/apps/tenant-web/features/examiner/api.ts`
  - `pte-web/apps/tenant-web/lib/navigation.tsx`
