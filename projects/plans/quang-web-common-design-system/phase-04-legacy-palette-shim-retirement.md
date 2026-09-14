# Phase 4: Thu Nhỏ Legacy Palette Shim

## Requirements

Đổi tên utility trong feature code từ palette legacy sang semantic vocabulary,
rồi co khối shim trong `design-tokens.css:42-102` xuống mức nhỏ nhất.

Đây là phase đắt nhất và **phải làm trước khi refactor thêm màn hình**. Mỗi
component mới viết bằng `text-gray-700` làm codemod này dài thêm.

## Design Constraints

- Đây là đổi tên, không đổi giá trị. Pixel output phải **giống hệt** trước/sau.
- Không codemod thủ công từng file — viết script, chạy, review diff.
- Mapping phải là 1-1 và quyết định được. Chỗ nào không quyết được (ví dụ
  `text-gray-700` vs `text-gray-900` giờ cùng màu — ý định gốc là gì?) thì đọc
  design reference, đừng đoán.

## Steps

### 1. Inventory TOÀN BỘ shim trước khi viết mapping

Khối shim có **61 key màu**, không phải vài họ như bảng rút gọn ban đầu. Sinh
inventory bằng máy, không liệt kê tay:

```bash
cd d:/GitHub/pte-org/pte-web
sed -n '/@theme inline/,/^}/p' packages/ui/src/styles/design-tokens.css \
  | grep -oE '^\s*--color-[a-z]+-[0-9]+' | tr -d ' ' | sort > /tmp/shim-keys.txt
wc -l /tmp/shim-keys.txt    # kỳ vọng 61
```

Phân bố đã đo (2026-09-14):

| Họ | Số key | Bậc |
|---|---:|---|
| `slate` | 11 | 50,100,200,300,400,500,600,**650**,700,800,**850** |
| `gray` | 10 | 50,100,200,300,400,500,600,700,800,900 |
| `blue` | 9 | 50,100,200,500,600,700,800,900,950 |
| `red` | 6 | 50,100,200,500,600,700 |
| `sky` | 5 | 50,100,500,600,700 |
| `green` | 5 | 50,100,500,600,700 |
| `amber` | 5 | 50,100,500,600,700 |
| `indigo` | 4 | 50,100,700,900 |
| `yellow` | 4 | 50,100,500,700 |
| `emerald` | 1 | 500 |
| `rose` | 1 | 500 |

Với **mỗi** key trong `/tmp/shim-keys.txt`, đối chiếu số lần dùng thật:

```bash
while read k; do
  cls=$(echo "$k" | sed 's/--color-//')
  n=$(grep -rEo "(bg|text|border|divide|ring|shadow|from|to|via)-$cls\b" \
        apps packages --include=*.tsx | wc -l)
  echo "$cls $n"
done < /tmp/shim-keys.txt | sort -k2 -rn > shim-usage.txt
```

Key có `n=0` → xóa thẳng, không cần mapping. Đã biết chắc 2 trường hợp:
**`slate-650` và `slate-850`** — không phải bậc Tailwind chuẩn (chúng *tạo mới*
utility), và grep trả về **0 usage** sau khi `DashboardChrome` bỏ
`hover:bg-slate-850` / `hover:text-slate-650`. Đó là token chết sinh ra từ đợt
refactor trước.

### 1b. Mapping (chỉ cho key còn dùng)

| Legacy | Semantic | Ghi chú |
|---|---|---|
| `gray-700/800/900`, `slate-700/800` | `ink-primary` | gộp có chủ ý |
| `gray-500/600`, `slate-500/600` | `ink-secondary` | |
| `gray-400`, `slate-400` | `ink-muted` (decorative) **hoặc** `ink-tertiary` (text) | ⚠ xem dưới |
| `gray-300` | `control-border` | `--control-border` đã tồn tại, chưa dùng |
| `gray-200` | `divider` | |
| `gray-100`, `slate-100` | `surface-page` | |
| `gray-50`, `slate-50` | *(cần quyết)* | cùng `#f6f9fc`; đối chiếu `#f8fafc`/`#eef2f6` ở Phase 02 bước 1b |
| `slate-200` | `surface-subtle` | |
| `slate-300` | *(cần quyết)* | `#dfe5ef` — không có trong design; ứng viên xóa |
| `blue-600` | `brand` | |
| `blue-700`, `blue-800` | `brand-hover` / `brand-active` | Phase 02 đã tách |
| `blue-900`, `blue-950` | `brand-deep` | `#24439f` không có trong design — verify |
| `blue-500` | `brand-soft` | |
| `blue-50/100/200`, `indigo-50/100` | `brand-tint` + bậc | |
| `indigo-700`, `indigo-900` | `brand-ink` / `brand-deep` | |
| `sky-*` | `sky-tint` / `sky-action` | |
| `green-*`, `emerald-500` | `mint-tint` / `mint-action` | |
| `amber-*`, `yellow-*` | `cream-tint` / `cream-action` | |
| `red-*`, `rose-500` | `blush-tint` / `blush-action` | |

⚠ **`gray-400` / `slate-400` không codemod máy móc được.** Decorative và text
phải ra 2 token khác nhau (Phase 02 bước 3). Liệt kê từng call site thành
checklist, phân loại tay, rồi mới thay.

Bốn dòng *(cần quyết)* là hex **không** truy được về `screen.html` — chúng hoặc
là dẫn xuất chưa ghi, hoặc là rác. Xử theo luật màu dẫn xuất ở Phase 02: có đủ
4 trường thì giữ, không thì xóa.

### 2. Viết codemod

Script Node đọc mapping, thay trong `apps/**/*.tsx` và `packages/ui/**/*.tsx`.
Phải xử lý đúng mọi prefix: `text-`, `bg-`, `border-`, `divide-`, `ring-`,
`shadow-`, `placeholder:`, `hover:`, `focus:`, `active:`, `disabled:`,
`focus-within:`, `focus-visible:`, `md:`, `[&>svg]:`, và opacity modifier
(`bg-blue-600/25`).

Chạy dry-run trước, in ra mọi thay thế dự kiến, review rồi mới apply.

### 3. Co shim

Sau codemod, mỗi dòng còn lại trong khối shim là một chỗ chưa migrate. Grep
từng tên legacy còn sót; xử lý tới khi khối shim rỗng hoặc chỉ còn những mục có
lý do ghi lại (ví dụ thư viện bên thứ ba sinh class Tailwind mặc định).

Khi shim rỗng: gỡ khối, trả `blue-*` / `gray-*` / `red-*` về palette Tailwind
gốc. Từ đó dev viết `text-gray-500` sẽ ra màu xám thật — và đó là hành vi đúng,
vì họ đã có `text-ink-secondary` cho ý định thật sự.

### 4. Rào chắn

Thêm ESLint rule (hoặc `tailwindcss/no-restricted-classes` tương đương) cấm
palette legacy trong code mới. Không có rào này, shim sẽ mọc lại.

## Success Criteria

- [ ] Screenshot mọi route (7 vendor + 10 tenant) khớp với trước Phase 04 — đây là đổi tên thuần
- [ ] `shim-usage.txt` phủ đủ **61 key**, mỗi key có kết luận: map / xóa / giữ-có-lý-do
- [ ] `slate-650`, `slate-850` đã xóa khỏi `design-tokens.css`
- [ ] Khối shim rỗng, hoặc mỗi dòng còn lại có lý do ghi trong `token-decisions.md`
- [ ] `grep -rE '(text|bg|border|divide|ring)-(gray|slate|blue|indigo|sky|green|emerald|amber|yellow|red|rose)-[0-9]' apps packages --include=*.tsx` trả rỗng
- [ ] Mọi call site `gray-400`/`slate-400` cũ được phân loại đúng decorative vs text
- [ ] ESLint chặn được palette legacy trong file mới
- [ ] `next build` + `eslint` xanh ở cả 2 app

## Quality/Testing State

Bằng chứng chính là **diff ảnh bằng 0**. Dùng bộ ảnh sau Phase 03 làm chuẩn;
bất kỳ pixel nào lệch nghĩa là mapping sai, không phải "design tinh chỉnh".

Codemod script commit vào repo (`tools/codemod/`) — nó là tài liệu sống của
mapping, và còn dùng lại khi migrate `pte-app`.
