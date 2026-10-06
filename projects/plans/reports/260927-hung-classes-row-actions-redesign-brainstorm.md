# Brainstorm: Classes row actions redesign

**Date:** 2026-09-27

## Ideas Explored

1. **Transparent rounded row** — 6 outlined buttons ngang hàng, Edit đậm nhất, các nút nguy hiểm nhạt dần. ❌ Trải ngang quá, vẫn wrap trên narrow screen, "đẹp" vẫn cảm tính.

2. **Primary pill flux** (đã chọn) — 2 nút primary (Edit, Assign Students) pill outlined accent đứng cạnh nhau, các nút status/archive gom vào `⋯` kebab đơn giản 1 cấp. ✓ Che 90% workflow ở primary level, kebab chỉ mở khi cần.

3. **Soft action chips** — mỗi action 1 chip icon+label viền nhẹ, layout grid ngang. ❌ Giống direction #1 nhưng phức tạp hơn về icon set; cùng vấn đề wrap.

4. **Two-grouped dropdown** — Edit + Assign Students primary + 2 menu "Change status" + "Danger zone" riêng. ❌ Over-engineered cho 4 items.

## User's Direction

**Chốt**: Primary pill flux + outlined accent + destructive styling cho Archive + disable Assign Students khi class INACTIVE/SUSPENDED.

Lý do user:
- "viền bo tròn trong suốt" → outlined pill `border-action` + `bg-transparent` + `rounded-full`
- "màu viền nhấn" → `border-action` (xanh đậm của theme) để Edit nổi bật trong row mà không quá chói
- "ngay ngắn căn lề" → chỉ 3 elements thẳng hàng (Edit / Assign Students / `⋯`), flex với gap đều
- "không bị trống" → bỏ label dài (vd. "Deactivate" / "Archive") ra khỏi row, gom vào kebab

## Open Questions

- Không có — đủ signal cho `/ck:plan` để vào pha layout chi tiết.

## Risks

1. **Dropdown primitive đã có sẵn** — `@pte/ui/src/components/Dropdown.tsx` support `danger`, `disabled`, `hidden`, `aria-label`, `align`. ✅ Gỡ risk này.
2. **Tooltip khi disabled**: nút Assign Students disabled ở INACTIVE/SUSPENDED cần giải thích vì sao — dùng HTML `title` attr (đơn giản, đủ dùng); không cần primitive `Tooltip`.
3. **Consistency với `ClassesListView` (tenant-wide)**: ở đó chỉ có 2 actions (Edit link + Assign Students button). Sau redesign này, `ClassesListView` row vẫn giữ style cũ (text link) → có thể gây lệch. Giải pháp: áp dụng cùng redesign cho `ClassesListView` trong cùng phase.
