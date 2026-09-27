# Plan: pte-web Common Design System (vendor-web + tenant-web)

**Status:** Phase 00 complete — Phase 01 pending test/quality selection
**Date:** 2026-09-14
**Mode:** Hard
**Author:** quang
**Implementation target:** `D:\GitHub\pte-org\pte-web`
**Design source:**
- `pte-doc/design/stitch-pte-admin-dashboards` — 5 screen → `vendor-web`
- `pte-doc/design/stitch-pte-tenant-web` — 16 screen → `tenant-web`

---

## Objective

Hoàn thiện lớp **common** (`packages/ui` + token layer) để cả `vendor-web` và
`tenant-web` dùng chung, trước khi refactor từng màn hình.

Plan này viết lại trên nền một đợt implement đã có sẵn trong working tree (do
một AI khác thực hiện). Đợt đó **đúng về trích xuất token** nhưng để lại 3
regression thật và một lớp token chỉ-ghi-không-đọc-được.

**Ngoài phạm vi (defer):** refactor nội dung từng màn hình. Chỉ chạm feature
component khi cần để lớp common đúng. Danh sách màn hình còn lại ghi vào
`deferred-screens.md` ở Phase 05.

---

## Baseline đã xác minh (2026-09-14)

| Kiểm tra | Kết quả |
|---|---|
| `pnpm --filter vendor-web exec next build` | ✅ pass (Next 16.2.9, Turbopack) |
| `pnpm --filter vendor-web exec eslint .` | ✅ clean |
| `pnpm --filter tenant-web exec next build` | ✅ pass (Next 16.2.9, Turbopack) |
| `pnpm --filter tenant-web exec eslint .` | ✅ clean |
| `pnpm --filter @pte/ui run typecheck` | ✅ pass |
| Diff | Working tree intentionally dirty; original `41 tracked + 1 untracked` inventory preserved |

Phase 00 đã ghi token decisions, baseline logs, 51 screenshot artifacts và quality
receipt APPROVED. Unit tests được bỏ qua theo lựa chọn của người dùng.

Build xanh **không** có nghĩa là đúng — cả 3 lỗi P0 dưới đây đều compile được.

---

## Design Authority (locked)

### Quyết định palette: MỘT palette chung, không theme riêng theo app

Đã đo hex thực tế trong `screen.html` của **cả hai** bundle (admin 5 screen,
tenant 16 screen):

| Hex | Admin | Tenant | Vai trò trong impl hiện tại |
|---|---:|---:|---|
| `#2a3547` | 10 | 229 | `--ink-primary` |
| `#7c8fac` | 26 | 169 | `--ink-muted` |
| `#f2f6fa` | 25 | 113 | `--surface-page` |
| `#088068` | 51 | 184 | `--mint-action` |
| `#9c6400` | 28 | 72 | `--cream-action` |
| `#be452b` | 20 | 47 | `--blush-action` |
| `#e6fffa` | 33 | 89 | `--mint-tint` |
| `#fdede8` | 11 | 37 | `--blush-tint` |
| `#4169e8` | 9 | 102 | `--brand` |
| `#204ece` | 8 | 27 | *(chưa có token)* |
| `#f9f9ff` | 15 | 52 | *(scaffold)* |
| `#111c2d` | 11 | 35 | *(scaffold)* |

**Hai bundle dùng chung một palette.** Điểm lệch mà review ban đầu nêu
(`#F2F6FA` vs `#F9F9FF`, `#2A3547` vs `#111C2D`) là so **hai tầng khác nhau
trong cùng một export**, không phải hai palette khác nhau:

- `#f9f9ff` / `#111c2d` nằm ở khối Tailwind config Material scaffold
  (`surface` / `on-surface`) — **cả hai** bundle đều có, với tần suất chuẩn hoá
  theo số screen gần như y hệt (~2.2 lần/screen).
- `#f2f6fa` / `#2a3547` là tầng **applied** — giá trị thực sự render ra.

→ **Chốt: một palette chung trong `packages/ui`.** Không dựng cơ chế theme
per-app. Dựng theme layer cho hai design vốn giống nhau là thêm một trục biến
thiên không có nhu cầu — YAGNI.

Hệ quả: `design-tokens.css` hiện tại thực chất được trích từ tầng applied của
bundle **tenant** (`--ink-secondary: #5a6a85`, `--brand-hover: #3359d2`,
`--cream-tint: #fef5e5`, `--sky-action: #0e729f` đều là giá trị tenant-heavy).
Đó là lựa chọn hợp lý — chỉ là chưa ai ghi lại nguồn.

### Lệch thật cần quyết (Phase 00)

| Điểm | Admin | Tenant | Ghi chú |
|---|---|---|---|
| sky action | `#00658e` (15×) | `#0e729f` (39×) | Impl đang dùng `#0e729f`. **Lệch thật**, phải chọn hoặc cho phép 2 bậc |
| `#eb6834` | 3× | 14× | Accent tenant-heavy, impl **chưa có token** |
| `#f8fafc` | 18× | 12× | Neutral xuất hiện ở cả hai bundle |
| `#eef2f6` | — | 44× | Neutral chỉ có ở tenant, impl chưa có |
| `#2a78d6` | 17× | 14× | Xuất hiện ở cả hai bundle, impl chưa có token |
| `primary` vs `primary-container` | cả hai đều dùng applied `#204ece` **và** `#4169e8` | | → **giữ tách 2 role**, không gộp. Đây là dữ liệu, không phải suy đoán |

---

## Vấn đề phải giải quyết

### P0 — Regression, chặn merge

| # | Vấn đề | Vị trí |
|---|---|---|
| 1 | `overflow-x-auto` mới clip menu row-action ở **cả 5 bảng** — `Dropdown` dùng `absolute`, không portal | `_RecentTenantsTable:36`, `_LicenseTable:28`, `_QuestionTable:23`, `_OrganizationTable:30`, `_TenantTable:91` |
| 2 | `first:pt-1` (specificity 0,2,0) luôn thắng `pt-4` (0,1,0) vì `<span>` luôn là first-child → grouping sidebar vô hình | `vendor DashboardChrome:73`, `tenant DashboardChrome:83` |
| 3 | SidebarNav có grouping bị copy-paste sang 2 app; `@pte/ui/SidebarNav` thành code chết — ngược mục tiêu "build lại common" và rule #6 `CLAUDE.md` | `packages/ui/src/components/SidebarNav.tsx` |

### P1 — Nợ kiến trúc

| # | Vấn đề |
|---|---|
| 4 | Token chỉ ghi: `--ink-primary`, `--brand`… có trong `:root` nhưng không expose thành utility. Chỉ chạm được qua tên palette cũ → design system bị khóa vào vocabulary legacy |
| 4b | Thang màu sụp: `blue-700 === blue-800` → `hover:bg-blue-700 active:bg-blue-800` không có phản hồi active. Tương tự `gray-700/800/900`, `gray-500/600`, `red/green/amber/sky 500/600/700` |
| 5 | `--ink-muted #7C8FAC` = 3.30:1 trên trắng, fail WCAG AA cho text nhỏ. Dùng ở placeholder, StatCard footnote/trend, sidebar section label |
| 6 | `sticky top-0` ở `DataTable` thead là code chết — scroll container không giới hạn chiều cao |
| 7 | Magic number ngược `CODING_STANDARDS_WEB.md`: `w-[270px]`×3, `min-h-[70px]`×3, `shadow-[0_1px_8px_...]` (dù `--shadow-sidebar` đã có), `text-[21px]` |
| 8 | `@import "../../../packages/ui/src/styles/design-tokens.css"` — relative path ×2 app thay vì package export |
| 9 | 4 token trong design (`#eb6834`, `#eef2f6`, `#2a78d6`, `#f8fafc`) chưa có trong impl |

### P2 — Vệ sinh

| # | Vấn đề |
|---|---|
| 10 | Prettier reflow (`printWidth: 100` lần đầu được apply) trộn vào diff nghĩa — ~40% số dòng là noise, hỏng `git blame` |
| 11 | Scope creep: nav thêm "Exam Blueprints", đổi "Students"→"Learners", đảo thứ tự — thay đổi IA lẫn trong refactor style |
| 12 | Export chết: `Mascot`, `TopBar`. Token chết: `--color-slate-650`, `--color-slate-850` (0 usage, không phải key Tailwind chuẩn) |

---

## Phases

| Phase | Nội dung | Blocking |
|---|---|---|
| [00](phase-00-baseline-and-diff-hygiene.md) | Bảo toàn work an toàn, tách commit prettier/IA, chốt token lệch, baseline cả 2 app | — |
| [01](phase-01-fix-p0-regressions.md) | Portal `Dropdown`, sửa `first:pt-1`, đưa SidebarNav về `@pte/ui` | P0 #1–#3 |
| [02](phase-02-semantic-token-layer.md) | Expose semantic utility, tách thang màu sụp, sửa contrast, bổ sung token thiếu | P1 #4, #4b, #5, #9 |
| [03](phase-03-shell-tokens-and-dead-code.md) | Token hóa shell dimension, sticky thead, dọn code/token chết, package export | P1 #6–#8, P2 #12 |
| [04](phase-04-legacy-palette-shim-retirement.md) | Inventory đủ 61 shim key → codemod → thu nhỏ shim | P1 #4 (phần còn lại) |
| [05](phase-05-verification.md) | Conformance 5 màn vendor + 8 màn tenant, audit contrast, responsive, regression | — |

Phase 01 merge được độc lập. Phase 02→04 là một chuỗi: **không** refactor thêm
màn hình nào trước khi Phase 04 xong.

---

## Design Constraints (áp dụng mọi phase)

- **Một palette chung.** Không dựng theme per-app.
- Không đổi hex đã đối chiếu với `screen.html`. Chỉ đổi **cách đặt tên và
  cách expose**.
- **Màu dẫn xuất** (không có trong bất kỳ `screen.html` nào) chỉ được thêm khi
  ghi đủ 4 trường vào `token-decisions.md`: hex cụ thể / lý do dẫn xuất /
  contrast ratio đo được / người quyết. Không có 4 trường này = không được thêm.
- Component dùng ở 2+ app → `packages/ui`. Không copy-paste (rule #6).
- Không arbitrary value mới. Giá trị dùng >1 nơi phải là token.
- Không đổi API/data-fetching. Plan này thuần presentation layer.
- Mỗi commit một loại: `style:` / `fix:` / `refactor:` / `feat:`. Không trộn.
- Sau mỗi phase: `next build` + `eslint` cho **cả hai** app, lưu **toàn bộ** log.

---

## Success Criteria

- [ ] 5 bảng mở được menu row-action ở hàng cuối, không bị clip
- [ ] Sidebar section header có khoảng cách nhóm nhìn thấy được ở cả 2 app
- [ ] Zero logic sidebar duplicate giữa 2 app
- [ ] Viết được `text-ink-primary` / `bg-surface-card` / `bg-brand` như utility
- [ ] `hover` và `active` của Button primary là 2 màu khác nhau
- [ ] Không còn text nhỏ dưới 4.5:1 trong `packages/ui` và auth/dashboard screens
- [ ] Zero arbitrary value trong `packages/ui`
- [ ] `token-decisions.md` phủ 100% hex trong `design-tokens.css`
- [ ] `next build` + `eslint` xanh ở cả `vendor-web` và `tenant-web`
- [ ] Conformance checklist pass: 5 màn vendor + 8 màn tenant
