# Spec: ClassesSection row actions → single common dropdown

**Date:** 2026-09-29
**Status:** Draft (iteration of 2026-09-27 spec)
**Previous design:** 2 outlined pills (Edit / Assign Students) + 1 ⋮ kebab for status mutations. See `reports/260927-hung-classes-row-actions-redesign-brainstorm.md`.

---

## Problem Statement

`ClassesSection` (program detail) và `ClassesListView` (tenant-wide) row hiện render 3 controls riêng biệt: Edit pill/Link, Assign Students button, ⋮ kebab. Mặc dù layout gọn hơn trước, user vẫn phải scan 3 vùng để tìm action cần — đặc biệt với các status mutations (Activate/Suspend/Deactivate/Archive) bị ẩn trong kebab thì "khó thấy, dễ quên".

Cần consolidate: **tất cả actions của 1 row gom vào 1 dropdown duy nhất**, trigger là button có label "Actions" + chevron. Mục tiêu:
- 1 nơi duy nhất để tìm mọi action → giảm cognitive load.
- Row gọn hơn nữa (chỉ còn 1 control), không còn wrap trên narrow viewport.
- Visual hierarchy đơn giản: "row này có actions" → click Actions → xem full list.

Scope: **cả `ClassesSection` (program detail) và `ClassesListView` (tenant-wide)**. Hai views phải đồng nhất pattern. Note: `ClassesListView` row hiện chỉ có 2 actions (Edit link + Assign Students button) — sau redesign, gom thành 1 dropdown duy nhất tương tự `ClassesSection`.

### Điểm khác biệt giữa 2 views cần preserve

| View | Edit behavior | Status mutations | Assign Students target |
|------|---------------|------------------|------------------------|
| `ClassesSection` | `onEdit()` callback → mở `EditClassModal` | Có (Activate/Suspend/Deactivate/Archive) | Deeplink `/host/students?...` |
| `ClassesListView` | `<Link>` → navigate `/host/programs/{p}/classes/{c}` | Không có (vì `ClassesListView` không có hook `useClassStatusMutations`) | Deeplink `/host/students?...` |

`ClassesListView` không có status mutations trên row (chỉ navigate + assign), nên dropdown bên đó chỉ có 2 items + 1 divider rỗng — **không nên render divider** khi chỉ có 1 group. Build menu items conditionally.

---

## User Stories

<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = future/out-of-scope -->

- **[P1]** As a Host, when I view a Program's Classes list, I want a single "Actions" button on every row so that I can find all 5 row actions in one predictable place without scanning 3 separate controls.
  Accepted when: Row chỉ có 1 button "Actions ▾". Click mở dropdown chứa đủ 5 items. Width button ≥ 100px, click target dễ hit.

- **[P1]** As a Host, when I click "Actions", I want the menu to clearly separate navigation actions (Edit, Assign Students) from status mutations (Activate/Suspend/Deactivate, Archive) via a divider so that I can scan by intent.
  Accepted when: Menu có divider ngăn giữa nhóm navigation và nhóm status. Archive hiển thị text đỏ (`text-red-600`).

- **[P1]** As a Host, when a Class is INACTIVE or SUSPENDED, I want the "Assign Students" item in the dropdown to be visible but disabled (grayed) so that I know the action exists but is not currently available.
  Accepted when: Item "Assign Students" hiển thị `disabled` + `opacity-50` + `cursor-not-allowed` khi status ≠ ACTIVE. Không ẩn hoàn toàn.

- **[P2]** As a Host, I want the trigger button to feel like a normal outlined button (viền xám, giống style pill cũ) so that the visual style đồng nhất với các nút khác trong row table.
  Accepted when: Trigger style = `border border-slate-300 bg-transparent text-slate-700 rounded-full` (bo tròn, outlined-neutral) + chevron icon. Hover: `bg-slate-50`.

- **[P2]** As a Host viewing the tenant-wide Classes list (`/host/classes`), I want the same single-dropdown pattern so that the two views feel consistent and I don't have to learn two different row action layouts.
  Accepted when: `ClassesListView.ClassRowActions` cũng dùng 1 dropdown duy nhất với trigger "Actions ▾" giống `ClassesSection`. Edit trong dropdown dùng `router.push` (navigate) thay vì callback (mở modal). Dropdown chỉ có 2 items (Edit, Assign Students), không render divider vì chỉ có 1 group.

- **[P3]** _(out of scope)_
  - Bulk action qua dropdown khi nhiều row được select.
  - Keyboard shortcut để mở dropdown (vd. `Enter` khi focus row).
  - Tooltip giải thích side-effects của từng status action.
  - Áp dụng cùng pattern cho `MergeClassRow` / `LecturerAssignmentRow`.

---

## Functional Requirements

1. **FR-01**: `ClassesSection.tsx` `ClassRowActions` chỉ render **1 element** duy nhất: `<Dropdown items={...} label="Actions" trigger={...} triggerClassName="..." align="right" />`. Bỏ Edit button, Assign Students button, và kebab cũ.

2. **FR-02**: `Dropdown.items` gồm 6 phần tử theo thứ tự:
   1. `{ label: "Edit", onSelect: () => onEdit() }`
   2. `{ label: "Assign students", onSelect: () => router.push(buildAssignStudentsUrl(...)), disabled: !isActive || pending, ... }`
   3. `{ separator: true, key: "nav-status-divider" }`
   4. `{ label: "Activate", onSelect: () => mutations.activate.mutate(), hidden: isActive }`
   5. `{ label: "Suspend", onSelect: () => mutations.suspend.mutate(), hidden: !isActive }`
   6. `{ label: "Deactivate", onSelect: () => mutations.deactivate.mutate(), hidden: studentClass.status === "INACTIVE" }`
   7. `{ separator: true, key: "danger-divider" }`
   8. `{ label: "Archive", onSelect: () => mutations.archive.mutate(), danger: true }`

3. **FR-03**: `Dropdown.label = "Actions"` (accessible name cho trigger button).

4. **FR-04**: `Dropdown.trigger` = JSX custom button:
   ```tsx
   <span className="inline-flex items-center gap-1.5">
     Actions
     <ChevronDownIcon className="h-4 w-4" />
   </span>
   ```
   Đặt trong `<span>` để giữ inline-flex alignment.

5. **FR-05**: `Dropdown.triggerClassName` override default `h-10 w-10 grid place-items-center` để button có shape outlined-pill:
   ```tsx
   triggerClassName="rounded-full border border-slate-300 bg-transparent px-4 py-1.5 text-sm font-medium text-slate-700 transition-colors hover:bg-blue-50 hover:text-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
   ```
   Note: `hover:bg-blue-50 hover:text-blue-700` được re-add manually vì `Dropdown` default classes bị override toàn bộ bởi `triggerClassName`.

6. **FR-06**: Khi `pending === true` (mutation đang chạy), trigger button `disabled` + dropdown items vẫn trigger được nhưng user thấy loading state qua `errorMessage` block dưới row.

7. **FR-07**: Khi click 1 item, menu đóng + mutation chạy. Error hiển thị inline dưới row (giữ pattern hiện tại `rowError && <p>`).

8. **FR-08**: `ChevronDownIcon` được add vào `packages/ui/src/components/icons.tsx` nếu chưa có (check trước). Nếu đã có, dùng lại.

9. **FR-09**: `ClassesListView.tsx` row cũng refactor:
   - Bỏ `<Link>` Edit + `<button>` Assign Students → thay bằng 1 `<Dropdown>` duy nhất.
   - `Dropdown.items` chỉ có 2 items (Edit, Assign Students), không có divider hay status mutations.
   - Edit item: `onSelect` → `router.push(\`/host/programs/${option.programPublicId}/classes/${option.classPublicId}?organizationPublicId=${option.organizationPublicId}\`)` (giữ nguyên navigate target cũ).
   - Assign Students item: `onSelect` → gọi callback `onRequestAssignStudents({...})` từ parent (giữ nguyên contract).
   - `ClassRowActionsProps` chỉ giữ `option` + `onRequestAssignStudents` (bỏ `onEdit` vì Edit là navigate, không cần parent biết).
   - Trigger `triggerClassName` giống FR-05.
   - **Constraint**: file `ClassesListView.tsx` phải ≤ 300 dòng (CLAUDE.md rule). Hiện tại 293 — chỉ được phép tăng tối đa ~7 dòng. Nếu cần thêm, extract items-builder sang helper trong cùng file hoặc file riêng.

---

## Non-Functional Requirements

- **Performance**: Row render ≤ 16ms. Không fetch mới, không re-render component khác khi 1 row thay đổi.
- **Accessibility**: 
  - Trigger button có `aria-label="Actions"` (qua `Dropdown.label`) + `aria-haspopup="menu"` + `aria-expanded` (đã có sẵn ở `Dropdown.tsx` line 101-102).
  - Disabled items có `aria-disabled="true"` (đã có sẵn qua `disabled` attribute + styling).
  - Menu `role="menu"`, items `role="menuitem"` (đã có sẵn).
- **Consistency**: Trigger style (outlined-neutral pill) đồng nhất với các pill cũ (`Assign Students` cũ dùng cùng shape `border-slate-300 text-slate-700`).
- **File size**: `ClassesSection.tsx` ≤ 300 dòng (CLAUDE.md rule). Hiện tại 285 → extract labels nếu cần.
- **Build**: `pnpm --filter tenant-web build` PASS, `tsc --noEmit` clean, `eslint` clean.

---

## Success Criteria

- [ ] **Visual**: Row chỉ có 1 outlined-pill button "Actions ▾", không còn Edit/Assign Students/kebab riêng.
- [ ] **Click target**: Trigger button width ≥ 100px, click area rõ ràng.
- [ ] **Menu content**: 6 items theo thứ tự FR-02, có 2 divider, Archive text đỏ.
- [ ] **Disabled state**: Khi class SUSPENDED, "Assign students" item hiển thị disabled + grayed + tooltip (qua `title` attr).
- [ ] **No wrap**: Trên viewport 1280px, row KHÔNG wrap (chỉ 1 control).
- [ ] **Tests pass**: `pnpm --filter tenant-web build` PASS.
- [ ] **Lint clean**: ESLint trên `ClassesSection.tsx` = 0 errors, 0 warnings.

---

## Out of Scope

- Thay đổi `EditClassModal` / `ManageStudentsModal` body.
- Bulk action trên nhiều rows.
- Animation mở/đóng dropdown (giữ instant).
- Mobile bottom-sheet menu (chỉ desktop dropdown).
- Áp dụng cùng pattern cho `MergeClassRow` / `LecturerAssignmentRow` (defer sang phase sau).
- Keyboard navigation đầy đủ trong dropdown (chỉ ESC đóng).

---

## Assumptions

- `@pte/ui` đã có `Dropdown` primitive (xác nhận ở `packages/ui/src/components/Dropdown.tsx`) với API: `items`, `label`, `trigger`, `triggerClassName`, `align`. Hỗ trợ `danger`, `disabled`, `hidden`, `label`, `separator`.
- `ChevronDownIcon` đã có trong `packages/ui/src/components/icons.tsx` hoặc cần add (check khi implement).
- `useClassStatusMutations` hook signature không đổi.
- `CLASS_ROW_ACTIONS_TEXT` constants hiện có đủ labels (edit, assignStudents, activate, suspend, deactivate, archive, assignStudentsDisabledTitle, moreOptions).
- Locale label không cần i18n cho phase này.

---

## [NEEDS CLARIFICATION]

_(Đã giải quyết hết trong brainstorm — section trống)_
