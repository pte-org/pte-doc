# Phase 0: Bảo Toàn Work, Diff Hygiene & Token Decisions

## Requirements

Tách working tree hiện tại (41 files, 3 loại thay đổi trộn làm một) thành các
commit đơn nghĩa, chốt token lệch, và ghi baseline đo được cho **cả hai** app.

Lý do làm trước: ~40% số dòng thêm là prettier reflow thuần (`printWidth: 100`
lần đầu được apply). Không tách bây giờ thì mọi review và `git blame` sau này
đều phải lội qua noise đó.

## Design Constraints

- **Không `git add -A`, không `git stash push -u` trên working tree dùng chung.**
  41 file đang sửa là công sức thật và chưa commit. `git diff` không bao gồm
  untracked (`packages/ui/src/styles/` là untracked) — stash/restore sai một
  bước là mất.
- Không sửa logic trong phase này. Chỉ bảo toàn, tách commit, ghi quyết định.
- Prettier commit phải là **pure format** — không đổi AST.

**Preflight:** repository là pnpm workspace TypeScript/Next.js; thay đổi hiện tại
gồm 41 tracked files và 1 untracked token stylesheet. Shared UI exports nằm ở
`packages/ui/src/components/index.ts`; hai app dùng scripts riêng cho build/lint.
Phase này chỉ được stage các paths đã có trong inventory, không stage asset hoặc
file ngoài `pte-web`.

**Testing:** skipped_by_user; decision: user_confirmed_skip. Unit tests không
chạy theo lựa chọn của người dùng; bằng chứng Phase 00 là inventory, commit
history, baseline logs và screenshot artifacts. Quality gate vẫn bắt buộc.

## Steps

### 1. Bảo toàn work — branch, không stash

```bash
cd d:/GitHub/pte-org/pte-web
git rev-parse HEAD | tee phase00-base-sha.txt

# inventory tường minh, tách tracked / untracked
git status --porcelain=v1 > /tmp/inv-all.txt
git diff --name-only                       > /tmp/inv-tracked.txt
git ls-files --others --exclude-standard    > /tmp/inv-untracked.txt
wc -l /tmp/inv-*.txt   # đối chiếu: tracked 41 + untracked (design-tokens.css)
```

Commit nguyên trạng lên branch bảo toàn — **liệt kê file từ inventory**, không
dùng `-A`:

```bash
git checkout -b wip/design-refactor-snapshot
git add $(cat /tmp/inv-tracked.txt) $(cat /tmp/inv-untracked.txt)
git status --short          # review TRƯỚC khi commit
git commit -m "wip: snapshot design system refactor (pre-split)"
```

Kiểm tra `git status` sạch và không có design asset / file lạ nào bị kéo theo.
Từ đây mọi thao tác đều revert được bằng SHA — không còn phụ thuộc stash.

### 2. Commit prettier trên nền sạch

```bash
git checkout -b chore/prettier-baseline <base-sha>
pnpm exec prettier --write "apps/**/*.{ts,tsx,css}" "packages/**/*.{ts,tsx,css}"
git add $(git diff --name-only)   # chỉ file prettier vừa đổi
git commit -m "style: apply prettier printWidth 100 across workspace"
```

Verify pure-format: diff giữa base và commit này, bỏ whitespace, phải rỗng.

```bash
git diff -w <base-sha> HEAD --stat   # kỳ vọng: rỗng hoặc chỉ wrapping
```

Snapshot chỉ là commit khôi phục, **không được cherry-pick nguyên commit** vào
nhánh làm việc vì nó vẫn chứa cả prettier, logic và IA. Đưa nội dung trở lại
nhánh prettier bằng apply không commit, rồi unstage để chọn từng nhóm:

```bash
git switch -c work/design-refactor <prettier-sha>
git cherry-pick --no-commit <snapshot-sha>
git reset                         # giữ thay đổi trong working tree
git add -p                        # chỉ stage refactor/common, review từng hunk
git commit -m "refactor: ..."
git add apps/vendor-web/lib/navigation.tsx apps/tenant-web/lib/navigation.tsx
git commit -m "feat(nav): ..."
```

Nếu apply có conflict do prettier đã đổi cùng dòng, resolve theo cây đã format,
rồi kiểm tra `git diff -w <base-sha> HEAD` và `git diff --check`. Diff nghĩa còn
lại phải giảm rõ so với 494/658 — ghi con số vào `baseline.md`.

### 3. Tách commit IA ra khỏi commit style

Thay đổi điều hướng bị lẫn vào refactor:

- `apps/vendor-web/lib/navigation.tsx` — thêm `Exam Blueprints` (`/admin/exams`),
  đảo `Licenses` lên trước `Question Bank`
- `apps/tenant-web/lib/navigation.tsx` — đổi `Students` → `Learners`, đảo thứ tự

`section` là structural (Phase 01 cần) → giữ trong commit refactor.
Đổi nhãn / thêm mục / đảo thứ tự là IA → commit riêng `feat(nav):`, **cần người
quyết trước khi merge**. Route `/admin/exams` có tồn tại nên không vỡ, nhưng
vẫn là quyết định sản phẩm.

### 4. Chốt token — ghi `token-decisions.md`

Bảng so sánh hex thực tế giữa 2 bundle đã có trong `plan.md`. Ba việc phải quyết:

**4a. `--sky-action`: `#00658e` (admin, 15×) vs `#0e729f` (tenant, 39×)**
Lệch thật giữa 2 bundle. Impl đang dùng `#0e729f`. Contrast trên trắng:
đo cả hai, chọn giá trị đạt ≥4.5:1 nếu dùng cho text. Nếu cả hai đạt → chọn
`#0e729f` (tần suất cao hơn, đã implement) và ghi rằng admin sẽ đổi theo.

**4b. `primary #204ece` vs `primary-container #4169e8`**
Đã có dữ liệu: **cả hai đều xuất hiện ở tầng applied** của cả hai bundle
(admin 8/9, tenant 27/102). → **Giữ tách 2 role.** Thêm `--brand-strong: #204ece`
bên cạnh `--brand: #4169e8`. Đây là kết luận từ dữ liệu, không cần tranh luận
thêm — chỉ cần ghi lại.

**4c. 4 token design chưa có trong impl**
`#eb6834` (admin 3×, tenant 14×), `#eef2f6` (tenant 44×),
`#2a78d6` (admin 17×, tenant 14×), `#f8fafc` (admin 18×, tenant 12×).
Xác định vai trò từng cái bằng cách đọc `screen.html` tại chỗ dùng, rồi đặt tên
semantic. Chưa dùng tới thì vẫn khai báo và đánh dấu `unused` — để Phase 04
không nhầm là màu lạ.

**Format bắt buộc mỗi dòng `token-decisions.md`:**

| Token | Hex | Nguồn | Contrast (trên bg nào) | Quyết bởi | Ghi chú |
|---|---|---|---|---|---|

Với màu **dẫn xuất** (không tồn tại trong `screen.html` nào), cột `Nguồn` ghi
`derived` và bắt buộc có lý do + contrast đo được. Phase 02 sẽ thêm
`--brand-active` và `--ink-tertiary` theo luật này.

Mục tiêu: 100% hex trong `design-tokens.css` truy được về một dòng ở đây.

### 5. Baseline evidence — full log, không `tail`

```bash
{
  echo "base-sha: $(git rev-parse HEAD)"
  echo "node: $(node -v)"; echo "pnpm: $(pnpm -v)"
  echo "next: $(pnpm --filter vendor-web exec next --version)"
  echo "date: $(date -Iseconds)"
} > baseline-env.txt

pnpm --filter vendor-web exec next build  > baseline-build-vendor.log 2>&1; echo "exit=$?" >> baseline-build-vendor.log
pnpm --filter tenant-web exec next build  > baseline-build-tenant.log 2>&1; echo "exit=$?" >> baseline-build-tenant.log
pnpm --filter vendor-web exec eslint .    > baseline-lint-vendor.log   2>&1; echo "exit=$?" >> baseline-lint-vendor.log
pnpm --filter tenant-web exec eslint .    > baseline-lint-tenant.log   2>&1; echo "exit=$?" >> baseline-lint-tenant.log
pnpm --filter @pte/ui run typecheck       > baseline-typecheck-ui.log  2>&1; echo "exit=$?" >> baseline-typecheck-ui.log
```

Lưu **toàn bộ** output, kèm exit code. `tail -30` cắt mất warning và route table
— đúng phần cần đối chiếu ở Phase 05.

`tenant-web` chưa từng được verify trong đợt implement trước. Nếu nó đã đỏ sẵn,
phải biết ngay để không quy nhầm cho các phase sau.

### 6. Chốt phương pháp so sánh ảnh — trước khi chụp

Stitch export ở **2560px desktop** (`metadata.json`: `width: 2560`). Baseline
định chụp 1440/1024/390. Hai con số này không so pixel với nhau được.

Chọn **một**, ghi vào `baseline.md`:

- **(A) Semantic checklist** — chụp 1440/1024/390, đối chiếu theo hạng mục
  (màu nền, màu chữ, radius, shadow, spacing, typography, badge state). Không
  claim pixel-perfect. *Khuyến nghị:* app là responsive layout, 2560 không phải
  viewport người dùng thật.
- **(B) Pixel diff** — thêm viewport 2560 vào bộ chụp **chỉ để** so với Stitch;
  1440/1024/390 vẫn giữ cho regression nội bộ. Đắt hơn, và vẫn sẽ lệch ở chỗ
  nội dung động (tên tenant, số liệu).

Phase 05 dùng đúng lựa chọn ở đây. Không để mỗi lần verify lại một chuẩn.

### 7. Chụp baseline

Theo phương pháp đã chốt ở bước 6, cho:

- vendor-web: `/login`, `/admin`, `/admin/tenants`, `/admin/tenants/[publicId]`,
  `/admin/questions`, `/admin/exams`, `/admin/licenses`
- tenant-web: `/login`, `/host/dashboard`, `/host/students`, `/host/programs`,
  `/host/programs/[publicId]`, `/host/programs/[publicId]/classes/[classPublicId]`,
  `/host/exams`, `/host/exams/[publicId]`, `/host/audit-log`, `/host/roster`

Lưu `baseline-shots/{app}/{route}/{viewport}.png`. Đây là đối chứng cho Phase 05
và cho quy tắc "Phase 03/04 không được đổi pixel nào".

## Success Criteria

- [ ] Branch snapshot tồn tại, `git status` sạch, không kéo theo file ngoài inventory
- [ ] `phase00-base-sha.txt` ghi SHA gốc
- [ ] Commit `style:` tồn tại và `git diff -w` so với base là rỗng
- [ ] Diff refactor còn lại không chứa dòng chỉ khác whitespace; con số mới ghi vào `baseline.md`
- [ ] Thay đổi IA ở commit riêng, chưa merge, đã gắn người quyết
- [ ] `token-decisions.md` phủ 100% hex trong `design-tokens.css`, gồm 4a/4b/4c
- [ ] Baseline log **đầy đủ** (không `tail`) + exit code + env cho cả 2 app
- [ ] Phương pháp so ảnh (A hay B) đã chốt bằng văn bản
- [ ] `baseline-shots/` phủ 7 route vendor + 10 route tenant

## Quality/Testing State

Không có test tự động. Bằng chứng là các file sinh ra ở bước 5–7 và khả năng
`git checkout <base-sha>` khôi phục nguyên trạng bất cứ lúc nào.
