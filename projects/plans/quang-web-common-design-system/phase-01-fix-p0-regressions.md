# Phase 1: Sửa 3 Regression P0

## Requirements

Ba lỗi này compile được, lint sạch, build xanh — và đều sai khi render. Phase
này sửa cả ba, và sửa theo cách đưa code về `packages/ui` thay vì vá tại chỗ ở
2 app.

## Design Constraints

- `Dropdown` phải mở đúng **trong** scroll container lẫn khi trang scroll. Fix
  bằng cách bỏ `overflow-x-auto` là sai hướng — bảng cần scroll ngang trên
  mobile, đó là lý do nó được thêm vào.
- Component sidebar nav mới phải sống ở `packages/ui`, không ở `features/auth`
  của từng app. Đây là điểm cốt lõi của mục tiêu "build lại common".
- Không đổi màu/khoảng cách nào ngoài phạm vi 3 lỗi. Token layer là Phase 02.

## Steps

### 1. Portal hóa `Dropdown`

`packages/ui/src/components/Dropdown.tsx` đang render menu bằng
`absolute z-20 mt-1`. Theo spec CSS, `overflow-x: auto` làm trục Y compute
thành `auto` → wrapper bảng trở thành scroll container → clip mọi absolute
descendant. Cả 5 bảng vừa được bọc wrapper đó.

- Render menu qua `createPortal(..., document.body)`, định vị bằng
  `getBoundingClientRect()` của trigger.
- Xử lý: reposition khi scroll/resize, đóng khi click ngoài, đóng khi `Escape`,
  flip lên trên khi không đủ chỗ dưới.
- SSR-safe: guard `typeof document !== "undefined"`, hoặc chỉ portal sau khi
  mounted.
- Giữ nguyên props API — 5 call site không được đổi.

Kiểm chứng: mở menu ở **hàng cuối cùng** của mỗi bảng, ở viewport 1440 và 390.

Sau khi portal chạy, gỡ `overflow-visible` thừa ở div cha các bảng (nó tồn tại
chỉ để né bug này) và gỡ `overflow-visible` ở `DataTable.tsx:77`.

### 2. Sửa grouping sidebar

`first:pt-1` sinh `.first\:pt-1:first-child` — specificity (0,2,0), luôn thắng
`.pt-4` (0,1,0). `<span>` section label luôn là first-child của wrapper `<div>`
của chính item đó, nên `pt-4` chưa từng có tác dụng ở bất kỳ nhóm nào.

Sửa bằng cấu trúc, không bằng variant: nhóm item theo `section` **trước khi**
render, mỗi section là một khối, spacing đặt ở khối chứ không ở span.

```tsx
// gom trước, render sau — bỏ hẳn so-sánh-với-phần-tử-trước
const groups = groupBySection(items);
```

Lợi ích phụ: hết `navItems[index - 1]?.section` (fragile khi filter theo
`requiredRoles` như tenant-web đang làm).

### 3. Đưa `SidebarNav` về `packages/ui`

Hiện `packages/ui/src/components/SidebarNav.tsx` còn style thời sidebar nền tối
và **không ai import** (chỉ còn trong barrel). Logic grouping mới nằm 2 bản y hệt
ở `apps/*/features/auth/components/DashboardChrome.tsx`.

- Viết lại `packages/ui/src/components/SidebarNav.tsx`: nhận `items` đã có
  `section`, tự group, render qua `renderLink` (giữ prop này — 2 app dùng
  `next/link` khác basePath, không import `next/link` vào `packages/ui`).
- Mở rộng `SidebarNavItem` với `section?: string`.
- Filter theo `requiredRoles` **ở lại app** (tenant-web) — đó là logic
  authorization, không phải presentation. `packages/ui` chỉ nhận mảng đã lọc.
- Xóa `SidebarNav` cục bộ ở cả 2 `DashboardChrome.tsx`; giữ lại `isActive` ở
  app vì luật active khác nhau (`/admin` exact vs `startsWith`) — truyền
  `isActive` đã tính vào item.
- A11y: bọc mỗi nhóm bằng `role="group"` + `aria-label={section}`, hoặc
  `<ul>`/`<li>` với heading liên kết. Hiện section label chỉ là `<span>` trôi
  nổi, screen reader không thấy nhóm.

## Success Criteria

- [ ] Menu row-action ở hàng cuối mở đầy đủ trên cả 5 bảng, 2 viewport
- [ ] Bảng vẫn scroll ngang được ở 390px
- [ ] Khoảng cách giữa các nhóm sidebar nhìn thấy rõ ở cả 2 app
- [ ] Zero duplicate: `grep -c "section !== " apps/` trả về 0
- [ ] `DashboardChrome.tsx` của cả 2 app không còn khai báo `SidebarNav` cục bộ
- [ ] Screen reader đọc được tên nhóm khi vào sidebar
- [ ] `next build` + `eslint` xanh ở cả 2 app

## Quality/Testing State

- Unit test cho hàm `groupBySection`: item không có `section`, tất cả cùng
  `section`, section xen kẽ không liền nhau, mảng rỗng.
- Kiểm chứng portal và grouping bằng browser (Playwright hoặc thủ công), ghi
  ảnh vào `phase-01-shots/`.
