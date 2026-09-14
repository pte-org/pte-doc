# Phase 5: Verification & Conformance

## Requirements

Chứng minh lớp common đúng, bằng bằng chứng đo được — không bằng "build xanh".
Đợt implement trước build xanh, lint sạch, typecheck pass, và vẫn có 3 lỗi
render. Phase này khép lỗ hổng đó.

## Design Constraints

- Mọi tuyên bố "xong" phải kèm output lệnh hoặc ảnh. Không tự đánh giá.
- Đối chiếu với `screen.png`, không với ấn tượng chủ quan.
- Verify **cả hai** app. `tenant-web` chưa từng được verify ở đợt trước.

## Steps

### 1. Visual conformance vs Stitch

**Phương pháp:** dùng đúng lựa chọn (A semantic checklist / B pixel diff) đã
chốt ở Phase 00 bước 6. Không đổi chuẩn giữa chừng. Lưu ý Stitch export ở
**2560px** (`metadata.json: width: 2560`) — nếu chọn (A) thì **không** claim
pixel-perfect ở bất kỳ mục nào trong report.

**vendor-web** — `stitch-pte-admin-dashboards/screens/`:

| Screen folder | Route |
|---|---|
| `01-tenants-list` | `/admin/tenants` |
| `02-tenant-detail` | `/admin/tenants/[publicId]` |
| `03-question-bank` | `/admin/questions` |
| `04-exam-blueprint-builder` | `/admin/exams` |
| `05-licences-quota` | `/admin/licenses` |

**tenant-web** — `stitch-pte-tenant-web/`:

| Screen folder | Route | Trạng thái |
|---|---|---|
| `01-dashboard-overview` | `/host/dashboard` | route có |
| `02-learners` | `/host/students` | route có |
| `03-programmes` | `/host/programs` | route có |
| `04-programme-detail` | `/host/programs/[publicId]` | route có |
| `05-class-detail` | `/host/programs/[publicId]/classes/[classPublicId]` | route có |
| `06-exam-sessions` | `/host/exams` | route có |
| `07-session-detail` | `/host/exams/[publicId]` | route có |
| `10-audit-log` | `/host/audit-log` | route có |
| `15-state-pack-empty-loading-error` | — | **tham chiếu state**, dùng để verify `EmptyState`/`LoadingState`/`ErrorState` trong `@pte/ui` |
| `16-responsive-views-tablet-mobile` | — | **tham chiếu responsive**, dùng ở bước 3 |

**Không có route tương ứng** — ghi vào `deferred-screens.md`, không verify ở
phase này: `08-create-edit-exam-session`, `09-scoring-review`, `11-staff-roles`,
`12-settings-system-config`, `13-staff-roles-assign-roles-drawer`,
`14-settings-branding`.

**Route có nhưng không có design** — cũng ghi vào `deferred-screens.md`:
`/host/roster`, `vendor-web /admin` (Overview), `/host` (vendor). Chúng vẫn phải
pass regression checklist ở bước 4 dù không có ảnh đối chiếu.

Phạm vi plan này là **common layer**, nên tiêu chí là: shell / card / table /
form / badge / button khớp. Nội dung riêng từng màn hình lệch thì ghi vào
`deferred-screens.md` làm đầu vào cho đợt sau — không sửa ở đây.

Kết quả ghi vào `visual-conformance-report.md`: một dòng mỗi (screen × hạng mục),
pass/fail, kèm đường dẫn ảnh.

### 2. Audit contrast tự động

Chạy script Phase 02 trên toàn bộ cặp fg/bg thực tế. Xuất bảng: cặp màu, tỉ lệ,
cỡ chữ, pass/fail. Zero fail cho text `<18px`.

### 3. Responsive

3 viewport: 1440 / 1024 / 390, đối chiếu với
`stitch-pte-tenant-web/16-responsive-views-tablet-mobile/`. Với mỗi route kiểm:

- Sidebar: desktop fixed ↔ mobile drawer, overlay đóng đúng
- Bảng scroll ngang được, không vỡ layout, không tràn ngang toàn trang
- Menu row-action ở **hàng cuối** mở đầy đủ (regression Phase 01)
- `PageHeader` actions wrap đúng khi hẹp
- Modal `max-h-[90vh]` không cắt nội dung ở 390

### 4. Regression checklist thủ công

Những thứ build không bắt được:

- [ ] Button primary: base / hover / active / disabled là 4 màu phân biệt được
- [ ] Sidebar section header có khoảng cách nhóm nhìn thấy được — cả 2 app
- [ ] Sidebar active item đúng route (`/admin` exact, còn lại `startsWith`)
- [ ] `requiredRoles` vẫn ẩn Audit Log với user không phải `HOST_ADMIN`
- [ ] Focus ring xuất hiện đúng một lần khi tab qua form
- [ ] Placeholder đọc được trên nền trắng
- [ ] Dropdown đóng khi `Escape` và khi click ngoài
- [ ] Login flow 2 app còn chạy (form submit, error state, SSO button)

### 5. Screen reader

VoiceOver/NVDA qua sidebar: tên nhóm được đọc, item có tên truy cập được,
trạng thái active thông báo được. Bảng: header liên kết đúng với cell.

### 6. Build cả hai app

Dùng đúng khuôn lệnh của Phase 00 bước 5 — **full log + exit code + env**,
không `tail`, để so được trực tiếp với `baseline-*.log`:

```bash
{ echo "sha: $(git rev-parse HEAD)"; echo "node: $(node -v)"; echo "pnpm: $(pnpm -v)"; } > verify-env.txt
pnpm --filter vendor-web exec next build > verify-build-vendor.log 2>&1; echo "exit=$?" >> verify-build-vendor.log
pnpm --filter tenant-web exec next build > verify-build-tenant.log 2>&1; echo "exit=$?" >> verify-build-tenant.log
pnpm --filter vendor-web exec eslint .   > verify-lint-vendor.log  2>&1; echo "exit=$?" >> verify-lint-vendor.log
pnpm --filter tenant-web exec eslint .   > verify-lint-tenant.log  2>&1; echo "exit=$?" >> verify-lint-tenant.log
pnpm --filter @pte/ui run typecheck      > verify-typecheck-ui.log 2>&1; echo "exit=$?" >> verify-typecheck-ui.log
```

So `diff baseline-build-tenant.log verify-build-tenant.log` — warning mới xuất
hiện cũng là regression, không chỉ exit code.

## Success Criteria

- [ ] `visual-conformance-report.md` có bảng pass/fail cho **5 màn vendor + 8 màn tenant**
- [ ] `15-state-pack` đối chiếu với `EmptyState`/`LoadingState`/`ErrorState` của `@pte/ui`
- [ ] Audit contrast: zero fail cho text nhỏ
- [ ] Responsive checklist pass đủ 3 viewport × mọi route, đối chiếu `16-responsive-views`
- [ ] Regression checklist pass đủ 8 mục, trên **cả hai** app
- [ ] Build + lint + typecheck xanh ở cả 2 app; full log lưu lại; diff với baseline không có warning mới
- [ ] `deferred-screens.md` liệt kê: 6 design chưa có route + 3 route chưa có design + việc màn-hình-cụ-thể còn lại

## Quality/Testing State

Đây là gate cuối. Không đánh dấu plan hoàn thành khi còn mục chưa có bằng chứng
đính kèm. Mục nào bỏ qua phải ghi rõ lý do bỏ qua, không im lặng.
