# Plan: Examiner route boundaries (completeness parity)

**Spec:** [spec.md](spec.md)
**Mode:** Fast · **Test:** default (không bật `--tdd`)
**Phạm vi:** 4 file mới + 1 file edit. Không động vào phase 03 logic đã pass quality gate.
**Trạng thái:** Đã triển khai — Phase 01 hoàn tất 2026-10-07 (Fast mode, quality + tests skipped by user). Build/typecheck/lint clean, 0 new warnings.

---

## Scope challenge

- **Exists?** Một phần: `/examiner/work` đã ship từ phase 03 của
  Quang. Status filter, empty state, inline error/retry đều có sẵn.
  Thiếu 4 boundary file: `/examiner` index redirect, segment-level
  `loading.tsx`, route-level `loading.tsx`, route-level `error.tsx`.
- **Minimum:** Tạo 4 file mới (≤ 25 dòng mỗi file) + extend
  `errorPageConstants.ts` với 1 entry. Pattern copy từ
  `host/classes/{loading,error}.tsx`. Không động vào phase 03.
- **Complexity:** **Fast** — single segment, 5 file tổng cộng, 0
  component mới, 0 thay đổi API contract, 0 backend change, không
  security-sensitive.
- **Spec quality:** **PASS** — P1/P3 stories, measurable success
  criteria, không còn `[NEEDS CLARIFICATION]`.
- **Test strategy:** Manual smoke theo pattern
  `host/classes/{loading,error}.tsx` đã có sẵn. Không cần E2E Playwright
  mới trong turn này (phase 03 đã cover examiner workflow).

## Phạm vi và nguyên tắc bất biến

1. Phase 03 logic không được động vào. Tất cả file trong
   `apps/tenant-web/features/examiner/`,
   `apps/tenant-web/app/(dashboard)/examiner/work/page.tsx`,
   `apps/tenant-web/lib/navigation.tsx` đều là output của phase 03,
   đã pass quality gate.
2. Chỉ thêm file mới + extend 1 constant. Không tạo duplicate component.
3. Mọi string copy phải vào `errorPageConstants.ts` (canonical cho
   boundary text), không hardcode trong JSX.
4. Mọi UI primitive phải từ `@pte/ui` (`Skeleton`, `Button`).
5. Pattern phải nhất quán với `host/classes/{loading,error}.tsx`.
6. Build / typecheck / lint phải pass với 0 warning mới.
7. Manual smoke 4 role (PLATFORM_ADMIN, HOST_ADMIN, STUDENT, EXAMINER)
   phải pass, đặc biệt phase 03 flow.

## Kiến trúc và ownership

| Concern | Owner | Ranh giới |
|---|---|---|
| Examiner workflow logic | `pte-web/apps/tenant-web/features/examiner/` (phase 03) | Không động vào |
| Route segment `/examiner/**` | `pte-web/apps/tenant-web/app/(dashboard)/examiner/` | 4 file mới thuộc đây |
| Boundary copy text | `pte-web/apps/tenant-web/lib/errorPageConstants.ts` | Extend 1 entry, không fork |
| UI primitives | `packages/ui` (`@pte/ui`) | Dùng `Skeleton`, `Button` — không wrap |
| Auth + nav | `apps/tenant-web/features/auth/` + `lib/navigation.tsx` (phase 03) | Không động vào |

## Thứ tự triển khai

```text
phase-01-route-boundaries
  ├─ extend errorPageConstants.ts (+1 line)
  ├─ create app/(dashboard)/examiner/page.tsx (5 lines)
  ├─ create app/(dashboard)/examiner/loading.tsx (12 lines)
  ├─ create app/(dashboard)/examiner/work/loading.tsx (12 lines)
  ├─ create app/(dashboard)/examiner/work/error.tsx (22 lines)
  ├─ build + typecheck + lint
  └─ manual smoke (4 roles + phase 03 flow)
```

Đây là single phase vì tất cả 4 file mới + 1 edit đều là 1 unit
logic (route boundary completeness), không có dependency nội tại
nào phải tách. Phase có thể complete trong 1 cycle.

## Bản đồ phase

| Phase | Stories | Kết quả có thể kiểm chứng |
|---|---|---|
| [01 — Route boundaries](phase-01-route-boundaries.md) | P1 route boundaries, reuse, non-regression; FR-01..07 | **Completed (2026-10-07, Fast mode).** 4 file mới + 1 edit; build/typecheck/lint clean; 0 new warnings. Quality + unit tests skipped by user (`--fast`). |

## Test và verification order

1. **Trước phase:** đọc 3 reference file (`host/classes/loading.tsx`,
   `host/classes/error.tsx`, `errorPageConstants.ts`) để khẳng định
   pattern. Verify `ExaminerWorkView.tsx` không bị touch bởi phase
   này (chỉ `app/(dashboard)/examiner/**` + `lib/errorPageConstants.ts`
   thuộc phase).
2. **Trong phase:** tạo 5 file theo thứ tự trong plan, mỗi file
   `git diff` verify trước khi next.
3. **Sau phase:**
   - `pnpm --filter tenant-web build` → PASS
   - `pnpm --filter tenant-web typecheck` → PASS
   - `pnpm --filter tenant-web lint` → 0 new warnings
   - Manual smoke: login as EXAMINER → `/examiner` → 200 →
     `/examiner/work` → queue render → filter change → page change
     → open attempt → submit score → back to queue. Login as
     PLATFORM_ADMIN/HOST_ADMIN/STUDENT → không có regression.
4. **Security:** Không có auth change. Route `/examiner` chỉ
   `redirect()` — không leak data. Destination `DashboardChrome`
   `allowedRoles={["EXAMINER"]}` enforce role check ở upstream.
5. **End-to-end:** Phase 03 flow (queue → detail → submit) vẫn pass
   unchanged.

## Acceptance mapping

| Spec success criterion | Cách verify |
|---|---|
| `GET /examiner` returns 200 (no 404) | `curl -I /examiner` → 307 hoặc render redirect page |
| `GET /examiner/work` render `Skeleton` ở boundary | DevTools Network slow-3G → thấy skeleton |
| `/examiner/work` `error.tsx` render khi route-level error | Inject `throw new Error()` tạm thời (hoặc giả lập API 500) → thấy error UI |
| Inline error/retry ở queue + detail vẫn hoạt động | Phase 03 manual smoke |
| Phase 03 flow (queue → submit) vẫn pass | Manual smoke |
| 4 roles không bị ảnh hưởng | Login lần lượt từng role, kiểm tra dashboard load |
| `pnpm --filter tenant-web build` PASS | Build log |
| `pnpm --filter tenant-web typecheck` PASS | tsc log |
| `pnpm --filter tenant-web lint` không tăng warnings | eslint log |

## Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Vô tình sửa `ExaminerWorkView.tsx` hoặc page.tsx của `/examiner/work/` | Chỉ thêm file mới trong `app/(dashboard)/examiner/`. FR-06 cấm sửa phase 03 files. |
| Pattern `host/classes/error.tsx` dùng `"use client"` — quên directive | Spec FR-04 ghi rõ `"use client"` ở đầu file. |
| `errorPageConstants.ts` mất alphabetical order | Append `EXAMINER_DESCRIPTION` giữa `EXAM_DESCRIPTION` và `PROGRAM_DESCRIPTION`. |
| Inline string trong JSX | FR-06 cấm. Mọi text qua constant. |
| File nào đó > 25 dòng | Review LOC trước commit; nếu > 25 → re-check pattern. |

## Handoff

Sau khi phase 01 hoàn tất, ready to cook:

```text
/ck:cook --fast pte-doc/projects/plans/hung-examiner-ui-coverage/plan.md
```

`--fast` vì đã được classify là Fast mode. Tests mặc định (manual
smoke, không cần viết test mới trong turn này). Quality gate
recommend yes (architectural consistency với các boundary hiện có).

Đây là trạng thái kế hoạch. Không có source code được viết trong bước
lập plan.
