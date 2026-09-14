# Phase 3: Shell Tokens, Sticky Header & Dọn Code Chết

## Requirements

Gỡ các arbitrary value lặp lại trong shell, sửa hoặc bỏ styling chết, và dọn
export không còn ai dùng. Toàn bộ phase này là hạ nợ — không thêm hành vi mới.

## Design Constraints

- `CODING_STANDARDS_WEB.md` cấm arbitrary value (`p-[16px]`, `bg-[#...]`).
  Giá trị dùng >1 nơi bắt buộc là token.
- Không xóa export khỏi `packages/ui` nếu còn ai import — verify bằng grep
  trước, không đoán.
- Sticky header: sửa cho chạy **hoặc** bỏ hẳn. Không để class chết.

## Steps

### 1. Token hóa kích thước shell

`packages/ui/src/layouts/DashboardShell.tsx` đang lặp arbitrary value:

| Giá trị | Số lần | Dòng |
|---|---|---|
| `w-[270px]` / `md:pl-[270px]` | 3 | 36, 49, 66 |
| `min-h-[70px]` | 3 | 37, 50, 67 |
| `shadow-[0_1px_8px_rgba(145,158,171,0.12)]` | 1 | 67 |

Chiều rộng sidebar xuất hiện ở 3 chỗ và phải khớp tuyệt đối — lệch một chỗ là
layout vỡ. Thêm vào `design-tokens.css`:

```css
--sidebar-width: 270px;
--topbar-height: 70px;
```

và expose qua `@theme` (`--spacing-sidebar`, `--spacing-topbar`) để viết
`w-sidebar` / `md:pl-sidebar` / `min-h-topbar`.

`shadow-[0_1px_8px_...]` đang hardcode trong khi `--shadow-sidebar` đã tồn tại
và không được dùng. Hoặc dùng `shadow-sidebar`, hoặc thêm `--shadow-topbar` vào
`@theme`. Không để inline.

Tương tự `text-[21px]` ở `PageHeader.tsx:12` — đưa về scale Tailwind hoặc khai
báo `--text-page-title`.

### 2. Sticky thead: sửa hoặc bỏ

`DataTable.tsx:80` có `sticky top-0 z-10` trên `<thead>`. Không bao giờ dính:
ancestor `overflow-x-auto` là scroll container, nhưng không có ràng buộc chiều
cao → nội dung không bao giờ overflow trục Y → `position: sticky` không có gì
để dính vào.

Hai lối:

- **Bỏ** — đơn giản nhất, page scroll vẫn dùng được nếu sau này bỏ scroll
  container.
- **Sửa** — thêm `max-h` (prop `maxHeight?: string`) lên scroll container, để
  header dính khi cuộn danh sách dài. Chỉ chọn lối này nếu thật sự muốn hành vi
  đó; nó đổi UX của mọi bảng.

Khuyến nghị: bỏ ở phase này. Nếu cần sticky header thì làm như một feature có
chủ đích, có thiết kế đối chiếu.

Lưu ý: sau khi Phase 01 portal hóa `Dropdown`, scroll container không còn clip
menu nữa, nên `overflow-x-auto` giữ nguyên là đúng.

### 3. Đổi relative import sang package export

Cả 2 app đang có:

```css
@import "../../../packages/ui/src/styles/design-tokens.css";
```

Thêm subpath vào `packages/ui/package.json`:

```json
"exports": {
  ".": "./src/index.ts",
  "./styles/design-tokens.css": "./src/styles/design-tokens.css"
}
```

rồi import qua tên package ở cả 2 `globals.css`. Verify build vẫn resolve được
(Tailwind v4 + Turbopack) — nếu không, giữ relative path và ghi lý do vào
`token-decisions.md` thay vì im lặng.

### 4. Dọn export chết

Đã grep, hiện không còn ai import:

- `packages/ui/src/components/Mascot.tsx` — thay bằng composition SVG trong
  `_AuthBrandPanel` ở cả 2 app
- `packages/ui/src/components/TopBar.tsx` — `DashboardShell` tự render header
- `packages/ui/src/components/SidebarNav.tsx` — Phase 01 viết lại, **không xóa**

Trước khi xóa: grep lại toàn workspace lần nữa (`pte-app` cũng có thể import
`@pte/ui`? — verify). Xóa file + dòng trong `components/index.ts`.

Chạy một lượt quét export chết cho toàn `packages/ui` (không chỉ 3 file trên) —
barrel export che mất code chết rất tốt.

### 5. Rà `packages/ui` hết arbitrary value

```bash
grep -rnE '\[(#|[0-9]+px|rgba?\()' packages/ui/src --include=*.tsx
```

Mỗi hit: đưa về token hoặc về scale Tailwind.

## Success Criteria

- [ ] `grep -rE '\[[0-9]+px\]|\[#|\[rgba' packages/ui/src` trả về rỗng
- [ ] Chiều rộng sidebar khai báo đúng một chỗ
- [ ] Không còn class sticky nào không hoạt động
- [ ] `@pte/ui` không còn export không ai dùng
- [ ] `globals.css` import token qua tên package (hoặc có lý do ghi lại)
- [ ] `next build` + `eslint` xanh ở cả 2 app
- [ ] Screenshot shell khớp `baseline-shots/` (phase này không được đổi pixel nào)

## Quality/Testing State

Phase này là refactor thuần: bằng chứng đúng = screenshot **không đổi** so với
sau Phase 02. Bất kỳ khác biệt pixel nào đều là regression, phải giải thích được.
