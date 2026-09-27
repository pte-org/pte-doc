# Token decisions — Phase 00

Phạm vi đối chiếu: 5 screen vendor trong `stitch-pte-admin-dashboards` và 16 screen
tenant trong `stitch-pte-tenant-web`. Contrast dùng công thức WCAG relative luminance,
làm tròn 2 chữ số; các màu chart/surface chỉ ghi contrast tham khảo và không được dùng
làm màu chữ nếu không đạt ngưỡng phù hợp.

| Token | Hex | Nguồn | Contrast (trên bg nào) | Quyết bởi | Ghi chú |
|---|---|---|---|---|---|
| `--sky-action` — admin candidate | `#00658e` | Stitch admin `secondary` | 6.46:1 trên `#ffffff` | Phase 00 | Candidate admin; không chọn làm implementation value vì tenant dùng màu gần tương ứng với tần suất cao hơn. |
| `--sky-action` | `#0e729f` | Stitch tenant `secondary` | 5.35:1 trên `#ffffff`; 4.93:1 trên `#f2f6fa` | Phase 00 | Chọn value chung cho cả hai app; giữ implementation hiện tại. Đủ 4.5:1 nếu dùng cho text trên nền sáng. |
| `--brand-strong` (planned) | `#204ece` | Stitch `primary` | 6.90:1 trên `#ffffff` | Phase 00 | Giữ role riêng với `--brand`; Phase 02 sẽ thêm semantic token. |
| `--brand` | `#4169e8` | Stitch `primary-container` | 4.76:1 trên `#ffffff` | Phase 00 | Giữ role container/action hiện tại; không gộp với `--brand-strong`. |
| `--chart-orange` | `#eb6834` | Stitch chart series / Reading / PTE Core | 3.20:1 trên `#ffffff`; 2.81:1 trên `#fdede8` | Phase 00 | Đã khai báo nhưng chưa được component dùng; decorative/data series, không dùng cho body text. |
| `--skeleton-base` | `#eef2f6` | Stitch state pack skeleton | 1.12:1 trên `#ffffff` | Phase 00 | Đã khai báo nhưng chưa được component dùng; chỉ dùng làm skeleton surface. |
| `--chart-blue` | `#2a78d6` | Stitch chart series / PTE Academic / Speaking & Writing | 4.42:1 trên `#ffffff`; 4.07:1 trên `#f2f6fa` | Phase 00 | Đã khai báo nhưng chưa được component dùng; data visualization, không mặc định làm text. |
| `--surface-row-hover` | `#f8fafc` | Stitch table hover / state pack skeleton | 1.05:1 trên `#ffffff` | Phase 00 | Đã khai báo nhưng chưa được component dùng; chỉ là surface phụ. |
| `--mint-action` | `#088068` | Stitch status/action `tertiary-container` | 4.89:1 trên `#ffffff` | Phase 00 | Giữ cho success/active mint action. |
| `--ink-primary` | `#2a3547` | Stitch on-surface/body text | 12.36:1 trên `#ffffff` | Phase 00 | Text chính. |
| `--ink-secondary` | `#5a6a85` | Stitch secondary text | 5.48:1 trên `#ffffff` | Phase 00 | Text phụ. |
| `--ink-muted` / `--control-border` | `#7c8fac` | Stitch outline/secondary text | 3.29:1 trên `#ffffff` | Phase 00 | Chỉ dùng cho muted text lớn, icon, border; không dùng cho body text nhỏ. |
| `--cream-action` | `#9c6400` | Stitch warning/cream action | 4.96:1 trên `#ffffff` | Phase 00 | Warning action/text. |
| `--blush-action` | `#be452b` | Stitch error/blush action | 5.15:1 trên `#ffffff` | Phase 00 | Error/destructive action. |
| `--brand-soft` | `#5d87ff` | derived | 3.29:1 trên `#ffffff` | Phase 00 | Derived từ brand scale để phục vụ soft emphasis; không dùng cho text nhỏ. |
| `--brand-deep` | `#2f52c4` | derived | 6.72:1 trên `#ffffff` | Phase 00 | Derived darker brand state cho hover/pressed. |
| `--brand-ink` / `--color-blue-700` | `#3359d2` | Stitch applied state | 6.00:1 trên `#ffffff` | Phase 00 | Giữ cho text/icon brand state. |
| `--color-blue-950` | `#24439f` | derived | 8.83:1 trên `#ffffff` | Phase 00 | Derived deep blue để không tạo thêm palette tùy ý. |
| `--color-slate-850` | `#202a3a` | derived | 14.45:1 trên `#ffffff` | Phase 00 | Derived deep neutral cho emphasis. |
| `--color-blue-200` | `#c4d5ff` | derived | 1.47:1 trên `#ffffff` | Phase 00 | Derived brand surface. |
| `--color-sky-100` | `#d5f1ff` | derived | 1.18:1 trên `#ffffff` | Phase 00 | Derived sky surface. |
| `--color-blue-100` | `#dce6ff` | derived | 1.25:1 trên `#ffffff` | Phase 00 | Derived blue surface. |
| `--color-slate-300` | `#dfe5ef` | Stitch surface/border | 1.27:1 trên `#ffffff` | Phase 00 | Border/surface only. |
| `--divider` | `#e5eaef` | Stitch divider | 1.21:1 trên `#ffffff` | Phase 00 | Divider only. |
| `--mint-tint` | `#e6fffa` | Stitch mint container | 1.05:1 trên `#ffffff` | Phase 00 | Surface tint only. |
| `--sky-tint` | `#e8f7ff` | Stitch sky container | 1.09:1 trên `#ffffff` | Phase 00 | Surface tint only. |
| `--surface-subtle` | `#eaeff4` | derived | 1.16:1 trên `#ffffff` | Phase 00 | Derived neutral surface between page and card. |
| `--brand-tint` | `#ecf2ff` | Stitch brand container | 1.12:1 trên `#ffffff` | Phase 00 | Surface tint only. |
| `--surface-page` | `#f2f6fa` | Stitch page background | 1.09:1 trên `#ffffff` | Phase 00 | Page background, not text. |
| `--color-red-200` | `#f3c7bb` | derived | 1.53:1 trên `#ffffff` | Phase 00 | Derived blush border/surface. |
| `--color-slate-50` / `--color-gray-50` | `#f6f9fc` | Stitch surface | 1.06:1 trên `#ffffff` | Phase 00 | Surface only. |
| `--blush-tint` | `#fdede8` | Stitch error container | 1.14:1 trên `#ffffff` | Phase 00 | Surface tint only. |
| `--cream-tint` | `#fef5e5` | Stitch warning container | 1.08:1 trên `#ffffff` | Phase 00 | Surface tint only. |
| `--surface-card` / `--on-primary` | `#ffffff` | Stitch surface/on-color | 1.00:1 trên `#ffffff` | Phase 00 | Card and inverse text surface. |

## Resolution

- `#00658e` và `#0e729f` đều đạt 4.5:1 trên nền trắng; chọn `#0e729f` làm
  `--sky-action` chung vì xuất hiện nhiều hơn trong bundle tenant và đã được implementation dùng.
- `#204ece` và `#4169e8` đều xuất hiện ở lớp applied của cả hai bundle; giữ hai role
  `--brand-strong` và `--brand` riêng biệt.
- Bốn màu trước đây chưa có trong implementation đã được khai báo semantic trong
  `design-tokens.css` và đánh dấu chưa được component dùng: `--chart-blue`,
  `--chart-orange`, `--skeleton-base`, `--surface-row-hover`.
- Mọi literal hex hiện có trong `design-tokens.css` đều được truy vết trong bảng trên;
  các màu không xuất hiện literal trong screen HTML được ghi `derived` và nêu lý do.
