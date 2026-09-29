# Brainstorm: ClassesSection row actions → single common dropdown

**Date:** 2026-09-29
**Iteration of:** `260927-hung-classes-row-actions-redesign-brainstorm.md`

## Why this brainstorm exists

The previous brainstorm (2026-09-27) landed on **2 primary pills + 1 kebab** (Edit pill / Assign Students pill / ⋮ for status mutations). That was implemented and merged on branch `hung/feat/classes-entry` (commits 1b7d201, d742243).

User has now reviewed the live result and wants to consolidate **further**: a single common dropdown containing **all** row actions. The rationale is consistency — every action lives in one discoverable place, no visual hierarchy debate, and rows on narrow viewports no longer wrap at all.

## Ideas Explored

1. **Keep current 3-element layout (2 pills + 1 kebab)** — status quo. ❌ User explicitly requested a change after seeing the live result.

2. **All-in-one Dropdown with labeled trigger (CHOSEN)** — single `Dropdown` whose trigger is a button "Actions ▾". All 5 actions (Edit, Assign Students, Activate, Suspend, Deactivate, Archive) listed inside, with divider separating navigation actions from status mutations, Archive styled `danger`. ✅

3. **Keep primary pills, drop kebab entirely** — just Edit + Assign Students, status changes go through a different entry point. ❌ Loses the existing mutations UX, requires separate page-level action.

4. **Per-row icon-only buttons in a fixed grid** — Edit icon / User+ icon / Power icon / Trash icon. ❌ Requires new icon set + tooltip layer per icon, harder to extend.

## User's Direction

**Chốt (this iteration):**
- **All-in-one Dropdown**: 1 dropdown chứa tất cả 5 actions.
- **Trigger style**: button có label "Actions" + chevron-down icon (outlined-neutral — viền xám, giống style pill "Assign Students" cũ để đồng nhất).
- **Divider inside menu**: giữa nhóm navigation (Edit, Assign Students) và nhóm status (Activate/Suspend/Deactivate, Archive).
- **Disabled handling**: Assign Students hiển thị disabled-grayed (giữ nguyên item, hiển thị grayed) khi class INACTIVE/SUSPENDED — không ẩn, để user biết action tồn tại.
- **Scope**: cả `ClassesSection` (program detail) **và** `ClassesListView` (tenant-wide). Hai views phải đồng nhất pattern.

Lý do user:
- "xổ xuống hết" → muốn 1 dropdown thay vì 3 controls rời rạc.
- "common" → dùng lại `Dropdown` primitive có sẵn trong `@pte/ui`, không tạo component mới.
- Screenshot hiện tại cho thấy row trông đầy đủ action nhưng muốn gọn hơn — tập trung mọi action vào 1 nơi.
- User đồng ý mở rộng scope bao gồm cả `ClassesListView` (tenant-wide) để 2 views đồng nhất pattern. `ClassesListView` chỉ có 2 actions (Edit link navigate + Assign Students button), nên dropdown chỉ render 2 items, không có divider vì không có group nào khác.

## Open Questions

_(none — đủ signal để `/ck:plan`)_

## Risks

1. **Trigger class override**: `Dropdown`'s default trigger button is `h-10 w-10 grid place-items-center` (icon-only). Khi dùng labeled trigger, cần override bằng `triggerClassName` (đè cả hover styles). Phải re-add `hover:bg-blue-50 hover:text-blue-700` manually trong override để giữ consistent hover state.
2. **Discoverability**: Tất cả action bị ẩn sau 1 click → user mới có thể mất 5-10s để khám phá. Mitigation: clear label "Actions" + chevron icon hint rằng đây là dropdown.
3. **Click depth**: 1 click cho Edit/Assign Students thay vì 1 click. Mức tăng friction nhỏ nhưng đáng để measure sau release.
4. **Accessibility**: Labeled trigger dễ screen-reader navigate hơn icon-only; nhưng cần confirm `aria-haspopup="menu"` + `aria-expanded` được `Dropdown` set đúng (đã verify ở `Dropdown.tsx` line 101-102).
