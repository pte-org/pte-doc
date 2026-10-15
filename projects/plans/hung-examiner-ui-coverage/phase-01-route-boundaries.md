# Phase 01 — Route boundaries completeness

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** P1 route boundaries, reuse, non-regression; FR-01..07.
**Depends on:** Không.
**Outcome:** `/examiner/**` segment có đủ 4 boundary file (index redirect,
segment loading, route loading, route error) — parity với
`/host/classes/**` — và `errorPageConstants.ts` có thêm
`EXAMINER_DESCRIPTION`.

## Mục tiêu

Đưa `/examiner/**` route segment về parity với các dashboard route khác
(ví dụ `/host/classes/**`) bằng cách thêm các boundary file bắt buộc
theo rule #7 của `pte-web` (App Router yêu cầu `loading.tsx` + `error.tsx`
cho dynamic route segments).

Không động vào phase 03 logic đã pass quality gate. Tất cả file mới đều
copy pattern từ `host/classes/{loading,error}.tsx`.

## Việc cần làm

### Step 1 — Extend `errorPageConstants.ts`

**File:** `apps/tenant-web/lib/errorPageConstants.ts`

Thêm 1 entry giữa `EXAM_DESCRIPTION` và `PROGRAM_DESCRIPTION` (giữ
alphabetical order):

```ts
EXAMINER_DESCRIPTION: "We could not load your marking work. Please try again.",
```

Object hiện tại:

```ts
export const ERROR_PAGE_TEXT = {
  SYSTEM_TITLE: "System Error",
  SYSTEM_DESCRIPTION: "Something went wrong. Please reload the page.",
  PAGE_TITLE: "Something went wrong",
  PAGE_DESCRIPTION: "We could not load this page. Please try again.",
  EXAM_DESCRIPTION: "We could not load this exam. Please try again.",
  PROGRAM_DESCRIPTION: "We could not load this program. Please try again.",
  CLASS_DESCRIPTION: "We could not load this class. Please try again.",
  CLASSES_DESCRIPTION: "We could not load the classes list. Please try again.",
  RELOAD: "Reload",
  RETRY: "Try again",
} as const;
```

Sau khi thêm: thêm `EXAMINER_DESCRIPTION` giữa `EXAM_DESCRIPTION` và
`PROGRAM_DESCRIPTION`.

### Step 2 — Tạo `/examiner` index page

**File mới:** `apps/tenant-web/app/(dashboard)/examiner/page.tsx`

Server component gọi Next.js `redirect()`:

```tsx
import { redirect } from "next/navigation";

export default function ExaminerIndexPage(): never {
  redirect("/examiner/work");
}
```

Lý do dùng `redirect()` (server-side) thay vì client redirect:
- Không cần render anything → không có flash of empty content.
- Không cần `"use client"` directive.
- `DashboardChrome` ở `/examiner/work` đã enforce
  `allowedRoles={["EXAMINER"]}` → role check ở upstream.

### Step 3 — Tạo `/examiner` segment-level loading

**File mới:** `apps/tenant-web/app/(dashboard)/examiner/loading.tsx`

Pattern copy từ `host/classes/loading.tsx`:

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

Hiển thị khi Next.js navigate giữa các sibling dashboard segments.

### Step 4 — Tạo `/examiner/work` route-level loading

**File mới:** `apps/tenant-web/app/(dashboard)/examiner/work/loading.tsx`

Cùng pattern như Step 3:

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

### Step 5 — Tạo `/examiner/work` route-level error

**File mới:** `apps/tenant-web/app/(dashboard)/examiner/work/error.tsx`

Pattern copy từ `host/classes/error.tsx`:

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

Note quan trọng:
- `"use client"` directive bắt buộc (App Router error boundary).
- Props: `{ error, reset }` theo convention Next.js 15.
- `TEXT.PAGE_TITLE` + `TEXT.EXAMINER_DESCRIPTION` + `TEXT.RETRY` đều
  đã có sẵn (1 mới, 2 có sẵn).
- KHÔNG render AI score, Host score, selected source (bảo vệ blind
  marking — phase 03 invariant).
- Inline errors từ TanStack Query (queue/detail) có retry riêng
  trong `ExaminerWorkView` — không conflict với boundary này. Hai
  layer complementary.

### Step 6 — Build gate

```bash
pnpm --filter tenant-web build
pnpm --filter tenant-web typecheck
pnpm --filter tenant-web lint
```

Cả 3 phải pass với 0 new warnings/errors.

### Step 7 — Manual smoke

Đăng nhập với 4 role và kiểm tra:

| Role | Flow | Expected |
|---|---|---|
| `EXAMINER` | Direct navigate `/examiner` | 200 (redirect to `/examiner/work`) |
| `EXAMINER` | Direct navigate `/examiner/work` | 200, queue render với loading skeleton ngắn |
| `EXAMINER` | Phase 03 flow (queue → detail → submit) | Vẫn pass như trước |
| `EXAMINER` | Filter status dropdown change | Queue refetch với `?status=` |
| `EXAMINER` | Open attempt có 0 eligible answers | Render `T.NO_ANSWERS` empty state |
| `PLATFORM_ADMIN` | Login + dashboard | Không regression |
| `HOST_ADMIN` | Login + dashboard | Không regression |
| `STUDENT` | Login + results | Không regression |

## Hợp đồng cần chốt khi implement

- File mới phải ≤ 25 dòng (spec FR constraint). Nếu vượt → re-check
  pattern, có thể đã leak logic không cần thiết.
- Không file mới nào có hardcoded string ngoài `TEXT.*` references.
- `errorPageConstants.ts` phải giữ `as const` assertion ở cuối
  object — không được remove khi extend.
- Append `EXAMINER_DESCRIPTION` alphabetical, không reorder các
  entry hiện có.
- `ExaminerWorkView.tsx`, `api.ts`, `constants.ts`, `navigation.tsx`,
  `LoginView.tsx`, `page.tsx` của `/examiner/work/` — **cấm động vào**.
  Nếu thấy cần sửa → escalate, không tự ý.

## Kiểm chứng và acceptance

- [ ] 4 file mới tồn tại với đúng nội dung như Step 2-5.
- [ ] `errorPageConstants.ts` có thêm `EXAMINER_DESCRIPTION`.
- [ ] `pnpm --filter tenant-web build` PASS.
- [ ] `pnpm --filter tenant-web typecheck` PASS.
- [ ] `pnpm --filter tenant-web lint` không có new warnings.
- [ ] `curl -I http://localhost:3000/examiner` returns 200 hoặc 307
      (không 404).
- [ ] Manual smoke 4 roles pass.
- [ ] Phase 03 flow vẫn pass.
- [ ] Không file mới nào > 25 dòng.
- [ ] Không file mới nào có inline string ngoài `TEXT.*` reference.

**Acceptance:** Route segment `/examiner/**` đạt parity với
`/host/classes/**` về boundary files; phase 03 logic intact; build +
typecheck + lint clean.

## Design Constraints

- **Không động vào phase 03 files.** Examiner workflow logic, API hooks,
  constants, navigation, LoginView, page.tsx của `/examiner/work/` đều
  là output đã pass quality gate của phase 03 — coi như read-only
  reference, không sửa.
- **Reuse `host/classes` boundary pattern.** Hai pattern file
  (`loading.tsx` skeleton, `error.tsx` + Button + TEXT.*) phải nhất
  quán với `host/classes`. Copy verbatim, không "improve".
- **Reuse `@pte/ui` primitives.** Chỉ `Skeleton`, `Button`. Không
  inline style, không tạo component wrap mới.
- **Reuse `errorPageConstants`.** Extend, không fork. Mọi error copy
  qua constant.
- **Append alphabetical.** `EXAMINER_DESCRIPTION` đi giữa
  `EXAM_DESCRIPTION` và `PROGRAM_DESCRIPTION`. Không reorder.
- **File size cap.** Mỗi file mới ≤ 25 dòng. Spec hard constraint
  (`pte-web` rule #4).
- **Preflight:** Đã verify `@pte/ui` exports `Skeleton`, `Button`
  từ `packages/ui/src/components/index.ts`. Đã verify
  `errorPageConstants.ts` pattern từ
  `apps/tenant-web/lib/errorPageConstants.ts`. Đã verify
  `host/classes/{loading,error}.tsx` pattern từ
  `apps/tenant-web/app/(dashboard)/host/classes/`. Không cần
  re-discovery khi implement.

## Files

- `pte-web/apps/tenant-web/lib/errorPageConstants.ts` (edit +1 line)
- `pte-web/apps/tenant-web/app/(dashboard)/examiner/page.tsx` (new,
  5 dòng)
- `pte-web/apps/tenant-web/app/(dashboard)/examiner/loading.tsx` (new,
  12 dòng)
- `pte-web/apps/tenant-web/app/(dashboard)/examiner/work/loading.tsx`
  (new, 12 dòng)
- `pte-web/apps/tenant-web/app/(dashboard)/examiner/work/error.tsx`
  (new, 22 dòng)

## Phase Checkpoint

- Unit tests: no (spec không có unit test mới trong turn này;
  boundary files là simple enough để manual smoke)
- `ck:quality`: no (user opted `--fast` in handoff Q&A) `[quality: skipped_by_user; decision: user_confirmed_skip]`
- Hard-mode confirmation: N/A (Fast mode)
- Manual smoke checklist: xem Step 7 ở trên.

## Quality and Testing State

- quality: skipped_by_user (user opted `--fast`; decision: user_confirmed_skip)
- quality report: (n/a — fast mode, no gate)
- quality receipt: (n/a — fast mode, no gate)
- testing: not_started
- testing report: (n/a — fast mode, no new unit tests)
- Testing detail: Manual smoke theo Step 7 sẽ do user tự chạy ở
  browser sau khi tôi báo cáo. Không có test tự động trong turn này
  (boundary files quá simple để warrant unit test; phase 03 đã cover
  examiner workflow E2E).

## Implementation result (2026-10-07)

- 4 file mới + 1 edit tạo thành công.
- `pnpm --filter tenant-web lint` PASS (1 pre-existing warning ở
  `CreateTicketModal.tsx` — không phải file của phase này).
- `pnpm --filter tenant-web build` PASS (Next.js 16.2.9, 22.9s
  compile + 10.4s TypeScript + 26/26 static pages).
- `tsc --noEmit` PASS (0 errors).
- Routes mới xuất hiện trong build output: `/examiner` + `/examiner/work`
  (cả 2 static prerendered).
