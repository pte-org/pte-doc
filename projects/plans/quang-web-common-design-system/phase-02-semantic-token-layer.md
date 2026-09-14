# Phase 2: Semantic Token Layer

## Requirements

Làm cho token **đọc được**. Hiện `--ink-primary`, `--surface-card`, `--brand`
định nghĩa ở `:root` nhưng không expose thành utility nào — đường duy nhất chạm
tới chúng là qua tên palette Tailwind cũ:

```css
/* design-tokens.css:78-80 */
--color-gray-700: var(--ink-primary);
--color-gray-800: var(--ink-primary);
--color-gray-900: var(--ink-primary);
```

Đây là shim migration hợp lý — nhưng nó đang **là** design system chứ không phải
lối đi tạm. Hệ quả: không viết được `text-ink-primary`, và thang màu sụp
(`blue-700 === blue-800` → `hover:bg-blue-700 active:bg-blue-800` ở
`Button.tsx:20` không có phản hồi active nào).

Phase này thêm lớp ngữ nghĩa **bên cạnh** shim, không xóa shim (Phase 04 mới thu
nhỏ nó).

## Design Constraints

- Không đổi hex nào đã đối chiếu với `screen.html`. Chỉ đổi cách đặt tên/expose.
- Phase 00 đã chốt: **giữ tách** `--brand: #4169e8` và `--brand-strong: #204ece`
  (cả hai đều xuất hiện ở tầng applied của cả 2 bundle). Áp dụng quyết định đó.
- Shim legacy phải được đánh dấu rõ là deprecated bằng comment, kèm trỏ tới
  Phase 04. Không để dev sau tưởng đó là cách dùng đúng.
- Mọi giá trị interactive phải có **state khác nhau nhìn thấy được**:
  base ≠ hover ≠ active ≠ disabled.

### Luật màu dẫn xuất (bắt buộc)

`plan.md` nói "không invent thêm hex". Phase này cần 2 màu **không** tồn tại
trong bất kỳ `screen.html` nào (`--brand-active`, `--ink-tertiary`). Đó là
ngoại lệ có điều kiện, không phải quyền tự do:

Một màu dẫn xuất chỉ được thêm khi **trước hết** đã chứng minh không có màu nào
trong design dùng được. Trình tự bắt buộc:

1. Grep cả 2 bundle tìm ứng viên phù hợp vai trò. Ghi lại đã tìm gì.
2. Chỉ khi không có → dẫn xuất, và ghi đủ **4 trường** vào `token-decisions.md`:

   | Trường | Ví dụ |
   |---|---|
   | Hex | `#2f52c4` |
   | Lý do dẫn xuất | "design không có bậc pressed cho brand; cần state thứ 3 phân biệt được với hover" |
   | Contrast ratio đo được | "4.8:1 với `#ffffff`" |
   | Người quyết | quang, 2026-09-14 |

3. Đặt tên phải lộ rõ là dẫn xuất trong comment CSS: `/* derived — xem
   token-decisions.md */`.

Thiếu bất kỳ trường nào = không được merge. Đây là rào chắn chống việc design
system trôi dần khỏi nguồn design qua từng lần "chỉnh tí cho đẹp".

## Steps

### 1. Expose semantic utility

Thêm vào `@theme` (khối riêng, trên khối shim):

```css
@theme {
  --color-surface-page: var(--surface-page);
  --color-surface-card: var(--surface-card);
  --color-surface-subtle: var(--surface-subtle);
  --color-ink-primary: var(--ink-primary);
  --color-ink-secondary: var(--ink-secondary);
  --color-ink-muted: var(--ink-muted);      /* decorative only — xem bước 3 */
  --color-ink-tertiary: <mới, xem bước 3>;
  --color-brand: var(--brand);
  --color-brand-hover: var(--brand-hover);
  --color-brand-active: <mới, xem bước 2>;
  --color-brand-tint: var(--brand-tint);
  --color-divider: var(--divider);
  /* + sky / mint / cream / blush: tint + action */
}
```

Sinh ra `text-ink-primary`, `bg-surface-card`, `bg-brand-tint`, … Đây là
vocabulary mà mọi component mới phải dùng.

### 1b. Bổ sung 4 token có trong design nhưng thiếu trong impl

Từ bảng đo ở `plan.md`:

| Hex | Tần suất | Việc cần làm |
|---|---|---|
| `#204ece` | admin 8, tenant 27 | → `--brand-strong`, expose `--color-brand-strong` |
| `#eef2f6` | tenant 44 | đọc `screen.html` tại chỗ dùng để xác định vai trò (divider? surface?), đặt tên rồi khai báo |
| `#f8fafc` | admin 18 | như trên |
| `#2a78d6` | admin 17, tenant có | như trên |
| `#eb6834` | tenant 14 | accent cam — chưa có role nào trong impl. Khai báo, đánh dấu `unused` nếu chưa dùng |

Chưa dùng tới thì vẫn khai báo và đánh dấu `/* unused — reserved */`. Mục đích:
Phase 04 quét shim sẽ không nhầm chúng là màu lạ, và dev sau không tự bịa lại
một màu cam khác.

### 2. Tách các thang màu bị sụp

Rà `design-tokens.css:42-102`, liệt kê mọi cặp `--color-*` cùng trỏ một biến.
Đã biết: `blue-700/800`, `gray-700/800/900`, `gray-500/600`, `slate-700/800`,
`indigo-50/100`, `red-500/600/700`, `green-500/600/700`, `amber-500/600/700`,
`yellow-500/700`, `sky-500/600/700`.

Với mỗi role **interactive**, thêm giá trị phân biệt:

- `--brand-active`: tối hơn `--brand-hover` một bậc. Lấy từ `screen.html` nếu
  bản Stitch có state pressed; nếu không, dẫn xuất và **ghi rõ là dẫn xuất**.
- Sửa `Button.tsx:20` → `hover:bg-brand-hover active:bg-brand-active`.
- Ba role status (mint/cream/blush) chỉ cần 1 action color — không tự bịa thêm
  bậc. Chỉ tách khi có state thật cần.

Với role **non-interactive** bị gộp: chấp nhận được, nhưng ghi vào
`token-decisions.md` để dev sau biết `text-gray-700` và `text-gray-900` là cố ý
giống nhau chứ không phải sót.

### 3. Sửa contrast — `--ink-muted` fail WCAG AA

`#7C8FAC` trên `#FFFFFF` = **3.30:1**. Ngưỡng AA cho text nhỏ là 4.5:1. Đang
dùng cho:

| Vị trí | Class | Cỡ chữ |
|---|---|---|
| `Input.tsx:45` | `placeholder:text-gray-400` | `text-sm` |
| `StatCard.tsx` footnote | `text-slate-400` | `text-xs` |
| `StatCard.tsx` trend | `text-slate-400` | `text-sm` |
| Sidebar section label | `text-slate-400` / `text-gray-400` | `text-[11px]` |

`#7C8FAC` là màu thật trong bản Stitch (xuất hiện 11 lần) — giữ nó, nhưng
**giới hạn vai trò**:

- `--ink-muted` (`#7C8FAC`) → chỉ dùng cho icon, border, divider, decorative.
- `--ink-tertiary` (mới, ≥4.5:1 trên `--surface-card`) → mọi text nhỏ.
  Dẫn xuất bằng cách tối dần `#7C8FAC` cho tới khi đạt ngưỡng; ghi hex và tỉ lệ
  đo được vào `token-decisions.md`.
- Thay 4 call site ở bảng trên sang `text-ink-tertiary`.

Kiểm tra cả các cặp khác trong khi đang ở đây — đã đo và **pass**:
`bg-gray-100/text-gray-600` = 5.10:1, `bg-green-50/text-green-700` = 4.66:1,
`text-gray-600` trên trắng = 5.53:1.

### 4. Bỏ focus indicator trùng

`design-tokens.css:136` có `:focus-visible { outline: 2px solid var(--brand) }`
global, còn `Button.tsx:50` có thêm `focus-visible:ring-2 ring-offset-2`. Hai
chỉ báo chồng nhau. Chọn một: giữ global outline (đơn giản, phủ mọi element) và
gỡ ring khỏi Button, hoặc ngược lại. Ghi quyết định.

### 5. Đánh dấu shim

Thay comment `/* Keep existing feature classes on the shared Academic Swiss
palette. */` bằng khối cảnh báo rõ: đây là deprecation shim, dev mới dùng
semantic utility, shim sẽ co lại ở Phase 04, trỏ tới file plan.

## Success Criteria

- [ ] Viết được `text-ink-primary`, `bg-surface-card`, `bg-brand-tint` và render đúng
- [ ] `Button` primary có 4 state phân biệt được bằng mắt: base / hover / active / disabled
- [ ] Không còn text `<18px` dưới 4.5:1 trong `packages/ui` và auth/dashboard
- [ ] Một chỉ báo focus duy nhất trên mọi interactive element
- [ ] Khối shim có comment deprecation trỏ tới Phase 04
- [ ] Mọi hex trong `design-tokens.css` truy được về `screen.html` hoặc về một
  dòng trong `token-decisions.md` giải thích vì sao dẫn xuất
- [ ] `next build` + `eslint` xanh ở cả 2 app

## Quality/Testing State

- Script kiểm tra contrast: đọc `design-tokens.css`, tính tỉ lệ cho mọi cặp
  foreground/background được dùng thật, fail nếu text nhỏ < 4.5:1. Chạy được
  trong CI.
- So màu bằng mắt: `Button` 4 state, `Badge` 5 variant, `Alert` 4 tone.
